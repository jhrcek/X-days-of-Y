module Course.Day.D08 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 8
        , dayTitle = "Errors and transactions"
        , daySubtitle = "One typo aborts the whole block — unless you have told psql to take savepoints for you."
        , dayMinutes = 35
        , dayLevel = "intermediate"
        , dayManRef = "Variables (AUTOCOMMIT, ON_ERROR_*, VERBOSITY), \\errverbose, \\timing"
        , dayTags = ["autocommit", "savepoints", "\\errverbose"]
        , dayGoals =
            [ "read the transaction indicator in your prompt and know whether the block is healthy"
            , "survive a typo inside a long transaction without losing the work before it"
            , "get the SQLSTATE and the full detail of an error you have already seen"
            ]
        , dayDiagram = Just d8diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("\\errverbose", "Repeat the last error at maximum verbosity, changing no settings.")
            , ("\\timing on", "Report how long each statement took. Milliseconds, then m:ss past a second.")
            ]
        , dayOpts =
            [ ("AUTOCOMMIT", "On by default: every statement commits itself unless you opened a block.")
            , ("ON_ERROR_ROLLBACK", c "off" <> " (default) / " <> c "interactive" <> " / " <> c "on" <> " — implicit per-statement savepoints.")
            , ("ON_ERROR_STOP", "Stop at the first error instead of carrying on. Exit code 3 in a script.")
            , ("VERBOSITY", c "default" <> " / " <> c "verbose" <> " / " <> c "terse" <> " / " <> c "sqlstate" <> ".")
            , ("SHOW_CONTEXT", c "never" <> " / " <> c "errors" <> " (default) / " <> c "always" <> " — the CONTEXT field.")
            , ("ERROR SQLSTATE ROW_COUNT", "Set after every statement: did it fail, with what code, how many rows.")
            , ("LAST_ERROR_MESSAGE LAST_ERROR_SQLSTATE", "The most recent failure, still there after later successes.")
            ]
        , dayConfig =
            [ ConfBlock
                "Interactively, one typo in the middle of a long transaction should cost you\nthat\
                \ statement, not the twenty minutes of work before it. In scripts you want\nthe\
                \ opposite — an error really should abort everything — so \"interactive\" is\nthe\
                \ value that gets both behaviours from one line."
                "\\set ON_ERROR_ROLLBACK interactive"
            , ConfBlock
                "You will want to know that the query took four seconds, and you will never\n\
                \remember to turn timing on beforehand."
                "\\timing on"
            , ConfBlock
                "Harmless at the prompt — it only means \"return to the prompt\", which is\nwhat\
                \ happens anyway — but it makes \\i stop at the first error instead of\nploughing\
                \ on through a half-applied script."
                "\\set ON_ERROR_STOP on"
            ]
        , dayDrills =
            [ "Type "
                <> c "BEGIN;"
                <> " and look at the prompt. There is a "
                <> c "*"
                <> " in it now. Type "
                <> c "ROLLBACK;"
                <> " and watch it go."
            , "Inside a transaction, run a deliberately broken query. The "
                <> c "*"
                <> " becomes a "
                <> c "!"
                <> ". Now try any other statement and read the refusal."
            , "Still in that failed block, type "
                <> c "COMMIT;"
                <> ". psql answers "
                <> c "ROLLBACK"
                <> ". Sit with that for a moment — you asked to commit and the server told you what \
                   \it actually did."
            , "Now "
                <> c "\\set ON_ERROR_ROLLBACK on"
                <> " and repeat the whole sequence. The broken statement is discarded, the block \
                   \stays healthy, and the "
                <> c "COMMIT"
                <> " commits."
            , "Run something that fails, then "
                <> c "\\errverbose"
                <> ". You get the SQLSTATE and the source location without having set "
                <> c "VERBOSITY"
                <> " beforehand — which matters, because you never do."
            , "Break it on purpose: "
                <> c "\\set AUTOCOMMIT off"
                <> ", create a table, and quit without committing. Reconnect. The table is gone, \
                   \and nothing warned you."
            , "After a successful query, "
                <> c "\\echo :ROW_COUNT :ERROR :SQLSTATE"
                <> ". After a failing one, the same again. Three variables, and the basis of every \
                   \conditional script on Day 14."
            , "Add the three lines to your psqlrc. From today a typo in a long transaction costs \
              \you one statement."
            ]
        , dayQuiz =
            [
                ( "You type "
                    <> c "COMMIT;"
                    <> " and psql replies "
                    <> c "ROLLBACK"
                    <> ". Did your work land?"
                , do
                    p_ $ do
                        "No. Somewhere earlier in the block a statement failed, the whole \
                        \transaction was marked aborted, and every statement since has been \
                        \refused with “current transaction is aborted, commands ignored until end \
                        \of transaction block”. "
                        c "COMMIT"
                        " on an aborted transaction is a rollback, and the server reports what it \
                        \did rather than what you asked for."
                    p_ $ do
                        "The prompt was telling you throughout: "
                        c "%x"
                        " shows "
                        c "*"
                        " in a healthy block and "
                        c "!"
                        " in a failed one. That single character is the reason to keep the default \
                        \prompt, or to keep "
                        c "%x"
                        " when you write your own on Day 15."
                )
            ,
                ( "Why is "
                    <> c "ON_ERROR_ROLLBACK interactive"
                    <> " better than "
                    <> c "on"
                    <> "?"
                , do
                    p_ $ do
                        "Because the two situations want opposite behaviour. At the prompt, a typo \
                        \forty statements into a transaction should cost you the typo, not the \
                        \transaction — so implicit savepoints are a kindness. In a script, an \
                        \error genuinely should abort everything, because a half-applied migration \
                        \is worse than none."
                    p_ $ do
                        c "interactive"
                        " gives you savepoints at the prompt and strict behaviour when reading a \
                        \file, from one line in your psqlrc. The mechanism is exactly what you \
                        \would write by hand: psql issues an implicit "
                        c "SAVEPOINT"
                        " before each statement in a block and rolls back to it if the statement \
                        \fails. It is not free — a savepoint per statement has a real cost in a \
                        \tight loop — which is the other reason not to set it to "
                        c "on"
                        " globally."
                )
            ,
                ( "Your script does its work and exits 0. Nothing was written to the database. \
                  \There were no errors. What is set?"
                , do
                    p_ $ do
                        c "AUTOCOMMIT off"
                        ", almost certainly from a psqlrc — yours, or the system-wide one — because \
                        \the script forgot "
                        c "-X"
                        ". With autocommit off, psql issues an implicit "
                        c "BEGIN"
                        " before your first statement and nothing is committed until you say so. \
                        \Exiting without a "
                        c "COMMIT"
                        " discards the lot, silently."
                    p_ $ do
                        "The manual page notes that autocommit-off is closer to the SQL standard \
                        \and autocommit-on is PostgreSQL's tradition. Either is defensible; what is \
                        \not defensible is a script that does not know which it will get. Hence "
                        c "-X"
                        "."
                )
            ,
                ( "An error message tells you nothing useful. You do not want to re-run the \
                  \statement — it took four minutes. What can you still get?"
                , do
                    p_ $ do
                        c "\\errverbose"
                        " re-prints the last server error as though "
                        c "VERBOSITY"
                        " had been "
                        c "verbose"
                        " and "
                        c "SHOW_CONTEXT"
                        " had been "
                        c "always"
                        ", from what psql already has in hand:"
                    sh
                        [ "testdb=# \\errverbose"
                        , "ERROR:  42703: column \"nosuch\" does not exist"
                        , "LINE 1: SELECT nosuch;"
                        , "               ^"
                        , "LOCATION:  errorMissingColumn, parse_relation.c:3854"
                        ]
                    p_ $ do
                        "And "
                        c ":LAST_ERROR_MESSAGE"
                        " and "
                        c ":LAST_ERROR_SQLSTATE"
                        " survive later successful statements, unlike "
                        c ":SQLSTATE"
                        ", which is reset by every statement. That distinction is what makes error \
                        \reporting in a script possible at all."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d8diagram :: Diagram
d8diagram =
    ( diagram
        "A statement runs inside a transaction block and can raise an error; the error aborts \
        \the block, which then becomes an aborted transaction reported by the %x prompt \
        \indicator, unless an implicit savepoint taken before the statement prevents it."
        body'
    )
        { dgCaption = do
            "One error aborts the "
            i_ "whole"
            " block, and everything after it is refused until you end the block — so a "
            c "COMMIT"
            " that answers "
            c "ROLLBACK"
            " is the server telling you what it did rather than what you asked. The amber box is \
            \the escape: "
            opt "ON_ERROR_ROLLBACK"
            " has psql take a savepoint before every statement in a block, so a failure costs one \
            \statement instead of the transaction. It is not free, which is why the default is off."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  stmt  [label=\"a statement\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  tx    [label=\"a transaction block\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  err   [label=\"an error\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  abort [label=\"an aborted\\ntransaction block\"];\n\
        \  sp    [label=\"an implicit SAVEPOINT\\n(ON_ERROR_ROLLBACK)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  ind   [label=\"the %x prompt\\nindicator\"];\n\
        \\n\
        \  stmt  -> tx    [label=\"  runs inside\"];\n\
        \  stmt  -> err   [label=\"can raise  \", style=dashed];\n\
        \  err   -> tx    [label=\"  aborts\"];\n\
        \  tx    -> abort [label=\"  then is\"];\n\
        \  abort -> ind   [label=\"  is reported by\"];\n\
        \  sp    -> stmt  [label=\"is taken before  \"];\n\
        \  sp    -> abort [label=\"prevents  \", style=dashed];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Autocommit is on, and that is the important default" $ do
        p_ [class_ "lede"] $ do
            "Every statement you run commits itself the moment it succeeds. There is no open \
            \transaction to forget about, no "
            c "COMMIT"
            " to remember, and no way to take back the "
            c "UPDATE"
            " you ran without a "
            c "WHERE"
            ". That is "
            opt "AUTOCOMMIT"
            ", it is on by default, and it is PostgreSQL's tradition rather than the SQL standard's."
        p_ $ do
            "To defer, open a block yourself with "
            c "BEGIN"
            ". Turn "
            opt "AUTOCOMMIT"
            " off instead and psql issues an implicit "
            c "BEGIN"
            " for you before any statement that is not already in a block — which sounds safer and \
            \introduces a new way to lose work:"
        gotcha $ p_ $ do
            "With autocommit off, quitting without committing discards everything, "
            b_ "silently"
            ". No warning, no prompt, exit status 0. The manual page mentions it in a note; the \
            \database mentions it not at all. If you turn autocommit off, you have taken on the \
            \job of remembering "
            c "COMMIT"
            "."
        p_ $ do
            "The prompt is where you watch all this. In the default prompt, "
            c "%x"
            " is the transaction slot — empty outside a block, "
            c "*"
            " inside a healthy one, "
            c "!"
            " once something in it has failed, "
            c "?"
            " when psql has no connection to ask."
        fig

    block "One error aborts the block" $ do
        p_ $ do
            "This is the behaviour that surprises people who have come from other databases. A \
            \failed statement inside a transaction does not just fail — it puts the "
            i_ "whole block"
            " into an aborted state, and everything after it is refused:"
        sh
            [ "testdb=# BEGIN;"
            , "BEGIN"
            , "testdb=*# CREATE TABLE a(i int);"
            , "CREATE TABLE"
            , "testdb=*# SELECT nosuch;"
            , "ERROR:  column \"nosuch\" does not exist"
            , "LINE 1: SELECT nosuch;"
            , "               ^"
            , "testdb=!# CREATE TABLE b(i int);"
            , "ERROR:  current transaction is aborted, commands ignored until end of transaction block"
            , "testdb=!# COMMIT;"
            , "ROLLBACK"
            ]
        p_ $ do
            "Read the last two lines again. You asked to commit and the server replied "
            c "ROLLBACK"
            ", because a commit of an aborted transaction is a rollback. Table "
            c "a"
            " does not exist. Nothing shouted; the "
            c "!"
            " in the prompt was the only warning you were given, for four statements running."
        why $ p_ $ do
            "Why so absolute? Because the alternative is worse. If a failed statement inside a \
            \transaction left the block usable, then a transaction's meaning would depend on which \
            \of its statements happened to succeed — atomicity would be something you had to check \
            \for rather than something you had. PostgreSQL makes the block all-or-nothing and hands \
            \you "
            c "SAVEPOINT"
            " for the cases where you genuinely want partial failure."

    block "Savepoints you did not have to write" $ do
        p_ $ do
            "Which is what "
            opt "ON_ERROR_ROLLBACK"
            " automates. Set it and psql issues an implicit "
            c "SAVEPOINT"
            " before every statement inside a block, rolling back to it if the statement fails. \
            \The typo costs you the typo:"
        sh
            [ "testdb=# \\set ON_ERROR_ROLLBACK on"
            , "testdb=# BEGIN;"
            , "testdb=*# CREATE TABLE a(i int);"
            , "CREATE TABLE"
            , "testdb=*# SELECT nosuch;"
            , "ERROR:  column \"nosuch\" does not exist"
            , "testdb=*# CREATE TABLE b(i int);        -- still a * , not a !"
            , "CREATE TABLE"
            , "testdb=*# COMMIT;"
            , "COMMIT"
            ]
        p_ $ do
            "Both tables exist. The three settings are "
            c "off"
            " (the default), "
            c "on"
            ", and "
            c "interactive"
            " — and "
            c "interactive"
            " is the one to put in your psqlrc, because it applies the kindness at the prompt and \
            \leaves script execution strict. A half-applied migration is worse than a failed one."
        note $ p_ $ do
            "A savepoint per statement is not free. In a loop inserting a hundred thousand rows \
            \inside one transaction you will notice, which is the other reason the default is "
            c "off"
            " and the reason not to set it to "
            c "on"
            " for everything."
        p_ $ do
            "The neighbouring setting, "
            opt "ON_ERROR_STOP"
            ", is about "
            i_ "control flow"
            " rather than the transaction: stop processing at the first error instead of carrying \
            \on. At the prompt that means “return to the prompt”, which happens anyway, so it is \
            \harmless there; its effect is on "
            c "\\i"
            " and on scripts, and Day 11 is where it earns its place."

    block "Making an error tell you more" $ do
        p_ $ do
            opt "VERBOSITY"
            " has four settings and they differ more than you would expect:"
        defs
            [ (c "default", "message, LINE, and the caret pointing at the offending token")
            , (c "verbose", "adds the SQLSTATE, the DETAIL and HINT fields, and the server's own source location")
            ,
                ( c "terse"
                , do
                    "one line, with the position folded in as “at character 8”. Good for "
                    c "\\watch"
                    " and for logs."
                )
            , (c "sqlstate", "the five-character code and nothing else — for scripts that grep")
            ]
        p_ $ do
            "The trouble with "
            c "verbose"
            " is that you want it after the error, not before it, and nobody sets it in advance. \
            \That is what "
            c "\\errverbose"
            " is for: it re-prints the error psql is still holding, at full verbosity, without \
            \changing any setting."
        sh
            [ "testdb=# SELECT nosuch;"
            , "ERROR:  column \"nosuch\" does not exist"
            , "LINE 1: SELECT nosuch;"
            , "               ^"
            , "testdb=# \\errverbose"
            , "ERROR:  42703: column \"nosuch\" does not exist"
            , "LINE 1: SELECT nosuch;"
            , "               ^"
            , "LOCATION:  errorMissingColumn, parse_relation.c:3854"
            ]
        p_ $ do
            opt "SHOW_CONTEXT"
            " controls the "
            c "CONTEXT"
            " field separately, and the default of "
            c "errors"
            " means you see it on errors but not on notices. Set it to "
            c "always"
            " while debugging a "
            c "plpgsql"
            " function and every "
            c "RAISE NOTICE"
            " tells you which line it came from — which is the difference between reading a stack \
            \and guessing at one."

    block "Four variables the next six days depend on" $ do
        p_ "Every statement updates a handful of variables. They are ordinary psql variables, readable with a colon, and they are the raw material for conditional scripts:"
        sh
            [ "testdb=# SELECT * FROM my_table;"
            , "-- 4 rows"
            , "testdb=# \\echo :ROW_COUNT :ERROR :SQLSTATE"
            , "4 false 00000"
            , "testdb=# SELECT nosuch;"
            , "ERROR:  column \"nosuch\" does not exist"
            , "testdb=# \\echo :ROW_COUNT :ERROR :SQLSTATE"
            , "0 true 42703"
            ]
        p_ $ do
            "Note the asymmetry that makes them usable. "
            c "ERROR"
            ", "
            c "SQLSTATE"
            " and "
            c "ROW_COUNT"
            " describe the "
            i_ "last"
            " statement and are reset by the next one. "
            c "LAST_ERROR_MESSAGE"
            " and "
            c "LAST_ERROR_SQLSTATE"
            " describe the last "
            i_ "failure"
            " and survive any number of subsequent successes — so a script can do its cleanup and \
            \still report what went wrong."
        tip $ p_ $ do
            "There is also "
            c "SHELL_ERROR"
            " and "
            c "SHELL_EXIT_CODE"
            " for the last shell command psql ran, on Day 12. Between them these seven variables \
            \are why psql can be scripted at all without a wrapper language."

    block "Today's habit" $ do
        p_ $ do
            "Start looking at the character before the "
            c "#"
            " or "
            c ">"
            " in your prompt. Three lines into psqlrc — "
            c "ON_ERROR_ROLLBACK interactive"
            ", "
            c "\\timing on"
            ", "
            c "ON_ERROR_STOP on"
            " — and the next typo inside a long transaction will cost you one statement rather than \
            \the afternoon."
        p_ "Tomorrow: moving bulk data in and out, and the one question that decides which command you need."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "The prompt's transaction slot."
        " Empty = none, "
        c "*"
        " = open, "
        c "!"
        " = failed, "
        c "?"
        " = no connection."
    cfg
        [ "AUTOCOMMIT on (default)  -- every statement commits itself; BEGIN to defer"
        , "  off -> implicit BEGIN, and quitting without COMMIT loses everything SILENTLY"
        , "one error aborts the WHOLE block; later statements are refused; COMMIT answers ROLLBACK"
        , "\\set ON_ERROR_ROLLBACK interactive   -- implicit SAVEPOINT per statement, prompt only"
        , "\\set ON_ERROR_STOP on                -- stop at the first error (matters for \\i, Day 11)"
        , "\\errverbose      -- re-print the last error verbosely, no setting needed in advance"
        , "\\set VERBOSITY default|verbose|terse|sqlstate     \\set SHOW_CONTEXT always"
        , "\\timing on       -- ms, then m:ss past one second"
        , ":ERROR :SQLSTATE :ROW_COUNT        -- the LAST statement; reset by the next one"
        , ":LAST_ERROR_MESSAGE :LAST_ERROR_SQLSTATE  -- the last FAILURE; survives later successes"
        ]
