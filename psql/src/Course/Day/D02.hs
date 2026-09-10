module Course.Day.D02 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 2
        , dayTitle = "Getting connected"
        , daySubtitle = "Four parameters, five places they can come from, and one file that stops you typing passwords."
        , dayMinutes = 35
        , dayLevel = "essential"
        , dayManRef = "OPTIONS, Connecting to a Database, ENVIRONMENT"
        , dayTags = ["conninfo", "pgpass", "\\c"]
        , dayGoals =
            [ "connect with a conninfo string or a URI instead of four separate flags"
            , "stop typing passwords, using ~/.pgpass and a named service entry"
            , "predict what \\c will keep and what it will silently drop"
            ]
        , dayDiagram = Just d2diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("\\c dbname", "Reconnect to another database, reusing host, port and user.")
            , ("\\c - user", "Reconnect as another user. A dash means “leave that one as it is”.")
            , ("\\c -reuse-previous=on ...", "Merge a conninfo string onto the current parameters.")
            , ("\\conninfo", "A twelve-row table describing the live connection.")
            , ("\\password", "Change a password without it reaching your history or the server log.")
            , ("\\encoding", "Show the client encoding, or set it.")
            ]
        , dayOpts =
            [ ("-h -p -U -d", "Host, port, user, database. " <> c "-d" <> " also takes a whole conninfo string.")
            , ("-w -W", "Never prompt for a password / always prompt. Both persist across " <> c "\\c" <> ".")
            , ("-l", "List databases and exit. Connects to " <> c "postgres" <> " unless told otherwise.")
            , ("PGHOST PGPORT PGUSER PGDATABASE", "libpq's defaults for the four parameters.")
            , ("PGPASSFILE", "The password file. Default " <> c "~/.pgpass" <> ", and it must be mode 0600.")
            , ("PGSERVICEFILE", "Named connection recipes. Default " <> c "~/.pg_service.conf" <> ".")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Run "
                <> c "psql -l"
                <> ". You now know what databases you can reach without having connected to any of \
                   \them in particular."
            , "Connect the long way — "
                <> c "psql -h HOST -p 5432 -U USER -d DB"
                <> " — then run "
                <> c "\\conninfo"
                <> " and read all twelve rows. Note "
                <> c "Superuser"
                <> " and "
                <> c "Backend PID"
                <> "; you will want both later."
            , "Rewrite that same connection as one conninfo string ("
                <> c "psql \"host=… port=… user=… dbname=…\""
                <> ") and again as a URI ("
                <> c "psql postgresql://user@host:5432/db"
                <> "). Confirm all three land in the same place."
            , "Write a "
                <> c "~/.pgpass"
                <> " line for a database you use daily and connect without a prompt. Then "
                <> c "chmod 644"
                <> " it and connect again — read the warning, and notice the file is ignored rather \
                   \than trusted."
            , "Put that same connection in "
                <> c "~/.pg_service.conf"
                <> " under a name, and connect with "
                <> c "psql service=thatname"
                <> ". This is the version you will actually type in six months."
            , "Break it on purpose: "
                <> c "psql -w -h localhost -p 1"
                <> ". Read the error, then check "
                <> c "echo $?"
                <> " — it is 2, which is the code for “the connection went bad”, not 1."
            , "From inside a session, "
                <> c "\\c postgres"
                <> " and then "
                <> c "\\c -"
                <> " some other role. Watch the prompt's database name and its final character change."
            , "Add the service entry for whichever database you connect to most often, and stop \
              \typing flags. That is the habit; the rest of today was so you can debug it."
            ]
        , dayQuiz =
            [
                ( "You are connected to "
                    <> c "db1"
                    <> " on a remote host, port 6432. You run "
                    <> c "\\c \"dbname=db2\""
                    <> " and psql tries to reach a Unix socket on your laptop. Why?"
                , do
                    p_ $ do
                        "Because parameters are reused in the "
                        b_ "positional"
                        " syntax but not when you give a conninfo string. Your string mentioned only "
                        c "dbname"
                        ", so host and port fell back to libpq's defaults — a local socket — rather \
                        \than to the connection you were sitting on."
                    p_ $ do
                        "Either write "
                        c "\\c db2"
                        " positionally, or say so explicitly: "
                        c "\\c -reuse-previous=on \"dbname=db2\""
                        ". The reverse override, "
                        c "-reuse-previous=off"
                        ", exists for the positional form."
                )
            ,
                ( c "\\c - otheruser"
                    <> " fails with “password authentication failed”, even though you connected \
                       \fine a moment ago and did not type a password then. What is the rule?"
                , do
                    p_ $ do
                        "A password is reused only if user, host and port are all unchanged. You \
                        \changed the user, so psql refuses to hand the old password to the new \
                        \role — which is right, because they are different credentials."
                    p_ $ do
                        "Give "
                        c "otheruser"
                        " its own line in "
                        c "~/.pgpass"
                        " and it will connect silently. Note also that "
                        c "-w"
                        " and "
                        c "-W"
                        " persist for the whole session: if you started with "
                        c "-w"
                        ", no "
                        c "\\c"
                        " will ever prompt you."
                )
            ,
                ( "A colleague's script does "
                    <> c "psql -h prod-db -d \"host=localhost dbname=app\""
                    <> " and it keeps hitting localhost. They insist the "
                    <> c "-h"
                    <> " is right there. Who wins?"
                , do
                    p_ $ do
                        "The conninfo string. The manual page is explicit: “connection string \
                        \parameters will override any conflicting command line options”. It reads \
                        \backwards — the thing further left looks more specific — but the string is \
                        \parsed later and wins."
                    p_ $ do
                        "This is worth knowing precisely because it is how a stray "
                        c "PGDATABASE"
                        " or a checked-in conninfo string sends a migration at the wrong server."
                )
            ,
                ( "Your batch job hangs for hours instead of failing. It runs psql from cron with \
                  \no terminal. What did it forget?"
                , do
                    p_ $ do
                        c "-w"
                        ". Without it, a server that wants a password gets psql to prompt for one, \
                        \and with no terminal to type into the job simply waits. "
                        c "-w"
                        " makes the connection attempt fail immediately unless the password is \
                        \available from somewhere non-interactive — "
                        c "~/.pgpass"
                        ", "
                        c "PGPASSWORD"
                        ", or a service entry."
                    p_ $ do
                        "Prefer the password file to "
                        c "PGPASSWORD"
                        ": an environment variable is visible to anything that can read "
                        c "/proc"
                        ", while the file at least has to be mode 0600 before libpq will look at it."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d2diagram :: Diagram
d2diagram =
    ( diagram
        "The four connection parameters can be set by command-line options, PG* environment \
        \variables, a conninfo string or URI, or a service entry, with libpq defaults last; the \
        \parameters determine a connection, and the password file supplies its password."
        body'
    )
        { dgCaption = do
            "There is only one set of "
            b_ "connection parameters"
            "; the five boxes above it are competing ways to fill the same four slots, and a \
            \conninfo string wins over the flags rather than losing to them. The two dashed \
            \aspects are the ones that make a connection quiet: a service entry you named once, \
            \and a password file you never think about again."
        , dgRankdir = "TB"
        , dgRanksep = "0.5"
        }
  where
    body' =
        "  opts [label=\"the -h -p -U -d\\noptions\"];\n\
        \  kv   [label=\"a conninfo string\\nor URI\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  env  [label=\"PGHOST, PGPORT,\\nPGUSER, PGDATABASE\", fillcolor=\"#f4efe6\"];\n\
        \  dflt [label=\"a libpq default\", fillcolor=\"#f4efe6\"];\n\
        \  svc  [label=\"a service entry in\\n~/.pg_service.conf\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  par  [label=\"the connection parameters\\n(host, port, user, dbname)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  conn [label=\"a connection\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  pass [label=\"~/.pgpass\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  opts -> par  [label=\"  set\"];\n\
        \  kv   -> par  [label=\"  overrides\"];\n\
        \  env  -> par  [label=\"  default\"];\n\
        \  dflt -> par  [label=\"  fills what is left of\"];\n\
        \  svc  -> par  [label=\"  expands into\"];\n\
        \  kv   -> svc  [label=\"can name  \", style=dashed, constraint=false];\n\
        \  par  -> conn [label=\"  determine\"];\n\
        \  pass -> conn [label=\"  supplies the password for  \", style=dashed];\n\
        \\n\
        \  { rank=same; opts; kv; env; dflt; svc; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Something to connect to" $ do
        p_ [class_ "lede"] $ do
            "If you already have a database you are willing to break, skip this section. If you \
            \have only the client — which is what a distribution's "
            c "postgresql"
            " package often installs — then one command gives you a whole server to practise on, \
            \and it is worth having before Day 1's drills rather than after."
        sh
            [ "$ docker run --rm --name pgcourse \\"
            , "    -p 5432:5432 \\"
            , "    -e POSTGRES_PASSWORD=postgres \\"
            , "    -e PGDATA=/var/lib/postgresql/data/pgdata \\"
            , "    --tmpfs /var/lib/postgresql/data/pgdata \\"
            , "    postgres:18.6-alpine \\"
            , "    -c log_statement=all -c log_duration=on"
            ]
        p_ "Every part of that is doing something, and two of the parts are the reason to prefer it to a real installation:"
        defs
            [
                ( c "--tmpfs" <> " with " <> c "PGDATA"
                , do
                    "the data directory is a RAM disk, so the entire database disappears when the \
                    \container stops. That is the point rather than a limitation: you are about to \
                    \be told to break things on purpose, and “start it again” is the whole recovery \
                    \procedure."
                )
            ,
                ( "no " <> c "-d"
                , do
                    "it runs in the foreground, so this terminal becomes the server's log. Run psql \
                    \in a second one. "
                    k "C-c"
                    " stops the server, and "
                    c "--rm"
                    " means it leaves nothing behind."
                )
            ,
                ( c "-c log_statement=all"
                , do
                    "log every statement the server receives, and with "
                    c "log_duration=on"
                    " how long each took. This turns the first terminal into a live view of what \
                    \psql actually sends — which is worth more on this course than it would be on \
                    \a real server, and is revisited on Day 17."
                )
            ,
                ( c "-p 5432:5432"
                , do
                    "the default port, so psql needs no "
                    c "-p"
                    ". If you do already have something on 5432, use "
                    c "-p 55432:5432"
                    " and add "
                    c "-p 55432"
                    " to every psql command from here on."
                )
            ]
        p_ "Then, in the second terminal:"
        sh
            [ "$ export PGPASSWORD=postgres"
            , "$ psql -h localhost -U postgres"
            , "psql (18.6)"
            , "Type \"help\" for help."
            , ""
            , "postgres=#"
            ]
        p_ $ do
            "Note the "
            c "-h localhost"
            ", and try leaving it out — you will get “connection to server on socket \
            \\"/var/run/postgresql/.s.PGSQL.5432\" failed”. The container speaks TCP and has no \
            \socket on your filesystem, which is the next section's first point arriving early."
        note $ do
            p_ $ do
                "On its very first start the image runs "
                c "initdb"
                ", listens briefly, shuts down and starts properly, so a connection attempt in the \
                \first second or two can fail with “server closed the connection unexpectedly”. \
                \Wait for “database system is ready to accept connections” in the first terminal, \
                \or use "
                c "pg_isready -h localhost"
                "."
            p_ $ do
                "The examples throughout this course use two tables. Paste this once and every \
                \drill runs verbatim:"
            cfg
                [ "CREATE TABLE my_table (first integer not null default 0, second text);"
                , "INSERT INTO my_table VALUES (1,'one'),(2,'two'),(3,'three'),(4,'four');"
                , "COMMENT ON TABLE my_table IS 'a scratch table';"
                , ""
                , "CREATE SCHEMA app;"
                , "CREATE TABLE app.orders (id serial primary key, customer text,"
                , "                         total numeric(10,2));"
                , "INSERT INTO app.orders (customer,total)"
                , "     VALUES ('acme',10.50),('globex',99.99),(NULL,0);"
                ]
            p_ $ do
                "The "
                c "app"
                " schema is deliberately not on your "
                c "search_path"
                " and the NULL "
                c "customer"
                " is deliberately there; Days 3 and 5 need both."

    block "Four parameters, and nothing else" $ do
        p_ [class_ "lede"] $ do
            "A connection needs a host, a port, a user and a database. Everything the manual page \
            \says about connecting is about where those four values come from — and it offers five \
            \places, which is why people who have used psql for years still occasionally end up in \
            \the wrong database."
        p_ $ do
            "The defaults are more generous than people expect. Omit the host and you get a \
            \Unix-domain socket on the local machine. Omit the port and you get whatever the server \
            \was compiled with, normally 5432. Omit the user and you get your operating-system user \
            \name — and then, because a database name is also needed, "
            i_ "that same name is used as the database"
            ". Which is why "
            c "psql"
            " on a fresh machine so often says “database \"jhrcek\" does not exist”: nothing is \
            \broken, it simply took your login name twice."
        p_ $ do
            "Positional arguments fill in the gaps in a fixed order: the first non-option argument \
            \is the database, the second is the user. So "
            c "psql testdb alice"
            " and "
            c "psql -d testdb -U alice"
            " are the same invocation."
        fig

    block "Say it once, in a string" $ do
        p_ $ do
            "Four flags is three too many to type twice. Anywhere a database name is accepted, you \
            \may instead give a "
            b_ "conninfo string"
            " or a URI, and then everything libpq understands is available — not just the four \
            \parameters but timeouts, SSL policy, application names, and the "
            c "options"
            " passthrough that sets server parameters at connect time."
        sh
            [ "$ psql \"host=db.internal port=6432 dbname=app user=alice connect_timeout=5\""
            , "$ psql \"postgresql://alice@db.internal:6432/app?sslmode=require\""
            , "$ psql \"service=staging sslmode=require\""
            ]
        gotcha $ p_ $ do
            "A conninfo string "
            b_ "overrides"
            " conflicting command-line options, whichever order you wrote them in. "
            c "psql -h prod -d \"host=localhost dbname=app\""
            " connects to localhost. The flag looks more specific and is not; the string is parsed \
            \afterwards and wins."
        p_ $ do
            "The tidiest form is the last one. A "
            b_ "service entry"
            " is a named block in "
            c "~/.pg_service.conf"
            " holding as many parameters as you like, and "
            c "service=name"
            " expands it:"
        cfg
            [ "# ~/.pg_service.conf"
            , "[staging]"
            , "host=db.staging.internal"
            , "port=6432"
            , "user=alice"
            , "dbname=app"
            ]
        p_ $ do
            "After which "
            c "psql service=staging"
            " is the whole invocation, and so is "
            c "PGSERVICE=staging psql"
            ". Scripts that take a service name rather than a host are the ones that survive a \
            \migration to a new database server."

    block "The file that stops you typing passwords" $ do
        p_ $ do
            c "~/.pgpass"
            " is a list of colon-separated lines, most specific first, each of them "
            c "host:port:database:user:password"
            ". Any of the first four fields may be "
            c "*"
            "."
        cfg
            [ "# ~/.pgpass   — and it must be chmod 600"
            , "db.staging.internal:6432:*:alice:s3cret"
            , "127.0.0.1:5432:*:*:localdev"
            ]
        p_ $ do
            "Set "
            c "PGPASSFILE"
            " to keep it somewhere else. Note that the password field is the "
            i_ "only"
            " one that is not a pattern, and that the file is consulted for "
            c "\\c"
            " as well as for the initial connection."
        gotcha $ do
            p_ $ do
                "Permissions are enforced, and the failure is quiet enough to waste an afternoon. \
                \Group or world access does not make libpq refuse to start — it makes it warn and \
                \then ignore the file entirely, so you get an authentication error that says \
                \nothing about permissions:"
            sh
                [ "WARNING: password file \"/home/alice/.pgpass\" has group or world access;"
                , "         permissions should be u=rw (0600) or less"
                , "psql: error: connection to server at \"127.0.0.1\", port 5432 failed:"
                , "         fe_sendauth: no password supplied"
                ]
        p_ $ do
            "Two flags decide what happens when no password is available. "
            c "-W"
            " prompts before connecting, which saves the wasted round trip of finding out the \
            \server wanted one. "
            c "-w"
            " never prompts and fails instead — the flag every cron job needs, because a psql \
            \waiting at an invisible password prompt looks exactly like a psql doing slow work. \
            \Both persist for the whole session, "
            c "\\c"
            " included."
        tip $ p_ $ do
            "Prefer the password file to "
            c "PGPASSWORD"
            ". An environment variable is readable by anything that can see the process; the file \
            \at least has to be mode 0600 before it is trusted at all."

    block "Moving without leaving" $ do
        p_ $ do
            c "\\c"
            " reconnects in place. In its positional form it keeps everything you do not mention, \
            \and a bare dash means “this one stays as it is”:"
        sh
            [ "testdb=# \\c postgres"
            , "You are now connected to database \"postgres\" as user \"postgres\"."
            , "postgres=# \\c - reporter"
            , "You are now connected to database \"postgres\" as user \"reporter\"."
            , "postgres=> \\conninfo"
            ]
        p_ $ do
            "Two details worth having. Parameters are reused positionally but "
            b_ "not"
            " when you pass a conninfo string, so "
            c "\\c \"dbname=other\""
            " starts from libpq's defaults and can leave a remote session pointing at your laptop; "
            c "-reuse-previous=on"
            " fixes that. And a password is only reused when user, host and port are all unchanged, \
            \which is why "
            c "\\c - someoneelse"
            " so often asks for one."
        p_ $ do
            "The failure behaviour differs on purpose. Interactively, a failed "
            c "\\c"
            " leaves you on the old connection — it assumes you mistyped. Non-interactively the old \
            \connection is closed and psql reports an error, so that a script cannot carry on \
            \against the wrong database because a "
            c "\\c"
            " silently did nothing."
        note $ p_ $ do
            "Every connect resets a handful of psql variables you can read: "
            c "DBNAME"
            ", "
            c "HOST"
            ", "
            c "PORT"
            ", "
            c "USER"
            ", "
            c "ENCODING"
            ", "
            c "SERVER_VERSION_NAME"
            " and "
            c "SERVICE"
            ". "
            c "\\echo :DBNAME"
            " is the cheapest way for a script to say where it ended up; Day 12 makes proper use \
            \of them."

        p_ $ do
            "One last thing while we are on failures. psql has four exit codes, and it is worth \
            \meeting them here rather than on Day 11, because the one you will hit first is the \
            \connection one:"
        defs
            [ (c "0", "finished normally")
            , (c "1", "a fatal error of psql's own — out of memory, file not found, a bad flag")
            ,
                ( c "2"
                , "the connection to the server went bad and the session was not interactive. This \
                  \is what a refused connection, a wrong password or a missing database gives you."
                )
            ,
                ( c "3"
                , do
                    "an error occurred in a script "
                    i_ "and"
                    " "
                    opt "ON_ERROR_STOP"
                    " was set. Day 11."
                )
            ]
        p_ $ do
            "So a wrapper script that wants to distinguish “could not reach the database” from “the \
            \SQL was wrong” has that distinction available for free, and almost nobody uses it."

    block "Today's habit" $ do
        p_ $ do
            "Write the service entry. One block in "
            c "~/.pg_service.conf"
            ", one line in "
            c "~/.pgpass"
            ", and the database you touch most often is "
            c "psql service=work"
            " from now on — no flags to mistype and no password to leak into your shell history."
        p_ "Tomorrow: finding your way around a database you have never seen before."

cheat :: Html ()
cheat =
    cfg
        [ "psql                          -- socket on localhost, $USER as both user and database"
        , "psql -h H -p P -U U -d D      -- the long way"
        , "psql \"host=H port=P dbname=D user=U connect_timeout=5\"    -- overrides the flags above"
        , "psql \"postgresql://U@H:P/D?sslmode=require\"               -- same thing, URI form"
        , "psql service=work             -- ~/.pg_service.conf  [work] host=… port=… dbname=…"
        , "~/.pgpass  host:port:db:user:password   -- chmod 600 or it is silently ignored"
        , "-w  never prompt (use in cron)          -W  always prompt (saves a round trip)"
        , "\\c db          -- reuses host/port/user      \\c - user   -- keeps the database"
        , "\\c -reuse-previous=on \"dbname=d\"  -- merge a conninfo string onto what you have"
        , "\\conninfo      -- twelve rows: host, port, user, PID, SSL, superuser, hot standby"
        , "exit 0 fine | 1 psql's own error | 2 connection went bad | 3 script error + ON_ERROR_STOP"
        ]
