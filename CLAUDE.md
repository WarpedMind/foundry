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
- `skills/foundry-hooks/` — wires hooks into a project's `.claude/settings.json`: Hook 1 (SessionStart doc-loader), Hook 2 (secrets-guard pre-commit, only if `HANDLES_SECRETS`), Hook 3 (status/offer — checks `foundry.scaffolded`/`foundry.dismissed`, always added), Hook 4 (directory-drift logger — optional, `PreToolUse`/`Bash`, logs out-of-project `cd`s to `.claude/drift.log`)
- `skills/foundry-security/` — `.gitignore` baseline, `.env.example` convention, already-committed-secrets check
- `skills/foundry-repo-hygiene/` — new-repo commit sequencing, ongoing docs-freshness discipline
- `skills/foundry-governance/` — regulatory/compliance section content, with an explicit anti-fabrication rule (states "not yet researched" rather than inventing plausible compliance language)
- `skills/foundry-stack/` — STACK.md setup/maintenance for career/portfolio documentation (separate audience/lifecycle from the other docs); enforces a "why this over alternatives" rule on every non-trivial entry, not just "what was used"
- `skills/promptify/` — standalone; `/promptify` and `/promptify!`, not dependent on the rest of Foundry
- `templates/` — the actual template files the above skills render (`CLAUDE.md`, `DECISIONS.md`, `SESSIONS.md`, `STACK.md`, `settings.hooks.json` [doc-loader], `settings.status.json` [status/offer])
- `install.sh` — symlinks `skills/*` into `~/.claude/skills/`

## Current status
- `EXPLAIN_MODE` convention across `foundry-init` and all sub-skills: an up-front question (brief vs. detailed/educational explanations) that, when set to detailed, makes each skill surface the "why" already documented in its own SKILL.md to the user in the moment.
- `foundry-stack`/STACK.md added: career/portfolio tech-stack tracking, modeled directly on a proven real pattern from one of the user's other projects, with a mandatory why-linkage rule (inline reasoning or a DECISIONS.md cross-reference) so it doesn't degenerate into a list of technology names with no interview value.
- Status/offer hook (Hook 3 in `foundry-hooks`) added: a project not yet scaffolded gets a one-line offer at session start; an already-scaffolded project gets a silent "Foundry: Active" confirmation; a dismissed project stays silent. All three states verified against the real, JSON-embedded extracted command, not just the unescaped logic.
- Context-checkpoint rule added to the CLAUDE.md template's standing Rules: proactively suggest a SESSIONS.md/memory update + `/clear` when a session has drifted across many unrelated subtasks or run long — same category as verify-before-trust (a good practice made into a written, enforced expectation rather than left to in-the-moment judgment).
- **Independent safety review completed (Session 4)**: a fresh subagent with no prior context reviewed every skill cold, specifically hunting for destructive/silent actions. Found 14 issues, 2 CRITICAL (both involving security-relevant regex/glob patterns that the skill prose claimed were "tested" but actually missed realistic filenames — verified by reproducing the failure independently before fixing). All CRITICAL and most HIGH/MEDIUM findings fixed and re-verified against adversarial fixture sets; remaining lower-severity findings explicitly tracked in README.md's Roadmap, none silently dropped.
- Two real overwrite-risk gaps (found by the user, not caught by prior sessions) closed: `foundry-docs`/`foundry-governance`/`foundry-stack` now all check for and protect existing file content before writing; `foundry-init` now checks whether the current directory is an actual project root before scaffolding (concrete, tested command — not just judgment).
- All 8 skills written; the security-critical mechanisms (secrets-guard regex, `.gitignore` baseline, already-committed-secrets scan, location-safety check) are now verified against real adversarial test fixtures, not just a single happy-path case.
- Pushed to `github.com/WarpedMind/foundry` (public) and installed at `~/.claude/skills/` — both confirmed working.
- **First real (non-scratch) `/foundry-init` run completed (Session 5)**, on Foundry's own repo via the actual Skill tool. Confirmed the Session 4 safety fixes work on real content: Step -1's location check returned 0 correctly, `foundry-docs` Step 0 detected all three existing real docs and asked per-file rather than overwriting. Created `STACK.md` for real, populated from Foundry's own verified history rather than left empty.
- **`/promptify` exercised for real for the first time (Session 5)**, against a deliberately rough debugging prompt. Found and fixed 4 real gaps in its Step 3 instructions (no role/persona-framing option, no domain-risk-flagging, no hypothesis enumeration for debugging, no test-infrastructure awareness) — confirmed via direct before/after comparison on the identical input, not just by re-reading the updated instructions.
- **Added a third `promptify` entry point: bare `/promptify` (no arguments) — guided build-from-scratch mode (Session 5)**, proposed by the user. Asks the open-ended goal question as plain text (a real `AskUserQuestion` constraint — it requires 2-4 concrete options and can't represent free text), then batches the remaining structural questions into one call. A cost claim in the skill's own description was corrected after being questioned directly: this mode is relatively cheaper in turn count than the fully-conversational alternative, not free.
- **Session 6 — systematic "bulletproof" pass, closing nearly every remaining KNOWN DEBT/Roadmap item.** Fixed and verified shell-quoting hardening (real bug confirmed in bash, fixed with a proper quoted array, re-verified against spaces-in-filename/normal/missing-file cases). Added and verified `foundry-stack`'s confidentiality cross-check. Exercised `/promptify` against all 5 rewrite-mode shapes (architecture, research, writing, debugging, implementation-adjacent) confirming role-framing fires when warranted and stays silent when not. Pressure-tested build-from-scratch mode with a 4+-relevant-question goal, confirming correct prioritization. Exercised the status hook's dismiss path through a real invocation (not just unit-tested), including proving the re-enable claim for real. Ran a full, real `/foundry-init` on a genuinely different project (secrets-handling, uncertain regulatory status, true day-one stack) — the single largest remaining gap — exercising `HANDLES_SECRETS=true`, the complete `foundry-security` flow (including a forced `git add -f .env` to prove the secrets-guard hook genuinely blocks it), `foundry-governance`'s honest-uncertainty handling, and `foundry-stack`'s empty-table discipline, all for the first time together on a real project.

## KNOWN DEBT
- The `foundry.scaffoldMode` field and the regulatory-staleness/outgrown-minimal-mode checks in `foundry-repo-hygiene` are designed and the underlying git-log pattern was verified against a real repo, but the *checks themselves* (as opposed to the marker write, which has now been exercised twice) have still never fired in a real invocation — no test project has yet had a stale regulatory section or an outgrown minimal-mode history to trigger them
- See README.md's Roadmap section for explicitly deferred features (proactive review agents, `foundry-update`, persistent statusLine indicator, pluggable external skill packs, cross-project lessons/stack aggregation, the standalone QC/adversarial-review skill, "Promptify auto mode")

## Next session priorities (in order)
- Re-read this KNOWN DEBT list and README's Roadmap fresh — confirm nothing was missed in the Session 6 pass, since this list should now be genuinely short
- If a real project naturally exercises `foundry-repo-hygiene`'s staleness checks (a stale regulatory section, an outgrown minimal-mode project) during ordinary use, note it — this is the one mechanism-level item left without a real-invocation confirmation
- Otherwise: use Foundry for real, on a real upcoming project — that's the actual remaining test that matters now, not another constructed scenario

## Rules / Never do
- Read CLAUDE.md, DECISIONS.md, and SESSIONS.md at the start of every session and stay anchored to them (enforced by this repo's own SessionStart hook once added — see `.claude/settings.json`)
- Verify external claims (API behavior, docs, third-party task briefs) against live/actual behavior before trusting them and writing code against them
- Use plan mode (or otherwise get explicit sign-off) before non-trivial implementation work
- Commit only when explicitly asked; never use destructive git operations (force-push, hard reset, history rewrites) without explicit confirmation
- Always read a file before editing it; if an exact-match replacement fails, re-read the file to find the actual current content rather than reaching for a regex fallback
- Update SESSIONS.md and, if status changed, CLAUDE.md as part of the same work — not as a separate cleanup pass remembered later
- If README.md describes a feature, command, or setup step that no longer matches reality, fix the README in the same change — don't leave it to drift
- Don't add a new composable skill without updating this CLAUDE.md's Architecture section in the same change
- Update STACK.md whenever a technology is added, replaced, retired, or reaches a milestone worth recording — and only mark something "in use" once actually verified running, not when first written
- Proactively suggest a checkpoint when EITHER (a) the session has covered several unrelated subtasks or run long, OR (b) the working directory has changed to a genuinely different project than where the session started — (b) is a stronger signal than (a) and shouldn't wait for (a) to also be true. To checkpoint: update SESSIONS.md/memory with current state, then suggest `/clear` before continuing.

## How to run / Bash commands
- Install: `./install.sh`
- Invoke: `/foundry-init` in any project directory (after install), or any individual `/foundry-*` skill standalone
- No test suite yet — verification so far has been direct skill invocation against scratch directories (see Current Status)
