module Course.Day.D17 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 17
        , dayTitle = "Conflicts at scale"
        , daySubtitle = "Strategies, sides, and teaching git to resolve the same conflict twice without you."
        , dayMinutes = 35
        , dayLevel = "advanced"
        , dayManRef = "git-merge(1) MERGE STRATEGIES; git-checkout(1) --ours/--theirs/-m; git-rerere(1)"
        , dayTags = ["strategies", "ours/theirs", "rerere"]
        , dayGoals =
            [ "choose between " <> c "-X ours" <> " and " <> c "-s ours" <> " knowing that one of them throws away the other side's work entirely"
            , "take one side of a conflicted file, or rebuild its markers, without losing your place — and say which side is which during a rebase"
            , "turn on rerere and let git replay a conflict resolution you have already made once"
            ]
        , dayDiagram = Just d17diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git merge -X ours <branch>", "Merge normally, but settle each conflicting hunk in favour of this side. Clean hunks from the other side still land.")
            , ("git merge -s ours <branch>", "Record a merge that keeps this tree exactly. The other branch's changes are discarded.")
            , ("git checkout --ours <path>", "During a conflict, take stage 2 for that path. In a rebase, stage 2 is the upstream.")
            , ("git checkout --theirs <path>", "Take stage 3 for that path. In a rebase, stage 3 is your own commit being replayed.")
            , ("git checkout -m <path>", "Re-create the conflict markers in a file you have mangled or resolved wrongly.")
            , ("git log --merge", "During a conflict, list only the commits on either side that touch the conflicted paths.")
            , ("git diff AUTO_MERGE", "Show only what you have edited since git wrote the conflicted files.")
            , ("git rerere status", "List paths whose conflict rerere has recorded a preimage for.")
            , ("git rerere diff", "Show the resolution you are about to teach rerere.")
            , ("git rerere forget <path>", "Drop a recorded resolution that turned out to be wrong.")
            ]
        , dayOpts =
            [ ("rerere.enabled", "Record every conflict and its resolution, and replay them on the next identical conflict.")
            , ("rerere.autoUpdate", "Stage a path once rerere has resolved it, instead of leaving it for you to " <> c "git add" <> ".")
            ]
        , dayConfig =
            [ ConfBlock
                "Remember how I resolved each conflict and replay it when the same conflict comes\n\
                \back - repeated rebases of a long-lived branch, test merges I abort. The merge\n\
                \still stops for me to review and commit; autoUpdate only saves the git add."
                "[rerere]\n\
                \\tenabled = true\n\
                \\tautoUpdate = true"
            ]
        , dayDrills =
            [ "Run "
                <> c "git merge -h 2>&1 | grep -- -s"
                <> ", then try "
                <> c "git merge -s nonsense main"
                <> " on any branch. Read the list of strategies it prints, and notice which one is missing."
            , "In a scratch repository, make two branches that change the same line and each touch one other \
              \file. Merge once with "
                <> c "-X ours"
                <> " and once with "
                <> c "-s ours"
                <> " (resetting in between). Compare the two resulting trees with "
                <> c "git diff"
                <> "."
            , "Start a conflicted merge and run "
                <> c "git ls-files -u"
                <> ", then "
                <> c "git checkout --theirs"
                <> " on the file, then "
                <> c "git checkout -m"
                <> " on it. You should be back where you started, with the markers."
            , "Break it on purpose: rebase a branch onto a conflicting one, then take "
                <> c "--ours"
                <> " for the conflicted file and "
                <> c "cat"
                <> " it. Explain to yourself why you got the upstream's version, then "
                <> c "git rebase --abort"
                <> "."
            , "During any real conflict at work, run "
                <> c "git log --merge --oneline"
                <> " before opening the file. It is usually two or three commits, and their messages tell you \
                   \what each side meant."
            , "Resolve part of a conflict, then run "
                <> c "git diff AUTO_MERGE"
                <> ". Only your edits appear — a quick check that you have not deleted something by accident."
            , "Add today's "
                <> c "[rerere]"
                <> " block, repeat a conflicting merge, resolve and commit it, "
                <> c "git reset --hard HEAD~1"
                <> ", and merge again. Watch for "
                <> c "Staged 'f' using previous resolution."
            , "From now on, before resolving a conflict by hand, ask whether you have seen it before. If you \
              \have, rerere should be doing it."
            ]
        , dayQuiz =
            [
                ( "You merge a feature branch with "
                    <> c "-s ours"
                    <> " because “there was one conflict and ours is right”. The merge succeeds. A week later \
                       \nobody can find the feature. What happened?"
                , do
                    p_ $ do
                        c "-s ours"
                        " is a strategy, not an option: it records a merge commit whose tree is exactly your \
                        \current tree, and ignores the other branch completely — conflicting hunks, clean hunks, \
                        \new files, all of it. The branch is marked as merged, so git will never offer those \
                        \commits again."
                    p_ $ do
                        "What was wanted was "
                        c "-X ours"
                        ", an option to the default "
                        c "ort"
                        " strategy: merge normally, and only where hunks conflict prefer this side. Reverting the \
                        \bad merge does not help, because it changed nothing; bring the feature's commits back \
                        \explicitly, for example by cherry-picking them (Day 15)."
                )
            ,
                ( "Mid-rebase, you run "
                    <> c "git checkout --ours config.yml"
                    <> " to keep “your” version. The file now contains your colleague's change and not yours. \
                       \Why?"
                , do
                    p_ $ do
                        "Because a rebase replays your commits on top of the upstream. At each step, "
                        c "HEAD"
                        " is the new base being built — the upstream plus whatever has been replayed so far — \
                        \and the commit being applied is yours. So stage 2, “ours”, is the upstream, and stage 3, \
                        \“theirs”, is your own commit."
                    p_ $ do
                        "The names are about "
                        c "HEAD"
                        " and the incoming commit, not about people. In a merge they happen to line up with \
                        \intuition; in a rebase or cherry-pick they are swapped. Use "
                        c "--theirs"
                        " to keep your own change when rebasing."
                )
            ,
                ( "rerere is on, you repeat a merge it has seen, and the output says it used the previous \
                  \resolution — but the merge still stops with “fix conflicts and then commit”. Is it broken?"
                , do
                    p_ $ do
                        "No. rerere rewrites the file with the recorded resolution (and, with "
                        opt "rerere.autoUpdate"
                        ", stages it), but it never concludes the merge. The merge stops as it always would, so \
                        \that a resolution recorded in one context is not committed blindly in another."
                    p_ $ do
                        "Check "
                        c "git diff --staged"
                        ", run the tests, and "
                        c "git commit"
                        ". The saving is the thinking, not the keystroke."
                )
            ,
                ( "You taught rerere a wrong resolution. You run "
                    <> c "git rerere forget f"
                    <> " and the wrong text is still in the file. What now?"
                , p_ $ do
                    c "forget"
                    " removes the recording from "
                    c ".git/rr-cache"
                    " so it will not be replayed again; it does not touch your working tree. To get the conflict \
                    \back, run "
                    c "git checkout -m f"
                    ", which rebuilds the markers from the three index stages. Resolve it properly, and the next "
                    c "git commit"
                    " records the corrected resolution."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d17diagram :: Diagram
d17diagram =
    ( diagram
        "During a conflicted merge a path has three index stages: the merge base, ours and theirs. \
        \checkout --ours and --theirs copy one stage to the working file; checkout -m rebuilds the \
        \markers from all three. rerere records the conflict as a preimage and your fix as a \
        \resolution, and replays the resolution on the next identical conflict."
        body'
    )
        { dgCaption = do
            "A conflict is not a broken file; it is three blobs sitting in the index at once. Everything \
            \today is a way of choosing among them — by hunk ("
            c "-X"
            "), by path ("
            c "--ours"
            ", "
            c "--theirs"
            "), or by memory ("
            b_ "a recorded resolution"
            "). Which stage counts as “ours” depends only on what "
            c "HEAD"
            " is at that moment, which is why a rebase swaps them."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  path   [label=\"a conflicted path\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  s1     [label=\"stage 1\\n(the merge base)\"];\n\
        \  s2     [label=\"stage 2\\n(ours: HEAD)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  s3     [label=\"stage 3\\n(theirs: incoming)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  file   [label=\"the working file\\nwith markers\"];\n\
        \  pre    [label=\"a preimage\\n(the conflict)\"];\n\
        \  res    [label=\"a recorded resolution\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  cache  [label=\".git/rr-cache\", fillcolor=\"#f4efe6\"];\n\
        \\n\
        \  path -> s1   [label=\"  has\"];\n\
        \  path -> s2   [label=\"  has\"];\n\
        \  path -> s3   [label=\"  has\"];\n\
        \  s2   -> file [label=\"  is written into\"];\n\
        \  s3   -> file [label=\"  is written into\"];\n\
        \  file -> pre  [label=\"  is recorded by rerere as\"];\n\
        \  pre  -> res  [label=\"  is paired with\"];\n\
        \  res  -> cache [label=\"  is kept in\"];\n\
        \  res  -> file [label=\"  is replayed into  \", style=dashed, constraint=false];\n\
        \\n\
        \  { rank=same; s1; s2; s3; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "A conflict is three blobs and a choice" $ do
        p_ [class_ "lede"] $ do
            "Day 4 showed that a conflicted path has three entries in the index — stage 1 the merge base, \
            \stage 2 ours, stage 3 theirs — and that the file on disk is git's attempt to show you all three \
            \at once. Today is about what to do when there are many conflicts, or the same ones keep coming \
            \back: choose a side per hunk, per path, or let git remember your choice from last time."
        p_ $ do
            "The machinery that produces conflicts is the "
            b_ "merge strategy"
            ". Since 2.34 the default is "
            c "ort"
            ", and in 2.52 the old name "
            c "recursive"
            " is only a synonym for it — git-merge(1) says it “was redirected to mean ort in v2.50.0”. The \
            \others ("
            c "resolve"
            ", "
            c "octopus"
            ", "
            c "ours"
            ", "
            c "subtree"
            ") are special-purpose; you will name one on purpose perhaps once a year."
        sh
            [ "$ git merge -s nonsense topic"
            , "Could not find merge strategy 'nonsense'."
            , "Available strategies are: octopus ours recursive resolve subtree."
            ]
        note $ p_ $ do
            "That list omits "
            c "ort"
            ", the strategy you are actually using, and still works when named ("
            c "git merge -s ort"
            "). The manual page is right and the error message is stale; do not read the list as a menu."
        fig

    block "-X ours is a preference; -s ours is a verdict" $ do
        p_ $ do
            "These two look like the same flag. They are opposite in scope. Take two branches that both \
            \change line 2 of "
            c "f"
            ", where "
            c "topic"
            " also adds a line to "
            c "g"
            ":"
        sh
            [ "$ git merge -X ours topic -m xours"
            , "Auto-merging f"
            , "$ cat f g"
            , "a"
            , "MAIN"
            , "c"
            , "one"
            , "topic-g"
            , "$ git reset --hard HEAD~1"
            , "$ git merge -s ours topic -m sours"
            , "$ cat f g"
            , "a"
            , "MAIN"
            , "c"
            , "one"
            ]
        p_ $ do
            c "-X ours"
            " is a "
            b_ "strategy option"
            ": run the normal three-way merge, and wherever two hunks collide, take ours. The other side's \
            \non-conflicting work, like "
            c "topic-g"
            ", still lands. "
            c "-s ours"
            " is a "
            b_ "strategy"
            ": produce a merge commit whose tree is identical to "
            c "HEAD"
            ". The other branch contributes a parent and nothing else."
        gotcha $ p_ $ do
            c "-s ours"
            " succeeds silently and marks the branch as merged. Its commits are now ancestors of your branch, \
            \so no later merge will ever bring them in. Its legitimate use is declaring an old line of \
            \development superseded; its accidental use loses a feature with no conflict to warn you. There \
            \is no "
            c "-s theirs"
            ", for the same reason."
        why $ p_ $ do
            "Resolving “in favour of a side” per hunk is safe only when the side you lose was also trying to \
            \do the same thing. "
            c "-X"
            " still hands you every hunk that did not collide, so the result is a merge; "
            c "-s ours"
            " throws the whole branch away, which is a decision about history, not about text."

    block "Choosing per path, and taking it back" $ do
        p_ $ do
            "When one file is best resolved wholesale — a lock file, generated code — pick a stage for that \
            \path and move on:"
        defs
            [ (c "git checkout --ours f", "Write stage 2 into the working file. Then " <> c "git add f" <> ".")
            , (c "git checkout --theirs f", "Write stage 3 into the working file.")
            , (c "git checkout -m f", "Rebuild the conflicted file with markers, from the three stages. Your undo.")
            , (c "git log --merge", "Show only the commits, from either side, that touched the conflicted paths.")
            , (c "git diff", "In a conflict, a combined diff: two columns of " <> c "+" <> "/" <> c "-" <> ", one per parent.")
            , (c "git diff AUTO_MERGE", "Only what you have changed since git wrote the conflicted files.")
            ]
        sh
            [ "$ git checkout --theirs f && cat f"
            , "Updated 1 path from the index"
            , "a"
            , "TOPIC"
            , "c"
            , "$ git checkout -m f && cat f"
            , "Recreated 1 merge conflict"
            , "a"
            , "<<<<<<< ours"
            , "MAIN"
            , "======="
            , "TOPIC"
            , ">>>>>>> theirs"
            , "c"
            ]
        p_ $ do
            "Notice the markers after "
            c "-m"
            ": "
            c "ours"
            " and "
            c "theirs"
            ", not "
            c "HEAD"
            " and "
            c "topic"
            " as in the original. The stage contents are the same; only the labels are lost."
        gotcha $ p_ $ do
            "“Ours” means "
            b_ "stage 2, which is whatever HEAD is"
            ". In a merge that is your branch. In a rebase, "
            c "HEAD"
            " is the upstream you are replaying onto, and the commit being applied is yours — so "
            c "--ours"
            " gives you the upstream's version and "
            c "--theirs"
            " gives you your own. The same swap applies to "
            c "-X ours"
            " passed to "
            c "git rebase"
            ". Verified: mid-rebase of "
            c "topic"
            " onto "
            c "main"
            ", "
            c "--ours"
            " produced "
            c "MAIN"
            "."
        tip $ p_ $ do
            c "AUTO_MERGE"
            " is a ref git writes when a merge stops with conflicts: the tree exactly as it wrote it to your \
            \working directory, markers included. Right after the conflict "
            c "git diff AUTO_MERGE"
            " is empty; as you resolve, it shows your edits and nothing else."

    block "rerere: resolve once, replay forever" $ do
        p_ $ do
            b_ "rerere"
            " is “reuse recorded resolution”. With "
            opt "rerere.enabled"
            ", whenever a merge stops with a conflict, git saves the conflicted hunks as a "
            b_ "preimage"
            ", keyed by their content. When you commit the resolved file, it saves your version as the "
            b_ "postimage"
            ". The next time an identical conflict appears — in any merge, rebase or cherry-pick — it writes \
            \your resolution in for you."
        sh
            [ "$ git merge topic"
            , "Auto-merging f"
            , "CONFLICT (content): Merge conflict in f"
            , "Recorded preimage for 'f'"
            , "Automatic merge failed; fix conflicts and then commit the result."
            , "$ printf 'a\\nMAIN+TOPIC\\nc\\n' > f && git add f && git commit -qm 'merge topic'"
            , "Recorded resolution for 'f'."
            , "$ git reset -q --hard HEAD~1 && git merge topic"
            , "Auto-merging f"
            , "CONFLICT (content): Merge conflict in f"
            , "Staged 'f' using previous resolution."
            , "Automatic merge failed; fix conflicts and then commit the result."
            ]
        p_ $ do
            "The situations where this pays: rebasing a long-lived branch repeatedly onto a moving "
            c "main"
            "; doing a trial merge to see what breaks, aborting it, and doing it for real later; and \
            \re-running an interactive rebase that you got wrong the first time. The recordings live in "
            c ".git/rr-cache/"
            "; "
            c "git rerere gc"
            " (which "
            c "git gc"
            " runs) keeps a resolved record for 60 days and an unresolved one for 15 ("
            opt "gc.rerereResolved"
            ", "
            opt "gc.rerereUnresolved"
            ")."
        gotcha $ p_ $ do
            "Even when rerere resolves every hunk, the merge "
            b_ "still stops"
            " and says “fix conflicts and then commit”. That is deliberate: a resolution that was right in \
            \one context is replayed as text, not as understanding. With "
            opt "rerere.autoUpdate"
            " the file is already staged, so the only thing left is to check and commit — do not let that \
            \make you skip the check."
        p_ $ do
            c "git rerere status"
            " lists the paths it is tracking, "
            c "git rerere diff"
            " shows the resolution you are about to record, and "
            c "git rerere forget f"
            " drops a bad recording. "
            c "forget"
            " does not restore the markers; follow it with "
            c "git checkout -m f"
            "."

    block "Today's habit" $ do
        p_ $ do
            "Add the "
            c "[rerere]"
            " block and forget about it; it costs nothing until the day it saves you an hour. When you hit a \
            \conflict, run "
            c "git log --merge --oneline"
            " before you open the file, and when you reach for a side, say out loud what "
            c "HEAD"
            " is right now."
        p_ "Tomorrow: hooks — programs git runs for you at fixed points, and why cloning a repository does not bring its hooks along."

cheat :: Html ()
cheat =
    cfg
        [ "git merge -X ours B        # per hunk: prefer ours where they collide"
        , "git merge -s ours B        # whole merge: keep our tree, discard B"
        , "git checkout --ours P      # stage 2 = HEAD (upstream, when rebasing)"
        , "git checkout --theirs P    # stage 3 = incoming (yours, when rebasing)"
        , "git checkout -m P          # put the markers back"
        , "git log --merge --oneline  # the commits behind this conflict"
        , "git diff AUTO_MERGE        # only my edits since the conflict"
        , "git rerere status|diff     # what rerere is tracking / about to record"
        , "git rerere forget P        # drop a bad recording"
        ]
