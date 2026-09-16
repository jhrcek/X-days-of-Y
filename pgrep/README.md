# 9 Days of pgrep

A course distilled from the `pgrep(1)` manual page, for someone comfortable on Linux who has
never used pgrep properly. Each day introduces a handful of criteria, a concept diagram,
drills to do in a real terminal, a self-check and a cheat sheet.

**Start here: [`index.html`](index.html).** Everything is static and works over `file://`.

```
index.html        the syllabus
reference.html    every command and option, with the day it appears
day_01/ … day_09/ one lesson each: index.html + olog.dot + olog.svg
pgrep.manpage     the source text this was distilled from
VERIFIED.md       every fact checked against the binary, and the discrepancies found
```

Drill checkboxes are remembered in `localStorage`, and the syllabus shows how far you got.

## The arc

| Day | | |
| --- | --- | --- |
| 1 | The selection model | `/proc`, criteria AND-ed, comma lists OR-ed, exit 0/1/2/3 |
| 2 | Name or command line | the 15-character wall, `-f`, `-x`, `-i`, and `-A` as the fix for `-f` |
| 3 | Shaping the output | `-l`, `-a`, `-Q`, `-d`, `-c`, `--quiet`, command substitution |
| 4 | Who and whose | `-u` vs `-U`, `-G`, `-P`, `-g`, `-s`, `-t`, `-p` |
| 5 | Time, state, inversion | `-n`, `-o`, `-O`, `-r`, and what `-v` actually negates |
| 6 | Threads and pidfiles | `-w` walks tasks, not processes; `-F`, `-L` |
| 7 | Signal and wait | pkill and pidwait: one query, three verbs |
| 8 | Cgroups and namespaces | `--cgroup`, `--ns`, `--nslist`, `--env` |
| 9 | Scripts and sharp edges | the TOCTOU race, the empty-pattern disaster, when to use something else |

Days 1–4 are the essentials, 5–7 intermediate, 8–9 advanced.

## No configuration file

pgrep has none — no dotfile, no environment variables, nothing in `pgrep(1)` resembling an
`ENVIRONMENT` section. So unlike the other courses here there is no generated config to
diff against your own. What the days build up instead is `~/pgrep-recipes.sh`: a file of
queries, each with the reason as a comment. Day 9 asks you to delete every line you can no
longer defend.

## Rebuilding

The HTML is generated; the content lives in Haskell.

```sh
cabal run pgrep-course    # this course
cabal run build-site      # every course, plus the repository landing page
```

Needs GHC with cabal, and `graphviz` on `PATH` for the diagrams.

Content lives in `src/Course/Day/D01.hs` … `D09.hs`; course metadata in
`src/Courses/Pgrep.hs`. The page templates, markup vocabulary and stylesheet are shared,
in `../course-builder/`.

## Accuracy

Checked against **procps-ng 4.0.7** on Linux 7.2.5, not just read off the manual page. Every
option was exercised against the live binary: the 15-character `comm` truncation and the
undocumented diagnostic it produces, the `-v` inversion semantics, `-w` matching per-thread
`comm` values, the three pidfile failure modes, pkill's exit status under partial
permission failure, `pidwait` blocking on a non-child, and the exact form `--cgroup`
demands. `VERIFIED.md` records the transcripts.

**Where the manual page and the binary disagree, the course follows the binary and says
so.** Eight options exist that `pgrep(1)` never mentions — `-p/--pid`, `--quiet`,
`-Q/--shell-quote`, `--env`, `pkill -m/--mrelease`, and `pidwait -e`, which the page
attributes to pkill alone. The page also gives `-v` four words ("Negates the matching")
for behaviour that inverts the entire conjunction of criteria, not the pattern.

One behaviour appears to be an outright bug and is documented nowhere: **`--nslist` with
more than one namespace silently keeps only the last**. `--nslist net,uts` and
`--nslist uts,net` return different sets, each matching their final element. Day 8 shows
the reproduction.

Nothing in the course needs changing for your own machine. The transcripts show PIDs and
process counts from the machine it was checked on; your numbers will differ and the
commands will not.
