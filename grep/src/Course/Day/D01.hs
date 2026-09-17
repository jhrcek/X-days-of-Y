module Course.Day.D01 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 1
        , dayTitle = "What grep does"
        , daySubtitle = "A line filter with three outputs — and the one you keep ignoring is the exit status."
        , dayMinutes = 30
        , dayLevel = "essential"
        , dayManRef = "SYNOPSIS, DESCRIPTION, EXIT STATUS"
        , dayTags = ["model", "stdin", "exit status"]
        , dayGoals =
            [ "say where grep's input comes from in all three forms, without guessing"
            , "distinguish “found nothing” from “something went wrong” without looking at the screen"
            , "explain why a bare " <> c "grep pattern" <> " appears to hang"
            ]
        , dayDiagram = Just d1diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("grep root /etc/passwd", "Search one named file. No filename prefix on the output.")
            , ("grep root /etc/passwd /etc/group", "Search several. Output gains a " <> c "file:" <> " prefix automatically.")
            , ("grep root", "No file operand: read standard input. From a terminal, this waits for you.")
            , ("grep -r root", "No file operand " <> em_ "and" <> " " <> c "-r" <> ": search the working directory instead.")
            , ("cmd | grep root -", "A file operand of " <> c "-" <> " is standard input, mixable with real files.")
            , ("echo $?", "Read the status grep just returned. The habit this whole day is about.")
            ]
        , dayOpts =
            [ ("-V, --version", "Print the version and exit. Know which grep you are actually running.")
            , ("--help", "Print the option summary and exit. Shorter and better organised than the man page.")
            , ("--", "End of options. Everything after it is a pattern or a filename, never a flag.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Run " <> c "grep root /etc/passwd" <> ". One line comes back. Now run " <> c "echo $?" <> " and see " <> c "0" <> "."
            , "Run " <> c "grep nosuchuser /etc/passwd" <> ". Nothing comes back. Run " <> c "echo $?" <> " and see " <> c "1" <> ". Nothing went wrong; there was simply nothing to select."
            , "Break it on purpose: " <> c "grep root /etc/shadow" <> ". You get " <> c "Permission denied" <> " and " <> c "echo $?" <> " says " <> c "2" <> ". Three different situations, three different numbers, and only this one is a bug in your script."
            , "Type " <> c "grep root" <> " with no filename and press Enter. It sits there. It is reading your terminal. Type " <> c "root is here" <> ", press Enter, watch it echo back, then press " <> k "C-d" <> "."
            , "Run " <> c "grep hello /etc" <> ". Read the error. Now run " <> c "grep -r hello /etc/ssh" <> " and watch it work. The difference is the whole of Day 7."
            , "On your own project: " <> c "cd" <> " into it and run " <> c "grep -r TODO" <> " with no path at all. That is the one form where grep supplies the working directory for you."
            , "Prove the two-file rule: " <> c "grep root /etc/passwd" <> ", then " <> c "grep root /etc/passwd /etc/group" <> ". The second one prefixes every line with a filename and you never asked it to."
            , "Adopt the habit: for the rest of this course, every time a grep prints nothing, type " <> c "echo $?" <> " before you type anything else."
            ]
        , dayQuiz =
            [
                ( "A deploy script does "
                    <> c "if grep -q ERROR \"$logfile\"; then alert; fi"
                    <> ". The log file was never created. What happens?"
                , do
                    p_ $ do
                        "grep prints "
                        c "No such file or directory"
                        " to stderr and exits "
                        c "2"
                        ". The "
                        c "if"
                        " treats any non-zero status as false, so the branch is skipped and no alert fires. A missing log file and a clean log file are indistinguishable to this script."
                    p_ $ do
                        "The fix is to stop conflating the two. Test for the file first, or capture the status: "
                        c "grep -q ERROR \"$logfile\"; case $? in 0) alert;; 1) :;; *) die \"cannot read $logfile\";; esac"
                        ". Day 9 comes back to this."
                )
            ,
                ( "You run "
                    <> c "grep -q ERROR app.log missing.log"
                    <> " and get exit status "
                    <> c "0"
                    <> " even though "
                    <> c "missing.log"
                    <> " does not exist. Why?"
                , do
                    p_ $ do
                        c "-q"
                        " is documented to exit zero the moment a line is selected, "
                        em_ "even if an error was detected"
                        ". A match was found in "
                        c "app.log"
                        ", so grep stopped and reported success; the unreadable second file never got a chance to change the answer."
                    p_ $ do
                        "Change the pattern so nothing matches and the status flips to "
                        c "2"
                        ", not "
                        c "1"
                        ". So "
                        c "-q"
                        " hides errors only when it succeeds — which is exactly when you are least likely to check."
                )
            ,
                ( "The manual page says the default for "
                    <> c "-d"
                    <> " is "
                    <> c "read"
                    <> ", \"read directories just as if they were ordinary files\". So why does "
                    <> c "grep hello /etc"
                    <> " print "
                    <> c "Is a directory"
                    <> " instead of reading it?"
                , do
                    p_ $ do
                        "Because it does exactly what the page says, and on Linux that fails. grep opens the directory and calls "
                        c "read(2)"
                        " on it; the kernel refuses with "
                        c "EISDIR"
                        " and grep reports the error it got. Passing "
                        c "-d read"
                        " explicitly produces the identical message, which is the proof."
                    p_ $ do
                        "The wording is a historical artefact of systems where reading a directory returned its raw contents. What you want is "
                        c "-r"
                        ", and "
                        c "-d skip"
                        " if you would rather have silence and status "
                        c "1"
                        "."
                )
            ,
                ( "Your file's last line has no trailing newline. You "
                    <> c "grep"
                    <> " it and pipe the result to "
                    <> c "wc -c"
                    <> ", and the byte count is one higher than you expect. Where did the byte come from?"
                , do
                    p_ $ do
                        "grep put it there. It reads the truncated last line as a line anyway and writes it out "
                        em_ "terminated"
                        ", so a file ending "
                        c "...b"
                        " comes back as "
                        c "...b\\n"
                        "."
                    p_ "grep's output is always a well-formed sequence of lines regardless of what the input was. That is usually a kindness, and occasionally — when you are checksumming or byte-counting the result — a silent corruption."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d1diagram :: Diagram
d1diagram =
    ( diagram
        "grep reads lines from a source, prints the ones matching a pattern to standard output, may print diagnostics to standard error, and always yields an exit status that the calling script branches on."
        body'
    )
        { dgCaption = do
            "grep has "
            b_ "three"
            " outputs, not one. The selected lines are the one you look at; the exit status is the one every script you write depends on, and it is the only output that is always produced — a grep that selects nothing and prints nothing has still told you something."
        , dgRankdir = "TB"
        , dgRanksep = "0.5"
        }
  where
    body' =
        T.unlines
            [ "  inv  [label=\"an invocation\\nof grep\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  pat  [label=\"a pattern\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  sel  [label=\"a selected line\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  line [label=\"an input line\"];"
            , "  src  [label=\"a file, or\\nstandard input\", fillcolor=\"#f4efe6\"];"
            , "  diag [label=\"a diagnostic\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  st   [label=\"an exit status\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  sc   [label=\"the calling script\", fillcolor=\"#f4efe6\"];"
            , ""
            , "  inv -> pat  [label=\"  is given\"];"
            , "  inv -> src  [label=\"  reads\"];"
            , "  src -> line [label=\"  contains\"];"
            , "  sel -> line [label=\"  is\"];"
            , "  sel -> pat  [label=\"  matches\"];"
            , "  inv -> sel  [label=\"  prints on stdout\"];"
            , "  inv -> diag [label=\"  may print on stderr  \", style=dashed];"
            , "  inv -> st   [label=\"  always yields\"];"
            , "  sc  -> st   [label=\"  branches on\"];"
            , "  sc  -> sel  [label=\"  pipes onward  \", style=dashed, constraint=false];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Three outputs, and you only ever read one" $ do
        p_ [class_ "lede"] $ do
            "grep reads its input one line at a time, decides for each line whether it matches, and prints the ones that do. That much everyone knows. What gets forgotten is that printing the lines is only "
            em_ "one"
            " of the three things grep produces, and it is the least reliable of them."
        p_ $ do
            "The selected lines go to standard output. Diagnostics — unreadable files, bad patterns — go to standard error, which is why they appear on your screen but do not appear in the pipe. And every invocation, without exception, yields an exit status: "
            c "0"
            " if at least one line was selected, "
            c "1"
            " if none were, "
            c "2"
            " if something went wrong."
        p_ $ do
            "Those three numbers are the difference between a script that works and a script that is quietly wrong. A blank screen means "
            em_ "either"
            " “no matches” "
            em_ "or"
            " “I could not open the file” — and on a terminal you see the error, but inside a pipeline with stderr redirected you do not. The status is the only thing that tells them apart."
        why $ do
            p_ $ do
                "The three-way status is older than most of the tools you use it with. It exists because grep was designed to be a "
                em_ "predicate"
                " as much as a printer: "
                c "if grep -q ..."
                " is meant to read like an "
                c "if"
                ". A two-way status would have been enough for that, but then a failed open would be indistinguishable from an honest absence, and every conditional built on grep would silently take the wrong branch the day a file went missing."
        fig

    block "Where the input comes from" $ do
        p_ "There are three forms, and the third is the one people get wrong."
        defs
            [
                ( c "grep pat file..."
                , "Named files. Straightforward. With two or more of them the output sprouts a filename prefix you did not ask for."
                )
            ,
                ( c "grep pat"
                , do
                    "No file operand: standard input. From a terminal this looks like a hang — it is not, it is waiting for you to type. "
                    k "C-d"
                    " ends it, "
                    k "C-c"
                    " aborts it."
                )
            ,
                ( c "grep -r pat"
                , do
                    "No file operand "
                    em_ "and"
                    " recursive: grep searches the working directory. This is the one case where a missing operand does not mean stdin, and it is a relatively recent convenience."
                )
            ]
        sh
            [ "$ grep root /etc/passwd"
            , "root:x:0:0:Super User:/root:/bin/bash"
            , "$ echo $?"
            , "0"
            , "$ grep nosuchuser /etc/passwd"
            , "$ echo $?"
            , "1"
            , "$ grep root /etc/shadow"
            , "grep: /etc/shadow: Permission denied"
            , "$ echo $?"
            , "2"
            ]
        p_ $ do
            "Three invocations that look almost identical on screen — one printed a line, two printed nothing much — and three completely different answers to the question “did that work?”."
        tip $ do
            p_ $ do
                "A file operand of "
                c "-"
                " means standard input, so you can mix a pipe with real files: "
                c "gzip -cd old.log.gz | grep -H pat - current.log"
                ". grep labels the piped one "
                c "(standard input)"
                ", which is ugly; Day 6 shows you "
                opt "--label"
                " to fix that."

    block "The status is the only output a script can trust" $ do
        p_ $ do
            "Get into the habit now, because it is nearly impossible to retrofit. Whenever a grep prints nothing, type "
            c "echo $?"
            " before you type anything else. You are training yourself to see the difference between "
            c "1"
            " and "
            c "2"
            ", and that difference is where broken shell scripts come from."
        gotcha $ do
            p_ $ do
                "The status is about "
                em_ "lines selected"
                ", not about files. "
                c "grep pat a.txt b.txt"
                " exits "
                c "0"
                " if a single line in either file matched. There is no status that means “matched in every file”, and no status that means “matched in exactly one”. If you need those, you are counting, and counting is "
                c "-c"
                " and "
                c "-l"
                " on Day 5."
        p_ $ do
            "Two smaller facts that fall out of the same model. grep always terminates the lines it writes, so a file whose last line lacks a newline comes back with one added. And grep never modifies its input — there is no in-place mode, no "
            c "-i"
            " in the "
            c "sed"
            " sense. The "
            c "-i"
            " you are thinking of means "
            em_ "ignore case"
            ", and it is the first thing on Day 2."

    block "Knowing which grep you are running" $ do
        p_ $ do
            "This course is checked against GNU grep 3.12. Other greps exist and differ: BSD and macOS ship a different implementation, "
            c "busybox grep"
            " is a subset, and several modern replacements install themselves under names that look familiar."
        sh
            [ "$ grep -V | head -1"
            , "grep (GNU grep) 3.12"
            ]
        gotcha $ do
            p_ $ do
                "On most distributions "
                c "grep"
                " in an interactive shell is not the binary — it is an alias. Fedora and friends ship "
                c "/etc/profile.d/colorgrep.sh"
                ", which sets "
                c "alias grep='grep --color=auto'"
                ". That is why your interactive greps are coloured and the ones in your scripts are not, and it is why "
                c "type grep"
                " is worth running once on any machine where grep is behaving strangely."

    block "Today's habit" $ do
        p_ $ do
            "Start "
            c "~/grep-recipes.sh"
            " today. It is this course's substitute for a config file, because grep has none: no dotfile, no rc, and "
            c "GREP_OPTIONS"
            " was removed years ago — 3.12 ignores it without so much as a warning. What you accumulate instead is invocations, each with the reason written above it."
        cfg
            [ "# ~/grep-recipes.sh - not sourced, just read. Copy lines out of it."
            , "#"
            , "# Day 1: the three statuses. 0 = selected something, 1 = selected"
            , "# nothing, 2 = could not do the job. Only 2 is ever a bug."
            , "grep -q PATTERN FILE; echo $?"
            ]

cheat :: Html ()
cheat =
    cfg
        [ "grep PAT FILE          # one file  - no filename prefix on output"
        , "grep PAT FILE1 FILE2   # two files - filename prefix appears, unasked"
        , "grep PAT               # no operand - reads stdin (looks like a hang)"
        , "grep -r PAT            # no operand + -r - reads the working directory"
        , "cmd | grep PAT -       # '-' is stdin as a file operand, mixable"
        , "grep -- -v FILE        # '--' ends options; the pattern is literally -v"
        , ""
        , "# exit status - the output you are not reading"
        , "0   at least one line selected"
        , "1   no line selected; nothing went wrong"
        , "2   error (unreadable file, bad pattern). Only this one is a bug."
        , "echo $?                # type this every time grep prints nothing"
        ]
