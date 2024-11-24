module Main exposing (main)

import Array
import Browser
import Browser.Events
import Game
import Helpers
import Html
import Html.Attributes
import Json.Decode as Decode


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type Msg
    = Game Game.Msg
    | OnVisibilityChange Browser.Events.Visibility


type alias Model =
    { gameModel : Game.Model }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map Game (Game.subscriptions model.gameModel)
        , Browser.Events.onKeyDown (Decode.map (\s -> Game (Game.OnKeyDown s)) (Decode.field "key" Decode.string))
        , Browser.Events.onVisibilityChange OnVisibilityChange
        ]


type alias Flags =
    { hidden : Bool }


init : Flags -> ( Model, Cmd Msg )
init flags =
    Game.init
        |> (\game ->
                ( { gameModel =
                        if flags.hidden then
                            game.model
                                |> (\m -> { m | pause = True })

                        else
                            game.model
                  }
                , Cmd.map Game game.command
                )
           )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnVisibilityChange visibility ->
            case visibility of
                Browser.Events.Visible ->
                    ( model, Cmd.none )

                Browser.Events.Hidden ->
                    ( { model | gameModel = (\m -> { m | pause = True }) model.gameModel }, Cmd.none )

        Game msgGame ->
            Game.update msgGame model.gameModel
                |> (\game ->
                        ( { model | gameModel = game.model }
                        , Cmd.map Game game.command
                        )
                   )


view : Model -> Html.Html Msg
view model =
    Html.div
        [ Html.Attributes.style "display" "flex"
        , Html.Attributes.style "justify-content" "center"
        ]
        ([ Html.node "style"
            []
            [ Html.text <|
                String.join ""
                    [ "body    {background-color: black; color: white; font-size: 16px}"
                    , ".level  {color: #24b}" -- Dark Blue
                    , ".shield {color: #900}" -- Red
                    , ".dot    {color: #540}" -- Dark Yellow
                    , ".player {color: #ff4}" -- Yellow
                    , ".ghost0 {color: #0ee}" -- Cyan
                    , ".ghost1 {color: #fa0}" -- Orange
                    , ".ghost2 {color: #f00}" -- Red
                    , ".ghost3 {color: #faa}" -- Pink
                    , ".hunt   {color: #35c}" -- Blue
                    , ".modal  {color: white; background-color: #24b}" -- Pink
                    ]
            ]
         , Html.pre []
            (Array.toList
                (model.gameModel
                    |> Game.view
                        { charToTile =
                            \index char charType ->
                                if index == 0 then
                                    Html.span [ Html.Attributes.class "level" ] [ Html.text char ]

                                else
                                    case charType of
                                        Game.TileLevelWhilePlaying ->
                                            Html.span [ Html.Attributes.class "level" ] [ Html.text char ]

                                        Game.TileLevelWhileShield ->
                                            Html.span [ Html.Attributes.class "shield" ] [ Html.text char ]

                                        Game.TileLevelWhileIdle ->
                                            Html.span [ Html.Attributes.class "dot" ] [ Html.text char ]

                                        Game.TileDot ->
                                            Html.span [ Html.Attributes.class "dot" ] [ Html.text char ]

                                        Game.TilePlayer ->
                                            Html.span [ Html.Attributes.class "player" ] [ Html.text char ]

                                        Game.TileNotVisible ->
                                            Html.text " "

                                        Game.TileModalNotVisible ->
                                            Html.span [ Html.Attributes.class "modal" ] [ Html.text " " ]

                                        Game.TileModalVisible ->
                                            Html.span [ Html.Attributes.class "modal" ] [ Html.text char ]

                                        Game.TileGhostEscaping id ->
                                            Html.span [ Html.Attributes.class ("ghost" ++ String.fromInt id) ] [ Html.text char ]

                                        Game.TileGhostHunting ->
                                            Html.span [ Html.Attributes.class "hunt" ] [ Html.text char ]

                                        Game.TileNoOp ->
                                            Html.span [ Html.Attributes.class "dot" ] [ Html.text char ]
                        , tilesToRow = \_ tiles -> Html.div [] (Array.toList tiles)
                        }
                )
            )
         ]
            ++ (if model.gameModel.debug then
                    [ Html.pre
                        [ Html.Attributes.style "color" "green"
                        , Html.Attributes.style "position" "fixed"
                        , Html.Attributes.style "left" "20px"
                        ]
                        [ Html.text <| Helpers.stringJoin "\n" (Game.debugText model.gameModel)
                        ]
                    ]

                else
                    []
               )
        )
