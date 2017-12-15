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


type alias Model =
    { phxSocket : Maybe (Phoenix.Socket.Socket Msg)
    , phxPresences : PresenceState UserPresence
    , users : List User
    , userId : String
    , content : String
    }


init : ( Model, Cmd Msg )
init =
    ( { phxSocket = Nothing
      , phxPresences = Dict.empty
      , users = []
      , userId = ""
      , content = ""
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
    | InputUserId String
    | JoinChannel
    | SendMessage String
    | ReceiveMessage JE.Value
    | HandlePresenceState JE.Value
    | HandlePresenceDiff JE.Value



-- VIEW


userView : User -> Html Msg
userView user =
    li []
        [ text user.id
        ]


view : Model -> Html Msg
view model =
    case model.phxSocket of
        Nothing ->
            div []
                [ input [ placeholder "Input your user Id", onInput InputUserId ] []
                , button [ onClick JoinChannel ] [ text "Join channel" ]
                ]

        Just modelPhxSocket ->
            div []
                [ input [ disabled True ] [ text model.userId ]
                , button [ disabled True ] [ text "Join channel" ]
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
            case model.phxSocket of
                Nothing ->
                    ( model, Cmd.none )

                Just modelPhxSocket ->
                    let
                        ( phxSocket, phxCmd ) =
                            Phoenix.Socket.update msg modelPhxSocket
                    in
                        ( { model | phxSocket = Just phxSocket }
                        , Cmd.map PhoenixMsg phxCmd
                        )

        InputUserId userId ->
            ( { model | userId = userId }
            , Cmd.none
            )

        JoinChannel ->
            case model.phxSocket of
                Nothing ->
                    let
                        url =
                            "ws://localhost:4000/socket/websocket?user_id=" ++ model.userId

                        phxSocket_ =
                            Phoenix.Socket.init url
                                |> Phoenix.Socket.withDebug
                                |> Phoenix.Socket.on "shout" "room:lobby" ReceiveMessage
                                |> Phoenix.Socket.on "presence_state" "room:lobby" HandlePresenceState
                                |> Phoenix.Socket.on "presence_diff" "room:lobby" HandlePresenceDiff

                        channel =
                            Phoenix.Channel.init "room:lobby"

                        ( phxSocket, phxCmd ) =
                            Phoenix.Socket.join channel phxSocket_
                    in
                        ( { model | phxSocket = Just phxSocket }
                        , Cmd.map PhoenixMsg phxCmd
                        )

                Just modelPhxSocket ->
                    let
                        channel =
                            Phoenix.Channel.init "room:lobby"

                        ( phxSocket, phxCmd ) =
                            Phoenix.Socket.join channel modelPhxSocket
                    in
                        ( { model | phxSocket = Just phxSocket }
                        , Cmd.map PhoenixMsg phxCmd
                        )

        SendMessage str ->
            case model.phxSocket of
                Nothing ->
                    ( model, Cmd.none )

                Just modelPhxSocket ->
                    let
                        payload =
                            (JE.object [ ( "body", JE.string str ) ])

                        push_ =
                            Phoenix.Push.init "shout" "room:lobby"
                                |> Phoenix.Push.withPayload payload

                        ( phxSocket, phxCmd ) =
                            Phoenix.Socket.push push_ modelPhxSocket
                    in
                        ( { model | phxSocket = Just phxSocket }
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.phxSocket of
        Nothing ->
            Sub.none

        Just phxSocket ->
            Phoenix.Socket.listen phxSocket PhoenixMsg



-- MAIN


main : Program Never Model Msg
main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
