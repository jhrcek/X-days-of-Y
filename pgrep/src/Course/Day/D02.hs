module Course.Day.D02 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 2
        , dayTitle = "Name or command line"
        , daySubtitle = "Fifteen characters, an extended regexp, and the trap inside -f."
        , dayMinutes = 35
        , dayLevel = "essential"
        , dayManRef = "NOTES, OPERANDS, OPTIONS (-f, -x, -i, -A)"
        , dayTags = ["comm", "cmdline", "regex"]
        , dayGoals =
            [ "say which of two strings a given invocation is matching, and where the kernel keeps it"
            , "recognise the fifteen-character wall from the symptom rather than from the error message"
            , "write a " <> c "-f" <> " query inside a script without the script matching itself"
            ]
        , dayDiagram = Just d2diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("pgrep -f 'python3 .*worker'", "Match the full command line, so the interpreter's arguments count.")
            , ("pgrep -x systemd", "Only processes named exactly " <> c "systemd" <> " — not " <> c "systemd-logind" <> ".")
            , ("pgrep -A -f myscript.sh", "Match command lines, but ignore every ancestor of this pgrep.")
            , ("cat /proc/PID/comm", "The 15-character name pgrep matches by default.")
            , ("tr '\\0' ' ' < /proc/PID/cmdline", "The full command line pgrep matches under " <> c "-f" <> ".")
            ]
        , dayOpts =
            [ ("-f, --full", "Match against the whole command line instead of the process name.")
            , ("-x, --exact", "Require the pattern to match the whole string, not a part of it.")
            , ("-i, --ignore-case", "Match case-insensitively.")
            , ("-A, --ignore-ancestors", "Drop every ancestor of this pgrep from the result. The fix for " <> c "-f" <> " in scripts.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Pick any PID from " <> c "pgrep -l ." <> " and read both strings yourself: " <> c "cat /proc/PID/comm" <> " and " <> c "tr '\\0' ' ' < /proc/PID/cmdline" <> "."
            , "Break it on purpose: " <> c "pgrep systemd-journald" <> ". Read the two-line diagnostic, then count the characters in that name."
            , "Find a process on your machine whose name is exactly fifteen characters (" <> c "pgrep -l . | awk 'length($2)==15'" <> ") and confirm with " <> c "-a" <> " that its real name is longer."
            , "Contrast " <> c "pgrep -c systemd" <> " with " <> c "pgrep -xc systemd" <> ". The pattern is unanchored until you say otherwise."
            , "Write a script containing nothing but " <> c "pgrep -f <its own filename>; echo $?" <> " and run it. It finds itself. Add " <> c "-A" <> " and run it again."
            , "Take a long-running process of your own started with arguments — a dev server, a language server, an ssh tunnel — and write the " <> c "-f" <> " query that isolates it from its siblings."
            , "Feed pgrep a deliberately broken regexp: " <> c "pgrep 'foo['" <> ". Note that this is exit " <> c "2" <> ", the same class as a typo'd option."
            , "Add today's best query to " <> c "~/pgrep-recipes.sh" <> ", with a comment saying which of the two strings it matches and why that was the right choice."
            ]
        , dayQuiz =
            [
                ( "You run " <> c "pgrep systemd-journald" <> " and get nothing, but " <> c "pgrep -a systemd-journal" <> " finds it immediately. What happened, and which of the two is the better habit?"
                , do
                    p_ $ do
                        c "systemd-journald"
                        " is sixteen characters. The kernel stores a process name in a fixed sixteen-byte field, one byte of which is the terminator, so what "
                        c "/proc/PID/stat"
                        " reports is "
                        c "systemd-journal"
                        " — fifteen characters, and your pattern can never match it."
                    p_ $ do
                        "Dropping the last character works but is a trap you have set for your future self. The right habit is "
                        c "pgrep -f systemd-journald"
                        ", which matches the command line and is immune to the wall. procps is helpful enough to warn you here: a pattern over fifteen characters produces a diagnostic and exit "
                        c "1"
                        ", which is one of the few places the binary tells you more than the manual page does."
                )
            ,
                ( "A cron job runs " <> c "backup.sh" <> ", which begins " <> c "if pgrep -f backup.sh; then exit 1; fi" <> " so that two backups never overlap. It has never once run. Why?"
                , do
                    p_ $ do
                        "The script is matching itself. Its own command line is "
                        c "/bin/bash /path/to/backup.sh"
                        ", which contains "
                        c "backup.sh"
                        ", so the guard fires on the very first invocation. pgrep's rule is that it never reports "
                        i_ "itself"
                        " — the pgrep process. Its parent, the script, is fair game, and so is the shell that launched the script."
                    p_ $ do
                        "The fix is "
                        opt "-A"
                        ", which drops every ancestor of the pgrep from the result. Then the first run says \"starting\" and a genuine second run is still caught."
                )
            ,
                ( "You know " <> c "pgrep -x nginx" <> " works on your web server. Why does adding " <> c "-f" <> " to it — " <> c "pgrep -x -f nginx" <> " — suddenly find nothing at all?"
                , do
                    p_ $ do
                        opt "-x"
                        " anchors the pattern to whichever string is being matched, and "
                        opt "-f"
                        " changes which string that is. Together they demand that the "
                        i_ "entire command line"
                        " be exactly "
                        c "nginx"
                        " — no path, no arguments. A real nginx command line is "
                        c "nginx: worker process"
                        " or "
                        c "/usr/sbin/nginx -g daemon off;"
                        ", so nothing qualifies."
                    p_ $ do
                        "With "
                        opt "-f"
                        ", the string pgrep matches is the argument vector joined with single spaces, so "
                        opt "-x"
                        " is only useful there when you know the invocation exactly — which occasionally you do, and then it is the sharpest query available."
                )
            ,
                ( "Two processes have the same name in " <> c "pgrep -l" <> " but you are sure they are different programs. How do you find out, and what is the general rule you have just discovered?"
                , do
                    p_ $ do
                        c "pgrep -a"
                        " prints the command line instead of the name, and the difference will be obvious — typically two "
                        c "python3"
                        " processes running different scripts, or two "
                        c "node"
                        " processes from different projects."
                    p_ $ do
                        "The rule is that the process name belongs to the "
                        i_ "executable"
                        ", not to the job. Anything launched through an interpreter, a wrapper, or a language runtime shares its name with every other user of that runtime, which makes the default matching mode nearly useless for exactly the software people most want to find. That is why "
                        opt "-f"
                        " exists and why you will end up using it more than you expect."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d2diagram :: Diagram
d2diagram =
    ( diagram
        "A running process has two matchable strings: a process name, truncated to fifteen \
        \characters and read from /proc/PID/stat, and a full command line read from \
        \/proc/PID/cmdline. The pattern matches the first by default and the second under -f."
        body'
    )
        { dgCaption = do
            "Every question you will ever have about \"why did pgrep not find it\" is a question \
            \about which of these two boxes you were aimed at. The name is cheap, stable and "
            b_ "fifteen characters long"
            "; the command line is complete but contains the arguments of every other process \
            \that merely mentions what you are looking for — including, when you are unlucky, \
            \the script doing the looking."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  exe   [label=\"the executable's\\nbasename\", fillcolor=\"#f4efe6\"];"
            , "  proc  [label=\"a running process\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  comm  [label=\"the process name\\n(15 characters)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  cline [label=\"the full command line\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  stat  [label=\"/proc/PID/stat\", fillcolor=\"#f4efe6\"];"
            , "  cmdl  [label=\"/proc/PID/cmdline\", fillcolor=\"#f4efe6\"];"
            , "  pat   [label=\"the pattern\\n(an extended regexp)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , ""
            , "  exe   -> comm  [label=\"  is truncated to\"];"
            , "  proc  -> comm  [label=\"  has as name\"];"
            , "  proc  -> cline [label=\"  has as command line\"];"
            , "  comm  -> stat  [label=\"  is read from\"];"
            , "  cline -> cmdl  [label=\"  is read from\"];"
            , "  pat   -> comm  [label=\"  matches by default  \", style=dashed, constraint=false];"
            , "  pat   -> cline [label=\"  matches under -f  \", style=dashed];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Two strings, and the short one is the default" $ do
        p_ [class_ "lede"] $ do
            "A process offers pgrep exactly two pieces of text to match against, and they live in \
            \different files, obey different rules and fail in different ways. Nearly every \
            \\"pgrep cannot find my process\" is really \"pgrep was looking at the other one\"."
        p_ $ do
            "The default is the "
            b_ "process name"
            ", the second field of "
            c "/proc/PID/stat"
            ", also exposed as "
            c "/proc/PID/comm"
            ". The kernel fills it in from the basename of the executable, and a program may \
            \change its own — bash sets it to the script it is running, which is why a shell \
            \script has a useful name at all."
        p_ $ do
            "The alternative, selected with "
            opt "-f"
            ", is the "
            b_ "full command line"
            " from "
            c "/proc/PID/cmdline"
            ": the argument vector as the process was started, stored NUL-separated and joined \
            \with single spaces before matching. Read both yourself for any process on your \
            \machine and the distinction stops being abstract:"
        sh
            [ "$ cat /proc/269399/comm"
            , "mybackup.sh"
            , "$ tr '\\0' ' ' < /proc/269399/cmdline"
            , "/bin/bash ./mybackup.sh"
            ]
        fig

    block "The fifteen-character wall" $ do
        p_ $ do
            "The name field is sixteen bytes wide in the kernel, one of which is the terminator. \
            \Fifteen usable characters, no configuration, no exceptions. A process whose \
            \executable is called "
            c "a-very-long-script-name.sh"
            " is called "
            c "a-very-long-scr"
            " as far as the default matching mode is concerned."
        sh
            [ "$ pgrep a-very-long-script-name.sh"
            , "pgrep: pattern that searches for process name longer than 15 characters will result in zero matches"
            , "Try `pgrep -f' option to match against the complete command line."
            , "$ pgrep a-very-long-scr"
            , "269411"
            , "$ pgrep -a -f a-very-long-script-name.sh"
            , "269411 /bin/bash ./a-very-long-script-name.sh"
            ]
        note $ p_ $ do
            "That diagnostic is not in "
            c "pgrep(1)"
            ". The binary is more helpful than its own documentation here, and it only fires \
            \when the "
            i_ "pattern"
            " is too long — a sixteen-character pattern with a "
            c ".*"
            " in it silently finds nothing instead, with exit status "
            c "1"
            " and not a word of explanation."
        gotcha $ p_ $ do
            "The names this bites hardest are the ones you most often want. "
            c "systemd-journald"
            " and "
            c "systemd-resolved"
            " are both sixteen characters. "
            c "gnome-keyring-daemon"
            " is twenty, "
            c "containerd-shim-runc-v2"
            " is twenty-three. Every one of them appears in "
            c "pgrep -l"
            " output with the last characters missing, which is a good reason to read that output \
            \with "
            opt "-a"
            " instead."

    block "The pattern is a regexp, and it floats" $ do
        p_ $ do
            "The operand is an "
            b_ "extended"
            " regular expression — "
            c "regex(7)"
            ", the same dialect as "
            c "grep -E"
            " — and it is matched "
            i_ "unanchored"
            ". "
            c "pgrep systemd"
            " means \"contains systemd anywhere\", which is why it finds "
            c "systemd-logind"
            " and "
            c "systemd-udevd"
            " along with "
            c "systemd"
            " itself."
        sh
            [ "$ pgrep -c systemd      # unanchored: any name containing 'systemd'"
            , "11"
            , "$ pgrep -c '^systemd$'  # anchored by hand"
            , "2"
            , "$ pgrep -xc systemd     # the same thing, said properly"
            , "2"
            ]
        p_ $ do
            "Three refinements, and that is the whole of the matching language:"
        defs
            [
                ( opt "-x"
                , do
                    "Anchor to the whole string. Equivalent to wrapping the pattern in "
                    c "^"
                    " and "
                    c "$"
                    ", and clearer than doing so, especially inside a shell where "
                    c "$"
                    " wants quoting."
                )
            ,
                ( opt "-i"
                , "Case-insensitive. Composes with everything, including -x and -f."
                )
            ,
                ( "the ERE itself"
                , do
                    "Alternation is how you ask for two things at once, since a second bare \
                    \pattern is an error: "
                    c "pgrep 'nginx|apache2'"
                    ". Quote it — "
                    c "|"
                    " is a pipe to your shell first."
                )
            ]
        gotcha $ p_ $ do
            "An empty pattern matches every process, and pgrep accepts it without comment. If a \
            \script builds its pattern from a variable, "
            c "pgrep -f \"$NAME\""
            " with "
            c "NAME"
            " unset selects the entire process table — which matters rather a lot on Day 7, when \
            \the command is pkill. A malformed pattern is safer: "
            c "pgrep 'foo['"
            " is "
            c "regex error: Invalid regular expression"
            " and exit "
            c "2"
            "."

    block "The trap that ships inside -f" $ do
        p_ $ do
            opt "-f"
            " widens the haystack from a fifteen-character name to every argument of every \
            \process, and the haystack it widens into includes the processes that are running "
            i_ "your own query"
            ". pgrep never reports itself — that is documented and reliable. It says nothing \
            \about your shell, your script, or the "
            c "sudo"
            " you ran them under."
        p_ $ do
            "The classic casualty is the single-instance guard. Here is one, in full, and it has \
            \never once let the job start:"
        cfg
            [ "#!/bin/bash"
            , "if pgrep -f backup.sh >/dev/null; then"
            , "    echo \"another instance is already running; exiting\""
            , "    exit 1"
            , "fi"
            , "echo \"starting\""
            , "sleep 400"
            ]
        sh
            [ "$ ./backup.sh          # nothing else is running"
            , "another instance is already running; exiting"
            ]
        p_ $ do
            "The script's own command line is "
            c "/bin/bash ./backup.sh"
            ". It contains the pattern, so the script finds itself, concludes it is a duplicate \
            \and exits. The bug survives code review because the code says what the author meant."
        p_ $ do
            "The fix is one flag. "
            opt "-A"
            " walks the parent chain from the pgrep upwards and removes every ancestor from the \
            \result — the script, the shell that ran it, cron, all of them:"
        sh
            [ "$ ./backup.sh          # same script, pgrep -A -f backup.sh"
            , "starting"
            , "$ ./backup.sh          # and now one really is running"
            , "another instance is already running; exiting"
            ]
        why $ p_ $ do
            opt "-A"
            " exists because of "
            c "sudo"
            ". The manual page motivates it as \"useful when elevating with sudo or similar \
            \tools\": "
            c "sudo pkill -f something"
            " has a "
            c "sudo"
            " in its own ancestry whose command line contains the pattern, and signalling your \
            \own sudo mid-command is a memorable way to lose a terminal. Single-instance guards \
            \get the benefit for free."
        tip $ p_ $ do
            "There is a second defence worth knowing even though it is a hack: "
            c "pgrep -f '[b]ackup.sh'"
            ". The bracket expression matches the character "
            c "b"
            ", so the pattern matches "
            c "backup.sh"
            " but the "
            i_ "literal text of the pattern"
            " does not match itself. It is older than "
            opt "-A"
            ", it works in every version, and it is much harder to read. Prefer "
            opt "-A"
            " and keep this one for recognising other people's scripts."

    block "Today's habit" $ do
        p_ $ do
            "Whenever "
            c "pgrep -l"
            " shows you a name, ask whether it is the whole name. Two keystrokes settle it: "
            c "-a"
            " instead of "
            c "-l"
            ". Over a week this is the difference between trusting the tool and being surprised \
            \by it."
        p_ $ do
            "And adopt the rule now, while it is cheap: "
            b_ "any -f inside a script gets an -A"
            ". There is no case where a script wants to match its own ancestors, and writing the \
            \two together means you never have to notice the bug."
        cfg
            [ "# Day 2: the command line, not the name - and never my own ancestors."
            , "pgrep -A -f 'python3 .*worker'"
            ]

cheat :: Html ()
cheat = do
    cfg
        [ "pgrep NAME         # matches /proc/PID/stat comm - 15 CHARACTERS, unanchored ERE"
        , "pgrep -f NAME      # matches /proc/PID/cmdline - the whole argv, joined by spaces"
        , "pgrep -x NAME      # anchor: the whole string, not a substring"
        , "pgrep -i NAME      # case-insensitive"
        , "pgrep -A -f NAME   # ...and drop my own ancestors. Always use -A with -f in a script."
        , "pgrep 'a|b'        # alternation; a second bare pattern is an error"
        , "#"
        , "# cat /proc/PID/comm            <- what plain pgrep sees"
        , "# tr '\\0' ' ' < /proc/PID/cmdline  <- what pgrep -f sees"
        , "# systemd-journald and systemd-resolved are BOTH 16 chars: use -f."
        ]
