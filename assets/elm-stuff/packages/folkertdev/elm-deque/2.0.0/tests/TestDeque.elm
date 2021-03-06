module TestDeque exposing (..)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string, unit)
import Deque exposing (Deque, fromList, toList, pushFront, pushBack)
import Tuple exposing (second)


deque : Fuzz.Fuzzer a -> Fuzz.Fuzzer (Deque a)
deque =
    Fuzz.map fromList << list


construction : Test
construction =
    describe "Construction"
        [ fuzz (deque int) "push << pop == identity; front" <|
            \ints ->
                (Deque.pushFront 1 >> Deque.popFront >> second >> toList) ints
                    |> Expect.equal (toList ints)
        , fuzz (deque int) "push << pop == identity; back" <|
            \ints ->
                (Deque.pushBack 1 >> Deque.popBack >> second >> toList) ints
                    |> Expect.equal (toList ints)
        , fuzz (list int) "fromList << pushLeft v << toList == v ::" <|
            \ints ->
                (fromList >> pushFront 42 >> toList) ints
                    |> Expect.equal (42 :: ints)
        , fuzz (list int) "fromList << pushRight v << toList == (\\l -> l ++ [v]" <|
            \ints ->
                (fromList >> pushBack 42 >> toList) ints
                    |> Expect.equal (ints ++ [ 42 ])
        , fuzz (tuple ( deque unit, unit )) "lenth (pushFront x deque) == 1 + length deque" <|
            \( deque, element ) ->
                let
                    given =
                        deque
                            |> Deque.pushFront element
                            |> Deque.length

                    expected =
                        1 + Deque.length deque
                in
                    given
                        |> Expect.equal expected
        , fuzz (tuple ( deque unit, unit )) "lenth (pushBack x deque) == 1 + length deque" <|
            \( deque, element ) ->
                let
                    given =
                        deque
                            |> Deque.pushBack element
                            |> Deque.length

                    expected =
                        1 + Deque.length deque
                in
                    given
                        |> Expect.equal expected
        , fuzz (tuple ( deque int, int )) "last (pushBack x deque) == Just x" <|
            \( deque, element ) ->
                let
                    given =
                        deque
                            |> Deque.pushBack element
                            |> Deque.last

                    expected =
                        Just element
                in
                    given
                        |> Expect.equal expected
        , fuzz (tuple ( deque int, int )) "first (pushFront x deque) == Just x" <|
            \( deque, element ) ->
                let
                    given =
                        deque
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
                toList (fromList ints)
                    |> Expect.equal ints
        , fuzz (deque unit) "toList << fromList == identity" <|
            \ints ->
                fromList (toList ints)
                    |> Expect.equal ints
        ]
