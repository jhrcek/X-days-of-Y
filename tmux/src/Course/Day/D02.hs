module Course.Day.D02 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
  Day
    { dayNum = 2
    , dayTitle = "Windows"
    , daySubtitle = "One session per project, one window per concern."
    , dayMinutes = 25
    , dayLevel = "essential"
    , dayManRef = "WINDOWS AND PANES, STATUS LINE"
    , dayTags = ["windows", "status line", "naming"]
    , dayGoals =
        [ "create, name, reorder and destroy windows without leaving the keyboard"
        , "read the window list in the status line, including every flag character"
        , "decide deliberately whether a window renames itself or keeps the name you gave it"
        ]
    , dayDiagram = Just d2diagram
    , dayBody = body
    , dayKeys =
        [ ("C-b c", "Create a window at the lowest free index.")
        , ("C-b ,", "Rename the current window — and pin the name.")
        , ("C-b n", "Next window by index.")
        , ("C-b p", "Previous window by index.")
        , ("C-b l", "Back to the last window you were in. The one to actually learn.")
        , ("C-b 0", "Jump straight to window 0 (likewise " <> k "1" <> " … " <> k "9" <> ").")
        , ("C-b '", "Prompt for a window index — for windows above 9.")
        , ("C-b w", "Choose a window from an interactive tree with previews.")
        , ("C-b &", "Kill the current window, after a confirmation.")
        , ("C-b .", "Move the current window to a different index.")
        , ("C-b i", "Flash some information about the current window.")
        ]
    , dayCmds =
        [ ("new-window", "Create a window. Alias " <> c "neww" <> ".")
        , ("new-window -n logs", "Create it with a fixed name.")
        , ("new-window -c ~/src/api", "Create it with that working directory.")
        , ("new-window -d", "Create it but do not switch to it.")
        , ("new-window -a -t 2", "Insert after window 2, shifting the rest along.")
        , ("rename-window api", "Rename the current window.")
        , ("select-window -t :3", "Switch to window 3 of the current session.")
        , ("last-window", "Switch to the previously current window.")
        , ("kill-window -t :logs", "Kill a window by name.")
        , ("list-windows", "List windows in the session. Alias " <> c "lsw" <> ".")
        , ("choose-tree -w", "The interactive picker behind " <> k "C-b w" <> ".")
        ]
    , dayOpts =
        [ ("automatic-rename", "Window renames itself after the running command. On by default.")
        , ("automatic-rename-format", "The format used when it does. Defaults to the pane's command.")
        , ("allow-rename", "Whether a program in the pane may rename the window by escape sequence.")
        ]
    , dayConfig = []
    , dayDrills =
        [ "In your " <> c "main" <> " session, build the shape of a real project: "
            <> k "C-b c" <> " three times, and name each one with " <> k "C-b ,"
            <> " — say " <> c "edit" <> ", " <> c "run" <> ", " <> c "git" <> "."
        , "Move between them with " <> k "C-b 0" <> " … " <> k "C-b 2" <> " for five minutes of \
          \real work. Then stop using the numbers and use " <> k "C-b l" <> " to bounce \
          \between the last two. Notice how much of your switching is really just bouncing."
        , "Open " <> k "C-b w" <> ". Navigate with the arrows, watch the preview pane, choose \
          \with Enter. Press " <> k "q" <> " to escape without choosing."
        , "Start " <> c "top" <> " in a window you have not renamed, and watch the window name \
          \change by itself. Now " <> k "C-b ," <> " it to something and start " <> c "top"
            <> " again — the name stays. You have just turned " <> opt "automatic-rename"
            <> " off for that one window."
        , "Create a window straight into a directory: " <> k "C-b :" <> " then "
            <> c "neww -c ~/some/project -n proj" <> "."
        , "Reorder: " <> k "C-b ." <> " and give an index that is already taken. Read the error. \
          \Now try an index that is free."
        , "Kill one with " <> k "C-b &" <> " and confirm. Then close another by just typing "
            <> c "exit" <> " in its shell. Same result, different route."
        ]
    , dayQuiz =
        [ ( "What is the difference between " <> k "C-b n" <> " and " <> k "C-b l" <> "?"
          , p_ $ do
              k "C-b n"
              " is "
              c "next-window"
              " — the next one "
              i_ "by index"
              ", wrapping round at the end. "
              k "C-b l"
              " is "
              c "last-window"
              " — the one you were in "
              i_ "before this one"
              ", regardless of index. In practice you alternate between two windows far more \
              \often than you sweep through them in order, so "
              k "C-b l"
              " earns its place in your fingers first."
          )
        , ( "Your window is called " <> c "zsh" <> ", then " <> c "vim" <> ", then " <> c "zsh"
              <> " again. Nothing in your config does this. What is happening?"
          , p_ $ do
              opt "automatic-rename"
              " is on by default, and it sets the window name from "
              c "#{pane_current_command}"
              " of the active pane. That is exactly why naming a window by hand switches the \
              \option off for that window: tmux assumes an explicit name beats a derived one."
          )
        , ( "You have twelve windows and want number 11. " <> k "C-b 1" <> k "1"
              <> " does not work. Why, and what does?"
          , p_ $ do
              "Each digit is a separate binding — "
              k "C-b 1"
              " immediately runs "
              c "select-window -t :1"
              " and the second "
              k "1"
              " just goes to the shell. Use "
              k "C-b '"
              " (prompt for an index) or "
              k "C-b w"
              " (pick from the tree). This is also the first good argument for naming windows \
              \instead of counting them."
          )
        , ( "In the status line you see " <> c "3:build-" <> " and " <> c "4:test*Z"
              <> ". Read it aloud."
          , do
              p_ "Window 3 is named build and is the last window you were in. Window 4 is \
                 \named test, is the current window, and its active pane is zoomed."
              p_ $ do
                "The full set: "
                c "*"
                " current, "
                c "-"
                " last, "
                c "#"
                " activity, "
                c "!"
                " bell, "
                c "~"
                " silent, "
                c "M"
                " contains the marked pane, "
                c "Z"
                " zoomed."
          )
        ]
    , dayCheat = cheat
    }

-- ---------------------------------------------------------------------------

d2diagram :: Diagram
d2diagram =
  (diagram
     "A window belongs to a session, carries an index, a name and flags, and the session \
     \distinguishes a current and a last window. The window name is either given explicitly \
     \or derived from the active pane's command."
     body')
    { dgCaption = do
        "The two dashed aspects are what "
        b_ "C-b l"
        " and the "
        b_ "*"
        "/"
        b_ "-"
        " flags in the status line are about: a session always distinguishes one current and \
        \one previous window. The fork on the right is "
        b_ "automatic-rename"
        " — a window's name comes from one of two places, and naming it by hand permanently \
        \picks the left branch."
    , dgRankdir = "TB"
    , dgRanksep = "0.45"
    }
  where
    body' =
      T.unlines
        [ "  sess  [label=\"a session\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  win   [label=\"a window\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  idx   [label=\"a window index\\n(0, 1, 2 …)\"];"
        , "  name  [label=\"a window name\"];"
        , "  flags [label=\"a flag\\n(* - # ! ~ M Z)\"];"
        , "  given [label=\"a name you typed\\n(C-b ,)\", fillcolor=\"#f4efe6\"];"
        , "  cmd   [label=\"the active pane's\\ncommand\", fillcolor=\"#f4efe6\"];"
        , "  bar   [label=\"the window list\\nin the status line\", fillcolor=\"#f4efe6\"];"
        , ""
        , "  sess -> win   [label=\"  contains\"];"
        , "  sess -> win   [label=\"has as current  \", style=dashed, constraint=false];"
        , "  sess -> win   [label=\"  has as last\", style=dashed, constraint=false];"
        , "  win  -> idx   [label=\"  has as index\"];"
        , "  win  -> name  [label=\"  has as name\"];"
        , "  win  -> flags [label=\"  shows\"];"
        , "  given -> name [label=\"  becomes\"];"
        , "  cmd   -> name [label=\"  becomes, if\\l  automatic-rename\\l\"];"
        , "  idx  -> bar   [style=dotted, arrowhead=empty];"
        , "  name -> bar   [style=dotted, arrowhead=empty];"
        , "  flags -> bar  [style=dotted, arrowhead=empty, label=\"  is drawn in\"];"
        ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
  block "Tabs, but they outlive the terminal" $ do
    p_ [class_ "lede"] $ do
      "A window fills the whole screen and appears as one entry in the status line. If you \
      \have used browser tabs you already have the model. What you do not yet have is the \
      \habit: most people who install tmux split panes obsessively and never make a second \
      \window, which is backwards."
    p_ $ do
      "The rule that has held up for years of daily use: "
      b_ "one session per project, one window per concern, panes only when you genuinely need \
        \to watch two things at once."
      " Editing is a concern. Running the server is a concern. Reading its logs is a concern. \
      \Ad-hoc git work is a concern. That is four windows and no splits, and every one of them \
      \gets the full width of your terminal."
    fig

  block "Making and naming them" $ do
    p_ $ do
      k "C-b c"
      " creates a window and switches to it. It lands at the "
      i_ "lowest free index"
      ", which is not necessarily the end — kill window 2 of 0,1,2,3 and the next "
      k "C-b c"
      " will fill the hole."
    p_ $ do
      "The name matters more than the index. "
      k "C-b ,"
      " opens a prompt pre-filled with the current name; edit it and press Enter. From then on \
      \the status line says "
      c "2:logs"
      " instead of "
      c "2:zsh"
      "."
    termStatus
      "main"
      [ "$ tail -F /var/log/app/current"
      , "12:04:11 INFO  worker started"
      , "12:04:11 INFO  listening on :8080"
      , ""
      ]
      "[api] 0:edit- 1:run 2:logs* 3:git"
      "\"thinkpad\" 12:04"
    p_ $ do
      "Read that bar: session "
      c "api"
      "; window 0 named "
      c "edit"
      " is where I was a moment ago ("
      c "-"
      "); window 2 named "
      c "logs"
      " is where I am now ("
      c "*"
      ")."
    why $ do
      p_ $ do
        "Naming a window by hand does something invisible but important: it turns "
        opt "automatic-rename"
        " off "
        i_ "for that window"
        ". By default tmux keeps rewriting the name to whatever command is running in the \
        \active pane, which is why an unnamed window flickers between "
        c "zsh"
        " and "
        c "vim"
        " and "
        c "man"
        " as you work."
      p_ $ do
        "So the two states are: “I have not decided, tell me what is running” and “I have \
        \decided, leave it alone”. There is no third state to configure, and the option flips \
        \itself when you express an opinion."

  block "Getting around" $ do
    p_ "Four movements, in the order you will come to rely on them:"
    defs
      [ (k "C-b l", "The previous window. Most switching is really alternation between two \
                    \things — the editor and the thing you just ran. Learn this one first.")
      , (k "C-b 0" <> " … " <> k "C-b 9", "Absolute jump by index. Fast and unambiguous, as \
                    \long as your important windows live at low indices.")
      , (k "C-b n" <> " / " <> k "C-b p", "Next and previous by index, wrapping at the ends. \
                    \Good for a sweep, bad for a target.")
      , (k "C-b w", "The interactive picker: a tree of sessions, windows and panes with a live \
                    \preview of each. Arrows to move, Enter to choose, " <> k "q" <> " to \
                    \escape, and a shortcut letter in brackets on the left of every line.")
      ]
    p_ $ do
      "Above nine you need "
      k "C-b '"
      ", which prompts for an index. If you regularly have more than ten windows in one \
      \session, that is usually a sign that two projects have been squeezed into one session — \
      \Day 6 is about splitting them apart."
    tip $ p_ $ do
      k "C-b w"
      " is not just a chooser. In that tree you can tag several windows with "
      k "t"
      ", kill them all with "
      k "X"
      ", reorder with "
      k "S-Up"
      "/"
      k "S-Down"
      ", and filter the list by typing "
      k "f"
      " and a format. It is a small file manager for your session, and almost nobody who has \
      \used tmux for a year knows it is there."

  block "Moving and removing" $ do
    p_ $ do
      k "C-b ."
      " prompts for a new index for the current window. If something already sits there you get "
      c "index in use: 3"
      " and nothing happens — unlike the "
      c "move-window"
      " command underneath it, which will happily take "
      c "-k"
      " to kill the occupant."
    sh
      [ "# from the command prompt (C-b :) or a shell"
      , "$ tmux move-window -t 9        # this window becomes window 9"
      , "$ tmux move-window -r          # renumber all windows, closing the gaps"
      , "$ tmux new-window -a -t 1      # insert right after window 1, shifting the rest"
      ]
    p_ $ do
      "To destroy a window, either exit every shell in it, or "
      k "C-b &"
      " which asks first. "
      c "kill-window -a"
      " kills every window "
      i_ "except"
      " the target — the fastest way to clean up a session that has grown weeds."
    gotcha $ p_ $ do
      "Killing a window does not always destroy it. A window can be "
      b_ "linked"
      " into several sessions at once, in which case "
      c "kill-window"
      " removes it from all of them but "
      c "unlink-window"
      " only removes it from one. You will not meet this by accident; Day 12 does it on \
      \purpose."

  block "The status line as an instrument" $ do
    p_ $ do
      "Everything above is visible in one line at the bottom of the screen. Each window is \
      \drawn as "
      c "index:name"
      " followed by any flags:"
    ascii
      [ "  *   the current window"
      , "  -   the last window (where C-b l goes)"
      , "  #   activity seen here since you last looked   (monitor-activity)"
      , "  !   a bell rang here                            (monitor-bell)"
      , "  ~   silent for a while                          (monitor-silence)"
      , "  M   this window holds the marked pane           (Day 12)"
      , "  Z   the active pane in it is zoomed             (Day 3)"
      ]
    p_ $ do
      "The last three of those are off until you turn them on, which is Day 10's business. "
      "For now just learn to read "
      c "*"
      " and "
      c "-"
      " at a glance; they answer “where am I and where does "
      k "C-b l"
      " take me” without thinking."

  block "Today's habit" $ do
    p_ $ do
      "Stop opening new terminal windows. When you catch yourself reaching for the terminal \
      \emulator's own “new tab”, use "
      k "C-b c"
      " instead and give it a name. By tomorrow evening you want the status line to describe \
      \your work rather than list four copies of "
      c "zsh"
      "."

cheat :: Html ()
cheat = do
  cfg
    [ "C-b c          # new window (lowest free index)"
    , "C-b ,          # rename it — and stop it renaming itself"
    , "C-b l          # the last window: the switch you will use most"
    , "C-b 0..9       # jump by index;  C-b '  prompts for higher ones"
    , "C-b w          # interactive tree, with previews, tagging and filtering"
    , "C-b &          # kill window (asks);  C-b .  move it to another index"
    ]
  p_ $ do
    "Status line: "
    c "index:name"
    " plus "
    c "*"
    " current, "
    c "-"
    " last, "
    c "Z"
    " zoomed, "
    c "#"
    " activity, "
    c "!"
    " bell, "
    c "~"
    " silent, "
    c "M"
    " marked."
