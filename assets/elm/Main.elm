module Main exposing (..)

import Html exposing (..)
import Navigation exposing (Location)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import UrlParser exposing (..)
import Visualization.Axis as Axis exposing (defaultOptions)
import Visualization.Scale as Scale exposing (BandConfig, BandScale, ContinuousScale, defaultBandConfig)


type Route
    = ParentCategoriesRoute
    | NotFoundRoute
    | SubCategoriesRoute String
    | ProductsRoute String


matchers : Parser (Route -> a) a
matchers =
    oneOf
        []


type alias Day =
    { name : String
    , position : ( Int, Float )
    }


parseLocation : Location -> Route
parseLocation location =
    case parseHash matchers location of
        Just route ->
            route

        Nothing ->
            NotFoundRoute


main : Program Never Model Msg
main =
    Navigation.program OnLocationChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Location -> ( Model, Cmd Msg )
init location =
    let
        currentRoute =
            parseLocation location
    in
    ( Model
        [ { name = "monday", position = ( 1, 24 ) }
        , { name = "tuesday", position = ( 2, 5 ) }
        , { name = "wednesday", position = ( 3, 5 ) }
        , { name = "thursday", position = ( 4, 24 ) }
        , { name = "friday", position = ( 5, 5 ) }
        , { name = "satruday", position = ( 6, 5 ) }
        , { name = "sunday", position = ( 7, 5 ) }
        ]
    , Cmd.none
    )


type Msg
    = Load
    | OnLocationChange Location


type alias Model =
    { days : List Day }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Load ->
            ( model, Cmd.none )

        OnLocationChange location ->
            let
                newRoute =
                    parseLocation location
            in
            ( model, Cmd.none )


w : Float
w =
    900


h : Float
h =
    450


padding : Float
padding =
    50


xScale : List Day -> BandScale Int
xScale day =
    Scale.band { defaultBandConfig | paddingInner = 0.1, paddingOuter = 0.2 }
        (day
            |> List.map
                (\day1 ->
                    Tuple.first day1.position
                )
        )
        ( 0, w - 2 * padding )



-- List.map Tuple.first day


yScale : ContinuousScale
yScale =
    Scale.linear ( 0, 24 ) ( h - 2 * padding, 0 )


xAxis : List Day -> Svg msg
xAxis model =
    Axis.axis { defaultOptions | orientation = Axis.Bottom, tickCount = 10 } (Scale.toRenderable (xScale model))


yAxis : Svg msg
yAxis =
    Axis.axis { defaultOptions | orientation = Axis.Left, tickCount = 24 } yScale


column : BandScale Int -> ( Int, Float ) -> Svg msg
column xScale ( date, value ) =
    g [ class "column" ]
        [ rect
            [ x <| toString <| Scale.convert xScale date
            , y <| toString <| Scale.convert yScale value
            , width <| toString <| Scale.bandwidth xScale
            , height <| toString <| h - Scale.convert yScale value - 2 * padding
            ]
            []
        , text_
            [ x <| toString <| Scale.convert (Scale.toRenderable xScale) date
            , y <| toString <| Scale.convert yScale value - 5
            , textAnchor "middle"
            ]
            [ Svg.text <| toString value ]
        ]


view : Model -> Html Msg
view model =
    div [] [ svgView model.days ]


svgView : List Day -> Svg msg
svgView days =
    svg [ width (toString w ++ "px"), height (toString h ++ "px") ]
        [ Svg.style [] [ Svg.text """
            .column rect { fill: #72F276; }
            .column text { display: none; }
            .column:hover rect { fill: rgb(118, 214, 78); }
            .column:hover text { display: inline; }
          """ ]
        , g [ transform ("translate(" ++ toString (padding - 1) ++ ", " ++ toString (h - padding) ++ ")") ]
            [ xAxis days ]
        , g [ transform ("translate(" ++ toString (padding - 1) ++ ", " ++ toString padding ++ ")") ]
            [ yAxis ]
        , g [ transform ("translate(" ++ toString padding ++ ", " ++ toString padding ++ ")"), class "series" ] <|
            (days
                |> List.map (\day -> column (xScale days) day.position)
            )
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
