module Course.Day.D12 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 12
        , dayTitle = "Interpolation"
        , daySubtitle = "Three quoting forms, one shell escape, and a colon that eats your array slices."
        , dayMinutes = 35
        , dayLevel = "advanced"
        , dayManRef = "SQL Interpolation, Variables, \\gset, \\getenv, \\setenv, \\prompt"
        , dayTags = [":var", "\\gset", "backquotes"]
        , dayGoals =
            [ "interpolate a value safely as a literal and as an identifier, and say which is which"
            , "capture a query result into variables and use it in the next statement"
            , "recognise the two ways interpolation can quietly change the meaning of your SQL"
            ]
        , dayDiagram = Just d12diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ (":name", "Substitute the value literally — unquoted, unchecked, unsafe.")
            , (":'name'", "Substitute as a properly quoted SQL literal. Handles embedded quotes.")
            , (":\"name\"", "Substitute as a properly quoted SQL identifier. Handles spaces and case.")
            , (":{?name}", c "TRUE" <> " or " <> c "FALSE" <> " depending on whether the variable exists.")
            , ("`command`", "Substitute a shell command's output, trailing newline removed.")
            , ("\\gset [prefix]", "Store a one-row result into variables named after its columns.")
            , ("\\getenv var ENVVAR", "Read an environment variable into a psql variable.")
            , ("\\setenv NAME value", "Set an environment variable for psql and anything it runs.")
            , ("\\prompt [text] name", "Ask the operator for a value and store it.")
            ]
        , dayOpts =
            [ ("SHELL_ERROR SHELL_EXIT_CODE", "Whether the last shell command failed, and its exit status.")
            ]
        , dayConfig =
            [ ConfBlock
                "Two queries you will otherwise retype for the rest of your career, stored\nas\
                \ variables: type :act to see what is running and :waits to see what is\nblocked.\
                \ The doubled '' inside the value is how you get a single quote into a\n\\set\
                \ argument. Add your own — this is psql's nearest thing to an alias."
                "\\set act 'SELECT pid, age(clock_timestamp(), query_start) AS running, state, left(query, 40) AS query FROM pg_stat_activity WHERE state <> ''idle'' AND pid <> pg_backend_pid() ORDER BY query_start;'\n\\set waits 'SELECT pid, wait_event_type, wait_event, left(query, 40) AS query FROM pg_stat_activity WHERE wait_event IS NOT NULL ORDER BY pid;'"
            ]
        , dayDrills =
            [ c "\\set t my_table"
                <> " then "
                <> c "SELECT * FROM :\"t\" LIMIT 1;"
                <> ". The identifier form is the one you want for table and column names."
            , c "\\set v 'it''s'"
                <> " then "
                <> c "SELECT :'v';"
                <> ". The embedded quote survives, because psql did the quoting rather than you."
            , "Break it on purpose: "
                <> c "SELECT ':v';"
                <> " with "
                <> c "v"
                <> " still set. It prints "
                <> c ":v"
                <> " — interpolation never happens inside a quoted literal, which is why "
                <> c ":'v'"
                <> " exists."
            , "Capture a value: "
                <> c "SELECT count(*) AS n FROM my_table"
                <> " then "
                <> c "\\gset"
                <> ", then "
                <> c "\\echo :n"
                <> ". You have moved a number from the database into psql."
            , "Now break "
                <> c "\\gset"
                <> ": run it on a query returning two rows, and again on one returning none. Neither \
                   \changes any variable, and neither is silent about it."
            , "Shell out: "
                <> c "\\set today `date +%F`"
                <> " then "
                <> c "SELECT :'today'::date;"
                <> ". psql ran "
                <> c "date"
                <> " on your machine."
            , "Break it on purpose again: "
                <> c "\\set arg 'a; echo INJECTED'"
                <> " then "
                <> c "\\echo `echo :arg`"
                <> " and compare with "
                <> c "\\echo `echo :'arg'`"
                <> ". One of them ran your semicolon."
            , "Put the two "
                <> c "\\set"
                <> " lines from the config box into your psqlrc, and use "
                <> c ":act"
                <> " the next time something is slow. Then add a third of your own."
            ]
        , dayQuiz =
            [
                ( "You have "
                    <> c "\\set n 2"
                    <> " set from earlier. Then you run "
                    <> c "SELECT (array[10,20,30])[1:n];"
                    <> " and get NULL. What did the server actually receive?"
                , do
                    p_ $ do
                        c "SELECT (array[10,20,30])[12];"
                        " — element twelve of a three-element array, which is NULL. psql saw "
                        c ":n"
                        ", replaced it with "
                        c "2"
                        ", and in doing so ate the colon that made it a slice."
                    p_ $ do
                        "The colon is standard SQL for embedded query languages, and PostgreSQL then \
                        \gave it two more meanings — array slices and "
                        c "::"
                        " casts. Nothing detects the collision, because "
                        c "1:n"
                        " is perfectly valid either way. Escape it with a backslash — "
                        c "[1\\:3]"
                        " — or, better, do not leave short lower-case variables lying around. \
                        \Run "
                        c "\\set"
                        " with no arguments if a query starts behaving oddly."
                )
            ,
                ( "When do you use "
                    <> c ":name"
                    <> ", "
                    <> c ":'name'"
                    <> " and "
                    <> c ":\"name\""
                    <> "?"
                , do
                    p_ "Three forms, three jobs, and picking the wrong one is either a bug or a vulnerability:"
                    defs
                        [ (c ":name", "raw text. For fragments that are not values at all — a whole query, a WHERE clause, a number you are sure of.")
                        , (c ":'name'", "a quoted SQL literal. For anything that is data. It handles embedded quotes correctly, which is exactly what you would get wrong by hand.")
                        , (c ":\"name\"", "a quoted SQL identifier. For table, column and schema names — it survives spaces and preserves case.")
                        ]
                    p_ $ do
                        "The manual page's warning about the raw form is worth quoting: “the value \
                        \of the variable is copied literally, so it can contain unbalanced quotes, \
                        \or even backslash commands”. If the value came from outside your session, \
                        \use one of the quoted forms."
                )
            ,
                ( c "SELECT ':name';"
                    <> " prints "
                    <> c ":name"
                    <> " rather than the value, but "
                    <> c "SELECT :'name';"
                    <> " works. Why the asymmetry?"
                , do
                    p_ $ do
                        "Because interpolation is deliberately not performed inside quoted SQL \
                        \literals and identifiers. If it were, you could not write a string \
                        \containing a colon, and — worse — the substituted value would not be \
                        \escaped for the quotes it landed inside, so a value containing "
                        c "'"
                        " would break out of the literal."
                    p_ $ do
                        "So "
                        c "':name'"
                        " is a string, and "
                        c ":'name'"
                        " — colon first — asks psql to produce a correctly quoted literal from the \
                        \variable. The two look almost identical on the page and mean entirely \
                        \different things."
                )
            ,
                ( "A script does "
                    <> c "\\gset"
                    <> " after a query that returns no rows, then uses the variables. What happens?"
                , do
                    p_ $ do
                        "The variables keep whatever they held before. "
                        c "\\gset"
                        " requires exactly one row, and if the query fails or returns any other \
                        \number of rows, "
                        b_ "no variable is changed"
                        " — it reports the problem and moves on. A NULL column is different again: \
                        \it "
                        i_ "unsets"
                        " the corresponding variable rather than setting it to anything."
                    p_ $ do
                        "That NULL rule is the useful half, because it pairs with "
                        c ":{?name}"
                        ", which is "
                        c "TRUE"
                        " or "
                        c "FALSE"
                        " depending on whether the variable exists. So “did that lookup find \
                        \anything” becomes "
                        c "\\if :{?found}"
                        ", which is Day 14's whole vocabulary."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d12diagram :: Diagram
d12diagram =
    ( diagram
        "A variable reference or a backquoted shell command can appear in the text you typed, \
        \which becomes, after substitution, what reaches the server; the reference names a psql \
        \variable whose value is put in, and an ordinary colon in SQL can be mistaken for a \
        \reference."
        body'
    )
        { dgCaption = do
            "Substitution happens entirely inside psql, before anything is sent — in SQL "
            i_ "and"
            " in meta-command arguments. The amber aspect is the day's trap and it has no \
            \diagnostic: "
            b_ "an ordinary colon in SQL"
            " — an array slice, a cast — is indistinguishable from a variable reference, so "
            c "[1:n]"
            " quietly becomes "
            c "[12]"
            " if "
            c "n"
            " happens to be set to 2."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  txt   [label=\"the text you typed\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  ref   [label=\"a variable reference\\n:name  :'name'  :\\\"name\\\"\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  var   [label=\"a psql variable\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  bq    [label=\"a backquoted\\nshell command\"];\n\
        \  sent  [label=\"what reaches the server\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  slice [label=\"a colon in SQL\\nan array slice, a cast\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  ref   -> txt  [label=\"  can appear in\"];\n\
        \  bq    -> txt  [label=\"can appear in  \"];\n\
        \  ref   -> var  [label=\"  names\"];\n\
        \  txt   -> sent [label=\"  becomes, after substitution,\"];\n\
        \  var   -> sent [label=\"  puts its value into\"];\n\
        \  bq    -> sent [label=\"puts its output into  \"];\n\
        \  slice -> ref  [label=\"  can be mistaken for\", style=dashed];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "The colon, three ways" $ do
        p_ [class_ "lede"] $ do
            "A psql variable is read by putting a colon in front of its name, and the substitution \
            \happens in ordinary SQL as well as in meta-command arguments. That much is easy. The \
            \part worth thirty minutes is that there are "
            i_ "three"
            " forms, they produce different text, and choosing the wrong one is either a bug or a \
            \vulnerability."
        defs
            [
                ( c ":name"
                , do
                    "the value, copied in literally. Nothing is quoted or checked. Right for things \
                    \that are not values — a whole query, a "
                    c "WHERE"
                    " clause, a column list."
                )
            ,
                ( c ":'name'"
                , "the value as a properly quoted SQL literal. Right for anything that is data. It handles embedded quotes, which is the bit you get wrong by hand."
                )
            ,
                ( c ":\"name\""
                , "the value as a properly quoted SQL identifier. Right for table, column and schema names. It survives spaces and preserves case."
                )
            ]
        sh
            [ "testdb=# \\set t my_table"
            , "testdb=# \\set v 'it''s'"
            , "testdb=# SELECT * FROM :\"t\" LIMIT 1;"
            , " first | second "
            , "-------+--------"
            , "     1 | one"
            , "(1 row)"
            , ""
            , "testdb=# SELECT :'v' AS lit;"
            , " lit  "
            , "------"
            , " it's"
            ]
        why $ p_ $ do
            "The manual page is blunt about the raw form: “the value of the variable is copied \
            \literally, so it can contain unbalanced quotes, or even backslash commands. You must \
            \make sure that it makes sense where you put it.” Which is the same warning every \
            \string-concatenation SQL injection has ever earned. If the value came from outside \
            \your own session — an environment variable, a "
            c "\\prompt"
            ", a shell command — one of the two quoted forms is not optional."
        fig

    block "Where interpolation does not happen" $ do
        p_ "Three exceptions, and all of them are deliberate."
        p_ $ do
            "First, "
            b_ "never inside a quoted SQL literal or identifier"
            ". So "
            c "':name'"
            " is the four-character string "
            c ":name"
            ", not the value:"
        sh
            [ "testdb=# \\set v hello"
            , "testdb=# SELECT ':v' AS in_quotes;"
            , " in_quotes "
            , "-----------"
            , " :v"
            ]
        p_ $ do
            "If it did work, the substituted value would sit inside quotes psql had not escaped it \
            \for, so a value containing "
            c "'"
            " would break out of the literal. The manual page says as much: it “would be unsafe if \
            \it did work”. "
            c ":'v'"
            " — colon on the outside — is the form that does the escaping."
        p_ $ do
            "Second, and this one bites in "
            i_ "meta-command"
            " arguments rather than in SQL: substitution happens only for an "
            b_ "unquoted"
            " colon. So the single quotes you add for readability are exactly what stops the \
            \substitution you wanted:"
        sh
            [ "testdb=# \\warn 'against :DBNAME'"
            , "against :DBNAME"
            , "testdb=# \\warn against :DBNAME"
            , "against testdb"
            ]
        p_ $ do
            "Which is not a contradiction of the three forms above — "
            c ":'name'"
            " has the colon on the outside, and it is that outer colon that is unquoted. Quote the \
            \whole thing and there is no unquoted colon left to act on."
        p_ $ do
            "Third, an "
            b_ "unset"
            " name is left completely alone. "
            c ":nosuchvar"
            " is passed through to the server, which is why a typo in a variable name shows up as \
            \a SQL syntax error at a colon rather than as an empty string:"
        sh
            [ "testdb=# SELECT 1 WHERE :nosuchvar IS NULL;"
            , "ERROR:  syntax error at or near \":\""
            , "LINE 1: SELECT 1 WHERE :nosuchvar IS NULL;"
            , "                       ^"
            ]
        gotcha $ do
            p_ $ do
                "The other side of that rule is the trap. A colon means three things in PostgreSQL \
                \SQL — a variable reference, an array slice, and half of a "
                c "::"
                " cast — and psql cannot tell them apart. If the name after the colon "
                i_ "is"
                " set, it wins:"
            sh
                [ "testdb=# \\set n 2"
                , "testdb=# SELECT (array[10,20,30])[1:n];      -- you meant a slice"
                , "SELECT (array[10,20,30])[12];                -- what the server received"
                , " slice "
                , "-------"
                , "      "
                ]
            p_ $ do
                "Element twelve of a three-element array is NULL, and nothing anywhere reported a \
                \problem. Escape the colon — "
                c "[1\\:3]"
                " — or keep short lower-case names out of your variable space. When SQL starts \
                \behaving impossibly, bare "
                c "\\set"
                " lists everything you have set."

    block "Getting values in" $ do
        p_ $ do
            "Four ways, and "
            c "\\gset"
            " is the one that changes how you work:"
        sh
            [ "testdb=# SELECT count(*) AS n, max(first) AS hi FROM my_table"
            , "testdb-# \\gset"
            , "testdb=# \\echo :n :hi"
            , "4 4"
            ]
        p_ $ do
            "One column becomes one variable, named after the column, so alias your expressions. \
            \A prefix argument namespaces them: "
            c "\\gset res_"
            " gives you "
            c ":res_n"
            " and "
            c ":res_hi"
            ". The rules for the edge cases are strict and worth knowing:"
        steps
            [ "The query must return exactly one row. If it fails, or returns none, or returns several, no variable is changed at all."
            , do
                "A NULL column "
                i_ "unsets"
                " its variable rather than setting it to anything. Pair that with "
                c ":{?name}"
                " — "
                c "TRUE"
                " or "
                c "FALSE"
                " depending on whether the variable exists — and “did the lookup find anything” \
                \becomes testable."
            , do
                "On an empty buffer, "
                c "\\gset"
                " re-runs the last query, like "
                c "\\g"
                "."
            ]
        p_ "The other three are simpler:"
        defs
            [ (c "\\getenv v HOME", "read an environment variable into a psql variable. The only way in, since psql does not expand $VAR.")
            , (c "\\setenv PAGER less", "the reverse: set an environment variable for psql and everything it runs — including your pager and your editor.")
            , (c "\\prompt 'schema? ' s", "ask the operator. Uses the terminal, unless " <> c "-f" <> " was given, in which case it reads standard input — which is how you pipe an answer in.")
            ]
        note $ p_ $ do
            "psql does "
            b_ "not"
            " expand shell variables. "
            c "SELECT '$HOME'"
            " is the literal five characters. Use "
            c "\\getenv"
            ", or let your shell do the expansion before psql ever sees the text."

    block "Backquotes, and why the quoted form matters" $ do
        p_ $ do
            "Text in backquotes inside a meta-command argument is run by the shell, and its output \
            \— minus the trailing newline — replaces it. Variable references inside the backquotes \
            \are substituted first:"
        sh
            [ "testdb=# \\set today `date +%F`"
            , "testdb=# SELECT :'today'::date AS d;"
            , "testdb=# \\echo `hostname`"
            ]
        p_ $ do
            "Both "
            c ":name"
            " and "
            c ":'name'"
            " work inside backquotes, and the difference is the same difference as everywhere else — \
            \except that here the consequence is shell injection rather than SQL injection:"
        sh
            [ "testdb=# \\set arg 'a; echo INJECTED'"
            , "testdb=# \\echo `echo :arg`"
            , "a"
            , "INJECTED"
            , "testdb=# \\echo `echo :'arg'`"
            , "a; echo INJECTED"
            ]
        p_ $ do
            "The quoted form wraps the value as a single shell argument. The manual page recommends \
            \it outright — “almost always preferable, unless you are very sure of what is in the \
            \variable” — and there is one case where it refuses to work at all: a value containing \
            \a newline or carriage return cannot be safely quoted on every platform, so psql prints \
            \an error and leaves the reference unsubstituted."
        p_ $ do
            "Two variables report on the shell command afterwards: "
            c "SHELL_EXIT_CODE"
            " (0–127 for exit codes, 128–255 for a signal, −1 if psql could not launch it) and "
            c "SHELL_ERROR"
            " ("
            c "true"
            "/"
            c "false"
            "). They cover backquotes and "
            c "\\!"
            ", "
            c "\\g |"
            ", "
            c "\\o |"
            ", "
            c "\\w |"
            " and "
            c "\\copy ... PROGRAM"
            " — with the wrinkle that for "
            c "\\o"
            " they only update when the pipe is closed by the "
            i_ "next"
            " "
            c "\\o"
            "."

    block "psql's nearest thing to an alias" $ do
        p_ $ do
            "Because "
            c ":name"
            " substitutes raw text into SQL, a variable can hold an entire query — and then its \
            \name is a command:"
        cfg
            [ "\\set act 'SELECT pid, state, left(query,40) FROM pg_stat_activity ORDER BY query_start;'"
            ]
        sh
            [ "testdb=# :act"
            , " pid | state  |               left               "
            , "-----+--------+----------------------------------"
            , " 303 | active | SELECT pid, state, left(query,40)"
            ]
        p_ $ do
            "Note the doubled "
            c "''"
            ", which is how a single quote gets into a "
            c "\\set"
            " argument. A handful of these in your psqlrc is the closest psql comes to letting you \
            \name your own commands, and it is the reason the config box for today is two long \
            \lines rather than a setting."
        gotcha $ p_ $ do
            "It has to be "
            b_ "one line"
            ", however long. A meta-command's arguments cannot continue past the end of the line, \
            \so wrapping the query for readability does not merely look different — it fails, \
            \noisily and confusingly:"
        sh
            [ "psqlrc:2: error: unterminated quoted string"
            , "psqlrc:3: ERROR:  syntax error at or near \"WHERE\""
            , "psqlrc:4: ERROR:  unterminated quoted string at or near \"'"
            ]
        p_ $ do
            "The second and third lines of the wrapped value were read as SQL and sent to the \
            \server, which is a good illustration of the rule from Day 1: parsing of a \
            \meta-command's arguments stops at the end of the line, and what follows is ordinary \
            \input again."
        tip $ p_ $ do
            "Keep the names upper-case-free but distinctive — "
            c ":act"
            ", "
            c ":waits"
            ", "
            c ":bloat"
            " — and remember the array-slice collision above when choosing them. A variable called "
            c "n"
            " or "
            c "i"
            " will bite you eventually."

    block "Today's habit" $ do
        p_ $ do
            "Two things. Use "
            c ":\"name\""
            " and "
            c ":'name'"
            " rather than "
            c ":name"
            " unless you can say why the raw form is safe. And start collecting stored queries in \
            \your psqlrc, one per thing you have looked up twice."
        p_ "Tomorrow: three commands that make psql write and run its own SQL."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Three forms, three jobs."
        " Raw for fragments, "
        c "'"
        " for data, "
        c "\""
        " for names."
    cfg
        [ ":name       -- raw text, unquoted, unchecked. For query fragments only."
        , ":'name'     -- a quoted SQL LITERAL     -> use for data"
        , ":\"name\"     -- a quoted SQL IDENTIFIER  -> use for table/column/schema names"
        , ":{?name}    -- TRUE / FALSE: is the variable set at all"
        , "':name'     -- just a string. Interpolation NEVER happens inside quotes."
        , ":nosuchvar  -- an unset name is passed through untouched -> a syntax error at ':'"
        , "[1:n]       -- COLLISION: if n is set, the colon is eaten. Escape it: [1\\:3]"
        , "SELECT ... AS n  \\gset [prefix]   -- exactly one row; NULL column UNSETS the variable"
        , "\\getenv v HOME    \\setenv PAGER less    \\prompt 'text ' v"
        , "`cmd`       -- shell output, trailing newline removed.  :'v' inside it is SAFE, :v is not"
        , ":SHELL_EXIT_CODE :SHELL_ERROR   -- after `cmd`, \\!, \\g |, \\o |, \\w |, \\copy PROGRAM"
        ]
