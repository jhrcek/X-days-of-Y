{- | "17 Days of psql": the course metadata, and the days in order.

The lessons themselves live in "Course.Day".
-}
module Courses.Psql (course) where

import Course.Types
import Lucid

import Course.Day.D01 qualified as D01
import Course.Day.D02 qualified as D02
import Course.Day.D03 qualified as D03
import Course.Day.D04 qualified as D04
import Course.Day.D05 qualified as D05
import Course.Day.D06 qualified as D06
import Course.Day.D07 qualified as D07
import Course.Day.D08 qualified as D08
import Course.Day.D09 qualified as D09
import Course.Day.D10 qualified as D10
import Course.Day.D11 qualified as D11
import Course.Day.D12 qualified as D12
import Course.Day.D13 qualified as D13
import Course.Day.D14 qualified as D14
import Course.Day.D15 qualified as D15
import Course.Day.D16 qualified as D16
import Course.Day.D17 qualified as D17

course :: Course
course =
    Course
        { courseSlug = "psql"
        , courseTool = "psql"
        , courseManRef = "psql(1)"
        , courseVersion = "psql 18.6"
        , courseTagline = do
            "From "
            em_ "“I can get a prompt and type SELECT”"
            " to conditional scripts, generated SQL, pipelined protocol tests and a "
            code_ "~/.psqlrc"
            " you can defend line by line. One sitting a day, each small enough to actually use \
            \at work the same afternoon."
        , courseHowTo =
            [
                ( "One sitting a day"
                , do
                    "Each lesson introduces one idea and stops. The drills at the bottom are the \
                    \actual lesson — reading that "
                    code_ "\\gexec"
                    " runs its own output teaches you nothing until you have watched it create four \
                    \indexes. Do the drills in whatever work you were going to do anyway."
                )
            ,
                ( "Get a server to break"
                , do
                    "Several days ask you to break something on purpose, so you want a database \
                    \that is yours and disposable rather than one your colleagues rely on. If you \
                    \have only the client — which is what a distribution's "
                    code_ "postgresql"
                    " package often gives you — then "
                    a_ [href_ "day_02/"] "Day 2"
                    " opens with one "
                    code_ "docker run"
                    " that gives you a throwaway PostgreSQL 18, in RAM, plus the few tables the \
                    \examples here use. Set it up before Day 1's drills rather than after."
                )
            ,
                ( "Build your own psqlrc"
                , do
                    "From Day 6 each lesson adds a few justified lines to "
                    code_ "~/.psqlrc"
                    ". Nothing is pasted from a stranger's dotfiles: by Day 17 you can say why every \
                    \line is there. The finished file is "
                    a_ [href_ "psqlrc"] "here"
                    "."
                )
            ]
        , courseLeftOut = do
            "SQL itself. This is a course about the client, and it assumes you can already write \
            \the queries you want to run. Beyond that: the Windows console code-page notes, the "
            code_ "latex"
            ", "
            code_ "latex-longtable"
            ", "
            code_ "troff-ms"
            " and "
            code_ "asciidoc"
            " output formats, the two variables the manual page itself calls “mainly useful for \
            \regression tests”, LDAP lookup of connection parameters, and the specialist corners \
            \of the describe family — access methods and operator classes ("
            code_ "\\dA"
            "…), text search ("
            code_ "\\dF"
            "…), foreign data wrappers ("
            code_ "\\de"
            "…) and replication ("
            code_ "\\dRp"
            ", "
            code_ "\\dRs"
            "). Day 3 teaches the naming scheme that generates all 45 of them and "
            code_ "\\?"
            " lists the rest, so by Day 17 you can read the manual page for any of it unaided — \
            \which is the real skill on offer."
        , courseCardBlurb = do
            "From “I can get a prompt and type SELECT” to the pattern language, "
            code_ "\\copy"
            ", generated SQL, conditional scripts and pipelining — plus a "
            code_ "~/.psqlrc"
            " you build line by line and can defend."
        , courseCardTags = ["17 lessons", "~30 min each", "psql 18.6"]
        , courseConfig =
            Just
                ConfigFile
                    { cfFileName = "psqlrc"
                    , cfUserPath = "~/.psqlrc"
                    , cfComment = "--"
                    , cfReloadHint = do
                        "psql reads this once at start-up, after connecting. Re-read it in place \
                        \with "
                        code_ "\\i ~/.psqlrc"
                        "."
                    , cfHeader =
                        [ "-- ~/.psqlrc"
                        , "--"
                        , "-- Assembled over the '17 Days of psql' course. Every line was introduced with"
                        , "-- a reason, and the comments are that reason. psql reads this file once, after"
                        , "-- connecting, so it may use \\set, \\pset and SET freely. Re-read it with:"
                        , "--"
                        , "--     \\i ~/.psqlrc"
                        , "--"
                        , "-- Start psql with -X to skip it entirely, which is what scripts should do."
                        , "--"
                        ]
                    }
        , courseDays =
            [ D01.day
            , D02.day
            , D03.day
            , D04.day
            , D05.day
            , D06.day
            , D07.day
            , D08.day
            , D09.day
            , D10.day
            , D11.day
            , D12.day
            , D13.day
            , D14.day
            , D15.day
            , D16.day
            , D17.day
            ]
        }
