# Handoff — triage the 16 absolute-rule INFO candidates, and close out the 2026-08-18 session

**Date written:** 2026-08-18. **Status:** ready for a fresh session.
**Suggested model:** Sonnet, medium effort. This is triage against one clear
criterion, not design work. See "Why this is Sonnet-suitable" below before
deciding otherwise.

**Prerequisite:** the 2026-08-18 changes (handoff items 1 and 4 — conditional
cross-skill offers, and `tests/calibration/qc-review/`) are in the working tree.
They may or may not be committed by the time you read this; check `git status`
rather than assuming either way.

---

## Read first

1. `CLAUDE.md`, `DECISIONS.md`, `SESSIONS.md` (auto-loaded by the SessionStart hook).
2. `CLAUDE.md`'s KNOWN DEBT entry labeled `[foundry-audit, 2026-08-18]` — that is
   the item this handoff exists to close.
3. `skills/foundry-audit/SKILL.md`, Step 3 and Known Limitations. The check you
   are triaging is one the skill already labels judgment-assisted and explicitly
   warns will produce descriptive-prose false positives. Read that before
   treating any candidate as a defect.

**Verify before trusting this document.** It was written by the session that
recorded the debt, which is not a neutral position. This repo's standing
practice is to check load-bearing claims against the actual files — the spot-check
summarized below is exactly the kind of claim to re-derive rather than inherit.
It has paid for itself repeatedly here.

---

## The task

`bash skills/foundry-audit/audit.sh` reports, and has reported for several
sessions:

```
[INFO] absolute-rule coverage — 16 candidate line(s) to compare by hand
```

Those 16 lines contain `never` or `non-negotiable` and live in `README.md`,
`USER_GUIDE.md`, and `docs/context-efficiency-playbook.md` — none of which the
SessionStart hook loads. The check surfaces them so that anything genuinely
absolute can be restated in `CLAUDE.md`'s Rules section, where a future session
will actually see it. The check does not decide, by design.

Nobody has ever gone through them. The INFO line has been read past every run,
which is the state this whole repo argues against: an unexamined signal that
appears every time teaches a skim.

**Deliverable: a recorded per-line disposition**, so the question is closed
rather than re-surfaced. Not necessarily 16 edits — quite possibly zero.

## The criterion

For each candidate line, exactly one of:

- **(A) A standing rule directed at a future assistant session.** Restate it in
  `CLAUDE.md`'s Rules section. This is the only disposition that produces an edit.
- **(B) Descriptive prose about what something does.** "Foundry never silently
  overwrites an existing CLAUDE.md" describes behavior; it does not instruct
  anyone. No action. This is the false-positive class the skill's own limitations
  predict.
- **(C) A rule whose audience is the human user, not the assistant.** Real, and
  correctly placed where the user reads it. Restating it in CLAUDE.md would not
  enforce anything, because the assistant is not the actor. No action.
- **(D) Another project's finding.** `docs/context-efficiency-playbook.md` records
  lessons from separate work. Its `never`s are observations about that project,
  not standards this repo commits to. No action.

## Why this is Sonnet-suitable

Each line resolves by asking who the sentence instructs. That is shallow and
fast per line; there are only 16. The work is bulk and mechanical, not a design
call — which is precisely why it was moved out of the session that found it
rather than folded in.

The one place to slow down: a line that reads as description but encodes a
promise the project actually has to keep. `README.md`'s "It never silently
overwrites an existing CLAUDE.md" is descriptive **and** a guarantee `foundry-docs`
implements. It is still (B) — the enforcement lives in the skill's Step 0
per-file overwrite question, not in a restated rule — but notice the distinction
before applying it, and say so in the write-up rather than resolving it silently.

## A spot-check, offered as a starting hypothesis and not as an answer

Sampling the candidates suggested most are (B) or (D):

- `README.md` — largely statements about Foundry's behavior. Several matches are
  inside Roadmap entries, including one whose text is literally "VSCode panel
  never shows the Foundry: Active status line."
- `USER_GUIDE.md` — mostly explanatory. The strongest candidate is "Always point
  every platform at the exact project folder, never a parent folder that merely
  contains it," which is real and load-bearing but is (C): its audience is the
  person choosing a folder in VSCode.
- `docs/context-efficiency-playbook.md` — (D) throughout, on this reading.

**Do not take this as the result.** It came from grepping a wider pattern than
`audit.sh` uses and reading a subset, so it may not even be looking at the same
16 lines. Derive the real list first; the method is below.

## Method

1. Get the actual list the script is reporting, rather than an approximation.
   The check lives in `skills/foundry-audit/audit.sh` under the absolute-rule
   coverage section — read the pattern it uses and reproduce it exactly. A hand
   grep that finds ~50 lines where the script reports 16 is triaging the wrong
   set.
2. Classify each line A/B/C/D with a one-line reason.
3. Apply (A) edits, if any, to `CLAUDE.md`'s Rules section.
4. Record the disposition somewhere durable so the INFO line stops being an open
   question — a short `docs/` note, or a DECISIONS.md entry if any (A) turns up.
   Then remove the KNOWN DEBT item, since it will be resolved.
5. If a candidate is a genuine false positive that will recur, consider whether
   `audit.sh`'s pattern should be narrowed. **If you change the script at all,
   the standing Rule applies without exception: a mutation case goes into
   `tests/run_fixtures.sh` in the same change.** Do not narrow the pattern just
   to make the INFO count drop — that is tuning the tool by the documents it
   audits, which the skill explicitly forbids.

## Finishing

Repo conventions, all of them:

- A `DECISIONS.md` entry per real design choice (Why / How to apply / Enforced at)
  — only if there is one. A triage that finds 16 instances of (B) is a recorded
  result, not a decision, and does not need a manufactured entry.
- A `SESSIONS.md` entry either way.
- `README.md`'s Roadmap updated in the same change if anything there is affected.
- `bash tests/run_fixtures.sh` and `bash skills/foundry-audit/audit.sh` both re-run
  before finishing. The doc set audits clean as of 2026-08-18 (exit 0), so any new
  FAIL is something this session introduced.
- State explicitly which category the work falls into: mutation-tested, manually
  verified, or prose with no mechanical surface. This one is prose. Do not let a
  green fixture suite imply it was validated — that distinction is the most
  load-bearing idea in this repo.
- Close with an `AskUserQuestion`.

## Note on `tests/calibration/qc-review/`

Unrelated to the triage, but if you edit `skills/qc-review/SKILL.md` for any
reason during this session, the standing Rule requires re-running the calibration
and appending the result to `tests/calibration/qc-review/RESULTS.md`. It is
manual, costs a subagent dispatch, and must never be added to
`tests/run_fixtures.sh`. Two rows exist as of 2026-08-18, both 5/5, both produced
by the session that built the fixture — a row from a session that did not build it
is worth more than either.
