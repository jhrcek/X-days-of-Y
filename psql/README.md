# 17 Days of psql

A course distilled from the `psql(1)` manual page, for someone comfortable on Linux who has
never used psql properly. Each day introduces one idea, a concept diagram, drills to do in a
real terminal against a real database, a self-check and a cheat sheet.

It is a course about the **client**, not about SQL. It assumes you can already write the
queries you want to run.

**Start here: [`index.html`](index.html).** Everything is static and works over `file://`.

```
index.html        the syllabus
reference.html    every key, command and option, with the day it appears
psqlrc            the finished ~/.psqlrc, assembled from Days 6–17
day_01/ … day_17/ one lesson each: index.html + olog.dot + olog.svg
psql.manpage      the source text, as `man -P cat psql | col -bx` produced it
```

Drill checkboxes are remembered in `localStorage`, and the syllabus shows how far you got.

## You need a server

Not just the client. If a distribution's `postgresql` package gave you only `psql`, Day 2
opens with a disposable one:

```sh
docker run --rm --name pgcourse \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=postgres \
  -e PGDATA=/var/lib/postgresql/data/pgdata \
  --tmpfs /var/lib/postgresql/data/pgdata \
  postgres:18.6-alpine \
  -c log_statement=all -c log_duration=on
```

The data directory is a RAM disk, so stopping the container resets everything — which suits a
course that keeps telling you to break things. It runs in the foreground so that terminal
becomes the server's log, and the two `-c` flags make that log a live view of what psql
actually sends. Day 2 explains each flag and gives the six statements the examples use; Day 17
uses the log to show that `-c 'a; b'` arrives as one statement and that `\bind` is logged as
`execute` rather than `statement:`.

## The arc

```
 1  The query buffer          you type into a buffer; a semicolon dispatches it
 2  Getting connected         conninfo strings, URIs, service files, .pgpass, \c
 3  Relations, and patterns   the \d grammar, and patterns as anchored regexes
 4  Functions and privileges  \df, \sf, \du, \drg, and reading an ACL entry
 5  Readable output           \pset: format, expanded, null, border, pager
 6  Your own psqlrc           the startup file; \set vs \pset vs SET      ← config starts
 --- essentials end here ---
 7  Editing and history       readline, \e, \ef, one history per database
 8  Errors and transactions   autocommit, %x, ON_ERROR_ROLLBACK, \errverbose
 9  Bulk data with \copy      \copy vs server COPY — whose filesystem?
10  Sending output elsewhere  \o, \g, pipes, and the channel errors never leave
11  psql in scripts           -c vs -f, -X, exit codes 0/1/2/3, \i vs \ir
 --- intermediate ends here ---
12  Interpolation             :var, :'var', :"var", :{?var}, backquotes, \gset
13  Making psql write SQL     \gexec, \gdesc, \crosstabview, \watch
14  Conditional scripts       \if driven by \gset, and one silent failure mode
15  Prompts worth reading     PROMPT1/2/3, every escape, colour, %w
16  The extended protocol     \bind, \parse, pipelining, %P
17  Sharp edges               -E, version skew, \restrict, and what to read next
```

## What is deliberately left out

SQL itself. Beyond that: the Windows console code-page notes, the `latex`,
`latex-longtable`, `troff-ms` and `asciidoc` output formats, the two variables the manual
page calls "mainly useful for regression tests", LDAP lookup of connection parameters, and
the specialist corners of the describe family — access methods and operator classes
(`\dA…`), text search (`\dF…`), foreign data wrappers (`\de…`) and replication (`\dRp`,
`\dRs`). Day 3 teaches the naming scheme that generates all forty-five of them and `\?`
lists the rest.

## Rebuilding

The HTML is generated; the content lives in Haskell.

```sh
cabal run psql-course     # this course
cabal run build-site      # every course, plus the repository landing page
```

Needs GHC with cabal, and `graphviz` on `PATH` for the diagrams.

Content lives in `src/Course/Day/D01.hs` … `D17.hs`; course metadata in
`src/Courses/Psql.hs`. The page templates, markup vocabulary and stylesheet are shared, in
`../course-builder/`.

## Accuracy

Checked against **psql 18.6** talking to a **PostgreSQL 18.6** server, not just read off the
manual page. Exercised against the live binary: every `\pset` and `\set` default; the exit
codes for `-c`, `-f`, `-1` and `ON_ERROR_STOP`; transaction grouping for `-c 'a; b'` versus
two `-c` flags; all eight table privilege letters, derived by granting one at a time; the
pattern language including case folding, partial quoting and character classes; every prompt
escape, over a pseudo-terminal; `HISTFILE`, `HISTCONTROL` and `COMP_KEYWORD_CASE`, by
inspecting the files and completions they produce; `\copy` against server-side `COPY`,
confirming which filesystem each writes to; `\gset`, `\gexec`, `\gdesc`, `\crosstabview` and
`\watch`; `\if` including its non-Boolean and unclosed-block failures; `\bind`, `\parse` and
a full pipeline including its aborted state; and every line of the generated `psqlrc`, which
loads silently and with no errors.

Six places where the manual page and the binary disagree or where the page is materially
incomplete, all of which the course follows the binary on:

- **`\pset pager`** reports its value as `1`, not the `on`/`off`/`always` the page describes.
  Day 5.
- **`psql -c` exits 1 on a SQL error** with or without `ON_ERROR_STOP`, while `psql -f`
  exits **0** unless it is set. The page's `EXIT STATUS` section describes only the `-f`
  case. Days 2 and 11.
- **`-1` rolls back without `ON_ERROR_STOP`.** The page implies the flag is what causes the
  rollback; in fact the server has already aborted the transaction, so what the flag buys is
  the exit code 3 and stopping at the first error. Day 11.
- **`HISTFILE` is only honoured if set before the session starts** — that is, in a startup
  file. Set at the prompt it is silently ignored, and `-v HISTFILE=…-:DBNAME` does not
  interpolate, producing a file named literally `…-:DBNAME`. The page shows the psqlrc form
  and does not say the others fail. Day 7.
- **A non-Boolean `\if` expression does not stop a script**, even with `ON_ERROR_STOP` set —
  the block is skipped and psql exits 0. The page calls this a warning, which is how it
  behaves, though psql prints it with an `error:` prefix. Day 14.
- **`COPY` in a pipeline aborts the connection**, not just the command. The page says only
  "COPY is not supported while in pipeline mode". Day 16.

Two things a reader must change for their own machine: the `\setenv PSQL_PAGER 'less -SXF'`
line on Day 10 assumes `less` (drop it, or point it at `pspg`), and the `\pset linestyle
unicode` pair on Day 6 assumes a terminal that renders box-drawing characters.
