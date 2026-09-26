module Course.Day.D21 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 21
        , dayTitle = "Sharp edges and what next"
        , daySubtitle = "Tracing what git really does, the repositories you should not trust, and where to read after this."
        , dayMinutes = 35
        , dayLevel = "advanced"
        , dayManRef = "git(1) ENVIRONMENT VARIABLES, SECURITY, FURTHER DOCUMENTATION; safe.directory, transfer.fsckObjects, help.autoCorrect"
        , dayTags = ["tracing", "security", "further reading"]
        , dayGoals =
            [ "switch on git's own tracing to see which command, config and repository it actually used"
            , "explain “dubious ownership”, and handle a repository you did not create without running its code"
            , "find the answer to your next git question in the documentation that is already on your machine"
            ]
        , dayDiagram = Just d21diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git clone --no-local <path>", "Clone a local path through the normal transport, so objects are checked, not hard-linked.")
            , ("git help -g", "List the concept guides: tutorial, everyday, glossary, workflows, faq…")
            , ("git help -a", "List every command git knows, including " <> c "git-*" <> " executables on your " <> c "PATH" <> ".")
            , ("git help <command>", "Open that command's manual page. Same as " <> c "git <command> --help" <> ".")
            ]
        , dayOpts =
            [ ("GIT_TRACE=1", "Print alias expansion, built-in and external command execution to stderr.")
            , ("GIT_TRACE_SETUP=1", "Print which " <> c ".git" <> ", worktree, cwd and prefix git settled on.")
            , ("GIT_TRACE2_PERF=1", "Print timed regions — where the milliseconds went.")
            , ("GIT_TRACE_CURL=1", "Dump HTTP traffic. Authorization headers and cookies are redacted unless " <> c "GIT_TRACE_REDACT=0" <> ".")
            , ("GIT_TERMINAL_PROMPT=0", "Never prompt for credentials on the terminal; fail instead. For scripts and cron.")
            , ("safe.directory", "Directories you trust although someone else owns them. Honoured only in protected (global, system, command-line) config.")
            , ("transfer.fsckObjects", "Check every object received by fetch or push, and abort on malformed or suspicious ones.")
            , ("help.autoCorrect", "What to do with a mistyped command: show a suggestion (default), " <> c "prompt" <> ", run it, or " <> c "never" <> ".")
            ]
        , dayConfig =
            [ ConfBlock
                "Check objects as they arrive. Off by default; it catches corrupt or deliberately\n\
                \malformed objects (bad idents, hostile .gitmodules, .GIT directories) before they\n\
                \land in my repository, at the cost of some CPU on large fetches."
                "[transfer]\n\
                \\tfsckObjects = true"
            , ConfBlock
                "When I mistype a command and git finds exactly one likely match, ask before running\n\
                \it. Never runs anything without a y; off a terminal it prints only the error."
                "[help]\n\
                \\tautocorrect = prompt"
            ]
        , dayDrills =
            [ "Run "
                <> c "GIT_TRACE=1 git status"
                <> " and read the first lines. Then do it with one of your aliases and find the "
                <> c "alias expansion"
                <> " line."
            , "From a subdirectory, run "
                <> c "GIT_TRACE_SETUP=1 git status -s"
                <> " and read which "
                <> c "git_dir"
                <> ", "
                <> c "worktree"
                <> " and "
                <> c "prefix"
                <> " git chose."
            , "Run "
                <> c "GIT_TRACE2_PERF=1 git status 2>&1 | grep region_leave"
                <> " in your largest repository. Find the slowest region."
            , "Break it on purpose: add today's "
                <> c "[help]"
                <> " block and type "
                <> c "git stauts"
                <> ". Answer "
                <> c "n"
                <> " and read the exit status; then try it again with "
                <> c "</dev/null"
                <> " and compare."
            , "Add the "
                <> c "[transfer]"
                <> " block and run "
                <> c "git fetch"
                <> " in a repository you work in. Nothing should change — that is the point. Note how long it took."
            , "In a script or cron job of yours that fetches or pushes, set "
                <> c "GIT_TERMINAL_PROMPT=0"
                <> " so that an expired credential fails loudly instead of hanging."
            , "Run "
                <> c "git help -g"
                <> " and open "
                <> c "git help glossary"
                <> ". Read the entries for "
                <> em_ "reachable"
                <> ", "
                <> em_ "unborn"
                <> " and "
                <> em_ "pathspec"
                <> " — all three should now read as things you already know."
            , "Read your finished "
                <> c "~/.gitconfig"
                <> " end to end. Every line should be one you can explain; delete any that you cannot."
            ]
        , dayQuiz =
            [
                ( "A colleague sends you a tarball of a repository to debug. You unpack it and run "
                    <> c "git log"
                    <> ". Why is that a risk even though the files are now owned by you?"
                , do
                    p_ $ do
                        "Because the "
                        c ".git"
                        " directory came from them, including "
                        c ".git/config"
                        " and "
                        c ".git/hooks"
                        ". Settings such as "
                        c "core.fsmonitor"
                        ", "
                        c "core.pager"
                        " or a diff driver's "
                        c "textconv"
                        " are commands, and git runs them “in the usual way”. The git(1) SECURITY section is \
                        \explicit: it is not safe to run git inside a "
                        c ".git"
                        " from an untrusted source. The ownership check does not help, because unpacking made \
                        \you the owner."
                    p_ $ do
                        "Clone it first: "
                        c "git clone --no-local ./unpacked clean"
                        ". The clone gets objects and refs, not config or hooks, and "
                        c "--no-local"
                        " sends them through the transport, where "
                        opt "transfer.fsckObjects"
                        " can check them."
                )
            ,
                ( "You set "
                    <> c "transfer.fsckObjects"
                    <> ", then "
                    <> c "git clone ../suspect"
                    <> " a repository containing a malformed commit. The clone succeeds. Why did the check not \
                       \fire?"
                , p_ $ do
                    "Because a clone from a local path does not transfer objects at all: it hard-links or copies "
                    c ".git/objects"
                    " directly, so nothing passes through the receiving side's checks. Verified in 2.52: the \
                    \plain local clone succeeded; the same clone with "
                    c "--no-local"
                    " or a "
                    c "file://"
                    " URL failed with "
                    c "badEmail: invalid author/committer line"
                    ". For anything you do not trust, use "
                    c "--no-local"
                    "."
                )
            ,
                ( "On a shared build machine, "
                    <> c "git status"
                    <> " in "
                    <> c "/srv/build/app"
                    <> " fails with “detected dubious ownership”. Someone suggests "
                    <> c "git config --global --add safe.directory '*'"
                    <> ". What does that give away?"
                , do
                    p_ $ do
                        "The check exists because running git in a repository means obeying its config and \
                        \hooks. On a multi-user machine, any user who can create a directory — "
                        c "/tmp/x/.git"
                        ", say — above or inside a path you work in could otherwise make your git run their \
                        \code. "
                        c "'*'"
                        " switches the protection off for every repository, forever."
                    p_ $ do
                        "Trust the one directory you mean: "
                        c "safe.directory = /srv/build/app"
                        ", or "
                        c "/srv/build/*"
                        " for everything under it. It is only honoured in global, system or command-line config, \
                        \so a repository cannot declare itself safe."
                )
            ,
                ( c "git last"
                    <> " is your alias for "
                    <> c "log -1 --oneline"
                    <> ". One day it prints something completely different. "
                    <> c "GIT_TRACE=1"
                    <> " shows "
                    <> c "trace: exec: git-last"
                    <> ". What happened?"
                , p_ $ do
                    "Something installed an executable called "
                    c "git-last"
                    " on your "
                    c "PATH"
                    ", and git looks for external "
                    c "git-<name>"
                    " commands before expanding aliases — the trace shows the "
                    c "exec: git-last"
                    " attempt first, and when it succeeds the alias is never consulted. Verified: with both \
                    \present, the external command ran. Built-in commands, by contrast, always win over both, \
                    \which is why you cannot alias "
                    c "status"
                    " to something else."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d21diagram :: Diagram
d21diagram =
    ( diagram
        "An untrusted .git directory contains config and hooks, which can run commands. A clone \
        \copies objects and refs but not config or hooks. The ownership check refuses repositories \
        \owned by another user unless safe.directory lists them, and safe.directory is read only from \
        \protected configuration. transfer.fsckObjects checks objects received over a transport."
        body'
    )
        { dgCaption = do
            "The line that matters is the one "
            b_ "a clone"
            " draws: objects and refs cross it, config and hooks do not. Everything that can execute lives \
            \on the wrong side of that line in someone else's repository, which is why reading a clone is \
            \safe and running git inside their "
            c ".git"
            " is not."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  alien  [label=\"an untrusted .git directory\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  cfg    [label=\"its config and hooks\"];\n\
        \  cmds   [label=\"a shell command\", fillcolor=\"#f4efe6\"];\n\
        \  objs   [label=\"its objects and refs\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  clone  [label=\"a clean clone\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  check  [label=\"the ownership check\"];\n\
        \  safe   [label=\"safe.directory\\n(protected config only)\"];\n\
        \  fsck   [label=\"transfer.fsckObjects\"];\n\
        \\n\
        \  alien -> cfg   [label=\"  contains\"];\n\
        \  alien -> objs  [label=\"  contains\"];\n\
        \  cfg   -> cmds  [label=\"  can run\"];\n\
        \  clone -> objs  [label=\"  receives\"];\n\
        \  clone -> cfg   [label=\"  never receives\", style=dashed];\n\
        \  fsck  -> objs  [label=\"  checks, when transferred,\"];\n\
        \  check -> alien [label=\"  refuses, if another user owns,\"];\n\
        \  safe  -> check [label=\"  makes exceptions to\"];\n\
        \\n\
        \  { rank=same; check; safe; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Ask git what it did" $ do
        p_ [class_ "lede"] $ do
            "When git does something you cannot explain — the wrong repository, the wrong config, a command \
            \that is not what you typed — stop guessing and turn on its tracing. The ENVIRONMENT VARIABLES \
            \section of git(1) lists over a dozen "
            c "GIT_TRACE*"
            " variables. Four of them cover almost every question you will have."
        sh
            [ "$ GIT_TRACE=1 git last"
            , "git.c:808               trace: exec: git-last"
            , "run-command.c:673       trace: run_command: git-last"
            , "git.c:447               trace: alias expansion: last => log -1 --oneline"
            , "git.c:502               trace: built-in: git log -1 --oneline"
            , "174e028 Awkward names"
            ]
        p_ $ do
            "Read that from the top: git first tried to run an external command called "
            c "git-last"
            ", found none, expanded the alias, and ran the built-in "
            c "log"
            ". "
            c "GIT_TRACE_SETUP"
            " answers “which repository is this?”:"
        sh
            [ "$ cd src && GIT_TRACE_SETUP=1 git status -s"
            , "trace.c:316             setup: git_dir: .git"
            , "trace.c:317             setup: git_common_dir: .git"
            , "trace.c:318             setup: worktree: /home/ada/p19"
            , "trace.c:319             setup: cwd: /home/ada/p19"
            , "trace.c:320             setup: prefix: src/"
            ]
        defs
            [ (c "GIT_TRACE=1", "Commands, aliases, child processes.")
            , (c "GIT_TRACE_SETUP=1", "The repository, worktree and prefix git settled on.")
            , (c "GIT_TRACE2_PERF=1", "A timed table of regions: index reading, status, diff, pack access.")
            , (c "GIT_TRACE_CURL=1", "Full HTTP exchanges for https remotes.")
            ]
        p_ $ do
            "Each accepts "
            c "1"
            " or "
            c "true"
            " for stderr, a number from 3 to 9 for that file descriptor, or an absolute path to append to."
        gotcha $ p_ $ do
            "Tracing output goes into bug reports and chat channels. Git redacts cookies, "
            c "Authorization:"
            " headers and packfile URIs by default; "
            c "GIT_TRACE_REDACT=0"
            " turns that off. Leave it on unless you are sure where the log is going."
        tip $ p_ $ do
            "Two variables every script should consider. "
            c "GIT_TERMINAL_PROMPT=0"
            " makes git fail instead of waiting for a password nobody will type. "
            c "GIT_PAGER=cat"
            " (or "
            c "git -P"
            ") guarantees output is never swallowed by "
            c "less"
            "."

    block "A repository is code, not just data" $ do
        p_ $ do
            "The git(1) SECURITY section is short and worth reading word for word. Its argument: \
            \configuration options and hooks can run arbitrary shell commands. Because they are not copied by "
            c "git clone"
            ", cloning an untrusted repository and inspecting it with "
            c "git log"
            " is generally safe. But it is not safe to run git inside a "
            c ".git"
            " directory that itself came from an untrusted source — a tarball, a USB stick, a shared \
            \directory — because its config and hooks run in the usual way."
        fig
        p_ $ do
            "Since the April 2022 fix for CVE-2022-24765 (2.35.2, and back-ported to 2.30.3 onwards), git \
            \defends one common case automatically: it refuses to work in a repository owned by another \
            \user. The release notes give the scenario — a shell prompt that runs "
            c "git status"
            " on every "
            c "cd"
            ", and another user's "
            c ".git"
            " in a scratch space above you, would run that user's commands. Reproduced here in a user \
            \namespace, with the repository "
            c "chown"
            "ed to another uid:"
        sh
            [ "$ git status"
            , "fatal: detected dubious ownership in repository at '/srv/shared/own21'"
            , "To add an exception for this directory, call:"
            , ""
            , "\tgit config --global --add safe.directory /srv/shared/own21"
            ]
        p_ $ do
            opt "safe.directory"
            " takes a path, a path ending in "
            c "/*"
            " for everything below it, or "
            c "*"
            " for everything. It is read only from "
            b_ "protected"
            " configuration — system, global, or "
            c "-c"
            " on the command line — so a repository cannot vouch for itself in its own "
            c ".git/config"
            ". "
            c "git -c safe.directory=$PWD status"
            " is the one-off form."
        gotcha $ p_ $ do
            "The ownership check only helps when ownership differs. Unpack someone's tarball and "
            b_ "you"
            " own their "
            c ".git"
            " — config, hooks and all. For such a directory, do what the manual page recommends: "
            c "git clone --no-local ./theirs ./clean"
            ", and work in the clone."

    block "Check what arrives" $ do
        p_ $ do
            opt "transfer.fsckObjects"
            " makes fetch and receive run fsck on every incoming object and abort on anything malformed or \
            \suspicious — bad author lines, links to missing objects, a "
            c ".GIT"
            " directory, a hostile "
            c ".gitmodules"
            ". It defaults to false. A commit with a broken email, fetched with the setting on:"
        sh
            [ "$ git clone --no-local ../bad21 dst"
            , "error: object 7277f63126af6fe310fea35c1d24307ad7908590: badEmail: invalid author/committer line - bad email"
            , "fatal: fsck error in packed object"
            , "fatal: fetch-pack: invalid index-pack output"
            ]
        gotcha $ p_ $ do
            "Without "
            c "--no-local"
            ", the same clone "
            b_ "succeeded"
            ". A clone from a plain local path copies or hard-links the object directory and never passes \
            \objects through the checks. This is not stated next to the setting in git-config(1); it was \
            \found by trying it. For local sources you do not trust, "
            c "--no-local"
            " (or a "
            c "file://"
            " URL) is what makes the check apply."

    block "Smaller edges" $ do
        defs
            [
                ( "typos"
                , do
                    "By default "
                    c "git stauts"
                    " prints “The most similar command is status” and exits 1. With "
                    opt "help.autoCorrect"
                    " set to "
                    c "prompt"
                    ", git asks "
                    c "Run 'status' instead [y/N]?"
                    " — and when it is not running on a terminal it prints only the error, "
                    b_ "without"
                    " the suggestion. The values "
                    c "1"
                    " and "
                    c "true"
                    " mean “run immediately” in 2.52, not a delay."
                )
            ,
                ( "case"
                , do
                    "On a case-insensitive filesystem (macOS, Windows) "
                    c "git init"
                    " sets "
                    c "core.ignoreCase = true"
                    "; on Linux it writes nothing. A repository containing both "
                    c "README"
                    " and "
                    c "readme"
                    " cannot be checked out faithfully on the former. Rename with "
                    c "git mv"
                    ", never by hand."
                )
            ,
                ( "line endings"
                , do
                    c "core.autocrlf"
                    " converts per machine and makes the result depend on who committed. The "
                    c "text"
                    " and "
                    c "eol"
                    " attributes from Day 14 put the rule in the repository instead, where it belongs."
                )
            ,
                ( "Git 3.0"
                , do
                    c "/usr/share/doc/git/BreakingChanges.adoc"
                    " lists what is planned, with no release date yet: "
                    c "main"
                    " as the default branch (hence the hint on every "
                    c "git init"
                    " without "
                    opt "init.defaultBranch"
                    "), SHA-256 as the default hash, "
                    c "reftable"
                    " as the default ref storage, and removals such as "
                    c "git whatchanged"
                    " — which in 2.52 already refuses to run and suggests "
                    c "git log --raw --no-merges"
                    "."
                )
            ]

    block "Where to read next" $ do
        p_ $ do
            "Everything in this course was checked against git 2.52.0, and every command's manual page is \
            \on your machine. The guides git(1) points to are worth reading now that the vocabulary is \
            \yours:"
        sh
            [ "$ git help -g"
            , "The Git concept guides are:"
            , "   …"
            , "   everyday        A useful minimum set of commands for Everyday Git"
            , "   faq              Frequently asked questions about using Git"
            , "   glossary         A Git Glossary"
            , "   tutorial         A tutorial introduction to Git"
            , "   workflows        An overview of recommended workflows with Git"
            , "   …"
            ]
        steps
            [ do
                c "git help glossary"
                " — the definitions this course has been using, in git's own words."
            , do
                c "git help workflows"
                " — how the git project itself uses branches, merges and rebases."
            , do
                c "git help revisions"
                " and "
                c "git help config"
                " — the two reference pages you will open most. Day 7 and Day 12 were an introduction to them."
            , do
                "The Git User's Manual in "
                c "/usr/share/doc/git/user-manual.html"
                ", whose Git concepts chapter is the long form of Day 1."
            ]
        why $ p_ $ do
            "Three weeks ago git(1) was a list of two hundred commands. It should now read as a map: \
            \porcelain you use daily, ancillary commands you reach for monthly, plumbing you script \
            \against, and a store of objects and names underneath that none of them can escape. That \
            \reading — not any single command — is what the course was for."

    block "Today's habit" $ do
        p_ $ do
            "Keep one reflex: when git surprises you, set "
            c "GIT_TRACE=1"
            " or "
            c "GIT_TRACE_SETUP=1"
            " before you search the web. And before running git in a directory someone else made, clone \
            \it first."

cheat :: Html ()
cheat =
    cfg
        [ "GIT_TRACE=1 git ...           # commands, aliases, subprocesses"
        , "GIT_TRACE_SETUP=1 git ...     # which .git / worktree / prefix"
        , "GIT_TRACE2_PERF=1 git ...     # where the time went"
        , "GIT_TERMINAL_PROMPT=0         # scripts: fail, never prompt"
        , "git -c safe.directory=$PWD status   # one-off trust"
        , "git clone --no-local SRC DST  # untrusted local repo: fresh, checked"
        , "# never run git inside a .git you did not create"
        , "git help -g | git help glossary | git help revisions"
        ]
