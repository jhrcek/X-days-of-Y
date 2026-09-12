{- | "14 Days of htop": the course metadata, and the days in order.

The lessons themselves live in "Course.Day".
-}
module Courses.Htop (course) where

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

course :: Course
course =
    Course
        { courseSlug = "htop"
        , courseTool = "htop"
        , courseManRef = "htop(1)"
        , courseVersion = "htop 3.5.3"
        , courseTagline = do
            "From "
            em_ "“it is a prettier top and the bars are nice”"
            " to reading the memory columns without lying to yourself, building your own screens, \
            \and owning the config file htop would rather own itself. One sitting a day, each small \
            \enough to actually use at work the same afternoon."
        , courseHowTo =
            [
                ( "One sitting a day"
                , do
                    "Each lesson introduces a handful of concepts and stops. The drills at the \
                    \bottom are the actual lesson — htop is a reading skill, and reading about "
                    code_ "RES"
                    " teaches you nothing. Do the drills against the processes already running on \
                    \your own machine."
                )
            ,
                ( "Keep it open on a real machine"
                , do
                    "Leave htop running in a spare window from Day 1 and consult it when something \
                    \is actually slow. A tool you only open during a crisis is a tool you cannot \
                    \read during a crisis."
                )
            ,
                ( "Build your own config"
                , do
                    "From Day 9 each lesson adds a few justified lines to "
                    code_ "~/.config/htop/htoprc"
                    ". Nothing is pasted from a stranger's dotfiles: by Day 14 you can defend every \
                    \line, including the ones that stop htop rewriting the file behind your back. \
                    \The finished file is "
                    a_ [href_ "htoprc"] "here"
                    "."
                )
            ]
        , courseLeftOut =
            "pcp-htop and the Performance Co-Pilot metric universe — a different binary with its \
            \own manual page; the build-time detail behind the optional libsystemd, libsensors and \
            \libnl bindings; the internals of --drop-capabilities; and the non-Linux platform \
            \quirks the cross-platform manual page carries. By Day 14 you can read the page for \
            \those yourself — which is the real skill on offer here."
        , courseCardBlurb = do
            "From “a prettier top” to reading "
            code_ "VIRT"
            " against "
            code_ "RES"
            " against "
            code_ "PSS"
            " honestly, building purpose-built screens, and an "
            code_ "htoprc"
            " you assemble line by line and can defend."
        , courseCardTags = ["14 lessons", "~30 min each", "htop 3.5"]
        , courseConfig =
            Just
                ConfigFile
                    { cfFileName = "htoprc"
                    , cfUserPath = "~/.config/htop/htoprc"
                    , cfComment = "#"
                    , cfReloadHint = do
                        "htop reads this file "
                        b_ "once, at startup"
                        ", and there is no reload key: quit and start it again. Note that htop \
                        \rewrites the file — comments and all — on a clean exit from any session in \
                        \which you changed a setting."
                    , cfHeader =
                        [ "# ~/.config/htop/htoprc"
                        , "#"
                        , "# Assembled over Days 9-14 of the '14 Days of htop' course. Every line was"
                        , "# introduced with a reason, and the comments are that reason."
                        , "#"
                        , "# WARNING, and the reason this file is worth keeping under version control:"
                        , "# htop rewrites this path in full whenever you exit cleanly from a session"
                        , "# in which any setting changed - including plain toggles like t, K and I,"
                        , "# not just the Setup screen. The rewrite drops every comment below."
                        , "# Day 9 covers the two defences: chmod 444, or $HTOPRC pointing elsewhere."
                        , "#"
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
            ]
        }
