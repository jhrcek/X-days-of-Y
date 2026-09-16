# Verified against procps-ng 4.0.7 (pgrep/pkill/pidwait), 2026-09-16

## Man page vs binary: DISCREPANCIES (course follows the binary)

1. `-p, --pid <PID,...>`   present in --help, works, absent from pgrep(1) entirely.
2. `--quiet`               present in --help, works (exit status only), absent from man page.
3. `-Q, --shell-quote`     present in --help, works, absent from man page.
4. `--env <name=val,...>`  present in --help, works, absent from man page.
5. `pkill -m, --mrelease`  present in --help, absent from man page.
6. `pidwait -e`            man page says "-e ... (pkill only.)"; pidwait accepts it and
                           prints "waiting for NAME (pid N)".
7. Over-long pattern       pgrep emits an undocumented diagnostic:
                           "pattern that searches for process name longer than 15 characters
                            will result in zero matches" + "Try `pgrep -f' option..."; exit 1.
8. `-v` semantics          man page says only "Negates the matching". It actually inverts the
                           WHOLE conjunction: `pgrep -u jhrcek -v lab_alpha` returned 656 of 658
                           PIDs INCLUDING pid 1 (root). i.e. NOT(A AND B), not "A AND NOT B".

## Verified behaviour

- Exit: 0 match, 1 no match, 2 syntax/usage, (3 fatal, not reproduced).
  `pgrep -c` prints 0 and exits 1 when nothing matches.
- No args -> "no matching criteria specified", exit 2.
- Two patterns -> "only one pattern can be provided", exit 2.
- `-n -o`, `-n -v` combined -> usage, exit 2 (blank first line, no message).
- comm truncated to 15 chars (/proc/PID/stat): averylongprocessname123 -> averylongproces.
- `-f` matches /proc/PID/cmdline (NUL-joined argv rendered with spaces).
- pgrep never matches itself, BUT matches its parent shell: `pgrep -f pgrep` returned the
  subshell running it. `-A` removes all ancestors: `pgrep -A -f scratchpad` returned nothing
  where `pgrep -f scratchpad` returned 2.
- Pattern is an unanchored ERE. `''` matches everything. `[` -> "regex error: Invalid
  regular expression". `-x` anchors whole string; `-x -f` anchors the whole command line
  ("./bin/lab_alpha 120" matched, "lab_alpha" did not).
- Comma lists OR within one criterion; criteria AND across.
  `-u nosuchuser` -> "invalid user name: nosuchuser", exit 2.
- `-g 0` / `-s 0` translate to pgrep's own pgid/sid. Verified.
- `-d,` joins with the delimiter AND still appends a trailing newline (xxd: ...5237 0a).
- `-c` overrides -l/-a/-d/--quiet: prints only the number.
- `-l` prints name even with `-f`; `-a` prints full cmdline; `-Q` shell-quotes EACH argv
  element separately, so argument boundaries survive:
    -a : 267082 python3 -c import time; time.sleep(500) an arg with spaces quote'y semi;colon
    -Q : 267082 python3 -c 'import time; time.sleep(500)' 'an arg with spaces' 'quote'\''y' 'semi;colon'
- `-w` walks TASKS, not processes, and matches each thread's own comm:
    pgrep gmain      -> nothing
    pgrep -w gmain   -> 96 TIDs
    pgrep -w -x udisksd -> 1230 only (leader thread's comm)
  udisksd pid 1230 threads: 1230 udisksd, 1255 gmain, 1256 pool-spawner, 1260 gdbus,
  1348 udisks-probing-, 1349 udisks-uevent-m, 1358 cleanup.
- `-r` with an invalid state letter (Q) is SILENT: exit 1, nothing on stderr.
- `-O 1` matched; `-O 100000` exit 1.
- `-F file` is an extra AND criterion; works with no pattern. A stale PID is exit 1.
  A non-numeric file -> "pidfile not valid", exit 1. `-L` on an unlocked file -> exit 1,
  "Locking check for pidfile failed: No such file or directory".
- `-w` output is NOT sorted (TID order); process output IS ascending.
- udisksd pid 1230, 7 tasks: udisksd, gmain, pool-spawner, gdbus, udisks-probing-,
  udisks-uevent-m, cleanup. `pgrep -f -c udisksd`=1 but `pgrep -w -f -c udisksd`=7,
  confirming NOTES: threads share the command line but not the name.
- `--cgroup` takes the full cgroup v2 path from /proc/PID/cgroup field 3.
- `--ns $$` works; `--ns 1` -> exit 1 (not root). `--nslist bogus` -> exit 2.
- `--env HOME=$HOME` matched; `--env NOSUCHVAR=1` exit 1.
- `--signal HUP -H` filters to processes with a userspace SIGHUP handler; sleep has
  SigCgt 0000000000000000 and is excluded, bash (SigCgt ...00010000) is not.
- pkill: `-v`, `-w`, `-d` rejected ("invalid option"). pgrep: `-e` rejected.
- pkill `-e` prints "NAME killed (pid N)" EVEN FOR `--signal 0`, which kills nothing
  (verified: both lab_alpha PIDs still alive afterwards).
- pkill `-c` counts matches, not kills.
- pkill `-q 42 --signal USR1` used sigqueue and terminated the targets (default USR1 action).
- pidwait `-e -o lab_alpha` printed "waiting for lab_alpha (pid 267445)", blocked 4s,
  exit 0. `pidwait -c` BLOCKS and prints the count afterwards. `pidwait zzznope` exit 1.

## No configuration surface
pgrep(1) has no ENVIRONMENT section; the binary reads no config file, dotfile or env var
of its own. courseConfig = Nothing.

## Added during writing (all re-verified)

- `pkill --inverse`, `--lightweight`, `--delimiter` are ACCEPTED and take effect; only the
  short `-v`, `-w`, `-d` are rejected. Man page documents only the `-v` case.
    pkill --signal 0 -c -f udisksd               = 3
    pkill --lightweight --signal 0 -c -f udisksd = 9
- pkill exit status: all-denied -> 1; partial (one denied, one signalled) -> 0.
    pkill --signal 0 -e -p 832,274951 ->
      "pkill: killing pid 832 failed: Operation not permitted" / " killed (pid 274951)", exit 0
- `pkill -H --signal TERM -x lab7` (a /bin/sleep copy, SigCgt 0) -> exit 1, survives.
- `pkill -m/--mrelease` works. `pkill -q 42 --signal USR1` works.
- pidwait waits on a NON-CHILD (ppid 4844, not the invoking shell), via pidfd_open.
  `pidwait -c` BLOCKS then prints the count. `pidwait <nomatch>` returns immediately, exit 1.
- `--cgroup` is an EXACT full-path match: basename, slash-less and parent-slice all fail
  (exit 1, silent). Comma lists work.
- `--nslist` KEEPS ONLY THE LAST NAME (undocumented bug in 4.0.7):
    --nslist net = 103   --nslist uts = 142
    --nslist net,uts = 142 (= uts)   --nslist uts,net = 103 (= net)
    --nslist net --nslist uts = uts
- `--ns` as non-root is silently wrong in both directions:
    pgrep --ns $$ -c . = 102, of which root-owned = 0, though 451 root processes share them.
    pgrep --ns 1 -c . = 465, including 451 root-owned.
- `--env NAME=VALUE` exact; `--env NAME` alone is a presence test.
- Empty pattern from an unset shell variable selects EVERY process: `pgrep -c "$UNSET"` = 613
  = `pgrep -c .`. Guard with `"${VAR:?}"`; `set -u` does not catch a set-but-empty variable.
- `/proc` here is mounted without `subset=pid`, so `-O` works (611). NOTES says it fails
  silently under that mount option.
- pid_max on this machine = 4194304.
- killall (PSmisc 23.7) matches names EXACTLY by default: `killall sle` -> "sle: no process
  found", where `pgrep -c sle` = 1.
- `pgrep -q` is NOT valid (`--quiet` is long-form only in pgrep; `-q` is pkill's --queue).
- `--quiet` + `-l`/`-a` is a hard error, exit 2; `--quiet` + `-c` is allowed and -c wins.
- A bash script's comm IS the script basename (bash sets it), truncated to 15:
  a-very-long-script-name.sh -> comm "a-very-long-scr".
- The -f self-match trap, reproduced with a name absent from all ancestors:
  a script running `pgrep -f <its own name>` matches ITSELF; adding -A fixes it.
