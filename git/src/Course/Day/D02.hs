module Course.Day.D02 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 2
        , dayTitle = "The three states"
        , daySubtitle = "Working tree, index, HEAD — and the commands that move a change from one to the next."
        , dayMinutes = 35
        , dayLevel = "essential"
        , dayManRef = "DISCUSSION (the index); git-status(1), git-add(1), git-diff(1), git-restore(1), git-commit(1)"
        , dayTags = ["index", "staging", "status"]
        , dayGoals =
            [ "say, for any file, whether its working-tree, index and HEAD versions agree — and read that off " <> c "git status -s"
            , "build a commit out of part of your changes with " <> c "git add -p" <> ", and check it with " <> c "git diff --staged" <> " before it exists"
            , "undo a change at exactly the level you meant: unstage it, or throw it away"
            ]
        , dayDiagram = Just d2diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git status -s", "Show each changed path with two columns: index vs HEAD, then working tree vs index.")
            , ("git add <path>", "Copy the file's current contents into the index. Writes the blob immediately.")
            , ("git add -p", "Walk through each hunk and choose which ones go into the index.")
            , ("git diff", "Show what differs between the index and the working tree — what " <> c "add" <> " would stage.")
            , ("git diff --staged", "Show what differs between HEAD and the index — what " <> c "commit" <> " would record.")
            , ("git restore <path>", "Overwrite the working-tree file with the index version. Discards unstaged edits.")
            , ("git restore --staged <path>", "Reset the index entry to HEAD's version. The working tree is untouched.")
            , ("git commit [-a]", "Turn the index into a tree, wrap it in a commit, move the branch to it. " <> c "-a" <> " first stages every modified tracked file (never untracked ones).")
            , ("git rm --cached <path>", "Remove a path from the index only; the file stays on disk, now untracked.")
            ]
        , dayOpts =
            [ ("user.name / user.email", "Set the identity written into every commit's author and committer lines.")
            , ("init.defaultBranch", "Name the first branch of every new repository.")
            , ("commit.verbose", "Show the staged diff below the message in the commit editor.")
            ]
        , dayConfig =
            [ ConfBlock
                "Who you are. Git refuses to commit without this, and it is copied into\n\
                \every commit you make, so set it once here rather than per repository."
                "[user]\n\
                \\tname = Your Name\n\
                \\temail = you@example.com"
            , ConfBlock
                "git 2.52 still names the first branch 'master' and prints a hint saying\n\
                \the default becomes 'main' in Git 3.0. Settle it now; the hint goes away.\n\
                \The diff below the commit message means you write the message while\n\
                \looking at what you are actually committing."
                "[init]\n\
                \\tdefaultBranch = main\n\
                \[commit]\n\
                \\tverbose = true"
            ]
        , dayDrills =
            [ "In a real repository, run "
                <> c "git status -s"
                <> " and say out loud what each two-letter code means before reading on."
            , "Edit a tracked file, "
                <> c "git add"
                <> " it, then edit it again. Run "
                <> c "git status -s"
                <> " and find the "
                <> c "MM"
                <> ". Now compare "
                <> c "git diff"
                <> " with "
                <> c "git diff --staged"
                <> "."
            , "Make two unrelated edits in one file. Use "
                <> c "git add -p"
                <> " to stage only one of them, and commit it on its own."
            , "Break it on purpose: set "
                <> c "GIT_CONFIG_GLOBAL=/dev/null"
                <> " for one command and try "
                <> c "git commit --allow-empty -m test"
                <> " in a scratch repository. Read the identity error, then unset the variable."
            , "Stage a file, then take it back out of the index with "
                <> c "git restore --staged"
                <> ". Check that your edit is still in the file."
            , "In a scratch repository, commit a file you should not have, then "
                <> c "git rm --cached"
                <> " it and commit again. Confirm the file is still on disk and now shows as "
                <> c "??"
                <> "."
            , "Add the two config blocks from today to your "
                <> c "~/.gitconfig"
                <> ", with your real name and email, and run "
                <> c "git config --list --show-origin | grep -E 'user|init|commit'"
                <> "."
            , "From today, run "
                <> c "git diff --staged"
                <> " (or read the diff in the commit editor) before every commit. What you stage is what you ship."
            ]
        , dayQuiz =
            [
                ( "You edit "
                    <> c "notes.txt"
                    <> ", run "
                    <> c "git add notes.txt"
                    <> ", add one more line, and commit. The last line is not in the commit. Why?"
                , do
                    p_ $ do
                        c "git add"
                        " copied the file's contents into the index at the moment you ran it — it wrote a blob \
                        \and pointed the index entry at it. "
                        c "git commit"
                        " builds the snapshot from the index, not from the disk. Your later edit exists only in \
                        \the working tree, and "
                        c "git status -s"
                        " still shows the file as "
                        c " M"
                        " after the commit."
                    p_ $ do
                        "The index is not a list of file names to commit. It is a full set of file contents, \
                        \one step ahead of HEAD."
                )
            ,
                ( "A colleague runs "
                    <> c "git commit -a -m 'Add report'"
                    <> " and the new "
                    <> c "report.py"
                    <> " is not in the commit. What happened?"
                , p_ $ do
                    c "-a"
                    " stages every "
                    em_ "tracked"
                    " file that has been modified or deleted. A file git has never seen is not tracked, so "
                    c "-a"
                    " leaves it alone. The first "
                    c "git add report.py"
                    " is what makes it tracked; after that, "
                    c "-a"
                    " picks up its changes."
                )
            ,
                ( "You meant to unstage a file and ran "
                    <> c "git restore notes.txt"
                    <> " instead of "
                    <> c "git restore --staged notes.txt"
                    <> ". What did you lose?"
                , do
                    p_ $ do
                        "Every edit in the working tree that was not in the index. Without "
                        c "--staged"
                        ", "
                        c "restore"
                        " copies the index version over the working-tree file; nothing stored those unstaged \
                        \bytes, so git cannot give them back. The staged version survives, because it is a blob \
                        \in the object store."
                    p_ $ do
                        "The rule: "
                        c "restore"
                        " moves a version one step towards the working tree. "
                        c "--staged"
                        " targets the index; without it, the target is your file."
                )
            ,
                ( "You committed "
                    <> c "secrets.env"
                    <> ", then ran "
                    <> c "git rm --cached secrets.env"
                    <> " and committed again. Is the secret gone from the repository?"
                , p_ $ do
                    "No. The new commit's tree no longer lists the file, but the previous commit still names \
                    \its tree, which still names the blob — exactly the Day 1 gotcha. "
                    c "git rm --cached"
                    " stops tracking a file from now on. If the secret was ever pushed, rotate it; removing \
                    \it from history means rewriting history, and every clone still has it."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d2diagram :: Diagram
d2diagram =
    ( diagram
        "The three states: a file in the working tree is copied into the index by add; the index is \
        \turned into a commit's tree by commit; HEAD names the commit the index started from; restore \
        \copies versions back in the other direction."
        body'
    )
        { dgCaption = do
            "Every command today copies a version of a file one step along this line, and "
            c "git status"
            " is the report of where the three disagree. The index is the middle box, and it is a "
            b_ "whole snapshot"
            ", not a list of changes: after a commit, index and HEAD are identical and "
            c "git diff --staged"
            " is empty."
        , dgRankdir = "LR"
        , dgNodesep = "0.5"
        , dgRanksep = "0.7"
        }
  where
    body' =
        "  wt     [label=\"a working-tree file\", fillcolor=\"#f4efe6\"];\n\
        \  index  [label=\"an index entry\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  blob   [label=\"a blob\"];\n\
        \  commit [label=\"the commit\\nHEAD names\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \\n\
        \  wt     -> index  [label=\"  is copied into\\n  (add)\"];\n\
        \  index  -> blob   [label=\"  points at\"];\n\
        \  index  -> commit [label=\"  becomes the tree of\\n  (commit)\"];\n\
        \  commit -> index  [label=\"  is copied into\\n  (restore --staged)\", style=dashed];\n\
        \  index  -> wt     [label=\"  is copied into\\n  (restore)\", style=dashed];\n\
        \\n\
        \  { rank=same; index; blob; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Every file has three versions" $ do
        p_ [class_ "lede"] $ do
            "At any moment, a tracked file exists in three places: the "
            b_ "working tree"
            " (the file on disk you edit), the "
            b_ "index"
            " (the snapshot being assembled for the next commit), and "
            b_ "HEAD"
            " (the snapshot of the last commit). Every everyday command copies a version from one place \
            \to another, and "
            c "git status"
            " is a report of where the three disagree."
        p_ $ do
            "The manual page's DISCUSSION section describes the index as a list of all paths and, for each \
            \path, a blob and some attributes. Read that carefully: it is not a list of what changed. After a \
            \checkout or a commit the index holds the complete tree of HEAD, entry for entry. Editing a file \
            \makes the working tree differ from it; "
            c "git add"
            " makes the index catch up; "
            c "git commit"
            " freezes the index into a tree and a commit, and now HEAD has caught up too."
        p_ $ do
            "Connect it to Day 1. "
            c "git add"
            " is the moment the blob is written. Stage a file and look:"
        sh
            [ "$ echo four >> notes.txt"
            , "$ git add notes.txt"
            , "$ git ls-files -s notes.txt"
            , "100644 f384549cbeb481e437091320de6d1f2e15e11b4a 0\tnotes.txt"
            , "$ git cat-file -t f384549"
            , "blob"
            ]
        p_ $ do
            "The object exists before any commit does. "
            c "git commit"
            " only has to write trees and the commit itself, which is why it is fast however large the \
            \change."
        why $ p_ $ do
            "Most version-control systems commit whatever is on disk. git puts a stage in between so that a \
            \commit can be "
            em_ "composed"
            ": you can have a morning's tangled edits in the working tree and still make three clean commits \
            \out of them, each one reviewed as a diff before it exists. The cost is one extra concept. The \
            \index is also where merges keep their conflicting versions (Day 4) — it earns its place twice."
        fig

    block "Reading git status in two columns" $ do
        p_ $ do
            "The long form of "
            c "git status"
            " is readable but wordy. The short form packs the three-way comparison into two characters \
            \per path, and it is the one worth learning:"
        sh
            [ "$ git status -s"
            , " M app.py"
            , "MM notes.txt"
            , "?? scratch.log"
            ]
        defs
            [ ("left column", "HEAD versus index — what is staged. " <> c "M" <> " modified, " <> c "A" <> " added, " <> c "D" <> " deleted, " <> c "R" <> " renamed.")
            , ("right column", "Index versus working tree — what is not staged yet. Same letters.")
            , (c " M", "Changed on disk, nothing staged.")
            , (c "M ", "Staged, and the file on disk matches what is staged.")
            , (c "MM", "Staged, then edited again. The commit will contain the staged version only.")
            , (c "??", "Untracked: git has no index entry for it at all.")
            ]
        p_ $ do
            "The two diffs are the same two comparisons, spelled out. "
            c "git diff"
            " is the right column — index versus working tree, the changes you have not staged. "
            c "git diff --staged"
            " is the left column — HEAD versus index, the commit you are about to make. Plain "
            c "git diff"
            " is empty for a fully staged file, which surprises everyone once."
        gotcha $ p_ $ do
            c "MM"
            " is the trap. You "
            c "add"
            ", keep editing, and commit: the commit has the version from the moment you ran "
            c "add"
            ", and the later edits stay behind as "
            c " M"
            ". git is doing exactly what the model says, but nobody expects it the first time. When in \
            \doubt, "
            c "git diff --staged"
            " shows what will actually be recorded."

    block "Composing a commit" $ do
        p_ $ do
            c "git add <path>"
            " stages a whole file. "
            c "git add -p"
            " (patch mode) is the one that makes the index worth having: it shows each hunk and asks."
        sh
            [ "$ git add -p big.txt"
            , "@@ -1,5 +1,5 @@"
            , " line1"
            , "-line2"
            , "+LINE2"
            , " line3"
            , "(1/2) Stage this hunk [y,n,q,a,d,k,K,j,J,g,/,e,p,P,?]? n"
            , "@@ -15,6 +15,6 @@ line14"
            , "-line18"
            , "+LINE18"
            , "(2/2) Stage this hunk [y,n,q,a,d,K,J,g,/,e,p,P,?]? y"
            , "$ git status -s"
            , "MM big.txt"
            ]
        p_ $ do
            "Four answers carry most of the use: "
            k "y"
            " stage it, "
            k "n"
            " skip it, "
            k "s"
            " split it into smaller hunks (offered only when the hunk has unchanged lines between its \
            \changes — which is why it is missing from the prompt above), "
            k "q"
            " stop. "
            k "?"
            " explains the rest."
        p_ $ do
            "Then commit. "
            c "git commit"
            " opens your editor; with "
            opt "commit.verbose"
            " set (today's config), the staged diff appears below the message, under a scissors line git \
            \strips out. "
            c "git commit -a"
            " is the shortcut that stages every modified "
            em_ "tracked"
            " file first — convenient, and it never picks up a new file."
        tip $ p_ $ do
            "A commit that does one thing is easier to review, revert (Day 8) and bisect (Day 16). "
            c "add -p"
            " is how you get there without discipline in the moment: edit freely, then sort the hunks into \
            \commits afterwards."

    block "Undoing at the level you meant" $ do
        p_ $ do
            "The reverse direction is one command with one switch. "
            c "git restore"
            " copies a version one step back towards the working tree:"
        defs
            [ (c "git restore --staged f", "HEAD's version into the index. Unstages; your file on disk is untouched.")
            , (c "git restore f", "The index version onto the file on disk. Discards unstaged edits.")
            , (c "git rm --cached f", "Delete the index entry. The file stays on disk and becomes untracked.")
            ]
        gotcha $ p_ $ do
            "Only one of these destroys anything. "
            c "git restore f"
            " without "
            c "--staged"
            " overwrites bytes that git never stored — unstaged work is the one kind git cannot recover, \
            \not even with the reflog on Day 11. Stage something before an experiment and you have a blob to \
            \fall back on."
        note $ p_ $ do
            c "git restore"
            " arrived in 2.23 to take the file-level half of "
            c "git checkout"
            "'s job. Older answers online say "
            c "git checkout -- f"
            " and "
            c "git reset HEAD f"
            "; they still work, and Day 8 explains how "
            c "reset"
            " relates."

    block "Your first config lines" $ do
        p_ $ do
            "Git refuses to commit without an identity, and the identity is written into every commit — so \
            \it belongs in "
            c "~/.gitconfig"
            ", not typed per repository. Two more lines are worth having from the start. "
            c "git init"
            " in 2.52 still names the first branch "
            c "master"
            ", and says so at length:"
        sh
            [ "$ git init probe"
            , "hint: Using 'master' as the name for the initial branch. This default branch name"
            , "hint: will change to \"main\" in Git 3.0. To configure the initial branch name"
            , "hint: to use in all of your new repositories, which will suppress this warning,"
            , "hint: call:"
            , "hint:"
            , "hint: \tgit config --global init.defaultBranch <name>"
            ]
        p_ $ do
            "Setting "
            opt "init.defaultBranch"
            " makes new repositories match what most hosts already default to, and silences the hint. "
            opt "commit.verbose"
            " puts the diff where you write the message. The blocks below go into your file with real values; \
            \Day 12 explains where git looks for it and in what order."

    block "Today's habit" $ do
        p_ $ do
            "Replace "
            c "git commit -a"
            " with "
            c "git add -p"
            " followed by "
            c "git commit"
            " for a week. It is slower for three days and then it is how you think: every commit is \
            \something you have read."
        p_ "Tomorrow: what a branch actually is, and why creating one costs forty-one bytes."

cheat :: Html ()
cheat =
    cfg
        [ "git status -s               # left col: staged   right col: unstaged"
        , "git diff                    # index    -> working tree  (not yet staged)"
        , "git diff --staged           # HEAD     -> index         (what commit records)"
        , "git add FILE                # working tree -> index (writes the blob now)"
        , "git add -p                  # choose hunks: y n s q ?"
        , "git commit                  # index -> tree -> commit; branch moves"
        , "git restore --staged FILE   # HEAD  -> index         (unstage; safe)"
        , "git restore FILE            # index -> working tree  (discards edits!)"
        , "git rm --cached FILE        # stop tracking, keep the file"
        ]
