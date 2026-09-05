module Course.Day.D06 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
  Day
    { dayNum = 6
    , dayTitle = "Many sessions"
    , daySubtitle = "One session per project, and moving between them faster than you can alt-tab."
    , dayMinutes = 30
    , dayLevel = "intermediate"
    , dayManRef = "CLIENTS AND SESSIONS"
    , dayTags = ["sessions", "clients", "workflow"]
    , dayGoals =
        [ "keep a session per project running for weeks and move between them in two keystrokes"
        , "understand what a client is well enough to attach two, evict one, or resize sanely"
        , "decide what happens to a session when the last client leaves"
        ]
    , dayDiagram = Just d6diagram
    , dayBody = body
    , dayKeys =
        [ ("C-b s", "Choose a session from the tree — with previews, tagging and filtering.")
        , ("C-b (", "Switch this client to the previous session.")
        , ("C-b )", "Switch this client to the next session.")
        , ("C-b L", "Switch back to the last session. The " <> k "C-b l" <> " of sessions.")
        , ("C-b D", "Choose a client from a list and detach it.")
        , ("C-b $", "Rename the current session.")
        ]
    , dayCmds =
        [ ("new-session -d -s api", "Create a session in the background and stay where you are.")
        , ("new-session -A -s api", "Attach if it exists, create if it does not.")
        , ("new-session -c ~/src/api -s api", "Create with a starting directory.")
        , ("switch-client -t api", "Move this client to another session, without detaching.")
        , ("switch-client -l", "Back to the previous session.")
        , ("has-session -t api", "Exit 0 if it exists. The " <> c "if" <> " in every wrapper script.")
        , ("attach-session -d -t api", "Attach here and detach whoever else was looking.")
        , ("list-clients", "Which terminals are attached to what. Alias " <> c "lsc" <> ".")
        , ("detach-client -s api", "Detach every client from that session.")
        , ("kill-session -a", "Kill every session except the current one.")
        , ("choose-tree -Zs", "The session picker behind " <> k "C-b s" <> ".")
        ]
    , dayOpts =
        [ ("detach-on-destroy", "What a client does when its session dies. " <> c "off" <> " moves it to another session instead.")
        , ("destroy-unattached", "Destroy a session once the last client leaves. Off by default, and rightly.")
        , ("default-size", "Size for sessions created detached, when no client dictates one.")
        , ("window-size", "Whether a window sizes to the largest, smallest or latest attached client.")
        , ("aggressive-resize", "Size each window to the clients actually viewing it, not the whole session.")
        ]
    , dayConfig = day6config
    , dayDrills =
        [ "Create three sessions in the background without leaving the one you are in: "
            <> c "tmux new -d -s api -c ~/src/api" <> " and two more for real projects."
        , "Move between them with " <> k "C-b s" <> ". Then learn the fast path: "
            <> k "C-b L" <> " to bounce between the last two, " <> k "C-b (" <> " and "
            <> k "C-b )" <> " to walk the list."
        , "In the " <> k "C-b s" <> " tree, collapse everything with " <> k "M--" <> ", expand \
          \with " <> k "M-+" <> ", and filter with " <> k "f" <> ". Kill a session from inside \
          \the tree with " <> k "x" <> "."
        , "Attach a second terminal to the same session and watch the window shrink to the \
          \smaller terminal's size. Then set " <> c "set -wg aggressive-resize on" <> " and \
          \see what changes."
        , "Evict the other client: from one terminal run " <> c "tmux attach -d -t <session>"
            <> ". Check " <> c "tmux lsc" <> " before and after."
        , "Write the wrapper: a two-line shell function " <> c "tm" <> " that does "
            <> c "tmux new -A -s \"$1\" -c \"$PWD\"" <> ". Use it for the rest of the course."
        , "Deliberately destroy a session you are attached to (" <> c "tmux kill-session -t x"
            <> " from another terminal) and watch what your client does. Then set "
            <> opt "detach-on-destroy" <> " to " <> c "off" <> " and do it again."
        ]
    , dayQuiz =
        [ ( "What is the difference between " <> c "attach-session" <> " and "
              <> c "switch-client" <> "?"
          , p_ $ do
              c "attach-session"
              " is what you run from "
              i_ "outside"
              " tmux: it takes a terminal that has no client and gives it one. "
              c "switch-client"
              " is what you run from "
              i_ "inside"
              ": your client stays alive and simply points at a different session. Confusingly, "
              c "attach-session"
              " run from inside tmux does the second thing — which is why "
              k "C-b s"
              " and "
              k "C-b ("
              " are all built on "
              c "switch-client"
              "."
          )
        , ( "Two terminals are attached to one session; one is 200 columns wide and one is 80. \
            \What size are the windows, and why?"
          , p_ $ do
              "80 columns, because "
              opt "window-size"
              " defaults to "
              c "smallest"
              " — anything bigger could not be drawn on the small client. Set it to "
              c "latest"
              " and tmux uses whichever client was last active instead, leaving the other \
              \showing a partial view it can scroll around with "
              c "refresh-client -U/-D/-L/-R"
              ". "
              opt "aggressive-resize"
              " narrows the rule to “clients actually looking at this window”, which is the \
              \right answer when a second client is parked on a different window."
          )
        , ( "Why is “one session per project” better advice than “one window per project”?"
          , do
              p_ $ do
                "Because a session is the unit that "
                i_ "detaches"
                ". A project's session can be left running for weeks, attached to from home and \
                \from the office, killed as a unit when the project ends, and recreated by a \
                \script. A window has none of those properties — it is just a tab inside \
                \somebody else's context."
              p_ "The practical test: when you finish with something, do you want to close four \
                 \tabs or one thing? If it is one thing, it should have been a session."
          )
        , ( "You run " <> c "tmux new -s api" <> " every morning and get "
              <> c "duplicate session" <> " half the time. What is the fix, and why is it not "
              <> c "kill-session" <> "?"
          , p_ $ do
              c "tmux new -A -s api"
              ". The "
              c "-A"
              " flag makes new-session behave like attach-session when the name is taken, which \
              \makes the command idempotent — safe in a shell function, a login script, or a \
              \keyboard shortcut. Killing and recreating would throw away exactly the running \
              \state you started using tmux to keep."
          )
        ]
    , dayCheat = cheat
    }

-- ---------------------------------------------------------------------------

d6diagram :: Diagram
d6diagram =
  (diagram
     "Clients and sessions are related many-to-many through the server: a client is attached to \
     \exactly one session at a time, a session may have several clients, and a detached session \
     \has none."
     body')
    { dgCaption = do
        "The asymmetry is the point: a client always looks at exactly one session, but a session \
        \need not have any client at all — that state is called "
        b_ "detached"
        ", and it is the whole reason tmux exists. Everything on the right of this diagram \
        \survives everything on the left going away."
    , dgRankdir = "LR"
    , dgRanksep = "0.7"
    }
  where
    body' =
      T.unlines
        [ "  t1   [label=\"a terminal\\n(ssh from home)\", fillcolor=\"#f4efe6\"];"
        , "  t2   [label=\"a terminal\\n(the office desk)\", fillcolor=\"#f4efe6\"];"
        , "  c1   [label=\"a client\"];"
        , "  c2   [label=\"a client\"];"
        , "  srv  [label=\"the tmux server\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  s1   [label=\"session 'api'\\n(attached ×2)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  s2   [label=\"session 'infra'\\n(detached)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
        , "  s3   [label=\"session 'notes'\\n(detached)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
        , ""
        , "  t1 -> c1 [label=\"  hosts\"];"
        , "  t2 -> c2 [label=\"  hosts\"];"
        , "  c1 -> s1 [label=\"  is attached to\"];"
        , "  c2 -> s1 [label=\"  is attached to\"];"
        , "  srv -> s1 [label=\"  owns\"];"
        , "  srv -> s2 [label=\"  owns\"];"
        , "  srv -> s3 [label=\"  owns\"];"
        , "  c1 -> s2 [label=\"  switch-client\\l  moves to\\l\", style=dashed, constraint=false];"
        , "  { rank=same; s1; s2; s3; }"
        ]

-- ---------------------------------------------------------------------------

day6config :: [ConfBlock]
day6config =
  [ ConfBlock
      "When a session is destroyed, move this client to another session instead of dumping it\n\
      \back to the shell. With a session per project you nearly always want to land somewhere."
      "set -g detach-on-destroy off"
  , ConfBlock
      "Size each window to the clients that are actually looking at it, rather than to the\n\
      \smallest client attached to the session. Good when a phone or a narrow ssh window is\n\
      \parked on some other window of the same session."
      "set -wg aggressive-resize on"
  , ConfBlock
      "Sessions created detached (new -d, or from a script) get a usable default size instead\n\
      \of 80x24, so a layout built by a script is not laid out for a 1978 terminal."
      "set -g default-size 200x50"
  ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
  block "Stop putting everything in one session" $ do
    p_ [class_ "lede"] $ do
      "By now you have windows and panes, and the natural next move is to grow "
      c "main"
      " until it has eleven windows and you cannot remember which is which. The fix is not more \
      \discipline about naming. It is a second session."
    p_ $ do
      "A session is the unit that persists, detaches, and can be created and destroyed as a \
      \whole. That makes it the right shape for “a project”: the windows in it are all about \
      \one thing, its working directories are all in one tree, and when the work is over you \
      \kill one object rather than closing seven tabs."
    fig

  block "Creating without leaving" $ do
    p_ $ do
      "The important flag is "
      c "-d"
      ": create the session but do not attach to it. That lets you set up a whole environment \
      \from a script — or just from your current pane — without your screen jumping around."
    sh
      [ "$ tmux new -d -s infra -c ~/src/infra"
      , "$ tmux new -d -s notes -c ~/notes"
      , "$ tmux ls"
      , "api: 4 windows (created Mon Sep  1 08:12:44 2026) (attached)"
      , "infra: 1 windows (created Sat Sep  5 09:31:02 2026)"
      , "notes: 1 windows (created Sat Sep  5 09:31:03 2026)"
      ]
    tip $ do
      p_ "The shell function worth having, and the last piece of tmux boilerplate you need:"
      cfg
        [ "tm() { tmux new -A -s \"${1:-main}\" -c \"$PWD\"; }"
        ]
      p_ $ do
        "Then "
        c "tm api"
        " attaches to "
        c "api"
        " or creates it in the current directory. Idempotent, so it never fails, and short \
        \enough to type without thinking."

  block "Moving between them" $ do
    defs
      [ (k "C-b s", "The session tree. Sessions collapsed or expanded, previews on the right, \
                    \a shortcut letter on every line. " <> k "x" <> " kills, " <> k "t"
                    <> " tags, " <> k "f" <> " filters, " <> k "M-+" <> " and " <> k "M--"
                    <> " expand and collapse everything.")
      , (k "C-b L", "The previous session. The one you will actually use, for the same reason "
                    <> k "C-b l" <> " beat " <> k "C-b n" <> " on Day 2.")
      , (k "C-b (" <> " / " <> k "C-b )", "Previous and next session in order. Fine with three \
                    \sessions, tedious with nine.")
      ]
    p_ $ do
      "All three run "
      c "switch-client"
      " underneath. Your client never detaches — it just points somewhere else, which is why \
      \switching is instantaneous and why nothing in the old session notices."
    why $ p_ $ do
      "This also explains a wart: from a shell, "
      c "tmux attach -t other"
      " starts a new client. From "
      i_ "inside"
      " tmux, the same command switches the existing one. tmux is being helpful — starting a \
      \client inside a client would nest two tmuxes — but it means the command's behaviour \
      \depends on where you run it. When you write scripts, prefer "
      c "switch-client"
      " when you mean switch and "
      c "attach-session"
      " when you mean attach."

  block "Clients, and why you should care" $ do
    p_ $ do
      "A client is a terminal displaying a session. Two clients on one session is genuinely \
      \useful — a second monitor, or a colleague over ssh — and it is also where tmux's sizing \
      \rules become visible."
    sh
      [ "$ tmux lsc"
      , "/dev/pts/3: api [200x50 xterm-256color] (utf8)"
      , "/dev/pts/9: api [80x24 xterm-256color] (utf8)"
      ]
    p_ $ do
      "By default every window is sized to the "
      i_ "smallest"
      " client attached to its session, because anything larger could not be drawn on the \
      \small one. Three options adjust that: "
      opt "window-size"
      " (largest / smallest / manual / latest), "
      opt "aggressive-resize"
      " (only count clients actually viewing this window), and "
      opt "default-size"
      " (what to use when nobody is attached at all)."
    p_ $ do
      "To take a session over from an idle client elsewhere, attach with "
      c "-d"
      ": "
      c "tmux attach -d -t api"
      " detaches the others first. "
      k "C-b D"
      " does it interactively, showing every client with its terminal and size."

  block "Ending a session, on purpose and by accident" $ do
    p_ $ do
      "Sessions die when their last window closes, or when you say so with "
      c "kill-session"
      ". Two options change what happens around that:"
    defs
      [ (opt "detach-on-destroy", "On by default: when your session is destroyed, your client \
            \is detached and you land back in the shell. Set it to " <> c "off" <> " and the \
            \client is moved to the most recently used remaining session instead — much nicer \
            \when you keep several around.")
      , (opt "destroy-unattached", "Off by default: sessions survive with nobody watching. \
            \Turning it on makes sessions ephemeral, which defeats the point of tmux for \
            \normal use but is occasionally right for a session created by a script.")
      ]
    p_ $ do
      c "kill-session -a"
      " kills everything except the current session — the annual spring clean. "
      c "has-session -t name"
      " exits 0 or 1 and prints nothing useful, which is exactly what a wrapper script wants:"
    sh
      [ "$ tmux has-session -t api 2>/dev/null || tmux new -d -s api -c ~/src/api"
      , "$ tmux attach -t api"
      ]
    note $ p_ $ do
      "There is also a rarely-used feature called a "
      b_ "session group"
      " ("
      c "new-session -t existing"
      "): several sessions that share one set of windows but keep their own current window. \
      \That is how two people can look at the same windows without fighting over which one is \
      \selected. Worth knowing it exists; rarely worth reaching for."

  block "Today's habit" $ do
    p_ $ do
      "Split "
      c "main"
      " up. Give each real project its own session, created with "
      c "-c"
      " pointing at its directory, and get used to "
      k "C-b L"
      " as the way back. If you find yourself with a session called "
      c "misc"
      " holding nine unrelated windows, that is the signal to make another one."

cheat :: Html ()
cheat = do
  cfg
    [ "tmux new -d -s api -c ~/src/api    # create in the background"
    , "tmux new -A -s api                 # attach or create — the idempotent one"
    , "tmux attach -d -t api              # attach here, evict other clients"
    , "tmux ls / tmux lsc                 # sessions / clients"
    , ""
    , "C-b s    # session tree (x kills, t tags, f filters)"
    , "C-b L    # last session      C-b ( )  previous / next session"
    , "C-b D    # choose a client and detach it"
    , ""
    , "tm() { tmux new -A -s \"${1:-main}\" -c \"$PWD\"; }"
    ]
