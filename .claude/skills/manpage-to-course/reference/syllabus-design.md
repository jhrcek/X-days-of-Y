# Carving a man page into N days

## The shape

A man page is organised for lookup. A course is organised for acquisition. The whole job
is re-sorting one into the other, and the ordering principle is **what can you use
tomorrow morning**, not what the page lists first.

Three phases, roughly equal:

| Phase | Days (of 14) | Content |
| --- | --- | --- |
| **Essentials** | 1–4 | The mental model, then the two or three nouns everything else hangs off. Someone who stops here is still better off than before. |
| **Intermediate** | 5–8 | Configuration, the tool's own command/query grammar, the things a competent user reaches within a year. |
| **Advanced** | 9–14 | Past where most users ever get: the expression language, the extension points, automation, the escape hatches. |

Day 1 is always **the mental model** — the design decision the whole tool follows from
(for tmux: server/client separation). Get that wrong and every later day is a list of
keys. Day N is always **the sharp edges plus what to read next**.

## Rules per day

- **One mental model.** If a day needs two diagrams, it is two days.
- **At most ~12 vocabulary entries** across `dayKeys`/`dayCmds`/`dayOpts`. More than that
  is a reference table, not a lesson.
- **Every day must be usable alone, today.** If the drills cannot be done inside the
  reader's actual work, the day is mis-scoped.
- **Order by dependency, not by man-page order.** Introduce nothing that needs a concept
  from a later day. Forward references ("Day 9 explains why") are good; forward
  *dependencies* are not.
- **Name what you skip.** Each day's prose should say when something is deliberately
  deferred or omitted, and the landing page carries a "what is deliberately left out".

## Finding the days in the page

1. List the section headings (`grep -nE '^[A-Z][A-Z ]*$'`). They are a first draft of the
   syllabus, but usually in the wrong order and at the wrong granularity.
2. Sort sections into: *daily use*, *configuration*, *the tool's own languages*
   (targets, formats, filters, expressions), *extension points* (hooks, plugins, modes),
   *plumbing* (terminal handling, protocols, IPC).
3. The big reference tables (options, format variables, key lists) are **not** days. They
   are the raw material for `dayKeys`/`dayCmds`/`dayOpts`, spread across the days that
   need them.
4. Anything you cannot motivate with a concrete "you would reach for this when…" gets cut.

## The tmux arc, as a worked example

```
 1  The mental model         server / client / session / window / pane; attach & detach
 2  Windows                  the "tab" layer, naming, the status line's window list
 3  Panes and layouts        splitting, zoom, the layout engine
 4  Copy mode and buffers    scrollback, search, selection, getting text out
 --- essentials end here; a reader who stops is already productive ---
 5  Options and first config the four option scopes; ~/.tmux.conf begins
 6  Many sessions            session-per-project workflow, clients
 7  The command language     parsing, quoting, the target grammar, ids
 8  Key bindings & tables    bind-key, root vs prefix tables, custom modal tables
 --- intermediate ends; the reader can now read other people's configs ---
 9  Formats                  the #{...} expression language
10  The status line          styles, ranges, alerts  (needs 9)
11  Scripting your workspace idempotent session scripts, send-keys, capture-pane
12  Moving things around     break/join/link/swap, the mouse as ordinary bindings
13  Hooks, popups and menus  reacting automatically; building interfaces
14  Environment & finish     stale $SSH_AUTH_SOCK, terminal features, extra servers
```

Note the two dependency chains that fixed the order: **9 before 10** (a status line is a
format), and **5 before everything that configures anything**.

## Adapting the shape to other tools

Not every tool has tmux's five layers. Map the phases onto whatever the tool does have:

- **A tool with subcommands** (git, systemctl, docker): Day 1 is the object model, the
  essentials are the four or five subcommands that carry 90% of use, the advanced third is
  plumbing, scripting, and the query/format flags.
- **A filter or one-shot tool** (rg, jq, awk, find): Day 1 is the execution model (what it
  reads, what it emits, in what order), the middle is its pattern/expression language, the
  advanced third is performance, composition with other tools, and the exotic flags.
- **A daemon or service** (systemd, ssh, nginx): Day 1 is the unit of configuration and
  its lifecycle, the middle is the config file, the advanced third is diagnosis,
  templating, and security surface.

If the tool has no config file, set `courseConfig = Nothing` and use the freed daily slot
for a "recipes" thread instead — a growing file of invocations the reader has built.
