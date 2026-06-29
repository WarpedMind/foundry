---
name: foundry-stack
description: Set up and maintain a STACK.md — a career-documentation record of what technologies were actually used in this project, when, and what each demonstrates for an interview or resume. Use when a project wants to track its tech stack for job-hunting/portfolio purposes, distinct from CLAUDE.md/DECISIONS.md/SESSIONS.md which serve the assistant's working context, not a human audience reading this later.
---

# foundry-stack

STACK.md answers a different question than every other Foundry doc. CLAUDE.md/DECISIONS.md/SESSIONS.md exist so an assistant (and the user, secondarily) can stay oriented on a project *while it's active*. STACK.md exists so the user, much later — in an interview, writing a resume bullet, prepping for a recruiter call — can answer "what did you actually build with, and what did it demonstrate" without having to reconstruct it from memory or git log. Different audience, different lifecycle (this outlives the project being actively worked on).

**Locating Foundry's templates**: this skill reads `templates/STACK.md.template` from this Foundry checkout. Check `~/Projects/foundry/templates/` first — if not found there (e.g. a different install location on this machine), ask the user where Foundry is checked out before proceeding.

**`EXPLAIN_MODE`** (set by `foundry-init`, or ask if standalone): in `detailed` mode, state the above distinction before setting this up, so it's clear why this isn't redundant with DECISIONS.md. In `brief` mode, just set it up.

## Is this project a fit for STACK.md?

Not every project needs this — ask, don't assume. Good fit: portfolio projects, anything you might discuss in a job search or want to remember the details of years later. Poor fit: genuinely disposable scripts (these should have used the minimal fast-path in `foundry-init` and skipped this entirely), work-for-hire where you don't own the narrative, anything you wouldn't want to talk about publicly.

**Before asking the fit question, check whether the project's own CLAUDE.md already answers it.** If a `## REGULATORY CONTEXT` or `## COMPLIANCE / AUDIT TRAIL` section exists (written by `foundry-governance`), read it and scan for confidentiality/non-disclosure language (e.g. "no public disclosure," "proprietary," "do not discuss externally," specific NDA references). If found, surface this explicitly before asking the generic fit question: "This project's CLAUDE.md has a compliance/regulatory section that mentions [the specific constraint] — does that affect whether (or how) you want to track this publicly in STACK.md?" Don't silently skip STACK.md because of this (the user may still want a private, non-shared version, or the constraint may not actually apply to a stack-tracking doc), and don't silently proceed either — surface the connection and let the user decide with that context in view, since the generic fit question alone could be answered "sure, track it" without the user consciously connecting it to a constraint already written elsewhere in their own docs.

## Setting up STACK.md (new project)

0. **Check first whether `STACK.md` already exists.** If it does, this is the same risk class as `foundry-docs` overwriting an existing CLAUDE.md: do not regenerate it from the template. Read the existing file in full, tell the user what's already there, and ask whether to leave it alone, append a new entry (the normal "updating" flow below), or fully redo it — defaulting to "leave alone" if unclear. Only proceed to step 1 below for a project that genuinely has no STACK.md yet, or where the user explicitly asked for a full redo.
1. Read `templates/STACK.md.template`.
2. Substitute `{{PROJECT_NAME}}`. Leave `{{FIRST_MILESTONE_NAME}}`/`{{FIRST_MILESTONE_DATE}}` as a real first entry if the project already has a v1/initial version worth recording, or leave the snapshot section with just the template's empty structure if this is truly day one.
3. Do not pre-fill the "Current stack" table speculatively — it should only ever contain things actually verified running, even at setup time. If nothing has been verified yet, leave it empty with just the header row.
4. Write to `STACK.md` in the project root.
5. Add an entry to CLAUDE.md's `{{ADDITIONAL_RULES}}` (coordinate with `foundry-docs`): "Update STACK.md whenever a technology is added, replaced, retired, or reaches a milestone worth recording — and only mark something 'in use' once actually verified running, not when first written." This is the mechanism that keeps this doc from going stale the same way the other three docs would without their own discipline.

## Verification discipline (the part that makes this trustworthy later)

The whole value of STACK.md depends on it being accurate — a resume claim that turns out to be wrong in an interview is worse than not having the claim at all. Apply the same standard already established elsewhere in Foundry's docs (verify-before-trust): before marking a technology "in use" with a since-version, confirm it's actually running — tests pass, it was exercised live, not just that code referencing it was written. If something is added but not yet confirmed, either omit it or mark it explicitly "pending verification" rather than listing it as settled fact.

## Updating an existing STACK.md (ongoing use, not just initial setup)

When invoked mid-project (e.g. at the end of a session that added/changed/retired something):
1. Read the existing STACK.md in full first — never blind-append.
2. Add/update the relevant "Current stack" row, with the "Since" marker and a notes field that explains *why this choice over the alternatives*, not just what it is — see the "why-linkage" rule below; this is the single most important quality bar for this doc.
3. If this change represents a version/milestone boundary worth its own snapshot (a meaningful jump, not every small dependency bump), add a new entry under "Version/milestone snapshots" with a "what this demonstrates" line written for an interview audience specifically — not a changelog entry, an answer to "why should I care."
4. If a technology was replaced or retired, move its row to note the retirement explicitly (don't just delete it — "tried X, replaced with Y because Z" is often more interview-worthy than either X or Y alone).

## The why-linkage rule (mandatory, not optional polish)

STACK.md is a quick-reference table — it should stay scannable, not turn into a second DECISIONS.md. But a row that only says *what* was used, with no hint of *why this over the alternatives* or *what problem it avoided*, loses most of its interview value: "I used PostgreSQL" answers nothing; "chose PostgreSQL over the SQLite we started with, once concurrent writes from multiple users started causing lock contention" is the actual interview-worthy fact.

So every non-trivial row (skip this for genuinely default/uninteresting choices — not every dependency needs a backstory) should do one of:
- **Name the alternative and the reason in the notes field itself**, if it fits in one clause (a real project's STACK.md does this for a database migration: "Replaced Excel/openpyxl from v1" — names the predecessor; add the *why* alongside it, e.g. "...because Excel couldn't handle concurrent writes," when there's a real reason to state).
- **Cross-reference the DECISIONS.md entry by date/title** when the reasoning is more than one clause, rather than duplicating it: `Notes: Chose FastAPI over Flask — see DECISIONS.md 2026-06-21`. This keeps STACK.md scannable while making the deeper reasoning one click away, not lost.

Never leave a non-trivial technology choice with a notes field that just restates its name or category — that's the failure mode this rule exists to prevent.

## Worked example of the target quality bar

A weak notes entry: `| Database | PostgreSQL | v2 | Used for data storage |` — says nothing a reader couldn't guess from the technology name, and gives no hint of *why this over alternatives*.

A strong notes entry, why stated inline (real example, slightly extended): `| Database | SQLite (via SQLAlchemy ORM) | v2 | Replaced Excel/openpyxl from v1 — a flat file couldn't support the validation layer or concurrent dashboard reads the v2 feature set needed; WAL mode enabled` — names the predecessor, names the specific reason it was outgrown, and the configuration detail.

A strong notes entry, why cross-referenced (when the reasoning is too long for the table): `| Web framework | FastAPI | v2 | Replaced raw http.server from v1 — see DECISIONS.md 2026-06-21 for the full async-vs-sync tradeoff discussion` — keeps the row scannable, doesn't lose the reasoning.

## What this skill does NOT do

It does not build or maintain a cross-project master rollup (a single STACK.md aggregating multiple repos). That's explicitly out of scope — Foundry operates per-project, and an aggregation tool spanning repos is a different, separate concern (potentially its own future tool, not this skill's job).
