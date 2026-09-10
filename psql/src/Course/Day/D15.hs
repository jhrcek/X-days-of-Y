module Course.Day.D15 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 15
        , dayTitle = "Prompts worth reading"
        , daySubtitle = "The prompt is a projection of session state — keep the escapes that carry something you would act on."
        , dayMinutes = 30
        , dayLevel = "advanced"
        , dayManRef = "Prompting; Variables (PROMPT1, PROMPT2, PROMPT3)"
        , dayTags = ["PROMPT1", "%x", "colour"]
        , dayGoals =
            [ "write a prompt that tells you which server and database you are about to change"
            , "colour it without breaking line editing on long statements"
            , "align continuation lines by making the second prompt invisible"
            ]
        , dayDiagram = Just d15diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds = []
        , dayOpts =
            [ ("PROMPT1", "The prompt for a new statement. Default " <> c "'%/%R%x%# '" <> ".")
            , ("PROMPT2", "Shown while a statement is unfinished. Same default as " <> opt "PROMPT1" <> ".")
            , ("PROMPT3", "Shown during " <> c "COPY ... FROM STDIN" <> ". Default " <> c "'>> '" <> ".")
            , ("%R", c "=" <> " ready, " <> c "-" <> " unterminated, " <> c "'" <> " open string, " <> c "@" <> " inactive branch, " <> c "^" <> " single-line, " <> c "!" <> " disconnected.")
            , ("%x", "Transaction: empty, " <> c "*" <> " in a block, " <> c "!" <> " failed block, " <> c "?" <> " no connection.")
            , ("%#", c "#" <> " for a superuser, " <> c ">" <> " for everyone else.")
            , ("%/ %~", "The database name; " <> c "%~" <> " prints " <> c "~" <> " when it is your default database.")
            , ("%n %M %m %>", "Session user; full host; host to the first dot; port.")
            , ("%[ ... %]", "Wrap non-printing characters so readline can measure the prompt.")
            , ("%w", "Whitespace as wide as the last " <> opt "PROMPT1" <> " — an invisible second prompt.")
            ]
        , dayConfig =
            [ ConfBlock
                "Who and where, then what. The dim user@host:port is there so that no DELETE\never\
                \ goes to the wrong server unnoticed; the bold database name is what you\nglance\
                \ at; and %R%x%# keeps everything the default prompt was telling you —\nwhether\
                \ psql wants more input, whether a transaction is open or broken, and\nwhether you\
                \ are a superuser. Every escape sequence is wrapped in %[ ... %] so\nreadline can\
                \ still measure the line. PROMPT2 is %w: invisible, exactly as wide\nas PROMPT1, so\
                \ multi-line statements line up under themselves."
                "\\set PROMPT1 '%[%033[2m%]%n@%m:%>%[%033[0m%] %[%033[1m%]%/%[%033[0m%]%R%x%# '\n\\set PROMPT2 '%w'"
            ]
        , dayDrills =
            [ "Look at what you have: "
                <> c "\\echo :PROMPT1"
                <> ". It is "
                <> c "'%/%R%x%# '"
                <> " unless you have changed it."
            , "Add the server: "
                <> c "\\set PROMPT1 '%n@%m:%> %/%R%x%# '"
                <> ". Connect to two different databases and see the whole thing change."
            , "Watch "
                <> c "%x"
                <> " work: "
                <> c "BEGIN;"
                <> " gives you a "
                <> c "*"
                <> ", a failing statement makes it a "
                <> c "!"
                <> ", "
                <> c "ROLLBACK;"
                <> " clears it."
            , "Watch "
                <> c "%R"
                <> " work in the second prompt: start a statement and leave it unterminated, then \
                   \open a quote, then a parenthesis. Three different characters, three different \
                   \diagnoses."
            , "Break it on purpose: set a colour prompt "
                <> i_ "without"
                <> " the "
                <> c "%["
                <> " and "
                <> c "%]"
                <> " wrappers, then type a long statement and press "
                <> k "C-a"
                <> ". The cursor lands in the wrong place and the line redraws wrongly."
            , "Fix it by adding the wrappers and try again. This is the only reason "
                <> c "%[ ... %]"
                <> " exists, and now you have seen what it prevents."
            , "Set "
                <> c "\\set PROMPT2 '%w'"
                <> " and type a three-line query. The continuation lines align under the first, \
                   \with no second prompt at all."
            , "Put the two lines from the config box in your psqlrc, then live with them for a week \
              \before changing the colours. The information matters more than the palette."
            ]
        , dayQuiz =
            [
                ( "You add a colour prompt and line editing goes wrong: "
                    <> k "C-a"
                    <> " puts the cursor in the middle of a word, and long statements redraw over \
                       \themselves. Nothing is wrong with the colours. What is missing?"
                , do
                    p_ $ do
                        c "%["
                        " and "
                        c "%]"
                        " around the escape sequences. Readline has to know how wide the prompt is \
                        \in order to work out where the line it is editing begins, and it does that \
                        \by counting the characters it was given. An unwrapped "
                        c "\\033[1;32m"
                        " is seven invisible characters that readline counts as seven visible ones, \
                        \so its idea of the cursor column is permanently off by seven."
                    p_ $ do
                        "Wrapping them in "
                        c "%[ ... %]"
                        " marks them non-printing. Multiple pairs are allowed, which is what you \
                        \need for a prompt that colours two things differently. This is also why "
                        c "%w"
                        " works correctly with a colour prompt: psql knows which characters were \
                        \visible."
                )
            ,
                ( "Which escapes are worth keeping, and why is "
                    <> c "%x"
                    <> " the one to fight for?"
                , do
                    p_ $ do
                        "The three in the default — "
                        c "%R"
                        ", "
                        c "%x"
                        ", "
                        c "%#"
                        " — plus enough of "
                        c "%n"
                        ", "
                        c "%m"
                        ", "
                        c "%>"
                        " and "
                        c "%/"
                        " to identify where you are. Everything else is decoration: "
                        c "%p"
                        " (backend PID) and "
                        c "%l"
                        " (line number) are real information you will never act on at a prompt."
                    p_ $ do
                        c "%x"
                        " is the one people delete when they write their own prompt, and it is the \
                        \one that costs them. It is the "
                        i_ "only"
                        " continuous indication that a transaction is open, or that it has failed \
                        \and every statement since has been quietly refused. Day 8's "
                        c "COMMIT"
                        " that answers "
                        c "ROLLBACK"
                        " is entirely avoidable, and "
                        c "%x"
                        " is how."
                )
            ,
                ( "A colleague's prompt says "
                    <> c "~=>"
                    <> " and yours says "
                    <> c "postgres=#"
                    <> " on the same server. Two differences. What are they?"
                , do
                    p_ $ do
                        "They are using "
                        c "%~"
                        " rather than "
                        c "%/"
                        ", and it prints "
                        c "~"
                        " when the current database is your "
                        i_ "default"
                        " one — that is, the database whose name matches your user name. Connected \
                        \to anything else it prints the name, exactly like "
                        c "%/"
                        "."
                    p_ $ do
                        "And "
                        c "%#"
                        " is "
                        c ">"
                        " for them and "
                        c "#"
                        " for you, so you are connected as a superuser and they are not. Both \
                        \characters are worth a glance before anything destructive — and note that "
                        c "%#"
                        " tracks the "
                        i_ "session"
                        " user, so it can change under you after a "
                        c "SET SESSION AUTHORIZATION"
                        "."
                )
            ,
                ( "What is "
                    <> c "PROMPT3"
                    <> " for, and when did you last see it?"
                , do
                    p_ $ do
                        "It is the prompt psql shows while you are typing data rows into a "
                        c "COPY ... FROM STDIN"
                        ", and its default is "
                        c "'>> '"
                        ". You saw it on Day 9, when you loaded two rows inline and ended them with \
                        \a line containing "
                        c "\\."
                        "."
                    p_ $ do
                        "It is the only one of the three where "
                        c "%R"
                        " produces nothing at all, because there is no parse state to report — psql \
                        \is not reading a statement, it is reading data. Which is a reasonable \
                        \argument for leaving it alone: a distinctive "
                        c ">>"
                        " is exactly the reminder that what you type next is not SQL."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d15diagram :: Diagram
d15diagram =
    ( diagram
        "PROMPT1 is written with escape sequences, each standing for a piece of session state, \
        \and is expanded into the prompt you see, which readline must measure; a non-printing \
        \sequence wrapped in percent-bracket can appear in the prompt and is counted as \
        \zero-width by readline."
        body'
    )
        { dgCaption = do
            "A prompt is a "
            b_ "projection of session state"
            ", which is the test for every escape you consider keeping: does it carry something \
            \you would act on? The amber box is why colour is not free — readline measures the \
            \prompt to know where your line starts, so an escape sequence that is not wrapped in "
            c "%[ ... %]"
            " gets counted as visible characters and line editing goes wrong on exactly the long \
            \statements you most need to edit."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  p1     [label=\"PROMPT1\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  esc    [label=\"an escape sequence\\n%R %x %# %/ %n %m\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  state  [label=\"a piece of\\nsession state\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  prompt [label=\"the prompt you see\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  np     [label=\"a non-printing sequence\\n%[ ... %]\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  rl     [label=\"readline\", fillcolor=\"#f4efe6\"];\n\
        \\n\
        \  p1     -> esc    [label=\"  is written with\"];\n\
        \  esc    -> state  [label=\"  stands for\"];\n\
        \  p1     -> prompt [label=\"is expanded into  \"];\n\
        \  state  -> prompt [label=\"  shows through in\"];\n\
        \  prompt -> rl     [label=\"  must be measured by\"];\n\
        \  np     -> p1     [label=\"can appear in  \"];\n\
        \  np     -> rl     [label=\"  is counted as zero-width by\", style=dashed];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "The default prompt is already three sensors" $ do
        p_ [class_ "lede"] $ do
            "The default "
            opt "PROMPT1"
            " is "
            c "'%/%R%x%# '"
            ", and every one of those four escapes is carrying information you would act on. Before \
            \designing your own, it is worth knowing what you would be throwing away — because \
            \almost everybody who writes a custom psql prompt drops "
            c "%x"
            ", and "
            c "%x"
            " is the valuable one."
        p_ $ do
            "The prompt is a projection of session state. That is the test for every escape: does \
            \it tell you something that changes what you would type next?"
        defs
            [
                ( c "%R"
                , do
                    "the parse state. In "
                    opt "PROMPT1"
                    " it is "
                    c "="
                    " normally, "
                    c "@"
                    " in an inactive "
                    c "\\if"
                    " branch, "
                    c "^"
                    " in single-line mode, "
                    c "!"
                    " when disconnected. In "
                    opt "PROMPT2"
                    " it says why psql wants more: "
                    c "-"
                    ", "
                    c "'"
                    ", "
                    c "\""
                    ", "
                    c "$"
                    ", "
                    c "("
                    " or "
                    c "*"
                    "."
                )
            ,
                ( c "%x"
                , do
                    "the transaction state. Empty outside a block, "
                    c "*"
                    " inside one, "
                    c "!"
                    " once a statement in it has failed, "
                    c "?"
                    " when psql cannot tell."
                )
            ,
                ( c "%#"
                , do
                    c "#"
                    " if the session user is a superuser, "
                    c ">"
                    " otherwise. It tracks the "
                    i_ "session"
                    " user, so "
                    c "SET SESSION AUTHORIZATION"
                    " changes it."
                )
            ,
                ( c "%/"
                , do
                    "the current database. "
                    c "%~"
                    " is the same but prints "
                    c "~"
                    " when the database is your default one — the one named after your user."
                )
            ]
        why $ p_ $ do
            c "%x"
            " is the one to fight for. It is the only continuous indication that a transaction is \
            \open, or — worse — that it has failed and every statement you have run since has been \
            \refused. Day 8's "
            c "COMMIT"
            " that answers "
            c "ROLLBACK"
            " is a four-statement failure that "
            c "%x"
            " announces from the first one. A prompt without it is a prompt that lets you work for \
            \a minute inside a transaction that no longer exists."
        fig

    block "Where you are, which is the other half" $ do
        p_ $ do
            "The default prompt tells you the database and nothing about the server, which is fine \
            \until you have four terminals open. Four escapes fix that:"
        defs
            [ (c "%n", "the session user name")
            , (c "%M", "the full host name, or " <> c "[local]" <> " over a Unix socket")
            , (c "%m", "the host name truncated at the first dot — " <> c "127.0.0.1" <> " becomes " <> c "127")
            , (c "%>", "the port")
            ]
        sh
            [ "testdb=# \\set PROMPT1 'M=%M|m=%m|port=%> '"
            , "M=127.0.0.1|m=127|port=55432 "
            ]
        p_ $ do
            "So "
            c "%n@%m:%>"
            " is “who and where” in nine characters. There are three more of this kind and none of \
            \them is worth prompt space: "
            c "%s"
            " (the service name, empty unless you connected with "
            c "service="
            "), "
            c "%p"
            " (the backend PID — real information, but you will reach for "
            c "\\conninfo"
            " when you want it) and "
            c "%P"
            " (pipeline status, for tomorrow's lesson)."
        p_ $ do
            "Two escapes exist for building things rather than reading them. "
            c "%:name:"
            " inserts the value of a psql variable, and "
            c "%`command`"
            " inserts the output of a shell command — which is evaluated "
            b_ "every time the prompt is drawn"
            ", so it wants to be something very cheap or nothing at all. "
            c "%l"
            " is the line number inside the current statement, which is genuinely useful in "
            opt "PROMPT2"
            " for a long "
            c "INSERT"
            ", and "
            c "%%"
            " is a literal percent sign."

    block "Colour, and the one rule about it" $ do
        p_ $ do
            "Terminal control sequences go in the prompt like any other text, and every one of them \
            \must be wrapped in "
            c "%["
            " and "
            c "%]"
            ". The reason is readline: to edit a line it has to know where that line starts, and it \
            \works that out by counting the prompt's characters. An unwrapped "
            c "%033[1;32m"
            " is seven invisible characters that readline counts as seven visible ones, and its \
            \idea of the cursor column is then wrong by seven for the rest of the session."
        gotcha $ p_ $ do
            "The symptom is not “the colours are wrong”. It is that "
            k "C-a"
            " lands in the middle of a word, that long statements redraw over themselves, and that "
            k "C-r"
            " through the history leaves debris on the line — all on precisely the long statements \
            \you most need to edit. Multiple "
            c "%[ ... %]"
            " pairs are allowed, so a prompt that colours two things differently needs two pairs."
        p_ "The manual page's own example, and then a more useful one:"
        cfg
            [ "-- the manual page's: bold yellow on black"
            , "\\set PROMPT1 '%[%033[1;33;40m%]%n@%/%R%[%033[0m%]%# '"
            , ""
            , "-- who and where, dim; the database, bold; then the three state characters"
            , "\\set PROMPT1 '%[%033[2m%]%n@%m:%>%[%033[0m%] %[%033[1m%]%/%[%033[0m%]%R%x%# '"
            ]
        sh
            [ "postgres@127:55432 testdb=# BEGIN;"
            , "BEGIN"
            , "postgres@127:55432 testdb=*# SELECT nosuch;"
            , "ERROR:  column \"nosuch\" does not exist"
            , "postgres@127:55432 testdb=!# ROLLBACK;"
            ]
        tip $ p_ $ do
            "Resist making production red. It sounds like a good idea and it is a bad one: the \
            \colour depends on a hostname pattern you have to maintain, and it fails silently — \
            \the day the host is reachable under a second name, your dangerous server is the \
            \reassuring colour. Put the host "
            i_ "in"
            " the prompt instead and read it."

    block "An invisible second prompt" $ do
        p_ $ do
            opt "PROMPT2"
            " has the same default as "
            opt "PROMPT1"
            ", so a multi-line statement is shown against a prompt of a similar width but different \
            \content, and the SQL does not line up. "
            c "%w"
            " solves it exactly: whitespace as wide as the most recent "
            opt "PROMPT1"
            ", so there is no second prompt at all and the statement aligns under itself."
        sh
            [ "longprompt=> SELECT"
            , "             1;"
            ]
        p_ $ do
            "It measures the "
            i_ "visible"
            " width, which is the second reason to wrap your colour sequences properly — with "
            c "%[ ... %]"
            " in place, "
            c "%w"
            " lines up correctly under a coloured prompt."
        p_ $ do
            "What you lose is "
            c "%R"
            "'s diagnosis of "
            i_ "why"
            " psql wants more input, which was the most useful thing on Day 1. A reasonable \
            \compromise is "
            c "'%w'"
            " for alignment while you are learning nothing new, or "
            c "'%R %w'"
            " if you would rather keep the character and shift the text by two columns. Both are \
            \defensible; the default is not, because it looks like a prompt and tells you almost \
            \nothing."
        note $ p_ $ do
            opt "PROMPT3"
            " is shown while you type rows into a "
            c "COPY ... FROM STDIN"
            ", and its default is "
            c "'>> '"
            ". "
            c "%R"
            " produces nothing in it, because psql is reading data rather than parsing a statement. \
            \Leaving it as the distinctive "
            c ">>"
            " is the right call: it is the reminder that what you type next is not SQL."

    block "Today's habit" $ do
        p_ $ do
            "Put the two lines in your psqlrc and then leave the colours alone for a week. The \
            \point of the exercise is not the palette — it is that you can no longer run a "
            c "DELETE"
            " without the host, the database, the transaction state and your superuser status all \
            \being on the screen in front of you."
        p_ "Tomorrow: the protocol underneath all of this, and the seven commands that let you drive it by hand."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Every escape sequence must be wrapped in "
        c "%[ ... %]"
        b_ " or readline miscounts the line."
    cfg
        [ "\\set PROMPT1 '%[%033[2m%]%n@%m:%>%[%033[0m%] %[%033[1m%]%/%[%033[0m%]%R%x%# '"
        , "\\set PROMPT2 '%w'          -- invisible, exactly as wide as PROMPT1"
        , "default PROMPT1 and PROMPT2 are '%/%R%x%# ' ; PROMPT3 is '>> ' (COPY FROM STDIN)"
        , "-- state, and the reason to have a prompt at all:"
        , "%R  = ready | - unterminated | ' \" $ ( * open ... | @ inactive \\if | ^ -S | ! disconnected"
        , "%x  (empty) none | * in a transaction | ! FAILED transaction | ? no connection"
        , "%#  # superuser | > everyone else        <- glance before every DELETE"
        , "-- place:"
        , "%/ database   %~ database, or ~ if it is your default   %n user"
        , "%M full host  %m host to the first dot   %> port   %s service   %p backend PID"
        , "-- building blocks:  %:var:  %`cmd` (run EVERY redraw)  %l line no.  %P pipeline  %% literal"
        ]
