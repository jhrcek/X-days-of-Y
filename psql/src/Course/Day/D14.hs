module Course.Day.D14 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 14
        , dayTitle = "Conditional scripts"
        , daySubtitle = "A four-command language with no arithmetic, no loops, and one silent failure mode."
        , dayMinutes = 30
        , dayLevel = "advanced"
        , dayManRef = "\\if, \\elif, \\else, \\endif; Variables"
        , dayTags = ["\\if", "\\gset", "idempotence"]
        , dayGoals =
            [ "branch a script on what a query found, using \\gset and :{?name}"
            , "read the prompt indicator that tells you you are inside a skipped branch"
            , "name the one way a conditional can fail while the script still reports success"
            ]
        , dayDiagram = Just d14diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("\\if expression", "Open a block. The expression is interpolated, then read as a Boolean.")
            , ("\\elif expression", "Another arm. Not evaluated at all once an earlier arm has matched.")
            , ("\\else", "At most one, and last before the " <> c "\\endif" <> ".")
            , ("\\endif", "Close the block. Must be in the same source file as its " <> c "\\if" <> ".")
            ]
        , dayOpts = []
        , dayConfig = []
        , dayDrills =
            [ "The simplest possible block: "
                <> c "\\if yes"
                <> ", "
                <> c "\\echo hello"
                <> ", "
                <> c "\\endif"
                <> ". Then change "
                <> c "yes"
                <> " to "
                <> c "no"
                <> " and watch the prompt become "
                <> c "@"
                <> " while it skips."
            , "Drive one from a query: "
                <> c "SELECT EXISTS(SELECT 1 FROM my_table WHERE first = 1) AS found"
                <> ", then "
                <> c "\\gset"
                <> ", then "
                <> c "\\if :found"
                <> "."
            , "Now the NULL trick: "
                <> c "SELECT NULL::text AS hit \\gset"
                <> " then "
                <> c "\\if :{?hit}"
                <> ". A NULL column unsets the variable, so “did the lookup find anything” \
                   \becomes a Boolean."
            , "Break it on purpose: "
                <> c "\\if maybe"
                <> ". Read the message, then check "
                <> c "echo $?"
                <> " after running the same thing from a file. It is 0, and the false branch ran."
            , "Break it differently: leave off the "
                <> c "\\endif"
                <> " and run the file. “reached EOF without finding closing \\endif(s)” — and \
                   \again exit 0 unless "
                <> c "ON_ERROR_STOP"
                <> " is set."
            , "Try to split a block across files: "
                <> c "\\if"
                <> " in one, "
                <> c "\\endif"
                <> " in a file it "
                <> c "\\ir"
                <> "s. It refuses, and now you know why."
            , "Write a real idempotent guard: check whether a column exists in "
                <> c "information_schema.columns"
                <> ", and "
                <> c "ALTER TABLE"
                <> " only if it does not."
            , "Take one of your own migration scripts and put a guard at the top: refuse to run \
              \unless the schema version is what you expect. Five lines, and it is the cheapest \
              \safety you will add this month."
            ]
        , dayQuiz =
            [
                ( "A deployment script has "
                    <> c "\\if :should_migrate"
                    <> " where the variable was never set. What runs, and what does the script exit \
                       \with?"
                , do
                    p_ $ do
                        "An unset name is not interpolated, so the expression is the literal text "
                        c ":should_migrate"
                        ", which is not a Boolean. psql reports “unrecognized value \
                        \\":should_migrate\" for \"\\if expression\": Boolean expected”, "
                        b_ "treats it as false"
                        ", and skips the block."
                    p_ $ do
                        "And the exit code is "
                        b_ "0"
                        " — even with "
                        opt "ON_ERROR_STOP"
                        " set. The manual page calls this a warning, and it behaves like one, \
                        \though psql prints it with an "
                        c "error:"
                        " prefix. So a typo in a variable name turns a migration into a silent \
                        \no-op that CI calls a success. Guard against it with "
                        c ":{?should_migrate}"
                        ", which is always substituted and always a Boolean."
                )
            ,
                ( "Why is there no "
                    <> c "\\while"
                    <> ", and no way to compare two numbers in an "
                    <> c "\\if"
                    <> "?"
                , do
                    p_ $ do
                        "Because "
                        c "\\if"
                        " does not evaluate expressions at all. It interpolates its argument, \
                        \expands backquotes, and then reads the "
                        i_ "result"
                        " exactly as it would read the value of an on/off variable — any \
                        \case-insensitive match for "
                        c "true"
                        ", "
                        c "false"
                        ", "
                        c "1"
                        ", "
                        c "0"
                        ", "
                        c "on"
                        ", "
                        c "off"
                        ", "
                        c "yes"
                        ", "
                        c "no"
                        ", or an unambiguous prefix of one."
                    p_ $ do
                        "So the arithmetic goes where arithmetic belongs. Compute the Boolean in \
                        \SQL and "
                        c "\\gset"
                        " it — "
                        c "SELECT count(*) > 100 AS busy FROM ... \\gset"
                        " — or in the shell, with backquotes. psql is deliberately not a \
                        \programming language, and the moment you want a loop you want a shell \
                        \script that calls psql, or "
                        c "\\gexec"
                        " from yesterday."
                )
            ,
                ( "Inside a skipped branch, does "
                    <> c "\\set x `rm -rf /tmp/thing`"
                    <> " run the shell command?"
                , do
                    p_ $ do
                        "No. Skipped lines are parsed enough to find where the block ends, but \
                        \queries are not sent, backslash commands other than the four conditionals \
                        \are ignored, "
                        b_ "variable references are not expanded and backquotes are not run"
                        "."
                    p_ $ do
                        "That is a stronger guarantee than it looks, and it is what makes "
                        c "\\if"
                        " usable for guarding destructive operations. The one thing still checked \
                        \in a skipped region is conditional nesting, so a stray "
                        c "\\endif"
                        " inside a branch you never take will still be reported."
                )
            ,
                ( "Your script "
                    <> c "\\ir"
                    <> "s a helper file, and you put the "
                    <> c "\\if"
                    <> " in the caller and the "
                    <> c "\\endif"
                    <> " in the helper. Why is that rejected?"
                , do
                    p_ $ do
                        "Because a conditional block must live entirely in one source file — “all \
                        \the backslash commands of a given conditional block must appear in the \
                        \same source file”. The helper's "
                        c "\\endif"
                        " reports “no matching \\if”, and the caller then hits EOF with a block \
                        \still open."
                    p_ $ do
                        "The restriction is what makes an included file safe to read on its own: \
                        \you can never be looking at a file whose meaning depends on a branch \
                        \opened somewhere you cannot see. Put the whole decision in the caller and \
                        \include different files in different branches instead."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d14diagram :: Diagram
d14diagram =
    ( diagram
        "A conditional block is opened by a Boolean expression which selects a branch; the block \
        \must live entirely in one source file and shows the @ prompt indicator while inactive; \
        \an untaken branch is made of skipped lines, and a non-Boolean expression silently \
        \selects the false branch."
        body'
    )
        { dgCaption = do
            "The amber aspect is the whole reason to spend a day on four commands. A "
            b_ "non-Boolean expression"
            " — most often an unset variable name that was never interpolated — is reported and \
            \then "
            i_ "treated as false"
            ", and "
            opt "ON_ERROR_STOP"
            " does not catch it, so the script exits 0. A skipped branch is genuinely inert: \
            \nothing is sent, no variable is expanded, no backquote is run."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  blk    [label=\"a conditional block\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  cond   [label=\"a Boolean expression\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  branch [label=\"a branch\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  skip   [label=\"a skipped line\"];\n\
        \  bad    [label=\"a non-Boolean\\nexpression\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  file   [label=\"one source file\", fillcolor=\"#f4efe6\"];\n\
        \  ind    [label=\"the @ prompt\\nindicator\"];\n\
        \\n\
        \  blk    -> cond   [label=\"  is opened by\"];\n\
        \  cond   -> branch [label=\"  selects\"];\n\
        \  blk    -> branch [label=\"contains  \"];\n\
        \  blk    -> file   [label=\"  must live entirely in\"];\n\
        \  blk    -> ind    [label=\"shows, while inactive,  \"];\n\
        \  branch -> skip   [label=\"  when untaken, is made of\"];\n\
        \  bad    -> branch [label=\"  silently selects the false\", style=dashed];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Four commands, and no expression language" $ do
        p_ [class_ "lede"] $ do
            c "\\if"
            ", "
            c "\\elif"
            ", "
            c "\\else"
            ", "
            c "\\endif"
            " — nestable, and that is the whole of it. There is no arithmetic, no comparison, no \
            \loop. Understanding why is the fastest route to using them well."
        p_ $ do
            c "\\if"
            " does not evaluate its argument. It interpolates variables and expands backquotes, and \
            \then reads the resulting text exactly as it reads the value of an on/off variable: any \
            \case-insensitive match for "
            c "true"
            ", "
            c "false"
            ", "
            c "1"
            ", "
            c "0"
            ", "
            c "on"
            ", "
            c "off"
            ", "
            c "yes"
            ", "
            c "no"
            " — or an unambiguous prefix, so "
            c "t"
            ", "
            c "T"
            " and "
            c "tR"
            " are all true."
        why $ p_ $ do
            "So the arithmetic goes where arithmetic already lives. You have a database that can \
            \evaluate any expression you like, a shell that can evaluate the rest, and "
            c "\\gset"
            " to carry the answer back — "
            c "SELECT count(*) > 100 AS busy FROM pg_stat_activity \\gset"
            " and then "
            c "\\if :busy"
            ". Building a second expression language into psql would have duplicated both of them \
            \badly. When you find yourself wanting a loop, what you want is a shell script that \
            \calls psql, or "
            c "\\gexec"
            "."
        fig

    block "Branching on what a query found" $ do
        p_ $ do
            "The standard shape is a query that computes Booleans, "
            c "\\gset"
            " to turn them into variables, and a block that reads them. This is the manual page's \
            \own example, and it is worth typing once:"
        sh
            [ "-- do two particular records exist?"
            , "SELECT EXISTS(SELECT 1 FROM customer WHERE customer_id = 123) AS is_customer,"
            , "       EXISTS(SELECT 1 FROM employee WHERE employee_id = 456) AS is_employee"
            , "\\gset"
            , "\\if :is_customer"
            , "    SELECT * FROM customer WHERE customer_id = 123;"
            , "\\elif :is_employee"
            , "    \\echo 'not a customer but is an employee'"
            , "    SELECT * FROM employee WHERE employee_id = 456;"
            , "\\else"
            , "    \\echo 'neither'"
            , "\\endif"
            ]
        p_ $ do
            "The second shape uses yesterday's NULL rule. A "
            c "\\gset"
            " column that comes back NULL "
            i_ "unsets"
            " its variable rather than setting it, and "
            c ":{?name}"
            " is "
            c "TRUE"
            " or "
            c "FALSE"
            " according to whether a variable exists. Together they turn “did the lookup find \
            \anything” into a Boolean without a second query:"
        sh
            [ "testdb=# SELECT max(first) AS hi FROM my_table WHERE second = 'nine' \\gset"
            , "testdb=# \\if :{?hi}"
            , "testdb@#   \\echo found: :hi"
            , "testdb=# \\else"
            , "testdb=#   \\echo nothing matched"
            , "testdb=# \\endif"
            , "nothing matched"
            ]
        p_ $ do
            "Note the prompt in that transcript. In an inactive branch "
            c "%R"
            " shows "
            c "@"
            " instead of "
            c "="
            ", and psql tells you when it ignores something: “\\echo command ignored; use \\endif \
            \or Ctrl-C to exit current \\if block”. If you have ever been stuck at a psql that \
            \refuses to do anything, that "
            c "@"
            " is what you were looking at."

    block "The failure that reports success" $ do
        p_ $ do
            "This is the day's real content. An expression that does not evaluate to a Boolean is "
            b_ "treated as false"
            ", and it does not stop the script — not even with "
            opt "ON_ERROR_STOP"
            " set:"
        sh
            [ "$ cat guard.sql"
            , "\\if maybe"
            , "\\echo migrating"
            , "\\endif"
            , "\\echo done"
            , "$ psql -X -v ON_ERROR_STOP=1 -f guard.sql; echo $?"
            , "psql:guard.sql:1: error: unrecognized value \"maybe\" for \"\\if expression\": Boolean expected"
            , "done"
            , "0"
            ]
        gotcha $ p_ $ do
            "The commonest way to hit it is a "
            b_ "misspelled variable name"
            ". An unset name is not interpolated, so "
            c "\\if :shuold_migrate"
            " leaves the literal text "
            c ":shuold_migrate"
            " as the expression, which is not a Boolean, so the block is skipped and the script \
            \exits 0. Your deployment did nothing and CI went green. The manual page calls this a \
            \warning — psql prints it with an "
            c "error:"
            " prefix, but it behaves as the page says."
        p_ $ do
            "Two defences. Use "
            c ":{?name}"
            " for existence tests, because it is always substituted and always yields "
            c "TRUE"
            " or "
            c "FALSE"
            ". And where the value matters, assert it rather than assuming it:"
        sh
            [ "\\if :{?target_schema}"
            , "\\else"
            , "    \\warn target_schema was not set; refusing to run"
            , "    \\q"
            , "\\endif"
            ]
        gotcha $ p_ $ do
            "Two traps in those four lines, and both are worth more than the guard itself. First, "
            c "\\q"
            " in a script terminates the script and exits "
            b_ "0"
            " — it is a “stop here”, not a “fail”. It takes no argument either: "
            c "\\q 3"
            " answers “\\q: extra argument \"3\" ignored”. If the caller checks the exit code, \
            \raise a real error instead and let "
            opt "ON_ERROR_STOP"
            " turn it into a 3:"
        sh
            [ "\\warn refusing to run against :DBNAME"
            , "DO $$ BEGIN RAISE EXCEPTION 'wrong database'; END $$;"
            , "-- psql -X -v ON_ERROR_STOP=1 -f guard.sql  ->  exit 3"
            ]
        p_ $ do
            "Second, note that the "
            c "\\warn"
            " argument above is "
            b_ "not"
            " quoted. Interpolation in a meta-command argument happens only for an "
            i_ "unquoted"
            " colon, so "
            c "\\warn 'against :DBNAME'"
            " prints the literal "
            c ":DBNAME"
            " while "
            c "\\warn against :DBNAME"
            " prints "
            c "against testdb"
            ". The quotes you add for readability are exactly what stops the substitution you \
            \wanted."
        p_ $ do
            "The other structural failure is an unclosed block. Reaching EOF with an "
            c "\\if"
            " still open is an error — “reached EOF without finding closing \\endif(s)” — and "
            i_ "that"
            " one does respect "
            opt "ON_ERROR_STOP"
            ", giving you exit code 3. So of the two ways to get a conditional wrong, one is \
            \catchable and the other is not."

    block "What a skipped branch does not do" $ do
        p_ $ do
            "Lines in an untaken branch are parsed, so that psql can find the matching "
            c "\\elif"
            ", "
            c "\\else"
            " or "
            c "\\endif"
            ". Beyond that they are inert, and the list of what does not happen is the useful part:"
        steps
            [ "Queries are not sent to the server."
            , do
                "Backslash commands other than the four conditionals are ignored — including "
                c "\\!"
                ", "
                c "\\copy"
                " and "
                c "\\i"
                "."
            , do
                "Variable references are "
                i_ "not"
                " expanded, and backquotes are "
                i_ "not"
                " run. So a "
                c "`rm -rf ...`"
                " inside a skipped branch does nothing at all."
            , "Conditional nesting is still checked, so a stray \\endif in a branch you never take is still reported."
            ]
        p_ $ do
            "That third point is what makes "
            c "\\if"
            " trustworthy as a guard around destructive work, rather than merely a way of not \
            \printing things."
        note $ p_ $ do
            "One structural rule, and it is absolute: a block must live entirely in one source \
            \file. An "
            c "\\if"
            " in the caller and its "
            c "\\endif"
            " in an "
            c "\\ir"
            "-included helper is rejected. The point is that you can read an included file on its \
            \own and know what it does, without hunting for a branch opened in a file you have not \
            \seen."

    block "Idempotence, which is what this is really for" $ do
        p_ $ do
            "Most SQL scripts want to be safe to run twice. Some of that is available in SQL — "
            c "CREATE TABLE IF NOT EXISTS"
            ", "
            c "DROP ... IF EXISTS"
            ", "
            c "CREATE OR REPLACE"
            " — and some is not, notably "
            c "ALTER TABLE ... ADD COLUMN"
            " on older servers, and anything whose guard is a data question rather than a schema \
            \one. That gap is where "
            c "\\if"
            " earns its place:"
        sh
            [ "SELECT NOT EXISTS ("
            , "  SELECT 1 FROM information_schema.columns"
            , "   WHERE table_schema = 'app' AND table_name = 'orders' AND column_name = 'shipped'"
            , ") AS needs_column"
            , "\\gset"
            , "\\if :needs_column"
            , "    ALTER TABLE app.orders ADD COLUMN shipped timestamptz;"
            , "    \\echo 'added app.orders.shipped'"
            , "\\else"
            , "    \\echo 'app.orders.shipped already present'"
            , "\\endif"
            ]
        p_ $ do
            "And the guard at the top of a migration, which is five lines and prevents the class of \
            \accident nothing else will: refuse to run unless the database is the one you think it \
            \is."
        sh
            [ "SELECT current_database() = 'staging' AS right_db \\gset"
            , "\\if :right_db"
            , "\\else"
            , "    \\warn refusing to run against :DBNAME"
            , "    DO $$ BEGIN RAISE EXCEPTION 'wrong database'; END $$;"
            , "\\endif"
            ]
        tip $ p_ $ do
            "Nothing today goes in your psqlrc. Conditionals are for scripts, and scripts pass "
            c "-X"
            " — but do give every script of your own the "
            c ":{?name}"
            " guard above for each variable it expects on the command line. It is the difference \
            \between a missing "
            c "-v"
            " being caught and being silently ignored."

    block "Today's habit" $ do
        p_ $ do
            "Add a guard to one script. Either the wrong-database check or a "
            c ":{?name}"
            " assertion on its arguments — whichever the script's last near-miss suggests. And \
            \remember the shape of the silent failure: a conditional whose expression is not a \
            \Boolean does nothing and says everything went fine."
        p_ "Tomorrow: the prompt, which after today you have a specific reason to care about."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "The one to remember."
        " A non-Boolean expression is false, and "
        c "ON_ERROR_STOP"
        " does not catch it."
    cfg
        [ "\\if expr / \\elif expr / \\else / \\endif        -- nestable; ALL in one source file"
        , "expr is NOT evaluated: it is interpolated, then read as on/off"
        , "  true false 1 0 on off yes no + unambiguous prefixes (t, T, tR are all true)"
        , "SELECT <boolean expr> AS ok \\gset      then     \\if :ok        -- do the maths in SQL"
        , "SELECT ... AS hit \\gset  -- a NULL column UNSETS it; test with \\if :{?hit}"
        , "\\if :{?v}   -- always substituted, always Boolean. Use it for \"was -v given?\""
        , "\\if :v      -- if v is unset the expression is the literal ':v' -> false, exit 0 (!)"
        , "unclosed block at EOF -> error, and this one DOES honour ON_ERROR_STOP (exit 3)"
        , "prompt shows @ instead of = while a branch is inactive"
        , "a skipped branch sends nothing, expands no :vars, runs no `backticks`"
        , "\\warn 'refusing' + \\q   -- the bail-out pair for a failed guard"
        ]
