module Course.Day.D07 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 7
        , dayTitle = "Looking inside"
        , daySubtitle = "Six keys that open a whole screen about one process — and htop is a launcher for other people's tools."
        , dayMinutes = 30
        , dayLevel = "intermediate"
        , dayManRef = "INTERACTIVE COMMANDS"
        , dayTags = ["strace", "lsof", "environment"]
        , dayGoals =
            [ "go from a suspicious row to its open files, its syscalls or its environment in one keystroke"
            , "search and filter inside those screens with the keys you already know"
            , "read the three failure messages these screens produce, and know which are about privilege"
            ]
        , dayDiagram = Just d7diagram
        , dayBody = body
        , dayKeys =
            [ ("l", "List open files, by running " <> c "lsof" <> " against the selected process.")
            , ("s", "Trace system calls, by running " <> c "strace" <> " against it.")
            , ("e", "Show the process's environment. Not in the manual page.")
            , ("w", "Show the command line wrapped across the whole screen.")
            , ("x", "Show the process's active file locks.")
            , ("b", "Show a backtrace. Only if htop was compiled with it, which it usually was not.")
            , ("F5", "Refresh the open screen. " <> k "F3" <> " and " <> k "F4" <> " search and filter it.")
            , ("F8", "In the strace screen: toggle auto-scroll. " <> k "F9" <> " stops the trace.")
            ]
        , dayCmds = []
        , dayOpts = []
        , dayConfig = []
        , dayDrills =
            [ "Select any process of your own and press "
                <> k "l"
                <> ". You are looking at "
                <> c "lsof"
                <> " output for one PID, without having had to find the PID."
            , "In that screen press "
                <> k "F4"
                <> " and filter for "
                <> c ".so"
                <> ". Same filter key, same semantics as Day 4 — these screens are not a separate \
                   \universe."
            , "Press "
                <> k "Esc"
                <> " to come back, then press "
                <> k "e"
                <> " on the same process. Read its environment. Notice how much of it you did not \
                   \know was there."
            , "Break something on purpose: press "
                <> k "e"
                <> " on a process owned by root. "
                <> c "Could not read process environment."
                <> " That is a permission boundary, not a bug — and it is the same boundary that \
                   \makes Day 3's "
                <> c "PSS"
                <> " column read zero."
            , "Press "
                <> k "s"
                <> " on something of your own. If "
                <> c "strace"
                <> " is not installed you will get "
                <> c "Could not execute 'strace'"
                <> " — htop opens the screen either way, because it cannot know until it tries."
            , "Find a process with a command line longer than your terminal is wide — a browser \
              \renderer, a Java service — and press "
                <> k "w"
                <> ". Compare that with Day 2's approach of scrolling sideways with "
                <> k "Right"
                <> " and decide which you will use from now on."
            , "Press "
                <> k "b"
                <> " on anything. Most likely nothing happens at all, because backtrace support is \
                   \a compile-time option most distributions leave off. Knowing which keys your \
                   \build does not have is worth ten seconds."
            , "On your own machine: next time a service will not start, go to its process in htop \
              \and press "
                <> k "e"
                <> " before you read any logs. A surprising share of “works on my machine” is one \
                   \missing environment variable, visible in two keystrokes."
            ]
        , dayQuiz =
            [
                ( "A deployment works from your shell and fails under systemd. The service is \
                  \running. Which key do you press first, and why that one?"
                , do
                    p_ $ do
                        k "e"
                        ". The overwhelmingly common cause is environment: a "
                        c "PATH"
                        " that does not include "
                        c "/usr/local/bin"
                        ", a missing "
                        c "HOME"
                        ", a proxy variable your shell exports from a dotfile that systemd never \
                        \reads, locale settings that change how a program parses numbers."
                    p_ $ do
                        "It is the right first move because it is "
                        i_ "cheap and conclusive"
                        ": two keystrokes, no privileges beyond owning the process, and you are \
                        \looking at exactly what the process actually got rather than at what a \
                        \unit file says it should have got. The manual page does not mention "
                        k "e"
                        " at all; htop's own help screen does."
                )
            ,
                ( "You press "
                    <> k "s"
                    <> " to trace a process and get "
                    <> c "Could not execute 'strace'. Please make sure it is available in your \
                       \$PATH."
                    <> " But the screen opened anyway. Why did htop not just grey the key out?"
                , do
                    p_ $ do
                        "Because htop has no way to know until it tries. It does not scan your "
                        c "$PATH"
                        " at startup looking for optional helpers — it shells out when you ask, and \
                        \reports what happened. The screen opening is not a promise that the trace \
                        \worked."
                    p_ $ do
                        "This is the general shape of "
                        k "s"
                        " and "
                        k "l"
                        ": htop is a "
                        i_ "launcher"
                        " for tools it does not contain. The upside is that you get the real "
                        c "strace"
                        " and the real "
                        c "lsof"
                        ", with their real output, rather than htop's approximation. The downside \
                        \is that two of the keys on this page do nothing on a minimal container."
                )
            ,
                ( "You attach strace to a busy process with "
                    <> k "s"
                    <> ", the screen scrolls too fast to read, and you want to look at one line. \
                       \What are your two options and what does each cost?"
                , do
                    p_ $ do
                        k "F8"
                        " toggles auto-scroll: the trace keeps running and keeps being collected, \
                        \but the view stops chasing the bottom, so you can read and scroll. Nothing \
                        \is lost."
                    p_ $ do
                        k "F9"
                        " stops tracing altogether. That detaches "
                        c "strace"
                        " from the process — which also removes the considerable slowdown that \
                        \being traced imposes. On a latency-sensitive service that slowdown is the \
                        \real cost of this whole screen, and it is the reason to press "
                        k "F9"
                        " rather than leaving the trace attached while you think."
                )
            ,
                ( "What do the file-locks screen ("
                    <> k "x"
                    <> ") and the open-files screen ("
                    <> k "l"
                    <> ") tell you that the process list cannot?"
                , do
                    p_ $ do
                        "Both answer “what is this process "
                        i_ "waiting for"
                        "”, which no column can. A process sitting in "
                        c "D"
                        " state with zero CPU% is completely opaque from the list — the row tells \
                        \you it is stuck and nothing about why."
                    p_ $ do
                        k "l"
                        " shows the file descriptors, so you can see it is blocked on an NFS mount \
                        \or a socket to a service that is down. "
                        k "x"
                        " shows the locks it holds and wants, which is how you find the other \
                        \process holding the one it needs — the classic two-processes-and-a-lockfile \
                        \deadlock that looks like a hang."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d7diagram :: Diagram
d7diagram =
    ( diagram
        "The inspection keys open an auxiliary screen about the selected process; some of those \
        \screens are filled by htop itself from /proc, and others by running an external tool such \
        \as strace or lsof, which may not be installed."
        body'
    )
        { dgCaption = do
            "Every one of these keys does the same thing — opens an auxiliary screen about the \
            \selected process, searchable and filterable with the "
            k "F3"
            " and "
            k "F4"
            " you already know. What differs is where the content comes from, and that is what \
            \determines how they fail. A screen htop fills from "
            c "/proc"
            " fails on "
            i_ "permission"
            "; a screen filled by an external tool fails on "
            i_ "the tool not being installed"
            ". Knowing which is which turns two confusing error messages into two obvious ones."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  sel   [label=\"the selected process\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  aux   [label=\"an auxiliary screen\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  procfs[label=\"a /proc file\"];\n\
        \  ext   [label=\"an external tool\\n(strace, lsof)\", fillcolor=\"#f4efe6\"];\n\
        \  priv  [label=\"a privilege you\\nmay not have\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  aux -> sel    [label=\"  is about\"];\n\
        \  aux -> procfs [label=\"  may be filled from\"];\n\
        \  aux -> ext    [label=\"  may be filled by running\"];\n\
        \  procfs-> sel  [label=\"  belongs to\"];\n\
        \  procfs-> priv [label=\"is gated by  \", style=dashed, constraint=false];\n\
        \  ext -> priv   [label=\"  is gated by\", style=dashed, constraint=false];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "One row is not much to go on" $ do
        p_ [class_ "lede"] $ do
            "A row tells you a process exists, how much it is using and what state it is in. It \
            \cannot tell you "
            b_ "what it is waiting for"
            ", which is the question you actually have when something is wrong. Six keys open a \
            \whole screen about the selected process to answer exactly that."
        p_ $ do
            "They all behave the same way, which is the thing worth learning once rather than six \
            \times. Each opens an auxiliary screen with a common function bar: "
            k "F3"
            " searches it, "
            k "F4"
            " filters it, "
            k "F5"
            " refreshes it, "
            k "Esc"
            " returns you to the list with your selection and scroll position intact."
        fig
        why $ p_ $ do
            "Two of these keys do not implement anything — they run "
            c "strace"
            " and "
            c "lsof"
            " and show you the output. That is a deliberate and slightly unusual choice for a \
            \curses tool, and it is the right one: you get the real tool's real output, with its \
            \own flags and its own accuracy, instead of htop's reimplementation drifting out of \
            \date. The price is that htop cannot promise those two keys will work, and it does not \
            \pretend to."

    block "The six keys" $ do
        defs
            [
                ( k "l" <> " — open files"
                , do
                    "Runs "
                    c "lsof"
                    " against the one PID. File descriptors, memory-mapped libraries, sockets, the \
                    \current directory. The fastest way to find out which config file a daemon \
                    \actually read."
                )
            ,
                ( k "s" <> " — trace syscalls"
                , do
                    "Attaches "
                    c "strace"
                    ". Live, scrolling, and it slows the traced process down substantially. "
                    k "F8"
                    " pauses the scrolling without detaching; "
                    k "F9"
                    " stops the trace."
                )
            ,
                ( k "e" <> " — environment"
                , do
                    "Reads "
                    c "/proc/[pid]/environ"
                    " directly. No external tool, no slowdown. Not mentioned anywhere in the \
                    \manual page."
                )
            ,
                ( k "w" <> " — wrapped command"
                , "The full command line, wrapped across the whole screen instead of running off the right edge. Use this instead of scrolling sideways."
                )
            ,
                ( k "x" <> " — file locks"
                , "The locks this process holds and is waiting for. The tool for a hang that is really a lock contention."
                )
            ,
                ( k "b" <> " — backtrace"
                , "A stack trace, if htop was compiled with support. Most distribution builds were not, and the key silently does nothing."
                )
            ]
        termWin
            "htop — l (open files)"
            [ "  mem REG            0x22                   55683489  /nix/store/zz125vwahb\8230"
            , "  mem REG            0x22                   55756459  /usr/lib/locale/local\8230"
            , "  rtd DIR            0x25      176               256  /"
            , "  txt REG            0x25   492000          57209935  /nix/store/9vbrbnpqbw\8230"
            , ""
            , "F3Search F4Filter F5RefreshEscDone"
            ]

    block "Three ways this fails, and they mean different things" $ do
        p_ "Each of these is a complete sentence about your machine, so read it rather than dismissing it."
        sh
            [ "Could not execute 'strace'. Please make sure it is available in your $PATH."
            , "    -> the tool is not installed. Install it, or use a machine where it is."
            , ""
            , "Could not read process environment."
            , "    -> a permission boundary. You do not own that process. Try under sudo."
            , ""
            , "(nothing happens at all, on b)"
            , "    -> your htop was built without that feature. No amount of privilege helps."
            ]
        gotcha $ p_ $ do
            "The permission wall here is the same one from Day 3. "
            c "/proc/[pid]/environ"
            ", "
            c "/proc/[pid]/smaps_rollup"
            " and the "
            c "EXE"
            " column all need you to own the process or to hold "
            c "CAP_SYS_PTRACE"
            ". If one of them is refusing you, they all are, and the fix is the same: run htop \
            \under "
            c "sudo"
            " for that question and quit it again afterwards."

    block "A note on reading someone else's environment" $ do
        p_ $ do
            "Process environments routinely contain credentials — database URLs with passwords in \
            \them, API tokens, cloud keys. "
            k "e"
            " on a process you own is looking at your own secrets; "
            k "e"
            " under "
            c "sudo"
            " on a shared machine is looking at everybody's."
        p_ $ do
            "That is worth knowing in both directions. As a debugging tool it is excellent and you \
            \should reach for it. As a thing you do on a production box with a colleague watching \
            \your screen share, think first — and remember that it is also the reason "
            c "/proc/[pid]/environ"
            " is permission-gated in the first place."

    block "Today's habit" $ do
        p_ $ do
            "Next time something is stuck, resist the urge to go straight to the logs. Find the \
            \process, press "
            k "l"
            ", and look at what it has open. Logs tell you what a program decided to say about \
            \itself; file descriptors tell you what it is actually doing. The second is often \
            \faster and always harder to argue with."
        p_ "Tomorrow: the top of the screen — what the CPU bar's coloured segments mean, and the thirty-odd meters you can put up there instead."

cheat :: Html ()
cheat = do
    cfg
        [ "l    open files      -- runs lsof on the selected PID"
        , "s    trace syscalls  -- runs strace; F8 pause scrolling, F9 stop tracing"
        , "e    environment     -- reads /proc/[pid]/environ   [not in man]"
        , "w    wrapped command -- the full cmdline, no sideways scrolling"
        , "x    file locks      -- held and waited-for; for hangs that are lock contention"
        , "b    backtrace       -- compile-time option; usually absent, fails silently"
        , ""
        , "in EVERY one of these screens:  F3 search   F4 filter   F5 refresh   Esc back"
        , ""
        , "\"Could not execute 'strace'\"      -> tool not installed"
        , "\"Could not read process environment\" -> not your process; try sudo"
        , "nothing happens at all              -> not compiled in"
        ]
    p_ $ do
        "Process environments often hold credentials. "
        k "e"
        " is an excellent debugging tool and a poor thing to do on a shared screen."
