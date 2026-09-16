{- | "10 Days of grep": the course metadata, and the days in order.

The lessons themselves live in "Course.Day". grep has no configuration file —
@GREP_OPTIONS@ was removed years ago and is silently ignored by 3.12 — so
'courseConfig' is 'Nothing' and the days build up a recipes file instead.
-}
module Courses.Grep (course) where

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

course :: Course
course =
    Course
        { courseSlug = "grep"
        , courseTool = "grep"
        , courseManRef = "grep(1)"
        , courseVersion = "GNU grep 3.12"
        , courseTagline = do
            "From "
            em_ "“I pipe things into it until something looks right”"
            " to writing a pattern you can defend, in the dialect you meant, over the files you \
            \meant, with an exit status the rest of the script can trust. One sitting a day, each \
            \small enough to actually use at work the same afternoon."
        , courseHowTo =
            [
                ( "One sitting a day"
                , do
                    "Each lesson introduces one idea and stops. The drills at the bottom are the \
                    \actual lesson: grep is muscle memory built on a small amount of theory, and \
                    \reading about "
                    code_ "-o"
                    " teaches you nothing. Do them against files already on your own disk."
                )
            ,
                ( "Check the exit status, not the output"
                , do
                    "From Day 1, get into the habit of typing "
                    code_ "echo $?"
                    " after a grep that printed nothing. The difference between "
                    em_ "no match"
                    " and "
                    em_ "something went wrong"
                    " is invisible on screen and is the single largest source of silently broken \
                    \shell scripts."
                )
            ,
                ( "Build a recipes file"
                , do
                    "grep has no configuration file and no dotfile: "
                    code_ "GREP_OPTIONS"
                    " was removed and 3.12 ignores it without a word. What you accumulate instead \
                    \is a file of invocations. Each day ends with a line or two for "
                    code_ "~/grep-recipes.sh"
                    ", always with the reason as a comment, and Day 10 asks you to delete every \
                    \line you can no longer defend."
                )
            ]
        , courseLeftOut = do
            "The full PCRE language. Day 10 covers what "
            code_ "-P"
            " buys you and where it bites, but the syntax itself is "
            code_ "pcre2syntax(3)"
            " and that page does it better. The complete "
            code_ "GREP_COLORS"
            " capability list and the SGR numbers behind it are named on Day 5 and then left to \
            \the manual — it is a lookup table, not a concept. "
            code_ "-U/--binary"
            " is skipped because the page itself says it has no effect outside MS-DOS and \
            \Windows, and "
            code_ "-D/--devices"
            " gets one line. Nothing here teaches "
            code_ "sed"
            " or "
            code_ "awk"
            ", though Day 10 is explicit about the point where you should stop reaching for grep \
            \and pick one of them up."
        , courseCardBlurb = do
            "From "
            code_ "ps aux | grep"
            "-grade guesswork to patterns you can defend: why "
            code_ "grep 'a+b'"
            " does not mean what you think, what "
            code_ "-w"
            " actually tests, why a perfectly good text file is reported as binary, and the three \
            \things the manual page promises that the binary does not do."
        , courseCardTags = ["10 lessons", "~30 min each", "GNU grep 3.12"]
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
            , D10.day
            ]
        }
