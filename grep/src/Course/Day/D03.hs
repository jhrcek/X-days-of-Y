module Course.Day.D03 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 3
        , dayTitle = "Matching one character"
        , daySubtitle = "Bracket expressions, named classes, and the anchors that match nothing at all."
        , dayMinutes = 35
        , dayLevel = "essential"
        , dayManRef = "REGULAR EXPRESSIONS: Character Classes and Bracket Expressions, Anchoring, The Backslash Character"
        , dayTags = ["brackets", "[:classes:]", "anchors"]
        , dayGoals =
            [ "put " <> c "]" <> ", " <> c "^" <> " and " <> c "-" <> " literally inside a bracket expression without escaping anything"
            , "explain why an anchor is not a character and what that costs you"
            , "choose between " <> c "-w" <> ", " <> c "\\<...\\>" <> " and a hand-written bracket expression for a word boundary"
            ]
        , dayDiagram = Just d3diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds = []
        , dayOpts =
            [ (".", "Match any single character. Whether it matches an encoding error is unspecified.")
            , ("[abc]", "Match one character from the list.")
            , ("[^abc]", "Match one character " <> em_ "not" <> " in the list. The " <> c "^" <> " must come first.")
            , ("[a-d]", "A range. In the C locale, ASCII order; elsewhere the standard says it is unspecified.")
            , ("[[:digit:]]", "A named class. The outer brackets are yours, the inner ones are part of the name.")
            , ("^ and $", "Anchor to the start and end of a line. They match a position, not a character.")
            , ("\\< and \\>", "Anchor to the start and end of a word. A GNU extension.")
            , ("\\b and \\B", "Anchor at, and not at, a word edge. " <> c "\\b" <> " is either edge; " <> c "\\<" <> " is only the left.")
            , ("\\w and \\W", "Shorthand for " <> c "[_[:alnum:]]" <> " and " <> c "[^_[:alnum:]]" <> ". Note the underscore.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Run " <> c "grep '^root' /etc/passwd" <> " and then " <> c "grep 'root$' /etc/passwd" <> ". The first matches, the second almost certainly does not. Anchors are about position, and the shell in the last field is not " <> c "root" <> "."
            , "Count the blank lines in a file you are working on: " <> c "grep -c '^$' somefile" <> ". That pattern is two anchors and nothing else — it matches a position, then immediately another one."
            , "Break it on purpose: " <> c "grep '[:digit:]' /etc/passwd" <> ". grep refuses with a specific and genuinely helpful message telling you the syntax is " <> c "[[:digit:]]" <> ". Read it; it is the error you will make most often."
            , "Prove the awkward literals in one go: " <> c "printf 'a]b\\na-b\\na^b\\n' | grep '[]^-]'" <> " matches all three lines. " <> c "]" <> " first, " <> c "^" <> " not first, " <> c "-" <> " last, and no backslashes anywhere."
            , "Find lines with a literal dot: " <> c "grep 'a\\.c'" <> " versus " <> c "grep 'a.c'" <> " over " <> c "printf 'a.c\\nabc\\n'" <> ". The unescaped one takes both. This is the single most common false positive in daily grep use."
            , "Compare the three word boundaries on one line: " <> c "echo 'foo foobar' | grep -o '\\<foo\\>'" <> ", then with " <> c "'\\bfoo\\b'" <> ", then with " <> c "'\\Bfoo'" <> ". The last matches nothing, and working out why is the point."
            , "On your own work: find every identifier in a source file that starts with an underscore — " <> c "grep -o '\\<_[[:alnum:]_]*'" <> " — and notice that " <> c "\\<" <> " sits happily before the underscore because a word can begin with one."
            , "Add to " <> c "~/grep-recipes.sh" <> " the one bracket expression you had to look up today, with a comment saying what it is for."
            ]
        , dayQuiz =
            [
                ( "You want lines containing a version number like "
                    <> c "1.2.3"
                    <> " so you write "
                    <> c "grep '[0-9].[0-9].[0-9]'"
                    <> ". It matches "
                    <> c "1x2y3"
                    <> " and, more annoyingly, "
                    <> c "sha256"
                    <> ". What went wrong, and what is the minimal fix?"
                , do
                    p_ $ do
                        "The unescaped "
                        c "."
                        " matches any character, so the pattern really says “digit, anything, digit, anything, digit”. "
                        c "sha256"
                        " has "
                        c "2"
                        ", "
                        c "5"
                        ", "
                        c "6"
                        " with nothing between them — but "
                        c "."
                        " needs a character to consume, so what actually matched there was a longer window in the surrounding text."
                    p_ $ do
                        "The minimal fix is "
                        c "grep '[0-9]\\.[0-9]\\.[0-9]'"
                        ". The tidier fix is a bracket expression, "
                        c "'[0-9][.][0-9][.][0-9]'"
                        ", because inside brackets the dot has no special meaning at all and you never have to think about backslashes again."
                )
            ,
                ( "Inside a bracket expression, why is "
                    <> c "[a^-]"
                    <> " three literal characters while "
                    <> c "[^a-]"
                    <> " is a negation of two?"
                , do
                    p_ $ do
                        "Because position is the entire syntax. "
                        c "^"
                        " negates only when it is the "
                        em_ "first"
                        " character after "
                        c "["
                        "; anywhere else it is a literal caret. "
                        c "-"
                        " forms a range only when it has a character on both sides; last (or first) it is a literal hyphen. And "
                        c "]"
                        " closes the expression unless it is first, in which case it is a literal bracket."
                    p_ $ do
                        "So "
                        c "[]^-]"
                        " is the set of those three awkward characters, written with no escapes at all. Backslash is not the mechanism here — inside brackets most metacharacters simply lose their meaning, which is why "
                        c "[.]"
                        " and "
                        c "[*]"
                        " are the cleanest way to write a literal dot or star."
                )
            ,
                ( "Why does "
                    <> c "grep -c '^$' file"
                    <> " work at all, when the pattern contains no characters to match?"
                , do
                    p_ $ do
                        "Because anchors do not consume characters — they assert something about a "
                        em_ "position"
                        ". "
                        c "^"
                        " asserts “we are at the start of the line”, "
                        c "$"
                        " asserts “we are at the end”, and on a blank line both are true of the same position, so the pattern matches the empty string there."
                    p_ $ do
                        "This is also why "
                        c "grep -o '^'"
                        " prints nothing useful and why "
                        c "-w"
                        " and "
                        c "\\b"
                        " can be combined freely: adding a zero-width assertion never changes how much text the match covers, only whether the match is allowed."
                )
            ,
                ( "The manual page warns that outside the C locale, "
                    <> c "[a-d]"
                    <> " “might be equivalent to "
                    <> c "[abcd]"
                    <> " or "
                    <> c "[aBbCcDd]"
                    <> " or some other bracket expression”. You test it on your machine and it behaves sensibly in every locale. Is the warning wrong?"
                , do
                    p_ $ do
                        "Not wrong — out of date for "
                        em_ "this"
                        " C library. On glibc 2.42 the range "
                        c "[a-d]"
                        " matches exactly "
                        c "abcd"
                        " in both "
                        c "C"
                        " and "
                        c "en_US.UTF-8"
                        "; the collation-order behaviour the page describes is not what you get."
                    p_ $ do
                        "The warning is about "
                        em_ "portability"
                        ", and there it still stands: POSIX leaves the behaviour unspecified, other libcs have made other choices, and the fact that your machine is well-behaved tells you nothing about the container your script will eventually run in. Where it matters, say "
                        c "LC_ALL=C"
                        " or write the set out as "
                        c "[abcd]"
                        ". Named classes like "
                        c "[[:lower:]]"
                        " are the portable way to mean a range."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d3diagram :: Diagram
d3diagram =
    (diagram
        "A bracket expression, the period and a literal are the three kinds of single-character regex, all of which consume a character; anchors are a separate kind that match a position and consume nothing. Ranges and named classes are interpreted by the locale."
        body'
    )
        { dgCaption = do
            "The split that matters is horizontal, not vertical: everything on the left consumes exactly one character of input, and the anchor on the right consumes none. Combining them is free — "
            c "\\<[[:upper:]]"
            " is one assertion and one character — and it is why adding "
            c "^"
            " to a pattern never changes what "
            c "-o"
            " prints."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  scr  [label=\"a single-character\\nregex\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  br   [label=\"a bracket expression\\n[...]\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  cls  [label=\"a named class\\n[:digit:]\"];"
            , "  rng  [label=\"a range\\na-d\"];"
            , "  dot  [label=\"the period .\"];"
            , "  ch   [label=\"a character\"];"
            , "  anc  [label=\"an anchor\\n^ $ \\\\< \\\\> \\\\b \\\\B\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  pos  [label=\"a position\\nbetween characters\"];"
            , "  loc  [label=\"the locale\", fillcolor=\"#f4efe6\"];"
            , ""
            , "  br  -> scr [label=\"  is\"];"
            , "  dot -> scr [label=\"  is\"];"
            , "  cls -> br  [label=\"  may appear inside\"];"
            , "  rng -> br  [label=\"  may appear inside\"];"
            , "  cls -> loc [label=\"  is defined by\"];"
            , "  rng -> loc [label=\"  is interpreted by\"];"
            , "  scr -> ch  [label=\"  consumes\"];"
            , "  anc -> pos [label=\"  matches\"];"
            , "  anc -> ch  [label=\"  never consumes  \", style=dashed, constraint=false];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Everything is built from one-character matchers" $ do
        p_ [class_ "lede"] $ do
            "A regular expression is a stack of two ideas. The bottom one — today — is a handful of ways to say “one character, from this set”. The top one, tomorrow, is a handful of ways to say “this thing, repeated, or that thing instead”. Almost every grep that goes wrong goes wrong at the bottom."
        p_ $ do
            "Most characters match themselves. The period matches any single character. A bracket expression matches one character from an explicit set. That is the whole inventory, and everything else on this page is either a shorthand for a bracket expression or an anchor, which is a different animal entirely."
        fig
        gotcha $ do
            p_ $ do
                "The unescaped "
                c "."
                " is the most expensive habit in daily grep use. "
                c "grep '10.0.0.1' access.log"
                " will happily match "
                c "10x0y0z1"
                " and, far more often, some longer run of digits inside a hash. Write "
                c "'10\\.0\\.0\\.1'"
                " or, better, "
                c "grep -F '10.0.0.1'"
                " — Day 4 explains why the fixed-string matcher is usually the right answer for an IP address."

    block "Bracket expressions, and their three awkward characters" $ do
        p_ $ do
            "Inside "
            c "[...]"
            " most metacharacters lose their powers: "
            c "[.]"
            " is a literal dot, "
            c "[*]"
            " a literal star. Three characters keep a meaning, and all three are disarmed by "
            em_ "position"
            " rather than by backslashes."
        defs
            [
                ( c "]"
                , do
                    "Closes the expression — unless it is the very first character, where it is a literal. "
                    c "[]]"
                    " matches a right bracket."
                )
            ,
                ( c "^"
                , do
                    "Negates the set — but only as the first character. "
                    c "[b^]"
                    " matches a "
                    c "b"
                    " or a caret."
                )
            ,
                ( c "-"
                , do
                    "Forms a range — but only with a character on each side. Put it last (or first) and it is a literal hyphen: "
                    c "[x-]"
                    "."
                )
            ]
        sh
            [ "$ printf 'a]b\\na-b\\na^b\\n' | grep '[]^-]'"
            , "a]b"
            , "a-b"
            , "a^b"
            ]
        p_ $ do
            "One bracket expression, three literals, no escapes. Learning that "
            c "[]^-]"
            " is legal saves you from the backslash-counting that most people fall into."
        why $ do
            p_ $ do
                "Bracket expressions predate the idea that backslash is the universal escape. They come from the original "
                c "ed"
                " syntax, where the contents of "
                c "[...]"
                " were a nearly literal character list, and POSIX froze that. The compensation for having no escape character is that you need almost none: the only things you cannot write directly are the three above, and each of them has a position where it is harmless."

    block "Named classes, and the error you will make" $ do
        p_ $ do
            "The twelve named classes are "
            c "[:alnum:]"
            ", "
            c "[:alpha:]"
            ", "
            c "[:blank:]"
            ", "
            c "[:cntrl:]"
            ", "
            c "[:digit:]"
            ", "
            c "[:graph:]"
            ", "
            c "[:lower:]"
            ", "
            c "[:print:]"
            ", "
            c "[:punct:]"
            ", "
            c "[:space:]"
            ", "
            c "[:upper:]"
            " and "
            c "[:xdigit:]"
            ". The brackets in those names are "
            b_ "part of the name"
            ", so they always appear inside a bracket expression of your own."
        sh
            [ "$ grep '[:digit:]' /etc/passwd"
            , "grep: character class syntax is [[:space:]], not [:space:]"
            , "$ echo $?"
            , "2"
            ]
        p_ $ do
            "grep detects this specific mistake and says so, which is unusually kind of it — without the check, "
            c "[:digit:]"
            " would silently be “one of the characters "
            c ":digit"
            "”, and you would spend an afternoon on it. The correct form is "
            c "[[:digit:]]"
            ", and a class can sit alongside other members: "
            c "[[:digit:]a-fA-F]"
            "."
        tip $ do
            p_ $ do
                "Named classes are the portable way to write a range. "
                c "[[:lower:]]"
                " means whatever the locale says lowercase is; "
                c "[a-z]"
                " means whatever the locale says that range is, which POSIX declines to define. If you find yourself writing "
                c "[A-Za-z0-9]"
                ", write "
                c "[[:alnum:]]"
                " instead and it will keep working in Turkish."

    block "Anchors match nothing, and that is the point" $ do
        p_ $ do
            "An anchor is a "
            em_ "zero-width assertion"
            ": it matches a position between characters rather than a character. "
            c "^"
            " and "
            c "$"
            " are the line boundaries. GNU adds four word anchors, and the difference between them is worth getting right once."
        defs
            [ (c "\\<", "The position at the start of a word — a non-word character (or line start) on the left, a word character on the right.")
            , (c "\\>", "The position at the end of a word. The mirror image.")
            , (c "\\b", do "Either edge. " <> c "\\bfoo\\b" <> " and " <> c "\\<foo\\>" <> " agree on ordinary words, and " <> c "\\b" <> " is the one other tools also understand.")
            , (c "\\B", do "A position that is " <> em_ "not" <> " a word edge. Useful for finding an identifier fragment in the middle of longer names.")
            ]
        sh
            [ "$ echo 'foo foobar' | grep -o '\\<foo\\>'"
            , "foo"
            , "$ echo 'foo foobar' | grep -o '\\Bfoo'"
            , "$ echo $?"
            , "1"
            ]
        p_ $ do
            "The second one finds nothing: both occurrences of "
            c "foo"
            " begin at a word edge, which is exactly what "
            c "\\B"
            " forbids. Note also that "
            c "\\w"
            " is defined as "
            c "[_[:alnum:]]"
            " — it includes the underscore, and so do all four word anchors. That is the same definition "
            c "-w"
            " uses, so "
            c "grep -w foo"
            " and "
            c "grep '\\<foo\\>'"
            " agree."
        gotcha $ do
            p_ $ do
                "In basic regular expressions, "
                c "^"
                " is an anchor only at the start of the pattern and "
                c "$"
                " only at the end. Elsewhere they are literals: "
                c "grep 'a^b'"
                " really does find the text "
                c "a^b"
                ". Extended regular expressions do not have this rule — "
                c "grep -E 'a^b'"
                " is an anchor in an impossible position and matches nothing at all. Same pattern, two dialects, two answers, and no error message from either."

    block "Today's habit" $ do
        p_ $ do
            "When a grep returns more than you expected, the first thing to suspect is an unescaped "
            c "."
            ". When it returns less, the first thing to suspect is a word boundary you did not know included underscores."
        cfg
            [ "# ~/grep-recipes.sh"
            , "#"
            , "# Day 3: the three awkward literals, no escapes needed."
            , "grep '[]^-]' file            # matches ] or ^ or - "
            , ""
            , "# Day 3: portable, locale-proof character sets."
            , "grep '[[:digit:]]\\{1,3\\}\\.' file   # classes, not [0-9]; ranges are unspecified"
            , ""
            , "# Day 3: blank lines, and lines that are only whitespace."
            , "grep -c '^$' file"
            , "grep -c '^[[:space:]]*$' file"
            ]

cheat :: Html ()
cheat =
    cfg
        [ ".          any one character  (the #1 source of false positives - escape it)"
        , "[abc]      one of a, b, c          [^abc]  one character that is NOT"
        , "[a-d]      a range; POSIX says unspecified outside the C locale"
        , "[[:digit:]]  a named class - the INNER brackets are part of the name"
        , "           alnum alpha blank cntrl digit graph lower print punct space upper xdigit"
        , ""
        , "# the three awkward literals - fixed by POSITION, never by backslash"
        , "[]]  ] must be first     [b^]  ^ anywhere but first     [x-]  - must be last"
        , ""
        , "# anchors: match a POSITION, consume no characters"
        , "^  $        line start / line end   (in BRE, literal anywhere else)"
        , "\\< \\>       word start / word end    \\b  either edge   \\B  not an edge"
        , "\\w  \\W      [_[:alnum:]] and its complement - note the UNDERSCORE"
        ]
