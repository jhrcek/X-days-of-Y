module Course.Day.D05 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 5
        , dayTitle = "Not printing the line"
        , daySubtitle = "Counts, names, fragments, silence — and why none of them change the exit status."
        , dayMinutes = 30
        , dayLevel = "intermediate"
        , dayManRef = "OPTIONS: General Output Control; ENVIRONMENT: GREP_COLORS"
        , dayTags = ["-c -l -L -o", "-q -m", "--color"]
        , dayGoals =
            [ "pick between " <> c "-c" <> ", " <> c "-l" <> " and " <> c "-o | wc -l" <> " for the number you actually want"
            , "explain why " <> c "if grep -L pat *.c" <> " takes the branch you did not intend"
            , "use " <> c "-q" <> " and " <> c "-m" <> " to stop grep early on input you cannot afford to read twice"
            ]
        , dayDiagram = Just d5diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds = []
        , dayOpts =
            [ ("-c, --count", "Print the number of selected " <> em_ "lines" <> " per file, not the number of matches.")
            , ("-l, --files-with-matches", "Print each filename that had a match, and stop reading that file at the first one.")
            , ("-L, --files-without-match", "Print each filename that had none. Read the gotcha about its exit status.")
            , ("-o, --only-matching", "Print each matched substring on its own line. Non-overlapping, empty matches dropped.")
            , ("-q, --quiet, --silent", "Print nothing; exit 0 on the first match. The right way to use grep as a test.")
            , ("-m NUM, --max-count=NUM", "Stop after NUM selected lines. " <> c "-m0" <> " reads nothing at all.")
            , ("-s, --no-messages", "Suppress error " <> em_ "messages" <> " about unreadable files. Does not change the exit status.")
            , ("--color[=WHEN]", "WHEN is " <> c "never" <> ", " <> c "always" <> " or " <> c "auto" <> ". Nothing else, and abbreviations are refused.")
            , ("GREP_COLORS", "Colon-separated SGR capabilities. Defaults to " <> c "ms=01;31:mc=01;31:sl=:cx=:fn=35:ln=32:bn=32:se=36" <> ".")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Run " <> c "grep -c bash /etc/passwd" <> ". One number. Now " <> c "grep -c bash /etc/passwd /etc/group" <> " — two lines, each prefixed with a filename, and the second is probably " <> c "0" <> "."
            , "See that " <> c "-c" <> " counts lines: " <> c "echo 'a1 b22 c333' | grep -cE '[0-9]'" <> " says " <> c "1" <> ". Then " <> c "echo 'a1 b22 c333' | grep -oE '[0-9]' | wc -l" <> " says " <> c "6" <> ". Those are different questions and only one of them has a flag."
            , "Break it on purpose: " <> c "grep --color=alway pattern file" <> ". One missing letter and grep prints its entire usage message to " <> em_ "standard output" <> " and exits " <> c "0" <> ". In a pipeline that help text becomes your data."
            , "Walk into the " <> c "-L" <> " trap deliberately. In a directory where every file matches, run " <> c "grep -L pattern *; echo $?" <> ". Nothing printed, status " <> c "0" <> ". Then use a pattern nothing matches: every filename printed, status " <> c "1" <> "."
            , "Use " <> c "-q" <> " the way it is meant: " <> c "if grep -q '^PermitRootLogin yes' /etc/ssh/sshd_config; then echo bad; fi" <> ". No output, no pipe, and it stops reading at the first hit."
            , "Stop early on something huge: " <> c "grep -m5 . /var/log/syslog" <> ", or any big file. Compare how long " <> c "grep -c ." <> " takes on the same file — " <> c "-m" <> " does not read the rest."
            , "On your own work: find which of your source files mention a symbol, with " <> c "grep -rl symbolname ." <> ". That is the fastest question grep can answer, because it abandons each file at the first match."
            , "Add to " <> c "~/grep-recipes.sh" <> " the occurrence-counting idiom, with a comment saying why " <> c "-c" <> " is not it."
            ]
        , dayQuiz =
            [
                ( "A CI check is supposed to fail when any source file is missing a licence header. It runs "
                    <> c "if grep -L 'SPDX-License' src/*.c; then echo 'missing headers'; exit 1; fi"
                    <> ". Every file is missing the header, and the check passes. Why?"
                , do
                    p_ $ do
                        "Because "
                        c "-L"
                        " inverts the "
                        em_ "output"
                        " but not the "
                        em_ "status"
                        ". The exit status still answers “was any line selected anywhere?”. No file contained the string, so no line was selected, so grep exits "
                        c "1"
                        " — while printing every filename. The "
                        c "if"
                        " sees failure and skips the branch."
                    p_ $ do
                        "Worse, it is exactly backwards: when every file "
                        em_ "does"
                        " have the header, "
                        c "-L"
                        " prints nothing and exits "
                        c "0"
                        ", so the check fires. Test the output, not the status: "
                        c "if [ -n \"$(grep -L 'SPDX-License' src/*.c)\" ]; then ..."
                        "."
                )
            ,
                ( "You want the number of times a word appears in a file, and "
                    <> c "grep -c word file"
                    <> " gives a number that is too low. Adding "
                    <> c "-o"
                    <> " does not help. What is going on?"
                , do
                    p_ $ do
                        c "-c"
                        " counts "
                        b_ "selected lines"
                        ", not matches. A line containing the word three times counts once. And combining the two does not compose: "
                        c "grep -oc"
                        " gives you the "
                        c "-c"
                        " behaviour, because "
                        c "-c"
                        " suppresses normal output and "
                        c "-o"
                        " only changes what normal output would have been."
                    p_ $ do
                        "The idiom is "
                        c "grep -o word file | wc -l"
                        ". Be aware it counts non-overlapping matches — "
                        c "grep -o aa"
                        " finds two in "
                        c "aaaa"
                        ", not three — and that empty matches are dropped, so "
                        c "grep -o 'x*'"
                        " prints nothing while still exiting "
                        c "0"
                        "."
                )
            ,
                ( "The manual says that with "
                    <> c "-o"
                    <> ", the "
                    <> c "-A"
                    <> ", "
                    <> c "-B"
                    <> " and "
                    <> c "-C"
                    <> " options “have no effect and a warning is given”. You try it and see no warning. Who is wrong?"
                , do
                    p_ $ do
                        "The manual. In GNU grep 3.12, "
                        c "grep -o -A2 pattern file"
                        " prints the matched substrings, ignores the context request, and writes "
                        b_ "nothing at all"
                        " to standard error — zero bytes. The same is true for "
                        c "-B"
                        " and "
                        c "-C"
                        "."
                    p_ $ do
                        "The page's own NOTES section admits it “is maintained only fitfully”, and this is one of the places that shows. The practical consequence is that a script asking for both gets silently less than it asked for, with no diagnostic and exit status "
                        c "0"
                        ". Treat "
                        c "-o"
                        " and context as mutually exclusive and never write both."
                )
            ,
                ( "Your script does "
                    <> c "grep -s pattern \"$file\""
                    <> " to keep quiet about files that may not exist, and it still behaves differently when the file is missing. But there is no error on screen."
                , do
                    p_ $ do
                        c "-s"
                        " suppresses the error "
                        em_ "message"
                        " only. The exit status is still "
                        c "2"
                        ", and anything testing that status — an "
                        c "if"
                        ", a "
                        c "&&"
                        ", "
                        c "set -e"
                        " — behaves exactly as it did before. You have hidden the evidence and kept the symptom."
                    p_ $ do
                        "If you genuinely want a missing file treated as “no match”, you have to say so: "
                        c "grep -s pattern \"$file\" || [ $? -eq 1 ]"
                        " is unreadable but honest, and testing "
                        c "[ -f \"$file\" ]"
                        " first is usually better. Day 9 puts this together properly."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d5diagram :: Diagram
d5diagram =
    ( diagram
        "The line itself, a per-file count, a file name and a matched substring are four kinds of report grep can print about the selected lines; none of them affects the exit status."
        body'
    )
        { dgCaption = do
            "These options do not change "
            em_ "which"
            " lines are selected — Day 2 settled that — only what grep prints about them. The dashed aspect is the one that catches people: whichever report you choose, the exit status still answers the original question, “was any line selected?”. That is why "
            c "-L"
            " can print a screen full of filenames and exit "
            c "1"
            "."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  sel  [label=\"a selected line\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  rep  [label=\"a report\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  whole[label=\"the line itself\\n(the default)\"];"
            , "  cnt  [label=\"a count per file\\n(-c)\"];"
            , "  fn   [label=\"a file name\\n(-l, -L)\"];"
            , "  frag [label=\"a matched substring\\n(-o)\"];"
            , "  st   [label=\"an exit status\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  whole -> rep [label=\"  is\"];"
            , "  cnt   -> rep [label=\"  is\"];"
            , "  fn    -> rep [label=\"  is\"];"
            , "  frag  -> rep [label=\"  is\"];"
            , "  whole -> sel [label=\"  is\"];"
            , "  cnt   -> sel [label=\"  counts\"];"
            , "  fn    -> sel [label=\"  names the file holding\"];"
            , "  frag  -> sel [label=\"  is part of\"];"
            , "  rep   -> st  [label=\"  never changes  \", style=dashed, constraint=false];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Same lines, different report" $ do
        p_ [class_ "lede"] $ do
            "Nothing on this page changes which lines match. Every option here changes only what grep "
            em_ "prints"
            " about the lines that already matched — a count instead of the line, a filename instead of the line, a fragment instead of the line, or nothing at all."
        p_ $ do
            "Keeping that separation clear is what stops the classic mistakes. "
            c "-c"
            " does not count matches, it counts selected lines. "
            c "-o"
            " does not change the selection, it slices up what gets printed. And none of them touches the exit status, which is where the sharpest trap on this page lives."
        fig

    block "Counting the thing you meant to count" $ do
        sh
            [ "$ echo 'a1 b22 c333' | grep -cE '[0-9]'"
            , "1"
            , "$ echo 'a1 b22 c333' | grep -oE '[0-9]' | wc -l"
            , "6"
            ]
        p_ $ do
            "One selected line; six matching digits. "
            c "-c"
            " answers the first question and there is no flag for the second — "
            c "-o | wc -l"
            " is the idiom, and it is worth learning as a unit."
        gotcha $ do
            p_ $ do
                "The output-control options do not compose; they override each other in a fixed priority. "
                c "grep -oc"
                " behaves as "
                c "-c"
                " and "
                c "grep -lc"
                " behaves as "
                c "-l"
                ". The measured order is "
                c "-q"
                " over "
                c "-l"
                "/"
                c "-L"
                " over "
                c "-c"
                " over "
                c "-o"
                ", regardless of the order you write them in — except that "
                c "-l"
                " and "
                c "-L"
                " are peers, where the last one on the line wins. There is no warning about any of this. If you want two different reports you run grep twice."
        p_ $ do
            "Two smaller facts about "
            c "-o"
            ": matches are non-overlapping, so "
            c "aaaa"
            " yields two "
            c "aa"
            " and not three; and empty matches are discarded, so "
            c "grep -o 'x*'"
            " prints nothing while still reporting success, because the line did match — the match was just zero characters wide."

    block "Filenames, and the exit status that lies about them" $ do
        p_ $ do
            c "-l"
            " prints the name of each file that had a match; "
            c "-L"
            " prints the name of each file that did not. "
            c "-l"
            " is also the fastest question you can ask grep, because it abandons each file at the first match rather than reading to the end."
        sh
            [ "$ grep -L beta c1.txt c2.txt"
            , "c2.txt"
            , "$ echo $?"
            , "0"
            , "$ grep -L zzz c1.txt c2.txt"
            , "c1.txt"
            , "c2.txt"
            , "$ echo $?"
            , "1"
            ]
        gotcha $ do
            p_ $ do
                "Read those two statuses again. "
                c "-L"
                " printed "
                em_ "one"
                " filename and exited "
                c "0"
                "; it printed "
                em_ "both"
                " filenames and exited "
                c "1"
                ". The status is not about what "
                c "-L"
                " printed — it is still answering “was a line selected anywhere?”, and with "
                c "-L"
                " that is the opposite of what the output shows."
            p_ $ do
                "So "
                c "if grep -L pat *.c"
                " fires precisely when nothing is missing. Any check built on "
                c "-L"
                " must test the output, not the status."

    block "Stopping early: -q and -m" $ do
        defs
            [
                ( c "-q"
                , do
                    "Print nothing and exit "
                    c "0"
                    " the instant a line is selected. This is grep-as-predicate, and it is strictly better than "
                    c "grep ... > /dev/null"
                    " because it stops reading. Remember from Day 1 that it exits 0 even if an error also occurred."
                )
            ,
                ( c "-m NUM"
                , do
                    "Stop after NUM selected lines. "
                    c "-m0"
                    " exits immediately without reading anything. With "
                    c "-c"
                    ", the count never exceeds NUM. With "
                    c "-v"
                    ", it counts NUM "
                    em_ "non"
                    "-matching lines."
                )
            ]
        tip $ do
            p_ $ do
                c "-m"
                " has a property that is easy to miss and occasionally invaluable: when standard input is a regular file, grep leaves the file offset positioned just after the last matching line before it exits. A second command reading the same descriptor resumes where grep stopped, which is how you write a two-stage parser in shell without a temporary file."

    block "Colour, and the typo that eats your output" $ do
        p_ $ do
            opt "--color"
            " takes "
            c "never"
            ", "
            c "always"
            " or "
            c "auto"
            ". "
            c "auto"
            " means “only when standard output is a terminal”, which is why your interactive greps are coloured and the same command in a pipeline is not. Use "
            c "always"
            " when you deliberately want the escape sequences to survive a pipe into "
            c "less -R"
            "."
        gotcha $ do
            p_ $ do
                "Give "
                opt "--color"
                " anything else — including an abbreviation like "
                c "alway"
                " or "
                c "al"
                " — and grep prints its entire usage message to "
                b_ "standard output"
                ", writes nothing to standard error, and exits "
                b_ "0"
                ". In a pipeline your search results are silently replaced by a help screen and every status check says it worked. It is the one grep typo that is genuinely dangerous in a script."
        p_ $ do
            "The colours themselves come from "
            c "GREP_COLORS"
            ", a colon-separated list of SGR capabilities that defaults to "
            c "ms=01;31:mc=01;31:sl=:cx=:fn=35:ln=32:bn=32:se=36"
            " — bold red for the match, magenta for filenames, green for line numbers and byte offsets, cyan for the separators. Setting "
            c "mt"
            " changes both "
            c "ms"
            " and "
            c "mc"
            " at once, which is the only one most people ever want."
        sh
            [ "$ GREP_COLORS='mt=01;33' grep --color=always ERROR app.log | less -R"
            ]
        p_ $ do
            "The full capability list runs to about seventy lines of the manual page and is a lookup table rather than a concept; this course does not reproduce it. "
            c "man grep"
            " under "
            c "GREP_COLORS"
            " is the reference, and the SGR numbers themselves belong to your terminal, not to grep."

    block "Today's habit" $ do
        p_ $ do
            "Before you run a grep, decide which of the five reports you want — the line, a count, a filename, a fragment, or just the answer yes-or-no — and ask for that one. Most slow, noisy greps are someone printing lines and reading them with their eyes when they wanted "
            c "-l"
            "."
        cfg
            [ "# ~/grep-recipes.sh"
            , "#"
            , "# Day 5: count OCCURRENCES, not lines. -c cannot do this."
            , "grep -o PATTERN file | wc -l"
            , ""
            , "# Day 5: which files mention this symbol? Fastest question grep answers -"
            , "# -l abandons each file at the first hit."
            , "grep -rl SYMBOL ."
            , ""
            , "# Day 5: -L's status is the OPPOSITE of its output. Test the output."
            , "[ -n \"$(grep -L 'SPDX-License' src/*.c)\" ] && echo 'missing headers'"
            ]

cheat :: Html ()
cheat =
    cfg
        [ "-c   count selected LINES per file   (not matches - use -o | wc -l for those)"
        , "-l   name each file that matched     (stops reading it at the first hit)"
        , "-L   name each file that did NOT     (its EXIT STATUS is inverted - see below)"
        , "-o   print each match on its own line (non-overlapping; empty matches dropped)"
        , "-q   print nothing, exit 0 at the first match   (grep as an if-condition)"
        , "-m N stop after N selected lines     (-m0 reads nothing at all)"
        , "-s   hide error MESSAGES only - the exit status is still 2"
        , ""
        , "# these do not compose; they override, whatever order you write them in:"
        , "#   -q  >  -l / -L  >  -c  >  -o     (-l vs -L: the LAST one on the line wins)"
        , "# -L trap:  prints nothing + exits 0 = every file matched"
        , "#           prints everything + exits 1 = no file matched"
        , "# --color takes never|always|auto ONLY. A typo prints usage to STDOUT, exits 0."
        ]
