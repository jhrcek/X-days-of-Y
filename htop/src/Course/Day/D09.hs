module Course.Day.D09 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 9
        , dayTitle = "Setup and htoprc"
        , daySubtitle = "The five Setup categories, the file they write — and how to stop htop overwriting your work."
        , dayMinutes = 40
        , dayLevel = "intermediate"
        , dayManRef = "CONFIG FILES, INTERACTIVE COMMANDS"
        , dayTags = ["Setup", "htoprc", "$HTOPRC"]
        , dayGoals =
            [ "navigate all five Setup categories and know which one owns which decision"
            , "state the exact rule for when htop rewrites your config file, and name two defences"
            , "hand-write an htoprc that does what you meant, including the trap that silently ignores half of it"
            ]
        , dayDiagram = Just d9diagram
        , dayBody = body
        , dayKeys =
            [ ("F2 S C", "Open Setup. " <> k "C" <> " is an alias the manual page does not mention.")
            , ("F10", "Leave Setup. Labelled " <> c "Done" <> ".")
            , ("Space", "In Setup: toggle the highlighted option, or add the highlighted meter.")
            ]
        , dayCmds =
            [ ("HTOPRC=~/x htop", "Read (and write) a different config file. One config per machine, one shared home directory.")
            , ("chmod 444 ~/.config/htop/htoprc", "Make the file read-only. htop then runs normally and stops clobbering it.")
            ]
        , dayOpts =
            [ ("highlight_changes", "Highlight processes that are new or whose command line changed. Default off.")
            , ("highlight_changes_delay_secs", "How long that highlight lasts. Default " <> c "5" <> ".")
            , ("enable_mouse", "Let htop capture mouse events. Default on, which costs you terminal text selection.")
            , ("header_margin", "Leave a blank line around the header. Default on.")
            , ("screen_tabs", "Show the names of screen tabs above the list. Default on.")
            , ("fields", "The legacy numeric column list. Silently overrides every " <> c "screen:" <> " line.")
            ]
        , dayConfig =
            [ ConfBlock
                "Highlight processes that have just appeared, or whose command line has changed,\n\
                \for five seconds. Off by default, and the single most useful thing in the Setup\n\
                \screen: it turns 'something keeps restarting' from a hunch into something you can\n\
                \see. Costs nothing when nothing is changing."
                "highlight_changes=1\n\
                \highlight_changes_delay_secs=5"
            , ConfBlock
                "Give the terminal back its text selection. With the mouse enabled htop captures\n\
                \drag events, so selecting a PID to copy selects nothing and clicks a column header\n\
                \instead. Turn this off if you copy things out of htop more often than you click\n\
                \inside it; leave it on if the reverse is true."
                "enable_mouse=0"
            , ConfBlock
                "Reclaim the blank line above the meters. One line of a 24-line terminal is one more\n\
                \process visible, and the margin is decoration."
                "header_margin=0"
            , ConfBlock
                "A header that does not grow with the core count. The default puts one bar per CPU\n\
                \up there, which is four lines on a laptop and thirty-five on a build machine; the\n\
                \combined 'CPU' meter is one line on all of them. Left column as bars for shape at a\n\
                \glance, right column as text for numbers you can read off.\n\
                \Modes: 1 bar, 2 text, 3 graph, 4 LED."
                "header_layout=two_50_50\n\
                \column_meters_0=CPU Memory Swap\n\
                \column_meter_modes_0=1 1 1\n\
                \column_meters_1=Tasks LoadAverage Uptime Clock\n\
                \column_meter_modes_1=2 2 2 2"
            , ConfBlock
                "Show the tab bar naming each screen. Day 11 adds screens beyond the default two,\n\
                \and without this line there is nothing on screen to tell you which one you are\n\
                \looking at or that the others exist."
                "screen_tabs=1"
            ]
        , dayDrills =
            [ "Press "
                <> k "F2"
                <> " and walk all five categories with the arrow keys without changing anything. \
                   \Say out loud what each one owns. This is the map of every decision htop lets \
                   \you make."
            , "In Display options, find "
                <> c "Detailed CPU time"
                <> " and turn it on with "
                <> k "Space"
                <> ". Leave Setup with "
                <> k "F10"
                <> " and watch the CPU bar gain segments. You just did Day 8's lesson permanently."
            , "Quit htop cleanly with "
                <> k "q"
                <> ", then "
                <> c "cat ~/.config/htop/htoprc"
                <> ". Find the line your keystroke wrote. This file is the only thing Setup does."
            , "Break something on purpose: put "
                <> c "delay=notanumber"
                <> " and "
                <> c "this_key_is_invented=7"
                <> " into the file and start htop. No error, no warning, no clue. Now you know \
                   \what you are dealing with."
            , "The trap, demonstrated: add "
                <> c "screen:Main=PID USER NICE Command"
                <> " to a config that already has a "
                <> c "fields="
                <> " line, and start htop. Your column list is ignored. Delete the "
                <> c "fields="
                <> " line and try again."
            , "Write a comment into your htoprc explaining why you set something. Start htop, press "
                <> k "t"
                <> " once, quit with "
                <> k "q"
                <> ". Your comment is gone and the file is sixty lines long. That is the whole \
                   \lesson of the day, in three keystrokes."
            , "Now defend yourself: "
                <> c "chmod 444 ~/.config/htop/htoprc"
                <> " and do it again. htop runs normally, the toggle works for the session, and \
                   \your file is untouched."
            , "On your own machine: start the config file this course builds. Copy today's block \
              \into place, and from here on every day adds a few lines you can defend."
            ]
        , dayQuiz =
            [
                ( "You carefully hand-write an htoprc with comments explaining every line. A week \
                  \later the comments are gone and the file is unrecognisable. You never opened \
                  \Setup. What happened?"
                , do
                    p_ $ do
                        "You pressed a toggle — "
                        k "t"
                        " for tree view, "
                        k "K"
                        " for kernel threads, "
                        k "I"
                        " to invert a sort — and then quit cleanly. htop rewrites the whole file \
                        \whenever a session ends cleanly "
                        i_ "and something changed"
                        ", and ordinary main-screen toggles count as changes. The rewrite emits \
                        \htop's own canonical form: every setting, no comments."
                    p_ $ do
                        "The manual page says the file “is overwritten upon clean exit by htop's \
                        \in-program Setup configuration”, which reads as though only Setup \
                        \triggers it. In htop 3.5.3 the trigger is any changed setting, from \
                        \anywhere. The good news hidden in the same rule: if nothing changed, \
                        \nothing is rewritten — a config you only ever read survives untouched."
                )
            ,
                ( "You edit "
                    <> c "screen:Main="
                    <> " in your htoprc to add a column. htop ignores it completely. The syntax is \
                       \correct and the column name is valid. What else is in the file?"
                , do
                    p_ $ do
                        "A "
                        c "fields="
                        " line — the legacy numeric column list, which htop writes into every \
                        \config it generates and which silently takes precedence over "
                        c "screen:Main="
                        " regardless of which appears first. Your names are parsed and then thrown \
                        \away in favour of a list of integers."
                    p_ $ do
                        "Delete the "
                        c "fields="
                        " line and the "
                        c "screen:"
                        " line takes effect. Note that htop will write it back the next time it \
                        \rewrites the file, so this is one more reason for the read-only defence. \
                        \Nothing in the manual page mentions "
                        c "fields="
                        " at all."
                )
            ,
                ( "You set "
                    <> c "HTOPRC=~/.config/htop/server.htoprc"
                    <> " and the file does not exist yet. What does htop use?"
                , do
                    p_ $ do
                        "Its hard-coded defaults, and it does not create the file. In particular it \
                        \does "
                        i_ "not"
                        " fall back to "
                        c "~/.config/htop/htoprc"
                        " — setting "
                        c "$HTOPRC"
                        " replaces the search entirely rather than adding a candidate to it."
                    p_ $ do
                        "That is exactly what you want for the use case the manual page suggests: \
                        \one home directory shared across machines, a different "
                        c "$HTOPRC"
                        " per machine, and no accidental bleed between them. It is a surprise the \
                        \first time you assume a fallback and get a default-looking htop instead."
                )
            ,
                ( "Between "
                    <> c "chmod 444"
                    <> " and a per-machine "
                    <> c "$HTOPRC"
                    <> ", which should you use?"
                , do
                    p_ $ do
                        b_ "Read-only"
                        " when the file is the authority — you keep it in a dotfiles repository, you \
                        \want it identical everywhere, and you want htop to stop having opinions. \
                        \htop notices nothing: it runs normally, your toggles work for the session, \
                        \and the write at exit fails silently. You lose the ability to save changes \
                        \from Setup, which is the point."
                    p_ $ do
                        b_ "A separate $HTOPRC"
                        " when different machines genuinely want different configs — a laptop and a \
                        \64-core build box do not want the same header. Then let htop own each file \
                        \normally and configure through Setup, which is the workflow htop is \
                        \designed around."
                    p_ "Using both is reasonable: a read-only shared base on your workstations, and a writable per-machine file on servers you tune in place."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d9diagram :: Diagram
d9diagram =
    ( diagram
        "An htop session reads the htoprc file once at startup; the Setup screen edits settings \
        \in memory; and a clean exit after any change rewrites the whole file, destroying any \
        \comments it contained."
        body'
    )
        { dgCaption = do
            "htop treats this file as "
            i_ "its"
            " storage, not as your configuration — Setup is an editor for it, and a clean exit is \
            \the save. Two aspects are worth reading carefully. The session "
            b_ "reads once, at startup"
            ", so there is no reload and editing the file under a running htop achieves nothing. \
            \And the dashed aspect is the whole reason this day exists: the rewrite is a full \
            \regeneration in htop's own canonical form, so every comment you wrote is gone."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  sess  [label=\"an htop session\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  file  [label=\"the htoprc file\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  setup [label=\"the Setup screen\"];\n\
        \  set   [label=\"a setting\"];\n\
        \  exit  [label=\"a clean exit after\\nsomething changed\"];\n\
        \  cmt   [label=\"a comment you wrote\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  sess  -> file  [label=\"  reads once, at startup\"];\n\
        \  sess  -> setup [label=\"  contains\"];\n\
        \  setup -> set   [label=\"  edits\"];\n\
        \  file  -> set   [label=\"  stores\"];\n\
        \  exit  -> file  [label=\"  rewrites in full\"];\n\
        \  cmt   -> file  [label=\"  lives in\"];\n\
        \  exit  -> cmt   [label=\"destroys  \", style=dashed, constraint=false];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Setup is an editor for one file" $ do
        p_ [class_ "lede"] $ do
            "Everything you have toggled for eight days lives in a single file, and the Setup \
            \screen is nothing but an editor for it. Understanding that one sentence makes both \
            \halves easier — and explains why htop will cheerfully overwrite anything you write \
            \there by hand."
        p_ $ do
            k "F2"
            " opens it, and so do "
            k "S"
            " and "
            k "C"
            " — the last of which appears in htop's help screen and nowhere in the manual page. "
            k "F10"
            " leaves. The left-hand pane lists five categories, and the division between them is \
            \worth memorising because it is the map of every decision htop offers you."
        fig

    block "The five categories" $ do
        defs
            [
                ( "Display options"
                , do
                    "About thirty toggles, split into per-screen and global. This is where "
                    opt "detailed_cpu_time"
                    " lives, along with kernel and userland thread hiding, program paths, merged \
                    \commands, the tree-stability modes from Day 5, CPU temperature and frequency, \
                    \SMT labelling, and the mouse."
                )
            ,
                ( "Header layout"
                , "Fourteen presets from one full-width column to four equal ones, including asymmetric splits like 33/67 and 40/20/40."
                )
            ,
                ( "Meters"
                , do
                    "The header, built by hand: a pane per column, plus the “Available meters” \
                    \list from Day 8. "
                    k "Space"
                    " adds, and cycling a meter changes its bar/text/graph/LED mode."
                )
            ,
                ( "Screens"
                , do
                    "The named tabs — "
                    c "Main"
                    " and "
                    c "I/O"
                    " by default — each with its own Active Columns list chosen from Available \
                    \Columns. All of Day 10 and Day 11 happen in this pane."
                )
            ,
                ( "Colors"
                , do
                    "Eight schemes: "
                    c "Default"
                    ", "
                    c "Monochromatic"
                    ", "
                    c "Black on White"
                    ", "
                    c "Light Terminal"
                    ", "
                    c "MC"
                    ", "
                    c "Black Night"
                    ", "
                    c "Broken Gray"
                    " and "
                    c "Nord"
                    "."
                )
            ]
        termWin
            "htop — F2"
            [ "Categories       Display options"
            , "Display options  For current screen tab: Main"
            , "Header layout    [ ]    Tree view"
            , "Meters           [0]    - Tree view is kept visually stable (0 - off, 1 - soft, 2 - hard)"
            , "Screens          Global options:"
            , "Colors           [x]    Show tabs for screens"
            , "                 [x]    Hide kernel threads"
            , "                 [ ]    Detailed CPU time (System/IO-Wait/Hard-IRQ/Soft-IRQ/Steal/Guest)"
            , "                 [x]    Enable the mouse"
            , "F1      F2      F3      F4      F5      F6      F7      F8      F9      F10Done"
            ]
        note $ p_ $ do
            "None of this is in the manual page — not the categories, not the option names, not \
            \the meter list, not the colour schemes. The "
            c "CONFIG FILES"
            " section describes where the file lives and then tells you not to edit it. For the \
            \Setup screen itself, the binary is the only documentation there is."

    block "The file, and when htop rewrites it" $ do
        p_ $ do
            "The file is "
            c "~/.config/htop/htoprc"
            ". If there is no user file, htop reads "
            c "/etc/htoprc"
            "; if that is absent too, it uses hard-coded defaults. "
            c "$HTOPRC"
            " overrides the path entirely."
        p_ "It opens with a warning that is more accurate than the manual page:"
        cfg
            [ "# Beware! This file is rewritten by htop when settings are changed in the interface."
            , "# The parser is also very primitive, and not human-friendly."
            ]
        p_ "The precise rule, which is worth knowing exactly because two of the three clauses are surprising:"
        steps
            [ do
                "htop rewrites the file on a "
                b_ "clean exit"
                " — "
                k "q"
                " or "
                k "F10"
                ". Exit by signal, by closing the terminal, by "
                k "Ctrl-C"
                ", and nothing is written."
            , do
                "…but only if "
                b_ "some setting actually changed"
                " during that session. A session in which you only looked at things leaves the file \
                \exactly as it was, comments and all."
            , do
                "…and “setting” means "
                b_ "any"
                " setting, not just ones you changed in Setup. Pressing "
                k "t"
                ", "
                k "K"
                " or "
                k "I"
                " on the main screen is enough to trigger a full rewrite."
            ]
        gotcha $ p_ $ do
            "The rewrite is a full regeneration in htop's canonical form: roughly sixty lines, in \
            \htop's order, with every comment removed. A carefully annotated config survives \
            \exactly as long as it takes you to press one toggle key and quit properly. This is why \
            \the file this course builds carries its reasoning in comments "
            i_ "and"
            " tells you to keep it under version control."

    block "Two defences" $ do
        p_ "If you want the file to be yours rather than htop's, pick one."
        defs
            [
                ( c "chmod 444"
                , do
                    "Make it read-only. htop starts normally, reads it, lets you toggle things for \
                    \the session, and the write at exit fails — "
                    b_ "silently, with no error and no warning"
                    ". Your file is intact. You have traded the ability to save from Setup for the \
                    \ability to keep comments, which is the right trade once a config is settled."
                )
            ,
                ( c "$HTOPRC"
                , do
                    "Point htop at a different file per machine, which is the use the manual page \
                    \suggests for shared home directories. Note that if the file named by "
                    c "$HTOPRC"
                    " does not exist, htop uses its built-in defaults and creates nothing — it does "
                    i_ "not"
                    " fall back to "
                    c "~/.config/htop/htoprc"
                    "."
                )
            ]
        sh
            [ "$ chmod 444 ~/.config/htop/htoprc          # the file is now yours"
            , "$ HTOPRC=~/.config/htop/buildbox htop      # a separate config for one machine"
            ]

    block "Writing it by hand, and the trap" $ do
        p_ $ do
            "The format is one "
            c "key=value"
            " per line, with per-screen settings written as "
            c "."
            "-prefixed lines immediately following their "
            c "screen:"
            " line. Comments start with "
            c "#"
            " and are preserved right up until the next rewrite."
        p_ $ do
            "“Very primitive” in that banner means the parser reports nothing, ever. An invented \
            \key is ignored. An unknown column name is dropped from the list. A meter that does not \
            \exist renders as nothing. "
            c "delay=notanumber"
            " is accepted. There is no syntax check and no startup warning — if a hand-written \
            \config does not do what you meant, the only feedback is the screen."
        gotcha $ p_ $ do
            "The specific trap that wastes an afternoon: every htop-written config contains "
            b_ "both"
            " a legacy "
            c "fields="
            " line (numeric column ids) "
            b_ "and"
            " a "
            c "screen:Main="
            " line (column names), and "
            c "fields="
            " wins — regardless of which comes first in the file. Edit "
            c "screen:Main="
            " to add a column and absolutely nothing happens. Delete the "
            c "fields="
            " line and it works. Neither line is documented anywhere."
        sh
            [ "fields=0 48 46 1                            # PID USER PERCENT_CPU Command -- this wins"
            , "screen:Main=PID USER NICE Command           # ...and this is silently ignored"
            ]

    block "Today's habit" $ do
        p_ $ do
            "Start the file. Everything below is a line you now have a reason for, and every day \
            \from here adds a few more — by Day 14 you will have a config you can defend line by \
            \line, which is a different thing entirely from a config you copied."
        p_ $ do
            "Put it somewhere you back up. htop will overwrite it the first time you press a \
            \toggle and quit, and the only real protection against that is a copy somewhere else \
            \— plus "
            c "chmod 444"
            " once you are happy with it."
        p_ "Tomorrow: the seventy-column catalogue, and how to choose from it."

cheat :: Html ()
cheat = do
    cfg
        [ "F2  S  C     open Setup      F10  leave it      Space  toggle / add"
        , ""
        , "categories:  Display options | Header layout | Meters | Screens | Colors"
        , ""
        , "file:        ~/.config/htop/htoprc"
        , "  then:      /etc/htoprc, then hard-coded defaults"
        , "  $HTOPRC    replaces the search outright -- NO fallback if the file is missing"
        , ""
        , "REWRITE RULE: clean exit  AND  some setting changed  ->  whole file regenerated,"
        , "              every comment lost.  't', 'K' and 'I' count as changes."
        , "              Nothing changed -> file untouched.   Killed by a signal -> untouched."
        , ""
        , "chmod 444 ~/.config/htop/htoprc     # htop stops clobbering it, silently"
        , "HTOPRC=~/.config/htop/box2 htop     # one config per machine"
        , ""
        , "TRAP: 'fields=' (numeric, legacy) beats 'screen:Main=' (names), whatever the order."
        , "      Delete the fields= line or your column edits do nothing."
        ]
    p_ $ do
        "The parser never reports an error: unknown keys, unknown column names, unknown meters and "
        c "delay=notanumber"
        " are all accepted in silence. The only feedback a hand-written config gives you is what \
        \appears on screen."
