module Course.Day.D12 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 12
        , dayTitle = "I/O and delays"
        , daySubtitle = "Bytes through the syscall, bytes off the disk, and the columns that say why a process is waiting."
        , dayMinutes = 35
        , dayLevel = "advanced"
        , dayManRef = "COLUMNS, EXTERNAL LIBRARIES"
        , dayTags = ["I/O", "delay accounting", "PSI"]
        , dayGoals =
            [ "tell RCHAR from RBYTES from DISK READ, and pick the one that answers your question"
            , "read the I/O priority column, and change it"
            , "explain an N/A in the delay columns, and know what to use instead"
            ]
        , dayDiagram = Just d12diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds = []
        , dayOpts =
            [ ("RCHAR", "Bytes the process has read through " <> c "read()" <> ". Counts cache hits — most of this never touched a disk.")
            , ("WCHAR", "Bytes written through " <> c "write()" <> ". Counted when the call returns, not when the data lands.")
            , ("RBYTES", "Bytes actually fetched from the block layer. Real disk reads.")
            , ("WBYTES", "Bytes actually sent to the block layer.")
            , ("CNCLWB", "Write bytes cancelled — dirtied, then truncated or deleted before writeback.")
            , ("IO_READ_RATE", "Block-layer read rate. Shown as " <> c "DISK READ" <> ".")
            , ("IO_WRITE_RATE", "Block-layer write rate. Shown as " <> c "DISK WRITE" <> ".")
            , ("IO_RATE", "The two rates added. Shown as " <> c "DISK R/W" <> ", and the right default sort for an I/O screen.")
            , ("IO_PRIORITY", "Scheduling class and priority: " <> c "R" <> " realtime, " <> c "B" <> " best-effort, " <> c "id" <> " idle.")
            , ("PERCENT_IO_DELAY", "Share of time blocked on synchronous block I/O. Needs delay accounting.")
            , ("PERCENT_CPU_DELAY", "Share of time runnable but not scheduled. The number that proves CPU contention.")
            , ("PERCENT_SWAP_DELAY", "Share of time waiting for pages to swap back in.")
            ]
        , dayConfig =
            [ ConfBlock
                "Replace the shipped I/O screen with one that leads with rates rather than totals.\n\
                \Totals since boot answer 'has this process ever done I/O'; rates answer 'is it\n\
                \doing I/O now', which is the question you have during an incident. RCHAR sits at\n\
                \the end so the gap between it and the block-layer numbers stays visible -- that\n\
                \gap is the page cache doing its job."
                "screen:I/O=PID USER IO_PRIORITY IO_READ_RATE IO_WRITE_RATE IO_RATE PERCENT_IO_DELAY RCHAR Command\n\
                \.sort_key=IO_RATE\n\
                \.sort_direction=-1"
            ]
        , dayDrills =
            [ "Press "
                <> k "Tab"
                <> " to the I/O screen and sort by "
                <> c "DISK R/W"
                <> ". On an idle machine almost every row is "
                <> c "0.00 B/s"
                <> ", which is itself worth seeing — most processes do no I/O at all, most of the \
                   \time."
            , "Run "
                <> c "cat /some/large/file > /dev/null"
                <> " twice in a row while watching. The first run shows "
                <> c "DISK READ"
                <> "; the second shows almost none, because the file is now in page cache. "
                <> c "RCHAR"
                <> " climbs both times."
            , "That is the whole lesson of "
                <> c "RCHAR"
                <> " versus "
                <> c "RBYTES"
                <> ", so make sure you saw it. One counts what the program asked for; the other \
                   \counts what the disk had to provide."
            , "Find the "
                <> c "IO"
                <> " column and read its value for a few processes. Most will be "
                <> c "B4"
                <> " — best-effort, priority 4, derived from a nice value of 0."
            , "Select a process of your own, press "
                <> k "i"
                <> ", and set it to "
                <> c "Idle"
                <> ". Watch the "
                <> c "IO"
                <> " column change to "
                <> c "id"
                <> ". You have just told the kernel this process only gets disk when nobody else \
                   \wants it."
            , "Break something on purpose: look at "
                <> c "IOD%"
                <> " and friends. If they read "
                <> c "N/A"
                <> " on every row — as they do on most distribution builds — you have found the \
                   \limit of this screen, and the rest of today explains what to use instead."
            , "Add a Pressure Stall Information meter to your header (Setup → Meters → "
                <> c "Pressure Stall Information, some io"
                <> "). It answers the same question as the delay columns, machine-wide, and it \
                   \works without special privileges."
            , "On your own machine: find the process with the highest "
                <> c "DISK WRITE"
                <> " and decide whether it should be. Backups, log shippers and indexers are the \
                   \usual answers; anything else is worth a question."
            ]
        , dayQuiz =
            [
                ( "A process shows 4 GB of "
                    <> c "RCHAR"
                    <> " and 12 MB of "
                    <> c "RBYTES"
                    <> ". Is it hammering the disk?"
                , do
                    p_ $ do
                        "No — it is being served almost entirely by the page cache, which is the \
                        \system working exactly as designed. "
                        opt "RCHAR"
                        " counts bytes the process asked for through "
                        c "read()"
                        "; "
                        opt "RBYTES"
                        " counts bytes the block layer actually had to fetch. The 4 GB gap is \
                        \memory, not disk."
                    p_ $ do
                        "Reverse the numbers and you have a problem: "
                        opt "RBYTES"
                        " approaching "
                        opt "RCHAR"
                        " means every read is missing cache and going to the device, which is what \
                        \a working set larger than RAM looks like. The ratio between these two \
                        \columns is more informative than either one alone, which is why an I/O \
                        \screen should carry both."
                )
            ,
                ( "Every delay column reads "
                    <> c "N/A"
                    <> " on your machine. Whose fault is it and what do you do instead?"
                , do
                    p_ $ do
                        "Nobody's, usually. The delay-accounting columns need two things: htop \
                        \built with "
                        c "--enable-delayacct"
                        ", which links against "
                        c "libnl-3"
                        " and "
                        c "libnl-genl-3"
                        ", and the "
                        c "CAP_NET_ADMIN"
                        " capability at runtime — the kernel exposes delay accounting over a \
                        \netlink socket, which is why a memory statistic needs a networking \
                        \privilege. Most distribution builds skip the flag."
                    p_ $ do
                        "The substitute is better than it sounds: the "
                        b_ "Pressure Stall Information"
                        " meters from Day 8. PSI answers “is anything on this machine waiting on \
                        \CPU, I/O or memory, and how much”, needs no capability, and is \
                        \machine-wide rather than per-process. You lose the ability to attribute \
                        \the stall to one process and keep the ability to detect it at all."
                )
            ,
                ( "Two processes each show "
                    <> c "0.0"
                    <> " in "
                    <> c "CPU%"
                    <> " and the machine is loaded. One has a high "
                    <> c "CPUD%"
                    <> " and the other a high "
                    <> c "IOD%"
                    <> ". What is different about them?"
                , do
                    p_ $ do
                        "Both are waiting, for entirely different reasons, and neither shows up in "
                        c "CPU%"
                        " because waiting is not running. High "
                        opt "PERCENT_CPU_DELAY"
                        " means "
                        i_ "runnable but not scheduled"
                        " — it is ready to work and the scheduler has not given it a core. That is \
                        \CPU contention, and the fix is fewer competing processes or a nice value."
                    p_ $ do
                        "High "
                        opt "PERCENT_IO_DELAY"
                        " means blocked on synchronous block I/O — it is in Day 2's "
                        c "D"
                        " state, waiting for a device. No amount of CPU will help; the fix is at \
                        \the storage layer. These two columns are the difference between “buy more \
                        \CPU” and “buy faster disks”, which is why they are worth the trouble of \
                        \getting them working."
                )
            ,
                ( "Why does htop offer both "
                    <> c "WCHAR"
                    <> " and "
                    <> c "CNCLWB"
                    <> ", and what does a large "
                    <> c "CNCLWB"
                    <> " tell you?"
                , do
                    p_ $ do
                        opt "WCHAR"
                        " counts bytes handed to "
                        c "write()"
                        ", which returns as soon as the data is in the page cache. "
                        opt "CNCLWB"
                        " counts bytes that were dirtied and then "
                        i_ "never written out"
                        " — because the file was truncated or deleted before writeback happened."
                    p_ $ do
                        "A large "
                        c "CNCLWB"
                        " is the signature of a program churning temporary files: write, use, \
                        \delete, repeat. That is not necessarily wrong — compilers and build \
                        \systems do it constantly — but it means the process's apparent write \
                        \volume overstates what the disk ever had to do, and it is a hint that a "
                        c "tmpfs"
                        " might remove the I/O entirely."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d12diagram :: Diagram
d12diagram =
    ( diagram
        "A read() call is counted by RCHAR and served from the page cache; only a cache miss \
        \reaches the block layer and is counted by RBYTES, and the time spent waiting for that is \
        \what the delay-accounting columns measure."
        body'
    )
        { dgCaption = do
            "Two columns count the same read at two different depths, and the distance between \
            \them is the page cache. "
            c "RCHAR"
            " is what the program asked for; "
            c "RBYTES"
            " is what the device had to supply. A large gap means caching is working; no gap means \
            \your working set does not fit in RAM. The dashed aspect is the part most builds cannot \
            \show you: attributing the "
            i_ "waiting"
            " to a process needs delay accounting, and without it you fall back to the machine-wide \
            \PSI meters."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  call  [label=\"a read() call\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  cache [label=\"the page cache\"];\n\
        \  blk   [label=\"a block-layer request\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  dev   [label=\"the storage device\", fillcolor=\"#f4efe6\"];\n\
        \  rchar [label=\"the RCHAR column\"];\n\
        \  rbyte [label=\"the RBYTES column\"];\n\
        \  wait  [label=\"time spent waiting\"];\n\
        \  dacct [label=\"delay accounting\\n(often not built in)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  call  -> cache [label=\"  is served from\"];\n\
        \  cache -> blk   [label=\"  falls back, on a miss, to\"];\n\
        \  blk   -> dev   [label=\"  is answered by\"];\n\
        \  rchar -> call  [label=\"  counts the bytes of\"];\n\
        \  rbyte -> blk   [label=\"  counts the bytes of\"];\n\
        \  wait  -> blk   [label=\"  is spent on\"];\n\
        \  wait  -> dacct [label=\"is only visible through  \", style=dashed, constraint=false];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Three ways to count a read" $ do
        p_ [class_ "lede"] $ do
            "htop offers three families of I/O column and they measure at three different depths. \
            \Confusing them produces confident, wrong conclusions — most often “this process is \
            \hammering the disk” about a process that has not touched a disk in an hour."
        defs
            [ (opt "RCHAR" <> " / " <> opt "WCHAR", do "Bytes through " ; c "read()" ; " and " ; c "write()" ; ". What the program asked for. Cache hits count; a " ; c "write()" ; " counts the moment it returns, long before anything reaches a disk.")
            , (opt "RBYTES" <> " / " <> opt "WBYTES", "Bytes that actually reached the block layer. What the device had to do.")
            , (opt "IO_READ_RATE" <> " / " <> opt "IO_WRITE_RATE" <> " / " <> opt "IO_RATE", do "The same block-layer traffic as a rate, in bytes per second. Displayed as " ; c "DISK READ" ; ", " ; c "DISK WRITE" ; " and " ; c "DISK R/W" ; ".")
            ]
        p_ $ do
            "The gap between the first two is the page cache, and reading it is a skill. 4 GB of "
            c "RCHAR"
            " against 12 MB of "
            c "RBYTES"
            " is a healthy machine serving a program from memory. The same two numbers close \
            \together means every read is missing cache — a working set that does not fit in RAM, \
            \which is a capacity problem rather than an application one."
        fig
        why $ p_ $ do
            "Both exist because both are the truth, at different layers, and neither can be derived \
            \from the other. The kernel cannot know that a "
            c "read()"
            " will be served from cache until it looks, and a process cannot know whether its \
            \writes have been persisted. htop simply exposes both counters and leaves the inference \
            \to you — which is the right call, and the reason the columns look redundant until the \
            \day they disagree."
        note $ p_ $ do
            "There is a fourth counter for the same reason: "
            opt "CNCLWB"
            ", cancelled writeback. Bytes a process dirtied and then deleted or truncated before \
            \the kernel got round to writing them out. A build system generates enormous amounts \
            \of it, and it means the disk never had to do the work — which is a strong hint that \
            \the whole directory might belong on a "
            c "tmpfs"
            "."

    block "The I/O screen, and rates versus totals" $ do
        p_ $ do
            "htop ships an "
            c "I/O"
            " screen already configured, one "
            k "Tab"
            " away. Its default column set leads with "
            opt "IO_RATE"
            ", which is right: totals since boot answer “has this ever done I/O”, and during an \
            \incident the question is always “is it doing I/O "
            i_ "now"
            "”."
        termWin
            "htop — the I/O screen"
            [ "  PID USER       IO   DISK READ  DISK WRITE    DISK R/W\9661 IOD% SWPD% Command"
            , " 4795 jhrcek     B4    0.00 B/s    0.00 B/s    0.00 B/s   N/A   N/A gnome-keyring-daemon"
            , " 5012 jhrcek     B4    0.00 B/s    0.00 B/s    0.00 B/s   N/A   N/A gdm-wayland-session"
            , " 1869 root       B4    1.20 M/s  340.00 K/s    1.53 M/s   N/A   N/A dockerd"
            ]
        p_ $ do
            "The "
            c "IO"
            " column is "
            opt "IO_PRIORITY"
            ", and it packs a class and a number into three characters: "
            c "R"
            " for realtime, "
            c "B"
            " for best-effort, "
            c "id"
            " for idle. "
            c "B4"
            " — best-effort, priority 4 — is what almost everything shows, because that is what \
            \the kernel derives from a nice value of zero."
        tip $ p_ $ do
            "Day 6's "
            k "i"
            " key changes it, and for a background job it is usually the more effective knob. "
            k "F8"
            " gives away CPU, but a backup or an indexer is rarely short of CPU — it is saturating \
            \the disk queue and making every interactive read wait behind it. Setting it to "
            c "Idle"
            " means it gets the disk only when nothing else wants it, and the difference on a \
            \loaded machine is dramatic."

    block "Delay accounting: the columns that explain waiting" $ do
        p_ $ do
            "Three columns answer a question no other part of htop can: "
            b_ "why is this process not getting anything done?"
        defs
            [ (opt "PERCENT_CPU_DELAY" <> " (" <> c "CPUD%" <> ")", "Share of time the process was runnable but not running. Pure CPU contention — it is ready and the scheduler is busy elsewhere.")
            , (opt "PERCENT_IO_DELAY" <> " (" <> c "IOD%" <> ")", do "Share of time blocked on synchronous block I/O. This is Day 2's " ; c "D" ; " state, quantified.")
            , (opt "PERCENT_SWAP_DELAY" <> " (" <> c "SWAPD%" <> ")", "Share of time waiting for pages to be swapped back in. On a machine with swap in use, the most important number on the screen.")
            ]
        p_ $ do
            "Together they separate “needs more CPU” from “needs faster disks” from “needs more \
            \RAM”, which is normally an argument and here is a measurement."
        gotcha $ p_ $ do
            "On most machines all three read "
            c "N/A"
            ". They need htop built with "
            c "--enable-delayacct"
            " — which links "
            c "libnl-3"
            " and "
            c "libnl-genl-3"
            " — "
            i_ "and"
            " the "
            c "CAP_NET_ADMIN"
            " capability at runtime, because the kernel publishes delay accounting over a netlink \
            \socket. Most distribution builds leave the flag off. Note that "
            c "N/A"
            " is a third kind of empty, distinct from the "
            c "-"
            " the manual page documents for unsupported columns and the bare "
            c "0"
            " that Day 3's "
            c "PSS"
            " prints when it is refused permission."

    block "What to use when the delay columns are N/A" $ do
        p_ $ do
            "Pressure Stall Information, from Day 8's meter list. Five meters — "
            c "some cpu"
            ", "
            c "some io"
            ", "
            c "full io"
            ", "
            c "full irq"
            ", "
            c "some memory"
            " — reporting the share of time that "
            i_ "some"
            " task, or "
            i_ "every"
            " task, was stalled waiting for that resource."
        p_ $ do
            "PSI needs no capability and no build flag beyond a modern kernel. What you give up is \
            \attribution: it tells you the machine is stalling on I/O without telling you which \
            \process is responsible. In practice that is a smaller loss than it sounds, because \
            \once you know "
            i_ "what"
            " the machine is waiting on, the I/O rate columns will usually tell you "
            i_ "who"
            "."
        p_ $ do
            "The workflow is: PSI in the header to notice, the I/O screen's rate columns to \
            \attribute, and Day 7's "
            k "l"
            " to find out which file or socket is actually involved."

    block "Today's habit" $ do
        p_ $ do
            "Put a PSI meter in your header today and leave it there. Load average tells you how \
            \many things are queued, which has meant several different things over the years and \
            \is hard to interpret across machines. PSI tells you what fraction of wall-clock time \
            \something was stalled, which means one thing and is comparable between boxes."
        p_ "Tomorrow: cgroups and containers — reading the ten shortening rules that turn a hundred-character path into eight characters."

cheat :: Html ()
cheat = do
    cfg
        [ "RCHAR / WCHAR      bytes through read()/write()  -- cache hits COUNT"
        , "RBYTES / WBYTES    bytes that reached the block layer -- real disk"
        , "IO_READ_RATE       DISK READ    IO_WRITE_RATE  DISK WRITE"
        , "IO_RATE            DISK R/W     -- the right default sort for an I/O screen"
        , "CNCLWB             dirtied, then deleted before writeback (build systems)"
        , ""
        , "RCHAR >> RBYTES  ->  page cache is working"
        , "RCHAR ~= RBYTES  ->  working set does not fit in RAM"
        , ""
        , "IO column (IO_PRIORITY):  R realtime   B best-effort   id idle"
        , "  B4 is the default, derived from nice 0.   Day 6's 'i' key changes it."
        , ""
        , "CPUD%  runnable but not scheduled  -> CPU contention"
        , "IOD%   blocked on block I/O        -> storage"
        , "SWPD%  waiting on swap-in          -> memory"
        , "  all three N/A unless built --enable-delayacct AND you hold CAP_NET_ADMIN"
        , "  substitute: the Pressure Stall Information meters (no privilege needed)"
        ]
