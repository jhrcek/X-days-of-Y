# 14 Days of htop

A course distilled from the `htop(1)` manual page, for someone comfortable on Linux who has
never used htop properly. Each day introduces a handful of concepts, a concept diagram,
drills to do in a real terminal, a self-check and a cheat sheet.

**Start here: [`index.html`](index.html).** Everything is static and works over `file://`.

```
index.html        the syllabus
reference.html    every key, command and column, with the day it appears
htoprc            the finished config, assembled from Days 9-14
day_01/ … day_14/ one lesson each: index.html + olog.dot + olog.svg
```

Drill checkboxes are remembered in `localStorage`, and the syllabus shows how far you got.

## The arc

```
 1  The sampling model        essential      what htop reads, delay=15, why percentages are deltas
 2  The process list          essential      selection vs view, the twelve default columns, p / m
 3  The memory columns        essential      VIRT RES SHR PRIV PSS SWAP EPSS, and the implicit-K units
 4  Finding a process         essential      F3 search vs F4 filter vs u vs digit PID-jump; -F -p -u
 5  Sorting and the tree      essential      F6 N P M T I, F5 tree, + - *, F follow, stable tree modes
 6  Acting on processes       intermediate   tagging, the signal menu, nice, autogroup, affinity, i, Y
 7  Looking inside            intermediate   s strace, l lsof, e environ, w wrap, x locks, and privilege
 8  The header meters         intermediate   CPU bar segments, detailed CPU time, ~35 meters, 4 modes
 9  Setup and htoprc          intermediate   the five categories, and the file they write   <- config starts
10  The column catalogue      intermediate   ~70 columns by family, threads K/H/NLWP/TGID, why '-'
11  Screens as tabs           advanced       per-screen columns, sort and tree state
12  I/O and delays            advanced       RCHAR vs RBYTES vs rates, IO priority, delay accounting, PSI
13  cgroups and containers    advanced       CCGROUP's ten shortening rules, CONTAINER, O
14  Sharp edges               advanced       every man-page/binary divergence, pcp-htop, what to read next
```

## Rebuilding

The HTML is generated; the content lives in Haskell.

```sh
cabal run htop-course     # this course
cabal run build-site      # every course, plus the repository landing page
```

Needs GHC with cabal, and `graphviz` on `PATH` for the diagrams.

Content lives in `src/Course/Day/D01.hs` … `D14.hs`; course metadata in
`src/Courses/Htop.hs`. The page templates, markup vocabulary and stylesheet are shared,
in `../course-builder/`.

## Accuracy

Checked against **htop 3.5.3** (an upstream build, with no `/etc/htoprc` and a pristine
`$HOME`), not just read off the manual page. What was exercised against the live binary:
every documented default was read out of a config file htop generated for itself; the
`-d` clamp, `-s`, `-t`, `-u`, `-p`, `-F`, `-n` and `--readonly` flags were each run; every
interactive key taught here was pressed in a pty and its screen captured; all four meter
display modes, both `detailed_cpu_time` settings and the `CGROUP`/`CCGROUP` pair were
rendered side by side; and the generated `htoprc` was loaded, tab by tab, with each claim
in its comments tested — including the rewrite behaviour, which really does reduce a
132-line annotated file to 86 lines with 2 comments after one keystroke and a clean exit.

Where the manual page and the binary disagree, **the course follows the binary** and says
so. Day 14 collects all ten:

| The page says | The binary does |
| --- | --- |
| `SYNOPSIS` lists `-v` | `-v` is an invalid option; version is `-V`. The line also omits `-n`, `-M`, `-U`, `--readonly`, `--no-meters`, `--no-function-bar` |
| nothing about `-n` | `-n`/`--max-iterations` exists, works, and exits after N frames |
| `INTERACTIVE COMMANDS` omits six keys | `#`, `e`, `i`, `Y`, `.` and `C` all work and are in the `F1` help |
| sort aliases are `F6`, `<`, `>` | the `F1` help says `F6`, `>`, `.` — and all four work |
| `COLUMNS` lists ~60 columns | `--sort-key help` adds `ELAPSED`, `SCHEDULERPOLICY`, `SECATTR`, `CWD`, `CONTAINER`, `ISCONTAINER`, `GPU_TIME`, `GPU_PERCENT` |
| a column named `M_M_PSSWP` | the column is `M_PSSWP`; the page's name is silently dropped from a config |
| `T` for a traced process | the `F1` help says `t` |
| "Default CPU bar segments ( use text attributes instead of hues:" | words lost in the page source; an unclosed parenthesis |
| the config "is overwritten upon clean exit" | only if a setting actually **changed** — and plain toggles (`t`, `K`, `I`) count, not just Setup. Nothing changed means nothing is rewritten |
| nothing about `fields=` | every generated config has one, and it silently overrides `screen:Main=` regardless of order |

Two go the other way, where the page is right and `htop --help` is not: `-u` does accept a
numeric UID, and `-H` does work without a delay argument. Neither source dominates, which
is the point.

Also established by experiment and documented nowhere: a missing `$HTOPRC` file does **not**
fall back to `~/.config/htop/htoprc` (htop uses built-in defaults and creates nothing);
`chmod 444` on the config makes htop stop clobbering it, silently and with no error; the
parser reports nothing at all for unknown keys, unknown column names, unknown meter names
or `delay=notanumber`; and `PSS`/`EPSS` print `0` rather than `-` for processes you do not
own, so an unprivileged sort by `PSS` silently ranks every daemon last.

## What a reader must change for their own machine

- The default `delay` is 15 (1.5 s); the shipped config does not override it.
- The `CPU` meter in the shipped `htoprc` is the combined average, chosen so the header does
  not grow with core count. On a machine where you want per-core bars, swap it for
  `LeftCPUs2`/`RightCPUs2` or `AllCPUs`.
- `detailed_cpu_time=1` is set for servers and VMs. On a laptop those segments are always
  zero and you may prefer the default.
- Day 7's `s` key needs `strace` installed and `l` needs `lsof`; neither ships everywhere.
- Day 12's delay-accounting columns (`CPUD%`, `IOD%`, `SWPD%`) read `N/A` unless htop was
  built with `--enable-delayacct` **and** holds `CAP_NET_ADMIN`. Most distribution builds
  have not been, including the one this course was checked against — the Pressure Stall
  Information meters are the substitute, and the course says so.

## What is deliberately left out

`pcp-htop` and the Performance Co-Pilot metric universe (a different binary with its own
manual page, `pcp-htop(5)`); the build-time detail behind the optional `libsystemd`,
`libsensors` and `libnl` bindings; the internals of `--drop-capabilities`; and the
non-Linux platform quirks the cross-platform manual page carries.
