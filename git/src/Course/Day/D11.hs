module Course.Day.D11 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 11
        , dayTitle = "The reflog"
        , daySubtitle = "Every place your branches have been, kept locally for months — the reason rewriting is safe."
        , dayMinutes = 30
        , dayLevel = "intermediate"
        , dayManRef = "git-reflog(1), gitrevisions(7) @{…}, git-config(1) gc.reflogExpire, core.logAllRefUpdates"
        , dayTags = ["reflog", "recovery", "ORIG_HEAD"]
        , dayGoals =
            [ "read " <> c "git reflog" <> " and name any earlier position of " <> c "HEAD" <> " or a branch with " <> c "@{n}" <> " or " <> c "@{date}"
            , "recover from a bad " <> c "reset --hard" <> ", a botched rebase, a deleted branch and a commit left behind on a detached HEAD"
            , "say precisely what the reflog cannot save you from, and how long it keeps what it can"
            ]
        , dayDiagram = Just d11diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git reflog", "List where " <> c "HEAD" <> " has pointed, newest first, as " <> c "HEAD@{n}" <> " entries. Short for " <> c "git reflog show HEAD" <> ".")
            , ("git reflog show <branch>", "List where one branch has pointed. Its entries are " <> c "<branch>@{n}" <> ".")
            , ("git reflog --date=iso", "Show each entry's time instead of its index: " <> c "main@{2026-09-25 09:00:00 +0200}" <> ".")
            , ("git log -g", "Walk a reflog with the full " <> c "git log" <> " formatting options.")
            , ("git reset --hard ORIG_HEAD", "Undo the last reset, merge or rebase: go back to where it started.")
            , ("git branch <name> <commit>", "Give a recovered commit a name again, so it is safe for good.")
            , ("git fsck --unreachable", "List objects nothing refers to — not even a reflog. Where dropped stashes are found.")
            ]
        , dayOpts =
            [ ("gc.reflogExpire", "Age after which reflog entries are pruned. Default 90 days.")
            , ("gc.reflogExpireUnreachable", "Same, for entries no longer reachable from the ref's tip. Default 30 days.")
            , ("core.logAllRefUpdates", "Whether reflogs are kept. True by default with a working tree, false in a bare repository.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Run "
                <> c "git reflog | head -20"
                <> " in a repository you use every day. Recognise your own last hour of work in it."
            , "Run "
                <> c "git reflog show <your-branch>"
                <> " and compare it with "
                <> c "git reflog"
                <> ". Explain why the branch's list is shorter."
            , "Break it on purpose: in a scratch repository, commit three times, run "
                <> c "git reset --hard HEAD~2"
                <> ", then get all three back from the reflog using the hash, not the index."
            , "Create a branch, commit on it, switch away and delete it with "
                <> c "git branch -D"
                <> ". Find the commit in "
                <> c "git reflog"
                <> " and recreate the branch with "
                <> c "git branch <name> <hash>"
                <> "."
            , "Check out an old commit with "
                <> c "git switch --detach HEAD~2"
                <> ", commit on it, switch back and read the warning. Then rescue the commit."
            , "After the next real rebase you do, run "
                <> c "git log --oneline -1 ORIG_HEAD"
                <> " and "
                <> c "git range-diff @{u} ORIG_HEAD HEAD"
                <> " before pushing."
            , "Ask where "
                <> c "main"
                <> " pointed this morning with "
                <> c "git log -1 'main@{8 hours ago}'"
                <> ". Try it in a fresh clone and read the difference."
            , "From today, when something goes wrong in git, the first command you type is "
                <> c "git reflog"
                <> ", before any attempt to fix it."
            ]
        , dayQuiz =
            [
                ( "You recover from a bad reset with "
                    <> c "git reset --hard HEAD@{2}"
                    <> ", having read the index off the reflog a minute ago. You land on the wrong commit. What \
                       \changed?"
                , p_ $ do
                    "The reflog itself. Every move of "
                    c "HEAD"
                    " adds an entry at "
                    c "@{0}"
                    " and pushes everything else down by one, so indices are only valid until the next command — \
                    \and even a failed recovery attempt counts as a move. Copy the hash from the reflog line instead; \
                    \a hash means the same thing forever. The reset you just did is itself in the reflog, so you can \
                    \still get to where you meant."
                )
            ,
                ( "You deleted a branch with "
                    <> c "git branch -D spike"
                    <> ". "
                    <> c "git reflog show spike"
                    <> " says the name is unknown. Is the work gone?"
                , p_ $ do
                    "Not yet. Deleting a branch deletes its own reflog along with it, so that command has nothing \
                    \to show. But you made those commits with "
                    c "HEAD"
                    " on "
                    c "spike"
                    ", and "
                    c "HEAD"
                    "'s reflog records every commit and checkout regardless of branch. "
                    c "git reflog | grep spike"
                    " finds the “commit: …” lines and the “checkout: moving from spike” line, and "
                    c "git branch spike <hash>"
                    " restores it. "
                    c "git branch -D"
                    " also printed the tip hash when it deleted the branch."
                )
            ,
                ( "A colleague force-pushed over "
                    <> c "main"
                    <> " on the shared server. You ssh in to recover it from the server's reflog, and there \
                       \isn't one. Why?"
                , p_ $ do
                    "Server repositories are bare, and "
                    opt "core.logAllRefUpdates"
                    " defaults to false in a bare repository. And reflogs are never transferred: they are not \
                    \pushed, fetched or cloned (a fresh clone's reflog has one entry, “clone: from …”). The copy \
                    \that has the old "
                    c "main"
                    " is in someone's clone — your "
                    c "origin/main"
                    " reflog, if you fetched before the force-push, has it as "
                    c "origin/main@{1}"
                    "."
                )
            ,
                ( "You dropped a stash an hour ago and now need it. "
                    <> c "git reflog"
                    <> " does not show it. Where is it?"
                , p_ $ do
                    "A stash is a commit (Day 13) recorded only in the reflog of "
                    c "refs/stash"
                    ", and "
                    c "git stash drop"
                    " deletes that reflog entry. So the commit is unreachable from everything, reflogs included, \
                    \and "
                    c "git fsck --unreachable"
                    " lists it among the unreachable commits. Easier still: "
                    c "drop"
                    " printed its hash (“Dropped refs/stash@{0} (615ea5d…)”), and "
                    c "git stash apply 615ea5d"
                    " brings it back while the object survives — normally two weeks, until "
                    c "gc"
                    " prunes it (Day 20)."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d11diagram :: Diagram
d11diagram =
    ( diagram
        "The reflog as types: a ref has a reflog; a reflog is a list of entries; an entry records an old \
        \commit, a new commit, a time and a reason; an expression like HEAD@{n} selects an entry; a \
        \commit named by some entry is protected from garbage collection; uncommitted work is not \
        \recorded by any entry."
        body'
    )
        { dgCaption = do
            "The reflog is the one piece of history git keeps about "
            em_ "names"
            " rather than content. Each entry keeps a commit alive, which is why rewriting (Days 8–10) \
            \never loses committed work. "
            b_ "uncommitted work"
            " has no entry pointing at it — that is the gap to remember."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  ref    [label=\"a ref\\n(HEAD, a branch)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  log    [label=\"a reflog\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  entry  [label=\"a reflog entry\"];\n\
        \  commit [label=\"a commit\"];\n\
        \  why    [label=\"a reason and a time\", fillcolor=\"#f4efe6\"];\n\
        \  expr   [label=\"an expression\\nHEAD@{n}, main@{yesterday}\"];\n\
        \  gc     [label=\"garbage collection\"];\n\
        \  work   [label=\"uncommitted work\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  ref    -> log    [label=\"  has\"];\n\
        \  log    -> entry  [label=\"  is a list of\"];\n\
        \  entry  -> commit [label=\"  records as the new position\"];\n\
        \  entry  -> why    [label=\"  records\"];\n\
        \  expr   -> entry  [label=\"  selects\"];\n\
        \  entry  -> gc     [label=\"  protects its commit from\", style=dashed];\n\
        \  entry  -> work   [label=\"  never records\", style=dashed];\n\
        \\n\
        \  { rank=same; ref; expr; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "git remembers every place a name has pointed" $ do
        p_ [class_ "lede"] $ do
            "Commits are never edited, only abandoned, and a ref is a small file that gets rewritten. So the \
            \one thing a rewrite could lose is the old value of that file. git keeps it: every time "
            c "HEAD"
            " or a branch moves, a line is appended to its "
            b_ "reflog"
            " — old hash, new hash, who, when, and why. That log is the safety net under Days 8 to 10."
        sh
            [ "$ git reflog"
            , "fad8de7 HEAD@{0}: reset: moving to HEAD~2"
            , "f28019d HEAD@{1}: checkout: moving from spike to main"
            , "2123547 HEAD@{2}: commit: spike1"
            , "f28019d HEAD@{3}: checkout: moving from main to spike"
            , "f28019d HEAD@{4}: commit: three"
            , "23631ff HEAD@{5}: commit: two"
            , "fad8de7 HEAD@{6}: commit (initial): one"
            ]
        p_ $ do
            "Read it bottom to top as a diary: three commits, a detour to "
            c "spike"
            " with one commit there, back to "
            c "main"
            ", and a "
            c "reset --hard"
            " that threw away two commits. Nothing has actually been thrown away. "
            c "f28019d"
            " (“three”) is right there, and "
            c "git reset --hard f28019d"
            " restores the branch."
        why $ p_ $ do
            "The reflog is what makes git's history editing tolerable. Because every rewrite leaves the old tip \
            \in a log and objects are only deleted once nothing — not even a log entry — refers to them, you \
            \can rebase, amend and reset with confidence rather than dread. It is also strictly local: it \
            \records what "
            em_ "your"
            " refs did, so it is never pushed, fetched or cloned."
        fig

    block "Every ref has its own log" $ do
        p_ $ do
            "The unqualified "
            c "git reflog"
            " shows "
            c "HEAD"
            "'s log, which records everything including checkouts. Each branch has a log of its own, recording \
            \only that branch's moves:"
        sh
            [ "$ git reflog show main"
            , "fad8de7 main@{0}: reset: moving to HEAD~2"
            , "f28019d main@{1}: commit: three"
            , "23631ff main@{2}: commit: two"
            , "fad8de7 main@{3}: commit (initial): one"
            ]
        p_ $ do
            "Those labels are revision expressions (Day 7), usable anywhere. "
            c "HEAD@{1}"
            " is where "
            c "HEAD"
            " was one move ago; "
            c "main@{1}"
            " where "
            c "main"
            " was; "
            c "@{1}"
            " is the current branch's previous value. Entries can also be selected by time, since each has a \
            \timestamp:"
        sh
            [ "$ git reflog --date=iso main | head -3"
            , "f28019d main@{2026-09-25 09:00:00 +0200}: reset: moving to HEAD@{1}"
            , "fad8de7 main@{2026-09-25 08:00:00 +0200}: reset: moving to HEAD~2"
            , "f28019d main@{2026-09-25 03:00:00 +0200}: commit: three"
            , "$ git log -1 --format=%s 'main@{2026-09-25 02:30}'"
            , "two"
            ]
        note $ p_ $ do
            c "main@{yesterday}"
            " means where "
            em_ "your local"
            " "
            c "main"
            " pointed yesterday, not the commits made yesterday. For those, use "
            c "git log --since"
            " (Day 6). In a fresh clone, "
            c "main@{yesterday}"
            " cannot go back further than the clone."
        gotcha $ p_ $ do
            "Indices shift with every move. "
            c "HEAD@{2}"
            " read off the screen a minute ago may mean something else after one more command — including a \
            \failed recovery attempt. In testing this lesson exactly that happened: a "
            c "reset"
            " to a remembered "
            c "HEAD@{2}"
            " landed one entry off. Copy the hash from the line, not the number."

    block "Four recoveries" $ do
        defs
            [
                ( "after reset, merge or rebase"
                , do
                    "These commands also write the old position to "
                    c "ORIG_HEAD"
                    ", so the immediate undo is "
                    c "git reset --hard ORIG_HEAD"
                    ". Later, find the line before the operation in "
                    c "git reflog"
                    " (a rebase leaves a “rebase (start)” and “rebase (finish)” pair) and reset to the hash above it."
                )
            ,
                ( "after deleting a branch"
                , do
                    "The branch's own reflog is deleted with it, but "
                    c "HEAD"
                    "'s is not. "
                    c "git reflog | grep <branch>"
                    ", then "
                    c "git branch <branch> <hash>"
                    "."
                )
            ,
                ( "after committing on a detached HEAD"
                , do
                    "No branch was moving, but "
                    c "HEAD"
                    " was, so the commits are in "
                    c "HEAD"
                    "'s reflog. git also tells you as you leave:"
                )
            ,
                ( "after dropping a stash"
                , do
                    c "git stash drop"
                    " prints the hash; "
                    c "git stash apply <hash>"
                    " works on it. Without the hash, "
                    c "git fsck --unreachable"
                    " lists it among the unreachable commits (Day 13 explains why a stash is a commit)."
                )
            ]
        sh
            [ "$ git switch main"
            , "Warning: you are leaving 1 commit behind, not connected to"
            , "any of your branches:"
            , ""
            , "  1bf30f0 detached-work"
            , ""
            , "If you want to keep it by creating a new branch, this may be a good time"
            , "to do so with:"
            , ""
            , " git branch <new-branch-name> 1bf30f0"
            ]
        tip $ p_ $ do
            "Once found, give the commit a name — a branch or a tag. A reflog entry is protection with an expiry \
            \date; a ref is permanent."

    block "What the reflog cannot save" $ do
        p_ $ do
            "The reflog records ref movements, and refs only ever point at commits. So it knows nothing about:"
        steps
            [ do
                "Unstaged edits overwritten by "
                c "reset --hard"
                ", "
                c "restore"
                " or "
                c "checkout -- <file>"
                ". They were never objects."
            , do
                "Untracked files deleted by "
                c "git clean"
                " (Day 8). Same reason."
            , do
                "Anything older than the expiry. "
                opt "gc.reflogExpire"
                " defaults to 90 days, and "
                opt "gc.reflogExpireUnreachable"
                " — for entries whose commit is no longer on the ref's current history, which is exactly what \
                \you are usually trying to recover — to 30 days. Entries are pruned by "
                c "git gc"
                ", which git runs for you from time to time (Day 20)."
            , do
                "Other people's refs, and the server. Reflogs are never transferred, and bare repositories do \
                \not keep them: "
                opt "core.logAllRefUpdates"
                " is true by default only where there is a working tree."
            ]
        p_ $ do
            "The first two are the real hazard, and the fix is habit, not configuration: commit early, even \
            \as "
            c "wip"
            ", because anything committed is covered and can be tidied later with Day 10's tools. Staged content \
            \is half-covered — "
            c "git add"
            " wrote a blob, so "
            c "git fsck --lost-found"
            " can often dig it out, without its file name."
        note $ p_ $ do
            "The defaults are right, and this lesson adds nothing to your config. Thirty days is long enough to \
            \notice a mistake; extend "
            opt "gc.reflogExpireUnreachable"
            " only if you have a concrete reason."

    block "Today's habit" $ do
        p_ $ do
            "When something goes wrong, stop and run "
            c "git reflog"
            " before typing anything that might move a ref. Find the line from before the mistake, copy its \
            \hash, check it with "
            c "git log -1 <hash>"
            " or "
            c "git diff <hash>"
            ", and only then reset or branch to it."
        p_ $ do
            "That finishes the rewriting trilogy. Tomorrow: configuration itself — where git's settings live, \
            \which one wins, and the aliases that are worth having."

cheat :: Html ()
cheat =
    cfg
        [ "git reflog                     # where HEAD has been (newest first)"
        , "git reflog show BRANCH         # where BRANCH has been"
        , "git reflog --date=iso          # times instead of indices"
        , "HEAD@{3}  main@{1}  @{1}       # earlier positions (indices shift!)"
        , "'main@{2 days ago}'            # your local main, by time"
        , "git reset --hard ORIG_HEAD     # undo the last reset/merge/rebase"
        , "git branch rescue HASH         # make a recovered commit permanent"
        , "git fsck --unreachable         # dropped stashes and orphans"
        , "# not covered: unstaged edits, untracked files, other clones"
        , "# expiry: 90 days reachable, 30 days unreachable (gc)"
        ]
