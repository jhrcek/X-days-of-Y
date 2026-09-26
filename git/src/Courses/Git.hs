{- | "21 Days of git": the course metadata, and the days in order.

The lessons themselves live in "Course.Day".
-}
module Courses.Git (course) where

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
import Course.Day.D18 qualified as D18
import Course.Day.D19 qualified as D19
import Course.Day.D20 qualified as D20
import Course.Day.D21 qualified as D21

course :: Course
course =
    Course
        { courseSlug = "git"
        , courseTool = "git"
        , courseManRef = "git(1)"
        , courseVersion = "git 2.52.0"
        , courseTagline = do
            "From "
            em_ "“add, commit, push, and hope”"
            " to reading history in its own query language, rewriting a branch without fear, \
            \recovering work you were sure was gone, and scripting git against the interfaces that \
            \are promised not to change. One sitting a day, each small enough to use at work the \
            \same afternoon."
        , courseHowTo =
            [
                ( "One sitting a day"
                , do
                    "Each lesson is one mental model and stops. The drills at the bottom are the \
                    \actual lesson: do them in a scratch repository first, then in the repository you \
                    \work in, where the history is yours and the stakes are real. No drill touches a \
                    \shared remote unless it says so."
                )
            ,
                ( "Ask what moved"
                , do
                    "Day 1 gives you one question to carry everywhere: which objects did that command \
                    \create, and which names did it move? "
                    code_ "git cat-file -p HEAD"
                    " before and after answers it. By Day 11 you will know that almost nothing git does \
                    \deletes anything, and most of the fear goes with it."
                )
            ,
                ( "Build your own gitconfig"
                , do
                    "From Day 2 each lesson that earns a setting adds a few justified lines to "
                    code_ "~/.gitconfig"
                    ". Nothing is pasted from a stranger's dotfiles; the comment above every line is \
                    \the reason for it. The finished file is "
                    a_ [href_ "gitconfig"] "here"
                    "."
                )
            ]
        , courseLeftOut =
            "Submodules, sparse checkout, partial clones and scalar; the e-mail patch workflow (am, \
            \format-patch, send-email, imap-send); the CVS, Subversion and Perforce bridges; \
            \filter-branch; the server side (daemon, http-backend, shell) and the wire protocols; \
            \namespaces; and most of the forty-odd trace and Windows-only environment variables. \
            \git(1) is an index of about two hundred commands. By Day 21 you can open any of their \
            \pages and read it unaided, which is the real skill on offer here."
        , courseCardBlurb = do
            "From “add, commit, push” to the object model, the revision language, interactive \
            \rebase, the reflog as a safety net, bisect, hooks and scripting against plumbing — plus a "
            code_ "~/.gitconfig"
            " you build line by line and can defend."
        , courseCardTags = ["21 lessons", "~30 min each", "git 2.52.0"]
        , courseConfig =
            Just
                ConfigFile
                    { cfFileName = "gitconfig"
                    , cfUserPath = "~/.gitconfig"
                    , cfComment = "#"
                    , cfReloadHint = do
                        "git reads its config afresh on every command, so there is nothing to reload. \
                        \Check what is in force, and which file it came from, with "
                        code_ "git config list --show-origin"
                        "."
                    , cfHeader =
                        [ "# ~/.gitconfig"
                        , "#"
                        , "# Assembled over Days 2-21 of the '21 Days of git' course. Every line was"
                        , "# introduced with a reason, and the comments are that reason."
                        , "#"
                        , "# Edit the [user] block before using this. git reads the file on every"
                        , "# command; check what is in force, and where it came from, with:"
                        , "#"
                        , "#     git config list --show-origin"
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
            , D15.day
            , D16.day
            , D17.day
            , D18.day
            , D19.day
            , D20.day
            , D21.day
            ]
        }
