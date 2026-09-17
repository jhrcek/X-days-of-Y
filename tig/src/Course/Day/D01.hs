module Course.Day.D01 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 1
        , dayTitle = "The viewer model"
        , daySubtitle = "A view is a git command's output, and views live on a stack."
        , dayMinutes = 30
        , dayLevel = "essential"
        , dayManRef = "tigmanual(7) DESCRIPTION, THE VIEWER"
        , dayTags = ["views", "view stack", "browsing state"]
        , dayGoals =
            [ "say what a tig view actually is, and name the git command behind the one you are looking at"
            , "open, stack and close views without ever being unsure which key gets you out"
            , "read the title window: which view, which commit, how far down, still loading"
            ]
        , dayDiagram = Just d1diagram
        , dayBody = body
        , dayKeys =
            [ ("m", "Open the main view — the one-line-per-commit list.")
            , ("d", "Open the diff view for the selected commit.")
            , ("s", "Open the status view: the working tree. " <> k "S" <> " does the same.")
            , ("h", "Open the help view: every binding that is live right now.")
            , ("q", "Close this view and fall back to the one underneath. Quits if it is the last.")
            , ("Q", "Quit immediately, however deep the stack.")
            , ("R", "Reload the current view by re-running its git command.")
            , ("v", "Show the version — and prove which build you are on.")
            , ("z", "Stop all background loading. For when you opened a 200,000-commit history.")
            ]
        , dayCmds =
            [ ("tig", "Open the main view for the current branch.")
            , ("tig status", "Start in the status view instead.")
            , ("tig -C <path>", "Run as if started in " <> var "path" <> ".")
            , ("tig -v", "Print the version and exit. Also reveals the optional features built in.")
            ]
        , dayOpts = []
        , dayConfig = []
        , dayDrills =
            [ "In a repository you know well, run "
                <> c "tig"
                <> " and press "
                <> k "q"
                <> ". That is the whole loop: you are back at the shell with nothing changed."
            , "Run "
                <> c "tig"
                <> " again. Press "
                <> k "h"
                <> " and scroll the help view once, top to bottom. Do not memorise it — notice \
                   \instead that it is organised by "
                <> i_ "keymap"
                <> ", and that the first section is called "
                <> c "generic"
                <> "."
            , "From the main view press "
                <> k "d"
                <> ", then "
                <> k "s"
                <> ", then "
                <> k "m"
                <> ". Now press "
                <> k "q"
                <> " four times slowly and watch which view you land on each time. That is the stack."
            , "Break it on purpose: run "
                <> c "tig"
                <> " somewhere that is not a git repository. Read the error, then run "
                <> c "tig -C ~/some/repo"
                <> " from the same place and watch it work anyway."
            , "Press "
                <> k "v"
                <> " and write down what it says. If there is no "
                <> c "PCRE"
                <> " line, your searches on Day 5 are POSIX extended regexps, not Perl ones."
            , "Open the biggest repository you have and press "
                <> k "z"
                <> " while the main view is still filling. The title window stops counting; the \
                   \commits already loaded stay usable."
            , "Today's habit: every time this week that you would have typed "
                <> c "git log"
                <> ", type "
                <> c "tig"
                <> " instead. Nothing else from this course sticks without that substitution."
            ]
        , dayQuiz =
            [
                ( "You press "
                    <> k "q"
                    <> " expecting to leave tig and instead land in a different view you do not \
                       \remember opening. What happened?"
                , do
                    p_ $ do
                        k "q"
                        " is "
                        c "view-close"
                        ", not “quit”. Views stack: opening the diff view from the main view leaves \
                        \the main view underneath rather than replacing it. Closing pops one level, \
                        \so you surface through the views you opened, in reverse order."
                    p_ $ do
                        "The view you landed in is the one you opened first and forgot about — often \
                        \the main view from before a detour through status. "
                        k "Q"
                        " is the unconditional exit, and it is the key to reach for when you want the \
                        \shell back rather than the previous screen."
                )
            ,
                ( "Two people run "
                    <> c "tig"
                    <> " in the same repository at the same moment and see different commit \
                       \lists. Neither has committed anything. How?"
                , do
                    p_ $ do
                        "A view is not a window onto a database that tig maintains. It is the "
                        b_ "output of a git command, captured once"
                        ", when the view opened. The main view runs "
                        c "git log"
                        " with whatever revision arguments were on the command line, and holds the \
                        \result."
                    p_ $ do
                        "So "
                        c "tig"
                        " and "
                        c "tig --all"
                        " disagree, and so do two instances started either side of a "
                        c "git fetch"
                        ". "
                        k "R"
                        " re-runs the command; until you press it, you are reading a snapshot."
                )
            ,
                ( "The title window says "
                    <> c "[main] … - commit 1 of 61 loading 5s"
                    <> ". What is tig waiting for, and what can you still do?"
                , do
                    p_ $ do
                        "It is waiting for "
                        c "git log"
                        " to finish writing. tig reads the pipe incrementally and renders what has \
                        \arrived, so the view is usable while loading. The "
                        c "loading 5s"
                        " suffix only appears once a view has taken more than three seconds."
                    p_ $ do
                        "You can navigate and open child views on the commits already loaded. If you \
                        \do not need the rest — and in a large repository you rarely do — "
                        k "z"
                        " stops every background load at once."
                )
            ,
                ( "Why is there no “refresh everything” key, and why does tig sometimes update \
                  \without being asked?"
                , do
                    p_ $ do
                        "Because refreshing means re-running a git command per view, which is \
                        \expensive on a large repository. "
                        k "R"
                        " reloads the current view only, deliberately."
                    p_ $ do
                        "The unasked-for updates come from "
                        opt "refresh-mode"
                        ", which defaults to "
                        c "auto"
                        ": when tig notices a modification made through another view — you staged \
                        \something — it refreshes the views that care. Day 14 turns this down for \
                        \repositories where it costs too much."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d1diagram :: Diagram
d1diagram =
    ( diagram
        "The tig viewer model: a git command produces output, a view captures that output, views \
        \are stacked by the viewer, the viewer tracks a browsing state consisting of a head ID and \
        \a commit ID, and the display shows the top view together with a title window and a status \
        \window."
        body'
    )
        { dgCaption = do
            "Everything tig shows you came out of a git command that it ran and captured. That is \
            \why "
            k "R"
            " exists, why two views can disagree, and why a view keeps working while it is still \
            \loading. The dashed aspects are the "
            b_ "browsing state"
            " — a head ID and a commit ID that follow your cursor, and that every child view and \
            \every external command is opened against."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  git  [label=\"a git command\\n(git log, git show,\\ngit blame)\", fillcolor=\"#f4efe6\"];"
            , "  out  [label=\"captured output\", fillcolor=\"#f4efe6\"];"
            , "  view [label=\"a view\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  stack [label=\"the view stack\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  state [label=\"the browsing state\\n(a head ID,\\na commit ID)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  disp [label=\"the display\"];"
            , "  title [label=\"the title window\"];"
            , "  stat [label=\"the status window\"];"
            , ""
            , "  git   -> out   [label=\"  produces\"];"
            , "  view  -> out   [label=\"  captures\"];"
            , "  stack -> view  [label=\"  is built from\"];"
            , "  stack -> view  [label=\"has as current  \", style=dashed, constraint=false];"
            , "  disp  -> stack [label=\"  shows the top of\"];"
            , "  disp  -> title [label=\"  reserves\"];"
            , "  disp  -> stat  [label=\"  reserves\"];"
            , "  view  -> state [label=\"  updates\", style=dashed];"
            , "  state -> git   [label=\"  parameterises\", style=dashed];"
            , ""
            , "  { rank=same; title; stat; }"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "tig is a reader, not a git client" $ do
        p_ [class_ "lede"] $ do
            "tig does not reimplement git. Every screen you will see is the "
            b_ "captured output of a git command"
            " that tig ran on your behalf, parsed just enough to colour it and to know which line \
            \is a commit. Hold onto that and the rest of the tool stops being surprising."
        p_ $ do
            "The main view is "
            c "git log"
            " with a "
            c "--pretty"
            " format tig chose. The diff view is "
            c "git show"
            ". The blame view is "
            c "git blame"
            ", the tree view is "
            c "git ls-tree"
            ", the grep view is "
            c "git grep"
            ". When something looks wrong in tig, the first question is what the underlying command \
            \would have printed — and usually you can run it yourself and find out."
        p_ $ do
            "This is also why tig is safe to explore. Reading is all it does by default. The few \
            \keys that change your repository are a short list, they live in the status and stash \
            \views, and you will meet them deliberately on Day 6 and Day 9."
        why $ p_ $ do
            "Building on git's own output rather than on libgit2 is what keeps tig honest. Your "
            c ".gitconfig"
            " aliases, your "
            c "diff.algorithm"
            ", your "
            c "core.abbrev"
            ", your mailmap — all of it applies, because the same commands run underneath. The cost \
            \is that tig inherits git's performance on a huge repository, which is why Day 14 spends \
            \time on making large histories bearable."
        fig

    block "A view is a screenful with a command behind it" $ do
        p_ $ do
            "There are fourteen view types. You will use five of them constantly and meet the rest \
            \as they become useful. Today only three matter:"
        defs
            [
                ( k "m" <> " main"
                , do
                    "One line per commit: date, author, and the first line of the message, with \
                    \branch and tag names in brackets. This is the view tig opens with, and the one \
                    \you will live in."
                )
            ,
                ( k "d" <> " diff"
                , do
                    "The selected commit in full: message, diffstat, patch. Opening it from the main \
                    \view is the single most common thing anyone does in tig."
                )
            ,
                ( k "s" <> " status"
                , do
                    "Your working tree — staged, unstaged and untracked files. This is the view that \
                    \replaces "
                    c "git add -p"
                    ", on Day 6."
                )
            ]
        p_ $ do
            "The remaining nine — log, reflog, tree, blob, blame, refs, stash, grep, pager, help — \
            \arrive on Days 8, 9 and 10. "
            k "h"
            " opens the help view at any time, and unlike a printed key list it shows the bindings \
            \that are actually live, including any you have added yourself."

    block "The stack, and the two ways out" $ do
        p_ $ do
            "Views do not replace each other. Opening one "
            b_ "pushes"
            " it onto a stack, and the view you came from is still sitting underneath with its \
            \cursor where you left it."
        ascii
            [ "  tig                    press d               press s"
            , "  ┌──────────┐           ┌──────────┐          ┌──────────┐"
            , "  │  main    │           │  diff    │          │  status  │  <- what you see"
            , "  └──────────┘           ├──────────┤          ├──────────┤"
            , "                         │  main    │          │  diff    │"
            , "                         └──────────┘          ├──────────┤"
            , "                                               │  main    │"
            , "                                               └──────────┘"
            , ""
            , "  q  pops one level          Q  drops the whole stack and exits"
            ]
        p_ $ do
            k "q"
            " closes the top view and reveals the one below; press it enough times and the last \
            \close quits tig. "
            k "Q"
            " quits immediately from any depth. Getting these two straight on the first day saves a \
            \great deal of confused key-mashing later."
        gotcha $ p_ $ do
            "Depth is easy to lose track of, because a view opened from a view opened from a view \
            \looks exactly like one opened directly. If "
            k "q"
            " lands you somewhere unexpected rather than at the shell, you are not lost — you are \
            \three deep. Use "
            k "Q"
            " when you mean “I am done with tig”, and keep "
            k "q"
            " for “I am done with this screen”."

    block "The two windows that are always there" $ do
        p_ $ do
            "Whatever view is on top, the bottom two lines of the terminal belong to tig itself."
        termStatus
            "tig"
            [ "2026-03-05 16:00 Ada Lovelace  ●─╮ [master] Merge branch 'feature/parser'"
            , "2026-03-03 09:30 Ada Lovelace  │ ∙ [feature/parser] Implement parse()"
            , "2026-03-02 11:00 Ada Lovelace  │ ∙ Add parser header"
            , "2026-03-04 14:00 Ada Lovelace  ∙ │ Start the manual"
            , "2026-03-01 10:00 Ada Lovelace  ◎─╯ <v1.0> Initial import"
            ]
            "[main] 7a023dd8c0aa2b818a7157790708dc30960b8b5d - commit 1 of 5"
            "100%"
        p_ $ do
            "The "
            b_ "title window"
            " is the second line from the bottom and answers three questions at once: which view \
            \you are in ("
            c "[main]"
            "), what the browsing state currently points at (the full commit ID), and where you are \
            \in the view ("
            c "commit 1 of 5"
            ", and a percentage on the right). If a view takes more than three seconds it also \
            \appends "
            c "loading 5s"
            " and counts."
        p_ $ do
            "The very last line is the "
            b_ "status window"
            ". It is blank most of the time and is where tig puts errors, prompts and the output of \
            \commands that report a single line. It is the only place some failures are ever \
            \mentioned, so when a key seems to do nothing, look there first."
        note $ p_ $ do
            "The commit ID in the title is the "
            b_ "full forty characters"
            ", not the abbreviated one shown in the view. That matters on Day 13, when external \
            \commands substitute it into shell commands."

    block "Browsing state: what the cursor quietly carries" $ do
        p_ $ do
            "tig tracks two identifiers as you move: a "
            b_ "head ID"
            " (the revision the history views were opened against, "
            c "HEAD"
            " by default) and a "
            b_ "commit ID"
            " that follows the cursor and changes every time you highlight a different line."
        p_ $ do
            "That pair is why child views feel telepathic. Pressing "
            k "d"
            " does not ask which commit you meant — the commit ID already says. Reopening the diff \
            \view reloads it only if the commit ID changed since last time, which is what makes \
            \arrowing down a commit list with a diff open feel instant rather than laggy."
        tip $ p_ $ do
            "This same state is what Day 13 hands to external commands as "
            c "%(commit)"
            ", "
            c "%(branch)"
            ", "
            c "%(file)"
            " and friends. “The thing under the cursor” is a first-class concept in tig, not an \
            \afterthought — which is why a five-line "
            c "~/.tigrc"
            " can turn it into a code-review tool."

    block "Today's habit" $ do
        p_ $ do
            "Replace one reflex, today: "
            c "git log"
            " becomes "
            c "tig"
            ". They take the same arguments — "
            c "tig --oneline"
            " and "
            c "tig -p"
            " both work, because the options go straight through to "
            c "git log"
            " — so the substitution costs you nothing and you get a navigable list instead of a \
            \pager full of text."
        p_ $ do
            "Tomorrow: the main view in detail, including the three rows at the top that look like \
            \commits and are not."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Day 1 in eight lines."
        " Everything else this fortnight is elaboration."
    cfg
        [ "tig               # main view: git log, navigable"
        , "tig status        # start in the working-tree view instead"
        , "tig -C ~/repo     # run as if started somewhere else"
        , "m d s             # open the main / diff / status view"
        , "h                 # help: the bindings that are live right now"
        , "q                 # close this view (pops the stack)"
        , "Q                 # quit, however deep you are"
        , "R                 # reload: re-run this view's git command"
        , "z                 # stop background loading on a huge history"
        ]
