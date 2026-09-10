module Course.Day.D01 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 1
        , dayTitle = "The query buffer"
        , daySubtitle = "Nothing is sent until a semicolon says so — and the prompt tells you what is waiting."
        , dayMinutes = 30
        , dayLevel = "essential"
        , dayManRef = "DESCRIPTION, Entering SQL Commands, Meta-Commands"
        , dayTags = ["buffer", "semicolon", "prompt"]
        , dayGoals =
            [ "explain why pressing Enter does not send your query but a semicolon does"
            , "read the second character of the prompt and know exactly what psql is still waiting for"
            , "repair a long mistyped query with " <> c "\\p" <> ", " <> c "\\e" <> " and " <> c "\\r" <> " instead of typing it out again"
            ]
        , dayDiagram = Just d1diagram
        , dayBody = body
        , dayKeys =
            [ ("C-c", "Abandon the line you are typing and empty the query buffer.")
            , ("C-d", "End the session — but only when the buffer is empty.")
            ]
        , dayCmds =
            [ ("psql", "Connect with the defaults and start an interactive session.")
            , (";", "Dispatch the buffer. Not a meta-command — SQL's own statement terminator.")
            , ("\\g", "Dispatch the buffer, exactly as a semicolon does.")
            , ("\\p", "Print the buffer without sending it. " <> c "\\print" <> " in full.")
            , ("\\r", "Reset: throw the buffer away. " <> c "\\reset" <> " in full.")
            , ("\\e", "Edit the buffer in " <> c "$EDITOR" <> "; on exit it is re-parsed and run.")
            , ("\\w file", "Write the buffer to a file instead of sending it.")
            , ("\\;", "Append a semicolon to the buffer " <> i_ "without" <> " dispatching it.")
            , ("\\?", "Every meta-command, in twelve groups. 121 of them in 18.6.")
            , ("\\h SELECT", "Syntax for one SQL command. " <> c "\\h" <> " alone lists what it knows.")
            , ("\\q", "Quit.")
            ]
        , dayOpts = []
        , dayConfig = []
        , dayDrills =
            [ "Start psql, type "
                <> c "SELECT 1"
                <> " and press Enter. Press Enter twice more. Nothing happens, and the prompt has \
                   \changed. Now type a semicolon on its own line."
            , "Type a query across three lines — "
                <> c "SELECT first, second"
                <> ", then "
                <> c "FROM my_table"
                <> ", then "
                <> c "WHERE first > 2"
                <> " — and before sending it press "
                <> c "\\p"
                <> ". You are looking at the buffer."
            , "Now press "
                <> c "\\r"
                <> " and "
                <> c "\\p"
                <> " again. “Query buffer is empty.” You threw away three lines without sending them."
            , "Break it on purpose: type "
                <> c "SELECT 'oops"
                <> " and press Enter. The prompt is now "
                <> c "'#"
                <> ". Try "
                <> c "\\r"
                <> " — it does not work. Read the next paragraph, then get yourself out."
            , "Send a query, then press "
                <> c "\\g"
                <> " on an empty buffer. It runs again. That is the cheapest “refresh” psql has."
            , "Type a query you got wrong, then "
                <> c "\\e"
                <> ". Fix it in your editor, save, quit. It runs the moment the editor exits."
            , "Run "
                <> c "\\?"
                <> " once and read only the group headings — twelve of them. You are not learning \
                   \the commands today, you are learning that they are grouped."
            , "Take the longest query in your own work — the one you keep pasting from a scratch \
              \file — and paste it into psql without the trailing semicolon. Then "
                <> c "\\p"
                <> " it. From today, that is how you check a paste arrived intact."
            ]
        , dayQuiz =
            [
                ( "You paste a 40-line query and press Enter. psql sits there showing "
                    <> c "testdb-#"
                    <> " and does nothing. Nothing is wrong with the query. What happened?"
                , do
                    p_ $ do
                        "The paste had no trailing semicolon, so the whole thing is sitting in the \
                        \query buffer waiting to be dispatched. The "
                        c "-"
                        " in the prompt is "
                        c "%R"
                        " reporting exactly that: “the statement simply is not terminated yet”."
                    p_ $ do
                        "Type "
                        c ";"
                        " or "
                        c "\\g"
                        ". This is also why "
                        c "\\p"
                        " is worth reaching for after a large paste — a terminal that dropped a \
                        \line will show up there before the server ever sees it."
                )
            ,
                ( "You mistype and end up at a "
                    <> c "'#"
                    <> " prompt. "
                    <> c "\\r"
                    <> " does nothing, and "
                    <> c "\\q"
                    <> " answers “Use control-D to quit.” Why have your meta-commands stopped working?"
                , do
                    p_ $ do
                        "Because a meta-command is a line beginning with an "
                        b_ "unquoted"
                        " backslash, and you are inside an unfinished single-quoted string. Every \
                        \backslash you type is now just a character in that string, so psql has \
                        \nothing to obey."
                    p_ $ do
                        "Two ways out. Type a closing "
                        c "'"
                        " — the prompt reverts to "
                        c "-#"
                        " and "
                        c "\\r"
                        " works again — or press "
                        k "C-c"
                        ", which abandons the line and empties the buffer regardless of what is in it."
                )
            ,
                ( "Why does psql use a semicolon rather than Enter to send a statement, when every \
                  \other interactive interpreter you use sends on Enter?"
                , do
                    p_ $ do
                        "Because SQL statements are routinely longer than a line, and psql has no \
                        \way to know whether "
                        c "SELECT count(*)"
                        " is finished or about to grow a "
                        c "FROM"
                        " clause. Rather than guess, it delegates the decision to SQL's own \
                        \statement terminator and lets you lay a query out over as many lines as \
                        \it deserves."
                    p_ $ do
                        "The other bargain is available: "
                        c "-S"
                        " (or "
                        opt "SINGLELINE"
                        ") makes a newline terminate a statement too. The manual page offers it \
                        \“for those who insist on it” and then says you are not encouraged to use \
                        \it, because mixing SQL and meta-commands on one line stops being \
                        \predictable."
                )
            ,
                ( "You try "
                    <> c "psql -c 'SELECT 1 \\gdesc'"
                    <> " and get a syntax error pointing at the backslash. But the same two lines \
                       \work fine when you type them at the prompt. What is different?"
                , do
                    p_ $ do
                        "A "
                        c "-c"
                        " string never enters the query buffer. It is handed to the server as one \
                        \request, so it has to be either something the server can parse — pure SQL \
                        \— or a single backslash command that psql handles itself. There is no \
                        \buffer in between for "
                        c "\\gdesc"
                        " to act on, and the server has no idea what a backslash means."
                    p_ $ do
                        "Repeat the flag instead ("
                        c "psql -c '\\x' -c 'SELECT 1'"
                        ") or feed the pair on standard input, where the buffer does exist. Day 11 \
                        \takes this apart properly."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d1diagram :: Diagram
d1diagram =
    ( diagram
        "A line you type is appended to the query buffer, which at a semicolon becomes a \
        \complete SQL statement sent to the server; a line beginning with an unquoted backslash \
        \is instead a meta-command, which reads and rewrites the buffer and may query the server \
        \on its own account."
        body'
    )
        { dgCaption = do
            "Every meta-command in the manual page is described in terms of "
            b_ "the query buffer"
            ", so it is the noun to learn first. Two things reach the server: a statement the \
            \buffer produced at a semicolon, and the catalogue queries that "
            c "\\d"
            " and friends issue behind your back — Day 17 shows you how to watch those. The \
            \dashed aspects are the partial ones: not every line is a meta-command, and most \
            \meta-commands never touch the connection."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  inp  [label=\"a line you type\", fillcolor=\"#f4efe6\"];\n\
        \  buf  [label=\"the query buffer\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  stmt [label=\"a complete\\nSQL statement\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  meta [label=\"a meta-command\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  srv  [label=\"the PostgreSQL server\", fillcolor=\"#f4efe6\"];\n\
        \  res  [label=\"a result\"];\n\
        \\n\
        \  inp  -> buf  [label=\"  is appended to\"];\n\
        \  inp  -> meta [label=\"can instead be  \", style=dashed];\n\
        \  buf  -> stmt [label=\"  becomes, at a semicolon,\"];\n\
        \  meta -> buf  [label=\"reads and rewrites  \"];\n\
        \  stmt -> srv  [label=\"  is sent to\"];\n\
        \  meta -> srv  [label=\"may itself query  \", style=dashed];\n\
        \  srv  -> res  [label=\"  answers with\"];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "psql looks like a REPL and is not one" $ do
        p_ [class_ "lede"] $ do
            "What you type does not go anywhere. It accumulates in a "
            b_ "query buffer"
            ", and the buffer is handed to the server only when something dispatches it. Almost \
            \every confusing thing psql does in your first hour with it follows from that one fact."
        p_ $ do
            "Two things dispatch the buffer: a semicolon, and "
            c "\\g"
            ". An end of line does not. So a statement can be spread over as many lines as it \
            \needs, and pressing Enter on an unfinished one is not a mistake — it is the normal way \
            \to write anything longer than a screen width."
        p_ $ do
            "Everything else you type is a "
            b_ "meta-command"
            ": a line starting with an unquoted backslash, handled by psql itself rather than sent \
            \anywhere. There are 121 of them in 18.6, and the majority are described in the manual \
            \page as acting on the query buffer — which is why the buffer is the first noun worth \
            \learning rather than the fortieth."
        why $ p_ $ do
            "Why a semicolon rather than Enter? Because psql cannot know whether "
            c "SELECT count(*)"
            " is a finished query or one about to grow a "
            c "FROM"
            " clause. A newline-terminated client would force you to write every join on one line. \
            \Instead psql declines to guess and delegates the decision to SQL's own statement \
            \terminator. The other bargain is on offer — "
            c "-S"
            " makes a newline terminate too — and the manual page offers it “for those who insist \
            \on it” before advising against it."
        fig

    block "The prompt is a status display, not decoration" $ do
        p_ $ do
            "The default prompt is four separate pieces of information. Connected to "
            c "testdb"
            " as a superuser you see "
            c "testdb=#"
            ", and that decomposes as:"
        defs
            [ (c "testdb", "the database you are connected to — it changes when you " <> c "\\c" <> " elsewhere")
            ,
                ( c "="
                , do
                    "psql is ready for a new statement. This is the character that changes most, \
                    \and the next section is about it."
                )
            ,
                ( "(nothing)"
                , do
                    "the transaction slot, empty outside a transaction block. It shows "
                    c "*"
                    " inside one and "
                    c "!"
                    " once a statement in it has failed. Day 8."
                )
            ,
                ( c "#"
                , do
                    "a superuser gets "
                    c "#"
                    ", everybody else gets "
                    c ">"
                    ". Worth a glance before every "
                    c "DELETE"
                    "."
                )
            ]
        p_ $ do
            "When the buffer is unfinished, the third character is replaced by one that says "
            i_ "why"
            " psql wants more input. This is the single highest-value thing to learn about psql's \
            \interface, because it turns “it has hung” into a diagnosis:"
        defs
            [ (c "-", "the statement is simply not terminated yet. Type a semicolon.")
            , (c "'", "an unfinished single-quoted string.")
            , (c "\"", "an unfinished quoted identifier.")
            , (c "(", "an unmatched left parenthesis.")
            , (c "*", "an unfinished " <> c "/* ... */" <> " comment.")
            , (c "$", "an unfinished dollar-quoted string — the usual one inside a function body.")
            ]
        sh
            [ "testdb=# SELECT first, second"
            , "testdb-#   FROM my_table"
            , "testdb-#  WHERE second = 'two'"
            , "testdb-# ;"
            , " first | second "
            , "-------+--------"
            , "     2 | two"
            , "(1 row)"
            ]
        gotcha $ do
            p_ $ do
                "A stray quote is the one that costs people twenty minutes, because it takes your \
                \meta-commands away. A meta-command is a line beginning with an "
                b_ "unquoted"
                " backslash; inside an open string every backslash is just a character:"
            sh
                [ "testdb=# SELECT 'oops"
                , "testdb'# \\r"
                , "testdb'# \\q"
                , "Use control-D to quit."
                , "testdb'# '"
                , "testdb-# \\r"
                , "Query buffer reset (cleared)."
                ]
            p_ $ do
                "Close the quote and your commands come back, or press "
                k "C-c"
                ", which abandons the line and empties the buffer whatever state it is in. "
                k "C-d"
                " only quits when the buffer is already empty."

    block "Six commands that talk about the buffer" $ do
        p_ "These are worth having as reflexes before you learn a single describe command."
        defs
            [ (c "\\p", "print the buffer. After a big paste, this is how you confirm it arrived whole.")
            , (c "\\r", "reset it — discard everything typed so far without sending it.")
            ,
                ( c "\\e"
                , do
                    "open the buffer in "
                    c "$PSQL_EDITOR"
                    ", "
                    c "$EDITOR"
                    " or "
                    c "$VISUAL"
                    " — in that order, defaulting to "
                    c "vi"
                    ". Day 7."
                )
            , (c "\\w file", "write the buffer to a file rather than the server.")
            ,
                ( c "\\g"
                , do
                    "send it. On an "
                    i_ "empty"
                    " buffer it re-runs the last query instead, which makes it a one-keystroke refresh."
                )
            ,
                ( c "\\;"
                , do
                    "append a semicolon without dispatching. "
                    c "SELECT 1\\; SELECT 2;"
                    " sends both statements as a single request — and therefore a single \
                    \transaction. Day 8 explains why you would want that."
                )
            ]
        note $ p_ $ do
            "Several buffer commands quietly fall back to “the last query you ran” when the buffer \
            \is empty: "
            c "\\p"
            ", "
            c "\\w"
            ", "
            c "\\g"
            ", "
            c "\\e"
            " and, later, "
            c "\\gexec"
            " and "
            c "\\watch"
            ". It is a small kindness that saves a lot of up-arrow."

    block "Where the two languages meet" $ do
        p_ $ do
            "Meta-command arguments are parsed by psql, not by SQL, and the rules are their own. \
            \Parsing stops at the end of the line — an argument can never continue onto the next \
            \one. An unquoted backslash starts a new meta-command, so several can share a line. And \
            \the special sequence "
            c "\\\\"
            " means “arguments end here, resume reading SQL”, which is how you mix the two:"
        sh
            [ "$ echo '\\x \\\\ SELECT * FROM my_table;' | psql testdb"
            ]
        p_ $ do
            "Single quotes group an argument and permit the usual C escapes ("
            c "\\n"
            ", "
            c "\\t"
            ", "
            c "\\xNN"
            "). Double quotes around an identifier argument protect it from being folded to lower \
            \case — the same rule SQL uses, so "
            c "\\d FOO"
            " describes "
            c "foo"
            " and "
            c "\\d \"Foo\""
            " describes "
            c "Foo"
            "."
        p_ $ do
            "Two escape hatches you need on day one, and then rarely: "
            c "\\?"
            " lists every meta-command in the twelve groups psql organises them into, and "
            c "\\h"
            " gives SQL syntax — "
            c "\\h ALTER TABLE"
            " rather than a trip to the browser. Multi-word commands need no quoting."
        tip $ p_ $ do
            "Read "
            c "\\?"
            " once for the group names — General, Help, Query Buffer, Input/Output, Conditional, \
            \Informational, Large Objects, Formatting, Connection, Operating System, Variables, \
            \Extended Query Protocol. Those twelve groups are more or less the rest of this course, \
            \and knowing which group a problem is in tells you what to search for."

    block "Today's habit" $ do
        p_ $ do
            "Stop retyping queries. When something is wrong with a long statement, the answer is "
            c "\\e"
            " and never the up-arrow followed by twenty presses of the left arrow. When a paste \
            \looks like it hung, look at the second character of the prompt before you look at \
            \anything else."
        p_ "Tomorrow: getting connected to the right database on purpose rather than by luck."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Day 1 in nine lines."
        " The prompt characters are the part to memorise."
    cfg
        [ ";        -- dispatch the buffer;  \\g does the same, and repeats on an empty buffer"
        , "\\p       -- print the buffer      \\r  throw it away      \\e  edit it      \\w  save it"
        , "\\;       -- semicolon WITHOUT dispatch: one request, one transaction"
        , "\\?       -- all 121 meta-commands, in 12 groups     \\h SELECT  -- SQL syntax"
        , "C-c      -- abandon the line and empty the buffer   C-d  quit (empty buffer only)"
        , "-- second prompt character = what psql is waiting for:"
        , "--   =  ready      -  unterminated statement    '  open string     \"  open identifier"
        , "--   (  open paren *  open /* comment */        $  open $$ quote"
        , "-- last prompt character: # superuser, > not.  Before it: * in tx, ! failed tx."
        ]
