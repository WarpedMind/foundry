#!/usr/bin/env bash
# Re-runnable version of the adversarial fixture checks referenced in
# skills/foundry-security/SKILL.md and skills/foundry-hooks/SKILL.md.
# Tests the actual .gitignore baseline and secrets-guard regex against
# committed fixture lists in tests/fixtures/, so a future change to either
# pattern gets re-verified automatically instead of relying on a one-time
# manual check from when the pattern was designed.
set -euo pipefail
cd "$(dirname "$0")"

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

if [ "$FAIL" -eq 0 ]; then
  echo "All fixture cases passed."
else
  echo "One or more fixture cases FAILED. See above."
fi
exit "$FAIL"
