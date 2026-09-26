module Course.Day.D04 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 4
        , dayTitle = "Merging"
        , daySubtitle = "Two histories become one: the merge base, the fast-forward, and a conflict read properly."
        , dayMinutes = 35
        , dayLevel = "essential"
        , dayManRef = "DISCUSSION (merges, index stages); git-merge(1), git-merge-base(1), gitrevisions(7) :<n>:<path>"
        , dayTags = ["merge base", "fast-forward", "conflicts"]
        , dayGoals =
            [ "predict whether a merge will fast-forward or create a merge commit, before you run it"
            , "read a conflict in " <> c "zdiff3" <> " style and resolve it knowing what each side intended"
            , "inspect the three versions of a conflicted file, and abort a merge cleanly"
            ]
        , dayDiagram = Just d4diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git merge <branch>", "Bring the branch's history into the current one: fast-forward if possible, else a merge commit.")
            , ("git merge --ff-only <branch>", "Merge only if it is a fast-forward; otherwise refuse and change nothing.")
            , ("git merge --no-ff <branch>", "Always create a merge commit, even when a fast-forward was possible.")
            , ("git merge --abort", "Give up a conflicted merge and restore the state before it started.")
            , ("git merge-base A B", "Print the best common ancestor of two commits — the version a merge compares against.")
            , ("git ls-files -u", "List the unmerged index entries: one line per stage per conflicted path.")
            , ("git show :1:<path>", "Show the base version of a conflicted file. " <> c ":2:" <> " is yours, " <> c ":3:" <> " theirs.")
            , ("git checkout --conflict=merge <path>", "Recreate the conflict markers in a file you mangled; " <> c "=zdiff3" <> " works too.")
            ]
        , dayOpts =
            [ ("merge.conflictStyle", "Choose the marker style: " <> c "merge" <> " (default), " <> c "diff3" <> " or " <> c "zdiff3" <> ".")
            ]
        , dayConfig =
            [ ConfBlock
                "Show the common ancestor inside every conflict, not just the two sides.\n\
                \Without the base you can see what each side has, but not what each side\n\
                \changed. zdiff3 also moves lines both sides agree on out of the markers."
                "[merge]\n\
                \\tconflictStyle = zdiff3"
            ]
        , dayDrills =
            [ "In a real repository, pick two branches and run "
                <> c "git merge-base main <branch>"
                <> ". Then "
                <> c "git log --oneline -1"
                <> " that hash: it is where they parted."
            , "In a scratch repository, make a branch, commit on it, switch back and merge it. Read the word "
                <> c "Fast-forward"
                <> " and check with "
                <> c "git cat-file -p HEAD"
                <> " that no merge commit was made."
            , "Repeat with "
                <> c "--no-ff"
                <> ". Find the two "
                <> c "parent"
                <> " lines in the new commit."
            , "Break it on purpose: change the same line differently on two branches and merge. Run "
                <> c "git status"
                <> " and "
                <> c "git ls-files -u"
                <> ", then "
                <> c "git show :1:<file>"
                <> ", "
                <> c ":2:"
                <> " and "
                <> c ":3:"
                <> "."
            , "Abort that merge with "
                <> c "git merge --abort"
                <> " and check "
                <> c "git status"
                <> " is clean. Set "
                <> opt "merge.conflictStyle"
                <> " to "
                <> c "zdiff3"
                <> ", merge again, and compare the markers."
            , "Resolve it: edit the file to what it should be, "
                <> c "git add"
                <> " it, "
                <> c "git commit"
                <> ". Look at the result with "
                <> c "git log --oneline --graph"
                <> "."
            , "Before your next real merge, run "
                <> c "git merge --ff-only <branch>"
                <> " first. If it refuses, you have learned that the histories diverged — before anything \
                   \changed."
            , "From today, when you meet a conflict, read the base section first. Ask what each side "
                <> em_ "changed"
                <> ", not what each side has."
            ]
        , dayQuiz =
            [
                ( "You merge "
                    <> c "fix"
                    <> " into "
                    <> c "main"
                    <> " and git says “Fast-forward”. Your team lead wanted a merge commit to show the fix as a \
                       \unit. What happened, and how do you get one next time?"
                , p_ $ do
                    c "main"
                    " had not moved since "
                    c "fix"
                    " branched off, so the merge base was "
                    c "main"
                    " itself. There was nothing to combine: git moved the "
                    c "main"
                    " pointer forward to "
                    c "fix"
                    "'s commit, and the history is a straight line. "
                    c "git merge --no-ff fix"
                    " forces a merge commit with two parents even when a fast-forward was possible."
                )
            ,
                ( "In a conflict, the "
                    <> c "HEAD"
                    <> " side says "
                    <> c "timeout = 10"
                    <> " and the other says "
                    <> c "timeout = 60"
                    <> ". Which one is right?"
                , do
                    p_ $ do
                        "You cannot tell from two sides alone. If the base said "
                        c "timeout = 30"
                        ", both sides changed it deliberately and you have to ask why. If the base said "
                        c "timeout = 10"
                        ", only the other side changed it, and 60 is almost certainly right — but git would \
                        \not have reported a conflict then, so something else is going on."
                    p_ $ do
                        "This is the argument for "
                        c "zdiff3"
                        ": the "
                        c "|||||||"
                        " section shows the base, and a conflict becomes a question about two "
                        em_ "changes"
                        "."
                )
            ,
                ( "Halfway through resolving a conflict you make a mess of the file. How do you get the \
                  \original markers back without aborting the whole merge?"
                , p_ $ do
                    c "git checkout --conflict=merge <path>"
                    " (or "
                    c "=zdiff3"
                    "). The index still holds the three stages — base, ours, theirs — for every unresolved \
                    \path, so git can regenerate the conflicted file from them. Once you "
                    c "git add"
                    " the file the stages collapse to one and this no longer works; use "
                    c "git merge --abort"
                    " and start again."
                )
            ,
                ( "git already refuses to merge when your uncommitted edits touch a file the merge needs. So \
                  \why does the manual page still warn against merging with uncommitted changes?"
                , p_ $ do
                    "Because the refusal covers only the files that overlap at the start. Edits to other files \
                    \are carried through the merge, and once a conflict is open you are editing the working \
                    \tree again — your changes and the merge's are now mixed in the same place. git-merge(1) \
                    \says that "
                    c "git merge --abort"
                    " will “in some cases be unable to reconstruct the original (pre-merge) changes”, \
                    \especially if they were modified after the merge started. Commit or stash (Day 13) first, \
                    \and "
                    c "--abort"
                    " always has a clean state to return to."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d4diagram :: Diagram
d4diagram =
    ( diagram
        "A merge commit has two parents: the tip of the current branch and the tip of the merged \
        \branch; both descend from a merge base. During a conflict the index holds three stages of \
        \the path: base, ours and theirs."
        body'
    )
        { dgCaption = do
            "A merge compares "
            em_ "two changes against one base"
            ", not two files against each other. "
            b_ "the merge base"
            " is what makes a three-way merge possible, and it is also where the three index stages \
            \come from while a conflict is open. When the current tip "
            em_ "is"
            " the merge base, there is nothing to combine and git fast-forwards instead."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  merge  [label=\"a merge commit\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  ours   [label=\"the current tip\\n(ours)\"];\n\
        \  theirs [label=\"the merged tip\\n(theirs)\"];\n\
        \  base   [label=\"the merge base\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  entry  [label=\"a conflicted\\nindex entry\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  merge  -> ours   [label=\"  has as first parent\"];\n\
        \  merge  -> theirs [label=\"  has as second parent\"];\n\
        \  ours   -> base   [label=\"  descends from\"];\n\
        \  theirs -> base   [label=\"  descends from\"];\n\
        \  entry  -> base   [label=\"  has as stage 1\", style=dashed];\n\
        \  entry  -> ours   [label=\"  has as stage 2\", style=dashed];\n\
        \  entry  -> theirs [label=\"  has as stage 3\", style=dashed];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "A merge is a three-way comparison" $ do
        p_ [class_ "lede"] $ do
            "Merging two branches does not compare two files. It finds the commit where the histories \
            \parted — the "
            b_ "merge base"
            " — works out what each side changed since then, and applies both sets of changes. Where the \
            \changes touch different lines, git combines them silently. Where they touch the same lines \
            \differently, you get a conflict. Everything about merging follows from that."
        p_ $ do
            c "git merge-base"
            " shows you the commit git will use:"
        sh
            [ "$ git merge-base main slow"
            , "1e379e1fb16a6575af5c290c61e59601fa3a172e"
            ]
        p_ $ do
            "The result of a real merge is a commit with "
            b_ "two parents"
            ". The manual page's DISCUSSION puts it in one line: commits with more than one parent \
            \represent merges of independent lines of development. It is an ordinary commit otherwise — \
            \a tree, an author, a message — and its tree is the combined snapshot."
        why $ p_ $ do
            "Two-way comparison cannot merge anything. If one side has "
            c "retries = 5"
            " and the other "
            c "retries = 3"
            ", either side could have changed it. The base settles it: if the base said 3, only one side \
            \made a change, and that change wins with no human involved. This is why git merges most \
            \branches without asking, and why the base is the first thing to look at when it does ask."
        fig

    block "Fast-forward, or a merge commit" $ do
        p_ $ do
            "If the current branch has not moved since the other one branched off, the merge base "
            em_ "is"
            " the current tip. There is nothing to combine, so git moves the branch pointer forward and \
            \calls it a fast-forward:"
        sh
            [ "$ git merge fix"
            , "Updating df97b49..014bdc9"
            , "Fast-forward"
            , " config.toml | 2 +-"
            , " 1 file changed, 1 insertion(+), 1 deletion(-)"
            ]
        p_ $ do
            "No new commit; "
            c "main"
            " now names the same commit as "
            c "fix"
            ". "
            c "--no-ff"
            " makes a merge commit anyway, which some teams prefer so that a feature appears in history as \
            \one unit:"
        sh
            [ "$ git merge --no-ff -m \"Merge branch 'feat2'\" feat2"
            , "Merge made by the 'ort' strategy."
            , "$ git log --oneline --graph"
            , "*   1e379e1 Merge branch 'feat2'"
            , "|\\"
            , "| * 72a9d3f Add log level"
            , "|/"
            , "* 014bdc9 More retries"
            , "* df97b49 Initial config"
            ]
        p_ $ do
            "The opposite switch, "
            c "--ff-only"
            ", merges only if a fast-forward is possible and refuses otherwise. It is the safe way to ask \
            \“has anything happened on my side?” — if it refuses, nothing has changed:"
        sh
            [ "$ git merge --ff-only slow"
            , "hint: Diverging branches can't be fast-forwarded, you need to either:"
            , "hint:"
            , "hint: \tgit merge --no-ff"
            , "hint:"
            , "hint: or:"
            , "hint:"
            , "hint: \tgit rebase"
            , "fatal: Not possible to fast-forward, aborting."
            ]
        note $ p_ $ do
            c "ort"
            " is the default merge strategy, named in the manual page as such. Day 17 covers strategies and their \
            \options; for now it is the name in the message."

    block "Reading a conflict" $ do
        p_ $ do
            "Both branches changed the same line: one lowered a timeout to 10, the other raised it to 60. \
            \git stops, writes markers into the file, and leaves the merge half-done:"
        sh
            [ "$ git merge slow"
            , "Auto-merging config.toml"
            , "CONFLICT (content): Merge conflict in config.toml"
            , "Automatic merge failed; fix conflicts and then commit the result."
            , "$ git status -s"
            , "UU config.toml"
            ]
        p_ $ do
            "With the default "
            c "merge"
            " style, the file shows the two sides and nothing else. With "
            c "zdiff3"
            " (today's config line) it shows the base between them, after "
            c "|||||||"
            ":"
        cols
            [ cfg
                [ "# conflictStyle = merge (default)"
                , "<<<<<<< HEAD"
                , "timeout = 10"
                , "======="
                , "timeout = 60"
                , ">>>>>>> slow"
                ]
            , cfg
                [ "# conflictStyle = zdiff3"
                , "<<<<<<< HEAD"
                , "timeout = 10"
                , "||||||| 1e379e1"
                , "timeout = 30"
                , "======="
                , "timeout = 60"
                , ">>>>>>> slow"
                ]
            ]
        p_ $ do
            "Now the conflict is legible: the base was 30, one side cut it to 10, the other raised it to \
            \60. Those are two decisions, and choosing between them is a conversation, not a guess. The "
            c "z"
            " in "
            c "zdiff3"
            " is for “zealous”: lines that both sides changed identically are moved outside the markers \
            \instead of being repeated on both sides. Where the two styles differ, it looks like this:"
        cols
            [ cfg
                [ "# diff3"
                , "<<<<<<< HEAD"
                , "def greet(name):"
                , "    print(\"hey\", name)"
                , "||||||| bfa1f83"
                , "def greet():"
                , "    print(\"hi\")"
                , "======="
                , "def greet(name):"
                , "    print(\"hello\", name)"
                , ">>>>>>> other"
                ]
            , cfg
                [ "# zdiff3"
                , "def greet(name):"
                , "<<<<<<< HEAD"
                , "    print(\"hey\", name)"
                , "||||||| bfa1f83"
                , "def greet():"
                , "    print(\"hi\")"
                , "======="
                , "    print(\"hello\", name)"
                , ">>>>>>> other"
                ]
            ]
        gotcha $ p_ $ do
            "Conflict markers are plain text, and git does not check that you removed them. "
            c "git add"
            " on a file still full of "
            c "<<<<<<<"
            " marks it resolved and the markers get committed. Search for them before you add — or run "
            c "git diff --check"
            ", which flags leftover markers."

    block "Three versions in the index" $ do
        p_ $ do
            "Yesterday the index held one entry per path. During a conflict it holds up to three, called "
            b_ "stages"
            ": 1 is the base, 2 is ours (the branch you are on), 3 is theirs (the branch being merged). \
            \The DISCUSSION section mentions them in its last paragraph; this is where they matter."
        sh
            [ "$ git ls-files -u"
            , "100644 40e3f0b64f3c622c45c61f863cc3ceaf5b75a7b8 1\tconfig.toml"
            , "100644 c55159fc863ec40e5ac6dce41e6cac7184cb2eb4 2\tconfig.toml"
            , "100644 b04b1a5aff230654988fece33540344191d4d477 3\tconfig.toml"
            , "$ git show :1:config.toml | grep timeout"
            , "timeout = 30"
            , "$ git show :2:config.toml | grep timeout"
            , "timeout = 10"
            , "$ git show :3:config.toml | grep timeout"
            , "timeout = 60"
            ]
        p_ $ do
            "That "
            c ":<n>:<path>"
            " syntax is part of the revision language (Day 7). The stages are also why "
            c "git checkout --conflict=zdiff3 config.toml"
            " can rebuild the markers if you mangle the file: the three versions are still in the index."
        steps
            [ "Edit the file to what it should be. Remove every marker."
            , do
                c "git add config.toml"
                " — the three stages collapse back into one entry, and "
                c "git status"
                " stops listing it as unmerged."
            , do
                c "git commit"
                " — git has kept the merge's second parent in "
                c ".git/MERGE_HEAD"
                " and pre-writes the message. The result is the two-parent commit."
            ]
        p_ $ do
            "Or give up: "
            c "git merge --abort"
            " puts the branch, index and working tree back where they were before "
            c "git merge"
            "."
        tip $ p_ $ do
            "Merge with a clean working tree. Uncommitted changes that do not overlap the merge are left \
            \alone, but if you then abort, git may not be able to separate your edits from its own. \
            \“Commit or stash first” turns "
            c "--abort"
            " into a guaranteed undo."

    block "Today's habit" $ do
        p_ $ do
            "Set "
            opt "merge.conflictStyle"
            " to "
            c "zdiff3"
            " and never read a two-sided conflict again. When one appears, read the base first, then ask \
            \each side's author — or each side's commit message — why they changed it."
        p_ "Tomorrow: the same ideas, when one of the branches lives on another machine."

cheat :: Html ()
cheat =
    cfg
        [ "git merge-base A B              # where they parted: the base of the 3-way merge"
        , "git merge BRANCH                # fast-forward if possible, else a 2-parent commit"
        , "git merge --ff-only BRANCH      # refuse unless it is a fast-forward"
        , "git merge --no-ff BRANCH        # always a merge commit"
        , "git ls-files -u                 # conflicted paths, one line per stage"
        , "git show :1:F  :2:F  :3:F       # base, ours, theirs"
        , "git checkout --conflict=zdiff3 F # rebuild the markers"
        , "git add F && git commit         # resolved; MERGE_HEAD becomes parent 2"
        , "git merge --abort               # back to before the merge"
        ]
