port module Main exposing (..)

import Api


port sendResponse : ( Int, Maybe String ) -> Cmd msg


port receiveRequest : (( String, String, Maybe String ) -> msg) -> Sub msg


type alias Model =
    ()


type Msg
    = GotRequest ( String, String, Maybe String )


main : Program () Model Msg
main =
    Platform.worker
        { init = \_ -> ( (), Cmd.none )
        , update = update
        , subscriptions = \_ -> receiveRequest GotRequest
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update (GotRequest ( method, path, body )) model =
    let
        response =
            Api.handle { method = method, path = path, body = body }
    in
    ( model, sendResponse response )
