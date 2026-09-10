module Course.Day.D09 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 9
        , dayTitle = "Bulk data with \\copy"
        , daySubtitle = "One question decides which command you need: whose filesystem is the file on?"
        , dayMinutes = 30
        , dayLevel = "intermediate"
        , dayManRef = "\\copy, and SQL COPY by contrast"
        , dayTags = ["\\copy", "COPY", "csv"]
        , dayGoals =
            [ "choose between " <> c "\\copy" <> " and SQL " <> c "COPY" <> " without thinking, from where the file lives"
            , "load a CSV and export a query result without leaving psql"
            , "explain why " <> c "\\copy" <> " is the only one of the two that never interpolates a variable"
            ]
        , dayDiagram = Just d9diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("\\copy tbl FROM 'file'", "Client-side load. psql reads the file, as you, with no server privileges.")
            , ("\\copy (query) TO 'file'", "Client-side export. A table name, or a query in parentheses.")
            , ("\\copy tbl FROM PROGRAM 'cmd'", "Run a command on the client and load its output. " <> c "TO PROGRAM" <> " pipes out.")
            , ("\\copy tbl FROM stdin", "Data rows follow, up to a line containing only " <> c "\\." <> ".")
            , ("\\copy ... TO pstdout", "psql's real stdout, ignoring " <> c "\\o" <> ". " <> c "pstdin" <> " is the input twin.")
            , ("\\copy ... FROM 'f' WHERE cond", "Filter rows as they load — the condition is evaluated server-side.")
            , ("COPY ... TO STDOUT then \\g f", "The multi-line, interpolating alternative to " <> c "\\copy" <> ".")
            ]
        , dayOpts = []
        , dayConfig = []
        , dayDrills =
            [ "Export a query: "
                <> c "\\copy (SELECT * FROM sometable) TO 'out.csv' WITH (FORMAT csv, HEADER)"
                <> ". Look at the file with "
                <> c "\\! head out.csv"
                <> "."
            , "Load it back into a new table with "
                <> c "\\copy newtable FROM 'out.csv' WITH (FORMAT csv, HEADER)"
                <> ". Two commands, no external tools."
            , "Now try the server-side version — "
                <> c "COPY sometable TO '/tmp/out.csv' CSV"
                <> " — and then look for "
                <> c "/tmp/out.csv"
                <> " on your own machine. If your server is remote, it is not there."
            , "Break it on purpose: put a non-numeric value in an integer column of your CSV and \
              \load it. The "
                <> c "CONTEXT"
                <> " line gives you the file line number and the column. Then check that "
                <> i_ "nothing"
                <> " was loaded."
            , "Load two rows inline, without a file at all: "
                <> c "\\copy t FROM stdin WITH (FORMAT csv)"
                <> ", the rows, then a line containing just "
                <> c "\\."
                <> "."
            , "Pipe out through a program: "
                <> c "\\copy (SELECT name FROM t) TO PROGRAM 'sort | head -20'"
                <> ". The sorting happens on your laptop."
            , "Break it on purpose again: "
                <> c "\\set f 'out.csv'"
                <> " then "
                <> c "\\copy t FROM :f"
                <> ". You get “:f: No such file or directory” — "
                <> c "\\copy"
                <> " does not interpolate. Then do the same job with "
                <> c "COPY t FROM STDIN"
                <> " and "
                <> c "\\g"
                <> "."
            , "Next time somebody asks you for “a CSV of that table”, do it with "
                <> c "\\copy"
                <> " rather than a script. It is one line and it needs no privileges."
            ]
        , dayQuiz =
            [
                ( "You run "
                    <> c "COPY orders TO '/tmp/orders.csv' CSV"
                    <> " against a production server and it succeeds. The file is not in your "
                    <> c "/tmp"
                    <> ". Where is it, and what would you have needed instead?"
                , do
                    p_ $ do
                        "It is in the "
                        b_ "server's"
                        " "
                        c "/tmp"
                        ", written by the operating-system user the server runs as. SQL "
                        c "COPY"
                        " with a filename is a server-side operation; the path is interpreted there \
                        \and nowhere else."
                    p_ $ do
                        c "\\copy orders TO '/tmp/orders.csv' CSV"
                        " is the client-side twin: psql opens the file, as you, on your machine, \
                        \with your permissions. It is one backslash and it is the whole difference. \
                        \That you had permission to do the server-side version at all means you are \
                        \a superuser or a member of "
                        c "pg_write_server_files"
                        ", which most people are not."
                )
            ,
                ( c "\\set f 'data.csv'"
                    <> " then "
                    <> c "\\copy t FROM :f"
                    <> " fails with “:f: No such file or directory”. Why is "
                    <> c "\\copy"
                    <> " different from every other meta-command, and what do you do instead?"
                , do
                    p_ $ do
                        "Because "
                        c "\\copy"
                        " has to hand almost all of its arguments through to SQL "
                        c "COPY"
                        " untouched, the manual page gives it special parsing: the entire remainder \
                        \of the line is the argument, and "
                        b_ "neither variable interpolation nor backquote expansion is performed"
                        ". The same exemption applies to "
                        c "\\!"
                        ", "
                        c "\\ef"
                        ", "
                        c "\\ev"
                        ", "
                        c "\\help"
                        " and the "
                        c "|command"
                        " form of "
                        c "\\g"
                        ", "
                        c "\\o"
                        " and "
                        c "\\w"
                        "."
                    p_ $ do
                        "The route round it is the manual page's own tip: "
                        c "COPY t FROM STDIN"
                        " — real SQL, which "
                        i_ "does"
                        " interpolate — dispatched with "
                        c "\\g :f"
                        ". You also get multi-line layout, which "
                        c "\\copy"
                        " cannot have because its argument stops at the end of the line."
                )
            ,
                ( "A colleague reports that "
                    <> c "\\copy"
                    <> " of a 40 GB table “took all night over the VPN” while a "
                    <> c "COPY"
                    <> " on the server took eight minutes. Is that expected?"
                , do
                    p_ $ do
                        "Entirely. "
                        c "\\copy"
                        " routes every row between the server and the client over the database \
                        \connection — that is what makes it work without privileges, and it is also \
                        \its cost. The manual page says so plainly: these operations “are not as \
                        \efficient as the SQL COPY command with a file or program data source”, and \
                        \“for large amounts of data the SQL command might be preferable”."
                    p_ $ do
                        "So the decision has two inputs, not one. Whose filesystem the file must be \
                        \on decides which command is "
                        i_ "possible"
                        "; the volume decides which is "
                        i_ "sensible"
                        ". A nightly 40 GB extract belongs on the server; a 200 000-row CSV for a \
                        \colleague belongs in "
                        c "\\copy"
                        "."
                )
            ,
                ( "Inside a script you have "
                    <> c "\\o results.txt"
                    <> " in force. You want a "
                    <> c "\\copy"
                    <> " to go to the terminal anyway. Which destination, and what happens to the "
                    <> c "COPY n"
                    <> " line?"
                , do
                    p_ $ do
                        c "pstdout"
                        " — psql's real standard output, regardless of the current "
                        c "\\o"
                        ". Plain "
                        c "stdout"
                        " means “wherever psql's query output is currently going”, which is the file."
                    p_ $ do
                        "The status line splits from the data, which is the point of the \
                        \distinction. With "
                        c "TO stdout"
                        " the "
                        c "COPY n"
                        " count is suppressed altogether, precisely so it cannot be mistaken for a \
                        \data row. With "
                        c "TO pstdout"
                        " the data goes to the terminal and the "
                        c "COPY n"
                        " goes to the query-output channel — the file."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d9diagram :: Diagram
d9diagram =
    ( diagram
        "A backslash-copy command reads and writes the client's filesystem and is implemented \
        \with COPY TO STDOUT or FROM STDIN, streaming every row over the connection; an SQL COPY \
        \naming a file reads and writes the server's filesystem and requires membership of the \
        \server-files roles."
        body'
    )
        { dgCaption = do
            "One question settles it: "
            b_ "whose filesystem is the file on?"
            " The client's, and you want "
            c "\\copy"
            ", which needs no privileges because it never asks the server to touch a file. The \
            \server's, and you want SQL "
            c "COPY"
            ", which needs a role most people do not have. The amber box is the price of the \
            \left-hand route — every row crosses the connection, which is why the manual page \
            \steers large volumes to the right-hand one."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  cp    [label=\"a \\\\copy command\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  stdio [label=\"COPY ... TO STDOUT\\nCOPY ... FROM STDIN\"];\n\
        \  cfs   [label=\"the client's filesystem\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  conn  [label=\"the connection\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  sql   [label=\"COPY ... TO 'file'\\nCOPY ... FROM 'file'\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  sfs   [label=\"the server's filesystem\", fillcolor=\"#f4efe6\"];\n\
        \  role  [label=\"a pg_*_server_files role\", fillcolor=\"#f4efe6\"];\n\
        \\n\
        \  cp    -> cfs   [label=\"  reads and writes\"];\n\
        \  cp    -> stdio [label=\"  is implemented with\"];\n\
        \  stdio -> conn  [label=\"  streams over\"];\n\
        \  cp    -> conn  [label=\"routes every row through  \", style=dashed];\n\
        \  sql   -> sfs   [label=\"  reads and writes\"];\n\
        \  sql   -> role  [label=\"  requires membership of\"];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "The backslash is the whole difference" $ do
        p_ [class_ "lede"] $ do
            c "COPY"
            " and "
            c "\\copy"
            " have nearly the same syntax and answer different questions. SQL "
            c "COPY"
            " with a filename opens that file "
            b_ "on the server"
            ", as the operating-system user the server runs as. "
            c "\\copy"
            " opens it "
            b_ "on your machine"
            ", as you. Everything else about them follows."
        p_ $ do
            "So the privileges differ absolutely. Server-side "
            c "COPY"
            " to or from a file needs superuser rights or membership of "
            c "pg_write_server_files"
            " / "
            c "pg_read_server_files"
            ". "
            c "\\copy"
            " needs nothing at all beyond the SQL privileges on the table, because the server is \
            \never asked to touch a file — psql runs "
            c "COPY ... TO STDOUT"
            " or "
            c "COPY ... FROM STDIN"
            " underneath and moves the bytes itself."
        p_ "The database will tell you this itself, if you let it fail:"
        sh
            [ "testdb=> COPY my_table TO '/tmp/x.csv' CSV;"
            , "ERROR:  permission denied to COPY to a file"
            , "DETAIL:  Only roles with privileges of the \"pg_write_server_files\" role may COPY to a file."
            , "HINT:  Anyone can COPY to stdout or from stdin. psql's \\copy command also works for anyone."
            ]
        p_ $ do
            "That is an unusually generous error: the server names the role you lack "
            i_ "and"
            " tells you which psql command sidesteps the problem."
        fig

    block "The four shapes you will use" $ do
        p_ $ do
            "Everything after the source or destination is SQL "
            c "COPY"
            "'s own option list, so "
            c "WITH (FORMAT csv, HEADER)"
            ", "
            c "DELIMITER"
            ", "
            c "NULL"
            ", "
            c "QUOTE"
            ", "
            c "FORCE_QUOTE"
            " and the rest all work unchanged. Only the source and destination are psql's business."
        sh
            [ "-- export a query"
            , "\\copy (SELECT * FROM my_table ORDER BY first) TO 'out.csv' WITH (FORMAT csv, HEADER)"
            , ""
            , "-- load a file"
            , "\\copy loaded FROM 'out.csv' WITH (FORMAT csv, HEADER)"
            , ""
            , "-- filter as you load; the condition is evaluated server-side"
            , "\\copy loaded FROM 'out.csv' WITH (FORMAT csv, HEADER) WHERE first > 2"
            , ""
            , "-- through a program on YOUR machine"
            , "\\copy (SELECT second FROM my_table) TO PROGRAM 'tr a-z A-Z'"
            ]
        p_ $ do
            "And the shape that needs no file at all, which is how you embed data in a script. \
            \Data rows are read from whatever is feeding psql, up to a line containing only "
            c "\\."
            ":"
        sh
            [ "testdb=# \\copy inline_load FROM stdin WITH (FORMAT csv)"
            , "1,alpha"
            , "2,beta"
            , "\\."
            , "COPY 2"
            ]
        p_ $ do
            "Four destinations exist and the "
            c "p"
            " prefix matters. "
            c "stdin"
            " and "
            c "stdout"
            " mean “the same place psql is currently reading from or writing to”, which respects a "
            c "\\o"
            " redirection or the script you are inside. "
            c "pstdin"
            " and "
            c "pstdout"
            " mean psql's "
            i_ "real"
            " standard input and output, whatever the current redirection."
        note $ p_ $ do
            "With "
            c "TO stdout"
            " the "
            c "COPY n"
            " status line is suppressed, deliberately, so that it cannot be mistaken for a data \
            \row. With "
            c "TO pstdout"
            " you get both, in different places: the data on the terminal, the "
            c "COPY n"
            " wherever "
            c "\\o"
            " is pointing."

    block "The one meta-command that ignores your variables" $ do
        p_ $ do
            c "\\copy"
            " parses unlike anything else in psql, and the manual page is explicit about why: the \
            \entire remainder of the line is taken as the argument, and neither variable \
            \interpolation nor backquote expansion is performed. So this does exactly what it says, \
            \and it is not what you meant:"
        sh
            [ "testdb=# \\set f '/tmp/data.csv'"
            , "testdb=# \\copy my_table FROM :f WITH (FORMAT csv, HEADER)"
            , ":f: No such file or directory"
            ]
        p_ $ do
            "psql looked for a file called "
            c ":f"
            ". The exemption exists because "
            c "\\copy"
            "'s arguments are mostly SQL destined for the server — where "
            c ":"
            " has meanings of its own, in array slices and casts — and psql would rather pass them \
            \through untouched than guess."
        p_ "The way round it is the SQL command plus a dispatcher, which is the manual page's own tip:"
        sh
            [ "testdb=# \\set out '/tmp/via_g.csv'"
            , "testdb=# COPY (SELECT * FROM my_table ORDER BY first) TO STDOUT WITH (FORMAT csv, HEADER)"
            , "testdb-# \\g :out"
            , "COPY 4"
            ]
        p_ $ do
            "That form has two further advantages. It can span multiple lines, because it is a \
            \query in the buffer rather than a meta-command argument that stops at the end of the \
            \line. And "
            c "\\g |program"
            " gives you the pipe as well. Day 10 is all about "
            c "\\g"
            " and "
            c "\\o"
            "."
        gotcha $ p_ $ do
            "The same no-interpolation rule applies to "
            c "\\!"
            ", "
            c "\\ef"
            ", "
            c "\\ev"
            ", "
            c "\\help"
            ", "
            c "\\unrestrict"
            ", and the "
            c "|command"
            " form of "
            c "\\g"
            ", "
            c "\\o"
            " and "
            c "\\w"
            ". It is a short list and it is worth knowing, because the failure is always the same \
            \shape: a literal "
            c ":name"
            " turning up in a filename or a shell command."

    block "When it goes wrong" $ do
        p_ $ do
            "A "
            c "COPY"
            " is one statement, so a bad row aborts the whole load. The error tells you where, in \
            \the file and in the row:"
        sh
            [ "testdb=# \\copy badload FROM 'baddata.csv' WITH (FORMAT csv, HEADER)"
            , "ERROR:  invalid input syntax for type integer: \"notanint\""
            , "CONTEXT:  COPY badload, line 3, column a: \"notanint\""
            , "testdb=# SELECT count(*) FROM badload;"
            , " count "
            , "-------"
            , "     0"
            ]
        p_ $ do
            "Zero rows, not two. That is the right behaviour and it is worth verifying rather than \
            \assuming, because the loading pattern people reach for next — a loop that loads and \
            \retries — depends on knowing whether a partial load is possible. It is not, within one "
            c "COPY"
            "."
        tip $ p_ $ do
            "For files where some rows are expected to be bad, load into a staging table whose \
            \columns are all "
            c "text"
            ", then "
            c "INSERT ... SELECT"
            " with a cast and a "
            c "WHERE"
            " that excludes the rubbish. The "
            c "WHERE"
            " clause on "
            c "\\copy ... FROM"
            " cannot help here, because it filters rows the server has already parsed."

    block "Today's habit" $ do
        p_ $ do
            "Stop writing throwaway scripts to produce CSVs. "
            c "\\copy (query) TO 'file' WITH (FORMAT csv, HEADER)"
            " is one line, needs no privileges, and works against a database you only have "
            c "SELECT"
            " on. Put it in your fingers and the next “can you send me that data” takes ten seconds."
        p_ "Tomorrow: the rest of the output plumbing, and the difference between redirecting once and redirecting until further notice."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Whose filesystem?"
        " Client → "
        c "\\copy"
        ". Server → "
        c "COPY"
        " with a filename, and a privileged role."
    cfg
        [ "\\copy (SELECT ...) TO 'f' WITH (FORMAT csv, HEADER)   -- export, no privileges needed"
        , "\\copy t FROM 'f' WITH (FORMAT csv, HEADER)            -- load"
        , "\\copy t FROM 'f' WITH (FORMAT csv, HEADER) WHERE i>2  -- filter server-side as it loads"
        , "\\copy t TO PROGRAM 'gzip > f.gz'                      -- program runs on the CLIENT"
        , "\\copy t FROM stdin WITH (FORMAT csv)  ... rows ...  \\.   -- inline data in a script"
        , "stdin/stdout  follow \\o and the current script;  pstdin/pstdout  are psql's real ones"
        , "  TO stdout suppresses the COPY n line;  TO pstdout does not"
        , "-- \\copy does NOT interpolate :vars or `backticks`. Instead:"
        , "COPY (SELECT ...) TO STDOUT WITH (FORMAT csv, HEADER)"
        , "\\g :out"
        , "-- a bad row aborts the WHOLE copy: CONTEXT gives file line + column, 0 rows loaded"
        , "-- every row crosses the connection: for 40 GB, use server-side COPY instead"
        ]
