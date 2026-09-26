# 21 Days of git

A course distilled from the `git(1)` manual page and the pages it delegates to (gitrevisions(7),
gitglossary(7), gitignore(5), gitattributes(5), githooks(5), gitrepository-layout(5) and the
subcommand pages), for someone comfortable on Linux who uses git every day but has never
learned it properly. Each day introduces one mental model, a concept diagram, drills to do in a
real repository, a self-check and a cheat sheet.

**Start here: [`index.html`](index.html).** Everything is static and works over `file://`.

```
index.html        the syllabus
reference.html    every command and option, with the day it appears
gitconfig         the finished config, assembled from Days 2-21
day_01/ … day_21/ one lesson each: index.html + olog.dot + olog.svg
git.manpage       git(1), as ingested
```

Drill checkboxes are remembered in `localStorage`, and the syllabus shows how far you got.

## Rebuilding

The HTML is generated; the content lives in Haskell.

```sh
cabal run git-course      # this course
cabal run build-site      # every course, plus the repository landing page
```

Needs GHC with cabal, and `graphviz` on `PATH` for the diagrams.

Content lives in `src/Course/Day/D01.hs` … `D21.hs`; course metadata in
`src/Courses/Git.hs`. The page templates, markup vocabulary and stylesheet are shared,
in `../course-builder/`.

## Accuracy

Checked against **git 2.52.0**, not just read off the manual pages. Every transcript is real
output from throwaway repositories, run with an isolated `HOME` and no system config (with
paths shortened, and commit hashes that will differ on your machine because author and time
go into them). Every `gitconfig` block was loaded on its own and exercised, and the assembled
file loads cleanly with `GIT_CONFIG_GLOBAL=gitconfig git config list`.

Where the manual pages and the binary disagree, the course follows the binary and says so:

- **git-bisect(1)** says `bisect run` treats exit codes 126 and 127 as "bad". In 2.52, git
  re-runs the script on a known-good commit and stops with `bogus exit code 127 for good
  revision`, so a mistyped script aborts the session instead of blaming a random commit.
- **githooks(5)** says `GIT_DIR`, `GIT_WORK_TREE` and friends are exported to hooks. In a
  non-bare repository, pre-commit and post-checkout get neither; they get `GIT_INDEX_FILE`
  and `GIT_PREFIX`. githooks(5) also documents post-checkout for checkout and switch only, but
  `git restore` fires it too.
- **git merge -s nonsense** lists the available strategies without `ort`, the default one.
- **gitrevisions(7)** says a bare `..` means `HEAD..HEAD`; `git log ..` instead reads it as the
  path `..` and fails with "outside repository".
- **transfer.fsckObjects** (git-config(1)) is not applied at all when cloning from a local
  path; a malformed commit is accepted unless you use `--no-local` or a `file://` URL.
- **git-prune(1)** names only refs as roots, but a blob that exists only in the index survives
  `gc --prune=now`.

Also verified rather than assumed: `pull.ff = only` restates the built-in default rather than
changing behaviour (the lesson argues for it as written-down policy); `rebase.autoSquash`
applies to interactive rebases only; `--force-with-lease` after a plain `git fetch` still
overwrites a colleague's push and only `--force-if-includes` refuses it; `diff.algorithm =
histogram` was left out because no realistic example produced a different diff.
