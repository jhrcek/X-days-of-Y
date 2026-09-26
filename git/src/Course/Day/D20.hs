module Course.Day.D20 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 20
        , dayTitle = "Inside .git"
        , daySubtitle = "Loose objects, packfiles, packed refs — and what garbage collection is actually allowed to collect."
        , dayMinutes = 35
        , dayLevel = "advanced"
        , dayManRef = "gitrepository-layout(5); git-gc(1), git-maintenance(1), git-verify-pack(1); git(1) --git-dir, --work-tree, --bare"
        , dayTags = ["repository layout", "packfiles", "gc"]
        , dayGoals =
            [ "find your way around " <> c ".git" <> " and say what each file and directory is for"
            , "watch loose objects become a packfile, and read the deltas inside one"
            , "predict whether " <> c "git gc" <> " will delete an unreachable object today, in two weeks, or never"
            ]
        , dayDiagram = Just d20diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git count-objects -vH", "Count loose and packed objects, with human-readable sizes.")
            , ("git gc", "Pack loose objects, pack refs, expire reflogs, prune old unreachable objects.")
            , ("git gc --prune=now", "Also delete unreachable objects at once, ignoring the two-week grace period.")
            , ("git verify-pack -v <pack>.idx", "List every object in a pack: size, packed size, delta depth and base.")
            , ("git fsck", "Check every object's hash and every link between objects.")
            , ("git maintenance run --task=<task>", "Run one maintenance task now: " <> c "gc" <> ", " <> c "commit-graph" <> ", " <> c "prefetch" <> ", " <> c "loose-objects" <> ", " <> c "incremental-repack" <> "…")
            , ("git maintenance start", "Register this repository and install an hourly background schedule.")
            , ("git init --bare", "Create a repository with no working tree — the shape of every server-side repository.")
            ]
        , dayOpts =
            [ ("gc.pruneExpire", "How old an unreachable object must be before gc deletes it. Default " <> c "2.weeks.ago" <> ".")
            , ("gc.cruftPacks", "Keep unreachable objects in a cruft pack rather than loose. Default true.")
            , ("gc.auto", "Loose-object count above which " <> c "git gc --auto" <> " packs. Default 6700.")
            , ("--git-dir / --work-tree", "Point git at a repository and a working tree explicitly; turns off discovery.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Run "
                <> c "ls .git"
                <> " and "
                <> c "git count-objects -vH"
                <> " in a repository you use. Note how many objects are loose and how many packs there are."
            , "In a scratch repository, commit a 20000-line file, then five one-line edits. Run "
                <> c "git count-objects -vH"
                <> ", then "
                <> c "git gc"
                <> ", then again. Compare the sizes."
            , "Run "
                <> c "git verify-pack -v .git/objects/pack/*.idx | grep blob"
                <> " on that scratch repository. Find which version of the file is stored whole and which are deltas."
            , "After the "
                <> c "gc"
                <> ", look for "
                <> c ".git/refs/heads/main"
                <> ". Then read "
                <> c ".git/packed-refs"
                <> ". Tell yourself why scripts must use "
                <> c "git rev-parse"
                <> " instead of "
                <> c "cat"
                <> "."
            , "Break it on purpose: from a subdirectory, run "
                <> c "git --git-dir=../.git status --short"
                <> ". Read why every file outside the subdirectory now looks deleted."
            , "Make a commit, "
                <> c "git reset --hard HEAD~1"
                <> ", run "
                <> c "git gc"
                <> ", and confirm with "
                <> c "git cat-file -t"
                <> " that the dropped commit survives. Work out which rule saved it."
            , "Try the dotfiles pattern in a scratch directory: a bare repository plus "
                <> c "--work-tree"
                <> ", with "
                <> c "status.showUntrackedFiles no"
                <> "."
            , "From now on, when a repository feels slow or big, start with "
                <> c "git count-objects -vH"
                <> " before reaching for anything that rewrites history."
            ]
        , dayQuiz =
            [
                ( "You committed a secret, reset it away, and ran "
                    <> c "git gc"
                    <> ". "
                    <> c "git cat-file -p <hash>"
                    <> " still prints it. Name the two things protecting it."
                , do
                    p_ $ do
                        "First, the reflog: "
                        c "HEAD@{1}"
                        " still names the commit, so it is reachable and gc keeps it (Day 11). Second, the \
                        \grace period: even once unreachable, an object is kept until it is older than "
                        opt "gc.pruneExpire"
                        ", two weeks by default. In 2.52 it waits in a "
                        b_ "cruft pack"
                        " (the one with a "
                        c ".mtimes"
                        " file), not as a loose file."
                    p_ $ do
                        c "git reflog expire --expire=now --all && git gc --prune=now"
                        " removes it locally. It does nothing for clones that already have it; a pushed secret \
                        \is rotated, not deleted."
                )
            ,
                ( "Day 1 said git stores snapshots, not diffs. "
                    <> c "git verify-pack -v"
                    <> " shows most of your file's versions stored as deltas. Was Day 1 wrong?"
                , do
                    p_ $ do
                        "No. Deltas are how a "
                        b_ "packfile"
                        " compresses objects, below the object model: ask for any blob and you get the full \
                        \contents, however it is stored. The deltas are chosen for size, not along history."
                    p_ $ do
                        "The experiment in this lesson shows it plainly: the "
                        em_ "newest"
                        " version of the file is stored whole, and the original version is a delta of depth 3 \
                        \based on the second edit. Recent objects are the ones you read most, so they are the \
                        \cheap ones to reach."
                )
            ,
                ( "A teammate runs "
                    <> c "git maintenance start"
                    <> " once and later finds a setting in their "
                    <> c "~/.gitconfig"
                    <> " they did not write. What was it, and where else did the command write?"
                , p_ $ do
                    c "start"
                    " does what "
                    c "register"
                    " does — adds the repository to the global "
                    opt "maintenance.repo"
                    " list — and then installs a scheduler entry (systemd timers, cron or launchd, depending on the \
                    \platform) that runs "
                    c "git maintenance run --scheduled"
                    " hourly for every registered repository. "
                    c "git maintenance stop"
                    " removes the schedule; "
                    c "unregister"
                    " removes the repository from the list."
                )
            ,
                ( "Your dotfiles live in a bare repository used as "
                    <> c "git --git-dir=~/.dotfiles --work-tree=~"
                    <> ". You forget the options once and run "
                    <> c "git status"
                    <> " in "
                    <> c "~/src/project"
                    <> ". What happens, and why is that the safe failure?"
                , p_ $ do
                    "Without "
                    c "--git-dir"
                    ", git discovers repositories by walking up from the current directory, so you get "
                    c "~/src/project"
                    "'s status as usual. The bare repository is invisible unless named: it has no "
                    c ".git"
                    " directory for discovery to find. The dangerous mistake is the opposite one — naming "
                    c "--git-dir"
                    " without "
                    c "--work-tree"
                    ", which makes git treat the current directory as the top of the working tree."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d20diagram :: Diagram
d20diagram =
    ( diagram
        "A repository directory contains an object store, refs, reflogs and the index. The object \
        \store holds loose objects and packfiles; a packfile stores an object either whole or as a \
        \delta against another object. gc turns loose objects into packs, and deletes an unreachable \
        \object only after the grace period."
        body'
    )
        { dgCaption = do
            "The object store has two representations and one meaning: whether "
            b_ "an object"
            " is loose or in a pack, as a whole or as a delta, "
            c "cat-file"
            " returns the same bytes. What gc may delete depends only on reachability and age — the amber \
            \box is where unreachable objects wait out their two weeks."
        , dgRankdir = "TB"
        , dgRanksep = "0.4"
        }
  where
    body' =
        "  repo   [label=\"a repository (.git)\", fillcolor=\"#f4efe6\"];\n\
        \  store  [label=\"the object store\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  refs   [label=\"refs and packed-refs\"];\n\
        \  logs   [label=\"reflogs\"];\n\
        \  obj    [label=\"an object\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  loose  [label=\"a loose object file\"];\n\
        \  pack   [label=\"a packfile\"];\n\
        \  delta  [label=\"a delta\\nagainst another object\"];\n\
        \  cruft  [label=\"a cruft pack\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  repo  -> store [label=\"  contains\"];\n\
        \  repo  -> refs  [label=\"  contains\"];\n\
        \  repo  -> logs  [label=\"  contains\"];\n\
        \  store -> obj   [label=\"  holds\"];\n\
        \  obj   -> loose [label=\"  is stored as\"];\n\
        \  obj   -> pack  [label=\"  or is stored in\"];\n\
        \  pack  -> delta [label=\"  may encode it as\"];\n\
        \  refs  -> obj   [label=\"  keep reachable  \", style=dashed, constraint=false];\n\
        \  logs  -> obj   [label=\"  keep reachable  \", style=dashed, constraint=false];\n\
        \  cruft -> pack  [label=\"  is a kind of  \", constraint=false];\n\
        \  cruft -> obj   [label=\"  holds, for two weeks,\\n  an unreachable\", style=dashed];\n\
        \\n\
        \  { rank=same; cruft; pack; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "A directory you can read" $ do
        p_ [class_ "lede"] $ do
            "Everything from Day 1 onwards has been operations on a directory, and today you open it. "
            c ".git"
            " is a handful of small text files that say where you are, an object store that only grows, and a \
            \housekeeper — "
            c "git gc"
            " — whose rules decide when anything is ever thrown away. Knowing those rules is what makes the \
            \safety net of Day 11 something you can reason about instead of hope for."
        sh
            [ "$ ls .git"
            , "COMMIT_EDITMSG  config  description  HEAD  hooks  index  info  logs  objects  refs"
            ]
        defs
            [ (c "HEAD", "The symbolic ref naming your current branch (Day 3).")
            , (c "config", "This repository's config — the " <> c "--local" <> " layer of Day 12.")
            , (c "index", "The binary staging area of Day 2. Replaced on every " <> c "git add" <> ".")
            , (c "objects/", "The store: loose objects in two-hex-digit directories, packs in " <> c "objects/pack/" <> ", the commit-graph in " <> c "objects/info/" <> ".")
            , (c "refs/", "Branches, remote-tracking branches and tags, one file each — until they are packed.")
            , (c "packed-refs", "Many refs in one text file. Written by " <> c "git gc" <> " and " <> c "git pack-refs" <> ".")
            , (c "logs/", "The reflogs of Day 11, one file per ref.")
            , (c "hooks/", "Day 18. " <> c "info/exclude" <> " is Day 14's per-clone ignore file.")
            ]
        fig

    block "Loose, then packed" $ do
        p_ $ do
            "A new object is written as its own zlib-compressed file, "
            c "objects/ce/013625…"
            ". That is fast to write and wasteful to keep. "
            c "git gc"
            " — which many commands run for you as "
            c "gc --auto"
            " once more than "
            opt "gc.auto"
            " (6700) loose objects accumulate — gathers them into a "
            b_ "packfile"
            ". Here is a 20000-line file and five one-line edits to it:"
        sh
            [ "$ git count-objects -vH"
            , "count: 18"
            , "size: 312.00 KiB"
            , "in-pack: 0"
            , "packs: 0"
            , "$ git gc -q && git count-objects -vH"
            , "count: 0"
            , "in-pack: 18"
            , "packs: 1"
            , "size-pack: 45.66 KiB"
            , "$ ls .git/objects/pack"
            , "pack-a6902c03….idx  pack-a6902c03….pack  pack-a6902c03….rev"
            ]
        p_ $ do
            "Three hundred kilobytes became forty-five. Inside the pack, "
            c "git verify-pack -v"
            " shows each object's real size, packed size, and — for deltas — depth and base object:"
        sh
            [ "$ git verify-pack -v .git/objects/pack/*.idx | grep blob"
            , "1f528f6… blob   108919 43832 855"
            , "30c3889… blob   23 36 44778 1 1f528f6…"
            , "d327c9b… blob   33 45 44814 2 30c3889…"
            , "7599e0c… blob   33 45 44859 3 d327c9b…"
            , "c26350d… blob   23 36 44950 3 d327c9b…"
            , "897cb86… blob   23 36 45078 2 30c3889…"
            ]
        p_ $ do
            "Match those against "
            c "git log --raw"
            ": "
            c "1f528f6"
            " is the "
            b_ "newest"
            " version, stored whole. "
            c "7599e0c"
            ", the original file from the first commit, is a 33-byte delta three steps away, based on the \
            \second edit. Deltas point backwards from the present and are chosen for size, not history order."
        why $ p_ $ do
            "Recent versions are read far more often than old ones, so git keeps them whole and makes history \
            \pay the delta cost. And because delta bases are picked by similarity, not ancestry, a pack is free \
            \to delta a file against an unrelated one that happens to look alike. None of this leaks into the \
            \model: "
            c "git cat-file -p 7599e0c"
            " prints the full original file."
        gotcha $ p_ $ do
            "After the "
            c "gc"
            ", "
            c ".git/refs/heads/main"
            " no longer exists. The branch moved into "
            c ".git/packed-refs"
            " as a line of text. Anything that reads or writes ref files directly is now wrong; use "
            c "git rev-parse"
            " and "
            c "git update-ref"
            ". (And Git 3.0 plans to change the default ref storage to "
            c "reftable"
            ", where there are no ref files at all — see Day 21.)"

    block "What gc is allowed to delete" $ do
        p_ $ do
            "gc deletes an object only if it is "
            b_ "unreachable"
            " — no ref, no reflog entry, no index entry leads to it — "
            b_ "and"
            " older than "
            opt "gc.pruneExpire"
            ", which defaults to two weeks. Watch a dropped commit go through each stage:"
        sh
            [ "$ git commit -qm 'Oops' && S=$(git rev-parse HEAD:s.txt)"
            , "$ git reset -q --hard HEAD~1 && git gc -q && git cat-file -t $S"
            , "blob                      # still reachable from the reflog"
            , "$ git reflog expire --expire=now --all && git gc -q && git cat-file -t $S"
            , "blob                      # unreachable, but inside its two weeks"
            , "$ git gc -q --prune=now && git cat-file -t $S"
            , "fatal: git cat-file: could not get object info"
            ]
        p_ $ do
            "Between the second and third step the object was neither loose nor in the main pack. With "
            opt "gc.cruftPacks"
            " at its default of true, gc moves unreachable objects into a separate "
            b_ "cruft pack"
            ", with a "
            c ".mtimes"
            " file recording each object's age, so that the grace period survives repacking without \
            \scattering thousands of loose files."
        why $ p_ $ do
            "The grace period is not about your mistakes; it is about concurrency. Another git process might \
            \have just written an object it has not yet linked into a ref. Deleting young unreachable objects \
            \would corrupt that process's work, so gc only deletes objects old enough that nobody can still \
            \be in the middle of using them."
        p_ $ do
            c "git fsck"
            " is the inverse check: it verifies every object's hash and every link, and with "
            c "--unreachable"
            " lists what gc would consider garbage. It exits 0 on a healthy repository and says nothing."

    block "Maintenance, bare repositories, and pointing git elsewhere" $ do
        p_ $ do
            c "git maintenance"
            " is gc's scheduled successor. "
            c "git maintenance run --task=commit-graph"
            " writes "
            c "objects/info/commit-graph"
            ", a cache that makes "
            c "log --graph"
            " and reachability queries fast on big histories. "
            c "git maintenance start"
            " registers the repository in your global config ("
            opt "maintenance.repo"
            ") and installs an hourly scheduler entry; it touches your user's systemd or cron, so run it \
            \knowing that, and undo it with "
            c "git maintenance stop"
            "."
        p_ $ do
            "A "
            b_ "bare"
            " repository is the contents of "
            c ".git"
            " with no working tree — "
            c "core.bare = true"
            ", and "
            c "git status"
            " says “this operation must be run in a work tree”. Every repository you push to is one. The \
            \global options "
            c "--git-dir"
            " and "
            c "--work-tree"
            " (or "
            c "GIT_DIR"
            " and "
            c "GIT_WORK_TREE"
            ") pair any repository with any directory, which is the whole trick behind keeping dotfiles in \
            \git:"
        sh
            [ "$ git init --bare -b main ~/.dotfiles"
            , "$ alias dot='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'"
            , "$ dot config status.showUntrackedFiles no"
            , "$ dot add ~/.bashrc && dot commit -qm 'Track bashrc'"
            , "$ dot status"
            , "On branch main"
            , "nothing to commit (use -u to show untracked files)"
            ]
        gotcha $ p_ $ do
            "git(1): setting "
            c "--git-dir"
            " “turns off the repository discovery” and “tells Git that you are at the top level of the \
            \working tree”. Run "
            c "git --git-dir=../.git status"
            " from a subdirectory and every file outside it shows as deleted — "
            c " D big.txt"
            ". Always pair "
            c "--git-dir"
            " with "
            c "--work-tree"
            ", or use "
            c "-C"
            " instead."

    block "Today's habit" $ do
        p_ $ do
            "Leave "
            c "git gc"
            " to git; it runs when it needs to. What changes is how you think about “deleted”: an object is \
            \gone only when nothing reaches it and two weeks have passed. Until then, Day 11's reflog and "
            c "fsck --unreachable"
            " can find it."
        p_ "Tomorrow: the sharp edges — tracing, untrusted repositories, and where to read after this course."

cheat :: Html ()
cheat =
    cfg
        [ "# .git: HEAD config index objects/ refs/ packed-refs logs/ hooks/ info/"
        , "git count-objects -vH                 # loose vs packed, sizes"
        , "git gc                                # pack, pack refs, expire, prune >2 weeks"
        , "git gc --prune=now                    # and prune unreachable now"
        , "git verify-pack -v PACK.idx           # size, packed, depth, base"
        , "git fsck [--unreachable]              # integrity; what gc would drop"
        , "git maintenance run --task=commit-graph"
        , "# deleted = unreachable AND older than gc.pruneExpire (2.weeks.ago)"
        , "git --git-dir=X --work-tree=Y ...     # always both, or use -C"
        ]
