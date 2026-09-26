module Course.Day.D09 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 9
        , dayTitle = "Rebase"
        , daySubtitle = "Replaying your commits on a new base — new commits, new hashes, and the rules that follow."
        , dayMinutes = 35
        , dayLevel = "intermediate"
        , dayManRef = "git-rebase(1), git-push(1) --force-with-lease"
        , dayTags = ["rebase", "--onto", "force-with-lease"]
        , dayGoals =
            [ "explain what rebase does in terms of Day 1's objects: which commits it copies, and why the copies have new hashes"
            , "rebase a branch onto its upstream, or transplant part of it with " <> c "--onto" <> ", and see a conflict mid-rebase through to the end"
            , "publish a rebased branch with " <> c "--force-with-lease" <> " and know the one case in which even that clobbers a colleague"
            ]
        , dayDiagram = Just d9diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git rebase <upstream>", "Replay the commits in " <> c "<upstream>..HEAD" <> " on top of " <> var "upstream" <> ". With no argument, uses " <> c "@{u}" <> ".")
            , ("git rebase --onto <new> <old> [<branch>]", "Replay " <> c "<old>..<branch>" <> " on top of " <> var "new" <> ": transplant part of a branch.")
            , ("git rebase --continue", "After resolving and " <> c "git add" <> "ing a conflict, commit it and go on.")
            , ("git rebase --skip", "Drop the commit that stopped, and go on.")
            , ("git rebase --abort", "Put the branch back exactly where it was before the rebase started.")
            , ("git push --force-with-lease", "Overwrite the remote branch only if it is still where your remote-tracking branch says.")
            , ("git push --force-if-includes", "With the lease: also refuse if the remote tip was fetched but never integrated locally.")
            ]
        , dayOpts =
            [ ("push.useForceIfIncludes", "Make every " <> c "--force-with-lease" <> " behave as if " <> c "--force-if-includes" <> " were given.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "On a feature branch, run "
                <> c "git log --oneline @{u}..HEAD"
                <> " or "
                <> c "main..HEAD"
                <> ": that list is exactly what a rebase onto it would replay."
            , "In a scratch repository, make a branch with two commits, add a commit to "
                <> c "main"
                <> ", and rebase. Compare "
                <> c "git log --format='%h %s'"
                <> " before and after, and "
                <> c "git cat-file -t"
                <> " the old hashes: they still exist."
            , "Break it on purpose: arrange for both "
                <> c "main"
                <> " and your branch to change the same line, rebase, and at the conflict run "
                <> c "git status"
                <> " and "
                <> c "git show REBASE_HEAD"
                <> ". Resolve and "
                <> c "--continue"
                <> "."
            , "Start a rebase that conflicts and then "
                <> c "git rebase --abort"
                <> ". Check with "
                <> c "git log -1"
                <> " that nothing moved."
            , "Stack a branch on another, then move just the top branch onto "
                <> c "main"
                <> " with "
                <> c "git rebase --onto main <lower> <upper>"
                <> "."
            , "Rebase one of your own un-pushed branches onto a freshly fetched "
                <> c "origin/main"
                <> " before opening its pull request, and run the tests."
            , "Set up a bare repository and two clones in a scratch directory. Push from one, rewrite in the \
              \other, and watch "
                <> c "--force-with-lease"
                <> " refuse; then fetch and watch it agree."
            , "Adopt the rule: rebase commits nobody else has built on; merge everything else. When you do push a \
              \rebase, type "
                <> c "--force-with-lease"
                <> ", never "
                <> c "--force"
                <> "."
            ]
        , dayQuiz =
            [
                ( "After "
                    <> c "git rebase main"
                    <> ", "
                    <> c "git log"
                    <> " shows your commits with the same messages, authors and dates. Why is "
                    <> c "git push"
                    <> " now rejected?"
                , p_ $ do
                    "Because they are not the same commits. Each copy has a new parent — the tip of "
                    c "main"
                    " instead of the old fork point — and a commit's hash covers its parent (Day 1). So each copy \
                    \is a new object, and your branch now points at a chain the remote has never seen and that does \
                    \not contain the chain it has. Pushing it would drop the old commits, and "
                    c "git push"
                    " refuses anything that is not a fast-forward unless you force it."
                )
            ,
                ( "Mid-rebase, "
                    <> c "git status"
                    <> " says you are not on any branch and "
                    <> c "git branch"
                    <> " shows "
                    <> c "(no branch, rebasing topic)"
                    <> ". Have you lost your branch?"
                , p_ $ do
                    "No. Rebase works on a detached "
                    c "HEAD"
                    ": it checks out the new base, cherry-picks your commits onto it one at a time, and only at the \
                    \end moves "
                    c "topic"
                    " to the result. Until then "
                    c "topic"
                    " still names the original commits, which is precisely why "
                    c "--abort"
                    " can restore everything by pointing back to it."
                )
            ,
                ( "During a rebase conflict, the block marked "
                    <> c "<<<<<<< HEAD"
                    <> " contains the other team's code, not yours. Is git confused?"
                , p_ $ do
                    "No, but the labels are the reverse of a merge. In a rebase, "
                    c "HEAD"
                    " is the new base plus the commits already replayed — that is, "
                    c "main"
                    "'s version. Your commit is the one being applied, shown after "
                    c "======="
                    " with its hash and subject. So in a rebase “ours” is upstream and “theirs” is you. Remember \
                    \this when Day 17 introduces "
                    c "--ours"
                    " and "
                    c "--theirs"
                    "."
                )
            ,
                ( "You ran "
                    <> c "git fetch"
                    <> " before "
                    <> c "git push --force-with-lease"
                    <> ", to be safe. It succeeded — and deleted the commit a colleague had just pushed. How?"
                , do
                    p_ $ do
                        "The lease checks that the remote branch is where "
                        em_ "your remote-tracking branch"
                        " says it is. The fetch updated "
                        c "origin/feat"
                        " to include your colleague's commit, so the check passed, although you never looked at \
                        \that commit or rebased onto it. Anything that updates remote-tracking branches in the \
                        \background — an IDE, a periodic fetch — has the same effect."
                    p_ $ do
                        c "--force-if-includes"
                        " closes the hole: it also requires that the remote tip be reachable from some entry in your \
                        \local branch's reflog, i.e. that you actually integrated it. It refused with "
                        c "(remote ref updated since checkout)"
                        ". "
                        opt "push.useForceIfIncludes"
                        " turns it on for every lease."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d9diagram :: Diagram
d9diagram =
    ( diagram
        "Rebase as replay: a rebase takes a range of original commits, produces a copy of each on top of \
        \a new base; each copy has the same change and message as its original but a different parent; \
        \at the end the branch is moved from the originals to the copies."
        body'
    )
        { dgCaption = do
            "Nothing is moved and nothing is edited. "
            b_ "a copy"
            " is a brand-new commit that happens to carry the same change and message as "
            b_ "an original commit"
            "; only its parent differs, and that alone gives it a new name. The branch is re-pointed at the \
            \end; the originals are still in the store, and still in anyone else's clone."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  rebase [label=\"a rebase\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  range  [label=\"a range upstream..branch\"];\n\
        \  orig   [label=\"an original commit\"];\n\
        \  copy   [label=\"a copy\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  base   [label=\"the new base\"];\n\
        \  change [label=\"a change + message\", fillcolor=\"#f4efe6\"];\n\
        \  br     [label=\"the branch\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \\n\
        \  rebase -> range  [label=\"  replays\"];\n\
        \  range  -> orig   [label=\"  contains\"];\n\
        \  rebase -> copy   [label=\"  produces\"];\n\
        \  copy   -> orig   [label=\"  is a copy of\"];\n\
        \  orig   -> change [label=\"  carries\"];\n\
        \  copy   -> change [label=\"  carries\"];\n\
        \  copy   -> base   [label=\"  has as (new) parent\"];\n\
        \  br     -> copy   [label=\"  is moved to\"];\n\
        \  br     -> orig   [label=\"  used to name  \", style=dashed];\n\
        \\n\
        \  { rank=same; rebase; br; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Rebase does not move commits; it copies them" $ do
        p_ [class_ "lede"] $ do
            "Merging joins two lines of history with a new commit. Rebasing makes your line look as if it had \
            \been started later: it takes the commits on your branch that are not on the new base, re-applies \
            \each one's change on top of that base as a new commit, and moves your branch to the last copy. \
            \The result is a straight line. The price is that every one of your commits has been replaced."
        p_ $ do
            "Here "
            c "topic"
            " forked from "
            c "B"
            ", and "
            c "main"
            " has since gained "
            c "C"
            " and "
            c "D"
            ":"
        sh
            [ "$ git log --oneline --graph --all"
            , "* 712d6e9 D"
            , "* e6927c6 C"
            , "| * 9c9d3df T2"
            , "| * 133afce T1"
            , "|/"
            , "* d287932 B"
            , "$ git switch topic && git rebase main"
            , "Successfully rebased and updated refs/heads/topic."
            , "$ git log --oneline --graph --all"
            , "* 223cc29 T2"
            , "* 1fd27af T1"
            , "* 712d6e9 D"
            , "* e6927c6 C"
            , "* d287932 B"
            , "$ git cat-file -t 133afce"
            , "commit"
            ]
        p_ $ do
            c "T1"
            " was "
            c "133afce"
            " and is now "
            c "1fd27af"
            ". The old object is still there, unreferenced; Day 11 shows how to find it again. What was replayed \
            \is exactly the set "
            c "main..topic"
            " from Day 7 — rebase is that range plus a series of cherry-picks (Day 15)."
        why $ p_ $ do
            "Why rewrite at all? Because history is read far more often than it is written. A reviewer, or \
            \you in a year running "
            c "git bisect"
            " (Day 16), gets a sequence of commits each of which applies to the code as it actually was, \
            \instead of a braid of merges from “main into feature” that record nothing but the passage of time. \
            \The cost is that the old commits are invalidated, which only matters if someone else has them."
        fig

    block "Upstream, and --onto for transplants" $ do
        p_ $ do
            c "git rebase <upstream>"
            " replays "
            c "<upstream>..HEAD"
            " onto "
            var "upstream"
            ". With no argument it uses the branch's configured upstream, "
            c "@{u}"
            ", which makes "
            c "git fetch && git rebase"
            " the standard way to bring a private branch up to date."
        p_ $ do
            "The three-argument form separates “what to replay” from “where to put it”: "
            c "git rebase --onto <new> <old> <branch>"
            " replays "
            c "<old>..<branch>"
            " on top of "
            var "new"
            ". The classic case is a branch "
            c "sub"
            " that was started from "
            c "topic"
            " and should now stand on "
            c "main"
            " without "
            c "topic"
            "'s commits:"
        sh
            [ "$ git log --oneline main..sub"
            , "8562903 S2"
            , "cac4566 S1"
            , "223cc29 T2"
            , "1fd27af T1"
            , "$ git rebase --onto main topic sub"
            , "Successfully rebased and updated refs/heads/sub."
            , "$ git log --oneline main..sub"
            , "4df1e75 S2"
            , "d8444e0 S1"
            ]

    block "When a replay conflicts" $ do
        p_ $ do
            "Each commit is applied separately, so a conflict stops the rebase at that commit, with the rest \
            \still queued:"
        sh
            [ "$ git rebase main"
            , "CONFLICT (content): Merge conflict in app.conf"
            , "error: could not apply 936e5b1... Raise timeout"
            , "$ git status"
            , "interactive rebase in progress; onto 9042deb"
            , "Last command done (1 command done):"
            , "   pick 936e5b1 # Raise timeout"
            , "Next command to do (1 remaining command):"
            , "   pick d58b8d4 # Add x"
            , "$ cat app.conf"
            , "<<<<<<< HEAD"
            , "timeout = 10"
            , "======="
            , "timeout = 60"
            , ">>>>>>> 936e5b1 (Raise timeout)"
            ]
        p_ $ do
            "Resolve the file as on Day 4, "
            c "git add"
            " it, and "
            c "git rebase --continue"
            " commits it and moves to the next. "
            c "--skip"
            " drops the commit that stopped (if its change is no longer needed), and "
            c "--abort"
            " puts the branch back exactly where it started. "
            c "REBASE_HEAD"
            " names the commit being applied, so "
            c "git show REBASE_HEAD"
            " shows what you were trying to do."
        note $ p_ $ do
            "Plain "
            c "git rebase"
            " reports itself as an “interactive rebase in progress”. That is not a mistake on your part: since \
            \2.26 the default backend is the same sequencer that runs "
            c "rebase -i"
            ", with a todo list you did not edit. Tomorrow you edit it."
        gotcha $ p_ $ do
            "The conflict labels are reversed compared with a merge. "
            c "HEAD"
            " is the new base — "
            c "main"
            "'s code — and your commit is the one after "
            c "======="
            ". In a rebase, “ours” is upstream and “theirs” is the commit being replayed."

    block "Publishing a rewrite: lease, not force" $ do
        p_ $ do
            "Once a rebased branch has been pushed before, the remote holds the originals and a normal push is \
            \refused. "
            c "--force"
            " overwrites whatever the remote has — including commits a colleague pushed since you last \
            \looked. "
            c "--force-with-lease"
            " overwrites only if the remote branch is still where your "
            c "origin/<branch>"
            " says it is:"
        sh
            [ "$ git push --force-with-lease"
            , " ! [rejected]        feat -> feat (stale info)"
            ]
        p_ $ do
            "Someone pushed while you were rewriting; the lease has saved their commit. Now fetch, look at what \
            \arrived, and integrate it."
        gotcha $ do
            p_ $ do
                "Fetching is also what defeats the lease. After a "
                c "git fetch"
                ", "
                c "origin/feat"
                " includes the colleague's commit, the lease matches, and the push goes through — deleting that \
                \commit even though you never rebased onto it:"
            sh
                [ "$ git fetch"
                , "$ git push --force-with-lease"
                , " + a9f9c39...362ff18 feat -> feat (forced update)"
                ]
            p_ $ do
                "Add "
                c "--force-if-includes"
                " (or set "
                opt "push.useForceIfIncludes"
                "), which also demands that the remote tip be reachable from your branch's reflog. In the same \
                \situation it refuses with "
                c "(remote ref updated since checkout)"
                "."

    block "The one rule" $ do
        p_ $ do
            "Rebase freely what only you have. Do not rebase commits other people have based work on: their \
            \clones still contain the originals, and the next time they pull they get your copies as well — the \
            \same changes twice, often with conflicts. A shared "
            c "main"
            " is never rebased. A feature branch that only you push to may be, as often as you like, until \
            \someone else starts building on it."
        p_ $ do
            "Tomorrow: the todo list itself — reordering, squashing, rewording and splitting commits with "
            c "rebase -i"
            "."

cheat :: Html ()
cheat =
    cfg
        [ "git rebase                    # replay @{u}..HEAD onto @{u}"
        , "git rebase main               # replay main..HEAD onto main"
        , "git rebase --onto NEW OLD BR  # replay OLD..BR onto NEW"
        , "# at a conflict: fix, git add, then one of"
        , "git rebase --continue | --skip | --abort"
        , "git show REBASE_HEAD          # the commit that stopped"
        , "# conflict labels: HEAD = upstream (ours), your commit = theirs"
        , "git push --force-with-lease --force-if-includes"
        , "# rule: never rebase what someone else has built on"
        ]
