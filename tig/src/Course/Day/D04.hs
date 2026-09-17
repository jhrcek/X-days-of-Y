module Course.Day.D04 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 4
        , dayTitle = "Reading diffs"
        , daySubtitle = "Context, chunks, and the filter you did not know was on."
        , dayMinutes = 32
        , dayLevel = "essential"
        , dayManRef = "tigmanual(7) Views, Misc; tigrc(5) SET COMMAND"
        , dayTags = ["diff view", "chunks", "filters"]
        , dayGoals =
            [ "read the diff view's header and know which part came from git show and which from tig"
            , "widen and narrow the context, and jump chunk to chunk, without scrolling"
            , "recognise when the diff you are looking at has been silently filtered, and turn the filter off"
            ]
        , dayDiagram = Just d4diagram
        , dayBody = body
        , dayKeys =
            [ ("]", "Increase the diff context by one line.")
            , ("[", "Decrease the diff context by one line.")
            , ("@", "Jump to the next chunk header. Implemented as a search — see today's gotcha.")
            , ("%", "Toggle the file filter: show the whole commit, not just the file you came from.")
            , ("W", "Toggle whitespace-insensitive diffing.")
            , ("$", "Highlight commit-title text past the conventional width.")
            ]
        , dayCmds =
            [ ("tig show <rev>", "Open a commit directly in the diff view.")
            , ("tig --word-diff=plain", "Word-level rather than line-level diffing.")
            ]
        , dayOpts =
            [ ("diff-context", "Context lines around each change. Default " <> c "3" <> ".")
            , ("diff-options", "Extra options for the diff view's " <> c "git show" <> ".")
            , ("ignore-space", "Whitespace handling: " <> c "no" <> " (default), " <> c "all" <> ", " <> c "some" <> ", " <> c "at-eol" <> ".")
            , ("diff-highlight", "Run git's " <> c "diff-highlight" <> " to mark intra-line changes. Off by default.")
            , ("diff-indicator", "Show the leading " <> c "+" <> "/" <> c "-" <> " signs. Default " <> c "yes" <> ".")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Open any commit's diff and press "
                <> k "]"
                <> " five times, then "
                <> k "["
                <> " five times. Watch the context grow and shrink a line at a time around every \
                   \chunk at once."
            , "Find a commit that touches four or five files. Press "
                <> k "@"
                <> " repeatedly to walk the chunk headers instead of scrolling."
            , "Immediately after that, press "
                <> k "n"
                <> ". It jumps to the next chunk too — because "
                <> k "@"
                <> " was a search all along. Now press "
                <> k "/"
                <> " and search for something else, then press "
                <> k "@"
                <> " again and watch your search get overwritten."
            , "Run "
                <> c "tig -- path/to/one/file"
                <> ", open a commit that touched several files, and count the files in the diff. \
                   \Press "
                <> k "%"
                <> " and count again."
            , "Find a commit where somebody reindented a block. Press "
                <> k "W"
                <> " and watch most of it disappear."
            , "Break it on purpose: press "
                <> k "["
                <> " about ten times in a row, past zero. Read what the status window says rather \
                   \than assuming it worked."
            , "Today's habit: when a diff is hard to follow because the change is a rename or a \
              \small edit inside a long line, reach for "
                <> k "W"
                <> " and "
                <> c "--word-diff=plain"
                <> " before you reach for a browser."
            ]
        , dayQuiz =
            [
                ( "You are reviewing a commit that changed six files, but the diff view shows only \
                  \one of them. Nothing is obviously wrong. What happened?"
                , do
                    p_ $ do
                        "You arrived with a path filter in force. If tig was started as "
                        c "tig -- src/parser.c"
                        ", or you descended from the tree view into a single file, the diff view \
                        \inherits that limit and shows the part of the commit that touches it."
                    p_ $ do
                        k "%"
                        " toggles "
                        opt "file-filter"
                        " and gives you the whole commit back. This is the most common “tig is \
                        \lying to me” moment, and it is the one filter that leaves no visible mark \
                        \on the screen."
                )
            ,
                ( "You press "
                    <> k "@"
                    <> " to step through chunks, then later press "
                    <> k "n"
                    <> " expecting to continue an earlier search, and land on a chunk header \
                       \instead. Why?"
                , do
                    p_ $ do
                        "Because "
                        k "@"
                        " is not a dedicated action. It is bound to "
                        c ":/^@@"
                        " — an ordinary forward search for the regexp "
                        c "^@@"
                        ". Running it replaces whatever search pattern you had, so "
                        k "n"
                        " afterwards repeats the chunk search."
                    p_ $ do
                        "This is a fair trade for the reader: it means chunk-hopping needs no \
                        \special machinery, and you could have written the binding yourself. It \
                        \also means that on Day 12 you can bind "
                        c ":/^diff --(git|cc)"
                        " to step file by file instead."
                )
            ,
                ( "Two people look at the same commit. One sees a three-line-context diff, the \
                  \other sees twenty lines of context, and neither has a "
                    <> c "~/.tigrc"
                    <> ". How?"
                , do
                    p_ $ do
                        "One of them pressed "
                        k "]"
                        " seventeen times. "
                        opt "diff-context"
                        " defaults to "
                        c "3"
                        " and "
                        k "]"
                        " / "
                        k "["
                        " adjust it by one, live, for the session."
                    p_ $ do
                        "There is a second possibility worth knowing: "
                        c "TIG_DIFF_OPTS"
                        " in the environment. The precedence runs command line, then "
                        opt "diff-options"
                        " in the config, then "
                        c "TIG_DIFF_OPTS"
                        " — so an export in somebody's shell profile quietly wins over nothing at \
                        \all and loses to everything else."
                )
            ,
                ( "Why does the diff view show "
                    <> c "Author"
                    <> " and "
                    <> c "AuthorDate"
                    <> " and "
                    <> c "Commit"
                    <> " and "
                    <> c "CommitDate"
                    <> " when "
                    <> c "git show"
                    <> " normally shows only one author line?"
                , do
                    p_ $ do
                        "Because tig asks for them. The diff view runs "
                        c "git show"
                        " with "
                        c "--patch-with-stat"
                        " always, and a pretty format that separates the author from the committer."
                    p_ $ do
                        "The two differ whenever a commit has been rebased, cherry-picked or \
                        \applied from a patch — the author is who wrote it, the committer is who \
                        \put it here and when. Seeing both by default is one of the quiet reasons \
                        \tig is better than "
                        c "git show"
                        " for archaeology."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d4diagram :: Diagram
d4diagram =
    ( diagram
        "The diff view: git show produces a commit header, a diffstat and a patch made of chunks; \
        \the context setting controls how many unchanged lines surround each chunk, and the file \
        \filter and whitespace settings decide how much of the commit is shown at all."
        body'
    )
        { dgCaption = do
            "A patch is a list of "
            b_ "chunks"
            ", and everything on this day is one of two questions about them: how much unchanged \
            \code surrounds a chunk ("
            k "]"
            " and "
            k "["
            "), and which chunks you are allowed to see at all. The file filter is the dangerous \
            \one, because it narrows the view and says nothing."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  show [label=\"git show\\n--patch-with-stat\", fillcolor=\"#f4efe6\"];"
            , "  dv   [label=\"the diff view\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  hdr  [label=\"a commit header\\n(author, committer,\\nmessage)\"];"
            , "  stat [label=\"a diffstat\"];"
            , "  patch [label=\"a patch\"];"
            , "  chunk [label=\"a chunk\\n@@ -1,8 +1,8 @@\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  ctx  [label=\"context lines\\n(diff-context, default 3)\"];"
            , "  filt [label=\"the file filter\\n(%)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  show  -> dv    [label=\"  fills\"];"
            , "  dv    -> hdr   [label=\"  begins with\"];"
            , "  dv    -> stat  [label=\"  then shows\"];"
            , "  dv    -> patch [label=\"  then shows\"];"
            , "  patch -> chunk [label=\"  is a list of\"];"
            , "  chunk -> ctx   [label=\"  is surrounded by\"];"
            , "  filt  -> patch [label=\"  silently narrows\", style=dashed];"
            , ""
            , "  { rank=same; hdr; stat; }"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "The diff view is git show, dressed" $ do
        p_ [class_ "lede"] $ do
            "Everything in the diff view came out of "
            c "git show"
            ", which tig always runs with "
            c "--patch-with-stat"
            ". What tig adds is colour, navigation and three controls — context, chunk-hopping and \
            \a file filter — that turn reading a patch from scrolling into aiming."
        p_ "A commit in the diff view, top to bottom:"
        termWin
            "tig — diff view"
            [ "commit 0b12e18ae519b2391fb2d91b008b7c30d1954fe6"
            , "Refs: <v1.0>"
            , "Author:     Ada Lovelace <dev@example.com>"
            , "AuthorDate: Sun Mar 1 10:00:00 2026 +0100"
            , "Commit:     Ada Lovelace <dev@example.com>"
            , "CommitDate: Sun Mar 1 10:00:00 2026 +0100"
            , ""
            , "    Initial import"
            , "---"
            , " README     | 1 +"
            , " src/main.c | 1 +"
            , " 2 files changed, 2 insertions(+)"
            , ""
            , "diff --git a/README b/README"
            , "new file mode 100644"
            , "index 0000000..1d51d01"
            , "--- /dev/null"
            , "+++ b/README"
            , "@@ -0,0 +1 @@"
            , "+Demo project"
            ]
        p_ $ do
            "Note "
            c "Author"
            " and "
            c "Commit"
            " as separate lines — tig asks for a format that distinguishes them, so a rebased or \
            \cherry-picked commit tells you both who wrote it and who moved it. The "
            c "Refs:"
            " line lists any branches or tags pointing here."
        fig

    block "Context is a dial, not a setting" $ do
        p_ $ do
            "A chunk shows three unchanged lines either side of the change. That is "
            opt "diff-context"
            ", it defaults to "
            c "3"
            ", and in the diff view it is live:"
        defs
            [ (k "]", "One more line of context, everywhere in the patch at once.")
            , (k "[", "One fewer.")
            ]
        p_ $ do
            "This matters more than it sounds. Three lines is rarely enough to tell whether an edit \
            \is inside the function you think it is inside. Pressing "
            k "]"
            " four or five times usually answers that without leaving the view, and it is much \
            \faster than opening the file."
        why $ p_ $ do
            "The bindings are "
            c ":toggle diff-context +1"
            " and "
            c "-1"
            " — internal commands, not special-purpose code. That is tig's recurring pattern: the \
            \built-in keys are made of the same parts you get on Day 12. Nothing in the default \
            \keymap is doing something you could not have written yourself, which is why reading \
            \the default bindings is the fastest way to learn the configuration language."

    block "Hopping chunks, and the search it quietly performs" $ do
        p_ $ do
            k "@"
            " jumps to the next chunk header. In a commit touching a dozen files it is the \
            \difference between reviewing and scrolling."
        gotcha $ p_ $ do
            k "@"
            " is not an action. Its binding is literally "
            c ":/^@@"
            " — a forward search for a line starting with "
            c "@@"
            ". So pressing it "
            b_ "overwrites your current search pattern"
            ", and afterwards "
            k "n"
            " and "
            k "N"
            " step through chunks rather than through whatever you were looking for. Useful once \
            \you know; baffling until you do."
        p_ $ do
            "The same trick generalises. tigrc(5) suggests "
            c "bind stage D :/^diff --(git|cc)"
            " to step file by file, and "
            c "bind stage 2 :?^@@"
            " to step backwards. You will write your own on Day 12."

    block "The filter that shows nothing of itself" $ do
        p_ $ do
            "This is the one that costs people an afternoon. If you started tig with a path — "
            c "tig -- src/parser.c"
            " — or descended into a single file through the tree view, then the diff view is "
            b_ "filtered to that file"
            ". A commit that changed six files shows you one."
        p_ $ do
            "Nothing on screen says so. The title window looks normal, the diffstat shows only the \
            \filtered file, and the patch looks complete because it is a complete patch for that \
            \file."
        defs
            [ (k "%", "Toggle " <> opt "file-filter" <> ": show the whole commit rather than the path you arrived by.")
            , (k "^", "Toggle " <> opt "rev-filter" <> ": the equivalent for revision limits in the main view.")
            ]
        tip $ p_ $ do
            "Make "
            k "%"
            " the first thing you press whenever a diff looks suspiciously small. It costs one \
            \keystroke and it is the difference between “this commit only touched the parser” and \
            \“I have been reading a third of this commit”."

    block "Whitespace, words, and intra-line changes" $ do
        p_ "Three more controls, each for a diff that is technically correct and humanly unreadable:"
        defs
            [
                ( k "W" <> " / " <> opt "ignore-space"
                , do
                    "Whitespace-insensitive diffing. The setting takes "
                    c "no"
                    " (default), "
                    c "all"
                    ", "
                    c "some"
                    " or "
                    c "at-eol"
                    ". Turns a reindentation commit back into the two lines that actually changed."
                )
            ,
                ( opt "word-diff"
                , do
                    "Word-level rather than line-level. Off by default; "
                    c "tig --word-diff=plain"
                    " for one session. Invaluable for prose and for long lines with one changed \
                    \token."
                )
            ,
                ( opt "diff-highlight"
                , do
                    "Runs git's "
                    c "diff-highlight"
                    " helper to mark what changed "
                    i_ "within"
                    " a modified line. Off by default; set to "
                    c "true"
                    " or to the path of the script."
                )
            ]
        gotcha $ p_ $ do
            "Turning "
            opt "ignore-space"
            " on has a consequence tigrc(5) warns about and people still hit: with it set to "
            c "all"
            ", "
            c "some"
            " or "
            c "at-eol"
            ", staging and reverting individual chunks "
            b_ "can fail"
            ", because the chunk tig offers git no longer matches the file. If tomorrow's staging \
            \refuses to apply, check "
            k "W"
            " first."

    block "Today's habit" $ do
        p_ $ do
            "Next time you review a change, resist scrolling. Use "
            k "@"
            " to move chunk to chunk, "
            k "]"
            " when you cannot tell where you are, and "
            k "%"
            " the moment a diff seems too short. Those three keys are most of code review."
        p_ "Tomorrow: finding a commit you cannot see, by search and by name."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "The diff view in nine lines."
        " The last two are the ones people lose time to."
    cfg
        [ "]  [    diff context, one line at a time (diff-context, default 3)"
        , "@       next chunk header — really a search for ^@@"
        , "n       ... so this now repeats the CHUNK search, not yours"
        , "%       file-filter: show the whole commit, not just the path you came by"
        , "^       rev-filter: the same, for revision limits"
        , "W       ignore-space — but see below"
        , "$       highlight over-long commit titles"
        , "e       open this file in $EDITOR at this line"
        , "# W on (all/some/at-eol) can make chunk staging FAIL tomorrow"
        ]
