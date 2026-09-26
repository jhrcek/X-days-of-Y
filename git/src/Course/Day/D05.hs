module Course.Day.D05 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 5
        , dayTitle = "Remotes"
        , daySubtitle = "Another repository's branches, copied into yours as read-only bookmarks — and the two verbs that move them."
        , dayMinutes = 35
        , dayLevel = "essential"
        , dayManRef = "git-clone(1), git-remote(1), git-fetch(1), git-pull(1), git-push(1); gitrevisions(7) refname rules"
        , dayTags = ["fetch", "push", "upstream"]
        , dayGoals =
            [ "explain the difference between " <> c "main" <> ", " <> c "origin/main" <> " and the " <> c "main" <> " on the server, and which command moves each"
            , "read ahead/behind counts and decide how to integrate before anything changes"
            , "push a new branch, set its upstream, and understand every rejection git gives you"
            ]
        , dayDiagram = Just d5diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git clone <url>", "Copy a repository: all objects, its branches as " <> c "origin/*" <> ", and one local branch checked out.")
            , ("git remote -v", "List remotes with their fetch and push URLs.")
            , ("git remote add <name> <url>", "Register another repository under a short name.")
            , ("git fetch", "Download new objects and move the remote-tracking refs. Never touches your branches or files.")
            , ("git pull", "Fetch, then integrate the upstream into the current branch.")
            , ("git push", "Send the current branch's commits and move the branch of the same name on the remote.")
            , ("git push -u origin <branch>", "Push and record " <> c "origin/<branch>" <> " as this branch's upstream.")
            , ("git push origin --delete <branch>", "Delete a branch on the remote.")
            , ("git branch -vv", "List branches with their upstream and ahead/behind counts.")
            ]
        , dayOpts =
            [ ("pull.ff", c "only" <> ": let " <> c "git pull" <> " fast-forward and refuse anything else.")
            , ("push.autoSetupRemote", "Make a plain " <> c "git push" <> " of a new branch create it upstream and track it.")
            , ("fetch.prune", "Delete remote-tracking refs whose branch was deleted on the remote, on every fetch.")
            ]
        , dayConfig =
            [ ConfBlock
                "pull only ever fast-forwards; merge-or-rebase stays a separate, deliberate\n\
                \command. Unset, git already refuses diverged pulls but nags about choosing\n\
                \a policy every time - this is that choice, written down, so a future\n\
                \default or someone else's dotfile cannot change what pull does to you."
                "[pull]\n\
                \\tff = only"
            , ConfBlock
                "The first push of a new branch works and sets its upstream, instead of\n\
                \failing with 'has no upstream branch'. Stale origin/* refs for branches\n\
                \deleted on the server disappear on the next fetch instead of accumulating."
                "[push]\n\
                \\tautoSetupRemote = true\n\
                \[fetch]\n\
                \\tprune = true"
            ]
        , dayDrills =
            [ "In a real clone, run "
                <> c "git remote -v"
                <> " and "
                <> c "git branch -vv"
                <> ". Find the upstream of the branch you are on."
            , "Run "
                <> c "git branch -r"
                <> " and then "
                <> c "git fetch"
                <> ". Run "
                <> c "git status"
                <> ": the ahead/behind numbers are now current. Your files did not change."
            , "In a scratch directory, make a bare repository with "
                <> c "git init --bare origin.git"
                <> " and clone it twice. Commit and push from one clone, "
                <> c "fetch"
                <> " in the other, and watch "
                <> c "origin/main"
                <> " move while "
                <> c "main"
                <> " stays."
            , "Break it on purpose: commit in both clones, then push from the second. Read the “rejected \
              \(non-fast-forward)” message, then run "
                <> c "git pull"
                <> " with no config and read that refusal too."
            , "In the same pair, integrate with "
                <> c "git merge origin/main"
                <> " and push. Look at the result with "
                <> c "git log --oneline --graph --all"
                <> "."
            , "Delete a branch on the scratch remote with "
                <> c "git push origin --delete"
                <> ", then compare "
                <> c "git fetch"
                <> " with "
                <> c "git fetch --prune"
                <> " in the other clone. Find the "
                <> c ": gone]"
                <> " in "
                <> c "git branch -vv"
                <> "."
            , "Add today's three settings to "
                <> c "~/.gitconfig"
                <> ", then push a new branch from real work with a plain "
                <> c "git push"
                <> "."
            , "From today, "
                <> c "git fetch"
                <> " first and read "
                <> c "git status"
                <> " before you pull, push, or start a branch. Know where you are relative to the server \
                   \before you move."
            ]
        , dayQuiz =
            [
                ( "You run "
                    <> c "git fetch"
                    <> ", and "
                    <> c "git log"
                    <> " still does not show your colleague's new commit. Did the fetch fail?"
                , p_ $ do
                    "No. The commit arrived, and "
                    c "origin/main"
                    " moved to it; your "
                    c "main"
                    " did not, because fetch never moves local branches. "
                    c "git log origin/main"
                    " shows it, and "
                    c "git status"
                    " now says you are behind. Moving "
                    c "main"
                    " is a separate step: a merge, a fast-forward pull, or (Day 9) a rebase."
                )
            ,
                ( c "git push"
                    <> " is rejected as “non-fast-forward”. A colleague suggests "
                    <> c "git push --force"
                    <> ". What would that do to the server?"
                , do
                    p_ $ do
                        "Move the server's "
                        c "main"
                        " to your commit regardless, making your colleague's commits unreachable from it — \
                        \they vanish from the branch for everyone who fetches next. The rejection is git \
                        \telling you that the server has commits you do not."
                    p_ $ do
                        "The right move is to fetch, integrate (merge today, rebase on Day 9), and push a \
                        \commit that contains both histories. Day 9 also covers "
                        c "--force-with-lease"
                        ", for when rewriting the remote branch really is the intent."
                )
            ,
                ( "Your laptop's "
                    <> c "git branch -r"
                    <> " lists thirty branches, but the server only has five. Where did the other twenty-five \
                       \come from?"
                , p_ $ do
                    "They are remote-tracking refs for branches that were deleted on the server after you \
                    \last fetched them. A plain "
                    c "git fetch"
                    " adds and updates "
                    c "origin/*"
                    " refs but does not remove them. "
                    c "git fetch --prune"
                    " (or "
                    opt "fetch.prune"
                    " set to true) deletes the ones with no branch behind them. Your own local branches are \
                    \not touched; ones that tracked a pruned branch show "
                    c "[origin/x: gone]"
                    " in "
                    c "git branch -vv"
                    "."
                )
            ,
                ( "With "
                    <> c "pull.ff = only"
                    <> ", "
                    <> c "git pull"
                    <> " refuses: “Not possible to fast-forward, aborting.” Your colleague's "
                    <> c "git pull"
                    <> " never refuses. Whose setup is better?"
                , do
                    p_ $ do
                        "It depends on what you want pull to decide for you. Yours stops whenever both sides \
                        \have new commits and hands the decision back: "
                        c "git merge"
                        " or "
                        c "git rebase"
                        ", explicitly, after you have looked at "
                        c "git log --oneline --graph --all"
                        "."
                    p_ $ do
                        "Your colleague has "
                        opt "pull.rebase"
                        " set — to "
                        c "true"
                        " (rebase) or "
                        c "false"
                        " (which means merge) — so their pull silently does one or the other. That is fine if \
                        \they chose it; it is how unintended merge commits and surprise rebases end up in a \
                        \shared history when they did not."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d5diagram :: Diagram
d5diagram =
    ( diagram
        "A local branch has a remote-tracking ref as its upstream; the remote-tracking ref records a \
        \branch in the remote repository. Fetch moves the remote-tracking ref; merge or pull moves the \
        \local branch; push moves the remote branch."
        body'
    )
        { dgCaption = do
            "There are three pointers for every shared branch, and every networking command moves exactly \
            \one of them. "
            b_ "a remote-tracking ref"
            " is the middle one: your repository's last-known copy of the server's branch, updated only by \
            \fetch (and by a successful push). Nothing ever makes you commit onto it."
        , dgRankdir = "LR"
        , dgNodesep = "0.5"
        , dgRanksep = "0.6"
        }
  where
    body' =
        "  local  [label=\"a local branch\\n(main)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  rtb    [label=\"a remote-tracking ref\\n(origin/main)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  remote [label=\"a branch in\\nthe remote repository\", fillcolor=\"#f4efe6\"];\n\
        \\n\
        \  local  -> rtb    [label=\"  has as upstream\"];\n\
        \  rtb    -> remote [label=\"  records\\n  (moved by fetch)\"];\n\
        \  local  -> remote [label=\"  is sent to\\n  (by push)\", style=dashed];\n\
        \  rtb    -> local  [label=\"  is integrated into\\n  (by merge / pull)\", style=dashed];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Three mains, not one" $ do
        p_ [class_ "lede"] $ do
            "A remote is another repository, and git never talks to it except when you ask. What you see \
            \of it in between is a set of "
            b_ "remote-tracking refs"
            " — "
            c "origin/main"
            ", "
            c "origin/feature"
            " — which are your repository's snapshot of where the remote's branches were the last time you \
            \looked. So every shared branch has three pointers: your "
            c "main"
            ", your "
            c "origin/main"
            ", and the server's "
            c "main"
            ". Each command today moves exactly one of them."
        p_ $ do
            c "git clone"
            " sets all of this up. Look at what it wrote:"
        sh
            [ "$ git clone -q origin.git bob && cd bob"
            , "$ git branch -r"
            , "  origin/HEAD -> origin/main"
            , "  origin/main"
            , "$ git for-each-ref refs/remotes"
            , "c4fc3f24017cde1f30aec6e574450f1b95a6ed14 commit\trefs/remotes/origin/HEAD"
            , "c4fc3f24017cde1f30aec6e574450f1b95a6ed14 commit\trefs/remotes/origin/main"
            , "$ git config --get-regexp '^(remote|branch)\\.'"
            , "remote.origin.url /srv/git/origin.git"
            , "remote.origin.fetch +refs/heads/*:refs/remotes/origin/*"
            , "branch.main.remote origin"
            , "branch.main.merge refs/heads/main"
            ]
        p_ $ do
            "Three pieces of config carry the whole mechanism. "
            c "remote.origin.url"
            " is where. "
            c "remote.origin.fetch"
            " is the "
            b_ "refspec"
            ": every branch under the remote's "
            c "refs/heads/"
            " is copied to "
            c "refs/remotes/origin/"
            " here, and the "
            c "+"
            " allows the copy to be updated even when that is not a fast-forward — when the server's branch was rewritten. And the two "
            c "branch.main.*"
            " lines make "
            c "origin/main"
            " the "
            b_ "upstream"
            " of "
            c "main"
            " — the default for pull, push, and the ahead/behind count."
        why $ p_ $ do
            "Keeping the remote's state in separate, read-only refs is what lets git work offline and \
            \lets you look before you leap. A fetch changes nothing you are working on, so it is always safe; \
            \afterwards you can compare, log and diff against "
            c "origin/main"
            " at leisure, and only then decide how to bring it into "
            c "main"
            ". Systems that update your working copy as part of syncing take that decision away."
        fig

    block "fetch moves the bookmark, never your branch" $ do
        p_ "Someone pushes. You fetch. Your branch, index and files stay exactly where they were:"
        sh
            [ "$ git fetch"
            , "From /srv/git/origin"
            , "   c4fc3f2..95e5378  main       -> origin/main"
            , "$ git status -sb"
            , "## main...origin/main [behind 1]"
            ]
        p_ $ do
            "The status line compares "
            c "main"
            " with its upstream and counts commits on each side. After you commit locally too, the \
            \histories have "
            b_ "diverged"
            ":"
        sh
            [ "$ git branch -vv"
            , "* main  0ee97bb [origin/main: ahead 1, behind 1] Bob: add b"
            ]
        p_ $ do
            "This is Day 4's situation with one branch on a server. The fix is Day 4's fix: "
            c "git merge origin/main"
            " finds the merge base, combines the two changes, and makes a two-parent commit that contains \
            \both. Then push."
        note $ p_ $ do
            "The ahead/behind numbers are only as fresh as your last fetch. "
            c "git status"
            " saying “up to date” means up to date with "
            c "origin/main"
            " as you last saw it, not with the server now."

    block "pull is fetch plus a decision" $ do
        p_ $ do
            c "git pull"
            " runs "
            c "git fetch"
            " and then integrates the upstream into the current branch. When your branch has not moved, \
            \integrating is a fast-forward and there is nothing to decide. When both sides have moved, there \
            \is, and an unconfigured "
            c "git pull"
            " refuses to guess:"
        sh
            [ "$ git pull"
            , "hint: You have divergent branches and need to specify how to reconcile them."
            , "hint: You can do so by running one of the following commands sometime before"
            , "hint: your next pull:"
            , "hint:"
            , "hint:   git config pull.rebase false  # merge"
            , "hint:   git config pull.rebase true   # rebase"
            , "hint:   git config pull.ff only       # fast-forward only"
            , "..."
            , "fatal: Need to specify how to reconcile divergent branches."
            ]
        p_ $ do
            "This course picks the third: "
            opt "pull.ff"
            " set to "
            c "only"
            ". "
            c "git pull"
            " then fast-forwards when it can and stops, changing nothing, when it cannot — and you choose \
            \merge or rebase as a separate command, with the graph in front of you. It keeps the one \
            \surprising thing pull can do (create a commit you did not ask for, or rewrite ones you did) \
            \out of a command you type without thinking."
        sh
            [ "$ git pull"
            , "hint: Diverging branches can't be fast-forwarded, you need to either:"
            , "..."
            , "fatal: Not possible to fast-forward, aborting."
            , "$ git log --oneline --graph --all     # look first"
            , "$ git merge origin/main               # then decide"
            ]
        note $ p_ $ do
            "Behaviourally this is what you already had: git-pull(1) says "
            c "--ff-only"
            " “is the default when no method for reconciling divergent histories is provided”, and the \
            \unconfigured refusal above is that default at work. What the setting adds is intent. The \
            \policy is now written down, the hint about choosing one stops appearing, and neither a future \
            \default nor a copied dotfile can change what "
            c "git pull"
            " does to you without you noticing."
        gotcha $ p_ $ do
            "An old tutorial's "
            c "git pull"
            " is not your "
            c "git pull"
            ". Depending on "
            opt "pull.rebase"
            " and "
            opt "pull.ff"
            " it merges, rebases or refuses, and an alias in someone's dotfiles can change it again. When \
            \following instructions, prefer the explicit pair: "
            c "git fetch"
            ", then "
            c "git merge"
            " or "
            c "git rebase"
            "."

    block "push asks the server to fast-forward" $ do
        p_ $ do
            c "git push"
            " sends your commits and asks the remote to move its branch to your tip. The remote agrees only \
            \if that is a fast-forward — if your tip contains everything its branch already had:"
        sh
            [ "$ git push"
            , " ! [rejected]        main -> main (non-fast-forward)"
            , "error: failed to push some refs to '/srv/git/origin.git'"
            , "hint: Updates were rejected because the tip of your current branch is behind"
            , "hint: its remote counterpart. If you want to integrate the remote changes,"
            , "hint: use 'git pull' before pushing again."
            ]
        p_ $ do
            "Read that as “the server has commits you do not”. Fetch, integrate, push again. A new branch \
            \has no upstream yet, and the default "
            opt "push.default"
            " ("
            c "simple"
            ") will not guess where it goes:"
        sh
            [ "$ git switch -c topic   # ...and commit something"
            , "$ git push"
            , "fatal: The current branch topic has no upstream branch."
            , "To push the current branch and set the remote as upstream, use"
            , ""
            , "    git push --set-upstream origin topic"
            , ""
            , "To have this happen automatically for branches without a tracking"
            , "upstream, see 'push.autoSetupRemote' in 'git help config'."
            ]
        p_ $ do
            c "git push -u origin topic"
            " is the long answer. "
            opt "push.autoSetupRemote"
            " is the permanent one: a plain "
            c "git push"
            " of a branch with no upstream pushes it to the same name and records the upstream."
        sh
            [ "$ git -c push.autoSetupRemote=true push"
            , " * [new branch]      topic -> topic"
            , "branch 'topic' set up to track 'origin/topic'."
            ]

    block "Keeping origin/* honest" $ do
        p_ $ do
            "Fetch adds and moves remote-tracking refs but, by default, never deletes them. A branch \
            \deleted on the server lives on in every clone as a stale "
            c "origin/…"
            " until someone prunes:"
        sh
            [ "$ git fetch"
            , "$ git branch -r"
            , "  origin/HEAD -> origin/main"
            , "  origin/main"
            , "  origin/topic"
            , "$ git fetch --prune"
            , " - [deleted]         (none)     -> origin/topic"
            , "$ git branch -vv"
            , "* main  71c732e [origin/main] Merge remote-tracking branch 'origin/main'"
            , "  topic 0561660 [origin/topic: gone] topic"
            ]
        p_ $ do
            opt "fetch.prune"
            " makes every fetch prune. It only ever deletes "
            c "refs/remotes/"
            " entries; your local "
            c "topic"
            " branch is untouched, and the "
            c "gone"
            " marker tells you its upstream was deleted — usually because it was merged, which makes it a \
            \candidate for "
            c "git branch -d"
            "."
        tip $ p_ $ do
            "Day 7 gives the upstream a name you can type: "
            c "@{u}"
            ". Until then, "
            c "origin/main"
            " spelled out works everywhere a branch name does — "
            c "git log main..origin/main"
            " is a preview of that day."

    block "Today's habit" $ do
        p_ $ do
            "Stop typing "
            c "git pull"
            " by reflex. Type "
            c "git fetch"
            ", read "
            c "git status"
            ", and only then pull, merge or push. With today's config, "
            c "git pull"
            " can no longer surprise you — but it is still better to know before you ask."
        p_ "Tomorrow: reading the history you now share — who changed what, when, and why."

cheat :: Html ()
cheat =
    cfg
        [ "# main          your branch; moved by commit, merge, pull"
        , "# origin/main   last-seen copy of the server's main; moved by fetch"
        , "git fetch                  # safe, always: objects + origin/* only"
        , "git status -sb             # ## main...origin/main [ahead 1, behind 2]"
        , "git branch -vv             # every branch, its upstream, ahead/behind"
        , "git merge origin/main      # integrate after a fetch"
        , "git pull                   # fetch + integrate (ff only, with today's config)"
        , "git push                   # server moves its branch only on a fast-forward"
        , "git push -u origin B       # first push; records the upstream"
        , "git fetch --prune          # drop origin/* for branches deleted upstream"
        ]
