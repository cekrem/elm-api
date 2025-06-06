module Api exposing (handle)

import Json.Decode as Decode
import Json.Encode as Encode


handle : { method : String, path : String, body : Maybe String } -> ( Int, Maybe String )
handle request =
    case ( request.method, request.path ) of
        ( "GET", "/" ) ->
            ( 200, Just <| Encode.encode 0 (Encode.object [ ( "works", Encode.bool True ) ]) )

        ( "GET", "/ping" ) ->
            ( 200, Just <| Encode.encode 0 (Encode.object [ ( "pong", Encode.bool True ) ]) )

        ( "POST", "/echo" ) ->
            -- Just echo back the body as-is
            ( 200, Just <| Encode.encode 0 (Encode.object [ ( "youSaid", Encode.string (request.body |> Maybe.withDefault "") ) ]) )

        _ ->
            ( 404, Just <| Encode.encode 0 (Encode.object [ ( "error", Encode.string "Not found" ) ]) )
