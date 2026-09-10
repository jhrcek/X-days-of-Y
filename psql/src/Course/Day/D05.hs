module Course.Day.D05 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 5
        , dayTitle = "Readable output"
        , daySubtitle = "Twenty-two printing options, the three that change your life, and which ones your format ignores."
        , dayMinutes = 30
        , dayLevel = "essential"
        , dayManRef = "Meta-Commands (\\pset, \\x), EXAMPLES"
        , dayTags = ["\\pset", "expanded", "null"]
        , dayGoals =
            [ "stop confusing NULL with an empty string in every result you read from now on"
            , "choose between aligned, wrapped and expanded output on purpose rather than by accident"
            , "predict which printing options a given format will silently ignore"
            ]
        , dayDiagram = Just d5diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("\\pset", "With no argument, print all 22 printing options and their current values.")
            , ("\\x", "Toggle expanded mode. " <> c "\\x auto" <> " is the setting worth keeping.")
            , ("\\a \\t \\f \\C \\H", "Shortcuts kept for compatibility: format, tuples_only, fieldsep, title, HTML.")
            ]
        , dayOpts =
            [ ("format", c "aligned" <> " (default), " <> c "wrapped" <> ", " <> c "unaligned" <> ", " <> c "csv" <> ", " <> c "html" <> ", " <> c "asciidoc" <> ", " <> c "latex" <> ", " <> c "troff-ms" <> ".")
            , ("expanded", c "on" <> " / " <> c "off" <> " (default) / " <> c "auto" <> " — vertical records, always or only when too wide.")
            , ("null", "What to print for NULL. Default is nothing, which reads exactly like an empty string.")
            , ("border", c "0" <> " none, " <> c "1" <> " dividing lines (default), " <> c "2" <> " a full frame.")
            , ("linestyle", c "ascii" <> " (default) or " <> c "unicode" <> ". Aligned and wrapped only.")
            , ("footer", "The " <> c "(n rows)" <> " line. " <> c "off" <> " removes it.")
            , ("columns", "Target width for " <> c "wrapped" <> ", and the threshold for " <> c "expanded auto" <> ". 0 means use " <> c "$COLUMNS" <> ".")
            , ("pager", c "off" <> " / " <> c "on" <> " (default, meaning “only when it does not fit”) / " <> c "always" <> ".")
            , ("xheader_width", c "full" <> " (default) / " <> c "column" <> " / " <> c "page" <> " / an integer — how long the record rule may be.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Run "
                <> c "\\pset"
                <> " with no arguments and read all 22 lines once. You are not memorising them; \
                   \you are learning that this is where the answer is."
            , "Query a table with a NULL in it. The NULL and an empty string look identical. Now "
                <> c "\\pset null '(null)'"
                <> " and look again. You will not go back."
            , "Take a table with more than five columns and one row. Look at it, then "
                <> c "\\x"
                <> " and look again. Then "
                <> c "\\x auto"
                <> " and run both a wide query and a two-column one — auto is the answer to “I \
                   \want expanded, but not always”."
            , c "\\pset linestyle unicode"
                <> " and "
                <> c "\\pset border 2"
                <> ". Screenshot the result. This is the psql you want in a screen share."
            , "Break it on purpose: "
                <> c "\\pset format csv"
                <> ", then "
                <> c "\\pset linestyle unicode"
                <> ". psql cheerfully says “Line style is unicode” and the CSV is unaffected. \
                   \Options are format-specific and nobody warns you."
            , "Try "
                <> c "\\pset format wrapped"
                <> " with a long text column and a narrow terminal. Find the "
                <> c "."
                <> " continuation markers in the margins — that is how you tell wrapping from \
                   \genuinely short data."
            , "Insert a value containing a newline and query it in aligned mode. The "
                <> c "+"
                <> " in the right margin means “this row continues”, and it is the difference \
                   \between one weird row and two normal ones."
            , "Pick the two "
                <> c "\\pset"
                <> " lines you would miss most and remember them. Tomorrow you write them into a \
                   \file and never type them again."
            ]
        , dayQuiz =
            [
                ( "A report shows an empty cell. Is that a NULL, an empty string, or a string of \
                  \spaces? How do you find out in one command?"
                , do
                    p_ $ do
                        "You cannot tell, and that is the default. psql prints nothing for NULL, so \
                        \NULL, "
                        c "''"
                        " and "
                        c "'   '"
                        " all render as blank space inside a padded column."
                    p_ $ do
                        c "\\pset null '(null)'"
                        " — or anything else distinctive — separates the first from the other two \
                        \permanently. The manual page's own suggestion is "
                        c "'(null)'"
                        ", and it is the single highest-value line you will put in "
                        c "~/.psqlrc"
                        " tomorrow. To separate an empty string from spaces you still need "
                        c "length()"
                        " or "
                        c "quote_literal()"
                        "."
                )
            ,
                ( "You set "
                    <> c "\\pset expanded auto"
                    <> " and then switch to "
                    <> c "\\pset format csv"
                    <> ". Wide rows stop going vertical. Bug?"
                , do
                    p_ $ do
                        "No — documented. "
                        c "expanded auto"
                        " is only effective in the "
                        c "aligned"
                        " and "
                        c "wrapped"
                        " formats; in every other format it behaves as if expanded were off. Which \
                        \is sensible, since a vertical CSV would not be CSV."
                    p_ $ do
                        "The general rule is that printing options belong to formats, and psql \
                        \accepts them regardless. "
                        c "linestyle"
                        " means nothing outside aligned and wrapped, "
                        c "fieldsep"
                        " means nothing outside unaligned, "
                        c "csv_fieldsep"
                        " means nothing outside CSV, and "
                        c "tableattr"
                        " means nothing outside HTML and latex-longtable. You get a cheerful \
                        \confirmation message either way."
                )
            ,
                ( "What is the difference between "
                    <> c "aligned"
                    <> " and "
                    <> c "wrapped"
                    <> ", and when does "
                    <> c "wrapped"
                    <> " behave exactly like "
                    <> c "aligned"
                    <> "?"
                , do
                    p_ $ do
                        c "wrapped"
                        " is aligned plus a target width: values too long for the column are broken \
                        \across lines, with a "
                        c "."
                        " in the right margin of the first line and again in the left margin of the \
                        \next. The target comes from "
                        c "\\pset columns"
                        ", or from "
                        c "$COLUMNS"
                        "/the detected screen width when "
                        c "columns"
                        " is 0."
                    p_ $ do
                        "It gives up when the "
                        b_ "column headers"
                        " alone exceed the target, because psql will not wrap a header — so a \
                        \fifteen-column query in a narrow terminal comes out exactly as it would in \
                        \aligned. There is one more consequence of "
                        c "columns"
                        ": at 0, wrapping applies to screen output only; set it to a number and \
                        \file and pipe output are wrapped too, which is rarely what you want."
                )
            ,
                ( "In an expanded result, the "
                    <> c "-[ RECORD 1 ]-----"
                    <> " rule runs the full width of your widest value — hundreds of characters for \
                       \one long text column. How do you shorten it without losing the value?"
                , do
                    p_ $ do
                        c "\\pset xheader_width column"
                        " truncates the rule to the width of the first column; "
                        c "page"
                        " truncates it to the terminal width; an integer sets it exactly. The \
                        \default is "
                        c "full"
                        ", which is what produces the hundred-dash line."
                    p_ $ do
                        "The values are untouched — only the "
                        i_ "header rule"
                        " between records is shortened. It is a small option and it makes expanded \
                        \mode usable for rows containing one long JSON or SQL column, which is \
                        \exactly when you reach for expanded mode."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d5diagram :: Diagram
d5diagram =
    ( diagram
        "A result set is rendered by an output format into the text psql prints, which goes to \
        \your terminal possibly by way of the pager; general printing options affect that text, \
        \while format-specific options belong to one output format."
        body'
    )
        { dgCaption = do
            "The distinction worth carrying away is the amber one. "
            b_ "Format-specific options belong to a format"
            ", and setting one while another format is active is accepted, confirmed and then \
            \ignored: "
            c "linestyle"
            " is for aligned and wrapped, "
            c "fieldsep"
            " for unaligned, "
            c "csv_fieldsep"
            " for CSV, "
            c "tableattr"
            " for HTML. Nothing warns you, so the habit is to set the format first and its options \
            \second."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  res  [label=\"a result set\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  fmt  [label=\"an output format\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  txt  [label=\"the text psql prints\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  gen  [label=\"a general option\\n(null, footer, border)\"];\n\
        \  spec [label=\"a format-specific option\\n(linestyle, fieldsep, csv_fieldsep)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  pgr  [label=\"the pager\"];\n\
        \  term [label=\"your terminal\", fillcolor=\"#f4efe6\"];\n\
        \\n\
        \  res  -> fmt  [label=\"  is rendered by\"];\n\
        \  fmt  -> txt  [label=\"  produces\"];\n\
        \  gen  -> txt  [label=\"  affects\"];\n\
        \  spec -> fmt  [label=\"belongs to  \"];\n\
        \  txt  -> term [label=\"  is written to\"];\n\
        \  txt  -> pgr  [label=\"may first be piped to  \", style=dashed];\n\
        \  pgr  -> term [label=\"writes to  \"];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "The default output is lying to you about NULL" $ do
        p_ [class_ "lede"] $ do
            "psql prints nothing at all for a NULL. In a padded, aligned column that is \
            \indistinguishable from an empty string — so the default rendering of a result set \
            \destroys a distinction the database went to some trouble to keep. This is the first \
            \thing to change, and it takes one line."
        sh
            [ "testdb=# SELECT customer, total FROM app.orders ORDER BY id;"
            , " customer | total "
            , "----------+-------"
            , " acme     | 10.50"
            , " globex   | 99.99"
            , "          |  0.00"
            , "(3 rows)"
            , ""
            , "testdb=# \\pset null '(null)'"
            , "Null display is \"(null)\"."
            , "testdb=# SELECT customer, total FROM app.orders ORDER BY id;"
            , " customer | total "
            , "----------+-------"
            , " acme     | 10.50"
            , " globex   | 99.99"
            , " (null)   |  0.00"
            , "(3 rows)"
            ]
        why $ p_ $ do
            "Why is the default not already this? Because psql's aligned output is also its \
            \machine-readable output for anyone piping "
            c "-A -t"
            " into a script, and a default null string would end up in their data. The manual page \
            \notes the problem — “the default is to print nothing, which can easily be mistaken for \
            \an empty string” — and then leaves the choice to you, which is the right call for a \
            \tool whose output is somebody's input."
        fig

    block "Three formats you will actually use" $ do
        p_ $ do
            c "\\pset format"
            " takes nine values and unique abbreviations, so "
            c "\\pset format u"
            " is enough for unaligned. Four of the nine are markup for documents — "
            c "html"
            ", "
            c "asciidoc"
            ", "
            c "latex"
            ", "
            c "troff-ms"
            " — and produce fragments rather than whole documents. Ignore them until the day you \
            \need one. The ones that matter:"
        defs
            [
                ( c "aligned"
                , "the default: padded columns, a header, a row count. For reading."
                )
            ,
                ( c "wrapped"
                , do
                    "aligned, but long values are broken to fit a target width. For reading data \
                    \with one chatty column."
                )
            ,
                ( c "unaligned"
                , do
                    "one row per line, columns joined by "
                    c "fieldsep"
                    " (default "
                    c "|"
                    "). For piping into other programs — though "
                    c "csv"
                    " is safer, because unaligned does nothing special when the separator appears \
                    \inside a value."
                )
            ]
        p_ $ do
            "Wrapping is visible once you know the marks. A "
            c "."
            " in the right margin means “this value continues”, and a matching "
            c "."
            " appears in the left margin of the continuation line:"
        sh
            [ "testdb=# \\pset format wrapped"
            , "testdb=# \\pset columns 40"
            , "testdb=# SELECT 'a'||repeat(' word',12) AS text_col, 1 AS n;"
            , "              text_col              | n "
            , "------------------------------------+---"
            , " a word word word word word word wo.| 1"
            , ".rd word word word word word        | "
            , "(1 row)"
            ]
        note $ p_ $ do
            "A related mark, and one people misread constantly: a "
            c "+"
            " in the right margin means the "
            i_ "value itself"
            " contains a newline. That is data, not wrapping. With "
            c "linestyle unicode"
            " you get a carriage-return symbol instead, and with "
            c "old-ascii"
            " a colon in the left-hand separator — which is the only reason to know "
            c "old-ascii"
            " exists."

    block "Expanded mode, and the setting that makes it bearable" $ do
        p_ $ do
            "A row with twelve columns does not fit on a screen, and no amount of wrapping helps. "
            c "\\x"
            " turns the table on its side: one record at a time, column names down the left."
        sh
            [ "testdb=# \\x"
            , "Expanded display is on."
            , "testdb=# SELECT * FROM app.orders WHERE id = 1;"
            , "-[ RECORD 1 ]---------------------------"
            , "id       | 1"
            , "customer | acme"
            , "total    | 10.50"
            , "placed   | 2026-09-10 10:47:47.716038+00"
            ]
        p_ $ do
            "The useful setting is neither on nor off but "
            c "auto"
            ": go vertical only when the result has more than one column "
            i_ "and"
            " is wider than the screen. Narrow results stay as tables, wide ones stop wrapping into \
            \soup, and you never toggle anything again. It works only in "
            c "aligned"
            " and "
            c "wrapped"
            "; elsewhere it behaves as off."
        p_ $ do
            "Two smaller things belong here. Most describe commands accept an "
            c "x"
            " suffix — "
            c "\\dt+x"
            ", "
            c "\\df+x"
            " — which is expanded mode for one listing, and the reason for yesterday's odd \
            \placement rule. And "
            c "\\gx"
            " sends the current buffer with expanded mode forced for that one query, which is what \
            \you want when a single row surprises you."
        tip $ p_ $ do
            "In expanded mode the "
            c "-[ RECORD 1 ]-----"
            " rule stretches to your widest value, which for one long JSON column is a screenful of \
            \dashes. "
            c "\\pset xheader_width column"
            " cuts the rule to the width of the first column and leaves the values alone."

    block "Borders, lines, and the pager" $ do
        p_ $ do
            c "border"
            " is a number: 0 for no lines, 1 for internal dividers (the default), 2 for a full \
            \frame. "
            c "linestyle"
            " chooses the characters — "
            c "ascii"
            " or "
            c "unicode"
            " box-drawing — and applies only to aligned and wrapped. Together they are the whole of \
            \“make this look good in a screen share”:"
        sh
            [ "testdb=# \\pset linestyle unicode"
            , "testdb=# \\pset border 2"
            , "testdb=# SELECT * FROM my_table LIMIT 2;"
            , "┌───────┬────────┐"
            , "│ first │ second │"
            , "├───────┼────────┤"
            , "│     1 │ one    │"
            , "│     2 │ two    │"
            , "└───────┴────────┘"
            , "(2 rows)"
            ]
        p_ $ do
            "Three further options pick single or double lines for the frame, the column dividers \
            \and the header rule independently ("
            c "unicode_border_linestyle"
            ", "
            c "unicode_column_linestyle"
            ", "
            c "unicode_header_linestyle"
            "). They are pure decoration, and they are the fastest way to make a slide look like \
            \you know what you are doing."
        p_ $ do
            "The pager deserves a mention because it is the option people disable in irritation and \
            \then miss. "
            c "on"
            " — the default — means “page only when the output does not fit”; "
            c "always"
            " pages everything; "
            c "off"
            " never does. "
            c "pager_min_lines"
            " adds a floor, so short-but-too-wide results stop opening a pager for four rows. \
            \psql uses "
            c "$PSQL_PAGER"
            " or "
            c "$PAGER"
            ", and there is a separate "
            c "$PSQL_WATCH_PAGER"
            " for Day 13's "
            c "\\watch"
            "."
        gotcha $ p_ $ do
            "The value shown for "
            c "pager"
            " by bare "
            c "\\pset"
            " is "
            c "1"
            ", not "
            c "on"
            " — the three settings are stored as 0, 1 and 2 while the manual page and the "
            c "\\pset"
            " command both talk in words. Harmless, but it looks like a different option \
            \altogether when you are scanning the list for something else."

    block "Today's habit" $ do
        p_ $ do
            "Set "
            c "\\pset null '(null)'"
            " and "
            c "\\x auto"
            " right now, in the session you have open. Live with them for a day. Tomorrow you learn \
            \where to put them so that you never type them again — and that is the day psql starts \
            \feeling like your tool rather than the one that ships with the server."
        p_ $ do
            "One more thing to notice: everything today was a "
            i_ "session"
            " setting, lost when you quit. That is the problem "
            c "~/.psqlrc"
            " exists to solve."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Set the format first, its options second."
        " A misplaced option is accepted and ignored."
    cfg
        [ "\\pset                       -- show all 22 options and their values"
        , "\\pset null '(null)'          -- stop confusing NULL with ''      <- do this one"
        , "\\pset expanded auto         -- vertical only when too wide      <- and this one"
        , "\\x  \\gx                     -- toggle expanded / force it for one query"
        , "\\pset format aligned|wrapped|unaligned|csv|html|asciidoc|latex|troff-ms  (u = unaligned)"
        , "\\pset border 0|1|2          \\pset linestyle ascii|unicode   -- aligned & wrapped only"
        , "\\pset columns 100           -- wrapped target width; also the expanded-auto threshold"
        , "\\pset footer off            -- lose the (n rows) line"
        , "\\pset xheader_width column  -- shorten the -[ RECORD n ]- rule"
        , "\\pset pager off|on|always   -- bare \\pset reports these as 0|1|2"
        , "-- margins: . = value wrapped here     + = the value contains a newline"
        ]
