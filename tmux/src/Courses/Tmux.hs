{- | "14 Days of tmux": the course metadata, and the days in order.

The lessons themselves live in "Course.Day".
-}
module Courses.Tmux (course) where

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
        { courseSlug = "tmux"
        , courseTool = "tmux"
        , courseManRef = "tmux(1)"
        , courseVersion = "tmux 3.7c"
        , courseTagline = do
            "From "
            em_ "“I know it keeps shells alive over ssh”"
            " to writing your own key tables, formats, hooks and session scripts. \
            \One sitting a day, each small enough to actually use at work the same afternoon."
        , courseHowTo =
            [
                ( "One sitting a day"
                , do
                    "Each lesson introduces a handful of concepts and stops. The drills at the \
                    \bottom are the actual lesson — tmux is muscle memory, and reading about "
                    code_ "C-b z"
                    " teaches you nothing. Do the drills inside whatever work you were going to \
                    \do anyway."
                )
            ,
                ( "Live in it from Day 1"
                , do
                    "Start every terminal session with "
                    code_ "tmux new -A -s main"
                    ". Everything after Day 1 is refinement of a habit you already have. Drop the \
                    \habit and none of this sticks."
                )
            ,
                ( "Build your own config"
                , do
                    "From Day 5 each lesson adds a few justified lines to "
                    code_ "~/.tmux.conf"
                    ". Nothing is pasted from a stranger's dotfiles: by Day 14 you can defend \
                    \every line. The finished file is "
                    a_ [href_ "tmux.conf"] "here"
                    "."
                )
            ]
        , courseLeftOut =
            "Server access control, terminfo minutiae, the deeper reaches of control \
            \mode, and the genuinely exotic flags. By Day 14 you can read the man page \
            \for those yourself — which is the real skill on offer here."
        , courseCardBlurb = do
            "From “I know it keeps shells alive over ssh” to key tables, formats, hooks and "
            "session scripts — plus a "
            code_ "~/.tmux.conf"
            " you build line by line and can defend."
        , courseCardTags = ["14 lessons", "~30 min each", "tmux 3.7"]
        , courseConfig =
            Just
                ConfigFile
                    { cfFileName = "tmux.conf"
                    , cfUserPath = "~/.tmux.conf"
                    , cfComment = "#"
                    , cfReloadHint = do
                        "Reload with "
                        code_ "tmux source-file ~/.tmux.conf"
                        " and watch for errors in the status line."
                    , cfHeader =
                        [ "# ~/.tmux.conf"
                        , "#"
                        , "# Assembled over Days 5-14 of the '14 Days of tmux' course. Every line was"
                        , "# introduced with a reason, and the comments are that reason. Reload with:"
                        , "#"
                        , "#     tmux source-file ~/.tmux.conf        (or prefix R, once Day 8 is done)"
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
