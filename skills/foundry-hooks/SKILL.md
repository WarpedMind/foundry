---
name: foundry-hooks
description: Wire a SessionStart doc-loader hook, a status/offer hook, and (if the project handles secrets) a secrets-guard pre-commit hook into a project's .claude/settings.json. Use after foundry-docs has created CLAUDE.md/DECISIONS.md/SESSIONS.md, or standalone on any existing project that wants its docs auto-loaded into every session.
---

# foundry-hooks

Wires hooks into the current project's `.claude/settings.json` (the shared, committed settings file — not `.claude/settings.local.json`, which is personal/gitignored).

**Locating Foundry's templates** (needed for every hook below): this skill reads template files from this Foundry checkout. Check `~/Projects/foundry/templates/` first — if not found there (e.g. a different install location on this machine), ask the user where Foundry is checked out before proceeding. Never guess or skip a template silently if the path can't be found.

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
2. Build a `PreToolUse` hook matching `Bash`, with an `if` filter scoped to `git commit` invocations, that checks staged files against a forbidden pattern.

   **Do not use a narrow exact-suffix regex** (an earlier version of this hook used `(^|/)(\.env|.*\.pem|.*\.key|config\.yaml)$`, which an independent security review caught and verified misses realistic real-world filenames: `secrets.env`, `.env.production.local`, `config.yaml.bak`, and `real.key.txt` all sailed through unflagged in a live test, because the regex required the dangerous token to be the literal filename suffix with nothing after it). Use this broader, independently re-tested pattern instead — verified against a 21-file adversarial fixture set covering both directions (catches secret-like names with extra suffixes and nested paths; does NOT false-positive on legitimate files like `.env.example`, `secretary_notes.txt`, `api_keynote.md`, `keyboard_shortcuts.md`, `monkey.py`, `the_keymaster.rb`):
   ```bash
   STAGED=$(git diff --cached --name-only)
   FORBIDDEN=$(echo "$STAGED" | grep -vE '(^|/)\.env\.example$' | grep -iE '(^|/)\.env(\.[^/]*)?$|\.pem(\.[^/]*)?$|\.key(\.[^/]*)?$|config[^/]*\.ya?ml(\.[^/]*)?$|(^|[/_.-])secrets?([_.-]|$)|(^|[/_.-])credentials?([_.-]|$)')
   if [ -n "$FORBIDDEN" ]; then echo "BLOCKED: forbidden files staged: $FORBIDDEN"; exit 1; fi
   ```
   Extend the pattern with any project-specific real-config filename named in CLAUDE.md's Security Rules section (e.g. if the project uses a different secrets file name than the defaults above) — but never narrow the existing alternatives, only add to them.
3. Validate this hook the same way before writing it: pipe-test with synthetic stdin matching a `Bash`/`git commit` tool call. Do not just test the one obvious case — build a small adversarial fixture set in a scratch repo first (secret-like filenames with extra suffixes/nested paths, AND legitimate filenames that merely contain substrings like "key"/"secret"/"env") and confirm the hook gets every case right in both directions before trusting it. A claim of "tested" that only checks the single easy case is not real verification — this is precisely the gap an outside reviewer found in this hook's first version.
4. This is a safety net, not a replacement for the user's own judgment — state that plainly when presenting it, don't oversell it as foolproof (e.g. it won't catch secrets pasted into a non-matching filename, secrets hardcoded inside otherwise-legitimate source files, or already-committed secrets).

## Hook 3: status/offer hook (always add this, even when invoked standalone outside foundry-init)

Lets a future session in this project know at a glance whether Foundry is set up, without re-running the questionnaire or being noisy about it. Three states, all verified: scaffolded (silent confirmation: "Foundry: Active (scaffolded <date>)"), dismissed (completely silent — empty `additionalContext`), or neither (a one-line offer to run `/foundry-init`, plus how to dismiss it).

**Steps:**
1. Read `templates/settings.status.json.template` from this Foundry checkout. It has no placeholders to substitute — the command reads `.foundry.scaffolded`/`.foundry.dismissed`/`.foundry.scaffoldedDate` from `.claude/settings.json` directly at runtime, not at template-render time, since those fields don't exist yet at the moment this hook is being installed.
2. Merge into `.claude/settings.json` under `hooks.SessionStart` as a **separate array entry** alongside Hook 1 (confirmed: multiple `SessionStart` entries coexist correctly in the same array — don't try to combine them into one hook's command).
3. Validate the same way as Hook 1: pipe-test with synthetic stdin against each of the three states (write a temporary `.foundry` block representing each state into a scratch `.claude/settings.json`, run the extracted command, confirm the right `additionalContext` comes back) before trusting it in the real project.
4. This hook only *reads* the `foundry.scaffolded`/`foundry.dismissed` fields — it does not write them. Those are written by `foundry-init` (Step 2.5, on successful completion) and by the dismiss flow (see `foundry-init`'s "Dismissing the status hook's offer" section) respectively. If this hook is ever wired standalone (not via `foundry-init`) onto a project that already has docs/hooks from some other process, ask the user whether to mark `foundry.scaffolded: true` immediately (since the scaffolding already effectively exists) rather than leaving it perpetually offering `/foundry-init` on a project that doesn't need it.

## Hook 4: directory-drift logger (optional — offer it, don't force it)

Detects when a Bash command's leading `cd` targets a directory outside this project, and logs it — a real, working substitute for the originally-desired `CwdChanged` hook, whose actual stdin payload could not be verified (see README.md Roadmap). This catches a specific, real, confirmed failure mode: a long session running many path-qualified commands (`cd ~/Projects/other-project && ...`) without ever triggering a harness-level "the session's cwd changed" event — which is exactly what happened during this hook's own design session, discovered when `EnterWorktree` reported "not in a git repository" despite extensive prior work in a real git repo, revealing the session's tracked root had never actually moved.

**Steps:**
1. Build a `PreToolUse` hook matching `Bash`, command (verified against 6 real test cases — detects drift to a different project, correctly stays silent for same-project subdirectories/the root itself/no-`cd`-at-all/a nonexistent path):
   ```bash
   CMD=$(jq -r '.tool_input.command // ""')
   TARGET=$(echo "$CMD" | grep -oE '^cd[[:space:]]+[^&;]+' | sed -E 's/^cd[[:space:]]+//' | sed -E 's/[[:space:]]+$//' | sed "s|^~|$HOME|")
   if [ -n "$TARGET" ]; then
     REAL_TARGET=$(cd "$TARGET" 2>/dev/null && pwd)
     ROOT="<the project's absolute root path, substituted at install time>"
     if [ -n "$REAL_TARGET" ] && [ "$REAL_TARGET" != "$ROOT" ] && [[ "$REAL_TARGET" != "$ROOT"/* ]]; then
       echo "$(date -Iseconds) DRIFT: cd to $REAL_TARGET (outside $ROOT)" >> .claude/drift.log
     fi
   fi
   ```
   This logs only — it does not block (`continue: true` implicitly, no `decision: block`) and does not inject `additionalContext`, since drift to another directory isn't inherently wrong (legitimate cross-project work happens), it's just a signal worth having a record of.
2. **Two known, real limitations — state both plainly, don't oversell this as comprehensive:**
   - Only catches `cd` as the **first** token of a command. A `cd` appearing later in a chain (e.g. `echo hello; cd ~/other-project`) is not detected — confirmed via direct test, not assumed.
   - A relative `cd ..`/`cd ../sibling` resolves against whatever the shell's *actual* current directory is at execution time, which this hook cannot independently know — it can produce a false positive (flagging a legitimate same-project relative move as drift) or a false negative depending on actual shell state. This is a real, accepted gap, not silently glossed over.
3. Validate before writing: pipe-test with synthetic stdin (`echo '{"tool_input":{"command":"cd ~/Projects/other && ls"}}' | bash -c "<command>"`) confirming it appends to `.claude/drift.log` for a real cross-project path and stays silent for a same-project path, exactly as tested during this hook's own design.
4. Add `.claude/drift.log` to `.gitignore` — it's local diagnostic output, not something to commit or share.
5. Offer this hook, don't force it into the default sequence — `foundry-init` does not call this automatically; mention it's available if the user wants visibility into cross-project drift specifically.

## After wiring

Confirm with the user before moving on — show the diff to `.claude/settings.json`, don't just report success.
