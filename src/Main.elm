port module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Browser.Navigation as Navigation
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Route exposing (Route(..))
import Url exposing (Url)



-- PORTS


port sendShouldBlockNavigation : Bool -> Cmd msg


port blockNavigationReceiver : (Decode.Value -> msg) -> Sub msg



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = ClickedLink
        , onUrlChange = UrlChanged
        }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    blockNavigationReceiver (BlockNavigationReceived << blockedNavigationDetailsDecoder)


type alias BlockedNavigationDetails =
    { location : Maybe Url
    , toUrl : Maybe Url
    }


blockedNavigationDetailsDecoder : Decode.Value -> BlockedNavigationDetails
blockedNavigationDetailsDecoder value =
    let
        default : BlockedNavigationDetails
        default =
            { location = Nothing
            , toUrl = Nothing
            }

        decoder : Decoder BlockedNavigationDetails
        decoder =
            Decode.succeed BlockedNavigationDetails
                |> Pipeline.required "location" (Decode.map Url.fromString Decode.string)
                |> Pipeline.required "toUrl" (Decode.map Url.fromString Decode.string)
    in
    Decode.decodeValue decoder value
        |> Result.withDefault default



-- MODEL


type alias Model =
    { navKey : Navigation.Key
    , route : Route
    , shouldBlockNavigation : Bool
    , blockedNavigation : BlockedNavigation
    }


type BlockedNavigation
    = UnBlocked
    | Blocked Url


init : () -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init _ url navKey =
    ( { navKey = navKey
      , route = Route.fromUrl url
      , shouldBlockNavigation = False
      , blockedNavigation = UnBlocked
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ClickedLink Browser.UrlRequest
    | UrlChanged Url
    | BlockNavigationReceived BlockedNavigationDetails
    | UserRejectedBlockedNavigationWarning Url
    | UserAcceptedBlockedNavigationWarning
    | ToggleUnsavedChanges


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLink (Browser.Internal url) ->
            if model.shouldBlockNavigation then
                ( { model | blockedNavigation = Blocked url }
                , Cmd.none
                )

            else
                ( { model | route = Route.fromUrl url }
                , Navigation.pushUrl model.navKey (Url.toString url)
                )

        ClickedLink (Browser.External url) ->
            ( model
            , Navigation.load url
            )

        UrlChanged url ->
            ( { model | route = Route.fromUrl url }
            , Cmd.none
            )

        BlockNavigationReceived { location, toUrl } ->
            let
                ( route, blockedNavigation ) =
                    case location of
                        Just location_ ->
                            ( Route.fromUrl location_
                            , Blocked (Maybe.withDefault location_ toUrl)
                            )

                        Nothing ->
                            ( model.route, model.blockedNavigation )
            in
            ( { model
                | route = route
                , blockedNavigation = blockedNavigation
              }
            , Cmd.none
            )

        UserRejectedBlockedNavigationWarning url ->
            ( { model
                | route = Route.fromUrl url
                , shouldBlockNavigation = False
                , blockedNavigation = UnBlocked
              }
            , Cmd.batch
                [ Navigation.pushUrl model.navKey (Url.toString url)
                , sendShouldBlockNavigation False
                ]
            )

        UserAcceptedBlockedNavigationWarning ->
            ( { model | blockedNavigation = UnBlocked }, Cmd.none )

        ToggleUnsavedChanges ->
            ( { model | shouldBlockNavigation = not model.shouldBlockNavigation }
            , sendShouldBlockNavigation (not model.shouldBlockNavigation)
            )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Unsaved changes example"
    , body =
        [ main_ []
            [ viewSidebar
            , div []
                [ viewPage model
                , p
                    [ classList
                        [ ( "red", model.shouldBlockNavigation )
                        , ( "green", not model.shouldBlockNavigation )
                        ]
                    ]
                    [ if model.shouldBlockNavigation then
                        text "There are \"unsaved changes\". Navigation is blocked."

                      else
                        text "No \"unsaved changes\". Navigation is unblocked."
                    ]
                , toggleUnsavedChangesButton model.shouldBlockNavigation
                ]
            , viewBlockedNavigationModal model.blockedNavigation
            ]
        ]
    }


viewSidebar : Html Msg
viewSidebar =
    nav []
        [ ul []
            [ li [] [ a [ href (Route.toUrl Home) ] [ text "Home" ] ]
            , li [] [ a [ href (Route.toUrl Blue) ] [ text "Blue" ] ]
            , li [] [ a [ href (Route.toUrl Green) ] [ text "Green" ] ]
            , li [] [ a [ href (Route.toUrl Yellow) ] [ text "Yellow" ] ]
            , li [] [ a [ href (Route.toUrl Red) ] [ text "Red" ] ]
            ]
        ]


viewPage : Model -> Html Msg
viewPage model =
    case model.route of
        Home ->
            h1 [] [ text "Home" ]

        Blue ->
            h1 [ class "blue" ] [ text "Blue route" ]

        Green ->
            h1 [ class "green" ] [ text "Green route" ]

        Yellow ->
            h1 [ class "yellow" ] [ text "Yellow route" ]

        Red ->
            h1 [ class "red" ] [ text "Red route" ]


toggleUnsavedChangesButton : Bool -> Html Msg
toggleUnsavedChangesButton shouldBlockNavigation =
    button [ onClick ToggleUnsavedChanges ]
        [ text
            (if shouldBlockNavigation then
                "Unblock"

             else
                "Block navigation"
            )
        ]


viewBlockedNavigationModal : BlockedNavigation -> Html Msg
viewBlockedNavigationModal blockedNavigation =
    case blockedNavigation of
        UnBlocked ->
            text ""

        Blocked url ->
            div [ class "modal" ]
                [ div [ class "modal__content" ]
                    [ h2 [] [ text "Unsaved changes" ]
                    , p []
                        [ text "You have unsaved changes. Are you sure you want to leave this page?" ]
                    , div
                        [ class "buttons" ]
                        [ button
                            [ class "button-secondary"
                            , onClick (UserRejectedBlockedNavigationWarning url)
                            ]
                            [ text "Yes, I'm sure" ]
                        , button
                            [ class "button-primary"
                            , onClick UserAcceptedBlockedNavigationWarning
                            ]
                            [ text "No, review changes" ]
                        ]
                    ]
                ]
