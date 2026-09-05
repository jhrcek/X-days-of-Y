module Course.Day.D05 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
  Day
    { dayNum = 5
    , dayTitle = "Options and your first config"
    , daySubtitle = "Four scopes, one inheritance chain, and a tmux.conf you can defend."
    , dayMinutes = 35
    , dayLevel = "essential"
    , dayManRef = "OPTIONS, FILES"
    , dayTags = ["tmux.conf", "options", "scopes"]
    , dayGoals =
        [ "say exactly which of the four option scopes a setting belongs to, and why"
        , "change an option for one pane, one window, one session, or everything"
        , "keep a ~/.tmux.conf that you understand line by line, and reload it with one key"
        ]
    , dayDiagram = Just d5diagram
    , dayBody = body
    , dayKeys =
        [ ("C-b C", "Customize mode: browse and change every option and key, with descriptions.")
        , ("C-b R", "Reload " <> c "~/.tmux.conf" <> " — after you add today's binding.")
        ]
    , dayCmds =
        [ ("set-option -g name value", "Set a global session option. Alias " <> c "set" <> ".")
        , ("set-option -w name value", "Set a window option (for the current window).")
        , ("set-option -p name value", "Set a pane option (for the current pane).")
        , ("set-option -s name value", "Set a server option.")
        , ("set-option -u name", "Unset, so the value is inherited again.")
        , ("set-option -a name value", "Append to a string or style option instead of replacing it.")
        , ("show-options -g", "Show global session options. Alias " <> c "show" <> ".")
        , ("show-options -A", "Show them including inherited values, marked with " <> c "*" <> ".")
        , ("show-options -gv history-limit", "Print just the value of one option.")
        , ("source-file ~/.tmux.conf", "Run a file of tmux commands now. Alias " <> c "source" <> ".")
        , ("customize-mode", "The interactive option browser behind " <> k "C-b C" <> ".")
        ]
    , dayOpts =
        [ ("base-index", "Index the first window gets. Default 0.")
        , ("pane-base-index", "Index the first pane gets. Default 0. A window option.")
        , ("renumber-windows", "Close the gaps in window indices when one is killed.")
        , ("escape-time", "Milliseconds tmux waits to decide whether Escape began a key sequence.")
        , ("focus-events", "Pass terminal focus in/out through to the programs in panes.")
        , ("display-time", "How long status line messages stay up. 750 ms by default.")
        , ("default-terminal", "The " <> c "$TERM" <> " new panes get. Must be a screen/tmux derivative.")
        ]
    , dayConfig = day5config
    , dayDrills =
        [ "Create " <> c "~/.tmux.conf" <> " with today's blocks. Then load it into a running \
          \server: " <> k "C-b :" <> " " <> c "source ~/.tmux.conf" <> ". From now on "
            <> k "C-b R" <> " does it."
        , "Break it on purpose: add the line " <> c "set -g nonsense 1" <> " and reload. Read \
          \where the error appears and how the rest of the file still runs."
        , "Prove the scope chain. Run " <> c "set -w window-style bg=#202020" <> " then "
            <> c "set -p window-style bg=#402020" <> " in one pane of a split. The pane option \
            \wins for that pane; the window option covers the rest. Undo both with "
            <> c "set -pu window-style" <> " and " <> c "set -wu window-style" <> "."
        , "Compare " <> c "tmux show -gw" <> " with " <> c "tmux show -w" <> " in a window \
          \where you have set something, then with " <> c "tmux show -wA" <> " and find the "
            <> c "*" <> " markers on inherited values."
        , "Open " <> k "C-b C" <> ". Navigate to an option, press " <> k "v" <> " to read its \
          \description, " <> k "s" <> " to set it, " <> k "u" <> " to unset. This is the \
          \fastest way to explore the several hundred options without leaving tmux."
        , "Set a user option and read it back: " <> c "tmux set -g @project api" <> " then "
            <> c "tmux show -gv @project" <> ". Day 9 uses these inside formats."
        , "Kill the server (" <> c "tmux kill-server" <> ") and start again, to confirm your \
          \config loads cleanly from cold and not just when re-sourced."
        ]
    , dayQuiz =
        [ ( "You edit " <> c "~/.tmux.conf" <> " and nothing changes. Why?"
          , p_ $ do
              "The file is read exactly once, when the "
              b_ "server"
              " starts. Detaching and re-attaching does not restart the server; only killing \
              \every session does. Reload deliberately with "
              c "source-file"
              " — which is why the first thing today's config adds is a key bound to it."
          )
        , ( "You re-source your config after deleting a " <> c "bind" <> " line, but the key \
            \still works. Why?"
          , p_ $ do
              "Because sourcing a file "
              i_ "runs the commands in it"
              "; it does not diff the file against the server's state. Removing a line removes \
              \nothing that already happened. To take a binding away you must actively "
              c "unbind-key"
              " it, or restart the server. The same applies to options: deleting a "
              c "set"
              " line leaves the value it set in place."
          )
        , ( "What is the difference between " <> c "set -g mode-keys vi" <> " and "
              <> c "set -wg mode-keys vi" <> "?"
          , p_ $ do
              "Nothing, in practice. "
              opt "mode-keys"
              " is a window option, and when the name is unambiguous tmux infers the scope for \
              \you, so the "
              c "-w"
              " is redundant. Being explicit still pays: it documents which scope you meant, \
              \and it is required for user options ("
              c "@name"
              "), where tmux cannot guess."
          )
        , ( "Which scope for: " <> opt "status-style" <> ", " <> opt "escape-time" <> ", "
              <> opt "synchronize-panes" <> ", " <> opt "automatic-rename" <> "?"
          , p_ $ do
              opt "status-style"
              " is a session option — the status line belongs to the session you are looking \
              \at. "
              opt "escape-time"
              " is a server option; it is about how tmux reads the terminal, which is global. "
              opt "synchronize-panes"
              " is a pane option (usually set at window scope so it applies to all of them). "
              opt "automatic-rename"
              " is a window option, because names belong to windows."
          )
        ]
    , dayCheat = cheat
    }

-- ---------------------------------------------------------------------------

d5diagram :: Diagram
d5diagram =
  (diagram
     "Option lookup: a pane option falls back to the window option, which falls back to global \
     \window options; a session option falls back to global session options; server options \
     \stand alone. Configuration files and set-option commands write into these."
     body')
    { dgCaption = do
        "Read the arrows as “falls back to”. This is the whole of the options system, and it \
        \explains the flags: "
        c "-p"
        " and "
        c "-w"
        " write to the left column, "
        c "-g"
        " writes to the bottom of a column instead of the top, "
        c "-s"
        " writes to the server, and "
        c "-u"
        " deletes a value so the next arrow takes over."
    , dgRankdir = "TB"
    , dgRanksep = "0.4"
    , dgNodesep = "0.45"
    }
  where
    body' =
      T.unlines
        [ "  conf  [label=\"~/.tmux.conf\\n(a list of tmux commands)\", fillcolor=\"#f4efe6\"];"
        , "  setc  [label=\"a set-option command\", fillcolor=\"#f4efe6\"];"
        , ""
        , "  po    [label=\"pane options\\n(set -p)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  wo    [label=\"window options\\n(set -w)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  gwo   [label=\"global window options\\n(set -wg)\"];"
        , "  so    [label=\"session options\\n(set)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  gso   [label=\"global session options\\n(set -g)\"];"
        , "  svo   [label=\"server options\\n(set -s)\"];"
        , ""
        , "  conf -> setc [label=\"  contains\"];"
        , "  setc -> po   [style=dotted, arrowhead=empty];"
        , "  setc -> so   [style=dotted, arrowhead=empty];"
        , "  setc -> svo  [style=dotted, arrowhead=empty, label=\"  writes to\"];"
        , "  po  -> wo    [label=\"  falls back to\"];"
        , "  wo  -> gwo   [label=\"  falls back to\"];"
        , "  so  -> gso   [label=\"  falls back to\"];"
        , "  { rank=same; po; so; svo; }"
        ]

-- ---------------------------------------------------------------------------

day5config :: [ConfBlock]
day5config =
  [ ConfBlock
      "Reload the config without restarting the server. Bind it first, because you will use\n\
      \it constantly while building the rest of this file."
      "bind -N \"Reload ~/.tmux.conf\" R \\\n\
\  source-file ~/.tmux.conf \\; display-message \"tmux.conf reloaded\""
  , ConfBlock
      "Count windows and panes from 1. The keyboard's number row starts at 1, and reaching\n\
      \past 0 for the first window is a small tax paid several hundred times a day."
      "set -g  base-index 1\n\
      \set -wg pane-base-index 1\n\
      \set -g  renumber-windows on"
  , ConfBlock
      "2000 lines of scrollback is a 1990s default. This costs a few MB per pane at worst."
      "set -g history-limit 50000"
  , ConfBlock
      "Copy mode keys. Choose the one your fingers already know; the default depends on\n\
      \$EDITOR, which means it silently differs between machines."
      "set -wg mode-keys vi"
  , ConfBlock
      "Mouse: click to select a pane or window, drag borders to resize, wheel to scroll into\n\
      \copy mode. Shift-drag still gives you the terminal's own selection when you want it."
      "set -g mouse on"
  , ConfBlock
      "How long tmux waits after Escape to see if it was really Alt-something. Older tmux\n\
      \defaulted to 500 ms, which made vim feel broken; 3.x already uses 10, so this line is\n\
      \insurance against sitting down at an older machine."
      "set -s escape-time 10"
  , ConfBlock
      "Let programs in panes see focus gained/lost, so things like vim's autoread work."
      "set -s focus-events on"
  , ConfBlock
      "Status line messages vanish after 750 ms by default, which is not long enough to read\n\
      \an error you did not expect."
      "set -g display-time 2000"
  ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
  block "A config file is just a list of commands" $ do
    p_ [class_ "lede"] $ do
      "There is no configuration language. "
      c "~/.tmux.conf"
      " is a file of the same commands you have been typing at "
      k "C-b :"
      " all week, executed top to bottom when the server starts. Every line in it could equally \
      \be typed at a prompt, and every command you type at a prompt could equally be a line in \
      \it."
    p_ $ do
      "tmux looks for "
      c "/etc/tmux.conf"
      " first, then your own file at "
      c "~/.tmux.conf"
      " or "
      c "$XDG_CONFIG_HOME/tmux/tmux.conf"
      " or "
      c "~/.config/tmux/tmux.conf"
      ". A different file can be forced with "
      c "tmux -f other.conf"
      ", which is the safe way to try someone else's configuration without touching yours."
    gotcha $ do
      p_ $ do
        b_ "The file is read once, when the server starts."
        " Not on attach, not on new-session. If nothing seems to change after an edit, the \
        \server from this morning is still running with this morning's settings."
      p_ $ do
        "And re-sourcing is not the same as restarting: "
        c "source-file"
        " runs the file's commands again, but it cannot undo commands you have deleted from the \
        \file. Removing a "
        c "bind"
        " line leaves the binding in place until you "
        c "unbind"
        " it or kill the server. When a config starts behaving strangely, "
        c "tmux kill-server"
        " and start clean before debugging."

  block "Four scopes" $ do
    p_ $ do
      "Every option belongs to one or more of four scopes, and this is the single thing that \
      \makes the options section of the man page navigable."
    defs
      [ ("server " <> c "-s", "One set for the whole server. Terminal handling, timings, \
            \clipboard behaviour: things that are not about any particular session.")
      , ("session " <> c "-g" <> " or per-session", "Status line, prefix key, mouse, history \
            \limit. Sessions that do not set one of these inherit the global value.")
      , ("window " <> c "-w", "Layout sizes, monitoring, copy mode keys, automatic renaming.")
      , ("pane " <> c "-p", "Styles, cursor, " <> opt "synchronize-panes" <> ", "
            <> opt "remain-on-exit" <> ". Pane options fall back to the window's value.")
      ]
    fig
    p_ $ do
      "The practical consequence of that last arrow: "
      b_ "any pane option can be set at window scope to cover every pane in the window"
      ". The man page's own example is worth stealing —"
    sh
      [ "$ tmux set -w  window-style bg=red      # every pane in this window"
      , "$ tmux set -pt :.0 window-style bg=blue # except pane 0"
      ]
    p_ $ do
      c "show-options -A"
      " is the debugging tool: it lists inherited values too, marking them with an asterisk, so \
      \you can see at a glance whether a value is really set here or is coming from further \
      \down the chain."

  block "Reading the options you have" $ do
    sh
      [ "$ tmux show -g | head            # global session options"
      , "$ tmux show -gw                  # global window options"
      , "$ tmux show -s                   # server options"
      , "$ tmux show -gv history-limit    # just the value"
      , "$ tmux show -wA                  # this window, inherited values marked with *"
      ]
    tip $ p_ $ do
      "Better than any of those: "
      k "C-b C"
      " opens "
      b_ "customize mode"
      ", a browsable tree of every option and every key binding with its current value. "
      k "v"
      " shows the option's own description, "
      k "s"
      " sets it, "
      k "S"
      " sets it globally, "
      k "u"
      " unsets it, "
      k "d"
      " restores the default. It is a live man page for the options section, and it is \
      \criminally under-used."

  block "User options" $ do
    p_ $ do
      "Any option whose name starts with "
      c "@"
      " is yours. tmux stores it and otherwise ignores it, at any scope:"
    sh
      [ "$ tmux set -g @project api"
      , "$ tmux show -gv @project"
      , "api"
      ]
    p_ $ do
      "These are how plugins keep their settings, and how you attach a little metadata to a \
      \session or window and then use it in a status line format on Day 9 — for example \
      \colouring a window by an "
      c "@env"
      " tag you set when you created it."

  block "Today's file, defended line by line" $ do
    p_ $ do
      "Below is the beginning of the configuration this course builds. Nothing here is \
      \cosmetic and nothing here is copied from a dotfiles repository — every block gets a \
      \comment saying why it exists, because in eight months that comment is the only thing \
      \standing between you and a config you are afraid to touch."
    p_ $ do
      "One deliberate omission: the "
      b_ "prefix key"
      " is still "
      k "C-b"
      ". Plenty of people remap it to "
      k "C-a"
      " (which then collides with readline's beginning-of-line) or "
      k "C-Space"
      ". Both are reasonable; neither is urgent. If you want to, the incantation is in the man \
      \page's own examples:"
    cfg
      [ "# only if you really want it — and then live with it everywhere"
      , "set -g prefix C-a"
      , "unbind C-b"
      , "bind C-a send-prefix"
      ]
    note $ p_ $ do
      "tmux config files also support line continuation with "
      c "\\"
      ", comments with "
      c "#"
      ", braces "
      c "{ }"
      " for multi-line command arguments, and conditionals with "
      c "%if"
      " / "
      c "%else"
      " / "
      c "%endif"
      " whose condition is a format. That last one is how a single config file copes with a \
      \laptop and three servers. Day 9 explains what can go in the condition."

cheat :: Html ()
cheat = do
  cfg
    [ "set -s  name value   # server scope   (escape-time, focus-events, terminal-*)"
    , "set -g  name value   # global session (prefix, mouse, status-*, history-limit)"
    , "set -wg name value   # global window  (mode-keys, monitor-*, automatic-rename)"
    , "set -p  name value   # this pane only (styles, synchronize-panes, remain-on-exit)"
    , "set -u  name         # unset -> inherit again;   set -a  appends to a string"
    , ""
    , "show -g / -gw / -s   # what is set     show -A  marks inherited values with *"
    , "C-b C                # customize mode: browse everything, with descriptions"
    , "C-b R                # your reload binding (source-file ~/.tmux.conf)"
    ]
  p_ $ do
    b_ "Chain: "
    "pane → window → global window. Session → global session. Server stands alone."
