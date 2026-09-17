module Course.Day.D06 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 6
        , dayTitle = "Staging from the diff"
        , daySubtitle = "Stage the file, the chunk, the part, or the single line you actually meant."
        , dayMinutes = 38
        , dayLevel = "essential"
        , dayManRef = "tigmanual(7) View Specific Actions; tigrc(5) Action names"
        , dayTags = ["status view", "stage view", "chunks"]
        , dayGoals =
            [ "stage and unstage whole files, single chunks and single lines without leaving tig"
            , "say what the status view and the stage view each are, and why u means two things"
            , "recover from a mis-stage, and recognise the one that git cannot undo for you"
            ]
        , dayDiagram = Just d6diagram
        , dayBody = body
        , dayKeys =
            [ ("u", "Stage or unstage: the file in the status view, the chunk in the stage view.")
            , ("1", "Stage or unstage the single line under the cursor.")
            , ("2", "Stage or unstage part of a chunk: from here to the end of it.")
            , ("\\", "Split the current chunk into smaller chunks.")
            , ("!", "Revert: throw away the chunk or file under the cursor. Prompts first.")
            , ("M", "Resolve an unmerged file with " <> c "git mergetool" <> ".")
            , ("C", "Commit. Runs " <> c "git commit" <> " in the foreground, in the status view.")
            ]
        , dayCmds = []
        , dayOpts =
            [ ("status-show-untracked-files", "Show untracked files. Default " <> c "yes" <> ".")
            , ("status-show-untracked-dirs", "Show the contents of untracked directories. Default " <> c "yes" <> ".")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Make an edit to a tracked file. Run "
                <> c "tig status"
                <> ", put the cursor on it and press "
                <> k "u"
                <> ". Watch it move from “Changes not staged” to “Changes to be committed”. Press "
                <> k "u"
                <> " again to move it back."
            , "Now press "
                <> k "Enter"
                <> " on the file instead. The stage view opens below with the diff. Put the cursor \
                   \inside a chunk and press "
                <> k "u"
                <> " — only that chunk is staged."
            , "Make a file with two unrelated edits far apart. Stage only the first chunk, then run "
                <> c "git diff --cached"
                <> " in another terminal and confirm the second is still unstaged."
            , "Put the cursor on a single "
                <> c "+"
                <> " line and press "
                <> k "1"
                <> ". Check "
                <> c "git diff --cached"
                <> ": you have staged one line of a chunk."
            , "Find a chunk where two changes sit close enough to be one chunk. Press "
                <> k "\\"
                <> " to split it, then stage one half."
            , "Break something on purpose: with the cursor on an unstaged chunk, press "
                <> k "!"
                <> ". Read the confirmation prompt carefully before answering, then answer no. \
                   \Understand that yes would have destroyed the change with no reflog to recover \
                   \it from."
            , "Today's habit: retire "
                <> c "git add -p"
                <> ". Stage your next commit entirely from the stage view, and use "
                <> k "C"
                <> " to commit without leaving tig."
            ]
        , dayQuiz =
            [
                ( "You press "
                    <> k "u"
                    <> " and sometimes a whole file is staged, sometimes a single chunk. What \
                       \decides?"
                , do
                    p_ $ do
                        "Which view you are in. "
                        k "u"
                        " is bound to the same action, "
                        c "status-update"
                        ", in both the "
                        c "status"
                        " and "
                        c "stage"
                        " keymaps, and the action asks what the cursor is on."
                    p_ $ do
                        "In the status view the cursor is on a file, so the file is staged. In the \
                        \stage view the cursor is inside a diff: on a chunk line it stages that \
                        \chunk, and anywhere else it stages everything in the displayed diff. One \
                        \key, three granularities, chosen by where you are pointing."
                )
            ,
                ( "You stage a single "
                    <> c "+"
                    <> " line with "
                    <> k "1"
                    <> " and the staged version of the file now has "
                    <> i_ "both"
                    <> " the old line and the new one. Is that wrong?"
                , do
                    p_ $ do
                        "No, and it is the thing to understand about line staging. A modification is \
                        \a deletion plus an insertion. Staging only the "
                        c "+"
                        " line stages the insertion and leaves the "
                        c "-"
                        " line unstaged, so the index holds both."
                    p_ $ do
                        "Verified on 2.6.1: staging "
                        c "+ONE"
                        " out of a "
                        c "-one"
                        " / "
                        c "+ONE"
                        " pair produces an index containing "
                        i_ "both"
                        " lines. That intermediate state often does not compile, which is exactly \
                        \why you should stage the "
                        c "-"
                        " line too — or use "
                        k "2"
                        " for a run of lines rather than picking them one at a time."
                )
            ,
                ( "Chunk staging suddenly fails with an error about the patch not applying, on a \
                  \file you have been editing normally. What is the most likely cause?"
                , do
                    p_ $ do
                        "You have "
                        opt "ignore-space"
                        " turned on — probably by pressing "
                        k "W"
                        " in the diff view yesterday. tigrc(5) warns about this directly: with \
                        \whitespace ignored, the chunk tig shows you is not the chunk git has, so "
                        c "status-update"
                        " and "
                        c "status-revert"
                        " can fail to apply."
                    p_ $ do
                        "Press "
                        k "W"
                        " to turn it back off and try again. It is a good reason to keep \
                        \whitespace-blindness as a deliberate, temporary reading aid rather than \
                        \something you set permanently in "
                        c "~/.tigrc"
                        "."
                )
            ,
                ( "Which key in this lesson can lose work that no git command will bring back?"
                , do
                    p_ $ do
                        k "!"
                        " — "
                        c "status-revert"
                        ". Unstaging with "
                        k "u"
                        " is harmless, and a commit made with "
                        k "C"
                        " is recoverable through the reflog even if you immediately reset it. "
                        k "!"
                        " throws away an uncommitted change, and uncommitted changes have never \
                        \been in the object database, so there is nothing to recover."
                    p_ $ do
                        "tig does prompt first, which is why the binding is "
                        c "?git"
                        "-style in spirit. Read that prompt. It is the only safety net between you \
                        \and an afternoon's work."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d6diagram :: Diagram
d6diagram =
    ( diagram
        "The staging model: the working tree, the index and the last commit are three states; the \
        \status view lists files moving between them, the stage view shows one file's diff broken \
        \into chunks and lines, and the update action moves whichever granularity the cursor is on."
        body'
    )
        { dgCaption = do
            "One action, "
            c "status-update"
            ", bound to one key. What it moves is decided by "
            b_ "what the cursor is pointing at"
            " — a file in the status view, a chunk or a line in the stage view. The amber box is \
            \the one-way door: "
            c "status-revert"
            " sends a change somewhere nothing can retrieve it from."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  wt   [label=\"the working tree\", fillcolor=\"#f4efe6\"];"
            , "  idx  [label=\"the index\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  head [label=\"the last commit\", fillcolor=\"#f4efe6\"];"
            , "  sv   [label=\"the status view\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  stv  [label=\"the stage view\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  file [label=\"a file\"];"
            , "  chunk [label=\"a chunk\"];"
            , "  line [label=\"a line\"];"
            , "  gone [label=\"discarded\\n(no reflog,\\nno recovery)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  sv   -> file  [label=\"  lists\"];"
            , "  stv  -> chunk [label=\"  shows\"];"
            , "  chunk -> line [label=\"  is made of\"];"
            , "  file -> idx   [label=\"  u stages into\"];"
            , "  chunk -> idx  [label=\"  u stages into\"];"
            , "  line -> idx   [label=\"  1 stages into\"];"
            , "  wt   -> file  [label=\"  supplies\"];"
            , "  idx  -> head  [label=\"  C commits into\"];"
            , "  chunk -> gone [label=\"  ! reverts to\", style=dashed];"
            , ""
            , "  { rank=same; wt; idx; head; }"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "This is the reason to install tig" $ do
        p_ [class_ "lede"] $ do
            "Everything so far has been a better way to read. This is the day tig replaces \
            \something: "
            c "git add -p"
            ", and the whole business of answering "
            c "y/n/s/e?"
            " at a prompt while trying to remember what chunk 4 of 9 contained. In tig you can see \
            \the whole diff, put the cursor on what you want, and press one key."
        p_ "Two views do the work, and they nest:"
        defs
            [
                ( k "s" <> " the status view"
                , "One line per file, grouped into staged, unstaged and untracked. This is " <> c "git status" <> ", navigable."
                )
            ,
                ( k "Enter" <> " the stage view"
                , "The diff for the file under the cursor, which is where chunk and line staging happen."
                )
            ]
        fig

    block "The status view, and the hint line you should read" $ do
        p_ $ do
            "Open it with "
            c "tig status"
            ", or press "
            k "s"
            " from anywhere:"
        termStatus
            "tig — status view"
            [ "On branch master"
            , ""
            , "Changes to be committed:"
            , "M README"
            , ""
            , "Changes not staged for commit:"
            , "M src/main.c"
            , ""
            , "Untracked files:"
            , "? notes.txt"
            ]
            "[status] Press u to stage 'src/main.c' for commit"
            "100%"
        p_ $ do
            "The status window at the bottom is doing something unusually helpful here: it tells \
            \you what "
            k "u"
            " will do to the line you are currently on. Move the cursor and it changes — “Press u \
            \to stage”, “Press u to unstage”, “Press u to add”. When you are unsure, read it \
            \instead of guessing."
        p_ $ do
            "Untracked files appear because "
            opt "status-show-untracked-files"
            " defaults to "
            c "yes"
            ", and whole untracked directories are expanded because of "
            opt "status-show-untracked-dirs"
            ". Pressing "
            k "u"
            " on an untracked file adds it, exactly like "
            c "git add"
            "."

    block "Four granularities, one key" $ do
        p_ $ do
            "Press "
            k "Enter"
            " on a modified file and the stage view opens below it. Now the cursor position means \
            \something, and "
            k "u"
            " means progressively smaller things:"
        steps
            [ do
                b_ "The file."
                " Cursor in the status view, on the filename. "
                k "u"
                " stages all of it."
            , do
                b_ "The chunk."
                " Cursor in the stage view, on a line inside a chunk. "
                k "u"
                " stages that chunk only."
            , do
                b_ "Part of a chunk."
                " "
                k "2"
                " ("
                c "stage-update-part"
                ") stages from the cursor to the end of the chunk — for when a chunk is nearly \
                \right."
            , do
                b_ "One line."
                " "
                k "1"
                " ("
                c "stage-update-line"
                ") stages exactly the line under the cursor."
            ]
        p_ $ do
            "And when a chunk is stubbornly two changes glued together by three lines of context, "
            k "\\"
            " ("
            c "stage-split-chunk"
            ") splits it so you can take half. That, plus "
            k "["
            " to shrink the context, handles nearly every awkward case."
        why $ p_ $ do
            "Line-level staging exists because a commit is an argument, not a backup. If you fixed \
            \a bug and also renamed a variable while you were in there, those are two commits, and \
            \the reader of your history deserves them separately. tig makes the cost of splitting \
            \them small enough that you actually do it."

    block "What line staging really does to the index" $ do
        p_ $ do
            "This one is worth doing rather than believing. Take a file where one line changed from "
            c "one"
            " to "
            c "ONE"
            ". The diff is a pair:"
        sh
            [ "@@ -1,8 +1,8 @@"
            , "-one"
            , "+ONE"
            , " two"
            ]
        p_ $ do
            "Put the cursor on "
            c "+ONE"
            ", press "
            k "1"
            ", and look at what you staged:"
        sh
            [ "$ git diff --cached"
            , "@@ -1,4 +1,5 @@"
            , " one"
            , "+ONE"
            , " two"
            ]
        gotcha $ p_ $ do
            "The index now contains "
            b_ "both"
            " lines. A modification is a deletion plus an insertion, and you staged only the \
            \insertion — so the staged file has the old line and the new one. Nothing is broken, \
            \but that intermediate state frequently does not compile, and if you commit it \
            \unexamined you have committed something that never existed on disk. Stage the "
            c "-"
            " line too, or use "
            k "2"
            " to take a run of lines in one go."
        tip $ p_ $ do
            "Whenever you have staged at line granularity, look at the result before committing. \
            \Moving the cursor to the “Staged changes” row in the main view, or "
            c ":!git diff --cached"
            ", takes three seconds and catches exactly this."

    block "Undoing, and the one thing you cannot undo" $ do
        defs
            [ (k "u" <> " again", "Unstages. Entirely safe — the change is still in your working tree.")
            , (k "!", "Reverts: throws the change away. Prompts first, and is not recoverable.")
            , (k "M", "Hands an unmerged file to " <> c "git mergetool" <> ", which needs configuring first.")
            , (k "C", "Runs " <> c "git commit" <> " in the foreground, editor and all.")
            ]
        p_ $ do
            k "!"
            " is the only genuinely dangerous key in this course. An uncommitted change has never \
            \been written to the object database, so there is no reflog entry, no dangling blob, \
            \nothing for "
            c "git fsck"
            " to find. The confirmation prompt is the entire safety mechanism."
        note $ p_ $ do
            k "C"
            " in the status view is a built-in external command — its binding is literally "
            c "!git commit"
            ". That is the Day 13 mechanism, shipping in the defaults. Once you have read Day 13 \
            \you will be able to add "
            c "!git commit --amend"
            " next to it in about fifteen seconds."

    block "Today's habit" $ do
        p_ $ do
            "Stage your next commit entirely from tig. Open "
            c "tig status"
            ", press "
            k "Enter"
            " on each modified file, stage the chunks that belong together, press "
            k "C"
            ", write the message. Then do the second commit with what is left."
        p_ $ do
            "That is the end of the essentials. You can now read history, read diffs, find things \
            \and build commits without leaving tig. Tomorrow the course turns around and starts \
            \making tig yours."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Staging, by granularity."
        " The cursor decides what "
        code_ "u"
        " means."
    cfg
        [ "s          status view: one line per file"
        , "Enter      stage view: that file's diff"
        , "u          stage/unstage — the FILE (status) or the CHUNK (stage)"
        , "2          stage from the cursor to the end of the chunk"
        , "1          stage exactly this line  (see the warning below)"
        , "\\          split this chunk into smaller ones"
        , "@          jump to the next chunk       [ ]  narrow/widen context"
        , "C          commit (runs 'git commit' in the foreground)"
        , "!          REVERT — destroys the change, no reflog, no recovery"
        , "# staging only a '+' line leaves the '-' line unstaged: the index gets BOTH"
        ]
