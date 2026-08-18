# Proposal — four Foundry improvements, from live use on the LOOMER project

**Date:** 2026-08-17
**Source:** scaffolding a real project (`~/Projects/loomer`) with Foundry's conventions,
then auditing the result three times from different angles. **Fifteen real defects** were
found in documents that had been written carefully and reviewed once. Four of them
generalize past that project and belong in Foundry itself.

**Status: proposal, not applied.** Foundry has its own `DECISIONS.md`, `SESSIONS.md`,
template mechanism and fixture suite, and changes here affect every future project
scaffolded. Editing nine skills in the tail of an unrelated session would violate exactly
the discipline Foundry exists to enforce. Run this through a proper Foundry session
instead — a ready prompt is at the bottom.

---

## 1. Binding rules must live in an auto-loaded file — state this in the template

**What happened.** The LOOMER project had three "cardinal rules" (never lose a recording;
never silently degrade quality; never send user content anywhere without explicit action).
They were written into `docs/05-STANDARDS.md`. **Only one of the three had also been
written into `CLAUDE.md`.** Since Hook 1 auto-loads `CLAUDE.md`, `DECISIONS.md` and
`SESSIONS.md` and nothing else, two absolute prohibitions would have been present in every
session only as a *reference to a file the session had to remember to open*.

**Why it generalizes.** This is precisely the argument Foundry already makes for Hook 1 —
"a written instruction to 'always read these docs' has actually been observed to get
silently skipped" — applied one level up. Hook 1 solves it for the three root files. It
does not solve it for a rule that lives in a fourth file those three merely point at.

**Suggested change.** Add a standing Rule to `templates/CLAUDE.md.template`:

> **Anything that must never be violated belongs in this file.** Other documents may
> elaborate, but a rule that exists only in a non-auto-loaded file is a rule the session
> has to remember to go and read — which is the failure mode the SessionStart hook exists
> to prevent. If a standard is absolute, restate it here even at the cost of duplication.

The duplication is the point, not a defect. Two copies of an absolute rule cost a few
lines; one copy in the wrong place costs the rule.

---

## 2. A mandatory security & privacy declaration on every work unit

**What happened.** A mission brief instructed a session to determine whether it could
"reliably capture click, drag, scroll and **key events**." The standards document said
elsewhere to suppress secure input fields and never record keystroke content. The brief —
the authoritative instruction — said nothing. **A session following it faithfully could
have built a keylogger in good faith**, and spike code has a way of surviving.

`qc-review` would plausibly have caught it. But `qc-review` is a single adversarial pass
at the end by one reviewer, and it is the last line of defence rather than the first.

**Why it generalizes.** Foundry has no mechanism requiring the *work itself* to declare
its security and privacy posture. There is a reviewer, but nothing the author must answer.

**Suggested change.** Two parts:

- Add a **mandatory SECURITY & PRIVACY section** to whatever ends a unit of work in a
  Foundry project (the closing-out convention is the natural home). *"No
  security-relevant code in this unit"* is a valid answer; **omitting the section is
  not.** Forcing an explicit "none" is what catches the case where the author had not
  considered the question at all.
- Where a project's work touches input capture, screen capture, accessibility APIs,
  credentials or personal data, require a per-unit **definition of done** — an explicit
  checklist answered item by item. "We followed the standards" is not an answer.

---

## 3. Decisions need an enforcement locus, not just a rationale

**What happened.** An audit for *orphaned decisions* — locked, correct, and referenced
nowhere a person building the relevant code would look — found four. One of them said no
product name may be hardcoded, because the name was not final. The very next unit of work
was the one that sets the bundle identifier, app name and window title. It did not mention
the decision. Bundle identifiers propagate into code signing, TCC permission grants and
notarization; changing one later means every user re-granting permission.

**Why it generalizes.** Foundry's decision format captures *what*, *why* and *how to
apply*. It does not capture **where and when the decision gets checked**. A decision with
no enforcement locus is a decision that will be discovered violated rather than obeyed.

**Suggested change.** Either add an optional `Enforced at:` line to the decision entry
format (naming the work unit, file or checkpoint where it becomes real), or add an
**orphan check** to the audit in §4: every decision should be referenced by at least one
brief, checklist or roadmap item, or explicitly marked as not-yet-actionable.

---

## 4. Ship a mechanical doc audit — `foundry-audit`

**What happened.** Three audit passes over a carefully-written, already-reviewed document
set found fifteen real defects: dangling references, decision-log entries out of order, an
index disagreeing with its own bodies, stale filenames surviving a rename, absolute rules
absent from the auto-loaded file, orphaned decisions, standards nothing would enforce, and
two concepts that would predictably be conflated in code.

**Almost all of it is mechanically checkable.** None of it was found by reading carefully;
it was found by running checks.

**Why it generalizes.** Every Foundry project accumulates the same classes of drift, and
they are invisible precisely because the documents look correct. `qc-review` covers *code*
adversarially; nothing covers *the documents* structurally.

**Suggested change.** A `foundry-audit` skill (or a mode of `qc-review`) that verifies:

| Check | Catches |
|---|---|
| Every `ADR-NNN` / decision reference resolves | dangling cross-references |
| Decision index matches decision bodies, and ordering matches the stated convention | silent drift after edits |
| Every referenced file path exists, or is on a known-future allowlist | stale links after renames |
| No references to renamed or deleted files remain | the rename that missed a spot |
| Every absolute rule ("never…", "must…") appears in an auto-loaded file | §1's failure mode |
| Every decision is referenced by ≥1 brief/checklist/roadmap item | §3's orphans |
| Every standards bullet is echoed somewhere actionable | standards nothing enforces |
| Code fences balanced, tables column-consistent, no TODO/FIXME, trailing newlines | truncation and copy-paste damage |
| Every doc reachable from the entry point | files nobody will ever open |
| Numeric claims agree across files ("seven questions", counts, versions) | edits that updated one place |
| Pasteable prompts are self-contained | prompts that assume conversation context |

A working implementation of all of these exists at `~/Projects/loomer` (written as an
ad-hoc script during the audit) and is straightforward to generalize — the project-specific
parts are only the decision-ID regex and the known-future-files allowlist.

**Run it from Hook 3** (the status hook) as a cheap periodic nudge, not on every session.

---

## Ready prompt for a Foundry session

Run this in `~/Projects/foundry`, following Foundry's own conventions:

```
Read CLAUDE.md, DECISIONS.md and SESSIONS.md, then read
PROPOSALS/2026-08-17-doc-audit-and-security-gate.md.

It contains four proposed Foundry improvements derived from live use scaffolding a real
project and auditing the result three times. Each names the concrete defect that
motivated it.

Use `oneshot` to batch any clarifying questions for Tom before starting.

Evaluate each proposal on its merits — Foundry's own decision log records that
self-directed process criticism needs the same evidence standard as any other claim, and
that applies to this document too. Some of these may not be worth the complexity they
add. Say so rather than implementing all four by default.

For any you do implement: follow Foundry's own conventions. Per-skill wording rather than
pasted boilerplate, an entry in DECISIONS.md with Why and How to apply, a SESSIONS.md
entry, and `bash tests/run_fixtures.sh` re-run afterward. Proposal 4 is the largest —
a new skill — and may warrant being its own session.

Close with an AskUserQuestion offering the concrete next steps that remain.
```
