module Course.Day.D08 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 8
        , dayTitle = "Files through time"
        , daySubtitle = "Tree to blob to blame, and walking back past the change you found."
        , dayMinutes = 34
        , dayLevel = "intermediate"
        , dayManRef = "tigmanual(7) Views; tigrc(5) SET COMMAND"
        , dayTags = ["tree", "blob", "blame"]
        , dayGoals =
            [ "browse a repository as it was at any commit, not as it is on disk"
            , "blame a file and then walk backwards through the commits that touched each line"
            , "teach blame to follow code that was moved or copied between files"
            ]
        , dayDiagram = Just d8diagram
        , dayBody = body
        , dayKeys =
            [ ("t", "Open the tree view at the current revision.")
            , ("f", "Open the blob view: the contents of the selected file.")
            , ("b", "Open the blame view for the selected file.")
            , ("e", "Open the file in your editor, at the line under the cursor.")
            ]
        , dayCmds =
            [ ("tig blame <file>", "Start in the blame view for a file.")
            , ("tig blame <rev> -- <file>", "Blame the file as it was at that revision.")
            , ("tig blame -C <file>", "Blame with copy detection for one run.")
            , ("tig show <rev>:<path>", "Show a file's contents at a revision.")
            ]
        , dayOpts =
            [ ("blame-options", "Default options for " <> c "git blame" <> ". Empty by default.")
            , ("recurse-tree", "Show every file recursively in the tree view. Default " <> c "no" <> ".")
            , ("editor-line-number", "Pass " <> c "+<line>" <> " to the editor. Default " <> c "yes" <> ".")
            ]
        , dayConfig = day8config
        , dayDrills =
            [ "In the main view, put the cursor on a commit from a few months ago and press "
                <> k "t"
                <> ". You are browsing the repository as it was then, not as it is now."
            , "Navigate into a directory with "
                <> k "Enter"
                <> " and back out with "
                <> k ","
                <> ". Then press "
                <> k "Enter"
                <> " on a file and watch the blob view open beside the tree."
            , "Find a file you did not write. Press "
                <> k "b"
                <> " on it. Put the cursor on a line that puzzles you and press "
                <> k "Enter"
                <> " to see the commit that introduced it."
            , "Now the important one: with the cursor on a line in the blame view, press "
                <> k ","
                <> ". Blame reloads for the "
                <> i_ "parent"
                <> " of that line's commit. Press it four or five times and watch a line's history \
                   \unwind. Then "
                <> k "<"
                <> " to come back."
            , "Find a file that was split out of another one. Blame it normally, then run "
                <> c "tig blame -C -C -C <file>"
                <> " and compare. The second one attributes moved code to whoever actually wrote \
                   \it."
            , "Break it on purpose: run "
                <> c "tig blame README"
                <> " on a file with uncommitted edits. Note the "
                <> c "0000000"
                <> " commit ID and the author "
                <> c "Not Committed Yet"
                <> " — blame is telling you those lines are not in history at all."
            , "Today's habit: when you would have opened a file to ask “why is this like this”, \
              \press "
                <> k "b"
                <> " instead of reading it."
            ]
        , dayQuiz =
            [
                ( "You press "
                    <> k ","
                    <> " in the blame view and the whole file changes under you. What did it \
                       \actually do?"
                , do
                    p_ $ do
                        "It reloaded the blame for the "
                        b_ "parent of the commit that last touched the line under the cursor"
                        " — that is, the state of the file immediately before that change landed."
                    p_ $ do
                        "This is the single most valuable key in the blame view. A line that says \
                        \“reformatting” tells you nothing; press "
                        k ","
                        " and you see the file as it was before the reformatting, where the same \
                        \line has a real commit behind it. Repeat until you reach the change that \
                        \actually explains the code. "
                        k "<"
                        " walks back down the chain."
                )
            ,
                ( "Blame says a colleague wrote a hundred lines last Tuesday. They insist they only \
                  \moved the file. Who is right, and which option settles it?"
                , do
                    p_ $ do
                        "Both, and the default is the problem. Plain "
                        c "git blame"
                        " attributes a line to the commit that put those bytes in that file, so \
                        \moving code between files makes the mover the author of everything they \
                        \moved."
                    p_ $ do
                        c "-C"
                        " tells blame to look for the lines in other files in the same commit; \
                        \repeating it widens the search — "
                        c "-C -C"
                        " also looks at files the commit created, and "
                        c "-C -C -C"
                        " searches every file in the parent. Putting "
                        c "set blame-options = -C -C -C"
                        " in your config makes this the default, at some cost in speed."
                )
            ,
                ( "The tree view shows the top-level directories but you wanted to find a file \
                  \three levels down without clicking through. What are your options?"
                , do
                    p_ $ do
                        "The tree view is non-recursive by default — "
                        opt "recurse-tree"
                        " is "
                        c "no"
                        " — so it shows one directory at a time and "
                        k "Enter"
                        " descends. Setting it to "
                        c "yes"
                        " lists every file in the repository at once, which is pleasant in a small \
                        \repository and unusable in a large one."
                    p_ $ do
                        "The better tool for “find the file” is usually the grep view ("
                        k "g"
                        ", tomorrow), or starting tig with a path. The tree view earns its place \
                        \when you want to see structure "
                        i_ "as of a particular commit"
                        ", which nothing else gives you."
                )
            ,
                ( "You press "
                    <> k "e"
                    <> " on a line in the blame view and your editor opens at line 1 instead of the \
                       \line you were on. What is misconfigured?"
                , do
                    p_ $ do
                        opt "editor-line-number"
                        " is on by default and makes tig pass "
                        c "+<line>"
                        " before the filename, as in "
                        c "vim +42 src/parser.c"
                        ". If your editor command does not understand that convention — or is \
                        \wrapped in a script that drops arguments — you land at the top."
                    p_ $ do
                        "Which editor tig uses is its own small hierarchy: "
                        c "TIG_EDITOR"
                        " beats "
                        c "$GIT_EDITOR"
                        ", which beats "
                        c "core.editor"
                        ", then "
                        c "$VISUAL"
                        " and "
                        c "$EDITOR"
                        ". "
                        c "TIG_EDITOR"
                        " exists precisely so you can use a different editor inside tig from the one \
                        \git opens for commit messages."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

day8config :: [ConfBlock]
day8config =
    [ ConfBlock
        "Make blame follow code that was moved or copied between files, instead of crediting\n\
        \whoever moved it. Three -C's widen the search to every file in the parent commit; it\n\
        \costs time on a big repository, and it is worth it every single time you use blame."
        "set blame-options = -C -C -C"
    ]

-- ---------------------------------------------------------------------------

d8diagram :: Diagram
d8diagram =
    ( diagram
        "The file-oriented views: a revision has a tree, a tree contains directories and blobs, a \
        \blob has contents shown by the blob view, and the blame view attributes each line to the \
        \commit that last changed it, whose parent can be blamed in turn."
        body'
    )
        { dgCaption = do
            "The three views are one chain: a revision has a tree, a tree has files, a file has \
            \lines, and every line names a commit. The dashed aspect is the one that makes blame \
            \worth using — from a line's commit you can step to its "
            b_ "parent"
            " and blame the file as it was before that change, repeatedly, until you reach the \
            \commit that actually explains anything."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  rev  [label=\"a revision\", fillcolor=\"#f4efe6\"];"
            , "  tree [label=\"a tree\\n(the tree view)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  dir  [label=\"a directory\"];"
            , "  blob [label=\"a blob\\n(the blob view)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  line [label=\"a line\"];"
            , "  blame [label=\"the blame view\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  cmt  [label=\"a commit\"];"
            , "  par  [label=\"its parent\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  rev   -> tree  [label=\"  has as its\"];"
            , "  tree  -> dir   [label=\"  contains\"];"
            , "  dir   -> blob  [label=\"  contains\"];"
            , "  blob  -> line  [label=\"  is made of\"];"
            , "  blame -> line  [label=\"  annotates\"];"
            , "  line  -> cmt   [label=\"  was last changed by\"];"
            , "  cmt   -> par   [label=\"  has\"];"
            , "  par   -> blame [label=\"  , re-blames at\", style=dashed];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Browsing a repository that no longer exists" $ do
        p_ [class_ "lede"] $ do
            "Everything so far has been organised by commit. These three views are organised by "
            b_ "file"
            ", and they all share one property worth stating plainly: they show you the repository "
            i_ "at a revision"
            ", not the files on your disk. Put the cursor on a commit from 2023, press "
            k "t"
            ", and you are browsing 2023."
        p_ "The tree view at the top of a repository:"
        termStatus
            "tig — tree view"
            [ "Directory path /"
            , "drwxr-xr-x Ada Lovelace     2026-03-04 14:00 doc"
            , "drwxr-xr-x Ada Lovelace     2026-03-03 09:30 src"
            , "-rw-r--r-- Ada Lovelace  13 2026-03-01 10:00 README"
            ]
            "[tree] dee863b82257ff120494a06c731a44ba5678f9f8 - file 1 of 3"
            "100%"
        p_ $ do
            "Mode, author, size, date, name — and the title window holds the tree's own object ID. "
            k "Enter"
            " descends into a directory or opens a file in the blob view; "
            k ","
            " goes back up. It is non-recursive by default ("
            opt "recurse-tree"
            "), which is the right call in any repository large enough to need browsing."
        fig

    block "Blame, and the key that makes it useful" $ do
        p_ $ do
            k "b"
            " on any file opens the blame view: every line prefixed with the commit that last \
            \touched it."
        termStatus
            "tig — blame view"
            [ "785f586 Ada Lovelace 2026-03-03 09:30   1│ void parse(void) {}"
            , "0000000 Not Committed Yet 2026-09-17    2│ // TODO: handle errors"
            ]
            "[blame] 785f5869…:src/parser.c - line 1 of 2"
            "100%"
        p_ $ do
            "Lines you have edited but not committed show as "
            c "0000000"
            " with the author "
            c "Not Committed Yet"
            " — blame is being precise rather than unhelpful: those lines are not in history yet."
        p_ $ do
            "Now the part most people never find. Blame usually answers “who last touched this”, \
            \which is frequently somebody who reindented the file in 2021. Put the cursor on such a \
            \line and press "
            k ","
            ":"
        steps
            [ "tig takes the commit that owns the line under the cursor."
            , "It finds that commit's parent."
            , do
                "It re-blames the file "
                i_ "as it was at that parent"
                " — immediately before the change you were looking at."
            ]
        p_ $ do
            "Press it again and you step back another change. Four or five presses will usually \
            \take you past the reformatting, past the rename, and to the commit that actually \
            \introduced the logic. "
            k "<"
            " retraces your way back down."
        why $ p_ $ do
            "This is why blame lives in an interactive tool rather than a command. On the command \
            \line, stepping back one change means reading a hash, typing "
            c "git blame <hash>^ -- <file>"
            ", and finding your line again in the output. Doing that five times is enough work that \
            \nobody does it, so people accept the first answer blame gives them — which is usually \
            \the wrong one. Here it is one key."

    block "Teaching blame about moved code" $ do
        p_ $ do
            "The other way blame lies is about code that moved. Split a 500-line file in two and \
            \git will credit you with writing both halves, because as far as the default algorithm \
            \is concerned those lines are new in those files."
        defs
            [ (c "-C", "Look for the lines in other files modified by the same commit.")
            , (c "-C -C", "Also look at files the commit created.")
            , (c "-C -C -C", "Search every file in the parent commit.")
            ]
        p_ $ do
            "Try it one run at a time with "
            c "tig blame -C -C -C <file>"
            ", and when you are convinced, make it the default with "
            opt "blame-options"
            ". It costs time proportional to how hard you make it look, and on any repository where \
            \you actually care about the answer it is worth it."
        gotcha $ p_ $ do
            opt "blame-options"
            " is ignored when you start tig in blame mode "
            i_ "and"
            " pass blame options on the command line — the command line wins wholesale rather than \
            \merging. So "
            c "tig blame -w <file>"
            " silently drops your configured "
            c "-C -C -C"
            " rather than adding "
            c "-w"
            " to it. If you want both, pass both."

    block "Getting out to your editor" $ do
        p_ $ do
            k "e"
            " opens the file under the cursor in your editor, at the line you were on — tig passes "
            c "+<line>"
            " before the filename when "
            opt "editor-line-number"
            " is on, which it is by default."
        p_ $ do
            "Which editor gets used runs down a hierarchy: "
            c "TIG_EDITOR"
            ", then "
            c "$GIT_EDITOR"
            ", then "
            c "core.editor"
            ", then "
            c "$VISUAL"
            ", then "
            c "$EDITOR"
            ". The first of those exists so you can have a heavyweight editor for code and a light \
            \one for commit messages without them fighting."
        tip $ p_ $ do
            "The blame-to-editor path is the one worth making reflexive: "
            k "b"
            " to blame, "
            k ","
            " a few times to find the commit that explains the line, "
            k "Enter"
            " to read that commit in full, "
            k "q"
            " back, "
            k "e"
            " to go and fix it. That whole loop never touches the shell."

    block "Today's habit" $ do
        p_ $ do
            "Next time you are about to ask a colleague why some code is the way it is, spend \
            \ninety seconds with "
            k "b"
            " and "
            k ","
            " first. More often than not the commit message answers it, and you will have found \
            \the person who actually knows rather than the person who last reindented it."
        p_ "Tomorrow: the views that browse names instead of history."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "File views."
        " The second line is the one worth remembering."
    cfg
        [ "t  f  b       tree / blob / blame view for the current revision"
        , ",             blame: re-blame at the PARENT of this line's commit"
        , "              tree: go up one directory        <  retrace your steps"
        , "Enter         descend a directory, or open the file"
        , "e             open in $EDITOR at this line (TIG_EDITOR wins over GIT_EDITOR)"
        , "tig blame <rev> -- <file>     blame the file as it was then"
        , "tig blame -C -C -C <file>     follow code moved between files"
        , "set blame-options = -C -C -C  # make that the default"
        , "# 0000000 / 'Not Committed Yet' = your own uncommitted edits"
        ]
