module Route exposing
    ( Route(..)
    , fromUrl
    , toUrl
    )

import Url exposing (Url)
import Url.Builder
import Url.Parser as Parser


type Route
    = Home
    | Blue
    | Green
    | Yellow
    | Red


fromUrl : Url -> Route
fromUrl url =
    url
        |> Parser.parse parser
        |> Maybe.withDefault Home


parser : Parser.Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map Blue (Parser.s "blue")
        , Parser.map Green (Parser.s "green")
        , Parser.map Yellow (Parser.s "yellow")
        , Parser.map Red (Parser.s "red")
        ]


toUrl : Route -> String
toUrl route =
    case route of
        Home ->
            Url.Builder.absolute [] []

        Blue ->
            Url.Builder.absolute [ "blue" ] []

        Green ->
            Url.Builder.absolute [ "green" ] []

        Yellow ->
            Url.Builder.absolute [ "yellow" ] []

        Red ->
            Url.Builder.absolute [ "red" ] []
