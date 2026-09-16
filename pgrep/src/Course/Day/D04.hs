module Course.Day.D04 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 4
        , dayTitle = "Who and whose"
        , daySubtitle = "Every column of the process table is a criterion in its own right."
        , dayMinutes = 35
        , dayLevel = "essential"
        , dayManRef = "OPTIONS (-u, -U, -G, -P, -g, -s, -t, -p)"
        , dayTags = ["euid", "ppid", "session"]
        , dayGoals =
            [ "choose between " <> c "-u" <> " and " <> c "-U" <> " knowing what a setuid program does to the answer"
            , "select a process by its place in the tree rather than by its name"
            , "write a useful pgrep query that contains no pattern at all"
            ]
        , dayDiagram = Just d4diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("pgrep -P $$", "Everything your current shell forked directly.")
            , ("pgrep -t pts/3 -a", "Everything running on one terminal — the other window.")
            , ("pgrep -g 0", "Processes in pgrep's own process group; " <> c "-s 0" <> " does the same for the session.")
            ]
        , dayOpts =
            [ ("-u, --euid", "Match on the effective user — the authority the process is acting with.")
            , ("-U, --uid", "Match on the real user — who started it.")
            , ("-G, --group", "Match on the real group. Name or number.")
            , ("-P, --parent", "Match processes whose parent is one of these PIDs.")
            , ("-g, --pgroup", "Match on process group. " <> c "0" <> " means pgrep's own.")
            , ("-s, --session", "Match on session ID. " <> c "0" <> " means pgrep's own.")
            , ("-t, --terminal", "Match on controlling terminal, named without " <> c "/dev/" <> ".")
            , ("-p, --pid", "Match only these PIDs — a filter, not a lookup. Undocumented.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Run " <> c "pgrep -u $USER -c ." <> " and " <> c "pgrep -u root -c ." <> ". Two numbers, no pattern, and together they are most of your machine."
            , "Run " <> c "sleep 300 &" <> " then " <> c "pgrep -P $$ -a" <> ". Your shell's children, with nothing said about their names."
            , "Open a second terminal, run " <> c "tty" <> " in it, and from the first one run " <> c "pgrep -t <that> -a" <> ". You are now reading another window's process list."
            , "Find a setuid process on your machine: " <> c "pgrep -u root -a" <> " then check " <> c "grep ^Uid /proc/PID/status" <> " on a few. A line whose first two numbers differ is the interesting case."
            , "Break it: " <> c "pgrep -u nosuchuser bash" <> ". This is exit " <> c "2" <> ", not " <> c "1" <> " — an unknown user is your mistake, not an empty result."
            , "Compare " <> c "pgrep -s 0 -a" <> " with " <> c "pgrep -g 0 -a" <> " from the same prompt and account for the difference in size."
            , "Use " <> c "-p" <> " as a filter: take the PIDs from a previous query and re-ask a narrower question about just those, e.g. " <> c "pgrep -p 1,832 -l systemd" <> "."
            , "Add one pattern-free recipe to your file — something like \"everything I am running on this terminal\" — and note why the absence of a pattern is the point."
            ]
        , dayQuiz =
            [
                ( "A monitoring check uses " <> c "pgrep -U root -x fusermount3" <> " and never fires, but " <> c "pgrep -u root -x fusermount3" <> " finds the process every time. Which is correct?"
                , do
                    p_ $ do
                        "Both are correct answers to different questions. "
                        c "fusermount3"
                        " is setuid root: it was "
                        i_ "started"
                        " by an ordinary user and runs "
                        i_ "with"
                        " root's authority. Its "
                        c "/proc/PID/status"
                        " says "
                        c "Uid: 1000 0 0 0"
                        " — real 1000, effective 0."
                    p_ $ do
                        opt "-U"
                        " asks who started it, "
                        opt "-u"
                        " asks what it can do. For a security question — \"what is running as root on this box\" — you want "
                        opt "-u"
                        ", because effective privilege is the thing that can hurt you. For an accounting question — \"what is this user running\" — you want "
                        opt "-U"
                        ". The mnemonic that sticks is that the lowercase, easier-to-type one is the one you want more often."
                )
            ,
                ( "You add " <> c "-g 0" <> " to a query to restrict it to \"this shell's process group\", and it returns almost nothing — not even the other jobs you started. Why?"
                , do
                    p_ $ do
                        "Because "
                        c "0"
                        " means pgrep's "
                        i_ "own"
                        " process group, and in an interactive shell with job control each pipeline gets a process group of its own. pgrep's group contains the command substitution it is running inside and very little else."
                    p_ $ do
                        c "-s 0"
                        " is nearly always what people mean: the session is the whole terminal, shared by every job you have started from that prompt. Process groups are the unit job control signals; sessions are the unit a terminal owns."
                )
            ,
                ( "Why is " <> c "pgrep -P $$" <> " more reliable than " <> c "pgrep -f 'the command I just launched'" <> " for finding a child you started?"
                , do
                    p_ $ do
                        "Because the parent relationship is a fact the kernel maintains, and the command line is a string that other processes are free to contain. "
                        c "-P $$"
                        " cannot match your editor, cannot match the "
                        c "grep"
                        " in someone's pipeline, and cannot match the shell doing the asking."
                    p_ $ do
                        "It has one real limitation: a process that daemonises is reparented to "
                        c "init"
                        " and drops out of the result immediately. For those, the PID you were given by "
                        c "$!"
                        " — or a pidfile, which is Day 6 — is the honest answer."
                )
            ,
                ( "What does " <> c "pgrep -p 1234,5678" <> " do that " <> c "kill -0 1234" <> " does not?"
                , do
                    p_ $ do
                        opt "-p"
                        " is a "
                        i_ "filter"
                        ", not a lookup. On its own it simply confirms which of those PIDs exist, but its purpose is to compose: "
                        c "pgrep -p 1234,5678 -u root -f worker"
                        " asks whether "
                        i_ "those specific processes"
                        " are also root-owned workers, and answers about each one."
                    p_ $ do
                        "It is the way to re-ask a narrower question about a set of PIDs you already have, without a loop. It is also entirely absent from "
                        c "pgrep(1)"
                        " — "
                        c "--help"
                        " is the only documentation."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d4diagram :: Diagram
d4diagram =
    ( diagram
        "A running process was started by a real user, acts with the authority of an effective \
        \user, belongs to a real group, was forked by a parent process, is a member of a \
        \process group which belongs to a session, and that session is attached to a \
        \controlling terminal."
        body'
    )
        { dgCaption = do
            "Seven facts the kernel maintains about every process, and pgrep has a flag for each: "
            c "-U"
            " and "
            c "-u"
            " for the two users, "
            c "-G"
            " for the group, "
            c "-P"
            " for the parent, "
            c "-g"
            ", "
            c "-s"
            " and "
            c "-t"
            " for the chain along the bottom. None of them can be faked by a process's command \
            \line, which is what makes them worth reaching for before the pattern. The amber box \
            \is the one that surprises people: it is usually equal to the real user, and the \
            \cases where it is not are exactly the cases you were worried about."
        , dgRankdir = "LR"
        , dgRanksep = "0.6"
        }
  where
    body' =
        T.unlines
            [ "  proc [label=\"a running process\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  ruid [label=\"its real user\"];"
            , "  euid [label=\"its effective user\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  rgid [label=\"its real group\"];"
            , "  ppid [label=\"its parent process\"];"
            , "  pgid [label=\"its process group\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  sess [label=\"its session\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  tty  [label=\"a controlling terminal\", fillcolor=\"#f4efe6\"];"
            , ""
            , "  proc -> ruid [label=\"  was started by\"];"
            , "  proc -> euid [label=\"  acts as\"];"
            , "  proc -> rgid [label=\"  belongs to\"];"
            , "  proc -> ppid [label=\"  was forked by\"];"
            , "  proc -> pgid [label=\"  is a member of\"];"
            , "  pgid -> sess [label=\"  belongs to\"];"
            , "  sess -> tty  [label=\"  is attached to\"];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "The pattern was never the important part" $ do
        p_ [class_ "lede"] $ do
            "Everything so far has been about matching a string. But a name is the weakest fact \
            \about a process — it is shared with every other user of the same interpreter, \
            \truncated at fifteen characters, and trivially coincidental. The kernel maintains \
            \seven other facts that are none of those things, and pgrep has a flag for each."
        p_ $ do
            "These are ordinary criteria, so Day 1's rules still apply: they AND with each other \
            \and with the pattern, and each one takes a comma list that ORs. What is new is that \
            \they are enough on their own. "
            c "pgrep -P $$"
            " has no pattern and is a perfectly good question."
        fig

    block "Two users, and only one of them can hurt you" $ do
        p_ $ do
            "Every process carries both a "
            b_ "real"
            " user — who started it — and an "
            b_ "effective"
            " user — whose authority it currently acts with. Normally they are the same number \
            \and the distinction is invisible. A setuid program is where they come apart, and \
            \there is usually one running on your machine right now:"
        sh
            [ "$ pgrep -a -x fusermount3"
            , "6008 fusermount3 -o rw,nosuid,nodev,fsname=portal,auto_unmount,subtype=portal -- ..."
            , "$ grep ^Uid: /proc/6008/status"
            , "Uid:\t1000\t0\t0\t0"
            ]
        p_ $ do
            "Real uid 1000, effective uid 0. An unprivileged user started it; it is running as \
            \root. The two flags disagree exactly as they should:"
        sh
            [ "$ pgrep -u root -x fusermount3     # -u: effective"
            , "6008"
            , "$ pgrep -U root -x fusermount3     # -U: real"
            , "$ echo $?"
            , "1"
            , "$ pgrep -U jhrcek -x fusermount3"
            , "6008"
            ]
        why $ p_ $ do
            "The lowercase, easier-to-type "
            opt "-u"
            " is the effective one, and that is deliberate: the question people ask most often is \
            \\"what is running with root's powers\", not \"what did root launch\". If you are \
            \auditing, "
            opt "-u"
            " is the flag. If you are billing, "
            opt "-U"
            " is. "
            opt "-G"
            " matches the "
            i_ "real"
            " group only — there is no effective-group counterpart, which is an asymmetry with no \
            \good explanation beyond nobody having needed it."
        note $ p_ $ do
            "All three accept names or numbers interchangeably: "
            c "-u root"
            " and "
            c "-u 0"
            " are the same query. A name that does not resolve is exit "
            c "2"
            " with "
            c "invalid user name"
            " — pgrep treats it as a typo in your command, not as an empty result, which is the \
            \right call and occasionally surprising in a script."

    block "Position in the tree" $ do
        p_ $ do
            "The remaining four locate a process by where it sits rather than by what it is. They \
            \are the ones that make pgrep usable for jobs whose names you cannot predict."
        defs
            [
                ( opt "-P" <> " — parent"
                , do
                    "Direct children only, not descendants. "
                    c "pgrep -P $$"
                    " is everything your shell forked and has not reaped."
                )
            ,
                ( opt "-g" <> " — process group"
                , do
                    "The unit job control signals: one pipeline, one group. "
                    c "0"
                    " is translated to pgrep's own group, which under command substitution is \
                    \smaller than you expect."
                )
            ,
                ( opt "-s" <> " — session"
                , do
                    "The unit a terminal owns; every job started from one prompt shares it. "
                    c "0"
                    " means pgrep's own session, and this is usually the one you wanted when you \
                    \typed "
                    c "-g 0"
                    "."
                )
            ,
                ( opt "-t" <> " — controlling terminal"
                , do
                    "Named without the "
                    c "/dev/"
                    " prefix: "
                    c "-t pts/3"
                    ", not "
                    c "-t /dev/pts/3"
                    ". Processes with no terminal — every daemon — match nothing here."
                )
            ]
        p_ "From one shell on pts/0, the four answers nest:"
        sh
            [ "$ pgrep -t pts/0 -l     # the whole terminal"
            , "264115 bash"
            , "264312 .claude-unwrapp"
            , "$ pgrep -s 264115 -l    # the session, same thing here"
            , "264115 bash"
            , "264312 .claude-unwrapp"
            , "$ pgrep -g 264312 -l    # one process group inside it"
            , "264312 .claude-unwrapp"
            , "$ pgrep -P 264115 -l    # just the shell's direct children"
            , "264312 .claude-unwrapp"
            ]
        gotcha $ p_ $ do
            c "-P"
            " loses anything that daemonises. A process that forks and lets its parent exit is \
            \reparented to "
            c "init"
            ", so it stops being your child the moment it succeeds in starting properly. If you \
            \need to track something across that transition, you need the PID it told you about \
            \— a pidfile, which is tomorrow's second half."

    block "The pattern-free query" $ do
        p_ $ do
            "Once the criteria stand alone, whole classes of question become one-liners that no \
            \amount of "
            c "ps | grep"
            " would have got you:"
        cfg
            [ "pgrep -u root -c .          # how many processes have root's authority"
            , "pgrep -P $$ -a              # what did this shell start"
            , "pgrep -t pts/3 -a           # what is running in that other window"
            , "pgrep -s 0 -a               # everything in my terminal session"
            , "pgrep -G docker -a          # everything a group can reach"
            ]
        p_ $ do
            "The odd one out is "
            opt "-p"
            ", which takes PIDs directly. It is not a lookup — you already know the PIDs — it is \
            \a "
            b_ "filter"
            ", and its value is that it composes with everything else:"
        sh
            [ "$ pgrep -p 1,832 -l systemd"
            , "1 systemd"
            , "832 systemd-journal"
            ]
        p_ $ do
            "That asks \"of these two PIDs, which are named something with systemd in it\". \
            \Without "
            opt "-p"
            " you would write a loop. Like "
            opt "-Q"
            " yesterday, it exists in "
            c "--help"
            " and nowhere in the manual page."

    block "Today's habit" $ do
        p_ $ do
            "Before you type a pattern, ask whether a criterion would be sharper. \"The thing I \
            \started\" is "
            c "-P $$"
            ". \"The thing in that window\" is "
            c "-t"
            ". \"The thing running as root\" is "
            c "-u"
            ". Patterns are for when you genuinely do not know where the process came from."
        p_ $ do
            "Tomorrow the criteria stop being facts about identity and start being facts about \
            \time and state — and "
            opt "-v"
            " arrives, which negates rather more than its one-line description admits."
        cfg
            [ "# Day 4: what has root's authority right now - effective uid, not real."
            , "pgrep -u root -a"
            , ""
            , "# Day 4: what did this shell start, whatever it happens to be called."
            , "pgrep -P $$ -a"
            ]

cheat :: Html ()
cheat = do
    cfg
        [ "pgrep -u USER   # EFFECTIVE uid - what it can do   <- the security question"
        , "pgrep -U USER   # REAL uid      - who started it   <- the accounting question"
        , "pgrep -G GROUP  # real group (there is no effective-group flag)"
        , "pgrep -P PPID   # direct children only; daemons reparent away to init"
        , "pgrep -g PGID   # process group; 0 = pgrep's own"
        , "pgrep -s SID    # session;       0 = pgrep's own   <- usually what you meant"
        , "pgrep -t pts/3  # controlling terminal, WITHOUT /dev/"
        , "pgrep -p 1,832  # filter an existing list of PIDs; composes with the rest"
        , "#"
        , "# All take name-or-number and comma lists. All AND together."
        , "# An unknown user name is exit 2, not an empty result."
        ]
