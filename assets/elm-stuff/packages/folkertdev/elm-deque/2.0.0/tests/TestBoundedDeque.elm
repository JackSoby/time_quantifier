module TestBoundedDeque exposing (..)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string, unit)
import BoundedDeque as Deque exposing (BoundedDeque, fromList, toList, pushFront, pushBack)
import Tuple exposing (second)


deque : Fuzz.Fuzzer a -> Fuzz.Fuzzer (BoundedDeque a)
deque a =
    list a
        |> Fuzz.map (\elements -> Deque.fromList (List.length elements) elements)


transforms : Fuzz.Fuzzer a -> Fuzz.Fuzzer (BoundedDeque a -> BoundedDeque a)
transforms a =
    let
        absint =
            Fuzz.map abs Fuzz.int
    in
        [ ( 1, Fuzz.map (\newSize -> Deque.resize (\_ -> newSize)) absint )
        , ( 1, Fuzz.map pushFront a )
        , ( 1, Fuzz.map pushBack a )
        , ( 1, Fuzz.map (\newSize -> Deque.toList >> Deque.fromList newSize) absint )
        , ( 1, Fuzz.map (\newSize -> Deque.toDeque >> Deque.fromDeque newSize) absint )
        , ( 1, Fuzz.map Deque.append (deque a) )
        ]
            |> Fuzz.frequency


respectsMaxSize : Test
respectsMaxSize =
    fuzz (tuple ( deque unit, Fuzz.map (List.take 10) (list (transforms unit)) )) "transforms respect that length <= maxSize" <|
        \( elements, transforms ) ->
            let
                transformed =
                    (List.foldl (<<) identity transforms) elements
            in
                Deque.length transformed
                    |> Expect.atMost (Deque.getMaxSize transformed)


construction : Test
construction =
    describe "Construction"
        [ fuzz (deque int) "non-full deque: push << pop == identity; front" <|
            \ints ->
                ints
                    |> Deque.resize (\size -> size + 1)
                    |> (Deque.pushFront 1 >> Deque.popFront >> second >> toList)
                    |> Expect.equal (toList ints)
        , fuzz (deque int) "non-full deque: push << pop == identity; back" <|
            \ints ->
                ints
                    |> Deque.resize (\size -> size + 1)
                    |> (Deque.pushBack 1 >> Deque.popBack >> second >> toList)
                    |> Expect.equal (toList ints)
        , fuzz (list int) "fromList << pushLeft v << toList == v ::" <|
            \ints ->
                (fromList (List.length ints + 1) >> pushFront 42 >> toList) ints
                    |> Expect.equal (42 :: ints)
        , fuzz (list int) "fromList << pushRight v << toList == (\\l -> l ++ [v]" <|
            \ints ->
                (fromList (List.length ints + 1) >> pushBack 42 >> toList) ints
                    |> Expect.equal (ints ++ [ 42 ])
        , fuzz (deque unit) "length distributes over toList" <|
            \deque ->
                Deque.length deque
                    |> Expect.equal (List.length (Deque.toList deque))
        , fuzz (tuple ( deque unit, unit )) "pushFront on a full deque leaves the length unchanged" <|
            \( deque, element ) ->
                let
                    given =
                        deque
                            |> Deque.pushFront element
                            |> Deque.length

                    expected =
                        Deque.length deque
                in
                    given
                        |> Expect.equal expected
        , fuzz (tuple ( deque unit, unit )) "pushFront on a non-full deque increases the length by 1" <|
            \( deque, element ) ->
                let
                    given =
                        deque
                            |> Deque.resize (\size -> size + 1)
                            |> Deque.pushFront element
                            |> Deque.length

                    expected =
                        1 + Deque.length deque
                in
                    given
                        |> Expect.equal expected
        , fuzz (tuple ( deque unit, unit )) "pushBack on a full deque leaves the length unchanged" <|
            \( deque, element ) ->
                let
                    given =
                        deque
                            |> Deque.pushBack element
                            |> Deque.length

                    expected =
                        Deque.length deque
                in
                    given
                        |> Expect.equal expected
        , fuzz (tuple ( deque unit, unit )) "pushBakc on a non-full deque increases the length by 1" <|
            \( deque, element ) ->
                let
                    given =
                        deque
                            |> Deque.resize (\size -> size + 1)
                            |> Deque.pushBack element
                            |> Deque.length

                    expected =
                        1 + Deque.length deque
                in
                    given
                        |> Expect.equal expected
        , fuzz (tuple ( deque int, int )) "non-full deque: last (pushBack x deque) == Just x" <|
            \( deque, element ) ->
                let
                    given =
                        deque
                            |> Deque.resize (\size -> size + 1)
                            |> Deque.pushBack element
                            |> Deque.last

                    expected =
                        Just element
                in
                    given
                        |> Expect.equal expected
        , fuzz (tuple ( deque int, int )) "non-full deque: first (pushFront x deque) == Just x" <|
            \( deque, element ) ->
                let
                    given =
                        deque
                            |> Deque.resize (\size -> size + 1)
                            |> Deque.pushFront element
                            |> Deque.first

                    expected =
                        Just element
                in
                    given
                        |> Expect.equal expected
        ]


append : Test
append =
    describe "Append"
        [ fuzz (tuple ( deque unit, deque unit )) "toList (append a b) == (toList a) ++ (toList b)" <|
            \( firstDeque, secondDeque ) ->
                let
                    given =
                        firstDeque
                            |> Deque.append secondDeque
                            |> Deque.toList

                    expected =
                        (Deque.toList firstDeque)
                            |> List.append (Deque.toList secondDeque)
                in
                    given
                        |> Expect.equal expected
        , fuzz (tuple ( deque unit, deque unit )) "length distributes over append: length (append a b) == length a + length b" <|
            \( firstDeque, secondDeque ) ->
                let
                    given =
                        Deque.length (firstDeque |> Deque.append secondDeque)

                    expected =
                        Deque.length firstDeque + Deque.length secondDeque
                in
                    given
                        |> Expect.equal expected
        ]


folds : Test
folds =
    describe "folds"
        [ fuzz (deque string) "foldl f d == foldl f d << toList" <|
            \strings ->
                let
                    given =
                        strings
                            |> Deque.foldl (++) ""

                    expected =
                        strings
                            |> Deque.toList
                            |> List.foldl (++) ""
                in
                    given
                        |> Expect.equal expected
        , fuzz (deque string) "foldr f d == foldr f d << toList" <|
            \strings ->
                let
                    given =
                        strings
                            |> Deque.foldr (++) ""

                    expected =
                        strings
                            |> Deque.toList
                            |> List.foldr (++) ""
                in
                    given
                        |> Expect.equal expected
        , fuzz (deque int) "map f << toList == toList << map f" <|
            \deque ->
                let
                    f x =
                        42 - x

                    given =
                        deque
                            |> Deque.map f
                            |> Deque.toList

                    expected =
                        deque
                            |> toList
                            |> List.map f
                in
                    given
                        |> Expect.equal expected
        , fuzz (deque int) "filter p << toList == toList << filter p" <|
            \deque ->
                let
                    p x =
                        x % 7 == 0

                    given =
                        deque
                            |> Deque.filter p
                            |> Deque.toList

                    expected =
                        deque
                            |> toList
                            |> List.filter p
                in
                    given
                        |> Expect.equal expected
        ]


lists : Test
lists =
    describe "FromList and ToList"
        [ fuzz (list unit) "fromList << toList == identity" <|
            \ints ->
                toList (fromList (List.length ints) ints)
                    |> Expect.equal ints
        , fuzz (deque unit) "toList << fromList == identity" <|
            \ints ->
                fromList (Deque.length ints) (toList ints)
                    |> Expect.equal ints
        , fuzz (deque unit) "toDeque << fromDeque == identity" <|
            \ints ->
                Deque.fromDeque (Deque.length ints) (Deque.toDeque ints)
                    |> Expect.equal ints
        , fuzz (tuple ( deque unit, Fuzz.int )) "x" <|
            \( elements, newSize ) ->
                let
                    transformed =
                        elements
                            |> Deque.toDeque
                            |> Deque.fromDeque (abs newSize)
                in
                    Deque.length transformed
                        |> Expect.atMost (Deque.getMaxSize transformed)
        ]
