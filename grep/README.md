# 10 Days of grep

A course distilled from the `grep(1)` manual page, for someone comfortable on Linux who has
never used grep properly. Each day introduces one idea, a concept diagram, drills to do in a
real terminal, a self-check and a cheat sheet.

**Start here: [`index.html`](index.html).** Everything is static and works over `file://`.

```
index.html        the syllabus
reference.html    every command and option, with the day it appears
day_01/ … day_10/ one lesson each: index.html + olog.dot + olog.svg
grep.manpage      the source text this was distilled from
VERIFIED.md       every fact checked against the binary, and the discrepancies found
```

Drill checkboxes are remembered in `localStorage`, and the syllabus shows how far you got.

## The arc

| Day | | |
| --- | --- | --- |
| 1 | What grep does | three outputs — lines, diagnostics, **status**; stdin vs `-r` vs operands |
| 2 | Saying what you mean | `-i -v -w -x`, and the three ways to hand grep a set of patterns |
| 3 | Matching one character | brackets, `[:classes:]`, the three awkward literals, zero-width anchors |
| 4 | Matching many | repetition, alternation, precedence, BRE↔ERE, leftmost-longest, `-F` |
| 5 | Not printing the line | `-c -l -L -o -q -m -s`, and why `-L`'s status is inverted |
| 6 | Lines around the line | `-A -B -C`, the `:` vs `-` separator, prefix fields |
| 7 | Searching a tree | `-r -R`, and the glob language of `--include`/`--exclude-dir` |
| 8 | When grep lies to you | binary detection, encoding, locale, the real cost of `LC_ALL=C` |
| 9 | grep in a pipeline | exit status as control flow, `set -e`, `-Z` + `xargs -0` |
| 10 | The other engine | `-P`: lookaround, `\K`, what it costs, and when to use `sed`/`awk`/`jq` |

Days 1–4 are the essentials — someone who stops there can write a pattern they can defend.
5–7 are intermediate, 8–10 advanced.

Two dependency chains fixed the order: **3 before 4** (you cannot teach repetition before
the thing being repeated), and **4 before 10** (leftmost-longest has to be established
before PCRE's disagreement with it means anything).

## No configuration file

grep has none. No dotfile, no rc file, and `GREP_OPTIONS` was removed years ago — 3.12
ignores it silently, with no warning at all. The only persistent state is `GREP_COLORS`
and whatever alias your distribution installed (`/etc/profile.d/colorgrep.sh` on Fedora,
which is why your interactive greps are coloured and your scripted ones are not).

So unlike the tmux, psql and htop courses here there is no generated config to diff against
your own. What the days build up instead is `~/grep-recipes.sh`: a file of invocations, each
with the reason as a comment. Day 10 asks you to delete every line you can no longer defend.

## What is deliberately left out

The full PCRE language — Day 10 covers what `-P` buys and where it bites, but the syntax is
`pcre2syntax(3)` and that page does it better. The complete `GREP_COLORS` capability table
(about seventy lines of the manual) is a lookup table rather than a concept; the defaults
are given on Day 5 and the rest is left to `man grep`. `-U/--binary` is skipped because the
page itself says it has no effect outside MS-DOS and Windows, and `-D/--devices` gets a
paragraph rather than a section. Nothing here teaches `sed` or `awk`, though Day 10 is
explicit about where grep stops being the right tool.

## Rebuilding

The HTML is generated; the content lives in Haskell.

```sh
cabal run grep-course     # this course
cabal run build-site      # every course, plus the repository landing page
```

Needs GHC with cabal, and `graphviz` on `PATH` for the diagrams.

Content lives in `src/Course/Day/D01.hs` … `D10.hs`; course metadata in
`src/Courses/Grep.hs`. The page templates, markup vocabulary and stylesheet are shared,
in `../course-builder/`.

## Accuracy

Checked against **GNU grep 3.12** on glibc 2.42, not just read off the manual page. Every
option, every transcript and every timing in the course was run against `/usr/bin/grep`;
`VERIFIED.md` records the results.

**Where the manual page and the binary disagree, the course follows the binary and says so.**
Seven such places were found. The four that matter most:

- **`-o` combined with `-A`/`-B`/`-C` produces no warning.** The page promises one three
  separate times. Measured: zero bytes on stderr, and the context request is silently dropped.
- **`-P` accepts only one pattern** — `grep -P -e foo -e bar` exits 2 with
  `the -P option only supports a single pattern`. This appears nowhere in `grep(1)`.
- **The `POSIXLY_CORRECT` "illegal" wording is stale**: 3.12 says `invalid option` either
  way. The argument-permutation half of that paragraph is real, and is taught.
- **`-y` works as a synonym for `-i`** despite being in neither the page nor `--help`.

Two more are documentation that has aged rather than outright error: the warning that
`[a-d]` may behave erratically outside the C locale does not reproduce on glibc 2.42 (the
course keeps it as a portability point, not a description of your machine), and the
documented `-d read` default is real but can never succeed on Linux, where reading a
directory returns `EISDIR`.

One behaviour is undocumented and genuinely hazardous: **an invalid `--color` argument
prints the usage message to standard output and exits 0.** A typo like `--color=alway`
replaces your search results with a help screen while every status check reports success.

Nothing in the course needs changing for your own machine, with one caveat worth checking
first: on most distributions `grep` in an interactive shell is an alias for
`grep --color=auto`, and this course was written in a session where `grep` was additionally
wrapped to call a different program entirely. Run `type grep` once before you start, and
use `/usr/bin/grep` if the answer surprises you.
