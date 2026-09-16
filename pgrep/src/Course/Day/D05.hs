module Course.Day.D05 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 5
        , dayTitle = "Time, state, inversion"
        , daySubtitle = "The newest, the oldest, the stuck — and what -v really negates."
        , dayMinutes = 35
        , dayLevel = "intermediate"
        , dayManRef = "OPTIONS (-n, -o, -O, -r, -v), BUGS"
        , dayTags = ["-n/-o", "runstates", "-v"]
        , dayGoals =
            [ "pick out the newest or oldest match, and say why " <> c "-n" <> " and " <> c "-v" <> " cannot both be used"
            , "read a process's run state and select on it, including the states nobody mentions"
            , "predict exactly which processes " <> c "pgrep -u you -v name" <> " returns"
            ]
        , dayDiagram = Just d5diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("pgrep -n -a firefox", "The most recently started match, with its command line.")
            , ("pgrep -O 3600 -u $USER -a", "Everything of yours that has been running for over an hour.")
            , ("pgrep -r D -a", "Processes in uninterruptible sleep — the ones a dying disk produces.")
            ]
        , dayOpts =
            [ ("-n, --newest", "Keep only the most recently started match.")
            , ("-o, --oldest", "Keep only the least recently started match.")
            , ("-O, --older", "Keep matches started more than this many seconds ago.")
            , ("-r, --runstates", "Keep matches in one of these kernel run states. A comma list.")
            , ("-v, --inverse", "Return everything the query did " <> b_ "not" <> " select — the whole query, not just the pattern.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Start three copies of something — " <> c "sleep 500 &" <> " three times, a second apart — then use " <> c "-n" <> " and " <> c "-o" <> " to pick out the two ends."
            , "Count the states on your machine: " <> c "for s in R S D Z I T; do echo -n \"$s \"; pgrep -r $s -c . ; done" <> ". Two of them will account for nearly everything."
            , "Look for what " <> c "-r" <> " does with nonsense: " <> c "pgrep -r Q -l; echo $?" <> ". No error, no output, exit " <> c "1" <> ". A typo here is invisible."
            , "Find your long-lived processes: " <> c "pgrep -O 86400 -u $USER -a" <> ". Anything surprising in there has probably leaked."
            , "Break the combination rule on purpose: " <> c "pgrep -n -v bash" <> ". Read the usage message and notice it does not say what is wrong."
            , "Run " <> c "pgrep -c ." <> ", " <> c "pgrep -c bash" <> " and " <> c "pgrep -v -c bash" <> ". Confirm the first equals the sum of the other two."
            , "Now run " <> c "pgrep -u $USER -v -c bash" <> " and compare it to the number above. If they match, you have just seen what " <> c "-v" <> " actually negates."
            , "Add a " <> c "-O" <> " recipe to your file for whatever on your machine is allowed to run for a while but not forever."
            ]
        , dayQuiz =
            [
                ( "You want \"my processes, except the shells\" and write " <> c "pgrep -u $USER -v bash" <> ". You get back more processes than you own, including PID 1. Explain."
                , do
                    p_ $ do
                        opt "-v"
                        " inverts the "
                        i_ "entire query"
                        ", not the pattern within it. You asked for the complement of \"owned by me AND named bash\", and by De Morgan that is everything which is either not mine or not a bash — which is almost the whole process table, root's included."
                    p_ $ do
                        "On a machine with 612 processes, 4 of them bash: "
                        c "pgrep -u $USER -v -c bash"
                        " returns 608, exactly the same as "
                        c "pgrep -v -c bash"
                        ". The user criterion contributed nothing except a false sense of having restricted something."
                    p_ $ do
                        "There is no single invocation that expresses \"mine but not bash\". Filter afterwards — "
                        c "comm -23 <(pgrep -u $USER . | sort) <(pgrep -u $USER bash | sort)"
                        " — or, far more often, reach for a sharper positive criterion instead of a negative one."
                )
            ,
                ( "Why can " <> c "-n" <> " and " <> c "-v" <> " not be used together, and what is unhelpful about how pgrep tells you?"
                , do
                    p_ $ do
                        "Because they contradict each other structurally. "
                        opt "-n"
                        " reduces the selection to a single process; "
                        opt "-v"
                        " replaces the selection with its complement. \"The newest of everything that did not match\" is a question nobody has needed, and procps declines to guess. "
                        c "pgrep(1)"
                        " lists it under BUGS with the invitation \"Let me know if you need to do this\"."
                    p_ $ do
                        "The unhelpful part is the diagnostic: you get the full usage message with "
                        b_ "no error line at all"
                        " explaining which two flags conflict. Exit status "
                        c "2"
                        ", and a wall of text you have to diff against your command by eye."
                )
            ,
                ( "A nightly job greps for stuck processes with " <> c "pgrep -r D -a" <> " and has never reported anything, on a machine with known NFS problems. What should you check first?"
                , do
                    p_ $ do
                        "That the job is running often enough. State "
                        c "D"
                        " — uninterruptible sleep — is real but usually brief; a process is in it for the duration of one blocking syscall. A once-a-night sample will miss almost every occurrence even on a badly behaved mount."
                    p_ $ do
                        "The second thing to check is the letter. "
                        opt "-r"
                        " accepts anything: "
                        c "pgrep -r Q"
                        " is not an error, it just silently matches nothing and exits "
                        c "1"
                        ", which is indistinguishable from \"no stuck processes\". A typo in that flag will never be noticed."
                )
            ,
                ( "Your machine has 612 processes. " <> c "pgrep -r S -c ." <> " says 370 and " <> c "pgrep -r R -c ." <> " says 0. Where are the other 242?"
                , do
                    p_ $ do
                        "Almost all of them are in state "
                        c "I"
                        ", idle — kernel worker threads that Linux has reported separately from ordinary sleep since 4.14. "
                        c "pgrep -r I -c ."
                        " on that machine returns exactly 242, and "
                        c "-r I,S"
                        " accounts for all 612."
                    p_ $ do
                        "The manual page's \"D,R,S,Z\" is a sample, not the list. "
                        c "T"
                        " (stopped), "
                        c "t"
                        " (traced) and "
                        c "I"
                        " are all selectable and none are mentioned. "
                        c "ps"
                        "'s own "
                        c "PROCESS STATE CODES"
                        " section is the real reference."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d5diagram :: Diagram
d5diagram =
    ( diagram
        "A running process was started at a start time and is currently in a run state; both \
        \are tested by criteria, every criterion is a conjunct of the whole conjunction, and \
        \that conjunction determines the selection. -v inverts the conjunction, producing the \
        \complement of the selection rather than the complement of any single criterion."
        body'
    )
        { dgCaption = do
            "The whole point is where the dashed arrow starts. "
            b_ "-v inverts the conjunction, not a criterion"
            " — so every other flag you added is inside the negation with the pattern, and \
            \contributes nothing to narrowing the result. "
            c "pgrep -u you -v bash"
            " is not \"your non-bash processes\"; it is \"everything that is not one of your \
            \bash processes\", which is nearly the whole machine."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  proc  [label=\"a running process\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  start [label=\"its start time\"];"
            , "  state [label=\"its run state\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  crit  [label=\"a criterion\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  conj  [label=\"the whole conjunction\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  sel   [label=\"the selection\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  comp  [label=\"the complement\\n(what -v returns)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  proc  -> start [label=\"  was started at\"];"
            , "  proc  -> state [label=\"  is currently in\"];"
            , "  start -> crit  [label=\"  is tested by\"];"
            , "  state -> crit  [label=\"  is tested by\"];"
            , "  crit  -> conj  [label=\"  is a conjunct of\"];"
            , "  conj  -> sel   [label=\"  determines\"];"
            , "  conj  -> comp  [label=\"  is inverted by -v into  \", style=dashed];"
            , "  sel   -> comp  [label=\"  has as complement  \", style=dashed, constraint=false];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Two facts the process table keeps for you" $ do
        p_ [class_ "lede"] $ do
            "Yesterday's criteria were about identity, and identity does not change. Today's two \
            \are about the present moment: when a process started, and what it is doing right \
            \now. Both come free from "
            c "/proc"
            ", and both let you write queries that would otherwise need "
            c "ps"
            " and a sort."
        p_ $ do
            "Start time gives three flags. "
            opt "-n"
            " and "
            opt "-o"
            " reduce the selection to a single process — the most and least recently started — \
            \and "
            opt "-O"
            " takes a number of seconds and keeps everything older than that."
        sh
            [ "$ pgrep -o -l bash      # the oldest shell on the machine"
            , "239195 bash"
            , "$ pgrep -n -l bash      # the newest, which is usually the one asking"
            , "273471 bash"
            , "$ pgrep -O 3600 -u jhrcek -c .    # mine, running for over an hour"
            , "144"
            ]
        tip $ p_ $ do
            opt "-n"
            " is the flag for \"the one I just started\" when you do not have "
            c "$!"
            " to hand — after a program has daemonised, or when the thing you want was started by \
            \something else. It is a guess, but it is usually the right guess, and it beats \
            \reading "
            c "ps"
            " output with your eyes."
        fig

    block "Run states, and the two nobody mentions" $ do
        p_ $ do
            opt "-r"
            " selects on the kernel's run state — the same letter "
            c "ps"
            " shows in its "
            c "STAT"
            " column. The manual page offers \""
            c "D,R,S,Z,…"
            "\" and the ellipsis is doing a great deal of work, because on a modern Linux box \
            \those four account for barely half the table:"
        sh
            [ "$ pgrep -c .        # every process"
            , "612"
            , "$ pgrep -r S -c .   # interruptible sleep"
            , "370"
            , "$ pgrep -r R -c .   # actually running"
            , "0"
            , "$ pgrep -r I -c .   # idle kernel threads"
            , "242"
            ]
        defs
            [ (c "S", "Interruptible sleep. Waiting for something, and can be signalled. Nearly every normal process, nearly all the time.")
            , (c "I", "Idle. A kernel thread with nothing to do. Linux has reported these separately since 4.14 and the manual page has not caught up.")
            , (c "R", "Running or runnable. Usually a very short list; on an idle machine, often empty.")
            , (c "D", "Uninterruptible sleep — blocked in a syscall that cannot be interrupted. The state a failing disk or a hung NFS mount produces, and the reason a process can survive " <> c "kill -9" <> ".")
            , (c "Z", "Defunct: exited, but its parent has not reaped it. It holds a PID and nothing else.")
            , (c "T" <> " and " <> c "t", "Stopped by a signal, and stopped by a debugger. Also selectable, also undocumented here.")
            ]
        gotcha $ p_ $ do
            opt "-r"
            " does not validate its argument. "
            c "pgrep -r Q"
            " — "
            c "Q"
            " is not a Linux run state — produces no error, no output and exit status "
            c "1"
            ", which is exactly what a correct query returns when nothing is in that state. A \
            \typo'd letter in a monitoring script will report \"all clear\" forever."

    block "The defunct are still in the table" $ do
        p_ $ do
            "A zombie is an exited process whose parent has not yet called "
            c "wait"
            ". It has no memory, no threads and cannot run, but it still owns a PID and a "
            c "/proc"
            " entry — so pgrep finds it, and "
            c "pgrep(1)"
            " lists \"Defunct processes are reported\" under BUGS."
        sh
            [ "$ pgrep -x python3 -l"
            , "273405 python3"
            , "273406 python3"
            , "$ pgrep -r Z -a"
            , "273406 [python3] <defunct>"
            ]
        p_ $ do
            "Two identical-looking lines, one of which is a corpse. Only "
            opt "-a"
            " or "
            opt "-r"
            " tells them apart — the "
            c "[brackets]"
            " and "
            c "<defunct>"
            " come from the command line being empty, not from anything pgrep adds."
        why $ p_ $ do
            "This is worth internalising before Day 7, because pkill will cheerfully \"signal\" a \
            \zombie and report success. There is nothing there to receive the signal; the count \
            \goes up and nothing happens. A process stuck at "
            c "Z"
            " is a bug in its "
            i_ "parent"
            ", and the only cure is to signal the parent instead."

    block "What -v actually negates" $ do
        p_ $ do
            "The manual page gives "
            opt "-v"
            " four words: \"Negates the matching.\" It is the most consequential four words in the \
            \page, because the thing it negates is not the pattern. It is the "
            b_ "entire conjunction"
            " — every criterion you supplied, taken together."
        p_ $ do
            "The demonstration takes three commands. This machine has 616 processes, 5 of them \
            \bash, all 5 mine:"
        sh
            [ "$ pgrep -c .                     # everything"
            , "612"
            , "$ pgrep -c bash                  # the bashes"
            , "4"
            , "$ pgrep -v -c bash               # not-bash: 612 - 4, as expected"
            , "608"
            , "$ pgrep -u jhrcek -c .           # everything of mine"
            , "149"
            , "$ pgrep -u jhrcek -v -c bash     # 'mine, but not bash'?"
            , "608"
            ]
        p_ $ do
            "That last number should be 145 — my 149 processes less my 4 shells. It is 608, \
            \identical to the run without "
            opt "-u"
            " at all, and the result contains PID 1, which belongs to root. The query pgrep \
            \answered was:"
        ascii
            [ "  you asked for:   NOT ( owned by jhrcek  AND  named bash )"
            , "  you meant:           ( owned by jhrcek  AND  NOT named bash )"
            ]
        p_ $ do
            "By De Morgan the first is \"not mine, "
            i_ "or"
            " not a bash\", which is satisfied by almost every process on the machine. The "
            opt "-u"
            " did not restrict anything; it went inside the negation along with the pattern."
        gotcha $ p_ $ do
            "There is no way to express \"mine but not bash\" in one pgrep. If you need it, take \
            \the difference of two queries — "
            c "comm -23 <(pgrep -u $USER . | sort) <(pgrep -u $USER bash | sort)"
            " — or, much better, find a positive criterion that says what you actually mean. A "
            opt "-v"
            " with other criteria beside it is nearly always a bug."
        note $ p_ $ do
            opt "-v"
            " cannot be combined with "
            opt "-n"
            " or "
            opt "-o"
            ", and pgrep reports the conflict by printing the usage message with no error line \
            \whatsoever. Exit "
            c "2"
            ", and you are left to work out which pair of flags it objected to. In pkill the short "
            c "-v"
            " is disabled outright — Day 7 explains why that is a mercy."

    block "Today's habit" $ do
        p_ $ do
            "When you catch yourself writing "
            opt "-v"
            ", stop and write down what you actually want in English. If the sentence has an \
            \\"and\" in it, "
            opt "-v"
            " will not do it, and the ten seconds you spend noticing that is the cheapest \
            \debugging you will ever do."
        p_ $ do
            "Tomorrow: what is underneath a process, and what is beside it — threads, which have \
            \their own names, and pidfiles, which have their own truth."
        cfg
            [ "# Day 5: my long-lived processes. Anything unexpected here has leaked."
            , "pgrep -O 86400 -u \"$USER\" -a"
            , ""
            , "# Day 5: the ones a dying disk produces. Sample often - D is usually brief."
            , "pgrep -r D -a"
            ]

cheat :: Html ()
cheat = do
    cfg
        [ "pgrep -n NAME     # newest match only     } cannot be combined"
        , "pgrep -o NAME     # oldest match only     } with each other, or with -v"
        , "pgrep -O 3600     # started more than 3600 seconds ago"
        , "pgrep -r S,I      # by run state, comma list. An invalid letter is SILENT."
        , "#"
        , "#   S interruptible sleep   I idle kernel thread   R running"
        , "#   D uninterruptible       Z defunct              T/t stopped, traced"
        , "#"
        , "pgrep -v NAME     # NOT(every criterion together) - not 'the others that match'"
        , "# pgrep -u me -v bash  ==  pgrep -v bash. The -u is inside the negation."
        , "# Zombies are reported like anything else: check with -a or -r Z."
        ]
