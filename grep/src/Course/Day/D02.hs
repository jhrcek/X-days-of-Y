module Course.Day.D02 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 2
        , dayTitle = "Saying what you mean"
        , daySubtitle = "Case, inversion, word and line boundaries, and how to hand grep more than one pattern."
        , dayMinutes = 30
        , dayLevel = "essential"
        , dayManRef = "OPTIONS: Matching Control"
        , dayTags = ["-i -v -w -x", "-e", "-f"]
        , dayGoals =
            [ "say exactly what " <> c "-w" <> " tests, and predict when it will refuse a match you expected"
            , "give grep several patterns three different ways and know which one a script should use"
            , "explain why " <> c "-v" <> " with two patterns is NOR, not two separate negations"
            ]
        , dayDiagram = Just d2diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("grep -e -v file.txt", "Search for the literal string " <> c "-v" <> ". " <> c "-e" <> " protects a pattern that starts with a dash.")
            , ("grep -f patterns.txt data.txt", "Take patterns from a file, one per line. The workhorse for long lists.")
            , ("cut -f1 ids.csv | grep -f - data.txt", "Patterns from a pipe. " <> c "-f -" <> " reads them from standard input.")
            ]
        , dayOpts =
            [ ("-i, --ignore-case", "Match regardless of case. What counts as “the same letter” depends on the locale.")
            , ("--no-ignore-case", "Cancel an earlier " <> c "-i" <> ". The last of the two on the line wins.")
            , ("-v, --invert-match", "Select the lines that did " <> em_ "not" <> " match. Applied once, after all patterns.")
            , ("-w, --word-regexp", "Require the matched substring to be bounded by non-word characters or line ends.")
            , ("-x, --line-regexp", "Require the match to be the entire line. Silently overrides " <> c "-w" <> ".")
            , ("-e PAT, --regexp=PAT", "Add a pattern. Repeatable, and combinable with " <> c "-f" <> ".")
            , ("-f FILE, --file=FILE", "Add every line of FILE as a pattern. An empty file matches nothing at all.")
            , ("-y", "Undocumented synonym for " <> c "-i" <> ". In neither the man page nor " <> c "--help" <> ", but 3.12 accepts it.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Run " <> c "grep -i root /etc/passwd" <> " and then " <> c "grep -i ROOT /etc/passwd" <> ". Same output. Case folding applies to the pattern and the data alike."
            , "Make a scratch file: " <> c "printf 'foo\\nfoobar\\nfoo-bar\\n_foo\\n' > w.txt" <> ". Run " <> c "grep -w foo w.txt" <> ". You get " <> c "foo" <> " and " <> c "foo-bar" <> " but not " <> c "_foo" <> ". Work out why before reading on: the underscore is a word character."
            , "Now " <> c "grep -x foo w.txt" <> ". Only the bare " <> c "foo" <> " survives. Then " <> c "grep -wx 'fo*' w.txt" <> " — " <> c "-w" <> " contributed nothing, because " <> c "-x" <> " had already made it redundant."
            , "Break it on purpose: run " <> c "grep -v data.txt" <> " with no pattern operand. grep treats " <> c "data.txt" <> " as the pattern and then waits on standard input. Press " <> k "C-c" <> ", then do it properly with " <> c "grep -v -e PATTERN data.txt" <> "."
            , "Prove that " <> c "-v" <> " is NOR: " <> c "grep -v -e foo -e bar w.txt" <> " drops every line containing either. There is no way to spell “not foo but yes bar” in one grep — that is a pipeline of two."
            , "On your own work: take a log file and run " <> c "grep -v -e DEBUG -e health-check" <> " over it. That two-pattern exclusion is the single most useful thing on this page."
            , "Put your project's identifiers in a file and run " <> c "grep -f ids.txt logfile" <> ". Then empty the file and run it again — it matches nothing, not everything. That asymmetry has surprised people at 2am."
            , "Add today's line to " <> c "~/grep-recipes.sh" <> ": the " <> c "-v -e ... -e ..." <> " noise filter you just built, with a comment saying which noise it removes."
            ]
        , dayQuiz =
            [
                ( "You run "
                    <> c "grep -w '[a-z]*foo[a-z]*'"
                    <> " over a file containing the line "
                    <> c "x_foo_y"
                    <> " and get nothing. The pattern clearly can match part of that line. What is "
                    <> c "-w"
                    <> " objecting to?"
                , do
                    p_ $ do
                        c "-w"
                        " does not test your "
                        em_ "pattern"
                        ", it tests the "
                        em_ "substring that matched"
                        ". Here "
                        c "[a-z]*"
                        " cannot cross the underscores, so the longest thing the pattern can match is "
                        c "foo"
                        " — and "
                        c "foo"
                        " sits between two underscores, which are word-constituent characters. Both edges fail the test, so the line is rejected."
                    p_ $ do
                        "Word-constituent means letters, digits and underscore. If you want underscores to count as separators, say so explicitly: "
                        c "grep -E '(^|[^[:alnum:]])foo([^[:alnum:]]|$)'"
                        ", or use "
                        c "\\b"
                        " from Day 3 and accept the same definition."
                )
            ,
                ( "A colleague's script has "
                    <> c "grep -i \"$pattern\" \"$file\""
                    <> " and it stops matching accented text when the script is run from cron. Nothing in the script changed."
                , do
                    p_ $ do
                        "cron runs with a bare environment, so the locale falls back to C. Under "
                        c "LC_ALL=C"
                        " every byte is its own character and case folding only knows about ASCII: "
                        c "grep -i 'café'"
                        " matches "
                        c "café"
                        " but not "
                        c "CAFÉ"
                        ". Under "
                        c "en_US.UTF-8"
                        " it matches both."
                    p_ $ do
                        c "-i"
                        " is not a fixed rule, it is a question asked of the locale. Day 8 is about the other things the locale silently decides for you — and about the cases where you should force "
                        c "LC_ALL=C"
                        " on purpose."
                )
            ,
                ( "You need to exclude two patterns, so you write "
                    <> c "grep -v foo file | grep -v bar"
                    <> ". A colleague writes "
                    <> c "grep -v -e foo -e bar file"
                    <> ". Are these the same, and does it matter?"
                , do
                    p_ $ do
                        "They produce identical output. grep ORs its patterns together into one decision and then "
                        c "-v"
                        " inverts that single result, which by De Morgan is exactly “not foo and not bar” — the same thing the pipeline computes in two passes."
                    p_ $ do
                        "The single grep is better: one process, one pass over the data, and — the part that actually bites — a meaningful exit status. In the pipeline the status you get back is the "
                        em_ "second"
                        " grep's, so a failure to open "
                        c "file"
                        " in the first one is thrown away entirely."
                )
            ,
                ( "Your script does "
                    <> c "grep -f \"$idfile\" audit.log"
                    <> " to find any mention of a list of user IDs. "
                    <> c "$idfile"
                    <> " comes out empty one morning. What does the script report?"
                , do
                    p_ $ do
                        "Nothing, with exit status "
                        c "1"
                        ". The manual is explicit: “The empty file contains zero patterns, and therefore matches nothing.” This is the right answer mathematically — an empty union matches nothing — but it is the opposite of what an empty "
                        em_ "pattern"
                        " does."
                    p_ $ do
                        "A single empty pattern, "
                        c "grep '' file"
                        ", matches every line, because the empty string occurs in every line. So "
                        c "-f"
                        " on an empty file gives you nothing and "
                        c "-e ''"
                        " gives you everything. Check that the file is non-empty before you trust the result."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d2diagram :: Diagram
d2diagram =
    (diagram
        "A match is an occurrence of one pattern from the pattern set inside an input line; whole-word and whole-line matches are progressively stricter kinds of match, and a matched line is selected unless -v is in force."
        body'
    )
        { dgCaption = do
            "Every pattern you supply — by operand, by "
            c "-e"
            ", by "
            c "-f"
            " — joins one set, and a line needs to match only one member of it. "
            c "-w"
            " and "
            c "-x"
            " narrow what counts as a match, and "
            c "-v"
            " flips the very last step. That is why "
            c "-x"
            " makes "
            c "-w"
            " redundant rather than conflicting with it: a match filling the whole line already has non-word characters on both sides, namely the ends of the line."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  pset  [label=\"a pattern set\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  pat   [label=\"a pattern\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  m     [label=\"a match\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  ww    [label=\"a whole-word match\\n(-w)\"];"
            , "  wl    [label=\"a whole-line match\\n(-x)\"];"
            , "  line  [label=\"an input line\"];"
            , "  ml    [label=\"a matched line\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  sel   [label=\"a selected line\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  pat -> pset [label=\"  belongs to\"];"
            , "  m   -> pat  [label=\"  is an occurrence of\"];"
            , "  m   -> line [label=\"  is a substring of\"];"
            , "  ww  -> m    [label=\"  is\"];"
            , "  wl  -> ww   [label=\"  is\"];"
            , "  ml  -> m    [label=\"  contains\"];"
            , "  ml  -> line [label=\"  is\"];"
            , "  ml  -> sel  [label=\"  is, unless -v  \", style=dashed];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "One set of patterns, one decision per line" $ do
        p_ [class_ "lede"] $ do
            "grep does not run your patterns one after another. It collects every pattern you gave it — the operand, each "
            c "-e"
            ", every line of each "
            c "-f"
            " file — into a single set, and asks one question of each input line: does it match "
            em_ "any"
            " of them. Everything on this page is a way of sharpening that question."
        p_ $ do
            "That the patterns are ORed is worth sitting with, because it means "
            c "-v"
            " does not distribute over them. "
            c "grep -v -e foo -e bar"
            " does not mean “not foo, and separately not bar”; it means “not (foo or bar)”. The two happen to coincide, by De Morgan, but the reasoning that gets you there matters once the patterns get complicated."
        fig
        why $ do
            p_ $ do
                "The set-of-patterns design is why "
                c "-f"
                " exists and why it scales. Handing grep ten thousand patterns in a file is not ten thousand searches; GNU grep compiles the whole set into one automaton and still makes a single pass over the data. That is the trick that lets "
                c "grep -f known-bad-ips.txt access.log"
                " finish at all."

    block "Case, and who decides what case means" $ do
        p_ $ do
            c "-i"
            " folds case in the pattern and in the data. Its companion "
            opt "--no-ignore-case"
            " exists so that a wrapper script can cancel an "
            c "-i"
            " it did not add: the two override each other and "
            b_ "the last one on the command line wins"
            "."
        sh
            [ "$ printf 'CAFE\\ncafé\\nCAFÉ\\n' > u.txt"
            , "$ LC_ALL=en_US.UTF-8 grep -i 'café' u.txt"
            , "café"
            , "CAFÉ"
            , "$ LC_ALL=C grep -i 'café' u.txt"
            , "café"
            ]
        gotcha $ do
            p_ $ do
                "Case folding is a locale question, not a grep question. In the C locale grep folds ASCII and nothing else, so "
                c "É"
                " and "
                c "é"
                " are unrelated bytes. Scripts that work in your shell and fail under cron, systemd or a container almost always differ in exactly this way — those environments start with a bare environment and fall back to C."
        note $ do
            p_ $ do
                "3.12 also accepts "
                c "-y"
                " as a synonym for "
                c "-i"
                ". It appears in neither the manual page nor "
                c "--help"
                ", and it is a survival from Version 7 grep. It works; do not write it, because the next implementation may well have dropped it."

    block "Bounding the match: -w and -x" $ do
        p_ $ do
            "These two are the most misread options in grep, because both look like they constrain the "
            em_ "pattern"
            " and in fact both constrain the "
            em_ "substring that the pattern matched"
            "."
        defs
            [
                ( c "-w"
                , do
                    "The matched substring must start at the beginning of the line or be preceded by a non-word character, and end at the end of the line or be followed by one. Word characters are letters, digits and "
                    c "_"
                    "."
                )
            ,
                ( c "-x"
                , do
                    "The match must be the whole line — as if you had wrapped the pattern in "
                    c "^(...)$"
                    ". The manual notes that "
                    c "-w"
                    " “has no effect if "
                    c "-x"
                    " is also specified”, and the olog above shows why that is structural rather than a special case."
                )
            ]
        sh
            [ "$ printf 'foo\\nfoobar\\nfoo-bar\\n_foo\\nfoo bar\\n' > w.txt"
            , "$ grep -w foo w.txt"
            , "foo"
            , "foo-bar"
            , "foo bar"
            , "$ grep -x foo w.txt"
            , "foo"
            ]
        p_ $ do
            "Note what "
            c "-w"
            " kept and what it dropped. "
            c "foo-bar"
            " is in, because a hyphen is not a word character. "
            c "_foo"
            " is out, because an underscore is. If that is not the boundary you meant — and for identifiers it usually is not — you need a bracket expression of your own, which is tomorrow."

    block "Handing grep more than one pattern" $ do
        p_ "Three spellings, and they are not interchangeable in a script."
        steps
            [ do
                "A newline inside the operand. "
                c "grep 'alpha\\ngamma' f"
                " with a real newline works, and is how the first synopsis form is defined, but it is unreadable in a script and a nightmare to quote."
            , do
                c "-e"
                ", repeated. Explicit, and the only way to use a pattern that starts with "
                c "-"
                ": "
                c "grep -e -v file"
                " searches for the string "
                c "-v"
                ". "
                c "--"
                " does the same job for the whole command line."
            , do
                c "-f FILE"
                ", one pattern per line, repeatable and combinable with "
                c "-e"
                ". "
                c "-f -"
                " reads the patterns from standard input, which is how you feed grep the output of another command."
            ]
        sh
            [ "$ cut -d, -f1 suspect-ids.csv | grep -f - audit.log"
            , "$ grep -e '^ERROR' -f known-noise.txt app.log"
            , "ERROR boom"
            , "timeout hit"
            ]
        gotcha $ do
            p_ $ do
                "An empty "
                c "-f"
                " file matches "
                b_ "nothing"
                ", not everything. An empty "
                em_ "pattern"
                " matches "
                b_ "every"
                " line. So "
                c "grep -f empty.txt data"
                " exits "
                c "1"
                " in silence while "
                c "grep '' data"
                " prints the whole file, and a script that builds its pattern file dynamically will flip between those two behaviours depending on whether the generating command produced anything."

    block "Today's habit" $ do
        p_ $ do
            "The single highest-value thing on this page is the two-pattern noise filter. Almost every log you read has two or three lines of chaff for every line of signal, and "
            c "-v -e ... -e ..."
            " is how you get rid of them in one pass with an exit status you can still trust."
        cfg
            [ "# ~/grep-recipes.sh"
            , "#"
            , "# Day 2: strip the noise before reading a log. One pass, one status."
            , "grep -v -e ' DEBUG ' -e '/health' -e 'favicon.ico' \"$1\""
            , ""
            , "# Day 2: patterns from a pipe - '-f -' reads the pattern list on stdin."
            , "cut -d, -f1 ids.csv | grep -f - audit.log"
            ]

cheat :: Html ()
cheat =
    cfg
        [ "-i    fold case (locale decides what that means; -y is an undocumented alias)"
        , "      --no-ignore-case cancels it; the LAST of the two on the line wins"
        , "-v    invert - applied once, AFTER all patterns are ORed together"
        , "-w    matched substring must be bounded by non-word chars or line ends"
        , "      word chars are letters, digits and _  (so _foo fails, foo-bar passes)"
        , "-x    match must be the whole line; makes -w redundant, never conflicts"
        , ""
        , "# giving grep several patterns - all three join ONE set, ORed"
        , "grep -e PAT -e PAT file     # repeatable; also protects a leading '-'"
        , "grep -f pats.txt file       # one per line; EMPTY FILE MATCHES NOTHING"
        , "cmd | grep -f - file        # patterns from a pipe"
        , "grep -- -v file             # '--' ends options, like -e for the whole line"
        ]
