module Course.Day.D03 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 3
        , dayTitle = "Shaping the output"
        , daySubtitle = "Six renderings of one answer, and only two of them compose."
        , dayMinutes = 30
        , dayLevel = "essential"
        , dayManRef = "OPTIONS (-l, -a, -Q, -d, -c), EXAMPLES"
        , dayTags = ["-a", "-Q", "substitution"]
        , dayGoals =
            [ "choose between " <> c "-l" <> ", " <> c "-a" <> " and " <> c "-Q" <> " by what you are about to do with the output"
            , "feed pgrep's result into another command without losing argument boundaries"
            , "predict what a command substitution does when pgrep matches nothing"
            ]
        , dayDiagram = Just d3diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("ps -fp $(pgrep -d, -x sshd)", "The man page's own idiom: hand a comma list to " <> c "ps" <> ".")
            , ("renice +4 $(pgrep chrome)", "Word-splitting turns newline-separated PIDs into separate arguments.")
            , ("pgrep -a -Q -f worker", "List command lines with argument boundaries preserved.")
            ]
        , dayOpts =
            [ ("-l, --list-name", "Print the process name after the PID. Still the 15-character name, even under " <> c "-f" <> ".")
            , ("-a, --list-full", "Print the full command line after the PID.")
            , ("-Q, --shell-quote", "Shell-quote each argument in " <> c "-a" <> " output, so boundaries survive. Undocumented.")
            , ("-d, --delimiter", "Join the PIDs with this string instead of a newline. A trailing newline is still added.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Run the same query four ways on a process of your own: plain, " <> c "-l" <> ", " <> c "-a" <> ", and " <> c "-a -Q" <> ". Line the four outputs up."
            , "Prove the trailing newline is still there: " <> c "pgrep -d, bash | xxd | tail -1" <> ". The last byte is " <> c "0a" <> "."
            , "Run " <> c "ps -fp $(pgrep -d, -u $USER -x bash)" <> ". Then break it on purpose by substituting a name that matches nothing, and read " <> c "ps" <> "'s complaint."
            , "Find a process started with a quoted argument containing a space — a " <> c "python3 -c" <> " or an " <> c "ssh -o" <> " will do — and confirm that " <> c "-a" <> " loses the boundary and " <> c "-a -Q" <> " keeps it."
            , "Try to combine " <> c "--quiet" <> " with " <> c "-l" <> ". Read the refusal. Then try " <> c "--quiet" <> " with " <> c "-c" <> " and notice it is allowed."
            , "Ask for " <> c "-l -f" <> " on something whose name is truncated. " <> c "-f" <> " changed what was matched, not what is printed."
            , "Take one recipe from your file and decide honestly whether it should end in " <> c "-a" <> " (you read it) or nothing at all (a script reads it). Change it to suit."
            ]
        , dayQuiz =
            [
                ( "A deploy script does " <> c "kill -TERM $(pgrep -f myapp)" <> ". One morning it fails with " <> c "kill: not enough arguments" <> " and the deploy aborts. What happened, and what is the right shape?"
                , do
                    p_ $ do
                        "The app was not running, so pgrep printed nothing and exited "
                        c "1"
                        ". Command substitution turned that into an empty word list, "
                        c "kill"
                        " was invoked with no PIDs, and it failed. The paradox is that the script broke precisely because there was nothing to do."
                    p_ $ do
                        "Two shapes avoid it. Branch on pgrep's status first — "
                        c "if pids=$(pgrep -f myapp); then kill -TERM $pids; fi"
                        " — or stop building the pipeline by hand and use "
                        c "pkill -f myapp"
                        ", which is Day 7 and does the whole thing atomically."
                )
            ,
                ( "You run " <> c "pgrep -l -f 'shard 3'" <> " and get " <> c "269667 python3" <> ". Why does the output not show the string you matched on?"
                , do
                    p_ $ do
                        opt "-f"
                        " and "
                        opt "-l"
                        " answer different questions. "
                        opt "-f"
                        " says what to "
                        i_ "match"
                        " against; "
                        opt "-l"
                        " says to print the "
                        i_ "name"
                        ". They are independent, so you can match on the command line and still be shown the fifteen-character name, which is exactly as unhelpful as it sounds."
                    p_ $ do
                        "If you matched with "
                        opt "-f"
                        ", print with "
                        opt "-a"
                        ". Treat the two as a pair."
                )
            ,
                ( "Why is " <> c "-Q" <> " worth knowing when " <> c "-a" <> " already prints the command line?"
                , do
                    p_ $ do
                        opt "-a"
                        " joins the argument vector with single spaces, so a process started with "
                        c "--worker 'shard 3'"
                        " is printed as "
                        c "--worker shard 3"
                        " — three arguments, or two, and nothing in the output tells you which. "
                        opt "-Q"
                        " quotes each element separately and the ambiguity disappears."
                    p_ $ do
                        "This matters most when you are about to reconstruct a command from what you see — restarting a process by hand, filing a bug, or writing the "
                        opt "-f"
                        " pattern that will find it next time. It is also not in "
                        c "pgrep(1)"
                        " at all; the only mention is in "
                        c "pgrep --help"
                        "."
                )
            ,
                ( "Your monitoring script pipes pgrep into " <> c "wc -l" <> " to count processes. A colleague replaces it with " <> c "pgrep -c" <> ". What behaviour changed?"
                , do
                    p_ $ do
                        "The counts agree, but the failure modes no longer do. "
                        c "pgrep foo | wc -l"
                        " exits with "
                        c "wc"
                        "'s status, which is "
                        c "0"
                        " whether or not anything matched — the pipeline hides pgrep's answer. "
                        c "pgrep -c foo"
                        " prints "
                        c "0"
                        " and exits "
                        c "1"
                        "."
                    p_ $ do
                        "So the replacement is strictly better, but any "
                        c "set -e"
                        " in that script will now abort on an empty result where it used to sail through. That is the correct behaviour arriving at an inconvenient moment, which is how most "
                        c "set -e"
                        " incidents go."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d3diagram :: Diagram
d3diagram =
    ( diagram
        "A matched process is identified by a process ID, has a name and a command line, and \
        \the command line can be shell-quoted. A line of pgrep output always begins with the \
        \process ID and carries one of the other three under -l, -a or -Q; the IDs are \
        \separated by the delimiter and become elements of another command's argument list."
        body'
    )
        { dgCaption = do
            "The process ID is the only thing every rendering has in common, and it is the only \
            \part another program can use. Everything the dashed aspects add is "
            b_ "for you to read"
            ": the moment a line carries a name or a command line, it has stopped being an \
            \argument list and become a report. Choosing an output flag is really choosing which \
            \of those two you are producing."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  proc  [label=\"a matched process\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  pid   [label=\"its process ID\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  nm    [label=\"its process name\"];"
            , "  cl    [label=\"its command line\"];"
            , "  qt    [label=\"its shell-quoted\\ncommand line\"];"
            , "  out   [label=\"a line of\\npgrep output\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  dl    [label=\"the delimiter\\n(a newline by default)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  argv  [label=\"another command's\\nargument list\", fillcolor=\"#f4efe6\"];"
            , ""
            , "  proc -> pid  [label=\"  is identified by\"];"
            , "  proc -> nm   [label=\"  has as name\"];"
            , "  proc -> cl   [label=\"  has as command line\"];"
            , "  cl   -> qt   [label=\"  is quoted as\"];"
            , "  out  -> pid  [label=\"  always begins with\"];"
            , "  out  -> nm   [label=\"  carries with -l  \", style=dashed];"
            , "  out  -> cl   [label=\"  carries with -a  \", style=dashed];"
            , "  out  -> qt   [label=\"  carries with -Q  \", style=dashed];"
            , "  pid  -> dl   [label=\"  is followed by\"];"
            , "  pid  -> argv [label=\"  is an element of\"];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "You are producing an argument list, or a report" $ do
        p_ [class_ "lede"] $ do
            "pgrep's default output — bare PIDs, one per line — looks minimal because it is aimed \
            \at another program, not at you. Every output flag moves it one step towards being \
            \readable and one step away from being usable, and the only question worth asking is \
            \which end you want."
        p_ $ do
            "Here is one selection rendered six ways. The process was started as "
            c "python3 -c '…' --worker 'shard 3'"
            ", which will matter in a moment:"
        sh
            [ "$ pgrep -f 'shard 3'"
            , "269645"
            , "$ pgrep -l -f 'shard 3'"
            , "269645 python3"
            , "$ pgrep -a -f 'shard 3'"
            , "269645 python3 -c import time; time.sleep(400) --worker shard 3"
            , "$ pgrep -a -Q -f 'shard 3'"
            , "269645 python3 -c 'import time; time.sleep(400)' --worker 'shard 3'"
            , "$ pgrep -d, -f 'shard 3'"
            , "269645"
            , "$ pgrep -c -f 'shard 3'"
            , "1"
            ]
        fig

    block "-l tells you less than you think" $ do
        p_ $ do
            opt "-l"
            " appends the process name. It is the fifteen-character name from yesterday, and it \
            \stays the fifteen-character name even when you matched with "
            opt "-f"
            ". The two flags are answering different questions — one is about matching, the other \
            \about printing — and nothing connects them."
        gotcha $ p_ $ do
            "This produces the single most confusing output in the tool: "
            c "pgrep -l -f 'shard 3'"
            " prints "
            c "269645 python3"
            ", a line in which neither the pattern you typed nor anything resembling it appears. \
            \Make it a rule: "
            b_ "matched with -f, print with -a"
            "."
        p_ $ do
            opt "-a"
            " prints the full command line instead, which is what you almost always wanted. It is \
            \the flag that replaces "
            c "ps aux | grep"
            " outright."

    block "-Q, and the argument boundaries -a throws away" $ do
        p_ $ do
            "The command line in "
            c "/proc/PID/cmdline"
            " is NUL-separated: the kernel knows exactly where each argument ends. "
            opt "-a"
            " discards that, joining everything with single spaces, so a space inside an argument \
            \and a space between two arguments print identically."
        cols
            [ do
                p_ $ b_ "What -a shows"
                sh ["--worker shard 3"]
                p_ "Two arguments, or three? The output cannot say."
            , do
                p_ $ b_ "What -a -Q shows"
                sh ["--worker 'shard 3'"]
                p_ "Two. The quoting is the answer."
            ]
        p_ $ do
            opt "-Q"
            " shell-quotes each element of the argument vector separately, which makes the output \
            \both unambiguous and safe to paste back into a shell. It only affects "
            opt "-a"
            "; on its own, or with "
            opt "-l"
            ", it changes nothing."
        note $ p_ $ do
            opt "-Q"
            " appears in "
            c "pgrep --help"
            " and in no section of "
            c "pgrep(1)"
            ". So do "
            opt "--quiet"
            ", "
            opt "-p"
            " and "
            opt "--env"
            ". If a flag seems to be missing from the manual page, check "
            c "--help"
            " before concluding your version does not have it."

    block "Feeding the result to something else" $ do
        p_ $ do
            "Bare PIDs separated by newlines are already an argument list, because the shell \
            \splits on whitespace. That is the whole of the man page's fourth example:"
        sh
            [ "$ renice +4 $(pgrep chrome)"
            ]
        p_ $ do
            "Commands that want one comma-separated argument instead of many — "
            c "ps -p"
            " is the common one — need "
            opt "-d"
            ":"
        sh
            [ "$ ps -fp $(pgrep -d, -x pipewire)"
            , "UID          PID    PPID  C STIME TTY          TIME CMD"
            , "jhrcek      5489    4844  0 06:23 ?        00:01:27 /usr/bin/pipewire"
            ]
        p_ $ do
            opt "-d"
            " replaces the separator "
            i_ "between"
            " PIDs and nothing else. A trailing newline is still written after the last one, \
            \which is usually invisible and occasionally not:"
        sh
            [ "$ pgrep -d, pipewire | xxd"
            , "00000000: 3534 3839 2c35 3839 370a                 5489,5897."
            ]
        gotcha $ do
            p_ $ do
                "Every one of these idioms fails when nothing matches, and fails in a way that \
                \reads like a different problem:"
            sh
                [ "$ ps -fp $(pgrep -d, -x notrunning)"
                , "error: list of process IDs must follow -p"
                , "$ renice +4 $(pgrep notrunning)"
                , "renice: not enough arguments"
                ]
            p_ $ do
                "pgrep did its job and exited "
                c "1"
                "; the substitution collapsed to nothing; the outer command was invoked with no \
                \arguments and complained about its own syntax. Capture first and branch — "
                c "if pids=$(pgrep -f myapp); then …"
                " — or skip the pipeline entirely and use pkill, which is Day 7."

    block "Which flag wins" $ do
        p_ $ do
            "The output flags are not orthogonal, and pgrep resolves the conflicts three \
            \different ways. It is worth knowing which, because only one of the three tells you \
            \anything:"
        defs
            [
                ( c "-c" <> " beats everything"
                , do
                    "Add "
                    opt "-c"
                    " to any combination and you get a bare number. It silently overrides "
                    opt "-l"
                    ", "
                    opt "-a"
                    " and "
                    opt "-d"
                    " — and it overrides "
                    opt "--quiet"
                    " too, which is arguably the wrong way round."
                )
            ,
                ( c "-a" <> " beats " <> c "-l"
                , "Ask for both and you get the command line. No warning; the more informative one wins."
                )
            ,
                ( c "--quiet" <> " refuses"
                , do
                    "Combined with "
                    opt "-l"
                    " or "
                    opt "-a"
                    " it is a hard error — "
                    c "Cannot use --quiet and -l,--list-name options together"
                    ", exit "
                    c "2"
                    ". The one place pgrep tells you that two flags contradict each other."
                )
            ]

    block "Today's habit" $ do
        p_ $ do
            "Split your muscle memory in two. At a prompt, reading, the query ends in "
            c "-a"
            ". In a script, feeding something else, it ends in nothing at all — and the result is \
            \captured into a variable before anything is done with it."
        p_ $ do
            "Tomorrow the pattern becomes optional: every column of the process table is a \
            \criterion in its own right, and some of the best queries have no pattern at all."
        cfg
            [ "# Day 3: for reading - full command line, boundaries intact."
            , "pgrep -a -Q -f 'python3 .*worker'"
            , ""
            , "# Day 3: for scripting - capture first, so an empty result is a branch,"
            , "# not a syntax error in whatever came next."
            , "if pids=$(pgrep -A -f 'python3 .*worker'); then renice +4 $pids; fi"
            ]

cheat :: Html ()
cheat = do
    cfg
        [ "pgrep NAME         # bare PIDs, one per line, ascending - an argument list"
        , "pgrep -l NAME      # + the 15-char name  (NOT affected by -f)"
        , "pgrep -a NAME      # + the full command line          <- for reading"
        , "pgrep -a -Q NAME   # + shell-quoted, argument boundaries kept"
        , "pgrep -d, NAME     # join PIDs with ','  (trailing newline is STILL added)"
        , "pgrep -c NAME      # just the number - overrides -l, -a, -d and --quiet"
        , "#"
        , "ps -fp $(pgrep -d, -x sshd)     # -d for commands wanting one argument"
        , "renice +4 $(pgrep chrome)       # newlines split into many arguments"
        , "# Both of these FAIL when nothing matches. Capture, then branch."
        ]
