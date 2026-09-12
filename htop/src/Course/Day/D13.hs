module Course.Day.D13 (day) where

import Course.Markup
import Course.Types
import Lucid

day :: Day
day =
    Day
        { dayNum = 13
        , dayTitle = "cgroups and containers"
        , daySubtitle = "Ten shortening rules that turn a hundred-character path into something you can read in a column."
        , dayMinutes = 30
        , dayLevel = "advanced"
        , dayManRef = "COLUMNS, INTERACTIVE COMMANDS"
        , dayTags = ["cgroups", "containers", "systemd"]
        , dayGoals =
            [ "read a compressed cgroup path back into the systemd unit or container it came from"
            , "tell which processes belong to a container and hide them when they are noise"
            , "build a screen that groups a machine by service rather than by process"
            ]
        , dayDiagram = Just d13diagram
        , dayBody = body
        , dayKeys =
            [ ("O", "Hide or show processes running in containers. A toggle, off by default.")
            ]
        , dayCmds = []
        , dayOpts =
            [ ("CGROUP", "The full cgroup path. Displayed as " <> c "CGROUP (raw)" <> ", and far too wide to keep on screen.")
            , ("CCGROUP", "The same path, compressed by ten rules. Displayed as " <> c "CGROUP (compressed)" <> ".")
            , ("CONTAINER", "The container's name, guessed by heuristics. Undocumented in the manual page.")
            , ("ISCONTAINER", "Whether the process is inside a child container. Undocumented too.")
            ]
        , dayConfig =
            [ ConfBlock
                "A screen that groups the machine by service rather than by process. CCGROUP is the\n\
                \point of it: on a systemd box that one column turns an unreadable list of PIDs into\n\
                \'which unit is this' at a glance, and it costs about a quarter of the width that\n\
                \the raw CGROUP column would. Sorted by CPU% so the noisy unit surfaces on its own."
                "screen:Containers=PID USER CONTAINER CCGROUP PERCENT_CPU M_RESIDENT Command\n\
                \.sort_key=PERCENT_CPU\n\
                \.sort_direction=-1"
            ]
        , dayDrills =
            [ "Add the "
                <> opt "CCGROUP"
                <> " column to any screen and read down it. On a systemd machine you have just \
                   \gained a “which service is this” column, which the process list never had."
            , "Now add "
                <> opt "CGROUP"
                <> " beside it. Same information, four times the width. Leave them side by side \
                   \for one minute and then delete the raw one forever."
            , "Find a row reading "
                <> c "/[S]/something"
                <> " and translate it back: "
                <> c "/system.slice/something.service"
                <> ". Confirm with "
                <> c "systemctl status something"
                <> "."
            , "Find a row starting "
                <> c "/[U:1000]"
                <> " — or whatever your UID is. That is your user session, and everything below it \
                   \is something you started."
            , "Break something on purpose: press "
                <> k "O"
                <> " on a machine with no containers running. Nothing happens, because nothing \
                   \matched. That is the correct behaviour and it looks exactly like a broken key."
            , "If you have Docker or Podman running, start a container and watch its processes \
              \appear with a "
                <> c "/[lxc:...]"
                <> " or "
                <> c "docker"
                <> "-shaped cgroup path. Press "
                <> k "O"
                <> " to hide them and see how much quieter the host looks."
            , "Sort by "
                <> opt "CCGROUP"
                <> ". The list is now grouped by service, which is close to what you actually \
                   \wanted every time you have squinted at a process list on a server."
            , "On your own machine: work out which systemd unit the process you care about \
              \actually lives in. On a modern box the answer is often not the one you would have \
              \guessed from the command line."
            ]
        , dayQuiz =
            [
                ( "A row's "
                    <> c "CCGROUP"
                    <> " reads "
                    <> c "/[U:1000]/[app]/!app-com.google.Chrome-7575"
                    <> ". Reconstruct the real path and say what each piece meant."
                , do
                    p_ $ do
                        "It is "
                        c "/user.slice/user-1000.slice/app.slice/app-com.google.Chrome-7575.scope"
                        ". Three rules fired: "
                        c "/user-*.slice"
                        " became "
                        c "/[U:*]"
                        " and swallowed the "
                        c "/user.slice"
                        " that preceded it, the generic "
                        c "/*.slice"
                        " rule turned "
                        c "app.slice"
                        " into "
                        c "[app]"
                        ", and "
                        c "/*.scope"
                        " became "
                        c "/!*"
                        "."
                    p_ $ do
                        "So: a process in your user session, in the application slice, in a scope \
                        \systemd created for Chrome when it was launched. The compression is not \
                        \lossy in any way that matters — each bracket is a reversible abbreviation \
                        \— and it turns 68 characters into 38."
                )
            ,
                ( "The "
                    <> c "CONTAINER"
                    <> " column shows "
                    <> c "/"
                    <> " for every process on your laptop. Is the column broken?"
                , do
                    p_ $ do
                        "No — nothing is in a container, so there is nothing to name. The column is \
                        \filled by heuristics over the cgroup path and namespace membership, and \
                        \when a process is simply running on the host it has no container name to \
                        \report."
                    p_ $ do
                        "The manual page is no help here because it documents neither "
                        opt "CONTAINER"
                        " nor "
                        opt "ISCONTAINER"
                        " — both appear only in "
                        c "htop --sort-key help"
                        ", where "
                        opt "CONTAINER"
                        " is described as “guessed by heuristics”. Treat it as a strong hint rather \
                        \than an authority; "
                        opt "CCGROUP"
                        " is the column that never guesses."
                )
            ,
                ( "Why does htop compress cgroup paths at all, rather than letting you scroll?"
                , do
                    p_ $ do
                        "Because a raw cgroup path is routinely 60 to 120 characters and a process \
                        \list has perhaps 40 to spare. An uncompressed column would either consume \
                        \the whole screen or be truncated to "
                        c "/system.slice/sys"
                        ", which distinguishes nothing — every row would start with the same \
                        \dozen characters."
                    p_ $ do
                        "The compression is designed around exactly that: it shortens the "
                        i_ "structural"
                        " parts, which are common to every row and therefore carry no information, \
                        \and leaves the unit name, which is the only part that differs. That is why "
                        c "/[S]/nginx"
                        " is genuinely as useful as "
                        c "/system.slice/nginx.service"
                        " and fits in a tenth of the space."
                )
            ,
                ( "You press "
                    <> k "O"
                    <> " on a busy container host and half the list disappears. When is that the \
                       \right thing to do?"
                , do
                    p_ $ do
                        "When you are looking at the "
                        i_ "host"
                        " rather than at the workloads. A Kubernetes node runs a few dozen host \
                        \processes — kubelet, the container runtime, the log shipper, sshd — \
                        \drowned in several hundred container processes that belong to somebody \
                        \else's problem."
                    p_ $ do
                        k "O"
                        " gives you the host back. The inverse question, “which container is \
                        \misbehaving”, is better answered by sorting on "
                        opt "CCGROUP"
                        " so that each container's processes group together, than by hiding \
                        \anything. Two toggles, two different jobs."
                )
            ]
        , dayCheat = cheat
        }

-- ---------------------------------------------------------------------------

d13diagram :: Diagram
d13diagram =
    ( diagram
        "Every process belongs to a cgroup, whose path names a systemd unit or a container; the \
        \CGROUP column shows that path in full and the CCGROUP column shows it compressed by a \
        \fixed set of rules."
        body'
    )
        { dgCaption = do
            "The cgroup path is the only place a process list records "
            i_ "what a process is part of"
            " rather than what it is — which unit, which session, which container. The two columns \
            \show the same path at two lengths, and the compressed one is almost always the right \
            \choice: the rules only shorten the structural parts that every row shares, leaving \
            \the name that distinguishes them. The dashed aspect is the softer one — "
            c "CONTAINER"
            " is guessed from the same path by heuristics, so it is a hint where "
            c "CCGROUP"
            " is a fact."
        , dgRankdir = "TB"
        , dgRanksep = "0.45"
        }
  where
    body' =
        "  proc  [label=\"a process\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  cg    [label=\"a cgroup\", fillcolor=\"#e7f0ec\", color=\"#2f7a63\"];\n\
        \  path  [label=\"a cgroup path\"];\n\
        \  unit  [label=\"a systemd unit\\nor a container\", fillcolor=\"#f4efe6\"];\n\
        \  raw   [label=\"the CGROUP column\"];\n\
        \  comp  [label=\"the CCGROUP column\"];\n\
        \  guess [label=\"the CONTAINER column\\n(heuristic)\", fillcolor=\"#f8efdf\", color=\"#d8b784\"];\n\
        \\n\
        \  proc -> cg   [label=\"  belongs to\"];\n\
        \  cg   -> path [label=\"  is named by\"];\n\
        \  path -> unit [label=\"  identifies\"];\n\
        \  raw  -> path [label=\"  shows in full\"];\n\
        \  comp -> path [label=\"  shows compressed\"];\n\
        \  guess-> path [label=\"is guessed from  \", style=dashed, constraint=false];\n"

-- ---------------------------------------------------------------------------

body :: Html () -> Html ()
body fig = do
    block "The column that says what a process is part of" $ do
        p_ [class_ "lede"] $ do
            "Every column so far describes a process in isolation. The cgroup columns describe "
            b_ "what it belongs to"
            " — which systemd unit, which login session, which container — and on a server that is \
            \usually the more useful question."
        p_ $ do
            "The catch is width. A real cgroup path runs to sixty or a hundred and twenty \
            \characters, and a process list has perhaps forty to spare. So htop offers the path \
            \twice: "
            opt "CGROUP"
            " in full, headed "
            c "CGROUP (raw)"
            ", and "
            opt "CCGROUP"
            " compressed, headed "
            c "CGROUP (compressed)"
            "."
        fig

    block "The ten rules, on real output" $ do
        p_ "Side by side on an ordinary systemd desktop, the compression speaks for itself:"
        ascii
            [ "  PID  CGROUP (compressed)            CGROUP (raw)"
            , "    1  /!init                         /init.scope"
            , "  843  /[S]/systemd-journald          /system.slice/systemd-journald.service"
            , "  889  /[S]/systemd-udevd/udev        /system.slice/systemd-udevd.service/udev"
            , " 1227  /[S]/polkit                    /system.slice/polkit.service"
            , " 5399  /[U:1000]/[session]/org.gnome.Shell@wayland"
            , " 7575  /[U:1000]/[app]/!app-com.google.Chrome-7575"
            ]
        p_ "The rules, from the manual page and confirmed against the binary:"
        defs
            [ (c "/*.slice" <> " → " <> c "/[*]", "The generic rule. " <> c "app.slice" <> " becomes " <> c "[app]" <> ".")
            , (c "/system.slice" <> " → " <> c "/[S]", "The system services.")
            , (c "/user.slice" <> " → " <> c "/[U]", "The user sessions.")
            , (c "/user-*.slice" <> " → " <> c "/[U:*]", do "One user, by UID — and it swallows the " ; c "/[U]" ; " immediately before it, so you get " ; c "/[U:1000]" ; " rather than " ; c "/[U]/[U:1000]" ; ".")
            , (c "/machine.slice" <> " → " <> c "/[M]", "Machines and VMs.")
            , (c "/machine-*.scope" <> " → " <> c "/[SNC:*]", "A systemd-nspawn container. Uppercase for the monitor process.")
            , (c "/lxc.monitor.*" <> " → " <> c "/[LXC:*]", "An LXC monitor.")
            , (c "/lxc.payload.*" <> " → " <> c "/[lxc:*]", "An LXC payload — lowercase, and the distinction from the monitor is deliberate.")
            , (c "/*.scope" <> " → " <> c "/!*", do "A scope. This is why PID 1 reads " ; c "/!init" ; ".")
            , (c "/*.service" <> " → " <> c "/*", "The suffix is simply dropped, because on a systemd box almost everything is a service.")
            ]
        why $ p_ $ do
            "The compression only touches the parts that are the "
            i_ "same on every row"
            ". "
            c "/system.slice/"
            " appears at the head of a hundred rows and therefore carries no information at all; \
            \the unit name after it is the only part that distinguishes anything, and it is left \
            \untouched. That is why "
            c "/[S]/nginx"
            " reads as well as the full path in a tenth of the width, and it is a principle worth \
            \stealing for any column you ever have to fit into a terminal."
        gotcha $ p_ $ do
            "Escape sequences inside a cgroup name are "
            b_ "not"
            " decoded. systemd escapes awkward characters in unit names — a mount unit for "
            c "/var/lib/docker"
            " becomes "
            c "var-lib-docker.mount"
            ", and stranger names get "
            c "\\x2d"
            "-style escapes — and htop passes them through as written. If a cgroup path looks like \
            \line noise, that is systemd's encoding showing through rather than corruption."

    block "Containers" $ do
        p_ $ do
            "Two more columns, neither documented in the manual page and both visible in "
            c "htop --sort-key help"
            ":"
        defs
            [ (opt "CONTAINER", "The container's name — “guessed by heuristics”, in the binary's own words, from the cgroup path and namespace membership. Shows " <> c "/" <> " for a process that is not in a container.")
            , (opt "ISCONTAINER", "Whether this process is inside a child container at all. The predicate behind the " <> k "O" <> " toggle.")
            ]
        p_ $ do
            k "O"
            " hides every containerised process. On a laptop it appears to do nothing, because \
            \nothing matched; on a container host it removes most of the list and hands you back \
            \the host itself — kubelet, the runtime, the log shipper, sshd — which is otherwise \
            \drowned in several hundred rows belonging to somebody else's workload."
        tip $ p_ $ do
            "For the opposite question — “which container is misbehaving” — do not hide anything. \
            \Sort by "
            opt "CCGROUP"
            " and each container's processes group together, so a busy container appears as a \
            \contiguous block of rows rather than as individuals scattered through a CPU-sorted \
            \list. Grouping beats filtering when you do not yet know what you are looking for."

    block "Today's habit" $ do
        p_ $ do
            "On any machine running systemd — which is to say nearly all of them — put "
            opt "CCGROUP"
            " somewhere you can see it. The single most common question on a server is “what is \
            \this process actually part of”, and until today your process list had no column that \
            \could answer it."
        p_ "Tomorrow: the sharp edges, every place the manual page and the binary disagree, and where to go next."

cheat :: Html ()
cheat = do
    cfg
        [ "CGROUP    the raw path      -- 60-120 chars; almost never worth the width"
        , "CCGROUP   compressed        -- the one to actually put on screen"
        , "CONTAINER container name    -- HEURISTIC. '/' means 'not in one'   [not in man]"
        , "O         hide/show containerised processes                        [toggle]"
        , ""
        , "the ten rules:"
        , "  /*.slice          -> /[*]        /system.slice   -> /[S]"
        , "  /user.slice       -> /[U]        /user-*.slice   -> /[U:*]  (eats the /[U])"
        , "  /machine.slice    -> /[M]        /machine-*.scope-> /[SNC:*]"
        , "  /lxc.monitor.*    -> /[LXC:*]    /lxc.payload.*  -> /[lxc:*]"
        , "  /*.scope          -> /!*         /*.service      -> /*  (suffix dropped)"
        , ""
        , "/[S]/nginx                 = /system.slice/nginx.service"
        , "/[U:1000]/[app]/!app-foo   = /user.slice/user-1000.slice/app.slice/app-foo.scope"
        , "/!init                     = /init.scope"
        ]
    p_ $ do
        "systemd's own escaping is passed through undecoded, so a cgroup path full of "
        c "\\x2d"
        " sequences is an awkward unit name rather than a bug."
