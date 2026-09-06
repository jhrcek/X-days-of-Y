module Course.Day.D07 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 7
        , dayTitle = "The command language"
        , daySubtitle = "Parsing, quoting, and how to name any pane on the server."
        , dayMinutes = 35
        , dayLevel = "intermediate"
        , dayManRef = "COMMAND PARSING AND EXECUTION, PARSING SYNTAX, COMMANDS"
        , dayTags = ["targets", "quoting", "ids"]
        , dayGoals =
            [ "name any session, window or pane unambiguously, from a shell or from inside tmux"
            , "chain commands with semicolons and survive the shell's quoting rules"
            , "know when to use a name, an index, or an id — and why scripts must use ids"
            ]
        , dayDiagram = Just d7diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("tmux neww \\; splitw -h", "Two commands in one invocation. Note the escaped semicolon.")
            , ("display-message -p '#{pane_id}'", "Print a value to stdout instead of the status line.")
            , ("list-panes -a", "Every pane on the server, not just this window.")
            , ("list-windows -a", "Every window on the server.")
            , ("list-sessions -F '#{session_name}'", "One field per line — the shape scripts want.")
            , ("list-commands", "Every command tmux knows, with its synopsis. Alias " <> c "lscm" <> ".")
            , ("list-commands neww", "The synopsis for one command.")
            ]
        , dayOpts =
            [ ("command-alias", "Server option: an array of your own command aliases.")
            ]
        , dayConfig = day7config
        , dayDrills =
            [ "Print the identity of the pane you are sitting in: "
                <> c "tmux display -p '#{session_name}:#{window_index}.#{pane_index} = #{pane_id}'"
                <> "."
            , "List every pane on the server with its full address: "
                <> c "tmux lsp -a -F '#{pane_id} #{session_name}:#{window_index}.#{pane_index} #{pane_current_command}'"
                <> "."
            , "Send a command to a pane you are not in. Split a window, note the other pane's id, \
              \then from this pane run "
                <> c "tmux send-keys -t %7 'echo hello' Enter"
                <> "."
            , "Try each target token against a session with several windows: "
                <> c "-t :^"
                <> ", "
                <> c "-t :$"
                <> ", "
                <> c "-t :!"
                <> ", "
                <> c "-t :+"
                <> ", "
                <> c "-t :-2"
                <> ". Use "
                <> c "tmux display -p -t ... '#{window_name}'"
                <> " to see where you landed."
            , "Prove the ambiguity trap: make windows named "
                <> c "test"
                <> " and "
                <> c "testing"
                <> ", then target "
                <> c "-t :test"
                <> " and "
                <> c "-t :=test"
                <> " and compare."
            , "Chain three commands from a shell in the two legal ways — "
                <> c "tmux neww \\; splitw -h \\; splitw -v"
                <> " and "
                <> c "tmux neww ';' splitw -h"
                <> " — and then get it wrong on purpose without the \
                   \escaping to see what the shell does with it."
            , "Add a command alias: "
                <> c "tmux set -s command-alias[100] zoom='resize-pane -Z'"
                <> " and then run "
                <> c "tmux zoom"
                <> "."
            ]
        , dayQuiz =
            [
                ( "Why does "
                    <> c "tmux neww; splitw"
                    <> " in a shell do something different from "
                    <> c "tmux neww \\; splitw"
                    <> "?"
                , p_ $ do
                    "The first is parsed by "
                    i_ "the shell"
                    ": it runs "
                    c "tmux neww"
                    ", then runs the separate command "
                    c "splitw"
                    ", which is not a program and fails. The second escapes the semicolon so it \
                    \reaches tmux, which then treats it as its own command separator. Inside tmux — \
                    \at the command prompt or in a config file — no escaping is needed, because the \
                    \shell is not involved."
                )
            ,
                ( "A script does " <> c "tmux kill-pane -t 1" <> " and kills the wrong thing. Why?"
                , do
                    p_ $ do
                        "Two reasons, both about ambiguity. First, a bare "
                        c "1"
                        " is not obviously a pane: tmux will consider window 1, or session 1, if the \
                        \current window has no pane 1. Fully qualify it as "
                        c "-t :.1"
                        " to mean “pane 1 of the current window”."
                    p_ $ do
                        "Second, pane indices are positional and shuffle when panes are killed. A \
                        \script that resolves "
                        c "#{pane_id}"
                        " once and then uses "
                        c "%7"
                        " thereafter cannot be surprised — ids are unique for the life of the server \
                        \and never move."
                )
            ,
                ( "What does " <> c "-t api:build.2" <> " mean, and which parts can be left out?"
                , p_ $ do
                    "Session "
                    c "api"
                    ", window named "
                    c "build"
                    ", pane index 2. Everything is optional: with no "
                    c ":"
                    " the current session is assumed, with no "
                    c "."
                    " the window's active pane is used, and an empty window part ("
                    c "api:"
                    ") means that session's current window. tmux also guesses the "
                    i_ "type"
                    " you need from the command, which is convenient interactively and treacherous in \
                    \scripts."
                )
            ,
                ( "What is " <> c "-t '{mouse}'" <> " for?"
                , p_ $ do
                    "It resolves to the pane, window or session where the most recent mouse event \
                    \happened, and it only makes sense inside a mouse binding. It is why the default "
                    c "MouseDown1Pane"
                    " binding is "
                    c "select-pane -t = \\; send-keys -M"
                    " — "
                    c "="
                    " being the short form of "
                    c "{mouse}"
                    ". The same trick with "
                    c "{marked}"
                    " (short form "
                    c "~"
                    ") addresses the marked pane, which Day 12 puts to work."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d7diagram :: Diagram
d7diagram =
    ( diagram
        "How a target string resolves: a session part, a window part and a pane part, each of which \
        \may be a name, an index, an id or a special token, resolving to a session, window or pane."
        body'
    )
        { dgCaption = do
            "The left column is what you type; the right column is what it resolves to. The \
            \important asymmetry: "
            b_ "names and indices are resolved every time and can move or become ambiguous"
            ", while ids ("
            c "$1"
            ", "
            c "@4"
            ", "
            c "%7"
            ") are assigned once and never change for the life of the server. Interactive use wants \
            \the top rows; scripts want the bottom one."
        , dgRankdir = "LR"
        , dgRanksep = "0.75"
        , dgNodesep = "0.22"
        }
  where
    body' =
        T.unlines
            [ "  tgt   [label=\"a target string\\n'api:build.2'\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  sp    [label=\"the session part\\n'api'\"];"
            , "  wp    [label=\"the window part\\n'build'\"];"
            , "  pp    [label=\"the pane part\\n'2'\"];"
            , "  nm    [label=\"a name\\n(exact, then prefix,\\nthen glob)\", fillcolor=\"#f4efe6\"];"
            , "  ix    [label=\"an index\\n(0, 1, 2 …)\", fillcolor=\"#f4efe6\"];"
            , "  tok   [label=\"a special token\\n^ $ ! + - @\\n{end} {last} {up-of} …\", fillcolor=\"#f4efe6\"];"
            , "  id    [label=\"an id\\n$1  @4  %7\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  obj   [label=\"a session,\\nwindow or pane\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , ""
            , "  tgt -> sp [label=\"  before ':'\"];"
            , "  tgt -> wp [label=\"  between ':' and '.'\"];"
            , "  tgt -> pp [label=\"  after '.'\"];"
            , "  sp -> nm; sp -> ix; sp -> id;"
            , "  wp -> nm; wp -> ix; wp -> tok; wp -> id;"
            , "  pp -> ix; pp -> tok; pp -> id;"
            , "  nm  -> obj [label=\"  resolves to\"];"
            , "  ix  -> obj;"
            , "  tok -> obj;"
            , "  id  -> obj [label=\"  always resolves to\\l  the same one\\l\"];"
            , "  { rank=same; nm; ix; tok; id; }"
            ]

-- ---------------------------------------------------------------------------

day7config :: [ConfBlock]
day7config =
    [ ConfBlock
        "Command aliases live in a server option array. Pick indices well above the built-ins\n\
        \(0-99 are taken) so you do not shadow anything. Aliases are expanded at parse time,\n\
        \which means they work in bindings and config files as well as at the prompt."
        "set -s command-alias[100] zoom='resize-pane -Z'\n\
        \set -s command-alias[101] panes='list-panes -a -F \"#{pane_id} #{session_name}:#{window_index}.#{pane_index} #{pane_current_command}\"'"
    ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Everything is a command, and commands have a grammar" $ do
        p_ [class_ "lede"] $ do
            "Six days in, you have been running tmux commands through three different doors: key \
            \bindings, the "
            k "C-b :"
            " prompt, and the shell. They are the same commands. Today is the grammar they share, \
            \because from here on the course stops being about keys and starts being about writing \
            \things down."
        p_ "A command is a name, some flags, and some arguments:"
        sh
            [ "$ tmux set-option -g status-style bg=cyan"
            , "#      ^^^^^^^^^^ ^^ ^^^^^^^^^^^^ ^^^^^^^"
            , "#      name       flag  argument   argument"
            ]
        p_ $ do
            "Most commands have an alias ("
            c "set"
            ", "
            c "neww"
            ", "
            c "splitw"
            ", "
            c "lsp"
            ") and tmux also accepts any unambiguous prefix, telling you off when it is not:"
        sh
            [ "$ tmux n"
            , "ambiguous command: n, could be: new-session, new-window, next-window"
            ]
        p_ $ do
            c "tmux list-commands"
            " prints every command with its synopsis; "
            c "tmux list-commands split-window"
            " prints just one. That is a faster lookup than the man page when you know the command \
            \and have forgotten a flag."

    block "Semicolons, and the two levels of parsing" $ do
        p_ $ do
            "Commands can be chained. Inside tmux the separator is a bare semicolon; from a shell it \
            \has to survive the shell first:"
        sh
            [ "# inside tmux (C-b : or ~/.tmux.conf)"
            , "neww ; splitw -h ; splitw -v"
            , ""
            , "# from a shell — escape it, or quote it"
            , "$ tmux neww \\; splitw -h \\; splitw -v"
            , "$ tmux neww ';' splitw -h"
            ]
        gotcha $ p_ $ do
            "This is the single most common source of “why did my tmux script do nothing”. Without \
            \the backslash, "
            i_ "the shell"
            " eats the semicolon and runs "
            c "splitw"
            " as a separate program. And a chain stops at the first error: if "
            c "neww"
            " fails, nothing after it runs."
        p_ $ do
            "Inside a config file or a binding, a group of commands can also be wrapped in braces, \
            \which avoids escaping entirely and can span lines:"
        cfg
            [ "bind C-t {"
            , "    new-window -n scratch"
            , "    split-window -h"
            , "    select-pane -t 0"
            , "}"
            ]
        p_ $ do
            "Quoting inside tmux follows familiar rules: single quotes are literal, double quotes \
            \expand "
            c "$VARIABLES"
            " from the tmux global environment and "
            c "~"
            ", "
            c "#"
            " starts a comment, and a trailing "
            c "\\"
            " continues a line."

    block "Targets: how to name things" $ do
        p_ $ do
            "Nearly every command takes "
            c "-t"
            " (and sometimes "
            c "-s"
            " for a source). The value is a target string with up to three parts:"
        ascii
            [ "        session : window . pane"
            , "           |        |       |"
            , "      api:build.2   |       └── pane index, id, or token"
            , "      api:build     └────────── window index, name, id, or token"
            , "      api:          └────────── that session's current window"
            , "      :build        └────────── window 'build' of the current session"
            , "      :.2           └────────── pane 2 of the current window"
            ]
        fig
        p_ "Each part is resolved in a defined order, and knowing the order stops the surprises:"
        steps
            [ do
                b_ "An id, if it starts with a sigil."
                " "
                c "$1"
                " a session, "
                c "@4"
                " a window, "
                c "%7"
                " a pane. Unique for the life of the server."
            , do
                b_ "A special token."
                " For windows: "
                c "^"
                " lowest, "
                c "$"
                " highest, "
                c "!"
                " last, "
                c "+"
                " next, "
                c "-"
                " previous, "
                c "@"
                " current — with long forms "
                c "{start}"
                ", "
                c "{end}"
                ", "
                c "{last}"
                " and so on, and offsets like "
                c ":+2"
                ". For panes there are also "
                c "{top}"
                ", "
                c "{bottom-right}"
                ", "
                c "{up-of}"
                ", "
                c "{left-of}"
                " and friends."
            , do
                b_ "An index"
                ", if it is a number."
            , do
                b_ "A name"
                " — exact match first, then “starts with”, then a glob pattern. Prefix "
                c "="
                " to demand an exact match: "
                c "-t =test"
                " will not match "
                c "testing"
                "."
            ]
        sh
            [ "$ tmux display -p -t 'api:{end}' '#{window_name}'   # highest-numbered window"
            , "$ tmux display -p -t ':+'        '#{window_name}'   # next window along"
            , "$ tmux display -p -t ':.{bottom}' '#{pane_id}'      # bottom pane, this window"
            , "$ tmux send-keys  -t '%7' 'make test' Enter         # a specific pane, forever"
            ]
        why $ p_ $ do
            "When the target is not fully qualified, tmux "
            i_ "guesses which kind of thing you meant"
            " from the command. A "
            c "-t 1"
            " given to a pane command will try pane 1, then the active pane of window 1, then the \
            \active pane of the current window of session 1. That is wonderful at a prompt and \
            \dangerous in a script, which is why the man page says plainly: from a script, fully \
            \qualify ("
            c "-t:.1"
            ") or use ids."

    block "Ids, and why scripts need them" $ do
        p_ $ do
            "Sessions, windows and panes each get an id when they are created: "
            c "$0"
            ", "
            c "@0"
            ", "
            c "%0"
            ", counting up forever. They are never reused and never renumbered. A pane's own id is in \
            \its environment as "
            c "$TMUX_PANE"
            ", which is how a program inside a pane can address itself."
        sh
            [ "$ tmux lsp -a -F '#{pane_id} #{session_name}:#{window_index}.#{pane_index} #{pane_current_command}'"
            , "%0 api:1.0 zsh"
            , "%1 api:1.1 vim"
            , "%3 api:2.0 tail"
            , "%2 infra:1.0 zsh"
            ]
        p_ $ do
            "Note "
            c "%3"
            " sitting between "
            c "%1"
            " and "
            c "%2"
            " in position but not in id — panes were created in a different order from where they \
            \ended up. Index tells you where a pane is now; id tells you which pane it is."
        tip $ p_ $ do
            "The idiom for a script that creates something and then wants to keep talking to it is "
            c "-P -F"
            ": most creation commands will print the new object in a format of your choosing."
        sh
            [ "$ pane=$(tmux splitw -d -P -F '#{pane_id}' -t api:1)"
            , "$ tmux send-keys -t \"$pane\" 'tail -F log' Enter"
            ]

    block "Listing, filtering, and the shape of scripts" $ do
        p_ $ do
            "The "
            c "list-*"
            " commands all take "
            c "-F"
            " for the output format and "
            c "-f"
            " for a filter — both of which are formats, tomorrow's topic. Even without knowing the \
            \format language yet, the shape is worth seeing now:"
        sh
            [ "$ tmux ls -F '#{session_name}'                       # names, one per line"
            , "$ tmux lsw -a -f '#{window_zoomed_flag}'             # only zoomed windows"
            , "$ tmux lsp -a -f '#{m:*vim*,#{pane_current_command}}' -F '#{pane_id}'"
            ]
        p_ $ do
            "And "
            c "display-message -p"
            " is the general-purpose “evaluate this and print it” command — the "
            c "echo"
            " of tmux:"
        sh
            [ "$ tmux display -p '#{session_name} has #{session_windows} windows'"
            , "api has 4 windows"
            ]

cheat :: Html ()
cheat = do
    cfg
        [ "session:window.pane        # any part may be omitted"
        , "  $1  @4  %7               # ids: unique forever, never move — use these in scripts"
        , "  :^ :$ :! :+ :- :@        # first last previous next prev current window"
        , "  :.{top} :.{bottom-right} # pane by position;  {up-of} {left-of} relative"
        , "  -t =name                 # exact name match (no prefix, no glob)"
        , "  {mouse} = / {marked} ~   # where the mouse was / the marked pane"
        , ""
        , "tmux a \\; b \\; c            # chain from a shell (escape the ;)"
        , "a ; b ; c                  # chain inside tmux;  { } groups multi-line"
        , ""
        , "tmux display -p '#{pane_id}'          # evaluate and print"
        , "tmux lsp -a -F '...' -f '...'         # list, formatted, filtered"
        , "tmux splitw -d -P -F '#{pane_id}'     # create and print what you created"
        ]
