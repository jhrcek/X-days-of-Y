module Course.Day.D08 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 8
        , dayTitle = "When grep lies to you"
        , daySubtitle = "Binary files that are not binary, and the environment variable that decides."
        , dayMinutes = 35
        , dayLevel = "advanced"
        , dayManRef = "OPTIONS: --binary-files; ENVIRONMENT"
        , dayTags = ["binary", "locale", "speed"]
        , dayGoals =
            [ "explain why a perfectly good text file is reported as binary, and fix it two ways"
            , "know which patterns " <> c "LC_ALL=C" <> " makes dramatically faster and which it does not touch"
            , "recognise a locale bug from the symptom, before you start debugging the pattern"
            ]
        , dayDiagram = Just d8diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds = []
        , dayOpts =
            [ ("--binary-files=TYPE", "TYPE is " <> c "binary" <> " (default), " <> c "text" <> " or " <> c "without-match" <> ".")
            , ("-a, --text", "Treat binary input as text. Equivalent to " <> c "--binary-files=text" <> ".")
            , ("-I", "Treat binary input as non-matching. Equivalent to " <> c "--binary-files=without-match" <> ".")
            , ("LC_ALL", "Overrides every locale category at once. The variable to set in a script.")
            , ("LC_CTYPE", "Decides the character encoding: what a character is, and what is whitespace.")
            , ("LC_COLLATE", "Decides collating order, which is what range expressions like " <> c "[a-z]" <> " consult.")
            , ("LANG", "The fallback when neither " <> c "LC_ALL" <> " nor the specific " <> c "LC_*" <> " variable is set.")
            , ("POSIXLY_CORRECT", "Stops grep permuting options after file names. Changes parsing, not matching.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Make a binary file and watch grep refuse it: " <> c "printf 'hello\\0world\\nmatch me\\n' > bin.dat" <> ", then " <> c "grep match bin.dat" <> ". You get a message on " <> em_ "standard error" <> " and nothing on standard output — but " <> c "echo $?" <> " says " <> c "0" <> "."
            , "Show that the count still works: " <> c "grep -c match bin.dat" <> " says " <> c "1" <> " and " <> c "grep -l match bin.dat" <> " names the file. Only the printing of lines was suppressed; the matching happened as normal."
            , "Now the interesting one. " <> c "printf 'caf\\xe9 match\\nplain match\\n' > latin.txt" <> " is valid Latin-1 text with no NUL bytes anywhere. Run " <> c "grep match latin.txt" <> " and watch grep call it binary."
            , "Fix it twice: " <> c "grep -a match latin.txt" <> " forces it, and " <> c "LC_ALL=C grep match latin.txt" <> " makes the problem disappear entirely because in the C locale every byte is a valid character."
            , "Measure the speed claim yourself on a large file: " <> c "time LC_ALL=en_US.UTF-8 grep -c '[a-z]\\{4\\}x' big.txt" <> " against " <> c "time LC_ALL=C grep -c '[a-z]\\{4\\}x' big.txt" <> ". Then repeat with a plain literal like " <> c "zzzz" <> " and watch the difference vanish."
            , "Break option parsing on purpose: " <> c "grep ERROR app.log -c" <> " prints a count, and " <> c "POSIXLY_CORRECT=1 grep ERROR app.log -c" <> " treats " <> c "-c" <> " as a filename — so you get prefixed lines, an error about a missing file, and exit 2. Your script's behaviour depends on a variable you did not set."
            , "On your own work: take a real log and run " <> c "grep -c ERROR yourlog > /dev/null" <> " (any pattern that actually occurs). If stderr says " <> c "binary file matches" <> ", that file has NUL bytes or encoding errors in it. Re-run under " <> c "LC_ALL=C" <> " — if the complaint disappears, it was an encoding error rather than a NUL."
            , "Add to " <> c "~/grep-recipes.sh" <> " the " <> c "LC_ALL=C" <> " form, with a comment saying it is for speed and byte-exactness, not for correctness on real text."
            ]
        , dayQuiz =
            [
                ( "A UTF-8 log file from a customer makes "
                    <> c "grep ERROR customer.log"
                    <> " print a couple of lines and then stop, with “binary file matches” on stderr. The file opens fine in your editor. Nothing in it is a NUL byte."
                , do
                    p_ $ do
                        "The file is not valid UTF-8 somewhere — a stray Latin-1 byte, a truncated multibyte sequence, a mangled emoji. In a UTF-8 locale those bytes are not characters, and grep counts “improperly encoded data” as binary exactly as it counts NUL bytes. It then suppresses lines containing the bad bytes and tells you on stderr."
                    p_ $ do
                        "Two fixes, and they are not equivalent. "
                        c "grep -a"
                        " forces the lines out but they will still be mis-decoded on your terminal. "
                        c "LC_ALL=C grep"
                        " changes the definition of “character” to “byte”, so nothing is an encoding error any more, matching is byte-exact, and it is usually faster too. For log triage, "
                        c "LC_ALL=C"
                        " is the better instinct."
                )
            ,
                ( "You read that "
                    <> c "LC_ALL=C"
                    <> " makes grep “ten times faster”, so you put it in front of every grep in a build script. Timings do not improve. Were you lied to?"
                , do
                    p_ $ do
                        "Half lied to. The speedup is real but specific to patterns that have to reason about "
                        em_ "characters"
                        ": bracket expressions, named classes, case folding, "
                        c "."
                        " — anything where grep must decode multibyte sequences to know what it is looking at. On a 20 MB file, "
                        c "[a-z]\\{4\\}x"
                        " took 0.72 s in "
                        c "en_US.UTF-8"
                        " and 0.03 s in "
                        c "C"
                        ", which is roughly 24×."
                    p_ $ do
                        "A plain literal search on the same file took 0.01 s in both locales, because the Boyer-Moore fast path never decodes anything. So "
                        c "LC_ALL=C"
                        " is worth reaching for when the pattern is character-classy and the input is large, and is noise otherwise. Measure before you sprinkle it everywhere."
                )
            ,
                ( "The manual page says that under "
                    <> c "POSIXLY_CORRECT"
                    <> ", unrecognised options are diagnosed as “illegal” rather than “invalid”. You test it and get “invalid option” either way. Which behaviour does the variable actually change?"
                , do
                    p_ $ do
                        "The wording claim is simply stale — GNU grep 3.12 says "
                        c "invalid option -- 'Q'"
                        " with and without the variable set. What "
                        c "POSIXLY_CORRECT"
                        " genuinely changes is "
                        b_ "argument permutation"
                        ": by default grep moves options that appear after file names to the front and honours them, and POSIX requires that they be treated as file names instead."
                    p_ $ do
                        "So "
                        c "grep pattern file.txt -c"
                        " prints a count normally and fails with "
                        c "-c: No such file or directory"
                        " under the variable. That is a real behavioural difference in something as ordinary as a shell script, triggered by an environment variable that a caller may have set for entirely unrelated reasons. Put options before operands and it can never bite you."
                )
            ,
                ( "Your CI grep matches accented words correctly on your laptop and fails inside the container. Same image, same file, same pattern, same grep version."
                , do
                    p_ $ do
                        "The container has no locale set, so everything falls back to C. In the C locale each byte is a separate character, case folding is ASCII-only, and a UTF-8 “é” is two bytes that "
                        c "."
                        " matches as two characters rather than one. A pattern like "
                        c "caf."
                        " or "
                        c "-i 'CAFÉ'"
                        " changes meaning."
                    p_ $ do
                        "This is the single most common “works on my machine” bug involving grep, and it has nothing to do with grep. Decide explicitly which behaviour you want and pin it: "
                        c "LC_ALL=C"
                        " for byte-exact, fast, encoding-agnostic matching, or "
                        c "LC_ALL=C.UTF-8"
                        " when you genuinely need character semantics and do not want to depend on a full locale being installed."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d8diagram :: Diagram
d8diagram =
    (diagram
        "A character is defined by the locale and encoded as a sequence of bytes; a run of bytes that decodes to no character is an encoding error, and either an encoding error or a NUL byte makes the containing file binary."
        body'
    )
        { dgCaption = do
            "The aspect that explains the whole day is "
            em_ "an encoding error is only an error relative to the locale"
            ". Nothing about the bytes on disk changes when you put "
            c "LC_ALL=C"
            " in front of a command — you have changed what counts as a character, and with it whether the file is binary, whether "
            c "."
            " matches one byte or three, and how much work grep must do per byte."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  loc  [label=\"the locale\\nLC_ALL, LC_CTYPE, LANG\", fillcolor=\"#f4efe6\"];"
            , "  ch   [label=\"a character\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  by   [label=\"a byte\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  err  [label=\"an encoding error\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  nul  [label=\"a NUL byte\"];"
            , "  file [label=\"an input file\"];"
            , "  bin  [label=\"a binary file\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  ch   -> loc  [label=\"  is defined by\"];"
            , "  ch   -> by   [label=\"  is encoded as a sequence of\"];"
            , "  err  -> by   [label=\"  is a sequence of\"];"
            , "  err  -> loc  [label=\"  is only an error relative to  \", style=dashed];"
            , "  nul  -> by   [label=\"  is\"];"
            , "  file -> by   [label=\"  contains\"];"
            , "  bin  -> file [label=\"  is\"];"
            , "  err  -> bin  [label=\"  makes its file  \", style=dashed, constraint=false];"
            , "  nul  -> bin  [label=\"  makes its file  \", style=dashed, constraint=false];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "grep decides what a character is, and it asks the environment" $ do
        p_ [class_ "lede"] $ do
            "Every day so far has treated “a character” as obvious. It is not. What counts as a character — and therefore what "
            c "."
            " matches, what "
            c "[[:alpha:]]"
            " contains, what "
            c "-i"
            " folds together, and whether your file is text at all — is decided by the locale, which is to say by environment variables that you probably did not set deliberately."
        p_ $ do
            "This is where grep stops being a tool you configure and starts being a tool that is configured around you. There is no flag for most of it; there are only "
            c "LC_ALL"
            ", "
            c "LC_CTYPE"
            ", "
            c "LC_COLLATE"
            " and "
            c "LANG"
            ", consulted in that order of precedence, and falling back to the C locale when none of them is set."
        fig

    block "The binary file that is not binary" $ do
        p_ $ do
            "grep calls a file binary when it finds either a NUL byte or "
            em_ "improperly encoded data"
            " — bytes that are not a valid character in the current locale. On finding one it stops printing lines, writes a note to standard error, and carries on matching."
        sh
            [ "$ printf 'hello\\0world\\nmatch me\\n' > bin.dat"
            , "$ grep match bin.dat"
            , "grep: bin.dat: binary file matches"
            , "$ echo $?"
            , "0"
            , "$ grep -c match bin.dat"
            , "1"
            ]
        p_ $ do
            "Note carefully what happened. Standard output got nothing, standard error got a note, and the exit status is "
            c "0"
            " because a line "
            em_ "was"
            " selected. The matching worked perfectly; only the printing was suppressed, which is why "
            c "-c"
            " and "
            c "-l"
            " still give the right answers."
        why $ do
            p_ $ do
                "The suppression is a terminal-safety measure, not squeamishness. The manual is blunt about it: binary output “can have nasty side effects if the output is a terminal and if the terminal driver interprets some of it as commands”. A file full of escape sequences can reprogram your terminal, change your keymap or, historically, do considerably worse. grep refuses on your behalf and lets you override."
        p_ "Now the version that catches people:"
        sh
            [ "$ printf 'caf\\xe9 match\\nplain match\\n' > latin.txt"
            , "$ grep match latin.txt"
            , "plain match"
            , "grep: latin.txt: binary file matches"
            , "$ LC_ALL=C grep match latin.txt | cat -v"
            , "cafM-i match"
            , "plain match"
            ]
        gotcha $ do
            p_ $ do
                "That file has no NUL byte in it. It is ordinary Latin-1 text, the sort of thing a decade-old log rotation leaves behind. In a UTF-8 locale the byte "
                c "0xe9"
                " begins a multibyte sequence that never completes, so it is an encoding error, so the file is binary, so the line containing it vanishes — while the "
                em_ "other"
                " lines print normally. You get a partial answer and a note you may not notice, and the exit status says everything is fine."
        defs
            [ (c "-a" <> " / " <> c "--binary-files=text", "Print the lines anyway. The bytes reach your terminal unfiltered, so pipe it somewhere rather than looking at it.")
            , (c "-I" <> " / " <> c "--binary-files=without-match", do "Treat a binary file as containing no matches at all. This is what you want inside " <> c "grep -r" <> " over a tree with object files in it.")
            , (c "LC_ALL=C", "Redefine “character” as “byte”, so nothing can be an encoding error. Usually the right answer for log triage.")
            ]

    block "The speed difference, and where it actually is" $ do
        p_ $ do
            "The folklore is that "
            c "LC_ALL=C"
            " makes grep much faster. The folklore is right about the size of the effect and wrong about when it applies. On a 20 MB file:"
        ascii
            [ "pattern              en_US.UTF-8     C          ratio"
            , "-------------------------------------------------------"
            , "[a-z]\\{4\\}x             0.72 s      0.03 s      ~24x"
            , "zzzz  (plain literal)   0.01 s      0.01 s       none"
            ]
        p_ $ do
            "The gain comes from not decoding. A pattern involving bracket expressions, named classes, case folding or "
            c "."
            " forces grep to work out where each character starts and ends; in the C locale that question is free, because every byte is a character. A literal string never asks the question at all — it goes through a Boyer-Moore search over raw bytes in both locales."
        tip $ do
            p_ $ do
                "So: reach for "
                c "LC_ALL=C"
                " when the input is large "
                em_ "and"
                " the pattern is character-classy "
                em_ "and"
                " byte semantics are acceptable. Do not put it in front of every grep in a script — on literal searches it buys nothing, and on real multilingual text it silently changes what "
                c "-i"
                " and "
                c "[[:alpha:]]"
                " mean."

    block "Collation, and a warning that has aged" $ do
        p_ $ do
            c "LC_COLLATE"
            " governs range expressions. The manual warns that outside the C locale "
            c "[a-d]"
            " “might be equivalent to "
            c "[abcd]"
            " or "
            c "[aBbCcDd]"
            " or some other bracket expression, or it might fail to match any character, or … it might be invalid”."
        note $ do
            p_ $ do
                "On glibc 2.42 that does not reproduce: "
                c "[a-d]"
                " matches exactly "
                c "abcd"
                " in both "
                c "C"
                " and "
                c "en_US.UTF-8"
                ". The dire behaviour the page describes belongs to an earlier era of collation handling. The warning is still correct as a "
                em_ "portability"
                " statement — POSIX leaves it unspecified and other C libraries have made other choices — but you will not see it on a current Linux box, and you should not go looking for it to explain a bug."
        p_ $ do
            "The durable advice is the one from Day 3: write "
            c "[[:lower:]]"
            " rather than "
            c "[a-z]"
            " when you mean a category, and "
            c "[abcd]"
            " when you mean those four characters. Neither depends on collation at all."

    block "POSIXLY_CORRECT changes parsing, not matching" $ do
        p_ $ do
            "By default grep permutes its arguments: options found after the file names are moved to the front and honoured. POSIX forbids that, and setting "
            c "POSIXLY_CORRECT"
            " restores the strict reading."
        sh
            [ "$ grep ERROR app.log -c"
            , "2"
            , "$ POSIXLY_CORRECT=1 grep ERROR app.log -c"
            , "app.log:ERROR timeout talking to db"
            , "app.log:ERROR timeout talking to db"
            , "grep: -c: No such file or directory"
            ]
        p_ $ do
            "Read the second one carefully: "
            c "-c"
            " did not merely stop working, it became a "
            em_ "second file operand"
            ". That pushed grep over the two-file threshold from Day 6, so the matching lines acquired a filename prefix, and then the non-existent file pushed the exit status to 2. One unset variable changed the output format and the status."
        gotcha $ do
            p_ $ do
                "That variable is often set for reasons that have nothing to do with you — a build system, a test harness, a colleague's shell profile. Any command line that puts an option after an operand has a different meaning depending on it. Put every option before the pattern and the operands and the question never arises."
        p_ $ do
            "The manual also claims this variable changes “invalid” to “illegal” in option error messages. It does not: 3.12 says "
            c "invalid option"
            " either way. Argument permutation is the whole of the observable difference."

    block "Today's habit" $ do
        p_ $ do
            "When a grep behaves differently in CI, in cron, in a container or on a colleague's machine, check the locale before you touch the pattern. "
            c "locale"
            " with no arguments prints what grep is actually going to use, and it is the answer far more often than the regular expression is."
        cfg
            [ "# ~/grep-recipes.sh"
            , "#"
            , "# Day 8: byte-exact and fast. For log triage over large or dirty files."
            , "# Changes what -i and [[:alpha:]] mean - do not use it on real prose."
            , "LC_ALL=C grep -c '[[:digit:]]\\{4\\}' bigfile"
            , ""
            , "# Day 8: a 'binary' file with no NUL in it has an encoding error."
            , "# -a to see the lines anyway, -I to skip such files during recursion."
            , "grep -a PATTERN dirty.log"
            , "grep -rI PATTERN ."
            , ""
            , "# Day 8: first thing to check when a grep behaves differently elsewhere."
            , "locale"
            ]

cheat :: Html ()
cheat =
    cfg
        [ "# a file is BINARY if it has a NUL byte OR bytes that are not valid"
        , "# characters IN THE CURRENT LOCALE. Latin-1 text is binary under UTF-8."
        , "#   -> lines suppressed, note on STDERR, exit status still 0"
        , "#   -> -c and -l still give the right answers; only printing stopped"
        , "-a   print them anyway   (--binary-files=text)"
        , "-I   treat the file as non-matching   (--binary-files=without-match)"
        , ""
        , "LC_ALL=C   'character' becomes 'byte': nothing is an encoding error,"
        , "           matching is byte-exact, and character-class patterns get much faster"
        , "#   measured on 20MB:  [a-z]\\{4\\}x  0.72s UTF-8 vs 0.03s C   (~24x)"
        , "#                      a plain literal  0.01s vs 0.01s        (no gain)"
        , ""
        , "LC_ALL > LC_CTYPE/LC_COLLATE > LANG > C.   'locale' prints what you have."
        , "POSIXLY_CORRECT=1   options after operands become FILENAMES, not options."
        ]
