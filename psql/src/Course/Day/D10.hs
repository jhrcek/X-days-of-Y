module Course.Day.D10 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 10
        , dayTitle = "Sending output elsewhere"
        , daySubtitle = "Three channels, one of which \\o moves — and errors are not it."
        , dayMinutes = 30
        , dayLevel = "intermediate"
        , dayManRef = "\\o, \\g, \\w, \\qecho, \\warn, \\lo_*, OPTIONS (-o, -L)"
        , dayTags = ["\\o", "\\g", "pipes"]
        , dayGoals =
            [ "redirect one query's output without disturbing the next one"
            , "capture a session's results to a file and know what will be missing from it"
            , "pipe a result straight into a shell command without a temporary file"
            ]
        , dayDiagram = Just d10diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("\\o file", "Point all future query output at a file. Bare " <> c "\\o" <> " restores stdout.")
            , ("\\o |command", "Pipe all future query output to a shell command.")
            , ("\\g file", "This one query's output to a file. " <> c "\\g |cmd" <> " pipes it instead.")
            , ("\\g (opt=val ...)", "A one-shot " <> c "\\pset" <> " for this query only.")
            , ("\\qecho text", "Write to the query-output channel, so it lands in the same file.")
            , ("\\warn text", "Write to standard error, so it never lands in the file.")
            , ("\\w file", "Write the query " <> i_ "buffer" <> " — not its output — to a file.")
            , ("\\lo_import file", "Store a file as a large object. Also " <> c "\\lo_export" <> ", " <> c "\\lo_list" <> ", " <> c "\\lo_unlink" <> ".")
            ]
        , dayOpts =
            [ ("-o file", "Send all query output to a file, decided at start-up.")
            , ("-L file", "Log each query " <> i_ "and" <> " its output to a file, as well as to the normal destination.")
            , ("tuples_only", "Data only — no header, no footer, no title. " <> c "-t" <> " on the command line.")
            , ("fieldsep recordsep csv_fieldsep", "Separators for unaligned and CSV output; " <> c "-F" <> ", " <> c "-R" <> ", " <> c "-z" <> ", " <> c "-0" <> ".")
            ]
        , dayConfig =
            [ ConfBlock
                "psql's default pager wraps long lines, which turns a wide result into an\n\
                \unreadable ribbon. -S chops them instead, so a wide table scrolls sideways\nwith\
                \ the arrow keys; -X leaves the screen contents alone on exit, and -F skips\nthe\
                \ pager altogether when the output already fits on one screen."
                "\\setenv PSQL_PAGER 'less -SXF'"
            ]
        , dayDrills =
            [ "Run a query, then "
                <> c "\\g /tmp/one.txt"
                <> " on the next one. Check that the query after "
                <> i_ "that"
                <> " came back to your screen on its own."
            , "Now "
                <> c "\\o /tmp/many.txt"
                <> ", run three queries, and "
                <> c "\\o"
                <> " to stop. All three are in the file — that is the difference between the two \
                   \commands."
            , "Pipe without a temporary file: "
                <> c "SELECT * FROM sometable"
                <> " then "
                <> c "\\g |wc -l"
                <> ". Then try "
                <> c "\\g |column -t -s'|'"
                <> " with unaligned output."
            , "One-shot formatting: run a query, then "
                <> c "\\g (format=csv tuples_only=on)"
                <> ". Run it again with a bare "
                <> c "\\g"
                <> " and confirm your session settings are untouched."
            , "Break it on purpose: "
                <> c "\\o /tmp/log.txt"
                <> ", run a query that fails, "
                <> c "\\o"
                <> ", and look at the file. The error is not in it — it went to standard error, \
                   \which "
                <> c "\\o"
                <> " does not touch."
            , "Now do the same but annotate it: "
                <> c "\\qecho == section one =="
                <> " inside the redirect. Compare with "
                <> c "\\echo"
                <> ", which stays on your terminal."
            , "Build a report from the shell in one line: "
                <> c "psql -X -A -t -F, -c 'SELECT ...' > out.csv"
                <> ". Four flags, and no meta-commands at all."
            , "Next time you need to hand somebody a result, use "
                <> c "\\g |xclip -selection clipboard"
                <> " or your platform's equivalent. It is the shortest path from query to paste."
            ]
        , dayQuiz =
            [
                ( "You capture a whole session with "
                    <> c "\\o session.log"
                    <> " to send to a colleague. The log looks complete and contains no sign of the \
                       \failure you were investigating. What is missing, and why?"
                , do
                    p_ $ do
                        "Error messages. The manual page defines “query results” for "
                        c "\\o"
                        " as tables, command responses, notices and the output of database-querying \
                        \backslash commands — and then says explicitly “but not error messages”. \
                        \Those go to standard error, which "
                        c "\\o"
                        " does not touch."
                    p_ $ do
                        "Two ways to get everything. Redirect at the shell instead — "
                        c "psql ... > session.log 2>&1"
                        " — or use "
                        c "-L"
                        ", which logs each query alongside its output. Neither is what people reach \
                        \for, which is why so many pasted logs end just before the interesting part."
                )
            ,
                ( "What is the difference between "
                    <> c "\\o file"
                    <> " and "
                    <> c "\\g file"
                    <> ", and which one do you almost always want?"
                , do
                    p_ $ do
                        c "\\o"
                        " is a mode: it redirects "
                        b_ "all future"
                        " query output until you turn it off with a bare "
                        c "\\o"
                        ". "
                        c "\\g file"
                        " is one-shot: it sends "
                        i_ "this"
                        " query's output to the file and the next query goes back to your screen."
                    p_ $ do
                        "The one-shot form is almost always what you meant, because the failure \
                        \mode of "
                        c "\\o"
                        " is silent — you forget to turn it off, run six more queries, and wonder \
                        \why the screen has gone quiet. "
                        c "\\g"
                        " has a further trick "
                        c "\\o"
                        " does not: "
                        c "\\g (format=csv tuples_only=on)"
                        " applies printing options for that query alone."
                )
            ,
                ( c "\\echo"
                    <> ", "
                    <> c "\\qecho"
                    <> " and "
                    <> c "\\warn"
                    <> " all print text. Which goes where?"
                , do
                    p_ "Three commands for three channels, and that is the whole reason there are three:"
                    defs
                        [ (c "\\echo", "psql's standard output. Not affected by \\o, so it stays on your screen.")
                        , (c "\\qecho", "the query-output channel — so it lands in whatever \\o is pointing at.")
                        , (c "\\warn", "standard error. Never captured by \\o, and never mixed into piped data.")
                        ]
                    p_ $ do
                        "So "
                        c "\\qecho"
                        " is how you put headings between the results in a captured report, and "
                        c "\\warn"
                        " is how a script tells the operator something without corrupting the \
                        \output another program is about to parse."
                )
            ,
                ( "A file written with "
                    <> c "\\copy ... TO"
                    <> " has no header row and one written with "
                    <> c "\\g out.csv"
                    <> " and "
                    <> c "--csv"
                    <> " does. Why, and which is easier to control?"
                , do
                    p_ $ do
                        c "\\copy"
                        " is SQL "
                        c "COPY"
                        " underneath, so headers come from "
                        c "COPY"
                        "'s own "
                        c "HEADER"
                        " option and nothing psql prints is involved. Output written by "
                        c "\\g"
                        " or "
                        c "\\o"
                        " is psql's ordinary formatted output, so it obeys "
                        c "\\pset"
                        " — "
                        c "format"
                        ", "
                        c "tuples_only"
                        ", "
                        c "footer"
                        ", "
                        c "null"
                        " and the separators."
                    p_ $ do
                        "Which makes them good at different things. "
                        c "\\copy"
                        " gives you RFC-4180 CSV with quoting rules the server implements, and it \
                        \streams. "
                        c "\\g"
                        " gives you anything "
                        c "\\pset"
                        " can express — including a one-shot "
                        c "\\g (format=csv)"
                        " — but the "
                        c "null"
                        " string and the footer are yours to remember."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d10diagram :: Diagram
d10diagram =
    ( diagram
        "A query writes its result to the query-output channel, which is psql's standard output \
        \by default and can be pointed at a file or a pipe by \\o or \\g; a query can also \
        \produce an error message, and error messages always go to standard error."
        body'
    )
        { dgCaption = do
            "There are three channels and "
            c "\\o"
            " moves exactly one of them. The amber box is the consequence people meet at the worst \
            \moment: "
            b_ "error messages never follow the redirection"
            ", so a session captured with "
            c "\\o"
            " contains the results and none of the failures. When you want everything, redirect at \
            \the shell with "
            c "2>&1"
            " or use "
            c "-L"
            "."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  q     [label=\"a query\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  qout  [label=\"the query-output channel\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  out   [label=\"psql's standard output\"];\n\
        \  dest  [label=\"a file or a pipe\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  msg   [label=\"an error message\"];\n\
        \  errch [label=\"psql's standard error\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  q    -> qout  [label=\"  writes its result to\"];\n\
        \  qout -> out   [label=\"  is, by default,\"];\n\
        \  qout -> dest  [label=\"is pointed at, by \\\\o or \\\\g,  \", style=dashed];\n\
        \  q    -> msg   [label=\"can produce  \", style=dashed];\n\
        \  msg  -> errch [label=\"  always goes to\"];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "A mode and a one-shot" $ do
        p_ [class_ "lede"] $ do
            "Two commands send query output somewhere other than your screen, and the difference \
            \between them is how long the decision lasts. "
            c "\\o"
            " is a mode that stays on until you turn it off. "
            c "\\g"
            " applies to the query in front of it and nothing else. The one-shot is almost always \
            \what you meant."
        sh
            [ "testdb=# SELECT * FROM my_table"
            , "testdb-# \\g /tmp/one.txt          -- this query only"
            , "testdb=# SELECT 1;                 -- back on screen, automatically"
            , ""
            , "testdb=# \\o /tmp/many.txt         -- a mode: everything from here on"
            , "testdb=# SELECT 1;"
            , "testdb=# SELECT 2;"
            , "testdb=# \\o                       -- and off again"
            ]
        p_ $ do
            "Both take a pipe instead of a filename, and then the entire rest of the line is handed \
            \to the shell verbatim — no variable interpolation, no backquote expansion, exactly as \
            \with "
            c "\\copy"
            " yesterday:"
        sh
            [ "testdb=# SELECT * FROM my_table"
            , "testdb-# \\g |wc -l"
            , "8"
            ]
        p_ $ do
            "Which is the shortest path from a query result to anything your shell can do — "
            c "\\g |column -t -s'|'"
            ", "
            c "\\g |jq ."
            " over a JSON column, "
            c "\\g |xclip -selection clipboard"
            " to hand somebody a table."
        fig

    block "The trick \\o does not have" $ do
        p_ $ do
            "Parentheses immediately after "
            c "\\g"
            " hold a space-separated list of "
            c "\\pset"
            " assignments that apply to this query alone. No spaces around the "
            c "="
            ", and spaces required between clauses:"
        sh
            [ "testdb=# SELECT * FROM my_table"
            , "testdb-# \\g (format=csv tuples_only=on)"
            , "1,one"
            , "2,two"
            , "3,three"
            , "4,four"
            , "testdb=# SELECT * FROM my_table LIMIT 1;"
            , " first | second "
            , "-------+--------"
            , "     1 | one"
            , "(1 row)"
            ]
        p_ $ do
            "The session's settings are untouched — that second query is aligned again. Combine it \
            \with a destination ("
            c "\\g (format=csv) out.csv"
            ") and you have “export this one result as CSV” without changing anything you will \
            \have to change back."
        p_ $ do
            "Two relatives worth knowing. "
            c "\\gx"
            " is "
            c "\\g"
            " with "
            c "expanded=on"
            " forced, for the row that turns out to be surprising. And "
            c "\\g"
            " on an "
            i_ "empty"
            " buffer re-runs the last query, so "
            c "\\g (format=csv) out.csv"
            " straight after looking at a result on screen exports the thing you were just looking \
            \at."
        note $ p_ $ do
            "The file or pipe is written "
            i_ "only"
            " if the query succeeds and returns zero or more rows. A failed query, or one that \
            \returns no result set at all — an "
            c "UPDATE"
            ", a "
            c "CREATE TABLE"
            " — leaves the destination alone. That is why "
            c "\\g out.csv"
            " after a typo does not truncate yesterday's export."

    block "Three channels, and the one that never moves" $ do
        p_ $ do
            "psql writes to three places, and "
            c "\\o"
            " redirects one of them. What it does redirect is generous — tables, command tags like "
            c "INSERT 0 1"
            ", server notices, and the output of database-querying backslash commands such as "
            c "\\d"
            ". What it does not redirect is the part you most want when something has gone wrong:"
        gotcha $ p_ $ do
            "Error messages go to standard error and "
            c "\\o"
            " does not touch them. A session captured with "
            c "\\o session.log"
            " contains all the results and none of the failures — which is exactly the log people \
            \paste into a ticket, wondering why it ends just before the interesting part. Use "
            c "psql ... > log 2>&1"
            " at the shell, or "
            c "-L"
            "."
        p_ "The three printing commands exist precisely so you can choose a channel on purpose:"
        defs
            [ (c "\\echo", "psql's standard output. Unaffected by \\o, so it stays on your screen.")
            , (c "\\qecho", "the query-output channel — it lands in whatever \\o is pointing at.")
            , (c "\\warn", "standard error. Never captured, never mixed into piped data.")
            ]
        p_ $ do
            "So "
            c "\\qecho"
            " puts headings between the results of a captured report, and "
            c "\\warn"
            " lets a script talk to the operator without corrupting the stream another program is \
            \parsing."
        p_ $ do
            "From the command line there are two more. "
            c "-o file"
            " is "
            c "\\o"
            " decided at start-up. "
            c "-L file"
            " is different and underused: it logs each query "
            i_ "and"
            " its output to a file, in addition to the normal destination, with the query wrapped \
            \in the same "
            c "/******** QUERY *********/"
            " banners that "
            c "-E"
            " uses. It is the closest thing psql has to a transcript."

    block "Machine-readable output without meta-commands" $ do
        p_ $ do
            "When the consumer is another program, the flags matter more than the commands, because \
            \they work in a "
            c "-c"
            " one-liner where meta-commands cannot go:"
        sh
            [ "$ psql -X -A -t -F, -c 'SELECT first, second FROM my_table' > out.csv"
            , "$ psql -X --csv -c 'SELECT * FROM my_table' > proper.csv"
            , "$ psql -X -A -t -z -c 'SELECT name FROM t' | xargs -0 -n1 echo"
            ]
        defs
            [ (c "-A", "unaligned — one row per line. " <> c "\\pset format unaligned" <> ".")
            , (c "-t", "tuples only: no header, no footer, no title.")
            , (c "-F sep", "the field separator. " <> c "-z" <> " makes it a zero byte.")
            , (c "-R sep", "the record separator. " <> c "-0" <> " makes it a zero byte — for " <> c "xargs -0" <> ".")
            , (c "--csv", "proper CSV, with RFC 4180 quoting. Prefer it to " <> c "-A -F," <> ".")
            ]
        tip $ p_ $ do
            "Prefer "
            c "--csv"
            " to "
            c "-A -F,"
            " whenever a value might contain your separator. Unaligned output does nothing special \
            \when the field separator appears inside a value; CSV format quotes it. The zero-byte \
            \pair, "
            c "-z"
            " and "
            c "-0"
            ", exists for the same reason and is the safest of all if the consumer can take it."

    block "Large objects, briefly" $ do
        p_ $ do
            "Four commands for PostgreSQL's large objects, and they are here rather than on their \
            \own day because they are rare and they are all the same shape — a file on the "
            i_ "client"
            ", moved by psql, exactly like "
            c "\\copy"
            ":"
        sh
            [ "testdb=# \\lo_import '/tmp/photo.xcf' 'a picture of me'"
            , "lo_import 16456"
            , "testdb=# \\lo_list+"
            , "  ID   |  Owner   | Access privileges |   Description   "
            , "-------+----------+-------------------+-----------------"
            , " 16456 | postgres |                   | a picture of me"
            , "testdb=# \\lo_export 16456 '/tmp/out.xcf'"
            , "testdb=# \\lo_unlink 16456"
            ]
        p_ $ do
            "The comment is optional and worth always giving, because "
            c "\\lo_list"
            " is otherwise a list of numbers. The OID also lands in "
            c ":LASTOID"
            ", which is the one place that variable is still useful — after an "
            c "INSERT"
            " it is always 0 against any server since version 12."
        p_ $ do
            "As with "
            c "\\copy"
            ", the point of the psql versions is that they act as "
            i_ "you"
            ", on your filesystem; the server functions "
            c "lo_import"
            " and "
            c "lo_export"
            " act as the server, on its filesystem, and need the privileges to match."

    block "Today's habit" $ do
        p_ $ do
            "Use "
            c "\\g"
            " and stop using "
            c "\\o"
            ". Whenever you catch yourself about to write a result to a file, put the destination \
            \on the "
            c "\\g"
            " instead — it cannot be left switched on, and it takes one-shot formatting options \
            \that "
            c "\\o"
            " cannot."
        p_ "Tomorrow: running psql without a terminal at all, which is where the exit codes from Day 2 finally earn their keep."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Three channels."
        " "
        c "\\o"
        " moves one of them, and it is not the one with the errors in it."
    cfg
        [ "\\g file      -- ONE query's output to a file      \\g |cmd   -- ...to a pipe"
        , "\\g (format=csv tuples_only=on) file   -- one-shot \\pset, session untouched"
        , "\\gx          -- \\g with expanded forced          \\g on an empty buffer re-runs"
        , "\\o file      -- a MODE: everything until a bare \\o turns it off"
        , "\\w file      -- the query BUFFER, not its output"
        , "\\echo -> stdout   \\qecho -> the \\o destination   \\warn -> stderr"
        , "errors ALWAYS go to stderr: \\o never captures them. Use  > log 2>&1  or -L file"
        , "-o file      -- \\o from the command line      -L file  -- log queries AND output"
        , "-A -t -F, / --csv / -z -0     -- machine-readable, and they work inside -c"
        , "\\lo_import f 'comment'   \\lo_list+   \\lo_export oid f   \\lo_unlink oid   (:LASTOID)"
        ]
