module Course.Day.D07 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 7
        , dayTitle = "Signal and wait"
        , daySubtitle = "One query, three verbs — and only one of them is reversible."
        , dayMinutes = 40
        , dayLevel = "intermediate"
        , dayManRef = "DESCRIPTION, OPTIONS (-signal, -e, -q, -H, -m), EXIT STATUS"
        , dayTags = ["pkill", "pidwait", "signals"]
        , dayGoals =
            [ "convert any pgrep query into a pkill without changing what it selects"
            , "read pkill's exit status correctly when some targets could not be signalled"
            , "wait for a process that is not your child, and know why " <> c "wait" <> " cannot"
            ]
        , dayDiagram = Just d7diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("pkill -e -f 'python3 worker'", "Signal every match and say which ones. SIGTERM by default.")
            , ("pkill -HUP syslogd", "The man page's own example: make a daemon reread its configuration.")
            , ("pkill --signal 0 -e -x myapp", "Send nothing. A pure permission probe — but " <> c "-e" <> " still says \"killed\".")
            , ("pidwait -e -x myapp", "Block until every match has exited, including processes you did not start.")
            ]
        , dayOpts =
            [ ("--signal SIG, -SIG", "Which signal to send. Name or number. Default " <> c "SIGTERM" <> ".")
            , ("-e, --echo", "Print a line per process signalled. Says \"killed\" whatever the signal was.")
            , ("-q, --queue N", "Use " <> c "sigqueue(3)" <> " and attach this integer to the signal.")
            , ("-H, --require-handler", "Only signal processes that have a userspace handler for that signal.")
            , ("-m, --mrelease", "Release the target's memory immediately after signalling. Undocumented.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Start three throwaway processes: " <> c "for i in 1 2 3; do sleep 500 & done" <> ". Everything below targets those and nothing else."
            , "Run your query as pgrep first: " <> c "pgrep -a -P $$ -x sleep" <> ". Read the list. Only then change the word to " <> c "pkill" <> " and add " <> c "-e" <> "."
            , "Probe without signalling: " <> c "pkill --signal 0 -e -x sleep" <> " on something you do not own, such as " <> c "-x systemd-journal" <> ". Read the permission error and the exit status."
            , "Prove " <> c "-e" <> " lies: " <> c "pkill --signal 0 -e -x sleep" <> " on your own sleeps, then " <> c "pgrep -x sleep" <> ". It said \"killed\" and they are all still there."
            , "Check the exclusions: try " <> c "pkill -v sleep" <> ", " <> c "pkill -w sleep" <> " and " <> c "pgrep -e sleep" <> ". Three refusals, all deliberate."
            , "Time a wait: " <> c "sleep 10 & pidwait -e -x sleep" <> ". Then do it again with " <> c "setsid sleep 10" <> ", which is not your child — " <> c "wait" <> " cannot do the second one."
            , "Count without killing: " <> c "pkill -c --signal 0 -x sleep" <> ". The count is of matches, not of successful signals — the distinction matters the moment permissions do."
            , "Write the one pkill you actually need for your own work into your recipes file, with the pgrep it was derived from on the line above it as a comment."
            ]
        , dayQuiz =
            [
                ( "A cleanup script runs " <> c "pkill -f worker" <> " and reports success, but half the workers are still running afterwards. The log shows exit status 0. Is that a bug in pkill?"
                , do
                    p_ $ do
                        "No. Exit "
                        c "0"
                        " from pkill means \"at least one process was successfully signalled\", not \"all of them were\". A run in which one worker was yours and the rest belonged to another user gives you "
                        c "Operation not permitted"
                        " on stderr for each failure and exit "
                        c "0"
                        " overall, because one of them worked."
                    p_ $ do
                        "Exit "
                        c "1"
                        " arrives only when "
                        i_ "nothing"
                        " was signalled — either nothing matched, or everything that matched was forbidden. The two cases are indistinguishable from the status alone, which is why "
                        opt "-e"
                        " and a look at stderr belong in any script that cares."
                )
            ,
                ( "You run " <> c "pkill --signal 0 -e -x myapp" <> " to check permissions. It prints " <> c "myapp killed (pid 4417)" <> ". Did you just kill it?"
                , do
                    p_ $ do
                        "No. Signal "
                        c "0"
                        " is the null signal: the kernel performs every permission check and delivers nothing. The process is untouched — "
                        c "pgrep -x myapp"
                        " immediately afterwards still finds it."
                    p_ $ do
                        opt "-e"
                        " prints the word \"killed\" unconditionally, whatever signal was sent. It is describing the "
                        i_ "match"
                        ", not the outcome, and it does not consult the signal number at all. Read it as \"selected\" and the flag becomes useful again."
                )
            ,
                ( c "pkill -v nginx" <> " is refused as an invalid option, but " <> c "pkill --inverse nginx" <> " runs. What is being protected against, and what is not?"
                , do
                    p_ $ do
                        "A typo. "
                        c "pkill -v nginx"
                        " would signal everything that is "
                        i_ "not"
                        " nginx, which on a normal machine is every process you own — and "
                        c "-v"
                        " is one slip away from "
                        c "-x"
                        " or "
                        c "-u"
                        " on the keyboard. The manual page says the short option is disabled \"to avoid accidental usage\"."
                    p_ $ do
                        "What is not protected against is anyone who means it. The long form is accepted and works, on the theory that nine deliberate characters are not a slip. The same is true of "
                        c "--lightweight"
                        " and "
                        c "--delimiter"
                        ", whose short forms are refused too — and that pair is undocumented, since "
                        c "pgrep(1)"
                        " only mentions the "
                        c "-v"
                        " case."
                    p_ $ do
                        c "--lightweight"
                        " genuinely changes the target set rather than being accepted and ignored: on a process with seven threads, "
                        c "pkill --signal 0 -c -f udisksd"
                        " counts 3 where "
                        c "pkill --lightweight --signal 0 -c -f udisksd"
                        " counts 9. Signalling threads is a real operation and pkill will do it if you insist in full."
                )
            ,
                ( "What can " <> c "pidwait" <> " do that the shell's built-in " <> c "wait" <> " cannot, and what does it need from the kernel to do it?"
                , do
                    p_ $ do
                        c "wait"
                        " only works on your own children — it is a wrapper around "
                        c "waitpid(2)"
                        ", and the kernel will not report the exit of a process you did not fork. pidwait waits on "
                        i_ "anything"
                        ": a daemon started by systemd, another user's job, a process whose parent is "
                        c "init"
                        "."
                    p_ $ do
                        "It does that with "
                        c "pidfd_open(2)"
                        ", which turns a PID into a file descriptor that becomes readable when the process dies. That syscall arrived in Linux 5.3, so pidwait simply does not work on anything older — the manual page lists this under BUGS. It also closes the PID-reuse race, because the descriptor refers to that specific process and not to whatever later inherits the number."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d7diagram :: Diagram
d7diagram =
    ( diagram
        "A pgrep run, a pkill run and a pidwait run are all selection queries; the query \
        \determines the selection. pgrep prints the selection, pkill sends a signal which is \
        \delivered to a matched process that may have installed a handler, and pidwait blocks \
        \until the moment the process exits."
        body'
    )
        { dgCaption = do
            "Three binaries, one selection engine: everything from the last six days applies \
            \unchanged, and the only thing that differs is what happens to the set at the end. \
            \That is why the safe way to write a pkill is to "
            b_ "write it as a pgrep first"
            " and change one word. The amber box is the irreversible part, and the dashed aspect \
            \is the one flag that consults it before acting."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  grepr [label=\"a pgrep run\"];"
            , "  killr [label=\"a pkill run\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  waitr [label=\"a pidwait run\"];"
            , "  q     [label=\"a selection query\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  sel   [label=\"the selection\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  proc  [label=\"a matched process\"];"
            , "  sig   [label=\"a signal\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  hdlr  [label=\"a userspace handler\"];"
            , "  gone  [label=\"the moment it exits\"];"
            , ""
            , "  grepr -> q    [label=\"  is\"];"
            , "  killr -> q    [label=\"  is\"];"
            , "  waitr -> q    [label=\"  is\"];"
            , "  q     -> sel  [label=\"  determines\"];"
            , "  grepr -> sel  [label=\"  prints\", constraint=false];"
            , "  killr -> sig  [label=\"  sends\"];"
            , "  sig   -> proc [label=\"  is delivered to\"];"
            , "  proc  -> hdlr [label=\"  may install\"];"
            , "  proc  -> gone [label=\"  has as\"];"
            , "  waitr -> gone [label=\"  blocks until\"];"
            , "  sig   -> hdlr [label=\"  is checked against, under -H  \", style=dashed, constraint=false];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Three programs, one selection engine" $ do
        p_ [class_ "lede"] $ do
            "pgrep, pkill and pidwait are the same binary's worth of logic wearing three names. \
            \Every criterion from the last six days works identically in all three — the pattern, "
            opt "-f"
            ", "
            opt "-u"
            ", "
            opt "-P"
            ", "
            opt "-O"
            ", all of it. What changes is the verb applied to the resulting set: list it, signal \
            \it, or block until it is gone."
        p_ $ do
            "This is the most useful safety property the tools have, and it deserves to become a \
            \reflex: "
            b_ "write the pgrep, read the output, then change the word"
            ". The query is identical, so there is nothing left to get wrong."
        sh
            [ "$ pgrep -a -f 'python3 worker'   # look first"
            , "4417 python3 worker.py --shard 1"
            , "4418 python3 worker.py --shard 2"
            , "$ pkill -e -f 'python3 worker'   # then act"
            , "python3 killed (pid 4417)"
            , "python3 killed (pid 4418)"
            ]
        fig

    block "Which signal, and how to say so" $ do
        p_ $ do
            "The default is "
            c "SIGTERM"
            ", the polite one: a process can catch it, flush its buffers and exit. Any other \
            \signal is named either way round, which is why "
            c "pkill"
            "'s synopsis has that odd bare "
            c "-signal"
            " in it:"
        defs
            [ (c "pkill -HUP syslogd", "The short form. Anything the system knows as a signal name.")
            , (c "pkill -1 syslogd", "The same thing, numerically.")
            , (c "pkill --signal HUP syslogd", "The long form. The only one available in pgrep and pidwait.")
            ]
        p_ $ do
            "In pgrep and pidwait "
            opt "--signal"
            " does nothing at all on its own — there is no signal to send. It is accepted so \
            \that it can be combined with "
            opt "-H"
            ", below, which is the one place a listing tool cares which signal you had in mind."
        p_ $ do
            "The signal worth knowing beyond TERM and KILL is "
            c "0"
            ". It is the null signal: every permission check runs and nothing is delivered. That \
            \makes it a pure probe — \"could I signal this, if I wanted to?\""
        sh
            [ "$ pkill --signal 0 -x systemd-journal"
            , "pkill: killing pid 832 failed: Operation not permitted"
            , "$ echo $?"
            , "1"
            ]
        gotcha $ do
            p_ $ do
                opt "-e"
                " reports \"killed\" regardless of what was actually sent, including when nothing \
                \was sent at all:"
            sh
                [ "$ pkill --signal 0 -e -x lab7"
                , "lab7 killed (pid 274921)"
                , "lab7 killed (pid 274922)"
                , "$ pgrep -x lab7"
                , "274921"
                , "274922"
                ]
            p_ $ do
                "Both processes were reported killed and both are alive. "
                opt "-e"
                " is describing which processes were "
                i_ "selected"
                ", not what became of them. Read it that way and it is a good flag; read it \
                \literally and it will mislead you in exactly the situation — an incident, at \
                \speed — where you can least afford it."

    block "Reading the exit status when it half worked" $ do
        p_ $ do
            "pkill's statuses are pgrep's, with one word changed in the definition of success: "
            c "0"
            " requires that one or more processes were "
            i_ "successfully signalled"
            ", not merely matched. That word does real work."
        sh
            [ "$ pkill --signal 0 -e -p 832,274951   # 832 is root's, 274951 is mine"
            , "pkill: killing pid 832 failed: Operation not permitted"
            , " killed (pid 274951)"
            , "$ echo $?"
            , "0"
            ]
        p_ $ do
            "One failure, one success, exit "
            c "0"
            ". Had both been root's, the exit would have been "
            c "1"
            " — the same status you get when nothing matched at all. A script cannot tell \"no \
            \such process\" from \"not allowed\" without reading stderr."
        gotcha $ p_ $ do
            opt "-c"
            " does not help here, and is the trap it looks like. In pkill and pidwait the count \
            \is \"the number of matching processes, not the processes that were successfully \
            \signaled or waited for\" — the manual page is explicit. "
            c "pkill -c -f worker"
            " printing "
            c "8"
            " tells you eight matched, and nothing whatsoever about how many died."
        note $ p_ $ do
            "Zombies count as matches, so a "
            c "pkill"
            " that reports success may have signalled a process that exited hours ago. Day 5's "
            c "pgrep -r Z"
            " is how you notice; the fix is always to signal the parent."

    block "What pkill refuses to do" $ do
        p_ $ do
            "Three short options that pgrep accepts are rejected outright by pkill, and one that \
            \pkill accepts is rejected by pgrep:"
        cfg
            [ "pkill -v NAME   ->  pkill: invalid option -- 'v'"
            , "pkill -w NAME   ->  pkill: invalid option -- 'w'"
            , "pkill -d, NAME  ->  pkill: invalid option -- 'd'"
            , "pgrep -e NAME   ->  pgrep: invalid option -- 'e'"
            ]
        p_ $ do
            "The long forms are a different matter. "
            c "--inverse"
            ", "
            c "--lightweight"
            " and "
            c "--delimiter"
            " are all accepted by pkill and all take effect — only the one-letter spellings are \
            \blocked. The manual page mentions this for "
            opt "-v"
            " alone; the other two are undocumented in both directions."
        why $ p_ $ do
            "The asymmetry is a guard against typos rather than against the feature. A mistyped "
            opt "-v"
            " in pgrep costs you a long list; the same slip in pkill signals everything you own \
            \that is not the thing you named, which on a desktop is your session. Disabling the \
            \short form catches the accident while leaving the capability available to anyone who \
            \writes out "
            c "--inverse"
            " and has therefore thought about it."
        tip $ p_ $ do
            "Two more flags exist for cases you will meet rarely and be glad of. "
            opt "-q"
            " sends through "
            c "sigqueue(3)"
            " with an integer attached, which a handler installed with "
            c "SA_SIGINFO"
            " can read from "
            c "si_value"
            " — the way to pass a small number to a daemon that expects one. "
            opt "-m"
            " asks the kernel to release the target's memory immediately rather than waiting for \
            \it to wind down, which matters when you are killing something to reclaim RAM under \
            \pressure. Neither is in the manual page's option list."

    block "-H: only the processes that are listening" $ do
        p_ $ do
            "A process that has not installed a handler for a signal gets the default action, \
            \which for most signals is death. "
            opt "-H"
            " restricts the selection to processes that have a "
            b_ "userspace handler"
            " for the signal being sent — the ones that will do something deliberate with it \
            \rather than simply dying."
        sh
            [ "$ pkill -H --signal TERM -e -x lab7   # lab7 is /bin/sleep: no handler"
            , "$ echo $?"
            , "1"
            , "$ pgrep -x lab7"
            , "274964"
            ]
        p_ $ do
            "It works in pgrep too, and that is arguably its best use — combined with "
            opt "--signal"
            " it answers \"which of these would actually "
            i_ "do"
            " something with a HUP, rather than dying?\" before you send one:"
        sh
            [ "$ pgrep --signal HUP -H -u $(id -u) -l"
            , "4864 gnome-keyring-d"
            , "5120 gnome-session-i"
            , "5476 gvfsd-fuse"
            , "5490 wireplumber"
            , "5602 dconf-service"
            ]
        note $ p_ $ do
            "The underlying fact is "
            c "SigCgt"
            " in "
            c "/proc/PID/status"
            ", a bitmask of caught signals. "
            c "/bin/sleep"
            " has "
            c "SigCgt: 0000000000000000"
            " and catches nothing, which is why the run above selected none of them."

    block "pidwait: blocking on something you did not start" $ do
        p_ $ do
            "The shell's "
            c "wait"
            " only works on your own children, because "
            c "waitpid(2)"
            " will not report on a process you did not fork. pidwait has no such limit:"
        sh
            [ "$ setsid sleep 5 &            # reparented away; not our child"
            , "$ pidwait -e -x sleep"
            , "waiting for sleep (pid 274979)"
            , "$ echo $?                     # five seconds later"
            , "0"
            ]
        p_ $ do
            "It does this with "
            c "pidfd_open(2)"
            ", which converts a PID into a file descriptor that becomes readable when the process \
            \dies. Two consequences: it needs Linux 5.3 or newer, and it is immune to PID reuse, \
            \because the descriptor is bound to that process rather than to the number."
        gotcha $ p_ $ do
            c "pidwait -c"
            " does not print a count and return. It blocks until every match has exited and "
            i_ "then"
            " prints how many there were — the counting flag still waits. A "
            c "pidwait"
            " that matches nothing, on the other hand, returns immediately with exit "
            c "1"
            ", which makes \"wait for this if it is running\" a one-liner with no race in it."
        p_ $ do
            "The natural shape is a graceful shutdown that does not guess at a timeout:"
        cfg
            [ "pkill -TERM -f 'python3 worker'   # ask"
            , "pidwait -f 'python3 worker'       # wait, however long it takes"
            , "echo \"all workers stopped\""
            ]

    block "Today's habit" $ do
        p_ $ do
            "Never type "
            c "pkill"
            " first. Type "
            c "pgrep -a"
            ", look at what comes back, then press up-arrow and change five characters. It takes \
            \two seconds and it is the only defence against a pattern that was one character \
            \wider than you thought."
        p_ $ do
            "Tomorrow: the criteria that know about containers, which is how you tell two \
            \identical-looking processes apart when the name, the user and the command line are \
            \all the same."
        cfg
            [ "# Day 7: graceful stop. The pgrep on the first line is the safety check;"
            , "# the pkill below it is the same query with one word changed."
            , "#   pgrep -a -f 'python3 worker'"
            , "pkill -e -TERM -f 'python3 worker'"
            , "pidwait -f 'python3 worker'"
            ]

cheat :: Html ()
cheat = do
    cfg
        [ "pgrep -a QUERY    # look"
        , "pkill  -e QUERY   # then act - IDENTICAL query, SIGTERM by default"
        , "pidwait  QUERY    # or block until every match has exited"
        , "#"
        , "pkill -HUP x  /  pkill -1 x  /  pkill --signal HUP x    # all the same"
        , "pkill --signal 0 -x app   # probe permissions, deliver nothing"
        , "pkill -H --signal HUP x   # only processes with a real handler for it"
        , "#"
        , "# exit 0 = at least ONE was signalled. 1 = none were - which covers both"
        , "#          'nothing matched' and 'all forbidden'. Read stderr to tell them apart."
        , "# -e always says 'killed', even for signal 0. It means 'selected'."
        , "# -c counts MATCHES, not kills.  pgrep rejects -e."
        , "# pkill rejects SHORT -v -w -d, but --inverse/--lightweight/--delimiter all work."
        ]
