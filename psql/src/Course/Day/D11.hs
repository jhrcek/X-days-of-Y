module Course.Day.D11 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 11
        , dayTitle = "psql in scripts"
        , daySubtitle = "The exit code is all the caller sees, and by default a failing script does not change it."
        , dayMinutes = 35
        , dayLevel = "intermediate"
        , dayManRef = "OPTIONS (-c, -f, -X, -v, -1), EXIT STATUS, \\i, \\ir"
        , dayTags = ["-c", "-f", "exit codes"]
        , dayGoals =
            [ "make a failing SQL script actually fail, with a distinguishable exit code"
            , "choose between -c, -f and standard input from what each one does to the query buffer"
            , "include one script from another without depending on the caller's working directory"
            ]
        , dayDiagram = Just d11diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("\\i file", "Read and execute a file. The path is relative to the current directory.")
            , ("\\ir file", "The same, resolved relative to the directory of the including script.")
            , ("\\! command", "Run a shell command. With no argument, a sub-shell until you exit it.")
            ]
        , dayOpts =
            [ ("-c command", "Run one command and exit. Repeatable, and mixable with " <> c "-f" <> ".")
            , ("-f file", "Read commands from a file. Repeatable, and gives errors a file and line number.")
            , ("-X", "Skip the startup files. Every script wants this.")
            , ("-q", "No banner, no informational chatter. Same as " <> opt "QUIET" <> ".")
            , ("-v NAME=value", "Set a variable from the command line. The value is not interpolated.")
            , ("-1", "Wrap everything the " <> c "-c" <> " and " <> c "-f" <> " options do in one transaction.")
            , ("ECHO", c "none" <> " (default) / " <> c "queries" <> " (" <> c "-e" <> ") / " <> c "all" <> " (" <> c "-a" <> ") / " <> c "errors" <> " (" <> c "-b" <> ").")
            , ("-s -S", "Single-step: confirm each statement. Single-line: a newline terminates one.")
            , ("SHOW_ALL_RESULTS", "Show every result of a " <> c "\\;" <> "-combined query, not just the last. Default on.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Write a two-line file where the second line is broken. Run "
                <> c "psql -f it.sql"
                <> " and then "
                <> c "echo $?"
                <> ". It is 0. Sit with that for a moment."
            , "Run it again as "
                <> c "psql -v ON_ERROR_STOP=1 -f it.sql; echo $?"
                <> ". Now it is 3, and it stopped at the error instead of carrying on."
            , "Compare "
                <> c "psql -f it.sql"
                <> " with "
                <> c "psql < it.sql"
                <> ". Only the first puts a file name and a line number in front of the error."
            , "Break it on purpose: "
                <> c "psql -c 'SELECT 1 \\gdesc'"
                <> ". Read the syntax error, then get the same result by piping the two lines in on \
                   \standard input."
            , "Run "
                <> c "psql -c 'CREATE TABLE a(i int); SELECT nosuch;'"
                <> " and check whether "
                <> c "a"
                <> " exists. Then run it as two separate "
                <> c "-c"
                <> " flags and check again. One string is one transaction."
            , "Add "
                <> c "-a"
                <> " to a script run and watch every input line echo. Then "
                <> c "-b"
                <> ", which prints only the statements that failed — the setting worth having in \
                   \a cron job's log."
            , "Put a "
                <> c "\\ir"
                <> " in a script inside a subdirectory, run it from somewhere else, and then change \
                   \it to "
                <> c "\\i"
                <> " and watch it break."
            , "Go and add "
                <> c "-X -v ON_ERROR_STOP=1"
                <> " to the psql invocations in your own scripts. That is today's real work, and it \
                   \takes five minutes."
            ]
        , dayQuiz =
            [
                ( "Your migration script has a typo halfway through. psql prints an error, runs the \
                  \rest of the file, and exits 0. CI goes green. What did you leave out?"
                , do
                    p_ $ do
                        opt "ON_ERROR_STOP"
                        ". By default psql carries on after an error and exits 0 regardless — the \
                        \exit status reflects whether "
                        i_ "psql"
                        " worked, not whether your SQL did. Set it and psql stops at the first \
                        \error and exits 3."
                    p_ $ do
                        "Three is deliberately not 1. One means psql itself failed — bad flag, \
                        \missing file, out of memory. Two means the connection went bad. Three means \
                        \“your SQL was wrong”, and a wrapper that wants to retry on 2 and give up on \
                        \3 can tell the difference. Note also that "
                        c "psql -c"
                        " does exit 1 on a SQL error even without "
                        opt "ON_ERROR_STOP"
                        ", so the two ways of running a statement do not behave the same — one more \
                        \reason to standardise on "
                        c "-f"
                        "."
                )
            ,
                ( "Why can you not write "
                    <> c "psql -c '\\timing on'"
                    <> " followed by SQL in the same "
                    <> c "-c"
                    <> ", when the same two lines work on standard input?"
                , do
                    p_ $ do
                        "Because a "
                        c "-c"
                        " string never enters the query buffer. It is handed to the server as a \
                        \single request, so it has to be either pure SQL or one whole backslash \
                        \command that psql handles itself. There is nothing in between for a \
                        \meta-command to act on."
                    p_ $ do
                        "Three ways round it, in increasing order of sanity: repeat the flag ("
                        c "psql -c '\\timing on' -c 'SELECT 1'"
                        "), pipe on standard input, or put it in a file and use "
                        c "-f"
                        ". Anything longer than a one-liner belongs in a file, because that is also \
                        \the only form that gives you line numbers in the error messages."
                )
            ,
                ( c "psql -1 -f migrate.sql"
                    <> " with a failing statement in the middle: does anything land, and does the \
                       \exit code tell you?"
                , do
                    p_ $ do
                        "Nothing lands, and the exit code does "
                        b_ "not"
                        " tell you unless you also set "
                        opt "ON_ERROR_STOP"
                        ". The manual page reads as though the flag were needed for the rollback — \
                        \it says a "
                        c "ROLLBACK"
                        " is sent “if any of the commands fails and the variable ON_ERROR_STOP was \
                        \set” — but the server has already aborted the transaction, so the "
                        c "COMMIT"
                        " psql sends is a rollback in either case."
                    p_ $ do
                        "What "
                        opt "ON_ERROR_STOP"
                        " actually buys you with "
                        c "-1"
                        " is the exit code 3 and stopping at the first error rather than trying \
                        \every remaining statement against an aborted transaction. Use both \
                        \together, always."
                )
            ,
                ( c "\\i"
                    <> " versus "
                    <> c "\\ir"
                    <> ": your build works when run from the repository root and fails from anywhere \
                       \else. Which one is in the file?"
                , do
                    p_ $ do
                        c "\\i"
                        ", which resolves its argument relative to the "
                        b_ "current working directory"
                        " of the psql process. So "
                        c "\\i sub/inner.sql"
                        " inside "
                        c "sub/mid.sql"
                        " looks for "
                        c "./sub/inner.sql"
                        " wherever you happened to be standing."
                    p_ $ do
                        c "\\ir"
                        " ("
                        c "\\include_relative"
                        ") resolves relative to the directory of the script doing the including, \
                        \which is what a set of SQL files that reference each other actually wants. \
                        \Interactively the two are identical, which is why the bug only ever shows \
                        \up in CI."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d11diagram :: Diagram
d11diagram =
    ( diagram
        "A psql invocation can carry -c command strings and -f files, or otherwise reads standard \
        \input; files and standard input are fed through the query buffer while a -c string \
        \bypasses it; the -1 flag wraps the whole invocation in one transaction, and the \
        \invocation ends with an exit code."
        body'
    )
        { dgCaption = do
            "The aspect that explains most of today is "
            c "-c"
            b_ " bypassing the query buffer"
            ": that is why you cannot mix SQL and meta-commands in one "
            c "-c"
            ", and why a multi-statement "
            c "-c"
            " string is a single request and so a single transaction. The amber box is the only \
            \thing the caller ever sees — 0, 1, 2 or 3 — and by default an error in your SQL does \
            \not change it."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  inv   [label=\"a psql invocation\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  cflag [label=\"a -c command string\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  fflag [label=\"a -f file\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  sin   [label=\"standard input\"];\n\
        \  buf   [label=\"the query buffer\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  tx    [label=\"one transaction (-1)\"];\n\
        \  code  [label=\"an exit code\\n0 1 2 3\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  inv   -> cflag [label=\"  can carry\", style=dashed];\n\
        \  inv   -> fflag [label=\"can carry  \", style=dashed];\n\
        \  inv   -> sin   [label=\"  otherwise reads\", style=dashed];\n\
        \  fflag -> buf   [label=\"  is fed through\"];\n\
        \  sin   -> buf   [label=\"is fed through  \"];\n\
        \  cflag -> buf   [label=\"  bypasses\", style=dashed];\n\
        \  tx    -> inv   [label=\"  can wrap the whole of\"];\n\
        \  inv   -> code  [label=\"  ends with\"];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "By default, a failing script succeeds" $ do
        p_ [class_ "lede"] $ do
            "This is the most consequential default in psql, and almost nobody meets it \
            \deliberately. Run a file containing an error and psql prints the error, carries on \
            \with the rest of the file, and exits "
            b_ "0"
            ". Your CI goes green over a half-applied migration."
        sh
            [ "$ cat it.sql"
            , "SELECT 1;"
            , "SELECT nosuch;"
            , "SELECT 2;"
            , "$ psql -X -f it.sql > /dev/null; echo $?"
            , "psql:it.sql:2: ERROR:  column \"nosuch\" does not exist"
            , "0"
            , "$ psql -X -v ON_ERROR_STOP=1 -f it.sql > /dev/null; echo $?"
            , "psql:it.sql:2: ERROR:  column \"nosuch\" does not exist"
            , "3"
            ]
        why $ p_ $ do
            "The exit status answers “did psql work”, not “did your SQL work”, and for an \
            \interactive tool that is the right question — a typo at the prompt should not end your \
            \session. "
            opt "ON_ERROR_STOP"
            " is how you say you are not at a prompt. It changes two things at once: processing \
            \stops at the first error, and the exit code becomes 3."
        p_ "And 3 is a specific number rather than a generic failure, which makes the four codes worth memorising:"
        defs
            [ (c "0", "psql finished normally")
            , (c "1", "a fatal error of psql's own: bad flag, file not found, out of memory")
            , (c "2", "the connection went bad and the session was not interactive")
            , (c "3", "an error occurred in a script and " <> opt "ON_ERROR_STOP" <> " was set")
            ]
        p_ $ do
            "A wrapper can therefore retry on 2 and give up on 3, which is exactly the distinction \
            \a deployment script needs and almost never makes."
        fig

    block "Three ways in, and one of them has no buffer" $ do
        p_ $ do
            c "-c"
            " and "
            c "-f"
            " may both be repeated and mixed, and they run in the order written. When either is \
            \present psql does not read standard input at all; it does the work and exits."
        p_ $ do
            "The difference that matters is the one from Day 1. A "
            c "-f"
            " file, and standard input, go through the query buffer, so they can hold anything you \
            \could type. A "
            c "-c"
            " string "
            b_ "bypasses the buffer"
            " and is handed to the server as a single request, so it must be either pure SQL or one \
            \complete backslash command:"
        sh
            [ "$ psql -c 'SELECT 1 \\gdesc'          # ERROR: syntax error at or near \"\\\"'"
            , "$ psql -c '\\x' -c 'SELECT 1'          # fine: one backslash command per -c"
            , "$ echo '\\x \\\\ SELECT 1;' | psql        # fine: standard input has a buffer"
            ]
        gotcha $ p_ $ do
            "The single-request rule has a second consequence people meet in production. "
            c "psql -c 'A; B;'"
            " sends both statements as one request, and the server runs a multi-statement request \
            \as "
            b_ "one transaction"
            " — so if B fails, A is rolled back. Two separate "
            c "-c"
            " flags are two requests and two transactions, and A survives. Same characters, \
            \different atomicity."
        p_ $ do
            "Prefer "
            c "-f"
            " to shell redirection, too. Both work, but "
            c "-f"
            " prefixes errors with the file name and line number — "
            c "psql:it.sql:2: ERROR: ..."
            " — while "
            c "psql < it.sql"
            " gives you a bare "
            c "ERROR:"
            " and leaves you counting statements by hand."

    block "The flags every scripted invocation should carry" $ do
        p_ "Four of them, and the argument for each is short:"
        defs
            [
                ( c "-X"
                , do
                    "skip the startup files. Since 9.6 even "
                    c "-c"
                    " reads them, so without this your script inherits whatever "
                    c "AUTOCOMMIT"
                    ", "
                    c "search_path"
                    " or output format the invoking user's psqlrc happens to set."
                )
            ,
                ( c "-v ON_ERROR_STOP=1"
                , "make errors stop the script and change the exit code. See above."
                )
            ,
                ( c "-q"
                , do
                    "no banner, no “Timing is on.”, no chatter. Useful precisely because it leaves \
                    \errors alone — "
                    c "-q"
                    " silences the informational output, not the diagnostics."
                )
            ,
                ( c "-1"
                , do
                    "wrap all the "
                    c "-c"
                    " and "
                    c "-f"
                    " work in one transaction. Combine with the above, not instead of it."
                )
            ]
        p_ $ do
            "So the shape of a psql call in a script is:"
        sh
            [ "psql -X -q -v ON_ERROR_STOP=1 -1 -f migrate.sql \"$DATABASE_URL\""
            ]
        note $ p_ $ do
            "Nothing today goes into your psqlrc, and that is the point: a script passes "
            c "-X"
            ", so nothing in that file can help it. Everything a script needs must be on its own \
            \command line, which is also what makes it reproducible on somebody else's machine."
        p_ $ do
            c "-v"
            " sets any psql variable, not just the control ones, which is how you parameterise a \
            \script: "
            c "-v schema=staging"
            " and then "
            c ":\"schema\""
            " in the SQL. Day 12 is about the interpolation half of that. One limitation to \
            \remember from Day 7: "
            c "-v"
            " does not interpolate its own value, so "
            c "-v f=out-:DBNAME"
            " gives you a literal colon."

    block "Watching a script run" $ do
        p_ $ do
            opt "ECHO"
            " has four settings and each has a command-line flag, because you want different ones \
            \at different times:"
        defs
            [ (c "none", "the default. You see results and errors, and no statements.")
            , (c "all" <> " / " <> c "-a", "every non-empty input line as it is read, comments included. Loud, and the right thing when you cannot work out where a script got to.")
            , (c "queries" <> " / " <> c "-e", "each query as it is sent to the server. Quieter than " <> c "all" <> ", and the pair to " <> c "\\gexec" <> " on Day 13.")
            , (c "errors" <> " / " <> c "-b", "only the statements that failed, as a " <> c "STATEMENT:" <> " line after the error. The setting a cron job's log wants.")
            ]
        sh
            [ "$ psql -X -b -f it.sql"
            , "psql:it.sql:2: ERROR:  column \"nosuch\" does not exist"
            , "LINE 1: SELECT nosuch;"
            , "               ^"
            , "psql:it.sql:2: STATEMENT:  SELECT nosuch;"
            ]
        p_ $ do
            "Two rarer debugging aids sit alongside. "
            c "-s"
            " is single-step mode: psql prints each statement inside a banner and waits for you to \
            \press return or type "
            c "x"
            " to cancel it — genuinely useful for walking through somebody else's migration against \
            \a copy. And "
            c "-S"
            " is single-line mode, where a newline terminates a statement as a semicolon does; the \
            \manual page offers it “for those who insist on it” and then advises against it."

    block "Scripts that include scripts" $ do
        p_ $ do
            c "\\i"
            " reads a file and executes it as though typed. It is "
            c "-f"
            " from the inside, and unlike "
            c "-f"
            " it can appear in the middle of a session — which is how you build a set of SQL files \
            \that call each other. The trap is path resolution:"
        sh
            [ "$ cd project"
            , "$ psql -f sub/mid.sql          # mid.sql contains:  \\i inner.sql"
            , "in mid"
            , "psql:sub/mid.sql:2: error: inner.sql: No such file or directory"
            , ""
            , "$ psql -f sub/mid.sql          # mid.sql contains:  \\ir inner.sql"
            , "in mid"
            , "inner ran"
            ]
        p_ $ do
            c "\\i"
            " resolves relative to the process's working directory; "
            c "\\ir"
            " ("
            c "\\include_relative"
            ") resolves relative to the directory of the script doing the including. Interactively \
            \the two behave identically, which is why this only ever breaks in CI. For a set of \
            \files that reference one another, "
            c "\\ir"
            " is simply the right answer."
        tip $ p_ $ do
            "Both honour "
            opt "ON_ERROR_STOP"
            ", and it terminates every script in the stack — the included file and the one that \
            \included it. A "
            c "-"
            " as the filename reads standard input until EOF or "
            c "\\q"
            ", which lets a script hand control back to the operator for a moment."

    block "Today's habit" $ do
        p_ $ do
            "Go and look at the psql invocations in your own repository. If any of them lacks "
            c "-X -v ON_ERROR_STOP=1"
            ", it is a script that can fail silently, and fixing it takes one line each. That is \
            \the whole of today's homework and it is worth more than the rest of the week."
        p_ "Tomorrow: the advanced third begins, with the psql variable machinery that makes any of this parameterisable."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "The invocation to standardise on."
        " Every flag in it is doing something."
    cfg
        [ "psql -X -q -v ON_ERROR_STOP=1 -1 -f migrate.sql \"$DATABASE_URL\""
        , "  -X  skip psqlrc   -q  no chatter   -1  one transaction   -f  file + line numbers"
        , "exit: 0 fine | 1 psql's own error | 2 connection went bad | 3 SQL error + ON_ERROR_STOP"
        , "  WITHOUT ON_ERROR_STOP a failing -f script still exits 0.  (-c exits 1 either way.)"
        , "-c 'A; B;'      -- ONE request = ONE transaction: B fails, A is rolled back"
        , "-c A -c B       -- two requests, two transactions: A survives"
        , "-c cannot mix SQL and meta-commands: it never touches the query buffer"
        , "-a all input lines | -e queries sent | -b failed statements only (best for cron logs)"
        , "-s single-step (confirm each)      -S single-line (newline terminates)"
        , "\\i  file  -- relative to the CURRENT DIRECTORY"
        , "\\ir file  -- relative to the INCLUDING SCRIPT   <- what you want between SQL files"
        ]
