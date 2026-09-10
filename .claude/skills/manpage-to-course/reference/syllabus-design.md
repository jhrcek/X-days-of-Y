# Carving a man page into N days

## The shape

A man page is organised for lookup. A course is organised for acquisition. The whole job
is re-sorting one into the other, and the ordering principle is **what can you use
tomorrow morning**, not what the page lists first.

Three phases, roughly equal thirds of however many days the tool turns out to support:

| Phase | Content |
| --- | --- |
| **Essentials** | The mental model, then the two or three nouns everything else hangs off. Someone who stops here is still better off than before. |
| **Intermediate** | Configuration, the tool's own command/query grammar, the things a competent user reaches within a year. |
| **Advanced** | Past where most users ever get: the expression language, the extension points, automation, the escape hatches. |

(In the 14-day tmux arc below that comes out as 1–4 / 5–8 / 9–14. A 7-day course
splits 1–3 / 4–5 / 6–7. The proportions travel; the numbers do not.)

Day 1 is always **the mental model** — the design decision the whole tool follows from
(for tmux: server/client separation). Get that wrong and every later day is a list of
keys. Day N is always **the sharp edges plus what to read next**.

## How many days

The day count falls out of the concept areas found in step 2 of the skill, not the other
way round. One area with a mental model of its own and enough material to drill is one
day; an area that needs two diagrams is two days; two thin areas that share a model are
one day. Then sanity-check the total:

- Every day must clear the bar below — one model, usable alone, real drills. A day you
  have to pad with reference tables is a day that does not exist.
- Every area that carries daily use must be in, whatever the total comes to.
- Big reference tables inflate a page without adding days; a page that is mostly one
  option list is a short course.

Typical outcomes: a filter with one pattern language and a pile of flags lands around
7–10 days; a tool with several layers and its own expression language lands around 14; a
tool the size of git or systemd can support 21 or more but is usually better split by
subsystem. Say the number you arrived at *and why* — the areas that justify it — rather
than reaching for a familiar one.

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

## The config thread

Only tools with a config file get one, and where it starts depends on the tool, not on a
fixed day number: the first `ConfBlock` belongs on the first day the reader has learned a
setting worth keeping. For tmux that is Day 5, because options are the fifth concept; for
a tool whose dotfile is the first thing you touch it could be Day 2. State the starting
day when you propose the shape, and keep the `Days N–M` span in the config card in sync
with it.

If the tool has no config file, set `courseConfig = Nothing` and use the freed daily slot
for a "recipes" thread instead — a growing file of invocations the reader has built.
