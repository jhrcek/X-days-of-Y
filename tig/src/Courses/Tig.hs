{- | "14 Days of tig": the course metadata, and the days in order.

The lessons themselves live in "Course.Day".
-}
module Courses.Tig (course) where

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
        { courseSlug = "tig"
        , courseTool = "tig"
        , courseManRef = "tig(1)"
        , courseVersion = "tig 2.6.1"
        , courseTagline = do
            "From "
            em_ "“a nicer git log”"
            " to staging single lines, writing your own keymaps, and driving tig from external \
            \commands that know which commit you are looking at. One sitting a day, each small \
            \enough to actually use at work the same afternoon."
        , courseHowTo =
            [
                ( "One sitting a day"
                , do
                    "Each lesson introduces a handful of concepts and stops. The drills at the \
                    \bottom are the actual lesson — tig is muscle memory, and reading about "
                    code_ "u"
                    " on a diff chunk teaches you nothing. Do the drills in a repository whose \
                    \history you already know."
                )
            ,
                ( "Replace one habit on Day 1"
                , do
                    "Every time you would have typed "
                    code_ "git log"
                    ", type "
                    code_ "tig"
                    " instead. That single substitution carries the first six days; everything \
                    \after is refinement of a habit you already have."
                )
            ,
                ( "Build your own tigrc"
                , do
                    "From Day 7 each lesson adds a few justified lines to "
                    code_ "~/.tigrc"
                    ". Nothing is pasted from a stranger's dotfiles: by Day 14 you can defend \
                    \every line. The finished file is "
                    a_ [href_ "tigrc"] "here"
                    "."
                )
            ]
        , courseLeftOut =
            "The full seventy-entry colour-area table, the complete list of browsing-state \
            \variables, the testing hooks (TIG_NO_DISPLAY, :save-view), the pgrp option and its \
            \Zsh interaction, and the deprecated v1 commit graph. By Day 14 you can read tigrc(5) \
            \for those yourself — which is the real skill on offer here."
        , courseCardBlurb = do
            "From “a nicer "
            code_ "git log"
            "” to staging single lines, custom keymaps and external commands that know which \
            \commit you are on — plus a "
            code_ "~/.tigrc"
            " you build line by line and can defend."
        , courseCardTags = ["14 lessons", "~30 min each", "tig 2.6.1"]
        , courseConfig =
            Just
                ConfigFile
                    { cfFileName = "tigrc"
                    , cfUserPath = "~/.tigrc"
                    , cfComment = "#"
                    , cfReloadHint = do
                        "tig reads this only at startup. Reload without quitting by binding "
                        code_ ":source ~/.tigrc"
                        " to a key (Day 12), or check it with "
                        code_ "tig 2>&1 | head"
                        " — errors arrive as "
                        code_ "tig warning:"
                        " lines before the first view draws."
                    , cfHeader =
                        [ "# ~/.tigrc"
                        , "#"
                        , "# Assembled over Days 7-14 of the '14 Days of tig' course. Every line was"
                        , "# introduced with a reason, and the comments are that reason."
                        , "#"
                        , "# tig reads this file once, at startup. A syntax error is reported as a"
                        , "# 'tig warning:' line and the rest of the file still loads, so check with:"
                        , "#"
                        , "#     tig 2>&1 | head"
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
