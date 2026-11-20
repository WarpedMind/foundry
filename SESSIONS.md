# Foundry Session Summary
# Entries are ordered newest-to-oldest. Most recent session is at the top.
# Entries older than the newest two are archived, verbatim, in SESSIONS_ARCHIVE.md
# (starting from "2026-10-25 (`.dev.vars` folded into the secrets baseline)")
# — not auto-loaded; see "Where the history lives" in CLAUDE.md.

## 2026-11-20 (Foundry made Projects-friendly: four conditional rules)

Ran `foundry-projects-update-prompt.md` in a separate worktree on branch `projects-friendly` (the live `~/.claude/skills` symlinks point at the main checkout, so switching branches here would have changed every project's skills). Nothing committed or pushed.

**Hook 3 was done test-first and watched failing:** the three new silent-when-skill-absent cases went red against the old hook, and the offer-present case went red when the gate was pointed at a wrong path. Suite green afterwards. Mutation-case count unchanged. Rules 1-3 (question menu, sign-off, standing reminders) are prose only and are labeled untested.

**Finding:** the brief's "remind the owner of a to-do doc every session" rule is not in any template or this repo — it lives in individual projects, so item 3 became new template wording using the neutral name a HUMANS-TODO doc. Hook 3's unknown-environment branch is silent, deliberately the opposite of the other three (DECISIONS.md 2026-11-20). Already-scaffolded projects keep the old rules; USER_GUIDE lists the hand-edits.

## 2026-10-27 (Private pre-existing docs: ask before the first commit)

Side session off a `/foundry-init` run on `orlandotechhub`, where a folder that already held an outreach/grant plan naming real people and unsent email drafts had them staged into the first commit with no warning (repo kept private; committed there by choice). Added the one generalizable lesson: `foundry-repo-hygiene` Part 1 has a new step 6 — before the first commit, look at pre-existing non-code docs and, if any look private, ask whether to commit them with a private remote or keep them untracked via `.gitignore` (old 6/7 became 7/8; nothing referenced them by number). `foundry-init` Step 4 surfaces it beside the commit question. Explicitly judgment-based, with its negative branches written out; no scanner, no fixture. Everything else from that run (stack-specific `.gitignore` lines, project rules) was judged project-specific and left out. Decision: DECISIONS.md 2026-10-27. Fixture suite and audit run; nothing committed.
