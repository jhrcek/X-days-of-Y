module Course.Day.D18 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 18
        , dayTitle = "Hooks"
        , daySubtitle = "Programs git runs at fixed moments — local, uncloned, and only as trustworthy as your own checkout."
        , dayMinutes = 35
        , dayLevel = "advanced"
        , dayManRef = "githooks(5); git(1) SECURITY; git-hook(1); core.hooksPath in git-config(1)"
        , dayTags = ["githooks", "pre-commit", "core.hooksPath"]
        , dayGoals =
            [ "write a pre-commit, commit-msg or pre-push hook that stops a bad commit, and read exactly what git passes it"
            , "explain why hooks are never cloned, and what that means for a team that wants to share them"
            , "use " <> c "core.hooksPath" <> " and " <> c "git hook run" <> " deliberately, without silently disabling hooks you already had"
            ]
        , dayDiagram = Just d18diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("ls .git/hooks", "See the sample hooks " <> c "git init" <> " installed. None of them runs: they end in " <> c ".sample" <> ".")
            , ("chmod +x .git/hooks/pre-commit", "Enable a hook. A hook without the executable bit is ignored, with a hint.")
            , ("git commit --no-verify", "Skip the pre-commit and commit-msg hooks for this commit. prepare-commit-msg still runs.")
            , ("git push --no-verify", "Skip the pre-push hook for this push.")
            , ("git hook run <name>", "Run a hook by hand, exactly as git would find it. Fails if it does not exist.")
            , ("git hook run --ignore-missing <name>", "Run it if it exists; succeed quietly if not. For scripts.")
            ]
        , dayOpts =
            [ ("core.hooksPath", "Look for hooks in this directory instead of " <> c "$GIT_DIR/hooks" <> ". Replaces it; does not add to it.")
            , ("GIT_INDEX_FILE", "Set for a pre-commit hook: the index being committed. Unset it before running git in another repository.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Run "
                <> c "ls .git/hooks"
                <> " in any repository and open "
                <> c "pre-commit.sample"
                <> ". Read what it checks. It has never run."
            , "Write a four-line pre-commit hook that prints "
                <> c "$(pwd)"
                <> " and "
                <> c "$GIT_PREFIX"
                <> " to stderr and exits 0. Commit from a subdirectory and read where the hook actually ran."
            , "Break it on purpose: make the hook "
                <> c "exit 1"
                <> ", try to commit, and read the result. Then take the executable bit off and commit again — \
                   \read the hint git prints instead."
            , "Write a commit-msg hook that rejects subjects starting with a lower-case letter. Test it with "
                <> c "git commit -m 'oops'"
                <> ", then get past it with "
                <> c "--no-verify"
                <> "."
            , "Write a pre-push hook that prints the lines it reads on stdin. Push a new branch and an update \
              \to an existing one, and compare the all-zeros hash in the first."
            , "In a repository you work in, list what it actually has enabled: "
                <> c "ls .git/hooks | grep -v sample"
                <> ", and "
                <> c "git config get core.hooksPath"
                <> ". If a tool installed hooks you did not know about, you know now."
            , "Clone a repository that has a hook installed and check the clone's "
                <> c ".git/hooks"
                <> ". Only samples."
            , "From now on, keep any check you want run on every commit in a script under version control, and \
              \make the hook a one-line call to it."
            ]
        , dayQuiz =
            [
                ( "Your pre-commit hook refuses commits whose staged diff contains "
                    <> c "DO NOT COMMIT"
                    <> ". You remove the marker, stage the file, and the hook still refuses. Why?"
                , do
                    p_ $ do
                        "Because the hook grepped the whole of "
                        c "git diff --cached"
                        ", and removing the marker produces a diff line "
                        c "-x DO NOT COMMIT"
                        ". The hook matched the deletion. This happened while writing this lesson."
                    p_ $ do
                        "Match only added lines: "
                        c "git diff --cached -U0 | grep -q '^+.*DO NOT COMMIT'"
                        ". The general lesson is that a hook sees text, not intent, and has to be tested against \
                        \the removal case as well as the adding one."
                )
            ,
                ( "The team adds a "
                    <> c "hooks/"
                    <> " directory to the repository. A new colleague clones and \
                       \commits a secret the pre-commit hook would have caught. What did the team assume, and why is \
                       \git designed not to allow it?"
                , do
                    p_ $ do
                        "That cloning installs hooks. It never does: "
                        c "git clone"
                        " copies objects and refs, not "
                        c ".git/hooks"
                        " or "
                        c ".git/config"
                        ". The git(1) SECURITY section explains why — hooks and configuration can run arbitrary \
                        \commands, so a clone that brought them along would mean anyone could run code on your \
                        \machine by getting you to clone."
                    p_ $ do
                        "Every colleague has to opt in, typically with "
                        c "git config core.hooksPath hooks"
                        " in their own clone. And a check that really must hold belongs in CI, where nobody can "
                        c "--no-verify"
                        " past it."
                )
            ,
                ( "You set "
                    <> c "core.hooksPath"
                    <> " globally to a directory of personal hooks. A week later, the project's own commit-msg \
                       \hook in "
                    <> c ".git/hooks"
                    <> " has stopped running. Why?"
                , p_ $ do
                    c "core.hooksPath"
                    " replaces the hooks directory; it is not a search path. Once it is set, git looks only there, \
                    \and "
                    c ".git/hooks"
                    " is ignored in every repository that inherits the setting. This is why this course puts no \
                    \hooks configuration in "
                    c "~/.gitconfig"
                    ". Set it per repository ("
                    c "git config core.hooksPath hooks"
                    ") or, if you want global hooks, have each one chain to the repository's own hook if it exists."
                )
            ,
                ( "A pre-commit hook does "
                    <> c "cd ~/other-repo && git status"
                    <> " and gets nonsense about staged files that do not exist there. What leaked?"
                , p_ $ do
                    c "GIT_INDEX_FILE"
                    ". For pre-commit, git 2.52 exports it pointing at "
                    c ".git/index.lock"
                    " of the repository being committed, and any git command the hook runs will use that index \
                    \— in whatever repository it happens to be in. githooks(5) warns about this: unset "
                    c "GIT_INDEX_FILE"
                    " (and "
                    c "GIT_DIR"
                    ", "
                    c "GIT_WORK_TREE"
                    " if set) before working on a foreign repository, or use "
                    c "env -u GIT_INDEX_FILE git -C ~/other-repo status"
                    "."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d18diagram :: Diagram
d18diagram =
    ( diagram
        "A git command reaches a hook point and looks for an executable in the hooks directory, which \
        \is .git/hooks unless core.hooksPath replaces it. The hook receives arguments, stdin and \
        \environment; its exit status can veto the command. A clone copies objects and refs but not \
        \the hooks directory."
        body'
    )
        { dgCaption = do
            "A hook is an executable at a name git knows, found in "
            b_ "one"
            " directory. Its exit status is the whole interface for the pre- hooks: non-zero stops the \
            \command. The dashed aspect is the one people assume holds: "
            b_ "a clone"
            " never carries the hooks directory, so every hook on your machine is one you, or a tool you \
            \ran, put there."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  cmd    [label=\"a git command\\n(commit, push, switch…)\", fillcolor=\"#f4efe6\"];\n\
        \  point  [label=\"a hook point\\n(pre-commit, commit-msg…)\"];\n\
        \  dir    [label=\"the hooks directory\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  path   [label=\"core.hooksPath\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  hook   [label=\"an executable hook\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  input  [label=\"arguments, stdin\\nand GIT_* variables\"];\n\
        \  status [label=\"an exit status\"];\n\
        \  clone  [label=\"a clone\", fillcolor=\"#f4efe6\"];\n\
        \\n\
        \  cmd   -> point  [label=\"  reaches\"];\n\
        \  point -> hook   [label=\"  runs, if present,\"];\n\
        \  dir   -> hook   [label=\"  contains\"];\n\
        \  path  -> dir    [label=\"  replaces\"];\n\
        \  hook  -> input  [label=\"  is given\"];\n\
        \  hook  -> status [label=\"  returns\"];\n\
        \  status -> cmd   [label=\"  can veto  \", style=dashed, constraint=false];\n\
        \  clone -> dir    [label=\"  never copies\", style=dashed];\n\
        \\n\
        \  { rank=same; path; clone; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "An executable with a known name" $ do
        p_ [class_ "lede"] $ do
            "A hook is a program git runs at a fixed moment — before a commit is written, after a checkout, \
            \before a push. There is no registration and no plugin API: git looks for an executable file \
            \with the hook's name in one directory, runs it with some arguments, and for the "
            c "pre-"
            " hooks, treats a non-zero exit as “stop”. That is the entire mechanism, and githooks(5) is a \
            \list of names."
        p_ $ do
            "Every "
            c "git init"
            " drops fourteen examples into "
            c ".git/hooks/"
            ", all ending in "
            c ".sample"
            " so that none of them runs. Rename one, or write your own, and make it executable:"
        sh
            [ "$ ls .git/hooks"
            , "applypatch-msg.sample     pre-commit.sample         pre-receive.sample"
            , "commit-msg.sample         pre-merge-commit.sample   push-to-checkout.sample"
            , "fsmonitor-watchman.sample prepare-commit-msg.sample sendemail-validate.sample"
            , "post-update.sample        pre-push.sample           update.sample"
            , "pre-applypatch.sample     pre-rebase.sample"
            ]
        gotcha $ p_ $ do
            "Forget "
            c "chmod +x"
            " and the hook is skipped — the commit succeeds, with only a hint: "
            c "hint: The '.git/hooks/pre-commit' hook was ignored because it's not set as executable."
            " In a noisy terminal, that is easy to miss for weeks."
        fig

    block "The four you will actually write" $ do
        defs
            [
                ( c "pre-commit"
                , "No arguments. Runs before the message is asked for. Inspect the index with "
                    <> c "git diff --cached"
                    <> "; exit non-zero to abort. Skipped by "
                    <> c "--no-verify"
                    <> "."
                )
            ,
                ( c "prepare-commit-msg"
                , "Given the message file and its source ("
                    <> c "message"
                    <> ", "
                    <> c "template"
                    <> ", "
                    <> c "merge"
                    <> ", "
                    <> c "commit"
                    <> "…). Edits the draft message. "
                    <> b_ "Not"
                    <> " skipped by "
                    <> c "--no-verify"
                    <> "."
                )
            ,
                ( c "commit-msg"
                , "Given the path of the message file (" <> c ".git/COMMIT_EDITMSG" <> "). May rewrite it, or exit non-zero to reject. Skipped by " <> c "--no-verify" <> "."
                )
            ,
                ( c "pre-push"
                , "Given the remote's name and URL as arguments, and one line per ref on stdin. Exit non-zero to cancel the push."
                )
            ]
        p_ "A pre-commit hook that refuses a marker, and a commit-msg hook that enforces a capital letter:"
        cfg
            [ "#!/bin/sh"
            , "# .git/hooks/pre-commit"
            , "if git diff --cached -U0 | grep -q '^+.*DO NOT COMMIT'; then"
            , "    echo \"pre-commit: remove the DO NOT COMMIT marker first\" >&2"
            , "    exit 1"
            , "fi"
            ]
        cfg
            [ "#!/bin/sh"
            , "# .git/hooks/commit-msg"
            , "grep -qE '^[A-Z]' \"$1\" || { echo \"commit-msg: subject must start with a capital\" >&2; exit 1; }"
            ]
        sh
            [ "$ git commit -qm 'lowercase subject'"
            , "commit-msg: subject must start with a capital"
            , "$ git commit -qm 'Clean up'"
            , "$ git commit --no-verify -m 'lowercase ok?'"
            , "[main cfbb862] lowercase ok?"
            ]
        p_ $ do
            "pre-push reads one line per ref being pushed: local ref, local hash, remote ref, remote hash. A \
            \new branch has forty zeros as its remote hash; a deletion has zeros as its local hash."
        sh
            [ "$ git push origin main"
            , "pre-push args: origin ../h18.git"
            , "pre-push stdin: refs/heads/main 9217bb79… refs/heads/main 0000000000000000000000000000000000000000"
            ]

    block "What a hook can see" $ do
        p_ $ do
            "githooks(5): before running a hook, git changes to the root of the working tree (or to "
            c "$GIT_DIR"
            " in a bare repository). So a hook always starts at the top, even when you committed from "
            c "src/deep/"
            ". Where you actually were is in "
            c "GIT_PREFIX"
            ". Here is every "
            c "GIT_*"
            " variable a pre-commit hook saw, run from a subdirectory:"
        sh
            [ "$ cd sub && git commit -qam 'Env dump'"
            , "GIT_AUTHOR_EMAIL=ada@example.com"
            , "GIT_AUTHOR_NAME=Ada Example"
            , "GIT_EDITOR=:"
            , "GIT_EXEC_PATH=/usr/libexec/git-core"
            , "GIT_INDEX_FILE=/…/h18/.git/index.lock"
            , "GIT_PREFIX=sub/"
            ]
        note $ p_ $ do
            "The manual page says that variables “such as GIT_DIR, GIT_WORK_TREE, etc., are exported”. In \
            \2.52, in an ordinary non-bare repository, neither is set for pre-commit or post-checkout; the \
            \hook finds the repository by starting in its top level. Server-side hooks such as "
            c "pre-receive"
            " do get "
            c "GIT_DIR=."
            ". Write hooks that work either way: do not rely on "
            c "GIT_DIR"
            " being set, and do not assume it is not."
        gotcha $ p_ $ do
            c "GIT_INDEX_FILE"
            " "
            b_ "is"
            " set, to the lock file of the commit in progress. Any git command in the hook inherits it — \
            \including one you run in a different repository, which will then read the wrong index. Unset it \
            \first: "
            c "env -u GIT_INDEX_FILE git -C ../other status"
            "."
        p_ $ do
            "One more surprise: "
            c "post-checkout"
            " is documented for "
            c "git checkout"
            " and "
            c "git switch"
            ", with a third argument of 1 for a branch checkout and 0 for a file checkout. "
            c "git restore f"
            " fires it too, with 0. A post-checkout hook that rebuilds something expensive will run on every \
            \restore."

    block "Hooks are local, on purpose" $ do
        p_ $ do
            c "git clone"
            " copies objects and refs. It does not copy "
            c ".git/hooks"
            ", and it does not copy "
            c ".git/config"
            ". The git(1) SECURITY section gives the reason: configuration and hooks can run arbitrary \
            \commands, so because they are not cloned, it is safe to clone an untrusted repository and read \
            \it. It is "
            b_ "not"
            " safe to run git inside a "
            c ".git"
            " directory someone handed you — Day 21 comes back to that."
        why $ p_ $ do
            "If hooks travelled with clones, cloning would be code execution. Every attempt to “share hooks \
            \with the team” therefore needs one explicit step per clone, and that step is where trust is \
            \granted. Hook-manager tools do exactly this: they ask you to run an install command once."
        p_ $ do
            "The usual shape is a versioned directory plus one per-clone setting:"
        sh
            [ "$ git config core.hooksPath hooks        # in this clone only"
            , "$ git hook run pre-commit                # run it as git would"
            , "$ git hook run --ignore-missing pre-push # no error if absent"
            ]
        gotcha $ p_ $ do
            opt "core.hooksPath"
            " "
            b_ "replaces"
            " the hooks directory. Set it globally and "
            c ".git/hooks"
            " is ignored in every repository you have, including hooks a project installed for you. That is \
            \why no hooks setting goes into this course's "
            c "~/.gitconfig"
            "."
        tip $ p_ $ do
            "Hooks are a convenience for you, not an enforcement mechanism for anyone else. "
            c "--no-verify"
            " exists, and so does a colleague who never ran the install step. Anything that must hold for \
            \the project goes in CI or in a server-side hook; the local hook tells you sooner."

    block "Today's habit" $ do
        p_ $ do
            "Take the check you most often forget — a linter, a formatter, a test that takes five seconds — \
            \and put it behind a pre-commit hook in the repository you spend most time in. Keep the logic in \
            \a script that lives in the repository; the hook is one line that calls it."
        p_ "Tomorrow: plumbing — the commands and output formats that are meant to be scripted against, and the ones that are not."

cheat :: Html ()
cheat =
    cfg
        [ "# .git/hooks/<name>, executable; non-zero exit aborts a pre- hook"
        , "pre-commit            # no args; inspect: git diff --cached -U0"
        , "prepare-commit-msg    # $1 msg file, $2 source; NOT skipped by --no-verify"
        , "commit-msg            # $1 msg file; reject or rewrite"
        , "pre-push              # $1 remote $2 url; stdin: lref loid rref roid"
        , "git commit --no-verify         # skip pre-commit + commit-msg"
        , "git config core.hooksPath hooks  # per clone; REPLACES .git/hooks"
        , "git hook run [--ignore-missing] NAME"
        , "# hooks run at the top level; cwd you came from is $GIT_PREFIX"
        , "# never cloned: every hook here is one you installed"
        ]
