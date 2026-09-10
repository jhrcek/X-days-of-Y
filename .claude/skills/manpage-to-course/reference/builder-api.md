# The `course-builder` API

A course is a package that exports one `Course`. `course-builder` turns it into HTML,
SVG and the config file. Nothing in a course is hand-written markup.

## Repository layout

```
cabal.project                packages: course-builder, site, <every course>
course-builder/              the library (never edited by a course)
  assets/style.css           the one stylesheet; embedded and copied into each course
  src/Course/{Types,Markup,Render,Build,Site}.hs
site/app/Main.hs             lists every course; builds all of them + the root page
<slug>/
  <slug>-course.cabal        library (Courses.<Tool>) + exe <slug>-course
  app/Main.hs                buildCourse (root </> "<slug>") course
  src/Courses/<Tool>.hs      the Course record
  src/Course/Day/D01..DNN.hs one Day each
  <generated>                index.html, reference.html, assets/, day_NN/, <config file>
```

`cabal run build-site` rebuilds everything; `cabal run <slug>-course` rebuilds one course.

## `Course`

| Field | Type | Notes |
| --- | --- | --- |
| `courseSlug` | `Text` | directory name **and** `localStorage` key prefix |
| `courseTool` | `Text` | display name in "N Days of *tool*" |
| `courseManRef` | `Text` | `"tmux(1)"` — footer |
| `courseVersion` | `Text` | `"tmux 3.7c"` — footer, "checked against" |
| `courseTagline` | `Html ()` | the paragraph under the cover title |
| `courseHowTo` | `[(Text, Html ())]` | the "How to use this" cards; three reads best |
| `courseLeftOut` | `Html ()` | what the course deliberately omits |
| `courseCardBlurb` | `Html ()` | one paragraph for the repo-root landing card |
| `courseCardTags` | `[Text]` | small tags on that card |
| `courseConfig` | `Maybe ConfigFile` | `Nothing` for tools with no config file |
| `courseDays` | `[Day]` | in order |

The day count, the "~N minutes each" figure and the "Days N–M" span in the config card
(derived from which days actually carry a `ConfBlock`) are all **computed**; do not hardcode them anywhere.

`ConfigFile`: `cfFileName` (written to the course root, e.g. `tmux.conf`), `cfUserPath`
(`~/.tmux.conf`, shown on each config box), `cfReloadHint` (`Html ()`, how to make the tool
re-read it), `cfHeader` (`[Text]`, raw banner lines **including** their `#`).

## `Day`

| Field | Type | Notes |
| --- | --- | --- |
| `dayNum` | `Int` | 1-based, matches the module number |
| `dayTitle` | `Text` | two or three words |
| `daySubtitle` | `Text` | one line; also the syllabus card text |
| `dayMinutes` | `Int` | honest estimate, 25–40 |
| `dayLevel` | `Text` | `essential` / `intermediate` / `advanced` |
| `dayManRef` | `Text` | the man-page sections this distils |
| `dayTags` | `[Text]` | two or three, for the syllabus card |
| `dayGoals` | `[Html ()]` | three, each completing "you can …" |
| `dayBody` | `Html () -> Html ()` | the lesson; argument is the rendered olog figure |
| `dayDiagram` | `Maybe Diagram` | |
| `dayKeys`/`dayCmds`/`dayOpts` | `[Entry]` = `[(Text, Html ())]` | feed the tables and `reference.html` |
| `dayConfig` | `[ConfBlock]` | `ConfBlock cbTitle cbCode` |
| `dayDrills` | `[Html ()]` | 6–8 |
| `dayQuiz` | `[(Html (), Html ())]` | 4 question/answer pairs |
| `dayCheat` | `Html ()` | usually one `cfg [...]` block |

`Diagram`: build with `diagram alt body` and override with record syntax —
`dgCaption` (`Html ()`), `dgRankdir` (`"TB"`/`"LR"`), `dgNodesep`, `dgRanksep`, `dgBody`
(graphviz statements only; the preamble is shared). Write `dgBody` as
`T.unlines [ "  a [label=\"a thing\"];", ... ]`.

## The markup vocabulary (`Course.Markup`)

A day module imports `Course.Markup`, `Course.Types` and `Lucid` — nothing else. If a
lesson needs a new kind of visual element, add it to `Course.Markup` so every course gets
it; do not inline raw `div_`s with new class names.

| Helper | Renders |
| --- | --- |
| `k "C-b c"` | key chips, one per space-separated token |
| `c "tmux ls"` | inline code |
| `opt "history-limit"` | an option name (tinted differently from code) |
| `var "target-pane"` | a placeholder inside a synopsis |
| `block "Title" $ do …` | a titled section of the lesson |
| `sh ["$ cmd", "output"]` | dark shell transcript; `$ ` lines are highlighted |
| `cfg ["set -g x y"]` | light config block; `#` lines are comments |
| `ascii [...]` | monospace art: layouts, trees, tables |
| `termWin "title" [...]` | terminal mock-up |
| `termStatus "title" [...] "left" "right"` | terminal mock-up with a status line |
| `note` / `tip` / `gotcha` / `why` | the four callouts |
| `steps [...]` | numbered walk-through inside prose |
| `defs [(term, meaning)]` | definition list |
| `cols [a, b]` | two side-by-side panels |

Prose is written with plain Lucid and `OverloadedStrings`:

```haskell
p_ $ do
  "The prefix is "; k "C-b"; ", and "; c "tmux ls"; " lists sessions."
```

## Gotchas when writing day modules

- **Local `where` helpers usually need a type signature.** Lucid's `Term` class is very
  polymorphic and ambiguity errors are cryptic; annotate and move on.
- `Html ()` has no `Eq`. Test emptiness on the list you built it from.
- Multi-line Haskell strings use the `\ ... \` gap syntax; a stray unescaped `"` inside a
  `cfg`/`sh` list is the usual compile error.
- `cbTitle` may be multi-line; every line is separately prefixed with `# ` in the output.
- Keep an eye on quoting when a `cbCode` contains both `"` and `\;`.
