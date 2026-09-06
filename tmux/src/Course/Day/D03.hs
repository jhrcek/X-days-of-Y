module Course.Day.D03 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 3
        , dayTitle = "Panes and layouts"
        , daySubtitle = "Splitting, zooming, and the layout engine underneath."
        , dayMinutes = 30
        , dayLevel = "essential"
        , dayManRef = "WINDOWS AND PANES"
        , dayTags = ["panes", "zoom", "layouts"]
        , dayGoals =
            [ "split, navigate, resize and close panes without looking anything up"
            , "use zoom as the answer to “this split is now too small”"
            , "drive the seven preset layouts, and know when to stop fighting them"
            ]
        , dayDiagram = Just d3diagram
        , dayBody = body
        , dayKeys =
            [ ("C-b %", "Split left/right. The " <> c "|" <> "-shaped key gives you a " <> c "|" <> "-shaped border.")
            , ("C-b \"", "Split top/bottom.")
            , ("C-b Left", "Move to the pane to the left (likewise " <> k "Right" <> ", " <> k "Up" <> ", " <> k "Down" <> ").")
            , ("C-b o", "Next pane in creation order.")
            , ("C-b ;", "The previously active pane — the " <> k "C-b l" <> " of panes.")
            , ("C-b q", "Flash the pane numbers; press a digit while they show to jump there.")
            , ("C-b z", "Zoom: this pane fills the window. Press again to restore.")
            , ("C-b x", "Kill this pane, after a confirmation.")
            , ("C-b Space", "Cycle to the next preset layout.")
            , ("C-b M-1", "even-horizontal — side by side in a row.")
            , ("C-b M-2", "even-vertical — stacked in a column.")
            , ("C-b M-3", "main-horizontal — one big pane on top.")
            , ("C-b M-4", "main-vertical — one big pane on the left.")
            , ("C-b M-5", "tiled — a grid.")
            , ("C-b E", "Spread the current pane and its neighbours out evenly.")
            , ("C-b C-Left", "Resize by one cell (hold to repeat). " <> k "M-Left" <> " does five.")
            , ("C-b {", "Swap this pane with the previous one; " <> k "C-b }" <> " with the next.")
            , ("C-b C-o", "Rotate every pane through the layout; " <> k "C-b M-o" <> " rotates back.")
            , ("C-b *", "Open a floating pane over the window — hovers above the layout.")
            ]
        , dayCmds =
            [ ("split-window -h", "Split left/right. Alias " <> c "splitw" <> ".")
            , ("split-window -v", "Split top/bottom. The default if neither is given.")
            , ("split-window -c ~/src", "Start the new pane in that directory.")
            , ("split-window -l 30%", "Give the new pane 30% of the space (" <> c "-l 20" <> " for cells).")
            , ("split-window -b", "Put the new pane before — above or to the left of — the old one.")
            , ("split-window -f -h", "Split the full window height, not just the current pane.")
            , ("select-pane -L", "Move to the pane on the left (" <> c "-R -U -D" <> " likewise).")
            , ("select-pane -t 2", "Move to pane 2 of this window.")
            , ("last-pane", "Back to the previously active pane.")
            , ("resize-pane -Z", "Toggle zoom.")
            , ("resize-pane -x 100 -y 30", "Resize to an absolute size, cells or " <> c "%" <> ".")
            , ("select-layout tiled", "Apply a named layout.")
            , ("select-layout -E", "Spread evenly (what " <> k "C-b E" <> " runs).")
            , ("select-layout -o", "Undo the most recent layout change.")
            , ("list-panes", "List panes with index, size and command. Alias " <> c "lsp" <> ".")
            , ("kill-pane -a", "Kill every pane except this one.")
            , ("swap-pane -D", "Swap with the next pane, keeping focus behaviour sane.")
            ]
        , dayOpts =
            [ ("main-pane-width", "Width of the big pane in the main-vertical layouts. Accepts " <> c "%" <> ".")
            , ("main-pane-height", "Height of the big pane in the main-horizontal layouts.")
            , ("tiled-layout-max-columns", "Cap the columns in the tiled layout; 0 means no cap.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Split a window three ways with "
                <> k "C-b %"
                <> " and "
                <> k "C-b \""
                <> ". Move \
                   \around with the arrow keys until it needs no thought."
            , "Now do real work in the smallest pane, and when it becomes annoying press "
                <> k "C-b z"
                <> ". Work. Press it again. This is the single highest-value key on \
                   \the page — most people resize when they should zoom."
            , "Press "
                <> k "C-b Space"
                <> " six times slowly and watch the seven presets go past. \
                   \Then set one directly with "
                <> k "C-b M-4"
                <> " and adjust "
                <> opt "main-pane-width"
                <> " from the command prompt: "
                <> c "set -w main-pane-width 60%"
                <> "."
            , "Hold "
                <> k "C-b"
                <> " then tap "
                <> k "C-Left"
                <> " several times without \
                   \re-pressing the prefix. That works because the resize keys are bound with "
                <> c "-r"
                <> " (repeatable) — Day 8 explains the mechanism."
            , "Break the layout on purpose by dragging panes to silly sizes, then repair it with "
                <> k "C-b E"
                <> ", and undo that with "
                <> c "select-layout -o"
                <> "."
            , "Run "
                <> c "tmux lsp"
                <> " and read the output: index, size, command, and which pane \
                   \is active. Compare it with "
                <> k "C-b q"
                <> "."
            , "Try the floating pane: "
                <> k "C-b *"
                <> ". Note that it hovers above the layout \
                   \instead of taking space from it, and that "
                <> k "C-b x"
                <> " closes it."
            ]
        , dayQuiz =
            [
                ( "Why does "
                    <> k "C-b %"
                    <> " make a left/right split when its command is "
                    <> c "split-window -h"
                    <> ", and "
                    <> c "h"
                    <> " usually means horizontal?"
                , do
                    p_ $ do
                        "Because the flag names the "
                        i_ "direction of the division"
                        " in tmux's head, not the shape of the result. Almost everyone reads it the \
                        \other way round at first."
                    p_ $ do
                        "Ignore the letters and use the shapes of the keys. The "
                        k "%"
                        " glyph has a stroke running top to bottom, and it gives you a top-to-bottom \
                        \border; "
                        k "\""
                        " sits high on the line like a divider, and it gives you a horizontal one. Weak \
                        \mnemonics — but they are printed on your keyboard, which is more than can be \
                        \said for "
                        c "-h"
                        "."
                )
            ,
                ( "You have four panes; three are tiny. Resize or zoom?"
                , p_ $ do
                    "Zoom. "
                    k "C-b z"
                    " is a temporary, reversible state — the layout is untouched underneath, and the "
                    c "Z"
                    " flag in the status line reminds you it is on. Resizing bakes a decision into \
                    \the layout that you then have to undo. Reach for the arrow keys only when the \
                    \new proportions are ones you want to keep."
                )
            ,
                ( "What is the practical difference between "
                    <> c "split-window -h"
                    <> " and "
                    <> c "split-window -fh"
                    <> "?"
                , p_ $ do
                    "Without "
                    c "-f"
                    " the new pane takes space from the "
                    i_ "current pane"
                    " only, so it inherits that pane's slot in the layout. With "
                    c "-f"
                    " it spans the full height of the window, cutting across every existing pane. \
                    \That is how you get a proper sidebar next to a stack of panes rather than a \
                    \split-of-a-split."
                )
            ,
                ( "What does "
                    <> c "layout: bb62,159x48,0,0{79x48,0,0,79x48,80,0}"
                    <> " in "
                    <> c "tmux lsw"
                    <> " output mean, and what is it for?"
                , p_ $ do
                    "It is the window's layout serialised: a checksum, the window size, and a nested \
                    \description of every pane's size and offset. You can feed the whole string back \
                    \to "
                    c "select-layout"
                    " to restore that arrangement exactly, which is how session-restoring scripts \
                    \and plugins reproduce a layout they cannot describe with a preset name. Day 11 \
                    \uses it."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d3diagram :: Diagram
d3diagram =
    ( diagram
        "A window has a layout which arranges its panes; each pane has an index, a size, a \
        \working directory and a pseudo-terminal; the window distinguishes an active pane, and \
        \zoom temporarily overrides the layout."
        body'
    )
        { dgCaption = do
            "The thing to take from this: "
            b_ "the layout is a property of the window, not of the panes"
            ". Splitting, swapping, rotating and the seven presets all rewrite that one value — \
            \which is why "
            c "select-layout -o"
            " can undo them and why a layout can be saved as a string and replayed. "
            b_ "Zoom"
            " is the exception: it hides the layout for a moment without changing it."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  win    [label=\"a window\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  layout [label=\"a layout\\n(a nested arrangement\\nof rectangles)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  preset [label=\"a preset layout\\n(tiled, main-vertical …)\", fillcolor=\"#f4efe6\"];"
            , "  pane   [label=\"a pane\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  idx    [label=\"a pane index\"];"
            , "  size   [label=\"a size and position\"];"
            , "  cwd    [label=\"a working directory\"];"
            , "  pty    [label=\"a pseudo-terminal\"];"
            , "  zoom   [label=\"the zoomed state\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  win    -> layout [label=\"  has as\"];"
            , "  layout -> pane   [label=\"  arranges\"];"
            , "  preset -> layout [label=\"  becomes\\l  (C-b Space, M-1..M-7)\\l\"];"
            , "  win    -> pane   [label=\"has as active  \", style=dashed, constraint=false];"
            , "  pane   -> idx    [label=\"  has as index\"];"
            , "  pane   -> size   [label=\"  occupies\"];"
            , "  pane   -> cwd    [label=\"  runs in\"];"
            , "  pane   -> pty    [label=\"  is\"];"
            , "  zoom   -> layout [label=\"  temporarily hides  \", style=dashed, constraint=false];"
            , "  { rank=same; preset; win; }"
            , "  { rank=same; zoom; layout; }"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "A pane is a whole terminal" $ do
        p_ [class_ "lede"] $ do
            "Splitting a window does not divide a terminal in two — it creates a second, complete \
            \pseudo-terminal with its own shell, its own process group, its own "
            c "$TMUX_PANE"
            ", and its own scrollback. That is why a pane can be moved to another window, broken \
            \out into its own window, or joined into a different one entirely without anything \
            \noticing."
        p_ $ do
            "Two splits, and the mnemonic that actually survives contact with real use: the "
            k "%"
            " glyph has a stroke running top to bottom, and gives you a top-to-bottom border; "
            k "\""
            " sits high on the line like a divider, and gives you a horizontal one. Do not try to \
            \remember which of them is “horizontal”, because tmux and your intuition disagree about \
            \that word."
        cols
            [ do
                p_ [class_ "lede-sm"] $ k "C-b %" <> " — left and right"
                ascii
                    [ "┌────────────┬────────────┐"
                    , "│            │            │"
                    , "│   pane 0   │   pane 1   │"
                    , "│            │            │"
                    , "└────────────┴────────────┘"
                    ]
            , do
                p_ [class_ "lede-sm"] $ k "C-b \"" <> " — top and bottom"
                ascii
                    [ "┌─────────────────────────┐"
                    , "│         pane 0          │"
                    , "├─────────────────────────┤"
                    , "│         pane 1          │"
                    , "└─────────────────────────┘"
                    ]
            ]
        fig

    block "Getting around, and getting out of the way" $ do
        p_ $ do
            "Arrow keys after the prefix move geometrically: "
            k "C-b Left"
            " selects the pane to the left of the current one, whatever its index. "
            k "C-b o"
            " cycles in creation order, and "
            k "C-b ;"
            " jumps back to the pane you were in before — the pane-level twin of yesterday's "
            k "C-b l"
            "."
        p_ $ do
            k "C-b q"
            " briefly paints a large number over each pane. While those numbers are on screen, \
            \pressing a digit jumps to that pane. It is the fastest way to reach pane 4 of six, and \
            \it doubles as a way to remind yourself what "
            c "-t 2"
            " will mean in a command."
        tip $ do
            p_ $ do
                b_ "Zoom is the feature to internalise today."
                " "
                k "C-b z"
                " expands the active pane to fill the whole window; press it again and everything \
                \returns exactly as it was. The status line shows "
                c "Z"
                " on that window while it lasts."
            p_
                "This dissolves the usual complaint that splits are too small. Keep a comfortable, \
                \stable layout, and zoom whenever you need room for a moment. Resizing is for \
                \proportions you intend to keep; zoom is for the next ninety seconds."

    block "Resizing, and the repeat trick" $ do
        p_ $ do
            k "C-b C-Left"
            " and friends resize by one cell, "
            k "C-b M-Left"
            " by five. Both are bound with "
            c "-r"
            ", which means that after the first one you can keep tapping the arrow without pressing \
            \the prefix again — tmux stays in the prefix table for "
            opt "repeat-time"
            " milliseconds (500 by default) after each repeatable key."
        sh
            [ "$ tmux resize-pane -x 100          # exactly 100 columns"
            , "$ tmux resize-pane -y 30%          # 30% of the window height"
            , "$ tmux resize-pane -D 5            # five rows shorter"
            , "$ tmux resize-pane -Z              # what C-b z does"
            ]
        p_ $ do
            "If the mouse is on (Day 5), dragging a border resizes too — that is a "
            c "MouseDrag1Border"
            " binding running "
            c "resize-pane -M"
            ", not a special case in the code."

    block "The seven layouts" $ do
        p_ $ do
            "tmux ships seven preset arrangements. "
            k "C-b Space"
            " cycles through them; "
            k "C-b M-1"
            " through "
            k "C-b M-7"
            " pick one directly. The bindings do not run in the order the man page lists the layouts \
            \in, so here is what your keyboard actually does:"
        ascii
            [ "  M-1  even-horizontal          M-5  tiled"
            , "  M-2  even-vertical            M-6  main-horizontal-mirrored"
            , "  M-3  main-horizontal          M-7  main-vertical-mirrored"
            , "  M-4  main-vertical"
            , ""
            , "  even-horizontal      main-vertical         tiled"
            , "  ┌───┬───┬───┐        ┌───────┬─────┐       ┌─────┬─────┐"
            , "  │   │   │   │        │       │     │       │     │     │"
            , "  │   │   │   │        │ main  ├─────┤       ├─────┼─────┤"
            , "  │   │   │   │        │       │     │       │     │     │"
            , "  └───┴───┴───┘        └───────┴─────┘       └─────┴─────┘"
            ]
        p_ $ do
            "The two "
            c "main-*"
            " layouts are the useful ones: a big pane for the work and a column or row of small \
            \ones for everything else. Their proportions come from "
            opt "main-pane-width"
            " and "
            opt "main-pane-height"
            ", both of which take a percentage:"
        sh
            [ "$ tmux set -w main-pane-width 62%"
            , "$ tmux select-layout main-vertical"
            ]
        note $ p_ $ do
            "Once you move or resize a pane by hand, the window is no longer “in” a preset layout — \
            \it has a custom one. "
            k "C-b E"
            " ("
            c "select-layout -E"
            ") spreads panes out evenly again without committing to a preset, and "
            c "select-layout -o"
            " undoes the last layout change. Between those two you rarely need to re-apply a preset \
            \in anger."

    block "Rearranging and closing" $ do
        p_ $ do
            k "C-b {"
            " and "
            k "C-b }"
            " swap the current pane with its neighbour by index, which is how you promote a pane \
            \into the “main” slot of a layout. "
            k "C-b C-o"
            " rotates all of them one step; "
            k "C-b M-o"
            " rotates the other way."
        p_ $ do
            "Panes close when their shell exits, or with "
            k "C-b x"
            " (which asks). "
            c "kill-pane -a"
            " keeps only the current one — a good panic button after an experiment gets out of hand. \
            \When the last pane in a window goes, so does the window."
        gotcha $ p_ $ do
            "Pane indices are positional and get reused. Kill pane 1 of three and the old pane 2 \
            \becomes pane 1. If you are writing a script, do not target "
            c "-t 1"
            " and hope; use the "
            b_ "pane id"
            " instead — "
            c "%3"
            "-style identifiers are unique for the life of the server and never shuffle. Day 7 makes \
            \a habit of it."

    block "One thing almost nobody knows" $ do
        p_ $ do
            "Recent tmux has "
            b_ "floating panes"
            ": "
            k "C-b *"
            " opens a pane that hovers over the window rather than taking space from the layout. It \
            \is the same object as any other pane — same keys, same commands — but it does not \
            \disturb the arrangement underneath. For a quick "
            c "man"
            " lookup or a throwaway command it beats splitting and then un-splitting."
        p_ $ do
            "Day 13 builds the more configurable version of the same idea with "
            c "display-popup"
            ", which can run a command in a bordered box and vanish when it exits."

cheat :: Html ()
cheat = do
    cfg
        [ "C-b %  /  C-b \"     # split left-right / top-bottom (look at the key glyph)"
        , "C-b arrows          # move geometrically;  C-b ;  = last pane;  C-b q  = numbers"
        , "C-b z               # ZOOM. the answer to \"this pane is too small\""
        , "C-b Space           # cycle presets;  M-1 even-h  M-2 even-v  M-3 main-h"
        , "                    #                 M-4 main-v  M-5 tiled"
        , "C-b E               # spread evenly;  select-layout -o  undoes a layout change"
        , "C-b C-arrow         # resize by 1 (repeatable);  M-arrow by 5"
        , "C-b { }             # swap panes;  C-b C-o  rotate;  C-b x  kill"
        ]
