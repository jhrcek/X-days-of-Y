module Course.Day.D04 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
  Day
    { dayNum = 4
    , dayTitle = "Copy mode and buffers"
    , daySubtitle = "Scrollback, search, selection — and getting text back out again."
    , dayMinutes = 35
    , dayLevel = "essential"
    , dayManRef = "WINDOWS AND PANES (copy mode), BUFFERS"
    , dayTags = ["copy mode", "scrollback", "clipboard"]
    , dayGoals =
        [ "scroll and search a pane's history without touching the mouse"
        , "select text — by character, line or rectangle — and paste it into another pane"
        , "get a pane's output into a file, a shell command, or the system clipboard"
        ]
    , dayDiagram = Just d4diagram
    , dayBody = body
    , dayKeys =
        [ ("C-b [", "Enter copy mode at the bottom of the history.")
        , ("C-b PageUp", "Enter copy mode already scrolled one page up.")
        , ("C-b ]", "Paste the most recent buffer into this pane.")
        , ("C-b =", "Choose which buffer to paste, from a list with previews.")
        , ("C-b #", "List the paste buffers.")
        , ("C-b -", "Delete the most recent buffer.")
        , ("q", "In copy mode: leave. (" <> k "Escape" <> " in emacs mode.)")
        , ("/ ?", "vi mode: search forward / backward; " <> k "n" <> " and " <> k "N" <> " repeat.")
        , ("C-s C-r", "emacs mode: incremental search forward / backward.")
        , ("Space", "vi mode: start a selection. " <> k "C-Space" <> " in emacs mode.")
        , ("v", "vi mode: toggle rectangle (block) selection. " <> k "R" <> " in emacs mode.")
        , ("Enter", "vi mode: copy the selection and leave. " <> k "M-w" <> " in emacs mode.")
        , ("g G", "vi mode: top / bottom of the history.")
        ]
    , dayCmds =
        [ ("copy-mode", "Enter copy mode; " <> c "-u" <> " starts a page up, " <> c "-e" <> " exits at the bottom.")
        , ("send-keys -X begin-selection", "How every copy-mode key is implemented. " <> c "-X" <> " means “to the mode”.")
        , ("list-buffers", "Show the buffer stack. Alias " <> c "lsb" <> ".")
        , ("set-buffer \"text\"", "Put a literal string into a buffer from a script.")
        , ("load-buffer file", "Read a file into a buffer (" <> c "-" <> " for stdin).")
        , ("save-buffer file", "Write a buffer out to a file (" <> c "-" <> " for stdout).")
        , ("show-buffer", "Print the newest buffer.")
        , ("paste-buffer -t :1.0", "Paste into a specific pane, not necessarily this one.")
        , ("delete-buffer -b name", "Remove one buffer.")
        , ("capture-pane -p -S -3000", "Dump the last 3000 lines of history to stdout.")
        , ("clear-history", "Throw away a pane's scrollback. Alias " <> c "clearhist" <> ".")
        ]
    , dayOpts =
        [ ("mode-keys", "vi or emacs key bindings inside copy mode. Default emacs.")
        , ("history-limit", "Lines of scrollback kept per pane. Default 2000, which is stingy.")
        , ("copy-command", "Shell command that bare " <> c "copy-pipe" <> " pipes to — your clipboard tool.")
        , ("set-clipboard", "Whether tmux sets the terminal's clipboard with OSC 52.")
        , ("word-separators", "What counts as a word boundary for " <> k "w" <> " and " <> k "b" <> ".")
        , ("wrap-search", "Whether searches wrap around the end of the history. On by default.")
        ]
    , dayConfig = []
    , dayDrills =
        [ "Run something with a lot of output (" <> c "find /usr -type f | head -5000" <> "). \
          \Enter copy mode with " <> k "C-b [" <> " and look at the top right corner: that is \
          \your position and the size of the history."
        , "Search backwards for a string you know is up there. In emacs mode that is "
            <> k "C-r" <> "; in vi mode " <> k "?" <> ". Then " <> k "n" <> " a few times."
        , "Select three lines and copy them: start a selection, move, then finish with "
            <> k "Enter" <> " (vi) or " <> k "M-w" <> " (emacs). Paste them into another pane \
            \with " <> k "C-b ]" <> "."
        , "Do it again with a rectangle: turn on block selection (" <> k "v" <> " in vi, "
            <> k "R" <> " in emacs) and grab a column out of some tabular output."
        , "Copy three different things in a row, then press " <> k "C-b #" <> " and "
            <> k "C-b =" <> ". Buffers are a stack, not a single clipboard."
        , "Capture without copy mode: " <> c "tmux capture-pane -p -S - > /tmp/pane.txt"
            <> " then look at the file. This is the one that matters for scripts and bug \
            \reports."
        , "Decide today whether you are a vi or an emacs person in copy mode, and note it — \
          \tomorrow's config sets " <> opt "mode-keys" <> " accordingly."
        , "Find out whether your terminal takes OSC 52: copy something in copy mode, then try \
          \to paste it into a GUI application. If nothing arrives, read the clipboard section \
          \again — you will want " <> opt "copy-command" <> " tomorrow."
        ]
    , dayQuiz =
        [ ( "You press " <> k "C-b [" <> ", scroll up, and now your usual keys do strange \
            \things. What is going on?"
          , p_ $ do
              "The pane is "
              i_ "in a mode"
              ". While a pane is in copy mode its keys come from the "
              c "copy-mode"
              " or "
              c "copy-mode-vi"
              " key table instead of going to the program, and each of those bindings runs "
              c "send-keys -X "
              "something. Leave with "
              k "q"
              " (vi) or "
              k "Escape"
              " (emacs) and the keys go back to your shell."
          )
        , ( "Why does copying inside tmux over ssh often not reach your laptop's clipboard, and \
            \what are the two ways out?"
          , do
              p_ "Because the copy landed in a tmux paste buffer on the remote server, which \
                 \knows nothing about your local clipboard."
              p_ $ do
                "Route one is OSC 52: with "
                opt "set-clipboard"
                " on, tmux emits an escape sequence asking the terminal you are sitting at to \
                \set its own clipboard, which works through ssh because it travels as terminal \
                \output. Route two is "
                opt "copy-command"
                " — pipe the selection to a local tool ("
                c "wl-copy"
                ", "
                c "xclip -sel c"
                ", "
                c "pbcopy"
                "), which only helps when tmux is running on the same machine as the display."
          )
        , ( "What is the difference between " <> c "capture-pane" <> " and copy mode?"
          , p_ $ do
              "None conceptually — both put pane content into a buffer — but "
              c "capture-pane"
              " is non-interactive, so it belongs in scripts. "
              c "capture-pane -p -S -"
              " prints the whole history to stdout; without "
              c "-p"
              " it fills a buffer instead. It is the right tool for “put the last 200 lines of \
              \that failing job into a file” and it needs nobody sitting at the keyboard."
          )
        , ( "Your scrollback runs out after a couple of screens of a big build. Fix?"
          , p_ $ do
              opt "history-limit"
              " defaults to 2000 lines "
              i_ "per pane"
              ". Raise it in "
              c "~/.tmux.conf"
              " — 50000 is unremarkable on a modern machine. Note that the limit is applied \
              \when a pane is created, so raising it does not retroactively lengthen the \
              \history of panes that already exist."
          )
        ]
    , dayCheat = cheat
    }

-- ---------------------------------------------------------------------------

d4diagram :: Diagram
d4diagram =
  (diagram
     "A pane keeps a history; copy mode gives it a cursor and a selection; a copy command turns \
     \the selection into a paste buffer, which can be pasted into a pane, saved to a file, \
     \piped to a command, or pushed to the terminal clipboard."
     body')
    { dgCaption = do
        "Everything on this page is one path through this diagram. Note that the "
        b_ "paste buffer"
        " is the hub: copy mode is only one of four ways to fill it ("
        c "set-buffer"
        ", "
        c "load-buffer"
        " and "
        c "capture-pane"
        " are the others) and pasting is only one of four ways to empty it."
    , dgRankdir = "TB"
    , dgRanksep = "0.42"
    , dgNodesep = "0.3"
    }
  where
    body' =
      T.unlines
        [ "  pane  [label=\"a pane\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  hist  [label=\"its history\\n(history-limit lines)\"];"
        , "  mode  [label=\"copy mode\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  cur   [label=\"a cursor\"];"
        , "  sel   [label=\"a selection\\n(char, line, rectangle)\"];"
        , "  buf   [label=\"a paste buffer\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
        , "  cap   [label=\"capture-pane\", fillcolor=\"#f4efe6\"];"
        , "  file  [label=\"a file\", fillcolor=\"#f4efe6\"];"
        , "  cmd   [label=\"a shell command\", fillcolor=\"#f4efe6\"];"
        , "  clip  [label=\"the terminal\\nclipboard\", fillcolor=\"#f4efe6\"];"
        , ""
        , "  pane -> hist [label=\"  keeps\"];"
        , "  hist -> mode [label=\"  is browsed in\"];"
        , "  mode -> cur  [label=\"  has\"];"
        , "  cur  -> sel  [label=\"  extends\"];"
        , "  sel  -> buf  [label=\"  copy-selection\\l  makes\\l\"];"
        , "  cap  -> buf  [label=\"  fills\"];"
        , "  file -> buf  [label=\"  load-buffer\"];"
        , "  buf  -> pane [label=\"  paste-buffer\\l  inserts into\\l\"];"
        , "  buf  -> file [label=\"  save-buffer\"];"
        , "  buf  -> cmd  [label=\"  copy-pipe\\l  feeds\\l\"];"
        , "  buf  -> clip [label=\"  set-clipboard\\l  (OSC 52)\\l\"];"
        ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
  block "A pane can be in a mode" $ do
    p_ [class_ "lede"] $ do
      "Normally your keystrokes go straight through to the program in the pane. Sometimes tmux \
      \needs the keyboard for itself — to let you scroll, to let you pick from a list — and for \
      \that a pane can be put into a "
      b_ "mode"
      ". Copy mode is the one you will live in; view mode (read-only output, as when you press "
      k "C-b ?"
      ") and choose mode (the tree behind "
      k "C-b w"
      ") are the same machinery."
    p_ $ do
      "Enter with "
      k "C-b ["
      ". A position indicator appears in the top-right corner showing where you are and how \
      \many lines of history exist. Leave with "
      k "q"
      " in vi mode or "
      k "Escape"
      " in emacs mode."
    termWin
      "copy mode"
      [ "make[2]: Entering directory '/home/j/src/app'         [42/1337]"
      , "  CC    src/parse.c"
      , "  CC    src/render.c"
      , "src/render.c:88:12: warning: unused variable 'tmp'"
      , "  CC    src/main.c"
      ]
    p_ $ do
      "The "
      c "[42/1337]"
      " is that indicator: 42 lines up, 1337 lines of history behind this pane."
    fig

  block "vi or emacs, decide once" $ do
    p_ $ do
      "Copy mode has two complete key sets, chosen by the "
      opt "mode-keys"
      " option. The default is "
      c "emacs"
      " unless your "
      c "$EDITOR"
      " or "
      c "$VISUAL"
      " contains “vi”, in which case tmux quietly gives you vi keys. Since that depends on your \
      \environment, it is worth setting explicitly tomorrow so that your muscle memory is the \
      \same on every machine."
    cols
      [ do
          h3_ "vi keys"
          cfg
            [ "h j k l      move             g / G   top / bottom"
            , "w b e        by word          C-u/C-d half page"
            , "0 $ ^        line ends        H M L   top/mid/bottom line"
            , "/ ?          search fwd/back  n / N   repeat / reverse"
            , "f x  t x     jump to char x   ; ,     repeat jump"
            , "Space        start selection  v       rectangle toggle"
            , "V            select line      o       swap selection end"
            , "Enter        copy and exit    q       leave"
            ]
      , do
          h3_ "emacs keys"
          cfg
            [ "arrows       move             M-< / M->  top / bottom"
            , "M-f M-b      by word          M-Up/M-Down half page"
            , "C-a C-e      line ends        M-r        middle line"
            , "C-s / C-r    incremental search (press again to repeat)"
            , "C-Space      start selection  R          rectangle toggle"
            , "M-w          copy and exit    Escape     leave"
            , "C-g          clear selection"
            ]
      ]
    why $ p_ $ do
      "These are not hardcoded. Every one of them is an ordinary binding in the "
      c "copy-mode"
      " or "
      c "copy-mode-vi"
      " key table whose command is "
      c "send-keys -X something"
      " — "
      c "send-keys -X history-top"
      ", "
      c "send-keys -X begin-selection"
      ", and so on. Run "
      c "tmux list-keys -T copy-mode-vi"
      " and you can read the entire mode as data. That also means you can add your own: Day 8 \
      \binds "
      k "Y"
      " to copy a whole line into the system clipboard."

  block "Searching, which is the actual reason to be here" $ do
    p_ $ do
      "Scrolling is a poor way to find something in 20,000 lines. In vi mode "
      k "/"
      " searches forward and "
      k "?"
      " backward, both taking a regular expression; "
      k "n"
      " and "
      k "N"
      " repeat and reverse. In emacs mode "
      k "C-s"
      " and "
      k "C-r"
      " search incrementally, and pressing them again with an empty prompt repeats the last \
      \search."
    p_ $ do
      "Searches wrap around the end of the history unless you turn "
      opt "wrap-search"
      " off, and the number of matches appears in the position indicator as you go."
    tip $ p_ $ do
      "If your shell emits the standard prompt-marking escape sequences, copy mode can also \
      \jump between "
      i_ "shell prompts"
      " — the "
      c "next-prompt"
      " and "
      c "previous-prompt"
      " commands, unbound by default. That turns “scroll back to the start of the command \
      \before last” into two keystrokes. Bind them on Day 8 if your shell supports it."

  block "Selecting and copying" $ do
    p_ "The sequence is always the same three moves:"
    steps
      [ "Move the cursor to where the text starts."
      , do
          "Begin a selection ("
          k "Space"
          " in vi, "
          k "C-Space"
          " in emacs). Optionally switch to rectangle mode ("
          k "v"
          " / "
          k "R"
          ") to grab a column instead of full lines."
      , do
          "Move to the end and copy ("
          k "Enter"
          " in vi, "
          k "M-w"
          " in emacs). Copy mode exits and the text is in a buffer."
      ]
    p_ $ do
      "Rectangle selection is the one worth remembering. Column three of "
      c "docker ps"
      ", the PID column of "
      c "ps aux"
      ", one field out of a wall of log lines — these are miserable with a mouse and trivial \
      \with "
      k "v"
      "."
    p_ $ do
      "Paste with "
      k "C-b ]"
      ". Note that a paste is “typed” into the pane, so it lands wherever the cursor is, and \
      \newlines act as Enter. That is fine in an editor and occasionally alarming in a shell — \
      \tmux uses bracketed paste when the program has asked for it, which is what stops a \
      \multi-line paste from executing itself in a modern shell."

  block "Buffers are a stack" $ do
    p_ $ do
      "tmux does not have "
      i_ "a"
      " clipboard; it has a stack of paste buffers. Each copy pushes a new automatically-named \
      \buffer ("
      c "buffer0"
      ", "
      c "buffer1"
      ", …), the oldest falling off once "
      opt "buffer-limit"
      " is reached."
    defs
      [ (k "C-b #", "list the buffers with a sample of each")
      , (k "C-b =", "pick one interactively — with a preview, and " <> k "d" <> " to delete, "
                    <> k "e" <> " to open it in an editor")
      , (k "C-b -", "delete the newest buffer")
      ]
    p_ "From a script or the command prompt they are all addressable by name:"
    sh
      [ "$ tmux set-buffer -b notes \"some text\"       # create a named buffer"
      , "$ tmux load-buffer -b conf ~/.tmux.conf      # from a file"
      , "$ tmux save-buffer -b notes /tmp/notes.txt   # back out to a file"
      , "$ tmux show-buffer | wc -l                   # the newest one, on stdout"
      , "$ tmux paste-buffer -b conf -t api:1.0       # into a particular pane"
      ]

  block "Getting text out of tmux entirely" $ do
    p_ "Three exits, in increasing order of usefulness:"
    steps
      [ do
          b_ "To a file, non-interactively."
          " "
          c "tmux capture-pane -p -S - > out.txt"
          " dumps the entire history of the current pane. "
          c "-S -3000"
          " limits it, "
          c "-e"
          " keeps the colour escape sequences, "
          c "-J"
          " rejoins wrapped lines. This is the right way to attach a failing run to a ticket."
      , do
          b_ "Through a pipe."
          " The copy-mode command "
          c "copy-pipe"
          " sends the selection to a shell command as well as to a buffer. With no argument it \
          \uses the "
          opt "copy-command"
          " option, so setting that once makes every copy also go to your clipboard tool."
      , do
          b_ "To the terminal's own clipboard."
          " With "
          opt "set-clipboard"
          " on, tmux emits the OSC 52 escape sequence asking the terminal to set its clipboard. \
          \This works "
          i_ "through ssh"
          ", because it is just terminal output — which makes it the only mechanism that solves \
          \the remote case. Your terminal emulator has to allow it; many require the feature to \
          \be enabled explicitly."
      ]
    gotcha $ p_ $ do
      "Holding Shift while selecting with the mouse bypasses tmux entirely and uses your \
      \terminal emulator's own selection. That is the escape hatch when tmux's mouse mode gets \
      \in the way — and it is also why people wrongly conclude that tmux copying “doesn't \
      \work”: they have been using the terminal's selection all along and never learned copy \
      \mode."

cheat :: Html ()
cheat = do
  cfg
    [ "C-b [        # enter copy mode        C-b PageUp   enter, scrolled up"
    , "  / ?  n N   # search (vi)            C-s / C-r    search (emacs)"
    , "  Space      # begin selection        C-Space      begin selection (emacs)"
    , "  v          # rectangle toggle       R            rectangle (emacs)"
    , "  Enter      # copy and exit          M-w          copy and exit (emacs)"
    , "  q          # leave                  g / G        top / bottom"
    , "C-b ]        # paste newest buffer    C-b =  pick  C-b #  list  C-b -  delete"
    , ""
    , "tmux capture-pane -p -S - > out.txt   # the whole history, no copy mode"
    ]
