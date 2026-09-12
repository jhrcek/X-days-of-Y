module Course.Day.D11 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 11
        , dayTitle = "Screens as tabs"
        , daySubtitle = "One column set per question, instead of one compromise for all of them."
        , dayMinutes = 30
        , dayLevel = "advanced"
        , dayManRef = "INTERACTIVE COMMANDS, CONFIG FILES"
        , dayTags = ["screens", "tabs", "htoprc"]
        , dayGoals =
            [ "move between screens and know which one you are on without looking at the columns"
            , "build a purpose-made screen for a question you actually have"
            , "write a screen directly into htoprc, per-screen sort and all"
            ]
        , dayDiagram = Just d11diagram
        , dayBody = body
        , dayKeys =
            [ ("Tab", "Move to the next screen. " <> k "Shift-Tab" <> " goes back.")
            ]
        , dayCmds = []
        , dayOpts =
            [ ("screen:NAME", "Define a screen and its columns, in order, space-separated.")
            , (".sort_key", "The sort column for the screen defined immediately above.")
            , (".sort_direction", c "-1" <> " for descending, " <> c "1" <> " for ascending.")
            , (".tree_view", "Whether this screen starts in tree view. Per-screen, like everything dotted.")
            ]
        , dayConfig =
            [ ConfBlock
                "A screen for 'what is eating the memory on this box'. PSS is the sort key because\n\
                \it is the only column from Day 3 that can be added up, and having RES, SHR, PRIV\n\
                \and PSS side by side is what makes the double-counting visible rather than\n\
                \theoretical. No CPU columns at all -- this screen answers one question."
                "screen:Memory=PID USER M_RESIDENT M_SHARE M_PRIV M_PSS M_SWAP PERCENT_MEM Command\n\
                \.sort_key=M_PSS\n\
                \.sort_direction=-1"
            ]
        , dayDrills =
            [ "Press "
                <> k "Tab"
                <> ". You have had a second screen called "
                <> c "I/O"
                <> " since the day you installed htop, and this is probably the first time you have \
                   \seen it."
            , "Press "
                <> k "Tab"
                <> " until you are back on "
                <> c "Main"
                <> ". Notice the tab bar at the top of the list showing "
                <> c "[Main] [I/O]"
                <> ", and that the current one is highlighted."
            , "Sort the "
                <> c "I/O"
                <> " screen by something, then "
                <> k "Tab"
                <> " to "
                <> c "Main"
                <> " and back. Your sort is still there — every screen keeps its own sort column, \
                   \direction and tree state."
            , "In Setup → Screens, add a new screen. Name it "
                <> c "Memory"
                <> " and give it the columns from today's config block. Leave Setup and press "
                <> k "Tab"
                <> " twice."
            , "Break something on purpose: create a screen and put "
                <> c "Command"
                <> " in the middle of the column list. Watch every command line get truncated. Move \
                   \it back to last."
            , "Quit cleanly and look at the "
                <> c "screen:"
                <> " lines htop wrote for you. Compare them with today's config block — this is the \
                   \format you are about to write by hand."
            , "Write a screen directly into your "
                <> c "htoprc"
                <> " instead of building it in Setup. Faster, version-controllable, and the only \
                   \way to keep a comment explaining why it exists."
            , "On your own machine: build the one screen that matches your actual job — a database \
              \screen, a container screen, a screen for whatever you are on call for. The point of \
              \tabs is that you no longer have to compromise."
            ]
        , dayQuiz =
            [
                ( "You add a "
                    <> c "screen:Memory="
                    <> " line to your htoprc, restart htop, and no new tab appears. The syntax is \
                       \right. What are the two likely causes?"
                , do
                    p_ $ do
                        "First, "
                        opt "screen_tabs"
                        " may be off, in which case the screen exists and "
                        k "Tab"
                        " reaches it, but nothing is drawn to tell you so. That is Day 9's config \
                        \line, and it is the reason most people never discover the "
                        c "I/O"
                        " screen they have always had."
                    p_ $ do
                        "Second — and this is the one that wastes the afternoon — a "
                        c "fields="
                        " line elsewhere in the file. It overrides the column list for "
                        c "Main"
                        " and, being a leftover from an older config format, tends to indicate a \
                        \file htop has rewritten since you last edited it. Delete it."
                )
            ,
                ( "What exactly does a screen remember, beyond its columns?"
                , do
                    p_ $ do
                        "Its sort column and direction, its tree view state, its tree sort column \
                        \and direction, whether all branches start collapsed, and its tree \
                        \stability mode — each written as a "
                        c "."
                        "-prefixed line immediately after the "
                        c "screen:"
                        " line it belongs to."
                    p_ $ do
                        "That is more than it sounds. It means a "
                        c "Processes"
                        " screen can permanently be a PID-sorted tree while your "
                        c "Memory"
                        " screen is permanently a flat list sorted by PSS, and switching between \
                        \them with "
                        k "Tab"
                        " switches the entire way you are looking at the machine — not just which \
                        \columns are on show."
                )
            ,
                ( "Why is a screen a better answer than just adding the columns you want to Main?"
                , do
                    p_ $ do
                        "Because width is finite and questions are not. A Main screen that carries \
                        \the memory columns, the I/O columns and the cgroup columns has no room \
                        \left for "
                        c "Command"
                        ", and a column set that answers every question answers none of them \
                        \quickly."
                    p_ $ do
                        "Screens let each one be uncompromised: eight memory columns on the memory \
                        \screen and none on the others. The cost is one keystroke to switch, which \
                        \is cheaper than horizontal scrolling and much cheaper than reading the \
                        \wrong column because two similar ones are adjacent."
                )
            ,
                ( "Screens are htop 3's headline feature. Why does the manual page barely mention \
                  \them?"
                , do
                    p_ $ do
                        "It mentions "
                        k "Tab"
                        " under INTERACTIVE COMMANDS and then discusses screens mostly in the \
                        \context of "
                        c "pcp-htop"
                        ", where extra screens can be added from configuration files. The \
                        \ordinary htop case — build a tab in Setup, get a "
                        c "screen:"
                        " line in your config — is not documented anywhere."
                    p_ $ do
                        "This is the same pattern as the whole Setup screen, and it is worth \
                        \generalising rather than resenting: a manual page tends to document the "
                        i_ "command-line and file interfaces"
                        " well and the interactive interface poorly, because the first two are what \
                        \scripts depend on. For anything you reach by pressing a key, the built-in \
                        \help and the config file the program writes are the real documentation."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d11diagram :: Diagram
d11diagram =
    ( diagram
        "A screen has a name, an ordered list of columns and its own sort and tree state; htop \
        \holds several screens and shows one at a time, with Tab moving between them."
        body'
    )
        { dgCaption = do
            "A screen is not a filter and not a view of a shared configuration — it owns its \
            \columns "
            i_ "and"
            " its sort "
            i_ "and"
            " its tree state, so switching tabs changes the whole way you are looking at the \
            \machine. The dashed aspect is the one that makes them usable: exactly one screen is \
            \current, and "
            k "Tab"
            " moves that mark. Everything else keeps its state while you are away."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  htop  [label=\"an htop session\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  scr   [label=\"a screen\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  nm    [label=\"a name on the tab bar\"];\n\
        \  col   [label=\"an ordered list\\nof columns\"];\n\
        \  srt   [label=\"a sort column\\nand direction\"];\n\
        \  tv    [label=\"a tree view state\"];\n\
        \  cur   [label=\"the current screen\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  htop -> scr [label=\"  holds several\"];\n\
        \  scr  -> nm  [label=\"  is labelled by\"];\n\
        \  scr  -> col [label=\"  displays\"];\n\
        \  scr  -> srt [label=\"  remembers its own\"];\n\
        \  scr  -> tv  [label=\"  remembers its own\"];\n\
        \  cur  -> scr [label=\"  is\"];\n\
        \  htop -> cur [label=\"shows only  \", style=dashed, constraint=false];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "You have had two tabs all along" $ do
        p_ [class_ "lede"] $ do
            "Press "
            k "Tab"
            ". htop ships with two screens — "
            c "Main"
            " and "
            c "I/O"
            " — and most people never find the second one, because until you turn on the tab bar \
            \there is nothing on screen to suggest it exists."
        p_ $ do
            "A screen is a named, complete configuration of the process list: its own columns, its \
            \own sort column and direction, its own tree state. "
            k "Tab"
            " and "
            k "Shift-Tab"
            " cycle. This is htop 3's most useful feature and the manual page does not describe it."
        termWin
            "htop — four screens"
            [ "Avg[||                                        0.9%] Tasks: 237, 2883 thr, 418 kthr"
            , "Mem[||||||||||||||||||||||||||||     11.9G/61.9G] Load average: 0.26 0.20 0.19"
            , "  [Main] [Memory] [I/O] [Containers]"
            , "  PID USER        NI   RES  PRIV   PSS S  CPU%\9661MEM%   TIME+  Command"
            , "76008 jhrcek       0  356M  240M  310M S   7.5  0.6  0:03.75 code --type=renderer"
            , " 5399 jhrcek       0  346M  164M  206M S   2.5  0.5  2:13.39 gnome-shell"
            ]
        fig
        why $ p_ $ do
            "Screens exist because the alternative does not scale. Every column you add to a single \
            \list takes width from "
            c "Command"
            ", so a layout that answers memory questions, I/O questions and container questions at \
            \once answers all of them badly. Tabs let each question have an uncompromised layout, \
            \at a cost of one keystroke — and because each screen keeps its own sort, switching \
            \tabs re-asks the question rather than just re-showing the data."

    block "The config format" $ do
        p_ $ do
            "A screen is one "
            c "screen:"
            " line followed by its "
            c "."
            "-prefixed settings. The dotted lines belong to the "
            c "screen:"
            " line immediately above them, so order matters here in a way it does not elsewhere in \
            \the file."
        cfg
            [ "screen:Memory=PID USER M_RESIDENT M_SHARE M_PRIV M_PSS M_SWAP PERCENT_MEM Command"
            , ".sort_key=M_PSS"
            , ".sort_direction=-1"
            , ".tree_view=0"
            ]
        defs
            [ (c "screen:" <> var "Name" <> "=", do "The tab's name, then its columns in order. Use the internal names from " ; c "htop --sort-key help" ; ", not the display headings.")
            , (c ".sort_key", "A column name — and it does not have to be one of the columns on screen.")
            , (c ".sort_direction", do c "-1" ; " descending, " ; c "1" ; " ascending.")
            , (c ".tree_view" <> ", " <> c ".tree_sort_key" <> ", " <> c ".all_branches_collapsed", "The tree state, remembered per screen.")
            ]
        tip $ p_ $ do
            "Writing screens by hand is better than building them in Setup, for the same reason \
            \writing any config by hand is better: you can put a comment above it saying why it \
            \exists. Build one in Setup first to see the shape, then move it into your file with \
            \its justification attached."

    block "Screens worth having" $ do
        p_ "Four that earn their tab, beyond the default two:"
        defs
            [
                ( c "Memory"
                , do
                    "Day 3's columns side by side — "
                    c "RES"
                    ", "
                    c "SHR"
                    ", "
                    c "PRIV"
                    ", "
                    c "PSS"
                    ", "
                    c "SWAP"
                    " — sorted by "
                    opt "M_PSS"
                    ". Today's config block. The point is not that PSS is on screen but that it is \
                    \next to RES, so the gap between them is visible."
                )
            ,
                ( c "Containers"
                , do
                    opt "CONTAINER"
                    " and "
                    opt "CCGROUP"
                    " with CPU and memory. Day 13 builds it."
                )
            ,
                ( c "Threads"
                , do
                    opt "NLWP"
                    ", "
                    opt "TGID"
                    ", "
                    opt "PROCESSOR"
                    " and "
                    opt "CTXT"
                    ". For the specific failure where one thread in a pool is pinned and the \
                    \process average looks fine."
                )
            ,
                ( c "Lifetime"
                , do
                    opt "STARTTIME"
                    ", "
                    opt "ELAPSED"
                    ", "
                    opt "PPID"
                    " and "
                    opt "OOM"
                    ", in tree view. Answers “what restarted, and what started it” — which is most \
                    \of what an incident turns out to be."
                )
            ]
        gotcha $ p_ $ do
            "Screens have the same "
            c "Command"
            "-goes-last rule as Day 10, and it bites harder here because you are writing the \
            \column list by hand rather than dragging entries in Setup. Nothing validates the \
            \order, and an unknown column name is silently dropped rather than reported — so a \
            \screen that comes out with fewer columns than you wrote has a typo in it somewhere."

    block "Today's habit" $ do
        p_ $ do
            "Turn on "
            opt "screen_tabs"
            " if you have not already, so that the screens you build are discoverable six months \
            \from now. A tab you cannot see is a tab you will not use."
        p_ $ do
            "Then build exactly one screen — the one matching the thing you are actually on call \
            \for. Four speculative screens you never press "
            k "Tab"
            " to reach are worse than none, because they make the tab bar noise."
        p_ "Tomorrow: the I/O screen you have had all along, and the delay-accounting columns that explain why a process is slow when nothing is busy."

cheat :: Html ()
cheat = do
    cfg
        [ "Tab  Shift-Tab     next / previous screen"
        , "screen_tabs=1      draw the tab bar (Day 9) -- without it, screens are invisible"
        , ""
        , "screen:Memory=PID USER M_RESIDENT M_SHARE M_PRIV M_PSS M_SWAP PERCENT_MEM Command"
        , ".sort_key=M_PSS          # may be a column that is NOT on screen"
        , ".sort_direction=-1       # -1 descending, 1 ascending"
        , ".tree_view=0             # tree state is per-screen too"
        , ""
        , "the dotted lines bind to the screen: line ABOVE them -- order matters here"
        , "use internal names (M_RESIDENT), not display headings (RES)"
        , "Command last, always; an unknown column name is dropped in silence"
        ]
    p_ $ do
        "Each screen remembers its own columns, sort column, sort direction and tree state, so "
        k "Tab"
        " changes the whole way you are looking at the machine rather than just which columns are \
        \visible."
