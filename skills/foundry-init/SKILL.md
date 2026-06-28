---
name: foundry-init
description: Initialize a new (or retrofit an existing) project with Foundry's full scaffolding — docs, hooks, security baseline, repo hygiene, governance, and optional career/stack tracking, derived from a short questionnaire rather than a fixed preset. This is the orchestrator; it calls foundry-docs, foundry-hooks, foundry-security, foundry-repo-hygiene, foundry-governance, and foundry-stack in sequence. Use at the start of a new project, or on an existing project that wants Foundry's structure retrofitted.
---

# foundry-init

Thin orchestrator. Does not duplicate logic from the skills it calls — read each referenced skill's `SKILL.md` and follow its steps directly rather than re-describing them here.

## Step 0 — fast path check

Ask first, before anything else: **"Is this a throwaway/personal script, or a real project you intend to maintain?"**

If throwaway: skip the full questionnaire. Just write a minimal CLAUDE.md with `What this is`, `Stack`, `How to run` — nothing else — via `foundry-docs` in its simplest mode (no DECISIONS.md/SESSIONS.md, no hooks, no security/governance sections). Stop here. Don't make a 10-line script justify a compliance section.

If real project: continue to Step 0.5, then the full questionnaire below.

## Step 0.5 — explain mode

Ask: **"As we go, do you want brief explanations (just what's happening) or detailed/educational ones (what's happening and why, useful if you're newer to this kind of project setup)? You can ask me to switch at any point."**

Set `EXPLAIN_MODE` to `brief` or `detailed` accordingly and carry it through to every sub-skill called below. In `detailed` mode, each sub-skill should state a short "why" before doing something non-obvious — most of this reasoning already exists in each skill's own `SKILL.md` (e.g. why `.gitignore` goes in before the first commit, why governance defaults to an honest gap instead of generic text) — `detailed` mode means surfacing that reasoning to the user in the moment, not inventing new explanations. In `brief` mode, just do the thing, the way Foundry behaves by default today. Default to `brief` if the user doesn't have a preference yet, but mention the option exists — don't make them discover it.

## Step 1 — questionnaire

Ask via `AskUserQuestion`, kept short (don't ask things you can infer from the repo if one already exists — check first):
1. Project name + one-paragraph "what this is."
2. Tech stack.
3. Does this project handle secrets/credentials/API keys? → `HANDLES_SECRETS`
4. Does this project handle other people's data or money? → `HANDLES_DATA_OR_MONEY`
5. Is this in a regulated industry or subject to specific external rules? → `REGULATED`
6. Solo project, or will others (people or other AI instances) work on this too? → informs whether to emphasize DECISIONS.md rationale fields and shared vs. personal settings files in the generated Rules section.
7. Where/how does this run today, or how will it once built?
8. Do you want to track this project's tech stack for career/portfolio purposes (resume bullets, interview prep)? → `TRACK_STACK`. Skip asking this if the project is clearly work-for-hire or otherwise not the user's to narrate publicly — ask directly if unclear rather than assuming.

Derive flags from answers — don't ask the user to name a "preset." If they answer "yes" to both secrets and regulated, that's just two true flags, not a special combined case requiring different handling.

## Step 2 — sequence the calls

Run in this order (matches dependency order — later steps assume earlier ones exist):
1. **`foundry-repo-hygiene`** (Part 1 — new repo sequencing) — if this is a brand-new repo, this establishes the correct order (`.gitignore` before first commit, etc.) for everything that follows. If retrofitting an existing repo, this step instead runs the already-committed-secrets check via `foundry-security` step 3 before proceeding.
2. **`foundry-security`** — only if `HANDLES_SECRETS`. Sets up `.gitignore`/`.env.example` baseline.
3. **`foundry-docs`** — always. Scaffolds CLAUDE.md/DECISIONS.md/SESSIONS.md using the flags gathered in Step 1.
4. **`foundry-governance`** — only if `REGULATED` or `HANDLES_DATA_OR_MONEY`. Fills in the REGULATORY CONTEXT / compliance sections `foundry-docs` left as placeholders, with real project-specific content (or an honest "not yet researched" placeholder — see that skill's step 2).
5. **`foundry-hooks`** — always (Hook 1, the SessionStart doc-loader; Hook 3, the status hook — see Step 2.5). Also Hook 2 (secrets-guard) if `HANDLES_SECRETS`.
6. **`foundry-stack`** — only if `TRACK_STACK`. Sets up STACK.md and adds its update discipline to CLAUDE.md's `{{ADDITIONAL_RULES}}`.
7. **`foundry-repo-hygiene`** (Part 2) — add the "keep docs current" rules into CLAUDE.md's `{{ADDITIONAL_RULES}}` (coordinate timing with `foundry-docs` — this needs to happen as part of or immediately after that skill's render step, not as a separate later edit that risks drifting from the template).

## Step 2.5 — write the scaffolded marker

After Step 2 completes successfully, write `foundry.scaffolded: true` and `foundry.scaffoldedDate: "<today's date>"` into `.claude/settings.json` (merge — don't clobber the hooks object `foundry-hooks` just wrote). This is what the status hook (see `foundry-hooks` skill, Hook 3) checks on future sessions to know not to offer `/foundry-init` again. Without this step, every future session in this project would see "not set up" forever even after a successful run — so this is not optional cleanup, it's the thing that makes the status hook's positive case work at all.

## Step 3 — mention Promptify

Once scaffolding is done, tell the user `/promptify` and `/promptify!` are available (from this Foundry install) for turning rough task descriptions into structured, effective prompts — and that it's worth a try the next time they're about to write a multi-step request. Don't invoke it automatically; just surface that it exists.

## Step 4 — final review, no auto-commit

Show the user a summary of everything created/modified (file list, not full contents again — they've already seen each piece as it was built). Ask if they want to commit now; do not commit without that explicit confirmation, consistent with the standing rule this very orchestrator just wrote into their CLAUDE.md.

## Notes on retrofitting an existing project

Everything above applies the same way, except:
- Step 0's fast-path question becomes "do you want full scaffolding, or just specific pieces (e.g. just the SessionStart hook)?" — an existing project may only want one piece, not the whole set. Offer to run just one sub-skill if that's all they want; don't force the full sequence.
- `foundry-docs` should check for and offer to migrate existing informal notes (per its own SKILL.md) rather than overwriting blindly.

## Dismissing the status hook's offer (not part of foundry-init's own flow, but related)

If the user responds to the status hook's offer (see `foundry-hooks` Hook 3) with something like "skip foundry" or "skip foundry for this project" rather than running `/foundry-init`, write `foundry.dismissed: true` into `.claude/settings.json` (merge, same as Step 2.5) so future sessions in this project stay silent rather than re-offering every time. This is a real, explicit user choice being recorded — don't write it speculatively or infer it from an unrelated "no" to some other question.
