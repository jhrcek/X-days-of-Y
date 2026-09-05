module Course.Day.D01 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
  Day
    { dayNum = 1
    , dayTitle = "The mental model"
    , daySubtitle = "Server, session, window, pane — and never losing a shell again."
    , dayMinutes = 30
    , dayLevel = "essential"
    , dayManRef = "DESCRIPTION, CLIENTS AND SESSIONS"
    , dayTags = ["sessions", "attach/detach", "prefix"]
    , dayGoals =
        [ "explain what the tmux server is and why your shells survive a dropped ssh connection"
        , "create, detach from, list and re-attach to named sessions without thinking about it"
        , "reach any tmux command two ways: through a key binding and through the command prompt"
        ]
    , dayDiagram = Just d1diagram
    , dayBody = body
    , dayKeys =
        [ ("C-b d", "Detach this client. The session keeps running.")
        , ("C-b $", "Rename the current session.")
        , ("C-b ?", "List every key binding. " <> k "q" <> " to leave.")
        , ("C-b :", "Open the tmux command prompt.")
        , ("C-b t", "Show a clock — a harmless way to prove the prefix works.")
        , ("C-b C-b", "Send a literal " <> k "C-b" <> " to the program in the pane.")
        ]
    , dayCmds =
        [ ("tmux", "Start the server if needed and create a session, attached.")
        , ("tmux new -s work", "Create a session named " <> c "work" <> ".")
        , ("tmux new -A -s work", "Attach to " <> c "work" <> ", creating it only if absent.")
        , ("tmux ls", "List sessions on this server. Alias for " <> c "list-sessions" <> ".")
        , ("tmux attach -t work", "Attach this terminal to " <> c "work" <> ".")
        , ("tmux attach -d -t work", "Attach, detaching any other client first.")
        , ("tmux detach", "Detach the current client, from inside or by target.")
        , ("tmux rename-session api", "Rename the current session.")
        , ("tmux kill-session -t work", "Destroy a session and everything in it.")
        , ("tmux kill-server", "Destroy every session. The nuclear option.")
        ]
    , dayOpts = []
    , dayConfig = []
    , dayDrills =
        [ "Run " <> c "tmux new -s day1" <> ". Start something long-lived in it — "
            <> c "top" <> ", a log tail, a dev server."
        , "Detach with " <> k "C-b d" <> ". Confirm the process is still alive from outside: "
            <> c "tmux ls" <> ", then " <> c "ps" <> " for it."
        , "Close the terminal window entirely. Open a new one. "
            <> c "tmux attach -t day1" <> ". Everything is exactly where you left it."
        , "Attach to the same session from two terminals side by side. Type in one and watch \
          \the other. Now detach one with " <> k "C-b d" <> " — the other is unaffected."
        , "Press " <> k "C-b ?" <> " and read the whole list once. You will not remember it. \
          \Notice instead that every line is a " <> c "bind-key" <> " command."
        , "Press " <> k "C-b :" <> ", type " <> c "rename-session tuesday" <> ", press Enter. \
          \Watch the status line on the left change."
        , "Finish the day by replacing your habit: from now on, the first thing you type in a \
          \new terminal is " <> c "tmux new -A -s main" <> "."
        ]
    , dayQuiz =
        [ ( "Your laptop's ssh connection to a server drops mid-build. What exactly survived, \
            \and what died?"
          , do
              p_ $ do
                "The "
                b_ "client"
                " died — it was the process attached to your dying terminal. The tmux "
                b_ "server"
                " on the remote host, and every session, window, pane and running process \
                \inside it, is untouched. tmux noticed the client vanished and simply marked \
                \the session unattached."
              p_ $ do
                "Reconnect and run "
                c "tmux attach"
                ". Your build is still scrolling."
          )
        , ( "What is the difference between " <> c "tmux new -s work" <> " and "
              <> c "tmux new -A -s work" <> "?"
          , p_ $ do
              "Without "
              c "-A"
              " the second invocation fails with "
              c "duplicate session: work"
              ". With "
              c "-A"
              ", new-session behaves like attach-session when the name already exists. It is \
              \the only form worth putting in your shell aliases, because it is idempotent."
          )
        , ( "You are inside tmux running an editor that itself wants " <> k "C-b" <> ". How do \
            \you feed it through?"
          , p_ $ do
              "Press the prefix twice: "
              k "C-b C-b"
              ". The binding for "
              k "C-b"
              " inside the prefix table is "
              c "send-prefix"
              ", which passes the key on to the pane instead of treating it as the start of a \
              \tmux command."
          )
        , ( "Why does " <> c "tmux ls" <> " sometimes say “no server running”, even though you \
            \ran tmux an hour ago?"
          , p_ $ do
              "Because the server exits when its last session is destroyed — that is the "
              opt "exit-empty"
              " server option, on by default. Detaching leaves sessions alive; "
              i_ "exiting the last shell"
              " in the last window of the last session destroys them, and then the server has \
              \nothing to do."
          )
        ]
    , dayCheat = cheat
    }

-- ---------------------------------------------------------------------------

d1diagram :: Diagram
d1diagram =
  (diagram
     "The tmux object model: a terminal runs a client, the client attaches to a session \
     \owned by the server, a session contains windows, a window is divided into panes, and \
     \each pane is a pseudo-terminal running a process."
     body')
    { dgCaption = do
        "How to read one of these: each box is a "
        b_ "type"
        " of thing, phrased so it fits in the sentence “this is …”. Each arrow is an "
        b_ "aspect"
        " — a function from one type to another, phrased so “a window "
        i_ "is a member of"
        " a session” reads as a true sentence. Dashed arrows are aspects that pick out "
        i_ "one distinguished"
        " thing rather than any of them."
    , dgRankdir = "TB"
    , dgRanksep = "0.42"
    }
  where
    body' =
      "  emu   [label=\"a terminal emulator\", fillcolor=\"#f4efe6\"];\n\
      \  cli   [label=\"a tmux client\", fillcolor=\"#f4efe6\"];\n\
      \  srv   [label=\"the tmux server\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
      \  sess  [label=\"a session\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
      \  win   [label=\"a window\"];\n\
      \  pane  [label=\"a pane\"];\n\
      \  pty   [label=\"a pseudo-terminal\"];\n\
      \  proc  [label=\"a process\\n(your shell)\"];\n\
      \\n\
      \  emu  -> cli  [label=\"  hosts\"];\n\
      \  cli  -> sess [label=\"  is attached to\"];\n\
      \  srv  -> sess [label=\"  owns\"];\n\
      \  sess -> win  [label=\"  contains\"];\n\
      \  sess -> win  [label=\"  has as current  \", style=dashed, constraint=false];\n\
      \  win  -> pane [label=\"  is divided into\"];\n\
      \  win  -> pane [label=\"  has as active  \", style=dashed, constraint=false];\n\
      \  pane -> pty  [label=\"  is\"];\n\
      \  pty  -> proc [label=\"  runs\"];\n\
      \\n\
      \  { rank=same; emu; srv; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
  block "The thing nobody tells you first" $ do
    p_ [class_ "lede"] $ do
      "tmux is not a program that draws split screens. tmux is a "
      b_ "server"
      " that owns a set of running terminals, plus a thin client that renders one of them \
      \into whatever terminal you happen to be sitting at. Every feature in the manual page \
      \follows from that one design decision, so it is worth ten minutes."
    p_ $ do
      "When you type "
      c "tmux"
      " the first time, two processes appear. One is a server — it detaches, daemonises, and \
      \communicates over a unix socket in "
      c "/tmp/tmux-$UID/"
      ". The other is a client attached to your terminal, whose entire job is to send your \
      \keystrokes to the server and paint what comes back."
    p_ $ do
      "The consequence is the reason most people install tmux: "
      b_ "your shells do not belong to your terminal any more."
      " Close the terminal, lose the ssh connection, reboot your laptop while ssh'd into a \
      \build box — the client dies, the server does not notice or care, and the processes \
      \keep running. You reattach later and find the scrollback still scrolling."
    why $ p_ $ do
      "This is why tmux has a vocabulary at all. If it were just a screen splitter it would \
      \need one noun. Because sessions outlive clients, it needs to name the thing that \
      \persists ("
      b_ "session"
      "), the thing that is looking at it ("
      b_ "client"
      "), and the thing that owns all of them ("
      b_ "server"
      "). Almost every command you will learn takes one of those as a target."

  block "Four nouns and one verb" $ do
    p_ "Learn these in this order. Everything else in the course hangs off them."
    defs
      [ ( "server"
        , do
            "One per user per socket. Starts on demand, exits when the last session is gone. \
            \You almost never address it directly, but "
            c "tmux kill-server"
            " exists for when you have made a mess."
        )
      , ( "session"
        , do
            "A named collection of windows — the unit you attach to and detach from. One \
            \project, one session, is the habit worth forming. Sessions have names ("
            c "work"
            ") and ids ("
            c "$0"
            ")."
        )
      , ( "window"
        , "Occupies the whole screen; appears as an entry in the status line at the bottom. \
          \Think browser tab. Tomorrow's lesson."
        )
      , ( "pane"
        , "A rectangle inside a window, and a real pseudo-terminal with its own shell. Think \
          \split view. Day 3."
        )
      , ( "client"
        , "A terminal currently displaying a session. Two clients can show the same session \
          \at once, which is how pair-programming over ssh works."
        )
      ]
    fig

  block "Your first session, narrated" $ do
    p_ $ do
      "Run it with a name. Anonymous sessions get numbers ("
      c "0"
      ", "
      c "1"
      "…) and you will not remember which was which by Thursday."
    sh
      [ "$ tmux new -s day1"
      ]
    p_ "The screen clears and you get something like this:"
    termStatus
      "day1"
      [ "jhrcek@thinkpad ~ $ "
      , ""
      , ""
      , ""
      , ""
      ]
      "[day1] 0:bash*"
      "\"thinkpad\" 09:14 05-Sep-26"
    p_ $ do
      "That green bar is the "
      b_ "status line"
      ", and it is already telling you a lot. "
      c "[day1]"
      " is the session name. "
      c "0:bash"
      " is window 0, named after the program running in it, and the "
      c "*"
      " means it is the current window. On the right is the active pane's title and the clock. \
      \You will rebuild this bar to your own taste on Day 10."
    note $ p_ $ do
      "Inside a tmux pane you are in an ordinary shell. Nothing is intercepted, nothing is \
      \wrapped. "
      c "echo $TMUX"
      " is non-empty and "
      c "echo $TERM"
      " says "
      c "tmux-256color"
      " (or "
      c "screen"
      "); otherwise it is the shell you always had."

  block "The prefix key" $ do
    p_ $ do
      "tmux has to distinguish “this keystroke is for you” from “this keystroke is for vim”. \
      \It does that with a "
      b_ "prefix"
      ": press "
      k "C-b"
      ", release, then press the command key. "
      k "C-b d"
      " is two separate keystrokes, not a chord."
    p_ $ do
      "Try the harmless one: "
      k "C-b t"
      " draws a large clock in the pane. Press any key to dismiss it. If that worked, your \
      \prefix is reaching tmux."
    gotcha $ p_ $ do
      k "C-b"
      " collides with “page back” in emacs, readline's backward-char, and vim's page-up. A \
      \great many people remap it to "
      k "C-a"
      " or "
      k "C-Space"
      " on Day 5. Do not remap it today — spend a few days on the defaults so that you can sit \
      \down at somebody else's machine and still be useful."
    p_ $ do
      "Two escape hatches you need immediately. "
      k "C-b ?"
      " lists every binding (it opens a scrollable read-only pane; leave it with "
      k "q"
      "). And "
      k "C-b :"
      " opens the command prompt at the bottom of the screen, where you can type any tmux \
      \command by name."
    why $ p_ $ do
      "Those two are the same thing. A key binding is literally a stored command: "
      c "bind-key d detach-client"
      ". Anything you can do with a key you can do by typing the command at "
      k "C-b :"
      ", from a shell as "
      c "tmux detach-client"
      ", or from a config file. There is no “GUI layer” with extra powers — which is why the \
      \man page is organised as a list of commands rather than a list of features."

  block "Detach, list, attach" $ do
    p_ $ do
      "This is the whole point of the tool, so make it reflex. "
      k "C-b d"
      " detaches. Your terminal returns to the shell you started from and prints the reason:"
    sh
      [ "$ tmux new -s day1"
      , "[detached (from session day1)]"
      , "$ tmux ls"
      , "day1: 1 windows (created Sat Sep  5 09:14:02 2026)"
      , "$ tmux attach -t day1"
      ]
    p_ $ do
      "Targets are forgiving: "
      c "-t day1"
      ", "
      c "-t day"
      " and "
      c "-t d"
      " all work as long as the prefix is unambiguous, and a glob like "
      c "-t 'da*'"
      " works too. Day 7 makes the full target grammar explicit."
    tip $ p_ $ do
      "The single command worth aliasing is "
      c "tmux new -A -s main"
      ": attach to "
      c "main"
      " if it exists, create it otherwise. It never fails, so it is safe to put in a script or \
      \a terminal profile."
    p_ $ do
      "Attaching a second terminal to the same session does not steal it — both clients see \
      \the same windows, and tmux sizes the window to the smaller of the two terminals. To \
      \evict the other client instead, attach with "
      c "-d"
      "."

  block "How things end" $ do
    p_ "Three levels of destruction, and they cascade upwards:"
    steps
      [ do
          "Exit the shell in a pane ("
          c "exit"
          " or "
          k "C-d"
          ") and the pane closes."
      , "When the last pane in a window closes, the window closes."
      , do
          "When the last window in a session closes, the session is destroyed — and every \
          \client attached to it is detached. If that was the last session, the server exits \
          \and "
          c "tmux ls"
          " starts saying “no server running”."
      ]
    p_ $ do
      "From outside, "
      c "tmux kill-session -t day1"
      " does it deliberately. "
      c "tmux kill-server"
      " ends everything at once; it is the right move roughly once a year and the wrong move \
      \the other times."

  block "Today's habit" $ do
    p_ $ do
      "None of this becomes yours by reading. Pick one long-running thing you do — a dev \
      \server, a log tail, an ssh session to a box you use daily — and move it inside a named \
      \tmux session today. Then do the drills."
    p_ $ do
      "Tomorrow: windows, so that one session can hold your editor, your server and your logs \
      \without a single split."

cheat :: Html ()
cheat = do
  p_ $ do
    b_ "The whole of Day 1 in six lines."
    " Everything else is elaboration."
  cfg
    [ "tmux new -A -s main    # start or resume; the only invocation you need"
    , "C-b d                  # detach — session keeps running"
    , "tmux ls                # what is running"
    , "tmux attach -t main    # come back (-d to evict other clients)"
    , "C-b ?                  # every key binding; q to leave"
    , "C-b :                  # command prompt: any command, by name"
    ]
