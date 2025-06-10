module Handler exposing (handleRequest)

import Json.Decode as Decode
import Json.Encode as Encode


type alias Request =
    { method : String
    , path : String
    , body : Maybe String
    }


type alias Response =
    { statusCode : Int
    , body : Maybe String
    }


handleRequest : Request -> Response
handleRequest request =
    case ( request.method, request.path ) of
        ( "GET", "/" ) ->
            { statusCode = 200
            , body = Just <| Encode.encode 0 (Encode.object [ ( "works", Encode.bool True ) ])
            }

        ( "GET", "/ping" ) ->
            { statusCode = 200
            , body = Just <| Encode.encode 0 (Encode.object [ ( "pong", Encode.bool True ) ])
            }

        ( "POST", "/echo" ) ->
            { statusCode = 200
            , body = Just <| Encode.encode 0 (Encode.object [ ( "youSaid", Encode.string (request.body |> Maybe.withDefault "") ) ])
            }

        _ ->
            { statusCode = 404
            , body = Just <| Encode.encode 0 (Encode.object [ ( "error", Encode.string "Not found" ) ])
            }

