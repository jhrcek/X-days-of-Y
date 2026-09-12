module Course.Day.D01 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 1
        , dayTitle = "The sampling model"
        , daySubtitle = "htop is a sampler, not a monitor — and that explains every number on the screen."
        , dayMinutes = 30
        , dayLevel = "essential"
        , dayManRef = "DESCRIPTION, COMMAND-LINE OPTIONS"
        , dayTags = ["/proc", "refresh", "CPU%"]
        , dayGoals =
            [ "say where every number on the screen came from, and how stale it is"
            , "set the refresh interval deliberately, and name the two values htop silently clamps it to"
            , "read a process at 780% CPU on an idle-looking machine without being surprised"
            ]
        , dayDiagram = Just d1diagram
        , dayBody = body
        , dayKeys =
            [ ("Ctrl-L", "Redraw the screen and recalculate, without waiting for the next tick.")
            , ("Z", "Pause and resume sampling. The screen freezes; the machine does not.")
            , ("F10 q", "Quit. This is also the only exit that saves your settings.")
            ]
        , dayCmds =
            [ ("htop", "Start htop, reading " <> c "~/.config/htop/htoprc" <> " once at startup.")
            , ("htop -d 10", "Sample every 10 tenths of a second. Clamped to the range 1–100.")
            , ("htop -n 5", "Draw five frames, then exit on its own. Absent from the manual page.")
            , ("htop -V", "Print the version. The " <> c "-v" <> " in the SYNOPSIS does not exist.")
            ]
        , dayOpts =
            [ ("delay", "Tenths of a second between samples in " <> c "htoprc" <> ". Default " <> c "15" <> ", i.e. 1.5 s.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Start "
                <> c "htop"
                <> " and find the boundary between the three regions: header meters on top, \
                   \process list in the middle, function bar on the last line. Say out loud which \
                   \region a number is in before you read it."
            , "Watch one row's "
                <> c "CPU%"
                <> " for thirty seconds without touching anything. Notice it never stops moving, \
                   \even for a process doing nothing — that is sampling noise, not work."
            , "Run "
                <> c "htop -d 1"
                <> " and then "
                <> c "htop -d 100"
                <> " side by side. The first is frantic and costs real CPU; the second is a \
                   \still photograph. Neither is more correct."
            , "Break it on purpose: run "
                <> c "htop -v"
                <> ", the version flag the manual page's SYNOPSIS promises. Read the error, then \
                   \run "
                <> c "htop -V"
                <> ". You have just found your first man-page bug, on Day 1."
            , "Run "
                <> c "htop -n 3"
                <> " and watch it exit by itself after three frames. Nothing in "
                <> c "man htop"
                <> " mentions this flag; "
                <> c "htop --help"
                <> " does."
            , "Press "
                <> k "Z"
                <> ". The clock in the header stops. Wait ten seconds, press "
                <> k "Z"
                <> " again, and watch the "
                <> c "TIME+"
                <> " column jump — the processes kept running the whole time."
            , "On your own machine: find the single busiest process right now, then run the same \
              \check with "
                <> c "htop -d 1"
                <> ". If the answer changes, you have learned something about how bursty that \
                   \workload is."
            , "Adopt the habit that makes the rest of the course work: leave htop running in a \
              \spare terminal or tmux window all day, and glance at it when something feels slow \
              \— not only when it already is."
            ]
        , dayQuiz =
            [
                ( "You run a build that spawns hundreds of short-lived compiler processes. The \
                  \machine is clearly working hard, the header CPU meters are pinned — yet the \
                  \process list looks almost empty and nothing in it has a high "
                    <> c "CPU%"
                    <> ". Where did the work go?"
                , do
                    p_ $ do
                        "Into processes that were born and died between two samples. At the \
                        \default 1.5 s a process that lives for 80 ms is simply never observed, so \
                        \it never gets a row. The list can only show you what existed at the \
                        \instant htop looked."
                    p_ $ do
                        "The header meters disagree because they have a different source. They are \
                        \built from the kernel's "
                        i_ "cumulative"
                        " counters, which count every tick of CPU time whether or not the process \
                        \that spent it still exists. So the meters see the whole build and the list \
                        \sees almost none of it. When those two disagree, believe the meters and \
                        \suspect process churn."
                )
            ,
                ( "htop shows one process at "
                    <> c "780%"
                    <> " CPU while the header meters are mostly idle bars. Is the number wrong?"
                , do
                    p_ $ do
                        "No. "
                        opt "PERCENT_CPU"
                        " is a share of "
                        i_ "one core"
                        ", so on a 32-core box it runs from 0 to 3200. 780% is 7.8 cores busy — \
                        \genuinely a lot of work, and genuinely about a quarter of this machine. \
                        \The manual page calls this Irix mode, after top(1)."
                    p_ $ do
                        "The other convention is on the same screen if you want it: add the "
                        opt "PERCENT_NORM_CPU"
                        " column ("
                        c "NCPU%"
                        ") and htop divides by the core count, so the same process reads 24.4%. \
                        \Neither is more honest; they answer different questions, and the mistake \
                        \is only ever reading one as if it were the other."
                )
            ,
                ( "You run "
                    <> c "htop -d 0"
                    <> " expecting a complaint and get none. What are you actually running at, and \
                       \why might you regret it next week?"
                , do
                    p_ $ do
                        "At "
                        c "delay=1"
                        " — one tenth of a second. htop clamps silently: anything below 1 becomes \
                        \1, anything above 100 becomes 100, and negative numbers become 1 as well. \
                        \You get no message either way."
                    p_ $ do
                        "The regret is that "
                        c "-d"
                        " is not a one-off override. If you change any setting during that session \
                        \and then quit cleanly, htop writes "
                        c "delay=1"
                        " into your "
                        c "htoprc"
                        ", and every htop you start afterwards samples ten times a second until you \
                        \notice. Day 9 covers how to stop htop editing your config behind you."
                )
            ,
                ( "The manual page's SYNOPSIS reads "
                    <> c "htop [-dCFhpustvH]"
                    <> ", yet "
                    <> c "htop -v"
                    <> " answers “invalid option”. What should you conclude?"
                , do
                    p_ $ do
                        "That the SYNOPSIS is stale, and that it is the wrong thing to trust. The \
                        \version flag is "
                        c "-V"
                        ". The same line also omits "
                        c "-n"
                        ", "
                        c "-M"
                        ", "
                        c "-U"
                        ", "
                        c "--readonly"
                        ", "
                        c "--no-meters"
                        " and "
                        c "--no-function-bar"
                        ", all of which the binary accepts."
                    p_ $ do
                        "The habit worth forming today: when the page and "
                        c "--help"
                        " disagree about a flag, the binary settles it, and it takes ten seconds to \
                        \ask. This course was written that way throughout — Day 14 collects every \
                        \place the two diverge."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d1diagram :: Diagram
d1diagram =
    ( diagram
        "How a number reaches the htop screen: the kernel publishes a /proc entry for each \
        \running process, htop reads it into a sample every delay tenths of a second, and a \
        \percentage on screen is computed from a pair of consecutive samples — which is why a \
        \process shorter than the interval is never seen at all."
        body'
    )
        { dgCaption = do
            "Nothing on the screen is a measurement of "
            i_ "now"
            ". A percentage is a rate reconstructed from two reads of "
            c "/proc"
            ", separated by "
            b_ "the refresh interval"
            " — 1.5 seconds unless you have said otherwise. Follow the dashed aspect: a process \
            \that lives and dies inside one interval never becomes a row, however much CPU it \
            \burned. That single gap explains most of the times htop seems to be lying to you."
        , dgRankdir = "TB"
        , dgRanksep = "0.42"
        }
  where
    body' =
        "  kern  [label=\"the kernel\", fillcolor=\"#f4efe6\"];\n\
        \  proc  [label=\"a running process\", fillcolor=\"#f4efe6\"];\n\
        \  entry [label=\"a /proc entry\"];\n\
        \  samp  [label=\"a sample\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  pair  [label=\"a pair of\\nconsecutive samples\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  ivl   [label=\"the refresh interval\"];\n\
        \  pct   [label=\"a percentage\\non screen\"];\n\
        \  row   [label=\"a row in the\\nprocess list\"];\n\
        \  brief [label=\"a process that lived\\nless than one interval\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  kern  -> entry [label=\"  publishes\"];\n\
        \  entry -> proc  [label=\"  describes\"];\n\
        \  samp  -> entry [label=\"  is one read of\"];\n\
        \  pair  -> samp  [label=\"  is made of\"];\n\
        \  pair  -> ivl   [label=\"  is separated by\"];\n\
        \  pct   -> pair  [label=\"  is computed from\"];\n\
        \  row   -> pct   [label=\"  displays\"];\n\
        \  row   -> proc  [label=\"  stands for\"];\n\
        \  pair  -> brief [label=\"never sees  \", style=dashed, constraint=false];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "A stopwatch, not a microscope" $ do
        p_ [class_ "lede"] $ do
            "htop does not watch your machine. It "
            b_ "wakes up on a timer, reads a pile of text files under "
            c "/proc"
            b_ ", subtracts the last reading from this one, and paints the difference."
            " Every surprising thing htop ever does to you follows from that, so it is worth ten \
            \minutes before you learn a single key."
        p_ $ do
            "The kernel does not maintain a live feed of process activity. It maintains counters \
            \— this process has accumulated so many clock ticks of user time, so many of system \
            \time, its resident set is currently so many pages — and exposes them as files under "
            c "/proc/[pid]/"
            ". Those counters only ever go up. They have no notion of “percent”."
        p_ $ do
            "So htop manufactures the percentages. It reads the counters, waits "
            opt "delay"
            " tenths of a second, reads them again, and divides the difference by the time that \
            \passed. "
            c "CPU%"
            " is not a property of a process that htop looked up; it is a rate that htop computed \
            \between two photographs."
        why $ p_ $ do
            "This is why htop has a refresh interval at all, and why the interval is a \
            \user-visible setting rather than an implementation detail. It is not a redraw rate \
            \for the benefit of your eyes — it is the "
            i_ "measurement window"
            ". Halve it and every percentage on screen becomes a different, noisier number about a \
            \shorter slice of time. There is no setting at which the numbers become exact, because \
            \there is nothing exact underneath to reach."
        fig

    block "Three regions, and they do not share a source" $ do
        p_ "Everything on screen belongs to exactly one of three bands. Name the band before you read the number."
        defs
            [
                ( "the header meters"
                , do
                    "The bars and readouts at the top. Built from machine-wide cumulative counters \
                    \— "
                    c "/proc/stat"
                    ", "
                    c "/proc/meminfo"
                    ", "
                    c "/proc/loadavg"
                    ". They account for all work, including work done by processes that have since \
                    \exited. Day 8 takes them apart."
                )
            ,
                ( "the process list"
                , do
                    "One row per process that existed when htop last looked. Built from "
                    c "/proc/[pid]/"
                    ". It can only describe processes that were alive at sampling time. Days 2 and \
                    \3 are spent here."
                )
            ,
                ( "the function bar"
                , do
                    "The last line. Not decoration — it is the live state of the interface. The \
                    \labels change to tell you what mode you are in, which is the fastest way to \
                    \answer “why is htop behaving oddly”."
                )
            ]
        termWin
            "htop"
            [ "    0[         0.0%]  8[||       9.1%]  16[         0.0%]  24[      0.0%]"
            , "    1[         0.0%]  9[||      10.0%]  17[         0.0%]  25[      0.0%]"
            , "  Mem[||||||||||||||||||||9.48G/61.9G] Tasks: 219, 2342 thr, 429 kthr"
            , "  Swp[                       0K/8.00G] Load average: 0.19 0.22 0.35"
            , "                                       Uptime: 03:16:22"
            , ""
            , "  PID USER       PRI  NI  VIRT   RES  PRIV S  CPU%\9661MEM%   TIME+  Command"
            , "70337 jhrcek      20   0  234M 10428  6160 R  81.3  0.0  0:00.17 htop"
            , " 5399 jhrcek      20   0 12.6G  345M  163M S  10.2  0.5  1:54.73 gnome-shell"
            , "    1 root        20   0 40080 22080 10516 S   0.0  0.0  0:02.64 systemd"
            , "F1Help  F2Setup F3SearchF4FilterF5Tree  F6SortByF7Nice -F8Nice +F9Kill  F10Quit"
            ]
        gotcha $ p_ $ do
            "htop always appears near the top of its own list, usually as the busiest thing on an \
            \idle machine. That is not a bug and not vanity: reading "
            c "/proc"
            " for a few thousand processes and redrawing the screen is genuinely the most \
            \expensive thing happening. It is also the reason "
            c "htop -d 1"
            " is not free — at ten samples a second htop can become a real fraction of a core."

    block "The clock you are allowed to set" $ do
        p_ $ do
            "The interval is "
            opt "delay"
            ", measured in "
            b_ "tenths of a second"
            ", and it defaults to "
            c "15"
            " — one and a half seconds. The manual page never states that default; it comes out of \
            \the config file htop writes for itself."
        sh
            [ "$ htop -d 5          # half a second: twitchy, good for catching bursts"
            , "$ htop -d 30         # three seconds: calm, good for leaving on a screen"
            , "$ htop -d 0          # accepted in silence, and clamped to 1"
            , "$ htop -d 500        # accepted in silence, and clamped to 100"
            ]
        p_ $ do
            "The clamp is the documented range 1–100, so the slowest htop you can ask for is one \
            \sample every ten seconds and the fastest is ten a second. Values outside it are not \
            \errors; they are quietly corrected, which is a pattern you will meet again on Day 9 \
            \when you write a config file by hand."
        tip $ p_ $ do
            "A flag that the manual page does not mention at all: "
            c "-n"
            ", or "
            c "--max-iterations"
            ". "
            c "htop -n 1"
            " draws exactly one frame and exits. It is the honest way to see what a single sample \
            \looks like, and the only way to get htop into a script or a screenshot without a \
            \terminal wrangler."

    block "Why the percentages do not add up" $ do
        p_ $ do
            "On a multi-core machine "
            c "CPU%"
            " is a share of a "
            i_ "single"
            " core. A process using four cores flat out reads "
            c "400.0"
            ", and on a 32-core box the column tops out at 3200. top(1) calls this Irix mode and \
            \htop inherits both the behaviour and the name."
        p_ $ do
            "The alternative lives one column away. "
            opt "PERCENT_NORM_CPU"
            " — "
            c "NCPU%"
            " on screen — divides by the number of cores, so the same process reads 12.5% of the \
            \whole machine. Day 10 shows how to put it on screen; today it is enough to know which \
            \question each column answers:"
        defs
            [ (c "CPU%" <> " (" <> opt "PERCENT_CPU" <> ")", "How hard is this process working? 100% means one core saturated.")
            , (c "NCPU%" <> " (" <> opt "PERCENT_NORM_CPU" <> ")", "How much of this machine is this process? 100% means the whole box.")
            ]
        note $ p_ $ do
            "Both are computed over the same interval, so both inherit its noise. A process that \
            \works in 200 ms bursts every two seconds will show a different number on every \
            \refresh, and no amount of staring will settle it. If you need a settled answer, widen \
            \the window — that is what the "
            c "TIME+"
            " column is for, and it is cumulative rather than sampled."

    block "Pausing, redrawing and leaving" $ do
        p_ $ do
            k "Z"
            " stops the sampling loop. The screen freezes so you can read a row that keeps moving, \
            \and the machine carries on entirely unaffected. Press it again and the counters catch \
            \up in one jump, because they were accumulating the whole time."
        p_ $ do
            k "Ctrl-L"
            " forces an immediate redraw and recalculation without waiting for the tick. Reach for \
            \it after something else has scribbled on your terminal, or when you cannot bear to \
            \wait 1.5 seconds."
        gotcha $ p_ $ do
            "Leave with "
            k "q"
            " or "
            k "F10"
            ", not by closing the terminal and not with "
            k "Ctrl-C"
            ". htop saves its settings only on a clean exit; any signal and the session's changes \
            \are dropped. The manual page is right about this one, and it becomes important the \
            \moment you start configuring anything."

    block "Today's habit" $ do
        p_ $ do
            "Put htop somewhere you will see it — a spare tmux window, a second monitor, a \
            \terminal tab you never close — and start glancing at it when a machine "
            i_ "feels"
            " slow rather than when it has already fallen over. Reading htop calmly is a skill, \
            \and a crisis is a poor place to practise it."
        p_ "Tomorrow: the process list itself — what the twelve default columns are, and how to move around in a list ten times taller than your screen."

cheat :: Html ()
cheat = do
    cfg
        [ "htop                 # three regions: header meters / process list / function bar"
        , "                     # samples /proc every `delay` tenths of a second; default 15"
        , "htop -d 5            # half-second sampling   (clamped to 1..100, silently)"
        , "htop -n 1            # draw one frame and exit (undocumented in man htop)"
        , "htop -V              # version.  `-v` from the SYNOPSIS does not exist"
        , "Z                    # pause/resume sampling; the machine keeps running"
        , "Ctrl-L               # redraw and recalculate now"
        , "q  F10               # quit -- the ONLY exit that saves settings"
        , ""
        , "CPU%   = share of ONE core   -> 780% means 7.8 cores busy"
        , "NCPU%  = share of the MACHINE -> the same process, divided by core count"
        ]
    p_ $ do
        "The header meters and the process list do not share a source. Meters come from \
        \machine-wide cumulative counters and count work done by processes that have already \
        \exited; rows come from "
        c "/proc/[pid]/"
        " and can only show what was alive at sampling time. When they disagree, suspect \
        \short-lived processes."
