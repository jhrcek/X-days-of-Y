module Course.Day.D08 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 8
        , dayTitle = "Reset, restore, revert"
        , daySubtitle = "Three commands with similar names that undo three different things."
        , dayMinutes = 35
        , dayLevel = "intermediate"
        , dayManRef = "GIT COMMANDS: Reset, restore and revert; git-reset(1), git-restore(1), git-revert(1), git-clean(1)"
        , dayTags = ["undo", "reset modes", "amend"]
        , dayGoals =
            [ "choose between " <> c "reset" <> ", " <> c "restore" <> " and " <> c "revert" <> " by asking what you want to change: a branch, some files, or the published record"
            , "predict exactly what " <> c "--soft" <> ", " <> c "--mixed" <> " and " <> c "--hard" <> " do to HEAD, the index and the working tree"
            , "fix the last commit with " <> c "--amend" <> ", and clear untracked debris with " <> c "git clean" <> " without deleting something you wanted"
            ]
        , dayDiagram = Just d8diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git commit --amend", "Replace the last commit with a new one built from the current index. Opens the editor.")
            , ("git commit --amend --no-edit", "Amend, keeping the message: for the file you forgot to add.")
            , ("git reset --soft <rev>", "Move the branch to " <> var "rev" <> ". Index and working tree untouched.")
            , ("git reset <rev>", "Move the branch and reset the index to it (" <> c "--mixed" <> ", the default). Working tree untouched.")
            , ("git reset --hard <rev>", "Move the branch, and overwrite index and working tree to match. Destroys uncommitted work.")
            , ("git reset -- <path>", "Copy " <> var "path" <> " from HEAD into the index: unstage. The branch does not move.")
            , ("git restore --source=<rev> <path>", "Overwrite a working-tree file with its version from any commit.")
            , ("git revert <commit>", "Make a new commit that undoes " <> var "commit" <> ". The safe undo for published history.")
            , ("git clean -n", "List the untracked files " <> c "-f" <> " would delete. Add " <> c "-d" <> " for directories, " <> c "-x" <> " for ignored files.")
            , ("git clean -fd", "Delete untracked files and directories. Ignored files survive unless " <> c "-x" <> ".")
            ]
        , dayOpts = []
        , dayConfig = []
        , dayDrills =
            [ "Make a commit, notice a typo in the message, and fix it with "
                <> c "git commit --amend"
                <> ". Compare the hash in "
                <> c "git log -1"
                <> " before and after."
            , "Commit, then realise you forgot a file. "
                <> c "git add"
                <> " it and "
                <> c "git commit --amend --no-edit"
                <> "."
            , "In a scratch repository, stage one change and leave another unstaged in the same file. Copy the \
              \directory three times and run "
                <> c "reset --soft HEAD~"
                <> ", "
                <> c "reset HEAD~"
                <> " and "
                <> c "reset --hard HEAD~"
                <> " in each. Read "
                <> c "git status"
                <> " after every one."
            , "Squash your last three local commits into one with "
                <> c "git reset --soft HEAD~3"
                <> " followed by "
                <> c "git commit"
                <> ". Check "
                <> c "git diff ORIG_HEAD"
                <> " is empty."
            , "Break it on purpose: try "
                <> c "git reset --soft -- somefile"
                <> ". Read the refusal and explain it from the table."
            , "Find a commit on a shared branch of your own project that you would like to undo. Run "
                <> c "git revert --no-edit <commit>"
                <> " on a throwaway branch and read the message it wrote."
            , "In a real project, run "
                <> c "git clean -ndx"
                <> " and read the list before you ever run it with "
                <> c "-f"
                <> ". Notice your editor settings and build caches in it."
            , "Adopt the rule: pushed commits are undone with "
                <> c "revert"
                <> "; local commits may be rewritten with "
                <> c "reset"
                <> " and "
                <> c "--amend"
                <> "."
            ]
        , dayQuiz =
            [
                ( "You run "
                    <> c "git reset --hard HEAD~1"
                    <> " to throw away a commit, and only then remember that the working tree also had an hour of \
                       \uncommitted edits. What can you get back?"
                , do
                    p_ $ do
                        "The commit, easily: it still exists, and "
                        c "ORIG_HEAD"
                        " (or "
                        c "HEAD@{1}"
                        ", Day 11) names it, so "
                        c "git reset --hard ORIG_HEAD"
                        " restores the branch. The uncommitted edits are a different matter. They were never objects \
                        \in the store; "
                        c "--hard"
                        " overwrote the files in place, and git has no record of them."
                    p_ $ do
                        "The one exception is anything you had "
                        c "git add"
                        "ed: staging writes a blob, so a staged version may survive as a dangling object that "
                        c "git fsck --lost-found"
                        " can find. Unstaged edits are gone. Before "
                        c "--hard"
                        ", run "
                        c "git status"
                        " and read it."
                )
            ,
                ( "You amend a commit you had already pushed, and "
                    <> c "git push"
                    <> " is rejected as non-fast-forward. Why, when you only changed the message?"
                , p_ $ do
                    c "--amend"
                    " does not edit a commit; commits are immutable (Day 1). It makes a new commit with the same parent \
                    \and moves the branch to it. The old commit is still on the remote, and the new one is not its \
                    \descendant, so pushing it would discard the old one. That is a rewrite, and publishing a rewrite \
                    \needs a force push (Day 9). If anyone may have fetched the old commit, the answer is a follow-up \
                    \commit, not an amend."
                )
            ,
                ( "A teammate reverts a bad merge on "
                    <> c "main"
                    <> ", the feature is fixed on its branch, and merging the branch again brings in only the fix \
                       \and none of the original work. Why?"
                , do
                    p_ $ do
                        "A revert undoes a commit's "
                        em_ "changes"
                        ", not its "
                        em_ "history"
                        ". The merge is still an ancestor of "
                        c "main"
                        ", so git considers every commit of the feature already merged; the new merge contributes \
                        \only commits made since. The revert commit still sits on "
                        c "main"
                        " undoing the original work."
                    p_ $ do
                        "The fix is to revert the revert before merging again. And reverting a merge at all needs "
                        c "-m 1"
                        " to say which parent is the mainline — Day 15 covers it."
                )
            ,
                ( c "git clean -fd"
                    <> " deleted your untracked "
                    <> c ".env"
                    <> " but left "
                    <> c "node_modules/"
                    <> " alone. Why the difference?"
                , p_ $ do
                    "Because "
                    c "node_modules/"
                    " is ignored and "
                    c ".env"
                    " was not. Without "
                    c "-x"
                    ", "
                    c "git clean"
                    " spares ignored files and deletes only untracked ones that are not ignored — often exactly the \
                    \hand-made files you care about. Ignore local-only files properly (Day 14) and always run "
                    c "-n"
                    " first; nothing "
                    c "clean"
                    " deletes was ever in the object store, so the reflog cannot bring it back."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d8diagram :: Diagram
d8diagram =
    ( diagram
        "What the three commands change: reset moves a branch and may overwrite the index and working \
        \tree; restore overwrites files in the working tree or index from a commit; revert adds a new \
        \commit whose changes undo an old one."
        body'
    )
        { dgCaption = do
            "Each command changes a different thing. "
            c "reset"
            " moves "
            b_ "a branch"
            " — history changes. "
            c "restore"
            " overwrites files and leaves every branch alone. "
            c "revert"
            " only ever adds "
            b_ "a new commit"
            ", which is why it is the one you can use on history other people already have."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  reset   [label=\"git reset\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  restore [label=\"git restore\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  revert  [label=\"git revert\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  branch  [label=\"a branch\"];\n\
        \  index   [label=\"the index\"];\n\
        \  wt      [label=\"the working tree\", fillcolor=\"#f4efe6\"];\n\
        \  newc    [label=\"a new commit\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  old     [label=\"an old commit\"];\n\
        \\n\
        \  reset   -> branch [label=\"  moves\"];\n\
        \  reset   -> index  [label=\"  overwrites (mixed, hard)\", style=dashed];\n\
        \  reset   -> wt     [label=\"  overwrites (hard)\", style=dashed];\n\
        \  restore -> wt     [label=\"  overwrites files in\"];\n\
        \  restore -> index  [label=\"  overwrites (--staged)\", style=dashed];\n\
        \  revert  -> newc   [label=\"  adds\"];\n\
        \  newc    -> old    [label=\"  undoes the changes of\"];\n\
        \  newc    -> branch [label=\"  is added on top of\"];\n\
        \\n\
        \  { rank=same; reset; restore; revert; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Three names, three different undos" $ do
        p_ [class_ "lede"] $ do
            "The git manual page is unusually direct about this. Under GIT COMMANDS it stops listing and \
            \explains: there are three commands with similar names, and they are not interchangeable. "
            c "revert"
            " makes a new commit that reverses an old one. "
            c "restore"
            " puts files back from the index or a commit and does not touch your branch. "
            c "reset"
            " moves your branch, adding or removing commits from it — and can also restore the index, which \
            \is where the overlap and the confusion come from."
        p_ $ do
            "So the first question is never “how do I undo?” but "
            b_ "what do I want to change"
            ": the files in front of me ("
            c "restore"
            "), where my branch points ("
            c "reset"
            "), or the shared record ("
            c "revert"
            ")."
        why $ p_ $ do
            "Until 2.23 all of this was "
            c "git checkout"
            " and "
            c "git reset"
            ", each doing several unrelated jobs depending on its arguments. "
            c "restore"
            " and "
            c "switch"
            " were split out so that the command name tells you what can be damaged. "
            c "reset"
            " kept its double role for compatibility, and that double role is today's main trap."
        fig

    block "Amend: the smallest rewrite" $ do
        p_ $ do
            "The most common undo is “that last commit is almost right”. "
            c "git commit --amend"
            " builds a new commit from the current index, with the same parent as the old one, and moves the \
            \branch to it. With "
            c "--no-edit"
            " it keeps the message; with "
            c "-m"
            " it replaces it."
        sh
            [ "$ git log --format='%h %s'"
            , "52040e8 two"
            , "131350f one"
            , "$ git commit --amend -m 'two, better'"
            , "$ git log --format='%h %s'"
            , "3267113 two, better"
            , "131350f one"
            ]
        p_ $ do
            "A new hash: the old "
            c "52040e8"
            " still exists, but nothing points at it. On a commit you have not pushed, that is harmless. On one \
            \you have pushed, it is a rewrite, and Day 9 explains what that costs."

    block "Reset moves the branch; the mode decides the collateral" $ do
        p_ $ do
            c "git reset <rev>"
            " always does one thing first: it points the current branch at "
            var "rev"
            ". The mode then decides how much of the rest follows along."
        ascii
            [ "                 branch (HEAD)   index        working tree"
            , "--soft           moved           untouched    untouched"
            , "--mixed          moved           = rev        untouched     (the default)"
            , "--hard           moved           = rev        = rev         (uncommitted work lost)"
            , "reset -- path    not moved       path = HEAD  untouched     (unstage)"
            ]
        p_ $ do
            "Start with a file whose last commit added “two”, with “three” staged and “four” unstaged, and \
            \step back one commit in each mode:"
        sh
            [ "[before] HEAD=two  index=three  wt=four"
            , "$ git reset --soft HEAD~   # HEAD=one  index=three  wt=four   status: MM"
            , "$ git reset HEAD~          # HEAD=one  index=one    wt=four   status:  M"
            , "$ git reset --hard HEAD~   # HEAD=one  index=one    wt=one    status: clean"
            , "HEAD is now at 131350f one"
            ]
        defs
            [
                ( c "--soft"
                , "Undo the commit, keep everything staged. " <> c "reset --soft HEAD~3" <> " then " <> c "commit" <> " squashes three commits into one."
                )
            ,
                ( c "--mixed"
                , "Undo the commit and the staging; your edits are all still in the files. The way to re-slice a commit you got wrong."
                )
            ,
                ( c "--hard"
                , "Make everything look like " <> var "rev" <> ". The only mode that can destroy work, because it overwrites files git never stored."
                )
            ]
        p_ $ do
            "With a path, "
            c "reset"
            " cannot move a branch — a branch is not per-file — so it only copies the path from "
            c "HEAD"
            " into the index. That is unstaging, which "
            c "git restore --staged"
            " (Day 2) does with a clearer name. Hence the refusal:"
        sh
            [ "$ git reset --soft -- f.txt"
            , "fatal: Cannot do soft reset with paths."
            ]
        gotcha $ p_ $ do
            c "reset --hard"
            " has no confirmation and no undo for the working tree. The commits it moves past are recoverable ("
            c "reset"
            " writes the old tip to "
            c "ORIG_HEAD"
            ", and Day 11's reflog keeps the rest); edits you never committed or staged are overwritten. \
            \If there is anything in "
            c "git status"
            " you might want, commit it or stash it (Day 13) first."

    block "Restore files, revert commits" $ do
        p_ $ do
            c "git restore"
            " takes files from somewhere and writes them somewhere else. By default it writes the working tree \
            \from the index; "
            c "--staged"
            " writes the index from "
            c "HEAD"
            "; "
            c "--source=<rev>"
            " takes them from any commit instead. The branch never moves."
        sh
            [ "$ git restore --source=HEAD~ f.txt           # working tree only"
            , "$ git restore --source=HEAD --staged --worktree f.txt   # both, from HEAD"
            ]
        p_ $ do
            c "git revert <commit>"
            " computes the inverse of that commit's change and commits it on top of your branch. Nothing is \
            \removed from history; a new commit is added, with a message that says so:"
        sh
            [ "$ git revert --no-edit HEAD~1"
            , "[main 09e2d06] Revert \"Lower the timeout\""
            , " 1 file changed, 1 deletion(-)"
            , "$ git log -1 --format=%B"
            , "Revert \"Lower the timeout\""
            , ""
            , "This reverts commit 7c58bc14f0ab6d5c15414ee33c6cdf191a583bf9."
            ]
        p_ $ do
            "If later commits touched the same lines, the revert conflicts exactly as a merge does (Day 4), and \
            \you finish with "
            c "git revert --continue"
            " or back out with "
            c "--abort"
            "."
        tip $ p_ $ do
            "The rule of thumb: if the commit exists anywhere but your machine, "
            c "revert"
            " it. Everyone who pulls gets an ordinary new commit and nobody's history is invalidated."

    block "Clean: the one that deletes files git never had" $ do
        p_ $ do
            "The three commands above never touch "
            em_ "untracked"
            " files. "
            c "git clean"
            " is the one that does, and it refuses to run without "
            c "-f"
            " because "
            opt "clean.requireForce"
            " defaults to true:"
        sh
            [ "$ git clean"
            , "fatal: clean.requireForce is true and -f not given: refusing to clean"
            , "$ git clean -n"
            , "Would remove .gitignore"
            , "Would remove junk.tmp"
            , "$ git clean -nd"
            , "Would remove .gitignore"
            , "Would remove build/"
            , "Would remove junk.tmp"
            , "$ git clean -ndx"
            , "Would remove .gitignore"
            , "Would remove build/"
            , "Would remove debug.log"
            , "Would remove junk.tmp"
            ]
        p_ $ do
            c "-d"
            " adds untracked directories, "
            c "-x"
            " adds ignored files too ("
            c "debug.log"
            " was matched by "
            c ".gitignore"
            ", which is itself untracked here and so on every list). Always run it with "
            c "-n"
            " first and read the list; untracked files were never objects, so nothing on Day 11 brings them \
            \back."

    block "Today's habit" $ do
        p_ $ do
            "Before undoing anything, say which of the three you are changing — branch, files or record — out \
            \loud if necessary, and pick the command by that. When it is the branch, prefer "
            c "--soft"
            " or "
            c "--mixed"
            " and reach for "
            c "--hard"
            " only after reading "
            c "git status"
            "."
        p_ $ do
            "Tomorrow: "
            c "rebase"
            ", which is many small resets and re-commits in a row, and the reason force-pushing exists."

cheat :: Html ()
cheat =
    cfg
        [ "# change the BRANCH (rewrites history: local commits only)"
        , "git commit --amend [--no-edit]   # redo the last commit"
        , "git reset --soft  REV            # move branch; keep index + files"
        , "git reset         REV            # move branch + index; keep files"
        , "git reset --hard  REV            # move all three; LOSES edits"
        , "git reset --hard ORIG_HEAD       # undo the last reset/merge/rebase"
        , "# change FILES (branch never moves)"
        , "git restore [--staged] [--source=REV] PATH"
        , "# change the RECORD (safe on pushed history)"
        , "git revert COMMIT                # new commit that undoes COMMIT"
        , "git clean -n / -fd / -fdx        # untracked / +dirs / +ignored"
        ]
