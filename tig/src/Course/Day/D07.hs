module Course.Day.D07 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 7
        , dayTitle = "Options and your first tigrc"
        , daySubtitle = "A setting is the same thing at the prompt and in the file."
        , dayMinutes = 34
        , dayLevel = "intermediate"
        , dayManRef = "tigrc(5) DESCRIPTION, GIT CONFIGURATION, SET COMMAND"
        , dayTags = ["tigrc", "set", "toggles"]
        , dayGoals =
            [ "find where your config file belongs, and know which of the three locations wins"
            , "try a setting at the prompt, then keep it, without ever restarting to test"
            , "read a tig warning and fix the line it names"
            ]
        , dayDiagram = Just d7diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ (":set <name> = <value>", "Change a setting for this session.")
            , (":toggle <name>", "Cycle a setting. " <> c ":toggle diff-context +3" <> " steps by three.")
            , (":source <file>", "Read a config file now. Later lines win over earlier ones.")
            , (":save-options <file>", "Write every current setting and binding to a file.")
            ]
        , dayOpts =
            [ ("mailmap", "Apply " <> c ".mailmap" <> ". Default " <> c "yes" <> ", whatever tigrc(5) says.")
            ]
        , dayConfig = day7config
        , dayDrills =
            [ "Run "
                <> c "tig"
                <> " and type "
                <> c ":set diff-context = 8"
                <> ". Open a diff and confirm. You have changed a setting without a config file."
            , "Type "
                <> c ":save-options /tmp/tig-defaults"
                <> " and read the file. That is every setting and every binding your tig has, with \
                   \the values it is using right now — the most reliable reference there is."
            , "Create "
                <> c "~/.tigrc"
                <> " with today's four lines. Restart tig and confirm the dates are relative."
            , "Break it on purpose: add "
                <> c "set diff-contexts = 5"
                <> " (note the typo) to the file and start tig. Read the "
                <> c "tig warning:"
                <> " line, note that it gives you the file and line number, and note that the rest \
                   \of your config still loaded."
            , "Break it differently: put "
                <> c "set tab-size = 0"
                <> " in the file. tigrc(5) says int values are “a non-negative integer”, so this \
                   \should be fine. Read the warning you get instead."
            , "Add "
                <> c "[tig] mouse = true"
                <> " to your repository's "
                <> c ".git/config"
                <> " and start tig there. Settings work from git config too — which is how you \
                   \make a setting apply to one repository only."
            , "Today's habit: when a toggle is one you press every single time, stop pressing it. \
              \Put it in the file with a comment saying why."
            ]
        , dayQuiz =
            [
                ( "You put "
                    <> c "set main-view-date = relative"
                    <> " in your config, but you have never heard of a "
                    <> c "main-view-date"
                    <> " setting and it is not in the list of variables. Why does it work?"
                , do
                    p_ $ do
                        "It is a shorthand. The real setting is "
                        opt "main-view"
                        ", whose value is a list of column specifications. Appending a column name \
                        \to a view setting addresses that column alone, so "
                        c "main-view-date"
                        " means “the date column of the main view”."
                    p_ $ do
                        "You can watch it happen: set it, then "
                        c ":save-options"
                        " and look at "
                        c "main-view"
                        ". The "
                        c "date:default"
                        " part has become "
                        c "date:relative"
                        " and everything else is untouched. Day 11 is this mechanism in full."
                )
            ,
                ( "tigrc(5) says "
                    <> opt "mailmap"
                    <> " is off by default. You have never configured it, and author names in your \
                       \repository are visibly being rewritten by "
                    <> c ".mailmap"
                    <> ". Who is wrong?"
                , do
                    p_ $ do
                        "The manual page. On 2.6.1 the built-in default is "
                        c "yes"
                        " — confirmed by starting tig with the system config disabled entirely and \
                        \dumping the settings, which reports "
                        c "set mailmap = yes"
                        "."
                    p_ $ do
                        "This is the general lesson for the rest of the course: when tigrc(5) and \
                        \the binary disagree, "
                        c ":save-options"
                        " settles it in five seconds. Day 14 lists the other disagreements found \
                        \while writing this."
                )
            ,
                ( "You have a line in "
                    <> c "~/.tigrc"
                    <> " with a typo. What happens to the rest of the file?"
                , do
                    p_ $ do
                        "It still loads. tig reports each bad line individually as "
                        c "tig warning: <file>:<line>: <message>"
                        ", then a summary line, and carries on. A broken config does not give you a \
                        \broken tig — it gives you a tig missing one setting."
                    p_ $ do
                        "That is convenient and easy to miss, because the warnings scroll past \
                        \before the first view draws. "
                        c "tig 2>&1 | head"
                        " is the way to read them deliberately after editing the file."
                )
            ,
                ( "Your colleague's settings live in "
                    <> c "~/.config/tig/config"
                    <> " and yours in "
                    <> c "~/.tigrc"
                    <> ". You copy their file to your machine and nothing changes. Why?"
                , do
                    p_ $ do
                        "Because tig reads one user file, not both, and the rule is positional. If "
                        c "$XDG_CONFIG_HOME"
                        " is set it reads "
                        c "$XDG_CONFIG_HOME/tig/config"
                        ". Otherwise it reads "
                        c "~/.config/tig/config"
                        " if that file exists, and falls back to "
                        c "~/.tigrc"
                        " only if it does not."
                    p_ $ do
                        "So creating the XDG file silently retires your "
                        c "~/.tigrc"
                        ". Keep one or the other, and if you need to know which tig actually read, \
                        \set "
                        c "TIGRC_USER"
                        " explicitly."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

day7config :: [ConfBlock]
day7config =
    [ ConfBlock
        "Case-insensitive searching until you type a capital letter, which is what you meant\n\
        \nearly every time. tig's default is fully case-sensitive."
        "set ignore-case = smart-case"
    , ConfBlock
        "Three lines of context is rarely enough to tell which function a change sits in.\n\
        \Five usually is, and ] still widens further when a particular diff needs it."
        "set diff-context = 5"
    , ConfBlock
        "When reading history the question is almost always how long ago, not on which\n\
        \Tuesday. D still cycles to an absolute date when you need to quote one."
        "set main-view-date = relative"
    , ConfBlock
        "Stop at the ends of a view rather than silently wrapping to the top, so that\n\
        \walking search results with n terminates instead of looping."
        "set wrap-search = no"
    ]

-- ---------------------------------------------------------------------------

d7diagram :: Diagram
d7diagram =
    ( diagram
        "Where settings come from: the system tigrc, the user config file chosen from three \
        \locations, and git configuration all feed the same settings, which the prompt and the \
        \option menu can also change for the current session only."
        body'
    )
        { dgCaption = do
            "Four sources, one destination. The distinction that matters is the dashed one: the \
            \prompt and the option menu change "
            b_ "this session"
            " and forget. A setting only survives the process if it is in a file, which is why the \
            \workflow is always “try it at the prompt, then keep it”."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  sys  [label=\"the system tigrc\\n{sysconfdir}/tigrc\", fillcolor=\"#f4efe6\"];"
            , "  usr  [label=\"the user config file\\n$XDG_CONFIG_HOME/tig/config\\n~/.config/tig/config\\n~/.tigrc\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  gitc [label=\"git configuration\\n[tig] name = value\", fillcolor=\"#f4efe6\"];"
            , "  set  [label=\"a setting\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  sess [label=\"this session's value\\n(forgotten on quit)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , "  pr   [label=\"the prompt\\n:set  :toggle\"];"
            , "  menu [label=\"the option menu\\n(o)\"];"
            , "  view [label=\"what you see\"];"
            , ""
            , "  sys  -> set  [label=\"  supplies\"];"
            , "  usr  -> set  [label=\"  overrides with\"];"
            , "  gitc -> set  [label=\"  also supplies\"];"
            , "  set  -> sess [label=\"  initialises\"];"
            , "  pr   -> sess [label=\"  changes\", style=dashed];"
            , "  menu -> sess [label=\"  changes\", style=dashed];"
            , "  sess -> view [label=\"  determines\"];"
            , ""
            , "  { rank=same; sys; usr; gitc; }"
            , "  { rank=same; pr; menu; }"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "You have been configuring tig for six days" $ do
        p_ [class_ "lede"] $ do
            "Every toggle you have pressed — "
            k "D"
            ", "
            k "A"
            ", "
            k "]"
            ", "
            k "W"
            " — changed a setting. The only thing a config file adds is that the change survives \
            \quitting. That is the whole idea, and it means you never have to guess what a setting \
            \does: try it at the prompt, keep it if you like it."
        p_ "The three forms are the same thing written three ways:"
        cfg
            [ "# at the prompt, for this session"
            , ":set diff-context = 5"
            , ""
            , "# in ~/.tigrc, for every session"
            , "set diff-context = 5"
            , ""
            , "# in git config, for this repository or globally"
            , "[tig] diff-context = 5"
            ]
        fig

    block "Where the file goes, and which one wins" $ do
        p_ $ do
            "tig reads a system file first and then exactly "
            b_ "one"
            " user file, chosen by this rule:"
        steps
            [ do
                "If "
                c "$XDG_CONFIG_HOME"
                " is set, read "
                c "$XDG_CONFIG_HOME/tig/config"
                "."
            , do
                "Otherwise, if "
                c "~/.config/tig/config"
                " exists, read that."
            , do
                "Otherwise read "
                c "~/.tigrc"
                "."
            ]
        gotcha $ p_ $ do
            "Note the middle step: creating "
            c "~/.config/tig/config"
            " silently retires your "
            c "~/.tigrc"
            ". tig does not merge them and does not warn you. If you have ever wondered why a \
            \setting stopped applying after you tidied your dotfiles, that is why. "
            c "TIGRC_USER=/path/to/file"
            " forces the question closed."
        p_ $ do
            "This course writes to "
            c "~/.tigrc"
            " because it is the name tigrc(5) uses throughout. If you prefer the XDG location, use \
            \it consistently and keep only one."
        note $ p_ $ do
            "There is also a system-wide file, and on this machine it is worth a look: it re-states \
            \most of the built-in defaults explicitly. Disabling it entirely with "
            c "TIGRC_SYSTEM="
            " produced a byte-identical settings dump, so on 2.6.1 it is documentation rather than \
            \policy — but on a distribution that has customised it, that is where a surprising \
            \default comes from."

    block "Settings from git config, and when to use them" $ do
        p_ $ do
            "Anything you can set in "
            c "~/.tigrc"
            " can live in git configuration instead, under a "
            c "[tig]"
            " section:"
        cfg
            [ "[tig]"
            , "        show-changes = true"
            , "        tab-size = 4"
            , "[tig \"color\"]"
            , "        cursor = yellow red bold"
            , "[tig \"bind\"]"
            , "        generic = P parent"
            ]
        p_ $ do
            "The reason to care is scope. Git config is per repository when it is in "
            c ".git/config"
            ", so this is how you say “in this one repository, with its eight-space tabs and its \
            \enormous history, do things differently”. Everything else belongs in "
            c "~/.tigrc"
            "."
        p_ $ do
            "tig also reads a handful of ordinary git settings and honours them: "
            c "core.abbrev"
            " for the width of commit IDs, "
            c "core.editor"
            " for "
            k "e"
            ", "
            c "gui.encoding"
            " for file contents, and your "
            c "color.*"
            " settings, which Day 14 comes back to."

    block "The syntax, in one screen" $ do
        p_ "tigrc(5) has four commands. You meet the first today and the rest over the next week."
        defs
            [ (c "set " <> var "name" <> " = " <> var "value", "A setting. " <> c "+=" <> " appends to a string one.")
            , (c "bind " <> var "keymap" <> " " <> var "key" <> " " <> var "action", "A key binding. Day 12.")
            , (c "color " <> var "area" <> " " <> var "fg" <> " " <> var "bg" <> " [" <> var "attrs" <> "]", "A colour rule. Day 14.")
            , (c "source " <> var "path", "Read another file here. " <> c "-q" <> " to ignore a missing one.")
            ]
        p_ $ do
            "Comments start with "
            c "#"
            " and run to end of line. A line ending in a backslash continues onto the next, which \
            \is how the long column specifications on Day 11 stay readable. Values may be quoted \
            \with "
            c "'"
            " or "
            c "\""
            " when they contain spaces."
        p_ $ do
            "Types are "
            c "bool"
            ", "
            c "int"
            ", "
            c "string"
            " and "
            c "mixed"
            ". For booleans, "
            c "1"
            ", "
            c "true"
            " and "
            c "yes"
            " are true and "
            b_ "anything else is false"
            " — so a typo in a boolean value silently turns the setting off rather than reporting \
            \an error."
        gotcha $ p_ $ do
            "tigrc(5) says an int is “a non-negative integer”. It is not that simple: "
            c "set tab-size = 0"
            " is rejected with “Value must be between 1 and 1024”. Bounds exist and are not \
            \documented per setting, so when a value is refused, read the warning — it tells you \
            \the range."

    block "When something is wrong with the file" $ do
        p_ "tig reports config problems and then carries on. A file with two bad lines gives you:"
        sh
            [ "$ tig 2>&1 | head"
            , "tig warning: /home/you/.tigrc:1: Unknown option name: bogus-option"
            , "tig warning: /home/you/.tigrc:2: Value must be between 1 and 1024"
            , "tig warning: Errors while loading /home/you/.tigrc."
            ]
        p_ $ do
            "File, line number, and what was wrong. The rest of the file still applied. Because \
            \these scroll past before the first view draws, "
            c "tig 2>&1 | head"
            " after every edit is a habit worth having — it is the only reliable way to notice that \
            \one of your forty lines stopped working after an upgrade."
        tip $ p_ $ do
            "Two prompt commands make editing the file pleasant. "
            c ":source ~/.tigrc"
            " re-reads it without restarting, so you can edit in one terminal and reload in \
            \another. And "
            c ":save-options /tmp/now"
            " dumps every setting and binding currently in effect — the fastest way to find out \
            \what a setting is actually called, or what its real default is."

    block "Your first four lines" $ do
        p_ $ do
            "The rule for this file, from here to Day 14: "
            b_ "never add a line you cannot defend."
            " Not “everyone sets this”. If you cannot say what it does and why you want it, leave \
            \it out — you can always add it in a month when the need is real."
        p_ "Four lines you have earned over the last six days:"

    block "Today's habit" $ do
        p_ $ do
            "For the rest of the course, when you find yourself pressing the same toggle every \
            \time you open tig, stop and write it down instead, with a comment saying why. That \
            \comment is what stops the file becoming something you are afraid to touch."
        p_ "Tomorrow: the views that follow a file rather than a commit."

cheat :: Html ()
cheat = do
    p_ $ do
        b_ "Configuration, compressed."
        " The workflow is always: try at the prompt, then keep."
    cfg
        [ ":set name = value      # this session only"
        , ":toggle name [+N|-N]   # cycle, or step a number"
        , "set name = value       # in the file, forever"
        , "[tig] name = value     # in git config; .git/config = this repo only"
        , "# file: $XDG_CONFIG_HOME/tig/config, else ~/.config/tig/config, else ~/.tigrc"
        , "# ONE of those, not all three — creating the XDG one retires ~/.tigrc"
        , ":source ~/.tigrc       # reload without restarting"
        , ":save-options /tmp/x   # every live setting and binding: the real reference"
        , "tig 2>&1 | head        # read the 'tig warning:' lines after every edit"
        ]
