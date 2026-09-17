# 14 Days of tig

A course distilled from the `tig(1)`, `tigrc(5)` and `tigmanual(7)` manual pages, for someone
comfortable on Linux and with git who has never used tig properly. Each day introduces a handful
of concepts, a concept diagram, drills to do in a real terminal, a self-check and a cheat sheet.

**Start here: [`index.html`](index.html).** Everything is static and works over `file://`.

```
index.html        the syllabus
reference.html    every key, command and option, with the day it appears
tigrc             the finished config, assembled from Days 7-14
day_01/ … day_14/ one lesson each: index.html + olog.dot + olog.svg
tig.manpage       the three source manual pages, as ingested
tigrc.manpage
tigmanual.manpage
```

Drill checkboxes are remembered in `localStorage`, and the syllabus shows how far you got.

## The arc

| Day | | |
| --- | --- | --- |
| 1 | The viewer model | a view is a git command's output, on a stack |
| 2 | The main view | the graph, the refs, and three rows that are not commits |
| 3 | Moving between views | parent/child split, and why the arrows are not `j`/`k` |
| 4 | Reading diffs | context, chunks, and the file filter that shows nothing of itself |
| 5 | Finding things | search reads the view; the prompt addresses things by name |
| 6 | Staging from the diff | the file, the chunk, the part, the line |
| 7 | Options and your first tigrc | ← the config thread starts |
| 8 | Files through time | tree, blob, blame, and `,` to walk back past a change |
| 9 | Refs, stashes and the reflog | the views that browse names |
| 10 | The command line | revision specification, path limiting, pager mode |
| 11 | Columns and view settings | the column-specification language |
| 12 | Bindings and keymaps | resolution: view, then generic, then built-in |
| 13 | External commands | command flags plus browsing-state substitution |
| 14 | Colours and sharp edges | areas, large repositories, and the manual's errors |

Days 1–6 are the essentials — someone who stops there can read history, read diffs and build
commits without leaving tig. Days 7–11 cover configuration and the remaining views. Days 12–14
are tig's own languages and extension points.

## Rebuilding

The HTML is generated; the content lives in Haskell.

```sh
cabal run tig-course      # this course
cabal run build-site      # every course, plus the repository landing page
```

Needs GHC with cabal, and `graphviz` on `PATH` for the diagrams.

Content lives in `src/Course/Day/D01.hs` … `D14.hs`; course metadata in `src/Courses/Tig.hs`.
The page templates, markup vocabulary and stylesheet are shared, in `../course-builder/`.

## Accuracy

Checked against **tig 2.6.1** (ncursesw 6.6, readline 8.3), not just read off the manual pages.
Every default quoted here came out of `:save-options` with the system config disabled, every
config block was loaded by a real tig and checked for warnings, every key binding was read from
the running binary, and the behavioural claims were exercised in a scratch repository — including
line-level staging, the blame-parent walk, keymap resolution order, and the regexp colour rule.

The manual pages and the binary disagree in five places. **The course follows the binary in each
case, and says so:**

1. **`tigmanual(7)` documents a built-in `generic G → git gc` external command.** It does not
   exist in 2.6.1; `G` in the main view is `:toggle commit-title-graph`. The same table omits the
   `refs`, `reflog` and `stash` external commands that *do* exist (Day 9).
2. **`tigmanual(7)` says `F` toggles reference display.** True only in the `main` and `reflog`
   keymaps; in `generic`, `F` is `:toggle file-name` (Day 12).
3. **`tigrc(5)` says `mailmap` is "Off by default".** The built-in default is `yes` (Day 7).
4. **`tigrc(5)`'s colour example `palette-0 = red` is invalid as a `color` command** — it needs a
   background: `color palette-0 red default`. `palette-0`…`palette-13` are valid; `palette-14` is
   rejected (Day 14).
5. **`tigrc(5)` says int values are "a non-negative integer".** `set tab-size = 0` is rejected with
   "Value must be between 1 and 1024" — per-setting bounds exist and are undocumented (Day 7).

Four settings the binary accepts are missing from `tigrc(5)`'s variable list entirely:
`diff-noprefix`, `file-filter`, `rev-filter` and `id-width`. The middle two are what the `%` and
`^` keys toggle (Day 4).

`tigmanual(7)`'s key tables are also incomplete: `L` (reflog), `S` (status), `J`/`K`, `<` (back),
`C-u`/`C-d`, `\` (split chunk), `2` (stage part) and the `i`/`I` sort toggles are all bound and
all undocumented. The help view (`h`) and `:save-options` are generated from the running program
and are the reliable references; the course says so on Day 14.

## What a reader must adjust for their own machine

- **The clipboard binding on Day 13** uses `xclip`. Use `pbcopy` on macOS or `wl-copy` under
  Wayland.
- **The regexp dialect on Day 5** depends on your build. This one has no PCRE (`tig -v` lists only
  ncursesw and readline), so searches are POSIX extended regexps and `\d` does not work. Press `v`
  to check yours.
- **The config file path.** The course writes `~/.tigrc`. If `$XDG_CONFIG_HOME` is set, or
  `~/.config/tig/config` exists, tig reads that instead — and only that.

## What is deliberately left out

The full seventy-entry colour-area table, the complete forty-entry browsing-state variable list,
the testing hooks (`TIG_NO_DISPLAY`, `:save-view`), the `pgrp` option and its Zsh interaction, the
mouse settings beyond a mention, and the deprecated `v1` graph internals. By Day 14 those are
lookups rather than lessons, which was the point.
