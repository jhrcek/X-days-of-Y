module Course.Day.D09 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 9
        , dayTitle = "Scripts and sharp edges"
        , daySubtitle = "The race you cannot win, and when to put pgrep down."
        , dayMinutes = 35
        , dayLevel = "advanced"
        , dayManRef = "BUGS, NOTES, EXIT STATUS, SEE ALSO"
        , dayTags = ["races", "scripting", "alternatives"]
        , dayGoals =
            [ "name the window between a pgrep and the kill that follows it, and close it where you can"
            , "write a pgrep into a script without an unset variable selecting the whole machine"
            , "recognise the four situations where the right answer is a different tool"
            ]
        , dayDiagram = Just d9diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("systemctl kill --signal=HUP unit", "Signal a unit's whole cgroup. No pattern, no race, no PID.")
            , ("killall -s 0 name", "PSmisc's tool: exact name matching by default, no regex unless you ask.")
            , ("pkill -A -f \"${PAT:?}\"", "The two guards that belong on every scripted pkill.")
            ]
        , dayOpts = []
        , dayConfig = []
        , dayDrills =
            [ "Read the whole of " <> c "man pgrep" <> " now. It will take four minutes and nothing in it will be new, which is the point of having done the other eight days."
            , "Find the empty-pattern hazard in your own shell: " <> c "unset NOPE; pgrep -c \"$NOPE\"" <> " against " <> c "pgrep -c ." <> ". They are the same number."
            , "Fix it: " <> c "pgrep -c \"${NOPE:?pattern is empty}\"" <> ". Read the error. Put that colon-question-mark into every scripted pattern you own."
            , "Check your own " <> c "/proc" <> ": " <> c "grep ' /proc ' /proc/mounts" <> ". If you see " <> c "subset=pid" <> ", " <> c "-O" <> " has been lying to you."
            , "Compare the two families: " <> c "pgrep -c sle" <> " and " <> c "killall -s 0 sle" <> ". One matches a substring, the other demands the whole name."
            , "Take the most dangerous pkill in your own scripts and add " <> c "-A" <> ", " <> c "-x" <> " or " <> c "-u \"$USER\"" <> " to it — whichever actually narrows it — then run it as a pgrep to confirm the set is unchanged."
            , "Replace one pgrep-based service check with " <> c "systemctl is-active" <> " and notice how much of your script disappears."
            , "Read back your " <> c "~/pgrep-recipes.sh" <> " from the top. Delete anything you can no longer defend; that is the exercise."
            ]
        , dayQuiz =
            [
                ( "A script does " <> c "pids=$(pgrep -f worker); sleep 2; kill $pids" <> ". Under what circumstances does it kill the wrong process, and does dropping the " <> c "sleep" <> " fix it?"
                , do
                    p_ $ do
                        "If a worker exits during those two seconds and the kernel hands its PID to something else, the "
                        c "kill"
                        " lands on an innocent process. Dropping the "
                        c "sleep"
                        " shortens the window but does not close it: there is always some interval between pgrep reading "
                        c "/proc"
                        " and the signal being delivered, and nothing in the PID makes the second operation refer to the same process as the first."
                    p_ $ do
                        "In practice PID reuse is slow — this machine's "
                        c "/proc/sys/kernel/pid_max"
                        " is 4194304, so the counter takes a long time to wrap — but plenty of systems still run with 32768, and a busy container churns through that in minutes."
                    p_ $ do
                        "The genuine fixes are to stop using PIDs as the handle: "
                        c "pkill"
                        " does the match and the signal in one pass, and "
                        c "systemctl kill"
                        " signals a cgroup, which is a set that cannot be reused out from under you."
                )
            ,
                ( "Why is " <> c "pkill -f \"$PATTERN\"" <> " one of the more dangerous lines you can put in a shell script?"
                , do
                    p_ $ do
                        "Because if "
                        c "PATTERN"
                        " is unset or empty, pgrep and pkill accept the empty pattern without comment and it matches "
                        i_ "everything"
                        ". On a machine with 613 processes, "
                        c "pgrep -c \"$NOPE\""
                        " returns 613. The pkill equivalent terminates every process you own."
                    p_ $ do
                        "Two characters prevent it: "
                        c "pkill -f \"${PATTERN:?}\""
                        " makes the shell abort with an error if the variable is unset or empty. "
                        c "set -u"
                        " alone is not enough, because it does not object to a variable that is set to the empty string."
                )
            ,
                ( "Your monitoring script has used " <> c "pgrep -O 300 -f batchjob" <> " to find stuck jobs for a year. You harden the machine by mounting " <> c "/proc" <> " with " <> c "subset=pid" <> ". What happens to the script?"
                , do
                    p_ $ do
                        "It stops finding anything, and does not say so. "
                        c "pgrep(1)"
                        "'s NOTES are explicit: \""
                        opt "-O"
                        " will silently fail if /proc is mounted with the subset=pid option\". Start time comes from "
                        c "/proc/PID/stat"
                        ", which that mount option hides, so every process looks ageless."
                    p_ $ do
                        "The symptom is a monitor that has gone permanently quiet, which is indistinguishable from a healthy system and is the worst failure mode a check can have. "
                        c "grep ' /proc ' /proc/mounts"
                        " is the thing to look at, and it is worth looking at before you trust "
                        opt "-O"
                        " on a machine you did not configure."
                )
            ,
                ( "You need to restart a service. Give two reasons to reach for " <> c "systemctl" <> " rather than " <> c "pkill" <> "."
                , do
                    p_ $ do
                        "First, systemd knows the set exactly. A unit's cgroup contains every process the service started, including the ones that renamed themselves, daemonised, or are called "
                        c "python3"
                        " like forty other things. "
                        c "systemctl kill"
                        " signals that set with no pattern to get wrong and no race to lose."
                    p_ $ do
                        "Second, it knows what to do next. pkill terminates a process; systemd terminates it, respects "
                        c "Restart="
                        ", waits for "
                        c "TimeoutStopSec"
                        ", escalates to "
                        c "SIGKILL"
                        " on its own schedule, and records the result. pkill against a supervised service is a fight with the supervisor, and the supervisor wins."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d9diagram :: Diagram
d9diagram =
    ( diagram
        "A pgrep run happened at the moment it read /proc, which yielded a process ID that \
        \identified the process that matched. A later kill is aimed at that same process ID, \
        \but by the moment the signal is sent the ID identifies whatever holds it now, which \
        \is usually, but need not be, the process that matched."
        body'
    )
        { dgCaption = do
            "The PID is a "
            b_ "name that outlives what it named"
            ". Between the two moments nothing guarantees the dashed aspect holds, and no amount \
            \of care in writing the query affects that — the race is in the handoff, not in the \
            \match. This is why "
            c "pkill"
            " exists at all, and why signalling a cgroup with "
            c "systemctl kill"
            " is better still: a cgroup is a set the kernel maintains, and it cannot be \
            \reassigned between your reading it and your acting on it."
        , dgRankdir = "TB"
        , dgRanksep = "0.5"
        }
  where
    body' =
        T.unlines
            [ "  run    [label=\"a pgrep run\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  scan   [label=\"the moment it\\nread /proc\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  pid    [label=\"a process ID\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  match  [label=\"the process\\nthat matched\"];"
            , "  klr    [label=\"a later kill\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  now    [label=\"the moment the\\nsignal is sent\"];"
            , "  holder [label=\"whatever holds\\nthat PID now\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  run   -> scan   [label=\"  happened at\"];"
            , "  scan  -> pid    [label=\"  yielded\"];"
            , "  pid   -> match  [label=\"  identified, then\"];"
            , "  klr   -> now    [label=\"  happens at\"];"
            , "  klr   -> pid    [label=\"  is aimed at\"];"
            , "  pid   -> holder [label=\"  identifies, now\"];"
            , "  match -> holder [label=\"  is usually, but need not be  \", style=dashed, constraint=false];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "A PID is a name that outlives what it named" $ do
        p_ [class_ "lede"] $ do
            "Everything in this course produces PIDs, and a PID is only meaningful at the instant \
            \it was read. The moment pgrep finishes scanning "
            c "/proc"
            " its answer starts going stale, and the classic three-line script is a race with a \
            \window you chose the size of:"
        cfg
            [ "pids=$(pgrep -f worker)   # true at this instant"
            , "sleep 2                   # ...and for however long you leave it"
            , "kill $pids                # aimed at numbers, not at processes"
            ]
        p_ $ do
            "If a worker exits during the gap and the kernel reissues its PID, the "
            c "kill"
            " hits a stranger. Removing the "
            c "sleep"
            " narrows the window; nothing removes it, because two separate syscall sequences \
            \cannot be made atomic from a shell."
        why $ p_ $ do
            "This is precisely why pkill is a separate binary rather than a shell function. It \
            \does the "
            c "/proc"
            " walk and the "
            c "kill(2)"
            " in one pass, with no shell in between and no opportunity for a PID to change \
            \meaning. Given a choice between "
            c "kill $(pgrep X)"
            " and "
            c "pkill X"
            ", the second is not merely shorter — it is the one that is correct."
        fig
        note $ p_ $ do
            "How urgent this is depends on your machine. "
            c "/proc/sys/kernel/pid_max"
            " is 4194304 here, so the counter takes a very long time to wrap and reuse is \
            \effectively theoretical. A box still running the old 32768 default, or a busy \
            \container, recycles PIDs in minutes."

    block "Two characters that stop a script destroying a session" $ do
        p_ $ do
            "The empty pattern matches every process. pgrep accepts it silently — Day 2 mentioned \
            \this, and here is the consequence in a script:"
        sh
            [ "$ unset NOPE"
            , "$ pgrep -c \"$NOPE\""
            , "613"
            , "$ pgrep -c ."
            , "613"
            ]
        p_ $ do
            "Change the verb and that is every process you own, terminated, because a variable was \
            \misspelled or a config file was missing a line. "
            c "set -u"
            " does not save you: it objects to an "
            i_ "unset"
            " variable, not to one set to the empty string, and half the ways this happens produce \
            \the latter."
        gotcha $ do
            p_ "The guard is a shell parameter expansion, and it belongs on every scripted pattern:"
            cfg
                [ "pkill -f \"${PATTERN:?pattern is empty}\""
                ]
            p_ $ do
                c ":?"
                " aborts with that message if the variable is unset "
                i_ "or"
                " empty. It costs nothing and it is the difference between a failed script and a \
                \logged-out session."
        p_ "Three more rules for a scripted pgrep, all of them from earlier days:"
        steps
            [ do
                b_ "Every -f gets an -A."
                " Day 2: without it the script matches itself, and with "
                c "sudo"
                " in the ancestry it matches that too."
            , do
                b_ "Branch on the status, not on the output."
                " Day 3: "
                c "if pids=$(pgrep …); then"
                " rather than an unguarded "
                c "$(…)"
                " that collapses to nothing and makes the next command complain about its own \
                \syntax."
            , do
                b_ "Narrow with a criterion, not with a longer pattern."
                " Day 4: "
                c "-u \"$USER\""
                " or "
                c "-x"
                " restricts the blast radius in a way that another few characters of regex does \
                \not."
            ]

    block "Three things that are true and will still surprise you" $ do
        defs
            [
                ( "Zombies count"
                , do
                    "BUGS: \"Defunct processes are reported.\" A "
                    c "pkill"
                    " that reports success may have signalled something that exited hours ago. If \
                    \a supposedly-killed process will not go away, check "
                    c "pgrep -r Z -a"
                    " and signal its parent instead."
                )
            ,
                ( c "-O" <> " can fail silently"
                , do
                    "NOTES: it \"will silently fail if /proc is mounted with the subset=pid \
                    \option\". Start times come from "
                    c "/proc/PID/stat"
                    ", which that hardening option hides. A monitor built on "
                    opt "-O"
                    " simply goes quiet, and quiet looks exactly like healthy. Check with "
                    c "grep ' /proc ' /proc/mounts"
                    "."
                )
            ,
                ( "The flag conflicts are unexplained"
                , do
                    "Combining "
                    opt "-n"
                    ", "
                    opt "-o"
                    " and "
                    opt "-v"
                    " prints the usage message with no error line at all. If a pgrep suddenly \
                    \returns exit "
                    c "2"
                    " and a wall of text after an innocuous edit, that pair is the first thing to \
                    \look for."
                )
            ]

    block "When the answer is a different tool" $ do
        p_ $ do
            "pgrep's reach ends where the process table does. Four situations where reaching for \
            \it is the mistake:"
        defs
            [
                ( "It is a systemd unit"
                , do
                    "Use "
                    c "systemctl"
                    ". "
                    c "systemctl is-active"
                    " replaces a health check, and "
                    c "systemctl kill --signal=HUP unit"
                    " signals the unit's entire cgroup — every process it started, whatever they \
                    \renamed themselves to, with no pattern to get wrong and no race. Fighting a \
                    \supervisor with pkill is a fight the supervisor wins."
                )
            ,
                ( "You started it yourself"
                , do
                    "Use "
                    c "$!"
                    " and the shell's "
                    c "wait"
                    ". The PID you were handed at fork time has no ambiguity in it at all, and \
                    \no pattern can be as precise. Reserve pgrep for processes you did not start."
                )
            ,
                ( "You need a column pgrep does not have"
                , do
                    "Use "
                    c "ps"
                    ". Memory, CPU time, start time as a date, the full "
                    c "STAT"
                    " field, scheduling class — none are selectable or printable here. The \
                    \idiomatic pairing is still "
                    c "ps -fp $(pgrep -d, …)"
                    ": pgrep selects, ps displays."
                )
            ,
                ( "You want exact names and nothing clever"
                , do
                    c "killall"
                    " from PSmisc matches the whole name by default and needs "
                    c "-r"
                    " before it will consider a regex — the opposite default from pkill, and safer \
                    \for interactive use. "
                    c "killall sle"
                    " says "
                    c "sle: no process found"
                    " where "
                    c "pkill sle"
                    " would have killed every sleep on the machine. "
                    c "pkill -x"
                    " gets you the same behaviour if you prefer one family of tools."
                )
            ]

    block "What to read next" $ do
        p_ $ do
            "Read "
            c "man pgrep"
            " now, properly, end to end. It is 227 lines and none of it will be new — which is \
            \what nine days were for. You will also notice how much of what you know is not in \
            \there: "
            opt "-p"
            ", "
            opt "--quiet"
            ", "
            opt "-Q"
            ", "
            opt "--env"
            " and "
            c "pkill -m"
            " appear only in "
            c "--help"
            ", and the "
            opt "--nslist"
            " behaviour appears nowhere."
        p_ "Then the four pages the SEE ALSO section actually earns:"
        defs
            [ (c "regex(7)", "The pattern language, properly. Every anchoring and alternation question you will have.")
            , (c "signal(7)", "What each signal's default action is, which decides whether " <> c "pkill -USR1" <> " is a message or an execution.")
            , (c "ps(1)", "Everything pgrep cannot print, and the " <> c "PROCESS STATE CODES" <> " table that " <> opt "-r" <> " needs.")
            , (c "cgroups(8)", "Where " <> opt "--cgroup" <> " paths come from, and why they are stable when names are not.")
            ]

    block "Today's habit" $ do
        p_ $ do
            "Open "
            c "~/pgrep-recipes.sh"
            " and read it from the top. Nine days ago the first line was a health check you had \
            \no reason to trust; by now every line should have a comment saying why it is written \
            \the way it is. Delete the ones you can no longer defend — that is not a loss, it is \
            \the whole exercise."
        p_ $ do
            "The habit worth keeping is the smallest one in the course, and it is from Day 7: "
            b_ "write the pgrep, read the output, then change the word"
            ". Everything else here is elaboration on knowing what you have selected before you \
            \do something to it."

cheat :: Html ()
cheat = do
    cfg
        [ "# The scripted-pgrep checklist"
        , "pkill -A -f \"${PAT:?pattern is empty}\"   # :? guards the empty-pattern disaster"
        , "                                        # -A stops the script matching itself"
        , "if pids=$(pgrep -f \"$PAT\"); then ...    # branch on status, not on output"
        , "pkill -x -u \"$USER\" NAME                 # narrow with a criterion, not more regex"
        , "#"
        , "# Prefer the one-pass tool: pkill X  beats  kill $(pgrep X)  - no race."
        , "#"
        , "# Reach elsewhere when:"
        , "#   it is a unit         -> systemctl is-active / systemctl kill --signal=HUP"
        , "#   you started it       -> $! and wait"
        , "#   you need a column    -> ps -fp $(pgrep -d, ...)"
        , "#   you want exact names -> killall (exact by default; -r for regex)"
        , "#"
        , "# grep ' /proc ' /proc/mounts   <- subset=pid makes -O silently fail"
        ]
