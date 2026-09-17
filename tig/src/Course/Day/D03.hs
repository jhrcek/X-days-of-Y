module Course.Day.D03 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 3
        , dayTitle = "Moving between views"
        , daySubtitle = "Parent and child, the view stack, and why the arrow keys are not j and k."
        , dayMinutes = 32
        , dayLevel = "essential"
        , dayManRef = "tigmanual(7) THE VIEWER, DEFAULT KEYBINDINGS"
        , dayTags = ["split view", "navigation", "stack"]
        , dayGoals =
            [ "split the main view against a diff and walk the history without touching the mouse"
            , "predict what the arrow keys do in a split view, and reach for j and k when you do not want that"
            , "get out of any depth on purpose, using q, Q, < and O deliberately"
            ]
        , dayDiagram = Just d3diagram
        , dayBody = body
        , dayKeys =
            [ ("Enter", "Open the selected line. From the main view, splits and shows the diff.")
            , ("Tab", "Move focus to the other view in a split.")
            , ("Up Down", "Move to the previous/next entry — in the parent view, even from the child.")
            , ("J K", "Same as the arrow keys: next and previous entry.")
            , ("O", "Maximise the focused view to fill the display.")
            , ("<", "Go back to the previous view state.")
            , (",", "Move to the parent: the parent directory, or the parent commit.")
            , ("Space -", "Page down and page up.")
            , ("C-d C-u", "Half a page down and up.")
            ]
        , dayCmds = []
        , dayOpts =
            [ ("split-view-height", "Height of the bottom view in a stacked split. Default " <> c "67%" <> ".")
            , ("split-view-width", "Width of the right-hand view in a side-by-side split. Default " <> c "50%" <> ".")
            , ("vertical-split", "Stacked or side by side. Default " <> c "auto" <> ".")
            , ("focus-child", "Whether opening a child view moves the focus into it. Default " <> c "yes" <> ".")
            ]
        , dayConfig = []
        , dayDrills =
            [ "In the main view, put the cursor on any commit and press "
                <> k "Enter"
                <> ". The screen splits: commit list above, diff below."
            , "Now hold "
                <> k "Down"
                <> " for a few seconds. The cursor walks the commit list in the top view and the \
                   \diff below keeps up. This is the single most useful thing tig does — spend a \
                   \minute on it."
            , "Press "
                <> k "Tab"
                <> " to move focus into the diff, then press "
                <> k "Down"
                <> " again. Notice it now scrolls the diff instead of changing commits. Press "
                <> k "Tab"
                <> " to go back."
            , "With focus in the diff, press "
                <> k "j"
                <> " a few times, then "
                <> k "Down"
                <> " a few times, and watch the difference. One moves inside this view; the other \
                   \moves the selection."
            , "Press "
                <> k "O"
                <> " to maximise whichever view has focus, then "
                <> k "O"
                <> " again from the other. Use this when a diff needs the whole screen."
            , "Break it on purpose: press "
                <> k "Enter"
                <> " repeatedly on lines inside the diff view until you have no idea how deep you \
                   \are. Now get out with "
                <> k "q"
                <> " one press at a time, counting. Then do it again and use "
                <> k "Q"
                <> "."
            , "Today's habit: stop pressing "
                <> k "d"
                <> " to look at a commit. Press "
                <> k "Enter"
                <> " instead, and leave the split open while you work down the list."
            ]
        , dayQuiz =
            [
                ( "You split the main view against a diff, press "
                    <> k "Tab"
                    <> " into the diff, and now the "
                    <> k "Down"
                    <> " key scrolls the patch instead of moving to the next commit. Your colleague \
                       \says theirs moves to the next commit from inside the diff. Who is right?"
                , do
                    p_ $ do
                        "Both, at different times. "
                        k "Down"
                        " is bound to "
                        c "next"
                        ", which is context sensitive: it means “next entry in the view that owns \
                        \the selection”. While the parent still owns the selection, "
                        k "Down"
                        " walks commits and reloads the diff. Once you "
                        k "Tab"
                        " into the child, the child owns it and "
                        k "Down"
                        " scrolls."
                    p_ $ do
                        "If you want the parent-walking behaviour permanently while reading a diff, \
                        \Day 12's "
                        c "bind diff <Down> move-up"
                        " family is exactly the knob — tigmanual(7) even suggests it."
                )
            ,
                ( "What is the difference between "
                    <> k "j"
                    <> " and "
                    <> k "Down"
                    <> ", given that both appear to move down one line?"
                , do
                    p_ $ do
                        k "j"
                        " is "
                        c "move-down"
                        ": move this view's cursor one line, and nothing else. "
                        k "Down"
                        " is "
                        c "next"
                        ": advance the selection, which in a split view means the parent's cursor \
                        \and a reload of the child."
                    p_ $ do
                        "In an unsplit view they are indistinguishable, which is why the difference \
                        \surprises people the first time they split something. "
                        k "J"
                        " and "
                        k "K"
                        " are the same as the arrows, for people who do not want to leave the home \
                        \row."
                )
            ,
                ( "You press "
                    <> k "Enter"
                    <> " on a commit and the diff opens "
                    <> i_ "below"
                    <> ", but you wanted it beside. What decides?"
                , do
                    p_ $ do
                        opt "vertical-split"
                        ", which defaults to "
                        c "auto"
                        " — tig picks based on the terminal's dimensions. In practice on 2.6.1 it \
                        \picks stacked at ordinary sizes; even a 400-column terminal still stacked \
                        \in testing."
                    p_ $ do
                        "If you want side by side, ask for it rather than hoping: "
                        c "set vertical-split = yes"
                        ", with "
                        opt "split-view-width"
                        " (default "
                        c "50%"
                        ") controlling the right-hand pane. Day 7 puts it in the file."
                )
            ,
                ( "You are four views deep and press "
                    <> k "<"
                    <> " instead of "
                    <> k "q"
                    <> ". What is the difference?"
                , do
                    p_ $ do
                        k "q"
                        " is "
                        c "view-close"
                        ": it destroys the top view and pops the stack. "
                        k "<"
                        " is "
                        c "back"
                        ", which returns to the previous "
                        i_ "view state"
                        " — where you were, in the view you were in, including the position."
                    p_ $ do
                        "The distinction shows up when you have navigated within one view: "
                        k "<"
                        " retraces your steps, "
                        k "q"
                        " throws the whole screen away. After a "
                        k ","
                        " walk up a blame chain (Day 8), "
                        k "<"
                        " is how you come back down."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d3diagram :: Diagram
d3diagram =
    ( diagram
        "The split view relationship: a parent view owns a selected line, opening it creates a \
        \child view; the next action moves the parent's selection and reloads the child, while the \
        \move-down action moves only the focused view's cursor."
        body'
    )
        { dgCaption = do
            "The whole of today is the difference between the two arrows leaving "
            b_ "the selection"
            ". "
            c "next"
            " (bound to the arrow keys) advances the selection, which belongs to whichever view is \
            \focused and drags the child view along with it. "
            c "move-down"
            " (bound to "
            k "j"
            ") moves a cursor inside one view and disturbs nothing."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  par  [label=\"a parent view\\n(main)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  chi  [label=\"a child view\\n(diff)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  sel  [label=\"the selected line\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  cur  [label=\"a cursor\"];"
            , "  foc  [label=\"the focus\"];"
            , "  nxt  [label=\"the next action\\n(<Down>, J)\", fillcolor=\"#f4efe6\"];"
            , "  mvd  [label=\"the move-down action\\n(j)\", fillcolor=\"#f4efe6\"];"
            , "  tab  [label=\"the view-next action\\n(<Tab>)\", fillcolor=\"#f4efe6\"];"
            , ""
            , "  par -> chi [label=\"  opens\"];"
            , "  par -> sel [label=\"  owns\"];"
            , "  sel -> chi [label=\"  determines the content of\", style=dashed];"
            , "  nxt -> sel [label=\"  advances\"];"
            , "  mvd -> cur [label=\"  moves\"];"
            , "  chi -> cur [label=\"  has\"];"
            , "  tab -> foc [label=\"  moves\"];"
            , "  foc -> chi [label=\"  may rest on\", style=dashed];"
            , "  foc -> par [label=\"  may rest on\", style=dashed];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "The split is the reason to use tig" $ do
        p_ [class_ "lede"] $ do
            "Yesterday you opened a diff with "
            k "d"
            ", which replaced the list. Today: press "
            k "Enter"
            " instead. The screen splits, the commit list stays, and the diff below follows your \
            \cursor as you walk the history. That one gesture is what tig is for."
        p_ "Pressing Enter on a commit in the main view gives you this:"
        ascii
            [ "  ┌────────────────────────────────────────────────────────────┐"
            , "  │ 2026-03-05 Ada Lovelace  ●─╮ [master] Merge branch 'feat…'  │"
            , "  │ 2026-03-03 Ada Lovelace  │ ∙ [feature/parser] Implement p…  │ <- selection"
            , "  │ 2026-03-02 Ada Lovelace  │ ∙ Add parser header             │"
            , "  ├────────────────────────────────────────────────────────────┤"
            , "  │ [main] 785f586… - commit 5 of 8                        62% │ <- parent title"
            , "  ├────────────────────────────────────────────────────────────┤"
            , "  │ commit 785f5861f1d5cd1a8a5d0a2b9c3e4f5a6b7c8d9e            │"
            , "  │ Author:     Ada Lovelace <dev@example.com>                  │"
            , "  │ ---                                                        │"
            , "  │  src/parser.c | 1 +                                        │"
            , "  ├────────────────────────────────────────────────────────────┤"
            , "  │ [diff] 785f586… - line 1 of 27                         92% │ <- child title"
            , "  └────────────────────────────────────────────────────────────┘"
            ]
        p_ $ do
            "Two views, each with its own title window. The bottom one gets "
            opt "split-view-height"
            " of the display — "
            c "67%"
            " by default, so the child is roughly twice the parent. Now hold "
            k "Down"
            ": the selection walks the list above and the diff below reloads for each commit."
        why $ p_ $ do
            "Note what tig is not doing: it is not re-running "
            c "git show"
            " on every keypress and throwing the result away. It reloads the child "
            i_ "only when the commit ID in the browsing state actually changes"
            ", which is why scrolling through a hundred commits stays responsive. Yesterday's \
            \browsing state is doing the work — the child view is a function of the selection, and \
            \tig recomputes it when the input changes and not otherwise."
        fig

    block "Focus, and the key distinction nobody explains" $ do
        p_ $ do
            k "Tab"
            " moves focus between the two views. The focused view is the one whose title is bold, \
            \and — more importantly — the one that owns the selection."
        p_ $ do
            "This is where the arrow keys get interesting. tig binds them to "
            c "next"
            " and "
            c "previous"
            ", which are "
            b_ "context sensitive"
            ", and binds "
            k "j"
            " and "
            k "k"
            " to "
            c "move-down"
            " and "
            c "move-up"
            ", which are not:"
        defs
            [
                ( k "Down" <> " / " <> k "J"
                , do
                    c "next"
                    ". Advance the selection. With focus in the parent, this changes commit and \
                    \reloads the diff. With focus in the child, it scrolls the child."
                )
            ,
                ( k "j"
                , do
                    c "move-down"
                    ". Move the focused view's cursor by one line. Never reaches across to the \
                    \parent, never reloads anything."
                )
            ]
        p_ $ do
            "In a single unsplit view the two are indistinguishable, which is exactly why the \
            \difference ambushes people the first time they split something. The rule worth \
            \internalising: "
            b_ "arrows move the selection, j and k move a cursor."
        tip $ p_ $ do
            "If you would rather the arrow keys always scrolled the diff, tigmanual(7) names the \
            \fix directly: "
            c "bind diff <Down> scroll-line-down"
            ". You will be able to write that on Day 12, and it is one of the most common lines in \
            \other people's "
            c "~/.tigrc"
            "."

    block "Stacked or side by side" $ do
        p_ $ do
            "Whether the split is horizontal or vertical is "
            opt "vertical-split"
            ", which defaults to "
            c "auto"
            " — “it depends on the window dimensions”, per tigrc(5)."
        gotcha $ p_ $ do
            "In practice "
            c "auto"
            " is shy about choosing side-by-side. Testing 2.6.1 at every size from 80×24 up to \
            \500×20, the main-to-diff split came out stacked every single time. If you have a wide \
            \monitor and want the diff beside the list, do not wait for "
            c "auto"
            " to notice — set "
            c "vertical-split = yes"
            " explicitly, and use "
            opt "split-view-width"
            " (default "
            c "50%"
            ") to size it."
        p_ $ do
            "The two sizing options are independent: "
            opt "split-view-height"
            " governs the bottom view when stacked, "
            opt "split-view-width"
            " the right-hand view when side by side. Both accept a row/column count or a \
            \percentage, and tig always keeps the smaller view at least four lines or columns."
        p_ $ do
            k "O"
            " maximises the focused view to fill the display, and pressing it in the other view \
            \swaps which one you see. It is the fastest way to read a long patch without closing \
            \the list you are working through."

    block "Getting out, four ways" $ do
        p_ "Four keys leave a view, and they mean different things:"
        defs
            [ (k "q", "Close this view, pop the stack, reveal what is underneath. Quits if it was the last.")
            , (k "Q", "Quit tig now, from any depth.")
            , (k "<", "Go back to the previous view state — where you were, not one level up.")
            , (k ",", "Move to the parent: the parent directory in the tree view, the parent commit in blame.")
            ]
        p_ $ do
            k "<"
            " and "
            k "q"
            " look similar and are not. "
            k "q"
            " is structural — it destroys the top view. "
            k "<"
            " is historical — it retraces where you have been, including positions within a view. \
            \After Day 8's habit of walking a blame chain backwards through history, "
            k "<"
            " is how you come home."
        note $ p_ $ do
            "tigmanual(7)'s key tables do not mention "
            k "<"
            " at all, nor "
            k "J"
            ", "
            k "K"
            ", "
            k "C-d"
            " or "
            k "C-u"
            ". The help view ("
            k "h"
            ") is generated from the bindings that actually exist, so it is the more reliable list \
            \of the two. This is the first of several places where the manual and the binary have \
            \drifted apart; Day 14 collects the rest."

    block "Today's habit" $ do
        p_ $ do
            "Stop using "
            k "d"
            " to inspect a commit. Press "
            k "Enter"
            ", leave the split open, and review a branch's worth of history by holding "
            k "Down"
            ". If you review other people's code, do the next review this way and notice how much \
            \less you type."
        p_ "Tomorrow: what the diff view is showing you, and the filter you did not know was on."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Navigation, compressed."
        " The top half is the split; the bottom half is getting out."
    cfg
        [ "Enter    open the selected line — from main, split and show the diff"
        , "Tab      move focus between the two views in a split"
        , "Down/J   next: advance the SELECTION (reloads the child view)"
        , "j / k    move THIS view's cursor only — never touches the parent"
        , "Space -  page down / up          C-d C-u   half a page"
        , "O        maximise the focused view"
        , "q        close this view (pops)   Q   quit from any depth"
        , "<        back to the previous view state (not one level up)"
        , ",        parent: parent directory (tree), parent commit (blame)"
        ]
