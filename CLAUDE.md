# Foundry

## What this is
Foundry scaffolds software projects with the documentation structure, hooks, and guardrails that make AI-assisted development reliable across many sessions, derived from a short per-project questionnaire rather than a fixed template. Part of the "Preamble" brand (Preamble = the umbrella; Foundry = this specific tool; Promptify = a separate, related tool also living here for now).

## Stack
- Claude Code skills (Markdown `SKILL.md` files, no compiled code)
- Bash (`install.sh`, hook commands)
- `jq` for hook JSON generation/validation

## Architecture
- `skills/foundry-init/` — orchestrator; calls the others in sequence based on a questionnaire
- `skills/foundry-docs/` — renders `templates/*.template` into a project's CLAUDE.md/DECISIONS.md/SESSIONS.md
- `skills/foundry-hooks/` — wires the SessionStart doc-loader hook (and secrets-guard, if applicable) into a project's `.claude/settings.json`
- `skills/foundry-security/` — `.gitignore` baseline, `.env.example` convention, already-committed-secrets check
- `skills/foundry-repo-hygiene/` — new-repo commit sequencing, ongoing docs-freshness discipline
- `skills/foundry-governance/` — regulatory/compliance section content, with an explicit anti-fabrication rule (states "not yet researched" rather than inventing plausible compliance language)
- `skills/promptify/` — standalone; `/promptify` and `/promptify!`, not dependent on the rest of Foundry
- `templates/` — the actual template files the above skills render
- `install.sh` — symlinks `skills/*` into `~/.claude/skills/`

## Current status
- `EXPLAIN_MODE` convention added across `foundry-init` and all 5 sub-skills: an extra up-front question (brief vs. detailed/educational explanations) that, when set to detailed, makes each skill surface the "why" already documented in its own SKILL.md to the user in the moment, rather than that reasoning only existing for whoever reads the skill files directly.
- All 7 skills written and individually verified:
  - `foundry-docs`: hand-rendered against two scratch scenarios (minimal vs. regulated) — confirmed conditional sections render correctly
  - `foundry-hooks`: SessionStart hook command pipe-tested with synthetic stdin, `jq -e` schema-validated, confirmed it degrades gracefully when not all 3 docs exist yet
  - `foundry-security`: `.gitignore` merge logic tested for idempotency in a scratch repo; secrets-guard detection logic tested against a scratch repo with a real staged `.env` (blocks correctly) and a clean stage (allows correctly)
  - `foundry-repo-hygiene`: docs-freshness `git log` pattern tested against a real repo (Karbot Rage) and produced a real, interpretable signal
  - `foundry-init`: ran a real end-to-end test via the actual Skill tool (not hand-simulated) against two scenarios — confirmed correct branching (minimal: 1 file, 3 sections; regulated: 4 files + hook, 14 sections, honest "not yet researched" governance placeholder)
- `install.sh`: run for real, confirmed idempotent, confirmed the harness recognized all 7 skills as available afterward
- Not yet pushed to a remote — this is the first commit
- README.md and docs/HOWS_AND_WHYS.md written, grounded in real examples from the build (not hypothetical)

## KNOWN DEBT
- No license chosen yet — needed before any public announcement/release
- Repo visibility (public/private) and remote not yet confirmed with the user as of this commit
- Promptify's "prompt shape" classification logic has not been tested against a range of real rough inputs yet — only designed, not exercised
- foundry-governance and foundry-security have been verified at the mechanism level (hook logic, detection patterns) but not yet exercised through a real multi-step Skill invocation the way foundry-init was

## Next session priorities (in order)
- Confirm repo name/visibility with the user and push the initial commit
- Exercise `/promptify` against a handful of real rough prompts to validate the shape-classification logic
- Decide on a license
- Consider whether foundry-docs needs a literal IF-block parser/instruction refinement after more real-world use, or whether the current "follow these steps" Markdown instruction has proven sufficient

## Rules / Never do
- Read CLAUDE.md, DECISIONS.md, and SESSIONS.md at the start of every session and stay anchored to them (enforced by this repo's own SessionStart hook once added — see `.claude/settings.json`)
- Verify external claims (API behavior, docs, third-party task briefs) against live/actual behavior before trusting them and writing code against them
- Use plan mode (or otherwise get explicit sign-off) before non-trivial implementation work
- Commit only when explicitly asked; never use destructive git operations (force-push, hard reset, history rewrites) without explicit confirmation
- Always read a file before editing it; if an exact-match replacement fails, re-read the file to find the actual current content rather than reaching for a regex fallback
- Update SESSIONS.md and, if status changed, CLAUDE.md as part of the same work — not as a separate cleanup pass remembered later
- If README.md describes a feature, command, or setup step that no longer matches reality, fix the README in the same change — don't leave it to drift
- Don't add a new composable skill without updating this CLAUDE.md's Architecture section in the same change

## How to run / Bash commands
- Install: `./install.sh`
- Invoke: `/foundry-init` in any project directory (after install), or any individual `/foundry-*` skill standalone
- No test suite yet — verification so far has been direct skill invocation against scratch directories (see Current Status)
