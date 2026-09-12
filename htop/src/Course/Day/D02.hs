module Course.Day.D02 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 2
        , dayTitle = "The process list"
        , daySubtitle = "Moving around a list ten times taller than your screen, and reading the twelve default columns."
        , dayMinutes = 35
        , dayLevel = "essential"
        , dayManRef = "INTERACTIVE COMMANDS, COLUMNS"
        , dayTags = ["navigation", "columns", "STATE"]
        , dayGoals =
            [ "move to any process in a list of three thousand without using the mouse"
            , "read every one of the twelve default columns, and say which are facts and which are rates"
            , "explain why the Command column is a reconstruction, and change what goes into it"
            ]
        , dayDiagram = Just d2diagram
        , dayBody = body
        , dayKeys =
            [ ("Up Down", "Move the selection one row. " <> k "Alt-k" <> " and " <> k "Alt-j" <> " do the same.")
            , ("PgUp PgDn", "Move the selection a screenful at a time.")
            , ("Home End", "Jump to the first or the last process in the list.")
            , ("Left Right", "Scroll the whole list sideways. Also " <> k "Alt-h" <> " and " <> k "Alt-l" <> ".")
            , ("Ctrl-A ^", "Scroll back to the start of the selected process's line.")
            , ("Ctrl-E $", "Scroll to the end of the selected process's line.")
            , ("Alt-Up Alt-Down", "Pan the view without moving the selection. " <> k "Shift-Up" <> "/" <> k "Shift-Down" <> " too, if your terminal lets them through.")
            , ("p", "Toggle full program paths in " <> c "Command" <> ".")
            , ("m", "Toggle merging " <> c "exe" <> ", " <> c "comm" <> " and " <> c "cmdline" <> " into " <> c "Command" <> ".")
            ]
        , dayCmds = []
        , dayOpts = []
        , dayConfig = []
        , dayDrills =
            [ "Press "
                <> k "End"
                <> " and then "
                <> k "Home"
                <> ". Note how many processes there actually are — almost certainly several \
                   \hundred more than you expected, most of them threads."
            , "Select any process, then press "
                <> k "Right"
                <> " a dozen times. Watch the column headings march off the left edge with the \
                   \data. Get back with "
                <> k "Ctrl-A"
                <> " rather than by pressing "
                <> k "Left"
                <> " a dozen times."
            , "Find the row for htop itself. Read its "
                <> c "S"
                <> " column: it is "
                <> c "R"
                <> ", because htop is by definition running at the moment it samples itself. Now \
                   \find a process in "
                <> c "D"
                <> " state. On an idle machine you may have to wait for one."
            , "Press "
                <> k "p"
                <> ". Every "
                <> c "/usr/lib/systemd/systemd-journald"
                <> " becomes "
                <> c "systemd-journald"
                <> ". Decide which you prefer and leave it that way — you will make it permanent on \
                   \Day 9."
            , "Press "
                <> k "m"
                <> ". The heading changes to "
                <> c "Command (merged)"
                <> " and thread rows start showing names like "
                <> c "JITWorker│claude"
                <> ". That vertical bar is the join between the thread's own name and its process's \
                   \command line."
            , "Break something on purpose: press "
                <> k "Alt-Down"
                <> " ten times to pan the view, then try to work out where the selection went. \
                   \Panning and selecting are different operations, and confusing them is the \
                   \usual reason people think htop has “jumped”."
            , "On your own machine: pick the process you care most about today and read its whole \
              \row out loud, column by column, saying what each number means. Any column you \
              \cannot explain is a gap this course will close — note it down."
            , "Adopt the habit of reading "
                <> c "TIME+"
                <> " next to "
                <> c "CPU%"
                <> ". One is a lifetime total and one is a 1.5-second sample; a process with a \
                   \huge "
                <> c "TIME+"
                <> " and zero "
                <> c "CPU%"
                <> " did its damage earlier and is not your current problem."
            ]
        , dayQuiz =
            [
                ( "A colleague says “htop says the machine is running 2342 processes, no wonder \
                  \it's slow”. The header reads "
                    <> c "Tasks: 219, 2342 thr, 429 kthr; 1 running"
                    <> ". What is actually true?"
                , do
                    p_ $ do
                        "There are 219 processes. 2342 is the count of "
                        i_ "threads"
                        ", 429 of which are kernel threads, and the number that matters for “is \
                        \this machine busy” is the last one: "
                        b_ "1 running"
                        ". Everything else is asleep."
                    p_ $ do
                        "A thread costs a scheduler entry and a stack, not a core. Machines \
                        \routinely carry thousands and idle at zero load. By default htop hides \
                        \kernel threads and shows userland ones, which is why the list is longer \
                        \than the process count — Day 10 covers the "
                        k "K"
                        " and "
                        k "H"
                        " toggles that change this."
                )
            ,
                ( "You scroll right to read a long command line, then want to compare two \
                  \processes' "
                    <> c "RES"
                    <> " values — but you can no longer tell which column is which. What went \
                       \wrong, and what is the fast way out?"
                , do
                    p_ $ do
                        "The whole list scrolls sideways as one block, headings included. Scroll \
                        \far enough right and the heading row runs out of text entirely, leaving \
                        \you with columns of numbers and nothing to label them."
                    p_ $ do
                        k "Ctrl-A"
                        " (or "
                        k "^"
                        ") snaps back to the start of the line in one keystroke. The better move \
                        \for reading a long command line is not to scroll at all: Day 7's "
                        k "w"
                        " opens the selected process's command wrapped across a whole screen, with \
                        \the list left where it was."
                )
            ,
                ( "The manual page's "
                    <> c "COLUMNS"
                    <> " section says a traced or suspended process shows "
                    <> c "T"
                    <> ", but htop's own help screen says "
                    <> c "t"
                    <> ". Which will you see, and does it matter?"
                , do
                    p_ $ do
                        "The two disagree because they were written at different times, and this \
                        \course follows the binary: htop's built-in help ("
                        k "F1"
                        ") is generated from the same source as the display. Press "
                        k "Ctrl-Z"
                        " on something in another terminal and read the letter yourself — that is \
                        \the only authority worth having."
                    p_ $ do
                        "It matters in exactly one situation, which is the one where you will meet \
                        \it: you are grepping or eyeballing for stopped processes at two in the \
                        \morning, and you search for the wrong letter and conclude there are none."
                )
            ,
                ( "Two rows show the same command line and nearly identical memory numbers, but \
                  \one has a much larger "
                    <> c "PID"
                    <> " and almost no "
                    <> c "TIME+"
                    <> ". Are you looking at two copies of a program?"
                , do
                    p_ $ do
                        "Probably not — you are most likely looking at a process and one of its "
                        i_ "threads"
                        ". htop shows userland threads as rows by default, and a thread inherits \
                        \its process's command line, so they are near-indistinguishable in the \
                        \default column set."
                    p_ $ do
                        "Two ways to settle it. Press "
                        k "m"
                        ": merged mode shows the thread's own name joined to the command line, so \
                        \a thread reads "
                        c "KMS thread│gnome-shell"
                        " rather than "
                        c "gnome-shell"
                        ". Or add the "
                        opt "TGID"
                        " column (Day 10) — a thread's "
                        opt "TGID"
                        " is its process's PID, and for a process "
                        opt "TGID"
                        " equals "
                        opt "PID"
                        "."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d2diagram :: Diagram
d2diagram =
    ( diagram
        "Where the Command column comes from: a task has an argument vector, a comm string and \
        \an exe path, and the Command column shows the argument vector, optionally merging in the \
        \other two; a kernel thread has an empty argument vector, which is how htop tells it \
        \apart."
        body'
    )
        { dgCaption = do
            "The "
            c "Command"
            " column is not a field the kernel hands over — it is assembled, and "
            k "m"
            " and "
            k "p"
            " change the recipe. Notice that the three sources can disagree: a process can be \
            \renamed in its own argument vector while "
            c "comm"
            " and "
            c "exe"
            " still say what it really is, which is exactly how a process hides. Follow the dashed \
            \aspect at the bottom for the other consequence: an empty argument vector is what \
            \makes something a kernel thread to htop, and those are the rows drawn in bold grey."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  task  [label=\"a task\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  col   [label=\"the Command column\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  cmdl  [label=\"an argument vector\\n(/proc/[pid]/cmdline)\"];\n\
        \  comm  [label=\"a comm string\\n(/proc/[pid]/comm)\"];\n\
        \  exe   [label=\"an exe path\\n(/proc/[pid]/exe)\"];\n\
        \  kth   [label=\"a kernel thread\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  task -> cmdl [label=\"  was started with\"];\n\
        \  task -> comm [label=\"  is named by\"];\n\
        \  task -> exe  [label=\"  runs the binary at\"];\n\
        \  col  -> cmdl [label=\"  shows\"];\n\
        \  col  -> comm [label=\"merges in  \", style=dashed, constraint=false];\n\
        \  col  -> exe  [label=\"  merges in\", style=dashed, constraint=false];\n\
        \  kth  -> task [label=\"  is\"];\n\
        \  kth  -> cmdl [label=\"has an empty  \", style=dashed, constraint=false];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "The screen is a window onto a much longer list" $ do
        p_ [class_ "lede"] $ do
            "Your terminal shows perhaps forty rows. A desktop Linux machine has two or three \
            \thousand tasks. Almost everything htop knows is off-screen at any moment, so the \
            \first skill is not reading — it is "
            b_ "getting to the row you want"
            " without losing your place."
        p_ $ do
            "Two things move independently, and confusing them is the commonest source of “htop \
            \just jumped on me”. The "
            b_ "selection"
            " is the highlighted row, and it is what every action key operates on. The "
            b_ "view"
            " is which slice of the list is painted. Arrow keys move the selection and drag the \
            \view along behind it; the panning keys move the view and leave the selection alone."
        defs
            [ (k "Up" <> " " <> k "Down" <> " / " <> k "Alt-k" <> " " <> k "Alt-j", "One row. The Alt forms exist so you can navigate without leaving the home row.")
            , (k "PgUp" <> " " <> k "PgDn", "One screenful.")
            , (k "Home" <> " " <> k "End", "First and last process. " <> k "End" <> " is the honest way to see how long the list really is.")
            , (k "Alt-Up" <> " " <> k "Alt-Down", "Pan the view, selection untouched.")
            ]
        gotcha $ p_ $ do
            "The manual page lists "
            k "Shift-Up"
            " and "
            k "Shift-Down"
            " for panning and then warns you, correctly, that terminal emulators usually grab \
            \those for their own scrollback. You press them, your terminal scrolls its buffer, \
            \htop never sees a thing, and it looks like a broken key. The "
            k "Alt-Up"
            " and "
            k "Alt-Down"
            " forms do the same job and survive; prefer them and save yourself rebinding your \
            \terminal."
        fig

    block "Sideways is a direction too" $ do
        p_ $ do
            "Command lines are long — a Chrome renderer's runs to several hundred characters — so \
            \htop scrolls horizontally as well. "
            k "Left"
            " and "
            k "Right"
            " (or "
            k "Alt-h"
            " and "
            k "Alt-l"
            ") move the whole list sideways as a block, heading row included."
        p_ $ do
            "Because the heading row scrolls too, going far enough right leaves you looking at \
            \unlabelled columns of numbers. "
            k "Ctrl-A"
            " (or "
            k "^"
            ") jumps back to the start of the line and "
            k "Ctrl-E"
            " (or "
            k "$"
            ") jumps to the end of the selected process's entry — the "
            c "readline"
            " keys, chosen deliberately so you already know them."
        tip $ p_ $ do
            "Horizontal scrolling is the wrong tool for reading one long command line. Day 7's "
            k "w"
            " opens the selected process's command wrapped across its own screen, and leaves your \
            \list position alone. Scroll sideways when you want to see a "
            i_ "column"
            " that is off the right edge; use "
            k "w"
            " when you want to read a "
            i_ "command"
            "."

    block "The twelve columns you get for free" $ do
        p_ $ do
            "A fresh htop shows these, in this order. Three of them are about memory and get a day \
            \of their own tomorrow, because they are the ones everybody misreads."
        defs
            [ (c "PID", "The task's id. For a thread this is the thread id, not the process id.")
            , (c "USER", "Owner. Truncated to ten characters, so " <> c "systemd-resolve" <> " appears as " <> c "systemd-re" <> ".")
            , (c "PRI", "The kernel's internal priority — normally nice + 20. " <> c "RT" <> " means a real-time process.")
            , (c "NI", "Nice value, −20 (greedy) to 19 (generous). Day 6 changes it.")
            , (c "VIRT" <> " " <> c "RES" <> " " <> c "PRIV", "Memory. Tomorrow. Do not add these up across processes today.")
            , (c "S", "State. The single most information-dense character on the screen; see below.")
            , (c "CPU%", "Share of one core over the last sample. A rate, not a fact.")
            , (c "MEM%", "Resident memory as a share of total RAM. Derived from " <> c "RES" <> ".")
            , (c "TIME+", "Cumulative CPU time since the process started. A total, not a rate.")
            , (c "Command", "Assembled, not read. The rest of this lesson is about how.")
            ]
        note $ p_ $ do
            "If you have used htop before and are looking for "
            c "SHR"
            ", it is not in the default set any more. htop 3 ships "
            opt "M_PRIV"
            " ("
            c "PRIV"
            ", resident minus shared) in that slot instead, which is the more useful of the two \
            \for the question “how much memory would I get back by killing this”. Day 10 puts "
            c "SHR"
            " back if you want it."

    block "Seven letters in the S column" $ do
        p_ "Most rows say S. The interesting ones never do."
        defs
            [ (c "S", "Sleeping — waiting on something. The normal state of almost everything.")
            , (c "I", "Idle. A kernel thread with nothing to do, split out from " <> c "S" <> " so it stops cluttering your attention.")
            , (c "R", "Running or runnable. Count these against your core count; the header's " <> c "running" <> " figure is exactly this.")
            , (c "D", "Uninterruptible sleep, essentially always disk or network I/O. A process in " <> c "D" <> " cannot be killed, which is Day 6's most annoying lesson.")
            , (c "Z", "Zombie — exited, but its parent has not collected the exit status. Costs a process-table slot and nothing else.")
            , (c "T", "Traced or stopped. Under a debugger, or suspended with " <> k "Ctrl-Z" <> ".")
            , (c "W", "Paging. You will not see this on modern Linux.")
            ]
        gotcha $ p_ $ do
            "The manual page and htop's own help disagree here. "
            c "COLUMNS"
            " says “"
            c "T"
            " for traced or suspended”; the "
            k "F1"
            " help screen says “"
            c "t"
            ": traced/stopped”. This course follows the binary and its help screen. Check it on \
            \your own machine in ten seconds: suspend something with "
            k "Ctrl-Z"
            " in another terminal and read the letter."
        why $ p_ $ do
            "Splitting "
            c "I"
            " out of "
            c "S"
            " looks like pedantry and is not. Kernel threads spend their lives asleep, so under \
            \the old scheme a hundred rows of "
            c "S"
            " told you nothing. Making idleness its own letter means "
            i_ "every remaining"
            " "
            c "S"
            " is a process that is genuinely waiting for something — a reply, a lock, a timer — \
            \and is therefore worth asking a question about."

    block "Command is a reconstruction" $ do
        p_ $ do
            "The kernel offers three different answers to “what is this process”, and they can all \
            \disagree:"
        defs
            [ (c "/proc/[pid]/cmdline", "The argument vector, as the process last set it. A process may rewrite this, and some deliberately do.")
            , (c "/proc/[pid]/comm", "A short name, 15 characters, settable per-thread. This is where thread names live.")
            , (c "/proc/[pid]/exe", "A symlink to the binary actually executing. The hardest of the three to lie about, and the one that needs privilege to read for other users' processes.")
            ]
        p_ $ do
            "By default "
            c "Command"
            " shows the argument vector. Two keys change that:"
        sh
            [ "p    # full paths off:  /usr/lib/systemd/systemd-journald  ->  systemd-journald"
            , "m    # merge on:        claude  ->  JITWorker│claude   (heading becomes 'Command (merged)')"
            ]
        p_ $ do
            "With "
            k "m"
            " active htop splices "
            c "comm"
            " and the "
            c "exe"
            " basename into the line, separated by a vertical bar, and the heading changes to "
            c "Command (merged)"
            " so you can tell at a glance which mode you are in. It is how you see thread names \
            \without adding a column."
        p_ $ do
            "The column is also colour-coded, and the colours are doing real work: "
            b_ "magenta"
            " for ordinary process names, "
            b_ "bold blue"
            " for userland thread names, "
            b_ "bold grey"
            " for kernel threads and anything with no command name at all. That last case is the \
            \tell — a kernel thread has an empty "
            c "cmdline"
            ", which is precisely how htop classifies it."
        note $ p_ $ do
            "The manual page notes that "
            c "Command"
            " “should be the last column in each screen”, and means it: it is the only \
            \variable-width column, so anything you put after it gets squeezed. When you start \
            \building your own screens on Day 11, put "
            c "Command"
            " last and everything will line up."

    block "Today's habit" $ do
        p_ $ do
            "Stop reaching for the mouse. For the next few days, every time you want a particular \
            \process, get to it with "
            k "End"
            ", "
            k "PgUp"
            " and the arrows. Tomorrow's lesson assumes you can park the selection on any row \
            \without thinking about it, and Day 4 replaces all of this with something faster \
            \anyway — but only once the navigation is reflex."
        p_ "Tomorrow: the three memory columns you skipped, and why adding any of them up gives the wrong answer."

cheat :: Html ()
cheat = do
    cfg
        [ "Up Down   Alt-k Alt-j    # move the SELECTION (view follows)"
        , "PgUp PgDn                # a screenful"
        , "Home End                 # first / last process in the list"
        , "Alt-Up Alt-Down          # pan the VIEW, selection stays put"
        , "                         #   (Shift-Up/Down too -- terminals often steal these)"
        , "Left Right  Alt-h Alt-l  # scroll sideways, headings included"
        , "Ctrl-A ^   Ctrl-E $      # start / end of the selected process's line"
        , "p                        # full program paths on/off"
        , "m                        # merge exe+comm+cmdline -> 'Command (merged)'"
        , ""
        , "S column:  S sleeping   I idle   R running   D uninterruptible I/O"
        , "           Z zombie     T traced/stopped     W paging (never, in practice)"
        ]
    p_ $ do
        "Default columns, left to right: "
        c "PID USER PRI NI VIRT RES PRIV S CPU% MEM% TIME+ Command"
        ". Note "
        c "PRIV"
        ", not "
        c "SHR"
        " — htop 3 changed the default. "
        c "CPU%"
        " is a rate over the last sample; "
        c "TIME+"
        " is a lifetime total."
