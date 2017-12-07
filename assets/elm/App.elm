module App exposing (..)

import Html exposing (Html, div, button, text, textarea, program)
import Html.Events exposing (onClick, onInput)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Encode as JE


-- MODEL


type alias Model =
    { phxSocket : Phoenix.Socket.Socket Msg
    }


init : ( Model, Cmd Msg )
init =
    ( { phxSocket =
            Phoenix.Socket.init "ws://localhost:4000/socket/websocket"
                |> Phoenix.Socket.withDebug
      }
    , Cmd.none
    )



-- MESSAGES


type Msg
    = PhoenixMsg (Phoenix.Socket.Msg Msg)
    | JoinChannel
    | SendMessage String



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick JoinChannel ] [ text "Join channel" ]
        , textarea [ onInput SendMessage ] []
        ]



-- UPDATE


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
