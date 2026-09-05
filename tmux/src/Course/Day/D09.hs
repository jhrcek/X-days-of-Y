module Course.Day.D09 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
  Day
    { dayNum = 9
    , dayTitle = "Formats"
    , daySubtitle = "The little expression language that runs the status line, filters and conditionals."
    , dayMinutes = 40
    , dayLevel = "advanced"
    , dayManRef = "FORMATS"
    , dayTags = ["#{}", "conditionals", "filters"]
    , dayGoals =
        [ "read any #{…} expression you meet in someone else's config"
        , "write conditionals, comparisons, string surgery and loops inside a format"
        , "use formats as filters, as conditions, and as a way to query the server"
        ]
    , dayDiagram = Just d9diagram
    , dayBody = body
    , dayKeys = []
    , dayCmds =
        [ ("display-message -p '#{…}'", "Evaluate a format and print it. The " <> c "echo" <> " of tmux.")
        , ("display-message -a", "List every format variable with its current value.")
        , ("display-message -v '#{…}'", "Show how the format is parsed, step by step.")
        , ("list-panes -f '#{…}'", "Filter a listing by a format that evaluates true.")
        , ("if-shell -F '#{…}' cmd", "Run a command when a format is non-empty and non-zero.")
        , ("set-option -F name '#{…}'", "Expand the format now and store the result.")
        ]
    , dayOpts =
        [ ("pane-border-format", "What is drawn on a pane's border line.")
        , ("pane-border-status", "Where that line goes: " <> c "off" <> ", " <> c "top" <> ", " <> c "bottom" <> ".")
        , ("automatic-rename-format", "The format used to rename windows automatically.")
        ]
    , dayConfig = day9config
    , dayDrills =
        [ "Run " <> c "tmux display -p -a | less" <> " and read the whole list once. It is \
          \about 140 lines and it is the real reference — the man page table tells you the \
          \names, this tells you the values here and now."
        , "Print your own coordinates: "
            <> c "tmux display -p '#{session_name}:#{window_index}.#{pane_index} in #{pane_current_path}'"
            <> "."
        , "Write a conditional: "
            <> c "tmux display -p '#{?client_prefix,PREFIX,-}'" <> " — then run it while \
            \holding the prefix down. (You cannot; that is the point of putting it in the \
            \status line instead.)"
        , "Compare and match: "
            <> c "tmux display -p '#{==:#{session_name},main}'" <> " and "
            <> c "tmux display -p '#{m:*api*,#{session_name}}'" <> "."
        , "Do arithmetic: " <> c "tmux display -p '#{e|*|f|2:#{window_width},0.5}'"
            <> " gives half your window width to two decimal places."
        , "Trim and pad: " <> c "tmux display -p '[#{=/10/…:pane_title}] [#{p-12:session_name}]'"
            <> " — one truncates with an ellipsis, the other right-aligns in twelve columns."
        , "Loop: " <> c "tmux display -p '#{W:#{window_index}:#{window_name} ,[#{window_name}] }'"
            <> " prints every window, with the current one in brackets."
        , "Filter a real question: “which panes are running vim?” — "
            <> c "tmux lsp -a -f '#{m:*vim*,#{pane_current_command}}' -F '#{pane_id} #{pane_current_path}'"
            <> "."
        ]
    , dayQuiz =
        [ ( "What does " <> c "#{?#{==:#{pane_current_command},vim},E,-}" <> " evaluate to, and \
            \how do you read it?"
          , do
              p_ $ do
                "Inside out. "
                c "#{pane_current_command}"
                " is the command; "
                c "#{==:x,vim}"
                " compares it with "
                c "vim"
                " and yields 1 or 0; "
                c "#{?cond,then,else}"
                " picks "
                c "E"
                " or "
                c "-"
                ". So: “E if this pane is running vim, otherwise a dash”."
              p_ $ do
                "The nesting is the only hard part of formats. Everything is "
                c "#{"
                " operator "
                c ":"
                " arguments "
                c "}"
                ", and the arguments can themselves be formats."
          )
        , ( "Why does " <> c "#{?session_attached,yes,no}" <> " work, but "
              <> c "#{?#{session_attached},yes,no}" <> " is what you see people write for other \
              \things?"
          , p_ $ do
              "The condition of "
              c "?"
              " is a "
              i_ "variable name"
              " when written bare — tmux checks whether it exists and is non-zero. Wrapping it \
              \in "
              c "#{…}"
              " makes it a nested "
              i_ "expression"
              " instead, which is necessary as soon as the condition is a comparison or a match \
              \rather than a plain variable. Both forms are correct in their place, which is why \
              \real configs contain both."
          )
        , ( "You want a comma inside the “then” branch of a conditional. What breaks and what \
            \fixes it?"
          , p_ $ do
              "A bare comma ends the branch, because "
              c "?"
              " splits on commas. Escape it as "
              c "#,"
              " — and likewise "
              c "#}"
              " for a closing brace and "
              c "##"
              " for a literal "
              c "#"
              ". The man page's own example is "
              c "#{?pane_in_mode,#[fg=white#,bg=red],#[fg=red#,bg=white]}#W"
              ", where the commas inside the style directives have to be escaped."
          )
        , ( "How do you find out what variables exist, without the man page?"
          , p_ $ do
              c "tmux display -p -a"
              " prints every format variable and its current value for the active pane — about \
              \140 of them. "
              c "tmux display -v '#{…}'"
              " traces how an expression is parsed when it is not doing what you expect. \
              \Between those two you rarely need the table in the manual."
          )
        ]
    , dayCheat = cheat
    }

-- ---------------------------------------------------------------------------

d9diagram :: Diagram
d9diagram =
  (diagram
     "A format string is expanded against a target; it contains variables, which may be \
     \modified, compared, made conditional or looped over, producing a string that is used as a \
     \status line, a filter, a condition or a printed value."
     body')
    { dgCaption = do
        "Formats are one language with four jobs. The same "
        c "#{…}"
        " string that draws your status line can be handed to "
        c "-f"
        " as a filter (is it non-zero?), to "
        c "if-shell -F"
        " as a condition, or to "
        c "display -p"
        " to be printed. Learning it once pays four times."
    , dgRankdir = "TB"
    , dgRanksep = "0.45"
    }
  where
    body' =
      T.unlines
        [ "  fmt  [label=\"a format string\\n'#{?a,b,c}'\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  tgt  [label=\"a target\\n(pane, window,\\nsession, client)\", fillcolor=\"#f4efe6\"];"
        , "  vars [label=\"format variables\\n#{pane_current_command}\\n#{session_name}  #S\"];"
        , "  mods [label=\"modifiers\\n?  ==  m  e|  =N  p  t  b  d  s///  E  W:\"];"
        , "  out  [label=\"a string\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
        , "  st   [label=\"a status line\", fillcolor=\"#f4efe6\"];"
        , "  filt [label=\"a filter\\n(-f: keep if non-zero)\", fillcolor=\"#f4efe6\"];"
        , "  cond [label=\"a condition\\n(if-shell -F, %if)\", fillcolor=\"#f4efe6\"];"
        , "  pr   [label=\"printed output\\n(display -p)\", fillcolor=\"#f4efe6\"];"
        , ""
        , "  tgt  -> vars [label=\"  supplies\"];"
        , "  vars -> fmt  [label=\"  appear in\"];"
        , "  mods -> fmt  [label=\"  transform\"];"
        , "  fmt  -> out  [label=\"  expands to\"];"
        , "  out -> st; out -> filt; out -> cond; out -> pr;"
        , "  { rank=same; st; filt; cond; pr; }"
        ]

-- ---------------------------------------------------------------------------

day9config :: [ConfBlock]
day9config =
  [ ConfBlock
      "Label each pane on its own border with its index and what is running in it. The whole\n\
      \label is a format, so it can react: the zoom marker only appears when it applies."
      "set -wg pane-border-format \" #{pane_index}: #{pane_current_command}#{?pane_zoomed_flag, [zoom],} \"\n\
      \set -wg pane-border-status top"
  , ConfBlock
      "The name tmux gives an unnamed window. The default is just the command; adding the\n\
      \directory makes three shells distinguishable at a glance."
      "set -wg automatic-rename-format \"#{pane_current_command}:#{b:pane_current_path}\""
  ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
  block "One language, four jobs" $ do
    p_ [class_ "lede"] $ do
      "A format is a string with "
      c "#{…}"
      " holes in it. tmux expands it against a target — usually the active pane and everything \
      \reachable from it — and hands the result to whatever asked. The status line is a format. \
      \A "
      c "-F"
      " listing is a format. A "
      c "-f"
      " filter is a format that is treated as a boolean. So is the condition of "
      c "%if"
      " in your config, and of "
      c "if-shell -F"
      "."
    p_ $ do
      "That is why this day is worth forty minutes: it is the last general-purpose thing to \
      \learn in tmux. Everything after it is application."
    fig

  block "Variables" $ do
    p_ $ do
      "About 140 of them exist. A few have single-letter aliases that you will meet in every \
      \status line you read:"
    ascii
      [ "  #S  session_name       #I  window_index     #P  pane_index"
      , "  #W  window_name        #F  window_flags     #D  pane_id"
      , "  #T  pane_title         #H  host             #h  host_short"
      , ""
      , "  ##  a literal #        #,  a literal ,      #}  a literal }"
      ]
    p_ "The ones you will reach for over and over:"
    defs
      [ (c "pane_current_command", "what is running in the pane right now")
      , (c "pane_current_path", "its working directory — the one that makes " <> c "-c" <> " useful")
      , (c "client_prefix", "1 while the prefix has been pressed and tmux is waiting")
      , (c "window_zoomed_flag" <> ", " <> c "window_panes", "state worth showing in a status line")
      , (c "session_attached" <> ", " <> c "session_windows", "for choosing what to display per session")
      , (c "pane_in_mode" <> ", " <> c "pane_mode", "whether this pane is in copy mode, and which")
      ]
    tip $ p_ $ do
      "Do not memorise the table. "
      c "tmux display -p -a"
      " prints every variable with its current value, which is both the reference and the \
      \experiment. When something is not doing what you expect, "
      c "tmux display -v '#{…}'"
      " traces the parse."

  block "Conditionals and comparisons" $ do
    p_ $ do
      "The workhorse is "
      c "#{?condition,then,else}"
      ". The condition is a variable name if written bare, or a nested "
      c "#{…}"
      " expression otherwise. It is true when it exists and is neither empty nor zero."
    sh
      [ "$ tmux display -p '#{?session_attached,attached,detached}'"
      , "$ tmux display -p '#{?window_zoomed_flag,ZOOM,}'"
      , "$ tmux display -p '#{?#{==:#{pane_current_command},vim},editing,shell}'"
      ]
    p_ "Comparisons and logic are prefix operators with a colon:"
    ascii
      [ "  #{==:a,b}   #{!=:a,b}   #{<:a,b}  #{>:a,b}  #{<=:a,b}  #{>=:a,b}"
      , "  #{||:a,b}   #{&&:a,b}   #{!:a}    #{!!:a}   -- boolean, and canonicalise to 1/0"
      , "  #{m:pattern,string}     -- glob match;  #{m/r:re,s} regex;  #{m/ri:…} ignore case"
      , "  #{C:pattern}            -- search the pane's content; 0 or the line number"
      , "  #{e|+|:2,3}             -- arithmetic: + - * / m  and comparisons"
      , "  #{e|*|f|2:3.5,2}        -- f = floating point, 2 = decimal places"
      ]
    gotcha $ p_ $ do
      "Inside a conditional, a literal comma or closing brace has to be escaped as "
      c "#,"
      " and "
      c "#}"
      ", because those characters delimit the branches. This bites hardest when you put a "
      c "#[fg=red,bg=white]"
      " style inside a conditional — the comma in the style needs escaping, giving the \
      \famously unreadable "
      c "#[fg=red#,bg=white]"
      "."

  block "String surgery" $ do
    p_ "Modifiers go before the variable, separated by a colon. They compose, separated by \
       \semicolons."
    defs
      [ (c "#{=10:pane_title}", "first 10 characters; " <> c "#{=-10:…}" <> " the last 10")
      , (c "#{=/10/…:pane_title}", "the same, appending " <> c "…" <> " if it was trimmed")
      , (c "#{p12:session_name}", "pad to 12 columns; " <> c "#{p-12:…}" <> " pads on the left, \
            \which right-aligns the text")
      , (c "#{n:window_name}", "the length of the value; " <> c "#{w:…}" <> " its display width")
      , (c "#{b:pane_current_path}", "basename; " <> c "#{d:…}" <> " dirname")
      , (c "#{t:window_activity}", "a time value as a string; " <> c "#{t/p:…}" <> " a shorter, \
            \relative form")
      , (c "#{t/f/%H#:%M:window_activity}", "a custom strftime format — note the "
            <> c "#:" <> ", because a bare colon would end the modifier")
      , (c "#{s/old/new/:window_name}", "substitute throughout; the pattern is a regular \
            \expression, and a trailing " <> c "i" <> " ignores case")
      , (c "#{q:pane_current_path}", "shell-quote the value — essential when a format is \
            \interpolated into a command")
      , (c "#{E:status-left}", "expand the value of an option, rather than its name; "
            <> c "#{T:…}" <> " also runs it through strftime")
      , (c "#{l:#{raw}}", "literal — do not expand this at all")
      ]
    sh
      [ "$ tmux display -p '#{=/12/…:pane_title}'"
      , "$ tmux display -p '#{b:pane_current_path}'"
      , "$ tmux display -p '#{t/f/%H#:%M:session_created}'"
      ]

  block "Loops" $ do
    p_ $ do
      c "S:"
      ", "
      c "W:"
      ", "
      c "P:"
      " and "
      c "L:"
      " repeat a format once for every session, window, pane or client. Two comma-separated \
      \formats can be given: the second is used for the current window, active pane or attached \
      \session."
    sh
      [ "$ tmux display -p '#{W:#{window_index}:#{window_name} ,[#{window_name}] }'"
      , "1:edit [run] 3:logs"
      , ""
      , "$ tmux display -p '#{S:#{session_name}(#{session_windows}) }'"
      , "api(4) infra(1) notes(2)"
      ]
    p_ $ do
      "A sort order can be appended — "
      c "#{S/n:…}"
      " by name, "
      c "/i"
      " by index, "
      c "/t"
      " by activity time, with "
      c "/r"
      " to reverse. This is exactly how the default status line builds its window list, which \
      \you can see for yourself with "
      c "tmux show -g status-format"
      "."

  block "Shell output, and the trap in it" $ do
    p_ $ do
      c "#(command)"
      " inserts the last line of a shell command's output. It is how status lines grow load \
      \averages, battery levels and git branches."
    cfg
      [ "set -g status-right \"#(uptime | sed 's/.*load average: //') | %H:%M\""
      ]
    gotcha $ do
      p_ $ do
        b_ "tmux does not wait for these."
        " It uses the previous result while the command runs, refreshing no more than once a \
        \second. A slow command does not block your status line — it just shows stale data."
      p_ $ do
        "It also runs on every status refresh, in the background, forever. A "
        c "#(git status)"
        " in your status line is a subprocess every few seconds for as long as tmux is running. \
        \Keep them cheap, and set "
        opt "status-interval"
        " deliberately (Day 10)."

  block "Formats as questions" $ do
    p_ $ do
      "The part people miss: formats make tmux queryable. Combine "
      c "-f"
      " with "
      c "-F"
      " and you have a small query language over your own workspace."
    sh
      [ "# which panes are running an editor?"
      , "$ tmux lsp -a -f '#{m:*vim*,#{pane_current_command}}' -F '#{pane_id} #{pane_current_path}'"
      , ""
      , "# which windows are zoomed right now?"
      , "$ tmux lsw -a -f '#{window_zoomed_flag}' -F '#{session_name}:#{window_name}'"
      , ""
      , "# which sessions has nobody looked at?"
      , "$ tmux ls -f '#{!:session_attached}' -F '#{session_name}'"
      , ""
      , "# does any pane in this window show an error?"
      , "$ tmux display -p '#{C/ri:error}'"
      ]
    p_ $ do
      "The same expressions work as conditions. In a config file, "
      c "%if \"#{==:#{host},laptop}\""
      " branches on the machine; in a binding, "
      c "if-shell -F '#{window_zoomed_flag}'"
      " branches on state without spawning a shell at all."

cheat :: Html ()
cheat = do
  cfg
    [ "#{var}  #S #I #P #W #F #T #D #H     ##  #,  #}   literal # , }"
    , ""
    , "#{?cond,then,else}       cond is a bare variable, or a nested #{...}"
    , "#{==:a,b}  #{!=:…}  #{<:…}  #{||:a,b}  #{&&:…}  #{!:a}"
    , "#{m:glob,s}  #{m/r:re,s}  #{C:pattern}   match / search pane content"
    , "#{e|+|:2,3}  #{e|*|f|2:3.5,2}           arithmetic, f = float"
    , ""
    , "#{=10:v} #{=/10/…:v}  truncate    #{p12:v} #{p-12:v}  pad / right-align"
    , "#{b:v} #{d:v}  base/dirname       #{n:v} #{w:v}  length / width"
    , "#{t:v} #{t/p:v} #{t/f/%H#:%M:v}   times (escape the colon as #:)"
    , "#{s/a/b/:v}  substitute           #{q:v}  shell-quote   #{E:opt}  expand option"
    , "#{W:fmt,curfmt}  #{S:…} #{P:…} #{L:…}     loops (+ /n /i /t /r sort)"
    , "#(shell cmd)     last line of output, cached, never blocking"
    , ""
    , "tmux display -p -a          # every variable and its value — the real reference"
    , "tmux lsp -a -f '…' -F '…'   # formats as a query language"
    ]
