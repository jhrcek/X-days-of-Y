module Course.Day.D19 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 19
        , dayTitle = "Plumbing for scripts"
        , daySubtitle = "The commands and formats that promise not to change — and the ones you should never parse."
        , dayMinutes = 35
        , dayLevel = "advanced"
        , dayManRef = "git(1) OPTIONS, LOW-LEVEL COMMANDS; git-rev-parse(1), git-for-each-ref(1), git-status(1) PORCELAIN FORMAT, gitglossary(7) pathspec"
        , dayTags = ["plumbing", "for-each-ref", "pathspecs"]
        , dayGoals =
            [ "tell a command whose output is safe to script against from one whose output is for humans"
            , "write a shell script that finds its repository, lists refs and reads status without breaking on odd file names"
            , "select paths with pathspec magic — exclusions, globs that respect " <> c "/" <> ", case-insensitive matches"
            ]
        , dayDiagram = Just d19diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git rev-parse --show-toplevel", "Print the root of the working tree. The first line of most scripts.")
            , ("git rev-parse --git-dir", "Print where the repository is — " <> c ".git" <> ", or somewhere else entirely.")
            , ("git rev-parse --is-inside-work-tree", "Print " <> c "true" <> ", or fail with status 128 outside a repository.")
            , ("git for-each-ref --format=… refs/heads/", "Print one formatted line per ref: the scriptable " <> c "git branch" <> ".")
            , ("git status --porcelain=v2 --branch -z", "Machine-readable status, NUL-terminated, with branch and ahead/behind headers.")
            , ("git log --format=…", "Print commits through a template of " <> c "%H" <> ", " <> c "%an" <> ", " <> c "%ad" <> ", " <> c "%s" <> " and friends.")
            , ("git ls-files -z", "List tracked paths raw, NUL-terminated, without C-quoting.")
            , ("git cat-file --batch-check", "Read object names on stdin; print hash, type and size for each. One process for thousands of objects.")
            , ("git var GIT_EDITOR", "Print the editor git would actually launch, after all the fallbacks.")
            ]
        , dayOpts =
            [ ("-C <path>", "Run as if started in " <> c "<path>" <> ". Global option: goes before the subcommand.")
            , ("--no-pager / -P", "Never pipe through the pager, even on a terminal.")
            , (":(exclude)… / :!…", "Pathspec magic: everything except the matching paths.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "From a subdirectory of any repository, run "
                <> c "git rev-parse --show-toplevel --show-prefix"
                <> ". Then run it in "
                <> c "/tmp"
                <> " and read the exit status with "
                <> c "echo $?"
                <> "."
            , "Print your branches newest first, with upstream and ahead/behind, using only "
                <> c "git for-each-ref --sort=-committerdate --format='%(committerdate:short) %(refname:short) %(upstream:track)' refs/heads/"
                <> "."
            , "Create a file called "
                <> c "naïve.txt"
                <> " in a scratch repository, commit it, and compare "
                <> c "git ls-files"
                <> " with "
                <> c "git ls-files -z | tr '\\0' '\\n'"
                <> "."
            , "Break it on purpose: run "
                <> c "git ls-files ':(glob)*.c'"
                <> " in a project with C (or any extension) files in subdirectories. Explain the empty output, \
                   \then fix it with "
                <> c "**/"
                <> "."
            , "In a real project, list everything tracked except one directory: "
                <> c "git ls-files -- ':!vendor'"
                <> " (or your equivalent), and count it with "
                <> c "wc -l"
                <> "."
            , "Run "
                <> c "git status --porcelain=v2 --branch"
                <> " with one staged and one unstaged change, and identify the two columns of "
                <> c "XY"
                <> "."
            , "Copy the "
                <> c "git-gone"
                <> " script below onto your "
                <> c "PATH"
                <> ", run "
                <> c "git fetch --prune"
                <> " in a real repository, then "
                <> c "git gone"
                <> "."
            , "From now on, when you write a script against git, check the command's manual page for a \
              \porcelain or format option before you reach for "
                <> c "awk"
                <> "."
            ]
        , dayQuiz =
            [
                ( "A script parses "
                    <> c "git status"
                    <> " for the word “modified:”. It works for a year, then breaks on a colleague's machine. \
                       \Name two likely causes."
                , do
                    p_ $ do
                        "Human output is translated — a German locale prints “geändert:” — and its layout is \
                        \explicitly allowed to change between versions; the git(1) page says the porcelain \
                        \interface is “subject to change in order to improve the end user experience”. \
                        \Colleagues' config ("
                        c "status.short"
                        ", "
                        c "color.status=always"
                        ") changes it too."
                    p_ $ do
                        "Use "
                        c "git status --porcelain=v2"
                        ": fixed format, untranslated, and unaffected by user config. Confusingly, "
                        em_ "porcelain"
                        " in that flag means “the format porcelain scripts consume”, which is the stable one."
                )
            ,
                ( "Your loop "
                    <> c "for f in $(git ls-files); do …"
                    <> " fails on exactly two files: one with a space and one called "
                    <> c "naïve.txt"
                    <> ". Why is the second one broken even though it has no space?"
                , p_ $ do
                    "Because "
                    c "ls-files"
                    " C-quotes any path with bytes outside printable ASCII, so it prints "
                    c "\"na\\303\\257ve.txt\""
                    " — quotes and octal escapes included — and no such file exists. ("
                    c "core.quotePath"
                    " controls this; it is on by default.) The space breaks word splitting separately. Use "
                    c "git ls-files -z"
                    " and read NUL-terminated records with "
                    c "xargs -0"
                    " or "
                    c "while IFS= read -r -d ''"
                    "."
                )
            ,
                ( c "git ls-files '*.c'"
                    <> " finds "
                    <> c "src/a.c"
                    <> ", but "
                    <> c "git ls-files ':(glob)*.c'"
                    <> " finds nothing. Which one is the odd one out?"
                , p_ $ do
                    "The first. A plain pathspec is matched with "
                    c "fnmatch"
                    " semantics where "
                    c "*"
                    " also matches "
                    c "/"
                    ", so "
                    c "*.c"
                    " means “any .c file anywhere”. The "
                    c "glob"
                    " magic switches to shell-like rules, where "
                    c "*"
                    " stops at a slash; you need "
                    c ":(glob)**/*.c"
                    ". Pick one style per script and say so explicitly, because "
                    c "--glob-pathspecs"
                    " or "
                    c "GIT_GLOB_PATHSPECS"
                    " in the caller's environment would silently change the plain one."
                )
            ,
                ( "A cron job runs "
                    <> c "cd /srv/app && git pull"
                    <> ". One day /srv/app is missing, and the job pulls into your home directory's dotfiles \
                       \repository. How do you make that impossible?"
                , p_ $ do
                    "Do not rely on "
                    c "cd"
                    " plus repository discovery, which walks up from wherever the shell happens to be. Use "
                    c "git -C /srv/app pull"
                    " — which fails if the directory does not exist — and check "
                    c "git -C /srv/app rev-parse --show-toplevel"
                    " equals "
                    c "/srv/app"
                    " before doing anything destructive. "
                    c "set -eu"
                    " in the script catches the failed "
                    c "cd"
                    " as well."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d19diagram :: Diagram
d19diagram =
    ( diagram
        "git's commands divide into porcelain, for humans, and plumbing, for scripts. Porcelain output \
        \may change and is translated; plumbing output and porcelain-format flags are stable. A \
        \script uses plumbing or a stable format flag, addresses the repository with -C, and selects \
        \paths with a pathspec."
        body'
    )
        { dgCaption = do
            "Scripts should depend only on the green boxes. The trap is that the same command can be \
            \on both sides: "
            c "git status"
            " is for humans, "
            c "git status --porcelain=v2"
            " is a contract. The dashed aspect is the one the git(1) page reserves the right to change."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  script  [label=\"a script\", fillcolor=\"#f4efe6\"];\n\
        \  plumb   [label=\"a plumbing command\\n(rev-parse, for-each-ref…)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  fmt     [label=\"a stable format flag\\n(--porcelain=v2, --format, -z)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  porc    [label=\"a porcelain command\\n(status, log, branch)\"];\n\
        \  human   [label=\"human-readable output\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  repo    [label=\"a repository\"];\n\
        \  spec    [label=\"a pathspec\"];\n\
        \\n\
        \  porc   -> fmt    [label=\"  offers\"];\n\
        \  porc   -> human  [label=\"  prints by default\"];\n\
        \  fmt    -> script [style=invis];\n\
        \  script -> fmt    [label=\"  asks for  \", constraint=false];\n\
        \  human  -> script [label=\"  may change under\", style=dashed];\n\
        \  script -> plumb  [label=\"  calls\"];\n\
        \  script -> repo   [label=\"  names with -C\"];\n\
        \  script -> spec   [label=\"  selects paths by\"];\n\
        \\n\
        \  { rank=same; fmt; human; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Two interfaces, two promises" $ do
        p_ [class_ "lede"] $ do
            "git(1) splits its commands into porcelain and plumbing, and attaches a promise to each. The \
            \plumbing interface — input, output, options, semantics — is meant to be “a lot more stable”, \
            \because it exists for scripts. Porcelain is explicitly “subject to change in order to improve \
            \the end user experience”. A script that parses porcelain output is a script with an expiry date."
        p_ $ do
            "In practice the line runs through individual commands, not between them. Most porcelain \
            \commands have a flag that switches them to a stable format: "
            c "git status --porcelain=v2"
            ", "
            c "git log --format="
            ", "
            c "-z"
            " on anything that prints paths. And a handful of plumbing commands do jobs every script needs: "
            c "rev-parse"
            " to find things, "
            c "for-each-ref"
            " to list refs, "
            c "cat-file --batch"
            " to read objects in bulk."
        why $ p_ $ do
            "Human output is allowed to get better: messages are reworded, hints appear, columns change, and \
            \everything is translated through your locale. That freedom is only affordable because scripts \
            \are pointed at a different, frozen interface. Respecting the split is what lets both keep \
            \working."
        fig

    block "Finding the repository" $ do
        p_ $ do
            c "git rev-parse"
            " is the Swiss-army knife: besides turning names into hashes (Day 7) it answers every “where am \
            \I?” question a script has."
        sh
            [ "$ cd src && git rev-parse --show-toplevel"
            , "/home/ada/p19"
            , "$ git rev-parse --git-dir"
            , "/home/ada/p19/.git"
            , "$ git rev-parse --show-prefix"
            , "src/"
            , "$ cd /tmp && git rev-parse --is-inside-work-tree; echo $?"
            , "fatal: not a git repository (or any parent up to mount point /)"
            , "Stopping at filesystem boundary (GIT_DISCOVERY_ACROSS_FILESYSTEM not set)."
            , "128"
            ]
        p_ $ do
            "The global options go "
            b_ "before"
            " the subcommand and apply to everything: "
            c "git -C <path>"
            " runs as if started there, "
            c "git -c key=value"
            " overrides config for one invocation (Day 12), "
            c "git -P"
            " (or "
            c "--no-pager"
            ") never starts "
            c "less"
            ". Scripts should use "
            c "-C"
            " rather than "
            c "cd"
            ", because a failed "
            c "cd"
            " leaves git discovering whatever repository contains the current directory."
        sh
            [ "$ git -C ~/p19 -c core.abbrev=12 log --oneline -1"
            , "174e0280853b Awkward names"
            ]

    block "Stable formats you can parse" $ do
        p_ $ do
            b_ "Refs. "
            c "git for-each-ref"
            " is "
            c "git branch"
            " and "
            c "git tag"
            " with a template language. Each "
            c "%(field)"
            " is documented in git-for-each-ref(1), and "
            c "%(if)…%(then)…%(end)"
            " gives you conditionals:"
        sh
            [ "$ git for-each-ref --sort=-committerdate \\"
            , "    --format='%(committerdate:short) %(refname:short) %(upstream:short) %(upstream:track)' refs/heads/"
            , "2026-09-25 main origin/main"
            , "2026-09-20 feature origin/main [ahead 2]"
            ]
        p_ $ do
            b_ "Status. "
            c "--porcelain=v2"
            " prints headers starting with "
            c "#"
            ", then one line per path: "
            c "1"
            " for an ordinary change, "
            c "2"
            " for a rename, "
            c "u"
            " for unmerged, "
            c "?"
            " for untracked. The "
            c "XY"
            " field is index then worktree, with "
            c "."
            " for unchanged:"
        sh
            [ "$ git status --porcelain=v2 --branch"
            , "# branch.oid 2c700360f7bd33b0317670aa25b27ea514da3218"
            , "# branch.head main"
            , "# branch.upstream origin/main"
            , "# branch.ab +0 -0"
            , "1 .M N... 100644 100644 100644 4bcfe98… 4bcfe98… docs/readme.md"
            , "1 M. N... 100644 100644 100644 7898192… b478595… src/a.c"
            , "? untracked.txt"
            ]
        p_ $ do
            b_ "Commits. "
            c "git log --format"
            " takes placeholders: "
            c "%H"
            "/"
            c "%h"
            " full and short hash, "
            c "%P"
            " parents, "
            c "%an"
            "/"
            c "%ae"
            " author name and email, "
            c "%ad"
            " author date (shaped by "
            c "--date=short"
            ", "
            c "iso-strict"
            " or "
            c "format:%Y-%m-%d"
            "), "
            c "%s"
            " subject, "
            c "%n"
            " newline. "
            b_ "Objects in bulk. "
            c "git cat-file --batch-check"
            " reads names on stdin and prints hash, type and size, one process for any number of objects; "
            c "--batch"
            " adds the contents."
        sh
            [ "$ printf '%s\\n' HEAD HEAD:src HEAD:src/a.c nosuch | git cat-file --batch-check"
            , "174e0280853b79cc646acf541286f6aad3825f2a commit 220"
            , "2e90ee9bdeebf8d96dfdb980f2c2a03f5e795ea4 tree 62"
            , "78981922613b2afb6025042ff6bd878ac1994e85 blob 2"
            , "nosuch missing"
            ]
        gotcha $ p_ $ do
            "Paths with unusual bytes are C-quoted in line-oriented output. "
            c "git ls-files"
            " prints "
            c "naïve.txt"
            " as "
            c "\"na\\303\\257ve.txt\""
            " and a name with a tab as "
            c "\"tab\\there\""
            ". Add "
            c "-z"
            " and you get the raw bytes, NUL-terminated. Any script that handles paths should use "
            c "-z"
            ", and nothing else. ("
            c "for-each-ref"
            ", by contrast, prints ref names raw.)"
        note $ p_ $ do
            c "cat-file"
            "'s format is smaller than "
            c "for-each-ref"
            "'s: "
            c "--batch-check='%(objectname:short)'"
            " fails with "
            c "fatal: bad cat-file format"
            ". Stick to "
            c "%(objectname)"
            ", "
            c "%(objecttype)"
            ", "
            c "%(objectsize)"
            " and "
            c "%(rest)"
            "."

    block "Pathspecs are a language too" $ do
        p_ $ do
            "Every path argument after "
            c "--"
            " is a "
            b_ "pathspec"
            ", and a pathspec can start with "
            c ":(magic)"
            " to change how it matches. These were each run against a tree containing "
            c "src/a.c"
            ", "
            c "src/B.C"
            ", "
            c "docs/readme.md"
            ":"
        defs
            [ (c "'*.c'", "Plain: " <> c "*" <> " matches across " <> c "/" <> ", so this finds " <> c "src/a.c" <> ".")
            , (c "':(glob)*.c'", "Shell-style: " <> c "*" <> " stops at " <> c "/" <> ". Finds nothing at the top level. " <> c "':(glob)**/*.c'" <> " finds " <> c "src/a.c" <> ".")
            , (c "':(icase)src/*.c'", "Case-insensitive: finds both " <> c "src/a.c" <> " and " <> c "src/B.C" <> ".")
            , (c "':(exclude)src'" <> " or " <> c "':!src'", "Everything except " <> c "src" <> ". Combine with positive pathspecs to subtract from them.")
            , (c "--literal-pathspecs", "No magic, no globbing: " <> c "'*.c'" <> " means a file literally named " <> c "*.c" <> ". For paths that came from git itself.")
            ]
        sh
            [ "$ git ls-files -- ':!*.md' src"
            , "src/B.C"
            , "src/a.c"
            ]
        tip $ p_ $ do
            "Quote pathspecs in single quotes so the shell does not expand them first, and keep "
            c "--"
            " before them so a path that looks like a branch name is never mistaken for one."

    block "A script worth keeping" $ do
        p_ $ do
            "After "
            c "git fetch --prune"
            " removes remote branches that were merged and deleted, your local branches that tracked them \
            \are left behind, with an upstream of "
            c "[gone]"
            ". This lists them, using only stable interfaces:"
        cfg
            [ "#!/bin/sh"
            , "# git-gone [repo]: local branches whose upstream no longer exists."
            , "set -eu"
            , "repo=${1:-.}"
            , "if ! git -C \"$repo\" rev-parse --git-dir >/dev/null 2>&1; then"
            , "    echo \"git-gone: not a repository: $repo\" >&2"
            , "    exit 1"
            , "fi"
            , "git -C \"$repo\" for-each-ref \\"
            , "    --format='%(if:equals=[gone])%(upstream:track)%(then)%(refname:short)%(end)' \\"
            , "    refs/heads/ | grep -v '^$' || true"
            ]
        sh
            [ "$ git fetch --prune && git gone"
            , "feature"
            , "fix/naïve"
            , "$ git gone /tmp; echo $?"
            , "git-gone: not a repository: /tmp"
            , "1"
            ]
        p_ $ do
            "Save it as "
            c "git-gone"
            " anywhere on your "
            c "PATH"
            " and it becomes "
            c "git gone"
            ": git runs any "
            c "git-<name>"
            " executable as a subcommand. Day 21 shows that such an executable even wins over an alias of \
            \the same name."
        p_ $ do
            "One more lookup worth knowing: "
            c "git var GIT_EDITOR"
            " prints the editor git would really launch after checking "
            c "GIT_EDITOR"
            ", "
            c "core.editor"
            ", "
            c "VISUAL"
            " and "
            c "EDITOR"
            " in turn — "
            c "vi"
            " when all are unset. A script that opens an editor should ask git rather than guess."

    block "Today's habit" $ do
        p_ $ do
            "Find one shell alias or script of yours that greps human git output and rewrite it against \
            \a format flag or plumbing command. Then add "
            c "-z"
            " wherever it handles paths."
        p_ "Tomorrow: the inside of .git — loose objects, packfiles, and what garbage collection actually collects."

cheat :: Html ()
cheat =
    cfg
        [ "git rev-parse --show-toplevel | --git-dir | --show-prefix"
        , "git rev-parse --is-inside-work-tree      # exit 128 outside"
        , "git -C DIR -c k=v -P <cmd>               # global options go first"
        , "git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads/"
        , "git status --porcelain=v2 --branch -z    # stable, NUL-separated"
        , "git log --format='%h %an %ad %s' --date=short"
        , "git ls-files -z                          # raw paths, never quoted"
        , "... | git cat-file --batch-check         # hash type size, in bulk"
        , "':!dir'  ':(glob)**/*.c'  ':(icase)x'    # pathspec magic"
        , "git var GIT_EDITOR                       # the editor git will use"
        ]
