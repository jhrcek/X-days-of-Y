module Course.Day.D16 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 16
        , dayTitle = "Bisect"
        , daySubtitle = "Binary search over history: which commit broke it, in log₂(n) tests, by hand or by script."
        , dayMinutes = 35
        , dayLevel = "advanced"
        , dayManRef = "git-bisect(1); gitrevisions(7) BISECT_HEAD"
        , dayTags = ["bisect", "debugging", "automation"]
        , dayGoals =
            [ "find the commit that introduced a regression in a few steps, starting from one good and one bad commit"
            , "hand the whole search to a script with " <> c "git bisect run" <> ", using the exit-code contract correctly"
            , "bisect something that is not a bug — a speed-up, a behaviour change — with custom terms"
            ]
        , dayDiagram = Just d16diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git bisect start <bad> <good>...", "Begin a search between a known-bad and one or more known-good commits.")
            , ("git bisect good | bad", "Mark the checked-out commit, and move to the next midpoint.")
            , ("git bisect skip", "This commit cannot be tested; pick a nearby one instead.")
            , ("git bisect run <cmd> [args]", "Test every step automatically: exit 0 good, 1–127 bad, 125 skip, anything else abort.")
            , ("git bisect reset", "End the session and return to the branch you started on.")
            , ("git bisect log", "Print the session so far as a replayable script.")
            , ("git bisect replay <file>", "Re-run a saved log, e.g. after correcting one wrong answer.")
            , ("git bisect view --oneline", "List the commits still in the running.")
            , ("git bisect terms", "Show the words in use for the two states.")
            ]
        , dayOpts =
            [ ("--first-parent", "On " <> c "bisect start" <> ": follow only first parents, so merged side branches count as one step.")
            , ("--term-old=<w> --term-new=<w>", "On " <> c "bisect start" <> ": use your own words instead of good/bad.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "In any repository, run "
                <> c "git bisect start HEAD HEAD~20"
                <> ", read the “roughly N steps” line, and "
                <> c "git bisect reset"
                <> "."
            , "Build a scratch repository with 30 commits where one of them plants a bug (a one-line change to \
              \a script), then find it by hand with "
                <> c "good"
                <> "/"
                <> c "bad"
                <> ". Count the steps."
            , "Find the same commit again with "
                <> c "git bisect run"
                <> " and a three-line test script. Compare the time."
            , "Break it on purpose: "
                <> c "git bisect run ./no-such-script.sh"
                <> ". Read how git reacts to exit code 127, then "
                <> c "git bisect reset"
                <> "."
            , "Mid-session, run "
                <> c "git bisect log > bisect.log"
                <> ", reset, then "
                <> c "git bisect replay bisect.log"
                <> " and check you are back on the same commit."
            , "Start a session with "
                <> c "--term-old=slow --term-new=fast"
                <> " and try typing "
                <> c "git bisect good"
                <> ". Then use the right word."
            , "Next time a regression turns up at work, write the smallest script that exits 0 on a good build \
              \and 1 on a bad one — before you start reading code — and bisect with it."
            , "Keep every commit on your main branch buildable and testable. That is what makes bisect a \
              \five-minute job rather than an afternoon of "
                <> c "skip"
                <> "."
            ]
        , dayQuiz =
            [
                ( "Your "
                    <> c "bisect run"
                    <> " script builds the project first, and on some old commits the build itself fails. \
                       \Bisect blames one of those commits. What should the script have done?"
                , do
                    p_ $ do
                        "Exited "
                        b_ "125"
                        " when the build fails. Any code from 1 to 127 except 125 means “bad”, so a broken build \
                        \looked like the bug. 125 means “cannot test this one”: git marks it skipped and tries a \
                        \neighbour."
                    p_ $ do
                        "Structure every bisect script as: build, "
                        c "|| exit 125"
                        "; then run the one test that detects the regression, and let its exit status through. \
                        \If too many commits are untestable, git may end with a set of candidates rather than one \
                        \commit."
                )
            ,
                ( "You mistyped "
                    <> c "good"
                    <> " for "
                    <> c "bad"
                    <> " at step three, and bisect confidently names a commit that cannot be the culprit. Do you \
                       \have to start again?"
                , p_ $ do
                    "No. "
                    c "git bisect log > log.txt"
                    ", open it, delete the wrong line and everything after it, then "
                    c "git bisect reset"
                    " and "
                    c "git bisect replay log.txt"
                    ". You are back at step three with the right answer on record. The log is plain "
                    c "git bisect"
                    " commands with comments, which is also what you attach to a bug report."
                )
            ,
                ( "Bisecting a year of history on "
                    <> c "main"
                    <> ", git keeps checking out commits from feature branches that were merged long ago, and \
                       \half of them do not build. How do you keep it on the mainline?"
                , p_ $ do
                    c "git bisect start --first-parent bad good"
                    ". git then considers only the commits reachable by first-parent links — the merges and direct \
                    \commits on "
                    c "main"
                    " — and never descends into the branches. The answer is a merge commit rather than the exact \
                    \commit inside it, which is often what you wanted anyway: “which merge broke it”. Bisect again \
                    \inside that merge's branch if you need more precision."
                )
            ,
                ( "You write "
                    <> c "git bisect run ./test.sh"
                    <> " but "
                    <> c "test.sh"
                    <> " is not executable. The man page says 126 counts as “bad”. Why do you not get a wrong answer?"
                , do
                    p_ $ do
                        "Because git 2.52 is more careful than its manual page. When the command exits 126 or 127 \
                        \(“not executable”, “not found”), "
                        c "bisect run"
                        " checks the verdict by running the command on a commit you told it was good. If that fails \
                        \too, it stops with "
                        c "error: bogus exit code 127 for good revision"
                        " instead of carrying on. A genuine 127 from inside a working script, on a bad commit, is \
                        \still treated as “bad”."
                    p_ "Relying on that safety net is still a mistake. Run the script once by hand on a good commit before you hand it to bisect."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d16diagram :: Diagram
d16diagram =
    ( diagram
        "A bisect session has a known-bad and a known-good commit, and narrows the set of candidate commits \
        \between them. The candidate set has as midpoint the commit checked out next. A test judges that \
        \commit and returns a verdict of good, bad or skip, which halves the candidate set. When one \
        \candidate is left, it is the first bad commit."
        body'
    )
        { dgCaption = do
            "Bisect never looks at code. It only needs "
            b_ "a test"
            " that can say good or bad about one commit, and it spends that test as efficiently as possible: \
            \every verdict removes half of the candidates, so 29 commits take five tests and a thousand take \
            \ten. The whole skill is writing a test you trust — the amber box is where sessions go wrong."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  sess  [label=\"a bisect session\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  bad   [label=\"a known-bad commit\"];\n\
        \  good  [label=\"a known-good commit\"];\n\
        \  cand  [label=\"the set of candidate commits\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  mid   [label=\"the commit checked out next\"];\n\
        \  test  [label=\"a test\\n(you, or a script)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  verd  [label=\"a verdict\\n(good, bad, skip)\"];\n\
        \  first [label=\"the first bad commit\"];\n\
        \\n\
        \  sess -> bad   [label=\"  has\"];\n\
        \  sess -> good  [label=\"  has\"];\n\
        \  sess -> cand  [label=\"  narrows\"];\n\
        \  cand -> mid   [label=\"  has as midpoint\"];\n\
        \  cand -> first [label=\"  ends, at size one, as\", style=dashed];\n\
        \  mid  -> test  [label=\"  judges\", dir=back];\n\
        \  test -> verd  [label=\"  returns\"];\n\
        \  verd -> cand  [label=\"  halves\", constraint=false];\n\
        \\n\
        \  { rank=same; bad; good; cand; }\n\
        \  { rank=same; mid; first; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "History is sorted, so search it" $ do
        p_ [class_ "lede"] $ do
            "If the bug is present now and was absent at the last release, then somewhere between those two \
            \commits there is a first commit that has it. You do not need to read any of them to find it. Check \
            \out the one in the middle and test it; whichever half the answer rules out, discard. "
            c "git bisect"
            " does the bookkeeping, and turns an afternoon of reading diffs into a handful of test runs."
        sh
            [ "$ git bisect start HEAD v1.0"
            , "Bisecting: 14 revisions left to test after this (roughly 4 steps)"
            , "[32535859ef4bd295a18c2147a6c6b48ecf5a8f6a] Change 15"
            ]
        p_ $ do
            "Twenty-nine candidates, four more steps after this one. git has detached "
            c "HEAD"
            " at the midpoint and is waiting for a verdict. The good commit can be given more than once — \
            \several known-good tags, for instance — and each one prunes more history."
        why $ p_ $ do
            "Bisect is only possible because a commit is a complete snapshot (Day 1): any single commit can be \
            \checked out and tested on its own, without replaying anything. And it is only fast because the \
            \search is logarithmic — "
            b_ "a thousand commits take about ten tests"
            ", ten thousand about fourteen. The cost of a regression hunt stops depending on how long ago it \
            \happened."
        fig

    block "A session by hand" $ do
        p_ "At each step, test the checked-out commit however you like — run the program, open the page, run one test — and answer:"
        sh
            [ "$ ./calc.sh"
            , "4"
            , "$ git bisect good"
            , "Bisecting: 7 revisions left to test after this (roughly 3 steps)"
            , "[f952f4e8666e148979abe0b0d9ee2662354e3959] Change 22"
            , "$ ./calc.sh"
            , "5"
            , "$ git bisect bad"
            , "Bisecting: 3 revisions left to test after this (roughly 2 steps)"
            , "[c7901deac8c54021e4a41457ec56927468bf8c13] Change 18"
            , "…"
            , "$ git bisect bad"
            , "7606c0694d3d53b691084c70f48f307cde960e52 is the first bad commit"
            , "commit 7606c0694d3d53b691084c70f48f307cde960e52"
            , "    Change 19"
            , "$ git bisect reset"
            , "Switched to branch 'main'"
            ]
        defs
            [ (c "git bisect skip", "The commit cannot be tested — it does not build, or the feature you test did not exist yet. git picks a neighbour instead of the exact midpoint.")
            , (c "git bisect view --oneline", "The commits still in the running, as a log.")
            , (c "git bisect log", "The session so far, as a replayable list of commands.")
            , (c "git bisect reset", "Leave the session and go back where you started. Always the last step, found or not.")
            ]
        gotcha $ p_ $ do
            "One wrong answer does not produce an error; it produces a wrong result, delivered with the same \
            \confidence as a right one. If the “first bad commit” makes no sense, do not argue with it. Save "
            c "git bisect log"
            " to a file, delete the line with the doubtful verdict and everything after it, "
            c "git bisect reset"
            ", and "
            c "git bisect replay"
            " the file. You are back where the mistake happened."

    block "Let a script answer" $ do
        p_ $ do
            "Any question a human answers the same way every time, a script can answer. "
            c "git bisect run"
            " runs a command at every step and reads its exit status:"
        defs
            [ (c "0", "good: this commit does not have the problem")
            , (c "1–127, except 125", "bad: this commit has it")
            , (c "125", "cannot test this commit; skip it")
            , ("anything else", "stop the whole bisect — something is wrong with the test itself")
            ]
        sh
            [ "$ cat test-calc.sh"
            , "#!/bin/sh"
            , "[ -x ./calc.sh ] || exit 125"
            , "[ \"$(./calc.sh)\" = 4 ]"
            , "$ git bisect start HEAD v1.0"
            , "$ git bisect run ./test-calc.sh"
            , "running './test-calc.sh'"
            , "Bisecting: 7 revisions left to test after this (roughly 3 steps)"
            , "…"
            , "7606c0694d3d53b691084c70f48f307cde960e52 is the first bad commit"
            , "bisect found first bad commit"
            ]
        p_ $ do
            "The first line of the script is the important one. A test that cannot even set itself up — no \
            \build, missing file — must say 125, not 1, or the bisect will blame the first commit that did not \
            \build. The pattern is always: prepare, "
            c "|| exit 125"
            "; then the one check. Keep the script outside the repository (or untracked), so checking out old \
            \commits cannot change or remove it."
        note $ p_ $ do
            "git-bisect(1) says that 126 and 127 are ordinary “bad” codes. git 2.52 adds a safety net the page \
            \does not describe: on 126 or 127 it re-runs the command on a known-good commit, and if that fails \
            \too it aborts with "
            c "error: bogus exit code 127 for good revision"
            ". A mistyped script name therefore stops the session instead of blaming a random commit. Exit codes \
            \of 128 and above abort immediately: "
            c "exit code 200 … is < 0 or >= 128"
            "."

    block "Beyond “bug”: terms and first parents" $ do
        p_ $ do
            "Bisect finds the boundary between any two states, not only working and broken. When you are hunting \
            \a performance improvement, or the commit that changed some output on purpose, “good” and “bad” \
            \read backwards. Name the states yourself:"
        sh
            [ "$ git bisect start --term-old=slow --term-new=fast HEAD v1.0"
            , "$ git bisect terms"
            , "Your current terms are slow for the old state"
            , "and fast for the new state."
            , "$ git bisect good"
            , "error: Invalid command: you're currently in a fast/slow bisect"
            , "$ git bisect slow"
            , "Bisecting: 7 revisions left to test after this (roughly 3 steps)"
            ]
        p_ $ do
            c "old"
            " and "
            c "new"
            " are built-in synonyms if you only want neutral words. The exit-code contract of "
            c "run"
            " is unchanged: 0 is the old state."
        p_ $ do
            "On a history full of merges, "
            c "git bisect start --first-parent"
            " keeps the search on the mainline and never checks out a commit from inside a merged branch. You \
            \learn which merge brought the problem in; bisect that branch separately if you need the exact \
            \commit. It also sidesteps the commits on long-dead feature branches that no longer build."

    block "Today's habit" $ do
        p_ $ do
            "The next time you catch yourself reading history to find when something changed, stop and bisect \
            \instead. Write the test first, as a script, and run it by hand once on a good and a bad commit \
            \before trusting it to "
            c "git bisect run"
            "."
        p_ $ do
            "Tomorrow: conflicts at scale — strategy options, resolving by side, and teaching git to repeat a \
            \resolution you already made."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Every verdict halves the candidates."
        " The test is the only hard part."
    cfg
        [ "git bisect start BAD GOOD...        # e.g. HEAD v1.0"
        , "git bisect good | bad | skip        # answer for the checked-out commit"
        , "git bisect run ./test.sh            # 0 good, 1-127 bad, 125 skip, >=128 abort"
        , "#   test.sh:  build || exit 125;  run the one check"
        , "git bisect log > f; git bisect replay f   # undo a wrong answer"
        , "git bisect view --oneline           # what is left"
        , "git bisect start --first-parent ... # mainline only: find the merge"
        , "git bisect start --term-old=slow --term-new=fast ..."
        , "git bisect reset                    # always, at the end"
        ]
