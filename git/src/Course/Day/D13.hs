module Course.Day.D13 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 13
        , dayTitle = "Stash and worktrees"
        , daySubtitle = "Putting work aside: a stash is a commit nobody named, a worktree is a second checkout of the same repository."
        , dayMinutes = 30
        , dayLevel = "intermediate"
        , dayManRef = "git-stash(1), git-worktree(1); GIT_COMMON_DIR"
        , dayTags = ["stash", "worktree", "interruptions"]
        , dayGoals =
            [ "stash exactly the changes you mean — staged, unstaged, untracked or one path — and get them back intact"
            , "read a stash as the commit it is, and recover from a pop that conflicted"
            , "take an urgent fix on another branch in a second worktree without disturbing what you had open"
            ]
        , dayDiagram = Just d13diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git stash push -m <msg>", "Save staged and unstaged changes to tracked files as a stash entry, and clean the tree.")
            , ("git stash push -u", "Include untracked files. " <> c "-a" <> " also takes ignored ones.")
            , ("git stash push --staged", "Stash only what is in the index.")
            , ("git stash list", "List entries; " <> c "stash@{0}" <> " is the newest.")
            , ("git stash show -p [stash@{n}]", "Show an entry as a patch. Add " <> c "--include-untracked" <> " to see its untracked files.")
            , ("git stash apply [--index]", "Reapply an entry and keep it. " <> c "--index" <> " restores what was staged as staged.")
            , ("git stash pop [--index]", "Apply, and drop the entry only if it applied cleanly.")
            , ("git stash drop [stash@{n}]", "Delete one entry.")
            , ("git stash branch <name>", "Create a branch at the commit the stash was made on, apply it there, drop it.")
            , ("git worktree add <path> [-b <new>] [<branch>]", "Check out a branch in a new directory that shares this repository.")
            , ("git worktree list", "List every working tree with its HEAD and branch.")
            , ("git worktree remove <path>", "Delete a clean worktree. " <> c "git worktree prune" <> " forgets ones you deleted by hand.")
            ]
        , dayOpts = []
        , dayConfig = []
        , dayDrills =
            [ "Make a small edit in a repository you work in, run "
                <> c "git stash push -m 'drill'"
                <> ", confirm "
                <> c "git status"
                <> " is clean, then "
                <> c "git stash pop"
                <> "."
            , "Stage one change and leave another unstaged. Stash, then "
                <> c "git stash pop"
                <> " without "
                <> c "--index"
                <> ", and look at "
                <> c "git status -s"
                <> ". Repeat with "
                <> c "--index"
                <> "."
            , "Stash something and run "
                <> c "git log --oneline --graph stash@{0} -3"
                <> ". Identify the three commits and say what each one holds."
            , "Create a new file, run plain "
                <> c "git stash"
                <> ", and notice the file is still there. Then "
                <> c "git stash push -u"
                <> "."
            , "Break it on purpose: stash an edit to a file, commit a different edit to the same line, and "
                <> c "git stash pop"
                <> ". Read the message, confirm with "
                <> c "git stash list"
                <> " that the entry survived, resolve, and "
                <> c "git stash drop"
                <> "."
            , "Try to check out the same branch twice: "
                <> c "git worktree add ../dup main"
                <> " (or whatever branch you are on). Read the error."
            , "Next time an urgent fix interrupts real work, do it in "
                <> c "git worktree add ../hotfix -b hotfix origin/main"
                <> ", then "
                <> c "git worktree remove ../hotfix"
                <> " when it is merged."
            , "Adopt a rule: a stash lives for minutes. Anything you would still want tomorrow goes on a branch, \
              \as a commit, with a name."
            ]
        , dayQuiz =
            [
                ( "You stashed, fixed a bug, and ran "
                    <> c "git stash pop"
                    <> ". It reported a conflict. Is your stashed work gone?"
                , p_ $ do
                    "No. "
                    c "pop"
                    " only drops the entry if it applied cleanly; on conflict it says “The stash entry is kept in \
                    \case you need it again.” Resolve the conflict as you would a merge (Day 4), then "
                    c "git stash drop"
                    " yourself. If you would rather start over, "
                    c "git reset --hard"
                    " and the entry is still in "
                    c "git stash list"
                    ", untouched."
                )
            ,
                ( "Before stashing, half of your changes were staged. After "
                    <> c "git stash pop"
                    <> " everything is unstaged. Did git lose information?"
                , do
                    p_ $ do
                        "No, it chose not to use it. A stash records the index as its own commit (the second parent), \
                        \but "
                        c "apply"
                        " and "
                        c "pop"
                        " restore only the working tree unless you pass "
                        c "--index"
                        ". The staged state is still in the entry until you drop it."
                    p_ "The default is the cautious one: git-stash(1) warns that --index can fail when there are conflicts, because conflicts are themselves stored in the index, so the staged state has nowhere to go. Without it, a pop succeeds in more cases."
                )
            ,
                ( "You run "
                    <> c "git stash"
                    <> " to get a clean tree for a quick test, and the test still sees your new "
                    <> c "config.local"
                    <> " file. Why?"
                , p_ $ do
                    "Plain "
                    c "git stash"
                    " takes changes to tracked files only. An untracked file is not a change git knows about, so \
                    \it stays. "
                    c "git stash push -u"
                    " takes untracked files too, as a third parent commit; "
                    c "-a"
                    " also takes ignored ones — build output included, which is usually not what you want."
                )
            ,
                ( "In a second worktree you run "
                    <> c "git stash list"
                    <> " and see entries you made in the first one. Is that a bug?"
                , p_ $ do
                    "No. Worktrees share everything except their own "
                    c "HEAD"
                    ", index and working files. Refs are shared, and a stash is a ref ("
                    c "refs/stash"
                    ") with a reflog. So "
                    c "git stash pop"
                    " in the wrong worktree will cheerfully apply work from the other one. Look at the message \
                    \(“On main: …”) before popping, or use a branch instead."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d13diagram :: Diagram
d13diagram =
    ( diagram
        "A stash entry is a merge-shaped commit whose first parent is the commit you were on, whose \
        \second parent is a commit of the index, and whose optional third parent is a commit of untracked \
        \files. A worktree has its own HEAD and index but shares the object store and refs, which hold \
        \the stash, with every other worktree."
        body'
    )
        { dgCaption = do
            "Both ways of putting work aside reduce to things you already know. "
            b_ "A stash entry"
            " is an ordinary commit with two or three parents, named only by a reflog position; "
            b_ "a worktree"
            " is a second "
            c "HEAD"
            " and index looking into the same store. Because the store and refs are shared, a stash made in \
            \one worktree is visible in all of them — and a branch can be checked out in only one."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  stash [label=\"a stash entry\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  base  [label=\"the commit you were on\"];\n\
        \  idx   [label=\"a commit of the index\"];\n\
        \  untr  [label=\"a commit of\\nuntracked files\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  wt    [label=\"a worktree\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  own   [label=\"a HEAD, an index\\nand a directory of files\"];\n\
        \  store [label=\"the object store and refs\", fillcolor=\"#f4efe6\"];\n\
        \  br    [label=\"a branch\"];\n\
        \\n\
        \  stash -> base  [label=\"  has as first parent\"];\n\
        \  stash -> idx   [label=\"  has as second parent\"];\n\
        \  stash -> untr  [label=\"  has as third parent\\n  (with -u)\", style=dashed];\n\
        \  wt    -> own   [label=\"  has its own\"];\n\
        \  wt    -> store [label=\"  shares\"];\n\
        \  store -> stash [label=\"  holds, as refs/stash,\"];\n\
        \  wt    -> br    [label=\"  has checked out\", style=dashed];\n\
        \\n\
        \  { rank=same; wt; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "A stash is a commit nobody named" $ do
        p_ [class_ "lede"] $ do
            c "git stash"
            " looks like a clipboard. It is not: it writes your uncommitted changes as real commits, points "
            c "refs/stash"
            " at them, and resets your working tree. Everything about how stashes behave — what they keep, \
            \what they lose, how to recover one — follows from the fact that they are commits with an odd \
            \shape and no branch."
        sh
            [ "$ git stash push -m 'half-done parser'"
            , "Saved working directory and index state On main: half-done parser"
            , "$ git cat-file -p stash@{0}"
            , "tree b2b0d4dad20fa5d7acd7263db2c65251c2a12cd8"
            , "parent 1c945ee234a20b74da5c8b5ba036d6220e457bae"
            , "parent dcfc219b813e26eb679c8a90bc7d8b0abf94c675"
            , "author Ada Example <ada@example.com> 1790319600 +0200"
            , "committer Ada Example <ada@example.com> 1790319600 +0200"
            , ""
            , "On main: half-done parser"
            , "$ git log --oneline --graph stash@{0}"
            , "*   7f88f5c On main: half-done parser"
            , "|\\  "
            , "| * dcfc219 index on main: 1c945ee Initial"
            , "|/  "
            , "* 1c945ee Initial"
            ]
        p_ $ do
            "Read it with Day 1's eyes. The entry is a commit whose tree is your working tree. Its first parent \
            \is the commit you were on. Its second parent is a separate commit of your "
            b_ "index"
            ", so the difference between staged and unstaged survives. Stash with "
            c "-u"
            " and a third parent appears holding your untracked files."
        p_ $ do
            c "stash@{0}"
            " is the revision syntax from Day 7: entry "
            var "n"
            " of the reflog of "
            c "refs/stash"
            ". That is the only thing listing your stashes — there is no stash database — which is why "
            c "git stash drop"
            " renumbers everything above it."
        why $ p_ $ do
            "Making stashes commits means git needed no new storage, no new merge logic and no new recovery \
            \story. Applying a stash is a three-way merge against its base, so it works after you have moved \
            \on. A dropped stash is an unreachable commit, so Day 11's "
            c "git fsck --unreachable"
            " can find it again."
        fig

    block "Choosing what goes in" $ do
        p_ "The defaults are not “everything”, and that is the source of most stash surprises."
        defs
            [ (c "git stash", "Staged and unstaged changes to tracked files. Untracked and ignored files stay where they are.")
            , (c "git stash push -m 'msg'", "The same, with a message you will recognise in the list. Always give one.")
            , (c "git stash push -u", "Also untracked files, as the third parent.")
            , (c "git stash push -a", "Also ignored files. Usually wrong: it sweeps up build output and caches.")
            , (c "git stash push --staged", "Only what is in the index — handy for setting aside a half-finished commit.")
            , (c "git stash push -- path", "Only changes under the given paths.")
            , (c "git stash push -p", "Choose hunks interactively, as with " <> c "add -p" <> ".")
            ]
        p_ $ do
            "Look before you apply: "
            c "git stash list"
            " shows the message and the branch it was made on, "
            c "git stash show -p stash@{1}"
            " the patch. "
            c "show"
            " leaves out the untracked part unless you add "
            c "--include-untracked"
            "."

    block "Getting it back" $ do
        p_ $ do
            c "apply"
            " merges an entry into your working tree and keeps it; "
            c "pop"
            " does the same and then drops it. Both restore the working tree only. The staged/unstaged split \
            \comes back only with "
            c "--index"
            ":"
        sh
            [ "$ git status -s"
            , " M app.txt"
            , "M  notes.txt"
            , "$ git stash && git stash pop"
            , "$ git status -s"
            , " M app.txt"
            , " M notes.txt"
            ]
        p_ $ do
            "When the stash conflicts with what you have done since, "
            c "pop"
            " stops short of dropping:"
        sh
            [ "$ git stash pop"
            , "Auto-merging app.txt"
            , "CONFLICT (content): Merge conflict in app.txt"
            , "The stash entry is kept in case you need it again."
            , "$ git stash list"
            , "stash@{0}: WIP on main: 1c945ee Initial"
            ]
        p_ $ do
            "Resolve as for a merge, then drop the entry by hand. If the stash was made long ago and the \
            \branch has moved a long way, "
            c "git stash branch old-work"
            " is gentler: it creates a branch at the commit the stash was made on, where it applies without \
            \conflict, and drops the entry."
        gotcha $ p_ $ do
            "Stashes are easy to forget, and a pile of entries all called "
            c "WIP on main"
            " is useless a week later. A stash is for minutes — switching branch to look at something. Work \
            \you want to keep belongs in a commit on a branch, where it has a name, a message, and a place in \
            \"
            c "git log"
            "."

    block "A worktree is a second checkout, not a second clone" $ do
        p_ $ do
            "The other way to handle an interruption is not to put anything aside. "
            c "git worktree add"
            " checks out another branch into another directory, attached to the same repository. Your \
            \editor, your running dev server and your half-typed changes stay exactly where they were."
        sh
            [ "$ git worktree add ../app-hotfix -b hotfix"
            , "Preparing worktree (new branch 'hotfix')"
            , "HEAD is now at ff764ed Conflicting edit"
            , "$ git worktree list"
            , "/home/ada/src/app         ff764ed [main]"
            , "/home/ada/src/app-hotfix  ff764ed [hotfix]"
            , "$ cat ../app-hotfix/.git"
            , "gitdir: /home/ada/src/app/.git/worktrees/app-hotfix"
            ]
        p_ $ do
            "The new directory has a "
            c ".git"
            " "
            em_ "file"
            ", not a directory, pointing into "
            c ".git/worktrees/"
            " of the main repository. Each worktree has its own "
            c "HEAD"
            ", its own index and its own files; everything else — objects, branches, tags, remotes, config, \
            \the stash — is shared. A commit made in one is instantly visible from the other, with no fetch."
        p_ "One rule keeps that sane: a branch can be checked out in only one worktree at a time."
        sh
            [ "$ git worktree add ../dup main"
            , "Preparing worktree (checking out 'main')"
            , "fatal: 'main' is already used by worktree at '/home/ada/src/app'"
            ]
        p_ $ do
            "The same protection stops "
            c "git switch hotfix"
            " in the main worktree and "
            c "git branch -d"
            " on a branch another worktree has checked out; "
            c "git branch"
            " marks such branches with "
            c "+"
            ". For a quick look at an old commit, "
            c "git worktree add --detach ../look v1.0"
            " needs no branch at all."
        gotcha $ p_ $ do
            c "git worktree add ../foo"
            " with no branch argument does not check out your current branch; it "
            b_ "creates a new branch called "
            c "foo"
            " from "
            c "HEAD"
            ". Name the branch explicitly. And clean up with "
            c "git worktree remove"
            ", which refuses if there are uncommitted changes; if you "
            c "rm -rf"
            " the directory instead, the branch stays locked until "
            c "git worktree prune"
            "."

    block "Today's habit" $ do
        p_ $ do
            "For an interruption that takes a minute, stash with a message. For anything longer — a review, a \
            \hotfix, a long build on another branch — make a worktree next to your main checkout and leave \
            \your work alone. Keep a naming convention ("
            c "../project-hotfix"
            ", "
            c "../project-review"
            ") so "
            c "git worktree list"
            " stays readable."
        p_ $ do
            "Tomorrow: ignore rules and attributes — telling git which files to leave alone, and how to treat \
            \the ones it keeps."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "A stash is a commit; a worktree is a second HEAD and index."
        " Minutes: stash. Longer: worktree."
    cfg
        [ "git stash push -m 'msg'          # tracked changes only; always name it"
        , "git stash push -u | --staged     # + untracked | only the index"
        , "git stash list; git stash show -p stash@{1}"
        , "git stash pop --index            # --index keeps staged as staged"
        , "git stash drop stash@{1}         # pop keeps the entry if it conflicts"
        , "git stash branch NAME            # apply where it was made, on a new branch"
        , "git worktree add ../dir -b NEW [START]    # second checkout, same repo"
        , "git worktree add --detach ../look v1.0    # read-only-ish look, no branch"
        , "git worktree list; git worktree remove ../dir; git worktree prune"
        ]
