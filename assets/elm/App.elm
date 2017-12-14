module App exposing (..)

import Html exposing (Html, div, input, button, text, textarea, program)
import Html.Attributes exposing (placeholder, cols, rows, value)
import Html.Events exposing (onClick, onInput)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Encode as JE
import Json.Decode as JD exposing (field)


-- MODEL


type alias Model =
    { phxSocket : Maybe (Phoenix.Socket.Socket Msg)
    , userId : String
    , content : String
    }


init : ( Model, Cmd Msg )
init =
    ( { phxSocket = Nothing
      , userId = ""
      , content = ""
      }
    , Cmd.none
    )



-- MESSAGES


type Msg
    = PhoenixMsg (Phoenix.Socket.Msg Msg)
    | InputUserId String
    | JoinChannel
    | SendMessage String
    | ReceiveMessage JE.Value



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ input [ placeholder "Input your user Id", onInput InputUserId ] []
        , button [ onClick JoinChannel ] [ text "Join channel" ]
        , textarea [ value model.content, onInput SendMessage, cols 80, rows 10 ] []
        ]



-- UPDATE


type alias ChatMessage =
    { body : String
    }


chatMessageDecoder : JD.Decoder ChatMessage
chatMessageDecoder =
    JD.map ChatMessage
        (field "body" JD.string)


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
