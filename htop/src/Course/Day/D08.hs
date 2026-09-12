module Course.Day.D08 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 8
        , dayTitle = "The header meters"
        , daySubtitle = "Reading the coloured segments, and the thirty-odd meters you can put up there instead."
        , dayMinutes = 35
        , dayLevel = "intermediate"
        , dayManRef = "METERS, EXTERNAL LIBRARIES"
        , dayTags = ["CPU bar", "meters", "PSI"]
        , dayGoals =
            [ "name every coloured segment of the CPU bar, and say what turning on detailed CPU time adds"
            , "read the memory bar's five segments instead of just its overall length"
            , "choose a meter and a display mode for the question you actually have"
            ]
        , dayDiagram = Just d8diagram
        , dayBody = body
        , dayKeys =
            [ ("#", "Hide and show the header meters entirely. Not in the manual page.")
            , ("F2 S C", "Open Setup, where meters are chosen. " <> k "C" <> " is an undocumented alias.")
            ]
        , dayCmds =
            [ ("htop --no-meters", "Start with the header hidden. Gives the process list the whole terminal.")
            , ("htop -C", "Monochrome. The bar segments become bold, normal and dim instead of colours.")
            , ("htop -U", "ASCII instead of unicode for the graph meters.")
            ]
        , dayOpts =
            [ ("detailed_cpu_time", "Split the CPU bar into irq, soft-irq, steal, guest and io-wait. Default off.")
            , ("header_layout", "One to four columns, in fourteen width presets. Default " <> c "two_50_50" <> ".")
            , ("column_meters_0", "The meters in the first header column, space-separated.")
            , ("column_meter_modes_0", "Their display modes: " <> c "1" <> " bar, " <> c "2" <> " text, " <> c "3" <> " graph, " <> c "4" <> " LED.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Press "
                <> k "F1"
                <> " and read the first four lines. They are a live colour legend for the CPU, \
                   \memory and swap bars in "
                <> i_ "your"
                <> " colour scheme, which no printed table can be."
            , "Press "
                <> k "#"
                <> ". The whole header disappears and the process list gets the space. Press it \
                   \again. This key is not in the manual page."
            , "Run "
                <> c "htop -C"
                <> " and look at the CPU bar. The segments are still there, distinguished by bold, \
                   \normal and dim rather than by hue. This is what your colleague on a broken \
                   \terminal is looking at."
            , "Compile something, or run "
                <> c "yes > /dev/null"
                <> ", and watch which segment of the CPU bar grows. Now run "
                <> c "find / -type f > /dev/null 2>&1"
                <> " and watch a different one grow. Those two colours are the difference between \
                   \a CPU problem and an I/O problem."
            , "Look at the memory bar and find the boundary between the used portion and the cache \
              \portion. Most of what looks alarming on a healthy Linux box is cache, and cache is \
              \free — the kernel will hand it back the moment anything needs it."
            , "Break something on purpose: put a meter name that does not exist into your config \
              \and start htop. Nothing appears, and nothing complains. htop's parser never \
              \reports an error, which is the single most important thing to know before Day 9."
            , "On your own machine: decide which four numbers you would actually want on screen \
              \during an incident. Almost nobody's honest answer is “thirty-two individual CPU \
              \bars”, and yet that is what most people run."
            , "Adopt the habit of reading the header before the list. The list tells you which \
              \process; the header tells you whether there is a problem at all."
            ]
        , dayQuiz =
            [
                ( "Your CPU bar is nearly full, but the process list shows nothing using much CPU \
                  \and the machine feels fine. Which segment should you look at, and what would it \
                  \mean?"
                , do
                    p_ $ do
                        "Most likely the grey "
                        b_ "io-wait"
                        " segment, which only appears as its own colour once Detailed CPU time is \
                        \switched on. io-wait is not work — it is a core sitting idle because \
                        \everything runnable on it is blocked waiting for a disk. The CPU is not \
                        \busy; it is bored."
                    p_ $ do
                        "The other candidate is cyan "
                        b_ "steal"
                        ", which on a VM means the hypervisor gave your vCPU's time to somebody \
                        \else. That one is genuinely lost time and no amount of tuning inside your \
                        \guest will recover it. Both are invisible by default, folded into the main \
                        \segments — which is exactly why the default bar can look busy while \
                        \nothing is running."
                )
            ,
                ( "A colleague reports “the server is using 52 of its 62 GB of RAM, we need to \
                  \order more”. What do you check before agreeing?"
                , do
                    p_ $ do
                        "The composition of the memory bar, not its length. The bar stacks "
                        b_ "used, shared, compressed, buffers and cache"
                        ", and on a healthy long-running Linux box the majority of it is usually \
                        \cache — file contents the kernel is keeping around because the RAM was \
                        \otherwise idle."
                    p_ $ do
                        "Cache is not consumption. The kernel evicts it instantly when anything \
                        \wants real memory, which is why the text-mode Memory meter also prints an "
                        c "available"
                        " figure — on the machine this course was checked against, 9.13G used and \
                        \24.9G cache came out as 51.5G "
                        c "available"
                        " of 61.9G. That "
                        c "available"
                        " number is the one to put in the capacity conversation."
                )
            ,
                ( "You put the Memory meter on screen four times in four different display modes. \
                  \What do you get, and when is each worth the space?"
                , do
                    p_ $ do
                        b_ "Bar"
                        " (mode 1) shows proportions at a glance and costs one line. "
                        b_ "Text"
                        " (mode 2) costs one line and gives you the actual breakdown — "
                        c "used"
                        ", "
                        c "shared"
                        ", "
                        c "compressed"
                        ", "
                        c "buffers"
                        ", "
                        c "cache"
                        ", "
                        c "available"
                        " — which the bar can only imply."
                    p_ $ do
                        b_ "Graph"
                        " (mode 3) costs two lines and is the only mode with any "
                        i_ "memory of the past"
                        ": it is a sparkline, so it answers “is this climbing?”, which is almost \
                        \always the real question. "
                        b_ "LED"
                        " (mode 4) costs three lines and is legible across a room — for a wall \
                        \display, and nothing else."
                )
            ,
                ( "The manual page's METERS section reads “Default CPU bar segments ( use text \
                  \attributes instead of hues:”. What happened, and what should it say?"
                , do
                    p_ $ do
                        "Words have been lost in the source — the parenthesis opens and never \
                        \closes, and the subject of “use text attributes” has gone missing. It \
                        \should say something like “in monochrome mode, segments use text \
                        \attributes instead of hues”, which is what the rest of the section then \
                        \describes segment by segment."
                    p_ $ do
                        "It is a typesetting bug rather than a factual one, and the surrounding \
                        \content is correct — the segment list and the monochrome mappings both \
                        \match the binary. It is worth noticing only because it is a reminder that \
                        \the live legend on the "
                        k "F1"
                        " screen is generated from the code, and is therefore the thing to trust."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d8diagram :: Diagram
d8diagram =
    ( diagram
        "The header is divided into columns by the header layout; each column holds a list of \
        \meters; each meter has a display mode and is drawn from a machine-wide statistic, some of \
        \which need an optional library that may not be loaded."
        body'
    )
        { dgCaption = do
            "A meter is two independent choices — "
            b_ "what it measures"
            " and "
            b_ "how it is drawn"
            " — and htop stores them as two parallel lists, which is why the config file has both a "
            c "column_meters_0"
            " and a "
            c "column_meter_modes_0"
            " line. The dashed aspect is the one that catches people out: a few meters depend on a \
            \library loaded at runtime, so the same htop on the same hardware can offer CPU \
            \temperatures on one machine and not on another."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  hdr   [label=\"the header\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  lay   [label=\"a header layout\\n(1 to 4 columns)\"];\n\
        \  colm  [label=\"a header column\"];\n\
        \  mtr   [label=\"a meter\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  mode  [label=\"a display mode\\n(bar/text/graph/LED)\"];\n\
        \  stat  [label=\"a machine-wide\\nstatistic\"];\n\
        \  lib   [label=\"an optional library\\nloaded at runtime\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  hdr  -> lay  [label=\"  is divided by\"];\n\
        \  hdr  -> colm [label=\"  contains\"];\n\
        \  colm -> mtr  [label=\"  lists\"];\n\
        \  mtr  -> mode [label=\"  is drawn in\"];\n\
        \  mtr  -> stat [label=\"  measures\"];\n\
        \  stat -> lib  [label=\"may require  \", style=dashed, constraint=false];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "The bars are stacked, and the stacking is the information" $ do
        p_ [class_ "lede"] $ do
            "Everybody reads the CPU bar as “how full is it”. The length is the least interesting \
            \thing about it: the bar is "
            b_ "several kinds of CPU time stacked left to right"
            ", and which segment is growing tells you what sort of problem you have."
        p_ $ do
            "By default the segments are, in order: "
            b_ "low"
            " (blue — time spent at a positive nice value), "
            b_ "normal"
            " (green — ordinary user code), "
            b_ "kernel"
            " (red — system time), and "
            b_ "virt"
            " (cyan — hypervisor steal plus guest time, folded together). In monochrome the same \
            \four become normal, bold, bold and dim."
        p_ $ do
            "Switching on "
            opt "detailed_cpu_time"
            " in Setup expands the bar to separate "
            b_ "irq"
            " (yellow), "
            b_ "soft-irq"
            " (magenta), "
            b_ "steal"
            " (cyan), "
            b_ "guest"
            " (cyan) and "
            b_ "io-wait"
            " (grey). You can see the difference immediately in text mode:"
        sh
            [ "detailed_cpu_time=0     0:  0.0% sys:  0.0% low:  0.0% vir:  0.0%"
            , "detailed_cpu_time=1     0:  0.0% sy:  0.0% ni:  0.0% hi:  0.0% si:  0.0% st:  0.0% gu:  0.0% wa:  0.0%"
            ]
        fig
        why $ p_ $ do
            "The default folds those five away because on an ordinary laptop they are always zero \
            \and would cost you four colours you have to learn. The moment you are on a VM or \
            \debugging storage they become the only segments that matter — "
            b_ "steal"
            " means your hypervisor is overcommitted and "
            b_ "io-wait"
            " means your disks are the bottleneck, and neither is visible at all with the default \
            \setting. Turn it on for servers, leave it off for desktops."
        gotcha $ p_ $ do
            "Exact hues depend on your colour scheme, and any table of colours — including the one \
            \above — is a generalisation. htop ships a live legend that is always right: press "
            k "F1"
            " and the first four lines show the CPU, memory and swap bar segments in the colours \
            \your terminal is actually using."

    block "The memory bar is not a fuel gauge" $ do
        p_ $ do
            "The memory bar stacks "
            b_ "used, shared, compressed, buffers and cache"
            ", and the swap bar stacks "
            b_ "used, cache and frontswap"
            ". Put the Memory meter in text mode and it will tell you the numbers outright:"
        sh
            [ "Mem:61.9G used:9.13G shared:585M compressed:0K buffers:4.69M cache:24.9G available:51.5G"
            , "Swp:8.00G used:0K cache:0K frontswap:0K"
            ]
        p_ $ do
            "That "
            c "available"
            " figure is the one worth arguing from. The bar looked more than half full; 51.5 GB of \
            \62 was available, because almost all of the apparent usage was page cache that the \
            \kernel will surrender the instant anything asks. A Linux box with empty cache is a \
            \Linux box wasting memory."

    block "Thirty-odd meters, four ways to draw them" $ do
        p_ "The Setup screen's “Available meters” list is long and is documented nowhere in the manual page. The useful groups:"
        defs
            [ ("CPU", "Ten different groupings — one combined average, all cores, or the cores split across two or four shorter columns. On a 32-core machine this choice is the difference between a three-line header and a thirty-five-line one.")
            , ("Memory", do "Memory, Swap, a combined memory-and-swap meter, and " ; c "HugePages" ; ".")
            , ("Load and tasks", "Load average, the one-minute load alone, and the Task counter that gives you the processes / threads / kernel-threads / running line.")
            , ("Time", do c "Clock" ; ", " ; c "Date" ; ", " ; c "Date and Time" ; ", " ; c "Uptime" ; " and uptime in raw seconds.")
            , ("System", do "A " ; c "System" ; " meter, " ; c "Hostname" ; ", " ; c "Battery" ; ", and — where libsystemd is present — the number of running, failed and jobs-queued systemd units.")
            , ("Pressure Stall Information", "Five PSI meters: some-cpu, some-io, full-io, full-irq and some-memory. These are the modern answer to “is this machine actually struggling”, and they are worth more than most of the bars above them.")
            , ("Blank", "A spacer. Genuinely useful for lining two header columns up.")
            ]
        p_ "Each meter is drawn in one of four modes, and the mode is as much of a decision as the meter:"
        ascii
            [ "  1  Bar     Mem[||||||||||||||||||||||||||     9.69G/61.9G]        1 line"
            , "  2  Text    Mem:61.9G used:9.12G shared:584M compressed:0K         1 line"
            , "  3  Graph   ⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣿             2 lines"
            , "  4  LED     ┌──╴ ┐ ┌──┐    ┌──┐  ┐ ╶──┐                            3 lines"
            ]
        tip $ p_ $ do
            b_ "Graph"
            " mode is the underrated one. Every other mode shows you an instant; the graph is a \
            \sparkline over time, so it answers “is this getting worse?” without you having to sit \
            \and watch. Two lines of header for a memory trend is the best trade in the whole Setup \
            \screen."
        note $ p_ $ do
            "Three meters depend on libraries loaded at runtime rather than linked at build time: "
            c "libsystemd"
            " for the SystemD meter (with a "
            c "systemctl"
            " fallback), "
            c "libsensors"
            " for CPU temperatures, and "
            c "libnl-3"
            " for the delay-accounting columns of Day 12. That is why the same htop version offers \
            \different meters on different machines, and why a missing temperature reading is \
            \usually a missing library rather than a missing sensor."

    block "Layout, and getting the header out of the way" $ do
        p_ $ do
            opt "header_layout"
            " divides the header into one, two, three or four columns, in fourteen width presets — "
            c "two_50_50"
            " by default, with everything from "
            c "1 column - full width"
            " to "
            c "4 columns - 25/25/25/25"
            " available. Each column gets its own list of meters, filled top to bottom."
        p_ $ do
            "And when you want none of it: "
            k "#"
            " hides the entire header and gives the process list the whole terminal. "
            c "htop --no-meters"
            " starts that way. Neither is in the manual page."
        p_ $ do
            "Two more flags worth knowing here. "
            c "htop -C"
            " is monochrome, which is what the segments look like when colour is unavailable — \
            \worth seeing once so you can read somebody else's screen. "
            c "htop -U"
            " swaps the unicode braille characters of graph mode for plain ASCII, for terminals \
            \and fonts that mangle them."

    block "Today's habit" $ do
        p_ $ do
            "Spend two minutes deciding what your header should say, before tomorrow makes it \
            \permanent. The default — every core as its own bar — is a poor default on any modern \
            \machine: it scales with your core count, it is the first thing to eat your screen, and \
            \“which of my 32 cores is busy” is a question almost nobody has. A single average CPU \
            \bar, memory, swap, and a PSI meter will serve you better."
        p_ "Tomorrow: the Setup screen in full, and the config file it writes — including the ways htop will overwrite your work if you let it."

cheat :: Html ()
cheat = do
    cfg
        [ "CPU bar, default:    low(nice)  normal(user)  kernel(sys)  virt(steal+guest)"
        , "  + detailed_cpu_time:  irq  soft-irq  steal  guest  io-wait   <- split out"
        , "  text mode shows:  sys low vir      -> detailed:  sy ni hi si st gu wa"
        , ""
        , "Memory bar:  used  shared  compressed  buffers  cache   (text mode adds 'available')"
        , "Swap bar:    used  cache  frontswap"
        , ""
        , "display modes:   1 Bar (1 line)    2 Text (1 line)"
        , "                 3 Graph (2 lines, a sparkline -- the only one with history)"
        , "                 4 LED (3 lines, legible across a room)"
        , ""
        , "#                 hide/show the whole header      [not in man]"
        , "htop --no-meters  start with it hidden"
        , "htop -C           monochrome: bold / normal / dim instead of hues"
        , "F1                the LIVE colour legend for your scheme -- trust this over any table"
        ]
    p_ $ do
        "A nearly full memory bar is usually mostly page cache, and cache is free. Read the "
        c "available"
        " figure from the text-mode Memory meter before anyone orders RAM."
