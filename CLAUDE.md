# Foundry

## What this is
Foundry scaffolds software projects with the documentation structure, hooks, and guardrails that make AI-assisted development reliable across many sessions, derived from a short per-project questionnaire rather than a fixed template. Part of the "Preamble" brand (Preamble = the umbrella; Foundry = this specific tool; Promptify = a separate, related tool also living here for now).

## Stack
- Claude Code skills (Markdown `SKILL.md` files, no compiled code)
- Bash (`install.sh`, hook commands)
- `jq` for hook JSON generation/validation

## Architecture
- `skills/foundry-init/` — orchestrator; calls the others in sequence based on a questionnaire; writes the `foundry.scaffolded`/`scaffoldedDate` marker into `.claude/settings.json` on successful completion, and `foundry.dismissed` if the user declines the status hook's offer
- `skills/foundry-docs/` — renders `templates/*.template` into a project's CLAUDE.md/DECISIONS.md/SESSIONS.md
- `skills/foundry-hooks/` — wires three hooks into a project's `.claude/settings.json`: Hook 1 (SessionStart doc-loader), Hook 2 (secrets-guard pre-commit, only if `HANDLES_SECRETS`), Hook 3 (status/offer — checks `foundry.scaffolded`/`foundry.dismissed`, always added)
- `skills/foundry-security/` — `.gitignore` baseline, `.env.example` convention, already-committed-secrets check
- `skills/foundry-repo-hygiene/` — new-repo commit sequencing, ongoing docs-freshness discipline
- `skills/foundry-governance/` — regulatory/compliance section content, with an explicit anti-fabrication rule (states "not yet researched" rather than inventing plausible compliance language)
- `skills/foundry-stack/` — STACK.md setup/maintenance for career/portfolio documentation (separate audience/lifecycle from the other docs); enforces a "why this over alternatives" rule on every non-trivial entry, not just "what was used"
- `skills/promptify/` — standalone; `/promptify` and `/promptify!`, not dependent on the rest of Foundry
- `templates/` — the actual template files the above skills render (`CLAUDE.md`, `DECISIONS.md`, `SESSIONS.md`, `STACK.md`, `settings.hooks.json` [doc-loader], `settings.status.json` [status/offer])
- `install.sh` — symlinks `skills/*` into `~/.claude/skills/`

## Current status
- `EXPLAIN_MODE` convention across `foundry-init` and all sub-skills: an up-front question (brief vs. detailed/educational explanations) that, when set to detailed, makes each skill surface the "why" already documented in its own SKILL.md to the user in the moment.
- `foundry-stack`/STACK.md added: career/portfolio tech-stack tracking, modeled directly on a proven real pattern (the user's existing `lazy-larry/STACK.md`), with a mandatory why-linkage rule (inline reasoning or a DECISIONS.md cross-reference) so it doesn't degenerate into a list of technology names with no interview value.
- Status/offer hook (Hook 3 in `foundry-hooks`) added: a project not yet scaffolded gets a one-line offer at session start; an already-scaffolded project gets a silent "Foundry: Active" confirmation; a dismissed project stays silent. All three states verified against the real, JSON-embedded extracted command, not just the unescaped logic.
- Context-checkpoint rule added to the CLAUDE.md template's standing Rules: proactively suggest a SESSIONS.md/memory update + `/clear` when a session has drifted across many unrelated subtasks or run long — same category as verify-before-trust (a good practice made into a written, enforced expectation rather than left to in-the-moment judgment).
- **Independent safety review completed (Session 4)**: a fresh subagent with no prior context reviewed every skill cold, specifically hunting for destructive/silent actions. Found 14 issues, 2 CRITICAL (both involving security-relevant regex/glob patterns that the skill prose claimed were "tested" but actually missed realistic filenames — verified by reproducing the failure independently before fixing). All CRITICAL and most HIGH/MEDIUM findings fixed and re-verified against adversarial fixture sets; remaining lower-severity findings explicitly tracked in README.md's Roadmap, none silently dropped.
- Two real overwrite-risk gaps (found by the user, not caught by prior sessions) closed: `foundry-docs`/`foundry-governance`/`foundry-stack` now all check for and protect existing file content before writing; `foundry-init` now checks whether the current directory is an actual project root before scaffolding (concrete, tested command — not just judgment).
- All 8 skills written; the security-critical mechanisms (secrets-guard regex, `.gitignore` baseline, already-committed-secrets scan, location-safety check) are now verified against real adversarial test fixtures, not just a single happy-path case.
- Pushed to `github.com/WarpedMind/foundry` (public) and installed at `~/.claude/skills/` — both confirmed working.

## KNOWN DEBT
- Promptify's "prompt shape" classification logic has not been tested against a range of real rough inputs yet — only designed, not exercised
- foundry-governance and foundry-security have been verified at the mechanism level (hook logic, detection patterns, now including adversarial regex/glob fixtures) but not yet exercised through a real multi-step Skill invocation the way foundry-init was
- foundry-stack has not yet been exercised through a real Skill invocation either — verified by hand-rendering against real project history, not by running the skill itself end-to-end
- Foundry has never been run on a real, non-scratch project — every test so far was a disposable scratch directory. This is the real next milestone before treating it as proven.
- The new `foundry.scaffoldMode` field and the regulatory-staleness/outgrown-minimal-mode checks in `foundry-repo-hygiene` are designed and written but not yet exercised through a real invocation — same gap as the items above, just added this session.
- See README.md's Roadmap section for explicitly deferred features (proactive review agents, `foundry-update`, persistent statusLine indicator, pluggable external skill packs, cross-project lessons/stack aggregation, shell-quoting hardening, STACK.md confidentiality cross-check)

## Next session priorities (in order)
- Run `/foundry-init` on a real project (not a scratch directory) — the actual milestone that matters most right now
- Exercise `/promptify`, `/foundry-stack`, the status hook's dismiss path, and the new `foundry-repo-hygiene` staleness checks through real Skill-tool invocations to close the remaining verification gaps above
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
