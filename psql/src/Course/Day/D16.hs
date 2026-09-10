module Course.Day.D16 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 16
        , dayTitle = "The extended protocol"
        , daySubtitle = "psql speaks the simple protocol; your application does not. Seven commands let you speak the other one by hand."
        , dayMinutes = 35
        , dayLevel = "advanced"
        , dayManRef = "\\bind, \\bind_named, \\parse, \\close_prepared, \\startpipeline … \\endpipeline"
        , dayTags = ["\\bind", "pipelining", "%P"]
        , dayGoals =
            [ "run a query through the extended protocol with real bound parameters, from a prompt"
            , "queue several statements without waiting for each result, and collect them"
            , "recognise the pipeline's version of an aborted transaction"
            ]
        , dayDiagram = Just d16diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("\\bind [param ...]", "Bind parameters for the next execution, and switch it to the extended protocol.")
            , ("\\bind_named name [param ...]", "The same, against a statement already prepared by " <> c "\\parse" <> ".")
            , ("\\parse name", "Prepare the buffer under a name. An empty string means the unnamed statement.")
            , ("\\close_prepared name", "Close a prepared statement. A no-op if there is no such statement.")
            , ("\\startpipeline \\endpipeline", "Open and close a pipeline. Everything inside uses the extended protocol.")
            , ("\\sendpipeline", "Append the current buffer to the pipeline. " <> c "\\g" <> " is refused inside one.")
            , ("\\syncpipeline", "Send a sync without ending the pipeline. Also the error-recovery point.")
            , ("\\flushrequest \\flush \\getresults", "Ask the server for results, push unsent bytes, read results back.")
            ]
        , dayOpts =
            [ ("PIPELINE_COMMAND_COUNT", "Commands queued in the current pipeline but not yet forced.")
            , ("PIPELINE_RESULT_COUNT", "Results the server has been asked for and you have not read.")
            , ("PIPELINE_SYNC_COUNT", "Syncs queued in the current pipeline.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Bind two parameters: "
                <> c "SELECT $1::int + $2::int \\bind 2 3 \\g"
                <> ". You have just used the protocol your application uses, from a prompt."
            , "Break it on purpose: supply one parameter for a query wanting two. Read the error — \
              \it is the server complaining about a bind message, not psql complaining about your \
              \typing."
            , "Prepare and reuse: "
                <> c "SELECT $1::text \\parse s1"
                <> ", then "
                <> c "\\bind_named s1 'hello' \\g"
                <> " twice, then "
                <> c "\\close_prepared s1"
                <> "."
            , "Set "
                <> c "\\set PROMPT1 '[P=%P] %/%R%# '"
                <> " and then "
                <> c "\\startpipeline"
                <> ". Watch the indicator go from "
                <> c "off"
                <> " to "
                <> c "on"
                <> " and back at "
                <> c "\\endpipeline"
                <> "."
            , "Queue two statements inside a pipeline, then "
                <> c "\\echo :PIPELINE_COMMAND_COUNT"
                <> " before you end it. Nothing has come back yet."
            , "Break it on purpose again: put a failing statement in a pipeline, then "
                <> c "\\flushrequest"
                <> " and "
                <> c "\\getresults"
                <> ". The indicator becomes "
                <> c "abort"
                <> " and every later command reports “Pipeline aborted, command did not run”."
            , "Recover the other way: do the same thing but use "
                <> c "\\syncpipeline"
                <> " instead. A sync is the error boundary, so the pipeline survives."
            , "Try a "
                <> c "COPY"
                <> " inside a pipeline, on a scratch connection. It does not merely fail — read \
                   \what it says about your connection."
            ]
        , dayQuiz =
            [
                ( "Your application reports a query plan quite different from the one you get in \
                  \psql, with the same SQL and the same data. Before blaming the planner, what \
                  \difference is there between the two clients?"
                , do
                    p_ $ do
                        "The protocol. psql uses the "
                        b_ "simple"
                        " query protocol — one string, parsed and planned and executed together, \
                        \with the constants right there in the text. Almost every driver uses the "
                        b_ "extended"
                        " protocol, where the statement is parsed with placeholders and the \
                        \parameter values arrive separately, so the planner may be working without \
                        \knowing the value it is filtering on."
                    p_ $ do
                        "Which is exactly what "
                        c "\\bind"
                        " lets you reproduce: "
                        c "SELECT ... WHERE x = $1 \\bind 'thevalue' \\g"
                        " goes over the extended protocol with a real bound parameter, so "
                        c "EXPLAIN"
                        " under "
                        c "\\bind"
                        " is comparable with what your application gets. It is the shortest route \
                        \out of “it is fast in psql” arguments."
                )
            ,
                ( "How long does "
                    <> c "\\bind"
                    <> " last, and what happens if you forget?"
                , do
                    p_ $ do
                        "One execution. The manual page is explicit: “this command affects only \
                        \the next query executed; all subsequent queries will use the simple query \
                        \protocol by default.” The same applies to "
                        c "\\parse"
                        " and "
                        c "\\close_prepared"
                        "."
                    p_ $ do
                        "So there is no mode to forget you are in — which is the right design for a \
                        \diagnostic tool, and it also means a benchmark loop has to repeat the "
                        c "\\bind"
                        " every time. Note that "
                        c "\\bind"
                        " with "
                        i_ "zero"
                        " parameters still switches protocol, which is how you test the extended \
                        \path for a query that has no placeholders at all."
                )
            ,
                ( "Inside a pipeline you run a failing statement, "
                    <> c "\\flushrequest"
                    <> ", "
                    <> c "\\getresults"
                    <> ". Now nothing works. What state are you in and how do you get out?"
                , do
                    p_ $ do
                        "An "
                        b_ "aborted pipeline"
                        " — "
                        c "%P"
                        " shows "
                        c "abort"
                        " — and every command you queue from now on answers “Pipeline aborted, \
                        \command did not run”. It is the pipeline's exact analogue of Day 8's \
                        \failed transaction block, including the part where it keeps accepting your \
                        \input and doing nothing with it."
                    p_ $ do
                        "Two ways out: "
                        c "\\endpipeline"
                        ", which returns "
                        c "%P"
                        " to "
                        c "off"
                        ", or a "
                        c "\\syncpipeline"
                        ", because a sync is the error-recovery boundary in the extended protocol. \
                        \Which is also why the same failing statement followed by "
                        c "\\syncpipeline"
                        " rather than "
                        c "\\flushrequest"
                        " never aborts in the first place."
                )
            ,
                ( "Why is a pipeline faster than the same statements sent one at a time, and why \
                  \is it not simply the default?"
                , do
                    p_ $ do
                        "Because it removes the round trips. Normally psql sends a statement and \
                        \waits for its result before sending the next, so a hundred statements over \
                        \a link with 20 ms latency costs two seconds in waiting alone. In a \
                        \pipeline the statements go out back to back and the results are collected \
                        \afterwards."
                    p_ $ do
                        "It is not the default because it changes what failure means. Without a \
                        \result in hand you cannot decide what to send next, error recovery becomes \
                        \a matter of sync points rather than statements, and "
                        c "COPY"
                        " does not work at all — psql answers “COPY in a pipeline is not supported, \
                        \aborting connection”, which is rather more than a failed command. \
                        \Interactive work wants the round trip; bulk work by a driver does not."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d16diagram :: Diagram
d16diagram =
    ( diagram
        "The simple query protocol is replaced, for one query, by the extended query protocol, \
        \which a prepared statement requires and a parameter binding switches psql to; a \
        \pipeline uses the extended protocol throughout and is punctuated by sync points, and an \
        \aborted pipeline is a state a sync point clears."
        body'
    )
        { dgCaption = do
            "psql is the odd client out: it speaks the "
            b_ "simple"
            " protocol, and everything your application does goes over the extended one. These \
            \commands are how you cross that gap by hand — which is why "
            c "EXPLAIN"
            " under "
            c "\\bind"
            " is comparable with production and "
            c "EXPLAIN"
            " at a bare prompt sometimes is not. The amber box is the pipeline's version of a \
            \failed transaction block: everything queued after an error is refused until a sync \
            \point or "
            c "\\endpipeline"
            "."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  simple [label=\"the simple\\nquery protocol\", fillcolor=\"#f4efe6\"];\n\
        \  ext    [label=\"the extended\\nquery protocol\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  bind   [label=\"a parameter binding\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  stmt   [label=\"a prepared statement\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  pipe   [label=\"a pipeline\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  sync   [label=\"a sync point\"];\n\
        \  ab     [label=\"an aborted pipeline\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  simple -> ext  [label=\"  is replaced, for one query, by\"];\n\
        \  bind   -> ext  [label=\"switches psql to  \"];\n\
        \  bind   -> stmt [label=\"  is made against\"];\n\
        \  stmt   -> ext  [label=\"  requires\"];\n\
        \  pipe   -> ext  [label=\"  uses, throughout,\"];\n\
        \  pipe   -> sync [label=\"is punctuated by  \"];\n\
        \  ab     -> pipe [label=\"  is a state of\"];\n\
        \  sync   -> ab   [label=\"  clears\", style=dashed];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "psql is the odd client out" $ do
        p_ [class_ "lede"] $ do
            "Everything you have typed so far went to the server over the "
            b_ "simple"
            " query protocol: one string, containing its own constants, parsed and planned and \
            \executed as a unit. Almost nothing else talks to PostgreSQL that way. Your \
            \application's driver uses the "
            b_ "extended"
            " protocol — parse a statement with placeholders, bind values to them, execute — and \
            \that difference is visible in the plans you get."
        p_ $ do
            "Which makes this the day that resolves “it is fast in psql”. When the planner sees "
            c "WHERE created > '2026-01-01'"
            " it can use the value; when it sees "
            c "WHERE created > $1"
            " at parse time it may not. "
            c "\\bind"
            " lets you ask the same question the application asks:"
        sh
            [ "testdb=# SELECT $1::int + $2::int AS sum \\bind 2 3 \\g"
            , " sum "
            , "-----"
            , "   5"
            , "(1 row)"
            ]
        p_ $ do
            "Read that line carefully, because the shape is unusual. The SQL goes in the buffer as \
            \normal, then "
            c "\\bind"
            " with its parameters, then a dispatcher. It works with "
            c "\\g"
            ", "
            c "\\gx"
            " and "
            c "\\gset"
            " — but not with a bare semicolon, because the semicolon would have dispatched the \
            \buffer before "
            c "\\bind"
            " was reached."
        why $ p_ $ do
            "The scope is one execution, deliberately. The manual page: “this command affects only \
            \the next query executed; all subsequent queries will use the simple query protocol by \
            \default.” There is no mode to forget you are in, which is right for a diagnostic tool \
            \— and it also means "
            c "\\bind"
            " with "
            i_ "zero"
            " parameters is meaningful, as the way to send a placeholder-free query over the \
            \extended protocol just to see what happens."
        fig

    block "Naming a statement" $ do
        p_ $ do
            "The three-step version separates parsing from execution, which is what a driver \
            \actually does when it reuses a statement:"
        sh
            [ "testdb=# SELECT $1::text AS greeting \\parse stmt1"
            , "testdb=# \\bind_named stmt1 'hello' \\g"
            , " greeting "
            , "----------"
            , " hello"
            , "(1 row)"
            , "testdb=# \\bind_named stmt1 'again' \\g"
            , "testdb=# \\close_prepared stmt1"
            ]
        p_ $ do
            c "\\parse"
            " issues a Parse message and nothing else — the statement exists on the server and has \
            \not run. "
            c "\\bind_named"
            " is "
            c "\\bind"
            " with a statement name in front, and an empty string names the "
            i_ "unnamed"
            " prepared statement, which is the one an ordinary "
            c "\\bind"
            " uses. "
            c "\\close_prepared"
            " tidies up, and is a no-op if the name does not exist."
        p_ $ do
            "This is not the same as SQL's "
            c "PREPARE"
            " and "
            c "EXECUTE"
            ", which live at the SQL level and are visible to the simple protocol. These four \
            \commands operate at the protocol level, which is the point: they are for finding out \
            \what the wire does, not for writing application logic in psql."
        note $ p_ $ do
            "Errors come back from the server in the server's own vocabulary, which is a good sign \
            \you are really exercising the protocol: bind two parameters to a query wanting three \
            \and you get “bind message supplies 2 parameters, but prepared statement \"\" requires \
            \3” — a protocol-level complaint, not a psql one."

    block "Not waiting for the answer" $ do
        p_ $ do
            "Normally psql sends a statement, waits for the result, and only then reads your next \
            \line. Over a link with 20 ms of latency, a hundred small statements spend two seconds \
            \doing nothing at all. A "
            b_ "pipeline"
            " sends them back to back and collects the results afterwards:"
        sh
            [ "testdb=# \\startpipeline"
            , "testdb=# SELECT 1;"
            , "testdb=# SELECT 2 \\bind \\sendpipeline"
            , "testdb=# \\flushrequest"
            , "testdb=# \\getresults"
            , " ?column? "
            , "----------"
            , "        1"
            , "(1 row)"
            , ""
            , " ?column? "
            , "----------"
            , "        2"
            , "(1 row)"
            , "testdb=# \\endpipeline"
            ]
        p_ "The vocabulary is small and each piece answers one question:"
        defs
            [ (c "\\startpipeline" <> " / " <> c "\\endpipeline", "the boundaries. Everything inside uses the extended protocol, whether or not you asked.")
            ,
                ( "a trailing " <> c ";"
                , "appends the statement to the pipeline. This is the ordinary way to queue something."
                )
            ,
                ( c "\\sendpipeline"
                , do
                    "appends the current buffer explicitly — needed after a "
                    c "\\bind"
                    ", because "
                    c "\\g"
                    " is refused inside a pipeline ("
                    c "\\g not allowed in pipeline mode"
                    ")."
                )
            ,
                ( c "\\flushrequest"
                , "asks the server to send what it has, so you can read results without ending the pipeline."
                )
            , (c "\\flush", "pushes psql's own unsent bytes at the server. Rarely needed; " <> c "\\getresults" <> " does it for you.")
            ,
                ( c "\\getresults [n]"
                , "reads pending results — the first " <> c "n" <> ", or all of them."
                )
            ,
                ( c "\\syncpipeline"
                , "sends a sync without ending the pipeline. Also the error boundary, which is the next section."
                )
            ]
        p_ $ do
            "Three variables let you see the state you are in: "
            opt "PIPELINE_COMMAND_COUNT"
            " (queued, not yet forced), "
            opt "PIPELINE_RESULT_COUNT"
            " (asked for, not yet read) and "
            opt "PIPELINE_SYNC_COUNT"
            ". And "
            c "%P"
            " in the prompt reports "
            c "off"
            ", "
            c "on"
            " or "
            c "abort"
            " — the one prompt escape from yesterday that is worth adding temporarily rather than \
            \permanently."

    block "The pipeline's failed transaction" $ do
        p_ $ do
            "An error inside a pipeline behaves almost exactly like an error inside a transaction \
            \block, and recognising the pattern is most of what you need:"
        sh
            [ "[P=off] =# \\startpipeline"
            , "[P=on] =# SELECT nosuch;"
            , "[P=on] =# \\flushrequest"
            , "[P=on] =# \\getresults"
            , "ERROR:  column \"nosuch\" does not exist"
            , "LINE 1: SELECT nosuch;"
            , "               ^"
            , "[P=abort] =# SELECT 1;"
            , "[P=abort] =# \\flushrequest"
            , "[P=abort] =# \\getresults"
            , "Pipeline aborted, command did not run"
            , "[P=abort] =# \\endpipeline"
            , "[P=off] =# "
            ]
        p_ $ do
            "Everything queued after the failure is refused, and psql goes on accepting your input \
            \and doing nothing with it — the same shape as “current transaction is aborted, \
            \commands ignored”, and the same reason to have the state in your prompt."
        p_ $ do
            "The way out is a "
            b_ "sync point"
            ", which is what "
            c "\\syncpipeline"
            " sends and what "
            c "\\endpipeline"
            " ends with. A sync is the extended protocol's error-recovery boundary: the server \
            \discards the failed work and becomes ready again. Which is why the same failing \
            \statement followed by "
            c "\\syncpipeline"
            " rather than "
            c "\\flushrequest"
            " never reaches the aborted state at all — the sync cleared it before you looked."
        gotcha $ p_ $ do
            c "COPY"
            " inside a pipeline does not fail politely. psql answers “COPY in a pipeline is not \
            \supported, "
            b_ "aborting connection"
            "” and the connection is gone — you are reconnecting, not recovering. The manual page \
            \puts it as a one-line “COPY is not supported while in pipeline mode”, which \
            \understates the consequence considerably."

    block "What this is actually for" $ do
        p_ "Three honest uses, and it is worth being clear that day-to-day psql needs none of them:"
        steps
            [ do
                b_ "Reproducing your application's plans."
                " "
                c "EXPLAIN (ANALYZE) SELECT ... WHERE x = $1 \\bind 'v' \\g"
                " is the same shape of request your driver makes, so the plan is comparable. This \
                \is the one that will earn its keep."
            , do
                b_ "Testing protocol-level behaviour."
                " Whether a statement can be prepared at all, what the server says about a bad \
                \bind, how a driver's reuse of the unnamed statement interacts with your DDL."
            , do
                b_ "Measuring the cost of round trips."
                " Time a hundred statements normally and then inside a pipeline, over the link you \
                \actually deploy across. It is the honest way to find out whether batching in your \
                \application would help."
            ]
        p_ $ do
            "Nothing here goes in your psqlrc. Unlike every other day since Day 6, this one adds \
            \no configuration — these are commands you reach for on a particular afternoon and \
            \then forget until the next one."

    block "Today's habit" $ do
        p_ $ do
            "Just the first one: the next time somebody says a query is fast in psql and slow in \
            \the application, run it once with "
            c "\\bind"
            " before discussing anything else. It takes ten seconds and it settles the question \
            \roughly half the time."
        p_ "Tomorrow: the sharp edges, and what to read next."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "psql speaks the simple protocol. Your application does not."
    cfg
        [ "SELECT $1::int + $2::int \\bind 2 3 \\g       -- extended protocol, real bound params"
        , "  works with \\g \\gx \\gset — NOT with a bare ; (that dispatches before \\bind is read)"
        , "  affects the NEXT execution only. \\bind with zero params still switches protocol."
        , "SELECT $1::text \\parse s1     \\bind_named s1 'v' \\g     \\close_prepared s1"
        , "  '' names the unnamed statement — the one a plain \\bind uses"
        , "EXPLAIN (ANALYZE) SELECT ... WHERE x = $1 \\bind 'v' \\g   <- the plan production gets"
        , "-- pipelining: send without waiting"
        , "\\startpipeline ... \\endpipeline      ;  queues a statement   \\sendpipeline queues the buffer"
        , "\\flushrequest  then  \\getresults [n]      \\syncpipeline = sync + error boundary"
        , ":PIPELINE_COMMAND_COUNT  :PIPELINE_RESULT_COUNT  :PIPELINE_SYNC_COUNT   prompt: %P"
        , "after an error: %P = abort, everything refused until a sync or \\endpipeline"
        , "COPY in a pipeline ABORTS THE CONNECTION, not just the command"
        ]
