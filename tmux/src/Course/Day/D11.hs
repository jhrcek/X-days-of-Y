module Course.Day.D11 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 11
        , dayTitle = "Scripting your workspace"
        , daySubtitle = "One command that rebuilds a whole project, exactly, every time."
        , dayMinutes = 35
        , dayLevel = "advanced"
        , dayManRef = "COMMANDS, MISCELLANEOUS"
        , dayTags = ["scripting", "send-keys", "automation"]
        , dayGoals =
            [ "write an idempotent script that builds a project session from nothing"
            , "drive panes from outside: send keys, capture output, pipe a pane to a file"
            , "know when to run a command as a pane's process and when to type it into a shell"
            ]
        , dayDiagram = Just d11diagram
        , dayBody = body
        , dayKeys =
            [ ("C-b m", "Mark this pane. Marked panes are addressable as " <> c "'~'" <> " or " <> c "{marked}" <> ".")
            , ("C-b M", "Clear the mark.")
            ]
        , dayCmds =
            [ ("send-keys -t %7 'make' Enter", "Type into a pane from outside. Alias " <> c "send" <> ".")
            , ("send-keys -l 'literal $text'", "Send characters literally, without key-name lookup.")
            , ("send-keys -N 5 Up", "Repeat a key five times.")
            , ("run-shell 'cmd'", "Run a shell command with no window; output shown in view mode. Alias " <> c "run" <> ".")
            , ("run-shell -b 'cmd'", "Same, in the background, not blocking the command queue.")
            , ("if-shell 'test -d .git' 'cmd' 'other'", "Branch on a shell command's exit status.")
            , ("if-shell -F '#{…}' 'cmd'", "Branch on a format, with no shell at all.")
            , ("pipe-pane -o 'cat >>log'", "Copy everything a pane prints to a command; " <> c "-o" <> " toggles.")
            , ("capture-pane -p -S -", "A pane's whole history on stdout.")
            , ("respawn-pane -k 'cmd'", "Restart the command in a pane, killing the old one.")
            , ("wait-for -S name", "Wake up a client blocked on " <> c "wait-for name" <> ".")
            , ("select-pane -m", "Mark a pane; " <> c "-M" <> " clears the mark.")
            ]
        , dayOpts =
            [ ("remain-on-exit", "Keep a pane open after its command exits: on, off, failed, key.")
            , ("remain-on-exit-format", "The text shown at the bottom of a pane that has exited.")
            , ("default-command", "What a new pane runs when nothing is specified.")
            ]
        , dayConfig = day11config
        , dayDrills =
            [ "Write the bootstrap script for one real project of yours, following the pattern \
              \below. Put it in "
                <> c "~/bin"
                <> " and use it tomorrow morning instead of \
                   \building the session by hand."
            , "Make it idempotent and prove it: run it twice. The second run must attach, not \
              \duplicate."
            , "Drive a pane from another pane. Split, note the id with "
                <> c "tmux display -p '#{pane_id}'"
                <> ", then from the other side: "
                <> c "tmux send-keys -t %N 'date' Enter"
                <> "."
            , "Compare the two ways to start a program: "
                <> c "tmux neww 'top'"
                <> " and "
                <> c "tmux neww"
                <> " followed by "
                <> c "send-keys 'top' Enter"
                <> ". Quit "
                <> c "top"
                <> " in each and note which window survives."
            , "Turn on "
                <> c "remain-on-exit"
                <> " for one pane ("
                <> c "tmux set -p remain-on-exit on"
                <> "), run "
                <> c "false"
                <> " in it, and read what tmux leaves behind. Bring it \
                   \back with "
                <> c "respawn-pane -k"
                <> "."
            , "Log a pane to a file with today's "
                <> k "C-b P"
                <> " binding, generate some output, \
                   \turn it off, and read the file."
            , "Mark a pane with "
                <> k "C-b m"
                <> ", go to another one, and use "
                <> k "C-b C-r"
                <> " to re-run the last command over there. This is the \
                   \edit-here / run-there loop, and it is worth building the habit around."
            , "Save a layout you like: "
                <> c "tmux lsw -F '#{window_layout}'"
                <> ", then destroy \
                   \the arrangement and restore it with "
                <> c "select-layout '<that string>'"
                <> "."
            ]
        , dayQuiz =
            [
                ( "Why does "
                    <> c "tmux new-window 'npm run dev'"
                    <> " leave you with no window when \
                       \the server stops, while "
                    <> c "send-keys 'npm run dev' Enter"
                    <> " does not?"
                , p_ $ do
                    "Because in the first form the command "
                    i_ "is"
                    " the pane's process — when it exits, the pane has nothing left to run and \
                    \closes, taking the window with it. In the second the pane's process is your \
                    \shell, and the command is merely something typed into it; when it ends you get \
                    \your prompt back."
                    " Use the first for things that should own the pane, the second for anything you \
                    \will want to re-run, edit or "
                    k "C-c"
                    " and restart. Or set "
                    opt "remain-on-exit"
                    " and keep the corpse."
                )
            ,
                ( "What is wrong with "
                    <> c "tmux send-keys -t api:1 'make' Enter"
                    <> " in a script \
                       \that ran ten seconds earlier?"
                , do
                    p_ $ do
                        "Two things. The target may have moved — window and pane indices shuffle — so \
                        \resolve a "
                        c "#{pane_id}"
                        " once with "
                        c "-P -F"
                        " and use that thereafter."
                    p_ $ do
                        "And there is no synchronisation: "
                        c "send-keys"
                        " types immediately, whether or not the shell in that pane has finished \
                        \starting. For a shell it is usually fine; for anything slower, either start \
                        \the program as the pane's command instead of typing it, or use "
                        c "wait-for"
                        " to have the pane signal when it is ready."
                )
            ,
                ( "When would you use "
                    <> c "if-shell -F"
                    <> " rather than plain "
                    <> c "if-shell"
                    <> "?"
                , p_ $ do
                    "When the condition is about tmux's own state rather than the outside world. \
                    \Plain "
                    c "if-shell"
                    " forks "
                    c "/bin/sh"
                    " and tests its exit status; "
                    c "-F"
                    " evaluates a format and treats a non-empty, non-zero result as true. In a key \
                    \binding that fires constantly — a mouse binding, say — the difference between \
                    \“fork a shell” and “read a variable” is the difference between smooth and \
                    \sticky. The default mouse bindings are full of "
                    c "if-shell -F"
                    " for exactly this reason."
                )
            ,
                ( "What is the marked pane for?"
                , p_ $ do
                    "It is a single, server-wide bookmark set with "
                    k "C-b m"
                    ". Once set, "
                    c "'~'"
                    " (or "
                    c "{marked}"
                    ") addresses it from anywhere, and "
                    c "join-pane"
                    ", "
                    c "swap-pane"
                    " and "
                    c "swap-window"
                    " use it as their default source when "
                    c "-s"
                    " is omitted. It turns two-pane operations into “mark there, act here”, which is \
                    \much easier than naming a target across a session boundary."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d11diagram :: Diagram
d11diagram =
    ( diagram
        "A script issues tmux commands to the server, which creates sessions, windows and panes; \
        \send-keys types into a pane, capture-pane and pipe-pane read from it, and -P -F hands the \
        \script back an id to keep using."
        body'
    )
        { dgCaption = do
            "The loop that makes scripting tmux pleasant is the dashed one: a creation command with "
            c "-P -F '#{pane_id}'"
            " hands you a stable name for the thing it just made, and every later command targets "
            b_ "that"
            " rather than a position that might have moved. Everything else is ordinary commands in \
            \an ordinary shell script."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  scr  [label=\"a shell script\", fillcolor=\"#f4efe6\"];"
            , "  cmd  [label=\"a tmux command\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  srv  [label=\"the server\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  pane [label=\"a pane\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  id   [label=\"a pane id\\n%7\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  keys [label=\"keystrokes\", fillcolor=\"#f4efe6\"];"
            , "  outp [label=\"its output\", fillcolor=\"#f4efe6\"];"
            , "  file [label=\"a file or\\nanother command\", fillcolor=\"#f4efe6\"];"
            , ""
            , "  scr  -> cmd  [label=\"  issues\"];"
            , "  cmd  -> srv  [label=\"  is executed by\"];"
            , "  srv  -> pane [label=\"  creates\"];"
            , "  pane -> id   [label=\"  -P -F prints\"];"
            , "  id   -> cmd  [label=\"  targets later\\l  commands\\l\", style=dashed];"
            , "  keys -> pane [label=\"  send-keys types\"];"
            , "  pane -> outp [label=\"  produces\"];"
            , "  outp -> file [label=\"  capture-pane /\\l  pipe-pane send\\l\"];"
            ]

-- ---------------------------------------------------------------------------

day11config :: [ConfBlock]
day11config =
    [ ConfBlock
        "Edit here, run there. Mark the pane your build runs in with C-b m, then C-b C-r sends\n\
        \Up-Enter to it from wherever you are - re-running the last command without leaving the\n\
        \editor. The single best two-pane habit in tmux."
        "bind -N \"Repeat the last command in the marked pane\" C-r \\\n\
        \  send-keys -t '~' Up Enter"
    , ConfBlock
        "Toggle a log of everything a pane prints. The file name is a format, so each pane gets\n\
        \its own file, and -o makes one binding both start and stop it."
        "bind -N \"Toggle logging this pane\" P \\\n\
        \  pipe-pane -o 'cat >>$HOME/tmux-#{session_name}-#{window_index}.#{pane_index}.log' \\; \\\n\
        \  display-message \"logging #{?pane_pipe,ON,off}\""
    , ConfBlock
        "Keep a pane that failed, so the error is still on screen. 'failed' means panes whose\n\
        \command exited non-zero; a successful command still closes its pane cleanly."
        "set -wg remain-on-exit failed"
    ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "The payoff" $ do
        p_ [class_ "lede"] $ do
            "You now know enough to stop building workspaces by hand. A project session — four \
            \windows, the right directories, the server already running, the logs already tailing — \
            \is twenty lines of shell that you write once and run every morning."
        p_ $ do
            "There is no special scripting interface. It is the same commands you have been typing, \
            \issued from a shell script, targeting things by id."
        fig

    block "The pattern" $ do
        p_ "Every good tmux bootstrap script has the same skeleton:"
        sh
            [ "#!/bin/sh"
            , "set -e"
            , "SESSION=api"
            , "ROOT=$HOME/src/api"
            , ""
            , "# 1. Idempotence. If it is already there, just go there."
            , "if tmux has-session -t \"=$SESSION\" 2>/dev/null; then"
            , "  exec tmux attach -t \"=$SESSION\""
            , "fi"
            , ""
            , "# 2. Build it detached, so nothing flickers."
            , "tmux new-session -d -s \"$SESSION\" -c \"$ROOT\" -n edit"
            , "tmux send-keys -t \"$SESSION:edit\" 'nvim .' Enter"
            , ""
            , "# 3. Capture ids for anything you will talk to again."
            , "tmux new-window -d -t \"$SESSION:\" -c \"$ROOT\" -n run"
            , "server=$(tmux split-window -d -P -F '#{pane_id}' -t \"$SESSION:run\" -c \"$ROOT\")"
            , "tmux send-keys -t \"$server\" 'npm run dev' Enter"
            , "tmux select-layout -t \"$SESSION:run\" main-horizontal"
            , ""
            , "tmux new-window -d -t \"$SESSION:\" -c \"$ROOT\" -n git"
            , ""
            , "# 4. Decide where you land."
            , "tmux select-window -t \"$SESSION:edit\""
            , "exec tmux attach -t \"=$SESSION\""
            ]
        p_ "Four things in there are doing real work:"
        defs
            [
                ( c "=$SESSION"
                , "the "
                    <> c "="
                    <> " prefix demands an exact name match, so a session \
                       \called "
                    <> c "api"
                    <> " is never confused with "
                    <> c "api-staging"
                    <> "."
                )
            ,
                ( c "-d"
                , "everything is built detached. Without it your screen jumps between windows \
                  \as the script runs, and the terminal size is whatever the last command left."
                )
            ,
                ( c "-P -F '#{pane_id}'"
                , "creation commands can print what they created. Capture it in \
                  \a shell variable and every later command has an unambiguous target."
                )
            ,
                ( c "-c \"$ROOT\""
                , "set the directory once per window instead of typing "
                    <> c "cd"
                    <> " into four shells."
                )
            ]
        tip $ p_ $ do
            "The same script works as a "
            c ".tmux"
            " file at the root of a repository, with the project's path derived from "
            c "$(dirname \"$0\")"
            ". Then “open this project” is "
            c "./.tmux"
            " and the layout travels with the code."

    block "Two ways to start a program, and they are not equivalent" $ do
        cols
            [ do
                h3_ "As the pane's command"
                cfg
                    [ "tmux new-window -n dev 'npm run dev'"
                    , "tmux split-window 'tail -F log'"
                    ]
                p_ [class_ "lede-sm"] $ do
                    "The program "
                    i_ "is"
                    " the pane. No shell underneath. When it exits the pane closes — unless "
                    opt "remain-on-exit"
                    " says otherwise. Right for long-lived services you do not interact with."
            , do
                h3_ "Typed into a shell"
                cfg
                    [ "tmux new-window -n dev"
                    , "tmux send-keys -t dev 'npm run dev' Enter"
                    ]
                p_
                    [class_ "lede-sm"]
                    "The pane runs your shell; the command is just something typed \
                    \into it. Ctrl-C gives you a prompt back, with the command in history ready for \
                    \Up-Enter. Right for anything you will restart, edit, or run variations of."
            ]
        p_ $ do
            "In practice: services and tails as the pane's command, everything you will fiddle with \
            \through "
            c "send-keys"
            ". And when a pane's command dies unexpectedly, "
            opt "remain-on-exit"
            " set to "
            c "failed"
            " keeps the pane and its error on screen instead of vanishing the evidence — with "
            c "respawn-pane -k"
            " to bring it back."

    block "Talking to a running pane" $ do
        p_ $ do
            c "send-keys"
            " is the general-purpose “type this” command. Key names are looked up, so "
            c "Enter"
            ", "
            c "C-c"
            " and "
            c "Escape"
            " mean what they say; "
            c "-l"
            " sends the argument literally instead."
        sh
            [ "$ tmux send-keys -t %7 C-c                 # interrupt whatever is running"
            , "$ tmux send-keys -t %7 'make test' Enter   # then run something else"
            , "$ tmux send-keys -t %7 -N 3 Up             # press Up three times"
            , "$ tmux send-keys -t %7 -l '$notavar'       # literally, no key lookup"
            ]
        p_ "Reading is the mirror image:"
        sh
            [ "$ tmux capture-pane -p -t %7 | tail -20      # what is on screen"
            , "$ tmux capture-pane -p -S - -t %7 > full.log # the entire history"
            , "$ tmux pipe-pane -o -t %7 'cat >>live.log'   # tee it from now on"
            ]
        p_ $ do
            c "pipe-pane"
            " is the interesting one: it attaches a shell command to a pane's output stream and \
            \leaves it there. With "
            c "-o"
            " a single binding toggles it, which is today's "
            k "C-b P"
            ". With "
            c "-I"
            " it works the other way — the command's "
            i_ "output"
            " is written into the pane as though typed, which is how "
            c "make 2>&1 | tmux splitw -dI"
            " puts a build into a new pane without a shell in the middle."

    block "Marked panes: edit here, run there" $ do
        p_ $ do
            "There is exactly one marked pane on the server at a time. "
            k "C-b m"
            " sets it, "
            k "C-b M"
            " clears it, the window carrying it shows "
            c "M"
            " in the status line, and "
            c "'~'"
            " addresses it from anywhere."
        p_ $ do
            "Today's "
            k "C-b C-r"
            " binding uses that for the loop most people do by hand a hundred times a day: mark the \
            \pane your tests run in, then from the editor press "
            k "C-b C-r"
            " to send "
            k "Up"
            " and "
            k "Enter"
            " over there. No window switching, no retyping."
        cfg
            [ "bind C-r send-keys -t '~' Up Enter"
            ]
        p_ $ do
            "The mark also serves as the default source for "
            c "join-pane"
            ", "
            c "swap-pane"
            " and "
            c "swap-window"
            " when you leave "
            c "-s"
            " out — which is tomorrow's subject."

    block "Sequencing, and its limits" $ do
        p_ $ do
            "tmux runs commands from a queue, in order, and a few commands block that queue until \
            \something happens: "
            c "run-shell"
            " and "
            c "if-shell"
            " until their shell command finishes, "
            c "display-panes"
            " until a key is pressed. Add "
            c "-b"
            " to run in the background instead."
        p_ $ do
            "For genuine synchronisation there is "
            c "wait-for"
            ": one client blocks on a channel, another wakes it. It is how a script waits for \
            \something inside a pane to be ready without sleeping and hoping:"
        sh
            [ "# in the script"
            , "$ tmux send-keys -t %7 'slow-thing; tmux wait-for -S ready' Enter"
            , "$ tmux wait-for ready          # blocks until the pane signals"
            , "$ tmux send-keys -t %9 'now-the-next-thing' Enter"
            ]
        gotcha $ p_ $ do
            "Do not reach for "
            c "sleep"
            " in tmux scripts. It appears to work on your machine and then fails on a slower one, or \
            \on a cold cache, in a way that is maddening to debug. Either "
            c "wait-for"
            ", or make the thing the pane's command so that tmux itself knows when it ends."

    block "Restoring layouts" $ do
        p_ $ do
            "A window's arrangement can be serialised. "
            c "tmux lsw -F '#{window_layout}'"
            " gives you a string like "
            c "bb62,159x48,0,0{79x48,0,0,79x48,80,0}"
            ", and "
            c "select-layout"
            " takes it straight back. That is how session-restoring tools reproduce arrangements no \
            \preset can describe — and it is a two-line way to save your own favourite layout in your \
            \config:"
        cfg
            [ "bind -N \"My three-pane layout\" M-l \\"
            , "  select-layout 'bb62,159x48,0,0{79x48,0,0,79x48,80,0}'"
            ]

cheat :: Html ()
cheat = do
    cfg
        [ "tmux has-session -t \"=name\" 2>/dev/null || build_it   # idempotence"
        , "tmux new -d -s name -c DIR -n first                    # always build detached"
        , "id=$(tmux splitw -d -P -F '#{pane_id}' -t name:win)    # capture ids, target those"
        , "tmux send-keys -t \"$id\" 'cmd' Enter                    # type into it"
        , "tmux capture-pane -p -S - -t \"$id\"                     # read back out"
        , "tmux pipe-pane -o -t \"$id\" 'cat >>log'                 # tee, toggleable"
        , "tmux select-layout -t name:win main-horizontal"
        , ""
        , "neww 'cmd'   -> cmd IS the pane; it closes when cmd exits (remain-on-exit)"
        , "send-keys    -> cmd is typed into a shell; you keep the prompt"
        , ""
        , "C-b m / C-b M   mark a pane;  -t '~'  targets it   (join/swap default to it)"
        , "wait-for name / wait-for -S name    -- synchronise; never sleep"
        ]
