module App exposing (..)

import Html exposing (Html, div, ul, li, input, button, text, textarea, program)
import Html.Attributes exposing (placeholder, cols, rows, value, disabled)
import Html.Events exposing (onClick, onInput)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Phoenix.Presence exposing (PresenceState, syncState, syncDiff, presenceStateDecoder, presenceDiffDecoder)
import Json.Encode as JE
import Json.Decode as JD exposing (field)
import Dict exposing (Dict)


-- MODEL


type alias Flags =
    { userToken : String
    }


type alias Model =
    { phxSocket : Phoenix.Socket.Socket Msg
    , phxPresences : PresenceState UserPresence
    , users : List User
    , userId : String
    , content : String
    , userToken : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { phxSocket =
            Phoenix.Socket.init ("ws://localhost:4000/socket/websocket?user_token=" ++ flags.userToken)
                |> Phoenix.Socket.withDebug
                |> Phoenix.Socket.on "shout" "room:lobby" ReceiveMessage
                |> Phoenix.Socket.on "presence_state" "room:lobby" HandlePresenceState
                |> Phoenix.Socket.on "presence_diff" "room:lobby" HandlePresenceDiff
      , phxPresences = Dict.empty
      , users = []
      , userId = ""
      , content = ""
      , userToken = flags.userToken
      }
    , Cmd.none
    )


type alias User =
    { id : String
    }


type alias UserPresence =
    { online_at : String
    }



-- MESSAGES


type Msg
    = PhoenixMsg (Phoenix.Socket.Msg Msg)
    | JoinChannel
    | LeaveChannel
    | SendMessage String
    | ReceiveMessage JE.Value
    | HandlePresenceState JE.Value
    | HandlePresenceDiff JE.Value
    | InitializeContent JE.Value



-- VIEW


userView : User -> Html Msg
userView user =
    li []
        [ text user.id
        ]


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick JoinChannel ] [ text "Join channel" ]
        , button [ onClick LeaveChannel ] [ text "Leave channel" ]
        , textarea [ value model.content, onInput SendMessage, cols 80, rows 10 ] []
        , div []
            [ text "Logined user Id"
            , ul [] (List.map userView model.users)
            ]
        ]



-- UPDATE


type alias ChatMessage =
    { body : String
    }


chatMessageDecoder : JD.Decoder ChatMessage
chatMessageDecoder =
    JD.map ChatMessage
        (field "body" JD.string)


userPresenceDecoder : JD.Decoder UserPresence
userPresenceDecoder =
    JD.map UserPresence
        (JD.field "online_at" JD.string)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.update msg model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )

        JoinChannel ->
            let
                channel =
                    Phoenix.Channel.init "room:lobby"
                        |> Phoenix.Channel.onJoin InitializeContent

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.join channel model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )

        LeaveChannel ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.leave "room:lobby" model.phxSocket
            in
                ( { model | content = "", users = [], phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )

        SendMessage str ->
            let
                payload =
                    (JE.object [ ( "body", JE.string str ) ])

                push_ =
                    Phoenix.Push.init "shout" "room:lobby"
                        |> Phoenix.Push.withPayload payload

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.push push_ model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )

        ReceiveMessage raw ->
            case JD.decodeValue chatMessageDecoder raw of
                Ok chatMessage ->
                    ( { model | content = chatMessage.body }
                    , Cmd.none
                    )

                Err error ->
                    ( model
                    , Cmd.none
                    )

        HandlePresenceState raw ->
            case JD.decodeValue (presenceStateDecoder userPresenceDecoder) raw of
                Ok presenceState ->
                    let
                        newPresenceState =
                            model.phxPresences |> syncState presenceState

                        users =
                            Dict.keys presenceState
                                |> List.map User
                    in
                        ( { model | users = users, phxPresences = newPresenceState }
                        , Cmd.none
                        )

                Err error ->
                    ( model
                    , Cmd.none
                    )

        HandlePresenceDiff raw ->
            case JD.decodeValue (presenceDiffDecoder userPresenceDecoder) raw of
                Ok presenceDiff ->
                    let
                        newPresenceState =
                            model.phxPresences |> syncDiff presenceDiff

                        users =
                            Dict.keys newPresenceState
                                |> List.map User
                    in
                        ( { model | users = users, phxPresences = newPresenceState }
                        , Cmd.none
                        )

                Err error ->
                    ( model
                    , Cmd.none
                    )

        InitializeContent raw ->
            case JD.decodeValue chatMessageDecoder raw of
                Ok chatMessage ->
                    ( { model | content = chatMessage.body }
                    , Cmd.none
                    )

                Err error ->
                    ( model
                    , Cmd.none
                    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.Socket.listen model.phxSocket PhoenixMsg



-- MAIN


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
