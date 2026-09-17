module Course.Day.D12 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 12
        , dayTitle = "Bindings and keymaps"
        , daySubtitle = "Key resolution runs view, then generic, then built-in."
        , dayMinutes = 36
        , dayLevel = "advanced"
        , dayManRef = "tigrc(5) BIND COMMAND, Action names"
        , dayTags = ["bind", "keymaps", "actions"]
        , dayGoals =
            [ "bind a key in one view without disturbing it everywhere else"
            , "name any key tig can see, including control and escape combinations"
            , "read the error tig gives for a mistyped action name, which does not mention actions"
            ]
        , dayDiagram = Just d12diagram
        , dayBody = body
        , dayKeys =
            [ ("C-r", "Reload " <> c "~/.tigrc" <> " — once you bind it, as today's config does.")
            ]
        , dayCmds =
            [ ("bind <keymap> <key> <action>", "The whole syntax.")
            , ("bind generic <key> none", "Unbind a key everywhere at once.")
            , (":source ~/.tigrc", "Re-read the config without restarting.")
            ]
        , dayOpts = []
        , dayConfig = day12config
        , dayDrills =
            [ "Add "
                <> c "bind generic <Ctrl-r> :source ~/.tigrc"
                <> " to your config and restart once. From now on you never restart tig to test a \
                   \binding again."
            , "Add "
                <> c "bind main T :toggle commit-title-refs"
                <> ", press "
                <> k "C-r"
                <> ", and try it. Then try "
                <> k "T"
                <> " in the diff view and notice it still does the committer toggle."
            , "Break it on purpose: add "
                <> c "bind main x view-mian"
                <> " (note the typo) and read the warning. It talks about command flags, not about \
                   \actions — work out why before reading the quiz."
            , "Unbind something: "
                <> c "bind generic Q none"
                <> ". Reload, press "
                <> k "Q"
                <> ", and confirm it does nothing. Then take it back out, because you want that \
                   \key."
            , "Bind a search: "
                <> c "bind diff F :/^diff --(git|cc)"
                <> ". Now "
                <> k "F"
                <> " steps file by file through a large commit, the way "
                <> k "@"
                <> " steps chunk by chunk."
            , "Find out what your terminal actually sends: bind "
                <> c "<ShiftTab>"
                <> " to something and see whether it arrives. Not every terminal emits every \
                   \symbolic key."
            , "Today's habit: every time you catch yourself typing the same thing at the "
                <> k ":"
                <> " prompt twice in a day, bind it."
            ]
        , dayQuiz =
            [
                ( "You write "
                    <> c "bind main x view-mian"
                    <> " and tig says "
                    <> c "Unknown command flag 'v'; expected one of :!?@<+>"
                    <> ". Why does a typo in an action name produce an error about flags?"
                , do
                    p_ $ do
                        "Because tig tries the action names first, and when nothing matches it \
                        \assumes you meant a "
                        i_ "command"
                        " rather than an action. Commands must begin with one of the flag \
                        \characters — "
                        c ":"
                        " for internal, "
                        c "!@+?<>"
                        " for external — and "
                        c "view-mian"
                        " begins with "
                        c "v"
                        ", so that is what it complains about."
                    p_ $ do
                        "Read it as “that is not an action name I know”. The same error appears for \
                        \every misspelling, so once you have seen it once it is diagnostic rather \
                        \than confusing."
                )
            ,
                ( "You bind "
                    <> c "bind generic F :toggle file-name"
                    <> "'s replacement, but in the main view your new binding is ignored while "
                    <> k "F"
                    <> " keeps toggling refs. What is happening?"
                , do
                    p_ $ do
                        "The main keymap has its own "
                        k "F"
                        ", and view keymaps win. Resolution order is: the current view's keymap, \
                        \then "
                        c "generic"
                        ", then the built-in defaults — and tig ships "
                        c "bind main F :toggle commit-title-refs"
                        " out of the box."
                    p_ $ do
                        "So a "
                        c "generic"
                        " binding only applies where the view has not claimed the key. To take it \
                        \back you must bind it in the specific keymap too: "
                        c "bind main F :toggle file-name"
                        ". This is verifiable in a few seconds — bind the same key in both keymaps \
                        \to commands that write to different files and see which one runs."
                )
            ,
                ( "What does "
                    <> c "bind generic Q none"
                    <> " do, and how is it different from simply not binding "
                    <> k "Q"
                    <> "?"
                , do
                    p_ $ do
                        c "none"
                        " is a real action meaning “do nothing”, and binding it in the "
                        c "generic"
                        " keymap clears the key from "
                        b_ "all"
                        " keymaps at once. Not binding a key leaves the built-in default in place; \
                        \binding "
                        c "none"
                        " actively removes it."
                    p_ $ do
                        "This is how you disable a default you keep hitting by accident. The \
                        \canonical example in tigrc(5) is disabling a key that runs something \
                        \destructive — worth doing for "
                        k "!"
                        " in the refs view if you have ever force-deleted the wrong branch."
                )
            ,
                ( "You want to bind "
                    <> k "C-m"
                    <> " and it does not work. Which other keys are unavailable, and why?"
                , do
                    p_ $ do
                        c "Ctrl-m"
                        " and "
                        c "Ctrl-i"
                        " cannot be bound, because at the terminal level they are indistinguishable \
                        \from Enter and Tab — the same bytes arrive. tig reads keys through ncurses \
                        \and inherits that limitation."
                    p_ $ do
                        "Three more to know: case is not distinguishable in control sequences, so "
                        c "Ctrl-f"
                        " and "
                        c "Ctrl-F"
                        " are one key; "
                        c "Ctrl-z"
                        " is taken by job control and suspends tig; and "
                        c "Ctrl-Space"
                        " usually arrives as "
                        c "Ctrl-@"
                        ", which "
                        i_ "is"
                        " bindable. Beyond that, whether a symbolic key like "
                        c "<ShiftTab>"
                        " arrives at all depends on your terminal emulator."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

day12config :: [ConfBlock]
day12config =
    [ ConfBlock
        "Reload this file without restarting. Bind it first and everything else in the config\n\
        \becomes cheap to experiment with: edit, press Ctrl-r, see the result."
        "bind generic <Ctrl-r> :source ~/.tigrc"
    , ConfBlock
        "In the diff view, make the arrow keys scroll the patch instead of moving to the next\n\
        \commit in the parent view. Keep J and K for walking commits; this is the split tigmanual\n\
        \itself suggests, and it stops long patches jumping out from under you."
        "bind diff <Down> scroll-line-down\n\
        \bind diff <Up>   scroll-line-up"
    , ConfBlock
        "Step file by file through a large commit, the way @ steps chunk by chunk. Both are\n\
        \ordinary searches, so n repeats whichever you used last."
        "bind diff F :/^diff --(git|cc)"
    ]

-- ---------------------------------------------------------------------------

d12diagram :: Diagram
d12diagram =
    ( diagram
        "Key resolution: a key press is looked up first in the current view's keymap, then in the \
        \generic keymap, then among the built-in defaults; a binding pairs a key with an action, \
        \which is either a named action, an internal command beginning with a colon, or an external \
        \command beginning with a flag character."
        body'
    )
        { dgCaption = do
            "Two things to take away. Resolution is "
            b_ "view, then generic, then built-in"
            " — so a "
            c "generic"
            " binding only applies where the view has not claimed the key. And an action is one of \
            \exactly three things; anything that is not a known action name is assumed to be a \
            \command, which is why a typo produces an error about flags."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  press [label=\"a key press\", fillcolor=\"#f4efe6\"];"
            , "  vkm  [label=\"the current view's keymap\\nmain diff log status\\nstage tree blame refs …\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  gkm  [label=\"the generic keymap\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  dflt [label=\"the built-in defaults\", fillcolor=\"#f4efe6\"];"
            , "  bind [label=\"a binding\"];"
            , "  act  [label=\"an action\"];"
            , "  name [label=\"a named action\\nview-main  move-down\\nstatus-update  none\"];"
            , "  int  [label=\"an internal command\\n:toggle  :set  :/regexp\"];"
            , "  ext  [label=\"an external command\\n! @ + ? < >  (Day 13)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  press -> vkm  [label=\"  is looked up first in\"];"
            , "  vkm  -> gkm   [label=\"  falls back to\"];"
            , "  gkm  -> dflt  [label=\"  falls back to\"];"
            , "  vkm  -> bind  [label=\"  contains\"];"
            , "  bind -> act   [label=\"  runs\"];"
            , "  act  -> name  [label=\"  is either\"];"
            , "  act  -> int   [label=\"  or\"];"
            , "  act  -> ext   [label=\"  or\"];"
            , ""
            , "  { rank=same; name; int; ext; }"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "One line, three parts" $ do
        p_ [class_ "lede"] $ do
            "Every key tig responds to — including all of the ones you have learned — is a line of \
            \configuration in exactly this shape. There is no privileged built-in layer: the \
            \defaults are written in the same language you are about to use."
        cfg
            [ "bind <keymap> <key> <action>"
            , ""
            , "bind main    C    ?git cherry-pick %(commit)     # a real default"
            , "bind diff    ]    :toggle diff-context +1        # another"
            , "bind generic h    view-help                      # and another"
            ]
        p_ $ do
            "Prove it to yourself with "
            c ":save-options /tmp/v"
            ": the second half of that file is every binding tig currently has, written as "
            c "bind"
            " lines you could paste into your own config."
        fig

    block "Keymaps, and the order that decides who wins" $ do
        p_ $ do
            "There are fifteen keymaps: one per view — "
            c "main"
            ", "
            c "diff"
            ", "
            c "log"
            ", "
            c "reflog"
            ", "
            c "help"
            ", "
            c "pager"
            ", "
            c "status"
            ", "
            c "stage"
            ", "
            c "tree"
            ", "
            c "blob"
            ", "
            c "blame"
            ", "
            c "refs"
            ", "
            c "stash"
            ", "
            c "grep"
            " — plus "
            c "generic"
            ", which applies everywhere. There is also "
            c "search"
            ", for keys that work while the search prompt is open."
        p_ "A key press is resolved in this order, and the first match wins:"
        steps
            [ do
                "The "
                b_ "current view's"
                " keymap."
            , do
                "The "
                c "generic"
                " keymap."
            , "The built-in defaults."
            ]
        p_ $ do
            "This is exactly why Day 2's "
            k "F"
            " key behaves differently in different views. tig ships "
            c "bind generic F :toggle file-name"
            " and also "
            c "bind main F :toggle commit-title-refs"
            ", so in the main view you get the refs toggle and everywhere else the file-name one. \
            \tigmanual(7) documents only the first behaviour, which is why it appears to be wrong."
        gotcha $ p_ $ do
            "The consequence for your own config: a "
            c "generic"
            " binding "
            b_ "cannot"
            " override a view's binding. If you rebind a key in "
            c "generic"
            " and it works in some views and not others, a view keymap has claimed it. Bind it in \
            \that keymap too, or clear it everywhere first with "
            c "bind generic <key> none"
            "."

    block "Naming keys" $ do
        p_ $ do
            "Key values are never quoted. An ordinary character stands for itself — including \
            \multi-byte UTF-8 ones, so "
            c "bind generic ø …"
            " is legal. Everything else has a symbolic name in angle brackets, case-insensitively:"
        cfg
            [ "<Enter> <Space> <Backspace> <Tab> <Escape>/<Esc>"
            , "<Left> <Right> <Up> <Down> <Home> <End>"
            , "<Insert>/<Ins> <Delete>/<Del> <PageUp>/<PgUp> <PageDown>/<PgDown>"
            , "<ScrollBack>/<SBack> <ScrollFwd>/<SFwd>"
            , "<ShiftTab>/<BackTab> <ShiftLeft> <ShiftRight> <ShiftDelete> <ShiftHome> <ShiftEnd>"
            , "<SingleQuote> <DoubleQuote> <F1> … <F19>"
            , ""
            , "<Hash>       the # key — # starts a comment, so it needs a name"
            , "<LessThan>   the < key, also spelled <LT>"
            , "<Ctrl-f>     control combinations"
            , "<Esc>o       escape followed by a key"
            ]
        note $ p_ $ do
            "Five limitations worth knowing before you spend time on a binding that cannot work. "
            c "Ctrl-m"
            " and "
            c "Ctrl-i"
            " are Enter and Tab at the byte level and cannot be bound. Case is invisible in control \
            \sequences, so "
            c "Ctrl-f"
            " and "
            c "Ctrl-F"
            " are the same key. "
            c "Ctrl-z"
            " suspends tig. "
            c "Ctrl-Space"
            " arrives as "
            c "Ctrl-@"
            ", which is bindable. And whether a symbolic key reaches tig at all depends on your \
            \terminal emulator."
        p_ $ do
            "One more boundary: keys at the "
            i_ "line-entry prompt"
            " are readline's, not tig's, and are configured in "
            c "~/.inputrc"
            ". tig honours an "
            c "$if tig"
            " section there but does not require one."

    block "Actions: three kinds" $ do
        p_ "The third field is one of exactly three things, and tig tries them in this order:"
        defs
            [
                ( "A named action"
                , do
                    c "view-main"
                    ", "
                    c "move-down"
                    ", "
                    c "status-update"
                    ", "
                    c "none"
                    ". Names are case-insensitive and "
                    c "-"
                    ", "
                    c "_"
                    " and "
                    c "."
                    " are interchangeable, so "
                    c "view-main"
                    " and "
                    c "View.Main"
                    " are the same."
                )
            ,
                ( "An internal command"
                , do
                    "Anything starting with "
                    c ":"
                    " — the Day 5 prompt commands. "
                    c ":toggle"
                    ", "
                    c ":set"
                    ", "
                    c ":source"
                    ", and searches like "
                    c ":/^@@"
                    "."
                )
            ,
                ( "An external command"
                , do
                    "Anything starting with "
                    c "!"
                    ", "
                    c "@"
                    ", "
                    c "+"
                    ", "
                    c "?"
                    ", "
                    c "<"
                    " or "
                    c ">"
                    ". Tomorrow's lesson entirely."
                )
            ]
        p_ $ do
            "The named actions are grouped much as this course has been: view switching ("
            c "view-main"
            " and friends), view manipulation ("
            c "enter"
            ", "
            c "back"
            ", "
            c "next"
            ", "
            c "parent"
            ", "
            c "maximize"
            ", "
            c "view-close"
            ", "
            c "quit"
            "), the staging actions from Day 6, cursor movement, scrolling, search, and a handful \
            \of miscellaneous ones ("
            c "edit"
            ", "
            c "prompt"
            ", "
            c "options"
            ", "
            c "screen-redraw"
            ", "
            c "stop-loading"
            ", "
            c "show-version"
            ", "
            c "none"
            ")."
        gotcha $ p_ $ do
            "Because unknown names fall through to the command branch, a typo gives you a confusing \
            \error: "
            c "bind main x view-mian"
            " reports "
            c "Unknown command flag 'v'; expected one of :!?@<+>"
            ". It is not talking about your action at all — it got as far as “this is not an action, \
            \so it must be a command” and then found no flag. Translate it as “no such action”."

    block "Making the config cheap to change" $ do
        p_ $ do
            "The first binding to add is the one that makes every other binding easy to try:"
        cfg
            [ "bind generic <Ctrl-r> :source ~/.tigrc"
            ]
        p_ $ do
            "Now the loop is: edit the file in one window, press "
            k "C-r"
            " in tig, see the result. No restarting, no losing your place. This was tested rather \
            \than assumed — binding a key, changing the sourced file, pressing the reload key and \
            \pressing the changed key does run the new binding."
        tip $ p_ $ do
            "Because sourcing is in-place and later definitions win, you can also split your config \
            \up: "
            c "source ~/.tig/colours.tigrc"
            " and "
            c "source ~/.tig/bindings.tigrc"
            " at the top of "
            c "~/.tigrc"
            ", with the things you are currently fiddling with below them. Use "
            c "source -q"
            " for a file that might not exist — otherwise tig warns on every start."

    block "Today's habit" $ do
        p_ $ do
            "For the rest of the week, keep "
            c "~/.tigrc"
            " open in a window. When you type the same thing at the "
            k ":"
            " prompt twice in one day, bind it and press "
            k "C-r"
            ". The three blocks below are the ones this course has earned; the rest should be \
            \yours."
        p_ "Tomorrow: bindings that run real commands, with your browsing state substituted in."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Bindings."
        " Resolution is view, then generic, then built-in — first match wins."
    cfg
        [ "bind <keymap> <key> <action>"
        , "  keymaps  main diff log reflog help pager status stage tree blob"
        , "           blame refs stash grep + generic (everywhere) + search"
        , "  keys     a  <Enter> <Tab> <Esc> <Up> <Hash> <LessThan> <Ctrl-f> <Esc>o <F5>"
        , "  actions  a name (view-main, move-down, none)"
        , "           :internal   (:toggle, :set, :source, :/regexp)"
        , "           !@+?<> external  (tomorrow)"
        , "bind generic <key> none      # unbind everywhere at once"
        , "bind generic <Ctrl-r> :source ~/.tigrc      # bind this FIRST"
        , "# 'Unknown command flag' really means 'no such action name'"
        ]
