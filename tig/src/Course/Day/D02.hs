module Course.Day.D02 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 2
        , dayTitle = "The main view"
        , daySubtitle = "The graph, the refs, and three rows that are not commits."
        , dayMinutes = 30
        , dayLevel = "essential"
        , dayManRef = "tigmanual(7) THE VIEWER, Misc; tigrc(5) SET COMMAND"
        , dayTags = ["main view", "graph", "toggles"]
        , dayGoals =
            [ "read a main-view line: date, author, graph, refs, subject — and know which column is which"
            , "recognise the three working-tree rows at the top and know why they are there"
            , "reshape the view on the spot with the display toggles, and find them again in the option menu"
            ]
        , dayDiagram = Just d2diagram
        , dayBody = body
        , dayKeys =
            [ ("D", "Cycle the date column: default, relative, compact, custom, hidden.")
            , ("A", "Cycle the author column: full, abbreviated, email, user, hidden.")
            , ("X", "Show or hide the abbreviated commit ID column.")
            , ("G", "Cycle the graph in the main view: v2, v1, off.")
            , ("F", "In the main view, show or hide the ref labels.")
            , ("#", "Show or hide line numbers.")
            , ("~", "Switch the line graphics between ASCII and the drawing characters.")
            , ("o", "Open the option menu: the same toggles, with their current values.")
            , ("j k", "Move the cursor down and up. Arrow keys work too, with a caveat on Day 3.")
            ]
        , dayCmds = []
        , dayOpts =
            [ ("show-changes", "Whether the working-tree rows appear at all. Default " <> c "yes" <> ".")
            , ("show-untracked", "Whether the untracked row appears. Default " <> c "yes" <> ".")
            , ("reference-format", "How refs are wrapped. Default " <> c "[branch] {remote} <tag> ~replace~" <> ".")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Open "
                <> c "tig"
                <> " in a repository with a few branches and press "
                <> k "G"
                <> " three times. Watch the graph go from the rounded v2 rendering, to the heavier \
                   \v1 one, to nothing at all, and back."
            , "Press "
                <> k "D"
                <> " four times and stop on whichever date format you actually want to read. Do the \
                   \same with "
                <> k "A"
                <> ". You have just chosen two lines of your Day 7 config."
            , "Press "
                <> k "X"
                <> " to bring in the commit ID column, then "
                <> k "#"
                <> " for line numbers. Note that the ID is abbreviated here while the title window \
                   \shows all forty characters."
            , "Make an edit in your working tree without staging it. Press "
                <> k "R"
                <> " in tig and watch the "
                <> c "Unstaged changes"
                <> " row appear at the top. Stage it and press "
                <> k "R"
                <> " again."
            , "Break it on purpose: run "
                <> c "tig -- some/file"
                <> " on a file you have modified. The working-tree rows are gone. Work out why \
                   \before reading the answer in the quiz."
            , "Press "
                <> k "o"
                <> " to open the option menu and read it top to bottom once. Every toggle you just \
                   \pressed is in there with its current value."
            , "Run "
                <> c "tig --all"
                <> " in a repository where you have remote branches, and compare the graph with \
                   \plain "
                <> c "tig"
                <> ". Adopt whichever you reach for more often."
            ]
        , dayQuiz =
            [
                ( "The top three lines of the main view say "
                    <> c "Staged changes"
                    <> ", "
                    <> c "Unstaged changes"
                    <> " and "
                    <> c "Untracked changes"
                    <> ", all dated today with no author. Pressing "
                    <> k "d"
                    <> " on one shows a diff. What are they?"
                , do
                    p_ $ do
                        "They are not commits. They are tig's summary of your working tree, spliced \
                        \into the top of the commit list by the "
                        opt "show-changes"
                        " and "
                        opt "show-untracked"
                        " options, both of which default to "
                        c "yes"
                        "."
                    p_ $ do
                        "The point is that the thing you are about to commit belongs on the same \
                        \timeline as the things you already committed. Pressing "
                        k "Enter"
                        " on one of these rows takes you into the status or stage view rather than a \
                        \commit diff — which is the doorway to Day 6."
                )
            ,
                ( "You run "
                    <> c "tig -- src/parser.c"
                    <> " and the working-tree rows vanish, even though that file has unstaged \
                       \edits. Why?"
                , do
                    p_ $ do
                        "Because a path limit turns the main view into a question about history — \
                        \“which commits touched this file” — and the pseudo-rows are not commits, so \
                        \there is no honest answer for them. tig drops them rather than showing rows \
                        \that would lie about the filter."
                    p_ $ do
                        "If you wanted the working-tree state for that file, the status view ("
                        k "s"
                        ") always shows it, filter or no filter."
                )
            ,
                ( "Your colleague's tig shows commit IDs and yours does not, and neither of you has \
                  \a "
                    <> c "~/.tigrc"
                    <> ". Who changed what?"
                , do
                    p_ $ do
                        "Nobody changed a file. The ID column is off by default and "
                        k "X"
                        " toggles it for the current session only — every display toggle is \
                        \in-memory and dies with the process."
                    p_ $ do
                        "That is the design: toggles are for looking at something a particular way \
                        \right now. When a toggle turns out to be what you always want, it graduates \
                        \into "
                        c "~/.tigrc"
                        " as a setting, which is Day 7. Until then, "
                        k "o"
                        " shows you the live values."
                )
            ,
                ( "The graph looks like a mess of "
                    <> c "|"
                    <> " and "
                    <> c "\\"
                    <> " characters instead of smooth lines. What happened, and which key fixes it?"
                , do
                    p_ $ do
                        "tig fell back to ASCII line graphics. The "
                        opt "line-graphics"
                        " setting decides between ASCII and the terminal's drawing characters, and "
                        k "~"
                        " toggles it live."
                    p_ $ do
                        "The usual causes are a terminal or locale that is not UTF-8, or an SSH \
                        \session that lost "
                        c "LANG"
                        " on the way. Setting "
                        c "line-graphics = utf-8"
                        " forces the pretty rendering; leaving it at the default makes tig decide \
                        \per terminal, which is the right choice if you log into machines that vary."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d2diagram :: Diagram
d2diagram =
    ( diagram
        "The anatomy of a main view line: the view is built from columns, each column has a \
        \display mode that a toggle key cycles; a line is either a commit, which carries refs and \
        \a graph position, or one of the three working-tree rows."
        body'
    )
        { dgCaption = do
            "Two different things share the main view. Most lines are "
            b_ "commits"
            ", drawn column by column, and every column has a display mode that a single key \
            \cycles. The top three lines are "
            b_ "working-tree rows"
            " — not commits at all, but spliced in so that what you are about to commit sits on the \
            \same timeline as what you already did."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  mv   [label=\"the main view\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  line [label=\"a line\"];"
            , "  cmt  [label=\"a commit\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  wt   [label=\"a working-tree row\\n(staged / unstaged /\\nuntracked changes)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  col  [label=\"a column\\n(date, author, id,\\ncommit-title)\"];"
            , "  mode [label=\"a display mode\"];"
            , "  key  [label=\"a toggle key\\n(D A X G F)\", fillcolor=\"#f4efe6\"];"
            , "  ref  [label=\"a reference label\\n[branch] <tag> {remote}\"];"
            , ""
            , "  mv   -> line [label=\"  is a list of\"];"
            , "  line -> cmt  [label=\"  is either\"];"
            , "  line -> wt   [label=\"  or\"];"
            , "  mv   -> col  [label=\"  is drawn from\"];"
            , "  col  -> mode [label=\"  has as current\", style=dashed];"
            , "  key  -> mode [label=\"  cycles\"];"
            , "  cmt  -> ref  [label=\"  may carry\"];"
            , ""
            , "  { rank=same; cmt; wt; }"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "One line per commit, and the line has structure" $ do
        p_ [class_ "lede"] $ do
            "The main view looks like "
            c "git log --oneline"
            " with decoration. It is better than that: every part of the line is a named "
            b_ "column"
            " with its own display mode, and each mode is one keystroke away. Learning the five \
            \toggle keys today is worth more than learning twenty commands."
        p_ "Here is a small history with two branches and a merge, as tig draws it:"
        termStatus
            "tig"
            [ "2026-09-17 07:12 Not Committed Yet ∙ Untracked changes"
            , "2026-09-17 07:12 Not Committed Yet ∙ Unstaged changes"
            , "2026-09-17 07:12 Not Committed Yet ∙ Staged changes"
            , "2026-03-05 16:00 Ada Lovelace      ●─╮ [master] Merge branch 'feature/parser'"
            , "2026-03-03 09:30 Ada Lovelace      │ ∙ [feature/parser] Implement parse()"
            , "2026-03-02 11:00 Ada Lovelace      │ ∙ Add parser header"
            , "2026-03-04 14:00 Ada Lovelace      ∙ │ Start the manual"
            , "2026-03-01 10:00 Ada Lovelace      ◎─╯ <v1.0> Initial import"
            ]
            "[main] Untracked changes"
            "100%"
        p_ $ do
            "Left to right: the committer date, the author, the graph, any reference labels, and \
            \the first line of the commit message. By default the commit ID is "
            i_ "not"
            " shown — tig assumes you want to read history, not copy hashes, and gives you "
            k "X"
            " for when you do."
        fig

    block "The three rows that are not commits" $ do
        p_ $ do
            "Look again at the top three lines. They have today's date, an author of "
            c "Not Committed Yet"
            ", and no position in the graph. They are your working tree, spliced into the commit \
            \list:"
        defs
            [ (c "Staged changes", "What is in the index, waiting to be committed.")
            , (c "Unstaged changes", "Tracked files you have modified but not staged.")
            , (c "Untracked changes", "Files git has never seen.")
            ]
        p_ $ do
            "They come from "
            opt "show-changes"
            " and "
            opt "show-untracked"
            ", both "
            c "yes"
            " by default. Pressing "
            k "Enter"
            " on one takes you into the working-tree views rather than a commit diff, which is how \
            \most people first arrive at Day 6's staging workflow without meaning to."
        why $ p_ $ do
            "Putting uncommitted work at the top of the log is a small decision with a large \
            \effect. It means the question “what have I got in flight?” and the question “what \
            \happened here recently?” have the same answer on the same screen, so you stop \
            \alternating between "
            c "git status"
            " and "
            c "git log"
            ". Once you are used to it, a bare "
            c "git log"
            " feels like it is hiding something."
        gotcha $ p_ $ do
            "These rows disappear the moment you limit the view by path — "
            c "tig -- src/"
            " shows no working-tree rows even when "
            c "src/"
            " is full of edits. They also disappear in a repository with no commits yet, which \
            \makes a fresh "
            c "git init"
            " look alarmingly empty. Neither is a bug; use "
            k "s"
            " for the working tree whenever a filter is in play."

    block "The graph is three renderings, not one" $ do
        p_ $ do
            k "G"
            " cycles the commit graph through three states, and they are genuinely different \
            \things rather than on and off:"
        ascii
            [ "  press G ->   ●─╮      the v2 graph: accurate, the default"
            , "  press G ->   ●━┑      the v1 graph: older, less accurate, faster"
            , "  press G ->   (none)   no graph column at all"
            , "  press G ->   ●─╮      back to v2"
            ]
        p_ $ do
            "v1 exists because drawing an accurate graph means looking further ahead in the commit \
            \stream than drawing an approximate one. In a repository with hundreds of thousands of \
            \commits that difference is felt; in yours it almost certainly is not. Stay on v2 until \
            \a repository makes you care, which Day 14 revisits."
        note $ p_ $ do
            "The graph interacts with commit ordering. "
            opt "commit-order"
            " defaults to "
            c "auto"
            ", which quietly switches to topological order whenever the graph is on — because a \
            \graph drawn over date-ordered commits is misleading. Turning the graph off with "
            k "G"
            " therefore changes the "
            i_ "order"
            " of the list as well as its appearance."

    block "Reference labels, and what the brackets mean" $ do
        p_ $ do
            "Branches, tags and remotes appear as labels before the subject, and the punctuation \
            \tells you which is which. The default "
            opt "reference-format"
            " is:"
        cfg
            [ "[branch]   {remote}   <tag>   ~replace~"
            ]
        p_ $ do
            "So "
            c "[master]"
            " is a local branch, "
            c "<v1.0>"
            " an annotated tag, "
            c "{origin/master}"
            " a remote. "
            k "F"
            " hides and shows the whole lot in the main view — useful in a repository with fifty \
            \tags on one commit."
        tip $ p_ $ do
            "The label format is configurable, including hiding a whole category: "
            c "hide:remote"
            " drops remote labels entirely. If your main view is unreadable because CI creates a \
            \tag per build, that is the knob, and Day 7 is where it goes in the file."

    block "Toggles: the five keys worth having in your fingers" $ do
        p_ $ do
            "Each of these cycles one column's display mode, immediately, for this session only. \
            \Try them now rather than reading them:"
        defs
            [
                ( k "D" <> " date"
                , do
                    "Five states: "
                    c "2026-03-05 16:00"
                    " → "
                    c "6 months ago"
                    " → "
                    c "6M"
                    " → "
                    c "2026-03-05"
                    " → hidden."
                )
            ,
                ( k "A" <> " author"
                , do
                    "Five states: "
                    c "Ada Lovelace"
                    " → "
                    c "ALovelace"
                    " → "
                    c "dev@example.com"
                    " → "
                    c "dev"
                    " → hidden."
                )
            , (k "X" <> " commit ID", "On or off. Abbreviated, honouring git's " <> c "core.abbrev" <> ".")
            , (k "G" <> " graph", "v2, v1, off — as above, and it changes the commit order with it.")
            , (k "F" <> " refs", "In the main view, the reference labels. Elsewhere " <> k "F" <> " means something else entirely — Day 12 explains why.")
            ]
        p_ $ do
            "There is no need to remember which key is which. "
            k "o"
            " opens the "
            b_ "option menu"
            ", a list of every toggle with its current value, and pressing "
            k "Enter"
            " on a line cycles it. That menu is the discoverable front end to everything in this \
            \section."
        gotcha $ p_ $ do
            "None of this is saved. Quit tig and every toggle returns to its default, because \
            \toggles are in-memory display state. That is deliberate — they are for answering a \
            \question now. When you find yourself pressing the same three keys every single time \
            \you open tig, those three have earned a place in "
            c "~/.tigrc"
            ", and Day 7 puts them there."

    block "Today's habit" $ do
        p_ $ do
            "Spend today deciding how you want the main view to look. Press "
            k "D"
            " and "
            k "A"
            " until the columns read the way you would have designed them, and notice which \
            \settings you keep re-applying. Those are the first lines of your config, and you will \
            \write them on Day 7 having earned them."
        p_ "Tomorrow: opening a diff without losing the list you opened it from."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "The main view, compressed."
        " Toggles are per-session; Day 7 makes the ones you keep permanent."
    cfg
        [ "D   date     default -> relative -> compact -> custom -> off"
        , "A   author   full -> abbreviated -> email -> user -> off"
        , "X   id       off -> on   (abbreviated; title window shows all 40)"
        , "G   graph    v2 -> v1 -> off   (also changes the commit order)"
        , "F   refs     [branch] {remote} <tag> labels, on or off"
        , "#   line numbers      ~   ASCII vs drawing characters"
        , "o   option menu: every toggle, with its current value"
        , "H   jump to HEAD      R   reload      --all   every ref, not just this branch"
        , "# top three rows = your working tree, not commits (show-changes)"
        ]
