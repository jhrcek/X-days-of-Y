module Course.Day.D09 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 9
        , dayTitle = "grep in a pipeline"
        , daySubtitle = "Exit status as control flow, NUL as a separator, and the ways a script gets this wrong."
        , dayMinutes = 35
        , dayLevel = "advanced"
        , dayManRef = "EXIT STATUS; OPTIONS: -Z, -z, --line-buffered; EXAMPLE"
        , dayTags = ["exit status", "-Z xargs -0", "set -e"]
        , dayGoals =
            [ "write a grep conditional that distinguishes “no match” from “could not read the file”"
            , "handle file names containing spaces, quotes and newlines without thinking about quoting"
            , "explain why a grep in a " <> c "set -e" <> " script aborts it, and what to write instead"
            ]
        , dayDiagram = Just d9diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("if grep -q PAT f; then", "The correct predicate form. No output, stops at the first match.")
            , ("grep -q PAT f || [ $? -eq 1 ]", "Succeed on “no match”, still fail on a genuine error.")
            , ("grep -rlZ PAT . | xargs -0 CMD", "NUL-separated file names, safe for every legal name.")
            , ("find . -name '*.c' -print0 | xargs -0 grep -Hn PAT", "When the filter needs directories, not just base names.")
            , ("${PIPESTATUS[0]}", "bash: the status of the first command in the pipeline, not the last.")
            , ("ps aux | grep '[s]shd'", "The bracket trick: the pattern no longer matches its own command line.")
            ]
        , dayOpts =
            [ ("-Z, --null", "Write a NUL after each file name instead of a newline. Pairs with " <> c "xargs -0" <> ".")
            , ("-z, --null-data", "Treat " <> em_ "input and output" <> " lines as NUL-terminated. Not the same option as " <> c "-Z" <> ".")
            , ("--line-buffered", "Flush after every output line. Costs throughput; needed when feeding a live tail.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Write the predicate properly once: " <> c "if grep -q '^root:' /etc/passwd; then echo found; fi" <> ". No " <> c "> /dev/null" <> ", no " <> c "wc -l" <> ", no " <> c "[ -n ... ]" <> "."
            , "Break a script on purpose: " <> c "bash -c 'set -e; grep zzz /etc/passwd; echo REACHED'" <> ". " <> c "REACHED" <> " never prints, and the script exits 1 — because “no match” is a non-zero status and " <> c "set -e" <> " cannot tell it from a failure."
            , "Fix it two ways and see the difference: append " <> c "|| true" <> " (hides genuine errors too) and then " <> c "|| [ $? -eq 1 ]" <> " (hides only “no match”). The second is what you want."
            , "Watch SIGPIPE: " <> c "grep -o . bigfile | head -2 > /dev/null; echo ${PIPESTATUS[0]}" <> " prints " <> c "141" <> ", not 0 or 1. That is 128+13, grep being killed when " <> c "head" <> " closed the pipe — normal, and not an error."
            , "Make a file name that breaks naive scripts: " <> c "mkdir nl && printf 'needle\\n' > $'nl/we\\nird.txt'" <> ". Now " <> c "grep -rl needle nl" <> " prints what looks like two files. Then " <> c "grep -rlZ needle nl | xargs -0 grep -c needle" <> " handles it correctly."
            , "Try the bracket trick: " <> c "ps aux | grep sshd" <> " then " <> c "ps aux | grep '[s]shd'" <> ". The second returns one fewer line, because the pattern " <> c "[s]shd" <> " does not match the literal text " <> c "[s]shd" <> " in grep's own command line."
            , "On your own work: find the grep in one of your scripts whose status is being thrown away — in a pipeline, or after a " <> c "$(...)" <> " — and decide deliberately whether that is acceptable."
            , "Add to " <> c "~/grep-recipes.sh" <> " the three-way status check, as a shell function you can paste into a script."
            ]
        , dayQuiz =
            [
                ( "A deployment script starts with "
                    <> c "set -euo pipefail"
                    <> ". Halfway down there is "
                    <> c "grep -c WARN build.log"
                    <> " purely for the log output. The build is clean, and the deployment aborts."
                , do
                    p_ $ do
                        "A clean build means no "
                        c "WARN"
                        " lines, which means grep exits "
                        c "1"
                        ", which "
                        c "set -e"
                        " treats as a fatal error. The script is behaving exactly as written: grep's “I found nothing” and “I failed” are the same thing to the shell, because the shell only sees non-zero."
                    p_ $ do
                        "The blunt fix is "
                        c "|| true"
                        ", which also swallows a genuinely unreadable file. The honest fix keeps the distinction: "
                        c "grep -c WARN build.log || [ $? -eq 1 ]"
                        ". This is the single most common way grep breaks a CI pipeline, and it always shows up on the day everything is working."
                )
            ,
                ( "Why does "
                    <> c "grep -rl TODO . | xargs rm"
                    <> " occasionally delete the wrong file, and why does adding quotes not fix it?"
                , do
                    p_ $ do
                        "Because "
                        c "-l"
                        " separates file names with newlines, and a file name may legally contain a newline — along with spaces, quotes, backslashes and almost everything else. "
                        c "xargs"
                        " then splits on whitespace and unquotes what it finds, so one file called "
                        c "we\\nird.txt"
                        " arrives as two names, neither of which exists, and a file called "
                        c "a b.txt"
                        " arrives as "
                        c "a"
                        " and "
                        c "b.txt"
                        "."
                    p_ $ do
                        "Quoting cannot help because the damage is done before your quotes are read: the ambiguity is in the byte stream between the two processes. The fix is to change the separator to the one byte a file name can never contain — "
                        c "grep -rlZ TODO . | xargs -0 rm"
                        ". That is the entire reason "
                        c "-Z"
                        ", "
                        c "find -print0"
                        " and "
                        c "xargs -0"
                        " exist."
                )
            ,
                ( "A monitoring command is "
                    <> c "tail -F app.log | grep ERROR | while read l; do alert \"$l\"; done"
                    <> ". Errors appear in the log immediately but alerts arrive minutes late, in bursts."
                , do
                    p_ $ do
                        "grep's standard output is a pipe, not a terminal, so the C library buffers it in blocks of a few kilobytes. grep is matching your lines the instant they arrive and then sitting on them until the buffer fills or the process ends."
                    p_ $ do
                        opt "--line-buffered"
                        " makes grep flush after each output line and the bursts disappear. The manual warns it “can cause a performance penalty”, which is true and irrelevant here — you are processing a handful of lines a minute. Use it whenever grep sits in the middle of a live pipeline, and leave it off when grep is processing a file as fast as it can."
                )
            ,
                ( c "ps aux | grep sshd"
                    <> " always shows one extra line that is the grep itself. Why does "
                    <> c "ps aux | grep '[s]shd'"
                    <> " not, given that it matches the same processes?"
                , do
                    p_ $ do
                        "Both commands start at the same time, so "
                        c "ps"
                        " sees grep's command line — which contains the pattern you typed. In the first case the literal text "
                        c "sshd"
                        " is in that command line, so it matches itself."
                    p_ $ do
                        "In the second, grep's command line contains the characters "
                        c "[s]shd"
                        ", while the pattern "
                        c "[s]shd"
                        " matches the text "
                        c "sshd"
                        " — a bracket expression of one character followed by three literals. The pattern and the text it matches are different strings, so the self-match disappears. It is a genuinely clever hack, and "
                        c "pgrep"
                        " is the tool that makes it unnecessary."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d9diagram :: Diagram
d9diagram =
    (diagram
        "A grep invocation yields an exit status that a shell conditional branches on, and prints file names; a file name may contain a newline but can never contain a NUL byte, which is why -Z exists."
        body'
    )
        { dgCaption = do
            "Two independent facts make grep safe in a script, and both are about what the "
            em_ "next"
            " process can see. The status is the only thing a conditional — or "
            c "set -e"
            " — ever looks at, so “found nothing” and “could not read it” must be told apart deliberately. And the dashed aspect is the whole justification for "
            c "-Z"
            ", "
            c "find -print0"
            " and "
            c "xargs -0"
            ": a NUL is the one byte that cannot appear inside a name, so it is the only unambiguous separator."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  inv   [label=\"a grep invocation\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  st    [label=\"an exit status\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  cond  [label=\"a shell conditional\\nif, &&, set -e\", fillcolor=\"#f4efe6\"];"
            , "  fname [label=\"a file name\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  nl    [label=\"the newline\"];"
            , "  nul   [label=\"the NUL byte\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  inv   -> st    [label=\"  yields\"];"
            , "  cond  -> st    [label=\"  branches on\"];"
            , "  inv   -> fname [label=\"  can print\"];"
            , "  inv   -> nul   [label=\"  separates with, under -Z\"];"
            , "  fname -> nl    [label=\"  may contain\"];"
            , "  fname -> nul   [label=\"  can never contain  \", style=dashed, constraint=false];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "In a script, the output is not the answer" $ do
        p_ [class_ "lede"] $ do
            "Interactively, grep's job is to print lines you read. In a script it usually has a different job: to answer a question, or to hand a list of file names to something else. Both of those go wrong in ways that are invisible until the day they matter, and both were set up on Day 1."
        fig

    block "The status, and set -e" $ do
        p_ $ do
            "Three statuses, from Day 1: "
            c "0"
            " selected something, "
            c "1"
            " selected nothing, "
            c "2"
            " something went wrong. The shell collapses all of that into “zero or non-zero”, which is fine for a deliberate "
            c "if"
            " and catastrophic under "
            c "set -e"
            "."
        sh
            [ "$ bash -c 'set -e; grep zzz /etc/passwd; echo REACHED'"
            , "$ echo $?"
            , "1"
            ]
        p_ $ do
            c "REACHED"
            " never printed. The grep was there to report a count, found nothing to report, and took the script down with it. This is the most common way grep breaks a CI pipeline, and it surfaces on the first clean build rather than on a broken one."
        defs
            [
                ( c "... || true"
                , "Swallows everything, including a missing or unreadable file. Quick, and quietly wrong."
                )
            ,
                ( c "... || [ $? -eq 1 ]"
                , "Succeeds only on “no match”. A real error still propagates. This is the one to memorise."
                )
            ,
                ( c "if grep -q ...; then"
                , do
                    "Best of all when you only want a yes or no: "
                    c "set -e"
                    " never fires on the condition of an "
                    c "if"
                    ", and "
                    c "-q"
                    " stops reading at the first match."
                )
            ]
        p_ "When you need all three answers, spell them out:"
        cfg
            [ "grep -q ERROR \"$log\""
            , "case $? in"
            , "  0) alert \"errors found\" ;;"
            , "  1) : ;;                     # clean - nothing to do"
            , "  *) die \"cannot read $log\" ;;"
            , "esac"
            ]
        gotcha $ do
            p_ $ do
                "A grep inside a pipeline hands you the "
                em_ "last"
                " command's status, not grep's. "
                c "grep pat file | wc -l"
                " succeeds whether or not the file exists. In bash, "
                c "${PIPESTATUS[0]}"
                " recovers it, and "
                c "set -o pipefail"
                " makes the pipeline fail if any stage does — at the cost of now failing on “no match” as well."
        note $ do
            p_ $ do
                "A fourth status you will meet: "
                c "141"
                ". "
                c "grep pattern bigfile | head -5"
                " leaves grep writing into a closed pipe, so it dies of "
                c "SIGPIPE"
                " and the shell reports 128+13. That is normal and healthy — it is how "
                c "head"
                " stops the producer — but under "
                c "pipefail"
                " it will fail your script."

    block "The one byte a file name cannot contain" $ do
        p_ $ do
            "A Unix file name may contain every byte except "
            c "/"
            " and NUL. In particular it may contain spaces, quotes, backslashes, and newlines. So a newline-separated list of file names is ambiguous, and no amount of quoting downstream can repair it."
        sh
            [ "$ printf 'needle\\n' > $'nl/we\\nird.txt'"
            , "$ grep -rl needle nl"
            , "nl/we"
            , "ird.txt"
            , "$ grep -rlZ needle nl | xargs -0 grep -c needle"
            , "1"
            ]
        p_ $ do
            "One file, printed as what looks like two. "
            c "-Z"
            " writes a NUL after each file name instead of a newline, and "
            c "xargs -0"
            " splits on NUL, so the ambiguity cannot arise. Use them together as a unit, always, even on file names you believe are tame."
        gotcha $ do
            p_ $ do
                c "-Z"
                " and "
                c "-z"
                " are different options and the similarity is unfortunate. "
                c "-Z"
                " (capital) changes the separator after "
                b_ "file names in the output"
                ". "
                c "-z"
                " (lower case) changes what counts as a "
                b_ "line in the input and the output"
                " — NUL-terminated rather than newline-terminated. Pass "
                c "-z"
                " to an ordinary text file and the entire file becomes one enormous line."
        p_ $ do
            c "-z"
            " has one genuinely common use, which is matching across newlines: with NUL as the terminator, "
            c "."
            " and "
            c "\\n"
            " stop being special to the line-splitter, so a pattern can span lines. That is mostly a "
            c "-P"
            " technique and it is tomorrow's page."
        tip $ do
            p_ $ do
                "When the file filter needs to know about directories — anything Day 7's base-name globs cannot express — put "
                c "find"
                " in front and keep the NUL discipline all the way through:"
        sh
            [ "$ find src -name '*.c' -not -path '*/generated/*' -print0 \\"
            , ">   | xargs -0 -r grep -Hn TODO"
            ]
        p_ $ do
            "The "
            c "-r"
            " on xargs matters: without it, an empty list still runs the command once, with no file operands, at which point grep reads standard input and appears to hang."

    block "Buffering, and live pipelines" $ do
        p_ $ do
            "When grep's output is a terminal it is line-buffered; when it is a pipe it is block-buffered, because that is what the C library does. In a batch pipeline this is what you want. In a live one it looks like grep has stopped working."
        sh
            [ "$ tail -F app.log | grep --line-buffered ERROR | while read l; do alert \"$l\"; done"
            ]
        p_ $ do
            "Without "
            opt "--line-buffered"
            " the alerts arrive in bursts of several kilobytes. With it, immediately. The performance penalty the manual mentions is real for bulk work and irrelevant for a live tail."

    block "Today's habit" $ do
        p_ $ do
            "Two reflexes. When grep is answering a question, use "
            c "-q"
            " and handle status "
            c "2"
            " separately from status "
            c "1"
            ". When grep is producing file names for another program, use "
            c "-Z"
            " and "
            c "xargs -0"
            " — not sometimes, always."
        cfg
            [ "# ~/grep-recipes.sh"
            , "#"
            , "# Day 9: the three-way check. 'no match' is not an error; unreadable is."
            , "grep_check() {"
            , "  grep -q \"$1\" \"$2\""
            , "  case $? in"
            , "    0) return 0 ;;"
            , "    1) return 1 ;;"
            , "    *) echo \"grep: cannot read $2\" >&2; exit 2 ;;"
            , "  esac"
            , "}"
            , ""
            , "# Day 9: survives spaces, quotes and newlines in file names. Always."
            , "grep -rlZ PATTERN . | xargs -0 -r sed -i 's/old/new/g'"
            , ""
            , "# Day 9: grep in a live pipeline needs --line-buffered or it looks dead."
            , "tail -F app.log | grep --line-buffered ERROR"
            ]

cheat :: Html ()
cheat =
    cfg
        [ "if grep -q PAT f; then ...       # the predicate form; set -e never fires here"
        , "grep PAT f || [ $? -eq 1 ]       # 'no match' is fine, a real error still fails"
        , "grep PAT f || true               # swallows real errors too - usually wrong"
        , "#   set -e + a grep that matches nothing = your script exits. The classic."
        , "#   in a pipeline you get the LAST status: use ${PIPESTATUS[0]} in bash."
        , "#   status 141 = SIGPIPE, normal when the reader (head) quit early."
        , ""
        , "grep -rlZ PAT . | xargs -0 -r CMD   # NUL separators - the ONLY safe way"
        , "find . -name '*.c' -print0 | xargs -0 -r grep -Hn PAT"
        , "#   a file name may contain spaces, quotes and NEWLINES; never a NUL."
        , "#   xargs -r: without it an empty list still runs CMD, and grep hangs on stdin."
        , ""
        , "-Z  NUL after each FILE NAME      -z  NUL terminates each INPUT/OUTPUT LINE"
        , "--line-buffered   flush per line; needed whenever grep feeds a live pipeline"
        , "ps aux | grep '[s]shd'            # the bracket trick: no self-match"
        ]
