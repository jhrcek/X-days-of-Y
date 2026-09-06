# Verification

The course's value is that it is *right*. A man page is a specification; the binary in
front of you is the truth, and they drift. Everything below is cheap and catches real
errors — the tmux course found a genuine man-page/binary disagreement this way.

## While researching (before writing anything)

Probe the binary for everything it will tell you about itself. Use a **throwaway
instance** wherever the tool has persistent state, so nothing touches the user's setup:

```sh
$tool --version
$tool --help 2>&1 | head -50

# tmux-style: an isolated server on its own socket
tmux -L probe new -d -s x
tmux -L probe list-keys -N -T prefix     # real bindings, with their notes
tmux -L probe show -g                    # real option defaults
tmux -L probe kill-server; rm -f /tmp/tmux-$(id -u)/probe

# git-style: a scratch repo
git init /tmp/probe-repo && git -C /tmp/probe-repo config --list --show-origin
```

Record, in a scratch note as you go:

- the exact version the course is checked against (`courseVersion`)
- every default you intend to quote
- **every disagreement** between the page and the binary — these are gold for `gotcha`
  callouts, and must be reported at the end

> Worked example: the tmux man page lists the `M-1`…`M-7` layout bindings in a different
> order from the one `list-keys` actually reports. The course follows the binary and says
> so.

## While writing

**Every config block is tested before it is written into a `ConfBlock`:**

```sh
cat > /tmp/try.conf <<'CONF'
<the candidate block>
CONF
tmux -L try -f /tmp/try.conf new -d -s x
tmux -L try show-messages | grep -viE 'command: '     # must be empty
tmux -L try show -gv <the-option-you-set>             # must be what you claimed
tmux -L try kill-server; rm -f /tmp/tmux-$(id -u)/try
```

**Every format/expression/flag example is run**, not reasoned about. If the output
surprises you, the surprise belongs in the lesson.

Compile after every batch of two or three days: `cabal build all`.

## Final checklist

```sh
cd <repo root>

# 1. builds clean
cabal build all

# 2. regenerates everything
cabal run build-site

# 3. no placeholders left
grep -rn 'TBD' --include='*.html' . | head

# 4. the generated config loads with no errors
tmux -L final -f "$PWD/<slug>/<config file>" new -d -s v
sleep 0.5; tmux -L final show-messages | grep -viE 'command: '   # must be empty
tmux -L final kill-server; rm -f /tmp/tmux-$(id -u)/final

# 5. no olog is scaled below ~65% (see writing-style.md for the arithmetic:
#    832px column / (Npt x 1.333) = scale; ~950pt is the floor)
for f in <slug>/day_*/olog.svg; do
  w=$(grep -o 'width="[0-9]*pt"' "$f" | head -1 | grep -o '[0-9]*')
  [ "$w" -gt 950 ] && echo "TOO WIDE: $f ${w}pt - switch that diagram to rankdir=TB"
done

# 6. GitHub Pages hazards: absolute paths, Jekyll templating, _-prefixed files
grep -ohE '(href|src)="/[^"]*"' <slug>/*.html <slug>/day_*/index.html | head
grep -rl '{{\|{%' --include='*.html' . | head
git ls-files | grep -E '(^|/)_' | head
#   all three must print nothing

# 7. every path resolves the way Pages will serve it
python3 -m http.server 8080 &   # a static server is fine here; it generates nothing
for u in / /<slug>/ /<slug>/reference.html /<slug>/assets/style.css /<slug>/day_01/; do
  curl -s -o /dev/null -w "$u %{http_code}\n" "http://127.0.0.1:8080$u"
done
kill %1
```

## Visual QA

Look at the pages. Layout bugs are invisible in HTML source and obvious in a screenshot.

```sh
google-chrome --headless --disable-gpu --no-sandbox --hide-scrollbars \
  --window-size=1200,9000 --virtual-time-budget=3000 \
  --screenshot=.preview/d01.png <slug>/day_01/index.html
magick .preview/d01.png -crop 1200x2400+0+2400 +repage .preview/d01-mid.png
```

Check at minimum: the landing page, one early day, one late day (the ones with the
densest tables), and `reference.html`. Read the crops — do not just confirm the file
exists. Delete `.preview/` afterwards; it is git-ignored.

## What to report at the end

- what the course covers, and what it deliberately leaves out
- the exact version verified against
- **every man-page/binary discrepancy found**, and which one the course follows
- anything a reader must change for their own machine (clipboard tool, shell, paths)
