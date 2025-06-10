module GoMain exposing (handleRequestFromGo, main)

import Handler
import Json.Decode as Decode
import Json.Encode as Encode
import Platform


type alias GoRequest =
    { method : String
    , path : String
    , body : Maybe String
    }


type alias GoResponse =
    { statusCode : Int
    , body : Maybe String
    }


requestDecoder : Decode.Decoder GoRequest
requestDecoder =
    Decode.map3 GoRequest
        (Decode.field "method" Decode.string)
        (Decode.field "path" Decode.string)
        (Decode.maybe (Decode.field "body" Decode.string))


responseEncoder : GoResponse -> Encode.Value
responseEncoder response =
    Encode.object
        [ ( "statusCode", Encode.int response.statusCode )
        , ( "body"
          , case response.body of
                Just body ->
                    Encode.string body

                Nothing ->
                    Encode.null
          )
        ]


{-| this main is a dummy to keep the compiler happy, what we're _actually_ using is `handleRequestFromGo`
-}
main : Program () () ()
main =
    Platform.worker
        { init =
            \_ ->
                -- Force the function to be included by referencing it
                let
                    _ =
                        handleRequestFromGo
                in
                ( (), Cmd.none )
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


handleRequestFromGo : String -> String
handleRequestFromGo jsonInput =
    case Decode.decodeString requestDecoder jsonInput of
        Ok request ->
            let
                response =
                    Handler.handleRequest request
            in
            Encode.encode 0 (responseEncoder response)

        Err _ ->
            Encode.encode 0
                (responseEncoder
                    { statusCode = 400
                    , body = Just """{"error": "Invalid request format"}"""
                    }
                )

