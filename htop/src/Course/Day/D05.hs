module Course.Day.D05 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 5
        , dayTitle = "Sorting and the tree"
        , daySubtitle = "Two orderings of the same rows, and they are mutually exclusive on purpose."
        , dayMinutes = 30
        , dayLevel = "essential"
        , dayManRef = "INTERACTIVE COMMANDS, COMMAND-LINE OPTIONS"
        , dayTags = ["sorting", "tree view", "follow"]
        , dayGoals =
            [ "sort by any column in two keystrokes, and invert it in one"
            , "explain why sorting by CPU% inside the tree does not put the busiest process at the top"
            , "pin the selection to a process that keeps moving"
            ]
        , dayDiagram = Just d5diagram
        , dayBody = body
        , dayKeys =
            [ ("F6 > < .", "Open the “Sort by” menu. All three punctuation aliases work.")
            , ("I", "Invert the sort direction. The arrow in the heading flips.")
            , ("N P M T", "Sort by PID, CPU%, MEM% and TIME. The top(1) compatibility keys.")
            , ("F5 t", "Toggle tree view. The " <> k "F5" <> " label changes to " <> c "List" <> " while you are in it.")
            , ("+ -", "Expand or collapse the selected subtree.")
            , ("*", "Expand or collapse every subtree at once.")
            , ("F", "Follow: pin the selection to this process wherever it moves.")
            ]
        , dayCmds =
            [ ("htop -s PERCENT_MEM", "Start sorted by a column. Forces list view.")
            , ("htop -s PERCENT_MEM -t", "Sorted " <> i_ "and" <> " in tree view — the one way to have both.")
            , ("htop --sort-key help", "Print every sortable column name and what it means.")
            , ("htop -t=soft", "Tree view with a stable cursor line. " <> c "classic" <> ", " <> c "soft" <> " and " <> c "hard" <> ", or " <> c "0" <> "/" <> c "1" <> "/" <> c "2" <> ".")
            ]
        , dayOpts = []
        , dayConfig = []
        , dayDrills =
            [ "Press "
                <> k "M"
                <> " then "
                <> k "P"
                <> " then "
                <> k "T"
                <> ". Three different pictures of the same machine in three keystrokes. Notice \
                   \which processes appear near the top of all three."
            , "Press "
                <> k "I"
                <> " while sorted by "
                <> c "CPU%"
                <> ". The arrow in the heading flips and the idlest processes come to the top — \
                   \which is occasionally exactly what you want to know."
            , "Press "
                <> k "F6"
                <> " and read the whole sort menu once. It is the same list as "
                <> c "htop --sort-key help"
                <> " and it is the menu you will live in from Day 10."
            , "Press "
                <> k "t"
                <> ". Find your shell, and follow the line of "
                <> c "├─"
                <> " characters up to PID 1. That chain is the answer to “what started this”, and \
                   \it is the single best reason to use the tree."
            , "In tree view, sort by "
                <> c "CPU%"
                <> " with "
                <> k "P"
                <> ". Watch yourself get thrown straight back to the flat list. Now do it the way \
                   \that works: quit and run "
                <> c "htop -s PERCENT_CPU -t"
                <> "."
            , "Break something on purpose: in tree view press "
                <> k "*"
                <> " to collapse everything, then try to find a process you know is running. \
                   \Collapsed subtrees hide rows just as thoroughly as a filter does, and with \
                   \even less warning."
            , "On your own machine: park the selection on the process you care about, press "
                <> k "F"
                <> ", and then sort by "
                <> c "CPU%"
                <> ". The list reorders around it and your row stays put. This is the closest htop \
                   \has to a watch window."
            , "Adopt the habit of starting htop the way you want it rather than fixing it every \
              \time: "
                <> c "htop -s PERCENT_MEM"
                <> " when you are chasing memory, "
                <> c "htop -t"
                <> " when you are chasing parentage."
            ]
        , dayQuiz =
            [
                ( "You are in tree view, you press "
                    <> k "P"
                    <> " to sort by CPU%, and the tree vanishes. Is that a bug?"
                , do
                    p_ $ do
                        "No, it is the design. The tree "
                        i_ "is"
                        " an ordering — parents above children, depth-first — so it cannot coexist \
                        \with an arbitrary sort of the whole list. The manual page says it plainly: \
                        \“Selecting a sort view will exit tree view.”"
                    p_ $ do
                        "The way to have both is to ask for both at startup: "
                        c "htop -s PERCENT_CPU -t"
                        ". Then the tree structure is kept and the sort is applied only within each \
                        \set of siblings, which is a genuinely different and often more useful \
                        \picture — the busiest child of each parent, rather than the busiest \
                        \process on the box."
                )
            ,
                ( "Running "
                    <> c "htop -s PERCENT_CPU -t"
                    <> ", you expect the hungriest process at the top and instead the top row is "
                    <> c "systemd"
                    <> " at 0.0%. Explain the list you are looking at."
                , do
                    p_ $ do
                        "In tree view the sort applies to "
                        b_ "direct children of each process"
                        ", never to the list as a whole. The top row is PID 1 because PID 1 is the \
                        \root of the tree, and roots come first regardless of what they are using."
                    p_ $ do
                        "What the sort bought you is that "
                        i_ "within"
                        " each parent, the busiest child is listed first — so walking down from a \
                        \root follows the hot path through the tree. If you want “the busiest \
                        \process on this machine, full stop”, that is a question about a flat list, \
                        \and you should leave the tree."
                )
            ,
                ( "A process is bouncing in and out of the top of a CPU%-sorted list, and every \
                  \time you try to select it the list reorders and you select something else. What \
                  \is the fix, and what is the trap in the fix?"
                , do
                    p_ $ do
                        k "F"
                        " — follow. Select the process once, press "
                        k "F"
                        ", and the selection stays glued to it no matter where the sort order \
                        \carries it. It is the only way to watch a single process without \
                        \freezing the whole screen with "
                        k "Z"
                        "."
                    p_ $ do
                        "The trap is that follow mode is sticky by default, so it stays on until \
                        \you press "
                        k "F"
                        " again — and while it is on, the ordinary movement keys behave oddly \
                        \because the selection is pinned. "
                        k "Shift-Up"
                        " and "
                        k "Shift-Down"
                        " still pan the view, which is how you look around without losing the pin."
                )
            ,
                ( "The manual page lists "
                    <> c "F6"
                    <> ", "
                    <> c "<"
                    <> " and "
                    <> c ">"
                    <> " for choosing a sort column. htop's own help screen lists "
                    <> c "F6"
                    <> ", "
                    <> c ">"
                    <> " and "
                    <> c "."
                    <> ". Which should you believe?"
                , do
                    p_ $ do
                        "Neither, entirely — all four work. The page and the help each list a \
                        \different incomplete subset, and the binary accepts "
                        c "<"
                        ", "
                        c ">"
                        " and "
                        c "."
                        " as well as "
                        k "F6"
                        "."
                    p_ $ do
                        "This is worth more than the trivia. Two independent pieces of \
                        \documentation disagreeing usually means both are stale, and the "
                        i_ "union"
                        " of what they claim is a better guess than either. It costs ten seconds to \
                        \press a key and find out, and that habit will serve you on every tool you \
                        \ever learn."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d5diagram :: Diagram
d5diagram =
    ( diagram
        "The flat list orders every row by a sort column, while the tree view indents each row \
        \under its parent and applies the sort only within a set of siblings; choosing a sort \
        \column replaces the tree."
        body'
    )
        { dgCaption = do
            "Both views contain exactly the same rows and differ only in how they are ordered — \
            \which is why they cannot both be on. Follow the dashed aspect: picking a sort column \
            \replaces the tree outright. The subtle one is the arrow from the tree to "
            b_ "a set of sibling rows"
            ": inside the tree, sorting never reaches across the whole list, only within one \
            \parent's children. That is the entire explanation for “I sorted by CPU% and the top \
            \row is idle”."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  row    [label=\"a row\"];\n\
        \  flat   [label=\"the flat list\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  tree   [label=\"the tree view\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  col    [label=\"a sort column\"];\n\
        \  parent [label=\"a parent process\"];\n\
        \  sibs   [label=\"a set of sibling rows\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  flat -> row    [label=\"  contains\"];\n\
        \  flat -> col    [label=\"  orders every row by\"];\n\
        \  tree -> row    [label=\"  contains\"];\n\
        \  tree -> parent [label=\"  indents each row under\"];\n\
        \  row  -> parent [label=\"  has as parent\"];\n\
        \  sibs -> parent [label=\"  all share\"];\n\
        \  tree -> sibs   [label=\"  sorts only within\"];\n\
        \  tree -> flat   [label=\"replaces  \", style=dashed, constraint=false];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "The same rows, ordered two ways" $ do
        p_ [class_ "lede"] $ do
            "htop has two ways to arrange the process list, and they are alternatives rather than \
            \options you combine. A "
            b_ "sort"
            " orders every row by one column. The "
            b_ "tree"
            " orders rows by parentage. Asking for a sort while in the tree throws you out of the \
            \tree, and that surprises everybody exactly once."
        p_ $ do
            "The reason is that the tree is not a decoration applied to a sorted list — it "
            i_ "is"
            " an ordering, and a total one: every row's position is determined by its ancestry. \
            \Two total orderings of the same rows cannot both be in effect."
        fig
        why $ p_ $ do
            "So why does "
            c "htop -s PERCENT_CPU -t"
            " work at all? Because it means something weaker and more useful: keep the tree, and \
            \wherever there is a free choice — the order of one parent's children among themselves \
            \— break the tie with the sort column. The tree fixes most of the ordering; the sort \
            \fills in the rest. That is the only sense in which the two can coexist, and it is why \
            \the combination has to be requested deliberately."

    block "Sorting, in one or two keystrokes" $ do
        p_ $ do
            k "F6"
            " opens the “Sort by” menu — and so do "
            k ">"
            ", "
            k "<"
            " and "
            k "."
            ", all of which work despite no single piece of documentation listing all of them. \
            \Arrows to move, "
            k "Enter"
            " to sort, "
            k "Esc"
            " to back out."
        p_ "Four columns are on single keys, inherited from top(1):"
        defs
            [ (k "N", "PID. Ascending, so it is roughly boot order — a cheap way to see what started recently.")
            , (k "P", c "CPU%" <> ". The default.")
            , (k "M", c "MEM%" <> ", which means " <> c "RES" <> ", with all of Day 3's caveats.")
            , (k "T", c "TIME+" <> ". Cumulative CPU since start — who has burned the most, ever.")
            ]
        p_ $ do
            k "I"
            " inverts. The current sort column is marked in the heading row with a highlight and a "
            c "▽"
            " or "
            c "△"
            ", which is the fastest way to answer “what am I even looking at” after coming back to \
            \a terminal."
        tip $ p_ $ do
            "Sorting by "
            c "TIME+"
            " with "
            k "T"
            " is the underused one. "
            c "CPU%"
            " tells you who is busy in the last 1.5 seconds; "
            c "TIME+"
            " tells you who has been busy since boot. A process that is quiet now but sits at the \
            \top of "
            c "TIME+"
            " has been quietly eating the machine for a week, and no amount of watching "
            c "CPU%"
            " will show you that."

    block "The tree" $ do
        p_ $ do
            k "F5"
            " or "
            k "t"
            " switches to tree view. You can tell you are in it without looking at the rows: the "
            k "F5"
            " label on the function bar changes to "
            c "List"
            ", because that is what pressing it will do next."
        termWin
            "htop — tree view"
            [ "  PID\9651USER       PRI  NI  VIRT   RES  PRIV S  CPU% MEM%   TIME+  Command"
            , "    1 root        20   0 40080 22080 10516 S   0.0  0.0  0:02.67 systemd"
            , "  843 root        20   0 67440 36624  1924 S   0.0  0.1  0:00.41 \9500\9472 systemd-journald"
            , "  875 root        20   0 16604  6988  1044 S   0.0  0.0  0:00.04 \9500\9472 systemd-userdbd"
            , " 1869 root        20   0 97348 68616 28732 S   0.0  0.1  0:04.12 \9500\9472 dockerd"
            , " 1485 root        20   0 49236 34128 15108 S   0.0  0.1  0:02.30 \9474  \9500\9472 containerd"
            , "F1Help  F2Setup F3SearchF4FilterF5List  F6SortByF7Nice -F8Nice +F9Kill  F10Quit"
            ]
        defs
            [ (k "+" <> " " <> k "-", "Expand or collapse the selected subtree. A collapsed subtree shows a " <> c "+" <> " to the left of the name.")
            , (k "*", do "Expand or collapse everything at once — strictly, every child of every parentless PID, which on Linux means PID 1 and " ; c "kthreadd" ; ".")
            ]
        gotcha $ p_ $ do
            "A collapsed subtree hides rows exactly as effectively as a filter, and gives you even \
            \less warning: a small "
            c "+"
            " character somewhere in a list of three hundred lines. If you are in tree view and a \
            \process you know is running is not on screen, press "
            k "*"
            " before you conclude anything."

    block "Keeping the tree still" $ do
        p_ $ do
            "The tree redraws every 1.5 seconds, and processes come and go, so the line you were \
            \reading tends to slide out from under you. htop offers three behaviours, and the \
            \manual page hides them inside the "
            c "-t"
            " flag:"
        defs
            [ (c "-t=classic" <> " / " <> c "-t=0", "No stabilisation. The tree redraws wherever the rows fall.")
            , (c "-t=soft" <> " / " <> c "-t=1", "Try to keep the currently selected line in the same place on screen.")
            , (c "-t=hard" <> " / " <> c "-t=2", "As soft, and additionally allow the whole tree to move down, leaving blank space above the root when that is what it takes.")
            ]
        p_ $ do
            "There is also an older behaviour worth naming because you will meet it in other \
            \people's configs: “tree view is always sorted by PID”, which was how htop 2 did it. \
            \It lives in the Setup screen, and Day 9 will show you where."
        note $ p_ $ do
            "An invalid mode is a clean error rather than a silent fallback: "
            c "htop --tree=bogus"
            " prints "
            c "Error: invalid tree mode \"bogus\""
            " and exits. The same is true of "
            c "-s"
            " with an unknown column name. That is worth knowing because so much of htop's config \
            \handling is silent — here, at least, you get told."

    block "Follow" $ do
        p_ $ do
            k "F"
            " pins the selection to whatever process is selected now. Sort the list, let everything \
            \reorder around it, and your row stays selected — htop tracks the process, not the \
            \position."
        p_ $ do
            "It is sticky by default: follow mode stays on until you press "
            k "F"
            " again. With it on, the ordinary movement keys will feel wrong, because the selection \
            \is no longer yours to move. "
            k "Shift-Up"
            " and "
            k "Shift-Down"
            " — or the "
            k "Alt-Up"
            " and "
            k "Alt-Down"
            " forms from Day 2 — pan the view without breaking the pin, which is how you look \
            \around while still following."
        tip $ p_ $ do
            k "F"
            " and "
            k "Z"
            " solve the same problem from opposite ends. "
            k "Z"
            " freezes the whole screen so nothing moves; "
            k "F"
            " lets everything move and holds one row still. Use "
            k "Z"
            " to read a screenful, "
            k "F"
            " to watch one process over minutes."

    block "Today's habit" $ do
        p_ $ do
            "Stop starting htop plain and then fixing it. Decide what question you are asking \
            \before you launch: "
            c "htop -s PERCENT_MEM"
            " for memory, "
            c "htop -t"
            " for “what started this”, "
            c "htop -s TIME"
            " for “what has been eating this box all week”."
        p_ $ do
            "That is the last of the essentials. You can now navigate, read the columns honestly, \
            \find anything and order it however you like. Everything from here changes the machine \
            \rather than just looking at it."
        p_ "Tomorrow: tagging, signals, nice, affinity — acting on processes, and the ways that goes wrong."

cheat :: Html ()
cheat = do
    cfg
        [ "F6  >  <  .   open the 'Sort by' menu   (all four work)"
        , "I             invert the sort direction"
        , "N P M T       sort by PID / CPU% / MEM% / TIME+   (top-compatible keys)"
        , ""
        , "F5  t         tree view on/off  -- the F5 label reads 'List' while you are in it"
        , "+  -          expand / collapse the selected subtree"
        , "*             expand / collapse everything"
        , "F             follow: pin the selection to this process (sticky; F again to stop)"
        , ""
        , "htop -s PERCENT_MEM       sorted, flat  (a sort FORCES list view)"
        , "htop -s PERCENT_MEM -t    sorted, tree  (sort applies within siblings only)"
        , "htop -t=soft              tree with a stable cursor line (classic|soft|hard)"
        , "htop --sort-key help      every sortable column, with descriptions"
        ]
    p_ $ do
        "In tree view the sort orders "
        b_ "each parent's children among themselves"
        ", never the list as a whole — so the top row is a root process, whatever it is using."
