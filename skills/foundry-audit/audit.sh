#!/usr/bin/env bash
# foundry-audit — mechanical structural audit of a project's documentation set.
#
# Run from a project root:  bash ~/.claude/skills/foundry-audit/audit.sh
# Or point it somewhere:    bash audit.sh --root /path/to/project
#
# Exit codes:
#   0  every applicable check ran and found nothing
#   1  one or more FAIL findings (see output)
#   2  harness error — no documents found to audit, so nothing was checked
#
# Three result states per check, and the distinction is the point:
#   PASS  the check ran against a real input set and found nothing
#   N/A   the convention genuinely does not apply to this project (e.g. no
#         ADR-style IDs anywhere) — not a gap, does not affect the exit code
#   SKIP  the check should have applied but its input set was unexpectedly
#         empty (e.g. DECISIONS.md exists but has zero parseable headings).
#         This counts as a FAIL finding. A check that cannot run is an
#         unknown, not a clean pass.
#
# Every FAIL-capable check in this script is mutation-tested in
# tests/run_fixtures.sh — a known instance of the defect class is injected
# and the check is confirmed to catch it. Do not add a check here without
# adding its mutation case there.

set -uo pipefail

ROOT="$(pwd)"
NUMERIC_NOUNS=""
EXTRA_DOC_ARGS=""

# A missing value for a flag is a usage error, not a findings-level result —
# `--root` as the final argument used to die on bash's own unbound-variable
# error and exit 1, which reads as "the audit found something".
need_value() {
  if [ "$2" -lt 2 ]; then
    echo "usage error: $1 requires a value" >&2
    exit 2
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --root) need_value "$1" "$#"; ROOT="$2"; shift 2 ;;
    --doc) need_value "$1" "$#"; EXTRA_DOC_ARGS="$EXTRA_DOC_ARGS
$2"; shift 2 ;;
    --numeric) need_value "$1" "$#"; NUMERIC_NOUNS="$NUMERIC_NOUNS
$2"; shift 2 ;;
    -h|--help)
      sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

cd "$ROOT" || { echo "cannot enter root: $ROOT" >&2; exit 2; }
ROOT="$(pwd)"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
FAILS="$WORK/fails"
INFOS="$WORK/infos"
: > "$FAILS"
: > "$INFOS"

fail() { printf '%s\n' "$*" >> "$FAILS"; }
info() { printf '%s\n' "$*" >> "$INFOS"; }

# ---------------------------------------------------------------------------
# Document set
# ---------------------------------------------------------------------------
# Root-level docs Foundry scaffolds or expects, plus anything under docs/.
# Deliberately fixed rather than "every .md in the repo": a skill's own
# SKILL.md, a vendored dependency's README, and a node_modules stray are not
# this project's document set, and sweeping them in produces noise that
# trains a reader to ignore the output.
CANDIDATES="CLAUDE.md DECISIONS.md SESSIONS.md README.md STACK.md USER_GUIDE.md CONTRIBUTING.md"

# The document set is kept in a newline-delimited file, never a space-separated
# string. A path containing a space would otherwise word-split into two
# nonexistent "documents", which doesn't merely miss a check — it manufactures
# false findings (a `docs/my notes.md` was reported as two unreachable docs and
# inflated the scanned count). Same shell-quoting failure class this repo
# already fixed once in the SessionStart hook templates.
DOCS_F="$WORK/docs.txt"
: > "$DOCS_F"
for f in $CANDIDATES; do
  [ -f "$f" ] && printf '%s\n' "$f" >> "$DOCS_F"
done
if [ -d docs ]; then
  find docs -type f -name '*.md' 2>/dev/null | sed 's|^\./||' | sort >> "$DOCS_F"
fi
# --doc lets a project with a different layout add files to the set. A named
# file that doesn't exist is an error, not something to skip quietly — being
# asked to audit a file and silently not auditing it is the failure this whole
# script exists to make impossible.
EXTRA_DOCS_F="$WORK/extradocs.txt"
printf '%s\n' "$EXTRA_DOC_ARGS" | grep -v '^[[:space:]]*$' > "$EXTRA_DOCS_F" 2>/dev/null || : > "$EXTRA_DOCS_F"
if [ -s "$EXTRA_DOCS_F" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if [ ! -f "$f" ]; then
      echo "RESULT: harness error — --doc named '$f', which does not exist. Nothing was checked."
      exit 2
    fi
    grep -qxF "$f" "$DOCS_F" || printf '%s\n' "$f" >> "$DOCS_F"
  done < "$EXTRA_DOCS_F"
fi

DOC_COUNT=$(wc -l < "$DOCS_F" | tr -d ' ')

echo "foundry-audit — $ROOT"
if [ "$DOC_COUNT" -eq 0 ]; then
  echo "RESULT: harness error — no documents found (looked for: $CANDIDATES, docs/**/*.md)."
  echo "Nothing was checked. This is not a clean result."
  exit 2
fi
echo "scanned $DOC_COUNT file(s): $(tr '\n' '|' < "$DOCS_F" | sed 's/|$//; s/|/, /g')"
echo

# Concatenated corpus, for checks that scan everything at once.
ALL="$WORK/all.txt"
: > "$ALL"
while IFS= read -r f; do
  [ -z "$f" ] && continue
  # Prefix each line with its source file so findings can name it.
  awk -v F="$f" '{print F "\t" $0}' "$f" >> "$ALL"
done < "$DOCS_F"

# Optional per-project allowlist of paths that are referenced deliberately
# before they exist (a planned file, a path in an example command).
# Absent file = empty allowlist; that is the normal case, not a gap.
ALLOW="$WORK/allow.txt"
: > "$ALLOW"
ALLOW_COUNT=0
if [ -f .foundry-audit-allow ]; then
  grep -v '^[[:space:]]*#' .foundry-audit-allow | grep -v '^[[:space:]]*$' > "$ALLOW" 2>/dev/null || true
  ALLOW_COUNT=$(wc -l < "$ALLOW" | tr -d ' ')
fi

report() { printf '[%s] %s\n' "$1" "$2"; }

# ---------------------------------------------------------------------------
# 1. Decision headings parse
# ---------------------------------------------------------------------------
# Foundry's DECISIONS.md convention is "## <ISO date> — <title>", newest first.
# (Verified against templates/DECISIONS.md.template — Foundry does not use
# ADR-NNN identifiers; that convention is detected separately in check 4.)
DHEADS="$WORK/dheads.txt"
: > "$DHEADS"
HAS_DECISIONS=0
if [ -f DECISIONS.md ]; then
  HAS_DECISIONS=1
  grep -E '^## [0-9]{4}-[0-9]{2}-[0-9]{2}' DECISIONS.md \
    | sed -E 's/^## ([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/' > "$DHEADS" 2>/dev/null || true
fi
DHEAD_COUNT=$(wc -l < "$DHEADS" | tr -d ' ')

if [ "$HAS_DECISIONS" -eq 0 ]; then
  report "N/A " "decision headings — no DECISIONS.md in this project"
elif [ "$DHEAD_COUNT" -eq 0 ]; then
  report SKIP "decision headings — DECISIONS.md exists but no '## YYYY-MM-DD' heading parsed"
  fail "DECISIONS.md has no parseable '## <ISO date> — <title>' headings. Every decision-log check below that depends on them could not run, so their silence means nothing."
else
  report PASS "decision headings — $DHEAD_COUNT parsed"
fi

# ---------------------------------------------------------------------------
# 2. Decision-reference resolution (by date)
# ---------------------------------------------------------------------------
# Recognised reference forms (documented in SKILL.md so a reader knows exactly
# what is and is not checked):
#   - any ISO date on a line that also mentions DECISIONS.md or "decision log"
#   - "the <ISO date> entry" / "entries" / "decision"
DREFS="$WORK/drefs.txt"
: > "$DREFS"
if [ "$DHEAD_COUNT" -gt 0 ]; then
  grep -iE 'DECISIONS\.md|decision log' "$ALL" \
    | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' >> "$DREFS" 2>/dev/null || true
  grep -oiE 'the [0-9]{4}-[0-9]{2}-[0-9]{2} (entry|entries|decision)' "$ALL" \
    | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' >> "$DREFS" 2>/dev/null || true
  sort -u "$DREFS" -o "$DREFS"
  # Same allowlist semantics as paths and ADR IDs: a document recounting a
  # dangling reference has to write the dangling value down, and that mention
  # is not itself a reference.
  if [ "$ALLOW_COUNT" -gt 0 ] && [ -s "$DREFS" ]; then
    grep -vxF -f "$ALLOW" "$DREFS" > "$DREFS.f" 2>/dev/null || : > "$DREFS.f"
    mv "$DREFS.f" "$DREFS"
  fi
fi
DREF_COUNT=$(wc -l < "$DREFS" | tr -d ' ')

if [ "$DHEAD_COUNT" -eq 0 ]; then
  report "N/A " "decision references — no decision headings to resolve against (see above)"
elif [ "$DREF_COUNT" -eq 0 ]; then
  report "N/A " "decision references — no cross-references to decision entries found"
else
  DANGLING=""
  DN=0
  while IFS= read -r d; do
    [ -z "$d" ] && continue
    if ! grep -qx "$d" "$DHEADS"; then
      DANGLING="$DANGLING $d"
      DN=$((DN + 1))
    fi
  done < "$DREFS"
  if [ "$DN" -gt 0 ]; then
    report FAIL "decision references — $DN of $DREF_COUNT do not resolve"
    for d in $DANGLING; do
      WHERE=$(grep -iE 'DECISIONS\.md|decision log' "$ALL" | grep -F "$d" | head -1 | cut -f1)
      fail "dangling decision reference: $d (cited in ${WHERE:-a doc}) has no '## $d' heading in DECISIONS.md"
    done
  else
    report PASS "decision references — $DREF_COUNT checked, all resolve"
  fi
fi

# ---------------------------------------------------------------------------
# 3. Decision ordering (newest first)
# ---------------------------------------------------------------------------
if [ "$DHEAD_COUNT" -lt 2 ]; then
  report "N/A " "decision ordering — fewer than 2 dated entries"
else
  SORTED="$WORK/dsorted.txt"
  sort -r "$DHEADS" > "$SORTED"
  if diff -q "$DHEADS" "$SORTED" >/dev/null 2>&1; then
    report PASS "decision ordering — newest-first holds across $DHEAD_COUNT entries"
  else
    report FAIL "decision ordering — entries are not in newest-first order"
    FIRSTBAD=$(diff "$DHEADS" "$SORTED" | head -4 | tr '\n' ' ')
    fail "DECISIONS.md is not in the newest-first order its own header states. First divergence: $FIRSTBAD"
  fi
fi

# ---------------------------------------------------------------------------
# 4. ADR-style identifiers (auto-detected; N/A for projects that don't use them)
# ---------------------------------------------------------------------------
ADR_REFS="$WORK/adrrefs.txt"
ADR_DEFS="$WORK/adrdefs.txt"
grep -oE 'ADR-[0-9]{3,}' "$ALL" 2>/dev/null | sort -u > "$ADR_REFS" || true
# The allowlist suppresses identifiers as well as paths. A document that
# *discusses* dangling references has to write an example one out, and that
# example is not a reference — the same distinction the path check draws
# between a filename as subject matter and a filename as a link.
if [ "$ALLOW_COUNT" -gt 0 ] && [ -s "$ADR_REFS" ]; then
  grep -vxF -f "$ALLOW" "$ADR_REFS" > "$ADR_REFS.f" 2>/dev/null || : > "$ADR_REFS.f"
  mv "$ADR_REFS.f" "$ADR_REFS"
fi
: > "$ADR_DEFS"
[ -f DECISIONS.md ] && grep -oE '^#{2,3} (ADR-[0-9]{3,})' DECISIONS.md 2>/dev/null \
  | grep -oE 'ADR-[0-9]{3,}' | sort -u > "$ADR_DEFS" || true
ADR_REF_COUNT=$(wc -l < "$ADR_REFS" | tr -d ' ')
ADR_DEF_COUNT=$(wc -l < "$ADR_DEFS" | tr -d ' ')

if [ "$ADR_REF_COUNT" -eq 0 ]; then
  report "N/A " "ADR identifiers — this project does not use ADR-NNN IDs"
elif [ "$ADR_DEF_COUNT" -eq 0 ]; then
  report SKIP "ADR identifiers — $ADR_REF_COUNT reference(s) found but no '## ADR-NNN' heading defines any"
  fail "Documents reference ADR-NNN identifiers ($ADR_REF_COUNT of them) but DECISIONS.md defines none as headings — either the convention moved or every one of those references is dangling. Not checkable as-is."
else
  ADR_BAD=$(comm -23 "$ADR_REFS" "$ADR_DEFS" | tr '\n' ' ')
  if [ -n "$(echo "$ADR_BAD" | tr -d ' ')" ]; then
    report FAIL "ADR identifiers — dangling: $ADR_BAD"
    for a in $ADR_BAD; do
      fail "dangling ADR reference: $a is cited but has no defining heading in DECISIONS.md"
    done
  else
    report PASS "ADR identifiers — $ADR_REF_COUNT reference(s) all resolve to $ADR_DEF_COUNT definition(s)"
  fi
fi

# ---------------------------------------------------------------------------
# 5. File-path references resolve
# ---------------------------------------------------------------------------
# Backticked repo-relative paths only. Absolute paths, ~-paths, URLs and globs
# are deliberately out of scope — they are not this repo's to verify.
#
# Precision matters more than recall here, and that is a finding from running
# this against a real doc set rather than a design preference. Documentation
# routinely discusses filenames as *subject matter* — `.gitignore` pattern
# examples, test-fixture names, "a file like `config/prod.yaml`" — and those
# are not references to anything in the repo. Treating every backticked
# filename as a reference produced 35 findings on Foundry's own docs of which
# roughly 20 were that class, which is the precision level at which a reader
# learns to ignore the output entirely.
#
# So references are split by confidence, using one signal that turns out to
# separate them well: does the reference's first path segment name something
# that actually exists at the top of this repo?
#   FAIL — first segment is a real top-level entry, full path is missing.
#          A reference INTO this repo's real tree that has gone stale.
#   INFO — anything else that doesn't resolve (bare filenames, paths rooted
#          at a directory this repo doesn't have). Reported as one grouped
#          line, since this bucket is dominated by legitimate examples.
PATHS="$WORK/paths.txt"
grep -oE '`[A-Za-z0-9_][A-Za-z0-9_./-]*\.(md|json|sh|py|ya?ml|txt|template|toml|cfg|ini|lock)`|`[A-Za-z0-9_][A-Za-z0-9_./-]*/`' "$ALL" 2>/dev/null \
  | tr -d '`' | sort -u > "$PATHS" || true
PATH_COUNT=$(wc -l < "$PATHS" | tr -d ' ')

# Directories that are copies of, or vendored into, this repo — searching them
# for a "the file moved here" hint yields a path nobody can act on. A git
# worktree under .claude/worktrees/ is a full second copy of this same repo
# and produced exactly that garbage before this was excluded.
PRUNE='-name .git -o -name .claude -o -name node_modules -o -name .venv -o -name venv -o -name dist -o -name build -o -name target'

if [ "$PATH_COUNT" -eq 0 ]; then
  report "N/A " "file-path references — none found in backticks"
else
  MISSING=0
  ALLOWED=0
  UNRESOLVED=""
  UNRESOLVED_N=0
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    if [ -e "$p" ]; then continue; fi
    if [ "$ALLOW_COUNT" -gt 0 ] && grep -qxF "$p" "$ALLOW"; then
      ALLOWED=$((ALLOWED + 1)); continue
    fi
    FIRST="${p%%/*}"
    if [ "$FIRST" != "$p" ] && [ -e "$FIRST" ]; then
      # High confidence: points into a directory this repo really has.
      MISSING=$((MISSING + 1))
      WHERE=$(grep -F "\`$p\`" "$ALL" | head -1 | cut -f1)
      BN="$(basename "$p")"
      ELSEWHERE=$(find . \( $PRUNE \) -prune -o -name "$BN" -print 2>/dev/null | head -1)
      if [ -n "$ELSEWHERE" ]; then
        fail "broken path reference: \`$p\` (in ${WHERE:-a doc}) does not exist — but a file named $BN exists at ${ELSEWHERE#./} (likely a rename that missed a spot)"
      else
        fail "broken path reference: \`$p\` (in ${WHERE:-a doc}) does not exist anywhere in the repo"
      fi
    else
      UNRESOLVED_N=$((UNRESOLVED_N + 1))
      UNRESOLVED="$UNRESOLVED $p"
    fi
  done < "$PATHS"

  if [ "$UNRESOLVED_N" -gt 0 ]; then
    info "$UNRESOLVED_N backticked name(s) don't resolve to a file here and aren't rooted in a real top-level directory, so they're most likely illustrative examples rather than references — but scan the list for anything that was meant as a real link:$UNRESOLVED"
  fi
  if [ "$MISSING" -gt 0 ]; then
    report FAIL "file-path references — $MISSING broken of $PATH_COUNT ($ALLOWED allowlisted, $UNRESOLVED_N unresolved-but-probably-examples, see below)"
  else
    report PASS "file-path references — $PATH_COUNT checked, no broken repo-rooted paths ($ALLOWED allowlisted, $UNRESOLVED_N unresolved-but-probably-examples)"
  fi
fi

# ---------------------------------------------------------------------------
# 6. "Enforced at:" targets resolve
# ---------------------------------------------------------------------------
# The mechanism DECISIONS.md's 2026-08-17 entry stopped short of building:
# a decision may name where it becomes real; if it names a path, that path
# has to exist.
ENF_LINES="$WORK/enf.txt"
: > "$ENF_LINES"
[ -f DECISIONS.md ] && grep -nE '^\*?\*?- \*\*Enforced at:\*\*|^\- \*\*Enforced at:\*\*' DECISIONS.md > "$ENF_LINES" 2>/dev/null || true
ENF_COUNT=$(wc -l < "$ENF_LINES" | tr -d ' ')

if [ "$HAS_DECISIONS" -eq 0 ]; then
  report "N/A " "enforcement loci — no DECISIONS.md"
elif [ "$ENF_COUNT" -eq 0 ]; then
  report "N/A " "enforcement loci — no entry uses the optional 'Enforced at:' field yet"
else
  ENF_BAD=0
  ENF_PATHS=0
  ENF_PROSE=0
  while IFS= read -r line; do
    LNO="${line%%:*}"
    # A locus stated only in prose ("tracked in the roadmap", "the next work
    # unit") names nothing anything can check, so it rots without trace. This
    # is not hypothetical: the first entry in this repo ever to use the field
    # named a roadmap item that was never added, and it took a hand grep to
    # notice — a defect this check would have surfaced immediately.
    if ! printf '%s' "$line" | grep -qE '`[A-Za-z0-9_][A-Za-z0-9_./-]*(\.[A-Za-z0-9]+|/)`'; then
      ENF_PROSE=$((ENF_PROSE + 1))
    fi
    for p in $(printf '%s' "$line" | grep -oE '`[A-Za-z0-9_][A-Za-z0-9_./-]*\.(md|json|sh|py|ya?ml|txt|template|toml)`' | tr -d '`'); do
      ENF_PATHS=$((ENF_PATHS + 1))
      if [ ! -e "$p" ]; then
        if [ "$ALLOW_COUNT" -gt 0 ] && grep -qxF "$p" "$ALLOW"; then continue; fi
        ENF_BAD=$((ENF_BAD + 1))
        fail "unenforceable decision: DECISIONS.md:$LNO names \`$p\` as its enforcement locus, but that path does not exist"
      fi
    done
  done < "$ENF_LINES"
  if [ "$ENF_BAD" -gt 0 ]; then
    report FAIL "enforcement loci — $ENF_BAD of $ENF_PATHS named path(s) do not exist"
  else
    report PASS "enforcement loci — $ENF_COUNT entry/entries, $ENF_PATHS named path(s), all exist"
  fi
  if [ "$ENF_PROSE" -gt 0 ]; then
    info "$ENF_PROSE 'Enforced at:' line(s) name no checkable path — the locus is stated in prose only, so nothing can verify it still exists. Prose loci rot silently; this exact failure has happened in this repo. Where the locus is a real file, name it in backticks."
  fi
fi

# Informational: how many decisions carry no enforcement locus at all. The
# field is optional by design, so this is never a FAIL — but the 2026-08-17
# decision explicitly asked that its absence be noticeable rather than
# silently treated as fine, and this line is that mechanism.
if [ "$DHEAD_COUNT" -gt 0 ]; then
  UNENFORCED=$((DHEAD_COUNT - ENF_COUNT))
  [ "$UNENFORCED" -lt 0 ] && UNENFORCED=0
  if [ "$UNENFORCED" -gt 0 ]; then
    info "$UNENFORCED of $DHEAD_COUNT dated decision entries name no 'Enforced at:' locus. The field is optional, so this is not a defect — but a decision nothing checks is one that gets discovered violated rather than obeyed. Expected to be large in a log that predates the field."
  fi
fi

# ---------------------------------------------------------------------------
# 7. Structural integrity
# ---------------------------------------------------------------------------
STRUCT_BAD=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  # `grep -c` prints 0 and exits 1 when there are no matches; `|| echo 0`
  # would append a second line and break the arithmetic below.
  FENCES=$(grep -c '^```' "$f" 2>/dev/null || true)
  [ -z "$FENCES" ] && FENCES=0
  if [ $((FENCES % 2)) -ne 0 ]; then
    fail "$f: odd number of code fences ($FENCES) — a fence is unclosed, which silently swallows the rest of the document in most renderers"
    STRUCT_BAD=$((STRUCT_BAD + 1))
  fi
  if [ -s "$f" ] && [ "$(tail -c 1 "$f" | wc -l | tr -d ' ')" -eq 0 ]; then
    fail "$f: no trailing newline — a common sign the file was truncated on write"
    STRUCT_BAD=$((STRUCT_BAD + 1))
  fi
  # Placeholder markers left behind. Deliberately narrow: only the
  # "left a marker in the document" shapes, so prose that merely discusses a
  # TODO does not fire. (`TODO:` / `FIXME:` / a bare list-item TODO / TKTK /
  # Lorem ipsum.)
  #
  # Inline code spans are stripped first. A marker inside backticks is being
  # *discussed* — documentation about placeholder markers necessarily writes
  # them out — whereas a real leftover marker is never formatted as code.
  # Found by running this against Foundry's own USER_GUIDE, which describes
  # this very check and tripped it.
  MARK=$(sed 's/`[^`]*`//g' "$f" 2>/dev/null | grep -nE '(TODO:|FIXME:|TKTK|Lorem ipsum)|^[[:space:]]*[-*][[:space:]]+(TODO|FIXME)\b|^[[:space:]]*(TODO|FIXME)\b' | head -3)
  if [ -n "$MARK" ]; then
    fail "$f: placeholder marker left in the document — $(printf '%s' "$MARK" | head -1 | cut -c1-90)"
    STRUCT_BAD=$((STRUCT_BAD + 1))
  fi
  # Table column consistency, ignoring fenced code blocks.
  BADROW=$(awk '
    /^```/ { infence = !infence; next }
    infence { next }
    /^[[:space:]]*\|/ {
      n = gsub(/\|/, "|")
      if (intable && n != cols) { print NR ": expected " cols " pipes, found " n; exit }
      if (!intable) { intable = 1; cols = n }
      next
    }
    { intable = 0 }
  ' "$f")
  if [ -n "$BADROW" ]; then
    fail "$f: markdown table has an inconsistent column count at line $BADROW"
    STRUCT_BAD=$((STRUCT_BAD + 1))
  fi
done < "$DOCS_F"
if [ "$STRUCT_BAD" -gt 0 ]; then
  report FAIL "structural integrity — $STRUCT_BAD issue(s) across $DOC_COUNT file(s)"
else
  report PASS "structural integrity — fences, trailing newlines, tables, placeholder markers ($DOC_COUNT files)"
fi

# ---------------------------------------------------------------------------
# 8. Reachability from the entry points
# ---------------------------------------------------------------------------
ENTRY=""
[ -f CLAUDE.md ] && ENTRY="$ENTRY CLAUDE.md"
[ -f README.md ] && ENTRY="$ENTRY README.md"
if [ -z "$ENTRY" ]; then
  report SKIP "reachability — neither CLAUDE.md nor README.md exists to walk from"
  fail "No CLAUDE.md and no README.md: there is no entry point to check document reachability from, so that check could not run."
else
  REACH="$WORK/reach.txt"
  FRONTIER="$WORK/frontier.txt"
  : > "$REACH"
  printf '%s\n' $ENTRY > "$FRONTIER"
  DEPTH=0
  while [ -s "$FRONTIER" ] && [ "$DEPTH" -lt 12 ]; do
    NEXT="$WORK/next.txt"
    : > "$NEXT"
    while IFS= read -r cur; do
      [ -z "$cur" ] && continue
      grep -qxF "$cur" "$REACH" && continue
      printf '%s\n' "$cur" >> "$REACH"
      [ -f "$cur" ] || continue
      { grep -oE '`[A-Za-z0-9_][A-Za-z0-9_./-]*\.md`' "$cur" 2>/dev/null | tr -d '`'
        grep -oE '\]\([A-Za-z0-9_][A-Za-z0-9_./-]*\.md\)' "$cur" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//'
      } >> "$NEXT"
    done < "$FRONTIER"
    sort -u "$NEXT" -o "$NEXT"
    cp "$NEXT" "$FRONTIER"
    DEPTH=$((DEPTH + 1))
  done
  UNREACH_F="$WORK/unreach.txt"
  : > "$UNREACH_F"
  UN=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if ! grep -qxF "$f" "$REACH"; then
      printf '%s\n' "$f" >> "$UNREACH_F"
      UN=$((UN + 1))
    fi
  done < "$DOCS_F"
  if [ "$UN" -gt 0 ]; then
    report FAIL "reachability — $UN doc(s) not reachable from$ENTRY"
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      fail "unreachable doc: $f is never linked or referenced from$ENTRY (directly or transitively) — nobody arriving at this project will find it"
    done < "$UNREACH_F"
  else
    report PASS "reachability — all $DOC_COUNT doc(s) reachable from$ENTRY"
  fi
fi

# ---------------------------------------------------------------------------
# 9. Absolute-rule candidates outside the auto-loaded file (judgment-assisted)
# ---------------------------------------------------------------------------
# This one does NOT decide anything. It surfaces candidate absolute rules that
# live only in a document the SessionStart hook does not load, for a human or
# an assistant to compare against CLAUDE.md. Whether two differently-worded
# rules are "the same rule" is not a mechanical question, and this check does
# not pretend otherwise — it is reported as INFO, never FAIL.
if [ -f CLAUDE.md ]; then
  AUTOLOADED="CLAUDE.md DECISIONS.md SESSIONS.md"
  CAND=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    case " $AUTOLOADED " in *" $f "*) continue ;; esac
    N=$(grep -cE '^[[:space:]]*[-*][[:space:]].*(\bnever\b|\bmust never\b|\bunder no circumstances\b|\bnon-negotiable\b)' "$f" 2>/dev/null || true)
    [ -z "$N" ] && N=0
    if [ "$N" -gt 0 ]; then
      CAND=$((CAND + N))
      info "$f contains $N absolute-sounding rule line(s) ('never' / 'non-negotiable'). $f is not auto-loaded by the SessionStart hook. Compare each against CLAUDE.md's Rules section: anything genuinely absolute belongs restated there. (Judgment call — this check surfaces candidates, it does not decide.)"
    fi
  done < "$DOCS_F"
  if [ "$CAND" -eq 0 ]; then
    report "PASS" "absolute-rule coverage — no absolute-sounding rules found outside the auto-loaded docs (judgment-assisted)"
  else
    report "INFO" "absolute-rule coverage — $CAND candidate line(s) to compare by hand (judgment-assisted, never a FAIL)"
  fi
else
  report "N/A " "absolute-rule coverage — no CLAUDE.md to compare against"
fi

# ---------------------------------------------------------------------------
# 10. Numeric-claim agreement (opt-in, one noun at a time)
# ---------------------------------------------------------------------------
# Fully mechanical once a noun is chosen; choosing which nouns matter is
# judgment, which is why this is a flag rather than a fixed list.
if [ -n "$(printf '%s' "$NUMERIC_NOUNS" | tr -d '[:space:]')" ]; then
  printf '%s\n' "$NUMERIC_NOUNS" | grep -v '^[[:space:]]*$' > "$WORK/nouns.txt"
  while IFS= read -r noun; do
    [ -z "$noun" ] && continue
    VALS=$(grep -oiE '(one|two|three|four|five|six|seven|eight|nine|ten|[0-9]+)[ -]'"$noun" "$ALL" 2>/dev/null \
      | sed -E 's/[ -]'"$noun"'$//I' | tr '[:upper:]' '[:lower:]' \
      | sed -e 's/^one$/1/' -e 's/^two$/2/' -e 's/^three$/3/' -e 's/^four$/4/' \
            -e 's/^five$/5/' -e 's/^six$/6/' -e 's/^seven$/7/' -e 's/^eight$/8/' \
            -e 's/^nine$/9/' -e 's/^ten$/10/' \
      | sort -u | tr '\n' ' ')
    NV=$(printf '%s' "$VALS" | wc -w | tr -d ' ')
    if [ "$NV" -eq 0 ]; then
      report "N/A " "numeric agreement '$noun' — no counted mentions found"
    elif [ "$NV" -gt 1 ]; then
      report FAIL "numeric agreement '$noun' — disagrees across files: $VALS"
      fail "numeric claim '$noun' disagrees across the doc set: found $VALS. One place was edited and another was not."
    else
      report PASS "numeric agreement '$noun' — consistent ($VALS)"
    fi
  done < "$WORK/nouns.txt"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
NFAIL=$(wc -l < "$FAILS" | tr -d ' ')
NINFO=$(wc -l < "$INFOS" | tr -d ' ')

echo
if [ "$NFAIL" -gt 0 ]; then
  echo "FINDINGS ($NFAIL):"
  while IFS= read -r l; do echo "  - $l"; done < "$FAILS"
  echo
fi
if [ "$NINFO" -gt 0 ]; then
  echo "FOR REVIEW — judgment required, not defects ($NINFO):"
  while IFS= read -r l; do echo "  - $l"; done < "$INFOS"
  echo
fi

if [ "$NFAIL" -eq 0 ]; then
  echo "RESULT: CLEAN — every applicable check ran and found nothing."
  exit 0
else
  echo "RESULT: $NFAIL finding(s)."
  exit 1
fi
