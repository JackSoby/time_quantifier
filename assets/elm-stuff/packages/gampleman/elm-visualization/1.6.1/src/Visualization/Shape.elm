module Visualization.Shape
    exposing
        ( line
        , lineRadial
        , area
        , areaRadial
        , linearCurve
        , basisCurveOpen
        , basisCurve
        , basisCurveClosed
        , bundleCurve
        , cardinalCurve
        , cardinalCurveClosed
        , cardinalCurveOpen
        , catmullRomCurve
        , catmullRomCurveClosed
        , catmullRomCurveOpen
        , monotoneInXCurve
        , monotoneInYCurve
        , stepCurve
        , naturalCurve
        , Curve
        , pie
        , Arc
        , arc
        , centroid
        , defaultPieConfig
        , PieConfig
        , stackOffsetNone
        , stackOffsetDiverging
        , stackOffsetExpand
        , stackOffsetSilhouette
        , stackOffsetWiggle
        , sortByInsideOut
        , StackConfig
        , StackResult
        , stack
        )

{-| Visualizations typically consist of discrete graphical marks, such as symbols,
arcs, lines and areas. While the rectangles of a bar chart may be easy enough to
generate directly using SVG or Canvas, other shapes are complex, such as rounded
annular sectors and centripetal Catmull–Rom splines. This module provides a
variety of shape generators for your convenience.


# Arcs

[![Pie Chart](http://code.gampleman.eu/elm-visualization/PieChart/preview.png)](http://code.gampleman.eu/elm-visualization/PieChart/)

@docs arc, Arc, centroid


# Pies

@docs PieConfig, pie, defaultPieConfig


# Lines

[![Line Chart](http://code.gampleman.eu/elm-visualization/LineChart/preview.png)](http://code.gampleman.eu/elm-visualization/LineChart/)

@docs line, lineRadial, area, areaRadial


# Curves

While lines are defined as a sequence of two-dimensional [x, y] points, and areas are similarly
defined by a topline and a baseline, there remains the task of transforming this discrete representation
into a continuous shape: i.e., how to interpolate between the points. A variety of curves are provided for this purpose.

@docs Curve, linearCurve
@docs basisCurve, basisCurveClosed, basisCurveOpen
@docs bundleCurve
@docs cardinalCurve, cardinalCurveClosed, cardinalCurveOpen
@docs catmullRomCurve, catmullRomCurveClosed, catmullRomCurveOpen
@docs monotoneInXCurve, monotoneInYCurve
@docs stepCurve, naturalCurve


# Stack

A stack is a way to fit multiple graphs into one drawing. Rather than drawing graphs on top of each other,
the layers are stacked. This is useful when the relation between the graphs is of interest.

In most cases, the absolute size of a piece of data becomes harder to determine for the reader.

@docs StackConfig, StackResult, stack


## Stack Offset

The method of stacking.

@docs stackOffsetNone , stackOffsetDiverging , stackOffsetExpand , stackOffsetSilhouette , stackOffsetWiggle


## Stack Order

The order of the layers. Normal list functions can be used, for instance

    -- keep order of the input data
    identity

    -- reverse
    List.reverse

    -- decreasing by sum of the values (largest is lowest)
    List.sortBy (Tuple.second >> List.sum >> negate)

@docs sortByInsideOut

-}

import Curve
import SubPath exposing (SubPath)
import Vector2 exposing (Float2)
import Visualization.Path.Conversion exposing (subpathToVizPath)
import Visualization.Shape.Generators
import Visualization.Shape.Pie
import Visualization.Shape.Stack
import Visualization.Path as Path exposing (..)


{-| Used to configure an `arc`. These can be generated by a `pie`, but you can
easily modify these later.


## innerRadius : Float

Usefull for creating a donut chart. A negative value is treated as zero. If larger
than `outerRadius` they are swapped.


## outerRadius : Float

The radius of the arc. A negative value is treated as zero. If smaller
than `innerRadius` they are swapped.


## cornerRadius : Float

If the corner radius is greater than zero, the corners of the arc are rounded
using circles of the given radius. For a circular sector, the two outer corners
are rounded; for an annular sector, all four corners are rounded. The corner
circles are shown in this diagram:

[![Corner Radius](http://code.gampleman.eu/elm-visualization/CornerRadius/preview.png)](http://code.gampleman.eu/elm-visualization/CornerRadius/)

The corner radius may not be larger than `(outerRadius - innerRadius) / 2`.
In addition, for arcs whose angular span is less than π, the corner radius may
be reduced as two adjacent rounded corners intersect. This is occurs more often
with the inner corners.


## startAngle : Float

The angle is specified in radians, with 0 at -y (12 o’clock) and positive angles
proceeding clockwise. If |endAngle - startAngle| ≥ τ, a complete circle or
annulus is generated rather than a sector.


## endAngle : Float

The angle is specified in radians, with 0 at -y (12 o’clock) and positive angles
proceeding clockwise. If |endAngle - startAngle| ≥ τ, a complete circle or annulus
is generated rather than a sector.


## padAngle : Float

The pad angle is converted to a fixed linear distance separating adjacent arcs,
defined as padRadius * padAngle. This distance is subtracted equally from the
start and end of the arc. If the arc forms a complete circle or annulus,
as when |endAngle - startAngle| ≥ τ, the pad angle is ignored.

If the inner radius or angular span is small relative to the pad angle, it may
not be possible to maintain parallel edges between adjacent arcs. In this case,
the inner edge of the arc may collapse to a point, similar to a circular sector.
For this reason, padding is typically only applied to annular sectors
(i.e., when innerRadius is positive), as shown in this diagram:

[![Pad Angle](http://code.gampleman.eu/elm-visualization/PadAngle/preview.png)](http://code.gampleman.eu/elm-visualization/PadAngle/)

The recommended minimum inner radius when using padding is outerRadius * padAngle / sin(θ),
where θ is the angular span of the smallest arc before padding. For example,
if the outer radius is 200 pixels and the pad angle is 0.02 radians,
a reasonable θ is 0.04 radians, and a reasonable inner radius is 100 pixels.

Often, the pad angle is not set directly on the arc generator, but is instead
computed by the pie generator so as to ensure that the area of padded arcs is
proportional to their value.
If you apply a constant pad angle to the arc generator directly, it tends to
subtract disproportionately from smaller arcs, introducing distortion.


## padRadius : Float

The pad radius determines the fixed linear distance separating adjacent arcs,
defined as padRadius * padAngle.

-}
type alias Arc =
    { innerRadius : Float
    , outerRadius : Float
    , cornerRadius : Float
    , startAngle : Float
    , endAngle : Float
    , padAngle : Float
    , padRadius : Float
    }


{-| The arc generator produces a [circular](https://en.wikipedia.org/wiki/Circular_sector)
or [annular] sector, as in
a pie or donut chart. If the difference between the start and end angles (the
angular span) is greater than [τ][tau],
the arc generator will produce a complete circle or annulus. If it is less than
[τ][tau], arcs may have
rounded corners and angular padding. Arcs are always centered at ⟨0,0⟩; use a
transform to move the arc to a different position.

See also the pie generator, which computes the necessary angles to represent an
array of data as a pie or donut chart; these angles can then be passed to an arc
generator.

This will produce a string suitable to being passed into the `d` attribute of an
SVG `path` element.

[annular]: https://en.wikipedia.org/wiki/Annulus_(mathematics)
[tau]: https://en.wikipedia.org/wiki/Turn_(geometry)#Tau_proposal

-}
arc : Arc -> String
arc =
    Visualization.Shape.Pie.arc


{-| Computes the midpoint (x, y) of the center line of the arc that would be
generated by the given arguments. The midpoint is defined as
(startAngle + endAngle) / 2 and (innerRadius + outerRadius) / 2. For example:

[![Centroid](http://code.gampleman.eu/elm-visualization/Centroid/preview.png)](http://code.gampleman.eu/elm-visualization/Centroid/)

Note that this is not the geometric center of the arc, which may be outside the arc;
this function is merely a convenience for positioning labels.

-}
centroid : Arc -> Point
centroid =
    Visualization.Shape.Pie.centroid


{-| Used to configure a `pie` generator function.

`innerRadius`, `outerRadius`, `cornerRadius` and `padRadius` are simply forwarded
to the `Arc` result. They are provided here simply for convenience.


## valueFn : a -> Float

This is used to compute the actual numerical value used for computing the angles.
You may use a `List.map` to preprocess data into numbers instead, but this is
useful if trying to use `sortingFn`.


## sortingFn : a -> a -> Order

Sorts the data. Sorting does not affect the order of the generated arc list,
which is always in the same order as the input data list; it merely affects
the computed angles of each arc. The first arc starts at the start angle and the
last arc ends at the end angle.


## startAngle : Float

The start angle here means the overall start angle of the pie, i.e., the start
angle of the first arc. The units of angle are arbitrary, but if you plan to use
the pie generator in conjunction with an arc generator, you should specify an
angle in radians, with 0 at -y (12 o’clock) and positive angles proceeding clockwise.


## endAngle : Float

The end angle here means the overall end angle of the pie, i.e., the end angle
of the last arc. The units of angle are arbitrary, but if you plan to use the
pie generator in conjunction with an arc generator, you should specify an angle
in radians, with 0 at -y (12 o’clock) and positive angles proceeding clockwise.

The value of the end angle is constrained to startAngle ± τ, such that |endAngle - startAngle| ≤ τ.


## padAngle : Float

The pad angle here means the angular separation between each adjacent arc. The
total amount of padding reserved is the specified angle times the number of
elements in the input data list, and at most |endAngle - startAngle|; the
remaining space is then divided proportionally by value such that the relative
area of each arc is preserved.

-}
type alias PieConfig a =
    { startAngle : Float
    , endAngle : Float
    , padAngle : Float
    , sortingFn : a -> a -> Order
    , valueFn : a -> Float
    , innerRadius : Float
    , outerRadius : Float
    , cornerRadius : Float
    , padRadius : Float
    }


{-| The default config for generating pies.

    import Visualization.Shape as Shape exposing (defaultPieConfig)

    pieData =
        Shape.pie { defaultPieConfig | outerRadius = 230 } model

Note that if you change `valueFn`, you will likely also want to change `sortingFn`.

-}
defaultPieConfig : PieConfig Float
defaultPieConfig =
    { startAngle = 0
    , endAngle = 2 * pi
    , padAngle = 0
    , sortingFn = Basics.compare
    , valueFn = identity
    , innerRadius = 0
    , outerRadius = 100
    , cornerRadius = 0
    , padRadius = 0
    }


{-| The pie generator does not produce a shape directly, but instead computes
the necessary angles to represent a tabular dataset as a pie or donut chart;
these angles can then be passed to an `arc` generator.
-}
pie : PieConfig a -> List a -> List Arc
pie =
    Visualization.Shape.Pie.pie


type alias Point =
    ( Float, Float )


{-| A curve is represented as a list of points, which a curve function can turn
into drawing commands.

*Note*: The intention is to eventually open this type so that custom curves may
be implemented, but I will first implement a number of curves to make sure the
type makes sense.

-}
type Curve
    = Curve (List Point)


adapter : (List Float2 -> SubPath) -> Curve -> List PathSegment
adapter curveFn (Curve points) =
    curveFn points |> subpathToVizPath


{-| Produces a polyline through the specified points.

<a href="http://code.gampleman.eu/elm-visualization/Curves/"><img style="max-width: 100%" src="http://code.gampleman.eu/elm-visualization/Curves/linear@2x.png" alt="linear curve illustration" /></a>

-}
linearCurve : Curve -> List PathSegment
linearCurve =
    adapter Curve.linear


{-| Produces a cubic [basis spline](https://en.wikipedia.org/wiki/B-spline) using the specified control points.
The first and last points are triplicated such that the spline starts at the first point and ends at the last
point, and is tangent to the line between the first and second points, and to the line between the penultimate
and last points.

<a href="http://code.gampleman.eu/elm-visualization/Curves/"><img style="max-width: 100%" src="http://code.gampleman.eu/elm-visualization/Curves/basis@2x.png" alt="basis curve illustration" /></a>

-}
basisCurve : Curve -> List PathSegment
basisCurve =
    adapter Curve.basis


{-| Produces a closed cubic basis spline using the specified control points. When a line segment ends, the first three control points are repeated, producing a closed loop with C2 continuity.

<a href="http://code.gampleman.eu/elm-visualization/Curves/"><img style="max-width: 100%" src="http://code.gampleman.eu/elm-visualization/Curves/basisclosed@2x.png" alt="closed basis curve illustration" /></a>

-}
basisCurveClosed : Curve -> List PathSegment
basisCurveClosed =
    adapter Curve.basisClosed


{-| Produces a cubic basis spline using the specified control points. Unlike basis, the first and last points are not repeated, and thus the curve typically does not intersect these points.

<a href="http://code.gampleman.eu/elm-visualization/Curves/"><img style="max-width: 100%" src="http://code.gampleman.eu/elm-visualization/Curves/basisopen@2x.png" alt="open basis curve illustration" /></a>

-}
basisCurveOpen : Curve -> List PathSegment
basisCurveOpen =
    adapter Curve.basisOpen


{-| Produces a straightened cubic [basis spline](https://en.wikipedia.org/wiki/B-spline) using the specified control points,
with the spline straightened according to the curve’s beta (a reasonable default is `0.85`). This curve is typically
used in hierarchical edge bundling to disambiguate connections, as proposed by [Danny Holten](https://www.win.tue.nl/vis1/home/dholten/)
in [Hierarchical Edge Bundles: Visualization of Adjacency Relations in Hierarchical Data](https://www.win.tue.nl/vis1/home/dholten/papers/bundles_infovis.pdf).

This curve is not suitable to be used with areas.

<a href="http://code.gampleman.eu/elm-visualization/Curves/"><img style="max-width: 100%" src="http://code.gampleman.eu/elm-visualization/Curves/bundle@2x.png" alt="bundle curve illustration" /></a>

-}
bundleCurve : Float -> Curve -> List PathSegment
bundleCurve beta =
    adapter (Curve.bundle (clamp 0 1 beta))


{-| Produces a cubic [cardinal spline](https://en.wikipedia.org/wiki/Cubic_Hermite_spline#Cardinal_spline) using
the specified control points, with one-sided differences used for the first and last piece.

The tension parameter determines the length of the tangents: a tension of one yields all zero tangents, equivalent to
`linearCurve`; a tension of zero produces a uniform Catmull–Rom spline.

<a href="http://code.gampleman.eu/elm-visualization/Curves/"><img style="max-width: 100%" src="http://code.gampleman.eu/elm-visualization/Curves/cardinal@2x.png" alt="cardinal curve illustration" /></a>

-}
cardinalCurve : Float -> Curve -> List PathSegment
cardinalCurve tension =
    adapter (Curve.cardinal (clamp 0 1 tension))


{-| Produces a cubic [cardinal spline](https://en.wikipedia.org/wiki/Cubic_Hermite_spline#Cardinal_spline) using
the specified control points. At the end, the first three control points are repeated, producing a closed loop.

The tension parameter determines the length of the tangents: a tension of one yields all zero tangents, equivalent to
`linearCurve`; a tension of zero produces a uniform Catmull–Rom spline.

<a href="http://code.gampleman.eu/elm-visualization/Curves/"><img style="max-width: 100%" src="http://code.gampleman.eu/elm-visualization/Curves/cardinalclosed@2x.png" alt="cardinal closed curve illustration" /></a>

-}
cardinalCurveClosed : Float -> Curve -> List PathSegment
cardinalCurveClosed tension =
    adapter (Curve.cardinalClosed (clamp 0 1 tension))


{-| Produces a cubic [cardinal spline](https://en.wikipedia.org/wiki/Cubic_Hermite_spline#Cardinal_spline) using
the specified control points. Unlike curveCardinal, one-sided differences are not used for the first and last piece, and thus the curve starts at the second point and ends at the penultimate point.

The tension parameter determines the length of the tangents: a tension of one yields all zero tangents, equivalent to
`linearCurve`; a tension of zero produces a uniform Catmull–Rom spline.

<a href="http://code.gampleman.eu/elm-visualization/Curves/"><img style="max-width: 100%" src="http://code.gampleman.eu/elm-visualization/Curves/cardinalopen@2x.png" alt="cardinal open curve illustration" /></a>

-}
cardinalCurveOpen : Float -> Curve -> List PathSegment
cardinalCurveOpen tension =
    adapter (Curve.cardinalOpen (clamp 0 1 tension))


{-| Produces a cubic Catmull–Rom spline using the specified control points and the parameter alpha (a good default is 0.5),
as proposed by Yuksel et al. in [On the Parameterization of Catmull–Rom Curves](http://www.cemyuksel.com/research/catmullrom_param/),
with one-sided differences used for the first and last piece.

If alpha is zero, produces a uniform spline, equivalent to `curveCardinal` with a tension of zero; if alpha is one,
produces a chordal spline; if alpha is 0.5, produces a [centripetal spline](https://en.wikipedia.org/wiki/Centripetal_Catmull–Rom_spline).
Centripetal splines are recommended to avoid self-intersections and overshoot.

<a href="http://code.gampleman.eu/elm-visualization/Curves/"><img style="max-width: 100%" src="http://code.gampleman.eu/elm-visualization/Curves/catmullrom@2x.png" alt="Catmul-Rom curve illustration" /></a>

-}
catmullRomCurve : Float -> Curve -> List PathSegment
catmullRomCurve alpha =
    adapter (Curve.catmullRom (clamp 0 1 alpha))


{-| Produces a cubic Catmull–Rom spline using the specified control points and the parameter alpha (a good default is 0.5),
as proposed by Yuksel et al. When a line segment ends, the first three control points are repeated, producing a closed loop.

If alpha is zero, produces a uniform spline, equivalent to `curveCardinal` with a tension of zero; if alpha is one,
produces a chordal spline; if alpha is 0.5, produces a [centripetal spline](https://en.wikipedia.org/wiki/Centripetal_Catmull–Rom_spline).
Centripetal splines are recommended to avoid self-intersections and overshoot.

<a href="http://code.gampleman.eu/elm-visualization/Curves/"><img style="max-width: 100%" src="http://code.gampleman.eu/elm-visualization/Curves/catmullromclosed@2x.png" alt="Catmul-Rom closed curve illustration" /></a>

-}
catmullRomCurveClosed : Float -> Curve -> List PathSegment
catmullRomCurveClosed alpha =
    adapter (Curve.catmullRomClosed (clamp 0 1 alpha))


{-| Produces a cubic Catmull–Rom spline using the specified control points and the parameter alpha (a good default is 0.5),
as proposed by Yuksel et al. Unlike curveCatmullRom, one-sided differences are not used for the first and last piece, and thus the curve starts at the second point and ends at the penultimate point.

If alpha is zero, produces a uniform spline, equivalent to `curveCardinal` with a tension of zero; if alpha is one,
produces a chordal spline; if alpha is 0.5, produces a [centripetal spline](https://en.wikipedia.org/wiki/Centripetal_Catmull–Rom_spline).
Centripetal splines are recommended to avoid self-intersections and overshoot.

<a href="http://code.gampleman.eu/elm-visualization/Curves/"><img style="max-width: 100%" src="http://code.gampleman.eu/elm-visualization/Curves/catmullromopen@2x.png" alt="Catmul-Rom open curve illustration" /></a>

-}
catmullRomCurveOpen : Float -> Curve -> List PathSegment
catmullRomCurveOpen alpha =
    adapter (Curve.catmullRomOpen (clamp 0 1 alpha))


{-| Produces a cubic spline that [preserves monotonicity](http://adsabs.harvard.edu/full/1990A%26A...239..443S)
in y, assuming monotonicity in x, as proposed by Steffen in
[A simple method for monotonic interpolation in one dimension](http://adsabs.harvard.edu/full/1990A%26A...239..443S):
“a smooth curve with continuous first-order derivatives that passes through any
given set of data points without spurious oscillations. Local extrema can occur
only at grid points where they are given by the data, but not in between two adjacent grid points.”

<a href="http://code.gampleman.eu/elm-visualization/Curves/"><img style="max-width: 100%" src="http://code.gampleman.eu/elm-visualization/Curves/monotoneinx@2x.png" alt="monotone in x curve illustration" /></a>

-}
monotoneInXCurve : Curve -> List PathSegment
monotoneInXCurve =
    adapter Curve.monotoneX


{-| Produces a cubic spline that [preserves monotonicity](http://adsabs.harvard.edu/full/1990A%26A...239..443S)
in y, assuming monotonicity in y, as proposed by Steffen in
[A simple method for monotonic interpolation in one dimension](http://adsabs.harvard.edu/full/1990A%26A...239..443S):
“a smooth curve with continuous first-order derivatives that passes through any
given set of data points without spurious oscillations. Local extrema can occur
only at grid points where they are given by the data, but not in between two adjacent grid points.”
-}
monotoneInYCurve : Curve -> List PathSegment
monotoneInYCurve =
    adapter Curve.monotoneY


{-| Produces a [natural](https://en.wikipedia.org/wiki/Spline_interpolation) [cubic spline](http://mathworld.wolfram.com/CubicSpline.html)
with the second derivative of the spline set to zero at the endpoints.

<a href="http://code.gampleman.eu/elm-visualization/Curves/"><img style="max-width: 100%" src="http://code.gampleman.eu/elm-visualization/Curves/natural@2x.png" alt="natural curve illustration" /></a>

-}
naturalCurve : Curve -> List PathSegment
naturalCurve =
    adapter Curve.natural


{-| Produces a piecewise constant function (a step function) consisting of alternating horizontal and vertical lines.

The factor parameter changes when the y-value changes between each pair of adjacent x-values.

<a href="http://code.gampleman.eu/elm-visualization/Curves/"><img style="max-width: 100%" src="http://code.gampleman.eu/elm-visualization/Curves/step@2x.png" alt="step curve illustration" /></a>

-}
stepCurve : Float -> Curve -> List PathSegment
stepCurve factor =
    adapter (Curve.step (clamp 0 1 factor))


{-| Generates a line for the given array of points which can be passed to the `d`
attribute of the `path` SVG element. It needs to be suplied with a curve function.
Points accepted are `Maybe`s, Nothing represent gaps in the data and corresponding
gaps will be rendered in the line.

**Note:** A single point (surrounded by Nothing) may not be visible.

Usually you will need to convert your data into a format supported by this function.
For example, if your data is a `List (Date, Float)`, you might use something like:

    lineGenerator : ( Date, Float ) -> Maybe ( Float, Float )
    lineGenerator ( x, y ) =
        Just ( Scale.convert xScale x, Scale.convert yScale y )

    linePath : List ( Date, Float ) -> String
    linePath data =
        List.map lineGenerator data
            |> Shape.line Shape.linearCurve

where `xScale` and `yScale` would be appropriate `Scale`s.

-}
line : (Curve -> List PathSegment) -> List (Maybe Point) -> String
line curve =
    Visualization.Shape.Generators.line (Curve >> curve)


{-| This works exactly like `line`, except it interprets the points it recieves as `(angle, radius)`
pairs, where radius is in *radians*. Therefore it renders a radial layout with a center at `(0, 0)`.

Use a transform to position the layout in final rendering.

-}
lineRadial : (Curve -> List PathSegment) -> List (Maybe Point) -> String
lineRadial curve =
    Visualization.Shape.Generators.line (Curve.toPolarWithCenter ( 0, 0 ) >> Curve >> curve)


{-| The area generator produces an area, as in an area chart. An area is defined
by two bounding lines, either splines or polylines. Typically, the two lines
share the same x-values (x0 = x1), differing only in y-value (y0 and y1);
most commonly, y0 is defined as a constant representing zero. The first line
(the topline) is defined by x1 and y1 and is rendered first; the second line
(the baseline) is defined by x0 and y0 and is rendered second, with the points
in reverse order. With a `linearCurve` curve, this produces a clockwise polygon.

The data attribute you pass in should be a `[Just ((x0, y0), (x1, y1))]`. Passing
in `Nothing` represents gaps in the data and corresponding gaps in the area will
be rendered.

Usually you will need to convert your data into a format supported by this function.
For example, if your data is a `List (Date, Float)`, you might use something like:

    areaGenerator : ( Date, Float ) -> Maybe ( ( Float, Float ), ( Float, Float ) )
    areaGenerator ( x, y ) =
        Just
            ( ( Scale.convert xScale x, Tuple.first (Scale.rangeExtent yScale) )
            , ( Scale.convert xScale x, Scale.convert yScale y )
            )

    areaPath : List ( Date, Float ) -> String
    areaPath data =
        List.map areaGenerator data
            |> Shape.area Shape.linearCurve

where `xScale` and `yScale` would be appropriate `Scale`s.

-}
area : (Curve -> List PathSegment) -> List (Maybe ( Point, Point )) -> String
area curve =
    Visualization.Shape.Generators.area (Curve >> curve)


{-| This works exactly like `area`, except it interprets the points it recieves as `(angle, radius)`
pairs, where radius is in *radians*. Therefore it renders a radial layout with a center at `(0, 0)`.

Use a transform to position the layout in final rendering.

-}
areaRadial : (Curve -> List PathSegment) -> List (Maybe ( Point, Point )) -> String
areaRadial curve =
    Visualization.Shape.Generators.area (Curve.toPolarWithCenter ( 0, 0 ) >> Curve >> curve)



--- STACK


{-| Configuration for a stacked chart.

  - `data`: List of values with an accompanying label.
  - `offset`: How to stack the layers on top of each other.
  - `order`: sorting function to determine the order of the layers.

Some example configs:

    stackedBarChart : StackConfig String
    stackedBarChart =
        { data = myData
        , offset = Shape.stackOffsetNone
        , order =
            -- stylistic choice: largest (by sum of values)
            -- category at the bottom
            List.sortBy (Tuple.second >> List.sum >> negate)
        }

    streamgraph : StackConfig String
    streamgraph =
        { data = myData
        , offset = Shape.stackOffsetWiggle
        , order = Shape.sortByInsideOut (Tuple.second >> List.sum)
        }

-}
type alias StackConfig a =
    { data : List ( a, List Float )
    , offset : List (List ( Float, Float )) -> List (List ( Float, Float ))
    , order : List ( a, List Float ) -> List ( a, List Float )
    }


{-| The basis for constructing a stacked chart

  - `labels`: Sorted list of labels
  - `values`: Sorted list of values, where every item is a `(yLow, yHigh)` pair.
  - `extent`: The minimum and maximum y-value. Convenient for creating scales.

-}
type alias StackResult a =
    { values : List (List ( Float, Float ))
    , labels : List a
    , extent : ( Float, Float )
    }


{-| Create a stack result
-}
stack : StackConfig a -> StackResult a
stack =
    Visualization.Shape.Stack.computeStack


{-| <img style="max-width: 100%;" src="https://rawgit.com/folkertdev/elm-visualization/master/docs/misc/stackOffsetNone.svg" />

Stacks the values on top of each other, starting at 0.

    stackOffsetNone [ [ (0, 42) ], [ (0, 70) ] ]
                --> [ [ (0, 42) ], [ (42, 112 ) ] ]

    stackOffsetNone [ [ (0, 42) ], [ (20, 70) ] ]
                --> [ [ (0, 42) ], [ (42, 112 ) ] ]

-}
stackOffsetNone : List (List ( Float, Float )) -> List (List ( Float, Float ))
stackOffsetNone =
    Visualization.Shape.Stack.offsetNone


{-| <img style="max-width: 100%;" src="https://rawgit.com/folkertdev/elm-visualization/master/docs/misc/stackOffsetDiverging.svg" />

Positive values are stacked above zero, negative values below zero.

    stackOffsetDiverging [ [ (0, 42) ], [ (0, -24) ] ]
                --> [ [ (0, 42) ], [ (-24, 0 ) ] ]

    stackOffsetDiverging [ [ (0, 42), (0, -20) ], [ (0, -24), (0, -24) ] ]
                --> [[(0,42),(-20,0)],[(-24,0),(-44,-20)]]

-}
stackOffsetDiverging : List (List ( Float, Float )) -> List (List ( Float, Float ))
stackOffsetDiverging =
    Visualization.Shape.Stack.offsetDiverging


{-| <img style="max-width: 100%;" src="https://rawgit.com/folkertdev/elm-visualization/master/docs/misc/stackOffsetExpand.svg" />
Applies a zero baseline and normalizes the values for each point such that the topline is always one.

    stackOffsetExpand [ [ (0, 50) ], [ (50, 100) ] ]
                --> [[(0,0.5)],[(0.5,1)]]

-}
stackOffsetExpand : List (List ( Float, Float )) -> List (List ( Float, Float ))
stackOffsetExpand =
    Visualization.Shape.Stack.offsetExpand


{-| <img style="max-width: 100%;" src="https://rawgit.com/folkertdev/elm-visualization/master/docs/misc/stackOffsetSilhouette.svg" />
Shifts the baseline down such that the center of the streamgraph is always at zero.

    stackOffsetSilhouette [ [ (0, 50) ], [ (50, 100) ] ]
                --> [[(-75,-25)],[(-25,75)]]

-}
stackOffsetSilhouette : List (List ( Float, Float )) -> List (List ( Float, Float ))
stackOffsetSilhouette =
    Visualization.Shape.Stack.offsetSilhouette


{-| <img style="max-width: 100%;" src="https://rawgit.com/folkertdev/elm-visualization/master/docs/misc/stackOffsetWiggle.svg" />
Shifts the baseline so as to minimize the weighted wiggle of layers.

Visually, high wiggle means peaks going in both directions very close to each other. The silhouette stack offset above often suffers
from having high wiggle.

    stackOffsetWiggle [ [ (0, 50) ], [ (50, 100) ] ]
                --> [[(0,50)],[(50,150)]]

-}
stackOffsetWiggle : List (List ( Float, Float )) -> List (List ( Float, Float ))
stackOffsetWiggle =
    Visualization.Shape.Stack.offsetWiggle


{-| Sort such that small values are at the outer edges, and large values in the middle.

This is the recommended order for stream graphs.

-}
sortByInsideOut : (a -> Float) -> List a -> List a
sortByInsideOut =
    Visualization.Shape.Stack.sortByInsideOut
