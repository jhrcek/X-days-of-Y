module Course.Day.D01 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 1
        , dayTitle = "The selection model"
        , daySubtitle = "Query the process table, and read the answer honestly."
        , dayMinutes = 30
        , dayLevel = "essential"
        , dayManRef = "DESCRIPTION, OPERANDS, EXIT STATUS"
        , dayTags = ["/proc", "criteria", "exit status"]
        , dayGoals =
            [ "explain why " <> c "pgrep sshd" <> " is a different kind of operation from " <> c "ps aux | grep sshd"
            , "predict whether a set of criteria will be combined with AND or with OR"
            , "use pgrep's exit status in a shell conditional without being caught by " <> c "-c"
            ]
        , dayDiagram = Just d1diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("pgrep sshd", "List the PID of every process whose name matches the ERE " <> c "sshd" <> ".")
            , ("pgrep -u root sshd", "Two criteria, AND-ed: owned by root and named " <> c "sshd" <> ".")
            , ("pgrep -u root,daemon", "One criterion, OR-ed: owned by root or by daemon. No pattern at all.")
            , ("pgrep 'systemd|cron'", "One ERE, two alternatives. Two bare patterns would be an error.")
            , ("pgrep --version", "Print the procps-ng version this course is checked against.")
            ]
        , dayOpts =
            [ ("-c, --count", "Print how many processes matched instead of their PIDs.")
            , ("--quiet", "Print nothing; the exit status is the whole answer. Long form only.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Run " <> c "pgrep -a bash" <> ". Then run " <> c "ps aux | grep bash" <> ". Count the lines in each and account for the difference."
            , "Run " <> c "pgrep" <> " with no arguments at all. Read the error, then run " <> c "pgrep systemd cron" <> " and read that one too. Both exit " <> c "2" <> "."
            , "Ask for something that does not exist — " <> c "pgrep notrunning" <> " — then immediately " <> c "echo $?" <> ". Do the same after a query that does match."
            , "Run " <> c "pgrep -c notrunning; echo $?" <> ". It prints " <> c "0" <> " and exits " <> c "1" <> ". Convince yourself why " <> c "if pgrep -c x" <> " is the wrong shape."
            , "Pick a daemon on your machine and narrow it twice: " <> c "pgrep -l <name>" <> ", then " <> c "pgrep -u root -l <name>" <> ". Watch the list shrink, or not."
            , "Now widen instead: " <> c "pgrep -u root,$USER -c ." <> " against " <> c "pgrep -u root -c ." <> ". The comma is the only OR pgrep has."
            , "Find something you genuinely run daily — a language server, a sync daemon, a database — and write down the shortest query that isolates it. You will refine it all week."
            , "For the rest of today, every time you reach for " <> c "ps aux | grep" <> ", type " <> c "pgrep -a" <> " instead. Notice which cases it cannot yet handle; Days 2 to 4 are those cases."
            ]
        , dayQuiz =
            [
                ( "You run " <> c "pgrep -u root -G audio firefox" <> " and get nothing, although a root-owned firefox is clearly running. What is the most likely reason?"
                , do
                    p_ $ do
                        "Every criterion has to hold at once. You asked for a process that is simultaneously owned by root, has "
                        c "audio"
                        " as its "
                        i_ "real group"
                        ", and is named firefox. The first two are independent facts about the same process, and both must be true — narrowing is AND, always."
                    p_ $ do
                        "The only OR in pgrep lives "
                        i_ "inside"
                        " one criterion, as a comma list: "
                        c "-u root,jhrcek"
                        " means either user. There is no way to write \"root-owned or audio-grouped\" in a single invocation, and that is deliberate — see Day 5 for what happens when you reach for "
                        opt "-v"
                        " to fake it."
                )
            ,
                ( "Why does " <> c "ps aux | grep sshd" <> " almost always show one more line than there are sshd processes?"
                , do
                    p_ $ do
                        "Because "
                        c "grep sshd"
                        " is itself a running process with "
                        c "sshd"
                        " in its command line, and "
                        c "ps"
                        " snapshots the table at a moment when the grep already exists. You are matching against a "
                        i_ "rendering"
                        " of the process table, so anything that mentions the string qualifies — including the tool doing the mentioning."
                    p_ $ do
                        "pgrep matches against the fields themselves and, by explicit rule, never reports itself. It still reports its "
                        i_ "parent"
                        ", which is the subject of tomorrow."
                )
            ,
                ( "A colleague's health-check script has " <> c "if pgrep -c myservice; then echo up; fi" <> " and it reports \"up\" even when the service is stopped. Why?"
                , do
                    p_ $ do
                        "It does not. It reports nothing at all when the service is stopped, and \"up\" when it is running — but it also prints a bare "
                        c "0"
                        " or "
                        c "3"
                        " into the log every time it runs, because "
                        opt "-c"
                        " writes the count to stdout. The count and the exit status are separate channels: with no matches pgrep prints "
                        c "0"
                        " and exits "
                        c "1"
                        "."
                    p_ $ do
                        "The shape that works is "
                        c "if pgrep --quiet myservice"
                        ". Note that "
                        opt "--quiet"
                        " has no short form in pgrep — "
                        c "-q"
                        " is "
                        opt "--queue"
                        " in pkill, and pgrep rejects it outright."
                )
            ,
                ( "You want every process owned by root or by www-data whose name contains " <> c "nginx" <> ". You write " <> c "pgrep -u root -u www-data nginx" <> ". What do you get?"
                , do
                    p_ $ do
                        "Only www-data's processes. A repeated option does not accumulate — the second "
                        opt "-u"
                        " replaces the first, so you asked for \"owned by www-data and named nginx\". No error, no warning, and the answer looks plausible, which is what makes it expensive."
                    p_ $ do
                        "The comma list is the accumulator: "
                        c "pgrep -u root,www-data nginx"
                        "."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d1diagram :: Diagram
d1diagram =
    ( diagram
        "A pgrep run is given one pattern and any number of criteria, scans the /proc \
        \filesystem whose directories describe processes, and yields a selection which is \
        \printed as process IDs and also determines the exit status."
        body'
    )
        { dgCaption = do
            "Two things are worth taking from this. First, the pattern is "
            b_ "one criterion among many"
            " and not the point of the tool — a run with no pattern at all is perfectly legal, "
            "and a run with two patterns is an error. Second, the selection leaves by "
            b_ "two exits"
            ": the PIDs on stdout and the status code. Scripts almost always want the second one, "
            "and reaching for the first is how "
            c "-c"
            " ends up in a conditional where it does not belong."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  run   [label=\"a pgrep run\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  pat   [label=\"the one pattern\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  crit  [label=\"a criterion\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  procd [label=\"the /proc filesystem\", fillcolor=\"#f4efe6\"];"
            , "  entry [label=\"a /proc/PID directory\", fillcolor=\"#f4efe6\"];"
            , "  proc  [label=\"a running process\"];"
            , "  sel   [label=\"the selection\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  pid   [label=\"a process ID\\non stdout\"];"
            , "  stat  [label=\"the exit status\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  self  [label=\"the pgrep process\\nitself\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  run   -> pat   [label=\"  is given\"];"
            , "  run   -> crit  [label=\"  is narrowed by\"];"
            , "  run   -> procd [label=\"  scans\"];"
            , "  procd -> entry [label=\"  contains\"];"
            , "  entry -> proc  [label=\"  describes\"];"
            , "  run   -> sel   [label=\"  yields\"];"
            , "  sel   -> pid   [label=\"  is printed as\"];"
            , "  sel   -> stat  [label=\"  determines\"];"
            , "  proc  -> pid   [label=\"  is identified by\"];"
            , "  run   -> self  [label=\"  never matches  \", style=dashed, constraint=false];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "It is a query, not a search" $ do
        p_ [class_ "lede"] $ do
            "pgrep is not grep for processes. It is a "
            b_ "query over the process table"
            ", in which the text pattern is one predicate among a dozen, and the answer comes \
            \back as process IDs rather than as lines you have to parse again. Once you see it \
            \that way, the whole option list stops being arbitrary."
        p_ $ do
            "The mechanism is unglamorous. pgrep walks "
            c "/proc"
            ", reads the numbered directories the kernel publishes there, and for each one \
            \decides whether every criterion you supplied holds. The survivors are printed, one \
            \PID per line, in ascending numeric order. That is the whole program."
        p_ $ do
            "What makes this different from "
            c "ps aux | grep sshd"
            " is that the comparison happens against "
            b_ "fields"
            ", not against a rendering. "
            c "ps"
            " formats the table into text and grep then matches that text, which is why the \
            \grep finds itself, why a username that happens to appear in someone's command line \
            \counts as a match, and why you end up with "
            c "awk '{print $2}'"
            " bolted on the end to recover the number you actually wanted."
        why $ do
            p_ $ do
                "pgrep was written in 2000 to kill that pipeline, and its design follows from one \
                \observation: the thing you want is almost never the text. It is the PID, so that \
                \you can pass it to "
                c "renice"
                ", or "
                c "kill"
                ", or "
                c "ps -f"
                "; or it is the yes/no answer, so that a script can branch on it."
            p_ $ do
                "So pgrep emits PIDs and sets an exit status, and everything else — the name, the \
                \command line, the count — is an option you have to ask for. The man page's own \
                \examples are all of the form "
                c "$(pgrep …)"
                " for exactly this reason."
        fig

    block "All of the criteria, any of the values" $ do
        p_ $ do
            "There are two combining rules and they operate at different levels. Get them the \
            \wrong way round and you will write queries that quietly return the wrong set."
        defs
            [
                ( "Between criteria: AND"
                , do
                    "Every option you add narrows the result. "
                    c "pgrep -u root sshd"
                    " means owned by root "
                    i_ "and"
                    " named sshd. There is no way to spell OR across two different criteria, and \
                    \no plans to add one."
                )
            ,
                ( "Within one criterion: OR"
                , do
                    "The criteria that take a list accept commas, and a comma means \"any of\". "
                    c "pgrep -u root,daemon"
                    " means owned by root "
                    i_ "or"
                    " by daemon. Note that this example has no pattern at all — perfectly legal."
                )
            ]
        sh
            [ "$ pgrep -l -u root systemd          # root AND matching /systemd/"
            , "1 systemd"
            , "832 systemd-journal"
            , "864 systemd-userdbd"
            , "877 systemd-udevd"
            , "1228 systemd-machine"
            , "1273 systemd-logind"
            , "$ pgrep -l -u root,jhrcek systemd   # (root OR jhrcek) AND matching /systemd/"
            , "1 systemd"
            , "832 systemd-journal"
            , "864 systemd-userdbd"
            , "877 systemd-udevd"
            , "1228 systemd-machine"
            , "1273 systemd-logind"
            , "4844 systemd                        # the per-user instance, mine"
            ]
        gotcha $ do
            p_ $ do
                "Repeating an option does not accumulate, it "
                b_ "overwrites"
                ". The second "
                opt "-u"
                " silently replaces the first, and the answer that comes back is plausible enough \
                \that you will not question it:"
            sh
                [ "$ pgrep -l -u root -u jhrcek systemd"
                , "4844 systemd"
                ]
            p_ $ do
                "Nine matches became one, and nothing warned you. Use the comma."

    block "The answer leaves by two doors" $ do
        p_ $ do
            "A pgrep run produces a list on stdout "
            i_ "and"
            " an exit status, and the two are independent. The statuses are worth learning \
            \properly because they are how pgrep is used in anger:"
        defs
            [ (c "0", "One or more processes matched.")
            , (c "1", "Nothing matched. Not an error — the commonest outcome in a health check.")
            , (c "2", "You made a syntax error: an unknown option, two patterns, an invalid username.")
            , (c "3", "Fatal — out of memory and similar. You will not see this.")
            ]
        sh
            [ "$ pgrep systemd cron"
            , "pgrep: only one pattern can be provided"
            , "Try `pgrep --help\' for more information."
            , "$ pgrep"
            , "pgrep: no matching criteria specified"
            , "Try `pgrep --help\' for more information."
            ]
        p_ $ do
            "For a script that only wants the yes/no, ask for silence. "
            opt "--quiet"
            " prints nothing whatsoever and leaves only the status behind:"
        sh
            [ "$ if pgrep --quiet pipewire; then echo up; else echo down; fi"
            , "up"
            ]
        gotcha $ do
            p_ $ do
                opt "--quiet"
                " has "
                b_ "no short form in pgrep"
                ". "
                c "pgrep -q"
                " fails with "
                c "invalid option -- 'q'"
                ", because "
                c "-q"
                " is "
                opt "--queue"
                " over in pkill and the three tools share one option table. Day 7 covers what \
                \pkill does with it."
            p_ $ do
                "It also refuses to be combined with the listing options — "
                c "pgrep --quiet -l x"
                " is a hard error — but it does "
                i_ "not"
                " refuse "
                opt "-c"
                ", which cheerfully prints the count anyway."
        p_ $ do
            "The trap in the other direction is "
            opt "-c"
            ". It suppresses the PIDs and prints a count, but the count is a "
            i_ "number on stdout"
            ", not a status:"
        sh
            [ "$ pgrep -c notrunning"
            , "0"
            , "$ echo $?"
            , "1"
            ]
        p_ $ do
            "So "
            c "if pgrep -c x; then"
            " does the right thing for the wrong reason, and pollutes the log with a stray "
            c "0"
            " on every run. Reach for "
            opt "--quiet"
            " when you want the branch and "
            opt "-c"
            " when you want the number."

    block "Two rules about the pattern, before we get to the pattern" $ do
        p_ $ do
            "Tomorrow is entirely about what the pattern matches against. Today only needs two \
            \structural facts, both of which produce exit status "
            c "2"
            " when violated."
        steps
            [ do
                b_ "At most one pattern."
                " "
                c "pgrep systemd cron"
                " is not \"either of these\"; it is "
                c "only one pattern can be provided"
                ", exit "
                c "2"
                ". If you want either, write it as one ERE: "
                c "pgrep 'systemd|cron'"
                "."
            , do
                b_ "At least one criterion."
                " Bare "
                c "pgrep"
                " is "
                c "no matching criteria specified"
                ". A pattern counts as a criterion, and so does "
                c "-u root"
                " on its own, but you cannot ask for nothing."
            ]
        note $ p_ $ do
            "pgrep never reports itself — that is a documented rule, not an accident of timing. \
            \It says nothing about your shell, your script, or the "
            c "sudo"
            " you ran this under, all of which remain eligible. That asymmetry costs people \
            \twenty minutes tomorrow."

    block "Today's habit" $ do
        p_ $ do
            "Retire "
            c "ps aux | grep"
            " for one day. Every time your fingers start it, type "
            c "pgrep -a"
            " instead and see how far it gets you. Some of the time it will not be enough yet, \
            \and those are precisely the cases the next three days cover."
        p_ $ do
            "Start a file — "
            c "~/pgrep-recipes.sh"
            " will do — and put today's one line in it with a comment saying what it is for. \
            \This course has no config file to build, because pgrep has no configuration of any \
            \kind; the recipes file is what you accumulate instead, and by Day 9 it is the \
            \artefact worth keeping."
        cfg
            [ "# ~/pgrep-recipes.sh - queries I have needed, with the reason"
            , "#"
            , "# Day 1: is it running at all? Status only, nothing on stdout."
            , "pgrep --quiet postgres"
            ]

cheat :: Html ()
cheat = do
    cfg
        [ "pgrep NAME              # PIDs of processes whose name matches the ERE"
        , "pgrep -u root NAME      # criteria are AND-ed: root AND named NAME"
        , "pgrep -u root,daemon    # values are OR-ed: root OR daemon. No pattern needed."
        , "pgrep -u root -u daemon # WRONG: the second -u replaces the first"
        , "pgrep -c NAME           # print the count instead of the PIDs"
        , "pgrep --quiet NAME      # print nothing; the exit status is the answer (no -q!)"
        , "#"
        , "# exit 0 = matched   1 = no match   2 = your syntax   3 = fatal"
        , "# 'pgrep -c x' prints 0 and exits 1 when nothing matches - two channels."
        ]
