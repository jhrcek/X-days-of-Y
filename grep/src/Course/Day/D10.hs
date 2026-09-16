module Course.Day.D10 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 10
        , dayTitle = "The other engine"
        , daySubtitle = "What -P buys, what it costs, and when to put grep down entirely."
        , dayMinutes = 35
        , dayLevel = "advanced"
        , dayManRef = "OPTIONS: -P; BUGS; SEE ALSO"
        , dayTags = ["-P", "lookaround", "what next"]
        , dayGoals =
            [ "use lookaround and " <> c "\\K" <> " to extract a field without a capture group"
            , "name the three things " <> c "-P" <> " takes away from you before you reach for it"
            , "recognise the point at which the right answer is " <> c "sed" <> ", " <> c "awk" <> " or a real parser"
            ]
        , dayDiagram = Just d10diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds = []
        , dayOpts =
            [ ("-P, --perl-regexp", "Use the PCRE2 engine. Accepts exactly one pattern, and may not be compiled in.")
            , ("\\d \\s \\w", "Digit, whitespace, word character. The POSIX spellings are " <> c "[[:digit:]]" <> " and friends.")
            , ("(?=...) and (?!...)", "Lookahead: assert what follows without consuming it.")
            , ("(?<=...) and (?<!...)", "Lookbehind: assert what precedes. The length must be fixed.")
            , ("\\K", "Drop everything matched so far from the reported match. A lookbehind without the length rule.")
            , ("*? +? ??", "Lazy quantifiers: match as little as possible. POSIX has no equivalent.")
            , ("-Pz", "NUL-terminated input, so a pattern can match across newlines. The manual calls this experimental.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Extract a field without a capture group: " <> c "echo 'Authorization: Bearer abc123' | grep -oP 'Bearer \\K\\S+'" <> " prints " <> c "abc123" <> ". Try writing that with " <> c "-E" <> " and " <> c "-o" <> " — you cannot, because POSIX has no way to exclude part of a match."
            , "Use a negative lookahead: " <> c "printf 'foo.c\\nfoo.h\\n' | grep -P '^foo\\.(?!h$)'" <> " keeps the " <> c ".c" <> " and drops the " <> c ".h" <> "."
            , "See lazy versus greedy: " <> c "echo '<a><b>' | grep -oP '<.+?>'" <> " gives two tags; change " <> c ".+?" <> " to " <> c ".+" <> " and it gives one."
            , "Break it on purpose: " <> c "grep -P -e 'foo' -e 'bar' file" <> " fails with " <> c "the -P option only supports a single pattern" <> " and exits 2. Nothing in the manual page warns you about this."
            , "Watch the engine give up: " <> c "python3 -c \"print('a'*40+'X')\" > bt.txt" <> ", then " <> c "grep -P '(a+)+$' bt.txt" <> " reports " <> c "exceeded PCRE's backtracking limit" <> " and exits 2. Now run " <> c "grep -E '(a+)+$' bt.txt" <> ": it answers correctly in under 10 ms."
            , "Match across lines: " <> c "printf 'BEGIN\\nmiddle\\nEND\\nother\\n' | grep -Pzo 'BEGIN\\n.*\\nEND'" <> ". This is the one thing " <> c "-P" <> " does that nothing else in grep can."
            , "On your own work: find a place where you chained two greps and a " <> c "cut" <> " to pull one field out of a line. Rewrite it as a single " <> c "grep -oP" <> " with " <> c "\\K" <> ", then decide honestly whether it is more readable."
            , "Finish the course: open " <> c "~/grep-recipes.sh" <> " and delete every line you can no longer explain. What is left is what you actually learned."
            ]
        , dayQuiz =
            [
                ( "A colleague replaces "
                    <> c "grep -E 'ERROR|WARN' app.log"
                    <> " with "
                    <> c "grep -P 'ERROR|WARN' app.log"
                    <> " and it works. They then try to split it into "
                    <> c "grep -P -e ERROR -e WARN app.log"
                    <> " and it fails. Why does the alternation work but the two options not?"
                , do
                    p_ $ do
                        c "-P"
                        " accepts exactly "
                        b_ "one"
                        " pattern. The alternation is one pattern containing a "
                        c "|"
                        ", which is fine. Two "
                        c "-e"
                        " options are two patterns, and grep refuses with "
                        c "the -P option only supports a single pattern"
                        " and exit 2. The same restriction applies to a "
                        c "-f"
                        " file with two lines in it, and to a newline inside the pattern operand."
                    p_ $ do
                        "This limitation appears nowhere in the manual page — the "
                        c "-P"
                        " entry mentions only that it is experimental with "
                        c "-z"
                        " and may warn about unimplemented features. It matters most when a script builds its pattern list dynamically, because it works fine right up until the list has two entries in it."
                )
            ,
                ( "You need to pull the token out of "
                    <> c "Authorization: Bearer abc123"
                    <> ". Why can "
                    <> c "grep -oP 'Bearer \\K\\S+'"
                    <> " do this when no "
                    <> c "-E"
                    <> " pattern can?"
                , do
                    p_ $ do
                        c "-o"
                        " prints the whole match, and POSIX regular expressions give you no way to say “match this part but do not report it”. There are no capture groups in grep's output — "
                        c "\\1"
                        " exists inside a pattern for back-references, but grep never prints a group, only the whole match."
                    p_ $ do
                        c "\\K"
                        " resets the start of the reported match to the current position, so everything before it is a condition rather than part of the answer. A lookbehind "
                        c "(?<=Bearer )\\S+"
                        " does the same job but requires a fixed-length assertion, which "
                        c "\\K"
                        " does not. If you find yourself wanting this often, that is a signal that "
                        c "sed -n 's/.../\\1/p'"
                        " or "
                        c "awk"
                        " is the better tool."
                )
            ,
                ( "The pattern "
                    <> c "(a+)+$"
                    <> " against forty "
                    <> c "a"
                    <> "s followed by an "
                    <> c "X"
                    <> " makes "
                    <> c "grep -P"
                    <> " fail with an error, while "
                    <> c "grep -E"
                    <> " answers instantly. Is the POSIX engine simply better?"
                , do
                    p_ $ do
                        "For this class of pattern, yes, and it is not a close call. A POSIX regular expression without back-references can be compiled into a deterministic automaton and matched in time linear in the input, no matter how the pattern is written. "
                        c "(a+)+$"
                        " is a nested quantifier that a backtracking engine explores exponentially many ways; PCRE hits its configured backtracking limit and gives up with exit 2 rather than running forever."
                    p_ $ do
                        "So the limit is a safety net, not a bug — but it means "
                        c "-P"
                        " can fail on input it merely finds awkward, which "
                        c "-E"
                        " never does. If a pattern is going to run unattended over data you do not control, that asymmetry is a reason to stay with "
                        c "-E"
                        ". Remember from Day 4 that adding a back-reference to an "
                        c "-E"
                        " pattern forfeits the same guarantee."
                )
            ,
                ( "You have written "
                    <> c "grep -oP '(?<=\"name\": \")[^\"]*' data.json"
                    <> " and it works on today's file. Why is this still the wrong tool?"
                , do
                    p_ $ do
                        "Because JSON is not a regular language and the file is only cooperating by accident. The pattern breaks on an escaped quote inside a value, on a different key order, on whitespace after the colon, on a "
                        c "name"
                        " key nested somewhere you did not mean, and on any pretty-printer that puts the value on the next line."
                    p_ $ do
                        "The rule that has aged well: grep finds "
                        em_ "lines"
                        ", and once you are reaching inside a line to pull out structure you have left grep's problem domain. Use "
                        c "jq"
                        " for JSON, "
                        c "awk"
                        " for columns, "
                        c "sed"
                        " for substitutions, and a real parser for anything with nesting in it. grep's job is to find the line and hand it over."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d10diagram :: Diagram
d10diagram =
    (diagram
        "A POSIX matcher compiles a pattern to a deterministic automaton that returns the leftmost-longest match in linear time; a PCRE matcher compiles it to a backtracking search that returns the leftmost-first match and may take exponential time."
        body'
    )
        { dgCaption = do
            "The same pattern text, two engines, and the difference is not a matter of features. The two return "
            em_ "different matches"
            " — Day 4's "
            c "ab|abcd"
            " — and they have different worst cases. "
            c "-P"
            " gives you lookaround and "
            c "\\K"
            "; the price is written along the dashed aspect, and is paid on the input you did not test."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  pat   [label=\"a pattern\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  posix [label=\"a POSIX matcher\\n-G  -E  -F\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  pcre  [label=\"a PCRE matcher\\n-P\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  dfa   [label=\"a deterministic\\nautomaton\"];"
            , "  bt    [label=\"a backtracking search\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  llm   [label=\"the leftmost-longest\\nmatch\"];"
            , "  lfm   [label=\"the leftmost-first\\nmatch\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  len   [label=\"the input length\"];"
            , ""
            , "  posix -> pat [label=\"  interprets\"];"
            , "  pcre  -> pat [label=\"  interprets\"];"
            , "  posix -> dfa [label=\"  compiles to\"];"
            , "  pcre  -> bt  [label=\"  compiles to\"];"
            , "  dfa   -> llm [label=\"  returns\"];"
            , "  bt    -> lfm [label=\"  returns\"];"
            , "  dfa   -> len [label=\"  runs in time linear in\"];"
            , "  bt    -> len [label=\"  may run in time exponential in  \", style=dashed];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "A different engine, not a bigger one" $ do
        p_ [class_ "lede"] $ do
            c "-P"
            " hands your pattern to PCRE2, a separate library with a separate language and a fundamentally different matching strategy. It is not “extended regular expressions with more features” — it answers some questions differently, and it can fail on inputs that "
            c "-E"
            " handles without noticing."
        p_ $ do
            "Day 4 showed the visible half of that: POSIX returns the leftmost-"
            em_ "longest"
            " match and PCRE the leftmost-"
            em_ "first"
            ", so "
            c "ab|abcd"
            " against "
            c "abcd"
            " gives different answers under "
            c "-E"
            " and "
            c "-P"
            ". The invisible half is what each engine does to get there."
        fig

    block "What -P buys you" $ do
        p_ $ do
            "Three things, and only the first two come up often."
        defs
            [
                ( "Lookaround"
                , do
                    c "(?=...)"
                    " and "
                    c "(?!...)"
                    " assert what follows without consuming it; "
                    c "(?<=...)"
                    " and "
                    c "(?<!...)"
                    " do the same backwards, with the restriction that the assertion must be of fixed length."
                )
            ,
                ( c "\\K"
                , "Discard everything matched so far from the reported match. This is what makes field extraction possible, because grep has no way to print a capture group."
                )
            ,
                ( "Lazy quantifiers"
                , do
                    c "*?"
                    ", "
                    c "+?"
                    ", "
                    c "??"
                    " match as little as possible. POSIX has no equivalent, because leftmost-longest makes the idea meaningless."
                )
            ]
        sh
            [ "$ echo 'Authorization: Bearer abc123' | grep -oP 'Bearer \\K\\S+'"
            , "abc123"
            , "$ echo 'price=10 cost=20' | grep -oP '(?<=cost=)\\d+'"
            , "20"
            , "$ printf 'foo.c\\nfoo.h\\n' | grep -P '^foo\\.(?!h$)'"
            , "foo.c"
            ]
        p_ $ do
            "The first of those is genuinely difficult to write any other way in grep. "
            c "-o"
            " prints the whole match and there is no facility for printing a group, so without "
            c "\\K"
            " or a lookbehind you have to pipe into "
            c "sed"
            " or "
            c "cut"
            "."
        note $ do
            p_ $ do
                "The PCRE shorthands "
                c "\\d"
                ", "
                c "\\s"
                " and "
                c "\\w"
                " are convenient but are not a reason to use "
                c "-P"
                ": POSIX has "
                c "[[:digit:]]"
                ", "
                c "[[:space:]]"
                " and "
                c "\\w"
                " — which, as Day 3 noted, GNU provides in the POSIX matchers too."

    block "What it costs" $ do
        p_ "Four things, in descending order of how often they will catch you out."
        steps
            [ do
                b_ "One pattern only."
                " "
                c "grep -P -e foo -e bar"
                " fails with "
                c "the -P option only supports a single pattern"
                " and exit 2. So does a two-line "
                c "-f"
                " file, and so does a newline inside the pattern operand. Use a "
                c "|"
                " alternation instead. "
                b_ "This appears nowhere in the manual page."
            , do
                b_ "It can fail on data it finds awkward."
                " A backtracking engine has a configured limit, and hitting it is an error rather than a wrong answer:"
            , do
                b_ "It may not be there at all."
                " PCRE support is a compile-time option. On a minimal container or a BSD you may get “support for the -P option is not compiled into this --disable-perl-regexp binary”, and your script has no fallback."
            , do
                b_ "It is the least portable thing in this course."
                " Every other option here is POSIX or a long-standing GNU extension. "
                c "-P"
                " is GNU-plus-a-library."
            ]
        sh
            [ "$ python3 -c \"print('a'*40+'X')\" > bt.txt"
            , "$ grep -P '(a+)+$' bt.txt"
            , "grep: bt.txt: exceeded PCRE's backtracking limit"
            , "$ echo $?"
            , "2"
            , "$ grep -E '(a+)+$' bt.txt"
            , "$ echo $?"
            , "1"
            ]
        why $ do
            p_ $ do
                "The POSIX engine wins here because of what it gives up. Without lookaround and back-references, a pattern describes a genuinely regular language, and every regular language has a deterministic automaton that recognises it in one pass, one state transition per input character — regardless of how the pattern was written. PCRE's extra features take it outside that class, so it must explore alternatives and undo them, and "
                c "(a+)+"
                " has exponentially many ways to split a run of "
                c "a"
                "s."
            p_ $ do
                "This is the whole trade. If a pattern will run unattended over input you do not control, the engine that cannot blow up is worth more than lookbehind."

    block "Matching across lines" $ do
        p_ $ do
            "grep is a line filter, and no option changes that — but "
            c "-z"
            " changes what a line "
            em_ "is"
            ". With NUL as the terminator, a whole file becomes one record, and a "
            c "-P"
            " pattern can then match across newlines."
        sh
            [ "$ printf 'BEGIN\\nmiddle\\nEND\\nother\\n' | grep -Pzo 'BEGIN\\n.*\\nEND'"
            , "BEGIN"
            , "middle"
            , "END"
            ]
        gotcha $ do
            p_ $ do
                "The manual calls "
                c "-P"
                " with "
                c "-z"
                " “experimental”, and the output is NUL-terminated, so it needs "
                c "tr '\\0' '\\n'"
                " before a human reads it. Without "
                c "-z"
                ", "
                c "grep -P 'BEGIN\\nEND'"
                " simply never matches — grep already split the input on newlines, so no line contains one."
        p_ $ do
            "This works, and it is still usually the wrong tool. A multi-line pattern over a whole file loaded as one record is what "
            c "awk"
            " with "
            c "RS"
            ", "
            c "sed"
            " with its hold space, or a small script are for. Reach for "
            c "-Pz"
            " for a one-off at the command line, not for something you will have to maintain."

    block "When to put grep down" $ do
        p_ $ do
            "The boundary is sharper than it looks: "
            b_ "grep finds lines"
            ". The moment you are reaching inside a line to extract or rewrite structure, you have left its problem domain, and the pipeline of three greps and a "
            c "cut"
            " that you are about to write is a symptom."
        defs
            [ (c "sed", "Substitution, deletion, and printing a capture group. " <> c "sed -n 's/.*id=\\([0-9]*\\).*/\\1/p'" <> " is the extraction grep cannot do.")
            , (c "awk", "Anything involving columns, arithmetic, accumulation across lines, or two conditions on different fields.")
            , (c "jq" <> ", " <> c "yq" <> ", " <> c "xmlstarlet", "Anything with nesting. A regular expression cannot match balanced delimiters; this is not a skill issue.")
            , (c "rg" <> " / " <> c "ag", do "When you want " <> c ".gitignore" <> " awareness and parallel recursion. Faster on trees, and Day 7's exclusion lists become unnecessary.")
            , (c "comm" <> ", " <> c "join", do "When the pattern list is really a second file you are matching against, and " <> c "-f" <> " is starting to strain.")
            ]
        p_ $ do
            "And when grep is right, it is very right. A single pass, linear time, no dependencies, present on every machine you will ever log into, and a status code the shell understands."

    block "What to read next, and today's habit" $ do
        p_ $ do
            "The manual page ends by admitting it “is maintained only fitfully; the full documentation is often more up-to-date”. That is not false modesty — this course found four places where the page and the 3.12 binary disagree. "
            c "info grep"
            " is the complete manual and is worth an hour."
        defs
            [ (c "info grep", "The full manual, with the usage examples and performance notes the man page omits.")
            , (c "regex(7)", "The POSIX regular-expression language on its own terms, without grep's options around it.")
            , (c "pcre2syntax(3)", do "The " <> c "-P" <> " language. Short, and the right page to keep open the first few times.")
            , (c "glob(7)", "The other pattern language, from Day 7.")
            ]
        p_ $ do
            "The habit to keep is the one from Day 1, because it survives every version change: when a grep prints nothing, find out whether that means "
            em_ "nothing matched"
            " or "
            em_ "nothing was read"
            ". Everything else in this course is detail on top of that."
        cfg
            [ "# ~/grep-recipes.sh"
            , "#"
            , "# Day 10: field extraction. \\K drops everything to its left from the match."
            , "grep -oP 'Bearer \\K\\S+' headers.txt"
            , ""
            , "# Day 10: -P takes ONE pattern. Use an alternation, never two -e options."
            , "grep -P 'ERROR|WARN' app.log"
            , ""
            , "# Day 10: the whole file as one record, so a pattern can cross newlines."
            , "grep -Pzo 'BEGIN\\n.*\\nEND' file | tr '\\0' '\\n'"
            , ""
            , "# Day 10: last step of the course - delete every line above that you"
            , "# can no longer explain to someone else."
            ]

cheat :: Html ()
cheat =
    cfg
        [ "-P   the PCRE2 engine. A DIFFERENT engine, not a bigger one."
        , "     leftmost-FIRST (POSIX is leftmost-longest) - 'ab|abcd' differs"
        , ""
        , "(?=x) (?!x)      lookahead, positive / negative"
        , "(?<=x) (?<!x)    lookbehind - the assertion must be FIXED LENGTH"
        , "\\K               drop everything to the left from the reported match"
        , "*? +? ??         lazy: match as little as possible"
        , "\\d \\s \\w         POSIX already has [[:digit:]] [[:space:]] \\w"
        , "-Pz              NUL records, so a pattern can cross newlines ('experimental')"
        , ""
        , "# the four costs, in the order they will bite you:"
        , "#  1. ONE pattern only - two -e options exit 2. NOT IN THE MAN PAGE."
        , "#  2. backtracking limit: '(a+)+$' EXITS 2 where -E answers in 10ms"
        , "#  3. may not be compiled in at all"
        , "#  4. least portable thing in this course"
        , ""
        , "# grep finds LINES. Reaching inside one? sed / awk / jq / a real parser."
        ]
