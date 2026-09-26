module Course.Day.D10 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 10
        , dayTitle = "Interactive rebase"
        , daySubtitle = "Editing the todo list: squash, reword, reorder and split, then prove nothing else changed."
        , dayMinutes = 35
        , dayLevel = "intermediate"
        , dayManRef = "git-rebase(1) INTERACTIVE MODE, git-commit(1) --fixup, git-range-diff(1)"
        , dayTags = ["rebase -i", "fixup", "range-diff"]
        , dayGoals =
            [ "read and edit a rebase todo list, knowing what each of " <> c "pick" <> ", " <> c "reword" <> ", " <> c "edit" <> ", " <> c "squash" <> ", " <> c "fixup" <> ", " <> c "drop" <> " and " <> c "exec" <> " will do"
            , "mark corrections as you work with " <> c "commit --fixup" <> " and fold them in later with one autosquash rebase"
            , "check a rewrite with " <> c "git range-diff" <> " before you push it"
            ]
        , dayDiagram = Just d10diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git rebase -i <base>", "Open the todo list for " <> c "<base>..HEAD" <> " in your editor, then run it.")
            , ("git rebase --edit-todo", "Re-open the remaining todo list while a rebase is stopped.")
            , ("git commit --fixup=<commit>", "Commit the staged change as " <> c "fixup! <subject>" <> ", to be melted into " <> var "commit" <> " later.")
            , ("git commit --fixup=amend:<commit>", "Like " <> c "--fixup" <> ", but the squash also replaces the target's message.")
            , ("git rebase -i --autosquash <base>", "Move every " <> c "fixup!" <> "/" <> c "squash!" <> "/" <> c "amend!" <> " commit under its target and mark it.")
            , ("git rebase -x '<cmd>' <base>", "Run " <> var "cmd" <> " after every replayed commit; stop at the first failure.")
            , ("git range-diff <base> <old> <new>", "Pair up the commits of two versions of a branch and show how each changed.")
            ]
        , dayOpts =
            [ ("rebase.autoSquash", "Make " <> c "rebase -i" <> " autosquash by default. Interactive mode only.")
            , ("rebase.updateRefs", "Also move any branch that points into the rebased range (" <> c "--update-refs" <> ").")
            ]
        , dayConfig =
            [ ConfBlock
                { cbTitle =
                    "Fold fixup! commits into their targets on every interactive rebase, and keep\n\
                    \stacked branches attached when the branch under them is rebased."
                , cbCode =
                    "[rebase]\n\
                    \\tautoSquash = true\n\
                    \\tupdateRefs = true"
                }
            ]
        , dayDrills =
            [ "On any branch with a few commits of your own, run "
                <> c "git rebase -i @{u}"
                <> " (or "
                <> c "main"
                <> "), read the help comment at the bottom, and quit the editor without changing anything. Nothing \
                   \happens."
            , "Change the second "
                <> c "pick"
                <> " to "
                <> c "reword"
                <> " and fix a commit message. Only that commit's hash, and those after it, change."
            , "Make a correction to an older commit on purpose: stage it, run "
                <> c "git commit --fixup=:/<word from its subject>"
                <> ", and then "
                <> c "git rebase -i --autosquash main"
                <> ". Read the todo list it prepared for you."
            , "Split a commit: mark it "
                <> c "edit"
                <> ", and when the rebase stops run "
                <> c "git reset HEAD~"
                <> ", commit the pieces separately with "
                <> c "git add -p"
                <> ", then "
                <> c "git rebase --continue"
                <> "."
            , "Break it on purpose: run "
                <> c "git rebase -x 'false' main"
                <> ". Watch it stop after the first commit, then "
                <> c "git rebase --abort"
                <> "."
            , "Before and after tidying one of your own branches, record the old tip with "
                <> c "git branch -f before"
                <> "; then run "
                <> c "git range-diff main before HEAD"
                <> " and read every "
                <> c "!"
                <> " line."
            , "Stack two branches, add the "
                <> c "[rebase]"
                <> " block below to your config, rebase the top one onto "
                <> c "main"
                <> " and check that the lower one moved too."
            , "From today, when you notice a mistake in an earlier commit of your branch, do not fix it in a \
              \“fix typo” commit: fix it with "
                <> c "--fixup"
                <> " and let the next rebase put it where it belongs."
            ]
        , dayQuiz =
            [
                ( "You set "
                    <> opt "rebase.autoSquash"
                    <> " to true, run a plain "
                    <> c "git rebase main"
                    <> ", and your "
                    <> c "fixup!"
                    <> " commits are still there. Why?"
                , p_ $ do
                    "Because the setting only applies to interactive mode — git-config(1) says “for interactive \
                    \mode”, and in 2.52 a plain rebase with it set left the "
                    c "fixup!"
                    " commit in place. Either run "
                    c "git rebase -i main"
                    " and accept the prepared list, or pass "
                    c "--autosquash"
                    " explicitly: "
                    c "git rebase --autosquash main"
                    " does squash: the option rewrites the todo list itself, and "
                    c "-i"
                    " only adds the chance to review it in an editor first."
                )
            ,
                ( "You delete a line from the todo list to get rid of a commit, save, and the commit is gone. \
                  \Next week you delete a line by accident. What did the help text warn you about, and how \
                  \do you get the commit back?"
                , p_ $ do
                    "The todo list says in capitals: “If you remove a line here THAT COMMIT WILL BE LOST.” "
                    c "drop"
                    " and deleting a line are the same operation. The commit is not destroyed, only unreferenced: \
                    \the branch's pre-rebase position is in the reflog (Day 11), so "
                    c "git reset --hard ORIG_HEAD"
                    " right after the rebase, or "
                    c "git branch rescue <branch>@{1}"
                    " later, brings the whole old branch back. "
                    opt "rebase.missingCommitsCheck"
                    " can make a missing line an error instead."
                )
            ,
                ( "You rebase "
                    <> c "part2"
                    <> ", which is stacked on "
                    <> c "part1"
                    <> ", onto a newer "
                    <> c "main"
                    <> ". "
                    <> c "git log --graph --all"
                    <> " now shows a stray copy of "
                    <> c "part1"
                    <> "'s commit. What happened?"
                , p_ $ do
                    "The rebase copied "
                    c "part1"
                    "'s commit, because it was in "
                    c "main..part2"
                    ", but only moved "
                    c "part2"
                    ". "
                    c "part1"
                    " still names the original. With "
                    c "--update-refs"
                    " (or "
                    opt "rebase.updateRefs"
                    ") the todo list gains an "
                    c "update-ref refs/heads/part1"
                    " line after that commit, and at the end git reports “Updated the following refs with \
                    \--update-refs”. Both branches then sit on the new copies."
                )
            ,
                ( "After a large interactive rebase you want to be sure you only squashed and reworded, and did \
                  \not change any code by accident while resolving conflicts. How do you check?"
                , do
                    p_ $ do
                        c "git diff ORIG_HEAD HEAD"
                        " answers the blunt question — if you only reorganised, the final trees are identical and it \
                        \is empty. It says nothing about the individual commits, though."
                    p_ $ do
                        c "git range-diff main ORIG_HEAD HEAD"
                        " pairs old commits with new ones by their patches: "
                        c "="
                        " for unchanged, "
                        c "!"
                        " with a diff-of-diffs for changed, "
                        c "<"
                        " and "
                        c ">"
                        " for commits only on one side. A squashed commit appears as "
                        c "!"
                        " with the absorbed lines."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d10diagram :: Diagram
d10diagram =
    ( diagram
        "Interactive rebase as types: an interactive rebase runs a todo list; a todo list is a sequence of \
        \instructions; an instruction names an original commit and produces a new commit or nothing; a \
        \fixup commit targets an earlier commit and is placed under it by autosquash; a range-diff compares \
        \the old and new sequences of commits."
        body'
    )
        { dgCaption = do
            b_ "the todo list"
            " is the whole interface: a plain text program that the rebase runs top to bottom. Everything \
            \else here — "
            c "--fixup"
            ", autosquash, "
            c "update-ref"
            " — is a way of writing that program for you, and "
            c "range-diff"
            " is how you check what it did."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  rebase [label=\"an interactive rebase\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  todo   [label=\"the todo list\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  instr  [label=\"an instruction\\n(pick, fixup, edit…)\"];\n\
        \  orig   [label=\"an original commit\"];\n\
        \  newc   [label=\"a new commit\"];\n\
        \  fix    [label=\"a fixup! commit\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  editor [label=\"your editor\", fillcolor=\"#f4efe6\"];\n\
        \  rd     [label=\"a range-diff\"];\n\
        \\n\
        \  rebase -> todo   [label=\"  runs\"];\n\
        \  editor -> todo   [label=\"  edits\"];\n\
        \  todo   -> instr  [label=\"  is a sequence of\"];\n\
        \  instr  -> orig   [label=\"  names\"];\n\
        \  instr  -> newc   [label=\"  produces (unless drop)\", style=dashed];\n\
        \  fix    -> orig   [label=\"  targets\"];\n\
        \  rd     -> orig   [label=\"  pairs\"];\n\
        \  rd     -> newc   [label=\"  pairs\"];\n\
        \\n\
        \  { rank=same; editor; rebase; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "The todo list is a program you are allowed to edit" $ do
        p_ [class_ "lede"] $ do
            "Yesterday's rebase replayed your commits in order, unchanged. "
            c "git rebase -i"
            " shows you the list of what it is about to do before it does it, in your editor, as plain text. \
            \Change a word and a commit is reworded; move a line and commits are reordered; change "
            c "pick"
            " to "
            c "fixup"
            " and two commits become one. You are writing a small script that builds a new history."
        sh
            [ "$ git rebase -i main"
            , "pick cc91ff3 # Add parser"
            , "pick 7a9b2f2 # Add renderer"
            , "pick 811582b # wip"
            , ""
            , "# Rebase 092a8dc..811582b onto 092a8dc (3 commands)"
            , "#"
            , "# Commands:"
            , "# p, pick <commit> = use commit"
            , "# r, reword <commit> = use commit, but edit the commit message"
            , "# e, edit <commit> = use commit, but stop for amending"
            , "# s, squash <commit> = use commit, but meld into previous commit"
            , "# f, fixup [-C | -c] <commit> = like \"squash\" but keep only the previous"
            , "#                    commit's log message, unless -C is used, ..."
            , "# x, exec <command> = run command (the rest of the line) using shell"
            , "# b, break = stop here (continue rebase later with 'git rebase --continue')"
            , "# d, drop <commit> = remove commit"
            , "# ..."
            , "# If you remove a line here THAT COMMIT WILL BE LOST."
            ]
        p_ $ do
            "The list is oldest first — the reverse of "
            c "git log"
            " — because it is executed top to bottom. Saving an unchanged list performs an ordinary rebase; \
            \deleting every line aborts. The trailing "
            c "label"
            ", "
            c "reset"
            ", "
            c "merge"
            " and "
            c "update-ref"
            " commands in the help exist for rebasing merges and stacks; you meet "
            c "update-ref"
            " below and can ignore the others."
        why $ p_ $ do
            "Making the plan a text file in your editor means git needs no user interface for history \
            \surgery at all. Everything you know about editing text — moving lines, search and replace, \
            \undo — is the interface. It also means the plan can be written by a program: "
            c "GIT_SEQUENCE_EDITOR"
            " (see git(1), ENVIRONMENT) names a command to edit the list instead of you, which is how \
            \this lesson's transcripts were produced."
        fig

    block "The instructions you will actually use" $ do
        defs
            [ (c "pick", "Replay the commit unchanged.")
            , (c "reword", "Replay it, then open the editor on its message. The code is not touched.")
            , (c "edit", "Replay it and stop, so you can " <> c "commit --amend" <> " it or split it with " <> c "reset HEAD~" <> " and several commits; then " <> c "--continue" <> ".")
            , (c "squash", "Meld into the previous commit and edit the combined message.")
            , (c "fixup", "Meld into the previous commit and keep the previous commit's message. " <> c "fixup -C" <> " keeps this commit's message instead.")
            , (c "drop", "Leave the commit out. Deleting the line does the same.")
            , (c "exec", "Run a shell command at this point; a non-zero exit stops the rebase.")
            , (c "break", "Stop here, as if an " <> c "edit" <> " had just finished.")
            ]
        p_ $ do
            "Turning the third line's "
            c "pick"
            " into "
            c "fixup"
            " folds the "
            c "wip"
            " commit into “Add renderer”:"
        sh
            [ "$ git log --oneline main.."
            , "f3a0f76 Add renderer"
            , "cc91ff3 Add parser"
            ]
        tip $ p_ $ do
            "While a rebase is stopped at an "
            c "edit"
            ", "
            c "break"
            " or conflict, "
            c "git rebase --edit-todo"
            " lets you change the rest of the plan, and "
            c "git status"
            " shows what has been done and what is next."

    block "Fixup commits: decide where it goes now, squash it later" $ do
        p_ $ do
            "Most tidying is the same move: a small correction belongs in an earlier commit. "
            c "git commit --fixup=<commit>"
            " records it with a subject that says so, and any revision expression from Day 7 will do as the \
            \target:"
        sh
            [ "$ git commit -a --fixup=':/Add parser'"
            , "$ git log --oneline main.."
            , "d352992 fixup! Add parser"
            , "f3a0f76 Add renderer"
            , "cc91ff3 Add parser"
            , "$ git rebase -i --autosquash main"
            , "pick cc91ff3 # Add parser"
            , "fixup d352992 # fixup! Add parser"
            , "pick f3a0f76 # Add renderer"
            ]
        p_ $ do
            c "--autosquash"
            " moved the fixup under its target and marked it before showing you the list. Accept it and the \
            \correction disappears into “Add parser”. "
            c "--fixup=amend:<commit>"
            " goes a step further: it opens the editor for a replacement message, and the squash rewrites the \
            \target's message too."
        gotcha $ p_ $ do
            opt "rebase.autoSquash"
            " applies to "
            b_ "interactive"
            " rebases only. With it set, plain "
            c "git rebase main"
            " printed “Current branch feat is up to date.” and left "
            c "fixup! Add parser"
            " where it was. Use "
            c "rebase -i"
            " (and accept the list), or pass "
            c "--autosquash"
            " explicitly, which does squash without opening an editor."

    block "Test every step, and check the result" $ do
        p_ $ do
            c "git rebase -x '<cmd>'"
            " inserts an "
            c "exec"
            " line after every commit. The rebase stops at the first commit where the command fails, so you \
            \find out which of your rewritten commits broke the build, not only that the last one did:"
        sh
            [ "$ git rebase -x 'test -f render.py' main"
            , "Executing: test -f render.py"
            , "warning: execution failed: test -f render.py"
            , "You can fix the problem, and then run"
            , ""
            , "  git rebase --continue"
            ]
        p_ $ do
            "Then compare the old branch with the new one. "
            c "git range-diff <base> <old> <new>"
            " pairs commits by content and prints a diff of their diffs:"
        sh
            [ "$ git range-diff main v1 feat"
            , "1:  34b584e = 1:  34b584e Add parser"
            , "2:  f667da0 = 2:  f667da0 Add renderer"
            , "3:  96caefd ! 3:  f148b94 Add numbers"
            , "    @@ nums.txt (new)"
            , "     +14"
            , "    -+15"
            , "    ++fifteen"
            , "     +16"
            ]
        p_ $ do
            c "="
            " means the commit is untouched, "
            c "!"
            " that it changed and how. Right after a rebase, "
            c "git range-diff main ORIG_HEAD HEAD"
            " needs no saved branch. Read it before every force-push; it is the review of your own rewrite."

    block "Stacked branches, and the config worth keeping" $ do
        p_ $ do
            "If "
            c "part2"
            " is built on "
            c "part1"
            ", rebasing "
            c "part2"
            " copies "
            c "part1"
            "'s commits too but leaves "
            c "part1"
            " pointing at the originals. "
            c "--update-refs"
            " adds an "
            c "update-ref"
            " line to the todo list for every branch inside the range:"
        sh
            [ "$ git rebase main"
            , "Successfully rebased and updated refs/heads/part2."
            , "Updated the following refs with --update-refs:"
            , "\trefs/heads/part1"
            , "$ git log --graph --all --format='%h %s%d'"
            , "* 0d05aa8 P2 (HEAD -> part2)"
            , "* ae46bbd P1 (part1)"
            , "* a30d61d M (main)"
            ]
        p_ $ do
            "Both behaviours are worth having on by default. "
            opt "rebase.updateRefs"
            " applies to plain rebases as well as interactive ones (the transcript above had it set); "
            opt "rebase.autoSquash"
            " prepares every interactive todo list with your fixups already in place."

    block "Today's habit" $ do
        p_ $ do
            "Commit as messily as you like while working, but mark corrections with "
            c "--fixup"
            " as you make them. Before you ask for review, run one "
            c "git rebase -i"
            " to tidy, one "
            c "git range-diff"
            " to check, and only then push."
        p_ $ do
            "Tomorrow: the reflog, which is why none of today's rewrites could lose anything for good."

cheat :: Html ()
cheat =
    cfg
        [ "git rebase -i main               # edit the plan for main..HEAD"
        , "#  pick reword edit squash fixup drop exec break   (oldest first)"
        , "git rebase --edit-todo           # change the rest of the plan"
        , "git commit --fixup=REV           # 'fixup! <subject>' for later"
        , "git commit --fixup=amend:REV     # ...and replace REV's message"
        , "git rebase -i --autosquash main  # fixups moved under targets"
        , "git rebase -x 'make test' main   # stop at the first broken commit"
        , "git range-diff main ORIG_HEAD HEAD   # = same  ! changed  <> gone/new"
        , "[rebase] autoSquash = true       # interactive mode only"
        , "[rebase] updateRefs = true       # stacked branches follow"
        ]
