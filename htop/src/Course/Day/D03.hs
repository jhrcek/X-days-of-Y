module Course.Day.D03 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 3
        , dayTitle = "The memory columns"
        , daySubtitle = "VIRT, RES, SHR, PRIV, PSS — five answers to “how much memory”, four of which you must not add up."
        , dayMinutes = 35
        , dayLevel = "essential"
        , dayManRef = "COLUMNS, MEMORY SIZES"
        , dayTags = ["memory", "PSS", "shared pages"]
        , dayGoals =
            [ "say what each memory column counts, and which single one is safe to add up across processes"
            , "explain a 1.4 TB VIRT next to a 650 MB RES without alarm"
            , "read htop's sizes correctly, including the suffix that is not there"
            ]
        , dayDiagram = Just d3diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds = []
        , dayOpts =
            [ ("M_VIRT", "Address space the process has mapped. " <> c "VIRT" <> ". Mostly promises, not memory.")
            , ("M_RESIDENT", "Pages actually in RAM, shared ones counted in full. " <> c "RES" <> ".")
            , ("M_SHARE", "The part of " <> c "RES" <> " that other processes also map. " <> c "SHR" <> ".")
            , ("M_PRIV", "Resident minus shared — what dies with the process. " <> c "PRIV" <> ", a default column.")
            , ("M_SWAP", "Pages of this process pushed out to swap. " <> c "SWAP" <> ".")
            , ("M_PSS", "Resident, but each shared page divided by its number of sharers. " <> c "PSS" <> ".")
            , ("M_PSSWP", "The same proportional treatment for swapped-out pages. " <> c "PSSWP" <> ".")
            , ("M_EPSS", "PSS plus PSSWP: the whole footprint, proportionally. " <> c "EPSS" <> ".")
            , ("PERCENT_MEM", "RES as a share of total RAM. " <> c "MEM%" <> " — and it inherits RES's double counting.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Find the biggest "
                <> c "VIRT"
                <> " on your machine. If you run a browser or a language server it will be in the \
                   \hundreds of gigabytes. Check your actual RAM in the "
                <> c "Mem"
                <> " meter and satisfy yourself that nothing is wrong."
            , "Pick any row and check the identity by hand: "
                <> c "RES"
                <> " should equal "
                <> c "SHR"
                <> " plus "
                <> c "PRIV"
                <> ". It will, to the last kilobyte."
            , "Read a real PSS without changing any htop setting. Take a PID from the list and run "
                <> c "grep -E '^(Rss|Pss|Swap):' /proc/PID/smaps_rollup"
                <> " in another terminal. Compare "
                <> c "Rss"
                <> " with htop's "
                <> c "RES"
                <> ": same number, different units — the file is in kB and says so."
            , "Break it on purpose: run that same "
                <> c "grep"
                <> " against PID 1, or any process owned by root. "
                <> c "Permission denied"
                <> ". You have just found the reason htop's "
                <> c "PSS"
                <> " column shows "
                <> c "0"
                <> " for every process you do not own."
            , "Add up "
                <> c "RES"
                <> " for the five biggest browser processes, then compare the total against what \
                   \the "
                <> c "Mem"
                <> " meter says the whole machine is using. The sum will be conspicuously too big; \
                   \that gap is shared pages counted five times."
            , "Find a row whose "
                <> c "RES"
                <> " has no suffix at all — "
                <> c "22080"
                <> ", say. That number is in KiB, so it is 21.6 MiB, not 22 kB and definitely not \
                   \22 bytes. Say it in megabytes out loud until it stops being surprising."
            , "On your own machine: take the service or application you are actually responsible \
              \for and write down its "
                <> c "RES"
                <> " and its "
                <> c "PRIV"
                <> " today. "
                <> c "PRIV"
                <> " is roughly what you would get back by restarting it — that is the number to \
                   \put in a ticket, not "
                <> c "VIRT"
                <> "."
            , "Adopt the habit: whenever someone quotes you a memory number, ask which column it \
              \came from before you react to it. Half of all “memory leak” reports are somebody \
              \watching "
                <> c "VIRT"
                <> "."
            ]
        , dayQuiz =
            [
                ( "A monitoring dashboard alerts that a Chrome renderer is using "
                    <> c "1454G"
                    <> " of memory on a machine with 62 GB of RAM. What is it looking at, and what \
                       \should it have looked at?"
                , do
                    p_ $ do
                        opt "M_VIRT"
                        " — address space, not memory. A process reserves address ranges far larger \
                        \than anything it will touch: guard pages, sandbox arenas, memory-mapped \
                        \files, thread stacks it has not grown into. On 64-bit machines address \
                        \space is free, so nobody economises, and browsers and JITs habitually map \
                        \terabytes."
                    p_ $ do
                        "The number that would have meant something is "
                        opt "M_RESIDENT"
                        " — pages actually in RAM — or better "
                        opt "M_PSS"
                        ", which does not double-count what the process shares with its twenty \
                        \siblings. "
                        c "VIRT"
                        " is worth watching for exactly one thing: a process whose address space \
                        \grows without bound is leaking mappings, which is a real if rare bug."
                )
            ,
                ( "You sort by "
                    <> c "PSS"
                    <> " to find the real memory hogs, and every system daemon drops to the bottom \
                       \with a PSS of zero — including ones whose "
                    <> c "RES"
                    <> " is clearly not zero. Have you found a very efficient daemon?"
                , do
                    p_ $ do
                        "No. You are not root. "
                        c "RES"
                        ", "
                        c "SHR"
                        " and "
                        c "PRIV"
                        " come from "
                        c "/proc/[pid]/statm"
                        ", which is world-readable and cheap. "
                        c "PSS"
                        " needs "
                        c "/proc/[pid]/smaps_rollup"
                        ", which the kernel only lets you read for processes you own."
                    p_ $ do
                        "htop does not mark this: it prints "
                        c "0"
                        ", which sorts like a real zero rather than like the "
                        c "-"
                        " the manual page uses for genuinely unavailable data. So an unprivileged \
                        \PSS sort silently ranks the entire system half of your machine at the \
                        \bottom. Run htop under "
                        c "sudo"
                        " when the question is about memory you do not own."
                )
            ,
                ( "Six browser processes each show "
                    <> c "RES"
                    <> " around 500M. Is the browser using 3 GB?"
                , do
                    p_ $ do
                        "Almost certainly not. "
                        c "RES"
                        " counts every resident page in full, including pages that several \
                        \processes map at once — the shared libraries, the binary itself, the \
                        \fonts, the copy-on-write heap inherited from the zygote. Add six "
                        c "RES"
                        " values together and you have counted each of those pages six times."
                    p_ $ do
                        "On the machine this course was checked against, five Chrome renderers \
                        \summed to 2510M of "
                        c "RES"
                        " but only 1725M of "
                        c "PSS"
                        " — the sum overstated by about 45%. "
                        c "PSS"
                        " exists precisely so that the column "
                        i_ "can"
                        " be added up: each shared page is divided by the number of processes \
                        \sharing it, so every page in the machine is counted exactly once across \
                        \the whole list."
                )
            ,
                ( "A row shows "
                    <> c "RES"
                    <> " of "
                    <> c "22080"
                    <> " and another shows "
                    <> c "234M"
                    <> ". Which is bigger, and by how much?"
                , do
                    p_ $ do
                        "The second, by about eleven times. A bare number in htop is "
                        b_ "kibibytes"
                        " — the suffix is omitted rather than absent, so "
                        c "22080"
                        " means 22080 KiB, which is 21.6 MiB. Everything is powers of 1024: "
                        c "M"
                        " is MiB, "
                        c "G"
                        " is GiB."
                    p_ $ do
                        "The manual page explains the reasoning, and it is sound: memory is \
                        \allocated in whole pages of 4 KiB, so kibibytes are the natural unit and \
                        \dropping the suffix buys a column of screen width on every row. It is \
                        \still the single most common misreading of an htop screen, because every \
                        \other tool you use prints its units."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d3diagram :: Diagram
d3diagram =
    ( diagram
        "Which memory column counts which pages: VIRT counts every mapped page of address \
        \space, RES counts every resident page in full, PRIV counts only the resident pages no \
        \other process maps, and PSS counts a 1/N share of each page that N processes map."
        body'
    )
        { dgCaption = do
            "One page of physical memory, four different answers — the columns disagree because \
            \they are counting different things, not because any of them is wrong. The consequence \
            \worth carrying: only "
            b_ "PSS"
            " can be added up. Sum "
            c "RES"
            " across a process tree and every shared page is counted once per process; sum "
            c "PRIV"
            " and you miss the shared pages entirely. "
            c "VIRT"
            " sits furthest from reality of all — it counts address space that may never be \
            \touched."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  proc   [label=\"a process\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  addr   [label=\"a mapped page\\nof address space\"];\n\
        \  res    [label=\"a resident page\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  shared [label=\"a resident page mapped\\nby N processes at once\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  virtC  [label=\"the VIRT column\"];\n\
        \  resC   [label=\"the RES column\"];\n\
        \  privC  [label=\"the PRIV column\"];\n\
        \  pssC   [label=\"the PSS column\"];\n\
        \\n\
        \  proc   -> addr   [label=\"  has mapped\"];\n\
        \  res    -> addr   [label=\"  is\"];\n\
        \  shared -> res    [label=\"  is\"];\n\
        \  virtC  -> addr   [label=\"  counts every\"];\n\
        \  resC   -> res    [label=\"  counts in full every\"];\n\
        \  privC  -> res    [label=\"  counts every unshared\"];\n\
        \  pssC   -> shared [label=\"  counts a 1/N share of\"];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Five columns, one pile of pages" $ do
        p_ [class_ "lede"] $ do
            "There is no such thing as “the memory a process is using”. There is a set of pages, \
            \some of them resident and some not, some of them mapped by one process and some by \
            \twenty — and each memory column is a different "
            b_ "accounting policy"
            " over that set. Learn the policies and the columns stop contradicting each other."
        p_ $ do
            "Here is a real row from the machine this course was checked against, a Chrome \
            \renderer, with every memory column on screen at once:"
        ascii
            [ "  PID USER        VIRT   RES   SHR  PRIV  SWAP   PSS  PSSWP  EPSS MEM%"
            , "15201 jhrcek     1454G  658M  150M  508M     0  500M      0  500M  1.0"
            ]
        p_ $ do
            "1454 gigabytes and 658 megabytes are the same process, in the same instant. Neither \
            \is a typo."
        why $ p_ $ do
            "The columns multiplied because the honest answer depends on the question. “Will this \
            \process fit in RAM?” is "
            c "RES"
            ". “What do I get back if I kill it?” is "
            c "PRIV"
            ". “What is this process's fair share of the machine?” is "
            c "PSS"
            ". A single memory number would have to pick one of those and be wrong for the other \
            \two, so Linux exposes all of them and htop passes them through."
        fig

    block "From address space to fair shares" $ do
        defs
            [
                ( c "VIRT" <> " (" <> opt "M_VIRT" <> ")"
                , do
                    "Everything the process has mapped, touched or not. Includes files mapped but \
                    \never read, arenas reserved but never allocated, and guard regions that exist \
                    \to stay empty. On 64-bit machines address space costs nothing, so large \
                    \programs do not ration it. "
                    b_ "Almost never the number you want."
                )
            ,
                ( c "RES" <> " (" <> opt "M_RESIDENT" <> ")"
                , "Pages genuinely in RAM right now — text, data and stack. The honest answer to \
                  \“is this process big”, and the one MEM% is computed from. Counts shared pages \
                  \in full, which is why you cannot add it up."
                )
            ,
                ( c "SHR" <> " (" <> opt "M_SHARE" <> ")"
                , "The part of RES that somebody else maps too: libraries, the executable, \
                  \copy-on-write pages not yet written to."
                )
            ,
                ( c "PRIV" <> " (" <> opt "M_PRIV" <> ")"
                , do
                    "RES minus SHR — the pages that belong to this process alone and die with it. \
                    \A default column in htop 3, and the right number for “how much would \
                    \restarting this free”."
                )
            ,
                ( c "PSS" <> " (" <> opt "M_PSS" <> ")"
                , "RES again, but every shared page divided by the number of processes sharing it. \
                  \The only column that sums correctly across processes."
                )
            ,
                ( c "SWAP" <> " / " <> c "PSSWP" <> " / " <> c "EPSS"
                , do
                    "Swapped-out pages, the same proportional treatment applied to them, and "
                    c "PSS"
                    " + "
                    c "PSSWP"
                    " together. "
                    c "EPSS"
                    " is the closest thing htop has to a single honest footprint."
                )
            ]
        tip $ p_ $ do
            "One identity holds on every row, and checking it once makes the whole family click: "
            b_ "RES = SHR + PRIV"
            ". In the row above, 150M + 508M = 658M. Everything else is a re-weighting of the same \
            \pages."

    block "Why you must not add these up" $ do
        p_ $ do
            "Six browser processes showing 500M of "
            c "RES"
            " each are not using 3 GB. They share the binary, every library, the fonts, and a \
            \large copy-on-write heap inherited at fork. "
            c "RES"
            " charges each of those pages in full to every process that maps it, so the sum counts \
            \them six times over."
        p_ "The five biggest renderers on the machine this course was checked against:"
        ascii
            [ "            RES     PSS"
            , "  15201    658M    500M"
            , "   9599    531M    375M"
            , "  10100    485M    324M"
            , "  15453    427M    262M"
            , "  10092    409M    264M"
            , "  ─────  ──────  ──────"
            , "  total   2510M   1725M      <- RES overstates by ~785M, about 45%"
            ]
        p_ $ do
            "This is the whole reason "
            c "PSS"
            " exists. Divide each shared page by its number of sharers and every page of physical \
            \memory is charged exactly once across the entire process list — so a column of "
            c "PSS"
            " values can be added up, and the total means something."
        gotcha $ p_ $ do
            c "MEM%"
            " is computed from "
            c "RES"
            ", so it inherits the double counting exactly. A column of "
            c "MEM%"
            " for a browser can comfortably sum past 100% on a machine that is not close to \
            \swapping. It is not a percentage of anything you can add up."

    block "The privilege wall in front of PSS" $ do
        p_ $ do
            c "RES"
            ", "
            c "SHR"
            " and "
            c "PRIV"
            " come from "
            c "/proc/[pid]/statm"
            ": world-readable, three numbers, effectively free to read. "
            c "PSS"
            " needs "
            c "/proc/[pid]/smaps_rollup"
            ", which the kernel walks page table by page table and only shows you for processes \
            \you own."
        sh
            [ "$ grep -E '^(Rss|Pss|Swap):' /proc/self/smaps_rollup"
            , "Rss:               10280 kB"
            , "Pss:                6076 kB"
            , "Swap:                  0 kB"
            , "$ grep Pss /proc/1/smaps_rollup"
            , "grep: /proc/1/smaps_rollup: Permission denied"
            ]
        gotcha $ p_ $ do
            "Where it cannot read that file, htop prints "
            c "0"
            " — not the "
            c "-"
            " that the manual page defines as “unsupported on your system”. A zero sorts like a \
            \real zero, so an unprivileged sort by "
            c "PSS"
            " silently files every daemon, every container and everything root owns at the very \
            \bottom of the list. If the question is about memory you do not own, run htop under "
            c "sudo"
            "."
        note $ p_ $ do
            "There is a cost on the other side of that wall. Walking "
            c "smaps_rollup"
            " for a few thousand processes is dramatically more expensive than reading "
            c "statm"
            ", so a root htop with "
            c "PSS"
            " on screen and "
            c "-d 1"
            " set is a genuinely heavy program. That is a fair trade when you are hunting a leak \
            \and a poor one for a dashboard you leave running."

    block "The suffix that is not there" $ do
        p_ $ do
            "htop prints sizes in powers of 1024, and "
            b_ "a number with no suffix is in KiB"
            ". So "
            c "22080"
            " is 21.6 MiB, "
            c "234M"
            " is 234 MiB, and "
            c "1454G"
            " is 1454 GiB."
        p_ $ do
            "The reasoning is in the manual page's "
            c "MEMORY SIZES"
            " section and it is a good one: memory is allocated in whole pages, 4 KiB on most \
            \platforms, so kibibytes are the granularity that actually exists. Dropping the suffix \
            \saves a character on every row of a screen that is always short of width."
        p_ $ do
            "It is still the most common misreading of an htop screen, because every other tool \
            \you use prints its units. Read a bare number as “thousands of kilobytes” once or \
            \twice and it will stop catching you."

    block "Today's habit" $ do
        p_ $ do
            "Pick the one service you are responsible for and learn its normal "
            c "RES"
            " and "
            c "PRIV"
            ". Not its peak, not its "
            c "VIRT"
            " — its ordinary Tuesday-afternoon numbers. Memory problems are almost always noticed \
            \as a "
            i_ "change"
            ", and you cannot see a change against a baseline you never had."
        p_ "Tomorrow: four different ways to find a process, and why people keep reaching for the wrong one."

cheat :: Html ()
cheat = do
    cfg
        [ "VIRT   address space mapped      -- mostly promises; ignore unless it GROWS"
        , "RES    pages in RAM, in full     -- 'is it big?'      MEM% comes from this"
        , "SHR    the shared part of RES    -- libraries, the binary, COW pages"
        , "PRIV   RES - SHR                 -- 'what do I free by killing it?'"
        , "PSS    RES, shared pages / N     -- the ONLY column you may add up"
        , "SWAP   pushed out to swap        -- PSSWP = the proportional version"
        , "EPSS   PSS + PSSWP               -- the whole footprint, counted once"
        , ""
        , "RES = SHR + PRIV        holds on every row, always"
        , "a bare number is KiB    22080 -> 21.6 MiB, not 22 kB"
        , "PSS shows 0, not '-', for processes you do not own (needs smaps_rollup)"
        ]
    p_ $ do
        "Sum "
        c "RES"
        " across a process tree and shared pages are counted once per process; sum "
        c "PRIV"
        " and they vanish. Only "
        c "PSS"
        " charges each page of physical memory exactly once across the whole list."
