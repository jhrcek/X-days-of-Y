module Course.Day.D01 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 1
        , dayTitle = "Snapshots, not diffs"
        , daySubtitle = "The object store under every git command: blobs, trees, commits, and names that are hashes."
        , dayMinutes = 30
        , dayLevel = "essential"
        , dayManRef = "DISCUSSION, IDENTIFIER TERMINOLOGY; git-cat-file(1), git-hash-object(1)"
        , dayTags = ["object model", "content addressing", "cat-file"]
        , dayGoals =
            [ "explain what a commit actually contains, and why git stores snapshots rather than changes"
            , "take a commit apart by hand with " <> c "git cat-file -p" <> ", down to the bytes of one file"
            , "predict when git will store a new object and when it will reuse one it already has"
            ]
        , dayDiagram = Just d1diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("git init -b main", "Create an empty repository whose first branch is " <> c "main" <> ".")
            , ("git hash-object <file>", "Print the object name the file's contents would get. Writes nothing without " <> c "-w" <> ".")
            , ("git cat-file -t <object>", "Print an object's type: " <> c "blob" <> ", " <> c "tree" <> ", " <> c "commit" <> " or " <> c "tag" <> ".")
            , ("git cat-file -p <object>", "Pretty-print an object's contents. The one command that shows what git really stores.")
            , ("git cat-file -s <object>", "Print an object's size in bytes.")
            , ("git ls-tree -r <tree-ish>", "List every blob in a tree, recursively, with mode and hash.")
            , ("git rev-parse HEAD", "Turn a name into the full hash it currently means.")
            , ("git count-objects -v", "Count loose and packed objects and the disk they use.")
            ]
        , dayOpts = []
        , dayConfig = []
        , dayDrills =
            [ "In a scratch directory, run "
                <> c "echo hello | git hash-object --stdin"
                <> ". Check that you get "
                <> c "ce01362…"
                <> " — the same name everyone on earth gets for those six bytes."
            , "In a repository you work in, run "
                <> c "git cat-file -p HEAD"
                <> ". Read the four kinds of line: tree, parent, author, committer."
            , "Follow the chain by hand: "
                <> c "cat-file -p"
                <> " the tree hash from the previous drill, then one subtree, then one blob. You have now \
                   \read a file out of history with no porcelain at all."
            , "Break it on purpose: "
                <> c "git cat-file -p deadbeef"
                <> ". Read the error, then try the first seven characters of a real hash from "
                <> c "git log --oneline"
                <> "."
            , "Create a new repository, commit one file, then commit a copy of it under another name. \
              \Count the objects with "
                <> c "find .git/objects -type f | wc -l"
                <> " and account for every one of them."
            , "Run "
                <> c "git ls-tree -r HEAD | sort -k3 | uniq -D -f2 -w41"
                <> " in a real project to find files with identical contents. git stores each of them once."
            , "Look in "
                <> c ".git/refs/heads/"
                <> " of your scratch repository and "
                <> c "cat"
                <> " the file named after your branch. It is one hash. Hold on to that for Day 3."
            , "From today, when a git command surprises you, ask which objects it created or which name \
              \it moved — not which files it changed."
            ]
        , dayQuiz =
            [
                ( "You rename a 200 MB video in your repository and commit. How much does the repository grow, \
                  \and why?"
                , do
                    p_ $ do
                        "By a few hundred bytes. The blob is named by its contents, and the contents did not \
                        \change, so git already has that object. The commit writes a new tree (the directory \
                        \listing now has a different name in it), new trees for any parent directories, and a \
                        \new commit. None of those contains the video."
                    p_ $ do
                        "This is also why git has no rename operation in its data model. "
                        c "git mv"
                        " is a convenience; renames are inferred afterwards by comparing trees, which is why \
                        \Day 6 needs "
                        c "--follow"
                        "."
                )
            ,
                ( "A colleague says “git stores diffs, so checking out a commit from three years ago must \
                  \replay three years of changes”. What is wrong with the argument?"
                , do
                    p_ $ do
                        "The premise. Every commit points at a complete tree, so checking out an old commit \
                        \means reading one tree and the blobs it names — the same work as checking out "
                        c "HEAD"
                        ". The diffs you see in "
                        c "git log -p"
                        " are computed on the fly by comparing two trees."
                    p_ $ do
                        "Packfiles (Day 20) do store objects as deltas against each other, to save disk. \
                        \That is a compression layer underneath the model, not the model itself, and the deltas \
                        \are chosen for size, not along history."
                )
            ,
                ( "You change one character in the commit message of an old commit. Why does every commit \
                  \after it get a new hash too?"
                , p_ $ do
                    "Because a commit's hash covers its whole text, and that text includes the "
                    c "parent"
                    " line — the hash of the commit before it. Change one commit and its hash changes; its \
                    \child now names a different parent, so its text and hash change; and so on to the tip. \
                    \This is what “rewriting history” means mechanically, and it is why Day 9 has to talk \
                    \about force-pushing."
                )
            ,
                ( "In a brand-new repository, "
                    <> c "git log"
                    <> " says your branch “does not have any commits yet”, and "
                    <> c ".git/refs/heads/"
                    <> " is empty. Where is the branch?"
                , p_ $ do
                    "Nowhere yet. "
                    c ".git/HEAD"
                    " already says "
                    c "ref: refs/heads/main"
                    ", but a branch is a file holding a commit hash, and there is no commit to hold. The \
                    \first "
                    c "git commit"
                    " creates the commit and the branch file in one step. The glossary calls this state an \
                    \“unborn” branch, and it is why some commands behave oddly before the first commit."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d1diagram :: Diagram
d1diagram =
    ( diagram
        "The git object model: a branch names a commit; a commit has a tree as its snapshot and \
        \zero or more commits as parents; a tree lists blobs and further trees; a blob holds the \
        \bytes of a file; every object is named by the hash of its contents."
        body'
    )
        { dgCaption = do
            "Everything git stores is one of these four types, and every arrow between them is a hash \
            \written inside the object. That is why history cannot be edited in place: changing any box \
            \changes its name, and so changes every box that points at it. "
            b_ "a branch"
            " sits outside the store — it is the only thing here that is mutable, which is where Day 3 \
            \picks up."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  br     [label=\"a branch\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  commit [label=\"a commit\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  tree   [label=\"a tree\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  blob   [label=\"a blob\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  tag    [label=\"an annotated tag\"];\n\
        \  person [label=\"a person\\n(name, email, time)\", fillcolor=\"#f4efe6\"];\n\
        \  bytes  [label=\"the bytes of a file\", fillcolor=\"#f4efe6\"];\n\
        \  hash   [label=\"a SHA-1 hash\\nof the object's contents\"];\n\
        \\n\
        \  br     -> commit [label=\"  names\"];\n\
        \  tag    -> commit [label=\"  points at\"];\n\
        \  commit -> tree   [label=\"  has as snapshot\"];\n\
        \  commit -> commit [label=\"  has as parent\", style=dashed];\n\
        \  commit -> person [label=\"  has as author\"];\n\
        \  tree   -> blob   [label=\"  lists\"];\n\
        \  tree   -> tree   [label=\"  lists\"];\n\
        \  blob   -> bytes  [label=\"  holds\"];\n\
        \  blob   -> hash   [label=\"  is named by\"];\n\
        \\n\
        \  { rank=same; br; tag; }\n\
        \  { rank=same; person; tree; }\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "git is a key–value store with a VCS on top" $ do
        p_ [class_ "lede"] $ do
            "Underneath the two hundred commands, git is a small database. You hand it some bytes, it \
            \hashes them, and it files them under the hash. Every commit, every directory listing, every \
            \version of every file is an entry in that store. Learn the four kinds of entry today and \
            \every later command becomes a question of which entries it creates and which names it moves."
        p_ $ do
            "The manual page says it in one paragraph, under DISCUSSION: the object database holds "
            b_ "blobs"
            ", which hold file data; "
            b_ "trees"
            ", which point to blobs and other trees to build up directories; and "
            b_ "commits"
            ", which each reference a single tree and some number of parent commits. A fourth type, the "
            b_ "tag"
            ", exists so that a point in history can be signed. That is the entire data model."
        p_ $ do
            "The word that matters is "
            em_ "single tree"
            ". A commit does not record what changed. It records what the whole project looked like — a \
            \complete snapshot — plus a pointer to the previous snapshot. When "
            c "git log -p"
            " shows you a diff, it is comparing two trees on the spot."
        why $ p_ $ do
            "Snapshots make the common operations cheap and the model simple. Checking out any commit is \
            \reading one tree, whatever its age. Comparing any two commits is comparing two trees, whether \
            \or not they are related. Branching costs nothing, because a branch is not a copy of anything. \
            \The cost you would expect — storing the whole project every time — is paid only for content \
            \that actually changed, as the next section shows."
        fig

    block "Names are hashes of contents" $ do
        p_ $ do
            "Every object's name is the SHA-1 of its contents (with a short header: its type and length). \
            \Nothing else goes into the name — not the file name, not the time, not the repository. So the \
            \same bytes get the same name everywhere:"
        sh
            [ "$ echo hello | git hash-object --stdin"
            , "ce013625030ba8dba906f756967f9e9ca394464a"
            , "$ printf 'blob 6\\0hello\\n' | sha1sum"
            , "ce013625030ba8dba906f756967f9e9ca394464a  -"
            ]
        p_ $ do
            "That second line is the whole trick, reproduced with coreutils: the word "
            c "blob"
            ", the length, a NUL byte, and the content. Run it on your machine and you get the same forty \
            \characters, because nothing about your machine went in."
        p_ "Three consequences follow, and you will lean on all three:"
        defs
            [
                ( "deduplication"
                , "Two files with identical contents — in the same commit, or ten years apart — are one \
                  \blob. A commit that changes one file out of ten thousand writes one new blob, a handful \
                  \of trees, and a commit."
                )
            ,
                ( "integrity"
                , "An object that does not hash to its own name is corrupt, and git can tell. Because a \
                  \commit names its tree and its parents by hash, one commit hash vouches for the entire \
                  \history behind it."
                )
            ,
                ( "immutability"
                , "You cannot edit an object; an edited object is a different object with a different name. \
                  \Every “rewrite” command you will meet makes new objects and moves a name to point at \
                  \them."
                )
            ]
        note $ p_ $ do
            "SHA-1 is the default for new repositories in 2.52 ("
            c "GIT_DEFAULT_HASH"
            " defaults to "
            c "sha1"
            "); SHA-256 repositories exist via "
            c "git init --object-format=sha256"
            ". Nothing in this course depends on which one you have."

    block "Taking a commit apart" $ do
        p_ $ do
            "One plumbing command is worth learning on the first day because it shows you the store \
            \directly: "
            c "git cat-file"
            ". "
            c "-t"
            " gives the type of an object, "
            c "-p"
            " prints it. Build a tiny repository and walk down from the commit to the bytes:"
        sh
            [ "$ git init -b main demo && cd demo"
            , "$ echo hello > greeting.txt"
            , "$ mkdir src && echo 'main = pure ()' > src/Main.hs"
            , "$ git add . && git commit -m 'First snapshot'"
            , "$ git cat-file -p HEAD"
            , "tree 8266f8d901ef8cd6b3e4b968709075333560d729"
            , "author Ada Example <ada@example.com> 1790319600 +0200"
            , "committer Ada Example <ada@example.com> 1790319600 +0200"
            , ""
            , "First snapshot"
            , "$ git cat-file -p 8266f8d"
            , "100644 blob ce013625030ba8dba906f756967f9e9ca394464a\tgreeting.txt"
            , "040000 tree 01942f8e7f0cb99a802716705f6b828f635567e0\tsrc"
            , "$ git cat-file -p ce01362"
            , "hello"
            ]
        p_ $ do
            "Read the commit: a "
            c "tree"
            " line, an "
            c "author"
            " and a "
            c "committer"
            " (who wrote the change, and who recorded it — they differ after a rebase or a cherry-pick), a \
            \blank line, the message. The first commit has no "
            c "parent"
            " line; every later one has one, and a merge has two. Your tree and commit hashes will differ \
            \from these, because your name and clock went into them. The blob hash will not."
        p_ $ do
            "Read the tree: one line per entry, with a mode ("
            c "100644"
            " a file, "
            c "100755"
            " an executable, "
            c "040000"
            " a directory, "
            c "120000"
            " a symlink), a type, a hash and a name. The "
            b_ "name lives in the tree"
            ", not in the blob — which is why the blob can be shared between two paths."
        tip $ p_ $ do
            "You rarely need to type full hashes. Any unique prefix works, and git's default abbreviation \
            \is seven characters, growing as the repository gets bigger. "
            c "git rev-parse HEAD"
            " turns a name back into the full hash."

    block "Watching deduplication happen" $ do
        p_ "Now commit a copy of the file under a new name, and count what got stored:"
        sh
            [ "$ cp greeting.txt copy.txt && git add copy.txt"
            , "$ git commit -m 'Copy the greeting'"
            , "$ git cat-file -p HEAD^{tree}"
            , "100644 blob ce013625030ba8dba906f756967f9e9ca394464a\tcopy.txt"
            , "100644 blob ce013625030ba8dba906f756967f9e9ca394464a\tgreeting.txt"
            , "040000 tree 01942f8e7f0cb99a802716705f6b828f635567e0\tsrc"
            , "$ git count-objects -v | head -1"
            , "count: 7"
            ]
        p_ $ do
            "Seven, not eight. Two blobs (the greeting and "
            c "Main.hs"
            "), three trees (the first root, "
            c "src"
            ", the second root), two commits. The copy is the same blob, listed twice. The "
            c "src"
            " tree is the same tree in both commits, because nothing inside it changed — the second \
            \snapshot reuses the whole subdirectory by hash."
        gotcha $ p_ $ do
            "Because a snapshot shares everything unchanged, deleting a large file in a new commit does "
            b_ "not"
            " shrink the repository. The old commit still names the old tree, which still names the blob. \
            \Getting a file out of history means rewriting every commit that contains it, and every clone \
            \that has it. Keep secrets and build artefacts out of the first commit, not the fifth."

    block "Where the store lives" $ do
        p_ $ do
            "All of this is in "
            c ".git/objects/"
            ", one file per object at first ("
            c ".git/objects/ce/013625…"
            ", zlib-compressed), later bundled into packfiles — Day 20 opens them up. Next to it are the "
            b_ "names"
            ": "
            c ".git/refs/heads/main"
            " is a file containing one commit hash, and "
            c ".git/HEAD"
            " is a file saying which branch you are on:"
        sh
            [ "$ cat .git/HEAD"
            , "ref: refs/heads/main"
            , "$ cat .git/refs/heads/main"
            , "b06f7f715b11ad4c834172526a44f2132f9760a4"
            ]
        p_ $ do
            "That split — an append-only store of immutable objects, and a handful of small mutable files \
            \that point into it — is the design. Committing adds objects and moves "
            c "main"
            ". Resetting moves "
            c "main"
            ". Fetching adds objects and moves "
            c "origin/main"
            ". Almost nothing git does ever deletes an object; tomorrow's lesson adds the one piece still \
            \missing, the index, which is where the next commit is assembled."
        note $ p_ $ do
            "Refs may also live packed together in "
            c ".git/packed-refs"
            ", so do not script against the files directly. Use "
            c "git rev-parse"
            " and friends (Day 19). Reading them by hand today is for understanding only."

    block "Today's habit" $ do
        p_ $ do
            "The next time a git command surprises you, run "
            c "git cat-file -p HEAD"
            " before and after it. Ask which objects appeared and which names moved. It is a slower \
            \question than “what happened to my files”, and it is the one that always has an answer."
        p_ $ do
            "Tomorrow: the working tree, the index, and "
            c "HEAD"
            " — the three places a file can be, and the commands that move it between them."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "The whole data model in nine lines."
        " Every later day is operations on this."
    cfg
        [ "# blob    the bytes of one file; no name, no mode"
        , "# tree    a directory listing: mode, type, hash, name"
        , "# commit  one tree + parents + author/committer + message"
        , "# tag     an annotated, signable pointer to an object"
        , "git hash-object FILE      # the name those bytes would get"
        , "git cat-file -t OBJ       # its type"
        , "git cat-file -p OBJ       # its contents"
        , "git ls-tree -r HEAD       # every blob in the current snapshot"
        , "cat .git/HEAD             # which branch you are on (read-only habit)"
        ]
