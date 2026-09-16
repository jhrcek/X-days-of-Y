# Verified against GNU grep 3.12 (glibc 2.42, Linux 7.2.5), 2026-09-16

Every claim in the course was exercised against `/usr/bin/grep`. Note that on this machine
a bare `grep` in an interactive shell is **not** the binary: `/etc/profile.d/colorgrep.sh`
aliases it to `grep --color=auto`, and the session this was built in had a wrapper function
routing `grep` to `ugrep`. All transcripts below used the absolute path.

```
$ /usr/bin/grep --version | head -1
grep (GNU grep) 3.12
```

## Man page vs binary: DISCREPANCIES (the course follows the binary and says so)

1. **`-o` with `-A`/`-B`/`-C` gives no warning.** grep(1) says, three separate times, "With
   the -o or --only-matching option, this has no effect and a warning is given."
   Measured: `grep -o -A2 M m.txt 2>err` produces **0 bytes** on stderr, prints only the
   matched fragments, and exits 0. Same for `-B` and `-C`. *(Day 5, Day 6)*

2. **`-y` is accepted as a synonym for `-i`.** Absent from grep(1) and from `--help`
   (`grep --help | grep -c '\-y'` → 0). `echo ABC | grep -y abc` → `ABC`, exit 0.
   A survival from Version 7 grep. *(Day 2)*

3. **`-P` accepts only one pattern.** Not mentioned anywhere in grep(1) — the `-P` entry
   warns only about `-z` and "unimplemented features".
   ```
   $ grep -P -e '\d' -e 'aa'        -> grep: the -P option only supports a single pattern
   $ printf 'x\ny\n' > two.pat; grep -P -f two.pat   -> same message
   $ grep -P 'aa<newline>bb'                          -> same message
   ```
   All exit 2. A single pattern containing `|` is fine. *(Day 10)*

4. **The `POSIXLY_CORRECT` "illegal" claim is false.** grep(1): "POSIX requires that
   unrecognized options be diagnosed as 'illegal', but since they are not really against
   the law the default is to diagnose them as 'invalid'." Both with and without the
   variable set, 3.12 says `grep: invalid option -- 'Q'`. The *other* half of that
   paragraph — argument permutation — is real and was verified:
   ```
   $ grep ERROR app.log -c                     -> 2
   $ POSIXLY_CORRECT=1 grep ERROR app.log -c   -> -c becomes a FILENAME:
       app.log:ERROR timeout talking to db
       app.log:ERROR timeout talking to db
       grep: -c: No such file or directory      (exit 2)
   ```
   *(Day 8)*

5. **The collation warning does not reproduce on glibc 2.42.** grep(1) warns that outside
   the C locale `[a-d]` "might be equivalent to `[abcd]` or `[aBbCcDd]` or some other
   bracket expression". Measured: `[a-d]` matches exactly `abcd`, and `[a-z]` does not
   match `B`, in both `C` and `en_US.UTF-8`. The course keeps the warning as a
   *portability* statement (POSIX leaves it unspecified) but says plainly that it does not
   describe current glibc. *(Day 3, Day 8)*

6. **`-d read` is documented as the default but always fails on Linux.** grep(1): "By
   default, ACTION is read, i.e., read directories just as if they were ordinary files."
   `grep hello /etc` and `grep -d read hello /etc` produce the identical
   `grep: /etc: Is a directory`, exit 2 — because `read(2)` on a directory fd returns
   `EISDIR`. The documented behaviour is what happens; on Linux it cannot succeed. *(Day 1)*

7. **Undocumented, and dangerous: an invalid `--color` argument prints the usage message to
   STDOUT and exits 0.** grep(1) documents the three legal values and says nothing about
   what happens otherwise.
   ```
   $ echo abc | grep --color=bogus b > out.txt 2> err.txt ; echo $?
   0
   $ wc -l < err.txt      -> 0
   $ head -1 out.txt      -> Usage: grep [OPTION]... PATTERNS [FILE]...
   ```
   Also true for `--colour=bogus`, `--color=BOGUS`, and for abbreviations (`alway`, `al`,
   `n`) — no abbreviation is accepted. In a pipeline this silently substitutes a help
   screen for your search results while reporting success. *(Day 5)*

## Verified behaviour

### Exit status
- 0 selected something, 1 selected nothing, 2 error. `grep root /etc/shadow` → 2.
- `-q` exits 0 on a match **even when another file errored**; with no match and an error
  it is 2, not 1. Verified both ways.
- `-s` suppresses the *message* only — the status is still 2.
- **`-L` inverts the output but not the status.** `grep -L beta c1.txt c2.txt` printed one
  filename and exited **0**; `grep -L zzz c1.txt c2.txt` printed both and exited **1**.
  Any check built on `-L` must test the output, not `$?`.
- `set -e` + a grep that matches nothing aborts the script (`bash -c 'set -e; grep zzz f;
  echo REACHED'` never reaches). `grep ... | head -2` leaves grep at **141** (SIGPIPE).
- grep terminates its last output line even when the input did not: `printf 'a\nb'` out →
  `a\nb\n`.

### Matching control
- `-w` tests the *matched substring*: `foo-bar` passes, `_foo` fails (underscore is a word
  character), and `grep -w '[a-z]*foo[a-z]*'` finds nothing in `x_foo_y`.
- `-x` makes `-w` redundant: `echo foo | grep -wx 'fo*'` matches.
- `-i` / `--no-ignore-case`: **last one on the line wins**, verified in both orders.
- `-i` is locale-dependent: `grep -i 'café'` matches `CAFÉ` under `en_US.UTF-8`, not under `C`.
- `-v` inverts once, after all patterns are ORed. `grep -v -e foo -e FOO` → nothing.
- An empty `-f` file matches **nothing**; an empty pattern matches **every** line.

### Regular expressions
- `[:digit:]` without outer brackets → `grep: character class syntax is [[:space:]], not
  [:space:]`, exit 2.
- `[]^-]` matches `]`, `^` and `-` with no escapes. `[.]` is a literal dot.
- `\w` includes `_`. `\Bfoo` finds nothing in `foo foobar`.
- BRE: `a^b` and `a$b` match those literal texts. ERE: `a^b` matches nothing (exit 1).
- **POSIX is leftmost-longest, PCRE is leftmost-first.** `echo abcd | grep -oE 'ab|abcd'`
  → `abcd`; `grep -oP 'ab|abcd'` → `ab`.
- `{,m}` works in both BRE and ERE (a GNU extension). A malformed `{` is a literal in both.
- Back-references work in ERE too (`grep -oE '(hello) \1'`), which POSIX does not require.
- Two matcher flags are an **error**, not last-wins: `grep -EF` and `grep -E -G` both give
  `grep: conflicting matchers specified`, exit 2.

### Output control
- `-c` counts **lines**, not matches: `echo 'a1 b22 c333' | grep -cE '[0-9]'` → 1, while
  `grep -oE '[0-9]' | wc -l` → 6.
- Priority, whatever order they are written in: `-q` > `-l`/`-L` > `-c` > `-o`.
  Between `-l` and `-L` the last one on the line wins (`-Ll` behaves as `-l`).
- `-o` matches are non-overlapping (`aaaa` → two `aa`) and empty matches are dropped
  (`grep -o 'x*'` prints nothing, exits 0).
- `-m2 -A1` still emits the trailing context of the second match. `-c -m2` caps at 2.
- Default `GREP_COLORS` confirmed by inspecting the emitted SGR: `ms=01;31`, `fn=35`,
  `ln=32`, `se=36`.

### Context and prefixes
- Selected lines close their prefix with `:`, context lines with `-`. Verified with `-n -C1`.
- The `--` separator marks a **gap**: with `-C1` on the sample log it appears, with `-C3`
  the windows overlap and it does not.
- `-NUM` is exactly `-C NUM` (`diff <(grep -2 ...) <(grep -C2 ...)` — identical).
- `-b` gives the line's offset; with `-o`, the match's offset (46 vs 52 on the sample).

### File selection
- `grep -r` **descends into `.git`, `node_modules` and hidden directories.** No ignore file.
- `-r` does not follow a symlinked directory found during descent; `-R` does; `-r` does
  follow one named on the command line. All three verified on the same tree.
- **When recursing, globs match the base name only**, so `--include='src/*.c'` matches
  nothing (exit 1, no warning). The same glob on the command-line operand `src/a.c` *does*
  match, because there any name suffix counts.
- Order of `--include`/`--exclude` changes the result:
  ```
  --include='*.c' --exclude='test_*'   -> 4 files (no tests)
  --exclude='test_*' --include='*.c'   -> 8 files (the whole tree, tests included)
  ```
  Last matching option wins; a file matching none is included unless the *first* such
  option was `--include`.
- `-D read` (the default) blocks on a FIFO; `-D skip` returns immediately, exit 1.

### Binary files, encoding, locale
- A NUL byte suppresses stdout output entirely; the note goes to **stderr**
  (`grep match bin.dat >o 2>e` → `o` empty, `e` = `grep: bin.dat: binary file matches`),
  and the exit status is **0**. `-c` still returns 1 and `-l` still names the file.
- **Valid Latin-1 text with no NUL byte is "binary" under a UTF-8 locale.** For
  `printf 'caf\xe9 match\nplain match\n'`, grep prints `plain match`, suppresses the
  ill-encoded line, and notes it on stderr. `LC_ALL=C` prints both lines; `-a` also prints both.
- **The `LC_ALL=C` speedup is specific to character-class patterns.** On a 20 400 000-byte
  file, three runs each:
  ```
  [a-z]\{4\}x    en_US.UTF-8  0.78 / 0.72 / 0.72 s      C  0.03 / 0.03 / 0.03 s   (~24x)
  zzzz (literal) en_US.UTF-8  0.01 / 0.01 s             C  0.01 / 0.01 s          (no gain)
  ```

### Pipelines
- A file name may contain a newline; `grep -rl` output is then ambiguous. `-Z` + `xargs -0`
  handles it (verified with a file literally named `we\nird.txt`).
- `-Z` changes the separator after **file names**; `-z` changes what a **line** is —
  `printf 'a\nb\nc\n' | grep -zc ''` → 1.
- `--line-buffered` works as documented.
- `ps aux | grep sshd` returns exactly one more line than `ps aux | grep '[s]shd'`.

### PCRE (`-P`)
- Available: `ldd /usr/bin/grep` → `libpcre2-8.so.0`.
- `\d \s \w`, `(?=)`, `(?!)`, `(?<=)`, `\K`, lazy `.+?` all verified.
- `-Pz` matches across newlines; `-P` alone cannot (`grep -P 'foo\nbar'` → exit 1).
- **The backtracking limit is a hard failure, not a slow answer.** 40 `a`s then `X`:
  ```
  grep -P '(a+)+$' bt.txt  -> grep: bt.txt: exceeded PCRE's backtracking limit   exit 2
  grep -E '(a+)+$' bt.txt  -> (no match)   exit 1, 0.00 s
  ```

## Not verifiable here, and therefore not taught as fact

- `-U, --binary` — the man page states it has no effect outside MS-DOS and MS-Windows. The
  course names it and moves on.
- The full `GREP_COLORS` capability table (`sl`, `cx`, `rv`, `ne`, …). Only the defaults
  were checked, by reading the emitted escape sequences; the rest is left to the manual.
- `--devices` on character/block devices — only the FIFO case was exercised.
