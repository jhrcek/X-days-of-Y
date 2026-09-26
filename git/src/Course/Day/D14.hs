module Course.Day.D14 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 14
        , dayTitle = "Ignore and attributes"
        , daySubtitle = "Per-path rules: which untracked files git should not offer you, and how to treat the files it keeps."
        , dayMinutes = 35
        , dayLevel = "intermediate"
        , dayManRef = "gitignore(5), gitattributes(5), git-check-ignore(1), git-check-attr(1)"
        , dayTags = [".gitignore", ".gitattributes", "line endings"]
        , dayGoals =
            [ "write ignore patterns that do what you meant, and prove it with " <> c "git check-ignore -v"
            , "explain why ignoring a file that is already tracked does nothing"
            , "fix line endings for good with " <> c ".gitattributes" <> ", and get readable diffs of files git thinks are binary"
            ]
        , dayDiagram = Just d14diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git check-ignore -v <path>", "Print the file, line and pattern that decides whether " <> var "path" <> " is ignored.")
            , ("git check-ignore -v --no-index <path>", "The same for a path that is already tracked.")
            , ("git status --ignored", "Also list ignored files, marked " <> c "!!" <> ".")
            , ("git ls-files -o -i --exclude-standard", "List every untracked file the ignore rules are hiding.")
            , ("git add -f <path>", "Add a file despite an ignore rule.")
            , ("git check-attr -a -- <path>", "Print every attribute set on a path.")
            , ("git ls-files --eol", "Show line endings in the index and working tree, and the attribute in force.")
            , ("git add --renormalize .", "Re-apply the current text/eol attributes to every tracked file in the index.")
            , ("git archive HEAD", "Write a tarball of a commit, leaving out " <> c "export-ignore" <> " paths.")
            ]
        , dayOpts =
            [ ("core.excludesFile", "Your personal ignore file. Defaults to " <> c "~/.config/git/ignore" <> " — usually leave it.")
            , ("diff.<driver>.textconv", "A program that turns a file into text for diffs, used by paths with " <> c "diff=" <> var "driver" <> ".")
            ]
        , dayConfig = []
        , dayDrills =
            [ "In a repository you work in, run "
                <> c "git status --ignored"
                <> ". Pick one "
                <> c "!!"
                <> " line and ask git why: "
                <> c "git check-ignore -v <that path>"
                <> "."
            , "Run "
                <> c "git ls-files -o -i --exclude-standard | head"
                <> " and make sure nothing in the list is a file you would be upset to lose. A "
                <> c "git clean -dX"
                <> " would delete all of it."
            , "Put your editor's and OS's clutter ("
                <> c ".DS_Store"
                <> ", "
                <> c "*.swp"
                <> ", "
                <> c ".idea/"
                <> ") in "
                <> c "~/.config/git/ignore"
                <> " and take it out of project "
                <> c ".gitignore"
                <> " files you own."
            , "Break it on purpose: in a scratch repository commit a file, add its name to "
                <> c ".gitignore"
                <> ", edit it, and run "
                <> c "git status"
                <> ". It still shows as modified. Then run "
                <> c "git check-ignore -v"
                <> " on it with and without "
                <> c "--no-index"
                <> "."
            , "Write "
                <> c "logs/"
                <> " followed by "
                <> c "!logs/keep.log"
                <> " in a scratch "
                <> c ".gitignore"
                <> " and check whether "
                <> c "keep.log"
                <> " shows up. Change the first line to "
                <> c "logs/*"
                <> " and check again."
            , "Run "
                <> c "git ls-files --eol | grep crlf"
                <> " in a real project. If anything turns up that should not, that is next week's "
                <> c ".gitattributes"
                <> " change."
            , "Pick a compressed or binary format your project keeps in git (a "
                <> c ".gz"
                <> ", a "
                <> c ".pdf"
                <> ", a SQLite file) and give it a "
                <> c "textconv"
                <> " driver. Look at "
                <> c "git log -p"
                <> " for it before and after."
            , "From now on, any repository you start gets a "
                <> c ".gitattributes"
                <> " in its first commit, with "
                <> c "* text=auto"
                <> " and explicit rules for scripts."
            ]
        , dayQuiz =
            [
                ( "You add "
                    <> c ".env"
                    <> " to "
                    <> c ".gitignore"
                    <> ", but "
                    <> c "git status"
                    <> " still reports it modified and "
                    <> c "git check-ignore .env"
                    <> " prints nothing. Is the pattern wrong?"
                , do
                    p_ $ do
                        "No. Ignore rules apply only to "
                        em_ "untracked"
                        " files; they decide what git offers to add, and "
                        c ".env"
                        " is already in the index. "
                        c "check-ignore"
                        " reflects that and stays silent for tracked paths unless you pass "
                        c "--no-index"
                        ", which shows the rule would match."
                    p_ $ do
                        "Stop tracking it with "
                        c "git rm --cached .env"
                        " (Day 2) and commit. The file stays on disk and is now ignored. It is still in every \
                        \earlier commit, so if it held a secret, rotate the secret."
                )
            ,
                ( "Your "
                    <> c ".gitignore"
                    <> " has "
                    <> c "build/"
                    <> " then "
                    <> c "!build/README"
                    <> ", and the README never appears in "
                    <> c "git status"
                    <> ". Why?"
                , p_ $ do
                    "Because gitignore(5) forbids re-including a file whose parent directory is excluded: once "
                    c "build/"
                    " matches, git does not look inside the directory at all, so there is nothing for the "
                    c "!"
                    " line to rescue. Ignore the contents instead of the directory — "
                    c "build/*"
                    " — and the negation works, because now the directory is visited and only its entries are \
                    \ignored."
                )
            ,
                ( "You set "
                    <> c "!secret.local"
                    <> " in "
                    <> c ".git/info/exclude"
                    <> " to override the project's "
                    <> c "*.local"
                    <> " rule. It has no effect. Why?"
                , p_ $ do
                    "Precedence. Within one level the last matching line wins, but between sources the order is \
                    \fixed: patterns in "
                    c ".gitignore"
                    " files beat "
                    c ".git/info/exclude"
                    ", which beats "
                    c "core.excludesFile"
                    ". A personal file can add ignores but cannot un-ignore something the project ignores. "
                    c "git add -f"
                    " is the escape hatch; once the file is tracked, the rule no longer applies to it."
                )
            ,
                ( "You add "
                    <> c "*.sh text eol=lf"
                    <> " and run "
                    <> c "git add --renormalize ."
                    <> ". "
                    <> c "git ls-files --eol"
                    <> " still says "
                    <> c "w/crlf"
                    <> " for your scripts. Did it fail?"
                , p_ $ do
                    "Half of it did exactly what it says. "
                    c "--renormalize"
                    " rewrites the "
                    b_ "index"
                    " (the "
                    c "i/"
                    " column now says "
                    c "lf"
                    "), which is what the next commit records. The working-tree files are only rewritten when git \
                    \next checks them out — delete them and "
                    c "git checkout -- ."
                    ", or wait for your next branch switch. Commit the renormalisation on its own, so the \
                    \“every line changed” diff is not mixed up with real work."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d14diagram :: Diagram
d14diagram =
    ( diagram
        "A path has attributes, which come from a .gitattributes file; an untracked path may be ignored by a \
        \pattern; a pattern comes from an ignore source; ignore sources are ranked, .gitignore above \
        \info/exclude above core.excludesFile; a tracked path is never ignored; a diff attribute names a \
        \driver whose textconv command turns the file into text."
        body'
    )
        { dgCaption = do
            "Both files are lists of patterns attached to "
            b_ "paths"
            ", but they answer different questions. Ignore rules are consulted only for untracked paths and \
            \only decide what git offers to add — hence the amber box: once a path is tracked, nothing in \
            \any ignore file touches it. Attributes apply to every path, tracked or not, and change how git \
            \reads, writes, diffs and merges its contents."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  path   [label=\"a path\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  untr   [label=\"an untracked path\"];\n\
        \  trk    [label=\"a tracked path\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  pat    [label=\"an ignore pattern\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  src    [label=\"an ignore source\\n(.gitignore > info/exclude\\n> core.excludesFile)\"];\n\
        \  attr   [label=\"an attribute\\n(text, eol, diff, merge, ...)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  gafile [label=\"a .gitattributes line\"];\n\
        \  drv    [label=\"a diff driver\"];\n\
        \  prog   [label=\"a textconv program\", fillcolor=\"#f4efe6\"];\n\
        \\n\
        \  untr -> path   [label=\"  is\"];\n\
        \  trk  -> path   [label=\"  is\"];\n\
        \  untr -> pat    [label=\"  may be ignored by\"];\n\
        \  pat  -> src    [label=\"  comes from\"];\n\
        \  path -> attr   [label=\"  has\"];\n\
        \  attr -> gafile [label=\"  is set by\"];\n\
        \  attr -> drv    [label=\"  may name\", style=dashed];\n\
        \  drv  -> prog   [label=\"  runs\"];\n\
        \\n\
        \  { rank=same; untr; trk; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Ignoring is about untracked files, and only those" $ do
        p_ [class_ "lede"] $ do
            "An ignore rule does not hide a file from git. It stops git from "
            em_ "offering"
            " an untracked file to you — in "
            c "git status"
            ", in "
            c "git add ."
            ", in "
            c "git clean"
            " without "
            c "-x"
            ". A file that is already tracked is past that point, and no pattern anywhere will make git stop \
            \noticing changes to it."
        sh
            [ "$ git add .env && git commit -m 'Oops'"
            , "$ echo .env > .gitignore && echo 'secret=2' > .env"
            , "$ git status -s"
            , " M .env"
            , "?? .gitignore"
            , "$ git check-ignore -v .env; echo $?"
            , "1"
            , "$ git check-ignore -v --no-index .env"
            , ".gitignore:1:.env\t.env"
            ]
        p_ $ do
            "The fix is to stop tracking the file: "
            c "git rm --cached .env"
            " (Day 2) and commit. It stays on disk; now the rule applies. Every earlier commit still has it — \
            \Day 1's gotcha about snapshots — so a leaked secret is rotated, not ignored."
        why $ p_ $ do
            "If ignore rules applied to tracked files, adding a broad pattern like "
            c "*.json"
            " would silently stop git recording changes to files the project depends on. Keeping the rules \
            \to “what to offer” means an ignore file can never lose data; the worst it can do is keep a new \
            \file out of a commit."
        fig

    block "Patterns, and the rule nobody expects" $ do
        p_ "gitignore(5) patterns are globs with a few extra rules, and each one matters:"
        defs
            [ (c "*.log", "No slash: matches a name at any depth — " <> c "app.log" <> ", " <> c "logs/app.log" <> ".")
            , (c "/build/", "A leading slash anchors the pattern to the directory holding the " <> c ".gitignore" <> "; a trailing slash matches only directories. So " <> c "src/build/" <> " is not ignored.")
            , (c "docs/**/*.html", "A slash in the middle also anchors. " <> c "**" <> " matches any number of directories.")
            , (c "!keep.log", "Negation: re-include something an earlier line in the same file excluded. Last matching line wins.")
            ]
        sh
            [ "$ git check-ignore -v build/a.o src/build/b.o logs/app.log logs/keep.log"
            , ".gitignore:1:/build/\tbuild/a.o"
            , ".gitignore:2:*.log\tlogs/app.log"
            , ".gitignore:3:!keep.log\tlogs/keep.log"
            ]
        p_ $ do
            c "src/build/b.o"
            " printed nothing: no rule matched, so it is not ignored. "
            c "keep.log"
            " printed its negation line, which means the deciding rule "
            em_ "re-included"
            " it. "
            c "check-ignore -v"
            " always tells you the one line that decided, which makes debugging a twenty-line "
            c ".gitignore"
            " a matter of seconds."
        gotcha $ p_ $ do
            b_ "You cannot re-include a file if its parent directory is excluded."
            " With "
            c "logs/"
            " followed by "
            c "!logs/keep.log"
            ", git never descends into "
            c "logs"
            ", so the negation never runs. Write "
            c "logs/*"
            " instead — ignore the contents, not the directory — and the negation works."

    block "Three places to put a rule" $ do
        p_ "The sources, from strongest to weakest:"
        steps
            [ do
                c ".gitignore"
                " files in the tree, committed and shared. A deeper file's rules are relative to its own \
                \directory and override the ones above it. This is for things "
                em_ "the project"
                " produces: build output, dependency directories, generated code."
            , do
                c ".git/info/exclude"
                ": the same syntax, never committed, this clone only. For a scratch file you keep in one \
                \repository."
            , do
                "The file named by "
                c "core.excludesFile"
                ", which defaults to "
                c "~/.config/git/ignore"
                " — you do not need to set it; create the file. For things "
                em_ "you"
                " produce everywhere: editor swap files, "
                c ".DS_Store"
                ", your IDE's directory."
            ]
        p_ $ do
            "The ranking is between sources, not lines: a "
            c "!"
            " in "
            c "info/exclude"
            " cannot un-ignore what a "
            c ".gitignore"
            " ignores."
        sh
            [ "$ git check-ignore -v TODO src/build/b.o"
            , "/home/ada/.config/git/ignore:1:TODO\tTODO"
            , ".gitignore:1:*.o\tsrc/build/b.o"
            ]
        tip $ p_ $ do
            "Keep editor and OS clutter out of project "
            c ".gitignore"
            " files. They belong in your global ignore file, and a project file full of other people's \
            \editors is a sign the global one is missing. "
            c "git ls-files -o -i --exclude-standard"
            " lists everything the rules currently hide — worth reading before a "
            c "git clean -dX"
            "."

    block "Attributes: how to treat the files you keep" $ do
        p_ $ do
            c ".gitattributes"
            " uses the same kind of path patterns, but each line assigns attributes, and they apply to \
            \tracked files — that is their whole purpose. Commit it; everyone who clones gets the same \
            \behaviour, which is the point. The ones worth knowing:"
        cfg
            [ "* text=auto              # let git detect text; store it with LF"
            , "*.sh text eol=lf         # always LF on disk: bash chokes on CR"
            , "*.bat text eol=crlf      # always CRLF on disk: cmd.exe wants it"
            , "*.png binary             # = -diff -merge -text: no conversion, no text diff"
            , "*.gz diff=gzip           # use the 'gzip' diff driver below"
            , "tests/ export-ignore     # leave out of git archive tarballs"
            ]
        p_ $ do
            c "text"
            " means “this is text: normalise line endings to LF in the repository”. "
            c "eol"
            " decides what the working-tree copy gets. Adding these rules to an existing project does not \
            \change what is already committed; "
            c "git add --renormalize ."
            " re-applies them to the index, and "
            c "git ls-files --eol"
            " shows the result:"
        sh
            [ "$ git add --renormalize . && git ls-files --eol"
            , "i/lf    w/lf    attr/text=auto          .gitattributes"
            , "i/lf    w/crlf  attr/text eol=crlf      notes.bat"
            , "i/lf    w/crlf  attr/text eol=lf        run.sh"
            ]
        p_ $ do
            c "run.sh"
            " is LF in the index but still CRLF on disk: renormalising rewrites the index, not your files. They \
            \are converted the next time git checks them out."
        gotcha $ p_ $ do
            c "git check-attr diff text users.csv.gz"
            " treats "
            c "text"
            " as a path, because the first argument is an attribute and everything after it is a path. Put "
            c "--"
            " before the paths, or use "
            c "-a"
            " to see everything: "
            c "git check-attr -a -- users.csv.gz"
            "."

    block "Readable diffs of unreadable files" $ do
        p_ $ do
            "A diff driver is a name in "
            c ".gitattributes"
            " plus a config entry saying what to do with it. The most useful setting is "
            c "textconv"
            ": a command that receives the file's path and prints text, which git then diffs normally."
        sh
            [ "$ git diff users.csv.gz"
            , "Binary files a/users.csv.gz and b/users.csv.gz differ"
            , "$ echo '*.gz diff=gzip' >> .gitattributes"
            , "$ git config set diff.gzip.textconv zcat"
            , "$ git diff users.csv.gz"
            , "@@ -1,2 +1,3 @@"
            , " id,name"
            , " 1,ada"
            , "+2,grace"
            ]
        p_ $ do
            "The attribute is committed; the command is not, because it is a program on your machine. \
            \Colleagues without the config see the old “Binary files differ”, which is a safe fallback. The \
            \same trick works for PDFs (a two-line wrapper script running "
            c "pdftotext \"$1\" -"
            ", since git appends the path last), SQLite files ("
            c "echo .dump | sqlite3"
            "), office documents — anything with a to-text converter."
        gotcha $ p_ $ do
            "The "
            c "merge=ours"
            " attribute — “always keep our version of this file” — is weaker than it sounds. Its driver runs \
            \only when both sides changed the file. If only the other branch changed it, or the merge is a \
            \fast-forward, their version comes in untouched. It is not a way to protect per-branch config."

    block "Today's habit" $ do
        p_ $ do
            "Move your personal clutter into "
            c "~/.config/git/ignore"
            ", and give the next repository you create a "
            c ".gitattributes"
            " in its first commit. Both are one-time changes that stop a whole class of noisy diffs and \
            \accidental commits."
        p_ $ do
            "Tomorrow the advanced third begins: moving individual commits between branches with cherry-pick, \
            \and naming releases with tags."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Ignore: untracked files only. Attributes: every path."
        " Both: last matching line wins."
    cfg
        [ "*.log   /build/   docs/**/*.html   !keep.log   # any depth / anchored dir / ** / negate"
        , "logs/*  then  !logs/keep.log                   # NOT logs/ - can't re-include in excluded dir"
        , ".gitignore > .git/info/exclude > ~/.config/git/ignore"
        , "git check-ignore -v PATH [--no-index]          # which line decided"
        , "git ls-files -o -i --exclude-standard          # what is being hidden"
        , "* text=auto  |  *.sh text eol=lf  |  *.png binary"
        , "git add --renormalize . ; git ls-files --eol   # apply eol rules to the index"
        , "*.gz diff=gzip   +   git config set diff.gzip.textconv zcat"
        , "git check-attr -a -- PATH                      # -- before paths"
        ]
