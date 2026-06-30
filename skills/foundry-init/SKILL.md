---
name: foundry-init
description: Initialize a project with Foundry's scaffolding — docs, hooks, security baseline, repo hygiene, governance, and optional career/stack tracking. Three paths at Step 0: throwaway/script (minimal CLAUDE.md only), new real project (full questionnaire + full sequence), or existing project (pick specific pieces to add without redoing the whole sequence). This is the orchestrator; it calls foundry-docs, foundry-hooks, foundry-security, foundry-repo-hygiene, foundry-governance, and foundry-stack.
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

Ask first, before anything else — three options, not two:

1. **Throwaway/personal script** — skip the full questionnaire. Write a minimal CLAUDE.md with `What this is`, `Stack`, `How to run` — nothing else — via `foundry-docs` in its simplest mode (no DECISIONS.md/SESSIONS.md, no hooks, no security/governance sections). Before stopping, write `foundry.scaffoldMode: "minimal"` into `.claude/settings.json` (create the file if it doesn't exist yet) — this lets a later freshness check (`foundry-repo-hygiene`) notice if a "throwaway" project has quietly grown into something that now warrants the full questionnaire. Stop here. Don't make a 10-line script justify a compliance section.

2. **New real project** — continue to Step 0.5, then the full questionnaire below.

3. **Existing project / already has docs** — this project already has some or all of CLAUDE.md, DECISIONS.md, SESSIONS.md, hooks, or other structure in place, and the user wants to add or update one or more specific pieces without redoing the whole sequence. Go to **Step 0-E** below instead of the full questionnaire.

---

## Step 0-E — existing project retrofit (only reached from Step 0 option 3)

Ask what they actually want — don't run anything they haven't asked for:

> "Which pieces do you want to add or update? (Pick one or more — I'll run just those, not the full sequence.)"
> - **SessionStart hook + status hook** (`/foundry-hooks`) — loads your docs automatically at every session start, shows Foundry status; the most useful single piece to add to an existing project
> - **Secrets guard** (`/foundry-security`) — `.gitignore` baseline, `.env.example`, and a commit-time hook that blocks accidental credential commits
> - **CLAUDE.md / DECISIONS.md / SESSIONS.md** (`/foundry-docs`) — create or update the core docs; Foundry will read existing files and ask per-file before changing anything
> - **Governance / compliance sections** (`/foundry-governance`) — regulatory context and compliance notes
> - **STACK.md career tracking** (`/foundry-stack`) — resume/portfolio tech-stack doc
> - **Repo hygiene rules** (`/foundry-repo-hygiene`) — "keep docs current" discipline added to CLAUDE.md
> - **All of the above** — run the full sequence (same as option 2 above, but Foundry will detect and protect existing files rather than treating this as a blank slate). **Warn the user before they pick this**: on a mature project with real hand-written docs, "all of the above" is the highest-risk option, not the safest — foundry-docs will encounter existing CLAUDE.md/DECISIONS.md/SESSIONS.md and ask per-file what to do with each one. If their docs are already good, there's no upside. Recommend picking only the specific pieces they're missing instead, and reserve this option for projects that genuinely want the full Foundry template structure from scratch.

Run only the selected sub-skills, in the dependency order defined in Step 2. Skip Step 0.5 (explain mode) and Step 1 (the full questionnaire) unless the user picks "All of the above" or is creating CLAUDE.md for the first time — in which case you need the questionnaire answers to derive the flags correctly.

**Important:** every selected sub-skill still applies the same overwrite protection — it reads existing files and asks per-file before changing anything. Running `/foundry-hooks` on a project that already has a `settings.json` merges cleanly rather than replacing it. This path is safe to run on a project that already has hand-written docs.

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
1. **`foundry-repo-hygiene`** (Part 1 — new repo sequencing). For a brand-new repo: this step always writes a universal `.gitignore` baseline (OS/build junk) regardless of `HANDLES_SECRETS` — see that skill's step 2 (Session 19 fix: this used to be entirely skipped for non-secrets projects). If `HANDLES_SECRETS`, it additionally invokes `foundry-security`'s `.gitignore`-baseline step to merge the credential-pattern baseline on top, as part of establishing the correct order (`.gitignore` before first commit) — that single sub-step is done once it completes. For a retrofit of an existing repo: this step instead runs the already-committed-secrets check via `foundry-security` step 3 before proceeding, and does not touch `.gitignore` itself (that happens in step 2 below for retrofits).
2. **`foundry-security`** — only if `HANDLES_SECRETS`. For a brand-new repo, the `.gitignore` baseline was already handled in step 1 — this step now only needs to run the remaining parts (`.env.example` convention, the already-committed-secrets check, wiring the secrets-guard hook). For a retrofit, run the full skill including `.gitignore` here, since step 1 didn't touch it for that case.
3. **`foundry-docs`** — always. Scaffolds CLAUDE.md/DECISIONS.md/SESSIONS.md using the flags gathered in Step 1.
4. **`foundry-governance`** — only if `REGULATED` or `HANDLES_DATA_OR_MONEY`. Fills in the REGULATORY CONTEXT / compliance sections `foundry-docs` left as placeholders, with real project-specific content (or an honest "not yet researched" placeholder — see that skill's step 2).
5. **`foundry-hooks`** — always (Hook 1, the SessionStart doc-loader; Hook 3, the status hook — see Step 2.5). Also Hook 2 (secrets-guard) if `HANDLES_SECRETS`.
6. **`foundry-stack`** — only if `TRACK_STACK`. Sets up STACK.md and adds its update discipline to CLAUDE.md's `{{ADDITIONAL_RULES}}`.
7. **`foundry-repo-hygiene`** (Part 2) — add the "keep docs current" rules into CLAUDE.md's `{{ADDITIONAL_RULES}}` (coordinate timing with `foundry-docs` — this needs to happen as part of or immediately after that skill's render step, not as a separate later edit that risks drifting from the template).

**Multi-writer note on `{{ADDITIONAL_RULES}}`:** more than one skill in this sequence (`foundry-stack`, `foundry-repo-hygiene`, and potentially `foundry-governance`/`foundry-security` rules added in earlier sessions) writes into this same CLAUDE.md section. Every write to it must be a read-then-append, never a replace: read the current contents of the section, confirm the new rule isn't already present (don't duplicate an identical line if a skill is re-run), and add the new line(s) without touching what's already there. This applies whether these skills run back-to-back in one `foundry-init` pass or are invoked standalone in separate sessions months apart. **This sequence must run strictly one step at a time, never in parallel** — the read-then-append discipline above only holds if each write fully completes before the next one starts; running steps 1-7 concurrently would create a race on this shared section.

## Step 2.5 — write the scaffolded marker

After Step 2 completes successfully, write `foundry.scaffolded: true`, `foundry.scaffoldedDate: "<today's date>"`, and `foundry.scaffoldMode: "full"` into `.claude/settings.json` (merge — don't clobber the hooks object `foundry-hooks` just wrote). `scaffolded`/`scaffoldedDate` are what the status hook (see `foundry-hooks` skill, Hook 3) checks on future sessions to know not to offer `/foundry-init` again. Without this step, every future session in this project would see "not set up" forever even after a successful run — so this is not optional cleanup, it's the thing that makes the status hook's positive case work at all. `scaffoldMode: "full"` (as opposed to `"minimal"`, written by Step 0's throwaway path) is what lets `foundry-repo-hygiene`'s freshness check later notice if a minimal-mode project has outgrown that original choice.

## Step 3 — mention Promptify and qc-review

Once scaffolding is done, tell the user both are available (from this Foundry install), without invoking either automatically — just surface that they exist:
- `/promptify` and `/promptify!` for turning rough task descriptions into structured, effective prompts — worth a try the next time they're about to write a multi-step request.
- `/qc-review` for an adversarial, fresh-context review hunting specifically for destructive actions, security gaps, and silent overwrites — worth running before treating security-sensitive or destructive-capable work as finished. This is narrower than a general code review; mention that distinction if the project also has something like `/code-review`.

## Step 4 — final review, no auto-commit

Show the user a summary of everything created/modified (file list, not full contents again — they've already seen each piece as it was built). Ask if they want to commit now; do not commit without that explicit confirmation, consistent with the standing rule this very orchestrator just wrote into their CLAUDE.md.

After the commit question, always show this reminder — word for word, every time, for both new and existing projects:

> **One thing to know about your docs going forward:** The hooks Foundry just wired will automatically load CLAUDE.md, DECISIONS.md, and SESSIONS.md into context at the start of every future session — so the assistant always starts with your project's full context without you having to ask. But the hooks don't *write* to those docs automatically. Keeping them current is still on you and the assistant.
>
> The good news: the rule "update SESSIONS.md and CLAUDE.md before ending a session" is now written into your CLAUDE.md, which loads automatically — so the assistant will see it every session. But to make sure it actually happens, get in the habit of saying **"wrap up and update the docs"** before you close a session. That one phrase is all it takes.

## Step 5 — mid-session catch-up offer (existing-project path only)

**Only run this step if `/foundry-init` was invoked via the existing-project path (Step 0-E).** Skip entirely for new projects and throwaway scripts — their docs were just created fresh and are already current.

The scenario this addresses: the user ran `/foundry-init` mid-session, not at the very start. Work may have happened earlier in this conversation that isn't captured in SESSIONS.md/CLAUDE.md yet. But there's a second, more serious risk: **this session may have been open for a long time, and other sessions (in other Claude Code instances) may have already updated the docs after this instance was opened** — meaning earlier parts of this session's history could predate changes already committed by other instances, and blindly backfilling would add conflicting or stale information.

### The warning — always show this first, before asking anything

State this plainly, every time, before offering the catch-up:

> **Heads up before we update anything:** If this session has been open for a while, or if other Claude Code instances have been working on this project at the same time, the docs may already reflect newer work than what happened earlier in this conversation. Backfilling from earlier in this session could add outdated or conflicting information — especially if another instance already captured that work more recently.
>
> The safest approach is to go back only as far as you're confident is still current. Or if you're not sure, start fresh from here and let future sessions capture forward from this point.

### The catch-up options — offer these after the warning

Ask the user which scope they want:

- **From the beginning of this session** — review everything that happened before this `/foundry-init` call and draft what to add. Highest risk of conflicts if other instances have been active.
- **Back X prompts** — the user names how many prompts back to go (e.g. "last 10 exchanges") — good middle ground when the user knows roughly when the relevant work happened.
- **Just the most recent work** — only the last exchange or two before this init call. Lowest conflict risk.
- **Skip — start fresh from here** — don't backfill anything. Future sessions capture forward from this point. Recommended when in doubt.

### How to execute the catch-up (for any scope other than "skip")

1. **Read the current docs first** — read CLAUDE.md and SESSIONS.md in full before proposing anything. The goal is to find the *delta* between what the docs already say and what this session did — not to reconstruct the session from scratch.
2. **Compare, don't overwrite** — identify what looks genuinely missing from the docs vs. what's already captured (possibly by another instance). If SESSIONS.md already has an entry for today, or CLAUDE.md's Current Status already reflects something from this session, don't duplicate or contradict it — note the overlap and ask.
3. **Flag conflicts explicitly** — if anything from the session history contradicts what's already in the docs (e.g. the docs say X is done but this session was still working on X), surface that directly: "The docs say [X] but earlier in this session we were [Y] — which is current?" Do not resolve this silently.
4. **Draft, don't write** — present the proposed additions as a draft and ask the user to confirm each piece before writing. The user is the only one who knows which instance has the authoritative current state.
5. **Write conservatively** — append to SESSIONS.md and CLAUDE.md (read-then-append, same discipline as always); never replace existing entries, never remove content already there.

### What this step explicitly does NOT do

- It does not measure context usage or know how long this session has been open — it can only see what's in the conversation history and what's currently in the docs.
- It cannot detect whether another instance updated the docs more recently than this session — it can only surface the conflict for the user to resolve.
- It does not auto-write anything. Every proposed addition requires explicit user confirmation.

## Dismissing the status hook's offer (not part of foundry-init's own flow, but related)

If the user responds to the status hook's offer (see `foundry-hooks` Hook 3) with something like "skip foundry" or "skip foundry for this project" rather than running `/foundry-init`, write `foundry.dismissed: true` into `.claude/settings.json` (merge, same as Step 2.5) so future sessions in this project stay silent rather than re-offering every time. This is a real, explicit user choice being recorded — don't write it speculatively or infer it from an unrelated "no" to some other question.

**Re-enabling after a dismissal**: the `foundry.dismissed` flag only affects the passive status hook (it goes silent rather than re-offering) — it does not, and must not, make `foundry-init` itself refuse to run. If the user manually invokes `/foundry-init` directly at any later point (e.g. the project has grown and now actually needs this), run the full flow normally from Step -1, regardless of any existing `dismissed` flag. On successful completion, Step 2.5's write of `foundry.scaffolded: true` naturally supersedes the old dismissal (the status hook's logic checks `scaffolded` before `dismissed` — see `foundry-hooks` Hook 3). There is no separate "undismiss" command needed; running `/foundry-init` again is itself the re-enable path. State this plainly if a user asks how to bring Foundry back after dismissing it.
