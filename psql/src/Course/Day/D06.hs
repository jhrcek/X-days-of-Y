module Course.Day.D06 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 6
        , dayTitle = "Your own psqlrc"
        , daySubtitle = "One startup file, three different things called “set”, and the typo nobody catches."
        , dayMinutes = 35
        , dayLevel = "essential"
        , dayManRef = "FILES, Variables, ENVIRONMENT"
        , dayTags = ["psqlrc", "\\set", "variables"]
        , dayGoals =
            [ "put yesterday's settings in a file that loads every time, without the start-up chatter"
            , "tell \\set, \\pset and SET apart, and say which of the three the server ever hears about"
            , "explain why a mistyped control-variable name is accepted without complaint"
            ]
        , dayDiagram = Just d6diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("\\set", "With no argument, list every variable currently set, with its value.")
            , ("\\set NAME value", "Set a psql variable. Several values are concatenated.")
            , ("\\unset NAME", "Delete it — or, for a control variable, restore its default.")
            , ("\\echo :NAME", "Read a variable back. The cheapest debugging tool psql has.")
            , ("\\i ~/.psqlrc", "Re-read the startup file without restarting. Tilde expansion works.")
            ]
        , dayOpts =
            [ ("-X", "Skip both startup files. Every script should pass this.")
            , ("PSQLRC", "Where the personal startup file lives. Overrides " <> c "~/.psqlrc" <> ".")
            , ("PGSYSCONFDIR", "Where the system-wide " <> c "psqlrc" <> " is looked for.")
            , ("QUIET", "Suppress psql's informational chatter. The startup file's bookends.")
            , ("VERSION_NAME SERVER_VERSION_NUM", "psql's version and the server's, as a string and a number.")
            ]
        , dayConfig =
            [ ConfBlock
                "Load quietly. Without this, every \\set and \\pset below announces itself\nevery\
                \ time you start psql, and you learn to ignore psql's messages — which\nis exactly\
                \ the habit you do not want. The matching \\unset QUIET is the last\nline of this\
                \ file, so anything you type yourself still reports back."
                "\\set QUIET on"
            , ConfBlock
                "Never confuse a NULL with an empty string again. psql prints nothing for\nNULL by\
                \ default, which in a padded column is indistinguishable from ''."
                "\\pset null '(null)'"
            , ConfBlock
                "Go vertical only when a row is genuinely too wide, rather than never or\nalways.\
                \ Narrow results stay as tables; twelve-column rows stop wrapping\ninto soup."
                "\\pset expanded auto"
            , ConfBlock
                "Box-drawing borders. Pure cosmetics, and worth it the first time somebody\nasks\
                \ you to share your screen. Drop these two lines if you work over a\nterminal that\
                \ mangles Unicode."
                "\\pset linestyle unicode\n\\pset border 2"
            ]
        , dayDrills =
            [ "Run "
                <> c "\\set"
                <> " with no arguments. Everything in capitals is a variable psql itself pays \
                   \attention to; there are about thirty of them."
            , "Create "
                <> c "~/.psqlrc"
                <> " containing nothing but "
                <> c "\\pset null '(null)'"
                <> ". Start psql. Notice it says “Null display is \"(null)\".” at you before the \
                   \prompt appears."
            , "Add "
                <> c "\\set QUIET on"
                <> " as the first line and "
                <> c "\\unset QUIET"
                <> " as the last. Start psql again — silence, and the setting is still applied. \
                   \Confirm with "
                <> c "\\pset null"
                <> "."
            , "Break it on purpose: put "
                <> c "\\set ON_ERROR_STOPP on"
                <> " in the file, with the extra P. psql accepts it without a murmur. Then try "
                <> c "\\set ON_ERROR_STOP maybe"
                <> " and watch it refuse. Understand why one is checked and the other is not."
            , "Run "
                <> c "psql -X"
                <> " and confirm your file was skipped. Then "
                <> c "\\i ~/.psqlrc"
                <> " to pull it in by hand — that is also how you test a change without restarting."
            , "Put "
                <> c "\\echo Connected to :DBNAME as :USER"
                <> " at the end of your file, "
                <> i_ "after"
                <> " the "
                <> c "\\unset QUIET"
                <> ". Connect to two different databases and watch it change."
            , "Find out where the system-wide file would be: "
                <> c "pg_config --sysconfdir"
                <> ". Look for a "
                <> c "psqlrc"
                <> " there. On most machines there is none, and now you know that for certain \
                   \rather than assuming it."
            , "Move yesterday's two settings into the file for good. From today you have a psqlrc, \
              \and every remaining day of this course adds a line or two to it."
            ]
        , dayQuiz =
            [
                ( "You put "
                    <> c "\\set ON_ERROR_STOPP on"
                    <> " in your psqlrc — one letter wrong. Why does psql not complain, when it \
                       \happily rejects "
                    <> c "\\set ON_ERROR_STOP maybe"
                    <> "?"
                , do
                    p_ $ do
                        "Because a control variable is just a psql variable whose "
                        i_ "name"
                        " psql recognises. "
                        c "ON_ERROR_STOPP"
                        " is not a name it knows, so it becomes an ordinary user variable holding \
                        \the string “on”, which is a perfectly legal thing to do. Nothing is wrong \
                        \from psql's point of view; you simply created a variable nobody reads."
                    p_ $ do
                        "Whereas "
                        c "ON_ERROR_STOP"
                        b_ " is"
                        " recognised, so its "
                        i_ "value"
                        " is validated — “unrecognized value \"maybe\" for \"ON_ERROR_STOP\": \
                        \Boolean expected”, and the variable is left at its previous setting. \
                        \Names are unchecked, values are checked. "
                        c "\\echo :ON_ERROR_STOP"
                        " after any change is the two-second confirmation."
                )
            ,
                ( c "\\set"
                    <> ", "
                    <> c "\\pset"
                    <> " and "
                    <> c "SET"
                    <> ". Which of the three does the server ever find out about?"
                , do
                    p_ $ do
                        "Only "
                        c "SET"
                        ", which is SQL and sets a server parameter for the session — "
                        c "search_path"
                        ", "
                        c "statement_timeout"
                        ", "
                        c "timezone"
                        ". The other two never leave psql: "
                        c "\\set"
                        " manages psql's own variables, and "
                        c "\\pset"
                        " manages the twenty-two printing options from yesterday."
                    p_ $ do
                        "The manual page's note under "
                        c "\\set"
                        " — “this command is unrelated to the SQL command SET” — is doing a lot of \
                        \work for one sentence. All three are legal in psqlrc, because the startup \
                        \file is read "
                        i_ "after"
                        " connecting, so it can configure the client and the session on the server \
                        \in the same breath."
                )
            ,
                ( "Two developers share a machine. One has "
                    <> c "~/.psqlrc"
                    <> " and "
                    <> c "~/.psqlrc-18"
                    <> ", and swears the first one is being ignored. Are they right?"
                , do
                    p_ $ do
                        "Yes, entirely. Both the system-wide and the personal startup file can be \
                        \version-suffixed — "
                        c "~/.psqlrc-18"
                        " or "
                        c "~/.psqlrc-18.6"
                        " — and the "
                        b_ "most specific match wins outright"
                        ". It is not additive: if "
                        c "~/.psqlrc-18"
                        " exists, "
                        c "~/.psqlrc"
                        " is not read at all."
                    p_ $ do
                        "It is a genuinely useful feature for anyone who keeps several major \
                        \versions of the client around, and a reliable source of confusion for \
                        \everyone else. If you do use it, have the specific file "
                        c "\\i"
                        " the general one on its first line."
                )
            ,
                ( "Why does a script that works on your machine fail on a colleague's with an \
                  \error about a variable they have never heard of?"
                , do
                    p_ $ do
                        "Because psql read one of their startup files first. Since PostgreSQL 9.6 "
                        c "-c"
                        " no longer implies "
                        c "-X"
                        ", so even a one-shot "
                        c "psql -c '...'"
                        " picks up "
                        c "~/.psqlrc"
                        " — along with whatever "
                        c "\\pset format"
                        ", "
                        c "AUTOCOMMIT"
                        " or "
                        c "search_path"
                        " it sets."
                    p_ $ do
                        "The fix is one flag: every psql invocation inside a script gets "
                        c "-X"
                        ". A script's behaviour should not depend on whose account it runs under, \
                        \and this is the commonest way that it does."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d6diagram :: Diagram
d6diagram =
    ( diagram
        "The startup file can set psql variables, printing options and server parameters; psql \
        \variables and printing options live in your session while server parameters live in the \
        \server, and a control variable is simply a psql variable whose name psql recognises."
        body'
    )
        { dgCaption = do
            "Three commands with nearly the same name, and only "
            c "SET"
            " crosses the connection. The amber aspect is the day's trap: a "
            b_ "control variable is an ordinary psql variable"
            " that psql happens to recognise by name, so misspelling the name creates a harmless \
            \variable nobody reads, while misspelling the "
            i_ "value"
            " of a real one is caught immediately."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  rc    [label=\"~/.psqlrc\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  pvar  [label=\"a psql variable\\n(\\\\set)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  popt  [label=\"a printing option\\n(\\\\pset)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  sparm [label=\"a server parameter\\n(SET)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  ctrl  [label=\"a control variable\\nON_ERROR_STOP, PROMPT1\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  sess  [label=\"your psql session\"];\n\
        \  srv   [label=\"the server\", fillcolor=\"#f4efe6\"];\n\
        \\n\
        \  rc    -> pvar  [label=\"  can set\"];\n\
        \  rc    -> popt  [label=\"  can set\"];\n\
        \  rc    -> sparm [label=\"  can set\"];\n\
        \  ctrl  -> pvar  [label=\"  is a\"];\n\
        \  pvar  -> sess  [label=\"  lives in\"];\n\
        \  popt  -> sess  [label=\"  lives in\"];\n\
        \  sparm -> srv   [label=\"  lives in\"];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Everything from yesterday, permanently" $ do
        p_ [class_ "lede"] $ do
            "Unless you pass "
            c "-X"
            ", psql reads two files at start-up: a system-wide "
            c "psqlrc"
            " and then your "
            c "~/.psqlrc"
            ". They are ordinary psql input — anything you can type at the prompt, you can put in \
            \them — and the important detail is "
            i_ "when"
            " they run: after connecting, but before you get a prompt. So they can configure the \
            \client "
            b_ "and"
            " the session on the server."
        p_ $ do
            "The system-wide file lives in the installation's configuration directory, which "
            c "pg_config --sysconfdir"
            " will tell you ("
            c "/etc"
            " on a Fedora package build) and "
            c "PGSYSCONFDIR"
            " will override. Most machines have no such file, and it is worth confirming that \
            \rather than assuming it: it is the natural place for someone to have set "
            c "AUTOCOMMIT off"
            " for the whole box."
        p_ $ do
            "Your own file is "
            c "~/.psqlrc"
            ", relocatable with "
            c "PSQLRC"
            ". Both files may carry a version suffix, and the most specific one "
            b_ "wins outright"
            " rather than adding to the others:"
        ascii
            [ "~/.psqlrc-18.6      most specific — if this exists, the two below are ignored"
            , "~/.psqlrc-18        checked next"
            , "~/.psqlrc           the plain one, used only if neither of the above is present"
            ]
        gotcha $ p_ $ do
            "Since PostgreSQL 9.6, "
            c "-c"
            " no longer implies "
            c "-X"
            ". So a one-line "
            c "psql -c 'SELECT ...'"
            " in a cron job reads your startup file, inherits whatever "
            c "AUTOCOMMIT"
            ", "
            c "search_path"
            " or output format it sets, and behaves differently depending on which account it runs \
            \under. Every psql invocation inside a script should carry "
            c "-X"
            ". This is the single most common source of “it works on my machine”."
        fig

    block "Three commands called set, and only one crosses the wire" $ do
        p_ "The names are unfortunate and the distinction is absolute."
        defs
            [
                ( c "\\set"
                , do
                    "psql's own variables. Name/value pairs, values are strings, and about thirty \
                    \specific names change psql's behaviour. Never leaves the client."
                )
            ,
                ( c "\\pset"
                , do
                    "yesterday's twenty-two printing options. Also purely client-side, and a \
                    \separate namespace — there is no psql variable called "
                    c "null"
                    " and no printing option called "
                    c "QUIET"
                    "."
                )
            ,
                ( c "SET"
                , do
                    "SQL. Sets a "
                    i_ "server"
                    " parameter for this session: "
                    c "search_path"
                    ", "
                    c "statement_timeout"
                    ", "
                    c "timezone"
                    ", "
                    c "work_mem"
                    ". The only one the server ever hears about."
                )
            ]
        p_ $ do
            "All three belong in psqlrc, and the third is the one people forget is available. A "
            c "SET search_path TO app, public"
            " in your startup file is how you stop typing schema prefixes in a database you work in \
            \daily — and "
            c "\\dconfig"
            " from Day 4 will show you the result."
        p_ $ do
            "Reading a variable back is "
            c "\\echo :NAME"
            ", and bare "
            c "\\set"
            " lists everything currently set. Day 12 does interpolation properly; today "
            c "\\echo :DBNAME"
            " is enough to prove a file loaded."

    block "Control variables, and the typo nobody catches" $ do
        p_ $ do
            "By convention psql's own variables are in capitals, and you should stay out of that \
            \namespace. But the convention is all there is: a "
            b_ "control variable is just a variable whose name psql recognises"
            ". Set a name it does not recognise and you have made yourself an ordinary variable, \
            \with no warning:"
        sh
            [ "testdb=# \\set ON_ERROR_STOPP on"
            , "testdb=# \\echo :ON_ERROR_STOPP"
            , "on"
            , "testdb=# \\set ON_ERROR_STOP maybe"
            , "unrecognized value \"maybe\" for \"ON_ERROR_STOP\": Boolean expected"
            , "testdb=# \\echo :ON_ERROR_STOP"
            , "off"
            ]
        p_ $ do
            "Names are unchecked; values are checked. That is worth knowing because a psqlrc is \
            \exactly where such a typo goes unnoticed for months — the file loads without \
            \complaint and the setting you thought you had is simply absent."
        p_ "Three further rules make control variables behave unlike ordinary ones:"
        steps
            [ do
                "They cannot be unset. "
                c "\\unset VERBOSITY"
                " is accepted, and means “back to the default”, not “gone”."
            , do
                c "\\set"
                " with no value means "
                c "on"
                " for the boolean ones, so "
                c "\\set ON_ERROR_STOP"
                " is the idiomatic spelling. For an enumerated one it is an error, and psql lists \
                \the valid values for you."
            , do
                "Booleans accept the usual spellings — "
                c "on"
                ", "
                c "off"
                ", "
                c "true"
                ", "
                c "false"
                ", "
                c "1"
                ", "
                c "0"
                ", "
                c "yes"
                ", "
                c "no"
                " — and any unambiguous prefix of them."
            ]

    block "Loading without the chatter" $ do
        p_ $ do
            "A psqlrc that sets four things greets you with four confirmations every time you start \
            \psql. That is how people learn to ignore psql's messages, which is a bad habit to \
            \acquire on purpose. The fix is a pair of bookends:"
        cfg
            [ "\\set QUIET on          -- first line of the file"
            , "\\pset null '(null)'"
            , "\\pset expanded auto"
            , "\\timing on"
            , "\\unset QUIET           -- last line, so YOUR commands still confirm themselves"
            ]
        p_ $ do
            "Without the pair, start-up prints “Null display is \"(null)\".”, “Expanded display is \
            \used automatically.” and “Timing is on.” before your prompt. With it, silence — and \
            \because "
            c "QUIET"
            " goes back off at the foot of the file, anything you type yourself still reports back."
        tip $ p_ $ do
            "Put an "
            c "\\echo"
            " after the "
            c "\\unset QUIET"
            " if you want one line of your own instead of psql's four: "
            c "\\echo Connected to :DBNAME as :USER"
            ". It is a small thing and it has saved a great many people from running a migration \
            \against production."
        p_ $ do
            "To test a change without restarting, "
            c "\\i ~/.psqlrc"
            " re-reads the file in place — tilde expansion included. That is also the answer to \
            \“how do I reload it”, since there is no "
            c "\\reload"
            "."

    block "Today's habit" $ do
        p_ $ do
            "Create the file. Four lines from the box above this section, and from tomorrow \
            \onwards every day of this course adds one or two more with a comment saying why. The \
            \whole assembled file is linked at the top of the syllabus, but copying it wholesale \
            \would defeat the point — the value is that you can defend each line."
        p_ "Tomorrow: making the editing itself less painful, which is mostly readline plus one environment variable."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Startup files, most specific first."
        " A match wins outright; it does not add to the others."
    cfg
        [ "~/.psqlrc-18.6  >  ~/.psqlrc-18  >  ~/.psqlrc        PSQLRC= relocates it"
        , "system-wide: $(pg_config --sysconfdir)/psqlrc        PGSYSCONFDIR= relocates it"
        , "-X   skip both.  ALWAYS pass it in scripts: since 9.6, -c no longer implies -X"
        , "read AFTER connecting, so \\set, \\pset AND SET are all legal in it"
        , "\\set QUIET on ... \\unset QUIET   -- bookends: load silently, then report normally"
        , "\\i ~/.psqlrc                     -- re-read it without restarting"
        , "-- \\set  = psql's own variables (client)      \\echo :NAME to read one, \\set to list all"
        , "-- \\pset = printing options       (client)"
        , "-- SET   = server parameters       (server)   <- the only one that crosses the wire"
        , "-- control variables: NAME unchecked, VALUE checked. \\unset = back to default."
        ]
