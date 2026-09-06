module Course.Day.D12 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 12
        , dayTitle = "Moving things around"
        , daySubtitle = "Break, join, link and swap — plus the mouse, which is just more key bindings."
        , dayMinutes = 30
        , dayLevel = "advanced"
        , dayManRef = "WINDOWS AND PANES, MOUSE SUPPORT"
        , dayTags = ["break/join", "linked windows", "mouse"]
        , dayGoals =
            [ "move a pane to another window or session, and back, without losing what is running in it"
            , "have one window appear in two sessions at once, and know when that is a good idea"
            , "rebind mouse events, and read the default ones as the ordinary bindings they are"
            ]
        , dayDiagram = Just d12diagram
        , dayBody = body
        , dayKeys =
            [ ("C-b !", "Break this pane out into a window of its own.")
            , ("C-b <", "The window menu — swap, kill, rename, new. Try it once.")
            , ("C-b >", "The pane menu — split, swap, mark, kill, respawn.")
            , ("C-b f", "Search every window for text, by name, title or visible content.")
            , ("C-b @", "Join the marked pane into this window (today's binding).")
            ]
        , dayCmds =
            [ ("break-pane -d", "Pane becomes its own window; " <> c "-d" <> " stays put. Alias " <> c "breakp" <> ".")
            , ("join-pane -t :2", "Move a pane into another window. Alias " <> c "joinp" <> ".")
            , ("join-pane -h -s %7 -t :1", "Move pane %7 beside the target, splitting left/right.")
            , ("move-pane -b -t %3", "The same command under another name, " <> c "-b" <> " to insert before.")
            , ("link-window -s api:2 -t infra:", "Make one window appear in a second session.")
            , ("unlink-window -t infra:3", "Remove it from one session, leaving the others.")
            , ("move-window -r", "Renumber the windows, closing gaps.")
            , ("swap-window -t :1", "Exchange two windows' positions.")
            , ("swap-pane -s %3 -t %5", "Exchange two panes.")
            , ("find-window -Z text", "Search names, titles and visible content. Alias " <> c "findw" <> ".")
            , ("choose-tree -Z", "The full tree; " <> k "t" <> " tags, " <> k ":" <> " runs a command on every tagged item.")
            ]
        , dayOpts =
            [ ("mouse", "Master switch. Off by default; turned on back on Day 5.")
            , ("focus-follows-mouse", "Moving the mouse into a pane selects it. Off by default.")
            , ("pane-scrollbars", "off, modal (only in copy mode), or on.")
            , ("pane-scrollbars-position", "left or right.")
            , ("pane-border-indicators", "How the active pane's border is marked: colour, arrows, both, off.")
            ]
        , dayConfig = day12config
        , dayDrills =
            [ "Break a pane out and put it back. Split a window, run something in the new pane, "
                <> k "C-b !"
                <> " to break it out, then "
                <> k "C-b m"
                <> " on it, go back, and "
                <> k "C-b @"
                <> " to pull it in. The process never restarts."
            , "Move a pane across sessions: mark it, switch to another session with "
                <> k "C-b L"
                <> ", and "
                <> k "C-b @"
                <> ". Panes are not owned by sessions in any way that \
                   \prevents this."
            , "Link a window into two sessions: "
                <> c "tmux link-window -s api:logs -t infra:"
                <> ". Change something in it from one session and watch the other. Then "
                <> c "unlink-window"
                <> " it from one."
            , "Make some gaps in your window indices by killing windows, then close them with "
                <> k "C-b M-r"
                <> " (today's binding for "
                <> c "move-window -r"
                <> ")."
            , "Use "
                <> k "C-b f"
                <> " to find a window by something that is currently "
                <> i_ "on screen"
                <> " in it, not by its name. Very few people know this searches \
                   \pane contents."
            , "Open "
                <> k "C-b >"
                <> " and "
                <> k "C-b <"
                <> ". These menus have been in tmux for \
                   \years and are almost undiscoverable — read what is in them."
            , "Read the mouse: "
                <> c "tmux lsk -T root"
                <> ". Find "
                <> c "WheelUpPane"
                <> " and \
                   \work out, from the binding, exactly why scrolling puts you into copy mode."
            , "Tag and act in bulk: "
                <> k "C-b s"
                <> ", tag two sessions with "
                <> k "t"
                <> ", \
                   \press "
                <> k ":"
                <> " and run a command against all of them."
            ]
        , dayQuiz =
            [
                ( "You " <> c "break-pane" <> " a pane running a long build. Does the build restart?"
                , p_ $ do
                    "No. A pane is a pseudo-terminal with a process group attached to it; breaking it \
                    \out changes which window "
                    i_ "displays"
                    " it, not what is running. The same is true of "
                    c "join-pane"
                    ", "
                    c "swap-pane"
                    " and moving a pane between sessions. Nothing is restarted and no output is lost."
                )
            ,
                ( "What is the difference between "
                    <> c "move-window"
                    <> " and "
                    <> c "link-window"
                    <> "?"
                , p_ $ do
                    c "move-window"
                    " takes the window out of one place and puts it in another. "
                    c "link-window"
                    " makes it appear in "
                    i_ "both"
                    " — one window, two sessions, genuinely the same object. Killing it removes it \
                    \everywhere; "
                    c "unlink-window"
                    " removes it from one session only. The status line marks linked windows, and "
                    c "#{window_linked_sessions_list}"
                    " tells you where else it lives."
                )
            ,
                ( "Why does "
                    <> c "join-pane"
                    <> " with no "
                    <> c "-s"
                    <> " sometimes work and \
                       \sometimes complain?"
                , p_ $ do
                    "Because with no source it uses "
                    b_ "the marked pane"
                    " if one is set, and the current pane otherwise. That is the whole design of the \
                    \mark: “go to the destination, then pull”. If nothing is marked and you are \
                    \already in the destination window, the command has nothing sensible to do."
                )
            ,
                ( "Mouse mode is on and you cannot select text with the mouse to paste into another \
                  \application. Why, and what do you do?"
                , p_ $ do
                    "With "
                    opt "mouse"
                    " on, tmux takes the mouse events itself — a drag becomes a copy-mode selection \
                    \into a tmux buffer, not a terminal selection. Hold "
                    b_ "Shift"
                    " while dragging and the events go to your terminal emulator instead, giving you \
                    \its native selection. That one modifier resolves nearly every complaint about \
                    \tmux and the mouse."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d12diagram :: Diagram
d12diagram =
    ( diagram
        "Panes move between windows with break-pane and join-pane; windows move between sessions \
        \with move-window, appear in several with link-window, and the marked pane is the default \
        \source for the join and swap commands."
        body'
    )
        { dgCaption = do
            "The arrows are reversible pairs, which is the thing to notice: nothing here destroys \
            \anything. "
            c "break-pane"
            " and "
            c "join-pane"
            " undo each other, as do "
            c "link-window"
            " and "
            c "unlink-window"
            ". A pane is a process attached to a pseudo-terminal, and all of these commands only \
            \change which container displays it."
        , dgRankdir = "LR"
        , dgRanksep = "0.85"
        }
  where
    body' =
        T.unlines
            [ "  pane [label=\"a pane\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  win  [label=\"a window\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  sess [label=\"a session\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  s2   [label=\"another session\", fillcolor=\"#f4efe6\"];"
            , "  mark [label=\"the marked pane\\n(C-b m, target ~)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  pane -> win  [label=\"  join-pane\\l  moves into\\l\"];"
            , "  win  -> pane [label=\"  break-pane\\l  extracts\\l\"];"
            , "  win  -> sess [label=\"  move-window\\l  moves into\\l\"];"
            , "  win  -> s2   [label=\"  link-window\\l  also shows in\\l\", style=dashed];"
            , "  mark -> pane [label=\"  is the default -s for\\l  join / swap\\l\", style=dashed];"
            , "  { rank=same; sess; s2; }"
            ]

-- ---------------------------------------------------------------------------

day12config :: [ConfBlock]
day12config =
    [ ConfBlock
        "The other half of C-b ! (break-pane): mark a pane anywhere with C-b m, come here, and\n\
        \pull it in. join-pane with no -s uses the marked pane, which is exactly what you want."
        "bind -N \"Join the marked pane here\"          @   join-pane\n\
        \bind -N \"Join the marked pane beside this\"   M-@ join-pane -h"
    , ConfBlock
        "Close the gaps in window numbering after killing a few."
        "bind -N \"Renumber windows\" M-r move-window -r"
    , ConfBlock
        "Double-clicking empty space on the status line makes a new window, the way a browser\n\
        \tab bar behaves. Mouse events are ordinary bindings in the root table."
        "bind -n DoubleClick1Status new-window -c \"#{pane_current_path}\""
    , ConfBlock
        "A scrollbar, but only while a pane is in copy mode - so it tells you where you are in\n\
        \the history without stealing a column the rest of the time."
        "set -wg pane-scrollbars modal\n\
        \set -wg pane-scrollbars-position right"
    ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Panes are not stuck where you made them" $ do
        p_ [class_ "lede"] $ do
            "A pane is a process attached to a pseudo-terminal. Which window shows it is a \
            \presentational detail, and tmux will happily change it while everything keeps running. \
            \Once that clicks, a whole class of “I should have started this somewhere else” problems \
            \disappears."
        fig
        p_ "The two commands are inverses:"
        defs
            [
                ( c "break-pane" <> " (" <> k "C-b !" <> ")"
                , "this pane leaves its window and becomes a \
                  \window of its own. "
                    <> c "-d"
                    <> " does not follow it; "
                    <> c "-n name"
                    <> " names the new window."
                )
            ,
                ( c "join-pane"
                , "a pane moves into this window, splitting it. "
                    <> c "-h"
                    <> " / "
                    <> c "-v"
                    <> " choose the direction, "
                    <> c "-b"
                    <> " puts it before, "
                    <> c "-l 30%"
                    <> " sizes it. With no "
                    <> c "-s"
                    <> " it takes the marked pane."
                )
            ]
        sh
            [ "$ tmux break-pane -d              # extract, but stay where I am"
            , "$ tmux join-pane -h -s %7 -t :1   # pull pane %7 into window 1, side by side"
            , "$ tmux join-pane -s api:2.0 -t infra:1   # across sessions; nothing restarts"
            ]
        tip $ p_ $ do
            "The ergonomic version is the mark. "
            k "C-b m"
            " on the pane you want to move, navigate to where you want it — another window, another \
            \session, does not matter — and press "
            k "C-b @"
            " from today's config. “Mark there, pull here” is much easier to think about than \
            \constructing a source target."

    block "Windows in two places at once" $ do
        p_ $ do
            "A window can be "
            b_ "linked"
            " into several sessions. It is one window, not a copy: the same panes, the same \
            \processes, the same scrollback, appearing in two window lists."
        sh
            [ "$ tmux link-window -s api:logs -t infra:      # now in both sessions"
            , "$ tmux lsw -a -F '#{window_name} -> #{window_linked_sessions_list}'"
            , "$ tmux unlink-window -t infra:3               # remove from one only"
            ]
        p_ $ do
            "The honest use case is narrow: a shared log or dashboard window that belongs to two \
            \projects. It is worth knowing mainly because it explains a piece of behaviour you would \
            \otherwise find baffling — "
            c "kill-window"
            " removes a window from "
            i_ "every"
            " session it is linked into, while "
            c "unlink-window"
            " refuses to unlink a window that lives in only one place unless you pass "
            c "-k"
            "."
        p_ $ do
            "Its plainer cousins get more use: "
            c "move-window"
            " to shift a window between sessions or indices, "
            c "swap-window"
            " to exchange two, and "
            c "move-window -r"
            " to renumber everything and close the gaps."

    block "Finding things" $ do
        p_ $ do
            k "C-b f"
            " searches for a pattern across every window — and by default it searches window "
            b_ "names, titles and visible content"
            ". Searching what is currently on screen in other windows is the part people miss; it \
            \turns “which of my eleven windows had that stack trace” into three keystrokes."
        sh
            [ "$ tmux find-window -Z 'Connection refused'   # -Z zooms the result"
            , "$ tmux find-window -N build                  # names only"
            , "$ tmux find-window -r '^ERROR'               # regular expression"
            ]
        p_ $ do
            "For structural questions there is the tree: "
            k "C-b s"
            " or "
            k "C-b w"
            ". Inside it, "
            k "f"
            " filters by a format, "
            k "t"
            " tags items, and "
            k ":"
            " runs a command against every tagged item at once. That is a bulk-edit facility for your \
            \whole workspace, hidden behind a chooser most people use only to pick a session."

    block "The mouse is just bindings" $ do
        p_ $ do
            "With "
            opt "mouse"
            " on, tmux receives mouse events as keys with names like "
            c "MouseDown1Pane"
            ", "
            c "WheelUpPane"
            ", "
            c "MouseDrag1Border"
            " and "
            c "DoubleClick1Status"
            ". They live in the root table with everything else:"
        sh
            [ "$ tmux lsk -T root | grep Wheel"
            , "bind-key -T root WheelUpPane if-shell -F \"#{||:#{alternate_on},#{pane_in_mode},…}\" \\"
            , "    { send-keys -M } { copy-mode -e }"
            ]
        p_ $ do
            "Read that and the behaviour stops being magic: if the program is using the alternate \
            \screen (like "
            c "less"
            " or vim) or the pane is already in a mode, forward the event to the program; otherwise \
            \enter copy mode. The "
            c "-e"
            " means “exit copy mode when you scroll back to the bottom”, which is why casual \
            \scrolling does not leave you stuck in a mode."
        p_ $ do
            "The event name is made of an action and a location: "
            c "Pane"
            ", "
            c "Border"
            ", "
            c "Status"
            ", "
            c "StatusLeft"
            ", "
            c "StatusRight"
            ", "
            c "StatusDefault"
            ", plus the scrollbar regions. Inside such a binding the target "
            c "{mouse}"
            " (short form "
            c "="
            ") means “where the event happened”, which is what makes one binding work for every pane."
        cfg
            [ "# middle-click a pane to zoom it"
            , "bind -n MouseDown2Pane resize-pane -Z -t '{mouse}'"
            , ""
            , "# right-click the left of the status line for a session menu (this is a default)"
            , "# tmux lsk -T root | grep MouseDown3StatusLeft"
            ]
        gotcha $ p_ $ do
            "Two mouse facts worth having in your fingers: "
            b_ "Shift-drag"
            " bypasses tmux entirely and gives you the terminal's own selection (for pasting into GUI \
            \applications), and double- or triple-clicking inside a pane selects a word or line "
            i_ "and copies it"
            " — that is a default binding running "
            c "copy-mode -H"
            ", "
            c "select-word"
            ", "
            c "copy-pipe-and-cancel"
            "."

    block "Menus you did not know were there" $ do
        p_ $ do
            k "C-b <"
            " opens a menu for the current window; "
            k "C-b >"
            " one for the current pane. Right-clicking a pane, the status line, or the session name \
            \opens the same menus. They contain swap, kill, respawn, mark, rename and split, with \
            \items that grey themselves out when they do not apply."
        p_ $ do
            "They are built with "
            c "display-menu"
            ", entirely in the default configuration — you can read the whole definition with "
            c "tmux lsk -T prefix '>'"
            ". Tomorrow you build your own."

cheat :: Html ()
cheat = do
    cfg
        [ "C-b !            break-pane      -> pane becomes its own window"
        , "C-b m … C-b @    mark, then join-pane   (join with no -s uses the mark)"
        , "join-pane -h -s %7 -t :1     move a pane anywhere, nothing restarts"
        , ""
        , "move-window -t :3 / -r       move / renumber      swap-window -t :1"
        , "link-window -s a:1 -t b:     one window, two sessions   unlink-window"
        , ""
        , "C-b f            find-window: searches names, titles AND visible content"
        , "C-b s / C-b w    tree: f filters, t tags, : runs a command on all tagged"
        , "C-b < / C-b >    the window and pane menus (display-menu, in the defaults)"
        , ""
        , "mouse events are root-table keys: MouseDown1Pane, WheelUpPane,"
        , "MouseDrag1Border, DoubleClick1Status …   target {mouse} or ="
        , "Shift-drag  ->  the terminal's own selection, bypassing tmux"
        ]
