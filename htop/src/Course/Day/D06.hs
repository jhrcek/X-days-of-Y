module Course.Day.D06 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 6
        , dayTitle = "Acting on processes"
        , daySubtitle = "Tag, signal, renice, pin to CPUs — and the one question to ask before every one of them."
        , dayMinutes = 35
        , dayLevel = "intermediate"
        , dayManRef = "INTERACTIVE COMMANDS"
        , dayTags = ["signals", "nice", "affinity"]
        , dayGoals =
            [ "say, before pressing any action key, exactly which processes it will hit"
            , "send a chosen signal to a chosen set without typing a single PID"
            , "change priority, CPU affinity and I/O class, and know which of them needs root"
            ]
        , dayDiagram = Just d6diagram
        , dayBody = body
        , dayKeys =
            [ ("Space", "Tag or untag the selected process. Tagged rows stay tagged until you clear them.")
            , ("c", "Tag the selected process and all of its children.")
            , ("U", "Untag everything. The most important key on this page.")
            , ("F9 k", "Open the signal menu. Defaults to " <> c "15 SIGTERM" <> ".")
            , ("F7 ]", "Raise priority — lower the nice value. Root only.")
            , ("F8 [", "Lower priority — raise the nice value. Anyone can do this to their own.")
            , ("}", "Raise the autogroup priority. " <> k "Shift-F7" <> ". Root only.")
            , ("{", "Lower the autogroup priority. " <> k "Shift-F8" <> ".")
            , ("a", "Set CPU affinity: tick the CPUs this process may run on.")
            , ("i", "Set the I/O scheduling class and priority. Not in the manual page.")
            , ("Y", "Set the scheduling policy. Not in the manual page either.")
            ]
        , dayCmds =
            [ ("htop --readonly", "Disable every process- and system-changing feature for this session.")
            ]
        , dayOpts = []
        , dayConfig = []
        , dayDrills =
            [ "Start something disposable — "
                <> c "sleep 600"
                <> " in another terminal — find it in htop, and send it "
                <> c "15 SIGTERM"
                <> " with "
                <> k "F9"
                <> ". Confirm the terminal says "
                <> c "Terminated"
                <> "."
            , "Do it again, but this time press "
                <> k "Space"
                <> " on the row first. Notice the row changes colour, and notice that "
                <> k "F9"
                <> " now acts on the tagged set rather than on wherever the cursor happens to be."
            , "Break something on purpose: tag three processes with "
                <> k "Space"
                <> ", then move the cursor somewhere completely different and press "
                <> k "F9"
                <> " — then "
                <> k "Esc"
                <> " out of it immediately. The menu was about to signal your three tags, not the \
                   \row under the cursor. This is the single most dangerous thing in htop."
            , "Press "
                <> k "U"
                <> " and watch the tags clear. Make this reflex: "
                <> k "U"
                <> " before every "
                <> k "F9"
                <> " unless you tagged deliberately ten seconds ago."
            , "Select your own shell and press "
                <> k "F8"
                <> " twice. Its "
                <> c "NI"
                <> " goes to 2. Now press "
                <> k "F7"
                <> " and read the failure — going back down needs root, and htop will not pretend \
                   \otherwise."
            , "Press "
                <> k "a"
                <> " on a busy process of your own and untick all but two CPUs. Watch the "
                <> c "CPU%"
                <> " ceiling drop to 200%, and watch the per-core meters in the header rearrange \
                   \themselves around your decision."
            , "Run "
                <> c "htop --readonly"
                <> " and look at the function bar. "
                <> c "F7"
                <> ", "
                <> c "F8"
                <> " and "
                <> c "F9"
                <> " have gone blank. This is the htop to put in a shared operations runbook."
            , "On your own machine: find the one process that is genuinely allowed to be greedy — \
              \a backup job, a batch import, a compile — and renice it to 10 with "
                <> k "F8"
                <> ". You have just given every interactive thing on the box priority over it, \
                   \for free."
            ]
        , dayQuiz =
            [
                ( "You select a runaway process, press "
                    <> k "F9"
                    <> ", choose "
                    <> c "SIGKILL"
                    <> ", press Enter — and three completely unrelated services die. What did you \
                       \do?"
                , do
                    p_ $ do
                        "You had tagged those three earlier and forgotten. Every action key in \
                        \htop follows the same rule: "
                        b_ "if anything is tagged, act on the tagged set; otherwise act on the \
                            \selected row"
                        ". The cursor position is a fallback, not the target."
                    p_ $ do
                        "Tags survive sorting, filtering, tree toggles and scrolling, and the only \
                        \sign of them is a colour change on rows that may well be off-screen. "
                        k "U"
                        " clears them all. Pressing "
                        k "U"
                        " before any destructive key costs nothing and is the habit that prevents \
                        \this entire class of accident."
                )
            ,
                ( "A process is stuck in "
                    <> c "D"
                    <> " state. You send it "
                    <> c "SIGTERM"
                    <> ", nothing. You send "
                    <> c "SIGKILL"
                    <> ", and it is still there a minute later. Is htop broken?"
                , do
                    p_ $ do
                        "No, and neither is "
                        c "kill"
                        ". "
                        c "D"
                        " is uninterruptible sleep — the process is inside a kernel call that \
                        \cannot be interrupted, almost always waiting on I/O from a disk or a \
                        \network filesystem. Signals are delivered when a process returns to user \
                        \space, and this one is not going to return until the I/O completes."
                    p_ $ do
                        c "SIGKILL"
                        " is not an exception: it is queued, not applied. The process will die the \
                        \instant its I/O finishes or errors out. If that never happens — a hung NFS \
                        \mount, a failing disk — the fix is at the storage layer, and nothing you \
                        \do in htop will help. Recognising "
                        c "D"
                        " early saves you from twenty minutes of escalating signals."
                )
            ,
                ( "You press "
                    <> k "F7"
                    <> " to speed up your own process and htop refuses, but "
                    <> k "F8"
                    <> " to slow it down works. Why the asymmetry?"
                , do
                    p_ $ do
                        "Because nice is a one-way street for unprivileged users: you may always \
                        \give away priority, and you may never take it back. Raising a nice value \
                        \is a concession, so anyone can do it; lowering it takes CPU from other \
                        \users, so it needs "
                        c "CAP_SYS_NICE"
                        " — in practice, root."
                    p_ $ do
                        "This catches people who renice “temporarily”. Drop your build to nice 10 \
                        \to keep your desktop responsive and you cannot put it back without "
                        c "sudo"
                        ", not even for a process you own and started yourself. Decide the nice \
                        \value before you commit to it."
                )
            ,
                ( "The manual page's INTERACTIVE COMMANDS section does not mention "
                    <> k "i"
                    <> " or "
                    <> k "Y"
                    <> ", yet both open dialogs. Where did they come from, and what else might be \
                       \missing?"
                , do
                    p_ $ do
                        "They are real, current features — "
                        k "i"
                        " sets the I/O scheduling class and "
                        k "Y"
                        " the CPU scheduling policy — and the manual page simply has not kept up. \
                        \htop's built-in help ("
                        k "F1"
                        ") lists both, because it is generated alongside the code rather than \
                        \maintained separately."
                    p_ $ do
                        "The same is true of "
                        k "#"
                        " (hide the header meters), "
                        k "e"
                        " (show a process's environment) and "
                        k "C"
                        " as an alias for Setup. The lesson generalises: for any curses program, "
                        b_ "the built-in help screen is closer to the truth than the man page"
                        ", because one of them ships with the binary and the other is a separate \
                        \file somebody has to remember to edit."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d6diagram :: Diagram
d6diagram =
    ( diagram
        "What an action key acts on: an action applies to the set of tagged processes, and only \
        \falls back to the selected row when that set is empty."
        body'
    )
        { dgCaption = do
            "One rule governs every destructive key on this page, and it is worth reading off the \
            \picture until it is automatic: an action targets "
            b_ "the tagged set"
            ", and the selected row is only a "
            i_ "fallback"
            " for when nothing is tagged. The dashed aspect is the one that hurts — it applies \
            \only when the tagged set is empty, and there is nothing on screen to tell you which \
            \case you are in if your tags have scrolled out of view."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  act   [label=\"an action\\n(kill, renice, affinity)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  tset  [label=\"the set of\\ntagged processes\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  tag   [label=\"a tagged process\"];\n\
        \  sel   [label=\"the selected row\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  proc  [label=\"a process\"];\n\
        \  sig   [label=\"a signal\"];\n\
        \\n\
        \  act  -> tset [label=\"  applies to\"];\n\
        \  tset -> tag  [label=\"  is made of\"];\n\
        \  tag  -> proc [label=\"  is\"];\n\
        \  sel  -> proc [label=\"  highlights\"];\n\
        \  act  -> sig  [label=\"  may send\"];\n\
        \  act  -> sel  [label=\"falls back to, only when nothing is tagged  \", style=dashed, constraint=false];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Ask the target question first" $ do
        p_ [class_ "lede"] $ do
            "From here on htop stops being a viewer and starts changing your machine. Before every \
            \action key there is exactly one question worth asking, and it is not “what does this \
            \key do” — it is "
            b_ "“what is this key about to do it to?”"
        p_ $ do
            "The answer is always the same rule. If any process is tagged, the action applies to "
            b_ "every tagged process"
            ". If nothing is tagged, it applies to the selected row. The cursor is the fallback, \
            \not the target."
        fig
        gotcha $ p_ $ do
            "Tags are persistent and nearly invisible. They survive re-sorting, filtering, \
            \switching to tree view and scrolling to the other end of the list; the only \
            \indication is a colour change on rows that may be nowhere near your screen. Tag three \
            \things, get distracted for ten minutes, press "
            k "F9"
            " on something else entirely, and you will kill the three. "
            k "U"
            " untags everything, and pressing it before anything destructive costs you nothing."

    block "Tagging" $ do
        defs
            [ (k "Space", "Tag or untag the selected process. The row changes colour and the cursor stays put.")
            , (k "c", "Tag the selected process and its children — the whole subtree, in one keystroke. Works in list view too, not only in the tree.")
            , (k "U", "Untag everything.")
            ]
        p_ $ do
            "Tagging is what makes htop faster than the shell for this kind of work. “Terminate \
            \these six workers but not the supervisor” is six presses of "
            k "Space"
            " and one "
            k "F9"
            ", with no PIDs typed and therefore no PIDs mistyped."
        tip $ p_ $ do
            k "c"
            " is the one to reach for when a process tree has gone wrong — a build that spawned \
            \fifty children, a container's process group. Tag the parent with "
            k "c"
            " and the whole subtree comes with it. Combine it with Day 5's tree view so you can \
            \actually see the boundary of what you have selected."

    block "Signals" $ do
        p_ $ do
            k "F9"
            " or "
            k "k"
            " opens a menu of every signal on the system, "
            b_ "already positioned on 15 SIGTERM"
            ". Arrows to choose, "
            k "Enter"
            " to send, "
            k "Esc"
            " to escape."
        termWin
            "htop — F9"
            [ "Send signal:     PID USER       PRI  NI  VIRT   RES  PRIV S  CPU%"
            , "11 SIGSEGV     74738 jhrcek      20   0  235M 10744  6424 R   3.1"
            , "12 SIGUSR2      8898 jhrcek      20   0 1460G  362M  212M R   1.4"
            , "13 SIGPIPE      5399 jhrcek      20   0 12.6G  346M  164M S   0.9"
            , "14 SIGALRM      7575 jhrcek      20   0 53.7G  823M  392M S   0.9"
            , "15 SIGTERM      7644 jhrcek      20   0 53.5G  456M  240M S   0.5"
            , "EnterSend   EscCancel"
            ]
        p_ $ do
            "That default is a small kindness. The key is labelled “Kill”, everybody reads that as "
            c "SIGKILL"
            ", and htop quietly starts you on the signal that lets a process clean up after itself. \
            \Take the default unless you have a reason not to."
        why $ p_ $ do
            "A menu rather than a prompt is the right design here, and for a reason worth \
            \internalising: it makes the dangerous option no easier to reach than the safe one. \
            \Typing "
            c "kill -9"
            " is fewer keystrokes than "
            c "kill -15"
            ", so the shell actively rewards impatience. In htop both are one arrow key away from \
            \each other and neither is the path of least resistance."
        gotcha $ p_ $ do
            "A process in "
            c "D"
            " state will not die, and no signal changes that — not "
            c "SIGKILL"
            ". Signals are delivered when a process returns to user space, and uninterruptible \
            \sleep means it is inside a kernel call that will not return until its I/O completes. \
            \The signal is queued and applied later, possibly never. When you see "
            c "D"
            ", stop signalling and go and look at the storage."

    block "Priority: nice, and the wall at zero" $ do
        p_ $ do
            "Nice runs from −20 (greedy) to 19 (generous), and the "
            c "NI"
            " column shows it. "
            k "F8"
            " or "
            k "["
            " raises the value — makes the process nicer, lower priority. "
            k "F7"
            " or "
            k "]"
            " lowers it, and needs root."
        p_ $ do
            "The asymmetry is a kernel rule, not an htop one: giving away priority is always \
            \allowed, taking it back needs "
            c "CAP_SYS_NICE"
            ". You can renice your own process down and then be unable to undo it without "
            c "sudo"
            "."
        p_ $ do
            "There is a second, coarser knob beside it. "
            k "}"
            " and "
            k "{"
            " — "
            k "Shift-F7"
            " and "
            k "Shift-F8"
            " — change the "
            b_ "autogroup"
            " nice value, which applies to a whole session's worth of processes at once rather \
            \than to one. It needs Linux CFS autogrouping enabled, and the "
            opt "AGRP"
            " and "
            opt "ANI"
            " columns from Day 10 show you what it is doing."
        tip $ p_ $ do
            "The high-value use of nice is not emergencies, it is routine: pick the one long job \
            \on your machine that nobody is waiting for — backups, indexing, a nightly compile — \
            \and put it at nice 10 permanently. Interactive work gets the CPU whenever it wants it, \
            \and the batch job soaks up the rest. Nothing is ever slower; some things are much \
            \faster."

    block "Affinity, I/O class and scheduling policy" $ do
        p_ "Three more dialogs, each pinning down a different resource. All three open on the same tagged-or-selected rule."
        defs
            [
                ( k "a" <> " — CPU affinity"
                , do
                    "A checklist of every CPU, all ticked by default. Untick some and the process \
                    \is confined to the rest. Useful for holding a noisy neighbour away from the \
                    \cores your latency-sensitive thing runs on; note that it caps that process's "
                    c "CPU%"
                    " at 100% per remaining core."
                )
            ,
                ( k "i" <> " — I/O priority"
                , do
                    "Classes "
                    c "Realtime 0–7"
                    ", "
                    c "Best-effort 0–7"
                    ", "
                    c "Idle"
                    ", and "
                    c "None (based on nice)"
                    " at the top, which is the default and derives the I/O class from the nice \
                    \value. The "
                    opt "IO_PRIORITY"
                    " column displays the result as "
                    c "R"
                    ", "
                    c "B"
                    " or "
                    c "id"
                    " plus a number. Undocumented in the manual page."
                )
            ,
                ( k "Y" <> " — scheduling policy"
                , do
                    c "Other"
                    ", "
                    c "Batch"
                    ", "
                    c "Idle"
                    ", "
                    c "FiFo"
                    ", "
                    c "RoundRobin"
                    ", and a “Reset on fork” toggle. The real-time policies need privilege and can \
                    \lock up a machine if you give one to something that spins. Undocumented in \
                    \the manual page."
                )
            ]
        note $ p_ $ do
            "For a batch job, "
            k "i"
            " set to "
            c "Idle"
            " is usually a bigger win than "
            k "F8"
            ". Nice governs CPU, and most background jobs are not short of CPU — they are \
            \saturating the disk and making everything else wait behind them in the I/O queue."

    block "Taking the sharp edges off" $ do
        p_ $ do
            c "htop --readonly"
            " disables every feature that changes a process or the system. It is not a warning \
            \dialog; the capability is simply gone, and the function bar shows it — "
            c "F7"
            ", "
            c "F8"
            " and "
            c "F9"
            " render blank."
        sh
            [ "$ htop --readonly"
            , "F1Help  F2Setup F3SearchF4FilterF5Tree  F6SortByF7      F8      F9      F10Quit"
            ]
        p_ $ do
            "Two places it earns its keep: the htop you paste into a runbook for someone who is \
            \tired and on call, and the htop you run on a machine where you have root and do not \
            \want it. There is also "
            c "--drop-capabilities"
            ", which goes further by shedding Linux capabilities outright, at the cost of some \
            \columns no longer working — this course leaves it alone, and Day 14 says where to read \
            \about it."

    block "Today's habit" $ do
        p_ $ do
            "Make "
            k "U"
            " part of the gesture. Not “press U when I think I might have tags”, but "
            k "U"
            " immediately before every "
            k "F9"
            ", the way you check a mirror before pulling out. It costs one keystroke and prevents \
            \the only genuinely bad thing htop can do to you."
        p_ "Tomorrow: the six keys that open a whole screen about one process — strace, lsof, the environment, and file locks."

cheat :: Html ()
cheat = do
    cfg
        [ "THE RULE: every action hits the TAGGED SET if non-empty, else the selected row."
        , ""
        , "Space     tag / untag this process      c    tag this process AND its children"
        , "U         untag everything  <- press this before every F9"
        , ""
        , "F9  k     signal menu, starts on 15 SIGTERM   (Enter sends, Esc cancels)"
        , "F8  [     nice +1  (lower priority)  -- anyone, on their own processes"
        , "F7  ]     nice -1  (raise priority)  -- root only, always"
        , "{   }     the same, for the process's AUTOGROUP (Shift-F8 / Shift-F7)"
        , "a         CPU affinity: tick the CPUs it may use"
        , "i         I/O class: None(nice) / Realtime / Best-effort / Idle   [not in man]"
        , "Y         scheduling policy: Other / Batch / Idle / FiFo / RR     [not in man]"
        , ""
        , "htop --readonly     F7, F8 and F9 go blank; nothing can be changed"
        ]
    p_ $ do
        "A process in "
        c "D"
        " state ignores every signal including "
        c "SIGKILL"
        " — it is inside a kernel call that has not returned. That is a storage problem, not a \
        \signalling problem."
