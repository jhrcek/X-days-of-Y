module Course.Day.D04 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 4
        , dayTitle = "Functions and privileges"
        , daySubtitle = "The other half of the describe family, and how to read an ACL entry without guessing."
        , dayMinutes = 35
        , dayLevel = "essential"
        , dayManRef = "Meta-Commands (\\df, \\du, \\dp, \\ddp, \\drg, \\dconfig)"
        , dayTags = ["\\df", "\\dp", "roles"]
        , dayGoals =
            [ "find a function by name and by the types of its arguments, and read its source without leaving psql"
            , "read a privilege grid letter by letter, including what an empty one means"
            , "say where role membership went, now that " <> c "\\du" <> " no longer shows it"
            ]
        , dayDiagram = Just d4diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("\\df pattern", "Functions, with result type, argument types and kind.")
            , ("\\df pattern t1 t2", "Extra arguments are type patterns, matched positionally.")
            , ("\\sf name", "The function's source as " <> c "CREATE OR REPLACE" <> ". " <> c "\\sf+" <> " numbers the body.")
            , ("\\sv name", "The same for a view. " <> c "\\ev" <> " and " <> c "\\ef" <> " edit rather than show.")
            , ("\\du", "Roles and their attributes. " <> c "\\dg" <> " is the same command.")
            , ("\\drg", "Role grants: who is a member of what, with " <> c "ADMIN" <> "/" <> c "INHERIT" <> "/" <> c "SET" <> ".")
            , ("\\dp", "Access privileges on tables, views and sequences. " <> c "\\z" <> " is the same command.")
            , ("\\ddp", "Default privileges — what future objects will be created with.")
            , ("\\dconfig", "Server parameters set to non-default values. " <> c "\\dconfig *" <> " for all of them.")
            , ("\\drds", "Settings attached to a role, a database, or the pair.")
            , ("\\dT \\do \\da", "Types, operators and aggregates — same grammar, rarer questions.")
            ]
        , dayOpts =
            [ ("a n p t w", "Function-kind filters for " <> c "\\df" <> ": aggregate, normal, procedure, trigger, window.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Run "
                <> c "\\df"
                <> " in your own database. If it is empty, that is the answer: no user-defined \
                   \functions. Now "
                <> c "\\dfS to_char"
                <> " to prove the built-ins are there and merely hidden."
            , "Find every built-in function whose second argument is a "
                <> c "bigint"
                <> " and whose name looks like integer addition: "
                <> c "\\df int*pl * bigint"
                <> ". Three results, and you never wrote a catalogue query."
            , "Pick any function you have and run "
                <> c "\\sf+"
                <> " on it. Line 1 is the first line of the body, not of the "
                <> c "CREATE"
                <> " — which is exactly what you want when the error said “line 4”."
            , "Run "
                <> c "\\dp"
                <> " on a table nobody has granted anything on. The Access privileges column is "
                <> b_ "empty"
                <> ". Convince yourself that this means “built-in defaults”, not “no access”."
            , "Break it on purpose: "
                <> c "GRANT SELECT ON sometable TO PUBLIC"
                <> " in your scratch database, then "
                <> c "\\dp sometable"
                <> ". Read the entry with nothing on the left of the "
                <> c "="
                <> " — that is PUBLIC."
            , "Grant one privilege at a time to a scratch role and watch the letters accumulate. \
              \Then grant one "
                <> c "WITH GRANT OPTION"
                <> " and find the "
                <> c "*"
                <> "."
            , "Run "
                <> c "\\du"
                <> " and then "
                <> c "\\drg"
                <> ". Notice that the membership you were looking for is only in the second one."
            , "Run "
                <> c "\\dconfig"
                <> " against a server you did not configure. Everything it prints is something \
                   \somebody chose deliberately — a two-minute way to learn what is unusual about \
                   \a machine."
            ]
        , dayQuiz =
            [
                ( c "\\dp orders"
                    <> " shows an empty Access privileges column. A colleague concludes that nobody \
                       \can read the table, including its owner. Where did they go wrong?"
                , do
                    p_ $ do
                        "An empty column means the object still has its "
                        b_ "built-in default"
                        " privileges, which for a table is “the owner has everything, nobody else \
                        \has anything”. It is the absence of an explicit ACL, not an ACL granting \
                        \nothing."
                    p_ $ do
                        "The moment anyone runs a single "
                        c "GRANT"
                        " or "
                        c "REVOKE"
                        " on the object, the whole ACL materialises — including the owner's own "
                        c "postgres=arwdDxtm/postgres"
                        " row, which was implicit before and is now written down. So the column \
                        \going from empty to long does not mean access widened."
                )
            ,
                ( "You need to know whether "
                    <> c "reporter"
                    <> " inherits the privileges of "
                    <> c "analysts"
                    <> ". "
                    <> c "\\du reporter"
                    <> " shows an empty Attributes column and no mention of "
                    <> c "analysts"
                    <> ". Where is the information?"
                , do
                    p_ $ do
                        c "\\drg"
                        ", which lists role grants: Role name, Member of, Options and Grantor. The \
                        \Options column is the answer to your actual question — "
                        c "INHERIT"
                        " means privileges flow automatically, "
                        c "SET"
                        " means the role can "
                        c "SET ROLE"
                        " to it, "
                        c "ADMIN"
                        " means it can grant the membership onward."
                    p_ $ do
                        c "\\du"
                        " used to carry a “Member of” column and no longer does; membership became \
                        \rich enough (three independent options, and a grantor) to need a listing \
                        \of its own. If you learned psql before that split, this is the change most \
                        \likely to trip you."
                )
            ,
                ( "What does "
                    <> c "analysts=r*w/alice"
                    <> " tell you, in words?"
                , do
                    p_ $ do
                        "The role "
                        c "analysts"
                        " has "
                        c "SELECT"
                        " ("
                        c "r"
                        ", for read) and "
                        c "UPDATE"
                        " ("
                        c "w"
                        ", for write) on this object; the "
                        c "*"
                        " says the "
                        c "SELECT"
                        " was given "
                        c "WITH GRANT OPTION"
                        ", so "
                        c "analysts"
                        " may pass it on; and "
                        c "alice"
                        " is the role that granted all of it."
                    p_ $ do
                        "The full alphabet for a table is "
                        c "a"
                        " insert (append), "
                        c "r"
                        " select (read), "
                        c "w"
                        " update (write), "
                        c "d"
                        " delete, "
                        c "D"
                        " truncate, "
                        c "x"
                        " references, "
                        c "t"
                        " trigger, "
                        c "m"
                        " maintain. An owner with everything reads "
                        c "arwdDxtm"
                        "."
                )
            ,
                ( "A newly created table in schema "
                    <> c "app"
                    <> " already grants "
                    <> c "SELECT"
                    <> " to a role you did not mention. Nobody ran a "
                    <> c "GRANT"
                    <> ". What happened, and which command shows it?"
                , do
                    p_ $ do
                        "Somebody ran "
                        c "ALTER DEFAULT PRIVILEGES"
                        " for that schema, so every table created there afterwards is born with \
                        \that grant already applied. "
                        c "\\ddp"
                        " lists exactly these — owner, schema, object type, and the privileges \
                        \future objects will get."
                    p_ $ do
                        "It is worth checking on any database where “the grants keep coming back”. \
                        \Default privileges are attached to the "
                        i_ "creating role"
                        " as well as the schema, so two people creating tables in the same schema \
                        \can produce differently-permissioned tables."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d4diagram :: Diagram
d4diagram =
    ( diagram
        "A privilege grant is made to a role, on a database object, by a granting role, and is \
        \displayed as an ACL entry of the form role=letters/grantor; a role can be a member of \
        \another role, and a default privilege setting pre-creates grants on future objects."
        body'
    )
        { dgCaption = do
            "What "
            c "\\dp"
            " prints is one "
            b_ "ACL entry"
            " per grantee, and the amber box is where the reading goes wrong: an "
            i_ "empty"
            " column is not an ACL that grants nothing, it is the absence of an ACL, meaning the \
            \built-in defaults still apply. The self-aspect on “a role” is why membership needs \
            \its own listing — it carries three options and a grantor of its own, so "
            c "\\du"
            " could not sensibly show it in a column."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  role  [label=\"a role\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  obj   [label=\"a database object\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  grant [label=\"a privilege grant\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  gtor  [label=\"the granting role\"];\n\
        \  acl   [label=\"an ACL entry\\nrole=letters/grantor\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  def   [label=\"a default\\nprivilege setting\"];\n\
        \\n\
        \  grant -> role [label=\"  is made to\"];\n\
        \  grant -> obj  [label=\"  is made on\"];\n\
        \  grant -> gtor [label=\"is made by  \"];\n\
        \  grant -> acl  [label=\"  is displayed as\"];\n\
        \  role  -> role [label=\"  can be a member of\", style=dashed];\n\
        \  def   -> grant [label=\"pre-creates  \", style=dashed];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Finding a function you cannot quite name" $ do
        p_ [class_ "lede"] $ do
            c "\\df"
            " takes the grammar from yesterday and adds something no other describe command has: \
            \extra arguments that match "
            i_ "argument types"
            ", positionally. That turns “what was the function that takes a text and an interval” \
            \from a catalogue query into one line."
        p_ $ do
            "The first argument is a name pattern; every argument after it is a type-name pattern \
            \for the first, second, third parameter and so on. Matching functions may take "
            i_ "more"
            " arguments than you listed — write a dash as the last pattern to forbid that."
        sh
            [ "testdb=# \\df int*pl * bigint"
            , "                          List of functions"
            , "   Schema   |  Name   | Result data type | Argument data types | Type "
            , "------------+---------+------------------+---------------------+------"
            , " pg_catalog | int28pl | bigint           | smallint, bigint    | func"
            , " pg_catalog | int48pl | bigint           | integer, bigint     | func"
            , " pg_catalog | int8pl  | bigint           | bigint, bigint      | func"
            , "(3 rows)"
            ]
        p_ $ do
            "The Type column classifies each result as "
            c "agg"
            ", "
            c "normal"
            ", "
            c "proc"
            ", "
            c "trigger"
            " or "
            c "window"
            ", and the letters "
            c "a"
            ", "
            c "n"
            ", "
            c "p"
            ", "
            c "t"
            ", "
            c "w"
            " filter to just those kinds. So "
            c "\\dfp"
            " is “list the procedures”, and "
            c "\\dft"
            " answers “which trigger functions exist in this database” without a join."
        fig

    block "Reading the source without leaving the prompt" $ do
        p_ $ do
            c "\\sf"
            " prints a function's definition as a "
            c "CREATE OR REPLACE FUNCTION"
            " statement, and "
            c "\\sf+"
            " numbers the lines — "
            b_ "counting from the first line of the body"
            ", not of the statement:"
        sh
            [ "testdb=# \\sf+ addone"
            , "        CREATE OR REPLACE FUNCTION public.addone(integer)"
            , "         RETURNS integer"
            , "         LANGUAGE sql"
            , "1       AS $function$SELECT $1+1$function$"
            ]
        p_ $ do
            "That numbering is the point of the "
            c "+"
            ": when PostgreSQL reports an error at “line 12 of the function”, those are the numbers \
            \it means. "
            c "\\sv"
            " does the same for a view."
        p_ $ do
            "The editing pair, "
            c "\\ef"
            " and "
            c "\\ev"
            ", fetch the same text into your editor and re-run it on save — so fixing a function is \
            \a round trip of "
            c "\\ef myfunc"
            ", edit, save, quit. Day 7 sets your editor up properly. With no argument, "
            c "\\ef"
            " gives you a blank "
            c "CREATE FUNCTION"
            " template."
        tip $ p_ $ do
            "Both take a line number: "
            c "\\ef myfunc 12"
            " opens the editor with the cursor on line 12 of the body. It needs "
            c "PSQL_EDITOR_LINENUMBER_ARG"
            " set correctly for your editor, and the default of "
            c "+"
            " is right for vi, emacs and most others."

    block "The privilege grid, letter by letter" $ do
        p_ $ do
            c "\\dp"
            " (identically, "
            c "\\z"
            ") is the command everyone runs and nobody reads, because the Access privileges column \
            \is a dense little language. It is one entry per grantee, of the form "
            c "role=letters/grantor"
            ":"
        sh
            [ "testdb=# \\dp my_table"
            , "                                   Access privileges"
            , " Schema |   Name   | Type  |     Access privileges      | Column privileges | Policies "
            , "--------+----------+-------+----------------------------+-------------------+----------"
            , " public | my_table | table | postgres=arwdDxtm/postgres+|                   | "
            , "        |          |       | analysts=r/postgres        |                   | "
            , "(1 row)"
            ]
        p_ "Three things to decode, and then it is readable for life. The letters, for a table:"
        defs
            [ (c "r", "SELECT — think read")
            , (c "a", "INSERT — think append")
            , (c "w", "UPDATE — think write")
            , (c "d", "DELETE")
            , (c "D", "TRUNCATE")
            , (c "x", "REFERENCES — may point a foreign key at it")
            , (c "t", "TRIGGER")
            , (c "m", "MAINTAIN — may VACUUM, ANALYZE, REINDEX and friends")
            ]
        p_ $ do
            "So "
            c "arwdDxtm"
            " is the complete set, which is what an owner has. A "
            c "*"
            " after a letter means that privilege carries "
            c "WITH GRANT OPTION"
            " — "
            c "analysts=r*w/alice"
            " is “select and update, may pass the select on, granted by alice”. And an "
            b_ "empty grantee"
            ", as in "
            c "=r/postgres"
            ", is "
            c "PUBLIC"
            "."
        gotcha $ p_ $ do
            "An "
            i_ "empty"
            " Access privileges column does not mean “nobody can touch it”. It means no ACL has \
            \ever been written, so the built-in defaults apply: the owner has everything and nobody \
            \else has anything. The first "
            c "GRANT"
            " or "
            c "REVOKE"
            " on the object materialises the whole ACL, the owner's own row included — so the \
            \column growing from empty to two long lines can happen without anyone's access \
            \widening at all."
        p_ $ do
            "The Column privileges column is separate because column-level grants are separate. A \
            \table with "
            c "GRANT SELECT (customer)"
            " and nothing else has an empty Access privileges column and a populated Column \
            \privileges one — which is easy to skim straight past."

    block "Roles, membership, and settings that follow them around" $ do
        p_ $ do
            c "\\du"
            " lists roles and their "
            b_ "attributes"
            " — the things a role "
            i_ "is"
            ", rather than what it may touch: superuser, create role, create db, replication, \
            \bypass RLS, and “Cannot login” for a role with "
            c "NOLOGIN"
            "."
        sh
            [ "testdb=# \\du"
            , "                             List of roles"
            , " Role name |                         Attributes                         "
            , "-----------+------------------------------------------------------------"
            , " analysts  | Cannot login"
            , " postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS"
            , " reporter  | "
            ]
        why $ p_ $ do
            "What is missing is membership, and its absence is deliberate. A role grant now carries \
            \three independent options — "
            c "INHERIT"
            " (privileges flow without asking), "
            c "SET"
            " (may "
            c "SET ROLE"
            " to it) and "
            c "ADMIN"
            " (may grant it onward) — plus a grantor. That is a row, not a column, so it moved out \
            \into "
            c "\\drg"
            ". If you learned psql when "
            c "\\du"
            " had a “Member of” column, this is the change most likely to have you concluding that \
            \a role has no memberships."
        sh
            [ "testdb=# \\drg"
            , "               List of role grants"
            , " Role name | Member of |   Options    | Grantor  "
            , "-----------+-----------+--------------+----------"
            , " reporter  | analysts  | INHERIT, SET | postgres"
            , "(1 row)"
            ]
        p_ $ do
            "Two more in this corner of the family, both worth knowing exist. "
            c "\\ddp"
            " lists default privileges — the "
            c "ALTER DEFAULT PRIVILEGES"
            " settings that quietly pre-grant things on every object created in a schema, and the \
            \reason grants sometimes “come back”. And "
            c "\\drds"
            " lists settings pinned to a role or a database by "
            c "ALTER ROLE ... SET"
            " or "
            c "ALTER DATABASE ... SET"
            ", which is where an inexplicable "
            c "statement_timeout"
            " usually turns out to live."
        p_ $ do
            "Finally "
            c "\\dconfig"
            ", which is not about privileges but belongs to the same habit of asking the database \
            \about itself. With no pattern it shows only the parameters set to "
            i_ "non-default"
            " values — a two-minute way to learn what is unusual about a server you have just been \
            \given. "
            c "\\dconfig *"
            " shows all of them; "
            c "\\dconfig+ work_mem"
            " adds the type, the context in which it can be changed, and any granted privileges."

    block "Today's habit" $ do
        p_ $ do
            "When somebody asks “can this service read that table”, stop reasoning about it and run "
            c "\\dp"
            " and "
            c "\\drg"
            ". Two commands, and the answer includes the grant option and the grantor, which is \
            \more than the person asking wanted and exactly what the audit will."
        p_ "Tomorrow: making psql's output readable, which is the day that changes how the tool feels."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Privilege letters for a table."
        " Owner with everything reads "
        c "arwdDxtm"
        "."
    cfg
        [ "\\df pat        -- functions       \\df pat t1 t2  -- match argument types positionally"
        , "\\dfa \\dfn \\dfp \\dft \\dfw   -- aggregate / normal / procedure / trigger / window"
        , "\\sf name       -- source          \\sf+  numbers lines FROM THE BODY (line 1 = body line 1)"
        , "\\du            -- roles + attributes only        \\drg  -- membership: ADMIN/INHERIT/SET"
        , "\\dp  \\z        -- access privileges              \\ddp  -- privileges future objects get"
        , "\\dconfig       -- non-default server parameters  \\drds -- settings pinned to role/db"
        , "-- ACL entry:  role=letters/grantor    * after a letter = WITH GRANT OPTION"
        , "--   r select(read)  a insert(append)  w update(write)  d delete  D truncate"
        , "--   x references    t trigger         m maintain"
        , "-- role= with nothing on the left is PUBLIC"
        , "-- EMPTY column = no ACL yet = built-in defaults (owner all, others none), NOT \"no access\""
        ]
