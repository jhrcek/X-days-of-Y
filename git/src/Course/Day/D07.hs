module Course.Day.D07 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 7
        , dayTitle = "The revision language"
        , daySubtitle = "Naming any commit, file or set of commits without ever copying a hash."
        , dayMinutes = 35
        , dayLevel = "essential"
        , dayManRef = "SYMBOLIC IDENTIFIERS; gitrevisions(7), git-rev-parse(1)"
        , dayTags = ["revisions", "ranges", "rev-parse"]
        , dayGoals =
            [ "walk from any name to any ancestor with " <> c "~" <> " and " <> c "^" <> ", including into the second parent of a merge"
            , "say in one sentence what " <> c "A..B" <> " and " <> c "A...B" <> " select, and why " <> c "git diff" <> " reads them differently"
            , "check what any expression means with " <> c "git rev-parse" <> " before handing it to a command that changes something"
            ]
        , dayDiagram = Just d7diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git rev-parse --verify <rev>", "Resolve an expression to one object name, or fail. The checker for everything today.")
            , ("git rev-parse --abbrev-ref <rev>", "Print the short ref name an expression means: " <> c "@{u}" <> " becomes " <> c "origin/main" <> ".")
            , ("git rev-parse --symbolic-full-name <rev>", "Print the full ref name, e.g. " <> c "refs/remotes/origin/main" <> ".")
            , ("git log A..B", "List commits reachable from B but not from A: what B has that A lacks.")
            , ("git log --left-right A...B", "List commits on either side but not both, marked " <> c "<" <> " or " <> c ">" <> ".")
            , ("git diff A...B", "Diff from the merge base of A and B to B: what B changed since they split.")
            , ("git show <rev>:<path>", "Print a file as it was in any commit, without checking anything out.")
            , ("git show :<path>", "Print the version of a file currently staged in the index.")
            ]
        , dayOpts = []
        , dayConfig = []
        , dayDrills =
            [ "In any repository run "
                <> c "git rev-parse --abbrev-ref HEAD"
                <> " and "
                <> c "git rev-parse --abbrev-ref @{u}"
                <> ". One names your branch; the other either names its upstream or tells you there is none."
            , "Print a file as it was ten commits ago with "
                <> c "git show HEAD~10:<path>"
                <> ". Then print the staged version of a file you have modified with "
                <> c "git show :<path>"
                <> "."
            , "Break it on purpose: find a commit that is not a merge and ask for "
                <> c "<commit>^2"
                <> ". Read the error, then find a real merge with "
                <> c "git log --merges -1"
                <> " and list the branch it brought in with "
                <> c "git log --oneline <merge>^-"
                <> "."
            , "On your own feature branch, run "
                <> c "git log --oneline @{u}.."
                <> " (what you have not pushed) and "
                <> c "git log --oneline ..@{u}"
                <> " (what you have not pulled). Fetch first."
            , "Run "
                <> c "git log --oneline --left-right @{u}...HEAD"
                <> " after a fetch, on a branch that has diverged from its upstream. Count the arrows on each \
                   \side and check them against the “ahead” and “behind” numbers in "
                <> c "git status"
                <> "."
            , "Compare "
                <> c "git diff --stat main..HEAD"
                <> " with "
                <> c "git diff --stat main...HEAD"
                <> " on the same branch. Explain every file that appears in only one of them."
            , "Find the most recent commit whose message mentions a word you remember, with "
                <> c "git show -s ':/<word>'"
                <> "."
            , "From today, before any command that moves a branch, run the same expression through "
                <> c "git rev-parse --verify"
                <> " or "
                <> c "git log -1"
                <> " first. It costs one second."
            ]
        , dayQuiz =
            [
                ( "On a merge commit, "
                    <> c "HEAD~2"
                    <> " and "
                    <> c "HEAD^2"
                    <> " name different commits. Which is which, and when does it matter?"
                , do
                    p_ $ do
                        c "~2"
                        " is two generations back along first parents: the parent's parent. "
                        c "^2"
                        " is the second parent of this commit — on a merge, the tip of the branch that was merged \
                        \in. On a non-merge commit "
                        c "^2"
                        " does not exist and git refuses."
                    p_ $ do
                        "It matters whenever you walk history through merges. Following "
                        c "~"
                        " keeps you on the mainline (what "
                        c "main"
                        " looked like at each step); "
                        c "^2"
                        " steps sideways into the feature. "
                        c "HEAD~1^2~1"
                        " reads left to right: one back on the mainline, into that merge's second parent, one back \
                        \along the feature."
                )
            ,
                ( "You run "
                    <> c "git log main..feature"
                    <> " and get nothing, although "
                    <> c "feature"
                    <> " definitely has commits. What happened?"
                , p_ $ do
                    "Two dots mean “reachable from "
                    c "feature"
                    ", minus everything reachable from "
                    c "main"
                    "”. If "
                    c "feature"
                    " has already been merged into "
                    c "main"
                    ", every one of its commits is reachable from "
                    c "main"
                    " too, so the set is empty. The range does not describe a branch's history; it describes a \
                    \difference between two sets of commits. Empty output means “nothing left to merge”, which is \
                    \often exactly the question you wanted answered."
                )
            ,
                ( "A reviewer asks for “the diff of your branch”. "
                    <> c "git diff main..feature"
                    <> " shows your changes plus a pile of reversed changes from other people. Why, and \
                       \what should you have typed?"
                , do
                    p_ $ do
                        c "git diff"
                        " does not take ranges of commits; it compares two endpoints. For diff, "
                        c "main..feature"
                        " is "
                        c "main feature"
                        ": the tree of "
                        c "main"
                        " today against the tree of "
                        c "feature"
                        ". Everything merged into "
                        c "main"
                        " since you branched shows up reversed, as if you had deleted it."
                    p_ $ do
                        c "git diff main...feature"
                        " compares the merge base with "
                        c "feature"
                        ": only what your branch changed. It is the diff a pull request shows. The dots mean one \
                        \thing to "
                        c "log"
                        " and another to "
                        c "diff"
                        ", and the man pages say so in different places."
                )
            ,
                ( "You tag a release "
                    <> c "main"
                    <> " by mistake. Now "
                    <> c "git log main"
                    <> " shows old history and prints a warning. What rule is at work?"
                , p_ $ do
                    "gitrevisions(7) resolves a bare name by trying, in order: a file in "
                    c ".git/"
                    " (like "
                    c "HEAD"
                    "), then "
                    c "refs/<name>"
                    ", then "
                    c "refs/tags/<name>"
                    ", then "
                    c "refs/heads/<name>"
                    ", then remotes. Tags come before branches, so the tag wins and git warns “refname 'main' is \
                    \ambiguous”. Spell the branch out as "
                    c "heads/main"
                    " until you delete the tag with "
                    c "git tag -d main"
                    "."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d7diagram :: Diagram
d7diagram =
    ( diagram
        "The revision language as types: an expression resolves to an object; a ref resolves to a commit; \
        \a commit has first and other parents; a commit and a path name a blob; two commits determine a \
        \merge base; a range is a set of commits determined by included and excluded commits."
        body'
    )
        { dgCaption = do
            "Every expression in gitrevisions(7) is a walk along these arrows. The suffixes "
            c "~"
            ", "
            c "^n"
            " and "
            c ":path"
            " each follow one aspect from "
            b_ "a commit"
            "; a range is not a commit at all but "
            b_ "a set of commits"
            ", which is why only commands that walk history accept one."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  expr   [label=\"a revision expression\", fillcolor=\"#f4efe6\"];\n\
        \  ref    [label=\"a ref\"];\n\
        \  commit [label=\"a commit\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  blob   [label=\"a blob or tree\"];\n\
        \  path   [label=\"a path\", fillcolor=\"#f4efe6\"];\n\
        \  base   [label=\"a merge base\"];\n\
        \  set    [label=\"a set of commits\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  expr   -> ref    [label=\"  may start at\"];\n\
        \  ref    -> commit [label=\"  resolves to\"];\n\
        \  commit -> commit [label=\"  has as first parent (~)\"];\n\
        \  commit -> commit [label=\"  has as n-th parent (^n)\", style=dashed];\n\
        \  commit -> blob   [label=\"  contains at a path (:)\"];\n\
        \  blob   -> path   [label=\"  is found at\"];\n\
        \  commit -> base   [label=\"  shares with another commit\"];\n\
        \  set    -> commit [label=\"  includes what is reachable from\"];\n\
        \  set    -> commit [label=\"  excludes what is reachable from (^)\", style=dashed];\n\
        \\n\
        \  { rank=same; expr; set; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Every argument that names a commit is an expression" $ do
        p_ [class_ "lede"] $ do
            "Wherever a git command takes "
            var "commit"
            ", "
            var "tree-ish"
            " or "
            var "rev"
            ", it accepts a small language, documented once in gitrevisions(7) and used by every command. \
            \Learn it and you stop copying hashes out of "
            c "git log"
            ": you say "
            c "HEAD~3"
            ", "
            c "@{u}"
            ", "
            c "main...feature"
            " or "
            c "v2.1:src/app.c"
            " and git does the walking."
        p_ $ do
            "An expression starts from a name and applies suffixes. The name is a hash prefix, a ref ("
            c "main"
            ", "
            c "origin/main"
            ", "
            c "v1.4"
            "), "
            c "HEAD"
            ", or one of the special files like "
            c "ORIG_HEAD"
            " and "
            c "FETCH_HEAD"
            ". "
            c "@"
            " alone is short for "
            c "HEAD"
            ". Each suffix follows one arrow from Day 1's object model: to a parent, into a tree, back \
            \through the reflog."
        why $ p_ $ do
            "The language exists because git's objects are named by hash and a hash is useless to a human. \
            \Instead of forcing you to look names up, git lets you describe a position relative to one you \
            \know. Because the language is shared, anything you learn here works in "
            c "log"
            ", "
            c "show"
            ", "
            c "diff"
            ", "
            c "reset"
            ", "
            c "rebase"
            ", "
            c "switch"
            " and the rest without further study."
        fig

    block "Walking back: tilde follows, caret chooses" $ do
        p_ $ do
            "Build a small history with one merge so there is something to walk. "
            c "M"
            " merged "
            c "feature"
            " ("
            c "F1"
            ", "
            c "F2"
            ") into "
            c "main"
            " after "
            c "C"
            ":"
        sh
            [ "$ git log --oneline --graph"
            , "* cae481f D"
            , "*   619e39e M"
            , "|\\"
            , "| * cca7ee6 F2"
            , "| * 1956a5b F1"
            , "* | e6927c6 C"
            , "|/"
            , "* d287932 B"
            , "* 5aad59a A"
            ]
        defs
            [
                ( c "HEAD~" <> ", " <> c "HEAD~1" <> ", " <> c "HEAD^"
                , "The first parent: " <> c "M" <> ". On a commit with one parent, tilde and caret agree."
                )
            ,
                ( c "HEAD~2"
                , "Two generations along first parents: " <> c "C" <> ". Tilde never leaves the mainline."
                )
            ,
                ( c "HEAD~1^2"
                , "The second parent of " <> c "M" <> ": " <> c "F2" <> ", the tip of the merged branch. Caret picks which parent."
                )
            ,
                ( c "HEAD~1^2~1"
                , "Into the merged branch, then one back along it: " <> c "F1" <> "."
                )
            ]
        p_ $ do
            "Read left to right, one step at a time. "
            c "HEAD^^2"
            " is the same as "
            c "HEAD~1^2"
            "; "
            c "HEAD~3"
            " is "
            c "B"
            ", reached through "
            c "C"
            " and never through "
            c "F1"
            "."
        sh
            [ "$ git log -1 --format=%s HEAD^2"
            , "fatal: ambiguous argument 'HEAD^2': unknown revision or path not in the working tree."
            ]
        p_ $ do
            c "D"
            " has one parent, so it has no second one. Note the wording of the error: git could not parse \
            \the word as a revision, so it tried it as a file name and failed at that too. That message is \
            \what you get for every typo in this language."

    block "Names for other places" $ do
        defs
            [
                ( c "@{-1}"
                , do
                    "The branch you were on before this one. "
                    c "git switch -"
                    " is shorthand for it; "
                    c "@{-2}"
                    " goes further back."
                )
            ,
                ( c "@{u}" <> ", " <> c "main@{upstream}"
                , do
                    "The remote-tracking branch this branch is set to build on (Day 5). Fails with “no \
                    \upstream configured” if there is none. "
                    c "@{push}"
                    " is where "
                    c "git push"
                    " would go, which differs only in triangular setups."
                )
            ,
                ( c ":/fix race"
                , "The youngest commit, reachable from any ref, whose message matches the regex. " <> c "HEAD^{/fix race}" <> " restricts the search to history behind " <> c "HEAD" <> "."
                )
            ,
                ( c "v1.4:src/main.c"
                , "The blob at that path in that commit's tree. A path starting " <> c "./" <> " is relative to where you stand."
                )
            ,
                ( c ":src/main.c"
                , "The version of the file in the index (stage 0). During a conflict, " <> c ":1:" <> ", " <> c ":2:" <> ", " <> c ":3:" <> " are base, ours and theirs (Day 4)."
                )
            ,
                ( c "HEAD@{1}" <> ", " <> c "main@{yesterday}"
                , "Where a ref pointed before, from your local reflog. Day 11 is about nothing else."
                )
            ]
        p_ $ do
            "When a name is ambiguous, git takes the first of: a file in "
            c ".git/"
            ", "
            c "refs/<name>"
            ", "
            c "refs/tags/<name>"
            ", "
            c "refs/heads/<name>"
            ", "
            c "refs/remotes/<name>"
            ", "
            c "refs/remotes/<name>/HEAD"
            ". Tags beat branches:"
        sh
            [ "$ git tag main HEAD~3"
            , "$ git log -1 --format=%s main"
            , "warning: refname 'main' is ambiguous."
            , "B"
            , "$ git log -1 --format=%s heads/main"
            , "D"
            ]
        tip $ p_ $ do
            c "git rev-parse"
            " is the checker. "
            c "--verify"
            " resolves to exactly one object or fails (add "
            c "-q"
            " to fail silently with exit status 1, for scripts); "
            c "--abbrev-ref"
            " and "
            c "--symbolic-full-name"
            " tell you which ref a name landed on. Put an unfamiliar expression through it before you "
            c "reset"
            " to it."
        note $ p_ $ do
            "Quote anything with spaces or shell metacharacters: "
            c "'main@{2 hours ago}'"
            ", "
            c "':/fix race'"
            ". gitrevisions(7) warns that the shell may need extra quoting; git itself never sees the quotes."

    block "Ranges are sets, not segments" $ do
        p_ $ do
            "Commands that walk history ("
            c "log"
            ", "
            c "rev-list"
            ", "
            c "shortlog"
            ", "
            c "range-diff"
            ") take a set of commits. One name means “this commit and everything reachable from it”. A "
            c "^"
            " in front "
            em_ "excludes"
            " everything reachable from that name. The dotted forms are shorthand:"
        ascii
            [ "expression      means                           answers"
            , "A..B            ^A B                            what does B have that A lacks?"
            , "A...B           A B --not $(merge-base A B)     what does each side have that the other lacks?"
            , "@{u}..          ^@{u} HEAD                      what have I not pushed?"
            , "..@{u}          ^HEAD @{u}                      what have I not pulled? (after a fetch)"
            , "X^!             X ^X^@                          just X, none of its parents"
            , "X^-             ^X^1 X                          everything merge X brought in, plus X"
            , "X^@             X^1 X^2 ...                     all parents of X, and their history"
            ]
        p_ $ do
            "With a branch "
            c "other"
            " that forked from "
            c "feature"
            " and gained "
            c "G"
            ", "
            c "--left-right"
            " marks which side each commit of a symmetric difference came from:"
        sh
            [ "$ git log --format='%m %s' --left-right main...other"
            , "< D"
            , "> G"
            , "< M"
            , "< C"
            , "$ git log --format=%s HEAD~1^- | xargs"
            , "M F2 F1"
            ]
        p_ $ do
            "Writing two ranges side by side does not give you two ranges. "
            c "git log A..B C..D"
            " is one set: reachable from B or D, and from neither A nor C. Only a few commands, like "
            c "range-diff"
            " (Day 10), take two ranges on purpose."
        gotcha $ do
            p_ $ do
                c "git diff"
                " does not walk history, and the dots mean something else to it. "
                c "git diff A..B"
                " is the same as "
                c "git diff A B"
                ": two snapshots. "
                c "git diff A...B"
                " is the diff from their merge base to B — only what B's side changed:"
            sh
                [ "$ git diff --stat main..other"
                , " C.txt | 1 -"
                , " D.txt | 1 -"
                , " G.txt | 1 +"
                , "$ git diff --stat main...other"
                , " G.txt | 1 +"
                ]
            p_ $ do
                "The first shows "
                c "main"
                "'s own work as deletions, because "
                c "other"
                " lacks it. The second is what a pull request shows. Two dots in "
                c "log"
                " and three dots in "
                c "diff"
                " answer the same question: what did this branch do?"

    block "Today's habit" $ do
        p_ $ do
            "Stop copying hashes. For the next week, every time you reach for the mouse to copy a hash out of "
            c "git log"
            ", write the expression instead — "
            c "HEAD~2"
            ", "
            c "@{u}"
            ", "
            c "':/typo'"
            " — and run it through "
            c "git log -1"
            " to check it."
        p_ $ do
            "That is the end of the essentials. From tomorrow you use this language to move branches around \
            \on purpose: "
            c "reset"
            ", "
            c "restore"
            " and "
            c "revert"
            "."

cheat :: Html ()
cheat =
    cfg
        [ "HEAD~3        # three back along first parents     @ = HEAD"
        , "M^2           # second parent of merge M (the merged tip)"
        , "@{-1}         # previous branch (git switch -)"
        , "@{u}          # this branch's upstream, e.g. origin/main"
        , ":/regex       # youngest commit whose message matches"
        , "REV:path      # a file as of REV       :path = staged version"
        , "A..B          # in B, not in A         (@{u}.. = unpushed)"
        , "A...B         # in either, not both    (log --left-right)"
        , "diff A...B    # merge-base(A,B) -> B: what B's side changed"
        , "X^!  X^-      # just X / everything merge X brought in"
        , "git rev-parse --verify --abbrev-ref EXPR   # check before acting"
        ]
