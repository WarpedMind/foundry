#!/usr/bin/env bash
# Re-runnable version of the adversarial fixture checks referenced in
# skills/foundry-security/SKILL.md and skills/foundry-hooks/SKILL.md.
# Tests the actual .gitignore baseline and secrets-guard regex against
# committed fixture lists in tests/fixtures/, so a future change to either
# pattern gets re-verified automatically instead of relying on a one-time
# manual check from when the pattern was designed.
set -euo pipefail
cd "$(dirname "$0")"
REPO_ROOT="$(cd .. && pwd)"

FAIL=0

# --- .gitignore baseline ---
echo "== .gitignore baseline (tests/fixtures/gitignore-cases.txt) =="
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
cat > "$TMPDIR/.gitignore" <<'EOF'
.env
.env.*
!.env.example
*.pem*
*.key*
config*.yaml*
config*.yml*
config*.json*
config/**/*.yaml
config/**/*.yml
config/**/*.json
secret*.yaml
secret*.yml
secret*.env
secret*.json
*secret*.yaml
*secret*.yml
*secret*.json
*_secret.*
*-secret.*
*credential*.yaml
*credential*.yml
*credential*.json
*.credentials*
*service*account*.json
id_rsa
id_dsa
id_ecdsa
id_ed25519
*.tfstate
*.tfstate.*
*.tfvars
.npmrc
*.pfx
EOF
git -C "$TMPDIR" init -q

while read -r expect path; do
  [ -z "${expect:-}" ] && continue
  case "$expect" in \#*) continue ;; esac
  mkdir -p "$TMPDIR/$(dirname "$path")"
  : > "$TMPDIR/$path"
  if git -C "$TMPDIR" check-ignore -q "$path"; then
    actual=ignore
  else
    actual=keep
  fi
  if [ "$actual" != "$expect" ]; then
    echo "  FAIL: $path — expected $expect, got $actual"
    FAIL=1
  fi
done < fixtures/gitignore-cases.txt
echo "  done."

# --- secrets-guard pre-commit regex ---
echo "== secrets-guard regex (tests/fixtures/secrets-guard-cases.txt) =="
while read -r expect path; do
  [ -z "${expect:-}" ] && continue
  case "$expect" in \#*) continue ;; esac
  STAGED="$path"
  FORBIDDEN=$(echo "$STAGED" | grep -vE '(^|/)\.env\.example$' | grep -iE '(^|/)\.env(\.[^/]*)?$|\.pem(\.[^/]*)?$|\.key(\.[^/]*)?$|(^|/)config[^/]*\.ya?ml(\.[^/]*)?$|(^|/)config/.*\.ya?ml(\.[^/]*)?$|(^|/)config[^/]*\.json$|(^|/)config/.*\.json$|(^|[/_.-])secrets?([_.-]|$)|(^|[/_.-])credentials?([_.-]|$)|(^|[/_.-])service[_-]?account[_-]?.*\.json$|(^|/)id_(rsa|dsa|ecdsa|ed25519)$|\.tfstate(\.[^/]*)?$|\.tfvars$|(^|/)\.npmrc$|\.pfx$' || true)
  if [ -n "$FORBIDDEN" ]; then
    actual=block
  else
    actual=allow
  fi
  if [ "$actual" != "$expect" ]; then
    echo "  FAIL: $path — expected $expect, got $actual"
    FAIL=1
  fi
done < fixtures/secrets-guard-cases.txt
echo "  done."

# --- Hook 4: directory-drift logger ---
# Cases live inline here rather than in tests/fixtures/*.txt: the other two
# suites match a static string against a regex/glob, but this hook parses a
# full Bash command string (cd/pushd, quoting, $HOME expansion), so each case
# needs a real root directory and a real target directory to resolve against
# rather than a bare filename. Inline keeps the command-with-special-chars
# cases (&&, ;, quotes) readable without inventing a second file format.
echo "== directory-drift hook (Hook 4, skills/foundry-hooks/SKILL.md) =="
DRIFT_TMPDIR=$(mktemp -d)
DROOT="$DRIFT_TMPDIR/proj-root"
DOTHER="$DRIFT_TMPDIR/proj-other"
DSIBLING="$DRIFT_TMPDIR/proj-rootx"
# $HOME-expansion case must point at a directory that really exists under
# the real $HOME, since the hook resolves with `cd` — a scratch tmpdir path
# substituted after "$HOME/" wouldn't actually exist there.
DHOMEOTHER="$HOME/.foundry-test-drift-home-case"
mkdir -p "$DROOT/sub" "$DOTHER" "$DSIBLING" "$DHOMEOTHER"

run_drift_hook() {
  # Mirrors the exact extraction/expansion logic in Hook 4's command.
  local cmd="$1" root="$2"
  local CMD="$cmd"
  local TARGET
  TARGET=$(echo "$CMD" | grep -oE '^(cd|pushd)[[:space:]]+(--[[:space:]]+)?[^&;]+' | sed -E 's/^(cd|pushd)[[:space:]]+//' | sed -E 's/^--[[:space:]]+//' | sed -E 's/[[:space:]]+$//' | sed -E 's/^"(.*)"$/\1/' | sed -E "s/^'(.*)'\$/\1/")
  TARGET="${TARGET/#\~/$HOME}"
  TARGET="${TARGET//\$HOME/$HOME}"
  if [ -n "$TARGET" ]; then
    local REAL_TARGET
    REAL_TARGET=$(cd "$TARGET" 2>/dev/null && pwd)
    if [ -n "$REAL_TARGET" ] && [ "$REAL_TARGET" != "$root" ] && [[ "$REAL_TARGET" != "$root"/* ]]; then
      echo "drift"
      return
    fi
  fi
  echo "silent"
}

check_drift_case() {
  local expect="$1" root="$2" cmd="$3" label="$4"
  local actual
  actual=$(run_drift_hook "$cmd" "$root")
  if [ "$actual" != "$expect" ]; then
    echo "  FAIL: $label — expected $expect, got $actual"
    FAIL=1
  fi
}

check_drift_case drift   "$DROOT" "cd $DOTHER && ls"               "cd to other project"
check_drift_case drift   "$DROOT" "pushd $DOTHER"                  "pushd to other project"
check_drift_case drift   "$DROOT" "cd -- $DOTHER"                  "cd -- to other project"
check_drift_case drift   "$DROOT" "cd \"\$HOME/$(basename "$DHOMEOTHER")\"" "quoted \$HOME expansion"
check_drift_case drift   "$DROOT" "cd $DSIBLING"                   "sibling dir with similar prefix (rootx vs root)"
check_drift_case silent  "$DROOT" "cd $DROOT/sub"                  "cd to own subdirectory"
check_drift_case silent  "$DROOT" "cd $DROOT"                      "cd to project root itself"
check_drift_case silent  "$DROOT" "ls -la"                         "no cd at all"
check_drift_case silent  "$DROOT" "cd /nonexistent/path/xyz"       "nonexistent path"
check_drift_case silent  "$DROOT" "echo hello; cd $DOTHER"         "mid-chain cd (documented limitation)"
check_drift_case silent  "$DROOT" "cd \"\$(echo $DOTHER)\""        "command substitution must NOT be evaluated"
check_drift_case silent  "$DROOT" "pushd_helper.sh $DOTHER"        "pushd-prefixed non-drift command"
check_drift_case silent  "$DROOT" "cd_helper $DOTHER"              "cd-prefixed non-drift command"
check_drift_case silent  "$DROOT" "echo pushd $DOTHER"             "pushd not at start of command"

rm -rf "$DRIFT_TMPDIR" "$DHOMEOTHER"
echo "  done."

# --- Hook 3: status/offer hook ---
# Same inline-case approach as Hook 4: this hook reads JSON fields and branches
# on string equality, not a static filename, so it doesn't fit *.txt's shape.
echo "== status/offer hook (Hook 3, templates/settings.status.json.template) =="
STATUS_TMPDIR=$(mktemp -d)
STATUS_CMD=$(jq -r '.hooks.SessionStart[].hooks[] | select(.type=="command") | .command' "$REPO_ROOT/templates/settings.status.json.template")
cd "$STATUS_TMPDIR"

check_status_case() {
  local label="$1" content="$2" expect_substr="$3"
  mkdir -p .claude
  printf '%s' "$content" > .claude/settings.json
  local actual
  actual=$(echo '{}' | bash -c "$STATUS_CMD" | jq -r '.hookSpecificOutput.additionalContext')
  case "$actual" in
    *"$expect_substr"*) ;;
    *) echo "  FAIL: $label — expected substring '$expect_substr', got '$actual'"; FAIL=1 ;;
  esac
}

check_status_case "empty file"                  ""                                                                  "not set up"
check_status_case "scaffolded, no date"          '{"foundry":{"scaffolded":true}}'                                  "Foundry: Active (scaffolded an unknown date)"
check_status_case "scaffolded, empty date"       '{"foundry":{"scaffolded":true,"scaffoldedDate":""}}'              "Foundry: Active (scaffolded an unknown date)"
check_status_case "scaffolded, normal date"      '{"foundry":{"scaffolded":true,"scaffoldedDate":"2026-01-01"}}'    "Foundry: Active (scaffolded 2026-01-01)"
check_status_case "dismissed"                    '{"foundry":{"dismissed":true}}'                                   ""
check_status_case "neither"                      '{}'                                                                "not set up"
check_status_case "malformed json"               '{not valid'                                                        "not set up"
check_status_case "top-level array"              '[1,2,3]'                                                           "not set up"
check_status_case "string \"true\" not boolean"  '{"foundry":{"scaffolded":"true","scaffoldedDate":"2026-02-02"}}'   "Foundry: Active (scaffolded 2026-02-02)"
check_status_case "contradictory both true"      '{"foundry":{"scaffolded":true,"dismissed":true,"scaffoldedDate":"2026-03-03"}}' "Foundry: Active (scaffolded 2026-03-03)"

cd "$REPO_ROOT"
rm -rf "$STATUS_TMPDIR"
echo "  done."

# --- Hook 5: push-time qc-review offer ---
# Unlike Hook 4, this hook's own logic (detection regex, once-per-session cap,
# risk classification) is simple enough to exercise against the real extracted
# command directly, in a real scratch git repo — no need for a parallel
# mirrored-logic function.
echo "== push-time qc-review offer (Hook 5, skills/foundry-hooks/SKILL.md) =="
PUSH_CMD=$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$REPO_ROOT/templates/settings.qcreview-offer.json.template")

push_payload() {
  # jq -n --arg handles quoting, so callers can pass cmd strings containing
  # literal double quotes (e.g. echo "git push") without manual escaping.
  jq -n --arg cmd "$1" --arg session "$2" '{tool_input:{command:$cmd},session_id:$session}'
}

check_push_fires() {
  local label="$1" cmd="$2" session="$3"
  local out
  out=$(push_payload "$cmd" "$session" | bash -c "$PUSH_CMD")
  if [ -z "$out" ]; then
    echo "  FAIL: $label — expected an offer, got silence"
    FAIL=1
  fi
}

check_push_silent() {
  local label="$1" cmd="$2" session="$3"
  local out
  out=$(push_payload "$cmd" "$session" | bash -c "$PUSH_CMD")
  if [ -n "$out" ]; then
    echo "  FAIL: $label — expected silence, got an offer"
    FAIL=1
  fi
}

# Detection-regex cases: a bare repo with no upstream, so risk classification
# can't resolve and defaults to risky/fires — isolates the regex itself from
# the risk-classification logic tested separately below.
PUSH_TMPDIR=$(mktemp -d)
cd "$PUSH_TMPDIR"
git init -q
git config user.email t@t.com; git config user.name t
echo hello > a.txt; git add a.txt; git commit -qm init

check_push_fires  "git push, no upstream (undetermined -> fires)"        'git push'                                    "hook5-s1"
check_push_silent "git status is not a push"                              'git status'                                  "hook5-s2"
check_push_silent "git push only inside a quoted string"                  'echo "git push"'                             "hook5-s3"
check_push_fires  "chained cd && git push"                                'cd foo && git push origin main'              "hook5-s4"
check_push_silent "git push mentioned inside a commit message string"     'git commit -m "note: run git push later"'    "hook5-s5"
check_push_silent "second push, same session (once-per-session cap)"      'git push'                                    "hook5-s1"

cd "$REPO_ROOT"
rm -rf "$PUSH_TMPDIR"

# Risk-classification cases: a repo with a real upstream, so the command's
# `git diff --name-only '@{u}' HEAD` actually resolves and the keyword check
# runs for real, rather than falling into the undetermined/fail-open branch.
PUSH_REMOTE=$(mktemp -d); git init -q --bare "$PUSH_REMOTE"
PUSH_LOCAL=$(mktemp -d); cd "$PUSH_LOCAL"
git init -q -b main; git config user.email t@t.com; git config user.name t
echo hello > readme.txt; git add readme.txt; git commit -qm init
git remote add origin "$PUSH_REMOTE"; git push -q -u origin main

echo more >> readme.txt; git add readme.txt; git commit -qm "non-risky readme tweak"
check_push_silent "non-risky push does not spend the session cap"         "git push" "hook5-s10"

mkdir -p src; echo 'SECRET_KEY=abc' > src/auth_config.py
git add src/auth_config.py; git commit -qm "add auth config"
check_push_fires  "risky push, same session, cap not yet spent"           "git push" "hook5-s10"

echo x > src/another_secret.txt; git add src/another_secret.txt; git commit -qm "more secret stuff"
check_push_silent "second risky push, same session (cap now spent)"       "git push" "hook5-s10"

cd "$REPO_ROOT"
rm -rf "$PUSH_LOCAL" "$PUSH_REMOTE"
echo "  done."

# --- Hook 1/3 merge guard: type-checked SessionStart merge ---
# Pure jq logic (no shell-quoting/JSON-escaping involved), so cases are plain
# jq invocations rather than full rendered-command extraction like Hooks 3/4.
echo "== SessionStart merge guard (Hook 1/3 install step, skills/foundry-hooks/SKILL.md) =="

merge_guard() {
  echo "$1" | jq 'if (.hooks.SessionStart | type) == "array"
      then .hooks.SessionStart += [{"hooks":[{"type":"command","command":$cmd}]}]
      elif (.hooks.SessionStart | type) == "object"
      then .hooks.SessionStart = [.hooks.SessionStart, {"hooks":[{"type":"command","command":$cmd}]}]
      else .hooks.SessionStart = [{"hooks":[{"type":"command","command":$cmd}]}]
      end' --arg cmd "echo new" 2>/dev/null
}

check_merge_case() {
  local label="$1" input="$2"
  local out
  out=$(merge_guard "$input")
  if ! echo "$out" | jq -e '.hooks.SessionStart | type == "array"' >/dev/null 2>&1; then
    echo "  FAIL: $label — merge did not produce an array, got: $out"
    FAIL=1
  fi
}

check_merge_case "bare-object SessionStart (the reported failure)" '{"hooks":{"SessionStart":{"command":"echo old"}}}'
check_merge_case "existing array"                                  '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"echo existing"}]}]}}'
check_merge_case "no hooks key"                                    '{}'
check_merge_case "hooks key, no SessionStart"                      '{"hooks":{"PreToolUse":[]}}'
check_merge_case "other settings present, no hooks"                '{"permissions":{"allow":["Bash(npm *)"]}}'
echo "  done."

# --- foundry-audit: mutation tests, one per FAIL-capable check ---
# This suite is deliberately shaped differently from the four above, because
# the thing being tested is different. The others assert that one pattern
# classifies one input correctly. This one asserts that a *check can fail* —
# it builds a clean synthetic doc set, confirms the audit reports it clean,
# then injects exactly one known defect per check class and confirms that
# specific check catches it. A check that stays silent with its own defect
# present is worthless no matter how often it is re-run, which is the whole
# argument the skill is built on; this is where that argument is cashed.
#
# Cases live inline rather than in tests/fixtures/*.txt for the same reason as
# Hooks 3/4: each case needs a whole multi-file project tree on disk, not a
# single string matched against a pattern.
echo "== foundry-audit mutation tests (skills/foundry-audit/audit.sh) =="
AUDIT="$REPO_ROOT/skills/foundry-audit/audit.sh"

# Rebuilds a pristine, deliberately-clean fixture project at $1.
build_audit_fixture() {
  local d="$1"
  rm -rf "$d"
  mkdir -p "$d/docs"
  cat > "$d/CLAUDE.md" <<'EOF'
# Fixture

## What this is
A synthetic Foundry-shaped doc set used to mutation-test the audit script.

## Architecture
- `docs/guide.md` — the extra doc
- `run.sh` — the thing decisions point at

## Rules / Never do
- Never commit a secret. See DECISIONS.md's 2026-02-01 entry.

## How to run
- `bash run.sh`
EOF
  cat > "$d/README.md" <<'EOF'
# Fixture

See [CLAUDE.md](CLAUDE.md), `DECISIONS.md`, `SESSIONS.md` and `docs/guide.md`.

| Col A | Col B |
|---|---|
| one | two |
EOF
  cat > "$d/DECISIONS.md" <<'EOF'
# Decision Log
# Entries are ordered newest-to-oldest.

## 2026-02-01 — Second decision

### We will guard commits
- Decided to add a guard.
- **Why:** cheap now, expensive later.
- **How to apply:** every commit.
- **Enforced at:** `run.sh`

## 2026-01-01 — First decision

### We will write things down
- Decided to keep a log.
- **Why:** memory is not a mechanism.
- **How to apply:** always.
EOF
  cat > "$d/SESSIONS.md" <<'EOF'
# Sessions

## 2026-02-01
Built the guard, per DECISIONS.md's 2026-02-01 entry. Touched `run.sh`.
EOF
  cat > "$d/docs/guide.md" <<'EOF'
# Guide
Read `CLAUDE.md` first.
EOF
  : > "$d/run.sh"
}

AUDIT_TMP=$(mktemp -d)
AUDIT_FX="$AUDIT_TMP/proj"

# $1 label, $2 expected exit code, $3 expected output substring ("" = none),
# $4 mutation shell snippet (runs with cwd = fixture root), $5.. extra audit args
check_audit_case() {
  local label="$1" expect_code="$2" expect_substr="$3" mutation="$4"
  shift 4
  build_audit_fixture "$AUDIT_FX"
  ( cd "$AUDIT_FX" && eval "$mutation" ) >/dev/null 2>&1 || true
  local out code
  # Most cases here deliberately make the audit exit non-zero, so errexit has
  # to be off across the call — otherwise the first successful mutation kills
  # the whole suite, which is a silent pass, not a pass.
  set +e
  out=$(cd "$AUDIT_FX" && bash "$AUDIT" "$@" 2>&1)
  code=$?
  set -e
  if [ "$code" != "$expect_code" ]; then
    echo "  FAIL: $label — expected exit $expect_code, got $code"
    echo "$out" | sed 's/^/        /'
    FAIL=1
    return
  fi
  if [ -n "$expect_substr" ] && ! printf '%s' "$out" | grep -qF "$expect_substr"; then
    echo "  FAIL: $label — output did not contain '$expect_substr'"
    echo "$out" | sed 's/^/        /'
    FAIL=1
  fi
}

# Baseline: the unmutated fixture must be clean. If this ever fails, every
# mutation case below is meaningless (they would "catch" the baseline noise).
check_audit_case "baseline clean fixture" 0 "RESULT: CLEAN" "true"

# One mutation per FAIL-capable check.
check_audit_case "dangling decision reference" 1 "dangling decision reference: 2099-01-01" \
  "printf '\nSee DECISIONS.md 2099-01-01 for details.\n' >> SESSIONS.md"

check_audit_case "allowlist suppresses a recounted decision date" 0 "RESULT: CLEAN" \
  "printf '\nDECISIONS.md once cited 2099-01-01, which never existed.\n' >> SESSIONS.md && printf '2099-01-01\n' > .foundry-audit-allow"

check_audit_case "decision log out of order" 1 "not in the newest-first order" \
  "printf '\n## 2025-01-01 — Older\n\n### x\n- y\n' > /tmp/_a && cat DECISIONS.md /tmp/_a > /tmp/_b && printf '\n## 2027-01-01 — Newest, in the wrong place\n\n### x\n- y\n' >> /tmp/_b && cp /tmp/_b DECISIONS.md"

check_audit_case "decision headings unparseable (empty input set)" 1 "no parseable" \
  "sed -E 's/^## [0-9]{4}-[0-9]{2}-[0-9]{2}/## Decision:/' DECISIONS.md > _m && mv _m DECISIONS.md"

check_audit_case "dangling ADR reference" 1 "dangling ADR reference: ADR-099" \
  "printf '\n## ADR-001 — a real one\n- body\n' >> DECISIONS.md && printf '\nBlocked by ADR-099.\n' >> SESSIONS.md"

check_audit_case "ADR referenced, none defined (empty input set)" 1 "but no '## ADR-NNN' heading defines any" \
  "printf '\nBlocked by ADR-042.\n' >> SESSIONS.md"

check_audit_case "broken path reference" 1 "broken path reference: \`docs/nope.md\`" \
  "printf '\nSee \`docs/nope.md\`.\n' >> CLAUDE.md"

check_audit_case "stale path after a rename" 1 "likely a rename that missed a spot" \
  "printf '\nSee \`docs/manuals/guide.md\`.\n' >> CLAUDE.md"

# Precision guards. These two are the reason the path check is split by
# confidence at all: documentation legitimately discusses filenames as
# subject matter, and a check that flags those is one nobody reads twice.
check_audit_case "bare example filename is not a broken reference" 0 "probably-examples" \
  "printf '\nA fixture file like \`auth.py\` demonstrates the problem.\n' >> CLAUDE.md"

check_audit_case "example path under a directory this repo lacks is not a finding" 0 "probably-examples" \
  "printf '\nThe pattern also has to catch \`config/prod.yaml\`.\n' >> CLAUDE.md"

check_audit_case "allowlisted future file is not a finding" 0 "1 allowlisted" \
  "printf '\nSee \`docs/planned.md\`.\n' >> CLAUDE.md && printf 'docs/planned.md\n' > .foundry-audit-allow"

check_audit_case "enforcement locus points at a missing file" 1 "names \`nope.sh\` as its enforcement locus" \
  "sed 's|\*\*Enforced at:\*\* \`run.sh\`|**Enforced at:** \`nope.sh\`|' DECISIONS.md > _m && mv _m DECISIONS.md"

check_audit_case "enforcement locus stated as prose is surfaced, not silently accepted" 0 "name no checkable path" \
  "sed 's|\*\*Enforced at:\*\* \`run.sh\`|**Enforced at:** the next work unit, tracked on the roadmap|' DECISIONS.md > _m && mv _m DECISIONS.md"

check_audit_case "unclosed code fence" 1 "odd number of code fences" \
  "printf '\n\`\`\`bash\necho hi\n' >> CLAUDE.md"

check_audit_case "missing trailing newline" 1 "no trailing newline" \
  "printf 'no newline at end' >> docs/guide.md"

check_audit_case "placeholder marker left behind" 1 "placeholder marker left in the document" \
  "printf '\n- TODO: finish this section\n' >> CLAUDE.md"

check_audit_case "prose mentioning a TODO is NOT a finding" 0 "RESULT: CLEAN" \
  "printf '\nThis is a permanent limitation, not a TODO to be picked up later.\n' >> CLAUDE.md"

check_audit_case "a marker inside backticks is discussed, not left behind" 0 "RESULT: CLEAN" \
  "printf '\nThe check looks for a leftover \`TODO:\` marker in the document.\n' >> CLAUDE.md"

check_audit_case "allowlist suppresses an example identifier, not just a path" 0 "does not use ADR-NNN" \
  "printf '\nA dangling reference looks like ADR-099 with nothing defining it.\n' >> CLAUDE.md && printf 'ADR-099\n' > .foundry-audit-allow"

check_audit_case "table with an inconsistent column count" 1 "inconsistent column count" \
  "printf '| three | four | five |\n' >> README.md"

check_audit_case "unreachable document" 1 "unreachable doc: docs/orphan.md" \
  "printf '# Orphan\nNothing links here.\n' > docs/orphan.md"

check_audit_case "no entry point at all (empty input set)" 1 "no entry point to check document reachability from" \
  "rm -f CLAUDE.md README.md"

check_audit_case "no documents at all (harness error, not clean)" 2 "This is not a clean result" \
  "rm -f ./*.md docs/*.md && rmdir docs"

check_audit_case "--doc naming a missing file errors rather than skipping it" 2 "which does not exist" \
  "true" --doc notes/nope.md

# From the adversarial pass on audit.sh itself. A space in a document path used
# to word-split the doc set, which didn't just miss a check — it manufactured
# false findings (one file counted twice, then reported unreachable).
# Before the fix this reported "scanned 6" while listing 5 names, and invented
# four unreachable documents out of one. The assertion is the reachability
# count: exactly 1, not 2 — that proves the path was iterated as a single
# document. It is genuinely unreachable, because the reference-matching
# patterns don't span spaces either; that limitation is stated in SKILL.md.
check_audit_case "a document path containing a space is one document, not two" 1 "reachability — 1 doc(s) not reachable" \
  "printf '# Notes\n' > 'docs/my notes.md'"

check_audit_case "--doc pulls an out-of-layout file into the scanned set" 1 "notes/extra.md: odd number of code fences" \
  "mkdir -p notes && printf '# Extra\n\`\`\`bash\nunclosed\n' > notes/extra.md" --doc notes/extra.md

check_audit_case "numeric claim disagrees across files" 1 "numeric claim 'widgets' disagrees" \
  "printf '\nThere are three widgets.\n' >> CLAUDE.md && printf '\nThere are four widgets.\n' >> SESSIONS.md" \
  --numeric widgets

check_audit_case "numeric claim agrees across files" 0 "RESULT: CLEAN" \
  "printf '\nThere are three widgets.\n' >> CLAUDE.md && printf '\nAll three widgets shipped.\n' >> SESSIONS.md" \
  --numeric widgets

rm -rf "$AUDIT_TMP" /tmp/_a /tmp/_b
echo "  done."

# --- NOT COVERED HERE, deliberately ---
# qc-review's calibration fixture (tests/calibration/qc-review/) is NOT run by
# this script and must never be added to it. That check dispatches an LLM
# subagent: non-deterministic, billed, minutes long, and impossible in GitHub
# Actions. Running it here would put a non-reproducible result behind a
# pass/fail gate and let a green suite imply coverage it does not have. It is a
# manual periodic calibration — see that directory's README.md.
echo "== NOT COVERED: qc-review calibration (tests/calibration/qc-review/) =="
echo "  manual only — LLM subagent, non-deterministic, never gated here."

if [ "$FAIL" -eq 0 ]; then
  echo "All fixture cases passed."
else
  echo "One or more fixture cases FAILED. See above."
fi
exit "$FAIL"
