module Course.Day.D09 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 9
        , dayTitle = "Refs, stashes and the reflog"
        , daySubtitle = "The views that browse names instead of history — and the keys that act."
        , dayMinutes = 34
        , dayLevel = "intermediate"
        , dayManRef = "tigmanual(7) Views, External Commands; tigrc(5) SET COMMAND"
        , dayTags = ["refs", "stash", "reflog", "grep"]
        , dayGoals =
            [ "switch branches, apply stashes and search file contents without leaving tig"
            , "use the reflog view to recover a commit you thought you had lost"
            , "recognise which keys in these views change the repository, and which of those prompt first"
            ]
        , dayDiagram = Just d9diagram
        , dayBody = body
        , dayKeys =
            [ ("r", "Refs view: branches, remotes and tags.")
            , ("y", "Stash view: the stash stack.")
            , ("L", "Reflog view: where HEAD has been.")
            , ("g", "Grep view: search file contents.")
            , ("C (refs, reflog)", "Check out the branch under the cursor. Prompts first.")
            , ("! (refs, stash, reflog)", "Delete the branch, drop the stash, or reset --hard. All prompt first.")
            , ("A (stash)", "Apply the selected stash, keeping the entry.")
            , ("P (stash)", "Pop it: apply and remove the entry.")
            ]
        , dayCmds =
            [ ("tig refs", "Start in the refs view.")
            , ("tig stash", "Start in the stash view.")
            , ("tig reflog", "Start in the reflog view.")
            , ("tig grep <pattern>", "Start in the grep view. Takes " <> c "git grep" <> " options.")
            , ("tig refs --branches", "Limit the refs view to branches.")
            ]
        , dayOpts =
            [ ("grep-view", "Columns of the grep view. Adding " <> c "file-name" <> " gives the " <> c "git grep" <> " shape.")
            ]
        , dayConfig = day9config
        , dayDrills =
            [ "Press "
                <> k "r"
                <> " to open the refs view. Put the cursor on a branch and press "
                <> k "Enter"
                <> " — the main view below reloads to show that branch's history."
            , "With the cursor on a branch you do not need, press "
                <> k "C"
                <> ". Read the confirmation prompt, then answer no. Now do it again on a branch you \
                   \do want and answer yes: you have checked out a branch from inside tig."
            , "Stash something with "
                <> c "git stash"
                <> ", then press "
                <> k "y"
                <> ". Press "
                <> k "Enter"
                <> " on the stash to see its diff before deciding anything."
            , "Apply it with "
                <> k "A"
                <> ", then check "
                <> c "git stash list"
                <> " and confirm the stash is still there. Now do it with "
                <> k "P"
                <> " and check again. Learn the difference once."
            , "Press "
                <> k "L"
                <> " for the reflog. Find a commit you have reset away from, or an old branch tip. \
                   \Press "
                <> k "Enter"
                <> " to inspect it."
            , "Break it on purpose: in the reflog view press "
                <> k "!"
                <> " and read the prompt very carefully. That one is "
                <> c "git reset --hard"
                <> ". Answer no."
            , "Today's habit: when you next think “I've lost that commit”, press "
                <> k "L"
                <> " before you panic. It is almost always in there."
            ]
        , dayQuiz =
            [
                ( "tigmanual(7) lists exactly three built-in external commands, one of which is "
                    <> c "G"
                    <> " running "
                    <> c "git gc"
                    <> ". You press "
                    <> k "G"
                    <> " in the main view and the commit graph disappears. What is going on?"
                , do
                    p_ $ do
                        "The manual is out of date. On 2.6.1 there is no "
                        c "git gc"
                        " binding at all — dumping every live binding with "
                        c ":save-options"
                        " shows nothing running "
                        c "gc"
                        ". "
                        k "G"
                        " in the main keymap is "
                        c ":toggle commit-title-graph"
                        ", which is what you saw."
                    p_ $ do
                        "It has gone the other way too: the binary ships several external commands \
                        \the manual does not mention, including everything in today's lesson — "
                        c "C"
                        " and "
                        c "!"
                        " in the refs and reflog views, and "
                        c "A"
                        ", "
                        c "P"
                        ", "
                        c "!"
                        " in the stash view. The help view ("
                        k "h"
                        ") is generated from reality; the manual is not."
                )
            ,
                ( "What is the difference between "
                    <> k "A"
                    <> " and "
                    <> k "P"
                    <> " in the stash view, and which should you reach for?"
                , do
                    p_ $ do
                        k "A"
                        " runs "
                        c "git stash apply"
                        ": the changes come back and the stash entry stays. "
                        k "P"
                        " runs "
                        c "git stash pop"
                        ": the changes come back and the entry is removed."
                    p_ $ do
                        "Reach for "
                        k "A"
                        ". If applying produces conflicts or turns out to be the wrong stash, you \
                        \still have the entry and can try again; with "
                        k "P"
                        " on a conflict you are left resolving by hand with nothing to fall back \
                        \on. Drop it deliberately with "
                        k "!"
                        " once you are sure — that is one keystroke of insurance."
                )
            ,
                ( "You reset a branch to an earlier commit and now want the work back, but you \
                  \never wrote down the hash. Which view, and why does it have what you need?"
                , do
                    p_ $ do
                        "The reflog view, "
                        k "L"
                        ". The reflog records every position "
                        c "HEAD"
                        " and your branches have held, whether or not anything still references \
                        \those commits, so the commit you reset away from is listed with the \
                        \operation that moved you off it."
                    p_ $ do
                        "The lines read like "
                        c "a992b98 commit: Start the manual"
                        " and "
                        c "0b12e18 checkout: moving from feature/parser to master"
                        ". Put the cursor on the one you want, press "
                        k "Enter"
                        " to confirm it is the right commit, and then recover it with a branch: "
                        c ":!git branch rescue %(commit)"
                        " is safer than any of the keys in that view."
                )
            ,
                ( "The grep view groups matches under filename headings, but you wanted one line \
                  \per match like "
                    <> c "git grep"
                    <> ". What changes it?"
                , do
                    p_ $ do
                        "The "
                        opt "grep-view"
                        " column list. Its default has "
                        c "file-name:no"
                        ", so tig shows a heading per file and bare matches beneath. Turning the \
                        \column on puts the filename on each match line instead:"
                    p_ $ do
                        c "set grep-view = file-name:yes line-number:yes,interval=1 text"
                        " — which is tomorrow's Day 11 machinery arriving early. The saved options \
                        \will report it back as "
                        c "file-name:auto"
                        ", because "
                        c "yes"
                        " resolves to that column's default display mode, and the effect is what you \
                        \asked for."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

day9config :: [ConfBlock]
day9config =
    [ ConfBlock
        "Put the filename on every grep match instead of grouping matches under per-file\n\
        \headings. Same shape as git grep, so the view can be read and copied line by line."
        "set grep-view = file-name:yes line-number:yes,interval=1 text"
    ]

-- ---------------------------------------------------------------------------

d9diagram :: Diagram
d9diagram =
    ( diagram
        "Four views that browse things other than the commit list: the refs view lists branches, \
        \remotes and tags; the stash view lists stash entries; the reflog view lists positions HEAD \
        \has held; the grep view lists matching lines in files. Each names a commit, and each has \
        \keys bound to git commands that change the repository."
        body'
    )
        { dgCaption = do
            "These four views browse "
            b_ "names"
            " rather than history, and each one resolves to a commit you can open. The amber box is \
            \what makes today different from every earlier day: these views carry keys bound to \
            \real git commands. All of them prompt first, and all of them are built in rather than \
            \documented."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  refs  [label=\"the refs view\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  stash [label=\"the stash view\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  rlog  [label=\"the reflog view\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  grep  [label=\"the grep view\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  name  [label=\"a branch, remote\\nor tag name\"];"
            , "  entry [label=\"a stash entry\"];"
            , "  pos   [label=\"a position HEAD held\"];"
            , "  line  [label=\"a matching line\"];"
            , "  cmt   [label=\"a commit\", fillcolor=\"#f4efe6\"];"
            , "  act   [label=\"a git command\\nC checkout  ! delete/reset\\nA apply  P pop\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  refs  -> name  [label=\"  lists\"];"
            , "  stash -> entry [label=\"  lists\"];"
            , "  rlog  -> pos   [label=\"  lists\"];"
            , "  grep  -> line  [label=\"  lists\"];"
            , "  name  -> cmt   [label=\"  points at\"];"
            , "  entry -> cmt   [label=\"  is\"];"
            , "  pos   -> cmt   [label=\"  was\"];"
            , "  line  -> cmt   [label=\"  can be blamed to\", style=dashed];"
            , "  act   -> name  [label=\"  acts on\", style=dashed];"
            , "  act   -> entry [label=\"  acts on\", style=dashed];"
            , ""
            , "  { rank=same; refs; stash; rlog; grep; }"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Four views, one shape" $ do
        p_ [class_ "lede"] $ do
            "Everything until now has browsed the commit list or a file. These four browse "
            b_ "names"
            ": branch names, stash entries, places HEAD has been, lines that match a pattern. Each \
            \one resolves to a commit you can open with "
            k "Enter"
            ", and each carries a few keys that run real git commands."
        fig

    block "The refs view: branches as a list you can act on" $ do
        p_ $ do
            k "r"
            " opens every branch, remote and tag, most recent first:"
        termStatus
            "tig — refs view"
            [ "                              All references"
            , "2026-03-05 16:00 Ada Lovelace master         Merge branch 'feature/parser'"
            , "2026-03-03 09:30 Ada Lovelace feature/parser Implement parse()"
            , "2026-03-01 10:00 Ada Lovelace v1.0           Initial import"
            ]
            "[refs] All references"
            "100%"
        p_ $ do
            k "Enter"
            " on a branch reloads the main view at that branch — the fastest way to answer “what \
            \has been happening on release/3.2” without checking anything out. "
            c "tig refs --branches"
            ", "
            c "--remotes"
            " or "
            c "--tags"
            " limits which categories appear."
        p_ "Two keys here change your repository, and both prompt first:"
        defs
            [ (k "C", c "git checkout %(branch)" <> " — switch to the branch under the cursor.")
            , (k "!", c "git branch -D %(branch)" <> " — force-delete it.")
            ]
        gotcha $ p_ $ do
            "Note that "
            k "!"
            " is "
            c "-D"
            ", not "
            c "-d"
            ": it deletes the branch whether or not it has been merged. The confirmation prompt is \
            \the only thing between you and losing an unmerged branch. The commits survive in the \
            \reflog for a while, but the name does not, and names are how you find things."

    block "The stash view, and why A beats P" $ do
        p_ $ do
            k "y"
            " lists the stash stack. "
            k "Enter"
            " shows a stash's diff — which is the real value, because "
            c "git stash list"
            " tells you nothing about what is in each entry and "
            c "stash@{2}"
            " is not a memorable name."
        defs
            [ (k "A", c "git stash apply %(stash)" <> " — restore the changes, keep the entry.")
            , (k "P", c "git stash pop %(stash)" <> " — restore the changes, remove the entry.")
            , (k "!", c "git stash drop %(stash)" <> " — discard the entry.")
            ]
        tip $ p_ $ do
            "Prefer "
            k "A"
            ". If the stash conflicts, or turns out to be the wrong one, the entry is still there \
            \and you can reset and try again; "
            k "P"
            " on a conflicted apply leaves you resolving by hand with nothing to go back to. Drop \
            \it with "
            k "!"
            " when you are sure. One extra keystroke, considerably less regret."

    block "The reflog: the view that undoes your mistakes" $ do
        p_ $ do
            k "L"
            " — a capital L, because lower-case "
            k "l"
            " is the log view — opens the reflog:"
        termStatus
            "tig — reflog view"
            [ "7a023dd [master] reset: moving to HEAD"
            , "7a023dd [master] merge feature/parser: Merge made by the 'ort' strategy."
            , "a992b98 commit: Start the manual"
            , "0b12e18 <v1.0> checkout: moving from feature/parser to master"
            , "785f586 [feature/parser] commit: Implement parse()"
            ]
            "[reflog] HEAD@{0} - reference 1 of 8"
            "100%"
        p_ $ do
            "Every position HEAD has held, with the operation that moved it. This is where a commit \
            \goes when you reset past it, when a rebase abandons it, when you delete the branch \
            \that pointed at it. It is not lost; it is here, until git's garbage collection \
            \eventually takes it weeks later."
        p_ $ do
            "The recovery move is to find the commit, press "
            k "Enter"
            " to confirm it is the one, and then give it a name. The two keys bound in this view — "
            k "C"
            " for "
            c "git checkout %(branch)"
            " and "
            k "!"
            " for "
            c "git reset --hard %(commit)"
            " — are both blunter than you usually want."
        gotcha $ p_ $ do
            k "!"
            " in the reflog view is "
            c "git reset --hard"
            ". It prompts, and you should read that prompt as carefully as you have ever read \
            \anything, because answering yes with uncommitted work in your tree destroys it. When \
            \recovering, prefer "
            c ":!git branch rescue-me %(commit)"
            " — it creates a name, changes nothing else, and cannot lose anything."

    block "The grep view" $ do
        p_ $ do
            k "g"
            ", or "
            c "tig grep <pattern>"
            ", searches file "
            i_ "contents"
            " — which is the thing "
            k "/"
            " on Day 5 could not do. It takes "
            c "git grep"
            "'s options, so "
            c "tig grep -i -w parse"
            " works as you would expect."
        p_ $ do
            "By default matches are grouped under a heading per file. If you would rather have the \
            \filename on every line, in the shape "
            c "git grep"
            " itself prints, that is a one-line setting — and it is today's config block."
        note $ p_ $ do
            "All four of today's views are missing from tigmanual(7)'s “External Commands” table, \
            \which lists three built-in commands and gets one of them wrong. Everything in this \
            \lesson was read out of the running binary with "
            c ":save-options"
            ". When you want to know what a key really does, that command and the help view are the \
            \authorities."

    block "Today's habit" $ do
        p_ $ do
            "Stop running "
            c "git branch -a"
            " and "
            c "git stash list"
            ". Press "
            k "r"
            " and "
            k "y"
            " instead — both give you the same list plus the ability to look inside before you act. \
            \And the next time something goes wrong, reach for "
            k "L"
            " before you reach for a search engine."
        p_ "Tomorrow: everything you can say to tig before it starts."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Four views, and the keys that act."
        " Everything in the last block prompts first."
    cfg
        [ "r   refs view      Enter = show that branch's history in main"
        , "y   stash view     Enter = show the stash's diff before deciding"
        , "L   reflog view    (capital L — l is the log view)"
        , "g   grep view      tig grep <pattern>, takes git grep options"
        , ""
        , "refs:    C checkout branch     ! branch -D  (force, even unmerged)"
        , "stash:   A apply (keeps it)    P pop (removes it)    ! drop"
        , "reflog:  C checkout            ! reset --hard   <- read the prompt"
        , "# recovering a lost commit: :!git branch rescue %(commit)  — safer than any of these"
        ]
