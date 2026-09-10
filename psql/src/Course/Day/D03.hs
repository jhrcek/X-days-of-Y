module Course.Day.D03 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 3
        , dayTitle = "Relations, and patterns"
        , daySubtitle = "One grammar behind forty-five describe commands, and the pattern language that narrows them."
        , dayMinutes = 35
        , dayLevel = "essential"
        , dayManRef = "Meta-Commands (\\d family), Patterns"
        , dayTags = ["\\d", "patterns", "search_path"]
        , dayGoals =
            [ "decompose any " <> c "\\d" <> "-something command into object letters, modifiers and a pattern"
            , "write a pattern that finds a table in a schema you are not currently searching"
            , "explain why " <> c "\\dt" <> " can show nothing while the table demonstrably exists"
            ]
        , dayDiagram = Just d3diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("\\d", "Bare: tables, views, materialized views, sequences and foreign tables.")
            , ("\\d my_table", "Describe one relation: columns, types, nullability, defaults, indexes, constraints.")
            , ("\\d+ my_table", "Adds storage, compression, stats target and per-column comments.")
            , ("\\dt", "Tables. The letters combine — " <> c "\\dti" <> " lists tables and indexes.")
            , ("\\di \\dv \\dm \\ds \\dE", "Indexes, views, materialized views, sequences, foreign tables.")
            , ("\\dn", "Schemas. " <> c "\\dn+" <> " adds permissions and comments.")
            , ("\\l", "Databases, with owner, encoding, locale provider and privileges.")
            , ("\\dP", "Partitioned tables and indexes; add " <> c "n" <> " to include non-root ones.")
            , ("\\dx", "Installed extensions; " <> c "\\dx+" <> " lists everything each one owns.")
            ]
        , dayOpts =
            [ ("S", "Include system objects: " <> c "\\dtS" <> ". Supplying any pattern does this too.")
            , ("+", "More columns — and a size lookup per relation, so it is not free.")
            , ("x", "Expanded output for this listing only. Goes after " <> c "S" <> " or " <> c "+" <> ", never straight after " <> c "\\d" <> ".")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Run "
                <> c "\\d"
                <> " with no arguments in a database you know. Then "
                <> c "\\dt"
                <> ". The first is longer, because bare "
                <> c "\\d"
                <> " means "
                <> c "\\dtvmsE"
                <> "."
            , "Pick one table and run "
                <> c "\\d"
                <> " on it, then "
                <> c "\\d+"
                <> ". Name three things the "
                <> c "+"
                <> " added."
            , "Run "
                <> c "\\dti"
                <> ". Two object letters, one listing, and an extra “Table” column telling you \
                   \which index belongs to what."
            , "Break it on purpose: pick a table in a schema that is not on your "
                <> c "search_path"
                <> " and run "
                <> c "\\dt thatname"
                <> ". Read “Did not find any relations.” Now find it with "
                <> c "\\dt *.thatname"
                <> "."
            , "Run "
                <> c "\\dt *.*"
                <> " and notice that "
                <> c "information_schema"
                <> " and "
                <> c "pg_catalog"
                <> " appear without your having asked for "
                <> c "S"
                <> " — supplying a pattern implies it."
            , "Use a character class: "
                <> c "\\dt [a-c]*"
                <> " lists tables whose names start with a, b or c. Patterns are regexes with three \
                   \characters rewritten, not globs."
            , "Find the table whose name you half-remember in your own database, using "
                <> c "\\dt *word*"
                <> ". This is the drill that pays for the day."
            , "Add "
                <> c "\\dn"
                <> " to your reflexes. Before describing anything in an unfamiliar database, look \
                   \at the schemas first — it tells you where the interesting half of the tables is \
                   \hiding."
            ]
        , dayQuiz =
            [
                ( c "\\dt orders"
                    <> " says “Did not find any relations.” But "
                    <> c "SELECT * FROM app.orders"
                    <> " works perfectly. Explain both."
                , do
                    p_ $ do
                        "A pattern with no dot in it matches only objects that are "
                        b_ "visible"
                        " — that is, in a schema on your "
                        c "search_path"
                        ", and not shadowed by a same-named object earlier in the path. "
                        c "app"
                        " is not on your path, so "
                        c "orders"
                        " is not visible, while the explicitly qualified "
                        c "app.orders"
                        " in a query needs no visibility at all."
                    p_ $ do
                        "Any of "
                        c "\\dt app.orders"
                        ", "
                        c "\\dt *.orders"
                        " or "
                        c "\\dt *.*"
                        " will show it. A dot in the pattern turns it into “schema pattern, then \
                        \object pattern”."
                )
            ,
                ( "You want the table literally named "
                    <> c "Orders"
                    <> ", capital O. Why does "
                    <> c "\\dt Orders"
                    <> " miss it, and what do the double quotes change?"
                , do
                    p_ $ do
                        "Unquoted pattern characters are folded to lower case, exactly as SQL names \
                        \are, so you asked for "
                        c "orders"
                        ". "
                        c "\\dt \"Orders\""
                        " stops the folding."
                    p_ $ do
                        "The quotes do more than that, and it catches people out: inside double \
                        \quotes "
                        c "*"
                        ", "
                        c "?"
                        ", "
                        c "."
                        " and every regular-expression metacharacter lose their meaning and match \
                        \literally. You can quote part of a pattern only — "
                        c "\\dt \"Ord\"*"
                        " is a literal "
                        c "Ord"
                        " followed by anything — which is usually what you want."
                )
            ,
                ( "Why does "
                    <> c "\\dx"
                    <> " list extensions while "
                    <> c "\\d+x"
                    <> " shows relations in expanded mode? Where can the "
                    <> c "x"
                    <> " modifier go?"
                , do
                    p_ $ do
                        "Because the object letters are read first, and "
                        c "\\dx"
                        " was already taken. The manual page is explicit that the "
                        c "x"
                        " modifier may only appear after an "
                        c "S"
                        " or a "
                        c "+"
                        " — never immediately after "
                        c "\\d"
                        " — and, for bare "
                        c "\\d"
                        ", only when no pattern is given."
                    p_ $ do
                        "So "
                        c "\\d+x"
                        " is "
                        c "\\dtvmsE+"
                        " in expanded mode. Elsewhere the modifier is unambiguous and reads \
                        \naturally: "
                        c "\\dt+x"
                        ", "
                        c "\\df+x int*pl"
                        "."
                )
            ,
                ( c "\\dt+"
                    <> " on a database with forty thousand tables takes twenty seconds; "
                    <> c "\\dt"
                    <> " is instant. What is the "
                    <> c "+"
                    <> " doing?"
                , do
                    p_ $ do
                        "Among other columns it adds "
                        b_ "Size"
                        ", and that is a physical on-disk size looked up per relation rather than \
                        \read out of one catalogue row. Persistence and access method are cheap; the \
                        \size is not."
                    p_ $ do
                        "Habit worth forming: reach for plain "
                        c "\\dt"
                        " when you are orienting yourself and "
                        c "\\dt+"
                        " only when you actually want the numbers. The same applies to "
                        c "\\l+"
                        ", which sizes every database."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d3diagram :: Diagram
d3diagram =
    ( diagram
        "A describe command is built from object-type letters, optional modifiers and an \
        \optional pattern; it is compiled into a catalogue query whose results are also \
        \filtered by the schema search path."
        body'
    )
        { dgCaption = do
            "There are not forty-five describe commands, there is one grammar: letters choose the \
            \kind of object, modifiers choose how much detail, a pattern narrows the set. The \
            \aspect worth remembering is the amber one — results are filtered "
            i_ "twice"
            ", once by your pattern and once by the search path, and it is the second filter that \
            \makes a table you can query invisible to "
            c "\\dt"
            "."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  cmd  [label=\"a describe command\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  let  [label=\"an object-type letter\\n(t, i, v, m, s, E, n, f, …)\"];\n\
        \  mod  [label=\"a modifier\\n(S, +, x)\"];\n\
        \  pat  [label=\"a pattern\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  qry  [label=\"a catalogue query\"];\n\
        \  obj  [label=\"a catalogue object\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  path [label=\"the schema\\nsearch path\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  cmd  -> let  [label=\"  chooses its objects with\"];\n\
        \  cmd  -> mod  [label=\"is qualified by  \", style=dashed];\n\
        \  cmd  -> pat  [label=\"  is narrowed by\", style=dashed];\n\
        \  cmd  -> qry  [label=\"  is compiled into\"];\n\
        \  qry  -> obj  [label=\"  returns\"];\n\
        \  pat  -> obj  [label=\"  matches the name of\"];\n\
        \  path -> obj  [label=\"  decides the visibility of\"];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Forty-five commands, one grammar" $ do
        p_ [class_ "lede"] $ do
            "The "
            c "\\d"
            " family looks like the part of psql you have to memorise. It is not: it is a small \
            \grammar, and once you can read it you can guess commands you have never used. A \
            \describe command is "
            c "\\d"
            ", then one or more letters naming the kind of object, then optional modifiers, then an \
            \optional pattern."
        p_ $ do
            "The letters are mnemonic once you know they were chosen under pressure. "
            c "t"
            " table, "
            c "v"
            " view, "
            c "m"
            " materialized view, "
            c "i"
            " index, "
            c "s"
            " sequence, "
            c "n"
            " namespace (schema), "
            c "f"
            " function, "
            c "T"
            " type, "
            c "u"
            " user. The awkward ones spell out a phrase instead: "
            c "\\des"
            " is external servers, "
            c "\\det"
            " external tables, "
            c "\\dew"
            " external wrappers, and the "
            c "\\dA"
            " family is access methods."
        p_ $ do
            "Where the letters make sense together they combine. "
            c "\\dti"
            " lists tables and indexes in one listing, with an extra column saying which table each \
            \index belongs to:"
        sh
            [ "testdb=# \\dti"
            , "                     List of relations"
            , " Schema |        Name         | Type  |  Owner   |  Table   "
            , "--------+---------------------+-------+----------+----------"
            , " public | my_table            | table | postgres | "
            , " public | my_table_second_idx | index | postgres | my_table"
            , "(2 rows)"
            ]
        why $ p_ $ do
            "And bare "
            c "\\d"
            " is defined as "
            c "\\dtvmsE"
            " — “everything you would call a table-shaped thing”. The manual page calls this \
            \“purely a convenience measure”, which is a useful admission: the family was not \
            \designed as a taxonomy, it accreted, and the letters are historical. That is why "
            c "\\dx"
            " means extensions rather than something starting with x, and why the "
            c "x"
            " modifier had to be given awkward placement rules to avoid the clash."
        fig

    block "Three modifiers, and what they cost" $ do
        defs
            [
                ( c "S"
                , do
                    "include system objects. Without it you see only user-created things, which is \
                    \almost always what you want — "
                    c "\\dfS"
                    " lists some three thousand built-in functions."
                )
            ,
                ( c "+"
                , do
                    "verbose. For relations that means persistence, access method, size and \
                    \description in listings, or storage, compression and per-column comments when \
                    \describing one table. The size is a physical lookup per relation, so "
                    c "\\dt+"
                    " is materially slower than "
                    c "\\dt"
                    " on a big database."
                )
            ,
                ( c "x"
                , do
                    "show this listing in expanded mode, as if "
                    c "\\x"
                    " were on for one command. Day 5 explains expanded mode; the placement rule is \
                    \here because it is a "
                    c "\\d"
                    " quirk. It goes "
                    i_ "after"
                    " "
                    c "S"
                    " or "
                    c "+"
                    ", never straight after "
                    c "\\d"
                    "."
                )
            ]
        p_ $ do
            "Describing one table is where "
            c "+"
            " earns its keep, because psql assembles it from half a dozen catalogues and shows you \
            \constraints, indexes, triggers and rules that no single query would have given you:"
        sh
            [ "testdb=# \\d+ my_table"
            , "                                             Table \"public.my_table\""
            , " Column |  Type   | Collation | Nullable | Default | Storage  | Compression | Stats target |     Description"
            , "--------+---------+-----------+----------+---------+----------+-------------+--------------+----------------------"
            , " first  | integer |           | not null | 0       | plain    |             |              | "
            , " second | text    |           |          |         | extended |             |              | the spelled-out name"
            , "Indexes:"
            , "    \"my_table_second_idx\" btree (second)"
            , "Not-null constraints:"
            , "    \"my_table_first_not_null\" NOT NULL \"first\""
            , "Access method: heap"
            ]
        note $ p_ $ do
            "Note what is "
            i_ "not"
            " there: the table's own comment. "
            c "\\d+"
            " shows comments on the "
            b_ "columns"
            "; the comment on the table appears in the "
            c "Description"
            " column of "
            c "\\dt+"
            ". Two different commands for two different comments, and the manual page says so if \
            \you read it closely enough."

    block "Patterns are regexes wearing a glob costume" $ do
        p_ $ do
            "The pattern argument looks like shell globbing and is not. Underneath it is a regular \
            \expression with three characters rewritten before it is used: "
            c "*"
            " becomes "
            c ".*"
            ", "
            c "?"
            " becomes "
            c "."
            ", and "
            c "$"
            " is matched literally. Everything else regular expressions can do, patterns can do."
        p_ "Which means all of these work:"
        cfg
            [ "\\dt orders          -- exactly this name, in a visible schema"
            , "\\dt ord*            -- anything beginning with ord"
            , "\\dt *order*         -- the one you use when you half-remember the name"
            , "\\dt [a-c]*          -- a character class: a, b or c to start"
            , "\\dt ?rders          -- exactly one character, then rders"
            , "\\dt app.o*          -- schema pattern . object pattern"
            , "\\dt *.orders        -- this object name in any schema"
            , "\\dt *.*             -- everything, visible or not, system schemas included"
            ]
        p_ $ do
            "Two rules do most of the surprising work. First, the pattern is "
            b_ "anchored"
            ": it must match the whole name, which is why "
            c "\\dt order"
            " does not find "
            c "orders"
            " and why you never need a trailing "
            c "$"
            ". Write "
            c "*"
            " at either end when you want it unanchored."
        p_ $ do
            "Second, "
            b_ "a dot is a separator, not a metacharacter"
            ". One dot splits the pattern into schema and object; two dots into database, schema \
            \and object — and the database part is not a pattern at all, it must literally be the \
            \database you are connected to, or you get an error. To match a real dot in a name, \
            \quote it."
        p_ $ do
            "Double quotes stop lower-case folding, exactly as in SQL, and also switch off every \
            \metacharacter inside them. You can quote part of a pattern: "
            c "\\dt \"Ord\"*"
            " is a literal "
            c "Ord"
            " followed by anything, and "
            c "\\dt \"FOO\"\"BAR\""
            " finds the table named "
            c "FOO\"BAR"
            "."
        gotcha $ p_ $ do
            "Supplying "
            i_ "any"
            " pattern turns on the "
            c "S"
            " behaviour. So "
            c "\\dt *.*"
            " is not “all my tables”, it is all tables including "
            c "pg_catalog"
            " and "
            c "information_schema"
            ", and on an empty database it still returns about sixty rows. When you want everything \
            \of your own across all schemas, you generally want "
            c "\\dt *.*"
            " piped through a pager and a squint, or a query against "
            c "pg_class"
            "."

    block "The filter you did not ask for" $ do
        p_ $ do
            "Omit the pattern entirely and a describe command shows what is "
            b_ "visible"
            " — objects whose schema is on your "
            c "search_path"
            " and which are not shadowed by a same-named object earlier in it. This is the single \
            \most common reason for “psql says my table does not exist”:"
        sh
            [ "testdb=# SHOW search_path;"
            , "   search_path   "
            , "-----------------"
            , " \"$user\", public"
            , "(1 row)"
            , ""
            , "testdb=# \\dt orders"
            , "Did not find any relations."
            , "testdb=# \\dt app.orders"
            , " Schema |  Name  | Type  |  Owner   "
            , "--------+--------+-------+----------"
            , " app    | orders | table | postgres"
            , "(1 row)"
            ]
        p_ $ do
            "Nothing was wrong with the table, and "
            c "SELECT * FROM app.orders"
            " would have worked throughout. Visibility governs what you can refer to "
            i_ "without"
            " qualifying it, and "
            c "\\d"
            " reports on that same notion."
        tip $ p_ $ do
            "In an unfamiliar database, run "
            c "\\dn"
            " before anything else. Schemas tell you how the place is organised, and they tell you \
            \which "
            c "SET search_path TO app, public"
            " will make the next twenty minutes bearable."

    block "Today's habit" $ do
        p_ $ do
            "When you next land in a database you do not know: "
            c "\\dn"
            ", then "
            c "\\dt *.*"
            " to see the shape of it, then "
            c "\\d+"
            " on the two or three tables that matter. That is a five-minute orientation, and it \
            \replaces reading someone's out-of-date schema diagram."
        p_ $ do
            "Tomorrow: the other half of the family — functions, roles and the privilege grid \
            \nobody can read at first sight."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "The grammar."
        " \\d + object letters + modifiers + pattern."
    cfg
        [ "\\d          = \\dtvmsE  -- tables, views, matviews, sequences, foreign tables"
        , "\\dt \\di \\dv \\dm \\ds \\dE \\dn \\dP \\dx     -- combine letters: \\dti, \\dtv"
        , "modifiers:  S system objects   + verbose (sizes: not free)   x expanded (after S or +)"
        , "\\d name     -- one relation in full: columns, indexes, constraints, triggers"
        , "-- patterns are anchored regexes with * -> .*   ? -> .   $ literal"
        , "\\dt ord*    \\dt *order*   \\dt [a-c]*   \\dt \"Ord\"*   -- \" stops folding AND metachars"
        , "\\dt app.o*  -- schema.object      \\dt *.orders  -- that name anywhere"
        , "\\dt *.*     -- everything, INCLUDING pg_catalog: any pattern implies S"
        , "-- no pattern = only what search_path makes visible. \\dn first, always."
        ]
