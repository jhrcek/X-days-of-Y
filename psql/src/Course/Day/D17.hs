module Course.Day.D17 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 17
        , dayTitle = "Sharp edges"
        , daySubtitle = "Watching psql work, version skew, restricted dumps — and what to read next."
        , dayMinutes = 30
        , dayLevel = "advanced"
        , dayManRef = "ECHO_HIDDEN, NOTES, FETCH_COUNT, \\restrict, ENVIRONMENT, \\?"
        , dayTags = ["-E", "version skew", "finish"]
        , dayGoals =
            [ "read the catalogue query behind any \\d command, and steal it"
            , "say which direction psql/server version skew breaks in, and why"
            , "find the answer to a psql question in under a minute without leaving the terminal"
            ]
        , dayDiagram = Just d17diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("\\? [topic]", c "commands" <> " (default), " <> c "options" <> " or " <> c "variables" <> ". Three manuals, none of them the man page.")
            , ("\\encoding [name]", "Show or set the client encoding. Sets " <> opt "ENCODING" <> " too.")
            , ("\\restrict key  \\unrestrict key", "Block every meta-command but the matching " <> c "\\unrestrict" <> ". Used by " <> c "pg_dump" <> ".")
            ]
        , dayOpts =
            [ ("-E ECHO_HIDDEN", "Print the catalogue query behind each " <> c "\\d" <> ". " <> c "noexec" <> " prints without running.")
            , ("--help=topic", "The three " <> c "\\?" <> " topics, from the shell, before you have connected.")
            , ("FETCH_COUNT", "Display " <> c "SELECT" <> " results in groups of N rows. 0 (the default) means all at once.")
            , ("PGCLIENTENCODING", "Override the client encoding psql would otherwise detect from your locale.")
            , ("PG_COLOR", c "always" <> " / " <> c "auto" <> " / " <> c "never" <> " — colour in psql's own diagnostics.")
            , ("TMPDIR", "Where " <> c "\\e" <> " writes its scratch file. Default " <> c "/tmp" <> ".")
            ]
        , dayConfig =
            [ ConfBlock
                "The last two lines of the file, and they must be last. \\unset QUIET turns\n\
                \reporting back on, so that everything you type from now on confirms itself;\nand\
                \ one line of your own beats the four psql would have printed. Seeing the\ndatabase\
                \ and the host before your first statement has stopped more accidents\nthan any\
                \ other line here."
                "\\unset QUIET\n\\echo Connected to :DBNAME as :USER on :HOST port :PORT"
            ]
        , dayDrills =
            [ "Run "
                <> c "psql -E"
                <> " and then "
                <> c "\\dn"
                <> ". Read the query. It is a query you could have written, and now you do not have \
                   \to."
            , "Steal one: run "
                <> c "-E"
                <> " with "
                <> c "\\dt+"
                <> ", copy the query out, and put your own "
                <> c "WHERE"
                <> " on it. That is how every “list tables over 1 GB” script you have ever seen was \
                   \written."
            , "Try "
                <> c "\\set ECHO_HIDDEN noexec"
                <> " and run a few describe commands. You get the queries and no results, which is \
                   \the reading mode rather than the debugging one."
            , "Run "
                <> c "\\? variables"
                <> " and count how many of the thirty-odd variables you now recognise. That number \
                   \is what the last sixteen days bought you."
            , "Break something on purpose one last time: "
                <> c "\\restrict abc"
                <> ", then try "
                <> c "\\dt"
                <> ", then a plain "
                <> c "SELECT 1;"
                <> ". SQL still works and meta-commands do not. Then "
                <> c "\\unrestrict abc"
                <> "."
            , "Set "
                <> c "\\set FETCH_COUNT 1000"
                <> " and run a query returning a lot of rows in "
                <> c "aligned"
                <> " format. Find the row that overflows the border, and then do the same in "
                <> c "--csv"
                <> "."
            , "Add the two closing lines to your psqlrc, below everything else. Start psql and read \
              \your own greeting."
            , "Read your finished "
                <> c "~/.psqlrc"
                <> " top to bottom. If there is a line you cannot defend, delete it — including \
                   \any of the ones this course suggested."
            ]
        , dayQuiz =
            [
                ( "You need to list every table over a gigabyte, with its index sizes. Where does \
                  \the query come from?"
                , do
                    p_ $ do
                        "From psql, with "
                        c "-E"
                        ". Run "
                        c "\\dt+"
                        " with "
                        opt "ECHO_HIDDEN"
                        " on and psql prints the catalogue query it is about to issue, between "
                        c "/******** QUERY *********/"
                        " banners. Copy it, add your own "
                        c "WHERE"
                        " and "
                        c "ORDER BY"
                        ", and you have a correct query against "
                        c "pg_class"
                        " and "
                        c "pg_namespace"
                        " without having learned their column names."
                    p_ $ do
                        "This is the single best-value flag in psql and it is documented as being \
                        \for studying “psql's internal operations”, which undersells it \
                        \considerably. "
                        c "ECHO_HIDDEN=noexec"
                        " prints the queries "
                        i_ "without"
                        " running them, which is the right setting when you are reading rather than \
                        \debugging."
                )
            ,
                ( "A colleague running psql 13 against your PostgreSQL 18 server gets errors from "
                    <> c "\\d"
                    <> ". You run psql 18 against a PostgreSQL 12 server and everything works. Why \
                       \is it asymmetric?"
                , do
                    p_ $ do
                        "Because the "
                        c "\\d"
                        " family is not a server feature. Each command is a catalogue query "
                        b_ "compiled into psql"
                        ", so psql needs to know the shape of the catalogues it is querying. It can \
                        \contain compatibility branches for catalogues that existed when it was \
                        \built — the manual page promises the "
                        c "\\d"
                        " family back to server 9.2 — but it cannot know about catalogue changes \
                        \made after it was written."
                    p_ $ do
                        "So the rule is one-directional and easy to remember: "
                        b_ "use the newest psql you have"
                        ". The manual page says the same — “if you want to use psql to connect to \
                        \several servers of different major versions, it is recommended that you \
                        \use the newest version of psql”. Running SQL and displaying results is \
                        \generally fine in both directions; it is the backslash commands that break."
                )
            ,
                ( "You open a "
                    <> c "pg_dump"
                    <> " plain-text file, and partway through there is "
                    <> c "\\restrict aB3xY"
                    <> ". What is it for, and what happens if you paste the file into a session \
                       \without it?"
                , do
                    p_ $ do
                        "It puts psql into restricted mode, where the only meta-command accepted is \
                        \a "
                        c "\\unrestrict"
                        " with the matching key. Ordinary SQL still runs; every backslash command \
                        \answers “backslash commands are restricted; only \\unrestrict is allowed”."
                    p_ $ do
                        "The point is that a dump contains data, and data can contain text that \
                        \looks like a meta-command. Wrapping the risky region in "
                        c "\\restrict"
                        " with an unguessable key means a value in somebody's "
                        c "text"
                        " column cannot turn into a "
                        c "\\!"
                        " when the dump is restored. If you strip the pair out you lose that \
                        \protection — which matters exactly when you are restoring a dump you did \
                        \not produce."
                )
            ,
                ( "A query returns nine million rows and psql runs out of memory before printing \
                  \anything. What do you set, and what does it do to the output?"
                , do
                    p_ $ do
                        opt "FETCH_COUNT"
                        ", to something between 100 and 1000. Instead of collecting the whole result \
                        \set before displaying it, psql fetches and prints in groups of that many \
                        \rows, so memory use stops depending on the result size. The cost is that a \
                        \query can now fail "
                        i_ "after"
                        " you have already seen some rows."
                    p_ $ do
                        "And it disturbs the "
                        c "aligned"
                        " format, because column widths are computed from the first group only — \
                        \later, wider values overflow the border rather than widening it. The \
                        \manual page's advice is to use another format, and it is right: with "
                        c "--csv"
                        " or "
                        c "-A"
                        " there is no width to get wrong."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d17diagram :: Diagram
d17diagram =
    ( diagram
        "Your psql compiles a backslash-d command into a query against the system catalogues, \
        \which belong to the server it connects to; an older server is supported back to 9.2, \
        \while a newer server can break the command."
        body'
    )
        { dgCaption = do
            "The whole of psql's version story is in this shape. A "
            c "\\d"
            " command is "
            b_ "a catalogue query compiled into psql"
            ", not a request the server understands, so psql has to know the catalogues it is \
            \asking about. It can carry branches for catalogues older than itself; it cannot know \
            \about ones invented afterwards. Hence the amber aspect, and hence the one rule: use \
            \the newest psql you have, whatever server you are pointing it at."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  psql  [label=\"your psql\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  dcmd  [label=\"a \\\\d command\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  qry   [label=\"a catalogue query\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  cat   [label=\"the system catalogues\"];\n\
        \  srv   [label=\"the server it connects to\", fillcolor=\"#f4efe6\"];\n\
        \  newer [label=\"a server newer\\nthan your psql\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  psql  -> dcmd  [label=\"  offers\"];\n\
        \  dcmd  -> qry   [label=\"  is compiled, inside psql, into\"];\n\
        \  qry   -> cat   [label=\"  reads\"];\n\
        \  cat   -> srv   [label=\"  belong to\"];\n\
        \  psql  -> srv   [label=\"connects to  \"];\n\
        \  newer -> dcmd  [label=\"  can break\", style=dashed];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Watching psql work" $ do
        p_ [class_ "lede"] $ do
            "Every "
            c "\\d"
            " command is a query. Not a protocol feature, not a server command — a "
            c "SELECT"
            " against the system catalogues, written into psql's source. "
            c "-E"
            " shows it to you, and it is the single best-value flag in the program."
        sh
            [ "$ psql -E"
            , "testdb=# \\dn"
            , "/******** QUERY *********/"
            , "SELECT n.nspname AS \"Name\","
            , "  pg_catalog.pg_get_userbyid(n.nspowner) AS \"Owner\""
            , "FROM pg_catalog.pg_namespace n"
            , "WHERE n.nspname !~ '^pg_' AND n.nspname <> 'information_schema'"
            , "ORDER BY 1;"
            , "/************************/"
            , ""
            , "      List of schemas"
            , "  Name  |       Owner       "
            , "--------+-------------------"
            , " app    | postgres"
            , " public | pg_database_owner"
            ]
        p_ $ do
            "That is where the monitoring queries in everybody's snippets file came from. You want \
            \“tables over a gigabyte, with index sizes”: run "
            c "\\dt+"
            " under "
            c "-E"
            ", take the query, add a "
            c "WHERE"
            ". You have never had to learn that "
            c "pg_class.relkind"
            " is "
            c "'r'"
            " for a table, because psql knew."
        p_ $ do
            opt "ECHO_HIDDEN"
            " is the variable behind the flag, and it has a third setting worth knowing: "
            c "noexec"
            " prints the queries and does "
            i_ "not"
            " run them. That is the reading mode — you get the SQL without waiting for a "
            c "\\dt+"
            " to size forty thousand relations."
        why $ p_ $ do
            "It also explains a class of surprise from earlier days. A Tab completion is a query. A "
            c "\\d"
            " is a query. So “nothing but my statement crossed the connection” was never true, and \
            \Day 7's tab-completion race with "
            c "SET TRANSACTION ISOLATION LEVEL"
            " stops being mysterious the first time you watch it with "
            c "-E"
            "."
        p_ $ do
            "There is a second view of the same thing, from the other end. If you took Day 2's \
            \container, its first terminal is already running with "
            c "log_statement=all"
            " and "
            c "log_duration=on"
            ", so the server is telling you what it received — and that is not merely a duplicate \
            \of "
            c "-E"
            ", because it settles two questions the client cannot:"
        sh
            [ "-- psql -c 'CREATE TABLE m1(i int); CREATE TABLE m2(i int)'"
            , "LOG:  statement: CREATE TABLE m1(i int); CREATE TABLE m2(i int)"
            , "LOG:  duration: 1.153 ms"
            , ""
            , "-- SELECT $1::int + 1 \\bind 41 \\g"
            , "LOG:  execute <unnamed>: SELECT $1::int + 1"
            , "LOG:  duration: 0.014 ms"
            ]
        p_ $ do
            "The first is Day 11's claim made visible: two statements in one "
            c "-c"
            " arrive as "
            b_ "one"
            " logged statement, which is why they share a transaction. The second is Day 16's: "
            c "\\bind"
            " is logged as "
            c "execute"
            " rather than "
            c "statement:"
            ", because the server is being driven over the extended protocol. Neither is something \
            \you can see from the client side at all."
        tip $ p_ $ do
            "This is the cheapest way to settle any “what does psql actually send” argument, and it \
            \costs two "
            c "-c"
            " flags on a throwaway server. Do not leave "
            c "log_statement=all"
            " on anything real: it logs every statement, parameter values included, to a file \
            \somebody else can read."
        fig

    block "Version skew runs one way" $ do
        p_ $ do
            "Because the "
            c "\\d"
            " family lives in psql rather than the server, compatibility is asymmetric. psql can \
            \contain branches for catalogues older than itself; it cannot anticipate catalogues \
            \newer than itself. So:"
        defs
            [
                ( "psql newer than the server"
                , do
                    "fine. The manual page promises the "
                    c "\\d"
                    " family works against servers back to 9.2."
                )
            ,
                ( "psql older than the server"
                , "the configuration that breaks. Backslash commands are “particularly likely to fail”, in the manual page's words."
                )
            ,
                ( "running SQL either way"
                , "generally works, “but this cannot be guaranteed in all cases”."
                )
            ]
        p_ $ do
            "Hence the rule: "
            b_ "use the newest psql you have"
            ", whichever server you are pointing it at. The manual page recommends exactly that in \
            \preference to keeping one client per server version, and the reason people do not is \
            \that distributions install the client that matches their own server package. If you \
            \talk to several major versions, install the newest client deliberately."
        note $ p_ $ do
            "Two historical notes from the same section, both of which you will meet in old \
            \scripts. Before 9.6, "
            c "-c"
            " implied "
            c "-X"
            " — so a script written then and running now suddenly reads your psqlrc, which is Day \
            \11's argument for passing "
            c "-X"
            " explicitly. And before 8.4 a single-letter backslash command could have its argument \
            \jammed up against it; "
            c "\\dtfoo"
            " is now an unknown command rather than "
            c "\\dt foo"
            "."

    block "Restricted mode, and why a dump has it" $ do
        p_ $ do
            "New enough to be unfamiliar, and you will meet it in a "
            c "pg_dump"
            " file before you meet it anywhere else. "
            c "\\restrict"
            " takes an alphanumeric key and blocks every meta-command except an "
            c "\\unrestrict"
            " with the same key:"
        sh
            [ "testdb=# \\restrict aB3xY"
            , "testdb=# \\dt"
            , "backslash commands are restricted; only \\unrestrict is allowed"
            , "testdb=# SELECT 1;"
            , " ?column? "
            , "----------"
            , "        1"
            , "(1 row)"
            , "testdb=# \\unrestrict wrongkey"
            , "\\unrestrict: wrong key"
            , "testdb=# \\unrestrict aB3xY"
            ]
        p_ $ do
            "Note that SQL keeps working — this is not a lock, it is a shield for one specific \
            \threat. A plain-text dump contains data, and data can contain text that looks like a \
            \meta-command. Restoring such a dump by feeding it to psql would otherwise let a value \
            \in somebody's "
            c "text"
            " column become a "
            c "\\!"
            ". Wrapping the region in "
            c "\\restrict"
            " with a key the dump chose at random makes that impossible, because the attacker \
            \would have to guess the key."
        p_ $ do
            "The practical consequence: do not strip the pair out of a dump to make it tidier, and \
            \do not be alarmed when "
            c "grep"
            " finds it. If you use it yourself — around an "
            c "\\i"
            " of a file you do not fully trust — remember that "
            c "\\unrestrict"
            "'s argument is not interpolated, like "
            c "\\copy"
            "'s and "
            c "\\!"
            "'s."

    block "Two more edges" $ do
        p_ $ do
            b_ "Enormous result sets."
            " psql collects a whole result before displaying it, so nine million rows is an \
            \out-of-memory error rather than a slow print. "
            opt "FETCH_COUNT"
            " changes that: set it to something between 100 and 1000 and psql fetches and displays \
            \in groups. Two costs, and both are worth knowing before you set it in psqlrc:"
        steps
            [ do
                "A query can now fail "
                i_ "after"
                " you have seen some rows, because the failure happens partway through fetching."
            , do
                "In "
                c "aligned"
                " format the column widths are computed from the "
                b_ "first group only"
                ", so later wider values overflow the border instead of widening it. The manual \
                \page recommends another format, and it is right — with "
                c "--csv"
                " or "
                c "-A"
                " there is no width to get wrong."
            ]
        p_ $ do
            b_ "Encodings."
            " When both standard input and standard output are a terminal, psql sets the client \
            \encoding to "
            c "auto"
            " and derives it from your locale — "
            c "LC_CTYPE"
            " on Unix. When they are not a terminal, it does not, which is why a script can mangle \
            \characters that were fine interactively. "
            c "PGCLIENTENCODING"
            " overrides it, and "
            c "\\encoding"
            " shows or changes it mid-session (and updates "
            opt "ENCODING"
            ")."
        p_ $ do
            "Two smaller ones to file away. "
            c "PG_COLOR"
            " ("
            c "always"
            "/"
            c "auto"
            "/"
            c "never"
            ") controls colour in psql's own diagnostics, which is worth "
            c "never"
            " in a log-scraping context. And "
            c "TMPDIR"
            " is where "
            c "\\e"
            " writes its scratch file, which matters if "
            c "/tmp"
            " is small, noexec, or shared."

    block "Finding the answer in under a minute" $ do
        p_ $ do
            "You will not remember all of this, and you do not need to. psql carries three \
            \reference manuals of its own, and none of them is the man page:"
        defs
            [ (c "\\?" <> " or " <> c "\\? commands", "every meta-command, in the twelve groups from Day 1. This is the one you will use.")
            , (c "\\? options", "the command-line options.")
            , (c "\\? variables", "the thirty-odd special variables, with their allowed values in brackets.")
            , (c "\\h NAME", "SQL syntax for one command. " <> c "\\h" <> " alone lists what it knows; " <> c "\\h *" <> " prints all of it.")
            ]
        p_ $ do
            "All three "
            c "\\?"
            " topics are available before you connect, as "
            c "--help=commands"
            ", "
            c "--help=options"
            " and "
            c "--help=variables"
            ". And "
            c "\\? variables"
            " is worth one deliberate read now: after sixteen days you will recognise most of the \
            \list, and the handful you do not are a fair map of what this course left out."
        p_ $ do
            "When the answer is not in psql, it is in the PostgreSQL manual, and the psql page \
            \points at the sections by number rather than by name. The ones it refers to most, so \
            \you can find them:"
        defs
            [ ("§32.1.1–32.1.2", "connection strings and every libpq parameter — the full vocabulary for Day 2's conninfo")
            , ("§32.15, §32.16", "the environment variables and the password file")
            , ("§32.5", "pipelining, from the library's side rather than psql's — Day 16's other half")
            , ("§54.1.2, §54.2.2.1", "the extended query protocol, and how the server treats a multi-statement request")
            , ("§5.8", "how to read a privilege display — Day 4's letters, defined")
            , ("§9.7.3", "regular expressions, which is what Day 3's patterns are underneath")
            ]

    block "What you have, and what is next" $ do
        p_ $ do
            "The file in your home directory is the artefact. Read it top to bottom once, and \
            \delete anything you cannot defend — including anything this course suggested. A psqlrc \
            \you inherited from a stranger is exactly the thing this was meant to replace."
        p_ $ do
            "Three directions from here, none of them psql. "
            c "pg_dump"
            " and "
            c "pg_restore"
            " share psql's connection options and conventions, so Day 2 transfers to them \
            \wholesale. "
            c "pspg"
            " is the pager that understands psql's output, and the reason "
            c "PSQL_WATCH_PAGER"
            " exists. And the catalogue queries you started stealing on this page are the beginning \
            \of your own monitoring — the "
            c "pg_stat_"
            " views are the other half, and "
            c "-E"
            " taught you how to read them."
        p_ $ do
            "The thing worth keeping from seventeen days is smaller than the syllabus: psql is a \
            \buffer, a set of variables, and a printing engine, and every command is described in \
            \terms of one of the three. When you meet something new in the manual page, work out \
            \which of the three it acts on. That is the whole trick."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Three manuals inside psql, and none of them is the man page."
    cfg
        [ "\\?           -- every meta-command, in 12 groups     --help=commands  from the shell"
        , "\\? options    -- the command line                     --help=options"
        , "\\? variables  -- the ~30 special variables            --help=variables"
        , "\\h NAME      -- SQL syntax for one command           \\h  lists them, \\h *  prints all"
        , "psql -E      -- print the catalogue query behind every \\d.  STEAL THESE."
        , "  \\set ECHO_HIDDEN noexec   -- show the queries WITHOUT running them"
        , "-- version skew runs one way: use the NEWEST psql you have"
        , "  psql newer than server: fine, \\d works back to server 9.2"
        , "  psql older than server: backslash commands break"
        , "\\restrict KEY / \\unrestrict KEY   -- pg_dump's shield: SQL still runs, \\commands do not"
        , "\\set FETCH_COUNT 1000  -- stream huge results; aligned widths come from the FIRST group"
        , "\\encoding | PGCLIENTENCODING | PG_COLOR=never | TMPDIR (where \\e writes)"
        ]
