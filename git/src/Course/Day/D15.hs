module Course.Day.D15 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 15
        , dayTitle = "Cherry-pick, tags, describe"
        , daySubtitle = "Copying one commit's change elsewhere, and giving a commit a name that never moves."
        , dayMinutes = 35
        , dayLevel = "advanced"
        , dayManRef = "git-cherry-pick(1), git-tag(1), git-describe(1); gitrevisions(7) CHERRY_PICK_HEAD"
        , dayTags = ["cherry-pick", "tags", "releases"]
        , dayGoals =
            [ "backport a fix to a release branch with " <> c "cherry-pick -x" <> ", and tell afterwards which commits are already there"
            , "choose between lightweight and annotated tags, and push, move and delete them without surprising anyone"
            , "turn any commit into a human-readable version string with " <> c "git describe"
            ]
        , dayDiagram = Just d15diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git cherry-pick -x <commit>", "Apply one commit's change on top of " <> c "HEAD" <> " as a new commit, noting the original in the message.")
            , ("git cherry-pick A..B", "Pick every commit in the range, oldest first. " <> var "A" <> " itself is excluded.")
            , ("git cherry-pick --continue | --skip | --abort", "Resume after resolving, drop the current commit, or return to where you started.")
            , ("git log --cherry-mark --left-right A...B", "Mark commits on each side with " <> c "=" <> " when the other side has an equivalent patch.")
            , ("git tag -a v1.2 -m <msg> [<commit>]", "Create an annotated tag: a tag object with tagger, date and message.")
            , ("git tag v1.2 [<commit>]", "Create a lightweight tag: just a ref.")
            , ("git tag -l 'v1.*'", "List tags matching a glob.")
            , ("git push origin <tag>", "Publish one tag. Tags are not pushed with branches by default.")
            , ("git push origin --delete <tag>", "Delete a tag on the remote.")
            , ("git describe [--tags] [--dirty] [--always]", "Name " <> c "HEAD" <> " relative to the nearest annotated tag, e.g. " <> c "v1.1-1-gc6dcec7" <> ".")
            ]
        , dayOpts =
            [ ("tag.sort", "Default ordering for " <> c "git tag -l" <> "; " <> c "version:refname" <> " sorts " <> c "v1.10" <> " after " <> c "v1.9" <> ".")
            , ("push.followTags", "Also push annotated tags that point into the history being pushed.")
            ]
        , dayConfig =
            [ ConfBlock
                "List tags in version order, not string order: v1.9 before v1.10, and a release\n\
                \candidate before its release (versionsort.suffix)."
                "[tag]\n\
                \\tsort = version:refname\n\
                \[versionsort]\n\
                \\tsuffix = -rc"
            , ConfBlock
                "Push annotated tags along with the commits they point at, so a release tag cannot be\n\
                \forgotten. Lightweight tags stay local, which is what they are for."
                "[push]\n\
                \\tfollowTags = true"
            ]
        , dayDrills =
            [ "Run "
                <> c "git tag -l"
                <> " in a project with releases, then "
                <> c "git -c tag.sort=version:refname tag -l"
                <> ". Find the pair whose order changed."
            , "Run "
                <> c "git describe --tags"
                <> " in the same project. Decode it: which tag, how many commits since, which commit."
            , "Run "
                <> c "git cat-file -p"
                <> " on one annotated tag and "
                <> c "git cat-file -t"
                <> " on a lightweight one. Day 1's fourth object type, finally in the wild."
            , "In a scratch repository with two branches, "
                <> c "git cherry-pick -x"
                <> " a commit from one to the other. Compare the hashes, then the output of "
                <> c "git show <sha> | git patch-id"
                <> " for both."
            , "Break it on purpose: cherry-pick a commit that touches a line you changed differently. Read \
              \the conflict message, run "
                <> c "git status"
                <> ", then "
                <> c "git cherry-pick --abort"
                <> " and confirm nothing changed."
            , "On a real release branch, run "
                <> c "git log --oneline --cherry-mark --left-right main...release"
                <> " (your branch names) and find the fixes that were backported."
            , "Tag a scratch commit lightweight and annotated, set "
                <> c "push.followTags"
                <> ", push to a bare scratch remote, and check with "
                <> c "git ls-remote --tags"
                <> " which one travelled."
            , "Adopt the rule: release tags are annotated, pushed once, and never moved. Everything else is a \
              \branch."
            ]
        , dayQuiz =
            [
                ( "You cherry-picked a fix onto the release branch. Later, merging "
                    <> c "main"
                    <> " into it, you expect a conflict and get none, and the fix appears once. Yet "
                    <> c "git log release"
                    <> " shows two commits with the same message. Explain."
                , do
                    p_ $ do
                        "A cherry-pick is a new commit: same change, same message and author, but a different parent \
                        \and committer time, so a different hash. git does not record that the two are related \
                        \(except as text, if you used "
                        c "-x"
                        "). When you merge, the three-way merge sees both sides made the same change to the same \
                        \lines and takes it once — no conflict, but history holds both commits."
                    p_ $ do
                        "To see which commits are equivalent, compare "
                        em_ "patches"
                        ", not hashes: "
                        c "git log --cherry-mark --left-right A...B"
                        " marks them "
                        c "="
                        ", using the same patch-id "
                        c "git patch-id"
                        " computes."
                )
            ,
                ( c "git describe"
                    <> " on a fresh checkout says “No annotated tags can describe…”, but "
                    <> c "git tag"
                    <> " lists "
                    <> c "v2.0"
                    <> ". What is going on?"
                , p_ $ do
                    c "v2.0"
                    " is a lightweight tag — a plain ref with no tag object — and "
                    c "describe"
                    " considers only annotated tags by default, on the theory that lightweight ones are private \
                    \bookmarks. "
                    c "git describe --tags"
                    " uses both. The real fix is to make release tags annotated, which also records who tagged, \
                    \when, and why."
                )
            ,
                ( "You deleted a mistaken tag on the server with "
                    <> c "git push origin --delete v3.0"
                    <> ". The next day it is back. Who pushed it?"
                , p_ $ do
                    "Possibly you. Deleting a remote tag does nothing to the copies in every clone. With "
                    c "push.followTags"
                    " set, the next "
                    c "git push"
                    " from any clone that still has "
                    c "v3.0"
                    " — and whose pushed history contains its commit — sends it again. Delete it locally too ("
                    c "git tag -d v3.0"
                    ") and tell everyone else to do the same, or to run "
                    c "git fetch --prune --prune-tags"
                    " — which also deletes any tag of their own the remote lacks. Without "
                    c "--prune"
                    ", "
                    c "--prune-tags"
                    " does nothing."
                )
            ,
                ( "The maintainer moved "
                    <> c "v3.1"
                    <> " to a different commit and force-pushed it. Your "
                    <> c "git fetch --tags"
                    <> " prints "
                    <> c "! [rejected] v3.1 -> v3.1 (would clobber existing tag)"
                    <> ". Why does git refuse?"
                , p_ $ do
                    "Because a tag is a promise that a name means one commit forever, and a fetch that silently \
                    \changed it would let someone rewrite what “the v3.1 release” is on your machine without your \
                    \noticing. Branches are expected to move; tags are not. If you do trust the change, "
                    c "git fetch --tags --force"
                    " accepts it. The better answer is never to move a published tag: tag a "
                    c "v3.1.1"
                    " instead."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d15diagram :: Diagram
d15diagram =
    ( diagram
        "A cherry-picked commit has as parent the tip of your branch and has the same patch as the original \
        \commit, which has a different parent. A lightweight tag is a ref naming a commit. An annotated tag \
        \is a ref naming a tag object, which points at a commit and has a tagger and a message. A describe \
        \name counts commits from the nearest annotated tag."
        body'
    )
        { dgCaption = do
            "Cherry-pick copies a "
            b_ "patch"
            ", not a commit — the dashed aspect is the only link between the two, and git does not store it. \
            \Tags are refs like branches, with one difference in intent: they do not move. The annotated kind \
            \adds a real object between the name and the commit, and that object is what "
            c "describe"
            ", signing and "
            c "push.followTags"
            " look for."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  orig  [label=\"the original commit\"];\n\
        \  pick  [label=\"a cherry-picked commit\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  tip   [label=\"the tip of your branch\"];\n\
        \  light [label=\"a lightweight tag\"];\n\
        \  ann   [label=\"an annotated tag\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  tobj  [label=\"a tag object\"];\n\
        \  who   [label=\"a tagger, date\\nand message\", fillcolor=\"#f4efe6\"];\n\
        \  rel   [label=\"a release commit\"];\n\
        \  desc  [label=\"a describe name\\n(v1.1-1-gc6dcec7)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  pick  -> tip   [label=\"  has as parent\"];\n\
        \  pick  -> orig  [label=\"  has the same patch as\", style=dashed];\n\
        \  light -> rel   [label=\"  names\"];\n\
        \  ann   -> tobj  [label=\"  names\"];\n\
        \  tobj  -> rel   [label=\"  points at\"];\n\
        \  tobj  -> who   [label=\"  has\"];\n\
        \  desc  -> ann   [label=\"  counts commits from\"];\n\
        \\n\
        \  { rank=same; pick; light; ann; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Cherry-pick copies a change, not a commit" $ do
        p_ [class_ "lede"] $ do
            c "git cherry-pick X"
            " asks: what did "
            var "X"
            " change relative to its parent? Then it makes that same change on top of "
            c "HEAD"
            " and commits it, reusing "
            var "X"
            "'s message and author. The result is a new commit with a new parent, so — by Day 1's rules — a \
            \new hash. Nothing in the object store records that the two are related."
        sh
            [ "$ git switch release-1.x"
            , "$ git cherry-pick -x ef9fe6f"
            , "[release-1.x a0f2e06] Fix crash on empty input"
            , " 1 file changed, 1 insertion(+)"
            , "$ git log -1 --format=%B"
            , "Fix crash on empty input"
            , ""
            , "(cherry picked from commit ef9fe6f573928dc89a7f974fc17a54e935bc4d0c)"
            ]
        p_ $ do
            c "-x"
            " appends that last line, which is the only durable trace of where the change came from. Use it \
            \whenever you pick from a public branch — for backports it is the difference between \
            \“is this fix in 1.x?” being a search and being a guess. Leave it off when picking from your own \
            \unpublished branches, where the original will disappear."
        p_ $ do
            "Because the hashes differ, git compares cherry-picks by "
            b_ "patch-id"
            " instead: a hash of the diff with line numbers and whitespace ignored. Equal patch-ids mean \
            \“same change”:"
        sh
            [ "$ git show ef9fe6f | git patch-id"
            , "3c5eb97fe2e9bbe1df3424ee1a5dcc36a36c7145 ef9fe6f573928dc89a7f974fc17a54e935bc4d0c"
            , "$ git show a0f2e06 | git patch-id"
            , "3c5eb97fe2e9bbe1df3424ee1a5dcc36a36c7145 a0f2e0634760924b5d536f12df9d751be60ff77a"
            , "$ git log --oneline --cherry-mark --left-right main...release-1.x"
            , "= ef9fe6f Fix crash on empty input"
            , "= a0f2e06 Fix crash on empty input"
            , "< f837ffa Add feature b"
            ]
        why $ p_ $ do
            "Cherry-pick and revert (Day 8) are the same operation with the patch pointing in opposite \
            \directions: revert applies the inverse of a commit's diff, cherry-pick applies the diff. Both \
            \are three-way merges using the commit's parent as the base, which is why both can conflict, both \
            \stop with the same "
            c "--continue"
            " / "
            c "--skip"
            " / "
            c "--abort"
            " choices, and both work across unrelated branches."
        fig

    block "When a pick conflicts" $ do
        p_ $ do
            "A pick is a small merge, so it conflicts when the lines it touches have changed on your branch. \
            \git stops, leaves markers as on Day 4, and records the commit it was applying in "
            c "CHERRY_PICK_HEAD"
            ":"
        sh
            [ "$ git cherry-pick main"
            , "Auto-merging app.txt"
            , "CONFLICT (content): Merge conflict in app.txt"
            , "error: could not apply 929255c... Add feature c"
            , "$ git status | sed -n 2p"
            , "You are currently cherry-picking commit 929255c."
            ]
        steps
            [ do "Resolve, " <> c "git add" <> " the files, then " <> c "git cherry-pick --continue" <> "."
            , do c "git cherry-pick --skip" <> " drops this commit and moves on to the next one in a range."
            , do c "git cherry-pick --abort" <> " puts the branch back exactly where it was before the command."
            ]
        p_ $ do
            "Ranges use Day 7's syntax: "
            c "git cherry-pick A..B"
            " picks everything reachable from "
            var "B"
            " but not from "
            var "A"
            ", oldest first — "
            var "A"
            " itself is "
            em_ "not"
            " included. "
            c "A^..B"
            " includes it."
        gotcha $ p_ $ do
            "Cherry-picking between two long-lived branches that will later be merged gives you duplicate \
            \commits in history, and if either side edits the same lines again afterwards, real conflicts at \
            \merge time. It is the right tool for backports to release branches that are never merged back; \
            \for moving a whole series of your own work, rebase (Day 9) is usually what you meant."

    block "Two kinds of tag" $ do
        p_ $ do
            "A tag is a ref under "
            c "refs/tags/"
            ", like a branch under "
            c "refs/heads/"
            ", with one social difference: it is not supposed to move. There are two kinds, and they are \
            \different objects:"
        sh
            [ "$ git tag v1.1-light"
            , "$ git tag -a v1.1 -m 'Release 1.1'"
            , "$ git cat-file -t v1.1-light"
            , "commit"
            , "$ git cat-file -t v1.1"
            , "tag"
            , "$ git cat-file -p v1.1"
            , "object 929255cad3cd35a2076669f3366fa32df2428c70"
            , "type commit"
            , "tag v1.1"
            , "tagger Ada Example <ada@example.com> 1790319600 +0200"
            , ""
            , "Release 1.1"
            ]
        defs
            [ ("lightweight", "A ref that names a commit directly. No author, no date, no message. A bookmark: “the commit I deployed on Tuesday”.")
            , ("annotated", do "A ref naming a " <> b_ "tag object" <> " — Day 1's fourth type — that records the tagger, the time and a message, and can be signed (" <> c "-s" <> "). Use these for releases.")
            ]
        p_ $ do
            "Tags are not pushed with branches. Push one by name, "
            c "git push origin v1.1"
            ", or set "
            c "push.followTags"
            " (today's config), which sends every annotated tag that points into the history you are pushing \
            \and leaves lightweight ones behind. Delete a published one with "
            c "git push origin --delete v1.1"
            "."
        gotcha $ p_ $ do
            "Deleting a tag on the server does not delete it anywhere else, and with "
            c "followTags"
            " the next push from a clone that still has it puts it straight back. Moving a tag is worse: \
            \clones that already have it reject the new value with "
            c "would clobber existing tag"
            ". Published tags are forever; if a release was wrong, tag the next version."

    block "Version order, and describe" $ do
        p_ $ do
            "By default "
            c "git tag -l"
            " sorts by string, so "
            c "v1.10"
            " comes before "
            c "v1.2"
            ". "
            c "tag.sort = version:refname"
            " fixes that; "
            c "versionsort.suffix = -rc"
            " additionally puts "
            c "v2.0-rc1"
            " before "
            c "v2.0"
            " instead of after it:"
        sh
            [ "$ git tag -l | paste -sd' '"
            , "v1.10 v1.2 v2.0 v2.0-rc1"
            , "$ git -c tag.sort=version:refname -c versionsort.suffix=-rc tag -l | paste -sd' '"
            , "v1.2 v1.10 v2.0-rc1 v2.0"
            ]
        p_ $ do
            c "git describe"
            " goes the other way: from a commit to a name. It finds the nearest annotated tag reachable from "
            c "HEAD"
            " and says how far away you are:"
        sh
            [ "$ git describe"
            , "v1.1-1-gc6dcec7"
            , "$ echo x >> app.txt && git describe --dirty"
            , "v1.1-1-gc6dcec7-dirty"
            ]
        p_ $ do
            "Read it as: tag "
            c "v1.1"
            ", one commit after it, at commit "
            c "c6dcec7"
            " (the "
            c "g"
            " is for “git”). This is what build scripts embed as a version string, and it is also valid \
            \revision syntax — "
            c "git show v1.1-1-gc6dcec7"
            " works. "
            c "--tags"
            " lets lightweight tags count, "
            c "--always"
            " falls back to a bare abbreviated hash in a repository with no tags, and "
            c "--abbrev=0"
            " prints just the tag."

    block "Today's habit" $ do
        p_ $ do
            "Backports get "
            c "-x"
            ", every time. Releases get an annotated tag and are never moved. Add today's two config blocks \
            \so the tag list reads in version order and release tags travel with their commits."
        p_ $ do
            "Tomorrow: bisect — using the commit graph to find which of five hundred commits broke something, \
            \in about nine steps."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "A pick is a new commit with the same patch. A tag is a ref that must not move."
    cfg
        [ "git cherry-pick -x SHA         # backport; -x records the source"
        , "git cherry-pick A..B           # A excluded; A^..B to include it"
        , "git cherry-pick --continue | --skip | --abort"
        , "git log --cherry-mark --left-right A...B   # '=' = equivalent patch"
        , "git tag -a v1.2 -m 'Release'   # annotated: for releases"
        , "git tag wip-deploy             # lightweight: a local bookmark"
        , "git push origin v1.2           # or push.followTags = true"
        , "git push origin --delete v1.2  # others still have it"
        , "git describe [--tags] [--dirty] [--always] [--abbrev=0]"
        ]
