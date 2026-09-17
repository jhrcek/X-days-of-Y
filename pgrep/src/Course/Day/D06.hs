module Course.Day.D06 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 6
        , dayTitle = "Threads and pidfiles"
        , daySubtitle = "One level below a process, and one source of truth beside it."
        , dayMinutes = 30
        , dayLevel = "intermediate"
        , dayManRef = "OPTIONS (-w, -F, -L), NOTES"
        , dayTags = ["-w", "TIDs", "pidfiles"]
        , dayGoals =
            [ "explain why " <> c "pgrep gmain" <> " finds nothing and " <> c "pgrep -w gmain" <> " finds ninety-five things"
            , "tell a TID from a PID in pgrep output, and know when the distinction bites"
            , "use a pidfile as a criterion, and say what its three failure modes look like"
            ]
        , dayDiagram = Just d6diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("ls /proc/PID/task", "Every thread of a process, by TID.")
            , ("cat /proc/PID/task/TID/comm", "One thread's own name — often nothing like the process's.")
            , ("pgrep -w -f nginx", "All threads of every matching process, since threads share the command line.")
            ]
        , dayOpts =
            [ ("-w, --lightweight", "Walk threads rather than processes: match every thread's own name, and print TIDs.")
            , ("-F, --pidfile", "Read PIDs from a file and use them as a criterion.")
            , ("-L, --logpidfile", "With " <> c "-F" <> ", fail unless the pidfile is locked.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Find something threaded: " <> c "pgrep -l . | while read p n; do echo \"$(ls /proc/$p/task 2>/dev/null | wc -l) $p $n\"; done | sort -rn | head" <> "."
            , "Read its thread names with " <> c "for t in /proc/PID/task/*; do echo \"$(basename $t) $(cat $t/comm)\"; done" <> ". Most will be nothing like the process name."
            , "Pick one of those thread names and run " <> c "pgrep <name>" <> " then " <> c "pgrep -w <name>" <> ". The first finds nothing at all."
            , "Compare " <> c "pgrep -f -c <procname>" <> " with " <> c "pgrep -w -f -c <procname>" <> " on the threaded process. The second is the thread count."
            , "Check the ordering: " <> c "pgrep -w gmain | head -5" <> ". Unlike every other pgrep output, this one is not sorted."
            , "Make a pidfile by hand — " <> c "pgrep -o -x bash > /tmp/x.pid" <> " — then use it: " <> c "pgrep -F /tmp/x.pid -a" <> "."
            , "Break it three ways: put a nonexistent PID in the file, put the word " <> c "garbage" <> " in it, and add " <> c "-L" <> " to an unlocked file. Three different messages, all exit " <> c "1" <> "."
            , "If any daemon you run writes a pidfile, add a " <> c "-F" <> " health check for it to your recipes — and note in the comment that the file can lie."
            ]
        , dayQuiz =
            [
                ( "You are told a process called " <> c "gdbus" <> " is running and eating CPU. " <> c "pgrep gdbus" <> " returns nothing, exit 1. Is your colleague wrong?"
                , do
                    p_ $ do
                        "No — they are reading "
                        c "top"
                        " in threads mode, or "
                        c "ps -L"
                        ". "
                        c "gdbus"
                        " is a "
                        i_ "thread"
                        " name, not a process name: glib gives its D-Bus worker thread that "
                        c "comm"
                        ", and it lives inside some larger process such as "
                        c "udisksd"
                        "."
                    p_ $ do
                        "Without "
                        opt "-w"
                        " pgrep only considers thread group leaders, and a leader's name is the \
                        \process's name. "
                        c "pgrep -w gdbus"
                        " finds the thread and prints its TID; to find out what it belongs to, \
                        \read "
                        c "/proc/TID/status"
                        " and look at "
                        c "Tgid"
                        "."
                )
            ,
                ( "Why does " <> c "pgrep -w -f udisksd" <> " return seven results when " <> c "pgrep -f udisksd" <> " returns one?"
                , do
                    p_ $ do
                        "Because "
                        opt "-f"
                        " matches the command line, and "
                        c "pgrep(1)"
                        "'s NOTES say it plainly: threads may not share the process's "
                        i_ "name"
                        ", but they do all share its "
                        i_ "command line"
                        ". udisksd has seven tasks with seven different "
                        c "comm"
                        " values and one identical "
                        c "/proc/…/cmdline"
                        "."
                    p_ $ do
                        "So "
                        opt "-w"
                        " with "
                        opt "-f"
                        " is a thread counter: it returns every task of every matching process. \
                        \That is occasionally what you want and almost never what you meant to \
                        \type, especially with pkill on the other end."
                )
            ,
                ( "A start-up script does " <> c "if pgrep -F /run/app.pid; then echo already running; fi" <> " and wrongly reports the app as running after a hard reboot. What went wrong, and what does " <> c "-L" <> " have to do with it?"
                , do
                    p_ $ do
                        "The pidfile was never cleaned up, and the PID in it has been reused by \
                        \something unrelated. pgrep checked that the PID exists, which it does — \
                        \it just belongs to a different program now. A stale pidfile whose PID has \
                        \been recycled is indistinguishable from a live one."
                    p_ $ do
                        "Two defences. Add a criterion, so that the PID must also be the right \
                        \program: "
                        c "pgrep -F /run/app.pid -x myapp"
                        ". Or use "
                        opt "-L"
                        ", which requires the file to be "
                        i_ "locked"
                        " — a lock the kernel drops when the holder dies, so a stale file fails \
                        \the check. That only works if the daemon takes the lock in the first \
                        \place, which many do not."
                )
            ,
                ( "What is different about the ordering of " <> c "pgrep -w" <> " output, and why should a script care?"
                , do
                    p_ $ do
                        "Ordinary pgrep output is in ascending numeric order — a consequence of \
                        \walking "
                        c "/proc"
                        ", which the kernel presents sorted. "
                        opt "-w"
                        " descends into each process's "
                        c "task"
                        " directory as it goes, so TIDs come out grouped by process and \
                        \unsorted overall: "
                        c "1291 1262 1305 1271 1255 …"
                        "."
                    p_ $ do
                        "A script that assumes \"the first line is the lowest number\" — a common \
                        \way of guessing at the main thread — gets a different answer every time \
                        \the process table shifts. If you want the leader, ask for the leader: \
                        \drop "
                        opt "-w"
                        "."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d6diagram :: Diagram
d6diagram =
    ( diagram
        "A thread belongs to a running process, is identified by a thread ID and has its own \
        \name, but shares the process's command line. The process lists its threads in \
        \/proc/PID/task, is identified by a process ID, and a pidfile contains one of those."
        body'
    )
        { dgCaption = do
            "The amber box is what "
            opt "-w"
            " exists for: a thread has a name "
            b_ "of its own"
            ", invisible to every query that does not use the flag, while the command line is \
            \shared by the whole group. That is why "
            c "-w"
            " changes which processes match and not merely how they are printed — and why "
            c "-w -f"
            " returns one result per thread rather than one per process."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  proc  [label=\"a running process\\n(the thread group leader)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  task  [label=\"a thread\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  tid   [label=\"its thread ID\"];"
            , "  tname [label=\"the thread's own name\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  cline [label=\"the command line\"];"
            , "  taskd [label=\"/proc/PID/task\", fillcolor=\"#f4efe6\"];"
            , "  pidf  [label=\"a pidfile\", fillcolor=\"#f4efe6\"];"
            , "  pid   [label=\"a process ID\"];"
            , ""
            , "  task -> proc  [label=\"  belongs to\"];"
            , "  task -> tid   [label=\"  is identified by\"];"
            , "  task -> tname [label=\"  has as name\"];"
            , "  task -> cline [label=\"  shares\"];"
            , "  proc -> taskd [label=\"  lists its threads in\"];"
            , "  proc -> pid   [label=\"  is identified by\"];"
            , "  pidf -> pid   [label=\"  claims to contain\"];"
            , "  tid  -> pid   [label=\"  equals, for the leader  \", style=dashed, constraint=false];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Every query so far has ignored most of the machine" $ do
        p_ [class_ "lede"] $ do
            "pgrep walks processes, and a process is really a "
            i_ "thread group"
            " — the kernel schedules threads, and what you have been selecting is only each \
            \group's leader. On a desktop the leaders are a minority, and the names of everything \
            \else have been invisible for five days."
        p_ $ do
            "Every thread has its own "
            c "comm"
            ", and libraries set them deliberately so that debuggers and "
            c "top"
            " can tell them apart. Look inside one process and the names have almost nothing to \
            \do with the program:"
        sh
            [ "$ ls /proc/1230/task"
            , "1230  1255  1256  1260  1348  1349  1358"
            , "$ for t in /proc/1230/task/*; do echo \"$(basename $t) $(cat $t/comm)\"; done"
            , "1230 udisksd"
            , "1255 gmain"
            , "1256 pool-spawner"
            , "1260 gdbus"
            , "1348 udisks-probing-"
            , "1349 udisks-uevent-m"
            , "1358 cleanup"
            ]
        p_ $ do
            "Only the first line has the name pgrep has been matching against. "
            c "gmain"
            ", "
            c "gdbus"
            " and "
            c "pool-spawner"
            " are glib's worker threads, and they appear in hundreds of processes on a modern \
            \desktop without pgrep ever admitting they exist."
        fig

    block "-w changes what matches, not just what prints" $ do
        p_ $ do
            "The manual page describes "
            opt "-w"
            " as \"Shows all thread ids instead of pids\", which reads like an output flag. It is \
            \not. It changes the "
            b_ "unit pgrep iterates over"
            " — tasks instead of thread group leaders — so the pattern is tested against each \
            \thread's own name:"
        sh
            [ "$ pgrep gmain"
            , "$ echo $?"
            , "1"
            , "$ pgrep -w -c gmain"
            , "95"
            ]
        p_ $ do
            "Ninety-five threads called "
            c "gmain"
            ", in ninety-five different processes, none of which pgrep would mention without the \
            \flag. The other direction is just as informative:"
        sh
            [ "$ pgrep -f -c udisksd      # processes"
            , "1"
            , "$ pgrep -w -f -c udisksd   # threads, because they share the command line"
            , "7"
            ]
        why $ p_ $ do
            "That asymmetry is the one piece of NOTES worth memorising: "
            b_ "threads may not share the process's name, but they always share its command line"
            ". So "
            opt "-w"
            " with a name pattern finds a few specific threads, and "
            opt "-w"
            " with "
            opt "-f"
            " finds "
            i_ "all"
            " threads of every matching process. The second is rarely what someone typing "
            c "-wf"
            " intended."
        gotcha $ do
            p_ $ do
                "The numbers "
                opt "-w"
                " prints are TIDs, and a TID is not a PID — except for the leader, where they are \
                \equal. Everything downstream of pgrep has to cope with that. "
                c "kill"
                " on a non-leader TID signals the whole thread group, not that thread; "
                c "ps -p"
                " will not find it at all; and "
                c "/proc/TID"
                " exists but reports the group's information."
            p_ $ do
                "This output is also the one place pgrep does not sort. Processes come out in \
                \ascending numeric order; TIDs come out grouped by process, so the first line is \
                \not the smallest number and never was."

    block "Pidfiles: the answer the process gave you" $ do
        p_ $ do
            "Everything else in this course infers identity from the process table. A pidfile is \
            \the opposite: a number the program wrote down itself, which is authoritative right \
            \up until it is not."
        p_ $ do
            opt "-F"
            " reads PIDs from a file and treats them as one more criterion, so it ANDs with \
            \everything else. It also works alone, with no pattern:"
        sh
            [ "$ pgrep -o -x bash > /tmp/x.pid"
            , "$ pgrep -F /tmp/x.pid -a"
            , "239195 /usr/bin/bash"
            , "$ pgrep -F /tmp/x.pid nosuchname"
            , "$ echo $?"
            , "1"
            ]
        p_ "It fails in three distinguishable ways, and all three are exit status 1:"
        defs
            [
                ( "The PID is gone"
                , do
                    "No output, no message. Identical to any other empty result — which is correct, \
                    \and is what a health check wants."
                )
            ,
                ( "The file is not a number"
                , do
                    c "pgrep: pidfile not valid"
                    ". A truncated or half-written file lands here."
                )
            ,
                ( c "-L" <> " and no lock"
                , do
                    c "pgrep: Locking check for pidfile failed: No such file or directory"
                    ". The file exists but nobody holds a lock on it."
                )
            ]
        gotcha $ p_ $ do
            "The failure a pidfile "
            i_ "cannot"
            " report is the one that matters: the PID is alive but belongs to something else. \
            \After an unclean shutdown the file survives, the number gets reused, and "
            c "pgrep -F /run/app.pid"
            " confidently confirms an app that is not running. Always pair the pidfile with a \
            \second criterion — "
            c "pgrep -F /run/app.pid -x myapp"
            " — so that the PID has to be the right program as well as an existing one."
        note $ p_ $ do
            opt "-L"
            " is the proper fix, because a lock is released by the kernel when its holder dies \
            \and therefore cannot go stale. It only helps if the daemon actually takes the lock, \
            \which is a convention rather than a rule, and plenty of software writes the file \
            \without one. Check before you rely on it."

    block "Today's habit" $ do
        p_ $ do
            "Next time "
            c "top"
            " or a profiler shows you a name you cannot find, try "
            opt "-w"
            " before concluding the tool is lying. It costs one keystroke and it is the answer \
            \surprisingly often."
        p_ $ do
            "Tomorrow the query stops being a question. Everything learned so far selects a set \
            \of processes; pkill and pidwait take that same set and do something irreversible to \
            \it."
        cfg
            [ "# Day 6: which processes have a thread called this, and how many"
            , "pgrep -w -l gdbus | wc -l"
            , ""
            , "# Day 6: a pidfile check that a recycled PID cannot fool."
            , "pgrep -F /run/myapp.pid -x myapp --quiet"
            ]

cheat :: Html ()
cheat = do
    cfg
        [ "pgrep -w NAME      # walk THREADS: match each thread's own comm, print TIDs"
        , "pgrep -w -f NAME   # every thread of every match - threads share the cmdline"
        , "#   pgrep gmain     -> nothing        pgrep -w -c gmain -> 95"
        , "#   -w output is NOT sorted. A TID is not a PID except for the leader."
        , "#   ls /proc/PID/task ; cat /proc/PID/task/TID/comm"
        , ""
        , "pgrep -F file      # PIDs from a file, as one more AND criterion"
        , "pgrep -L -F file   # ...and fail unless the file is locked"
        , "#   gone -> exit 1, silent.  not a number -> 'pidfile not valid', exit 1."
        , "#   A RECYCLED pid is undetectable: always add -x myapp as well."
        ]
