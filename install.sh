#!/usr/bin/env bash
# Foundry — personal install
#
# Symlinks each skill in skills/ into ~/.claude/skills/ so they're available
# in every Claude Code project on this machine, without copying files (so
# `git pull` in this repo keeps the installed skills current automatically).
#
# Safe to re-run — skips a skill if a real (non-symlink) directory already
# exists at the target, rather than overwriting it silently.

set -euo pipefail

FOUNDRY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$FOUNDRY_DIR/skills"
SKILLS_DEST="$HOME/.claude/skills"

mkdir -p "$SKILLS_DEST"

for skill_dir in "$SKILLS_SRC"/*/; do
  name="$(basename "$skill_dir")"
  dest="$SKILLS_DEST/$name"

  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "SKIP: $dest already exists and is not a symlink — not overwriting. Remove it manually first if you want Foundry's version installed."
    continue
  fi

  if [ -L "$dest" ]; then
    rm "$dest"
  fi

  ln -s "${skill_dir%/}" "$dest"
  echo "Linked: $dest -> ${skill_dir%/}"
done

echo
echo "Done. Skills are available in any project. Run /hooks once in an open session if newly-installed skills don't show up immediately."
