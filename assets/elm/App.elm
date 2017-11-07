module App exposing (..)

import Html exposing (Html, div, text, program)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push


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



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ text "hello" ]



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
