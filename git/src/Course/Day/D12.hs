module Course.Day.D12 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 12
        , dayTitle = "Config and aliases"
        , daySubtitle = "Five layers of settings, the last one read wins, and a small language of your own on top."
        , dayMinutes = 35
        , dayLevel = "intermediate"
        , dayManRef = "OPTIONS (-c), CONFIGURATION MECHANISM, ENVIRONMENT (GIT_CONFIG_GLOBAL); git-config(1)"
        , dayTags = ["config", "includeIf", "aliases"]
        , dayGoals =
            [ "find out which file a setting came from, and why the value you set is not the one git uses"
            , "keep a second identity for work repositories that switches on by directory, with no manual step"
            , "write aliases — plain and shell — and know when an alias is the wrong tool"
            ]
        , dayDiagram = Just d12diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git config list --show-origin --show-scope", "List every setting in effect, with the file and scope it came from.")
            , ("git config get <name>", "Print the value git will use. Exit status 1 if unset.")
            , ("git config set [--global] <name> <value>", "Write a setting, to the repository's " <> c ".git/config" <> " unless told otherwise.")
            , ("git config unset [--global] <name>", "Remove a setting from one file. Exit status 5 if it was not there.")
            , ("git config edit --global", "Open " <> c "~/.gitconfig" <> " in your editor.")
            , ("git -c <name>=<value> <cmd>", "Override one setting for one command, above every file.")
            , ("git help <alias>", "Print what an alias expands to.")
            ]
        , dayOpts =
            [ ("includeIf.\"gitdir:<dir>/\".path", "Read another config file only for repositories under " <> var "dir" <> ".")
            , ("alias.<name>", "Define " <> c "git <name>" <> ". A leading " <> c "!" <> " makes it a shell command.")
            , ("GIT_CONFIG_GLOBAL", "Read this file instead of " <> c "~/.gitconfig" <> "; " <> c "/dev/null" <> " for none.")
            , ("GIT_PREFIX", "Set for shell aliases: the directory you ran them from, relative to the top level.")
            ]
        , dayConfig =
            [ ConfBlock
                "Aliases for things no built-in says in one word. lg shows every branch as a graph;\n\
                \last is the commit you just made, with its files; aliases lists these very lines,\n\
                \using get --all --show-names because plain get --regexp prints one bare value."
                "[alias]\n\
                \\tlg = log --graph --oneline --all\n\
                \\tlast = log -1 --stat\n\
                \\taliases = !git config get --all --show-names --regexp '^alias\\\\.'"
            , ConfBlock
                "A second identity for everything under ~/work/. The trailing slash matters: it means\n\
                \every repository below that directory. If ~/.gitconfig-work does not exist git\n\
                \silently skips it, so this line is harmless until you create that file."
                "[includeIf \"gitdir:~/work/\"]\n\
                \\tpath = ~/.gitconfig-work"
            ]
        , dayDrills =
            [ "Run "
                <> c "git config list --show-origin --show-scope"
                <> " in a repository you work in. Find one setting you did not know you had."
            , "Pick a setting that appears in two scopes (or create one: set "
                <> c "user.name"
                <> " locally in a scratch repository). Run "
                <> c "git config get --all --show-scope user.name"
                <> " and predict which line git uses before checking with plain "
                <> c "get"
                <> "."
            , "Break it on purpose: run "
                <> c "git config nothere"
                <> " and "
                <> c "git config unset --global nothere.x; echo $?"
                <> ". Read the error and the exit status; scripts depend on both."
            , "Run one command with a different identity, without touching any file: "
                <> c "git -c user.name=Test commit --allow-empty -m probe"
                <> " in a scratch repository, then "
                <> c "git log -1 --format=%an"
                <> "."
            , "If you have work and personal repositories on one machine, write "
                <> c "~/.gitconfig-work"
                <> " with just a "
                <> c "[user] email"
                <> ", add the "
                <> c "includeIf"
                <> " block, and check "
                <> c "git config get --show-origin user.email"
                <> " in one repository of each kind."
            , "Add the three aliases from today's config block. Then run "
                <> c "git help lg"
                <> " and "
                <> c "git aliases"
                <> "."
            , "Try to shadow a built-in: "
                <> c "git config set --global alias.status 'status -s'"
                <> ", run "
                <> c "git status"
                <> ", and notice nothing changed. Remove it with "
                <> c "git config unset --global alias.status"
                <> "."
            , "From today, when git does something you did not expect, the first command you run is "
                <> c "git config list --show-origin"
                <> ", before searching the web."
            ]
        , dayQuiz =
            [
                ( "You ran "
                    <> c "git config set --global pull.ff only"
                    <> ", but in one repository "
                    <> c "git pull"
                    <> " still creates merge commits. Where do you look?"
                , do
                    p_ $ do
                        "At the other layers. Local "
                        c ".git/config"
                        " is read after "
                        c "~/.gitconfig"
                        ", and for a single-valued setting the last value read wins, so a stale "
                        c "pull.ff"
                        " or "
                        c "pull.rebase"
                        " in that repository beats yours. "
                        c "git config get --all --show-origin --show-scope pull.ff"
                        " shows every definition in the order git read them."
                    p_ $ do
                        "Also check the environment and the command line: a wrapper script or an alias passing "
                        c "-c"
                        ", or "
                        c "GIT_CONFIG_GLOBAL"
                        " pointing somewhere else, changes what “global” means."
                )
            ,
                ( "Your "
                    <> c "[includeIf \"gitdir:~/work\"]"
                    <> " block never applies, although every work repository is under "
                    <> c "~/work"
                    <> ". Why?"
                , p_ $ do
                    "Because the pattern is matched against the repository's "
                    c ".git"
                    " directory, not the working directory, and without a trailing slash it has to match the \
                    \whole path. "
                    c "~/work/api/.git"
                    " is not "
                    c "~/work"
                    ". With "
                    c "gitdir:~/work/"
                    " git appends "
                    c "**"
                    " for you, and everything below matches — including "
                    c "~/work"
                    " itself if it is a repository. Note also that "
                    c "includeIf \"gitdir:…\""
                    " never applies outside a repository, so "
                    c "git config get user.email"
                    " run from "
                    c "/tmp"
                    " shows your default identity."
                )
            ,
                ( "You define "
                    <> c "alias.grepall = !grep -rn TODO ."
                    <> " and run it from "
                    <> c "src/"
                    <> ". It searches the whole project. Why, and how do you fix it?"
                , do
                    p_ $ do
                        "Shell aliases run from the top level of the working tree, not from where you typed them. \
                        \git puts the directory you started in, relative to the top, in "
                        c "GIT_PREFIX"
                        " ("
                        c "src/"
                        " here). Write "
                        c "!cd \"${GIT_PREFIX:-.}\" && grep -rn TODO ."
                        " to get the behaviour you expected."
                    p_ "Plain (non-!) aliases do not have this problem: they are git commands, and git commands already understand the current directory."
                )
            ,
                ( "A script does "
                    <> c "git config get --regexp '^remote\\.'"
                    <> " expecting a list of remotes, and gets one bare URL. What happened?"
                , p_ $ do
                    "The new "
                    c "get"
                    " subcommand keeps the semantics of a single lookup: it returns the "
                    em_ "last"
                    " matching value, and prints values without names. You need "
                    c "--all --show-names"
                    " for the old "
                    c "--get-regexp"
                    " behaviour. The deprecated spellings ("
                    c "git config --get-regexp"
                    ", "
                    c "git config name value"
                    ") still work in 2.52 without a warning, which is why old scripts keep running and new \
                    \ones get surprised."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d12diagram :: Diagram
d12diagram =
    ( diagram
        "git's configuration: a git command reads the last value of a config variable; a config variable \
        \is set in a config file or by a -c argument; each config file has a scope; a config file can \
        \include another under a condition; an alias is a config variable that expands to a git command."
        body'
    )
        { dgCaption = do
            "There is no merge of settings and no priority field: git reads the files in scope order and "
            b_ "the last value it reads wins"
            ". Everything in the day follows from that — "
            c "-c"
            " wins because it is read last, a local file beats the global one because it is read later, and \
            \an "
            c "includeIf"
            " behaves as if its file were pasted in at that line. An alias is not a separate mechanism \
            \at all; it is one more variable."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  cmd   [label=\"a git command\", fillcolor=\"#f4efe6\"];\n\
        \  var   [label=\"a config variable\\n(section.key = value)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  file  [label=\"a config file\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  scope [label=\"a scope\\n(system, global, local,\\nworktree, command)\"];\n\
        \  flag  [label=\"a -c argument\"];\n\
        \  cond  [label=\"an includeIf condition\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  alias [label=\"an alias\"];\n\
        \\n\
        \  cmd   -> var   [label=\"  reads the last value of\"];\n\
        \  var   -> file  [label=\"  is set in\"];\n\
        \  flag  -> var   [label=\"  sets, for one command,\"];\n\
        \  file  -> scope [label=\"  has\"];\n\
        \  file  -> file  [label=\"  may include\"];\n\
        \  file  -> cond  [label=\"  guards an include with\", style=dashed];\n\
        \  alias -> var   [label=\"  is\"];\n\
        \  alias -> cmd   [label=\"  expands to\", style=dashed, constraint=false];\n\
        \\n\
        \  { rank=same; flag; cmd; alias; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Five layers, and the last one read wins" $ do
        p_ [class_ "lede"] $ do
            "git's configuration is not one file. It is a stack of files read in a fixed order, plus \
            \whatever you pass on the command line, and for any single-valued setting the value read last \
            \is the one that counts. Almost every “git ignores my setting” story is a setting defined twice, \
            \in two layers, and the other one being read later."
        p_ "The order, first to last:"
        defs
            [ ("system", do "The installation's file, usually " <> c "/etc/gitconfig" <> ". Shared by every user on the machine.")
            ,
                ( "global"
                , do
                    "Yours. Two files, both in the global scope: "
                    c "~/.config/git/config"
                    " is read first, then "
                    c "~/.gitconfig"
                    ". Most people only have the second. If both exist and disagree, "
                    c "~/.gitconfig"
                    " wins."
                )
            , ("local", do "The repository's " <> c ".git/config" <> ". Remotes and branch upstreams live here; " <> c "git clone" <> " writes it for you.")
            ,
                ( "worktree"
                , do
                    c ".git/config.worktree"
                    ", only if "
                    c "extensions.worktreeConfig"
                    " is enabled. Otherwise "
                    c "--worktree"
                    " quietly means "
                    c "--local"
                    "."
                )
            , ("command", do "Anything given with " <> c "git -c name=value" <> " or " <> c "GIT_CONFIG_COUNT" <> ". Read last, so it always wins.")
            ]
        p_ $ do
            "The file format is the one in the manual page's CONFIGURATION MECHANISM section: "
            c "[section]"
            " headers, "
            c "key = value"
            " lines, "
            c "#"
            " or "
            c ";"
            " comments. Section and key names are case-insensitive — "
            c "pull.ff"
            ", "
            c "Pull.FF"
            " and "
            c "[pull] ff"
            " are the same variable — and a section may appear any number of times."
        why $ p_ $ do
            "“Last one wins” is what makes the layering useful without a priority system. Your global file \
            \states your defaults; a repository that needs something different says so locally; a script \
            \that needs a guaranteed value passes "
            c "-c"
            ". Nobody has to know about anybody else's layer, and nothing has to be merged."
        fig

    block "Asking git where a value came from" $ do
        p_ $ do
            "Since 2.46, "
            c "git config"
            " has proper subcommands — "
            c "list"
            ", "
            c "get"
            ", "
            c "set"
            ", "
            c "unset"
            ", "
            c "edit"
            " — and the old forms are listed under DEPRECATED MODES in git-config(1). They still work in \
            \2.52, silently, so both appear in the wild. Use the new ones. The two display flags are the \
            \useful part:"
        sh
            [ "$ git config list --show-origin --show-scope"
            , "global  file:/home/ada/.gitconfig  user.name=Ada Example"
            , "global  file:/home/ada/.gitconfig  user.email=ada@example.com"
            , "local   file:.git/config           core.repositoryformatversion=0"
            , "local   file:.git/config           core.editor=vim"
            , "$ git config get --all --show-scope user.name"
            , "global  Ada Global"
            , "local   Ada Local"
            , "$ git config get user.name"
            , "Ada Local"
            , "$ git -c user.name=Cmdline config get --show-scope user.name"
            , "command Cmdline"
            ]
        p_ $ do
            "Writes go to the local file unless you say otherwise, which surprises people who expected "
            c "set"
            " to be global. "
            c "git config set --global"
            " writes "
            c "~/.gitconfig"
            "; "
            c "git config edit --global"
            " opens it."
        gotcha $ p_ $ do
            c "git config get --regexp '^alias\\.'"
            " prints "
            b_ "one value, with no name"
            " — the last match — because "
            c "get"
            " keeps single-lookup semantics even with a pattern. You want "
            c "get --all --show-names --regexp"
            ". The deprecated "
            c "--get-regexp"
            " printed everything with names, so an old script and its obvious modern translation \
            \disagree."
        p_ $ do
            "Scripts care about exit status: "
            c "get"
            " returns 1 for an unset key, "
            c "unset"
            " returns 5 when there was nothing to remove, and "
            c "--type=bool --default=false"
            " turns an unset or odd-looking value into a clean "
            c "true"
            "/"
            c "false"
            ". For a completely clean environment — a test, a bug report — "
            c "GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1"
            " leaves only the repository's own file."

    block "One machine, two identities" $ do
        p_ $ do
            "The problem everyone with a work laptop has: personal repositories should commit as you, work \
            \repositories as your work address, and remembering to run "
            c "git config user.email"
            " after every clone does not happen. The answer is a conditional include:"
        cfg
            [ "# ~/.gitconfig"
            , "[user]"
            , "\tname = Ada Example"
            , "\temail = ada@example.com"
            , "[includeIf \"gitdir:~/work/\"]"
            , "\tpath = ~/.gitconfig-work"
            , ""
            , "# ~/.gitconfig-work"
            , "[user]"
            , "\temail = ada@work.example"
            ]
        p_ $ do
            "An include is read as if its contents were pasted in at that line. Put the "
            c "includeIf"
            " after your default "
            c "[user]"
            " so that the work value is read later and wins. Check it from inside a work repository:"
        sh
            [ "$ cd ~/work/api && git config get --show-origin user.email"
            , "file:/home/ada/.gitconfig-work  ada@work.example"
            , "$ cd ~/workshop && git config get user.email"
            , "ada@example.com"
            ]
        p_ $ do
            "Note "
            c "~/workshop"
            ": it shares a prefix with "
            c "~/work"
            " but is not under it. The pattern is a path glob, not a string prefix: the trailing slash \
            \becomes "
            c "~/work/**"
            ", which matches whole directories below "
            c "~/work"
            " and nothing beside it."
        gotcha $ p_ $ do
            "A missing include file is not an error. If "
            c "~/.gitconfig-work"
            " has a typo in its name, git reads nothing and says nothing, and you commit with the wrong \
            \address. That is convenient for sharing one "
            c "~/.gitconfig"
            " across machines and dangerous for exactly this use, so check with "
            c "--show-origin"
            " once, in one real work repository."
        note $ p_ $ do
            "Other conditions exist: "
            c "gitdir/i:"
            " (case-insensitive), "
            c "onbranch:"
            ", and "
            c "hasconfig:remote.*.url:"
            " to match on where a repository was cloned from. Plain "
            c "[include] path = …"
            " includes unconditionally."

    block "Aliases are config too" $ do
        p_ $ do
            "An alias is a variable in the "
            c "[alias]"
            " section. "
            c "git lg"
            " looks up "
            c "alias.lg"
            ", splits the value into words, and runs the result as a git command with your arguments \
            \appended. "
            c "git help lg"
            " prints the expansion, which is the fastest way to read someone else's."
        sh
            [ "$ git config set --global alias.lg 'log --graph --oneline --all'"
            , "$ git help lg"
            , "'lg' is aliased to 'log --graph --oneline --all'"
            ]
        p_ $ do
            "A value starting with "
            c "!"
            " is handed to the shell instead, with your arguments appended as positional parameters. \
            \That lets an alias run any program, pipe, or several git commands in a row. The idiom for \
            \using arguments in the middle of a command is a throwaway function: "
            c "!f() { git log --author=\"$1\" --oneline; }; f"
            "."
        gotcha $ p_ $ do
            "Shell aliases run from the top level of the working tree, whatever directory you typed them in. \
            \git exports "
            c "GIT_PREFIX"
            " (for example "
            c "sub/"
            ") so you can "
            c "cd"
            " back. Plain aliases do not have this problem."
        p_ $ do
            "Two limits. An alias cannot replace a built-in — "
            c "alias.status"
            " is silently ignored, so "
            c "git status"
            " stays "
            c "git status"
            ". And an alias hides the real command from the person looking over your shoulder, so keep them \
            \for long spellings you type daily, not for renaming verbs. Most of what people alias — "
            c "co"
            ", "
            c "br"
            ", "
            c "ci"
            " — saves two keystrokes and costs you fluency on every other machine."

    block "Today's habit" $ do
        p_ $ do
            "Open your "
            c "~/.gitconfig"
            " with "
            c "git config edit --global"
            " and read it top to bottom. Delete every line you cannot explain. What is left, plus the \
            \lines this course adds with a reason attached, is a file you can carry between machines."
        p_ $ do
            "Tomorrow: stash and worktrees — two ways to put work aside, one of which is almost always \
            \the better choice."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Order of reading: system, global, local, worktree, command."
        " Last one wins."
    cfg
        [ "git config list --show-origin --show-scope   # everything, and where from"
        , "git config get --all --show-scope KEY         # every definition, in read order"
        , "git config set --global KEY VALUE             # without --global: .git/config"
        , "git config unset --global KEY                 # exit 5 if absent"
        , "git config edit --global                      # open ~/.gitconfig"
        , "git -c KEY=VALUE CMD                          # one command, beats every file"
        , "GIT_CONFIG_GLOBAL=/dev/null git ...           # run without your global file"
        , "[includeIf \"gitdir:~/work/\"] path = ...       # trailing slash = everything below"
        , "alias.x = log --oneline   /   alias.y = !sh   # ! runs at top level; see GIT_PREFIX"
        , "git help ALIAS                                # what it expands to"
        ]
