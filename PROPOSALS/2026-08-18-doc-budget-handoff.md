# Handoff — cut the SessionStart doc-loading burden

**Date written:** 2026-08-18. **Status:** ready for a fresh session.
**Prerequisite:** none. Working tree was clean and pushed when this was written.

**Suggested model: Sonnet, medium effort — for items 1-3, which is most of the work.**
Those are lossless text moves governed by an explicit cutover rule, plus one small bounded
rewrite; they are deliberately specified below so that no synthesis-under-judgment is
required. **Item 4 is different** — it is design work against this repo's unusually
specific bar (per-skill wording with no repeated sentences, every check mutation-tested).
Either use a stronger model for item 4, or make it its own session. Do not let item 4's
difficulty push items 1-3 to a bigger model than they need; they are genuinely mechanical.

---

## Read first

1. `CLAUDE.md`, `DECISIONS.md`, `SESSIONS.md` (auto-loaded by the SessionStart hook —
   which is itself the thing this session is fixing, so notice how much of your context
   they consumed before you read a single instruction).
2. `CLAUDE.md`'s KNOWN DEBT entry beginning "The SessionStart doc-loader now injects
   ~76,000 tokens" — the measurement this session exists to act on.
3. `docs/HOWS_AND_WHYS.md`, the section "Why three separate files (CLAUDE.md,
   DECISIONS.md, SESSIONS.md) instead of one." This is the design principle the current
   state violates, and it is the criterion for what moves and what stays.

**Verify before trusting this document.** It was written by the session that took the
measurement, not one that did the restructure, so its claims about what is safe to move
are reasoning, not experience. This repo's standing instruction is to check load-bearing
claims against the actual files — that instruction has already caught a wrong decision
date and a wrong diagnosis of a stale line count in previous handoffs. Re-run the
measurements below yourself before acting on them; if a number disagrees, trust the file.

---

## The problem, with the numbers

The SessionStart doc-loader in `.claude/settings.json` reads a fixed three-filename array
and injects all three files whole:

```
DOC_FILES_ARR=("CLAUDE.md" "DECISIONS.md" "SESSIONS.md")
```

Combined, as measured 2026-08-18: **303,867 bytes ≈ 76,000 tokens**, injected into every
session before the user types anything. On a 200k context window that is ~38% of the floor,
and it grows every session, because this repo's own discipline requires updating these
files every session.

Measured breakdown — re-derive these rather than quoting them:

| File | Total | Archivable | What is archivable |
|---|---|---|---|
| CLAUDE.md | 61,737 | 46,349 (75%) | the `Current status` section |
| DECISIONS.md | 82,394 | 34,707 (42%) | the 2026-06 entries |
| SESSIONS.md | 159,736 | 131,399 (82%) | everything older than the newest 3 sessions |

Target end state: roughly 93KB (~23k tokens), a ~70% cut, with nothing deleted.

**Archiving works with no hook change.** The loader reads that fixed array, so a file not
named in it is simply never loaded. Confirm this yourself with
`jq -r '.hooks.SessionStart[0].hooks[0].command' .claude/settings.json` before relying on it.

---

## Item 1 — CLAUDE.md's `Current status` (do this first)

**Why first:** biggest single win, lowest risk, and it is the only one of the three that
fixes a correctness problem rather than just a size problem. `Current status` is 46KB of
per-session narrative log covering Sessions 4-20. `docs/HOWS_AND_WHYS.md` says CLAUDE.md
"should always be readable as a snapshot, not a history," and that section is a history.
The content is **already duplicated in SESSIONS.md**, which is the file whose actual job
it is — so this is largely removing a second copy, not discarding a record.

Do it in two mechanical steps, not as one synthesis:

1. **Move losslessly.** Append the entire existing `Current status` body verbatim to a new
   `docs/PROJECT_HISTORY.md` (or into `SESSIONS_ARCHIVE.md` from item 2 if you do that
   first and it fits cleanly — decide once and be consistent). Verbatim means verbatim; do
   not summarize during the move, so the move itself can never lose anything.
2. **Write a fresh, short `Current status`** — target 15-25 lines. It answers only "what is
   true right now": what exists, what works, what is in flight. Not what happened, in what
   order, in which session. End it with a pointer to the archive and to SESSIONS.md.

Framing it as move-then-write rather than "condense 20 sessions" is deliberate: the lossy
step is bounded to a small fresh write with the full record still on disk beside it.

**Before/after check:** `wc -c CLAUDE.md` before and after, and confirm the archive file
contains the old text (`grep` for a distinctive phrase from an early session).

---

## Item 2 — SESSIONS.md archive split

The plan already exists and has been deferred three times (Sessions 15, 16, and again
since); it is not new design work. `SESSIONS_ARCHIVE.md`, newest-first like its parent.

**Cutover rule — mechanical, decide once, state it in both files:** keep the newest three
session entries inline in SESSIONS.md; everything older moves to `SESSIONS_ARCHIVE.md`
verbatim. Put a one-line pointer at the point of truncation in SESSIONS.md, and a header
in the archive saying what it is and which file supersedes it.

Three is a starting value, not a law — if the newest three are unusually long (the
2026-08-18 entries are very long), keep two and say so. What matters is that the rule is
written down, so the next session extends it rather than re-litigating it.

---

## Item 3 — DECISIONS.md archive split

Same shape, smaller payoff: the 2026-06 entries are 42% of the file. `DECISIONS_ARCHIVE.md`.

**One caution specific to this file.** Decision entries are cross-referenced by date from
CLAUDE.md, SESSIONS.md and several SKILL.md files, and `foundry-audit` has a real check
for exactly this (`decision references — N checked, all resolve`). Run
`bash skills/foundry-audit/audit.sh` after the move. If it reports a dangling reference,
that is the check doing its job — fix the reference, do not suppress the check.

Consider doing item 3 last, or skipping it this session if time is short: it is the
smallest win and carries the highest cross-reference risk.

---

## Item 4 — generalize it (the part that actually matters long-term)

Items 1-3 fix this repo once. **Every project Foundry scaffolds inherits the same
three-file set and the same auto-loader, and will hit the same wall** — and unlike this
repo, most will not have someone measuring it. A one-time cleanup here is a fix; the
durable version is a mechanism.

Two pieces, and please evaluate whether each earns its complexity rather than building both
on this document's say-so:

**(a) A size/budget check in `foundry-audit`.** Natural fit: `audit.sh` already scans
exactly these files, already has a mutation-test harness in `tests/run_fixtures.sh`, and
this check is genuinely mechanical — a byte count against a threshold, which is the kind of
thing that *can* be shown capable of failing, unlike the prose rules this repo has spent
several rounds discovering it cannot verify. Design questions to settle: what threshold
(and defended on what basis — an arbitrary number presented confidently is exactly what
this repo's anti-fabrication discipline forbids); WARN versus FAIL; whether it reports the
per-file breakdown or just a total. **Mutation-test it like every other check** — inject a
file over the threshold, confirm it fires.

**(b) A discipline entry in `foundry-repo-hygiene` Part 2.** Same shape as the existing
`foundry.readmeChangelogDiscipline` — a one-time question, recorded in `.claude/settings.json`,
asked when it first becomes relevant rather than at init time when there is nothing to
measure. **Read that existing entry first, including its `"not-applicable-yet"` skip state
and why that state exists** (a prior session shipped this exact mechanism with the skip path
leaving the field unset, which was indistinguishable from "never checked" — see the
post-Session-19 follow-up entries). Write the negative branch explicitly; it is a standing
Rule in this repo and this is precisely the shape that keeps violating it.

---

## Conventions to follow (this repo holds itself to these)

- **A `DECISIONS.md` entry** with Why / How to apply / Enforced at, for the real design
  choices: the cutover rule, the threshold in item 4(a), and anything you decide *not* to
  do. Note that no decision entry was written when this handoff was created — the
  measurement was a finding, not a decision; the decisions get made by the session that
  does the work, which is this one.
- **A `SESSIONS.md` entry** (in the newly-trimmed file).
- **Update `README.md`'s Roadmap** — the doc-restructure item has been listed as deferred
  since Session 15; mark what actually shipped.
- **Run both suites after every doc change:** `bash tests/run_fixtures.sh` and
  `bash skills/foundry-audit/audit.sh`. For items 1-3 specifically, `audit.sh`'s
  reachability and decision-reference checks are the real safety net — they are what
  proves the archives are still linked and no cross-reference broke.
- **State the verification category explicitly per item**, as every recent session here
  does: items 1-3 are text moves verified by byte counts, `grep` for moved content, and
  `audit.sh` — *not* mutation-tested, because moving text has no defect class to inject.
  Item 4(a) is mutation-testable and must be. Item 4(b) is prose with no mechanical
  surface. Say so; do not let a green fixture run imply coverage it does not have.

## When you are done — reevaluate

Re-measure the loaded total and state it plainly against the 76k baseline. If the cut came
in far below target, say what you left on the table and why. And ask whether the work
surfaced anything else worth tracking — the standing discipline here is that every finding
gets fixed or visibly deferred, never silently dropped.

Use `oneshot` to batch clarifying questions before starting, and close with an
`AskUserQuestion` covering what shipped, the measured before/after, and what was deferred.
