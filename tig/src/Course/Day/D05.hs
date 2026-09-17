module Course.Day.D05 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 5
        , dayTitle = "Finding things"
        , daySubtitle = "Search and the prompt are two different ways to move."
        , dayMinutes = 30
        , dayLevel = "essential"
        , dayManRef = "tigmanual(7) Searching, Prompt"
        , dayTags = ["search", "prompt", "goto"]
        , dayGoals =
            [ "search a view forwards and backwards, and know which regexp dialect your build speaks"
            , "jump straight to a line number, a commit ID or a revision without searching at all"
            , "run a git command from inside tig and read its output in the pager view"
            ]
        , dayDiagram = Just d5diagram
        , dayBody = body
        , dayKeys =
            [ ("/", "Search forwards. Prompts for a regexp.")
            , ("?", "Search backwards.")
            , ("n", "Next match. " <> k "N" <> " for the previous one.")
            , (":", "Open the prompt.")
            , ("H", "Jump to the HEAD commit, in the main view.")
            ]
        , dayCmds =
            [ (":42", "Jump to line 42 of this view.")
            , (":2f12bcc", "Jump to that commit.")
            , (":goto <rev>", "Jump to a revision: a branch, a tag, " <> c "HEAD~3" <> ", " <> c "%(commit)^2" <> ".")
            , (":!git <cmd>", "Run a git command and show the output in the pager view.")
            , (":edit", "Run an action by name. Any action name works here.")
            , (":q", "Run the binding for a key. Same as pressing " <> k "q" <> ".")
            , (":echo <text>", "Print a line in the status window.")
            , (":save-display <file>", "Write the current screen to a file.")
            ]
        , dayOpts =
            [ ("ignore-case", "Search case handling: " <> c "no" <> " (default), " <> c "yes" <> ", " <> c "smart-case" <> ".")
            , ("wrap-search", "Wrap around the ends of the view. Default " <> c "yes" <> ".")
            , ("history-size", "Lines kept in " <> c "~/.tig_history" <> ". Default " <> c "500" <> ", " <> c "0" <> " disables.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "In the main view press "
                <> k "/"
                <> ", type part of a commit message you know is there, press Enter. Then press "
                <> k "n"
                <> " a few times to cycle through the matches."
            , "Press "
                <> k "/"
                <> " again and press "
                <> k "Up"
                <> " at the empty prompt. Your previous searches are there, and they survive \
                   \quitting tig — that is "
                <> c "~/.tig_history"
                <> "."
            , "Search for something in UPPERCASE that exists only in lowercase. No match. Now run "
                <> c "tig"
                <> " again after putting "
                <> c "set ignore-case = smart-case"
                <> " in a scratch file and starting with "
                <> c "TIGRC_USER=/tmp/try.tigrc tig"
                <> "."
            , "Type "
                <> c ":42"
                <> " and press Enter. Then type "
                <> c ":"
                <> " followed by the first seven characters of any commit ID from the view."
            , "Type "
                <> c ":goto HEAD~5"
                <> ", then "
                <> c ":goto master"
                <> ". Neither needs the commit to be visible on screen."
            , "Break it on purpose: type "
                <> c ":goto no-such-branch"
                <> " and read the status window. Then type "
                <> c ":nonsense"
                <> " and read that error too — they fail differently."
            , "Type "
                <> c ":!git shortlog -sn"
                <> " and read the result in the pager view, then "
                <> k "q"
                <> " back. Today's habit: stop leaving tig to run small git commands."
            ]
        , dayQuiz =
            [
                ( "Your search for "
                    <> c "\\d+"
                    <> " finds nothing, but "
                    <> c "[0-9]+"
                    <> " works. Is the regexp engine broken?"
                , do
                    p_ $ do
                        "No — it is POSIX. tig uses POSIX extended regular expressions unless it was \
                        \compiled with PCRE support, and "
                        c "\\d"
                        " is a Perl shorthand that POSIX ERE does not have. "
                        c "[0-9]"
                        " and "
                        c "[[:digit:]]"
                        " both work everywhere."
                    p_ $ do
                        k "v"
                        " tells you which build you have: if the version output lists PCRE or PCRE2 \
                        \alongside ncurses and readline, you get Perl syntax. The build this course \
                        \was checked against does "
                        b_ "not"
                        " list it, so its searches are POSIX."
                )
            ,
                ( "What is the difference between "
                    <> c ":2f12bcc"
                    <> " and "
                    <> c ":goto 2f12bcc"
                    <> "?"
                , do
                    p_ $ do
                        "For a plain commit ID, very little — both move the cursor to that commit. \
                        \The difference is what else they accept. The bare form is pattern-matched \
                        \by the prompt: a number means a line, something that looks like a commit ID \
                        \means that commit, a single character means “run that key's binding”."
                    p_ $ do
                        c ":goto"
                        " takes a full revision expression, so "
                        c ":goto HEAD~3"
                        ", "
                        c ":goto origin/master"
                        " and "
                        c ":goto %(commit)^2"
                        " all work, and the last of those — the current commit's second parent — is \
                        \how you navigate a merge without leaving the view."
                )
            ,
                ( "You press "
                    <> k "n"
                    <> " repeatedly and the cursor eventually arrives back where it started, having \
                       \passed the end of the view. Bug?"
                , do
                    p_ $ do
                        "That is "
                        opt "wrap-search"
                        ", on by default. Searching past the last match continues from the top."
                    p_ $ do
                        "It is the right default for a commit list, where you usually want “find \
                        \this anywhere”. It is the wrong one when you are walking matches to count \
                        \them, because you will loop forever without noticing. "
                        c "set wrap-search = no"
                        " makes tig stop at the end and say so."
                )
            ,
                ( "You type "
                    <> c ":!git rebase -i HEAD~3"
                    <> " and get something unusable. Why, and what runs interactive commands \
                       \properly?"
                , do
                    p_ $ do
                        c ":!"
                        " runs a command and captures its output into the pager view. That is right \
                        \for "
                        c "git shortlog"
                        " or "
                        c "git reflog"
                        ", and wrong for anything that wants a terminal of its own — an interactive \
                        \rebase, an editor, a pager, anything that prompts."
                    p_ $ do
                        "Day 13's external commands are the answer: a binding whose action starts \
                        \with "
                        c "!"
                        " runs in the foreground with the terminal handed over properly. The "
                        c ":!"
                        " prompt form is the capture-the-output cousin, not the run-it-properly one."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d5diagram :: Diagram
d5diagram =
    ( diagram
        "Two ways to move within a view: a search takes a regexp and produces matches that next \
        \and previous step through, while the prompt takes a line number, a commit ID, a revision \
        \expression, an action name or a system command and moves or acts directly."
        body'
    )
        { dgCaption = do
            "Search scans what is already in the view; the prompt addresses things by name whether \
            \they are on screen or not. Reach for "
            k "/"
            " when you know what the line "
            i_ "says"
            ", and for "
            k ":"
            " when you know what it "
            i_ "is"
            ". The prompt is also the doorway to every action tig has, which is why Day 12 starts \
            \here."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  view [label=\"a view\", fillcolor=\"#f4efe6\"];"
            , "  srch [label=\"a search\\n(/ and ?)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  re   [label=\"a POSIX regexp\\n(PCRE only if\\ncompiled in)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  mat  [label=\"a match\"];"
            , "  pr   [label=\"the prompt\\n(:)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  ln   [label=\"a line number\\n:42\"];"
            , "  rev  [label=\"a revision\\n:goto HEAD~3\"];"
            , "  act  [label=\"an action name\\n:edit\"];"
            , "  cmd  [label=\"a system command\\n:!git shortlog\"];"
            , "  cur  [label=\"the cursor\"];"
            , ""
            , "  srch -> re   [label=\"  takes\"];"
            , "  srch -> mat  [label=\"  finds\"];"
            , "  view -> mat  [label=\"  contains\"];"
            , "  mat  -> cur  [label=\"  moves\"];"
            , "  pr   -> ln   [label=\"  accepts\"];"
            , "  pr   -> rev  [label=\"  accepts\"];"
            , "  pr   -> act  [label=\"  accepts\"];"
            , "  pr   -> cmd  [label=\"  accepts\"];"
            , "  ln   -> cur  [label=\"  moves\", style=dashed];"
            , "  rev  -> cur  [label=\"  moves\", style=dashed];"
            , ""
            , "  { rank=same; ln; rev; act; cmd; }"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Two different questions" $ do
        p_ [class_ "lede"] $ do
            "There are two ways to get somewhere in tig, and they answer different questions. "
            k "/"
            " searches the text that is already loaded in this view. "
            k ":"
            " addresses something by name — a line, a commit, a revision — whether it is on screen \
            \or not. Confusing them is why people scroll."
        fig

    block "Search: it is the view's text, not the repository" $ do
        p_ $ do
            k "/"
            " prompts for a regexp and moves to the first line that matches; "
            k "?"
            " does the same backwards; "
            k "n"
            " and "
            k "N"
            " step through the matches."
        p_ $ do
            "The important limitation is in the first sentence: search looks at "
            b_ "the lines this view has loaded"
            ". In the main view that is commit subjects, authors and dates — not commit messages in \
            \full, and certainly not file contents. Searching for a word that appears only in the \
            \body of a commit message will find nothing, and that is not a bug."
        p_ $ do
            "For the things search cannot reach, git already has answers and tig passes them \
            \through: "
            c "tig --grep=pattern"
            " limits the main view to commits whose message matches, and "
            c "tig -Spattern"
            " limits it to commits that changed the number of occurrences of a string. Day 10 goes \
            \through these properly; the grep view on Day 9 searches file contents."
        gotcha $ p_ $ do
            "The regexp dialect depends on how your tig was built. Without PCRE compiled in — and \
            \the 2.6.1 build this course was checked against does not have it — you get "
            b_ "POSIX extended"
            " regexps. Alternation "
            c "(a|b)"
            ", classes "
            c "[0-9]"
            " and anchors work; Perl shorthands like "
            c "\\d"
            ", "
            c "\\w"
            " and "
            c "\\s"
            " do not. Press "
            k "v"
            " and look for a PCRE line before assuming otherwise."
        p_ $ do
            "Case is controlled by "
            opt "ignore-case"
            ", which is "
            c "no"
            " by default. The value worth setting is "
            c "smart-case"
            ": case-insensitive unless your pattern contains an uppercase letter, which is what \
            \most people mean most of the time. It goes in the file on Day 7."
        note $ p_ $ do
            "At the search prompt, "
            k "Up"
            " and "
            k "Down"
            " walk your history, which persists in "
            c "~/.tig_history"
            " between runs when tig is built with readline ("
            opt "history-size"
            ", default "
            c "500"
            "). The prompt itself is readline, so your "
            c "~/.inputrc"
            " bindings apply — tig respects an "
            c "$if tig"
            " section there but does not require one."

    block "The prompt: addressing things by name" $ do
        p_ $ do
            k ":"
            " opens the prompt at the bottom of the screen. What you type is pattern-matched into \
            \one of several kinds of thing:"
        defs
            [ (c ":42", "A number: jump to that line of this view.")
            , (c ":2f12bcc", "Something ID-shaped: jump to that commit.")
            , (c ":q", "A single key: run that key's binding. " <> c ":q" <> " closes the view.")
            , (c ":edit", "An action name: run it. Every name in the Day 12 tables works here.")
            , (c ":goto <rev>", "A revision expression, resolved by git.")
            , (c ":!git shortlog -sn", "A system command; its output opens in the pager view.")
            , (c ":echo <text>", "Print a line in the status window. Useful when testing bindings.")
            ]
        p_ $ do
            c ":goto"
            " is the one worth learning properly, because it takes anything git would take: "
            c ":goto v1.0"
            ", "
            c ":goto origin/master"
            ", "
            c ":goto HEAD~10"
            ". It also takes browsing-state variables, so "
            c ":goto %(commit)^2"
            " moves to the second parent of the commit under the cursor — the standard way to walk \
            \into the other side of a merge."
        why $ p_ $ do
            "The prompt is not a convenience layer bolted on top. It is the same execution path \
            \that key bindings use: a binding is a stored prompt command, and "
            c ":x"
            " runs the binding for key "
            c "x"
            ". That is why you can test a Day 12 binding by typing its action at the prompt first, \
            \and why there is no capability that keys have and the prompt lacks."
        tip $ p_ $ do
            c ":!"
            " is the fastest way to stop leaving tig. "
            c ":!git shortlog -sn"
            ", "
            c ":!git reflog"
            ", "
            c ":!git branch -vv"
            " — the output lands in the pager view with tig's colouring, and "
            k "q"
            " brings you back to exactly where you were. Save it for non-interactive commands; \
            \anything that wants its own terminal belongs in a Day 13 binding."

    block "Where the cursor already knows to go" $ do
        p_ $ do
            "Two shortcuts sidestep both mechanisms. "
            k "H"
            " jumps to the HEAD commit in the main view — useful after scrolling into 2019. And "
            opt "start-on-head"
            " (off by default) makes tig start there rather than at the top of the list, which in a \
            \repository where you often browse other branches is worth turning on."
        p_ $ do
            "The "
            c "search"
            " keymap is a small piece of polish worth knowing about: while the search prompt is \
            \open, "
            k "C-n"
            " and "
            k "C-p"
            " — and the arrow keys — step through matches without closing it, so you can walk \
            \results and refine the pattern in one go."

    block "Today's habit" $ do
        p_ $ do
            "Pick the small git command you most often leave a tool to run — "
            c "git shortlog"
            ", "
            c "git branch -vv"
            ", "
            c "git reflog"
            " — and run it with "
            c ":!"
            " instead for the rest of the week. Then start using "
            c ":goto"
            " rather than scrolling to find a branch's tip."
        p_ "Tomorrow: the view that changes your repository rather than reading it."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Search on the left, prompt on the right."
        " Search reads the view; the prompt addresses things by name."
    cfg
        [ "/  ?      search forwards / backwards (POSIX ERE unless PCRE is built in)"
        , "n  N      next / previous match     (wrap-search = yes by default)"
        , ":42       jump to line 42"
        , ":2f12bcc  jump to that commit"
        , ":goto HEAD~3     any revision git understands"
        , ":goto %(commit)^2    the other parent of a merge"
        , ":!git shortlog -sn   run it, read the output in the pager view"
        , ":edit  :q            an action name, or a key's binding"
        , "H         jump to HEAD      (start-on-head = yes to begin there)"
        ]
