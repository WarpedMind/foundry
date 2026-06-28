---
name: foundry-init
description: Initialize a new (or retrofit an existing) project with Foundry's full scaffolding — docs, hooks, security baseline, repo hygiene, governance, and optional career/stack tracking, derived from a short questionnaire rather than a fixed preset. This is the orchestrator; it calls foundry-docs, foundry-hooks, foundry-security, foundry-repo-hygiene, foundry-governance, and foundry-stack in sequence. Use at the start of a new project, or on an existing project that wants Foundry's structure retrofitted.
---

# foundry-init

Thin orchestrator. Does not duplicate logic from the skills it calls — read each referenced skill's `SKILL.md` and follow its steps directly rather than re-describing them here.

**Safety invariant, applies to every step below without exception: never silently overwrite a pre-existing CLAUDE.md, DECISIONS.md, SESSIONS.md, STACK.md, `.gitignore`, or `.claude/settings.json`.** This is most often run on an *existing* project, not a blank one — `foundry-docs` (Step 0 in its own SKILL.md) and `foundry-security`/`foundry-hooks` all already check for and merge with existing files rather than blind-overwriting, but it's worth stating here too because the cost of getting this wrong is real and irreversible: a hand-maintained CLAUDE.md with months of real project history is not something a template can regenerate if it gets clobbered. If any sub-skill's instructions ever seem to call for writing over an existing file without first reading it and asking the user, that's a bug in this Foundry checkout — stop and ask the user how to proceed rather than following the letter of an instruction that would destroy real content.

## Step -1 — location sanity check (run before anything else, including Step 0)

Foundry scaffolds exactly one project at the current working directory — it does not, and must never, cascade into subdirectories or affect anything beyond the current folder. Before asking any other question, run an actual check, not just a visual judgment call (an independent safety review flagged that judgment alone, with no concrete command, is too weak a guard against scaffolding the wrong directory):

```bash
for d in */; do [ -d "${d}.git" ] && echo "$d"; done | wc -l
```

This counts immediate subdirectories that are themselves separate git repositories. Verified behavior: inside a real single-project root, this returns 0 (or very low, e.g. for a monorepo with intentional sub-repos — use judgment there); inside a container folder holding multiple unrelated projects (e.g. `~/Projects/`), it returns one count per sibling project. **If this returns 2 or more, treat it as an automatic stop, not a soft signal** — also check whether the current directory itself has no obvious single-project markers (no `.git`, no `package.json`/`pyproject.toml`/`Cargo.toml`/`go.mod`/etc. of its own) combined with the subdirectory count being nonzero, which is the strongest signal of a container folder.

If the check indicates a wrong location:
1. **Stop. Do not proceed to Step 0.** Tell the user plainly what the check found (e.g. "This folder has 4 subdirectories that are each their own git repo — that looks like a container folder holding multiple projects, not one project's root. Did you mean to `cd` into a specific project first?").
2. Ask them to confirm the intended directory, or `cd`/navigate there first, before continuing.
3. Never default to "proceed anyway" — a wrong-location scaffold is exactly the kind of mistake this skill must not make silently, since CLAUDE.md/DECISIONS.md/SESSIONS.md written directly into a container folder like `~/Projects/` would be confusing clutter at best and could shadow/conflict with unrelated tooling at worst.

This check is a strong heuristic, not an absolute technical guarantee — Claude Code itself has no built-in concept of "project boundary" beyond the current working directory. A monorepo with intentional git submodules could have a nonzero count and still be a legitimate single project; use the command's result as the primary signal, but still apply judgment for edge cases like that rather than blocking unconditionally on the number alone.

## Step 0 — fast path check

Ask first, before anything else: **"Is this a throwaway/personal script, or a real project you intend to maintain?"**

If throwaway: skip the full questionnaire. Just write a minimal CLAUDE.md with `What this is`, `Stack`, `How to run` — nothing else — via `foundry-docs` in its simplest mode (no DECISIONS.md/SESSIONS.md, no hooks, no security/governance sections). Before stopping, write `foundry.scaffoldMode: "minimal"` into `.claude/settings.json` (create the file if it doesn't exist yet, even without the full hooks setup) — this is what lets a later freshness check (`foundry-repo-hygiene`) notice if a "throwaway" project has quietly grown into something that now warrants the full questionnaire, since nothing else in Foundry would otherwise ever revisit that original choice. Stop here. Don't make a 10-line script justify a compliance section.

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

Run in this order (matches dependency order — later steps assume earlier ones exist). Note the step 1/step 2 boundary below to avoid double-running or skipping the `.gitignore` setup — `foundry-repo-hygiene`'s own sequencing notes mention calling into `foundry-security` for `.gitignore`, but that call happens *as part of* step 1 below for new repos, not as a separate thing step 2 also has to do:
1. **`foundry-repo-hygiene`** (Part 1 — new repo sequencing). For a brand-new repo: this step itself invokes `foundry-security`'s `.gitignore`-baseline step (only) as part of establishing the correct order (`.gitignore` before first commit) — that single sub-step is done once it completes. For a retrofit of an existing repo: this step instead runs the already-committed-secrets check via `foundry-security` step 3 before proceeding, and does not touch `.gitignore` itself (that happens in step 2 below for retrofits).
2. **`foundry-security`** — only if `HANDLES_SECRETS`. For a brand-new repo, the `.gitignore` baseline was already handled in step 1 — this step now only needs to run the remaining parts (`.env.example` convention, the already-committed-secrets check, wiring the secrets-guard hook). For a retrofit, run the full skill including `.gitignore` here, since step 1 didn't touch it for that case.
3. **`foundry-docs`** — always. Scaffolds CLAUDE.md/DECISIONS.md/SESSIONS.md using the flags gathered in Step 1.
4. **`foundry-governance`** — only if `REGULATED` or `HANDLES_DATA_OR_MONEY`. Fills in the REGULATORY CONTEXT / compliance sections `foundry-docs` left as placeholders, with real project-specific content (or an honest "not yet researched" placeholder — see that skill's step 2).
5. **`foundry-hooks`** — always (Hook 1, the SessionStart doc-loader; Hook 3, the status hook — see Step 2.5). Also Hook 2 (secrets-guard) if `HANDLES_SECRETS`.
6. **`foundry-stack`** — only if `TRACK_STACK`. Sets up STACK.md and adds its update discipline to CLAUDE.md's `{{ADDITIONAL_RULES}}`.
7. **`foundry-repo-hygiene`** (Part 2) — add the "keep docs current" rules into CLAUDE.md's `{{ADDITIONAL_RULES}}` (coordinate timing with `foundry-docs` — this needs to happen as part of or immediately after that skill's render step, not as a separate later edit that risks drifting from the template).

**Multi-writer note on `{{ADDITIONAL_RULES}}`:** more than one skill in this sequence (`foundry-stack`, `foundry-repo-hygiene`, and potentially `foundry-governance`/`foundry-security` rules added in earlier sessions) writes into this same CLAUDE.md section. Every write to it must be a read-then-append, never a replace: read the current contents of the section, confirm the new rule isn't already present (don't duplicate an identical line if a skill is re-run), and add the new line(s) without touching what's already there. This applies whether these skills run back-to-back in one `foundry-init` pass or are invoked standalone in separate sessions months apart. **This sequence must run strictly one step at a time, never in parallel** — the read-then-append discipline above only holds if each write fully completes before the next one starts; running steps 1-7 concurrently would create a race on this shared section.

## Step 2.5 — write the scaffolded marker

After Step 2 completes successfully, write `foundry.scaffolded: true`, `foundry.scaffoldedDate: "<today's date>"`, and `foundry.scaffoldMode: "full"` into `.claude/settings.json` (merge — don't clobber the hooks object `foundry-hooks` just wrote). `scaffolded`/`scaffoldedDate` are what the status hook (see `foundry-hooks` skill, Hook 3) checks on future sessions to know not to offer `/foundry-init` again. Without this step, every future session in this project would see "not set up" forever even after a successful run — so this is not optional cleanup, it's the thing that makes the status hook's positive case work at all. `scaffoldMode: "full"` (as opposed to `"minimal"`, written by Step 0's throwaway path) is what lets `foundry-repo-hygiene`'s freshness check later notice if a minimal-mode project has outgrown that original choice.

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

**Re-enabling after a dismissal**: the `foundry.dismissed` flag only affects the passive status hook (it goes silent rather than re-offering) — it does not, and must not, make `foundry-init` itself refuse to run. If the user manually invokes `/foundry-init` directly at any later point (e.g. the project has grown and now actually needs this), run the full flow normally from Step -1, regardless of any existing `dismissed` flag. On successful completion, Step 2.5's write of `foundry.scaffolded: true` naturally supersedes the old dismissal (the status hook's logic checks `scaffolded` before `dismissed` — see `foundry-hooks` Hook 3). There is no separate "undismiss" command needed; running `/foundry-init` again is itself the re-enable path. State this plainly if a user asks how to bring Foundry back after dismissing it.
