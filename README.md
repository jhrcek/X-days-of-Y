# X Days of Y

Short courses distilled from primary sources — one manual page, one sitting a day, drills
you do in real work rather than exercises you read.

| Course | Source |
| --- | --- |
| [14 Days of tmux](https://janhrcek.cz/X-days-of-Y/tmux) | `tmux(1)`, checked against tmux 3.7c |

## Building

The HTML is generated; the content lives in Haskell.

```sh
cabal run build-site      # every course, plus the root landing page
cabal run tmux-course     # one course, for fast iteration
```

Needs GHC with `cabal`, and `graphviz` on `PATH` for the diagrams.

```
cabal.project        course-builder, site, and one package per course
course-builder/      the shared half: lesson types, markup vocabulary, page
                     templates, graphviz rendering, the one stylesheet
site/                lists the courses; builds them all and the root page
tmux/                a course: metadata + one module per day, plus its output
index.html           GENERATED — do not edit by hand
```

## Adding a course

```
/manpage-to-course <tool>
```

The [`manpage-to-course` skill](.claude/skills/manpage-to-course/SKILL.md) does the whole
job: reads the man page, agrees a syllabus with you, scaffolds the package, writes and
verifies the lessons against the installed binary, and wires the result into the site.

By hand it is: a package directory following `tmux/`'s shape, one line in `cabal.project`,
and one entry in `courses` in `site/app/Main.hs`.
