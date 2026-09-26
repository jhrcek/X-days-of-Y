module Course.Day.D03 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 3
        , dayTitle = "Branches are pointers"
        , daySubtitle = "A branch is a file holding one hash. HEAD is a file naming a branch. Everything else follows."
        , dayMinutes = 30
        , dayLevel = "essential"
        , dayManRef = "DISCUSSION (refs), SYMBOLIC IDENTIFIERS; git-branch(1), git-switch(1)"
        , dayTags = ["refs", "HEAD", "detached HEAD"]
        , dayGoals =
            [ "explain what moves, and what does not, when you commit, create a branch or switch to one"
            , "create, switch, rename and delete branches without reaching for a GUI"
            , "recognise a detached HEAD, and leave it without losing the commits you made there"
            ]
        , dayDiagram = Just d3diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git branch", "List local branches; " <> c "*" <> " marks the one HEAD names.")
            , ("git branch -v", "List branches with the commit each points at and its subject line.")
            , ("git branch <name>", "Create a branch at HEAD without switching to it.")
            , ("git switch <branch>", "Point HEAD at a branch and update the index and working tree to its commit.")
            , ("git switch -c <name>", "Create a branch at HEAD and switch to it in one step.")
            , ("git switch -", "Switch back to the branch you were on before.")
            , ("git switch --detach <commit>", "Point HEAD directly at a commit, with no branch in between.")
            , ("git branch -d <name>", "Delete a branch, refusing unless it is merged into its upstream (or into HEAD, if it has none).")
            , ("git branch -D <name>", "Delete a branch unconditionally.")
            , ("git branch -m <old> <new>", "Rename a branch.")
            ]
        , dayOpts =
            [ ("branch.sort", "Set the default order of " <> c "git branch" <> "; " <> c "-committerdate" <> " puts recent work first.")
            ]
        , dayConfig =
            [ ConfBlock
                "List branches most-recently-committed first. Alphabetical order puts\n\
                \the branch you touched this morning somewhere in the middle of forty."
                "[branch]\n\
                \\tsort = -committerdate"
            ]
        , dayDrills =
            [ "In a real repository, run "
                <> c "cat .git/HEAD"
                <> ", then "
                <> c "git branch -v"
                <> ". Match the two up."
            , "Create a branch with "
                <> c "git switch -c try"
                <> ", commit something, and run "
                <> c "git branch -v"
                <> " again. Only one line changed its hash."
            , "Use "
                <> c "git switch -"
                <> " three times in a row and watch where you land each time."
            , "Break it on purpose: on "
                <> c "main"
                <> ", run "
                <> c "git branch -d try"
                <> ". Read the refusal, then decide whether "
                <> c "-D"
                <> " is what you actually want."
            , "In a scratch repository, "
                <> c "git switch --detach HEAD~1"
                <> ", make a commit, then "
                <> c "git switch main"
                <> ". Copy the hash from the warning and rescue the commit with "
                <> c "git branch rescued <hash>"
                <> "."
            , "Rename a badly named branch of your own with "
                <> c "git branch -m"
                <> ". If it was pushed, note that the remote still has the old name (Day 5)."
            , "Add today's "
                <> opt "branch.sort"
                <> " line to your "
                <> c "~/.gitconfig"
                <> " and run "
                <> c "git branch"
                <> " in your busiest repository."
            , "From today, start every piece of work with "
                <> c "git switch -c <name>"
                <> ". A branch costs one small file; not having one costs you the ability to put the work \
                   \aside."
            ]
        , dayQuiz =
            [
                ( "You create a branch "
                    <> c "feature"
                    <> " while on "
                    <> c "main"
                    <> ", but forget to switch, and commit. Which branch has the new commit?"
                , p_ $ do
                    c "main"
                    ". "
                    c "git branch feature"
                    " wrote a second file holding the same hash, and nothing else. HEAD still said "
                    c "ref: refs/heads/main"
                    ", so the commit moved "
                    c "main"
                    ". "
                    c "feature"
                    " still points at the commit before. Only the branch HEAD names ever moves on commit — \
                    \which is why "
                    c "switch -c"
                    " exists as one step."
                )
            ,
                ( c "git switch 72da6fa"
                    <> " fails with “a branch is expected, got commit”. Why does git make you type "
                    <> c "--detach"
                    <> "?"
                , do
                    p_ $ do
                        "Because switching to a commit rather than a branch changes what committing means. \
                        \With HEAD naming a branch, a commit moves the branch. With HEAD holding a hash \
                        \directly, a commit moves only HEAD, and no branch remembers the new work."
                    p_ $ do
                        c "git checkout 72da6fa"
                        " detaches without being asked — it prints a paragraph of advice, which is how a \
                        \generation of users learned to scroll past it and ended up there by accident. "
                        c "switch"
                        " makes you say it."
                )
            ,
                ( "You committed twice on a detached HEAD, then switched to "
                    <> c "main"
                    <> " and closed the terminal without reading the warning. Are the commits gone?"
                , p_ $ do
                    "Not yet. They are still objects in the store; they are only unreachable, because no \
                    \branch names them. Every position HEAD has held is recorded in the reflog, so "
                    c "git reflog"
                    " lists them and "
                    c "git branch rescued <hash>"
                    " gives them a name again. Day 11 covers this properly. Unreachable objects are eventually \
                    \pruned by garbage collection, so do it this week rather than next quarter."
                )
            ,
                ( c "git branch -d old-work"
                    <> " refuses: “not fully merged”. But you merged it last month. What is git \
                       \checking?"
                , p_ $ do
                    "Whether the branch's commit is reachable from its upstream right now — or, if the branch has \
                    \no upstream, from HEAD. If you are on a different branch from the one you merged into, or \
                    \the merge was a squash or rebase that made new commits with the same content, the \
                    \original commits are not ancestors of HEAD and git cannot tell they were integrated. \
                    \Switch to the branch you merged into and try again; if it still refuses and you are \
                    \sure, "
                    c "-D"
                    " is the honest answer."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d3diagram :: Diagram
d3diagram =
    ( diagram
        "HEAD names a branch, a branch names a commit, a commit has a parent. In detached state HEAD \
        \names a commit directly. Committing moves whatever HEAD resolves through."
        body'
    )
        { dgCaption = do
            "There are two kinds of pointer here, and the whole day is about the difference. "
            b_ "HEAD"
            " normally names a branch, and "
            b_ "a branch"
            " names a commit; a new commit moves the branch HEAD names, and HEAD follows along without \
            \changing. The dashed aspect is the detached state: HEAD names a commit directly, so a new \
            \commit moves HEAD alone and no branch remembers it."
        , dgRankdir = "TB"
        , dgRanksep = "0.5"
        }
  where
    body' =
        "  head   [label=\"HEAD\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  branch [label=\"a branch\\n(refs/heads/<name>)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  commit [label=\"a commit\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  file   [label=\"a 41-byte file\\nin .git/refs/heads\", fillcolor=\"#f4efe6\"];\n\
        \\n\
        \  head   -> branch [label=\"  names\"];\n\
        \  head   -> commit [label=\"  names directly\\n  (detached)  \", style=dashed];\n\
        \  branch -> commit [label=\"  names\"];\n\
        \  branch -> file   [label=\"  is stored as\"];\n\
        \  commit -> commit [label=\"  has as parent\"];\n\
        \\n\
        \  { rank=same; branch; file; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "A branch is forty-one bytes" $ do
        p_ [class_ "lede"] $ do
            "A branch is not a copy of anything, not a line of development, not a container of commits. It \
            \is a file in "
            c ".git/refs/heads/"
            " containing one commit hash and a newline. Creating one writes that file; committing on one \
            \rewrites it. The history the branch “has” is everything reachable from that commit by \
            \following parents."
        sh
            [ "$ git switch -c feature"
            , "Switched to a new branch 'feature'"
            , "$ cat .git/HEAD"
            , "ref: refs/heads/feature"
            , "$ cat .git/refs/heads/feature .git/refs/heads/main"
            , "72da6fa2ba428bd5eafc0699d5e7adf1b9e9e80d"
            , "72da6fa2ba428bd5eafc0699d5e7adf1b9e9e80d"
            , "$ git commit -qam 'Feature work'"
            , "$ git branch -v"
            , "* feature 29abc22 Feature work"
            , "  main    72da6fa Start"
            ]
        p_ $ do
            "Two branches, same hash, until the commit. Then only "
            c "feature"
            " moved. How did git know which to move? Because of the second pointer, "
            b_ "HEAD"
            ". The manual page defines it in one line under SYMBOLIC IDENTIFIERS — “the head of the \
            \current branch” — and in DISCUSSION it is a "
            em_ "symbolic ref"
            ": a ref whose content is the name of another ref, not a hash."
        why $ p_ $ do
            "Making branches this cheap is a design choice with consequences all through git. Because a \
            \branch costs nothing, you are expected to make one for every piece of work and throw it away \
            \afterwards. Because a branch is only a name for a commit, “which branch is this commit on?” is \
            \not a question git stores an answer to — a commit is on every branch it can be reached from, \
            \and a merge is a commit that makes two histories reachable from one name."
        fig

    block "Switching moves HEAD, then the files" $ do
        p_ $ do
            c "git switch <branch>"
            " does two things: rewrites "
            c ".git/HEAD"
            " to name the branch, and updates the index and working tree from HEAD's old commit to the new \
            \one. Files that did not change between the two commits are not touched at all, which is why \
            \switching in a large repository is usually instant."
        defs
            [ (c "git switch -c name", "Create at HEAD and switch. The one you type most.")
            , (c "git switch -", "Back to the previous branch, like " <> c "cd -" <> ".")
            , (c "git branch name", "Create without switching. Rarely what you want mid-work.")
            , (c "git branch -m old new", "Rename: move the ref file, and its reflog with it.")
            , (c "git branch -d name", "Delete, if its commit is merged. " <> c "-D" <> " deletes regardless.")
            ]
        p_ $ do
            "Uncommitted changes travel with you when you switch, as long as the files they touch are the \
            \same in both commits. When they are not, git refuses rather than overwrite them — commit, or \
            \stash them (Day 13), then switch."
        sh
            [ "$ git branch -d feature"
            , "error: the branch 'feature' is not fully merged"
            , "hint: If you are sure you want to delete it, run 'git branch -D feature'"
            , "$ git branch -D feature"
            , "Deleted branch feature (was 29abc22)."
            ]
        tip $ p_ $ do
            "Note the “"
            c "(was 29abc22)"
            "” git prints when it deletes a branch. That hash is all you need to put the branch back: "
            c "git branch feature 29abc22"
            ". Deleting a branch deletes the name, never the commits."

    block "Detached HEAD" $ do
        p_ $ do
            "HEAD can also hold a commit hash directly. That is the "
            b_ "detached HEAD"
            " state, and it is what you get when you check out a tag, an old commit, or a remote branch \
            \without creating a local one. It is useful — for looking around, for building an old version, \
            \for bisecting (Day 16) — and "
            c "git switch"
            " makes you ask for it explicitly:"
        sh
            [ "$ git switch 72da6fa"
            , "fatal: a branch is expected, got commit '72da6fa'"
            , "hint: If you want to detach HEAD at the commit, try again with the --detach option."
            , "$ git switch --detach 72da6fa"
            , "HEAD is now at 72da6fa Start"
            , "$ cat .git/HEAD"
            , "72da6fa2ba428bd5eafc0699d5e7adf1b9e9e80d"
            ]
        p_ $ do
            "You can commit here. The commit moves HEAD, and nothing else. When you switch away, the only \
            \pointer to it is gone — and git tells you, once:"
        sh
            [ "$ git commit -qam 'Detached work'"
            , "$ git switch main"
            , "Warning: you are leaving 1 commit behind, not connected to"
            , "any of your branches:"
            , ""
            , "  50c6022 Detached work"
            , ""
            , "If you want to keep it by creating a new branch, this may be a good time"
            , "to do so with:"
            , ""
            , " git branch <new-branch-name> 50c6022"
            ]
        gotcha $ p_ $ do
            "That warning is the only time git will show you the hash. It scrolls away with the next \
            \command. The commit is not deleted — Day 11's reflog can still find it — but the path of least \
            \resistance is to run "
            c "git switch -c <name>"
            " "
            em_ "before"
            " committing whenever "
            c "git status"
            " starts with "
            c "HEAD detached at"
            "."

    block "A branch list you can read" $ do
        p_ $ do
            c "git branch"
            " sorts alphabetically. After a few months a repository has dozens of branches, and the ones \
            \you care about are the ones you touched recently. "
            opt "branch.sort"
            " takes any "
            c "git for-each-ref"
            " field; "
            c "-committerdate"
            " is newest first:"
        sh
            [ "$ git branch -v"
            , "  alpha  7be1a36 a"
            , "* main   ac874fc Second"
            , "  middle ac874fc Second"
            , "  zebra  7be3672 Zebra fix"
            , "$ git -c branch.sort=-committerdate branch -v"
            , "* main   ac874fc Second"
            , "  middle ac874fc Second"
            , "  zebra  7be3672 Zebra fix"
            , "  alpha  7be1a36 a"
            ]
        note $ p_ $ do
            c "git -c key=value"
            " sets a config value for one command only — a safe way to try any line before it goes into \
            \your file. Day 12 covers it with the rest of the config machinery."

    block "Today's habit" $ do
        p_ $ do
            "Start every piece of work, however small, with "
            c "git switch -c"
            ". When "
            c "git status"
            " says "
            c "HEAD detached"
            ", stop and make a branch before doing anything else."
        p_ "Tomorrow: what happens when two branches that moved independently have to become one."

cheat :: Html ()
cheat =
    cfg
        [ "cat .git/HEAD               # ref: refs/heads/main   (or a bare hash: detached)"
        , "git branch -v               # every branch, its commit, its subject"
        , "git switch -c NAME          # create at HEAD and switch"
        , "git switch NAME             # move HEAD, then the files"
        , "git switch -                # previous branch"
        , "git switch --detach COMMIT  # HEAD holds a hash; commits here belong to no branch"
        , "git branch -m OLD NEW       # rename"
        , "git branch -d NAME          # delete if merged   (-D: regardless)"
        , "git branch NAME HASH        # undelete, from the '(was ...)' hash"
        ]
