module Course.Day.D10 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 10
        , dayTitle = "The column catalogue"
        , daySubtitle = "Seventy columns in eight families, the threads that fill your list, and why a column says '-'."
        , dayMinutes = 35
        , dayLevel = "intermediate"
        , dayManRef = "COLUMNS"
        , dayTags = ["columns", "threads", "reference"]
        , dayGoals =
            [ "find the column that answers a question, without reading a seventy-entry table"
            , "tell a thread from a process on sight, and decide which you want in the list"
            , "distinguish the four different ways a column can fail to have a value"
            ]
        , dayDiagram = Just d10diagram
        , dayBody = body
        , dayKeys =
            [ ("K", "Hide or show kernel threads. Hidden by default.")
            , ("H", "Hide or show userland threads. Shown by default — this is why your list is so long.")
            ]
        , dayCmds =
            [ ("htop --sort-key help", "The authoritative column list, straight from the binary. Better than the manual page.")
            ]
        , dayOpts =
            [ ("NLWP", "How many threads this process has. The cheapest way to spot a thread pool.")
            , ("TGID", "Thread group id — a thread's process. Equals " <> c "PID" <> " for a process.")
            , ("STARTTIME", "Wall-clock time the process started. Shown as " <> c "START" <> ".")
            , ("ELAPSED", "How long it has been running. Undocumented in the manual page.")
            , ("OOM", "The OOM killer's score for this process. Who dies first under memory pressure.")
            , ("CTXT", "Context switches counted over the refresh interval. A rate, not a lifetime total.")
            , ("PROCESSOR", "Which CPU it last ran on. Shown as " <> c "CPU" <> ".")
            , ("SCHEDULERPOLICY", "The scheduling policy from Day 6's " <> k "Y" <> " dialog. Undocumented in the manual page.")
            , ("SECATTR", "The SELinux or AppArmor label. Undocumented, and very wide.")
            , ("show_thread_names", "Show each thread's own name rather than its process's command. Default off.")
            , ("highlight_threads", "Draw thread rows in a different colour. Default on.")
            ]
        , dayConfig =
            [ ConfBlock
                "A Main screen for the question 'what is this machine doing, and can I afford it'.\n\
                \Changes from the default: PRIORITY dropped (NICE is the part you can act on), and\n\
                \M_PSS added beside RES and PRIV, so the three memory numbers from Day 3 that\n\
                \actually disagree are side by side. Command stays last -- it is the only\n\
                \variable-width column, and anything after it gets squeezed."
                "screen:Main=PID USER NICE M_RESIDENT M_PRIV M_PSS STATE PERCENT_CPU PERCENT_MEM TIME Command\n\
                \.sort_key=PERCENT_CPU\n\
                \.sort_direction=-1\n\
                \.tree_sort_key=PID\n\
                \.tree_sort_direction=1"
            , ConfBlock
                "Make threads identifiable without pressing m every time. Kernel threads stay hidden\n\
                \(the default, and right -- there are several hundred and they are almost never your\n\
                \problem); userland threads stay visible but are drawn in their own colour and\n\
                \labelled with their own name, so a row called 'JITWorker' stops masquerading as\n\
                \another copy of the program."
                "hide_kernel_threads=1\n\
                \hide_userland_threads=0\n\
                \highlight_threads=1\n\
                \show_thread_names=1"
            ]
        , dayDrills =
            [ "Run "
                <> c "htop --sort-key help"
                <> " and page through the whole list once. It takes ninety seconds and it is the \
                   \only complete, current column reference that exists."
            , "Press "
                <> k "H"
                <> ". Watch the list shrink by roughly a factor of ten. Those were all threads, and \
                   \they were there the entire time you were reading Days 2 to 9."
            , "Press "
                <> k "K"
                <> ". Now several hundred kernel threads appear — "
                <> c "kworker"
                <> ", "
                <> c "ksoftirqd"
                <> ", "
                <> c "kswapd"
                <> ". Press it again. This is what your machine is really made of."
            , "Add the "
                <> opt "NLWP"
                <> " column in Setup → Screens and sort by it. The top of that list is every thread \
                   \pool on your machine, ranked."
            , "Add "
                <> opt "OOM"
                <> " and sort descending. You are now looking at the order in which things die if \
                   \the machine runs out of memory. Check whether you are comfortable with the top \
                   \three."
            , "Break something on purpose: add "
                <> opt "SECATTR"
                <> " as the second column, before "
                <> c "Command"
                <> ". The SELinux labels are eighty characters wide and push everything off the \
                   \screen. Now move "
                <> c "Command"
                <> " back to last and see the difference."
            , "Find a column showing "
                <> c "-"
                <> " in every row and one showing "
                <> c "N/A"
                <> " in every row. They mean different things, and Day 12 explains the second."
            , "On your own machine: build the Main screen you actually want. Every column you add \
              \costs width, so the discipline is subtraction — decide what to drop from the \
              \default twelve before you decide what to add."
            ]
        , dayQuiz =
            [
                ( "Your list has 2400 rows but the header says 219 tasks. You press "
                    <> k "H"
                    <> " and it drops to about 200. What were the other 2200?"
                , do
                    p_ $ do
                        "Userland threads, which htop shows as rows by default. The header's "
                        c "Tasks: 219, 2396 thr, 422 kthr"
                        " was telling you this the whole time: 219 processes, 2396 threads in \
                        \total, 422 of them kernel threads."
                    p_ $ do
                        k "H"
                        " hides userland threads and "
                        k "K"
                        " hides kernel ones — and the defaults are asymmetric, kernel threads \
                        \hidden and userland threads shown. That is the right default for finding \
                        \a runaway thread in a thread pool and the wrong one for getting an \
                        \overview, which is why the key exists."
                )
            ,
                ( "A column shows "
                    <> c "-"
                    <> " in every row, another shows "
                    <> c "N/A"
                    <> ", another shows "
                    <> c "0"
                    <> " for other users' processes but real numbers for yours. Three different \
                       \failures — what are they?"
                , do
                    p_ $ do
                        c "-"
                        " is the manual page's documented marker for “unsupported on your system, \
                        \or not implemented in htop”. Nothing you can do about it; the data does \
                        \not exist on this platform."
                    p_ $ do
                        c "N/A"
                        " is the delay-accounting columns saying the feature was not compiled in or \
                        \you lack "
                        c "CAP_NET_ADMIN"
                        " — Day 12's subject. And "
                        c "0"
                        " is the "
                        opt "M_PSS"
                        " family from Day 3, where htop could not read "
                        c "smaps_rollup"
                        " and printed a plausible-looking zero instead of admitting it. That last \
                        \one is the dangerous one, because it sorts."
                )
            ,
                ( "The manual page's COLUMNS section documents a column called "
                    <> c "M_M_PSSWP"
                    <> ". Setup does not list it and it will not sort. What is going on?"
                , do
                    p_ $ do
                        "It is a typo in the manual page. The real column is "
                        opt "M_PSSWP"
                        " — one "
                        c "M_"
                        ", not two — as "
                        c "htop --sort-key help"
                        " and the generated "
                        c "htoprc"
                        " both confirm. Copy the name out of the page into a config file and htop \
                        \silently drops it, because the parser never complains about an unknown \
                        \column."
                    p_ $ do
                        "It is not the only gap: the page's COLUMNS section also has no entry for "
                        opt "ELAPSED"
                        ", "
                        opt "SCHEDULERPOLICY"
                        ", "
                        opt "SECATTR"
                        ", "
                        opt "CWD"
                        ", "
                        opt "CONTAINER"
                        ", "
                        opt "ISCONTAINER"
                        ", "
                        opt "GPU_TIME"
                        " or "
                        opt "GPU_PERCENT"
                        ", all of which the binary offers. Use "
                        c "--sort-key help"
                        " as your catalogue."
                )
            ,
                ( "Why does the manual page insist that "
                    <> c "Command"
                    <> " should be the last column, and what happens if you ignore it?"
                , do
                    p_ $ do
                        "Because it is the only column with no natural width. Every other column \
                        \is sized to its content — a PID is at most seven characters, a percentage \
                        \is five — and "
                        c "Command"
                        " simply takes whatever is left. Put it last and it absorbs the remaining \
                        \width gracefully."
                    p_ $ do
                        "Put something after it and htop has to give "
                        c "Command"
                        " a fixed width, so command lines are truncated early while the column \
                        \after it sits alone at the right-hand edge. You end up scrolling \
                        \horizontally on every row to read something that would have fitted. It is \
                        \a layout rule rather than a hard constraint, which is exactly why it is \
                        \easy to break by accident."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d10diagram :: Diagram
d10diagram =
    ( diagram
        "A screen holds an ordered list of columns; each column reads a field of a task, which \
        \the kernel may not publish, may not let you read, or may not implement — producing three \
        \different empty markers."
        body'
    )
        { dgCaption = do
            "Choosing columns is choosing which "
            i_ "questions"
            " are on screen, and the constraint is width, not availability — every column you add \
            \takes space from "
            c "Command"
            ". The three dashed aspects are the ways a column comes back empty, and they are worth \
            \telling apart: "
            c "-"
            " means the data does not exist here, "
            c "N/A"
            " means the feature was not built in, and a bare "
            c "0"
            " means htop was refused permission and said so badly."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  scr   [label=\"a screen\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  col   [label=\"a column\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  fld   [label=\"a field of a task\"];\n\
        \  task  [label=\"a task\"];\n\
        \  plat  [label=\"a platform that does\\nnot publish it\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  build [label=\"a build option\\nthat was left off\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  perm  [label=\"a permission\\nyou lack\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  scr -> col   [label=\"  lists, in order\"];\n\
        \  col -> fld   [label=\"  displays\"];\n\
        \  fld -> task  [label=\"  belongs to\"];\n\
        \  col -> plat  [label=\"shows - because of  \", style=dashed, constraint=false];\n\
        \  col -> build [label=\"  shows N/A because of\", style=dashed, constraint=false];\n\
        \  col -> perm  [label=\"  shows 0 because of\", style=dashed, constraint=false];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Seventy columns is a catalogue, not a lesson" $ do
        p_ [class_ "lede"] $ do
            "The manual page spends 312 of its 768 lines listing columns — nearly half the \
            \document. Reading it end to end teaches you almost nothing, because the useful skill \
            \is not knowing all seventy but "
            b_ "knowing which family to look in"
            " when you have a question."
        p_ $ do
            "And the catalogue in the page is out of date. The current, authoritative list comes \
            \from the binary:"
        sh
            [ "$ htop --sort-key help"
            , "                PID Process/thread ID"
            , "            Command Command line (insert as last column only)"
            , "              STATE Process state (S sleeping, R running, D disk, Z zombie, ...)"
            , "            ELAPSED Time since the process was started"
            , "    SCHEDULERPOLICY Current scheduling policy of the process"
            , "            SECATTR Security attribute of the process (e.g. SELinux or AppArmor)"
            ]
        p_ $ do
            "The last three of those appear nowhere in the manual page's COLUMNS section, along \
            \with "
            opt "CWD"
            ", "
            opt "CONTAINER"
            ", "
            opt "ISCONTAINER"
            ", "
            opt "GPU_TIME"
            " and "
            opt "GPU_PERCENT"
            ". The page also documents a column called "
            c "M_M_PSSWP"
            ", which does not exist — the real name is "
            opt "M_PSSWP"
            "."
        fig

    block "The eight families" $ do
        defs
            [ ("Identity", do opt "PID" ; ", " ; opt "PPID" ; ", " ; opt "PGRP" ; ", " ; opt "SESSION" ; ", " ; opt "TGID" ; ", " ; opt "TTY" ; ", " ; opt "TPGID" ; ", " ; opt "USER" ; ", " ; opt "ST_UID" ; ". Who and what — and the parentage that Day 5's tree draws.")
            , ("What it is running", do opt "Command" ; ", " ; opt "COMM" ; ", " ; opt "EXE" ; ", " ; opt "CWD" ; ". Day 2's three sources, each available as its own column.")
            , ("State and scheduling", do opt "STATE" ; ", " ; opt "PRIORITY" ; ", " ; opt "NICE" ; ", " ; opt "PROCESSOR" ; ", " ; opt "SCHEDULERPOLICY" ; ", " ; opt "AGRP" ; ", " ; opt "ANI" ; ". What the scheduler thinks of it.")
            , ("Lifetime", do opt "STARTTIME" ; " and " ; opt "ELAPSED" ; ". When it started, and how long ago — the pair that answers “did this restart?”.")
            , ("CPU", do opt "PERCENT_CPU" ; ", " ; opt "PERCENT_NORM_CPU" ; ", " ; opt "TIME" ; ", and the four-way split " ; opt "UTIME" ; " / " ; opt "STIME" ; " / " ; opt "CUTIME" ; " / " ; opt "CSTIME" ; " — user and system time, for the process and for its reaped children.")
            , ("Memory", do "Day 3's nine, plus " ; opt "MINFLT" ; ", " ; opt "MAJFLT" ; " and their " ; c "C" ; "-prefixed child versions. A high " ; opt "MAJFLT" ; " means going to disk for pages, which is what thrashing looks like.")
            , ("I/O and cgroups", "Day 12 and Day 13 respectively.")
            , ("The odds and ends", do opt "NLWP" ; ", " ; opt "OOM" ; ", " ; opt "CTXT" ; ", " ; opt "SECATTR" ; ", " ; opt "GPU_TIME" ; ", " ; opt "GPU_PERCENT" ; ".")
            ]
        tip $ p_ $ do
            opt "OOM"
            " deserves more attention than it gets. It is the score the kernel's out-of-memory \
            \killer uses to pick a victim, so sorting by it descending gives you, in order, the \
            \list of things that will die if the machine runs out of memory. On a server that is \
            \worth checking once before you find out empirically at three in the morning."
        note $ p_ $ do
            opt "CTXT"
            " is not a lifetime total despite the manual page's wording — the values are small \
            \single or double digits for processes that have been up for hours, so it is counting \
            \over the refresh interval. Read it as a switching "
            i_ "rate"
            ": a process in the thousands is fighting for a lock or ping-ponging between cores."

    block "Threads are most of your list" $ do
        p_ $ do
            "The header line has been telling you this since Day 1. "
            c "Tasks: 219, 2396 thr, 422 kthr"
            " means 219 processes, 2396 threads, 422 of which belong to the kernel — and by \
            \default htop shows you the userland threads as rows while hiding the kernel ones."
        defs
            [ (k "K", do "Kernel threads — " ; c "kworker" ; ", " ; c "ksoftirqd" ; ", " ; c "kswapd" ; ". Hidden by default, and that is the right default.")
            , (k "H", "Userland threads. Shown by default, which is why your list is ten times longer than your process count.")
            , (opt "NLWP", "How many threads a process has. Sort by it to find every thread pool on the machine at once.")
            , (opt "TGID", do "A thread's process. For a process, " ; opt "TGID" ; " equals " ; opt "PID" ; "; for a thread it does not.")
            ]
        p_ $ do
            "Two display settings make threads legible rather than confusing. "
            opt "highlight_threads"
            " draws them in their own colour — on by default. "
            opt "show_thread_names"
            " shows each thread's own name instead of inheriting its process's command line, and \
            \it is "
            b_ "off"
            " by default, which is why twenty rows all read "
            c "claude"
            " until you turn it on."
        why $ p_ $ do
            "Showing threads by default looks like clutter and is a deliberate choice about what \
            \htop is for. A thread pool where one thread is pinned at 100% is a real and common \
            \failure, and it is invisible if you aggregate threads into their process — the \
            \process shows a modest average and nothing looks wrong. htop optimises for finding \
            \that, and gives you "
            k "H"
            " for the times you wanted the overview instead."

    block "Choosing is subtracting" $ do
        p_ $ do
            "Columns are added in Setup → Screens, picking from Available Columns into Active \
            \Columns. The constraint is not availability, it is "
            b_ "width"
            ": every column you add takes space away from "
            c "Command"
            ", which is the only one with no natural size."
        p_ $ do
            "So the discipline is to decide what to remove from the default twelve first. "
            c "PRI"
            " is a good candidate — it is almost always just "
            c "NI"
            " plus twenty, so it carries one bit of information ("
            c "RT"
            " or not) in four characters. "
            c "VIRT"
            " is another, for all of Day 3's reasons."
        gotcha $ p_ $ do
            "Keep "
            c "Command"
            " last. The manual page says it “should be the last column in each screen” and means \
            \it: anything placed after it forces htop to give "
            c "Command"
            " a fixed width, so every command line is truncated early and you spend the rest of \
            \the day scrolling sideways. Setup will let you do it; nothing will warn you."

    block "Today's habit" $ do
        p_ $ do
            "Build the Main screen you actually want, today, and then leave it alone for a week. \
            \A column set you keep fiddling with never becomes readable — the value of a fixed \
            \layout is that you stop reading the headings and start reading the shape."
        p_ "Tomorrow: stop compromising. Screens are tabs, and you can have a different column set for every question you ask."

cheat :: Html ()
cheat = do
    cfg
        [ "htop --sort-key help    # THE column reference. The man page's list is stale."
        , ""
        , "K    hide/show kernel threads   (hidden by default -- several hundred of them)"
        , "H    hide/show userland threads (SHOWN by default -- this is why the list is huge)"
        , ""
        , "NLWP       threads in this process   -- sort by it to find every thread pool"
        , "TGID       a thread's process        -- equals PID for a process"
        , "OOM        who the OOM killer picks first"
        , "CTXT       context switches per refresh -- a RATE, not a total"
        , "ELAPSED    how long it has been up   [not in man]"
        , "SECATTR    SELinux/AppArmor label    [not in man; very wide]"
        , ""
        , "show_thread_names=1   # threads get their OWN name, not the parent's cmdline"
        , "highlight_threads=1   # and their own colour (on by default)"
        , ""
        , "empty column?   '-' = not on this platform    'N/A' = not compiled in (Day 12)"
        , "                 0  = permission denied, reported badly (PSS, Day 3)"
        ]
    p_ $ do
        "Keep "
        c "Command"
        " last in every screen. It is the only variable-width column; anything after it forces a \
        \fixed width and truncates every command line on screen."
