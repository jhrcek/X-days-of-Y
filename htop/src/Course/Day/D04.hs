module Course.Day.D04 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 4
        , dayTitle = "Finding a process"
        , daySubtitle = "Search moves the selection, filter changes the list — and confusing the two wastes an afternoon."
        , dayMinutes = 30
        , dayLevel = "essential"
        , dayManRef = "INTERACTIVE COMMANDS, COMMAND-LINE OPTIONS"
        , dayTags = ["search", "filter", "users"]
        , dayGoals =
            [ "choose between search, filter, the user menu and a PID jump without thinking"
            , "spot from the function bar alone that a filter is still narrowing your list"
            , "start htop already pointed at the processes you came for"
            ]
        , dayDiagram = Just d4diagram
        , dayBody = body
        , dayKeys =
            [ ("F3 /", "Incremental search: move the selection to the next match. Does not hide anything.")
            , ("F3", "While searching: jump to the next match. " <> k "Shift-F3" <> " goes backwards.")
            , ("F4 \\", "Incremental filter: hide every row that does not match.")
            , ("Enter", "In the filter prompt: keep the filter and put the prompt away.")
            , ("Esc", "In the filter prompt: clear the filter. In search: cancel it.")
            , ("u", "Open the user menu and show only one user's processes.")
            , ("Digits", "Type a PID and the selection jumps to it. Silently — there is no prompt.")
            ]
        , dayCmds =
            [ ("htop -F chrome", "Start with the filter already applied. Multiple terms: " <> c "-F 'nginx|php'" <> ".")
            , ("htop -p 1,843", "Show only these PIDs, and nothing else ever appears.")
            , ("htop -u", "Show only your own processes.")
            , ("htop -u postgres", "Show one user's processes. A numeric UID works too.")
            ]
        , dayOpts = []
        , dayConfig = []
        , dayDrills =
            [ "Press "
                <> k "/"
                <> ", type three letters of something you know is running, and watch the selection \
                   \jump while the list stays exactly as long as it was. Press "
                <> k "F3"
                <> " a few times to walk the matches."
            , "Now press "
                <> k "\\"
                <> " and type the same three letters. This time the list collapses. Say out loud \
                   \which of the two you actually wanted."
            , "With the filter still typed, press "
                <> k "Enter"
                <> ". The prompt disappears. Find the only thing on screen that still tells you \
                   \the filter is on — it is on the function bar, and it is a change of case."
            , "Break something on purpose: with no prompt open, type "
                <> c "sshd"
                <> " as if it were a search box. The "
                <> k "s"
                <> " attaches strace to whatever was selected. Press "
                <> k "Esc"
                <> " and reflect on why the manual page says “for the first character normal key \
                   \bindings take precedence”."
            , "Type the digits of a PID you can see on screen — no prefix key, just the digits. \
              \The selection jumps there with no prompt and no feedback at all."
            , "Filter for "
                <> c "chrome"
                <> " and count the rows. Now filter for "
                <> c "chrome|systemd"
                <> ". Fixed strings only: try "
                <> c "chr.*me"
                <> " and watch it match nothing, because the "
                <> c "."
                <> " and "
                <> c "*"
                <> " are literal characters."
            , "On your own machine: work out the "
                <> c "htop"
                <> " invocation that would have saved you the most time last week — "
                <> c "htop -u postgres"
                <> ", "
                <> c "htop -F myapp"
                <> ", "
                <> c "htop -p $(pgrep -d, nginx)"
                <> " — and put it in your shell aliases before you forget."
            , "Adopt the habit: when htop “is not showing a process you know is running”, check the \
              \function bar for a stuck filter before you check anything else. It is the answer \
              \more often than not."
            ]
        , dayQuiz =
            [
                ( "You filter for "
                    <> c "postgres"
                    <> ", press "
                    <> k "Enter"
                    <> ", get distracted, and come back twenty minutes later convinced that every \
                       \other process on the box has died. What happened, and what is the one \
                       \pixel that would have told you?"
                , do
                    p_ $ do
                        k "Enter"
                        " means “keep this filter and put the prompt away”, not “cancel”. The \
                        \prompt line vanishes and the ordinary function bar comes back, so the \
                        \screen looks entirely normal — it is just showing you four rows."
                    p_ $ do
                        "The tell is the case of one label: the bar reads "
                        c "F4FILTER"
                        " in capitals while a filter is active, and "
                        c "F4Filter"
                        " when it is not. To actually clear it, press "
                        k "F4"
                        " again to reopen the prompt and then "
                        k "Esc"
                        " — which is precisely the sequence the manual page gives, and precisely \
                        \the one nobody reads until this has happened to them."
                )
            ,
                ( "You want to find "
                    <> c "sshd"
                    <> ", so you type "
                    <> c "sshd"
                    <> " at the list. htop attaches strace to a random process instead. Why, and \
                       \what is the rule?"
                , do
                    p_ $ do
                        "Because "
                        k "s"
                        " is bound to “trace syscalls with strace”, and bindings win on the first \
                        \character. htop will fall through to a search only for letters that are \
                        \not bound to anything — and most letters are bound to something."
                    p_ $ do
                        "The rule is simply to press "
                        k "/"
                        " first, always. Typing a name directly works often enough to feel like a \
                        \feature and fails destructively often enough to be a trap: "
                        k "x"
                        " opens file locks, "
                        k "p"
                        " changes your Command column, "
                        k "t"
                        " throws you into tree view, and "
                        k "k"
                        " opens the kill menu."
                )
            ,
                ( "Search and filter both take “part of a command line”. When is search the right \
                  \tool and when is filter?"
                , do
                    p_ $ do
                        b_ "Search"
                        " when you want to "
                        i_ "act on one process"
                        ": it moves the selection and leaves the list intact, so you keep your \
                        \sense of where that process sits relative to everything else — still the \
                        \third-busiest thing on the machine, still below the browser."
                    p_ $ do
                        b_ "Filter"
                        " when you want to "
                        i_ "study a group"
                        ": all eleven Postgres backends, all the containers of one service. You \
                        \lose the context of the whole machine and gain a list you can read \
                        \without scrolling. The giveaway is whether your question has the word \
                        \“all” in it."
                )
            ,
                ( "Your colleague runs "
                    <> c "htop -F nginx"
                    <> " and reports “nginx is using 12 processes”. You run "
                    <> c "htop -p $(pgrep -d, nginx)"
                    <> " and get 8. Who is right?"
                , do
                    p_ $ do
                        "Both, about different questions. "
                        c "-F"
                        " matches the text of the "
                        i_ "command line"
                        ", so it catches anything with “nginx” anywhere in it — a log tailer, an "
                        c "nginx -t"
                        " you left running, a shell whose history happens to contain the word, and \
                        \every thread of every match."
                    p_ $ do
                        c "-p"
                        " takes an explicit list of PIDs, so it shows exactly those and never \
                        \anything else — including never showing new nginx workers that start \
                        \after htop did. "
                        c "-F"
                        " is a live text match; "
                        c "-p"
                        " is a frozen set. Neither is wrong, but only one of them will still be \
                        \telling the truth after a reload."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d4diagram :: Diagram
d4diagram =
    ( diagram
        "Two levels of narrowing: a filter term and a user restriction decide which rows the \
        \visible list contains, while a search term or a typed PID only moves the selection \
        \within whatever rows are already there."
        body'
    )
        { dgCaption = do
            "The four ways of finding something live on two different levels, and that is the \
            \whole lesson. "
            b_ "Filter"
            " and the "
            b_ "user menu"
            " change which rows exist; "
            b_ "search"
            " and a typed "
            b_ "PID"
            " only move the selection among the rows that survived. It follows that a search can \
            \never find a row the filter has already removed — which is why “htop cannot find my \
            \process” is usually a filter you forgot about, not a process that is missing."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  all   [label=\"every task\\non the machine\", fillcolor=\"#f4efe6\"];\n\
        \  vis   [label=\"the visible list\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  filt  [label=\"a filter term\"];\n\
        \  usr   [label=\"a user restriction\"];\n\
        \  sel   [label=\"the selection\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \  srch  [label=\"a search term\"];\n\
        \  pid   [label=\"a typed PID\"];\n\
        \\n\
        \  vis -> all  [label=\"  is a subset of\"];\n\
        \  vis -> filt [label=\"  is narrowed by\"];\n\
        \  vis -> usr  [label=\"  is narrowed by\"];\n\
        \  sel -> vis  [label=\"  picks one row of\"];\n\
        \  sel -> srch [label=\"is moved by  \", style=dashed, constraint=false];\n\
        \  sel -> pid  [label=\"  is moved by\", style=dashed, constraint=false];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "Two levels, four keys" $ do
        p_ [class_ "lede"] $ do
            "htop gives you four ways to find a process and they sit on two different levels. "
            b_ "Filter and the user menu change which rows exist. Search and a typed PID only move \
                \the selection."
            " Almost every complaint about htop's searching comes from reaching for one when you \
            \meant the other."
        p_ $ do
            "The distinction matters more than it sounds, because the two compose in one direction \
            \only. A filter removes rows, and a search cannot then find them — so a stale filter \
            \makes processes genuinely invisible, while a stale search does nothing at all."
        fig
        why $ p_ $ do
            "Both exist because htop is answering two different questions that happen to take the \
            \same input. “Where is my process, relative to everything else on this box?” needs the \
            \whole list kept intact, with the selection moved — that is search. “Show me these \
            \eleven things and nothing else” needs everything else gone — that is filter. A single \
            \mechanism would have to sacrifice one of the two."

    block "Search: the selection moves, the list does not" $ do
        p_ $ do
            k "F3"
            " or "
            k "/"
            " opens an incremental search over command lines. The selection moves to the first \
            \match as you type, and the list underneath is untouched — same rows, same order, same \
            \length."
        termWin
            "htop — searching"
            [ "  PID USER       PRI  NI  VIRT   RES  PRIV S  CPU%\9661MEM%   TIME+  Command"
            , " 8268 jhrcek      20   0 1454G  422M  251M S   0.9  0.7  1:36.09 chrome --type=re"
            , " 5435 jhrcek       5 -15 12.6G  346M     0 S   0.5  0.5  0:23.78 gnome-shell"
            , " 5455 jhrcek      20   0 12.6G  346M     0 S   0.5  0.5  0:07.88 gnome-shell"
            , "F3Next  S-F3Prev   EscCancel    Search: chrome"
            ]
        p_ $ do
            "Note that "
            c "gnome-shell"
            " is still on screen: search narrowed nothing. "
            k "F3"
            " walks forward through the matches, "
            k "Shift-F3"
            " walks back, "
            k "Esc"
            " cancels."
        gotcha $ p_ $ do
            "The manual page mentions that you can start a search by simply typing, “although for \
            \the first character normal key bindings take precedence”. That sentence is doing a \
            \lot of work. Type "
            c "sshd"
            " at the list and "
            k "s"
            " attaches "
            c "strace"
            " to whatever happened to be selected. Type "
            c "ptyxis"
            " and you will pass through the path toggle, tree view and the file-locks screen on \
            \the way. Press "
            k "/"
            " first. Always."

    block "Filter: the list shrinks" $ do
        p_ $ do
            k "F4"
            " or "
            k "\\"
            " hides every row that does not match. The matching is "
            b_ "case-insensitive"
            " and uses "
            b_ "fixed strings, not regular expressions"
            " — so "
            c "."
            " and "
            c "*"
            " match themselves and nothing else. Separate alternatives with "
            c "|"
            "."
        sh
            [ "\\chrome              # every process whose command line contains 'chrome'"
            , "\\CHROME              # the same rows; matching is case-insensitive"
            , "\\chrome|ptyxis       # either term"
            , "\\chr.*me             # matches nothing: '.' and '*' are literal"
            ]
        p_ $ do
            "Two keys leave the prompt and they do opposite things. "
            k "Enter"
            " means “keep this filter, hide the prompt”. "
            k "Esc"
            " means “throw the filter away”."
        gotcha $ p_ $ do
            "A filter left on after "
            k "Enter"
            " is close to invisible: the prompt is gone and the ordinary function bar is back. The "
            i_ "only"
            " difference is the case of one label — "
            c "F4FILTER"
            " while a filter is active, "
            c "F4Filter"
            " when it is not. Clearing it means pressing "
            k "F4"
            " to reopen the prompt and then "
            k "Esc"
            ", which is a strange enough gesture that most people restart htop instead."

    block "Whole-user and single-PID shortcuts" $ do
        p_ $ do
            k "u"
            " opens a list of every user with processes on the machine, "
            c "All users"
            " at the top. Move with the arrows, "
            k "Enter"
            " to apply, "
            k "Esc"
            " to back out. It is a narrowing like the filter, not a search."
        p_ $ do
            "Typing "
            b_ "digits"
            " jumps the selection to that PID. There is no prompt, no echo and no confirmation — \
            \the selection simply moves, and if you mistype you land somewhere arbitrary. It is \
            \the fastest route from a PID in a log file to a row on screen, and it is worth knowing \
            \precisely because it gives no feedback: the absence of a prompt is not the absence of \
            \an effect."

    block "Arriving already narrowed" $ do
        p_ "Every one of these has a command-line form, which is usually the better move — you were going to type something anyway."
        defs
            [ (c "htop -F " <> var "term", do "Start filtered. Same semantics as " ; k "F4" ; ": fixed strings, case-insensitive, " ; c "|" ; " for alternatives.")
            , (c "htop -p " <> var "pid,pid", "Show exactly these PIDs. A frozen set — nothing new ever joins it.")
            , (c "htop -u", "Your own processes.")
            , (c "htop -u " <> var "user", "One user's. A numeric UID works, despite what " <> c "--help" <> " implies.")
            ]
        sh
            [ "$ htop -u postgres                 # the database, and nothing else"
            , "$ htop -F 'nginx|php-fpm'          # one stack, live text match"
            , "$ htop -p $(pgrep -d, nginx)       # exactly today's nginx PIDs, frozen"
            ]
        note $ p_ $ do
            c "-F"
            " and "
            c "-p"
            " answer different questions and the difference bites during an incident. "
            c "-F"
            " is a live text match, so workers that start later appear. "
            c "-p"
            " is a fixed list captured when htop started, so a process that restarts under a new \
            \PID silently vanishes from your screen and you watch an empty row instead of the \
            \thing you care about."
        tip $ p_ $ do
            "The manual page documents "
            c "-u"
            " as taking a username "
            i_ "or"
            " a UID, while "
            c "htop --help"
            " only mentions a username. The binary accepts both — "
            c "htop -u 1000"
            " works. When the page and the help disagree, try it."

    block "Today's habit" $ do
        p_ $ do
            "Pick the one thing you look for most often — your app, your database, your build \
            \agent — and write the invocation down as a shell alias today. "
            c "htop"
            " with no arguments is for exploring; "
            c "htop -u postgres"
            " is for working."
        p_ "Tomorrow: sorting and the tree, and why choosing a sort column throws you out of tree view."

cheat :: Html ()
cheat = do
    cfg
        [ "F3  /     search  -- moves the SELECTION, list unchanged"
        , "          F3 next, Shift-F3 previous, Esc cancel"
        , "F4  \\     filter  -- hides non-matching rows"
        , "          Enter = keep it (prompt hides!), Esc = clear it"
        , "u         user menu; Enter applies, Esc cancels"
        , "digits    jump to that PID -- silent, no prompt"
        , ""
        , "filter matching: case-insensitive, FIXED STRINGS (no regex), | separates terms"
        , "filter still on?  the bar reads F4FILTER in caps, F4Filter when off"
        , "never type a name at the list: s=strace  x=locks  p=paths  t=tree  k=kill"
        , ""
        , "htop -F term          start filtered (live text match)"
        , "htop -p 1,843         exactly these PIDs (frozen set)"
        , "htop -u [user|uid]    one user, or yourself"
        ]
