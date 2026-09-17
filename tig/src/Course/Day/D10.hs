module Course.Day.D10 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 10
        , dayTitle = "The command line"
        , daySubtitle = "Revision specification, path limiting, and tig as a pager."
        , dayMinutes = 34
        , dayLevel = "intermediate"
        , dayManRef = "tig(1) OPTIONS, PAGER MODE; tigmanual(7) REVISION SPECIFICATION"
        , dayTags = ["revisions", "pager mode", "subcommands"]
        , dayGoals =
            [ "limit what tig loads by revision, by path, by date and by count — and combine them"
            , "pipe the output of any git command into tig and get it coloured and navigable"
            , "recognise the argument-parsing trap that makes tig say \"no revisions match\""
            ]
        , dayDiagram = Just d10diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("tig <rev>", "Start the main view at a revision instead of HEAD.")
            , ("tig a..b", "Commits reachable from " <> var "b" <> " but not " <> var "a" <> ".")
            , ("tig b ^a", "The same thing, written as a negation.")
            , ("tig --all", "Every ref, as if all of " <> c "refs/" <> " were on the command line.")
            , ("tig -- <path>", "Only commits touching that path. " <> c "--" <> " ends option parsing.")
            , ("tig -n20 --since=1.month", "Limit by count and by date.")
            , ("tig +42", "Open with line 42 selected.")
            , ("git log -p | tig", "Pager mode: colourise and navigate any git output.")
            , ("tig --stdin", "Read a list of commit IDs from stdin.")
            ]
        , dayOpts =
            [ ("main-options", "Default options for the main view's " <> c "git log" <> ".")
            , ("log-options", "Default options for the log view. Default " <> c "--cc --stat" <> ".")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Run "
                <> c "tig v1.0..master"
                <> " (substituting a tag and branch you have). Count the commits, then run "
                <> c "tig master ^v1.0"
                <> " and confirm you get the same list."
            , "Run "
                <> c "tig origin/master..HEAD"
                <> " in a repository with an upstream. That is exactly what you are about to push."
            , "Run "
                <> c "tig --since=1.month -n20 -- src/"
                <> ". Three limits at once: by date, by count, by path."
            , "Run "
                <> c "tig -- <a file you have modified>"
                <> " and confirm the working-tree rows are gone, as promised on Day 2."
            , "Break it on purpose: run "
                <> c "tig -S return"
                <> " with a space. Read the error. Then run "
                <> c "tig -Sreturn"
                <> " with no space and watch it work."
            , "Pipe something in: "
                <> c "git log -p -3 | tig"
                <> ". Then try "
                <> c "git show --stat HEAD | tig"
                <> ". You now have a pager for every git command you own."
            , "Today's habit: alias the one you will use daily. "
                <> c "alias tigp='tig @{upstream}..HEAD'"
                <> " — review what you are about to push, every time, before you push it."
            ]
        , dayQuiz =
            [
                ( "You run "
                    <> c "tig -S return"
                    <> " and get "
                    <> c "tig: No revisions match the given arguments."
                    <> " The same option works with "
                    <> c "git log"
                    <> ". Why?"
                , do
                    p_ $ do
                        "Because tig stops parsing options at the first argument that does not start \
                        \with "
                        c "-"
                        ", and treats it as a revision or a path. With "
                        c "-S return"
                        ", the "
                        c "return"
                        " is a separate argument, so tig reads it as a revision, fails to resolve \
                        \it, and reports exactly that."
                    p_ $ do
                        "The rule from tig(1) is to attach the value to the option: "
                        c "tig -Sreturn"
                        ", "
                        c "tig --grep=foo"
                        " rather than "
                        c "tig --grep foo"
                        ". Anything that takes a value must be written as one argument."
                )
            ,
                ( "You have a file called "
                    <> c "status"
                    <> " and "
                    <> c "tig status"
                    <> " opens the status view instead of that file's history. How do you ask for \
                       \the file?"
                , do
                    p_ $ do
                        c "tig -- status"
                        ". The "
                        c "--"
                        " separator ends option and subcommand parsing, so everything after it is a \
                        \path."
                    p_ $ do
                        "The same ambiguity exists between paths and refs: a file named "
                        c "master"
                        " and a branch named "
                        c "master"
                        " are indistinguishable until you say which you meant. Getting into the \
                        \habit of writing "
                        c "--"
                        " before paths costs three characters and removes the whole class of \
                        \problem."
                )
            ,
                ( "What is the difference between "
                    <> c "tig a..b"
                    <> " and "
                    <> c "tig a...b"
                    <> ", and what does "
                    <> c "^"
                    <> " have to do with it?"
                , do
                    p_ $ do
                        c "a..b"
                        " is “reachable from "
                        c "b"
                        " but not from "
                        c "a"
                        "” — what "
                        c "b"
                        " has that "
                        c "a"
                        " lacks. It is precisely "
                        c "b ^a"
                        ", and "
                        c "^"
                        " is a negation you can repeat: "
                        c "tig master ^v1.0 ^v1.1"
                        " prunes two starting points at once."
                    p_ $ do
                        c "a...b"
                        " (three dots) is the symmetric difference — commits in either but not \
                        \both. tig does not parse any of this itself; it hands the arguments to \
                        \git, so every range expression from git-rev-list(1) works unchanged."
                )
            ,
                ( "You pipe "
                    <> c "git log --oneline | tig"
                    <> " and get a plain list rather than a navigable commit view. Why, and what \
                       \gets you the navigable one?"
                , do
                    p_ $ do
                        "In pager mode tig displays what it is given. It assumes the input looks \
                        \like "
                        c "git log"
                        " or "
                        c "git diff"
                        " output and colours it accordingly, but it cannot turn one-line summaries \
                        \back into commits it can open."
                    p_ $ do
                        "For that, give it identifiers instead of text: "
                        c "git rev-list --author=ada HEAD | tig --stdin"
                        " feeds commit IDs to the main view, and "
                        c "… | tig show --stdin"
                        " feeds them to the diff view. Pager mode is for reading; "
                        c "--stdin"
                        " is for browsing."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d10diagram :: Diagram
d10diagram =
    ( diagram
        "How a tig command line is interpreted: options are passed through to git, the first \
        \non-option argument ends option parsing and becomes a revision or a path, a double dash \
        \forces the rest to be paths, and when stdin is a pipe tig ignores all of this and opens \
        \the pager view instead."
        body'
    )
        { dgCaption = do
            "tig parses almost nothing itself — it sorts the command line into revisions, paths and \
            \“everything else”, and hands each group to git. The amber box is where the time goes: \
            \the first argument not starting with a dash "
            b_ "ends option parsing"
            ", so a detached option value becomes a revision and the command fails with a message \
            \about revisions rather than about options."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  cl   [label=\"a tig command line\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  sub  [label=\"a subcommand\\nlog show blame\\ngrep refs stash status\"];"
            , "  opt  [label=\"an option\\n--since=1.month  -n20\"];"
            , "  rev  [label=\"a revision\\nv1.0..master  ^branch\"];"
            , "  path [label=\"a path\\n(after --)\"];"
            , "  brk  [label=\"the first argument\\nnot starting with -\\nENDS option parsing\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  git  [label=\"a git command\", fillcolor=\"#f4efe6\"];"
            , "  pipe [label=\"a pipe on stdin\", fillcolor=\"#f4efe6\"];"
            , "  pv   [label=\"the pager view\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , ""
            , "  cl  -> sub  [label=\"  may begin with\"];"
            , "  cl  -> opt  [label=\"  contains\"];"
            , "  cl  -> rev [label=\"  contains\"];"
            , "  cl  -> path [label=\"  contains\"];"
            , "  brk -> rev  [label=\"  turns the rest into\", style=dashed];"
            , "  opt -> git  [label=\"  is passed to\"];"
            , "  rev -> git  [label=\"  is passed to\"];"
            , "  path -> git [label=\"  is passed to\"];"
            , "  pipe -> pv  [label=\"  opens\"];"
            , ""
            , "  { rank=same; sub; opt; rev; path; }"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Everything you say before tig starts" $ do
        p_ [class_ "lede"] $ do
            "tig's command line is mostly git's command line. It recognises a handful of \
            \subcommands and three of its own options, sorts the rest into revisions and paths, and \
            \passes everything through. That means every "
            c "git log"
            " option you already know works, and the ones you do not know are worth learning once \
            \for both tools."
        p_ "The subcommands each start you in a particular view:"
        cfg
            [ "tig                 main view (the default)"
            , "tig log             log view — full messages and diffstats"
            , "tig show <rev>      diff view"
            , "tig blame <file>    blame view"
            , "tig grep <pattern>  grep view"
            , "tig refs            refs view        tig stash    stash view"
            , "tig status          status view      tig reflog   reflog view"
            ]
        p_ $ do
            "Plus three options that belong to tig rather than git: "
            c "-C <path>"
            " to run as if started elsewhere, "
            c "+<number>"
            " to open with a particular line selected, and "
            c "-v"
            " for the version."
        fig

    block "Limiting by revision" $ do
        p_ $ do
            "The single most useful thing on this page is the range. "
            c "tig a..b"
            " means “reachable from "
            c "b"
            " but not from "
            c "a"
            "”:"
        cfg
            [ "tig v1.0..master        what master has that v1.0 does not"
            , "tig origin/master..HEAD what you are about to push"
            , "tig origin..            the same — a missing end means HEAD"
            , "tig master ^v1.0        identical to the first line, written as a negation"
            , "tig master ^v1.0 ^v1.1  negation repeats; prune several starting points"
            , "tig --all               every ref, as if all of refs/ were listed"
            ]
        p_ $ do
            "The second line is the one to make a habit of. Reviewing your own commits before you \
            \push them catches the debugging "
            c "print"
            " you left in, and it is one alias away: "
            c "alias tigp='tig @{upstream}..HEAD'"
            "."
        why $ p_ $ do
            "tig does not parse any of this. It sorts arguments into revisions and paths using "
            c "git rev-parse"
            " and hands them over, which is why the full grammar of git-rev-list(1) works — "
            c "HEAD~3"
            ", "
            c "master@{yesterday}"
            ", "
            c "v1.0^{commit}"
            " and the rest. Anything you can say to "
            c "git log"
            " you can say to tig, including options this course has never mentioned."

    block "Limiting by path, date and count" $ do
        cfg
            [ "tig -- src/parser.c        only commits touching that path"
            , "tig -- src/ doc/           several paths"
            , "tig --since=1.month        by date"
            , "tig --after=2026-01-01 --before=2026-03-01"
            , "tig --after=May.5th        dots avoid having to quote spaces"
            , "tig -n20                   at most twenty commits"
            , "tig --since=1.month -n20 -- doc/     all three at once"
            ]
        gotcha $ p_ $ do
            "Always put "
            c "--"
            " before paths. Without it, a file called "
            c "status"
            " collides with the "
            c "status"
            " subcommand and a file called "
            c "master"
            " collides with the branch — "
            c "tig status"
            " opens the status view, and "
            c "tig -- status"
            " shows that file's history. The separator costs three characters and removes an entire \
            \class of confusion."
        p_ $ do
            "Remember from Day 2 that a path limit also removes the working-tree rows from the top \
            \of the main view, and from Day 4 that it silently filters the diff view until you \
            \press "
            k "%"
            ". Both follow from the same decision and both surprise people."

    block "The argument-parsing trap" $ do
        p_ $ do
            "This one costs everybody twenty minutes exactly once. tig stops parsing options at the \
            \first argument that does not begin with "
            c "-"
            ", and treats it as a revision or a path. So an option whose value is a separate word \
            \breaks:"
        sh
            [ "$ tig -S return"
            , "tig: No revisions match the given arguments."
            , "$ tig -Sreturn"
            , "(works: commits that changed the number of occurrences of \"return\")"
            ]
        p_ $ do
            "The error talks about revisions because that is genuinely what happened — "
            c "return"
            " was read as a revision and does not resolve. The rule is to attach every value to its \
            \option: "
            c "-Sfoo"
            ", "
            c "--grep=foo"
            ", "
            c "--author=ada"
            ". Never "
            c "--grep foo"
            "."

    block "tig as a pager for anything git prints" $ do
        p_ $ do
            "When stdin is a pipe, tig ignores revision arguments entirely and opens the "
            b_ "pager view"
            " on what it is given, colouring it as though it were log or diff output:"
        sh
            [ "$ git log -p -2 | tig"
            , "$ git show --stat HEAD | tig"
            , "$ git log -Schange -p --raw | tig"
            ]
        p_ $ do
            "That turns tig into a pager for every git command you own — searchable with "
            k "/"
            ", navigable, and with "
            k "q"
            " to leave. It is worth setting as your git pager for the commands where you want it."
        p_ "Three variations do something cleverer than colouring text:"
        defs
            [
                ( c "tig --stdin"
                , do
                    "stdin is a list of commit IDs, fed to the main view. "
                    c "git rev-list --author=ada HEAD | tig --stdin"
                    " gives you a browsable list of one person's commits."
                )
            ,
                ( c "tig show --stdin"
                , "The same, into the diff view — a browsable sequence of patches."
                )
            ,
                ( c "tig --pretty=raw"
                , do
                    "stdin is "
                    c "pretty=raw"
                    " output. "
                    c "git reflog --pretty=raw | tig --pretty=raw"
                    " is the documented use."
                )
            ]
        tip $ p_ $ do
            "The difference between pager mode and "
            c "--stdin"
            " is worth holding onto: pager mode shows you "
            i_ "text"
            ", and "
            c "--stdin"
            " gives tig "
            i_ "identifiers"
            " it can open, blame and diff. If you find yourself wanting to press "
            k "Enter"
            " on a line in the pager view and nothing useful happens, you wanted "
            c "--stdin"
            "."

    block "Today's habit" $ do
        p_ $ do
            "Write one alias today and use it before every push: "
            c "alias tigp='tig @{upstream}..HEAD'"
            ". Then, the next time you would have run "
            c "git log --oneline --graph --all"
            " and squinted, run "
            c "tig --all"
            " instead."
        p_ "Tomorrow: reshaping the views themselves, one column at a time."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "The command line."
        " Everything but the last three lines is passed straight to git."
    cfg
        [ "tig log|show|blame|grep|refs|stash|status|reflog    start in that view"
        , "tig v1.0..master        b but not a      tig master ^v1.0   same, negated"
        , "tig origin/master..HEAD what you are about to push"
        , "tig --all               every ref        tig -n20  --since=1.month"
        , "tig -- src/ doc/        paths — ALWAYS after --"
        , "tig -Sfoo  --grep=bar   attach the value; 'tig -S foo' fails on revisions"
        , "git log -p | tig        pager mode: colour and navigate any git output"
        , "… | tig --stdin         a list of commit IDs, browsable in the main view"
        , "tig -C <path>  +<line>  -v"
        ]
