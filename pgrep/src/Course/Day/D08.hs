module Course.Day.D08 (day) where

import Course.Markup
import Course.Types
import Data.Text qualified as T
import Lucid

day :: Day
day =
    Day
        { dayNum = 8
        , dayTitle = "Cgroups and namespaces"
        , daySubtitle = "A name is the weakest identity a process has left."
        , dayMinutes = 35
        , dayLevel = "advanced"
        , dayManRef = "OPTIONS (--cgroup, --ns, --nslist, --env)"
        , dayTags = ["cgroup v2", "namespaces", "--env"]
        , dayGoals =
            [ "tell two identical-looking processes apart by where they live rather than what they are called"
            , "select by cgroup, and say why a parent slice matches nothing"
            , "recognise the two ways " <> c "--ns" <> " and " <> c "--nslist" <> " will quietly give you the wrong answer"
            ]
        , dayDiagram = Just d8diagram
        , dayBody = body
        , dayKeys = []
        , dayCmds =
            [ ("cut -d: -f3 /proc/PID/cgroup", "The cgroup v2 path " <> c "--cgroup" <> " wants, exactly as it wants it.")
            , ("systemctl status PID", "Which unit a PID belongs to — the reverse lookup " <> c "--cgroup" <> " does not offer.")
            , ("ls -l /proc/PID/ns", "The namespace identities a process is confined by.")
            ]
        , dayOpts =
            [ ("--cgroup", "Match on cgroup v2 path. The whole path, leading slash included. A comma list.")
            , ("--ns PID", "Match processes sharing all of this PID's namespaces. Needs root to be correct.")
            , ("--nslist", "Restrict which namespaces " <> c "--ns" <> " compares. Broken for lists of more than one.")
            , ("--env NAME=VALUE", "Match on an environment variable, or just " <> c "NAME" <> " for its presence. Undocumented.")
            ]
        , dayConfig = []
        , dayDrills =
            [ "Read your own: " <> c "cut -d: -f3 /proc/self/cgroup" <> ". That string, verbatim and with its leading slash, is what " <> c "--cgroup" <> " matches."
            , "Select by it: " <> c "pgrep --cgroup \"$(cut -d: -f3 /proc/self/cgroup)\" -a" <> ". Everything in the same unit as your shell."
            , "Break it three ways: try the basename alone, the path without its leading slash, and the parent slice. All three are exit " <> c "1" <> " with no complaint."
            , "Survey the machine: " <> c "for p in $(pgrep .); do cut -d: -f3 /proc/$p/cgroup 2>/dev/null; done | sort | uniq -c | sort -rn | head" <> ". The " <> c "/" <> " at the top is the kernel threads."
            , "Compare " <> c "pgrep --ns $$ -u root -c ." <> " with " <> c "pgrep -u root -c ." <> " as an ordinary user. The first is 0 and the second is hundreds, and both are on one machine with no containers."
            , "Watch " <> c "--nslist" <> " lose an argument: " <> c "pgrep --ns $$ --nslist net,uts -c ." <> " then " <> c "pgrep --ns $$ --nslist uts,net -c ." <> ". Same list, different answer."
            , "Use " <> c "--env" <> " for something real: " <> c "pgrep --env DISPLAY -a" <> " finds everything with a graphical session, whatever it is called."
            , "Add a cgroup-based recipe for one service you actually run, and note in the comment that the path breaks if the unit is renamed."
            ]
        , dayQuiz =
            [
                ( "You want everything under " <> c "/user.slice/user-1000.slice" <> " and write " <> c "pgrep --cgroup /user.slice/user-1000.slice -a" <> ". Nothing comes back, although hundreds of processes are underneath it. Why?"
                , do
                    p_ $ do
                        opt "--cgroup"
                        " compares the "
                        i_ "whole path"
                        " for equality. It is not a prefix match and not a hierarchy walk, so a process in "
                        c "/user.slice/user-1000.slice/session-2.scope"
                        " does not match its own parent slice. Only processes sitting directly in the named cgroup — usually none, for a slice — qualify."
                    p_ $ do
                        "There is no flag for \"and everything beneath\". Either enumerate the leaves into a comma list, or let systemd do the tree walk: "
                        c "systemctl status user-1000.slice"
                        " prints the whole subtree, and "
                        c "systemd-cgls"
                        " draws it."
                )
            ,
                ( "As an ordinary user on a machine with no containers at all, " <> c "pgrep --ns $$ -c ." <> " returns 102 and every one of them is yours — no root processes, although root's processes are obviously in the same namespaces. What is happening?"
                , do
                    p_ $ do
                        "pgrep compares namespaces by reading the symlinks in "
                        c "/proc/PID/ns/"
                        ", and an unprivileged process cannot read those for a process it does not own. Every root-owned process therefore fails the comparison rather than passing it, and drops out silently."
                    p_ $ do
                        "The manual page's \"Required to run as root to match processes from other users\" is understating it: the failure is not that you get a partial answer, it is that you get a "
                        i_ "confident"
                        " partial answer with no warning. Worse, the error runs the other way too — on the same machine "
                        c "pgrep --ns 1 -c ."
                        " returns 465, including 451 root-owned processes. Use "
                        opt "--ns"
                        " as root or do not use it."
                )
            ,
                ( c "pgrep --ns $$ --nslist net,uts" <> " and " <> c "pgrep --ns $$ --nslist uts,net" <> " return different numbers of processes. What does that tell you?"
                , do
                    p_ $ do
                        "That the list is not being combined at all — only the last entry takes effect. On one machine "
                        c "--nslist net"
                        " returned 104 processes and "
                        c "--nslist uts"
                        " returned 143; "
                        c "--nslist net,uts"
                        " returned 143 and "
                        c "--nslist uts,net"
                        " returned 104, each matching its final element and differing from it only by the handful of processes that started and stopped between the two runs."
                    p_ $ do
                        "So in procps-ng 4.0.7 a multi-name "
                        opt "--nslist"
                        " silently discards everything but the last name. Use one namespace at a time, and if you need two, run the query twice and intersect the results yourself."
                )
            ,
                ( "Two " <> c "node" <> " processes, same user, same command line, both started by systemd. How do you tell which is the staging one?"
                , do
                    p_ $ do
                        "By where it lives or what it was given, since what it is called has run out of information. "
                        c "--cgroup"
                        " separates them if they are different units, which under systemd they will be. "
                        c "--env"
                        " separates them if the difference is configuration, which it usually is: "
                        c "pgrep --env NODE_ENV=staging -a"
                        "."
                    p_ $ do
                        opt "--env"
                        " also takes a bare name, matching any process that has the variable set at all — "
                        c "pgrep --env DISPLAY"
                        " is a decent definition of \"has a graphical session\". Like "
                        opt "-Q"
                        " and "
                        opt "-p"
                        ", it appears only in "
                        c "--help"
                        "."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d8diagram :: Diagram
d8diagram =
    ( diagram
        "A running process has a name, was given an environment, lives in a cgroup v2 path \
        \managed by a systemd unit or container runtime, and is confined by a network \
        \namespace and a PID namespace."
        body'
    )
        { dgCaption = do
            "Five facts, and the amber one is the only one the first seven days could see. On a \
            \machine where the same runtime starts twenty services, "
            b_ "the name distinguishes nothing"
            " — but the cgroup path is unique per unit by construction, and the environment is \
            \where the configuration difference already lives. These are the criteria that work \
            \when everything else has collided."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        T.unlines
            [ "  unit  [label=\"a systemd unit\\nor a container\", fillcolor=\"#f4efe6\"];"
            , "  cg    [label=\"its cgroup v2 path\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  proc  [label=\"a running process\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  env   [label=\"its environment\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];"
            , "  netns [label=\"its network namespace\"];"
            , "  pidns [label=\"its PID namespace\"];"
            , "  name  [label=\"its process name\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];"
            , ""
            , "  proc -> name  [label=\"  has as name\"];"
            , "  proc -> env   [label=\"  was given\"];"
            , "  proc -> cg    [label=\"  lives in\"];"
            , "  cg   -> unit  [label=\"  is managed by\"];"
            , "  proc -> netns [label=\"  is confined by\"];"
            , "  proc -> pidns [label=\"  is confined by\"];"
            ]

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "When the name has stopped meaning anything" $ do
        p_ [class_ "lede"] $ do
            "Everything so far assumes a process can be told apart from its neighbours. On a \
            \machine running twenty services under one runtime that assumption fails completely: \
            \twenty processes called "
            c "node"
            ", same user, same command line, and no query built from Days 1 to 7 can separate \
            \them. What has changed since pgrep was written is that the kernel now records "
            i_ "where"
            " a process lives, and that is unique by construction."
        fig

    block "--cgroup wants the whole path, exactly" $ do
        p_ $ do
            "Under cgroup v2 every process is in exactly one cgroup, and systemd gives each unit \
            \its own. The path is the third colon-separated field of "
            c "/proc/PID/cgroup"
            ":"
        sh
            [ "$ cut -d: -f3 /proc/5489/cgroup"
            , "/user.slice/user-1000.slice/user@1000.service/session.slice/pipewire.service"
            , "$ pgrep --cgroup /user.slice/user-1000.slice/user@1000.service/session.slice/pipewire.service -a"
            , "5489 /usr/bin/pipewire"
            ]
        gotcha $ do
            p_ $ do
                "That is an equality test on the full string, and nothing else works. All three of \
                \these return nothing, with no error and exit "
                c "1"
                ":"
            cfg
                [ "pgrep --cgroup pipewire.service               # the basename"
                , "pgrep --cgroup user.slice/user-1000.slice/... # no leading slash"
                , "pgrep --cgroup /user.slice/user-1000.slice    # a parent slice"
                ]
            p_ $ do
                "The third is the one that catches people. "
                opt "--cgroup"
                " does not descend: a process in a child cgroup does not match its parent, so \
                \asking for a slice gets you only whatever sits directly in it, which for a slice \
                \is nothing at all. There is no recursive form; if you want a subtree, "
                c "systemd-cgls"
                " draws it and "
                c "systemctl status <unit>"
                " lists it."
        tip $ p_ $ do
            "The reverse lookup is the one you want more often and pgrep does not have it: given a \
            \PID, which unit is this? "
            c "systemctl status 5489"
            " answers directly, cgroup path and all. Reach for pgrep when you have the unit and \
            \want the processes, and for systemctl when you have a process and want the unit."

    block "Namespaces, and why yours are probably lying to you" $ do
        p_ $ do
            "A namespace is the other half of container isolation: separate views of the network, \
            \the mount table, the PID numbering, and so on. "
            opt "--ns"
            " takes a PID and matches processes sharing "
            i_ "all"
            " of that process's namespaces — which is how you say \"everything inside the same \
            \container as this\"."
        p_ $ do
            "It also has a precondition that the manual page states in one sentence and that \
            \deserves rather more. Comparing namespaces means reading the symlinks in "
            c "/proc/PID/ns/"
            ", and an unprivileged process cannot read those for processes it does not own. The \
            \result on an ordinary machine with no containers whatsoever:"
        sh
            [ "$ pgrep --ns $$ -c .          # 'same namespaces as my shell'"
            , "102"
            , "$ pgrep --ns $$ -u root -c .  # ...of which root-owned:"
            , "0"
            , "$ pgrep -u root -c .          # root processes actually on this machine:"
            , "451"
            ]
        p_ $ do
            "Every one of those 451 is in the same namespaces as the shell. All of them were \
            \dropped, silently, because pgrep could not read the evidence. Run the comparison the \
            \other way and the error reverses — "
            c "pgrep --ns 1 -c ."
            " returns 465, root's processes included."
        gotcha $ p_ $ do
            b_ "Use --ns as root or do not use it."
            " There is no warning, no partial-result indication and no non-zero status; the answer \
            \simply omits or includes whatever the permissions happened to allow. This is the one \
            \flag in pgrep that can be confidently wrong."

    block "--nslist drops all but the last name" $ do
        p_ $ do
            opt "--nslist"
            " is meant to narrow the comparison: \"same network namespace, never mind the rest\". \
            \One name works as documented. A list does not, and the way it fails is easy to \
            \reproduce:"
        sh
            [ "$ pgrep --ns $$ --nslist net -c ."
            , "104"
            , "$ pgrep --ns $$ --nslist uts -c ."
            , "143"
            , "$ pgrep --ns $$ --nslist net,uts -c ."
            , "143"
            , "$ pgrep --ns $$ --nslist uts,net -c ."
            , "104"
            ]
        p_ $ do
            "The same two namespaces in the other order give a different answer, and each answer \
            \equals whichever name came "
            b_ "last"
            ". The sets agree too, not merely the counts — the only differences are the processes \
            \that started or stopped between the two runs. Repeating the flag behaves the same \
            \way: "
            c "--nslist net --nslist uts"
            " is "
            c "--nslist uts"
            "."
        p_ $ do
            "This is procps-ng 4.0.7 as installed, and it is not mentioned in the manual page, in "
            c "--help"
            ", or in the BUGS section. Treat "
            opt "--nslist"
            " as single-valued: use one namespace, and if you genuinely need two, run the query \
            \twice and intersect the results with "
            c "comm -12"
            "."

    block "--env: the configuration is the identity" $ do
        p_ $ do
            "The flag that earns its place most often is the one that is not documented at all. \
            \Two processes that are identical in every respect pgrep can see are usually \
            \different because of their environment, and "
            opt "--env"
            " matches on it directly:"
        sh
            [ "$ pgrep --env DISPLAY -c .          # anything with a graphical session"
            , "76"
            , "$ pgrep --env NODE_ENV=staging -a   # the staging one, whatever it is called"
            , "4417 node server.js"
            ]
        defs
            [ (c "--env NAME=VALUE", "The variable must be set to exactly that value.")
            , (c "--env NAME", "The variable must be set to anything at all. A presence test.")
            ]
        p_ $ do
            "The presence form is the more useful of the two: "
            c "--env DISPLAY"
            " is a serviceable definition of \"belongs to a graphical session\" — 76 of the 611 \
            \processes on this machine — "
            c "--env container"
            " catches processes systemd-nspawn has marked, and "
            c "--env KUBERNETES_SERVICE_HOST"
            " catches everything running inside a pod. None of that is expressible any other way."
        note $ p_ $ do
            "pgrep reads "
            c "/proc/PID/environ"
            ", which has the same permission rules as everything else here: you can read your own \
            \processes' and root can read everyone's. Note also that this is the environment the \
            \process was "
            i_ "started"
            " with. A process that calls "
            c "setenv"
            " later does not change the file, so "
            opt "--env"
            " reports history rather than current state."

    block "Today's habit" $ do
        p_ $ do
            "When a query cannot separate two processes, stop refining the pattern. The pattern \
            \has no information left in it. Ask instead which unit started them, or what \
            \configuration they were handed — both are recorded, and neither can collide the way \
            \a name does."
        p_ $ do
            "Tomorrow is the last day: the race you cannot win with any of this, and the several \
            \situations in which the right answer is to put pgrep down and use something else."
        cfg
            [ "# Day 8: every process in the same systemd unit as this shell."
            , "pgrep --cgroup \"$(cut -d: -f3 /proc/self/cgroup)\" -a"
            , ""
            , "# Day 8: separate two identical processes by their configuration."
            , "# Note: this is the environment they were STARTED with, not the current one."
            , "pgrep --env NODE_ENV=staging -a"
            ]

cheat :: Html ()
cheat = do
    cfg
        [ "pgrep --cgroup /full/path/to.service  # EXACT path, leading slash, no descent"
        , "#   cut -d: -f3 /proc/PID/cgroup   <- get the path in the form it wants"
        , "#   systemctl status PID           <- the reverse lookup pgrep lacks"
        , ""
        , "pgrep --env NAME=VALUE   # exact match on the STARTING environment"
        , "pgrep --env NAME         # presence test - 'has a DISPLAY', 'is in a pod'"
        , ""
        , "pgrep --ns PID           # same namespaces. ROOT ONLY, or it is silently wrong:"
        , "#   as a user, 'pgrep --ns $$ -u root' returns 0 of 451 real matches."
        , "pgrep --ns PID --nslist net   # ONE namespace only - a list keeps just the LAST"
        ]
