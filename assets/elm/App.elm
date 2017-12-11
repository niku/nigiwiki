module App exposing (..)

import Html exposing (Html, div, button, text, textarea, program)
import Html.Attributes exposing (cols, rows, value)
import Html.Events exposing (onClick, onInput)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Encode as JE
import Json.Decode as JD exposing (field)


-- MODEL


type alias Model =
    { phxSocket : Phoenix.Socket.Socket Msg
    , content : String
    }


init : ( Model, Cmd Msg )
init =
    ( { phxSocket =
            Phoenix.Socket.init "ws://localhost:4000/socket/websocket"
                |> Phoenix.Socket.withDebug
                |> Phoenix.Socket.on "new:msg" "room:lobby" ReceiveMessage
      , content = ""
      }
    , Cmd.none
    )



-- MESSAGES


type Msg
    = PhoenixMsg (Phoenix.Socket.Msg Msg)
    | JoinChannel
    | SendMessage String
    | ReceiveMessage JE.Value



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick JoinChannel ] [ text "Join channel" ]
        , textarea [ value model.content, onInput SendMessage, cols 80, rows 10 ] []
        ]



-- UPDATE


type alias ChatMessage =
    { user : String
    , body : String
    }


chatMessageDecoder : JD.Decoder ChatMessage
chatMessageDecoder =
    JD.map2 ChatMessage
        (field "user" JD.string)
        (field "body" JD.string)


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

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.join channel model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )

        SendMessage str ->
            let
                payload =
                    (JE.object [ ( "user", JE.string "user" ), ( "body", JE.string str ) ])

                push_ =
                    Phoenix.Push.init "new:msg" "room:lobby"
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.Socket.listen model.phxSocket PhoenixMsg



-- MAIN


main : Program Never Model Msg
main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
