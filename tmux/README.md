# 14 Days of tmux

A fourteen-lesson course distilled from the `tmux(1)` manual page, for someone who is
comfortable on Linux but has never properly used tmux. Each day introduces a handful of
concepts, a concept diagram, drills to do in a real terminal, a self-check, and a cheat
sheet — and from Day 5 onwards it builds up an annotated `~/.tmux.conf` line by line.

**Start here: [`index.html`](index.html).** Open it in a browser; everything is static and
works over `file://`.

```
index.html        the syllabus
reference.html    every key, command and option, with the day it appears
tmux.conf         the finished config, assembled from Days 5–14
day_01/ … day_14/ one lesson each: index.html + olog.dot + olog.svg
```

Drill checkboxes are remembered in `localStorage`, and the syllabus shows how far you got.

## Hosting

The generated site is committed, fully self-contained and uses only relative links, so it
needs no build step to publish. On GitHub Pages, set **Settings → Pages → Source** to
*Deploy from a branch*, branch `master`, folder `/ (root)`; the course is then at
`https://<user>.github.io/X-days-of-Y/tmux/`, and the repo-root `index.html` links to it.

The empty `.nojekyll` at the repo root turns off Jekyll processing — nothing here needs it,
and it keeps a future lesson that mentions `{{` from being mangled.

## Rebuilding

The HTML is generated; the content lives in Haskell.

```sh
cabal run tmux-course          # regenerates every page, diagram, and tmux.conf
```

Requires GHC ≥ 9.4 with `cabal`, and `graphviz` on `PATH` for the diagrams (without it
the pages still build, the `.dot` files are still written, and the `.svg` files are left
alone).

## Where things live

| Path | What it is |
| --- | --- |
| `src/Course/Types.hs` | the shape of one lesson |
| `src/Course/Markup.hs` | the small vocabulary lessons are written in (`k`, `c`, `termWin`, `gotcha`, …) |
| `src/Course/Render.hs` | page templates, graphviz invocation, `tmux.conf` assembly |
| `src/Course/Day/D01.hs` … `D14.hs` | the actual content, one `Day` value per module |
| `assets/style.css` | the whole design; not generated, edit directly |

To change a lesson, edit its `DNN.hs` and re-run the build. The cumulative reference, the
per-day "everything so far" tables and `tmux.conf` are all derived from the `dayKeys`,
`dayCmds`, `dayOpts` and `dayConfig` fields, so adding an entry in one place updates
everything.

Diagrams are ologs (in David Spivak's sense): boxes are types phrased so they complete
"this is …", arrows are aspects phrased so "an X *is a member of* a Y" reads as a
sentence. Each day supplies only the graphviz statements; the shared preamble in
`Render.hs` keeps all fourteen looking like one family.

## Accuracy

Everything was checked against **tmux 3.7c**, not just read off the manual page — the
default key bindings, option defaults, target token forms and format modifiers were all
exercised against a live server, and the generated `tmux.conf` is loaded into a throwaway
server (`tmux -f tmux.conf -L test new -d`) to confirm it parses without errors.

A few places where the manual page and the shipped binary disagree (the `M-1` … `M-7`
layout bindings, for instance) follow the binary.
