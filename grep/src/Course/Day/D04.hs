module Course.Day.D04 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 4
        , dayTitle = "Matching many"
        , daySubtitle = "Repetition, alternation, precedence — and the three dialects that spell them differently."
        , dayMinutes = 40
        , dayLevel = "essential"
        , dayManRef = "REGULAR EXPRESSIONS: Repetition through Basic vs Extended; OPTIONS: Pattern Syntax"
        , dayTags = ["-E -G -F", "precedence", "leftmost-longest"]
        , dayGoals =
            [ "translate any pattern between basic and extended syntax without trial and error"
            , "predict which of two overlapping alternatives grep will report, and why " <> c "-P" <> " disagrees"
            , "reach for " <> c "-F" <> " automatically whenever the pattern came from a variable"
            ]
        , dayDiagram = Just d4diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds = []
        , dayOpts =
            [ ("*", "Zero or more of the preceding item. The only repetition operator BRE spells the same way.")
            , ("? and +", "At most one, and at least one. In BRE you must write " <> c "\\?" <> " and " <> c "\\+" <> ".")
            , ("{n,m}", "Between n and m times. " <> c "{,m}" <> " with no lower bound is a GNU extension.")
            , ("|", "Alternation, and the loosest-binding operator there is. BRE spells it " <> c "\\|" <> ".")
            , ("(...)", "Group, to override precedence. BRE spells it " <> c "\\(...\\)" <> ".")
            , ("\\1 … \\9", "Re-match the exact text the nth group captured. Slow, and worth avoiding.")
            , ("-E, --extended-regexp", "Extended syntax: the operators above are bare. What you usually want.")
            , ("-G, --basic-regexp", "Basic syntax: " <> c "? + { | ( )" <> " need backslashes. The default.")
            , ("-F, --fixed-strings", "No regex at all. Every pattern is a literal string, and it is the fastest matcher.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Run " <> c "echo 'color colour' | grep -oE 'colou?r'" <> ". Both words. Now drop the " <> c "-E" <> " and watch it find nothing — in basic syntax that " <> c "?" <> " is a literal question mark."
            , "Fix it the basic way: " <> c "echo 'color colour' | grep -o 'colou\\?r'" <> ". Same two words. You have now written the same pattern in both dialects, which is the whole of this page."
            , "Watch precedence bite: " <> c "echo abc | grep -oE '^ab|bc$'" <> " prints " <> c "ab" <> ", not the whole line. " <> c "|" <> " binds loosest, so that pattern means “starts with ab” OR “ends with bc”, not “starts with a, then b-or-b, then c”."
            , "Break something on purpose: " <> c "grep -E -F pattern file" <> ". grep refuses with " <> c "conflicting matchers specified" <> " and exits 2. Unlike " <> c "-i" <> " and " <> c "--no-ignore-case" <> ", the matcher flags do not override each other — the last one does not win, it errors."
            , "See leftmost-longest for yourself: " <> c "echo abcd | grep -oE 'ab|abcd'" <> " prints " <> c "abcd" <> ". Then " <> c "echo abcd | grep -oP 'ab|abcd'" <> " prints " <> c "ab" <> ". Same pattern, same input, two engines, two answers."
            , "Take a literal string with punctuation in it — a version number, an IP, a file path — and grep your own notes for it twice, once bare and once with " <> c "-F" <> ". Count the difference in false positives."
            , "On your own work: find doubled words with a back-reference, " <> c "grep -nE '\\b([a-z]+) \\1\\b' *.md" <> ", over some prose you have written. Then read the BUGS section of " <> c "man grep" <> " on why you should not put that in a script."
            , "Add to " <> c "~/grep-recipes.sh" <> " the rule you will actually follow: if the pattern came from a variable, it gets " <> c "-F" <> "."
            ]
        , dayQuiz =
            [
                ( "You write "
                    <> c "grep -E 'ab|abcd'"
                    <> " with "
                    <> c "-o"
                    <> " over the line "
                    <> c "abcd"
                    <> " and get "
                    <> c "abcd"
                    <> ", even though "
                    <> c "ab"
                    <> " is listed first and matches at the same place. Is grep ignoring your ordering?"
                , do
                    p_ $ do
                        "It is ignoring it deliberately. POSIX regular expressions are "
                        b_ "leftmost-longest"
                        ": among all matches starting at the earliest possible position, the engine returns the "
                        em_ "longest"
                        ". The order of the alternatives carries no information at all."
                    p_ $ do
                        "Perl-compatible expressions are leftmost-"
                        em_ "first"
                        " instead — they try the alternatives in order and take the first that succeeds — so "
                        c "grep -oP 'ab|abcd'"
                        " on the same line prints "
                        c "ab"
                        ". If you have ever ported a pattern from a scripting language and watched it match more than it used to, this is why. Day 10 returns to it."
                )
            ,
                ( "A script does "
                    <> c "grep \"$user_input\" data.txt"
                    <> ". A user types "
                    <> c "a.*"
                    <> " and gets the whole file; another types "
                    <> c "["
                    <> " and the script exits 2. What is the fix, and why is escaping the input not it?"
                , do
                    p_ $ do
                        "The fix is "
                        c "grep -F -- \"$user_input\" data.txt"
                        ". "
                        c "-F"
                        " says the pattern is a literal string, so "
                        c "a.*"
                        " matches the three characters "
                        c "a.*"
                        " and "
                        c "["
                        " matches a bracket. The "
                        c "--"
                        " separately stops an input beginning with "
                        c "-"
                        " from being read as an option."
                    p_ $ do
                        "Escaping is not the fix because there is no correct escaping function you can write in shell: the set of metacharacters differs between BRE, ERE and PCRE, and "
                        c "["
                        " opens a construct rather than being a self-contained character. "
                        c "-F"
                        " removes the problem instead of trying to sanitise it, and as a bonus it is the fastest matcher grep has."
                )
            ,
                ( "In basic syntax "
                    <> c "grep 'a+b'"
                    <> " finds the literal text "
                    <> c "a+b"
                    <> ". So why does "
                    <> c "grep 'a{b'"
                    <> " also find the literal text "
                    <> c "a{b"
                    <> ", when "
                    <> c "{"
                    <> " is supposedly reserved?"
                , do
                    p_ $ do
                        "The two are literals for different reasons. "
                        c "+"
                        " is unconditionally a literal in BRE — the operator is spelled "
                        c "\\+"
                        ". "
                        c "{"
                        " is a literal here only because "
                        c "{b"
                        " is not a well-formed interval; GNU grep falls back to treating an unparseable brace as ordinary text rather than erroring."
                    p_ $ do
                        "POSIX leaves that case undefined, so it is a GNU kindness you should not lean on. It also means a typo inside an interval — "
                        c "a{2,x}"
                        " — silently becomes a literal search instead of the error you would prefer. If you mean a brace, bracket it: "
                        c "[{]"
                        "."
                )
            ,
                ( "Why does the manual's BUGS section single out back-references as “very slow, and may require exponential time”, when "
                    <> c ".*"
                    <> " is also unbounded?"
                , do
                    p_ $ do
                        "Because they take grep off its fast path. Without back-references a POSIX regular expression can be compiled to a deterministic automaton and matched in time linear in the input, whichever way it is written. A back-reference is not a regular language at all — the engine has to remember what group 1 actually captured and re-check it — so grep falls back to backtracking, where a pattern like "
                        c "(a+)+b"
                        " can explore exponentially many splits."
                    p_ $ do
                        "The practical rule: back-references are fine interactively on a file you can see the end of, and do not belong in anything that runs unattended over input you do not control. The same paragraph warns that large "
                        c "{n,m}"
                        " counts can eat memory, for the related reason that the automaton is built by expansion."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d4diagram :: Diagram
d4diagram =
    ( diagram
        "A regular expression is an alternation of concatenations of repetitions of atoms; a parenthesised subexpression is itself an atom, which is how the ladder recurses, and a back-reference is an atom that re-matches a subexpression's captured text."
        body'
    )
        { dgCaption = do
            "Read the chain downwards and you have the precedence rules exactly: "
            c "|"
            " binds loosest, then juxtaposition, then the repetition operators, then a single atom. "
            c "abc|d"
            " is therefore "
            c "(abc)|(d)"
            " and never "
            c "ab(c|d)"
            ". Parentheses are the only rung that lets a whole expression become an atom again — which is why they are the only way to make "
            c "|"
            " bind tighter than concatenation."
        , dgRankdir = "TB"
        , dgRanksep = "0.4"
        }
  where
    body' =
        T.unlines
            [ "  re   [label=\"a regular expression\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  alt  [label=\"an alternation\\nx|y\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  cat  [label=\"a concatenation\\nxy\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  rep  [label=\"a repetition\\nx*  x+  x?  x{n,m}\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  atom [label=\"an atom\"];"
            , "  sub  [label=\"a subexpression\\n( ... )\"];"
            , "  bref [label=\"a back-reference\\n\\\\1\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  re   -> alt  [label=\"  is\"];"
            , "  alt  -> cat  [label=\"  is a choice between\"];"
            , "  cat  -> rep  [label=\"  is a sequence of\"];"
            , "  rep  -> atom [label=\"  repeats\"];"
            , "  sub  -> atom [label=\"  is\"];"
            , "  sub  -> re   [label=\"  encloses  \", constraint=false];"
            , "  bref -> atom [label=\"  is\"];"
            , "  bref -> sub  [label=\"  re-matches the text of  \", style=dashed, constraint=false];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "One language, three notations, and a fourth that is not a language" $ do
        p_ [class_ "lede"] $ do
            "Yesterday was “one character”. Today is everything built on top: repeat it, put two of them in a row, offer a choice. The operators are the same handful you already half-know; what trips people up is that grep spells them three different ways and defaults to the least convenient one."
        p_ $ do
            "The manual is unusually direct about this: “In GNU grep, basic and extended regular expressions are merely different notations for the same pattern-matching functionality.” "
            c "-G"
            " and "
            c "-E"
            " are not more and less powerful. They differ in exactly which characters need a backslash, and the difference runs the wrong way from every other tool you use."
        fig
        why $ do
            p_ $ do
                "Basic syntax is the default for compatibility, not because anyone prefers it. It is the "
                c "ed"
                " syntax from 1971, when "
                c "+"
                " and "
                c "?"
                " and "
                c "|"
                " were not yet operators, so those characters were ordinary text in existing scripts. When the operators were added they had to be given backslashed spellings to avoid breaking every regexp already written. Extended syntax was the later, cleaner take, and POSIX standardised both rather than choose."

    block "The precedence ladder" $ do
        p_ $ do
            "Repetition binds tightest, then concatenation, then alternation. That single sentence resolves most regex surprises, and the worked example is worth memorising:"
        sh
            [ "$ echo abc | grep -oE '^ab|bc$'"
            , "ab"
            ]
        p_ $ do
            "That pattern is "
            c "(^ab)|(bc$)"
            ", not "
            c "^a(b|b)c$"
            ". The alternation swallowed everything on both sides of it, including the anchors. If you meant the other thing, parenthesise: "
            c "'^a(b|d)c$'"
            "."
        defs
            [ (c "x*", "Zero or more. Greedy — it takes as much as it can while still letting the rest of the pattern match.")
            , (c "x?", "At most one.")
            , (c "x+", "One or more.")
            , (c "x{3}", "Exactly three.")
            , (c "x{2,}", "Two or more.")
            , (c "x{,4}", do "At most four. This one is a " <> b_ "GNU extension" <> " — POSIX has no such form, so it is not portable.")
            , (c "x{2,4}", "Between two and four.")
            ]

    block "Leftmost-longest: the rule that surprises everyone" $ do
        p_ $ do
            "POSIX regular expressions do not try your alternatives in order. Among all matches beginning at the earliest position in the line, the engine returns the "
            b_ "longest"
            " one. Ordering is not a tiebreaker; it carries no meaning."
        sh
            [ "$ echo abcd | grep -oE 'ab|abcd'"
            , "abcd"
            , "$ echo abcd | grep -oP 'ab|abcd'"
            , "ab"
            ]
        gotcha $ do
            p_ $ do
                "Perl-compatible expressions are leftmost-"
                em_ "first"
                ": they take the first alternative that works. That is the same pattern, the same input, and two different answers, decided entirely by whether you passed "
                c "-E"
                " or "
                c "-P"
                ". Patterns copied out of a Python or JavaScript codebase carry the leftmost-first assumption with them, and under "
                c "-E"
                " they quietly match more than they did at home."

    block "Translating between the dialects" $ do
        p_ $ do
            "Six characters change meaning between the two notations, and nothing else does. In extended syntax "
            c "? + { | ( )"
            " are operators; in basic syntax they are literal text, and the operators are "
            c "\\? \\+ \\{ \\| \\( \\)"
            ". The backslash inverts the meaning rather than removing it."
        cols
            [ do
                p_ $ b_ "Extended — " <> c "grep -E"
                cfg
                    [ "colou?r"
                    , "(cat|dog)s?"
                    , "^[0-9]{1,3}\\.[0-9]{1,3}$"
                    , "(ab)+c"
                    ]
            , do
                p_ $ b_ "Basic — " <> c "grep" <> " (the default)"
                cfg
                    [ "colou\\?r"
                    , "\\(cat\\|dog\\)s\\?"
                    , "^[0-9]\\{1,3\\}\\.[0-9]\\{1,3\\}$"
                    , "\\(ab\\)\\+c"
                    ]
            ]
        p_ $ do
            "Note that "
            c "*"
            ", "
            c "."
            ", "
            c "^"
            ", "
            c "$"
            " and bracket expressions are identical in both, which is why so many people get away with never learning the distinction. Back-references are "
            c "\\1"
            " in both — and GNU accepts them in extended syntax too, although POSIX does not require it."
        tip $ do
            p_ $ do
                "Just pass "
                c "-E"
                ". The only reasons to stay with basic syntax are a pattern inherited from an old script, or a pattern containing a lot of literal braces and parentheses. A widely repeated claim that "
                c "-E"
                " is slower has not been true for decades — both compile to the same automaton."

    block "The matcher that is not a regex at all" $ do
        p_ $ do
            c "-F"
            " turns the pattern language off. Every pattern is a literal string; "
            c "."
            " is a full stop and "
            c "*"
            " is an asterisk. It is also the fastest matcher grep has, because a set of fixed strings can go through Commentz-Walter rather than a general automaton."
        sh
            [ "$ printf 'a.c\\nabc\\n' | grep -F 'a.c'"
            , "a.c"
            , "$ grep -E -F pattern file"
            , "grep: conflicting matchers specified"
            ]
        gotcha $ do
            p_ $ do
                "The four matcher flags do "
                b_ "not"
                " override one another the way "
                c "-i"
                " and "
                opt "--no-ignore-case"
                " do. Specifying two is an error and exits 2, even if you give the same one twice in different spellings. A wrapper script that appends "
                c "-E"
                " to a command line that already said "
                c "-F"
                " does not quietly win — it breaks."
        p_ $ do
            "The rule worth adopting: "
            b_ "if the pattern came from a variable, it gets -F"
            ". User input, a filename, a version string, a value read out of JSON — none of those were written as regular expressions, and passing them as regular expressions is how you get both false positives and hard exits on a stray bracket."

    block "Today's habit" $ do
        p_ $ do
            "Two rules, and they cover most of what goes wrong: reach for "
            c "-E"
            " by reflex, and reach for "
            c "-F"
            " whenever the pattern is data rather than something you typed."
        cfg
            [ "# ~/grep-recipes.sh"
            , "#"
            , "# Day 4: a pattern that came from a variable is DATA, not a regex."
            , "grep -F -- \"$needle\" file          # -F for the metacharacters, -- for a leading dash"
            , ""
            , "# Day 4: doubled words in prose. Interactive only - back-references"
            , "# take grep off its linear-time path (see BUGS in man grep)."
            , "grep -nE '\\b([a-z]+) \\1\\b' *.md"
            ]

cheat :: Html ()
cheat =
    cfg
        [ "# precedence, loosest first:   |    then juxtaposition   then * + ? {n,m}"
        , "#   'abc|d'  is  '(abc)|(d)'        - () is the only way to change this"
        , "# POSIX is LEFTMOST-LONGEST: 'ab|abcd' on abcd gives abcd, order is ignored"
        , "#   -P is leftmost-FIRST and gives ab. Same pattern, different answer."
        , ""
        , "#            extended (-E)        basic (-G, the default)"
        , "# optional   colou?r              colou\\?r"
        , "# one-or-more (ab)+c              \\(ab\\)\\+c"
        , "# alternate  (cat|dog)            \\(cat\\|dog\\)"
        , "# interval   x{1,3}   x{,3}=GNU   x\\{1,3\\}"
        , "#  . * ^ $ [...] \\1  are spelled the SAME in both"
        , ""
        , "-F   pattern is a literal string, and the fastest matcher. Use it whenever"
        , "     the pattern came from a variable. Two matcher flags = exit 2, not last-wins."
        ]
