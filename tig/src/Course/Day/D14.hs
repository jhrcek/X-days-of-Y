module Course.Day.D14 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 14
        , dayTitle = "Colours and sharp edges"
        , daySubtitle = "Areas, large repositories, and every place the manual is wrong."
        , dayMinutes = 36
        , dayLevel = "advanced"
        , dayManRef = "tigrc(5) COLOR COMMAND, SOURCE COMMAND; tig(1) ENVIRONMENT VARIABLES"
        , dayTags = ["colour", "performance", "environment"]
        , dayGoals =
            [ "colour any part of any view, including lines matching a pattern you choose"
            , "make tig usable in a repository with a very long history"
            , "know which parts of tigrc(5) and tigmanual(7) to distrust, and how to check"
            ]
        , dayDiagram = Just d14diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("color <area> <fg> <bg> [attrs]", "The whole syntax.")
            , ("source [-q] <path>", "Read another config file in place.")
            ]
        , dayOpts =
            [ ("refresh-mode", c "manual" <> " / " <> c "auto" <> " (default) / " <> c "after-command" <> " / " <> c "periodic" <> ".")
            , ("commit-order", c "auto" <> " by default; " <> c "default" <> " is faster on long histories.")
            , ("git-colors", "Map git's colour settings onto tig's areas, or " <> c "no" <> " to ignore them.")
            , ("horizontal-scroll", "How far " <> k "Left" <> "/" <> k "Right" <> " move. Default " <> c "50%" <> ".")
            , ("mouse", "Mouse support. Off by default, and it costs you text selection.")
            ]
        , dayConfig = day14config
        , dayDrills =
            [ "Add "
                <> c "color cursor default default reverse"
                <> " and reload with "
                <> k "C-r"
                <> ". The cursor line now inverts whatever your terminal theme is, rather than \
                   \fighting it."
            , "Add a pattern colour: "
                <> c "color \"/(TODO|FIXME|XXX)/\" yellow default bold"
                <> ". Open a diff that adds a TODO and watch it stand out."
            , "Colour one view only: "
                <> c "color stage.diff-chunk magenta default"
                <> ". Chunk headers in the stage view differ from the diff view, which helps when \
                   \you are staging."
            , "Break it on purpose: copy tigrc(5)'s own example, "
                <> c "color palette-0 = red"
                <> ", into your config. Read the error, then work out what it is missing."
            , "Find your slowest repository. Time "
                <> c "tig"
                <> " there, then add "
                <> c "set commit-order = default"
                <> " and time it again."
            , "In that same repository, press "
                <> k "G"
                <> " to turn the graph off and notice the commit order change with it — then \
                   \reread Day 2's note on why."
            , "Today's habit: run "
                <> c ":save-options ~/tig-reference"
                <> " and keep the file. When tig and its manual disagree, that file is the \
                   \tiebreaker."
            ]
        , dayQuiz =
            [
                ( "tigrc(5) gives "
                    <> c "palette-0 = red"
                    <> " as its example for the graph palette. You put "
                    <> c "color palette-0 red"
                    <> " in your config and get “Invalid color mapping”. Who is wrong?"
                , do
                    p_ $ do
                        "The manual — or rather, the example is written in the git-config form and \
                        \does not survive translation. The "
                        c "color"
                        " command needs both a foreground "
                        i_ "and"
                        " a background: "
                        c "color palette-0 red default"
                        " is accepted."
                    p_ $ do
                        "While checking this, the range turned out to be real: "
                        c "palette-0"
                        " through "
                        c "palette-13"
                        " work and "
                        c "palette-14"
                        " is rejected with “Unknown color name”. Fourteen colours, as documented, \
                        \but the example needs fixing."
                )
            ,
                ( "tig takes eleven seconds to draw its first screen in your monorepo. What are the \
                  \two settings to reach for, and which one should you not need?"
                , do
                    p_ $ do
                        "First "
                        opt "commit-order"
                        ". It defaults to "
                        c "auto"
                        ", which silently switches to topological ordering whenever the commit graph \
                        \is enabled — and topological ordering means git cannot stream results, it \
                        \has to walk further before it can emit anything. Setting it to "
                        c "default"
                        " restores chronological order and lets the view fill immediately."
                    p_ $ do
                        "Second, limit what you ask for: "
                        c "tig -n1000"
                        " or "
                        c "tig --since=6.months"
                        ". The one you should not need is the "
                        c "v1"
                        " graph — it is faster but less accurate, and it is only worth it once "
                        c "commit-order"
                        " and a revision limit have failed you."
                )
            ,
                ( "Your tig refreshes itself while you are reading a diff, and the cursor jumps. \
                  \What is doing it, and what should you set?"
                , do
                    p_ $ do
                        opt "refresh-mode"
                        ", which defaults to "
                        c "auto"
                        ": tig watches for modifications made through another view and reloads the \
                        \ones affected. That is helpful while staging and disruptive while reading."
                    p_ $ do
                        "The four values are "
                        c "manual"
                        " (never), "
                        c "auto"
                        " (the default), "
                        c "after-command"
                        " (only on returning from an external command) and "
                        c "periodic"
                        " (every "
                        opt "refresh-interval"
                        " seconds, default "
                        c "10"
                        "). "
                        c "after-command"
                        " is the setting most people actually want: it updates after you do \
                        \something, and never while you are reading."
                )
            ,
                ( "Which is authoritative when they disagree: tigrc(5), tigmanual(7), the help view, \
                  \or "
                    <> c ":save-options"
                    <> "?"
                , do
                    p_ $ do
                        c ":save-options"
                        ", then the help view, then the manual pages. The first two are generated \
                        \from the running program; the manual pages are maintained by hand and have \
                        \drifted."
                    p_ $ do
                        "This course found five disagreements in 2.6.1 without looking hard, listed \
                        \below. None of them is serious, and all of them would have cost somebody an \
                        \afternoon. The habit worth keeping is cheap: when a documented thing does \
                        \not work, dump the options and look."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

day14config :: [ConfBlock]
day14config =
    [ ConfBlock
        "Let the cursor line invert whatever the terminal theme already is, instead of forcing\n\
        \a colour pair that fights it. Survives changing terminal themes, which a hard-coded\n\
        \pair does not."
        "color cursor default default reverse"
    , ConfBlock
        "Make TODO, FIXME and XXX stand out anywhere they appear, in any view. A quoted area\n\
        \of the form /.../ is a regular expression matched against the whole line."
        "color \"/(TODO|FIXME|XXX)/\" yellow default bold"
    , ConfBlock
        "Refresh only on returning from an external command, rather than whenever tig notices\n\
        \a change elsewhere. Views stop reloading underneath you while you are reading a diff,\n\
        \but still update after you stage or commit something."
        "set refresh-mode = after-command"
    ]

-- ---------------------------------------------------------------------------

d14diagram :: Diagram
d14diagram =
    ( diagram
        "A colour rule binds an area - a built-in name, a view-prefixed name, or a quoted string \
        \or regular expression - to a foreground colour, a background colour and optional \
        \attributes; git's own colour configuration is mapped onto the same areas."
        body'
    )
        { dgCaption = do
            "An area is the only interesting part: as well as the built-in names, a "
            b_ "quoted string"
            " colours any line containing it, and a string of the form "
            c "/…/"
            " is a regular expression. That turns the colour command from theming into annotation — \
            \you can make your own conventions visible in every view at once."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  rule [label=\"a colour rule\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  area [label=\"an area\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  bi   [label=\"a built-in name\\ncursor  title-focus\\ndiff-add  main-head\"];"
            , "  vp   [label=\"a view-prefixed name\\nstage.diff-chunk\"];"
            , "  re   [label=\"a quoted string\\nor /regexp/\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  fg   [label=\"a colour\\nnamed, colorN, or N\"];"
            , "  attr [label=\"an attribute\\nbold dim reverse\\nunderline blink standout\"];"
            , "  gitc [label=\"git's color.* settings\", fillcolor=\"#f4efe6\"];"
            , ""
            , "  rule -> area [label=\"  names\"];"
            , "  area -> bi   [label=\"  is either\"];"
            , "  area -> vp   [label=\"  or\"];"
            , "  area -> re   [label=\"  or\"];"
            , "  rule -> fg   [label=\"  sets as foreground\"];"
            , "  rule -> fg   [label=\"and as background  \", style=dashed, constraint=false];"
            , "  rule -> attr [label=\"  may add\"];"
            , "  gitc -> area [label=\"  is mapped onto\", style=dashed];"
            , ""
            , "  { rank=same; bi; vp; re; }"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "The third language" $ do
        p_ [class_ "lede"] $ do
            "Settings shape the data, bindings shape the keys, and colours shape what your eye \
            \finds first. The syntax is one line, and the interesting part is that an “area” does \
            \not have to be something tig already knows about — it can be a pattern of your own."
        cfg
            [ "color <area> <foreground> <background> [attributes]"
            , ""
            , "color default          white   black"
            , "color cursor           default default reverse"
            , "color diff-header      yellow  default"
            , "color tree.date        black   cyan    bold      # one view only"
            , "color \"Reported-by:\"   green   default           # a literal string"
            , "color \"/(TODO|FIXME)/\" yellow default bold       # a regular expression"
            ]
        p_ $ do
            "Colours are "
            c "white"
            ", "
            c "black"
            ", "
            c "green"
            ", "
            c "magenta"
            ", "
            c "blue"
            ", "
            c "cyan"
            ", "
            c "yellow"
            ", "
            c "red"
            " and "
            c "default"
            " — plus "
            c "color0"
            " … "
            c "colorN"
            " or bare numbers for 256-colour terminals. Attributes are "
            c "normal"
            ", "
            c "blink"
            ", "
            c "bold"
            ", "
            c "dim"
            ", "
            c "reverse"
            ", "
            c "standout"
            " and "
            c "underline"
            "."
        fig

    block "Areas: three kinds, and the one worth your time" $ do
        defs
            [
                ( "Built-in names"
                , do
                    "About seventy of them, grouped: interface ("
                    c "cursor"
                    ", "
                    c "status"
                    ", "
                    c "title-focus"
                    ", "
                    c "title-blur"
                    ", "
                    c "search-result"
                    "), columns ("
                    c "date"
                    ", "
                    c "author"
                    ", "
                    c "id"
                    ", "
                    c "line-number"
                    "), the main view's ref labels ("
                    c "main-head"
                    ", "
                    c "main-tag"
                    ", "
                    c "main-remote"
                    ") and the diff markup ("
                    c "diff-header"
                    ", "
                    c "diff-chunk"
                    ", "
                    c "diff-add"
                    ", "
                    c "diff-del"
                    ")."
                )
            ,
                ( "View-prefixed names"
                , do
                    "Any built-in name prefixed with a view: "
                    c "stage.diff-chunk"
                    " differs from "
                    c "diff.diff-chunk"
                    ". Useful for making “I am staging” look different from “I am reading”."
                )
            ,
                ( "Your own patterns"
                , do
                    "A quoted string colours every line containing it. A quoted string of the form "
                    c "/…/"
                    " is a regular expression. This is the one worth your time."
                )
            ]
        tip $ p_ $ do
            "Pattern areas turn colour into annotation. Highlight "
            c "TODO"
            " and "
            c "FIXME"
            ", or your issue-tracker prefix so ticket references jump out of commit messages, or "
            c "Signed-off-by"
            " if your project cares. It applies in every view at once, including diffs and the \
            \pager, because it is matched against lines rather than against a data model."
        p_ $ do
            "Two related settings. "
            opt "git-colors"
            " maps git's own "
            c "color.*"
            " configuration onto tig's areas, so your "
            c "color.diff.new"
            " already applies; set it to "
            c "no"
            " to make tig ignore git's colours entirely. And tig respects "
            c "NO_COLOR"
            " in the environment."
        gotcha $ p_ $ do
            "tigrc(5)'s own example for the graph palette, "
            c "palette-0 = red"
            ", does not work as a "
            c "color"
            " command — "
            c "color palette-0 red"
            " is rejected with “Invalid color mapping”, because a background is required. Write "
            c "color palette-0 red default"
            ". The fourteen palette entries "
            c "palette-0"
            " to "
            c "palette-13"
            " are real; "
            c "palette-14"
            " is not."

    block "Large repositories" $ do
        p_ $ do
            "tig is as fast as the git command behind it, so making it fast means asking git for \
            \less. In rough order of effect:"
        steps
            [ do
                b_ "Set "
                c "commit-order = default"
                b_ "."
                " The default is "
                c "auto"
                ", which switches to topological ordering whenever the graph is on. Topological \
                \order cannot be streamed — git must walk ahead before emitting anything — so the \
                \first screen waits. tigrc(5) recommends this explicitly for long histories."
            , do
                b_ "Limit the revisions."
                " "
                c "tig -n1000"
                " or "
                c "tig --since=1.year"
                ". You almost never want all 200,000 commits."
            , do
                b_ "Press "
                k "z"
                b_ " when you have enough."
                " It stops every background load; what has arrived stays usable."
            , do
                b_ "Turn the graph off with "
                k "G"
                b_ ", or fall back to "
                c "v1"
                b_ "."
                " Last resort: "
                c "v1"
                " is faster and less accurate."
            , do
                b_ "Set "
                c "refresh-mode"
                b_ "."
                " "
                c "auto"
                " watches for changes; on a large working tree that costs. "
                c "after-command"
                " or "
                c "manual"
                " is cheaper."
            ]
        note $ p_ $ do
            "A subtlety from Day 2 that matters here: because "
            c "commit-order = auto"
            " keys off the graph, pressing "
            k "G"
            " to hide the graph also changes the "
            i_ "order"
            " of the commits. If you set "
            c "commit-order = default"
            " explicitly, that coupling disappears and "
            k "G"
            " becomes purely cosmetic — which is another reason to set it."

    block "The environment, and what it is for" $ do
        defs
            [ (c "TIGRC_USER" <> ", " <> c "TIGRC_SYSTEM", "Override the config file paths. Set the second to empty for built-in defaults only.")
            , (c "TIG_EDITOR", "The editor for " <> k "e" <> ". Beats " <> c "$GIT_EDITOR" <> ", " <> c "core.editor" <> ", " <> c "$VISUAL" <> " and " <> c "$EDITOR" <> ".")
            , (c "TIG_DIFF_OPTS", "Diff options. Overridden by " <> opt "diff-options" <> " and by the command line.")
            , (c "TIG_LS_REMOTE", "The command that lists refs. Narrow it to hide a thousand remote branches.")
            , (c "TIG_SCRIPT", "A file of prompt commands run at startup. Also the basis of tig's own test suite.")
            , (c "TIG_TRACE", "A path to log every git command tig runs. The first thing to reach for when a view is empty or slow.")
            ]
        p_ $ do
            c "TIG_TRACE"
            " is the one people do not know about and should. When a view is empty, or \
            \inexplicably slow, or showing something you did not expect, set it to a path and read \
            \the file: you get the exact git command tig ran, which you can then run yourself. \
            \Almost every “tig is broken” turns out to be “that git command returns that”."
        p_ $ do
            "And "
            c "source"
            " is worth a line. It reads a file in place, so later commands still win, and "
            c "source -q"
            " suppresses the warning when the file does not exist — which is what you want for a \
            \machine-specific fragment that is not on every machine."

    block "Where this course disagrees with the manual" $ do
        p_ $ do
            "Everything in these fourteen days was checked against tig 2.6.1 rather than read off \
            \the page. Five things turned out to be wrong or missing, and the course follows the \
            \binary in each case:"
        defs
            [
                ( "The " <> c "git gc" <> " binding"
                , do
                    "tigmanual(7) documents a built-in external command "
                    c "generic G → git gc"
                    ". It does not exist in 2.6.1. "
                    k "G"
                    " in the main view is "
                    c ":toggle commit-title-graph"
                    ". The same table omits the refs, reflog and stash commands from Day 9, which "
                    i_ "do"
                    " exist."
                )
            ,
                ( "What " <> k "F" <> " does"
                , do
                    "tigmanual(7) says “toggle reference display”. True in the main and reflog \
                    \views; in the generic keymap "
                    k "F"
                    " is "
                    c ":toggle file-name"
                    "."
                )
            ,
                ( opt "mailmap" <> "'s default"
                , do
                    "tigrc(5) says “Off by default”. The built-in default is "
                    c "yes"
                    ", confirmed with the system config disabled."
                )
            ,
                ( "The palette example"
                , do
                    c "palette-0 = red"
                    " is not a valid "
                    c "color"
                    " command; it needs a background."
                )
            ,
                ( "“A non-negative integer”"
                , do
                    "tigrc(5)'s description of int values. "
                    c "set tab-size = 0"
                    " is rejected — “Value must be between 1 and 1024”. Bounds exist and are not \
                    \documented per setting."
                )
            ]
        p_ $ do
            "There are also four settings the binary accepts that tigrc(5)'s variable list does not \
            \mention at all: "
            opt "diff-noprefix"
            ", "
            opt "file-filter"
            ", "
            opt "rev-filter"
            " and "
            opt "id-width"
            ". The first three are what Day 4's "
            k "%"
            " and "
            k "^"
            " keys toggle."
        why $ p_ $ do
            "None of this is a complaint. It is the reason "
            c ":save-options"
            " and the help view are worth more than any documentation: they are generated from the \
            \running program, so they cannot drift. Keep a dump of your own build somewhere, and \
            \when something documented does not work, look there before you look anywhere else."

    block "What to read next, and today's habit" $ do
        p_ $ do
            "You can now read all three manual pages unaided, which was the point. The parts this \
            \course deliberately skipped: the full colour-area table in tigrc(5), the complete \
            \browsing-state variable list, "
            opt "pgrp"
            " and its Zsh interaction, the mouse settings, and the "
            c "v1"
            " graph internals. All of them are lookups now rather than lessons."
        p_ $ do
            "The habit that outlasts the course: keep "
            c "~/.tigrc"
            " small and defensible. Every line in the file this course built has a comment saying \
            \why it is there, and that comment is the only thing that will stop you being afraid of \
            \the file in eight months. Add lines the same way — one at a time, each earned by an \
            \annoyance you actually had."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Colours, speed, environment."
        " The last line is the one to keep."
    cfg
        [ "color <area> <fg> <bg> [bold|dim|reverse|underline|standout|blink]"
        , "  areas    cursor status title-focus diff-add main-head … (~70)"
        , "           stage.diff-chunk        one view only"
        , "           \"/(TODO|FIXME)/\"        a regexp: YOUR conventions, every view"
        , "  colours  8 names + default, or color0..colorN / bare numbers"
        , ""
        , "set commit-order = default     # long histories: the big one"
        , "set refresh-mode = after-command   # stop views moving while you read"
        , "tig -n1000 / --since=1.year    # ask git for less      z  stop loading"
        , "TIG_TRACE=/tmp/t tig           # log every git command tig runs"
        , ":save-options ~/tig-reference  # the tiebreaker when the manual is wrong"
        ]
