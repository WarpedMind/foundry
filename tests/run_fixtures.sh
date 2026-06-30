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

if [ "$FAIL" -eq 0 ]; then
  echo "All fixture cases passed."
else
  echo "One or more fixture cases FAILED. See above."
fi
exit "$FAIL"
