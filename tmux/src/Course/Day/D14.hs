module Course.Day.D14 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
  Day
    { dayNum = 14
    , dayTitle = "Environment, terminals, and the finished config"
    , daySubtitle = "The last sharp edges — stale ssh agents, true colour, extra servers — and what to read next."
    , dayMinutes = 35
    , dayLevel = "advanced"
    , dayManRef = "GLOBAL AND SESSION ENVIRONMENT, TERMINFO EXTENSIONS, CONTROL MODE"
    , dayTags = ["environment", "terminal", "servers"]
    , dayGoals =
        [ "fix the stale $SSH_AUTH_SOCK and $DISPLAY problem for good"
        , "get true colour, styled underlines and clipboard support working deliberately"
        , "run more than one tmux server, and know when that is the right answer"
        ]
    , dayDiagram = Just d14diagram
    , dayBody = body
    , dayKeys =
        [ ("C-b ~", "Show the message log — every error tmux has shown you and you missed.")
        ]
    , dayCmds =
        [ ("tmux -L work", "Use a separate server on the socket named " <> c "work" <> ".")
        , ("tmux -S /path/sock", "Use a server at an explicit socket path.")
        , ("tmux -f test.conf -L test", "Try a config in an isolated server — no risk to your real one.")
        , ("tmux -CC", "Control mode: a text protocol for programs that drive tmux.")
        , ("tmux -v", "Log the client and server to files in the current directory.")
        , ("show-environment -g", "The global environment new panes inherit.")
        , ("set-environment -g NAME value", "Set it. " <> c "-u" <> " unsets, " <> c "-h" <> " hides it from processes.")
        , ("show-messages", "The message log, behind " <> k "C-b ~" <> ". Alias " <> c "showmsgs" <> ".")
        , ("kill-server", "End everything on this socket.")
        ]
    , dayOpts =
        [ ("update-environment", "Which variables are refreshed from the client on attach.")
        , ("terminal-features", "Tell tmux what your terminal can do: RGB, clipboard, usstyle, hyperlinks…")
        , ("terminal-overrides", "Override individual terminfo capabilities. The older, lower-level lever.")
        , ("exit-empty", "Server exits when the last session goes. On by default.")
        , ("exit-unattached", "Server exits when the last client detaches. Off, and leave it off.")
        , ("default-shell", "The shell new panes run; " <> opt "default-command" <> " overrides it entirely.")
        , ("set-titles", "Set the outer terminal's title; " <> opt "set-titles-string" <> " is the format.")
        ]
    , dayConfig = day14config
    , dayDrills =
        [ "Reproduce the stale agent problem: attach to an old session over a new ssh \
          \connection and run " <> c "ssh-add -l" <> " in a pane that existed before. Then fix \
          \it with the symlink recipe below and confirm it survives a reattach."
        , "Check your colour depth honestly: "
            <> c "tmux display -p '#{client_termname} #{client_termfeatures}'"
            <> ", and outside tmux run a 24-bit colour test script in the same terminal. Only \
            \claim RGB in your config if the terminal really has it."
        , "Run a second server for something long-lived: "
            <> c "tmux -L bg new -d -s builds" <> ". Notice that " <> c "tmux ls" <> " does not \
            \see it at all — different socket, different world."
        , "Test a config change safely: " <> c "tmux -f /tmp/experiment.conf -L test new"
            <> ". Nothing you do in there can break the session you are working in."
        , "Look at " <> k "C-b ~" <> ". Every config error and failed command you have squinted \
          \at for half a second this fortnight is in that log."
        , "Read your finished " <> c "~/.tmux.conf" <> " end to end. Every line should be one \
          \you can justify; delete any that are not."
        , "Finally: run " <> c "man tmux" <> " and read the OPTIONS section properly. Two weeks \
          \ago it was an undifferentiated wall. It should now read as a reference to things you \
          \recognise — which was the actual goal of this course."
        ]
    , dayQuiz =
        [ ( "You reattach to a week-old session over a fresh ssh connection and "
              <> c "git push" <> " cannot reach your ssh agent. Why does "
              <> opt "update-environment" <> " not fix it?"
          , do
              p_ $ do
                "Because it updates the "
                i_ "session environment"
                " — the environment handed to processes created "
                b_ "from now on"
                ". Shells that were already running were given the old "
                c "$SSH_AUTH_SOCK"
                " when they started, and nothing can reach into a running process and change \
                \its environment."
              p_ $ do
                "The durable fix is indirection: point "
                c "$SSH_AUTH_SOCK"
                " at a stable symlink and re-point the symlink on each login. The variable in \
                \the old shell then still holds the right path."
          )
        , ( "Colours look wrong inside tmux but fine outside. Where do you look first?"
          , p_ $ do
              "At three things, in order. "
              c "$TERM"
              " outside tmux (it should describe your real terminal), "
              opt "default-terminal"
              " inside (it must be a "
              c "screen"
              " or "
              c "tmux"
              " derivative — "
              c "tmux-256color"
              "), and "
              opt "terminal-features"
              " (does tmux know your terminal can do RGB?). Setting "
              c "$TERM"
              " to something exotic inside tmux, which people do try, breaks things rather than \
              \fixing them."
          )
        , ( "When is a second tmux server the right answer?"
          , p_ $ do
              "When you want a genuinely separate world: long-running background jobs that must \
              \not be killed by a stray "
              c "kill-server"
              "; testing a configuration without endangering your working sessions; a service \
              \account's sessions kept apart from your own. "
              c "-L name"
              " picks a socket in the standard directory, "
              c "-S path"
              " an explicit path. It is not a way to organise projects — sessions already do \
              \that, and they can see each other."
          )
        , ( "What is control mode for, and why should you know it exists?"
          , p_ $ do
              c "tmux -CC"
              " turns tmux into a line-based protocol: commands in on stdin, blocks of output \
              \and asynchronous "
              c "%notification"
              " lines out. It is how a GUI terminal can render tmux windows as its own native \
              \tabs, and how a program can watch a server without polling."
              " You will rarely type it, but it explains a whole category of integrations — and "
              c "refresh-client -B"
              " lets such a client subscribe to a format and be told when it changes, which is \
              \the cleanest way to build a status widget outside tmux."
          )
        ]
    , dayCheat = cheat
    }

-- ---------------------------------------------------------------------------

d14diagram :: Diagram
d14diagram =
  (diagram
     "Environment inheritance: the server copies the environment at startup; update-environment \
     \refreshes named variables from the attaching client into the session environment; a new \
     \pane's environment is the merge of the global and session environments; already-running \
     \processes keep what they were given."
     body')
    { dgCaption = do
        "The thick arrow is the one that matters and the dashed one is the one that does not \
        \exist. Everything to the right of “a new pane” is decided "
        b_ "at creation time"
        ", which is why a fresh window picks up your new ssh agent and a five-day-old shell \
        \never will. Indirection through a stable symlink is the only fix that reaches \
        \backwards."
    , dgRankdir = "LR"
    , dgRanksep = "0.6"
    }
  where
    body' =
      T.unlines
        [ "  cli   [label=\"the attaching client\\n(a fresh ssh login)\", fillcolor=\"#f4efe6\"];"
        , "  ge    [label=\"the global\\nenvironment\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  se    [label=\"the session\\nenvironment\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  ue    [label=\"update-environment\\n(a list of names)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
        , "  np    [label=\"a NEW pane\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  op    [label=\"an already-running\\nprocess\", fillcolor=\"#f4efe6\"];"
        , ""
        , "  cli -> ue [label=\"  supplies values for\"];"
        , "  ue  -> se [label=\"  writes into\", penwidth=2.0];"
        , "  ge  -> np [label=\"  merged into\"];"
        , "  se  -> np [label=\"  merged into\\l  (and wins)\\l\"];"
        , "  se  -> op [label=\"  cannot reach\", style=dashed, color=\"#c08a8a\", fontcolor=\"#a2444a\"];"
        ]

-- ---------------------------------------------------------------------------

day14config :: [ConfBlock]
day14config =
  [ ConfBlock
      "Refresh these from the client every time a session is created or reattached, so a new\n\
      \window after a fresh ssh login has a working agent and display."
      "set -g update-environment \\\n\
      \  \"SSH_AUTH_SOCK SSH_CONNECTION SSH_AGENT_PID DISPLAY WAYLAND_DISPLAY XAUTHORITY\""
  , ConfBlock
      "TERM inside tmux must be a screen/tmux derivative - this is not the place to name your\n\
      \real terminal. Then tell tmux what that real terminal can actually do. Only claim RGB\n\
      \if it is true: check with tmux display -p '#{client_termfeatures}' first."
      "set -s default-terminal \"tmux-256color\"\n\
      \set -sa terminal-features \",*256col*:RGB:usstyle:clipboard:hyperlinks\"\n\
      \set -sa terminal-overrides \",*256col*:Tc\""
  , ConfBlock
      "OSC 52: let a copy inside tmux set the clipboard of the terminal you are sitting at,\n\
      \which is the only mechanism that works through ssh. 'external' also stops applications\n\
      \inside panes from silently overwriting your tmux buffers."
      "set -s set-clipboard external"
  , ConfBlock
      "Set the outer terminal's title from tmux, so a window switcher shows something useful."
      "set -g set-titles on\n\
      \set -g set-titles-string \"#S: #W - #{b:pane_current_path}\""
  ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
  block "The environment problem" $ do
    p_ [class_ "lede"] $ do
      "This is the tmux annoyance that survives longest, because it looks like a tmux bug and \
      \is really a fact about processes: you reattach to a session from a new ssh connection, \
      \and every shell that was already running still has the "
      i_ "old"
      " connection's "
      c "$SSH_AUTH_SOCK"
      ". Your agent is unreachable, "
      c "git push"
      " asks for a password, and nothing you do to tmux fixes the shells that already exist."
    fig
    p_ $ do
      "tmux keeps two environments: a "
      b_ "global"
      " one copied from wherever the server was started, and a "
      b_ "session"
      " one per session. A new pane gets the merge of the two, with the session winning. The "
      opt "update-environment"
      " option lists the variables to refresh from the attaching client into the session \
      \environment — so a "
      i_ "new"
      " window after a fresh login is fine."
    sh
      [ "$ tmux show-environment -g | grep SSH"
      , "$ tmux show-environment | grep SSH        # this session's"
      , "$ tmux set-environment -g FOO bar         # -u unsets, -h hides from processes"
      ]
    p_ "For the shells that already exist, the fix is indirection — put a stable path in the \
       \variable, and move the symlink on each login:"
    sh
      [ "# in ~/.bashrc or ~/.zshrc, before anything uses the agent"
      , "if [ -n \"$SSH_AUTH_SOCK\" ] && [ \"$SSH_AUTH_SOCK\" != \"$HOME/.ssh/agent.sock\" ]; then"
      , "  ln -sf \"$SSH_AUTH_SOCK\" \"$HOME/.ssh/agent.sock\""
      , "fi"
      , "export SSH_AUTH_SOCK=\"$HOME/.ssh/agent.sock\""
      ]
    p_ $ do
      "Now every shell — old and new — holds the same path, and re-pointing the symlink on \
      \login fixes them all at once. This is not a tmux feature; it is the standard answer, and \
      \it is worth the four lines."
    tip $ p_ $ do
      "The same trick applies to "
      c "$DISPLAY"
      " and "
      c "$WAYLAND_DISPLAY"
      " if you open GUI programs from inside long-lived sessions. And a variable marked hidden \
      \with "
      c "set-environment -h"
      " is kept by tmux for use in formats but never passed to a process — the right place for \
      \something you want in your status line and not in every child's environment."

  block "Telling tmux what your terminal can do" $ do
    p_ $ do
      "Two rules, and most colour problems are one of them being broken."
    steps
      [ do
          b_ "Outside tmux, "
          c "$TERM"
          " describes your real terminal ("
          c "xterm-256color"
          ", "
          c "alacritty"
          ", "
          c "foot"
          ")."
      , do
          b_ "Inside tmux, "
          c "$TERM"
          " must be a "
          c "screen"
          " or "
          c "tmux"
          " derivative — set by "
          opt "default-terminal"
          ", and "
          c "tmux-256color"
          " is the right value. tmux is emulating a terminal for the programs in the panes, and \
          \it has to describe "
          i_ "itself"
          " accurately, not the terminal it happens to be displayed on."
      ]
    p_ $ do
      "Between those, "
      opt "terminal-features"
      " is how tmux learns what the outer terminal can do. It is a list of glob patterns and \
      \feature names:"
    ascii
      [ "  RGB          24-bit colour           usstyle    coloured / styled underlines"
      , "  clipboard    OSC 52 clipboard        hyperlinks OSC 8 links"
      , "  cstyle       set the cursor style    ccolour    set the cursor colour"
      , "  focus        focus reporting         title      set the window title"
      , "  sync         synchronised updates    sixel      SIXEL graphics"
      , "  margins  overline  strikethrough  rectfill  extkeys  progressbar  osc7"
      ]
    cfg
      [ "set -sa terminal-features \",*256col*:RGB:usstyle:clipboard:hyperlinks\""
      , "set -sa terminal-overrides \",*256col*:Tc\"   # the older, terminfo-level lever"
      ]
    p_ $ do
      "Note the "
      c "-a"
      ": these are arrays and you want to add to them, not replace tmux's own entries. Check \
      \what tmux believes with "
      c "tmux display -p '#{client_termfeatures}'"
      ", and do not claim a feature your terminal does not have — the failure mode is garbage \
      \on screen rather than a graceful fallback."
    gotcha $ p_ $ do
      "A related annoyance with a one-line fix: if Escape feels sluggish in vim inside tmux, \
      \that is "
      opt "escape-time"
      " (Day 5). If function keys or modified keys arrive wrong, look at "
      opt "extended-keys"
      " and the "
      c "extkeys"
      " terminal feature. And "
      k "C-b ~"
      " shows tmux's message log, which is where the error you half-saw an hour ago still is."

  block "More than one server" $ do
    p_ $ do
      "Everything in this course has assumed one server on the default socket. "
      c "-L name"
      " uses a different socket in the same directory; "
      c "-S path"
      " an explicit path. Servers cannot see each other at all — separate sessions, separate \
      \options, separate everything."
    sh
      [ "$ tmux -L bg new -d -s builds        # a server for long-running jobs"
      , "$ tmux -L bg ls                      # only visible with the same -L"
      , "$ tmux -f /tmp/try.conf -L test new  # test a config in isolation"
      , "$ tmux -L test kill-server           # and throw it away"
      ]
    p_ $ do
      "That third line is the one to remember. Trying a new configuration in a throwaway server \
      \means never again wondering whether the thing you just pasted is about to eat the \
      \session you have been running for three weeks."
    p_ $ do
      "Two server options govern the lifecycle: "
      opt "exit-empty"
      " (on by default — the server exits when the last session goes) and "
      opt "exit-unattached"
      " (off, and should stay off; turning it on kills your sessions when you detach, which is \
      \the opposite of the point). For a server that must survive with nothing in it, turn "
      opt "exit-empty"
      " off and start it with "
      c "tmux start-server"
      "."

  block "Control mode, briefly" $ do
    p_ $ do
      c "tmux -CC"
      " is not for humans. It turns the client into a line protocol: you send commands, tmux \
      \replies with "
      c "%begin"
      " … "
      c "%end"
      " blocks and emits asynchronous notifications — "
      c "%output"
      ", "
      c "%window-add"
      ", "
      c "%session-changed"
      ", "
      c "%layout-change"
      " — whenever anything happens."
    p_ $ do
      "It exists so that a graphical terminal can present tmux windows as its own native tabs, \
      \and so that programs can drive a server without screen-scraping. The piece worth \
      \remembering is "
      c "refresh-client -B name:what:format"
      ": a control-mode client can subscribe to a format and be notified when its value \
      \changes, which is how you build an external status widget that does not poll."

  block "The finished configuration" $ do
    p_ $ do
      "Your "
      c "~/.tmux.conf"
      " is now perhaps sixty lines, assembled over ten days, and every block has a comment \
      \saying why it is there. The whole file is "
      a_ [href_ "../tmux.conf"] "here"
      " if you want to diff it against yours."
    p_ $ do
      "Read it once, end to end, and delete anything you cannot justify. A configuration you \
      \understand and half-use beats one you copied and are afraid to touch — that is the \
      \entire argument for having built it this way instead of pasting somebody's 400-line \
      \dotfile on Day 1."

  block "What comes next" $ do
    p_ "Three honest directions, in the order I would take them."
    defs
      [ ( "Live in it for a month"
        , "Nothing here is knowledge; it is all habit. The keys you have not used by October \
          \are the keys you did not need, and the ones you fumble are the ones to rebind."
        )
      , ( "Write the plugin instead of installing it"
        , do
            "The popular tmux plugins are mostly assemblies of what Days 9 to 13 covered. A \
            \session manager is a popup and "
            c "switch-client"
            ". A layout restorer is "
            c "#{window_layout}"
            " and a script. If you do want the ecosystem, "
            c "tpm"
            " and "
            c "tmux-resurrect"
            " are the well-trodden ones — but read them first; they are short, and now they \
            \will read as ordinary tmux commands."
        )
      , ( "Read the man page properly"
        , do
            "Specifically the OPTIONS section, and the FORMATS variable table. Two weeks ago \
            \both were walls of text. They should now read as reference material for a system \
            \you know the shape of. That was the real objective here: not fourteen lists of \
            \keys, but enough structure that "
            c "man tmux"
            " becomes usable."
        )
      ]
    p_ $ do
      b_ "That is the course."
      " Fourteen days ago tmux was a thing that kept shells alive over ssh. It is now a small, \
      \consistent system you can bend: a server holding sessions, a command language, a format \
      \language, key tables, hooks, and a config you wrote yourself."

cheat :: Html ()
cheat = do
  cfg
    [ "update-environment \"SSH_AUTH_SOCK … DISPLAY\"   # refreshed on attach — for NEW panes"
    , "  old shells keep the old value: use a stable ~/.ssh/agent.sock symlink"
    , ""
    , "default-terminal tmux-256color                 # inside tmux: a screen/tmux TERM"
    , "set -sa terminal-features \",*256col*:RGB:usstyle:clipboard:hyperlinks\""
    , "tmux display -p '#{client_termfeatures}'       # what tmux believes"
    , ""
    , "tmux -L name …          # a separate server (own socket, own world)"
    , "tmux -f try.conf -L test new    # test a config with nothing at risk"
    , "tmux -CC                # control mode; refresh-client -B subscribes to a format"
    , "C-b ~                   # the message log — where the errors you missed went"
    ]
