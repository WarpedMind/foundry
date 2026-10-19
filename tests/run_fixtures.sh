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

# --- check 11: the auto-load budget -----------------------------------------
# This check measures cost rather than correctness, so its defect class is
# "a doc set that grew past the threshold and nothing said so". Injecting that
# means writing a real loader into the fixture and padding a file it names.
#
# Writes a fixture .claude/settings.json whose SessionStart doc-loader names
# exactly the files given, in the same rendered form Foundry actually produces
# (a bash array literal inside a JSON string, so the quotes arrive escaped) —
# not a simplified stand-in, because the escaped-quote parse is itself part of
# what these cases exist to exercise. Callable from a mutation snippet: those
# run in a subshell of this script, so functions defined here are in scope.
write_loader_settings() {
  mkdir -p .claude
  local arr="" f
  for f in "$@"; do arr="${arr}\\\"${f}\\\" "; done
  printf '%s\n' \
    '{' \
    '  "hooks": {' \
    '    "SessionStart": [' \
    '      {' \
    '        "hooks": [' \
    '          {' \
    '            "type": "command",' \
    "            \"command\": \"DOC_FILES_ARR=($arr); for f in \\\"x\\\"; do cat \\\"\$f\\\"; done; echo hookEventName: \\\"SessionStart\\\"\"" \
    '          }' \
    '        ]' \
    '      }' \
    '    ]' \
    '  }' \
    '}' > .claude/settings.json
}

# A hand-rolled SessionStart hook that cats documents with no parseable file
# list — the shape the "unparseable" branch exists for. Note what this command
# does NOT contain: the string "SessionStart". The event name lives in the JSON
# key, not the command, and an earlier version of this fixture appended an
# `echo hookEventName: SessionStart` so the then-current heuristic would fire
# on it. That made the case pass against an input built to satisfy the check
# rather than against the shape it claims to represent.
write_optout_loader_settings() {
  mkdir -p .claude
  printf '%s\n' \
    '{' \
    '  "hooks": {' \
    '    "SessionStart": [' \
    '      {' \
    '        "hooks": [' \
    '          {' \
    '            "type": "command",' \
    '            "command": "cat CLAUDE.md DECISIONS.md"' \
    '          }' \
    '        ]' \
    '      }' \
    '    ]' \
    '  }' \
    '}' > .claude/settings.json
}

# Two SessionStart loader blocks under one "SessionStart" key. $1.. are the
# first loader's files (default CLAUDE.md); the second always names DECISIONS.md
# and SESSIONS.md, so a parse that keeps only one array undercounts visibly.
write_two_loader_settings() {
  local first="${1:-CLAUDE.md}"
  write_loader_settings "$first"
  local second
  second=$(printf 'DOC_FILES_ARR=(\\"DECISIONS.md\\" \\"SESSIONS.md\\" ); for f in \\"x\\"; do cat \\"$f\\"; done')
  jq --arg c "$second" '.hooks.SessionStart += [{"hooks":[{"type":"command","command":$c}]}]' \
    .claude/settings.json > .claude/_t && mv .claude/_t .claude/settings.json
}

# A real SessionStart loader naming only CLAUDE.md, plus a decoy DOC_FILES_ARR
# in a PreToolUse hook naming the padded file. Tests that the parse is scoped
# to SessionStart rather than grepping the whole settings file.
write_decoy_loader_settings() {
  write_loader_settings CLAUDE.md
  jq '.hooks.PreToolUse = [{"matcher":"Bash","hooks":[{"type":"command","command":"DOC_FILES_ARR=(\"DECISIONS.md\"); echo ok"}]}]' \
    .claude/settings.json > .claude/_t && mv .claude/_t .claude/settings.json
}

# A loader in settings.local.json. Claude Code runs matching hooks from both
# files, so this one's files are injected on top of settings.json's.
write_local_loader_settings() {
  mkdir -p .claude
  local arr="" f
  for f in "$@"; do arr="${arr}\\\"${f}\\\" "; done
  printf '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"DOC_FILES_ARR=(%s); for f in \\"x\\"; do cat \\"$f\\"; done"}]}]}}\n' \
    "$arr" > .claude/settings.local.json
}

# Foundry's real status hook, from the template rather than a stand-in: the
# exemption that keeps it from reading as an unidentified loader matches on the
# foundry.scaffolded read, so this case fails loudly if that hook is rewritten.
write_status_settings() {
  mkdir -p .claude
  cp "$REPO_ROOT/templates/settings.status.json.template" .claude/settings.json
}

# The same status hook with a hand-rolled loader added under the same
# "SessionStart" key — the recognised hook must not vouch for its sibling.
write_status_plus_handrolled_settings() {
  write_status_settings
  jq '.hooks.SessionStart += [{"hooks":[{"type":"command","command":"cat CLAUDE.md DECISIONS.md"}]}]' \
    .claude/settings.json > .claude/_t && mv .claude/_t .claude/settings.json
}

# A PreToolUse command that merely mentions a Markdown file.
add_pretooluse_md_mention() {
  jq '.hooks.PreToolUse = [{"matcher":"Bash","hooks":[{"type":"command","command":"grep -q x CHANGELOG.md || true"}]}]' \
    .claude/settings.json > .claude/_t && mv .claude/_t .claude/settings.json
}

# A loader whose array mixes a quoted filename with an unquoted glob, the shape
# bash expands at array-construction time and this parse cannot resolve.
write_glob_loader_settings() {
  mkdir -p .claude
  printf '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"DOC_FILES_ARR=(\\"CLAUDE.md\\" docs/*.md); for f in \\"${DOC_FILES_ARR[@]}\\"; do cat \\"$f\\"; done"}]}]}}\n' \
    > .claude/settings.json
}

# Collapses settings.json to one line, the shape a line-based parse got wrong.
minify_settings() {
  jq -c . .claude/settings.json > .claude/_t && mv .claude/_t .claude/settings.json
}

# ~52 bytes per line, so the line counts below are the byte budget in disguise.
PAD='Padding line written to grow this file past the budget.'

# Over the budget, under the ceiling: INFO, and deliberately exit 0. The
# assertion on the exit code is as load-bearing as the one on the text — an
# implementation that made this a FAIL would produce the right message and the
# wrong behaviour.
check_audit_case "auto-load budget crossed (INFO, does not fail the run)" 0 "an archive pass is due" \
  "write_loader_settings CLAUDE.md DECISIONS.md SESSIONS.md && awk -v p=\"\$PAD\" 'BEGIN{for(i=0;i<3400;i++) print p}' >> DECISIONS.md"

check_audit_case "auto-load budget past the hard ceiling (FAIL)" 1 "hard ceiling" \
  "write_loader_settings CLAUDE.md DECISIONS.md SESSIONS.md && awk -v p=\"\$PAD\" 'BEGIN{for(i=0;i<6000;i++) print p}' >> DECISIONS.md"

# Precision guard, and the one that proves the check measures the *loaded* set
# rather than the scanned one: an oversized document nobody injects costs a
# session nothing, and flagging it would be a finding with no fix.
#
# The assertion used to be the substring "auto-load budget", which appears in
# all five branch labels and so asserted nothing — the case rested entirely on
# its exit code, and only because its pad happens to clear the hard ceiling.
# Raise the ceiling as well as mis-measure the set and it passed while the
# audit reported INFO on a set the loader never names. Asserting the
# percentage is what makes it discriminating: counting the padded file reads
# 195%, not 0%. The "tokens), " anchor is load-bearing and was added after the
# neuter test caught it missing — these assertions are plain substring matches,
# and a bare "0% of the" is also a substring of "190% of the", so the case
# passed against a mis-measuring implementation whose percentage happened to
# end in a zero. An assertion that depends on the last digit of a number
# asserts nothing reliable.
check_audit_case "an oversized doc outside the loaded set is not a budget finding" 0 "tokens), 0% of the" \
  "write_loader_settings CLAUDE.md && awk -v p=\"\$PAD\" 'BEGIN{for(i=0;i<6000;i++) print p}' >> DECISIONS.md"

# Negative branch: a SessionStart hook is present and declared no file list
# this script can read, so whether it injects documents is undetermined. The
# budget is unknown, and unknown is a finding here, not a pass. This fixture's
# loader does inject three documents past the hard ceiling; the point is that
# the audit says so rather than reporting PASS at 0%.
check_audit_case "loader present but its file list is unparseable (SKIP = finding)" 1 "could not be identified" \
  "write_optout_loader_settings"

# ...and the escape hatch clears it, so the SKIP above is never a permanent
# unclearable finding.
check_audit_case "--budget-file states the set an unparseable loader hides" 0 "source: --budget-file" \
  "write_optout_loader_settings" --budget-file CLAUDE.md --budget-file DECISIONS.md

# A file the loader names but which does not exist is reported, not silently
# counted as zero — matching the loader's own [ -f ] guard while still saying so.
check_audit_case "a loader naming a missing file says so in the breakdown" 0 "named but absent" \
  "write_loader_settings CLAUDE.md GONE.md"

# --- check 11: the loaded-set parse ----------------------------------------
# From the adversarial pass on the budget check itself. Every case below is a
# shape that made the old parse report a confident number for a set nothing
# injects, or miss an injection entirely — it reported PASS at 0% while the
# fixture's real injection sat past the hard ceiling. The assertions are on
# the percentage and the exit code rather than on the words "auto-load budget",
# which appear in all five branch labels and so assert nothing.

# Two SessionStart loader blocks. The old parse took the first array and
# discarded the rest, so the padded file the second one names went uncounted.
check_audit_case "every SessionStart loader is counted, not just the first" 0 "an archive pass is due" \
  "write_two_loader_settings && awk -v p=\"\$PAD\" 'BEGIN{for(i=0;i<3400;i++) print p}' >> DECISIONS.md"

# A DOC_FILES_ARR in a hook that is not a SessionStart loader. The old grep ran
# over the whole file, so this decoy won outright and the real loader's set was
# never read. Asserting 0% is what makes this discriminating: the decoy names
# the padded file, so counting it would read 119%.
check_audit_case "a DOC_FILES_ARR outside a SessionStart hook is not the loaded set" 0 "tokens), 0% of the" \
  "write_decoy_loader_settings && awk -v p=\"\$PAD\" 'BEGIN{for(i=0;i<3400;i++) print p}' >> DECISIONS.md"

# Claude Code runs matching hooks from both settings files, so a loader added
# in settings.local.json injects too. The old parse stopped at the first file
# that yielded an array.
check_audit_case "a loader in settings.local.json is counted alongside settings.json's" 0 "an archive pass is due" \
  "write_loader_settings CLAUDE.md && write_local_loader_settings DECISIONS.md && awk -v p=\"\$PAD\" 'BEGIN{for(i=0;i<3400;i++) print p}' >> DECISIONS.md"

# Nothing is deduplicated, and that is deliberate: two loaders naming the same
# file cat it twice, so the repeat is real injected bytes. Without the second
# array this reads 61%; with it, 119%.
check_audit_case "two loaders naming the same file count it twice" 0 "an archive pass is due" \
  "write_two_loader_settings CLAUDE.md && write_local_loader_settings CLAUDE.md && awk -v p=\"\$PAD\" 'BEGIN{for(i=0;i<1700;i++) print p}' >> CLAUDE.md"

# The scoping is positional, not line-based, because a minified settings.json
# puts every hook on one line and a pretty-printed one splits the event key
# from its command. Both shapes must give the same answer. This pair is a
# regression guard on that, not a defect injection.
check_audit_case "a minified settings.json parses the same as a pretty-printed one" 0 "an archive pass is due" \
  "write_loader_settings CLAUDE.md DECISIONS.md && minify_settings && awk -v p=\"\$PAD\" 'BEGIN{for(i=0;i<3400;i++) print p}' >> DECISIONS.md"

# ...and the scoping has to hold minified too, which needs a discriminating
# input: the case above would pass even if the decoy were counted, since the
# loader it names is small either way. Here the decoy names the padded file, so
# counting it reads 119%.
check_audit_case "a minified settings.json scopes a decoy out, same as a pretty-printed one" 0 "tokens), 0% of the" \
  "write_decoy_loader_settings && minify_settings && awk -v p=\"\$PAD\" 'BEGIN{for(i=0;i<3400;i++) print p}' >> DECISIONS.md"

# The input shape that used to manufacture a finding: minified, the old
# heuristic's three greps all matched the single line, so a SessionStart key
# plus an unrelated PreToolUse command mentioning a .md reported SKIP on a
# project whose only SessionStart hook injects nothing. Pinned here so that
# shape can't start failing again — but note honestly what carries it now:
# the heuristic is gone, so this passes because the status hook is recognised
# (the case below), not because of anything to do with the .md or the
# minification. Neutering the exemption is what breaks it.
check_audit_case "the retired '.md on the command line' signal no longer manufactures a SKIP" 0 "tokens), 0% of the" \
  "write_status_settings && add_pretooluse_md_mention && minify_settings"

# An unquoted entry in the array — a glob bash expands when the hook builds it.
# Previously dropped on the floor: not counted, and not even surfaced as "named
# but absent", so this fixture's 177KB injection reported PASS at 0%. How many
# files it becomes is not determined by the settings file, so the honest answer
# is unknown.
check_audit_case "an unquoted glob in the loader's array is unknown, not zero" 1 "could not resolve" \
  "write_glob_loader_settings && awk -v p=\"\$PAD\" 'BEGIN{for(i=0;i<3400;i++) print p}' >> docs/guide.md"

# ...and the precision counterpart, because the two look alike and are not the
# same case. A *quoted* entry containing a glob is never expanded — the loader
# iterates "${DOC_FILES_ARR[@]}" — so it stays a literal path that does not
# exist, and "named but absent" is the honest answer rather than a SKIP.
check_audit_case "a quoted glob is a literal path, reported absent rather than unknown" 0 "named but absent" \
  "write_loader_settings CLAUDE.md 'docs/*.md'"

# Foundry installs the status hook unconditionally and it injects no documents,
# so it must not read as an unidentified loader — that would put a standing
# SKIP on every Foundry project that declined the doc-loader hook. Recognised
# by the foundry.scaffolded read that is the hook's whole purpose, and the
# fixture uses the real template so rewriting that hook fails this case loudly.
check_audit_case "Foundry's own status hook alone is not an unidentified loader" 0 "tokens), 0% of the" \
  "write_status_settings"

# ...but it vouches only for itself. A hand-rolled loader sharing the same
# "SessionStart" key is still unidentified, so the total is still unknown.
check_audit_case "a recognised status hook does not vouch for a sibling loader" 1 "could not be identified" \
  "write_status_plus_handrolled_settings"

# --- check 9 now reads the derived loaded set, not three hardcoded names -----
# Same change, and it needs its own pair: the check's whole job is to surface
# absolute rules the session never sees, so getting the loaded set wrong makes
# it silently wrong in the direction of a false pass.
check_audit_case "an absolute rule in a doc this project's loader omits is surfaced" 0 "SESSIONS.md contains 1 absolute-sounding" \
  "write_loader_settings CLAUDE.md && printf '\n- The guard must never be skipped.\n' >> SESSIONS.md"

check_audit_case "the same rule in a doc the loader does include is not surfaced" 0 "no absolute-sounding rules found outside" \
  "write_loader_settings CLAUDE.md SESSIONS.md && printf '\n- The guard must never be skipped.\n' >> SESSIONS.md"

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
