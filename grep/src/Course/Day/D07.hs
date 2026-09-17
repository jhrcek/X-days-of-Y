module Course.Day.D07 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 7
        , dayTitle = "Searching a tree"
        , daySubtitle = "Recursion, and a second pattern language that is not regular expressions."
        , dayMinutes = 35
        , dayLevel = "intermediate"
        , dayManRef = "OPTIONS: File and Directory Selection"
        , dayTags = ["-r -R", "--include", "globs"]
        , dayGoals =
            [ "keep " <> c "grep -r" <> " out of " <> c ".git" <> " and " <> c "node_modules" <> " without thinking about it"
            , "explain why " <> c "--include='src/*.c'" <> " matches nothing when recursing but works on a named file"
            , "predict what swapping the order of an " <> opt "--include" <> " and an " <> opt "--exclude" <> " does"
            ]
        , dayDiagram = Just d7diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds = []
        , dayOpts =
            [ ("-r, --recursive", "Descend into directories, following symbolic links only if named on the command line.")
            , ("-R, --dereference-recursive", "Descend, following every symbolic link. Can loop forever on a cyclic tree.")
            , ("-d ACTION, --directories=ACTION", c "read" <> " (the default, which fails on Linux), " <> c "skip" <> ", or " <> c "recurse" <> " — the last being " <> c "-r" <> ".")
            , ("-D ACTION, --devices=ACTION", c "read" <> " (default) or " <> c "skip" <> ", for devices, FIFOs and sockets. " <> c "skip" <> " stops grep blocking on a pipe.")
            , ("--include=GLOB", "Search only files whose base name matches GLOB.")
            , ("--exclude=GLOB", "Skip files whose base name matches GLOB.")
            , ("--exclude-dir=GLOB", "Skip directories whose base name matches GLOB. Trailing slashes are ignored.")
            , ("--exclude-from=FILE", "Read a list of " <> opt "--exclude" <> " globs from a file, one per line.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "In any git repository, run " <> c "grep -rl . . | wc -l" <> " and then " <> c "grep -rl --exclude-dir=.git . . | wc -l" <> ". The difference is how much of your last search was spent inside " <> c ".git" <> "."
            , "Confirm that grep has no ignore file: " <> c "grep -rl needle ." <> " in a tree with a " <> c "node_modules" <> " walks straight into it. grep is not ripgrep and never pretends to be."
            , "Break the glob on purpose: " <> c "grep -rl --include='src/*.c' needle ." <> " finds nothing and exits 1. Then " <> c "grep -l --include='src/*.c' needle src/a.c" <> " finds it. Same glob, same file, two answers — the recursive form tests base names, which never contain a slash."
            , "Watch order change the result: " <> c "grep -rl --include='*.c' --exclude='test_*' needle ." <> " gives you C files without tests. Swap the two options and you get " <> em_ "every file in the tree" <> ", including the " <> c ".js" <> " and " <> c ".md" <> " ones."
            , "Prove the symlink rule both ways: " <> c "ln -s src link" <> ", then " <> c "grep -rl needle ." <> " (does not enter it) versus " <> c "grep -Rl needle ." <> " (does) versus " <> c "grep -rl needle link" <> " (does, because you named it)."
            , "On your own work: write the one recursive invocation you want for this project — the right " <> opt "--include" <> ", the right " <> opt "--exclude-dir" <> " list — and time it against the naive version."
            , "Put that list somewhere reusable: " <> c "printf '*.min.js\\n*.map\\n' > ~/.grep-exclude" <> " and use " <> c "--exclude-from=~/.grep-exclude" <> ". It is the closest thing grep has to a config file."
            , "Add the finished invocation to " <> c "~/grep-recipes.sh" <> " as a shell function, with a comment naming the directories it skips and why."
            ]
        , dayQuiz =
            [
                ( "You write "
                    <> c "grep -r --include='src/*.c' TODO ."
                    <> " and get nothing, although "
                    <> c "src/main.c"
                    <> " plainly contains a TODO. The same glob works in "
                    <> c "ls src/*.c"
                    <> ". What is different?"
                , do
                    p_ $ do
                        "When grep is recursing, "
                        opt "--include"
                        " is tested against the "
                        b_ "base name"
                        " — "
                        c "main.c"
                        ", with no directory part at all. A glob containing a "
                        c "/"
                        " therefore can never match anything, and grep does not warn you; it simply selects no files and exits 1."
                    p_ $ do
                        "Confusingly, the rule is different for files named directly on the command line: there the glob is tested against any "
                        em_ "name suffix"
                        ", so "
                        c "grep --include='src/*.c' TODO src/main.c"
                        " does match. If you need directory structure in the filter, that is "
                        c "find"
                        "'s job — "
                        c "find src -name '*.c' -exec grep -Hn TODO {} +"
                        "."
                )
            ,
                ( "Why does "
                    <> c "grep -rl --include='*.c' --exclude='test_*' pat ."
                    <> " behave sensibly, while the same two options in the opposite order return every file in the tree?"
                , do
                    p_ $ do
                        "Two rules interact. The first is that among the options that "
                        em_ "do"
                        " match a given file, the last one on the command line wins. The second is the tiebreak for files that match "
                        em_ "none"
                        " of them: such a file is included unless the "
                        b_ "first"
                        " include/exclude option on the line was an "
                        opt "--include"
                        "."
                    p_ $ do
                        "So with "
                        opt "--include"
                        " first, a "
                        c ".md"
                        " file matches nothing and is therefore excluded — which is the behaviour you wanted. With "
                        opt "--exclude"
                        " first, that same "
                        c ".md"
                        " file matches nothing and is therefore "
                        em_ "included"
                        ". The options are not commutative, and nothing in the output tells you which reading you got."
                )
            ,
                ( "A nightly job runs "
                    <> c "grep -R pattern /var/data"
                    <> " and one morning it has been running for nine hours and the log is enormous. "
                    <> c "grep -r"
                    <> " over the same tree takes a minute."
                , do
                    p_ $ do
                        c "-R"
                        " follows every symbolic link it meets during the descent; "
                        c "-r"
                        " follows only links you named on the command line. Somewhere under "
                        c "/var/data"
                        " there is a link pointing to an ancestor directory — or to "
                        c "/"
                        " — and grep is walking the resulting cycle, re-reading the same files under ever longer paths."
                    p_ $ do
                        "Use "
                        c "-r"
                        " by default and reserve "
                        c "-R"
                        " for trees you control. It is the same reason "
                        c "find"
                        " does not follow links without "
                        c "-L"
                        ": on a general-purpose filesystem, link-following recursion has no guaranteed termination."
                )
            ,
                ( "A script reads "
                    <> c "grep -r pattern \"$dir\""
                    <> ". It normally prints a few lines; occasionally it hangs forever with no output. The directory is fine."
                , do
                    p_ $ do
                        "There is a FIFO in the tree. The default "
                        c "-D"
                        " action is "
                        c "read"
                        ", so grep opens the named pipe and blocks waiting for a writer that may never come. Sockets and some device files behave the same way."
                    p_ $ do
                        "The fix is "
                        c "-D skip"
                        ", and it belongs in any recursive grep that runs unattended over a tree you did not create. It costs nothing when there are no devices to skip."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d7diagram :: Diagram
d7diagram =
    ( diagram
        "A directory contains files and further directories; every file has a base name, and that base name is the only thing an --include or --exclude glob is tested against. Symbolic links are descended into only under -R."
        body'
    )
        { dgCaption = do
            "Two things follow from the arrow into "
            em_ "a base name"
            ". First, a glob containing a "
            c "/"
            " can never match during recursion, because a base name never contains one. Second, grep's file filtering has no idea where in the tree it is — there is no "
            c ".gitignore"
            ", no ignore file of any kind, and "
            c ".git"
            " and "
            c "node_modules"
            " are searched like anything else until you name them."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  dir  [label=\"a directory\"];"
            , "  file [label=\"a file\"];"
            , "  base [label=\"a base name\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  glob [label=\"a glob\\n--include / --exclude\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  srch [label=\"a searched file\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  link [label=\"a symbolic link\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  dir  -> file [label=\"  contains\"];"
            , "  dir  -> dir  [label=\"  contains  \", constraint=false];"
            , "  file -> base [label=\"  has\"];"
            , "  glob -> base [label=\"  is tested against\"];"
            , "  srch -> file [label=\"  is\"];"
            , "  srch -> glob [label=\"  was admitted by the last matching  \", style=dashed, constraint=false];"
            , "  link -> dir  [label=\"  points to\"];"
            , "  link -> dir  [label=\"  is descended into only under -R  \", style=dashed, constraint=false];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "grep searches everything, because nobody told it not to" $ do
        p_ [class_ "lede"] $ do
            c "grep -r"
            " walks the tree and reads every file in it. Every file: the "
            c ".git"
            " object store, "
            c "node_modules"
            ", the build directory, the minified bundle, the vendored copy of a library you have never opened. grep has no ignore file and no concept of a project. Everything on this page exists to narrow that down."
        p_ $ do
            "This is the largest single difference between grep and the modern replacements. "
            c "ripgrep"
            " reads your "
            c ".gitignore"
            " and skips hidden directories by default; grep does neither, and will not start. What it gives you instead is an explicit filter language you control completely — and it is a second pattern language, unrelated to the regular expressions of Days 3 and 4."
        fig
        why $ do
            p_ $ do
                "The filters are globs rather than regular expressions because they are matched against file names, and file-name matching in Unix has always been glob-shaped — the same syntax the shell uses for "
                c "*.c"
                ". Reusing it means "
                c "--include='*.c'"
                " means exactly what it looks like. The cost is that you now have two pattern languages on one command line, where "
                c "*"
                " means “zero or more of the previous thing” in one and “any run of characters” in the other."

    block "The two recursive options" $ do
        defs
            [
                ( c "-r"
                , "Descend into directories, following symbolic links only when you named them on the command line. This is what you want."
                )
            ,
                ( c "-R"
                , do
                    "Descend, following every symbolic link encountered along the way. On a tree containing a link to one of its own ancestors this does not terminate."
                )
            ]
        p_ $ do
            "Both accept no file operand at all, in which case they search the working directory — the one case in grep where a missing operand does not mean standard input. "
            c "-d recurse"
            " is a synonym for "
            c "-r"
            "; "
            c "-d skip"
            " silently ignores directories, which is occasionally useful when a glob has handed grep a mixture of files and directories."
        gotcha $ do
            p_ $ do
                "The default "
                c "-D"
                " action is "
                c "read"
                ", so a recursive grep that meets a FIFO opens it and blocks — possibly forever — waiting for a writer. Any unattended recursive grep over a tree you do not control should carry "
                c "-D skip"
                "."

    block "The glob language, and where it is applied" $ do
        p_ $ do
            "The filters understand "
            c "*"
            ", "
            c "?"
            " and "
            c "[...]"
            ", with "
            c "\\"
            " to quote a wildcard literally. What matters far more than the syntax is "
            em_ "what they are matched against"
            ", and the answer differs between the two cases."
        defs
            [
                ( "When recursing"
                , do
                    "The glob is tested against the file's "
                    b_ "base name"
                    " — the part after the last slash. "
                    c "src/deep/main.c"
                    " is tested as "
                    c "main.c"
                    "."
                )
            ,
                ( "For a file named on the command line"
                , do
                    "The glob is tested against any "
                    b_ "name suffix"
                    ": the whole name, or a trailing part beginning just after a slash. "
                    c "src/main.c"
                    " can be matched by "
                    c "main.c"
                    " or by "
                    c "src/main.c"
                    "."
                )
            ]
        sh
            [ "$ grep -rl --include='src/*.c' needle ."
            , "$ echo $?"
            , "1"
            , "$ grep -l --include='src/*.c' needle src/a.c"
            , "src/a.c"
            ]
        gotcha $ do
            p_ $ do
                "The same glob, the same file, and two different answers. A glob containing a "
                c "/"
                " is silently useless when recursing, because base names do not contain slashes. There is no warning — you get an empty result and exit status 1, which looks exactly like “no matches”. If your filter needs to know about directories, the tool for that is "
                c "find"
                ":"
        sh
            [ "$ find src -name '*.c' -not -path '*/deep/*' -exec grep -Hn TODO {} +"
            ]

    block "Include, exclude, and the order that changes everything" $ do
        p_ "Two rules govern how the filters combine, and neither is guessable:"
        steps
            [ do
                "If more than one "
                opt "--include"
                " or "
                opt "--exclude"
                " matches a file, "
                b_ "the last one on the command line wins"
                "."
            , do
                "If "
                em_ "none"
                " of them matches, the file is included — "
                b_ "unless the first such option on the line was an "
                opt "--include"
                ", in which case it is excluded."
            ]
        sh
            [ "$ grep -rl --include='*.c' --exclude='test_*' needle ."
            , "./.git/g.c"
            , "./vendor/v.c"
            , "./src/a.c"
            , "./src/deep/c.c"
            , "$ grep -rl --exclude='test_*' --include='*.c' needle ."
            , "./README.md"
            , "./node_modules/n.js"
            , "./.git/g.c"
            , "./vendor/v.c"
            , "./src/test_a.c"
            , "./src/b.h"
            , "./src/a.c"
            , "./src/deep/c.c"
            ]
        p_ $ do
            "The second command is the first with two options transposed, and it returns the whole tree. (Note that even the first one reached into "
            c ".git"
            " — the filter was about file names, and nothing told grep that directory was uninteresting.) "
            c "README.md"
            " matches neither filter; because the first filter was an "
            opt "--exclude"
            ", the default is to include, so in it comes. And "
            c "src/test_a.c"
            " matches both, so the last one — "
            opt "--include"
            " — wins and it is kept, which is the opposite of what the author meant."
        tip $ do
            p_ $ do
                "Write "
                opt "--include"
                " options first, always. Then the default is “exclude”, the filter is a whitelist, and the "
                opt "--exclude"
                " options that follow carve exceptions out of it. That is the reading almost everyone intends."

    block "Making it permanent" $ do
        p_ $ do
            "grep has no config file, but "
            opt "--exclude-from"
            " reads a list of globs from a file, which is the closest approximation available. Combined with a shell function it gives you a project-aware grep without leaving grep."
        cfg
            [ "# ~/.grep-exclude - one glob per line, base names only"
            , "*.min.js"
            , "*.map"
            , "*.lock"
            , "*.pyc"
            ]
        sh
            [ "$ g() {"
            , ">   grep -rn --exclude-from=\"$HOME/.grep-exclude\" \\"
            , ">     --exclude-dir=.git --exclude-dir=node_modules \\"
            , ">     --exclude-dir=target --exclude-dir=.venv \"$@\""
            , "> }"
            , "$ g -F -- \"$needle\" src/"
            ]
        note $ do
            p_ $ do
                "Define it as a shell "
                em_ "function"
                " rather than an alias, so that options you pass end up before the pattern rather than after it. And keep "
                c "grep"
                " itself unshadowed — the day you need to know what plain grep does, you do not want to be fighting your own wrapper. Day 1's "
                c "type grep"
                " is the check."

    block "Today's habit" $ do
        p_ $ do
            "Stop typing bare "
            c "grep -r"
            " in a repository. The version with your exclusions is faster, quieter, and does not fill the screen with hits from inside "
            c ".git"
            "."
        cfg
            [ "# ~/grep-recipes.sh"
            , "#"
            , "# Day 7: project grep. --include FIRST so the filter reads as a whitelist."
            , "grep -rn --include='*.py' --exclude='test_*' TODO ."
            , ""
            , "# Day 7: the directories that are never worth reading."
            , "grep -rn --exclude-dir={.git,node_modules,target,.venv,dist} PATTERN ."
            , ""
            , "# Day 7: unattended recursion - -r not -R (cycles), -D skip (FIFOs)."
            , "grep -rn -D skip PATTERN /var/data"
            ]

cheat :: Html ()
cheat =
    cfg
        [ "-r   recurse; follows a symlink only if you NAMED it   (use this one)"
        , "-R   recurse; follows every symlink   (can loop forever on a cyclic tree)"
        , "-D skip   do not open FIFOs/sockets/devices   (default is 'read' = may hang)"
        , "-d skip   ignore directory operands instead of erroring"
        , ""
        , "--include=GLOB  --exclude=GLOB  --exclude-dir=GLOB  --exclude-from=FILE"
        , "#   globs are * ? [...] and \\ to quote.  NOT regular expressions."
        , "#   when RECURSING they match the BASE NAME only - a glob with a / in it"
        , "#   can never match, and you get exit 1 with no warning."
        , "#   for a file named on the command line they match any name SUFFIX."
        , ""
        , "# combining:  last matching option wins; a file matching NONE is included"
        , "#   unless the FIRST such option was --include. So put --include first and"
        , "#   the whole filter reads as a whitelist. Transposing them changes everything."
        , ""
        , "# grep has NO ignore file. .git and node_modules are searched until you say not to."
        ]
