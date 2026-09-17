module Course.Day.D11 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 11
        , dayTitle = "Columns and view settings"
        , daySubtitle = "A view is a list of column specifications, and each one is addressable."
        , dayMinutes = 34
        , dayLevel = "intermediate"
        , dayManRef = "tigrc(5) View settings"
        , dayTags = ["columns", "view settings", "layout"]
        , dayGoals =
            [ "read a view setting and say what each column and column option does"
            , "change one column of one view without rewriting the whole specification"
            , "predict which columns a given view will accept, and read the error when it will not"
            ]
        , dayDiagram = Just d11diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ (":toggle author-display", "Cycle a column's display option from the prompt.")
            , (":toggle commit-title-graph", "Cycle a non-display column option.")
            ]
        , dayOpts =
            [ ("main-view", "Column list for the main view. " <> c "reflog-view" <> ", " <> c "refs-view" <> " and the rest follow the same shape.")
            , ("main-view-date", "Shorthand: the date column of the main view alone.")
            , ("main-view-date-format", "A " <> c "strftime" <> " string, when the display mode is " <> c "custom" <> ".")
            , ("main-view-id", "Shorthand: show the commit ID column in the main view.")
            , ("tree-view-file-size", "Shorthand: how the tree view shows sizes.")
            ]
        , dayConfig = day11config
        , dayDrills =
            [ "Run "
                <> c ":save-options /tmp/v"
                <> " and read the "
                <> c "set main-view = …"
                <> " line. Every column and every option is spelled out, including the ones you \
                   \have never set."
            , "At the prompt, type "
                <> c ":set main-view-id = yes"
                <> ". The ID column appears. You changed one column without naming the other five."
            , "Now type "
                <> c ":set main-view = author:full commit-title"
                <> ". Note what you lost — the date, the graph, the refs. A full list replaces; a \
                   \shorthand patches."
            , "Try "
                <> c ":set main-view-date = custom"
                <> " followed by "
                <> c ":set main-view-date-format = \"%a %d %b\""
                <> ". Column options are set the same way as display modes."
            , "Break it on purpose: "
                <> c ":set grep-view = author:full text"
                <> ". Read the error — it names the view and the column it refused."
            , "Break it differently: "
                <> c ":set main-view = author:full,nosuchopt=3"
                <> ". Note that this error names the column, not the view."
            , "Today's habit: when a view is nearly right, change the one column that is wrong \
              \using the shorthand. Rewriting the whole list is how people lose their graph \
              \and never notice."
            ]
        , dayQuiz =
            [
                ( "You set "
                    <> c "main-view-date = relative"
                    <> " on Day 7. Today you write a full "
                    <> c "set main-view = …"
                    <> " line that includes "
                    <> c "date:relative"
                    <> ". Your custom date format stops working. Why?"
                , do
                    p_ $ do
                        "Because the two forms do different things. The shorthand "
                        i_ "patches"
                        " one field of one column and leaves the rest of that column's options \
                        \alone. A full list "
                        i_ "replaces"
                        " the entire specification, so every option you did not mention reverts to \
                        \its default."
                    p_ $ do
                        "You can watch it happen with "
                        c ":save-options"
                        ". After the shorthand, the date column reads "
                        c "date:relative,use-author=no,local=no,format=\"%Y-%m-%d\""
                        "; after a full list mentioning only "
                        c "date:relative"
                        ", the "
                        c "format="
                        " has gone empty. Prefer shorthands unless you genuinely want to specify \
                        \every column."
                )
            ,
                ( "What is the difference between "
                    <> c "author:email"
                    <> " and "
                    <> c "author:full,width=20"
                    <> ", and what does "
                    <> c "width=5"
                    <> " do to an author column?"
                , do
                    p_ $ do
                        "The first value in a specification is always the "
                        b_ "display option"
                        "; everything after it is a named column option. So "
                        c "author:email"
                        " sets the display mode, and "
                        c "author:full,width=20"
                        " sets the mode and a fixed width."
                    p_ $ do
                        c "width=5"
                        " does something specific to author and committer columns: any width from 1 \
                        \to 10 switches the column to initials rather than truncating the name. "
                        c "width=0"
                        " means “size to fit the content”, and "
                        c "maxwidth"
                        " means “size to fit, but no wider than this” and accepts a percentage."
                )
            ,
                ( "Why does "
                    <> c "set grep-view = author:full text"
                    <> " fail when "
                    <> c "set main-view = author:full …"
                    <> " is fine?"
                , do
                    p_ $ do
                        "Because each view supports only the columns that make sense for what it \
                        \lists. The grep view lists matching lines in files, and a line does not \
                        \have an author — so it accepts "
                        c "file-name"
                        ", "
                        c "line-number"
                        " and "
                        c "text"
                        ", and nothing else."
                    p_ $ do
                        "The error is unusually good: "
                        c "The grep view does not support author column"
                        ". Compare it with the error for a bad column option, "
                        c "Unknown option `nosuchopt' for column author"
                        ", which names the column instead. Between the two you can always tell \
                        \whether you picked the wrong column or the wrong option."
                )
            ,
                ( "Day 2's "
                    <> k "D"
                    <> " and "
                    <> k "A"
                    <> " keys, and the option menu, and the settings in this lesson — how are they \
                       \related?"
                , do
                    p_ $ do
                        "They are the same mechanism at three levels of ceremony. "
                        k "D"
                        " is bound to "
                        c ":toggle date"
                        ", which cycles the date column's display option. The option menu is a list \
                        \of those same toggles. This lesson simply writes the resulting value down."
                    p_ $ do
                        "The naming rule is worth knowing: display options are "
                        c "<column>-display"
                        " — as in "
                        c ":toggle author-display"
                        " — while other column options are "
                        c "<column>-<option>"
                        ", as in "
                        c ":toggle commit-title-graph"
                        ". That is why Day 2's graph toggle had such an odd-looking name."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

day11config :: [ConfBlock]
day11config =
    [ ConfBlock
        "Show the abbreviated commit ID in the main view. You copy hashes out of tig often\n\
        \enough that pressing X every session is wasted motion, and the column is narrow."
        "set main-view-id = yes"
    , ConfBlock
        "Highlight commit titles running past 72 characters, so that over-long subject lines\n\
        \are visible while reviewing rather than after pushing."
        "set main-view-commit-title-overflow = 72"
    , ConfBlock
        "Human-readable file sizes in the tree view: 12.2K rather than 12524."
        "set tree-view-file-size = units"
    ]

-- ---------------------------------------------------------------------------

d11diagram :: Diagram
d11diagram =
    ( diagram
        "A view setting is a list of column specifications; each specification names a column \
        \type, a display option and further named options; a shorthand setting addresses one \
        \column of one view, while a full list replaces every column."
        body'
    )
        { dgCaption = do
            "The whole language is one line: a view setting is a list of "
            c "type:display,option=value"
            " items. The distinction that costs people their configuration is the dashed pair — a "
            b_ "shorthand"
            " patches one column and preserves the rest, while a "
            b_ "full list"
            " replaces everything you did not mention with its default."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  vs   [label=\"a view setting\\nmain-view, blame-view, …\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  spec [label=\"a column specification\\nauthor:email,width=20\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  type [label=\"a column type\\nauthor date id text\\nfile-name commit-title\"];"
            , "  disp [label=\"a display option\\n(always first)\"];"
            , "  copt [label=\"a column option\\nwidth= maxwidth=\\ninterval= format=\"];"
            , "  short [label=\"a shorthand setting\\nmain-view-date\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  tog  [label=\"a toggle\\n:toggle author-display\", fillcolor=\"#f4efe6\"];"
            , ""
            , "  vs   -> spec  [label=\"  is a list of\"];"
            , "  spec -> type  [label=\"  names\"];"
            , "  spec -> disp  [label=\"  begins with\"];"
            , "  spec -> copt  [label=\"  may carry\"];"
            , "  short -> spec [label=\"  patches one\", style=dashed];"
            , "  vs   -> spec  [label=\"replaces every  \", style=dashed, constraint=false];"
            , "  tog  -> disp  [label=\"  cycles\"];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Every view is a list of columns" $ do
        p_ [class_ "lede"] $ do
            "The main view's layout is not hard-coded. It is a setting whose value is a list of "
            b_ "column specifications"
            ", and once you can read one of those you can reshape every view tig has. This is the \
            \first of tig's three small languages; bindings and colours follow."
        p_ "Here is the real default, as tig reports it:"
        cfg
            [ "set main-view = line-number:no,interval=5 \\"
            , "                id:no,color=no \\"
            , "                date:default,use-author=no,local=no,format=\"%Y-%m-%d\" \\"
            , "                author:full \\"
            , "                committer:no \\"
            , "                commit-title:yes,graph=v2,refs=yes"
            ]
        p_ $ do
            "Each item is "
            c "type:display,option=value,option=value"
            ". The type comes first, then a colon, then a comma-separated list in which "
            b_ "the first value is always the display option"
            " and the rest are named. A line ending in a backslash continues, which is the only way \
            \to keep these readable."
        fig

    block "The column types, and which views accept them" $ do
        p_ "There are eleven column types. Not every view takes every one:"
        defs
            [ (c "author" <> ", " <> c "committer", "Display: " <> c "full" <> ", " <> c "abbreviated" <> ", " <> c "email" <> ", " <> c "email-user" <> ". Plus " <> c "width" <> " and " <> c "maxwidth" <> ".")
            , (c "date", "Display: " <> c "default" <> ", " <> c "relative" <> ", " <> c "relative-compact" <> ", " <> c "custom" <> ". Plus " <> c "use-author" <> ", " <> c "local" <> ", " <> c "format" <> ".")
            , (c "id", "The commit ID. " <> c "width" <> ", and " <> c "color" <> " to tint it.")
            , (c "commit-title", "The subject. " <> c "graph" <> ", " <> c "refs" <> ", " <> c "overflow" <> ".")
            , (c "file-name", "Display: " <> c "auto" <> ", " <> c "always" <> ". Plus widths.")
            , (c "file-size", "Display: " <> c "default" <> " or " <> c "units" <> " (" <> c "12.2K" <> ").")
            , (c "line-number", c "interval" <> " controls how often a number is printed.")
            , (c "mode" <> ", " <> c "ref" <> ", " <> c "status" <> ", " <> c "text", "File mode, ref name, status label, and the line itself.")
            ]
        p_ $ do
            "Which view takes which is a short table in tigrc(5), and you do not need to memorise \
            \it because the error is explicit:"
        sh
            [ "$ tig 2>&1 | head -1     # with 'set grep-view = author:full text'"
            , "tig warning: /home/you/.tigrc:1: The grep view does not support author column"
            ]
        p_ $ do
            "Broadly: the history views ("
            c "main"
            ", "
            c "reflog"
            ", "
            c "refs"
            ", "
            c "stash"
            ") take the commit-shaped columns; the text views ("
            c "diff"
            ", "
            c "log"
            ", "
            c "pager"
            ", "
            c "stage"
            ", "
            c "blob"
            ") take only "
            c "line-number"
            " and "
            c "text"
            "; and "
            c "blame"
            ", "
            c "tree"
            ", "
            c "grep"
            " and "
            c "status"
            " take the file-shaped ones."

    block "Addressing one column: the shorthand that saves your config" $ do
        p_ $ do
            "Writing the whole list to change one thing is how people lose their commit graph. \
            \Appending a column name to the view setting addresses that column alone:"
        cfg
            [ "set main-view-date = relative        # just the date column"
            , "set main-view-id = yes               # just the ID column"
            , "set blame-view-line-number = no      # just that, in the blame view"
            , "set tree-view-file-size = units"
            , ""
            , "# and column options get the option name appended too"
            , "set main-view-date-format = \"%a %d %b\""
            , "set main-view-id-width = 12"
            , "set main-view-commit-title-overflow = 72"
            ]
        gotcha $ p_ $ do
            "A shorthand "
            b_ "patches"
            "; a full list "
            b_ "replaces"
            ". Setting "
            c "main-view-date = relative"
            " leaves the column's "
            c "format=\"%Y-%m-%d\""
            " intact, so pressing "
            k "D"
            " round to "
            c "custom"
            " still shows the date you configured. Writing a full "
            c "set main-view = … date:relative …"
            " wipes that format back to empty. Check with "
            c ":save-options"
            " if you are unsure which you just did."
        why $ p_ $ do
            "This is the same mechanism as Day 2's toggles, written down. "
            k "D"
            " is "
            c ":toggle date"
            ", the option menu is a list of those toggles, and a shorthand setting is the value \
            \that a toggle would have cycled to. The naming is regular: display options are "
            c "<column>-display"
            ", other options are "
            c "<column>-<option>"
            " — which is why Day 2's graph key was "
            c ":toggle commit-title-graph"
            " rather than "
            c ":toggle graph"
            "."

    block "Widths, and the two that behave oddly" $ do
        defs
            [ (c "width=0", "Size the column to fit its content. The default for most columns.")
            , (c "width=20", "Fixed width, truncated with the truncation delimiter — " <> c "~" <> " by default.")
            , (c "maxwidth=15", "Size to fit, but never wider than this. Accepts " <> c "20%" <> " of the view.")
            ]
        p_ $ do
            "The odd one: on "
            c "author"
            " and "
            c "committer"
            " columns, a "
            c "width"
            " between 1 and 10 does not truncate — it switches the column to initials. So "
            c "author:full,width=8"
            " shows "
            c "ALovelace"
            ", not "
            c "Ada Love"
            ". If you wanted truncation at eight characters, you cannot have it; use "
            c "abbreviated"
            " deliberately instead."
        tip $ p_ $ do
            "Two settings pair naturally with fixed widths. "
            opt "truncation-delimiter"
            " is the character drawn where a column is cut ("
            c "~"
            " by default; the special value "
            c "utf-8"
            " gives you an ellipsis), and "
            opt "horizontal-scroll"
            " decides how far "
            k "Left"
            " and "
            k "Right"
            " move — "
            c "50%"
            " of the view by default, which is usually too much. A plain "
            c "8"
            " is easier to follow."

    block "Today's habit" $ do
        p_ $ do
            "Run "
            c ":save-options /tmp/v"
            " once and keep the file. It is the complete, accurate, version-correct reference for \
            \every setting and binding your tig has — better than any documentation, because it is \
            \the running program describing itself."
        p_ "Tomorrow: the second of tig's three languages, and the one that makes it yours."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Column specifications."
        " The last two lines are the distinction that matters."
    cfg
        [ "set <view>-view = type:display,option=value  type:display  …"
        , "  types    author committer date id commit-title file-name file-size"
        , "           line-number mode ref status text"
        , "  common   width=0 (fit)  width=20 (fixed)  maxwidth=15 or 20%"
        , "  date     default|relative|relative-compact|custom + format= use-author= local="
        , "  author   full|abbreviated|email|email-user   (width 1-10 = initials!)"
        , "  title    graph=v2|v1|no  refs=  overflow=72"
        , "set main-view-date = relative        # SHORTHAND: patches one column"
        , "set main-view = date:relative …      # FULL LIST: replaces all the others"
        ]
