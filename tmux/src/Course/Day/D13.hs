module Course.Day.D13 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
  Day
    { dayNum = 13
    , dayTitle = "Hooks, popups and menus"
    , daySubtitle = "Making tmux react on its own, and building interfaces of your own."
    , dayMinutes = 35
    , dayLevel = "advanced"
    , dayManRef = "HOOKS, STATUS LINE (menus and popups)"
    , dayTags = ["hooks", "display-popup", "display-menu"]
    , dayGoals =
        [ "run commands automatically when tmux does something, with the right scope"
        , "put a shell, a picker or a note in a popup over your work, and dismiss it"
        , "build menus and prompts so a multi-step operation becomes one key"
        ]
    , dayDiagram = Just d13diagram
    , dayBody = body
    , dayKeys =
        [ ("C-b C-g", "Scratch shell in a popup (today's binding).")
        , ("C-b C-j", "Fuzzy session switcher in a popup (today's binding).")
        , ("C-b C-n", "Prompt for a name and create a session (today's binding).")
        , ("C-b C-s", "Your own session menu (today's binding).")
        ]
    , dayCmds =
        [ ("set-hook -g name 'cmd'", "Run a command when something happens.")
        , ("set-hook -g name[1] 'cmd'", "Hooks are arrays; index them to keep several.")
        , ("set-hook -u -g name", "Remove a hook.")
        , ("set-hook -R name", "Fire a hook right now, by hand.")
        , ("show-hooks -g", "List the hooks that are set.")
        , ("display-popup -E 'cmd'", "Run a command in a box over the panes; " <> c "-E" <> " closes it on exit. Alias " <> c "popup" <> ".")
        , ("display-menu -T title n k cmd", "Show a menu of name/key/command triples. Alias " <> c "menu" <> ".")
        , ("command-prompt -p 'name:' 'cmd %%'", "Ask for input; " <> c "%%" <> " is the answer.")
        , ("command-prompt -I '#S' 'cmd %%'", "Pre-fill the prompt with something.")
        , ("confirm-before -p 'sure? (y/n)' cmd", "Ask before doing something irreversible.")
        , ("display-message -d 0 'text'", "A message that stays until a key is pressed.")
        ]
    , dayOpts =
        [ ("popup-style", "Style for the popup's interior; " <> opt "popup-border-style" <> " for its edge.")
        , ("popup-border-lines", "single, rounded, double, heavy, simple, padded, none.")
        , ("menu-style", "Style for menus; " <> opt "menu-selected-style" <> " for the highlighted item.")
        ]
    , dayConfig = day13config
    , dayDrills =
        [ "Add today's config and try each binding in turn. The popup shell (" <> k "C-b C-g"
            <> ") is the one that changes daily habits: a throwaway command without disturbing \
            \your layout."
        , "Watch hooks fire. Set " <> c "set-hook -g after-split-window 'display-message \"split: #{pane_index}\"'"
            <> " and split a few times. Then remove it with " <> c "set-hook -ug after-split-window" <> "."
        , "Discover which hooks exist: " <> c "tmux show-hooks -g | head -40" <> " lists the "
            <> c "after-*" <> " ones, and the man page's HOOKS section lists the rest. Note \
            \that almost every command has an " <> c "after-" <> " hook."
        , "Scope a hook: set one on a single session (" <> c "set-hook '…'" <> " without "
            <> c "-g" <> ") and confirm it does not fire in your other sessions."
        , "Use the format variables a hook gets: "
            <> c "set-hook -g pane-exited 'display-message \"#{hook}: #{hook_pane}\"'" <> "."
        , "Build a menu of your own with three entries you actually use. Bind it. Note that a \
          \menu item's name is itself a format, so items can grey themselves out."
        , "Make a prompt that takes two answers: "
            <> c "command-prompt -p 'session:,window:' \"new-window -t '%1' -n '%2'\"" <> "."
        , "If you have " <> c "fzf" <> ", use " <> k "C-b C-j" <> " for the rest of the week \
          \instead of " <> k "C-b s" <> " and see which you prefer."
        ]
    , dayQuiz =
        [ ( "Why are hooks stored as arrays?"
          , p_ $ do
              "So that several things can hang off one event without overwriting each other. "
              c "set-hook -g after-split-window[0] …"
              " and "
              c "…[1] …"
              " both run, in order. Setting a hook "
              i_ "without"
              " an index clears the array and sets element zero — which is exactly the trap: \
              \two plugins that each “set” the same hook will silently clobber one another."
          )
        , ( "What is the difference between a popup and a pane?"
          , p_ $ do
              "A popup is not part of any window's layout — it is drawn over the top of \
              \whatever is there and takes no space from it, and it belongs to a "
              i_ "client"
              " rather than to a window. That makes it right for things that are transient: a \
              \picker, a quick lookup, a scratch shell. A pane is durable, survives detaching, \
              \and can be broken out and moved. If you want the thing to still be there \
              \tomorrow, it should be a pane."
          )
        , ( "In " <> c "command-prompt -p 'name:' \"new-session -d -s '%%'\"" <> ", what is "
              <> c "%%" <> " and why is it quoted?"
          , p_ $ do
              c "%%"
              " is replaced by the user's answer before the command is executed ("
              c "%1"
              " … "
              c "%9"
              " for multiple prompts). It is quoted because the answer is arbitrary text — a \
              \space in it would otherwise split into two arguments. "
              c "%%%"
              " is the variant that also escapes quotation marks, for when the answer is going \
              \somewhere that will be parsed again."
          )
        , ( "You set " <> c "after-select-pane" <> " to run something, and tmux appears to hang \
            \or loop. What is the likely cause?"
          , p_ $ do
              "A hook whose command triggers the same hook. tmux does guard the obvious case — \
              \a command's "
              c "after-"
              " hook does not fire when that command is run "
              i_ "from a hook"
              " — but you can still build cycles through two hooks that trigger each other, or \
              \pick an event that fires far more often than you assumed. Prefer specific events \
              \("
              c "pane-exited"
              ", "
              c "session-created"
              ") over the very chatty ones, and keep hook commands cheap: they run on tmux's \
              \command queue, so a slow "
              c "run-shell"
              " without "
              c "-b"
              " blocks everything behind it."
          )
        ]
    , dayCheat = cheat
    }

-- ---------------------------------------------------------------------------

d13diagram :: Diagram
d13diagram =
  (diagram
     "An event fires a hook, which is an array of commands; commands may also open a popup, a \
     \menu or a prompt, each of which runs further commands, all going through the same command \
     \queue."
     body')
    { dgCaption = do
        "Two directions into the same queue. "
        b_ "Hooks"
        " are tmux reacting on its own — no key was pressed. "
        b_ "Popups, menus and prompts"
        " are you building an interface for a human. Both end up as ordinary commands, which is \
        \why a hook can open a menu and a menu item can set a hook."
    , dgRankdir = "LR"
    , dgRanksep = "0.6"
    }
  where
    body' =
      T.unlines
        [ "  ev   [label=\"an event\\n(a pane exits, a client\\nattaches, a bell rings)\", fillcolor=\"#f4efe6\"];"
        , "  hook [label=\"a hook\\n(an array of commands)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
        , "  key  [label=\"a key press\", fillcolor=\"#f4efe6\"];"
        , "  pop  [label=\"a popup\\n(display-popup)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  menu [label=\"a menu\\n(display-menu)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  pr   [label=\"a prompt\\n(command-prompt)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  q    [label=\"the command queue\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  eff  [label=\"a change to\\nthe server's state\", fillcolor=\"#f4efe6\"];"
        , ""
        , "  ev   -> hook [label=\"  fires\"];"
        , "  hook -> q    [label=\"  appends to\"];"
        , "  key  -> pop; key -> menu; key -> pr;"
        , "  key  -> q    [label=\"  appends to\"];"
        , "  pop  -> q    [label=\"  its command\\l  runs through\\l\"];"
        , "  menu -> q;"
        , "  pr   -> q    [label=\"  %% substituted,\\l  then\\l\"];"
        , "  q    -> eff  [label=\"  produces\"];"
        , "  eff  -> ev   [label=\"  which is itself\\l  an event\\l\", style=dashed, constraint=false];"
        , "  { rank=same; pop; menu; pr; hook; }"
        ]

-- ---------------------------------------------------------------------------

day13config :: [ConfBlock]
day13config =
  [ ConfBlock
      "A scratch shell floating over the work, in the same directory, gone when you exit it.\n\
      \Replaces the reflex of splitting a pane for one command and then closing it again."
      "bind -N \"Scratch shell in a popup\" C-g \\\n\
      \  display-popup -E -w 80% -h 70% -d \"#{pane_current_path}\""
  , ConfBlock
      "Fuzzy session switching, if you have fzf. This is the single binding most likely to\n\
      \replace an existing habit: it beats C-b s once you have more than four sessions."
      "bind -N \"Switch session (fzf)\" C-j \\\n\
      \  display-popup -E -w 60% -h 50% \\\n\
      \    \"tmux ls -F '#{session_name}' | fzf --reverse | xargs -r tmux switch-client -t\""
  , ConfBlock
      "Create a named session without leaving the keyboard. %% is the answer to the prompt."
      "bind -N \"New named session\" C-n \\\n\
      \  command-prompt -p \"new session:\" \\\n\
      \    \"new-session -d -s '%%' -c '#{pane_current_path}' ; switch-client -t '%%'\""
  , ConfBlock
      "A menu of your own. Each entry is a name, a shortcut key and a command; an empty name\n\
      \is a separator, and a name beginning with '-' is greyed out."
      "bind -N \"Session menu\" C-s \\\n\
      \  display-menu -T \"#[align=centre]#{session_name}\" -x C -y C \\\n\
      \    \"New session\"  n \"command-prompt -p name: { new-session -d -s '%%' ; switch-client -t '%%' }\" \\\n\
      \    \"Rename\"       r \"command-prompt -I '#S' { rename-session '%%' }\" \\\n\
      \    \"\" \\\n\
      \    \"Detach\"       d \"detach-client\" \\\n\
      \    \"Kill session\" X \"confirm-before -p 'kill #S? (y/n)' kill-session\""
  , ConfBlock
      "Say something when a pane's command dies badly. Pairs with remain-on-exit failed from\n\
      \Day 11: the pane stays, and this tells you why."
      "set-hook -g pane-died 'display-message \"pane #{pane_index}: exited #{pane_dead_status}\"'"
  ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
  block "tmux reacting on its own" $ do
    p_ [class_ "lede"] $ do
      "A hook is a command that runs when something happens, with no key pressed. Nearly every \
      \tmux command has an "
      c "after-"
      " hook, and there are a few dozen more named after events — a client attaching, a pane \
      \dying, a bell ringing, a layout changing."
    fig
    sh
      [ "$ tmux set-hook -g after-split-window 'select-layout -E'"
      , "$ tmux show-hooks -g | head"
      , "$ tmux set-hook -ug after-split-window        # remove it again"
      ]
    p_ $ do
      "Hooks are stored as array options, which is both a feature and a trap. "
      c "set-hook -g name[1] '…'"
      " adds a second command to the same event; "
      c "set-hook -g name '…'"
      " without an index "
      b_ "clears the array"
      " and sets element zero. Two things configuring the same hook the careless way will \
      \silently overwrite each other."
    p_ $ do
      "Hooks have scope, like options: global with "
      c "-g"
      ", or attached to a session, window or pane. And inside a hook you get variables about \
      \what triggered it — "
      c "#{hook}"
      ", "
      c "#{hook_pane}"
      ", "
      c "#{hook_session_name}"
      ", "
      c "#{hook_window}"
      "."
    p_ "A few that earn their place:"
    cfg
      [ "# say why a pane died (with remain-on-exit failed, the pane is still there)"
      , "set-hook -g pane-died 'display-message \"pane #{pane_index}: exit #{pane_dead_status}\"'"
      , ""
      , "# never silently swallow a broken binding again"
      , "set-hook -g command-error 'display-message -d 0 \"command failed\"'"
      , ""
      , "# always spread panes evenly after a split"
      , "set-hook -g after-split-window 'select-layout -E'"
      , ""
      , "# light and dark terminal themes, if your terminal reports them"
      , "set-hook -g client-light-theme 'source-file ~/.tmux/light.conf'"
      , "set-hook -g client-dark-theme  'source-file ~/.tmux/dark.conf'"
      ]
    gotcha $ p_ $ do
      "Hook commands run on the same command queue as everything else. A "
      c "run-shell"
      " without "
      c "-b"
      " inside a frequently-fired hook will make tmux feel sticky, because every other command \
      \waits behind it. Use "
      c "-b"
      ", prefer "
      c "if-shell -F"
      " over "
      c "if-shell"
      ", and choose specific events over chatty ones."

  block "Popups" $ do
    p_ $ do
      c "display-popup"
      " runs a command in a box drawn over the panes. It takes no space from the layout, it \
      \belongs to the client rather than a window, and with "
      c "-E"
      " it closes itself when the command exits."
    sh
      [ "$ tmux display-popup -E -w 80% -h 70% -d '#{pane_current_path}'   # a scratch shell"
      , "$ tmux display-popup -E -w 60% -h 60% -T ' git log ' 'git log --oneline | less'"
      , "$ tmux display-popup -E -w 50% -h 40% 'man tmux'"
      ]
    p_ $ do
      "Position and size take percentages or cells, plus the special values "
      c "C"
      " (centre), "
      c "M"
      " (mouse), "
      c "P"
      " (the pane), "
      c "W"
      " (the window's spot on the status line). "
      c "-T"
      " sets a title, "
      c "-b rounded"
      " picks the border style, "
      c "-B"
      " removes it entirely."
    p_ $ do
      "The pattern that changes how people work is the picker: run something interactive in the \
      \popup and have it act on tmux when you choose. Today's "
      k "C-b C-j"
      " does that with "
      c "fzf"
      ":"
    cfg
      [ "bind C-j display-popup -E -w 60% -h 50% \\"
      , "  \"tmux ls -F '#{session_name}' | fzf --reverse | xargs -r tmux switch-client -t\""
      ]
    p_ $ do
      "The same shape gives you a fuzzy window switcher, a project opener that runs your \
      \bootstrap script from Day 11, a "
      c "git branch"
      " chooser, or a paste-buffer picker. It is the most reusable four lines in this course."
    note $ p_ $ do
      "A popup is transient by design: it is not in any layout, and it does not survive \
      \detaching. If you find yourself wanting the thing to still be there tomorrow, you wanted \
      \a pane — or a "
      i_ "floating pane"
      " ("
      k "C-b *"
      " from Day 3), which hovers like a popup but is a real pane."

  block "Menus" $ do
    p_ $ do
      c "display-menu"
      " takes triples: a name, a shortcut key, and a command. An empty name is a separator; a \
      \name starting with "
      c "-"
      " is shown greyed out and cannot be chosen. Because the names are formats, a menu can \
      \disable its own entries depending on state — which is exactly what the built-in "
      k "C-b >"
      " menu does with “Unzoom” and “Swap Marked”."
    cfg
      [ "bind C-s display-menu -T \"#[align=centre]#{session_name}\" -x C -y C \\"
      , "  \"New session\"  n \"command-prompt -p name: { new-session -d -s '%%' }\" \\"
      , "  \"Rename\"       r \"command-prompt -I '#S' { rename-session '%%' }\" \\"
      , "  \"\" \\"
      , "  \"Detach\"       d \"detach-client\" \\"
      , "  \"Kill session\" X \"confirm-before -p 'kill #S? (y/n)' kill-session\""
      ]
    p_ $ do
      "Menus are worth building for operations you do rarely enough that you forget the key but \
      \often enough to want them. They are also the friendly face of a dangerous command: put "
      c "confirm-before"
      " behind the destructive entries and the menu becomes safer than the raw binding."

  block "Prompts and confirmations" $ do
    p_ $ do
      c "command-prompt"
      " asks for input on the status line and substitutes it into a command. "
      c "%%"
      " is the first answer; with "
      c "-p a,b,c"
      " you get three prompts and "
      c "%1"
      ", "
      c "%2"
      ", "
      c "%3"
      "."
    cfg
      [ "bind C-n command-prompt -p \"new session:\" \\"
      , "  \"new-session -d -s '%%' -c '#{pane_current_path}' ; switch-client -t '%%'\""
      , ""
      , "# pre-fill with the current name, so renaming is an edit rather than a retype"
      , "bind , command-prompt -I \"#W\" \"rename-window -- '%%'\""
      ]
    p_ $ do
      "Useful flags: "
      c "-I"
      " pre-fills the input, "
      c "-1"
      " accepts a single key press, "
      c "-N"
      " accepts only digits, "
      c "-i"
      " re-runs the command on every keystroke (that is how incremental search in copy mode \
      \works), and "
      c "-T"
      " tells tmux what kind of completion to offer when you press Tab — "
      c "command"
      ", "
      c "target"
      ", "
      c "window-target"
      " or "
      c "search"
      "."
    p_ $ do
      c "confirm-before -p 'prompt' command"
      " is the small sibling: it is what stands between "
      k "C-b &"
      " and an accidentally destroyed window. Wrap your own destructive bindings in it."

  block "Where this leaves you" $ do
    p_ $ do
      "With hooks, popups, menus and prompts you have everything the popular tmux plugins are \
      \built out of. A session manager is a popup plus "
      c "switch-client"
      ". A “resurrect” plugin is "
      c "capture-pane"
      ", "
      c "#{window_layout}"
      " and a script. A theme is a handful of style options. That is worth knowing before you \
      \install four thousand lines of someone else's shell to get a feature you could write in \
      \six."

cheat :: Html ()
cheat = do
  cfg
    [ "set-hook -g EVENT 'cmd'      # hooks are ARRAYS: use [1], [2] to keep several"
    , "set-hook -ug EVENT           # remove      show-hooks -g       # list"
    , "  after-<any command>        pane-died  pane-exited  session-created"
    , "  client-attached  client-detached  alert-bell  window-layout-changed"
    , "  command-error    client-light-theme / -dark-theme"
    , "  inside a hook: #{hook} #{hook_pane} #{hook_session_name} #{hook_window}"
    , ""
    , "display-popup -E -w 60% -h 50% -d DIR -T ' title ' 'cmd'"
    , "  -x/-y: C centre  M mouse  P pane  W window in the status line"
    , "display-menu -T title  \"Name\" key \"cmd\"  …    ('' = separator, '-…' = disabled)"
    , "command-prompt -p 'a:,b:' \"cmd '%1' '%2'\"     -I prefill  -1 one key  -N digits"
    , "confirm-before -p 'sure? (y/n)' cmd"
    ]
