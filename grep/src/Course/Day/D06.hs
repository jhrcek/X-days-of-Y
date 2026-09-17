module Course.Day.D06 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 6
        , dayTitle = "Lines around the line"
        , daySubtitle = "Context, prefixes, and the colon-versus-hyphen distinction nobody notices."
        , dayMinutes = 30
        , dayLevel = "intermediate"
        , dayManRef = "OPTIONS: Context Line Control, Output Line Prefix Control"
        , dayTags = ["-A -B -C", "-n -H -b", "separators"]
        , dayGoals =
            [ "read a grep -C listing and tell a hit from its context without counting lines"
            , "explain when the " <> c "--" <> " group separator appears and when it silently does not"
            , "parse grep's own output safely, prefix fields and all"
            ]
        , dayDiagram = Just d6diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds = []
        , dayOpts =
            [ ("-A NUM, --after-context=NUM", "Print NUM lines after each match.")
            , ("-B NUM, --before-context=NUM", "Print NUM lines before each match.")
            , ("-C NUM, --context=NUM", "Print NUM lines on both sides.")
            , ("-NUM", "Bare number: identical to " <> c "-C NUM" <> ". " <> c "grep -2 pat" <> " is the one worth typing.")
            , ("--group-separator=SEP", "Print SEP instead of " <> c "--" <> " between non-adjacent groups.")
            , ("--no-group-separator", "Print no separator at all. What you want before piping into another tool.")
            , ("-n, --line-number", "Prefix each output line with its 1-based line number.")
            , ("-H, --with-filename", "Force the filename prefix. Automatic with two or more files.")
            , ("-h, --no-filename", "Suppress the filename prefix. Automatic with one file.")
            , ("-b, --byte-offset", "Prefix the 0-based byte offset. With " <> c "-o" <> ", the offset of the match itself.")
            , ("-T, --initial-tab", "Line the content up on a tab stop, and pad the numeric fields to a fixed width.")
            , ("--label=LABEL", "Call standard input LABEL instead of " <> c "(standard input)" <> ".")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Take any log you have and run " <> c "grep -n -C2 ERROR" <> " over it. Look at the characters after the line numbers: the hits have a " <> c ":" <> ", the context lines have a " <> c "-" <> ". You have been reading past that for years."
            , "Widen the context until the groups merge: " <> c "grep -n -C1 ERROR app.log" <> " shows a " <> c "--" <> " between groups; " <> c "grep -n -C5 ERROR app.log" <> " on the same file shows none, because the two windows now overlap and became one group."
            , "Type the short form. " <> c "grep -2 ERROR app.log" <> " is exactly " <> c "-C2" <> " and is three keystrokes shorter; confirm with " <> c "diff <(grep -2 ERROR app.log) <(grep -C2 ERROR app.log)" <> "."
            , "Break a parser on purpose: run " <> c "grep -n -C1 ERROR app.log | cut -d: -f1" <> " and watch the context lines come through as the whole line rather than a number, because their separator is a hyphen. Then add " <> c "--no-group-separator" <> " and see the " <> c "--" <> " lines still ruin it."
            , "Force the filename on a single file: " <> c "grep -Hn ERROR app.log" <> ". Then get it for free the cheap old way — " <> c "grep -n ERROR app.log /dev/null" <> " — and notice the empty file exists purely to push grep over the two-file threshold."
            , "Label a pipe properly: " <> c "gzip -cd old.log.gz | grep -Hn --label=old.log ERROR" <> ". Without " <> c "--label" <> " you get the useless " <> c "(standard input)" <> "."
            , "On your own work: find a function definition in a source file with " <> c "grep -n -A20 'def process' *.py" <> " (or your language's equivalent) and read the body without opening an editor."
            , "Add to " <> c "~/grep-recipes.sh" <> " the context invocation you will actually use, with " <> c "--no-group-separator" <> " if it is destined for a pipe."
            ]
        , dayQuiz =
            [
                ( "You run "
                    <> c "grep -n -C2 ERROR app.log | cut -d: -f1"
                    <> " expecting a list of line numbers and get a mixture of numbers and whole log lines. What did you forget?"
                , do
                    p_ $ do
                        "That context lines use a different separator. grep joins the prefix fields of a "
                        em_ "selected"
                        " line with "
                        c ":"
                        " and those of a "
                        em_ "context"
                        " line with "
                        c "-"
                        ". So "
                        c "3:ERROR ..."
                        " splits on the colon and "
                        c "4-INFO ..."
                        " does not."
                    p_ $ do
                        "The "
                        c "--"
                        " group separator lines have no prefix at all and will also come through untouched. If you are parsing, the answer is not to ask for context: get the line numbers with a plain "
                        c "grep -n"
                        " and expand the windows yourself. Context output is designed for a human reading it."
                )
            ,
                ( "Two greps over the same file, one with "
                    <> c "-C1"
                    <> " and one with "
                    <> c "-C5"
                    <> ". The first prints "
                    <> c "--"
                    <> " between the groups and the second prints none. Neither command mentions separators."
                , do
                    p_ $ do
                        "The separator marks a "
                        em_ "gap"
                        ", not a match. With "
                        c "-C1"
                        " the two context windows do not reach each other, so there is a stretch of unprinted file between them and grep marks it. With "
                        c "-C5"
                        " the windows overlap, the output is one contiguous run of lines, and there is no gap to mark."
                    p_ $ do
                        "So the presence of "
                        c "--"
                        " tells you something real: lines are missing there. That also makes it unreliable as a record delimiter, because whether it appears depends on the data. "
                        opt "--no-group-separator"
                        " removes it, and "
                        opt "--group-separator=SEP"
                        " replaces it with something you chose."
                )
            ,
                ( "Why does "
                    <> c "grep -n pattern *.c"
                    <> " show filenames but the same command against a single file not, and what is the "
                    <> c "/dev/null"
                    <> " trick the manual's EXAMPLE section uses?"
                , do
                    p_ $ do
                        "grep prefixes filenames when it has two or more file operands and suppresses them when it has one — the "
                        c "--help"
                        " text puts it as “with fewer than two FILEs, assume "
                        c "-h"
                        "”. With a glob that is a problem, because the number of operands depends on how many files happen to exist, so the same command changes output format as the directory changes."
                    p_ $ do
                        "The old fix is to add "
                        c "/dev/null"
                        " as an extra operand: it is always readable, always empty, never matches, and pushes the count to two. The modern fix is "
                        c "-H"
                        ", which says what you mean. The manual keeps the trick because the example also demonstrates "
                        c "--"
                        ", and both are worth recognising in other people's scripts."
                )
            ,
                ( "Your script does "
                    <> c "zcat archive.log.gz | grep -n ERROR"
                    <> " and the output is prefixed with "
                    <> c "(standard input)"
                    <> " once you add a second input. How do you make the label useful, and why can grep not work it out itself?"
                , do
                    p_ $ do
                        "Use "
                        opt "--label"
                        ": "
                        c "zcat archive.log.gz | grep -Hn --label=archive.log ERROR"
                        ". grep cannot infer it because by the time the bytes arrive they have no filename — the pipe is anonymous, and the process that knew the name was "
                        c "zcat"
                        ", which has already forgotten."
                    p_ $ do
                        "This is the same reason "
                        c "-H"
                        " is needed alongside it when there is only one input: "
                        opt "--label"
                        " supplies the name, "
                        c "-H"
                        " asks for it to be printed. Neither implies the other."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d6diagram :: Diagram
d6diagram =
    ( diagram
        "An output line is either a selected line or a context line; it may carry prefix fields joined by a field separator, and that separator reveals which kind of line it is. A group separator is printed between non-adjacent groups."
        body'
    )
        { dgCaption = do
            "The aspect worth remembering is the dashed one. grep encodes the difference between a hit and its context in a single character — "
            c ":"
            " after the prefix fields of a selected line, "
            c "-"
            " after those of a context line. It is the only machine-readable part of context output, and it is why "
            c "cut -d:"
            " falls apart the moment you add "
            c "-C"
            "."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  out  [label=\"an output line\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  sel  [label=\"a selected line\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  ctx  [label=\"a context line\\n(-A, -B, -C)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  pfx  [label=\"a prefix field\\nname, line no., offset\"];"
            , "  fsep [label=\"a field separator\\n: or -\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  grp  [label=\"a group of\\nadjacent lines\"];"
            , "  gsep [label=\"a group separator\\n--\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  sel  -> out  [label=\"  is\"];"
            , "  ctx  -> out  [label=\"  is\"];"
            , "  ctx  -> sel  [label=\"  is within NUM lines of\"];"
            , "  out  -> pfx  [label=\"  may carry\"];"
            , "  pfx  -> fsep [label=\"  is followed by\"];"
            , "  grp  -> out  [label=\"  is a run of\"];"
            , "  gsep -> grp  [label=\"  is printed between\"];"
            , "  fsep -> out  [label=\"  reveals the kind of  \", style=dashed, constraint=false];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "A match is rarely the thing you wanted to read" $ do
        p_ [class_ "lede"] $ do
            "A stack trace, a config stanza, the body of a function, the request that preceded the error — none of these are one line. Context options let grep print the neighbourhood of a match, and they turn grep from a line filter into a passable file reader."
        p_ $ do
            c "-A NUM"
            " prints lines after, "
            c "-B NUM"
            " before, "
            c "-C NUM"
            " both. There is also a bare "
            c "-NUM"
            ", which is exactly "
            c "-C NUM"
            " — "
            c "grep -2 ERROR"
            " is the form worth putting in your fingers, and it is one of the very few options in any Unix tool that is just a number."
        fig

    block "The colon and the hyphen" $ do
        sh
            [ "$ grep -n -C1 ERROR app.log"
            , "2-INFO  connected to db"
            , "3:ERROR timeout talking to db"
            , "4-INFO  retrying"
            , "--"
            , "7-INFO  steady state"
            , "8:ERROR timeout talking to db"
            , "9-INFO  giving up"
            ]
        p_ $ do
            "Look at what follows the line numbers. Lines 3 and 8 matched, and their prefix is closed with a "
            c ":"
            ". Lines 2, 4, 7 and 9 are context, and theirs is closed with a "
            c "-"
            ". The same rule applies to the filename prefix when there is one."
        why $ do
            p_ $ do
                "It is the only way to distinguish the two once the line numbers are gone — and in the common case of "
                c "grep -C2 pat file"
                " with no "
                c "-n"
                ", it is the only marker at all. The choice of "
                c "-"
                " is not arbitrary either: it makes context output visually recede, so a wall of "
                c "grep -C3"
                " reads as blocks with a highlighted line in each, which is exactly how you want to scan it."
        gotcha $ do
            p_ $ do
                "This breaks every naive parser. "
                c "grep -n -C2 pat file | cut -d: -f1"
                " gives you line numbers for the matches and entire log lines for the context. If you are going to process the output, do not ask for context — get the line numbers from a plain "
                c "grep -n"
                " and open the windows yourself."

    block "The -- that means “lines are missing here”" $ do
        p_ $ do
            "Between two groups of output that are not adjacent in the file, grep prints a line containing "
            c "--"
            ". It marks a gap, not a match, and whether it appears depends entirely on the data."
        sh
            [ "$ grep -n -C3 ERROR app.log"
            , "1-INFO  starting worker 1"
            , "2-INFO  connected to db"
            , "3:ERROR timeout talking to db"
            , "4-INFO  retrying"
            , "5-INFO  connected to db"
            , "6-INFO  steady state"
            , "7-INFO  steady state"
            , "8:ERROR timeout talking to db"
            , "9-INFO  giving up"
            ]
        p_ $ do
            "Same file, same pattern, wider context — and no separator anywhere, because the two windows now touch and the output is one contiguous run. Widen or narrow the context and the delimiters in your output appear and disappear."
        defs
            [ (opt "--no-group-separator", "Drop it entirely. Use this before piping context output anywhere.")
            , (opt "--group-separator=SEP", do "Replace it. " <> c "--group-separator=" <> " with an empty value gives you a blank line between groups, which reads well in a terminal.")
            ]
        note $ do
            p_ $ do
                "Remember from Day 5 that combining "
                c "-o"
                " with any of "
                c "-A"
                ", "
                c "-B"
                " or "
                c "-C"
                " silently does nothing — the manual promises a warning that GNU grep 3.12 does not emit. There is no way to get context around a "
                c "-o"
                " fragment; the two ideas do not fit together."

    block "Prefix fields" $ do
        p_ $ do
            "Everything before the separator is a prefix field, and they appear in a fixed order: filename, line number, byte offset."
        defs
            [ (c "-n", "The 1-based line number. The single most useful option in this course when you are about to open an editor.")
            , (c "-H" <> " / " <> c "-h", do "Force or suppress the filename. The default is “on with two or more file operands”, which means a glob can change your output format depending on how many files matched it.")
            , (c "-b", do "The 0-based byte offset of the line — or, with " <> c "-o" <> ", of the matched substring itself. Useful for seeking into a file you are not going to read linearly.")
            , (c "-T", "Put the content on a tab stop and pad the numeric fields to a fixed width, so a multi-file listing lines up.")
            , (opt "--label", do "Rename " <> c "(standard input)" <> " to something meaningful. Needs " <> c "-H" <> " to actually show.")
            ]
        sh
            [ "$ grep -bn ERROR app.log"
            , "3:46:ERROR timeout talking to db"
            , "8:149:ERROR timeout talking to db"
            , "$ grep -bo timeout app.log"
            , "52:timeout"
            , "155:timeout"
            ]
        p_ $ do
            "Line 3 begins at byte 46; the word "
            c "timeout"
            " within it begins at byte 52. That change of meaning under "
            c "-o"
            " is deliberate and documented, and it is what makes "
            c "-b"
            " usable for indexing."
        tip $ do
            p_ $ do
                "The manual's own EXAMPLE section ends with "
                c "/dev/null"
                " as an extra file operand — "
                c "grep -n -- 'f.*\\.c$' *g*.h /dev/null"
                ". It is there to guarantee at least two operands so filenames are printed even when the glob expands to one file. "
                c "-H"
                " does the same job and says so out loud; recognise the older trick, write the newer one."

    block "Today's habit" $ do
        p_ $ do
            "Add "
            c "-n"
            " to every grep you run against source code, permanently. The line number costs nothing, and it is the difference between finding a thing and being able to go to it."
        cfg
            [ "# ~/grep-recipes.sh"
            , "#"
            , "# Day 6: read a log around its errors. -2 is -C2, and shorter."
            , "grep -n -2 ERROR app.log"
            , ""
            , "# Day 6: context destined for another program - kill the -- separator."
            , "grep -n -C2 --no-group-separator PATTERN file"
            , ""
            , "# Day 6: name a pipe so the prefix is not '(standard input)'."
            , "gzip -cd old.log.gz | grep -Hn --label=old.log ERROR"
            ]

cheat :: Html ()
cheat =
    cfg
        [ "-A n  after      -B n  before      -C n  both      -n  is short for -C n"
        , "--no-group-separator      drop the '--' (do this before piping)"
        , "--group-separator=SEP     replace it"
        , ""
        , "# reading the output:   PREFIXES then SEPARATOR then content"
        , "#   3:ERROR ...   ':' = this line MATCHED"
        , "#   4-INFO  ...   '-' = this line is CONTEXT"
        , "#   --            a gap: lines are missing here (absent if windows overlap)"
        , ""
        , "-n  line number   -H/-h  force/suppress filename   -b  byte offset"
        , "-T  align content on a tab stop   --label=NAME  rename '(standard input)'"
        , "#  filenames appear automatically with 2+ file operands - so a glob can"
        , "#  change your output format. Say -H instead of adding /dev/null."
        , "#  -b with -o gives the offset of the MATCH, not of the line."
        ]
