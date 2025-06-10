port module Main exposing (..)

import Api


port sendResponse : ( Int, Int, Maybe String ) -> Cmd msg


port receiveRequest : ({ requestId : Int, method : String, path : String, body : Maybe String } -> msg) -> Sub msg


type alias Model =
    ()


type Msg
    = GotRequest { requestId : Int, method : String, path : String, body : Maybe String }


main : Program () Model Msg
main =
    Platform.worker
        { init = \_ -> ( (), Cmd.none )
        , update = update
        , subscriptions = \_ -> receiveRequest GotRequest
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update (GotRequest request) model =
    let
        ( statusCode, responseBody ) =
            Api.handle { method = request.method, path = request.path, body = request.body }
    in
    ( model, sendResponse ( request.requestId, statusCode, responseBody ) )
