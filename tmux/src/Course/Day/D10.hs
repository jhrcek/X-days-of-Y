module Course.Day.D10 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 10
        , dayTitle = "The status line"
        , daySubtitle = "Styles, ranges, alerts — and a status line that is yours."
        , dayMinutes = 35
        , dayLevel = "advanced"
        , dayManRef = "STATUS LINE, STYLES"
        , dayTags = ["status line", "styles", "alerts"]
        , dayGoals =
            [ "take the status line apart into its five configurable pieces and rebuild it"
            , "write styles confidently: colours, attributes, alignment, and inline #[…] directives"
            , "make windows tell you when something happened in them while you were elsewhere"
            ]
        , dayDiagram = Just d10diagram
        , dayBody = body
        , dayKeys =
            [ ("C-b M-n", "Go to the next window with an alert.")
            , ("C-b M-p", "Go to the previous window with an alert.")
            , ("C-b t", "The clock — which is really " <> c "clock-mode" <> ", styled by " <> opt "clock-mode-colour" <> ".")
            ]
        , dayCmds =
            [ ("refresh-client -S", "Redraw the status line right now.")
            , ("show-options -g status-format", "Read the default status line's own definition.")
            , ("display-menu -T title name key cmd", "Pop up a menu — what the status line's mouse bindings use.")
            ]
        , dayOpts =
            [ ("status", "off, on, or 2–5 for a taller status line.")
            , ("status-position", "top or bottom.")
            , ("status-style", "The base style for the whole line.")
            , ("status-left", "The left segment. A format. " <> b_ "Truncated to 10 columns by default.")
            , ("status-left-length", "How wide the left segment may be. Raise it before anything else.")
            , ("status-right", "The right segment. Also a format, also length-limited (40).")
            , ("status-justify", "Where the window list sits: left, centre, right, absolute-centre.")
            , ("status-interval", "Seconds between redraws. 15 by default; matters if you use " <> c "#()" <> ".")
            , ("window-status-format", "How each window is drawn in the list.")
            , ("window-status-current-format", "How the current one is drawn.")
            , ("window-status-separator", "What goes between them. A space by default.")
            , ("window-status-style", "Style for a window entry; " <> c "-current-" <> ", " <> c "-activity-" <> ", " <> c "-bell-" <> ", " <> c "-last-" <> " variants exist.")
            , ("monitor-activity", "Flag windows where output appeared while you were away.")
            , ("monitor-bell", "Flag windows that rang the terminal bell.")
            , ("monitor-silence", "Flag windows that have been quiet for N seconds.")
            , ("visual-activity", "Show a message instead of (or as well as) ringing the bell.")
            , ("activity-action", "any / none / current / other — which windows count.")
            ]
        , dayConfig = day10config
        , dayDrills =
            [ "Before changing anything, read the default: "
                <> c "tmux show -g status-format"
                <> ". That single option is the whole line, and \
                   \every other status option is interpolated into it."
            , "Discover the length trap: set "
                <> c "status-left"
                <> " to something 30 characters \
                   \long and watch it get cut at 10. Then raise "
                <> opt "status-left-length"
                <> "."
            , "Move it: "
                <> c "tmux set -g status-position top"
                <> ". Live with it for a day — \
                   \with the prompt at the bottom of the screen, a bottom status line is the thing your \
                   \eye lands on least."
            , "Add today's config, reload, and then take it apart: change one colour, "
                <> k "C-b R"
                <> ", look. The feedback loop is under a second, so experiment rather \
                   \than plan."
            , "Turn on monitoring: leave a long build in one window, switch away, and watch the "
                <> c "#"
                <> " flag appear. Then jump straight to it with "
                <> k "C-b M-n"
                <> "."
            , "Prove that the window list is just a format: "
                <> c "tmux display -p '#{W:#{E:window-status-format},#{E:window-status-current-format}}'"
                <> " reproduces it outside the status line."
            , "Add something live to the right: "
                <> c "#(uptime | sed 's/.*load average: //')"
                <> " with "
                <> c "status-interval 5"
                <> ". Then decide whether you actually want a \
                   \subprocess every five seconds forever."
            ]
        , dayQuiz =
            [
                ( "Your " <> c "status-left" <> " is being cut off. Why, and where is the setting?"
                , p_ $ do
                    opt "status-left-length"
                    " defaults to "
                    b_ "10"
                    " — enough for the default "
                    c "[#S] "
                    " and nothing else. "
                    opt "status-right-length"
                    " defaults to 40. These two are the most common cause of “my status line \
                    \configuration does not work”, and neither produces an error."
                )
            ,
                ( "What is the difference between "
                    <> opt "status-style"
                    <> " and a "
                    <> c "#[…]"
                    <> " directive?"
                , p_ $ do
                    opt "status-style"
                    " sets the base style for the whole line. "
                    c "#[…]"
                    " is an inline directive inside a format that changes the style from that point \
                    \onwards. "
                    c "#[default]"
                    " returns to the base. There is also "
                    c "#[push-default]"
                    " / "
                    c "#[pop-default]"
                    ", which redefine what “default” means for a stretch — that is how the built-in \
                    \status line lets a window-status format inherit the right colours in the middle \
                    \of the line."
                )
            ,
                ( "You set "
                    <> opt "monitor-activity"
                    <> " on and now every window is permanently \
                       \flagged. What went wrong?"
                , p_ $ do
                    "Something in those windows is producing output constantly — a log tail, a \
                    \progress spinner, a clock. Activity monitoring means literally “bytes arrived”. \
                    \Use "
                    opt "activity-action"
                    " to narrow which windows count, turn monitoring off for the noisy windows \
                    \specifically ("
                    c "set -w monitor-activity off"
                    " in that window), or switch to "
                    opt "monitor-bell"
                    ", which only fires when a program deliberately rings."
                )
            ,
                ( "What is a " <> c "range=" <> " style directive for?"
                , p_ $ do
                    "It marks a stretch of the status line as clickable. "
                    c "#[range=window|3]"
                    " tells tmux that this text stands for window 3, so a click there fires the "
                    c "Status"
                    " mouse key with that window as the target. It is how the default window list \
                    \responds to clicks, and how a custom status line keeps that behaviour. "
                    c "range=user|X"
                    " gives you an arbitrary tag, readable from the binding as "
                    c "#{mouse_status_range}"
                    "."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d10diagram :: Diagram
d10diagram =
    ( diagram
        "The status line is built from status-format, which interpolates status-left, a window \
        \list built from window-status-format and window-status-current-format, and status-right; \
        \styles and ranges are applied to each part."
        body'
    )
        { dgCaption = do
            "Every option in the middle column is a "
            b_ "format"
            " and every one in the right column is a "
            b_ "style"
            ", which is why Day 9 came first. The top box is the one almost nobody edits — but \
            \reading it ("
            c "tmux show -g status-format"
            ") shows you exactly how the parts are assembled, including the "
            c "list=on"
            " and "
            c "range="
            " markers that make the window list clickable."
        , dgRankdir = "LR"
        , dgRanksep = "0.65"
        , dgNodesep = "0.22"
        }
  where
    body' =
        T.unlines
            [ "  sf   [label=\"status-format[0]\\n(the whole line)\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  sl   [label=\"status-left\"];"
            , "  wl   [label=\"the window list\"];"
            , "  sr   [label=\"status-right\"];"
            , "  wsf  [label=\"window-status-format\"];"
            , "  wscf [label=\"window-status-current-format\"];"
            , "  sty  [label=\"status-style\", fillcolor=\"#f4efe6\"];"
            , "  wsty [label=\"window-status-*-style\\n(current, activity,\\nbell, last)\", fillcolor=\"#f4efe6\"];"
            , "  inl  [label=\"#[fg=… bg=… bold]\\ninline directives\", fillcolor=\"#f4efe6\"];"
            , "  rng  [label=\"#[range=window|3]\\nclickable regions\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  sf -> sl [label=\"  interpolates\"];"
            , "  sf -> wl;"
            , "  sf -> sr;"
            , "  wsf  -> wl [label=\"  draws each window\"];"
            , "  wscf -> wl [label=\"  draws the current one\"];"
            , "  sty  -> sf [label=\"  styles\", style=dashed];"
            , "  wsty -> wl [label=\"  styles\", style=dashed];"
            , "  inl  -> sl [label=\"  restyles mid-string\", style=dashed];"
            , "  rng  -> wl [label=\"  makes clickable\", style=dashed];"
            , "  { rank=same; sl; wl; sr; }"
            ]

-- ---------------------------------------------------------------------------

day10config :: [ConfBlock]
day10config =
    [ ConfBlock
        "Put the status line at the top. Your shell prompt lives at the bottom of the screen,\n\
        \which is exactly where your eyes already are - so the status line competes with it\n\
        \there and is ignored. At the top it is where a title bar would be."
        "set -g status-position top\n\
        \set -g status-justify left\n\
        \set -g status-interval 5"
    , ConfBlock
        "A quiet base: no background of its own, so it borrows the terminal's."
        "set -g status-style \"bg=default,fg=colour245\""
    , ConfBlock
        "Left: the session name, which is the one piece of state you cannot get any other way.\n\
        \Raise the length limit first - it defaults to 10 columns and silently truncates."
        "set -g status-left-length 40\n\
        \set -g status-left \"#[fg=black,bg=green,bold] #S #[default] \""
    , ConfBlock
        "Right: a PREFIX indicator (so a half-pressed prefix is never a mystery), the pane\n\
        \title, and the clock. Note the escaped commas inside the #[...] directive."
        "set -g status-right-length 60\n\
        \set -g status-right \"#{?client_prefix,#[fg=black#,bg=yellow#,bold] PREFIX #[default] ,}\\\n\
        \#[fg=colour245] #{=/20/…:pane_title} %H:%M \""
    , ConfBlock
        "The window list. The current window is inverted; the others are quiet. The zoom flag\n\
        \is spelled out because Z among the other flag characters is easy to miss."
        "set -wg window-status-format \" #I:#W#{?window_flags,#{window_flags}, } \"\n\
        \set -wg window-status-current-format \"#[fg=black,bg=colour250,bold] #I:#W#{?window_zoomed_flag, Z,} \"\n\
        \set -wg window-status-separator \"\""
    , ConfBlock
        "Tell me when something happened in a window I was not looking at, but do not interrupt\n\
        \me with a message about it - the flag in the status line is enough. C-b M-n jumps to\n\
        \the next flagged window."
        "set -wg monitor-activity on\n\
        \set -g  visual-activity off\n\
        \set -g  activity-action other\n\
        \set -wg monitor-bell on\n\
        \set -wg window-status-activity-style \"fg=yellow,bold\"\n\
        \set -wg window-status-bell-style \"fg=red,bold\""
    ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Five pieces and a format" $ do
        p_ [class_ "lede"] $ do
            "The status line looks like a fixed widget and is not. It is a format string in the "
            opt "status-format"
            " option, which interpolates the pieces you actually configure: a left segment, a window \
            \list, a right segment, and the styles for each."
        p_ $ do
            "Read the default before you replace it — "
            c "tmux show -g status-format"
            " — and you will see the assembly, including markers like "
            c "list=on"
            " and "
            c "range=window|…"
            " that make the list scroll sensibly and respond to clicks. You almost never need to edit \
            \that option; you need to know it exists so that the others make sense."
        fig

    block "The two-column trap" $ do
        p_ $ do
            "Before anything else: "
            opt "status-left-length"
            " defaults to "
            b_ "10"
            " and "
            opt "status-right-length"
            " to "
            b_ "40"
            ". Anything longer is silently cut. This is the cause of most “my status line config \
            \does nothing” reports, and it produces no error at all."
        sh
            [ "$ tmux set -g status-left-length 40"
            , "$ tmux set -g status-right-length 60"
            ]

    block "Styles" $ do
        p_ $ do
            "A style is a comma- or space-separated list of terms, used both as option values ("
            opt "status-style"
            ") and inline inside formats ("
            c "#[…]"
            ")."
        ascii
            [ "  fg=colour   bg=colour   us=colour        -- foreground, background, underscore"
            , "  colour names: black red green yellow blue magenta cyan white"
            , "                brightred …   colour0..colour255   #1e1e1e   default   terminal"
            , ""
            , "  bold (bright) dim italics underscore blink reverse hidden strikethrough"
            , "  overline double-underscore curly-underscore dotted-underscore dashed-underscore"
            , "  prefix any of them with 'no' to turn it off;  'none' clears everything"
            , ""
            , "  align=left|centre|right      fill=colour      width=N"
            , "  push-default / pop-default   -- redefine what #[default] means for a stretch"
            , "  range=window|3  range=pane|%7  range=user|tag  -- clickable regions"
            ]
        p_ $ do
            "Inline directives change the style from that point on; "
            c "#[default]"
            " returns to the option's base style. So a segment is usually a sandwich:"
        cfg
            [ "set -g status-left \"#[fg=black,bg=green,bold] #S #[default] \""
            ]
        gotcha $ p_ $ do
            "Inside a conditional, the commas in a style must be escaped, because commas separate the \
            \branches of "
            c "#{?…}"
            ". That is why the PREFIX indicator in today's config reads "
            c "#[fg=black#,bg=yellow#,bold]"
            " — three escapes, and the reason status line configs have a reputation for being \
            \unreadable."

    block "Building one" $ do
        p_ "Here is the target, and then the pieces:"
        termStatus
            "with the status line on top"
            [ ""
            , "$ cargo test"
            , "   Compiling api v0.4.0"
            , ""
            ]
            " api  1:edit 2:run 3:logs# "
            " \"cargo\" 14:22 "
        p_ $ do
            "Left is the session name in reverse video — the one piece of state that is otherwise \
            \invisible. The window list is plain except for the current window, which is inverted, \
            \and window 3 carries a "
            c "#"
            " because something printed there while you were away. Right is the pane title and the \
            \clock, with a "
            c "PREFIX"
            " badge that appears while tmux is waiting for the second half of a key."
        p_ $ do
            "That last one is worth stealing whatever else you do. "
            c "#{?client_prefix,…,…}"
            " removes an entire category of confusion — the “did my prefix register?” pause that \
            \everybody does silently several times a day."

    block "Alerts: making windows speak up" $ do
        p_ "Three kinds of monitoring, each a window option, each producing a flag in the list:"
        defs
            [
                ( opt "monitor-activity"
                , "any output at all. Flag "
                    <> c "#"
                    <> ". Useful, and noisy \
                       \if a window is tailing a log."
                )
            ,
                ( opt "monitor-bell"
                , "the program rang the terminal bell. Flag "
                    <> c "!"
                    <> ". This is \
                       \what a shell does when a long command finishes, if you configure it to."
                )
            ,
                ( opt "monitor-silence 30"
                , "no output for 30 seconds. Flag "
                    <> c "~"
                    <> ". The one for \
                       \“tell me when this build stops printing”."
                )
            ]
        p_ $ do
            "Each has an action ("
            opt "activity-action"
            ", "
            opt "bell-action"
            ", "
            opt "silence-action"
            ") taking "
            c "any"
            ", "
            c "none"
            ", "
            c "current"
            " or "
            c "other"
            " — with "
            c "other"
            " meaning “ignore whatever is happening in the window I am looking at”, which is nearly \
            \always what you want. And each has a "
            c "visual-"
            " option controlling whether you also get a message across the status line."
        p_ $ do
            k "C-b M-n"
            " and "
            k "C-b M-p"
            " jump to the next and previous window carrying an alert. With monitoring on and those \
            \two keys, “start a build, go and do something else, come back when it says so” stops \
            \needing a second terminal."
        tip $ p_ $ do
            "The status line can be more than one row: "
            c "set -g status 2"
            " gives two, each configured by its own "
            opt "status-format"
            " index. Combined with "
            c "align="
            " and "
            c "fill="
            " you can build something genuinely dashboard-like. Whether you should is another matter \
            \— every row is a row not showing your work."

    block "It is clickable, too" $ do
        p_ $ do
            "With the mouse on, clicking a window in the list selects it, and right-clicking opens a \
            \menu. Those are root-table bindings ("
            c "MouseDown1Status"
            ", "
            c "MouseDown3Status"
            ") using the target "
            c "{mouse}"
            ", and they work because the default window list marks each entry with "
            c "#[range=window|…]"
            "."
        p_ $ do
            "If you write your own "
            opt "window-status-format"
            " you keep that behaviour for free — tmux inserts the ranges around the list. Adding "
            c "range=user|something"
            " to your own segments lets you build custom clickable regions, read back in the binding \
            \as "
            c "#{mouse_status_range}"
            ". Day 13 hangs a menu off one."

cheat :: Html ()
cheat = do
    cfg
        [ "status-left-length 40   status-right-length 60   # DO THIS FIRST (10 / 40 by default)"
        , "status-position top|bottom   status-justify left|centre|right   status-interval 5"
        , "status-style / window-status-style / -current-style / -activity-style / -bell-style"
        , "window-status-format / -current-format / window-status-separator"
        , ""
        , "#[fg=red,bg=black,bold]  …  #[default]      # inline; escape commas as #, in a #{?}"
        , "#{?client_prefix,PREFIX,}                   # the badge worth having"
        , "#[range=window|3] … #[norange]              # clickable regions"
        , ""
        , "monitor-activity / monitor-bell / monitor-silence N   -> flags  #  !  ~"
        , "activity-action other      visual-activity off"
        , "C-b M-n / C-b M-p                           # jump to the next / previous alert"
        ]
