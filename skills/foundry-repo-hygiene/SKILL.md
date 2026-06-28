---
name: foundry-repo-hygiene
description: Apply git repo and documentation hygiene practices that don't fit neatly into docs/hooks/security alone — correct sequencing for a brand-new repo's first commit, and a standing discipline for keeping README/SESSIONS.md current as the project changes. Use during foundry-init for new repos, or standalone on an existing repo to audit its current hygiene.
---

# foundry-repo-hygiene

Covers two things that are easy to get backwards or let slide silently: how a repo's *first* commit should be sequenced, and the ongoing discipline of keeping documentation honest as code changes — neither of which is really a "security" concern or a "docs template" concern on its own.

**`EXPLAIN_MODE`** (set by `foundry-init`, or ask if standalone): in `detailed` mode, explain the sequencing rationale before applying it — `.gitignore` goes in before the first `git add`, not after, because once a secret is committed it's in history even if later deleted; fixing the order in advance is strictly cheaper than cleaning up after the fact. In `brief` mode, just apply the sequence.

## Part 1 — new repo sequencing (use during initial setup)

The common mistake this prevents: writing code first, committing it, *then* adding `.gitignore` and security rules — by which point a secret may already be in history (see `foundry-security` step 3 for what to do if that's already happened).

**Check first whether this is even a git repo yet** (`git rev-parse --is-inside-work-tree` or equivalent). If not, and the project is meant to be version-controlled, `git init` is step 1 below, not assumed already done. If the user has deliberately chosen not to use git for this project, skip the git-specific steps below entirely (the doc/hook scaffolding still applies fine without git) rather than forcing a `git init` they didn't ask for.

**Correct order for a brand-new project:**
1. `git init`
2. Write/merge `.gitignore` (via `foundry-security`, if the project handles secrets) — **before the first `git add`**, not after.
3. Run `foundry-docs` to create CLAUDE.md/DECISIONS.md/SESSIONS.md.
4. Run `foundry-hooks` to wire the SessionStart loader (and secrets-guard, if applicable).
5. Only then write/add actual project code.
6. First commit should include the scaffolding (docs, `.gitignore`, `.claude/settings.json`) as one coherent commit — not mixed in ad hoc with the first feature code, so the scaffolding is easy to find/reference later (`git log` shows "project scaffolding" as a distinct, identifiable point in history).
7. Before any commit at any point: confirm working tree status and diff, never blind-stage with `git add -A`/`git add .` — stage specific files, consistent with standing git-safety practice.

**For an existing repo being retrofitted** (Foundry added after the fact): don't try to rewrite history to "fix" the sequencing — that's a destructive operation with low payoff. Just apply `foundry-security`'s already-committed-secrets check (step 3 in that skill) to see if anything needs rotating, then proceed with the scaffolding as a normal new commit going forward.

## Part 2 — keeping documentation honest over time (an ongoing discipline, not a one-time setup step)

This isn't something a hook can fully enforce (a hook can't judge whether a README *description* is still accurate), but Foundry should make the expectation explicit and give the user/assistant a concrete check to run periodically, rather than leaving "keep docs current" as a vague aspiration.

**What gets added to the generated CLAUDE.md's Rules section** (coordinate with `foundry-docs` — this is additional content for `{{ADDITIONAL_RULES}}` when this skill runs):
- "Update SESSIONS.md and, if status changed, CLAUDE.md as part of the same work — not as a separate cleanup pass remembered later. A session that changed behavior but didn't update these docs is not finished."
- "If README.md describes a feature, command, or setup step that no longer matches reality, fix the README in the same change — don't leave it to drift."

**A standalone freshness check** (`foundry-repo-hygiene` can run this on request, e.g. "audit doc freshness"):
1. Check `git log -1 --format=%ci -- README.md` vs. `git log -1 --format=%ci` (most recent commit overall) — if the gap is large relative to the project's commit cadence, flag it as a candidate for review (not an automatic failure — a stable README that hasn't needed changes isn't necessarily stale).
2. Read README.md's stated "how to run" / setup commands and actually try them (or at minimum check the referenced files/scripts still exist) — a command that references a deleted file is a concrete, checkable staleness signal, not a guess.
3. Check whether CLAUDE.md's "Current status" section references things (files, agents, features) that still exist in the codebase — grep for the named files/symbols.
4. **If CLAUDE.md has a REGULATORY CONTEXT or COMPLIANCE/AUDIT TRAIL section** (written by `foundry-governance`), explicitly include it in this check — regulatory guidance changes over time and that section is dated for exactly this reason, but nothing else in Foundry ever resurfaces it for review. Check the date stated in that section against today; if it's been more than a few months (use judgment based on how fast-moving the relevant regulatory area is — ask the user if unsure), flag it specifically as "this compliance section was written on X and may be stale — worth re-verifying with the relevant regulatory source before continuing to rely on it," not just lumped in with general doc staleness.
5. **If the project was originally scaffolded via the minimal/throwaway fast-path** (check `foundry.scaffoldMode` in `.claude/settings.json`, if present) but now has real complexity (handles secrets, has grown significantly, etc.), flag this explicitly: "this project was scaffolded as a quick/minimal setup — if it's become a real project now, consider re-running `/foundry-init` for the full questionnaire (security baseline, etc.)." This is the only mechanism that catches a throwaway script that quietly became a real project with no security baseline.
6. Report findings plainly; don't auto-fix without showing the user what's stale and why first.

## Verification (for this skill's own setup logic)

The `.gitignore`-before-first-commit sequencing and the "stage specific files, not `-A`" rule were checked against the same git-safety standing instructions already in use elsewhere (see Karbot Rage's CLAUDE.md "Git" section for the precedent) — not a new invented rule, just made explicit and sequenced correctly here.
