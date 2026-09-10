module Course.Day.D07 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 7
        , dayTitle = "Editing and history"
        , daySubtitle = "Readline sits in front of the buffer, your editor sits behind it, and one file per database."
        , dayMinutes = 30
        , dayLevel = "intermediate"
        , dayManRef = "Command-Line Editing, \\e, \\ef, \\ev, \\s, ENVIRONMENT"
        , dayTags = ["readline", "\\e", "history"]
        , dayGoals =
            [ "keep a separate command history for every database you connect to"
            , "fix a function in your editor and have the change applied on save"
            , "say why setting HISTFILE at the prompt does nothing"
            ]
        , dayDiagram = Just d7diagram
        , dayBody = body
        , dayKeys =
            [ ("Tab", "Complete a keyword or an object name. Twice for a menu, depending on the library.")
            , ("Up C-p", "The previous line from the history.")
            , ("C-r", "Reverse incremental search through the history. The one worth learning today.")
            ]
        , dayCmds =
            [ ("\\e", "Edit the buffer — or a file, or the last query — optionally at a line number.")
            , ("\\ef name", "Fetch a function's definition into your editor. " <> c "\\ev" <> " for a view.")
            , ("\\s file", "Print the command history, or write it to a file.")
            ]
        , dayOpts =
            [ ("HISTFILE", "Where history is kept. Default " <> c "~/.psql_history" <> ". Must be set in psqlrc.")
            , ("HISTSIZE", "How many commands to keep. Default 500; a negative value means no limit.")
            , ("HISTCONTROL", c "ignorespace" <> " / " <> c "ignoredups" <> " / " <> c "ignoreboth" <> " / " <> c "none" <> " (default).")
            , ("COMP_KEYWORD_CASE", "Casing for completed keywords. Default " <> c "preserve-upper" <> ".")
            , ("PSQL_EDITOR EDITOR VISUAL", "Checked in that order. " <> c "vi" <> " if none of them is set.")
            , ("PSQL_EDITOR_LINENUMBER_ARG", "How a line number is passed. Default " <> c "+" <> ", which suits vi and emacs.")
            ]
        , dayConfig =
            [ ConfBlock
                "One history per database. Without this, up-arrow in the reporting database\noffers\
                \ you the migration you ran against production, which is a bad way to\nfind out how\
                \ tired you are. The :DBNAME interpolation only works here, in a\nstartup file —\
                \ setting HISTFILE at the prompt is silently ignored."
                "\\set HISTFILE ~/.psql_history-:DBNAME"
            , ConfBlock
                "500 lines of history is about a fortnight. Keep more, and stop storing the\nsame\
                \ SELECT forty times over."
                "\\set HISTSIZE 5000\n\\set HISTCONTROL ignoredups"
            ]
        , dayDrills =
            [ "Press "
                <> k "C-r"
                <> " and type three characters of a query you ran yesterday. If you take one thing \
                   \from today, this is it."
            , "Type "
                <> c "ins"
                <> " and press Tab. Then clear the line, type "
                <> c "INS"
                <> " and press Tab. The completion follows the case you typed — that is "
                <> c "preserve-upper"
                <> " at work."
            , "Type "
                <> c "SELECT * FROM "
                <> " and press Tab. psql is querying the server to answer you, which is worth \
                   \knowing before you do it inside a transaction."
            , "Put a wrong query in the buffer and "
                <> c "\\e"
                <> " it. Fix it, save, quit — it runs immediately if you left a semicolon on the \
                   \end, and waits if you did not."
            , "Break it on purpose: "
                <> c "\\e somefile.sql"
                <> " and quit the editor "
                <> i_ "without"
                <> " changing anything. The buffer is now empty — the file case and the buffer case \
                   \behave differently, and the manual page says so in one easily-missed sentence."
            , "Run "
                <> c "\\ef"
                <> " with no arguments. You get a blank "
                <> c "CREATE FUNCTION"
                <> " template, which is a pleasant way to start writing one."
            , "Add the "
                <> c "HISTFILE"
                <> " line to your psqlrc, restart, connect to two different databases and check \
                   \that two files appeared in your home directory."
            , "Then try setting "
                <> c "HISTFILE"
                <> " at the prompt instead and watch it do nothing at all. Knowing which settings \
                   \are start-up-only is half of knowing psql."
            ]
        , dayQuiz =
            [
                ( "You put "
                    <> c "\\set HISTFILE ~/.psql_history-:DBNAME"
                    <> " in your psqlrc and it works. You type the same line at the prompt and \
                       \nothing happens — no error, no new file. Why?"
                , do
                    p_ $ do
                        "The history file is chosen when the interactive session is set up, before \
                        \you have a prompt to type at. By the time you set the variable, psql has \
                        \already decided where the history will be written, and it will write it to "
                        c "~/.psql_history"
                        " when you quit. There is no warning because nothing is wrong — you set a \
                        \variable, and it will be honoured by your "
                        i_ "next"
                        " session."
                    p_ $ do
                        "There is a second trap in the same corner. "
                        c "-v HISTFILE=~/hist-:DBNAME"
                        " does not work either, because "
                        c "-v"
                        " assignments are not interpolated: you get a file named literally "
                        c "hist-:DBNAME"
                        ". The "
                        c ":DBNAME"
                        " trick belongs in a startup file, which is exactly where the manual page \
                        \puts it."
                )
            ,
                ( "Tab completion has just made "
                    <> c "SET TRANSACTION ISOLATION LEVEL"
                    <> " fail immediately after a "
                    <> c "BEGIN"
                    <> ". How is that possible?"
                , do
                    p_ $ do
                        "Because completing an object name means "
                        b_ "sending a query to the server"
                        ", and that query counts as the first statement of your transaction. "
                        c "SET TRANSACTION ISOLATION LEVEL"
                        " must be the first statement in a transaction block, so a stray Tab \
                        \between the "
                        c "BEGIN"
                        " and it is enough to lose the race."
                    p_ $ do
                        "The manual page raises exactly this example. It is also the reason "
                        c "-E"
                        " (Day 17) is so illuminating: a lot more crosses your connection than the \
                        \statements you typed."
                )
            ,
                ( "You want to turn tab completion off permanently. Which file, and why is it not \
                  \a psql setting?"
                , do
                    p_ $ do
                        "It is a readline setting, not a psql one, so it goes in "
                        c "~/.inputrc"
                        " — and readline lets you scope it to this application:"
                    cfg
                        [ "$if psql"
                        , "set disable-completion on"
                        , "$endif"
                        ]
                    p_ $ do
                        "For one run, "
                        c "-n"
                        " ("
                        c "--no-readline"
                        ") switches readline off altogether: no completion, no history recording, \
                        \no multi-line editing. Its real use is pasting text that contains literal \
                        \tab characters, which readline would otherwise try to complete."
                )
            ,
                ( "A colleague's "
                    <> c "\\ef myfunc 12"
                    <> " opens the editor at line 1 instead of line 12. What is unset?"
                , do
                    p_ $ do
                        c "PSQL_EDITOR_LINENUMBER_ARG"
                        ", or rather it is set to something their editor does not understand. psql \
                        \invokes the editor as "
                        c "$EDITOR <arg><n> <tempfile>"
                        ", and the default "
                        c "+"
                        " gives "
                        c "vi +12 /tmp/psql.edit.1234.sql"
                        " — right for vi, emacs and most others."
                    p_ $ do
                        "Editors wanting a separate word need the trailing space included in the \
                        \value: "
                        c "PSQL_EDITOR_LINENUMBER_ARG='--line '"
                        ". And the line number counts from the first line of the "
                        i_ "function body"
                        ", which is what the server means when it reports an error at line 12."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d7diagram :: Diagram
d7diagram =
    ( diagram
        "Readline edits the line you type, appends it to the history file and hands it to the \
        \query buffer; the buffer can be copied into a temporary file, opened in your editor, \
        \and the result replaces the buffer."
        body'
    )
        { dgCaption = do
            "Two separate machines sit either side of "
            b_ "the query buffer"
            ", and neither is psql. Readline owns the line you are typing — which is why \
            \completion and history are configured in "
            c "~/.inputrc"
            " rather than by psql, and why "
            c "-n"
            " removes all three at once. Your editor owns the buffer once "
            c "\\e"
            " has copied it into the amber box, and the round trip through a real file is why \
            \quitting the editor unchanged behaves differently for a file than for the buffer."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  line [label=\"a line you type\", fillcolor=\"#f4efe6\"];\n\
        \  rl   [label=\"readline\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  hist [label=\"the history file\\n(HISTFILE)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  buf  [label=\"the query buffer\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  tmp  [label=\"a temporary file\\n/tmp/psql.edit.PID.sql\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  ed   [label=\"your editor\", fillcolor=\"#f4efe6\"];\n\
        \\n\
        \  line -> rl   [label=\"  is edited by\"];\n\
        \  rl   -> hist [label=\"appends it to  \"];\n\
        \  rl   -> buf  [label=\"  hands the finished line to\"];\n\
        \  hist -> rl   [label=\"  is recalled by\", style=dashed, constraint=false];\n\
        \  buf  -> tmp  [label=\"  is copied into, by \\\\e\"];\n\
        \  tmp  -> ed   [label=\"  is opened in\"];\n\
        \  ed   -> buf  [label=\"replaces  \", style=dashed, constraint=false];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "The line editor is not psql" $ do
        p_ [class_ "lede"] $ do
            "Everything about editing a line, recalling an old one and completing a name is \
            \readline's work, not psql's. That is worth knowing for two practical reasons: your \
            \readline configuration applies here, and one flag — "
            c "-n"
            " — removes completion, history and multi-line editing together, because they are all \
            \the same library."
        p_ $ do
            "So the ordinary keys work: "
            k "C-a"
            " and "
            k "C-e"
            " for the ends of the line, "
            k "C-w"
            " and "
            k "C-u"
            " to kill backwards, "
            k "C-p"
            " and up-arrow through the history. The one people do not know they have is "
            k "C-r"
            ": reverse incremental search, three characters of a query you ran last Tuesday, and \
            \there it is."
        p_ $ do
            "Completion is more interesting than it looks. Keywords complete from a built-in list, \
            \but "
            b_ "object names complete by querying the server"
            ", which means a Tab has side effects on your connection:"
        gotcha $ p_ $ do
            "The manual page's own example: after "
            c "BEGIN"
            ", a tab-completion query counts as the transaction's first statement, so "
            c "SET TRANSACTION ISOLATION LEVEL"
            " is then too late and fails. If you have ever had that command fail “for no reason”, \
            \this was probably it."
        p_ $ do
            "Turning completion off is a readline matter, and readline can scope a setting to one \
            \application:"
        cfg
            [ "# ~/.inputrc"
            , "$if psql"
            , "set disable-completion on"
            , "$endif"
            ]
        fig

    block "Your editor, on both sides of the buffer" $ do
        p_ $ do
            c "\\e"
            " copies the query buffer to a temporary file, runs your editor on it, and re-parses \
            \whatever comes back. psql looks at "
            c "PSQL_EDITOR"
            ", then "
            c "EDITOR"
            ", then "
            c "VISUAL"
            ", and falls back to "
            c "vi"
            "."
        p_ "The re-parsing has a consequence people meet by accident. The returned text is treated as a single line, so:"
        steps
            [ "If it contains or ends with a semicolon, everything up to that semicolon is executed at once — you do not get a chance to look at it."
            , do
                "Whatever remains is redisplayed and waits for a "
                c ";"
                " or a "
                c "\\g"
                ", or a "
                c "\\r"
                " to abandon it."
            , do
                "Because the whole buffer counts as one line, a meta-command in it swallows \
                \everything after it as its arguments. So you cannot write meta-command scripts \
                \this way — that is what "
                c "\\i"
                " is for, on Day 11."
            ]
        p_ $ do
            "And one asymmetry worth committing to memory. Quit the editor without saving and: if \
            \you were editing "
            b_ "the buffer"
            ", it survives; if you were editing "
            b_ "a file or the previous query"
            ", the buffer is cleared."
        sh
            [ "testdb=# \\e somefile.sql        -- quit without changing anything"
            , "testdb=# \\p"
            , "Query buffer is empty."
            ]
        p_ $ do
            "The other two are the ones that change how you work on a schema. "
            c "\\ef name"
            " fetches a function as a "
            c "CREATE OR REPLACE FUNCTION"
            " statement, and "
            c "\\ev name"
            " does the same for a view; save and exit and the new definition is applied. With no \
            \argument, "
            c "\\ef"
            " gives you a blank template. Both take a line number, and it counts from the first \
            \line of the "
            i_ "body"
            " — the same numbering the server uses when it reports an error inside a function."
        tip $ p_ $ do
            "psql passes the line number using "
            c "PSQL_EDITOR_LINENUMBER_ARG"
            ", default "
            c "+"
            ", producing "
            c "vi +12 /tmp/psql.edit.1234.sql"
            ". If your editor wants a separate argument, include the space in the value: "
            c "PSQL_EDITOR_LINENUMBER_ARG='--line '"
            ". The temporary file goes in "
            c "$TMPDIR"
            "."

    block "One history per database" $ do
        p_ $ do
            "The history is saved on exit and reloaded on start-up, and by default it all goes into \
            \one file, "
            c "~/.psql_history"
            ", regardless of which database you were in. That means up-arrow in your reporting \
            \database offers you the migration you ran against production. The fix is the manual \
            \page's own example, and it works because a startup file runs "
            i_ "after"
            " connecting, so "
            c ":DBNAME"
            " already has a value:"
        cfg
            [ "\\set HISTFILE ~/.psql_history-:DBNAME"
            ]
        p_ $ do
            "Two more worth setting. "
            c "HISTSIZE"
            " defaults to 500, which is about a fortnight of real use; a negative value means no \
            \limit. And "
            c "HISTCONTROL"
            " borrows bash's vocabulary wholesale — the manual page cheerfully says this feature \
            \“was shamelessly plagiarized from Bash”:"
        defs
            [ (c "ignoredups", "do not store a line identical to the previous one")
            , (c "ignorespace", "do not store a line that begins with a space — the deliberate way to keep something out")
            , (c "ignoreboth", "both of the above")
            , (c "none", "the default: store everything typed interactively")
            ]
        gotcha $ p_ $ do
            c "HISTFILE"
            " only has an effect if it is set "
            b_ "before the session starts"
            " — that is, in a startup file. Type it at the prompt and nothing happens: no error, \
            \no new file, and your history quietly goes to the default location. Nor can you use "
            c "-v HISTFILE=~/h-:DBNAME"
            ", because "
            c "-v"
            " does not interpolate; you get a file named literally "
            c "h-:DBNAME"
            "."
        p_ $ do
            c "\\s"
            " prints the history, and "
            c "\\s file"
            " writes it out — the quickest way to turn “what did I actually run this afternoon” \
            \into a script you can edit. It is unavailable if psql was built without readline."

    block "Two settings for the way you type" $ do
        p_ $ do
            c "COMP_KEYWORD_CASE"
            " decides the case of completed keywords. The default, "
            c "preserve-upper"
            ", means the completion follows whatever you already typed, and defaults to upper case \
            \when you have typed nothing:"
        sh
            [ "testdb=# ins<Tab>          ->  insert into"
            , "testdb=# INS<Tab>          ->  INSERT INTO"
            ]
        p_ $ do
            "Set it to "
            c "lower"
            " or "
            c "upper"
            " to force one regardless. If you write SQL in lower case and dislike being handed \
            \shouted keywords, "
            c "\\set COMP_KEYWORD_CASE lower"
            " is the line you want."
        p_ $ do
            "And "
            c "IGNOREEOF"
            ", also borrowed from bash: how many consecutive "
            k "C-d"
            " it takes to end an interactive session. The default is 0, meaning one is enough. Set \
            \it to 2 or 3 if you keep exiting psql by accident — and note that psql swallows the \
            \ignored ones "
            i_ "silently"
            ", with none of bash's “use exit to leave the shell”."

    block "Today's habit" $ do
        p_ $ do
            "Two lines into your psqlrc, and then use "
            k "C-r"
            " instead of holding down the up-arrow. Per-database history is one of those changes \
            \you do not notice until you sit at a machine without it."
        p_ "Tomorrow: what happens when a statement fails, which is where psql's defaults are least like what you would guess."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Readline in front, your editor behind."
        " Neither is configured by psql."
    cfg
        [ "C-r        -- reverse history search. The one to learn today."
        , "Tab        -- complete. Object names query the SERVER: a Tab has side effects."
        , "-n         -- no readline at all: no completion, no history, no multi-line edit"
        , "~/.inputrc:  $if psql / set disable-completion on / $endif"
        , "\\e [file] [line]   \\ef func [line]   \\ev view [line]   \\s [file]"
        , "  quit unchanged: editing the BUFFER keeps it; editing a FILE clears it"
        , "  line numbers count from the first line of the function BODY"
        , "$PSQL_EDITOR > $EDITOR > $VISUAL > vi     PSQL_EDITOR_LINENUMBER_ARG default '+'"
        , "\\set HISTFILE ~/.psql_history-:DBNAME   -- psqlrc ONLY; ignored at the prompt"
        , "\\set HISTSIZE 5000    \\set HISTCONTROL ignoredups|ignorespace|ignoreboth|none"
        , "\\set COMP_KEYWORD_CASE lower           \\set IGNOREEOF 2   -- C-d twice to leave"
        ]
