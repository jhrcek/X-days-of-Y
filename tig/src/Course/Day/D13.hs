module Course.Day.D13 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 13
        , dayTitle = "External commands"
        , daySubtitle = "Command flags, plus your browsing state substituted in."
        , dayMinutes = 36
        , dayLevel = "advanced"
        , dayManRef = "tigrc(5) External user-defined command; tigmanual(7) Browsing State"
        , dayTags = ["external commands", "%(variables)", "flags"]
        , dayGoals =
            [ "choose the right flag for a command: foreground, background, one line, or confirm first"
            , "substitute the commit, branch, file or line under the cursor into a shell command"
            , "know which variables are empty in which views, and why that fails silently"
            ]
        , dayDiagram = Just d13diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("bind <keymap> <key> !<cmd>", "Run in the foreground, output shown.")
            , ("bind <keymap> <key> @<cmd>", "Run in the background, no output.")
            , ("bind <keymap> <key> +<cmd>", "Run and echo the first output line to the status bar.")
            , ("bind <keymap> <key> ?<cmd>", "Ask before running.")
            , ("bind <keymap> <key> <<cmd>", "Exit tig after running.")
            , ("bind <keymap> <key> ><cmd>", "Reopen tig in the last view afterwards.")
            ]
        , dayOpts = []
        , dayConfig = day13config
        , dayDrills =
            [ "Add the clipboard binding from today's config (adjusting "
                <> c "xclip"
                <> " for your platform) and press it on a commit. Paste the result somewhere and \
                   \confirm you got forty characters, not seven."
            , "Add "
                <> c "bind main A !git commit --amend"
                <> ". Use it. Note that your editor opens properly, because "
                <> c "!"
                <> " hands over the terminal."
            , "Try the same thing with "
                <> c "@"
                <> " instead of "
                <> c "!"
                <> " and watch it fail confusingly — a background command has no terminal for the \
                   \editor to use."
            , "Add "
                <> c "bind refs U +sh -c 'git log --oneline -1 %(branch)'"
                <> " and press it in the refs view. Only the first line of output reaches the \
                   \status bar."
            , "Add a prompting one: "
                <> c "bind main B ?git checkout -b \"%(prompt Enter new branch name: )\""
                <> ". Note that the prompt text is part of the variable."
            , "Break it on purpose: bind "
                <> c "@sh -c \"echo [%(branch)] >> /tmp/v\""
                <> " to a key and press it in the "
                <> i_ "main"
                <> " view rather than refs. Read "
                <> c "/tmp/v"
                <> ": the variable expanded to nothing, and no error was reported."
            , "Today's habit: the next time you copy a commit hash by selecting it with the mouse, \
              \stop and write the binding instead."
            ]
        , dayQuiz =
            [
                ( "Your binding "
                    <> c "@git push origin %(branch)"
                    <> " works in the refs view and silently pushes the wrong thing from the main \
                       \view. What happened?"
                , do
                    p_ $ do
                        "Browsing-state variables that have no value in the current view expand to \
                        \the "
                        b_ "empty string"
                        ", not to an error. In the main view nothing is a selected branch, so the \
                        \command that actually ran was "
                        c "git push origin"
                        " — which pushes according to your push configuration rather than failing."
                    p_ $ do
                        "This was verified: a binding echoing "
                        c "%(branch)"
                        " pressed in the main view writes an empty value and reports nothing. The \
                        \defence is to bind view-specific commands in view-specific keymaps — "
                        c "bind refs …"
                        ", not "
                        c "bind generic …"
                        " — so the key does not exist where the variable is meaningless."
                )
            ,
                ( "Which flag do you use for "
                    <> c "git rebase -i"
                    <> ", and what goes wrong with each of the others?"
                , do
                    p_ $ do
                        c "!"
                        ", the foreground flag — it is also the default if you give no flag at all. \
                        \Interactive commands need the terminal, and "
                        c "!"
                        " hands it over and waits."
                    p_ $ do
                        c "@"
                        " runs in the background with no terminal, so the editor cannot open. "
                        c "+"
                        " runs synchronously and captures the first line, so an editor would fight \
                        \for the terminal. The prompt form "
                        c ":!git rebase -i"
                        " from Day 5 captures output into the pager view, which is equally wrong. \
                        \Flags combine, so "
                        c "?!"
                        " — confirm, then run in the foreground — is a reasonable belt and braces."
                )
            ,
                ( "You write "
                    <> c "bind generic Y @echo %(commit) | xclip -selection c"
                    <> " and the clipboard ends up containing nothing useful. Why?"
                , do
                    p_ $ do
                        "There is no shell. tig does not hand the command line to "
                        c "sh"
                        ", so the pipe is not a pipe — it is just more arguments to "
                        c "echo"
                        ". Anything involving pipes, redirection, variable expansion or globbing has \
                        \to run inside an explicit shell."
                    p_ $ do
                        "Write it as "
                        c "@sh -c \"printf '%s' %(commit) | xclip -selection clipboard\""
                        ". And prefer "
                        c "printf"
                        " to "
                        c "echo -n"
                        ", which is not portable — a trailing newline in your clipboard is exactly \
                        \the kind of thing that breaks a paste into a commit message."
                )
            ,
                ( "Why is "
                    <> c "%(commit)"
                    <> " forty characters when the view shows seven?"
                , do
                    p_ $ do
                        "Because the abbreviated ID is a display choice and the browsing state \
                        \holds the real thing. tig substitutes the full forty-character SHA — \
                        \confirmed by echoing it from a binding — regardless of what the "
                        c "id"
                        " column is showing or what "
                        c "core.abbrev"
                        " says."
                    p_ $ do
                        "That is the right call for scripting: an abbreviation can become ambiguous \
                        \as a repository grows, and a command built from a full ID keeps working. \
                        \If you want a short one in a commit message, abbreviate at the far end "
                        i_ "("
                        c "git rev-parse --short"
                        i_ ")"
                        " rather than hoping tig gives you one."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

day13config :: [ConfBlock]
day13config =
    [ ConfBlock
        "Copy the full commit ID of the selected commit to the clipboard. Needs a shell because\n\
        \of the pipe, and printf rather than echo -n so no trailing newline is copied.\n\
        \Replace xclip with pbcopy on macOS, or wl-copy under Wayland."
        "bind generic Y @sh -c \"printf '%s' %(commit) | xclip -selection clipboard\""
    , ConfBlock
        "Amend the last commit without leaving tig. The ! flag runs in the foreground and hands\n\
        \over the terminal, which is what lets your editor open properly."
        "bind main A !git commit --amend"
    , ConfBlock
        "Create and check out a branch from the selected commit, asking for the name first.\n\
        \The prompt text is part of the variable, and ? confirms before anything runs."
        "bind main B ?git checkout -b \"%(prompt Enter new branch name: )\" %(commit)"
    , ConfBlock
        "In the refs view only, show the tip commit of the branch under the cursor in the status\n\
        \bar. Bound in the refs keymap because %(branch) is empty everywhere else - and an empty\n\
        \expansion is silent, not an error."
        "bind refs U +sh -c 'git log --oneline -1 %(branch)'"
    ]

-- ---------------------------------------------------------------------------

d13diagram :: Diagram
d13diagram =
    ( diagram
        "An external command binding: a flag decides how the command is run, the command text \
        \contains browsing-state variables which are substituted from the current view and cursor \
        \position before execution, and a variable with no value in the current view expands to the \
        \empty string."
        body'
    )
        { dgCaption = do
            "A binding, a flag and a command with holes in it. The flag decides "
            i_ "how"
            " it runs; the browsing state decides "
            i_ "what"
            " it runs on. The amber box is the trap: a variable that has no value in the current \
            \view expands to nothing at all, so the command still runs — just not on what you \
            \meant."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  bind [label=\"an external\\ncommand binding\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  flag [label=\"a flag\\n! @ + ? < >\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  cmd  [label=\"a command line\"];"
            , "  vars [label=\"browsing-state variables\\n%(commit) %(branch)\\n%(file) %(lineno)\"];"
            , "  state [label=\"the browsing state\\n(the view + the cursor)\", fillcolor=\"#f4efe6\"];"
            , "  sh   [label=\"sh -c\\n(needed for pipes\\nand redirection)\", fillcolor=\"#f4efe6\"];"
            , "  run  [label=\"a running process\"];"
            , "  empty [label=\"the empty string\\n(when the variable has\\nno value in this view)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  bind  -> flag  [label=\"  begins with\"];"
            , "  bind  -> cmd   [label=\"  carries\"];"
            , "  cmd   -> vars  [label=\"  contains\"];"
            , "  state -> vars  [label=\"  supplies\"];"
            , "  vars  -> empty [label=\"  may expand to\", style=dashed];"
            , "  cmd   -> sh    [label=\"  may invoke\"];"
            , "  flag  -> run   [label=\"  decides how tig starts\"];"
            , "  cmd   -> run   [label=\"  becomes\"];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "The extension point" $ do
        p_ [class_ "lede"] $ do
            "This is where tig stops being a viewer and becomes a place you work. A binding whose \
            \action starts with a flag character runs an arbitrary command, with the commit, \
            \branch, file or line under your cursor substituted into it. Five lines of config and \
            \tig is a code-review tool shaped like your team's workflow."
        p_ $ do
            "You have already used four of these without knowing: "
            k "C"
            " in the main view is "
            c "?git cherry-pick %(commit)"
            ", "
            k "C"
            " in the status view is "
            c "!git commit"
            ", and the refs and stash keys from Day 9 are all of this form."
        fig

    block "Six flags, and choosing between them" $ do
        defs
            [ (c "!", "Foreground, output shown, tig waits. The default when no flag is given.")
            , (c "@", "Background, no output, tig does not wait.")
            , (c "+", "Synchronous; the first line of output goes to the status bar.")
            , (c "?", "Ask before running.")
            , (c "<", "Exit tig after the command.")
            , (c ">", "Reopen tig in the last view after the command.")
            ]
        p_ "The choice is almost mechanical once you ask what the command needs:"
        steps
            [ do
                "Does it want the terminal — an editor, a pager, an interactive prompt? "
                c "!"
                ". Nothing else will do."
            , do
                "Is it fire-and-forget, with nothing to show you? "
                c "@"
                ". Copying to the clipboard, kicking off a fetch."
            , do
                "Does it answer a question in one line? "
                c "+"
                ". Verified: only the first line of output reaches the status bar; the rest is \
                \discarded."
            , do
                "Is it destructive or irreversible? Prefix "
                c "?"
                ". The prompt reads "
                c "Run `<command>`? [Yy/Nn]"
                "."
            ]
        p_ $ do
            "Flags combine, and the combinations are the useful part: "
            c "?<git rebase -i %(commit)^"
            " asks first and then exits tig so the rebase owns the terminal; "
            c "?>"
            " asks, runs, and comes back to where you were."
        gotcha $ p_ $ do
            "There is no shell unless you ask for one. tig does not pass the command line to "
            c "sh"
            ", so pipes, redirections, "
            c "&&"
            ", globs and "
            c "$VARIABLES"
            " are not interpreted — they are just arguments. Anything using them must be written as "
            c "sh -c '…'"
            ". This is the single most common reason a binding “does nothing”."

    block "Browsing state: the holes in the command" $ do
        p_ $ do
            "Day 1's browsing state is what makes these bindings worth having. The variables are \
            \substituted before the command runs, from the current view and cursor position. The \
            \dozen worth memorising:"
        defs
            [ (c "%(commit)", "The selected commit ID — the full forty characters.")
            , (c "%(head)", "The head the view was opened against. Literally " <> c "HEAD" <> " by default.")
            , (c "%(branch)", "The selected branch name. Refs view.")
            , (c "%(remote)" <> ", " <> c "%(tag)" <> ", " <> c "%(refname)", "Likewise, by category. " <> c "%(refname)" <> " includes the remote prefix.")
            , (c "%(stash)", "The selected stash, e.g. " <> c "stash@{0}" <> ".")
            , (c "%(file)", "The selected file. " <> c "%(directory)" <> " in the tree view.")
            , (c "%(lineno)", "The selected line number. " <> c "%(text)" <> " is the line's text.")
            , (c "%(prompt)", "Ask the user. " <> c "%(prompt Enter a name: )" <> " sets the wording.")
            , (c "%(repo:head)", "The checked-out branch name; " <> c "%(repo:upstream)" <> ", " <> c "%(repo:remote)" <> " and " <> c "%(repo:git-dir)" <> " alongside it.")
            ]
        p_ $ do
            "There are about forty in total, including the argument groups ("
            c "%(revargs)"
            ", "
            c "%(fileargs)"
            ", "
            c "%(diffargs)"
            ") that let a binding re-run tig with the same limits. tigrc(5) has the full list; these \
            \are the ones that earn their place in your fingers."
        gotcha $ p_ $ do
            "A variable with no value in the current view expands to "
            b_ "the empty string"
            ", and nothing is reported. "
            c "%(branch)"
            " in the main view is empty, so "
            c "git push origin %(branch)"
            " becomes "
            c "git push origin"
            " and pushes something you did not choose. Verified by echoing the variable from a \
            \binding pressed in the wrong view: an empty value, no error, no warning."
        tip $ p_ $ do
            "The defence is the keymap. Bind view-specific commands in view-specific keymaps — "
            c "bind refs …"
            " for anything using "
            c "%(branch)"
            ", "
            c "bind stash …"
            " for "
            c "%(stash)"
            " — so the key simply does not exist where the variable would be empty. That is what the \
            \built-in bindings do, and it is why Day 12's resolution order matters here."

    block "Two worked examples" $ do
        p_ "The clipboard binding, which is the one everybody wants first:"
        cfg
            [ "bind generic Y @sh -c \"printf '%s' %(commit) | xclip -selection clipboard\""
            ]
        p_ $ do
            "Every part is doing work. "
            c "@"
            " because there is nothing to show. "
            c "sh -c"
            " because of the pipe. "
            c "printf"
            " rather than "
            c "echo -n"
            " because "
            c "echo -n"
            " is not portable and a trailing newline in your clipboard will bite you. Substitute "
            c "pbcopy"
            " on macOS or "
            c "wl-copy"
            " under Wayland."
        p_ "And a prompting one, which shows how user input works:"
        cfg
            [ "bind main B ?git checkout -b \"%(prompt Enter new branch name: )\" %(commit)"
            ]
        p_ $ do
            "The prompt text lives inside the variable, the quotes protect a name with spaces in \
            \it, and "
            c "?"
            " gives you a look at the assembled command before it runs. Branch off any commit in \
            \your history with two keystrokes and a name."
        note $ p_ $ do
            "One packaging alternative worth knowing: put the complicated part in a git alias and \
            \keep the binding trivial. "
            c "[alias] publish = !for i in origin public; do git push $i; done"
            " in "
            c ".gitconfig"
            ", then "
            c "bind generic > !git publish"
            ". The shell quoting lives in one place, and the alias works from the command line too."

    block "Today's habit" $ do
        p_ $ do
            "Add the clipboard binding today — it is the one you will use most, and it retires the \
            \habit of selecting hashes with the mouse. Then watch yourself for a week: every time \
            \you leave tig to run a command, ask whether it wanted "
            c "%(commit)"
            " or "
            c "%(file)"
            ". If it did, it was a binding."
        p_ "Tomorrow: colours, large repositories, and everywhere this course disagrees with the manual."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "External commands."
        " The last two lines are where the time goes."
    cfg
        [ "bind <keymap> <key> <flag><command>"
        , "  !  foreground, shows output, waits   (the default; use for editors)"
        , "  @  background, no output             +  first output line -> status bar"
        , "  ?  confirm first                     <  exit after    >  reopen after"
        , "  flags combine:  ?<git rebase -i %(commit)^"
        , "%(commit) full 40-char SHA   %(branch) %(tag) %(stash) %(file) %(lineno)"
        , "%(prompt Enter a name: )     %(repo:head) %(repo:upstream) %(repo:git-dir)"
        , "# NO SHELL: pipes/redirection/globs need sh -c '…'"
        , "# an out-of-context variable expands to EMPTY, silently — bind per keymap"
        ]
