# Writing style

The reader is a competent Linux user of many years who has never used this tool properly.
Write for that person: no explaining what a shell is, no apologising for depth, no
enthusiasm. The tone that works is *a good colleague explaining something they clearly know
well, at a whiteboard, once*.

## Voice

- **Lead with the mechanism, then the keystroke.** "A binding is a stored command plus the
  table it lives in" earns the list of keys that follows. The reverse order does not.
- **Say why the tool is like this.** The `why` callout is the highest-value block on the
  page. Design rationale is what makes the rest memorable and is exactly what a man page
  cannot give.
- **Name the trap.** Every day should carry at least one `gotcha` — the thing that will
  cost the reader twenty minutes at 2am. These are the paragraphs people remember.
- **British-ish, plain, no hype.** No "simply", "just", "powerful", "leverage", "delve",
  "seamless". No exclamation marks. Em dashes sparingly, and never as a substitute for a
  full stop.
- **Concrete numbers over adjectives.** "defaults to 10, and silently truncates" beats
  "may be too small".
- **Second person, present tense.** "You reattach later and find the scrollback still
  scrolling."

## The skeleton of a day

`dayBody` is a `Html () -> Html ()`; the argument is the rendered olog, placed where the
prose wants it (usually after the first or second section).

```
block "<a title that is a claim, not a label>"
    p_ [class_ "lede"]  -- one paragraph that states the day's whole idea
    p_ ...              -- two or three paragraphs of mechanism
    why / gotcha / tip  -- at least one, where it belongs in the argument
    fig                 -- the olog, once
block "<the operational section>"
    defs / steps        -- the actual keys or commands, in the order you meet them
    sh / cfg / termWin  -- a transcript or a mock-up: show, do not describe
block "<one section that goes deeper than the reader expected>"
block "Today's habit"   -- what to actually change about tomorrow morning
```

Three to six `block`s. A day that needs eight is two days.

Titles are claims: "Tabs, but they outlive the terminal", "A pane is a whole terminal",
"The two-column trap". Never "Introduction", "Overview", "More about panes".

## Drills

Six to eight, `dayDrills`. Each one is an **imperative sentence the reader can execute in
under two minutes inside real work**. Not "read about X". Not "consider Y".

- Drill 1 is always trivially achievable, to get them into a terminal.
- At least one drill must *break something on purpose* and read the error.
- At least one must use the day's idea on the reader's own real work.
- The last drill is usually a habit to adopt, not a command to run.

## Self-check

Four questions, `dayQuiz`. A good question has a **failure mode in it** — "You do X and Y
happens. Why?" — not "What does X do?". The answer is one or two short paragraphs that
teach something the body did not spell out. If an answer can be a single sentence quoting
the body, the question is not worth asking.

## Cheat sheet

`dayCheat` is normally a single `cfg [...]` block: the day compressed to 6–12 aligned
lines, with `#` comments. It is meant to be screenshotted. Add one sentence of prose after
it only when a table (like tmux's status-line flags) does not fit the code-block shape.

## Vocabulary tables

`dayKeys` / `dayCmds` / `dayOpts` feed the day's "New vocabulary" section, the per-day
cumulative table and the site-wide `reference.html`. Descriptions are **one line, starting
with a verb**, and may contain inline markup:

```haskell
, ("C-b z", "Zoom: this pane fills the window. Press again to restore.")
, ("split-window -h", "Split left/right. Alias " <> c "splitw" <> ".")
```

Put an entry in exactly one day — the day it is first taught.

## Ologs

Ologs in David Spivak's sense, and the convention is what makes them readable:

- **A box is a type**, phrased to complete "this is …": `a session`, `a paste buffer`,
  `the tmux server`. Not `Session`, not `sessions`, not a verb.
- **An arrow is an aspect** — a function between types — labelled so that
  *box → label → box* reads as a true English sentence: "a window **is divided into** a
  pane". Read every arrow aloud before you keep it.
- **Dashed arrows** are aspects that pick out one distinguished element ("has as current",
  "has as active"), or relationships that do not hold structurally (tmux Day 14's
  "cannot reach").
- Two leading spaces in a label (`label="  contains"`) keep it off the edge.

Styling, so all diagrams in a course look like one family:

```
fillcolor="#e7f0ec", color="#2f7a63"   the day's central types (green)
fillcolor="#f4efe6"                    context: things outside the tool (warm grey)
fillcolor="#f8efdf", color="#d8b784"   the surprising or transient one (amber)
(default white)                        everything else
```

**Width matters, and the arithmetic is not obvious.** Graphviz emits `width="Npt"`, which
a browser renders at `N × 96/72` CSS px. The figure column is `--wide` = 52rem = 832px, so
the diagram is scaled by `624/N`:

| Natural width | Scale | 11.5pt label renders at |
| --- | --- | --- |
| ≤ 624pt | 100% | 15.3px — ideal |
| 841pt | 74% | 11.3px — still comfortably legible |
| 960pt | 65% | 10.0px — the floor |

So: **aim under ~700pt, accept up to ~950pt, fix anything wider.**

```sh
grep -o 'width="[0-9]*pt" height="[0-9]*pt"' <slug>/day_NN/olog.svg
```

Fix by switching `dgRankdir` to `"TB"`, not by shrinking fonts. Long left-to-right chains
of five or more boxes are the usual culprit. And look at the result — the number is a
smoke alarm, not a verdict.

Every diagram needs a `dgCaption` that says **what to take away**, not what is drawn. The
caption is prose that argues; the boxes are just its illustration.

**Never teach the notation.** The conventions above are for you, the author; the reader is
assumed to know how to read an olog. No caption explains that a box is a type or an arrow
an aspect, and none tells the reader how to read the arrows — a labelled arrow already
reads as a sentence, so saying so again is dead weight. Olog vocabulary ("the dashed
aspects", "this aspect") is fine to *use*; just never gloss it.

## Config blocks

`ConfBlock` is a `cbTitle` (plain text, becomes a `#` comment in the generated file) and
`cbCode`. The title is **the justification**, in one or two sentences — in eight months it
is the only thing standing between the reader and a config they are afraid to touch.

Never add a line the reader cannot defend. If the only reason is "everyone sets this",
leave it out.
