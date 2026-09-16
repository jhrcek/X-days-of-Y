{- | "9 Days of pgrep": the course metadata, and the days in order.

The lessons themselves live in "Course.Day". pgrep has no configuration file of
any kind, so 'courseConfig' is 'Nothing' and the days build up a recipes file in
their prose instead.
-}
module Courses.Pgrep (course) where

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

course :: Course
course =
    Course
        { courseSlug = "pgrep"
        , courseTool = "pgrep"
        , courseManRef = "pgrep(1)"
        , courseVersion = "procps-ng 4.0.7"
        , courseTagline = do
            "From "
            em_ "“it is ps aux pipe grep, with fewer keystrokes”"
            " to querying the process table by cgroup, namespace and environment, and knowing \
            \exactly which of the three verbs — list, signal, wait — you are about to apply to \
            \the result. One sitting a day, each small enough to actually use at work the same \
            \afternoon."
        , courseHowTo =
            [
                ( "One sitting a day"
                , do
                    "Each lesson introduces a handful of criteria and stops. The drills at the \
                    \bottom are the actual lesson — pgrep is a habit rather than a body of \
                    \knowledge, and reading about "
                    code_ "-f"
                    " teaches you nothing. Do them against the processes already running on your \
                    \own machine."
                )
            ,
                ( "Type it before you need it"
                , do
                    "The day you reach for pgrep in earnest is a day something is wrong and you \
                    \are in a hurry. Use it for trivial lookups from Day 1 — "
                    code_ "pgrep -a"
                    " instead of "
                    code_ "ps aux | grep"
                    ", every time — so that the muscle memory is there when the stakes are not \
                    \trivial."
                )
            ,
                ( "Build a recipes file"
                , do
                    "pgrep has no configuration file, no dotfile and no environment variables: \
                    \there is nothing to tune and nothing to get wrong. What you accumulate \
                    \instead is a file of queries. Each day ends with a line or two for "
                    code_ "~/pgrep-recipes.sh"
                    ", always with the reason as a comment, and Day 9 asks you to delete every \
                    \line you can no longer defend."
                )
            ]
        , courseLeftOut =
            do
                "Signal semantics beyond what pkill needs — "
                code_ "signal(7)"
                " is the page for that, and Day 9 points at it. The regular-expression language \
                \itself is used throughout but taught nowhere; "
                code_ "regex(7)"
                " already does it better. Nothing here covers reading process "
                em_ "state"
                " — memory, CPU, scheduling — which is "
                code_ "ps(1)"
                " and "
                code_ "htop(1)"
                " territory and has its own course in this repository. And the BSD and Solaris \
                \behaviours the portable documentation hints at are ignored entirely: this is \
                \procps-ng on Linux, checked against the binary."
        , courseCardBlurb = do
            "From "
            code_ "ps aux | grep"
            " to querying the process table properly: what the fifteen-character name costs you, \
            \what "
            code_ "-v"
            " really negates, why "
            code_ "pgrep gmain"
            " finds nothing, and the eight options the manual page forgot to mention."
        , courseCardTags = ["9 lessons", "~35 min each", "procps-ng 4.0"]
        , courseConfig = Nothing
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
            ]
        }
