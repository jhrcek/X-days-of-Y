module Course.Day.D08 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 8
        , dayTitle = "Key bindings and key tables"
        , daySubtitle = "Where keys actually live, and how to add your own without wrecking the defaults."
        , dayMinutes = 35
        , dayLevel = "intermediate"
        , dayManRef = "KEY BINDINGS"
        , dayTags = ["bind-key", "key tables", "tmux.conf"]
        , dayGoals =
            [ "explain what happens between pressing a key and a tmux command running"
            , "bind keys with and without the prefix, make them repeat, and give them notes"
            , "build a modal key table of your own, the way vim's leader key works"
            ]
        , dayDiagram = Just d8diagram
        , dayBody = body
        , dayKeys =
            [ ("C-b /", "Describe a key: press it and tmux tells you what it is bound to.")
            , ("C-b ?", "List every binding in every table — really " <> c "list-keys -N" <> ".")
            ]
        , dayCmds =
            [ ("bind-key c new-window", "Bind in the prefix table. Alias " <> c "bind" <> ".")
            , ("bind-key -n M-Left select-pane -L", "Bind without a prefix (" <> c "-n" <> " = " <> c "-T root" <> ").")
            , ("bind-key -r H resize-pane -L", "Repeatable: keep tapping without re-pressing the prefix.")
            , ("bind-key -N \"note\" x cmd", "Attach a note, shown by " <> k "C-b ?" <> ".")
            , ("bind-key -T mytable g cmd", "Bind in a table of your own.")
            , ("unbind-key -T prefix x", "Remove a binding. Alias " <> c "unbind" <> ".")
            , ("list-keys -T copy-mode-vi", "Read a whole mode as data. Alias " <> c "lsk" <> ".")
            , ("list-keys -N", "Only keys with notes, in a readable form.")
            , ("send-keys -X copy-selection", "Send a command into a mode.")
            , ("send-prefix", "Pass the prefix key through to the program.")
            , ("switch-client -T mytable", "Make the next key be looked up in another table.")
            ]
        , dayOpts =
            [ ("prefix", "The prefix key. " <> c "None" <> " disables it entirely.")
            , ("prefix2", "A second prefix key, for when you want both " <> k "C-b" <> " and " <> k "C-a" <> ".")
            , ("repeat-time", "Milliseconds the prefix stays live after a " <> c "-r" <> " key. Default 500.")
            , ("initial-repeat-time", "The same, for the first press of a repeat sequence.")
            , ("key-table", "Which table a client starts in. The lever behind modal setups.")
            ]
        , dayConfig = day8config
        , dayDrills =
            [ "Press "
                <> k "C-b /"
                <> " and then some key you are unsure about. tmux tells you \
                   \what it runs. Do it for "
                <> k "C-b E"
                <> ", "
                <> k "C-b <"
                <> " and "
                <> k "C-b >"
                <> " — three defaults most people never discover."
            , "Add today's config blocks and reload with "
                <> k "C-b R"
                <> ". Then split a pane and \
                   \confirm the new pane starts in the same directory."
            , "Run "
                <> c "tmux lsk -T copy-mode-vi | head -30"
                <> " and find the binding for "
                <> k "v"
                <> ". Then add your own: bind "
                <> k "Y"
                <> " in that table to "
                <> c "send-keys -X copy-pipe-line-and-cancel"
                <> "."
            , "Bind something without a prefix and feel the difference: "
                <> c "bind -n M-Enter resize-pane -Z"
                <> ". Then unbind it — "
                <> k "M-Enter"
                <> " is a real key some programs want."
            , "Make a repeat key of your own and compare: bind "
                <> k "C-b y"
                <> " to "
                <> c "next-window"
                <> " with and without "
                <> c "-r"
                <> ", and tap it three times."
            , "Build a two-key chord. Add the three lines from the “Modal tables” section and check \
              \that "
                <> k "C-b g"
                <> k "s"
                <> " opens a git status window."
            , "Give every custom binding a "
                <> c "-N"
                <> " note, then look at "
                <> k "C-b ?"
                <> " — your own bindings now document themselves in the same list as the defaults."
            ]
        , dayQuiz =
            [
                ( "What is the difference between " <> c "bind x" <> " and " <> c "bind -n x" <> "?"
                , p_ $ do
                    c "bind x"
                    " puts the binding in the "
                    b_ "prefix"
                    " table, so it fires on "
                    k "C-b x"
                    ". "
                    c "bind -n x"
                    " is short for "
                    c "-T root"
                    ", the table consulted for keys pressed with no prefix at all — so it fires on a \
                    \bare "
                    k "x"
                    ", stealing that key from every program running inside tmux. Root-table bindings \
                    \are for modified keys nothing else wants ("
                    k "M-Left"
                    ", "
                    k "S-F5"
                    "), never for letters."
                )
            ,
                ( "Why can you tap "
                    <> k "C-b"
                    <> k "C-Left"
                    <> k "Left"
                    <> k "Left"
                    <> " and keep resizing, but not do the same with "
                    <> k "C-b"
                    <> k "n"
                    <> "?"
                , p_ $ do
                    "The resize keys are bound with "
                    c "-r"
                    ". After a repeatable key fires, tmux keeps the client in the prefix table for "
                    opt "repeat-time"
                    " milliseconds (500 by default), so the next key is treated as though the prefix \
                    \had been pressed again. "
                    c "next-window"
                    " is bound without "
                    c "-r"
                    ", so the prefix is consumed immediately. You can change that: "
                    c "bind -r n next-window"
                    "."
                )
            ,
                ( "You want "
                    <> k "C-b"
                    <> " to reach the program in the pane. What happens, and why \
                       \does "
                    <> k "C-b"
                    <> k "C-b"
                    <> " work?"
                , p_ $ do
                    "The first "
                    k "C-b"
                    " is swallowed and puts the client into the prefix table. The second is looked up "
                    i_ "in that table"
                    ", where it is bound to "
                    c "send-prefix"
                    " — a command whose only job is to emit the prefix key into the pane. It is an \
                    \ordinary binding, so you could rebind it, and if you set a "
                    opt "prefix2"
                    " there is a "
                    c "send-prefix -2"
                    " for that one too."
                )
            ,
                ( "How would you build a “leader key” with several keys under it, like "
                    <> c "g"
                    <> " then "
                    <> c "s"
                    <> " for git status?"
                , do
                    p_ $ do
                        "With a key table of your own. "
                        c "switch-client -T name"
                        " tells the client to look the "
                        i_ "next"
                        " key up in that table and then fall back to normal:"
                    cfg
                        [ "bind -T git s new-window -n git 'git status; $SHELL'"
                        , "bind -T git l new-window -n git 'git log --oneline --graph; $SHELL'"
                        , "bind g switch-client -T git"
                        ]
                    p_
                        "Tables are how copy mode works too, so this is not a trick bolted on the \
                        \side — it is the same mechanism the built-in modes use."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d8diagram :: Diagram
d8diagram =
    ( diagram
        "A key press is looked up in the client's current key table; the root table handles \
        \unprefixed keys, the prefix table handles keys after the prefix, copy-mode tables handle \
        \keys while a pane is in a mode, and a binding's command is put on the command queue."
        body'
    )
        { dgCaption = do
            "There is no special case anywhere in this diagram. The prefix key is just a binding in \
            \the root table that switches tables; copy mode is just another table; your own \
            \“leader” is a table you make. The only state involved is "
            b_ "which table this client is currently in"
            ", and "
            c "switch-client -T"
            " is the lever that moves it."
        , dgRankdir = "LR"
        , dgRanksep = "0.6"
        }
  where
    body' =
        T.unlines
            [ "  press [label=\"a key press\", fillcolor=\"#f4efe6\"];"
            , "  tbl   [label=\"the client's\\ncurrent key table\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  root  [label=\"root\\n(no prefix)\"];"
            , "  pfx   [label=\"prefix\\n(after C-b)\"];"
            , "  copy  [label=\"copy-mode-vi\\ncopy-mode\"];"
            , "  mine  [label=\"a table of\\nyour own\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  bind  [label=\"a binding\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  cmd   [label=\"a tmux command\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  pane  [label=\"the program\\nin the pane\", fillcolor=\"#f4efe6\"];"
            , ""
            , "  press -> tbl  [label=\"  is looked up in\"];"
            , "  tbl -> root; tbl -> pfx; tbl -> copy; tbl -> mine;"
            , "  root -> bind  [label=\"  may contain\"];"
            , "  pfx  -> bind;"
            , "  copy -> bind;"
            , "  mine -> bind;"
            , "  bind -> cmd   [label=\"  runs\"];"
            , "  cmd  -> tbl   [label=\"  switch-client -T\\l  changes\\l\", style=dashed];"
            , "  press -> pane [label=\"  otherwise reaches\", style=dashed];"
            , "  { rank=same; root; pfx; copy; mine; }"
            ]

-- ---------------------------------------------------------------------------

day8config :: [ConfBlock]
day8config =
    [ ConfBlock
        "New panes and windows should open where you already are. This is the single highest\n\
        \value rebinding in tmux: without it every split starts in your home directory."
        "bind -N \"Split top/bottom, same directory\" '\"' split-window -v -c \"#{pane_current_path}\"\n\
        \bind -N \"Split left/right, same directory\" %   split-window -h -c \"#{pane_current_path}\"\n\
        \bind -N \"New window, same directory\"       c   new-window   -c \"#{pane_current_path}\""
    , ConfBlock
        "Mnemonic aliases for the same two splits: the key looks like the border it makes.\n\
        \This takes '-' away from delete-buffer, which you can still reach with C-b = then d."
        "bind -N \"Split left/right\" '|' split-window -h -c \"#{pane_current_path}\"\n\
        \bind -N \"Split top/bottom\" '-' split-window -v -c \"#{pane_current_path}\""
    , ConfBlock
        "Type into every pane of this window at once - for the same command on four servers.\n\
        \Dangerous enough that the binding announces the state it just moved to."
        "bind -N \"Toggle synchronize-panes\" S \\\n\
        \  set -w synchronize-panes \\; \\\n\
        \  display-message \"synchronize-panes #{?synchronize-panes,ON,off}\""
    , ConfBlock
        "Copy mode: y copies to a tmux buffer and to the system clipboard, Y does a whole line.\n\
        \Set copy-command to your platform's tool - wl-copy, xclip -sel c, or pbcopy."
        "set -s copy-command 'wl-copy'\n\
        \bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel\n\
        \bind -T copy-mode-vi Y send-keys -X copy-pipe-line-and-cancel"
    ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "What a key press actually is" $ do
        p_ [class_ "lede"] $ do
            "A binding is a stored command plus the table it lives in. When you press a key, tmux \
            \looks it up in "
            i_ "whichever table the client is currently in"
            ", and if it finds a binding it puts that command on the command queue. If it does not, \
            \the key goes through to the program in the pane."
        p_ $ do
            "Four tables matter. "
            c "root"
            " is for keys with no prefix. "
            c "prefix"
            " is for keys after "
            k "C-b"
            ". "
            c "copy-mode"
            " and "
            c "copy-mode-vi"
            " are consulted while a pane is in copy mode. And you can invent your own, which is the \
            \last section of today."
        fig
        why $ p_ $ do
            "The prefix itself is not special-cased in the source: "
            k "C-b"
            " is a binding in the root table whose effect is “put this client in the prefix table for \
            \one key”. That is why "
            opt "prefix2"
            " can exist, why "
            c "set -g prefix None"
            " is legal, and why a table of your own behaves exactly like the built-in ones."

    block "Reading what you already have" $ do
        p_ $ do
            "Before binding anything, learn to interrogate. "
            k "C-b /"
            " ("
            c "describe-key"
            ") prompts for a key and tells you what it does — far faster than scrolling "
            k "C-b ?"
            "."
        sh
            [ "$ tmux lsk -T prefix | head -5        # every prefix binding, as bind-key commands"
            , "$ tmux lsk -N -T prefix               # only the ones with notes, human-readable"
            , "$ tmux lsk -T copy-mode-vi            # the whole of vi copy mode, as data"
            , "$ tmux lsk -T root                    # mouse bindings live here"
            ]
        p_ $ do
            "That last one is worth a minute: every mouse behaviour in tmux — click to select a pane, \
            \drag a border to resize, wheel to enter copy mode, right-click for a menu — is an \
            \ordinary root-table binding with a name like "
            c "MouseDown1Pane"
            " or "
            c "WheelUpPane"
            ". There is no separate mouse subsystem. Day 12 rebinds some of them."

    block "The four flags" $ do
        defs
            [
                ( c "-n"
                , do
                    "Short for "
                    c "-T root"
                    ": bind the key with no prefix. Reserve this for modified keys that no program \
                    \wants — "
                    k "M-Left"
                    ", "
                    k "S-F1"
                    ", "
                    k "C-M-h"
                    ". Binding a bare letter here takes it away from vim, your shell and everything \
                    \else, forever."
                )
            ,
                ( c "-r"
                , do
                    "Repeatable. After the command runs, the client stays in the prefix table for "
                    opt "repeat-time"
                    " milliseconds, so you can tap the key again without the prefix. The default \
                    \resize bindings use it; "
                    c "next-window"
                    " is a good candidate to add it to."
                )
            ,
                ( c "-N \"note\""
                , do
                    "Attach a description. It shows up in "
                    k "C-b ?"
                    " and in customize mode alongside the built-in notes. Costs nothing, and turns \
                    \your config into its own documentation."
                )
            ,
                ( c "-T table"
                , "Bind in a named table. Without it you get the prefix table."
                )
            ]
        p_ $ do
            "Key names follow a small grammar: "
            c "C-"
            " or "
            c "^"
            " for control, "
            c "M-"
            " for alt/meta, "
            c "S-"
            " for shift, plus names like "
            c "Up"
            ", "
            c "PageUp"
            ", "
            c "Enter"
            ", "
            c "Escape"
            ", "
            c "Space"
            ", "
            c "Tab"
            ", "
            c "BSpace"
            ", "
            c "F1"
            "–"
            c "F12"
            ". To bind a quote character you have to quote it, which reads oddly the first time:"
        cfg
            [ "bind-key '\"' split-window -v"
            , "bind-key \"'\" new-window"
            ]

    block "Bindings worth having" $ do
        p_ $ do
            "Today's config adds four groups. The first is the one everybody eventually discovers, \
            \usually after a year of typing "
            c "cd"
            " in every new pane:"
        cfg
            [ "bind '\"' split-window -v -c \"#{pane_current_path}\""
            , "bind %   split-window -h -c \"#{pane_current_path}\""
            , "bind c   new-window   -c \"#{pane_current_path}\""
            ]
        p_ $ do
            c "#{pane_current_path}"
            " is a format — tomorrow's subject — evaluated when the key is pressed. Note that this "
            i_ "rebinds the defaults rather than adding new keys"
            ", which is the right call here: you want the muscle memory you already have to do the \
            \better thing."
        p_ $ do
            "The second group adds "
            k "C-b |"
            " and "
            k "C-b -"
            " as shape-mnemonic aliases. The third makes "
            opt "synchronize-panes"
            " reachable — type once, into every pane in the window, which is how you run the same \
            \command on four servers at once. Because it is easy to forget it is on, the binding \
            \reports the state it just switched to."
        p_ $ do
            "The fourth teaches copy mode to talk to your system clipboard. "
            c "copy-pipe-and-cancel"
            " with no argument pipes the selection to the "
            opt "copy-command"
            " option, so setting that once fixes every copy path at the same time."
        gotcha $ p_ $ do
            "Sourcing your config does not remove bindings you deleted from it — sourcing only "
            i_ "runs"
            " what is there. If you bind something, change your mind and delete the line, the \
            \binding survives until you "
            c "unbind"
            " it or restart the server. When a config starts behaving oddly, "
            c "tmux kill-server"
            " and try again from cold."

    block "Modal tables: your own leader key" $ do
        p_ $ do
            "This is the part that most tmux users never reach, and it takes three lines. "
            c "switch-client -T name"
            " puts the client into a table for exactly one key press, after which it falls back to \
            \normal. That gives you vim-style multi-key sequences:"
        cfg
            [ "# C-b g then a letter: a small git menu"
            , "bind -T git s new-window -n git 'git status; read'"
            , "bind -T git l new-window -n git 'git log --oneline --graph -30; read'"
            , "bind -T git d new-window -n git 'git diff; read'"
            , "bind -N \"git prefix\" g switch-client -T git"
            ]
        p_ $ do
            "Nest them and you have arbitrary chords. Set "
            opt "key-table"
            " and you have modes — a client that starts in a table of your own, with the normal keys \
            \reachable through an explicit switch, which is how people build read-only or \
            \presentation modes."
        tip $ p_ $ do
            "Two escape hatches for when a binding fights with a program: "
            c "send-keys"
            " can push any key into a pane regardless of bindings, and the "
            c "Any"
            " key name matches every key that has no more specific binding — useful as a catch-all \
            \inside a custom table so that a stray keystroke leaves the mode instead of doing \
            \something surprising."

cheat :: Html ()
cheat = do
    cfg
        [ "bind    key cmd     # prefix table      C-b /   describe a key"
        , "bind -n key cmd     # root table (no prefix) — modified keys only"
        , "bind -r key cmd     # repeatable within repeat-time (default 500 ms)"
        , "bind -N \"note\" ...   # self-documenting; shows up in C-b ?"
        , "bind -T tbl key cmd # a table of your own"
        , "unbind [-T tbl] key # remove one"
        , ""
        , "lsk -T prefix       # read the defaults as bind-key commands"
        , "lsk -T copy-mode-vi # copy mode is just a key table"
        , "lsk -T root         # so is the entire mouse"
        , ""
        , "bind g switch-client -T git   # + bind -T git s ...  = a leader key"
        ]
