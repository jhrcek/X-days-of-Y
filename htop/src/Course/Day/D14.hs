module Course.Day.D14 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 14
        , dayTitle = "Sharp edges"
        , daySubtitle = "Every place the manual page and the binary disagree, what htop cannot tell you, and where to go next."
        , dayMinutes = 30
        , dayLevel = "advanced"
        , dayManRef = "EXTERNAL LIBRARIES, MEMORY SIZES, CONFIG FILES, SEE ALSO"
        , dayTags = ["discrepancies", "pcp-htop", "what next"]
        , dayGoals =
            [ "name the questions htop is the wrong tool for, and say what to use instead"
            , "carry a config between machines without htop quietly editing it"
            , "read the rest of the manual page unaided, knowing which parts of it to distrust"
            ]
        , dayDiagram = Just d14diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("htop --drop-capabilities=strict", "Shed Linux capabilities at startup. Kills renicing and delay accounting with them.")
            , ("pcp-htop", "A different binary: htop over Performance Co-Pilot metrics. Its own manual page, " <> c "pcp-htop(5)" <> ".")
            ]
        , dayOpts = []
        , dayConfig =
            [ ConfBlock
                "Split the CPU bar so that steal and io-wait are visible as their own segments.\n\
                \Off by default because on a laptop they are always zero; on anything virtualised or\n\
                \anything with real disks they are the only segments that matter, and folded into\n\
                \the defaults they are invisible. The cost is four more colours to recognise."
                "detailed_cpu_time=1"
            , ConfBlock
                "The last line, and a reminder rather than a setting. Keep this file in version\n\
                \control, and once you are happy with it:\n\
                \\n\
                \    chmod 444 ~/.config/htop/htoprc\n\
                \\n\
                \Without that, the first time you press t, K or I and quit cleanly, htop rewrites\n\
                \this file in its own canonical form and every comment above is gone. For a\n\
                \shared home directory across several machines, point $HTOPRC at a per-machine\n\
                \file instead -- and remember that if that file does not exist, htop uses its\n\
                \built-in defaults rather than falling back to this one."
                "color_scheme=0"
            ]
        , dayDrills =
            [ "Run "
                <> c "htop --sort-key help"
                <> " and "
                <> c "man htop"
                <> " side by side. Find three columns in the first that are missing from the \
                   \second. You are now better informed than the documentation."
            , "Look at your "
                <> c "htoprc"
                <> ". Every line should be one you can justify out loud. Delete any you cannot — \
                   \that is the whole difference between this file and a pasted one."
            , "Run "
                <> c "chmod 444"
                <> " on it, then deliberately press "
                <> k "t"
                <> " and quit with "
                <> k "q"
                <> ". Confirm the file is untouched and htop said nothing about it."
            , "Break something on purpose one last time: "
                <> c "HTOPRC=/tmp/nope htop"
                <> ". You get default htop, no error, and no file created at "
                <> c "/tmp/nope"
                <> ". Setting " <> c "$HTOPRC" <> " replaces the search rather than extending it."
            , "Ask htop a question it cannot answer: “how much memory did this process use at its \
              \peak?” Nothing on any screen will tell you. Then get it from "
                <> c "/proc/PID/status"
                <> " as "
                <> c "VmHWM"
                <> ", and note where the boundary of the tool is."
            , "Read the "
                <> c "SEE ALSO"
                <> " line: "
                <> c "proc(5)"
                <> ", "
                <> c "top(1)"
                <> ", "
                <> c "free(1)"
                <> ", "
                <> c "ps(1)"
                <> ", "
                <> c "uptime(1)"
                <> ", "
                <> c "limits.conf(5)"
                <> ". The first of those is where every number in this course actually comes from."
            , "Go back to Day 1's drills and do them again. They will take four minutes now and \
              \you will notice things you could not see a fortnight ago."
            , "Adopt the last habit: when a tool and its manual page disagree, believe the tool and \
              \write the discrepancy down. That is the entire method this course was built with, \
              \and it works on everything."
            ]
        , dayQuiz =
            [
                ( "Your monitoring says a service is being OOM-killed, but you watch it in htop for \
                  \an hour and its "
                    <> c "RES"
                    <> " never goes above 400 MB. What is htop failing to show you?"
                , do
                    p_ $ do
                        "The peak. htop samples every 1.5 seconds and shows you what it found; a \
                        \process that allocates 6 GB over 200 milliseconds and is killed for it \
                        \is invisible between two samples, exactly as on Day 1."
                    p_ $ do
                        "The kernel does keep a high-water mark — "
                        c "VmHWM"
                        " in "
                        c "/proc/PID/status"
                        " — and htop has no column for it. This is the honest boundary of the tool: \
                        \htop answers “what is happening now” extremely well and “what happened” \
                        \not at all. For the second question you need something that records, \
                        \which is what "
                        c "pcp-htop"
                        " and the Performance Co-Pilot behind it exist for."
                )
            ,
                ( "Which parts of "
                    <> c "man htop"
                    <> " should you trust, and which should you check?"
                , do
                    p_ $ do
                        b_ "Trust"
                        " the prose sections that explain concepts: "
                        c "MEMORY SIZES"
                        ", "
                        c "EXTERNAL LIBRARIES"
                        ", "
                        c "CONFIG FILES"
                        "' description of where the file lives, and the "
                        c "METERS"
                        " account of the CPU segments. These describe design decisions, which do \
                        \not drift."
                    p_ $ do
                        b_ "Check"
                        " anything that is a list: the SYNOPSIS, the option list, INTERACTIVE \
                        \COMMANDS and COLUMNS. Lists go stale one entry at a time and nobody \
                        \notices. The two authorities are "
                        c "htop --help"
                        " for flags and the "
                        k "F1"
                        " help screen for keys, both generated from the same source as the \
                        \behaviour."
                )
            ,
                ( "You keep one dotfiles repository for a laptop and a 64-core build server. How \
                  \should the htop config be arranged?"
                , do
                    p_ $ do
                        "A shared, read-only base is the wrong answer on its own, because the two \
                        \machines genuinely want different headers — the per-core CPU meters that \
                        \are fine on four cores are unusable on sixty-four, and "
                        opt "detailed_cpu_time"
                        " matters on a server and not on a laptop."
                    p_ $ do
                        "Use "
                        c "$HTOPRC"
                        " per machine, with the shared parts kept in the repository and symlinked \
                        \or generated. Set it in your shell profile so it applies to every \
                        \invocation, and remember that a missing "
                        c "$HTOPRC"
                        " file silently yields default htop rather than falling back — so a typo \
                        \in the path looks like “my config stopped working” rather than an error."
                )
            ,
                ( "After fourteen days, what is htop actually for?"
                , do
                    p_ $ do
                        "Answering “what is this machine doing right now, and which process is \
                        \responsible” faster than any other tool, on a machine you are sitting in \
                        \front of. Everything it is good at follows from sampling "
                        c "/proc"
                        " on a short interval and drawing it well."
                    p_ $ do
                        "And everything it is bad at follows from the same thing. It does not \
                        \record, so it cannot tell you about last Tuesday. It samples, so it misses \
                        \anything brief. It is per-machine, so it cannot see a fleet. Knowing that \
                        \boundary is most of what separates someone who uses htop from someone who \
                        \reaches for it and then stares at it."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d14diagram :: Diagram
d14diagram =
    ( diagram
        "The manual page and the binary are two descriptions of htop that drift apart; the \
        \binary's own --help output and F1 help screen are generated from the same source as the \
        \behaviour, while the manual page is a separate file that must be edited by hand."
        body'
    )
        { dgCaption = do
            "Why a manual page goes stale, in one picture: "
            b_ "htop's behaviour"
            ", its "
            c "--help"
            " and its "
            k "F1"
            " screen all come from the same source tree and are rebuilt together, while the \
            \manual page is a separate file somebody has to remember to edit. The dashed aspect is \
            \the one to internalise — the page describes the behaviour only as well as its last \
            \editor managed. When they disagree, the generated documentation wins, and it costs ten \
            \seconds to ask."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  src   [label=\"the source tree\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  bin   [label=\"the behaviour\\nof the binary\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  help  [label=\"--help and the\\nF1 help screen\"];\n\
        \  page  [label=\"the manual page\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  edit  [label=\"a human who must\\nremember to edit it\", fillcolor=\"#f4efe6\"];\n\
        \\n\
        \  bin  -> src  [label=\"  is compiled from\"];\n\
        \  help -> src  [label=\"  is generated from\"];\n\
        \  page -> edit [label=\"  is maintained by\"];\n\
        \  page -> bin  [label=\"claims to describe  \", style=dashed, constraint=false];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Where the page and the binary part company" $ do
        p_ [class_ "lede"] $ do
            "This course was written by running everything it claims against htop 3.5.3 rather \
            \than by reading the manual page. That turned up ten places where the two disagree. \
            \None is disastrous; all of them will cost you ten minutes on the day you trust the \
            \wrong one."
        fig
        defs
            [ ("The SYNOPSIS is wrong", do "It reads " ; c "htop [-dCFhpustvH]" ; ", but " ; c "-v" ; " does not exist — the version flag is " ; c "-V" ; ", and " ; c "htop -v" ; " answers " ; c "invalid option" ; ". The same line omits " ; c "-n" ; ", " ; c "-M" ; ", " ; c "-U" ; ", " ; c "--readonly" ; ", " ; c "--no-meters" ; " and " ; c "--no-function-bar" ; ".")
            , (c "-n" <> " is undocumented", do c "--max-iterations" ; " draws N frames and exits. It is in " ; c "--help" ; " and works; the manual page has never heard of it.")
            , ("Six interactive keys are missing", do k "#" ; " hides the header, " ; k "e" ; " shows the environment, " ; k "i" ; " sets I/O priority, " ; k "Y" ; " sets the scheduling policy, and " ; k "." ; " and " ; k "C" ; " are aliases for sort and Setup. All are in the " ; k "F1" ; " help.")
            , ("The sort-key aliases disagree", do "The page lists " ; k "F6" ; ", " ; k "<" ; ", " ; k ">" ; "; the help lists " ; k "F6" ; ", " ; k ">" ; ", " ; k "." ; ". All four work — each source has a different incomplete subset.")
            , ("COLUMNS is stale", do "No entry for " ; opt "ELAPSED" ; ", " ; opt "SCHEDULERPOLICY" ; ", " ; opt "SECATTR" ; ", " ; opt "CWD" ; ", " ; opt "CONTAINER" ; ", " ; opt "ISCONTAINER" ; ", " ; opt "GPU_TIME" ; " or " ; opt "GPU_PERCENT" ; ".")
            , (c "M_M_PSSWP" <> " does not exist", do "A typo for " ; opt "M_PSSWP" ; ". Copy it into a config and htop drops it in silence.")
            , ("The traced-state letter", do "COLUMNS says " ; c "T" ; " for traced or suspended; the " ; k "F1" ; " help says " ; c "t" ; ". Believe the help.")
            , ("METERS has lost some words", do "“Default CPU bar segments ( use text attributes instead of hues:” — an unclosed parenthesis and a missing subject. The content around it is correct.")
            , ("The rewrite rule is overstated", do "The page says the config “is overwritten upon clean exit”. In 3.5.3 it is overwritten only if a setting actually changed — and plain toggles like " ; k "t" ; ", " ; k "K" ; " and " ; k "I" ; " count, not just Setup.")
            , (c "fields=" <> " is undocumented entirely", do "The legacy numeric column list silently overrides " ; c "screen:Main=" ; " regardless of order. Nothing anywhere mentions it.")
            ]
        note $ p_ $ do
            "Two smaller ones, in the other direction: the page is "
            i_ "right"
            " that "
            c "-u"
            " accepts a UID as well as a username, where "
            c "--help"
            " mentions only a username; and "
            c "--help"
            " is right that "
            c "-H"
            " takes an optional delay, where the page implies it is mandatory. Neither source \
            \dominates — which is the actual lesson."

    block "What htop cannot tell you" $ do
        p_ "Four questions it is simply the wrong tool for. Knowing them is worth more than another key binding."
        defs
            [
                ( "“What was the peak?”"
                , do
                    "htop samples; peaks between samples do not exist for it. The kernel keeps a \
                    \high-water mark in "
                    c "/proc/PID/status"
                    " as "
                    c "VmHWM"
                    ", and htop has no column for it."
                )
            ,
                ( "“What happened last Tuesday?”"
                , do
                    "Nothing is recorded. Graph-mode meters keep a few screens' worth of history \
                    \and no more. This is what "
                    c "pcp-htop"
                    " and Performance Co-Pilot exist for."
                )
            ,
                ( "“Which of my fifty machines is unhappy?”"
                , "One host per htop, and one terminal per host. A fleet needs a metrics system."
                )
            ,
                ( "“Why is this process slow?”"
                , do
                    "htop narrows it to CPU, memory or I/O and hands you to something else — "
                    c "strace"
                    ", "
                    c "perf"
                    ", a profiler. Day 7's keys are the doorway, deliberately."
                )
            ]

    block "A note on pcp-htop" $ do
        p_ $ do
            "The manual page you have been reading also covers "
            c "pcp-htop"
            ", which is a separate binary: the same interface over Performance Co-Pilot metrics \
            \instead of "
            c "/proc"
            ". It reads its config from "
            c "~/.pcp/htop/htoprc"
            " so the two can coexist, and it can add meters, columns and whole screens from \
            \configuration files under the same directory."
        p_ $ do
            "That is the interesting part: it turns every PCP metric — including anything exported \
            \in OpenMetrics format — into something htop can display, and it can read from a remote \
            \host with "
            c "--host"
            ". This course does not cover it, because it is a different tool with its own manual \
            \page. If “what happened last Tuesday” is a question you keep having, "
            c "pcp-htop(5)"
            " is where to go next."

    block "Carrying your config between machines" $ do
        p_ $ do
            "You now have an "
            c "htoprc"
            " you can defend line by line. Two things keep it that way."
        steps
            [ do
                b_ "Version control it, and "
                c "chmod 444"
                " it once you are happy. htop rewrites the file in full — comments and all — the \
                \first time you change any setting and exit cleanly. Read-only stops that silently \
                \and costs you only the ability to save from Setup, which you no longer need."
            , do
                b_ "Use "
                c "$HTOPRC"
                " for per-machine differences. A laptop and a build server want different headers. \
                \Set it in your shell profile, and remember that if the file it names does not \
                \exist, htop uses built-in defaults and creates nothing — it does "
                i_ "not"
                " fall back to "
                c "~/.config/htop/htoprc"
                ", so a typo in the path presents as “my config stopped working”."
            ]
        gotcha $ p_ $ do
            "One flag to know about and leave alone: "
            c "--drop-capabilities"
            ". In "
            c "strict"
            " mode htop sheds almost everything, and the manual page is explicit that killing, \
            \renicing and delay accounting stop working as a result. It is a hardening option for \
            \an htop you leave running as root, not something to put in an alias — and if a \
            \colleague's htop mysteriously cannot renice anything, this is worth checking before \
            \you blame the kernel."

    block "Where to go next" $ do
        p_ $ do
            "The manual page's own "
            c "SEE ALSO"
            " is a good reading list, and the first entry is the important one."
        defs
            [ (c "proc(5)", "Where every number in this course actually comes from. Read the sections on " <> c "stat" <> ", " <> c "statm" <> ", " <> c "status" <> " and " <> c "smaps_rollup" <> " and htop stops being magic.")
            , (c "top(1)", "The ancestor. Worth knowing because it is on machines where htop is not, and because its Irix/Solaris mode vocabulary is where Day 1's " <> c "CPU%" <> " convention came from.")
            , (c "ps(1)", "For scripting. htop is for looking; " <> c "ps" <> " is for pipelines.")
            , (c "free(1)" <> ", " <> c "uptime(1)", "The header meters, as one-shot commands.")
            , (c "limits.conf(5)", "Why a process could not do the thing you were watching it fail to do.")
            , (c "pcp-htop(5)", "The recording version, and the extension format for custom meters and columns.")
            ]

    block "Today's habit" $ do
        p_ $ do
            "Keep the one that built this course: "
            b_ "when a tool and its documentation disagree, believe the tool, and write the \
                \disagreement down."
            " Ten of them turned up in a 768-line manual page for a program in its third major \
            \version and under active maintenance. That is not a criticism of htop — it is the \
            \normal condition of documentation, and the only defence is a habit of checking."
        p_ $ do
            "The practical form is small: before you rely on a flag, run "
            c "--help"
            ". Before you rely on a key, press "
            k "F1"
            ". Both take ten seconds and both are generated from the code."
        p_ $ do
            "That is the fortnight. You started able to tell that a machine was busy; you can now \
            \say which process, why, whether it is CPU or memory or I/O, what it belongs to, what \
            \it has open, and what to do about it — and you have a config file you wrote yourself, \
            \with a reason attached to every line."

cheat :: Html ()
cheat = do
    cfg
        [ "man htop vs the binary -- believe the binary:"
        , "  SYNOPSIS lists -v      -> it is -V; -n -M -U --readonly are missing entirely"
        , "  -n / --max-iterations  -> undocumented, works, exits after N frames"
        , "  # e i Y . C            -> six keys the page omits; all in the F1 help"
        , "  COLUMNS                -> no ELAPSED SCHEDULERPOLICY SECATTR CWD CONTAINER GPU_*"
        , "  M_M_PSSWP              -> typo; the column is M_PSSWP"
        , "  'T' for traced         -> the F1 help says 't'"
        , "  'overwritten on exit'  -> only if a setting CHANGED; t/K/I count"
        , "  fields=                -> undocumented, and it beats screen:Main="
        , ""
        , "htop cannot tell you:  the peak (see VmHWM in /proc/PID/status)"
        , "                       what happened yesterday (see pcp-htop)"
        , "                       anything about another machine"
        , ""
        , "chmod 444 ~/.config/htop/htoprc     # stop htop rewriting your comments"
        , "HTOPRC=~/dotfiles/htoprc.$(hostname) htop   # per-machine; NO fallback if missing"
        , ""
        , "next: proc(5) -- stat, statm, status, smaps_rollup.  Then top(1), ps(1), pcp-htop(5)."
        ]
