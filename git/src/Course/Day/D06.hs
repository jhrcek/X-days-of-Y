module Course.Day.D06 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 6
        , dayTitle = "Reading history"
        , daySubtitle = "log is a query language over the commit graph; blame and the pickaxe answer who, when and why."
        , dayMinutes = 35
        , dayLevel = "essential"
        , dayManRef = "git-log(1), git-show(1), git-blame(1), gitdiffcore(7) pickaxe"
        , dayTags = ["log", "pickaxe", "blame"]
        , dayGoals =
            [ "narrow " <> c "git log" <> " to exactly the commits that matter, by path, author, date or content"
            , "find the commit that introduced or removed a string with " <> c "-S" <> ", and follow one function's history with " <> c "-L"
            , "get past reformatting and file moves in " <> c "git blame" <> " to the commit that actually wrote a line"
            ]
        , dayDiagram = Just d6diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git log --oneline --graph --all", "Draw every branch's history, one line per commit.")
            , ("git log -p", "Show each commit's diff against its parent.")
            , ("git log --stat", "Show which files each commit touched, and how much.")
            , ("git log --author=<re> --since=<date>", "Keep only commits whose author matches, from a date onwards.")
            , ("git log -- <path>", "Keep only commits that changed the path. The " <> c "--" <> " separates paths from revisions.")
            , ("git log --follow -- <file>", "Follow one file's history back through renames.")
            , ("git log -S<string>", "Pickaxe: keep commits that change how many times the string occurs.")
            , ("git log -G<regex>", "Keep commits whose diff adds or removes a line matching the regex.")
            , ("git log -L :<func>:<file>", "Show the history of one function (or " <> c "-L 10,20:file" <> " for a line range).")
            , ("git show <commit>", "Show one commit: message and diff.")
            , ("git blame -w -C <file>", "Annotate each line with its last commit, ignoring whitespace and seeing moves between files.")
            ]
        , dayOpts =
            [ ("diff.colorMoved / diff.colorMovedWS", "Colour moved blocks differently from added and removed ones; " <> c "allow-indentation-change" <> " still recognises a re-indented move.")
            ]
        , dayConfig =
            [ ConfBlock
                "In a diff, a block that was moved is shown in its own colours instead of as\n\
                \an unrelated deletion and addition, so a refactor that moves code around\n\
                \reads as a move and the real edits stand out. Re-indented moves count too."
                "[diff]\n\
                \\tcolorMoved = default\n\
                \\tcolorMovedWS = allow-indentation-change"
            ]
        , dayDrills =
            [ "In a real repository, run "
                <> c "git log --oneline --graph --all -20"
                <> " and find where the branch you are on last merged or forked."
            , "Pick a file you know and run "
                <> c "git log --oneline --follow -- <file>"
                <> ". Compare with the same command without "
                <> c "--follow"
                <> "."
            , "Think of a config key, constant or error message in your codebase. Find the commit that \
              \introduced it with "
                <> c "git log -S'<string>' --oneline"
                <> ", then read it with "
                <> c "git show"
                <> "."
            , "Run "
                <> c "git log -L :<function>:<file>"
                <> " on a function you have edited this month. Read its whole life in one screen."
            , "Break it on purpose: run "
                <> c "git log <file-that-was-deleted>"
                <> " without "
                <> c "--"
                <> ". Read the ambiguity error, then add the "
                <> c "--"
                <> "."
            , "Blame a file that has been reformatted at some point. Compare "
                <> c "git blame"
                <> " with "
                <> c "git blame -w -C"
                <> " and count how many lines change author."
            , "Add today's "
                <> opt "diff.colorMoved"
                <> " lines, then look at "
                <> c "git show"
                <> " on a commit that moved code."
            , "From today, before asking a colleague why a line is the way it is, run "
                <> c "git log -S"
                <> " or "
                <> c "git blame -w -C"
                <> " on it and read the commit message first."
            ]
        , dayQuiz =
            [
                ( c "git log -- lib/helpers.py"
                    <> " shows two commits, but you know the code is a year old. Where did the rest go?"
                , do
                    p_ $ do
                        "The file was renamed, and a path filter matches paths, not files. Before the rename, \
                        \commits touched "
                        c "util.py"
                        ", which does not match. git records no renames (Day 1: a tree lists names and blobs, \
                        \nothing more), so "
                        c "--follow"
                        " asks log to detect them as it walks, comparing each commit's tree with its parent's."
                    p_ $ do
                        c "--follow"
                        " works for exactly one file. For a directory that moved, give both paths: "
                        c "git log -- lib/ util.py"
                        "."
                )
            ,
                ( c "git log -S'attempts=5'"
                    <> " lists two commits: the one that set it to 5 and the one that set it to 4. Why the second?"
                , p_ $ do
                    c "-S"
                    " keeps commits that change the "
                    em_ "number of occurrences"
                    " of the string. The second commit removed the only occurrence, so the count went from one \
                    \to zero. That is usually what you want — introduced and removed — but it means a commit \
                    \that only moves the string, leaving the count unchanged, is invisible to "
                    c "-S"
                    ". "
                    c "-G"
                    " is the regex alternative that matches any added or removed line, moves included."
                )
            ,
                ( c "git blame"
                    <> " says every line of a function was written by “Reformat Bot” last week. How do you \
                       \see who actually wrote the code?"
                , p_ $ do
                    c "git blame -w"
                    " ignores whitespace when deciding whether a line changed, so a pure re-indent is looked \
                    \through and the line is attributed to the commit before. If the bot did more than \
                    \whitespace — reformatting quotes, reflowing — list its commits in a file and pass it with "
                    c "--ignore-revs-file"
                    ". Both are ways of telling blame which history is not interesting."
                )
            ,
                ( "You moved a small helper from one file to another. "
                    <> c "git blame -C"
                    <> " on the new file still shows every line as yours. Doesn't "
                    <> c "-C"
                    <> " detect moves?"
                , p_ $ do
                    "It does, above a threshold: git-blame(1) says "
                    c "-C"
                    " needs at least 40 alphanumeric characters of moved text to associate lines with another \
                    \file, by default. A two-line helper can fall under it. "
                    c "-C<num>"
                    " lowers the threshold; "
                    c "-C -C"
                    " and "
                    c "-C -C -C"
                    " widen the search — to the commit that created the file, then to any commit — at a cost in \
                    \time."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d6diagram :: Diagram
d6diagram =
    ( diagram
        "git log starts from some commits, walks their ancestors, and keeps the ones that pass a set \
        \of filters; a filter tests a commit's metadata or its diff against its parent. git blame \
        \assigns each line of a file to the last commit whose diff changed it."
        body'
    )
        { dgCaption = do
            "Every history question is a walk plus a filter. "
            c "git log"
            " walks back from "
            b_ "a starting commit"
            " and keeps the commits whose metadata or "
            em_ "diff against their parent"
            " pass the filter — which is why the pickaxe and path filters cost time on large histories: \
            \those diffs are computed during the walk, because none are stored (Day 1). Blame runs the same \
            \walk in the other direction, per line."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  start  [label=\"a starting commit\\n(HEAD, a branch, --all)\", fillcolor=\"#f4efe6\"];\n\
        \  commit [label=\"a commit\\nin the walk\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  filter [label=\"a filter\\n(-- path, --author, -S, -G)\"];\n\
        \  diff   [label=\"the diff against\\nits parent\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  meta   [label=\"its metadata\\n(author, date, message)\"];\n\
        \  line   [label=\"a line of a file\"];\n\
        \\n\
        \  start  -> commit [label=\"  is walked back to\"];\n\
        \  commit -> diff   [label=\"  has (computed on demand)\"];\n\
        \  commit -> meta   [label=\"  has\"];\n\
        \  filter -> diff   [label=\"  tests\"];\n\
        \  filter -> meta   [label=\"  tests\"];\n\
        \  line   -> commit [label=\"  is blamed on\", style=dashed];\n\
        \\n\
        \  { rank=same; start; line; }\n\
        \  { rank=same; diff; meta; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "log is a walk plus a filter" $ do
        p_ [class_ "lede"] $ do
            c "git log"
            " is not a list of what happened. It starts from one or more commits (HEAD, by default), walks \
            \back through parents, and prints the commits that pass whatever filters you gave it. Learning \
            \log is learning the filters — and a handful of them answer almost every question you will ever \
            \ask of a history."
        p_ $ do
            "Start with the picture. "
            c "--oneline"
            " gives one line per commit, "
            c "--graph"
            " draws the parent links, and "
            c "--all"
            " starts from every ref instead of only HEAD:"
        sh
            [ "$ git log --oneline --graph --all"
            , "*   f556cdd (HEAD -> main) Merge branch 'slow'"
            , "|\\"
            , "| * 6ad2702 (slow) Raise timeout to 60"
            , "* | ef89957 Lower timeout to 10"
            , "|/"
            , "*   1e379e1 Merge branch 'feat2'"
            ]
        p_ $ do
            "Then the diff views. "
            c "-p"
            " shows each commit's patch, "
            c "--stat"
            " the files and line counts. Neither diff is stored anywhere: git computes it by comparing the \
            \commit's tree with its parent's, on the spot. "
            c "git show <commit>"
            " is the same thing for one commit."
        why $ p_ $ do
            "Because history is a graph of snapshots rather than a sequence of patches, “the history of a \
            \file” is not a thing git has. It is a question log answers by walking commits and asking, at \
            \each one, whether that path differs from the parent. That is why path filters, renames and the \
            \pickaxe all work the same way, and why they are only as clever as the comparison git runs at \
            \each step."
        fig

    block "Narrowing by who, when and where" $ do
        defs
            [ (c "--author=Bo", "A regex against the author line. " <> c "--committer" <> " for the other one.")
            , (c "--since=2026-09-15", "From a date. Also " <> c "--until" <> ", and relative forms like " <> c "--since='2 weeks ago'" <> ".")
            , (c "--grep=timeout", "A regex against the commit message.")
            , (c "-- lib/", "Only commits that changed something under the path.")
            ]
        sh
            [ "$ git log --oneline --author=Bo"
            , "cc12673 Retry five times"
            , "$ git log --oneline --since=2026-09-15"
            , "01e8bee Four is enough"
            , "b846fc8 Move helpers into lib/"
            ]
        p_ $ do
            "Filters combine with “and”. Path filters come last, after "
            c "--"
            ", which tells git that everything after it is a path, not a branch or a commit."
        gotcha $ p_ $ do
            "A path filter matches "
            em_ "paths"
            ". Rename a file and its history splits in two:"
        sh
            [ "$ git log --oneline -- lib/helpers.py"
            , "01e8bee Four is enough"
            , "b846fc8 Move helpers into lib/"
            , "$ git log --oneline --follow -- lib/helpers.py"
            , "01e8bee Four is enough"
            , "b846fc8 Move helpers into lib/"
            , "cc12673 Retry five times"
            , "4a2587c Add util helpers"
            ]
        p_ $ do
            c "--follow"
            " detects the rename during the walk and keeps going under the old name. It works for a single \
            \file only."

    block "The pickaxe: find the commit that changed a string" $ do
        p_ $ do
            "The most useful history question is “when did this appear, and why?” "
            c "-S<string>"
            " answers it: it keeps commits where the number of occurrences of the string changed — the ones \
            \that introduced or removed it. "
            c "-G<regex>"
            " is the looser cousin: commits whose diff adds or removes a line matching the regex."
        sh
            [ "$ git log --oneline -S'attempts=5'"
            , "01e8bee Four is enough"
            , "cc12673 Retry five times"
            , "$ git log --oneline -G'attempts=[0-9]'"
            , "01e8bee Four is enough"
            , "cc12673 Retry five times"
            , "4a2587c Add util helpers"
            ]
        p_ $ do
            "Add "
            c "-p"
            " to see the diffs, and narrow with a path to make it fast. For one function, "
            c "-L"
            " is better still: it follows a line range, or a function found by name, through every commit \
            \that changed it — renames included:"
        sh
            [ "$ git log --oneline -L :retry:lib/helpers.py"
            , "01e8bee Four is enough"
            , "@@ -4,6 +4,6 @@"
            , "-def retry(fn, attempts=5):"
            , "+def retry(fn, attempts=4):"
            , "..."
            , "cc12673 Retry five times"
            , "--- a/util.py"
            , "+++ b/util.py"
            , "-def retry(fn, attempts=3):"
            , "+def retry(fn, attempts=5):"
            , "..."
            ]
        tip $ p_ $ do
            c "-L :name:file"
            " finds the function with a regex, and git's default guess at what starts a function is a line \
            \beginning with a letter, "
            c "_"
            " or "
            c "$"
            ". It works for many languages as is; Day 14's diff attributes teach it the rest."

    block "blame, and seeing past the noise" $ do
        p_ $ do
            c "git blame"
            " annotates each line with the last commit that changed it. A leading "
            c "^"
            " marks a line that has not changed since the commit where blame stopped — here, the root. \
            \It follows renames on its own:"
        sh
            [ "$ git blame lib/helpers.py"
            , "^4a2587c util.py        (Ada Example 2026-08-01 10:00:00 +0200 1) def parse(line):"
            , "01e8bee7 lib/helpers.py (Ada Example 2026-09-25 09:00:00 +0200 4) def retry(fn, attempts=4):"
            , "^4a2587c util.py        (Ada Example 2026-08-01 10:00:00 +0200 5)     for _ in range(attempts):"
            ]
        p_ $ do
            "Two kinds of commit make blame lie. A re-indent touches every line and takes the blame for all \
            \of them; "
            c "-w"
            " ignores whitespace and looks through it:"
        sh
            [ "$ git blame -L2,2 lib/helpers.py"
            , "ea8b0c84 (Reformat Bot 2026-09-25 09:00:00 +0200 2) \treturn line.split(\",\")"
            , "$ git blame -w -L2,2 lib/helpers.py"
            , "^4a2587c util.py (Ada Example 2026-08-01 10:00:00 +0200 2) \treturn line.split(\",\")"
            ]
        p_ $ do
            "And moving code between files makes the mover its author; "
            c "-C"
            " looks for the lines in other files changed by the same commit:"
        sh
            [ "$ git blame lib/retry.py | head -2"
            , "84e52de5 (Bo Other 2026-09-25 09:00:00 +0200 1) def retry(fn, attempts=4):"
            , "84e52de5 (Bo Other 2026-09-25 09:00:00 +0200 2)     for _ in range(attempts):"
            , "$ git blame -C lib/retry.py | head -2"
            , "01e8bee7 lib/helpers.py (Ada Example 2026-09-25 09:00:00 +0200 1) def retry(fn, attempts=4):"
            , "^4a2587c util.py        (Ada Example 2026-08-01 10:00:00 +0200 2)     for _ in range(attempts):"
            ]
        gotcha $ p_ $ do
            c "-C"
            " has a threshold: at least 40 alphanumeric characters must move before blame will attribute \
            \them to another file. A two-line helper can fall under it and still be blamed on the mover. "
            c "-C -C"
            " and "
            c "-C -C -C"
            " search further — also “the commit that creates the file”, then “any commit”, in the \
            \manual page's words — and get slower accordingly."

    block "Diffs that show moves as moves" $ do
        p_ $ do
            "The same problem appears in "
            c "git show"
            " and "
            c "git diff"
            ": a moved block looks like a deletion in one place and an unrelated addition in another. "
            opt "diff.colorMoved"
            " gives moved lines their own colours (bold magenta and cyan in a default terminal, instead of \
            \red and green), so the eye skips them and lands on what actually changed. "
            opt "diff.colorMovedWS"
            " set to "
            c "allow-indentation-change"
            " keeps recognising the block when it was also re-indented — moving a function into a class, \
            \say."
        note $ p_ $ do
            "Colour settings only affect terminals. "
            c "git diff | cat"
            " or a pipe into a script sees plain text, because "
            opt "color.ui"
            " defaults to "
            c "auto"
            "."

    block "Today's habit" $ do
        p_ $ do
            "Before asking why a line exists, ask git: "
            c "git log -S"
            " for a string, "
            c "git log -L"
            " for a function, "
            c "git blame -w -C"
            " for a line. The commit message is usually there, and it was written by someone who knew."
        p_ $ do
            "Tomorrow: the syntax behind "
            c "HEAD~1"
            ", "
            c "main..feature"
            " and "
            c ":1:file"
            " — the small language every command on this page accepts."

cheat :: Html ()
cheat =
    cfg
        [ "git log --oneline --graph --all    # the whole picture"
        , "git log -p / --stat                # with diffs / with file summaries"
        , "git log --author=RE --since=DATE   # who, when"
        , "git log --follow -- FILE           # one file, through renames"
        , "git log -S'STRING' -p              # commits that add or remove STRING"
        , "git log -G'REGEX'                  # commits whose diff lines match"
        , "git log -L :FUNC:FILE              # one function's whole life"
        , "git show COMMIT                    # one commit, message + diff"
        , "git blame -w -C FILE               # authors, past re-indents and moves"
        ]
