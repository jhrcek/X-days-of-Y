module Course.Day.D13 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 13
        , dayTitle = "Making psql write SQL"
        , daySubtitle = "Four commands that take a result set and do something other than print it."
        , dayMinutes = 30
        , dayLevel = "advanced"
        , dayManRef = "\\gexec, \\gdesc, \\crosstabview, \\watch"
        , dayTags = ["\\gexec", "\\watch", "\\crosstabview"]
        , dayGoals =
            [ "generate and run a hundred DDL statements from one query, and see them as they go"
            , "find out a query's result types without running it"
            , "keep a diagnostic query on screen while something else is happening"
            ]
        , dayDiagram = Just d13diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("\\gexec", "Run the buffer, then execute every cell of the result as SQL.")
            , ("\\gdesc", "Report the result's column names and types " <> i_ "without" <> " running it.")
            , ("\\crosstabview colV colH colD", "Pivot the result into a grid. Two columns become the axes.")
            , ("\\watch i=N c=N m=N", "Re-run the buffer every N seconds, at most N times, while it returns N rows.")
            ]
        , dayOpts =
            [ ("WATCH_INTERVAL", "Default seconds between " <> c "\\watch" <> " runs. Default 2; an explicit interval wins.")
            , ("PSQL_WATCH_PAGER", "A pager for " <> c "\\watch" <> " only. Unset by default, because ordinary pagers cannot cope.")
            ]
        , dayConfig =
            [ ConfBlock
                "Two seconds is aggressive for a query against a busy server's catalogues,\nand\
                \ five is long enough to read the result before it is replaced. An explicit\n\
                \interval on the command still wins, so this only changes the default."
                "\\set WATCH_INTERVAL 5"
            ]
        , dayDrills =
            [ "Type a query, then "
                <> c "\\gdesc"
                <> " instead of a semicolon. You now know the column types without having run \
                   \anything — useful when the query takes four minutes."
            , "Break it on purpose: "
                <> c "\\gdesc"
                <> " a query with a misspelled column. The error arrives normally, because psql \
                   \still has to ask the server to describe it."
            , "Generate DDL: "
                <> c "SELECT format('CREATE INDEX ON t(%I)', attname) FROM pg_attribute WHERE attrelid='t'::regclass AND attnum>0"
                <> ". Look at the output first, then press "
                <> c "\\gexec"
                <> "."
            , "Do the same again with "
                <> c "\\set ECHO queries"
                <> " first. Now you can see each generated statement as it runs, which is the \
                   \difference between confidence and hope."
            , "Write the destructive one and do "
                <> i_ "not"
                <> " run it: a query generating "
                <> c "DROP TABLE"
                <> " for every table matching a pattern. Read the output. Then "
                <> c "\\r"
                <> "."
            , "Pivot something: a query returning three columns, then "
                <> c "\\crosstabview"
                <> " with no arguments. Column 1 becomes the rows, column 2 the columns, column 3 \
                   \the cells."
            , "Watch something: "
                <> c "SELECT count(*) FROM pg_stat_activity"
                <> " then "
                <> c "\\watch 5"
                <> ". Start a slow query in another terminal and see it appear. "
                <> k "C-c"
                <> " to stop."
            , "Use the stop conditions: "
                <> c "\\watch i=2 m=1"
                <> " on a query that returns nothing until something happens. It ends by itself, \
                   \which makes it usable in a script rather than only at a prompt."
            ]
        , dayQuiz =
            [
                ( "You want to add an index to forty tables. Why is "
                    <> c "\\gexec"
                    <> " better than writing the forty statements, and what is the discipline that \
                       \makes it safe?"
                , do
                    p_ $ do
                        "Because the catalogue already knows which forty tables, and "
                        c "format('...%I...', relname)"
                        " quotes each identifier correctly — including the one somebody named with a \
                        \capital letter. Forty hand-written statements are forty chances to typo, \
                        \and no chance at all of noticing you missed the forty-first."
                    p_ $ do
                        "The discipline is two keystrokes: run the query with a semicolon "
                        b_ "first"
                        " and read what it produced, then recall it and press "
                        c "\\gexec"
                        ". Because "
                        c "\\gexec"
                        " on an empty buffer re-runs the last query, that costs you nothing. And \
                        \set "
                        opt "ECHO"
                        " to "
                        c "queries"
                        " so you can see each generated statement go — the manual page recommends \
                        \exactly this."
                )
            ,
                ( "Halfway through a "
                    <> c "\\gexec"
                    <> " over 200 generated statements, number 87 fails. What happens to 88 through \
                       \200?"
                , do
                    p_ $ do
                        "They run, unless "
                        opt "ON_ERROR_STOP"
                        " is set. "
                        c "\\gexec"
                        " keeps going through a failure by default, which for a batch of "
                        c "CREATE INDEX"
                        " statements is usually what you want and for a batch of migrations is \
                        \usually not."
                    p_ $ do
                        "Nor is the batch atomic: each generated statement is sent on its own, so \
                        \with autocommit on you get 199 committed changes and one failure. If you \
                        \want all-or-nothing, wrap the whole "
                        c "\\gexec"
                        " in "
                        c "BEGIN"
                        " and "
                        c "COMMIT"
                        " yourself — and then Day 8's rules take over, so the first failure aborts \
                        \the rest anyway."
                )
            ,
                ( "What can "
                    <> c "\\gexec"
                    <> " not generate, and why?"
                , do
                    p_ $ do
                        "Meta-commands, and anything containing a psql variable reference. The \
                        \generated text is sent "
                        b_ "literally to the server"
                        ", so a cell containing "
                        c "\\d mytable"
                        " or "
                        c ":schema"
                        " is a syntax error rather than a psql instruction."
                    p_ $ do
                        "That is a real constraint rather than an oversight — psql would otherwise \
                        \be executing arbitrary client-side commands out of query results, which is \
                        \a much larger surface than executing SQL. When you genuinely need \
                        \generated meta-commands, generate them into a file with "
                        c "\\g"
                        " and then "
                        c "\\i"
                        " it."
                )
            ,
                ( c "\\watch"
                    <> " with a pager set to "
                    <> c "always"
                    <> " produces nonsense. Why does psql have a separate pager variable for it?"
                , do
                    p_ $ do
                        "Because a pager expects a document that ends, and "
                        c "\\watch"
                        " produces a stream that does not. So "
                        c "PSQL_WATCH_PAGER"
                        " is consulted instead of "
                        c "PSQL_PAGER"
                        " during a watch, and it is "
                        b_ "unset by default"
                        " — no pager at all, which is why watching works out of the box."
                    p_ $ do
                        "The manual page names the tool it was added for: "
                        c "pspg --stream"
                        ", which understands psql's output format and can redraw it. If you do not \
                        \have pspg, leave the variable alone; setting it to "
                        c "less"
                        " is how you get the nonsense."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d13diagram :: Diagram
d13diagram =
    ( diagram
        "The query buffer produces a result set, which \\gdesc describes without running, \
        \\\crosstabview pivots into a grid, \\watch re-runs on a timer, and \\gexec treats cell \
        \by cell as SQL to send straight back to the server."
        body'
    )
        { dgCaption = do
            "Four commands, one shape: each takes the "
            b_ "result set"
            " and does something other than print it. The amber path is the one that changes what \
            \psql is for — "
            c "\\gexec"
            " feeds the result back to the server as SQL, which makes the catalogue a source of \
            \programs rather than a thing to read. The aspect worth remembering is that generated \
            \text goes to the server "
            i_ "literally"
            ": no meta-commands, no variable references."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  buf   [label=\"the query buffer\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  res   [label=\"a result set\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  shape [label=\"a column name\\nand type\"];\n\
        \  grid  [label=\"a crosstab grid\"];\n\
        \  cell  [label=\"a cell, read as SQL\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  srv   [label=\"the server\", fillcolor=\"#f4efe6\"];\n\
        \\n\
        \  buf   -> res   [label=\"  produces\"];\n\
        \  buf   -> shape [label=\"is described, by \\\\gdesc, as  \"];\n\
        \  res   -> grid  [label=\"  is pivoted, by \\\\crosstabview, into\"];\n\
        \  res   -> cell  [label=\"  is taken, by \\\\gexec, cell by cell as\"];\n\
        \  cell  -> srv   [label=\"  is sent literally to\"];\n\
        \  buf   -> srv   [label=\"is re-sent on a timer, by \\\\watch, to  \", style=dashed];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "The catalogue as a source of programs" $ do
        p_ [class_ "lede"] $ do
            c "\\gexec"
            " sends the buffer, then treats every cell of every row of the result as an SQL \
            \statement and runs it. One line, and the database's knowledge of itself becomes \
            \something you can act on rather than something you read and then retype."
        sh
            [ "testdb=# SELECT format('CREATE INDEX ON gx1(%I)', attname)"
            , "testdb-#   FROM pg_attribute"
            , "testdb-#  WHERE attrelid = 'gx1'::regclass AND attnum > 0"
            , "testdb-#  ORDER BY attnum"
            , "testdb-# \\gexec"
            , "CREATE INDEX"
            , "CREATE INDEX"
            ]
        p_ $ do
            "The mechanics are worth stating precisely, because they are what makes it safe or not. \
            \Rows execute in the order returned, and left to right within a row when there is more \
            \than one column. NULL cells are skipped. Each statement is subject to "
            opt "ECHO"
            ", to timing, to single-step mode — everything that applies to a statement you typed. \
            \And if one fails, the rest continue, unless "
            opt "ON_ERROR_STOP"
            " is set."
        p_ $ do
            "Two habits make the difference between a tool and a foot-gun. First, "
            b_ "run the query with a semicolon and read the output"
            " before you run it with "
            c "\\gexec"
            ". Because "
            c "\\gexec"
            " on an empty buffer re-runs the last query, that inspection is free — look, then \
            \press "
            c "\\gexec"
            " on its own. Second:"
        tip $ p_ $ do
            c "\\set ECHO queries"
            " before a "
            c "\\gexec"
            ". Every generated statement is printed as it is sent, so you can watch a hundred of \
            \them go past and stop if the shape is wrong. The manual page says the same thing in \
            \fewer words: “setting ECHO to all or queries is often advisable when using \\gexec”."
        p_ $ do
            "Use "
            c "format()"
            " with "
            c "%I"
            " for identifiers and "
            c "%L"
            " for literals rather than string concatenation. It is the server-side equivalent of \
            \yesterday's "
            c ":\"name\""
            " and "
            c ":'name'"
            ", and it is the reason a table somebody named "
            c "\"Weird Name\""
            " does not break the batch."
        gotcha $ p_ $ do
            "Generated text is sent "
            b_ "literally"
            " to the server, so it cannot be a meta-command and cannot contain a psql variable \
            \reference. A cell holding "
            c "\\d foo"
            " is a syntax error. When you really need generated meta-commands, write them to a file \
            \with "
            c "\\g out.sql"
            " and then "
            c "\\i out.sql"
            "."
        fig

    block "Asking what a query would return" $ do
        p_ $ do
            c "\\gdesc"
            " reports the column names and types of the current buffer "
            i_ "without executing it"
            ". The server still parses and plans enough to answer, so genuine errors surface \
            \normally — but no rows are read and nothing is written:"
        sh
            [ "testdb=# SELECT 1 AS a, now() AS b, ARRAY[1,2] AS c"
            , "testdb-# \\gdesc"
            , " Column |           Type           "
            , "--------+--------------------------"
            , " a      | integer"
            , " b      | timestamp with time zone"
            , " c      | integer[]"
            , "(3 rows)"
            ]
        p_ $ do
            "It answers two questions that otherwise cost you a round trip. What type did that \
            \expression actually come out as — "
            c "numeric"
            " or "
            c "double precision"
            ", "
            c "text"
            " or "
            c "varchar"
            "? And what will this four-minute reporting query give me, so I can write the "
            c "CREATE TABLE"
            " for its output now rather than after lunch?"
        note $ p_ $ do
            "Like the rest of the family it falls back to the last query when the buffer is empty, \
            \so "
            c "\\gdesc"
            " straight after a result tells you the types of what you are looking at."

    block "Two axes and a grid" $ do
        p_ $ do
            c "\\crosstabview"
            " runs the buffer and pivots the result: one output column becomes the vertical header, \
            \another the horizontal header, and a third fills the cells. With no arguments it takes \
            \column 1 as the rows and column 2 as the columns, and requires the result to have \
            \exactly three columns so that the third is unambiguous."
        sh
            [ "testdb=# SELECT first, second, first > 2 AS gt2 FROM my_table"
            , "testdb-# \\crosstabview first second"
            , " first | one | two | three | four "
            , "-------+-----+-----+-------+------"
            , "     1 | f   |     |       | "
            , "     2 |     | f   |       | "
            , "     3 |     |     | t     | "
            , "     4 |     |     |       | t"
            ]
        p_ $ do
            "Header values appear in the order the query returned them, duplicates removed — so "
            b_ "the ordering is yours to control"
            " with "
            c "ORDER BY"
            ". A fourth argument names a column of integers to sort the horizontal header by \
            \independently, which is how you get rows in one order and columns in another:"
        sh
            [ "testdb=# SELECT t1.first AS \"A\", t2.first+100 AS \"B\", t1.first*(t2.first+100) AS \"AxB\","
            , "testdb-#        row_number() over(order by t2.first) AS ord"
            , "testdb-#   FROM my_table t1 CROSS JOIN my_table t2 ORDER BY 1 DESC"
            , "testdb-# \\crosstabview \"A\" \"B\" \"AxB\" ord"
            , " A | 101 | 102 | 103 | 104 "
            , "---+-----+-----+-----+-----"
            , " 4 | 404 | 408 | 412 | 416"
            , " 3 | 303 | 306 | 309 | 312"
            , " 2 | 202 | 204 | 206 | 208"
            , " 1 | 101 | 102 | 103 | 104"
            ]
        p_ $ do
            "It is a display command, not an aggregate: if two rows land in the same cell you get \
            \an error rather than a sum. Which is the right behaviour — it means the grid you are \
            \looking at is a faithful rearrangement of the rows, and any aggregation you want is \
            \yours to write in the query."

    block "Keeping a query on the screen" $ do
        p_ $ do
            c "\\watch"
            " re-runs the buffer until you interrupt it, and it is the reason to stop reaching for "
            c "watch 'psql -c ...'"
            " in another terminal — no reconnection per run, and the whole session's settings apply:"
        sh
            [ "testdb=# SELECT count(*) FROM pg_stat_activity WHERE state = 'active'"
            , "testdb-# \\watch 5"
            , "Thu 10 Sep 2026 01:35:08 PM CEST (every 5s)"
            , ""
            , " count "
            , "-------"
            , "     3"
            , "(1 row)"
            ]
        p_ "Three stop conditions turn it from an interactive toy into something scriptable, and they can be combined:"
        defs
            [ (c "i=N" <> " or " <> c "interval=N", "seconds between runs. Bare " <> c "\\watch 5" <> " works too, for compatibility.")
            , (c "c=N" <> " or " <> c "count=N", "stop after N executions.")
            , (c "m=N" <> " or " <> c "min_rows=N", "stop as soon as the query returns fewer than N rows.")
            ]
        p_ $ do
            "So "
            c "\\watch i=2 m=1"
            " is “tell me when this starts returning something, then stop” — a poll loop in eleven \
            \characters. It also stops on its own if the query fails, which means a table being \
            \dropped under you ends the watch rather than filling the screen with errors."
        p_ $ do
            "The header line carries the "
            c "\\pset title"
            " if you have set one, then the time the run started and the interval — so "
            c "\\pset title 'Active backends'"
            " gives you a labelled monitor. And "
            opt "WATCH_INTERVAL"
            " sets the default interval for the session, with an explicit "
            c "i="
            " always winning."
        gotcha $ p_ $ do
            "Do not point a pager at a watch. psql looks at "
            c "PSQL_WATCH_PAGER"
            " rather than "
            c "PSQL_PAGER"
            " during "
            c "\\watch"
            " precisely because the two need different things — a pager expects a document that \
            \ends. It is unset by default, which is why watching works out of the box; the manual \
            \page names "
            c "pspg --stream"
            " as the tool it was added for."

    block "Today's habit" $ do
        p_ $ do
            "Next time you catch yourself about to write out a list of similar statements, write \
            \the query that generates them instead — read it, then "
            c "\\gexec"
            " it. And put "
            c "\\watch"
            " in your fingers for the next incident: a query on screen, refreshing, is worth more \
            \than five people running the same "
            c "SELECT"
            " by hand."
        p_ "Tomorrow: turning yesterday's variables and today's commands into scripts that make decisions."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Look before you \\gexec."
        " Semicolon first, read the output, then "
        c "\\gexec"
        " on the empty buffer."
    cfg
        [ "SELECT format('CREATE INDEX ON %I(%I)', c.relname, a.attname) FROM ... ;"
        , "\\gexec        -- runs every cell of the result as SQL, in order, NULLs skipped"
        , "  \\set ECHO queries    <- see each generated statement as it goes"
        , "  one failure does NOT stop the rest, unless ON_ERROR_STOP is set"
        , "  no meta-commands, no :vars: the text goes to the server LITERALLY"
        , "\\gdesc        -- column names and types, WITHOUT running the query"
        , "\\crosstabview colV colH colD [sortcolH]   -- pivot; ORDER BY controls header order"
        , "  two rows in the same cell = an error, not a sum"
        , "\\watch i=5 c=10 m=1     -- every 5s, at most 10 times, until fewer than 1 row"
        , "  stops on failure too;  \\pset title labels the header;  WATCH_INTERVAL sets the default"
        , "  PSQL_WATCH_PAGER, not PSQL_PAGER — and unset is the right value unless you have pspg"
        ]
