---
name: foundry-hooks
description: Wire a SessionStart doc-loader hook (and optionally a secrets-guard pre-commit hook) into a project's .claude/settings.json. Use after foundry-docs has created CLAUDE.md/DECISIONS.md/SESSIONS.md, or standalone on any existing project that wants its docs auto-loaded into every session.
---

# foundry-hooks

Wires hooks into the current project's `.claude/settings.json` (the shared, committed settings file — not `.claude/settings.local.json`, which is personal/gitignored).

**`EXPLAIN_MODE`** (set by `foundry-init`, or ask if standalone): in `detailed` mode, explain before wiring Hook 1 that this exists because a written instruction to "always read these docs" has actually been observed to get silently skipped — a hook makes it the harness's job, not the assistant's memory. In `brief` mode, just wire it.

## Hook 1: SessionStart doc-loader (always add this)

This is the single most load-bearing piece of Foundry: it guarantees CLAUDE.md, DECISIONS.md, and SESSIONS.md are loaded into context at the start of every session, without depending on the assistant remembering to read them. (CLAUDE.md is also auto-loaded by Claude Code's built-in memory system already — this hook is redundant for that one file specifically, but DECISIONS.md and SESSIONS.md are not auto-loaded, and the hook is cheap enough that loading all three explicitly is simpler than special-casing.)

**Steps:**
1. Check which of `CLAUDE.md`, `DECISIONS.md`, `SESSIONS.md` actually exist in the project root. Build the file list from what's actually there — don't assume all three exist.
2. Read `templates/settings.hooks.json.template` from this Foundry checkout.
3. Substitute `{{DOC_FILES}}` with the space-separated list of existing files (e.g. `CLAUDE.md DECISIONS.md SESSIONS.md`), and `{{DOC_FILES_DISPLAY}}` with a comma-separated display version.
4. If `.claude/settings.json` already exists in the project, read it first and **merge** — add this hook under `hooks.SessionStart`, don't overwrite any existing hooks/settings. If a SessionStart hook already exists with a similar doc-loading command, ask the user whether to replace or keep both rather than silently duplicating.
5. Before writing, validate: run the rendered command with synthetic stdin (`echo '{}' | bash -c "<command>"`) and confirm it produces valid JSON with `jq -e 'has("hookSpecificOutput")'`. If this fails, do not write the file — fix the command first.
6. Write/merge into `.claude/settings.json`. Re-validate the final file with `jq -e '.hooks.SessionStart[0].hooks[0].command' .claude/settings.json` to confirm the JSON itself is well-formed and the hook is reachable at the expected path.
7. Tell the user: this hook may need `/hooks` opened once or a fresh session to take effect, since the settings watcher may not pick up a brand-new `.claude/` directory mid-session.

## Hook 2: secrets-guard pre-commit check (only if the project handles secrets)

Generalizes "before every commit, confirm no `.env`/config/`*.pem` staged" from a written reminder into an actually-enforced `PreToolUse` hook on `Bash` that inspects `git commit` invocations.

**Steps:**
1. Only offer this if `HANDLES_SECRETS` was true in the foundry-docs questionnaire (or ask directly if invoked standalone).
2. Build a `PreToolUse` hook matching `Bash`, with an `if` filter scoped to `git commit` invocations, that checks staged files against a forbidden pattern. Verified detection logic (tested against a scratch repo: blocks when `.env` is staged, allows when only safe files are staged):
   ```bash
   STAGED=$(git diff --cached --name-only)
   FORBIDDEN=$(echo "$STAGED" | grep -E '(^|/)(\.env|.*\.pem|.*\.key|config\.yaml)$')
   if [ -n "$FORBIDDEN" ]; then echo "BLOCKED: forbidden files staged: $FORBIDDEN"; exit 1; fi
   ```
   Extend the pattern with any project-specific real-config filename named in CLAUDE.md's Security Rules section (e.g. if the project uses a different secrets file name than the defaults above).
3. Validate this hook the same way before writing it: pipe-test with synthetic stdin matching a `Bash`/`git commit` tool call, confirm it blocks when a forbidden file is staged (test in a scratch git repo, not the real project) and allows when it isn't.
4. This is a safety net, not a replacement for the user's own judgment — state that plainly when presenting it, don't oversell it as foolproof (e.g. it won't catch secrets pasted into a non-matching filename, or already-committed secrets).

## After wiring

Confirm with the user before moving on — show the diff to `.claude/settings.json`, don't just report success.
