---
name: manpage-to-course
description: Turn a Linux tool's manual page into an "N Days of <tool>" course in this repository - Haskell/Lucid-generated static HTML with graphviz ologs, terminal mock-ups, drills, self-check quizzes, cumulative cheat sheets and an incrementally built config file, every claim verified against the installed binary and the result ready for GitHub Pages. Use when asked to build a course, tutorial or learning path from a man page.
disable-model-invocation: true
arguments: [tool, manpage]
allowed-tools: Bash(cabal *) Bash(dot *) Bash(man *) Bash(col *) Bash(git status *) Bash(git ls-files *)
---

Build a course for **$tool** from its manual page ($manpage, or `man $tool` if not given),
as a new package in this repository alongside `tmux/`.

`tmux/` is the worked example. When any instruction here is ambiguous, go and look at how
`tmux/src/Course/Day/D01.hs` (essentials) and `D09.hs` (advanced) actually do it.

## Non-negotiables

- **Haskell only for automation.** Site generation is the `course-builder` library. Never
  add Python, Node, Make or a shell script that generates content. Ad-hoc `sed`/Edit for
  patching source is fine.
- **Verify, do not paraphrase.** Every default, flag, key binding and config line goes into
  the course only after being exercised against the installed `$tool`. Where the man page
  and the binary disagree, follow the binary and say so.
- **Read the whole man page** before planning the syllabus. Chunked `Read` calls, not
  `head`/`grep`. You cannot carve a good syllabus out of a file you have skimmed.
- **Never commit or push** unless explicitly asked.

## Procedure

### 0. Preconditions

```sh
ghc --version && cabal --version     # required
dot -V                               # required, for the ologs
$tool --version                      # required: verification needs the real binary
google-chrome --version; magick -version   # optional, for visual QA
```

If `$tool` is not installed, stop and say so — the course cannot be verified without it.

### 1. Ingest the manual page

```sh
mkdir -p <slug>
man -P cat $tool | col -bx > <slug>/$tool.manpage    # if $manpage was not supplied
grep -nE '^[A-Z][A-Z ]*$' <slug>/$tool.manpage       # the section map
```

Read it end to end. Then probe the binary for everything it will tell you — version,
option defaults, key bindings, subcommands — and keep a scratch note of verified facts and
of any place the page and the binary disagree. See `reference/verification.md`.

### 2. One round of questions

Ask exactly once, with `AskUserQuestion`, marking the defaults below as *(Recommended)*:

| Question | Options (first is the default) |
| --- | --- |
| Length and depth | 14 days / 21 days / 10 days |
| Page contents (multi-select) | drills, olog diagram, cheat sheet + cumulative keymap, self-check quiz |
| Config thread | incremental from ~Day 5 / one dedicated day / none |
| Delivery | local files + GitHub Pages / local files only |

Then proceed autonomously. Do not ask again mid-course.

### 3. Design the syllabus

Follow `reference/syllabus-design.md`. In short: front third essentials, middle third the
things a competent user reaches in a year, final third past where most users ever get. One
mental model per day, at most ~12 vocabulary entries. Decide explicitly what is left out.

Show the syllabus in one message, then keep going without waiting.

### 4. Scaffold and compile before writing prose

Copy the templates, substituting `SLUG` / `TOOL` / `MANREF` / `VERSION`:

```
templates/course.cabal.tmpl   -> <slug>/<slug>-course.cabal
templates/Main.hs.tmpl        -> <slug>/app/Main.hs
templates/Course.hs.tmpl      -> <slug>/src/Courses/<Tool>.hs
templates/Day.hs.tmpl         -> <slug>/src/Course/Day/D01.hs .. DNN.hs   (stubs first)
templates/README.md.tmpl      -> <slug>/README.md
```

Register the package in `cabal.project` and add it to `courses` in `site/app/Main.hs`.
Then `cabal build all` — **the pipeline must compile before any content is written.**

### 5. Write the days, two or three at a time

Per `reference/writing-style.md` and the field reference in `reference/builder-api.md`.
After each batch: `cabal build all`. Every `ConfBlock` is tested in a throwaway instance of
`$tool` *before* it goes in the file.

### 6. Verify

Run the whole checklist in `reference/verification.md`: no `TBD` left, the generated config
loads clean, no olog wider than ~830pt, screenshots of the landing page plus an early and a
late day, relative links only, and `cabal run build-site` regenerating the root page.

### 7. Finish

Write the course `README.md`, then report: what the course covers, what was deliberately
left out, what you verified against the binary, and any man-page/binary discrepancies you
found. Leave the working tree uncommitted.

## Reference

- `reference/syllabus-design.md` — carving a man page into N days
- `reference/writing-style.md` — voice, day skeleton, drills, quizzes, olog conventions
- `reference/builder-api.md` — every `Course`/`Day`/`Diagram` field and the markup vocabulary
- `reference/verification.md` — the checklist and the exact commands
