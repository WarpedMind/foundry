# Handoff — four follow-ups from the `foundry-audit` build session

**Date written:** 2026-08-17. **Status:** ready for a fresh session.
**Prerequisite:** branch `foundry-audit` (commit `e1d8a0a`) is merged or checked out.

**Suggested model:** items 2 and 3 are mechanical and fine on Sonnet at medium
effort. Items 1 and 4 are judgment-heavy prose/design work against a repo with an
unusually specific quality bar (per-skill wording with no repeated sentences; every
claim backed by evidence that can fail), and are worth a stronger model. If running
all four in one session, use the stronger model throughout — the cost difference is
small next to redoing item 1.

---

## Read first

1. `CLAUDE.md`, `DECISIONS.md`, `SESSIONS.md` (auto-loaded).
2. `DECISIONS.md`'s upper 2026-08-17 entry — seven sub-entries on why
   `foundry-audit` is a script, why an empty input set is a finding rather than a
   pass, and what the adversarial pass on it found.
3. `skills/foundry-audit/SKILL.md` — specifically its "What was verified, and how"
   table, which is the shape items 1 and 4 should be held to.

**Verify before trusting this document.** It was written by the session that built
`foundry-audit`, which is structurally the worst reviewer of its own work — this
repo's own 2026-06-28 decision entry says exactly that. Check any load-bearing claim
here against the actual files. That instruction has already paid for itself twice:
the previous handoff contained a wrong decision date that propagated into two files
before a script caught it.

---

## The framing question this session must not get wrong

**`foundry-audit` does not replace or diminish `qc-review`.** A previous
conversation raised the question directly, so it is settled here in writing.

The two do not overlap at all:

| | `qc-review` | `foundry-audit` |
|---|---|---|
| Subject | code and its behavior | documents and their structure |
| Mechanism | fresh-context subagent, adversarial judgment | deterministic script |
| Can it find a security bug? | yes — that is its entire purpose | no, never |
| Can it be mutation-tested? | not automatically (see item 4) | yes, and is |

`foundry-audit` cannot find an auth bypass, a race condition, or an unsalted hash.
It cannot judge anything. Its determinism is exactly what makes it testable, and
exactly what makes it useless for the class of problem `qc-review` exists for.
Nothing here argues for retiring `qc-review`, and item 4 is about strengthening it.

What building `foundry-audit` *did* expose is a real, specific shortcoming in
`qc-review` — item 4 below. Treat it as a gap to close, not as evidence against the
skill.

---

## Item 1 — surface the right tool as an option in closing questions (do this first)

**Cheapest of the four and highest immediate value.** Every skill already ends its
turn with an `AskUserQuestion` (the 2026-08-11 convention). Nothing currently causes
`/qc-review` or `/foundry-audit` to appear as an option at the moment it would
actually help, so remembering them is left entirely to the user.

Add, per skill, an option that appears **conditionally** — when the work in that turn
touched auth/credentials/destructive operations, offer `/qc-review`; when it touched
the doc set, offer `/foundry-audit`.

**Constraints, all of which this repo already enforces and a reviewer will check:**
- Per-skill wording, not pasted boilerplate. The 2026-08-11 entry records that no
  sentence repeats across the existing `## Closing out` sections, verified
  mechanically (`sort | uniq -c`). Hold the new text to the same bar and re-verify.
- Conditional, never unconditional. An option that appears on every turn regardless
  of relevance is the filler-menu failure the convention explicitly guards against,
  and it would make the offer worthless within a week.
- This is instruction prose with no mechanical surface, so `tests/run_fixtures.sh`
  has nothing to exercise. Say so explicitly in the SESSIONS entry rather than
  implying a green suite validated it — that exact disclosure is standing practice
  here since Session 18.

## Item 2 — `/foundry-help`

An on-demand skill that explains what Foundry is, what each skill does, and when to
reach for which. **Deliberately not an automatic info box**, and the reasoning should
survive into the skill file:

- Hook 3 already occupies the session-start slot, and its three-state design
  (scaffolded / dismissed / neither) exists specifically to avoid nagging — see the
  2026-06-28 decision entry.
- Session 20 established that the VSCode extension never renders a SessionStart
  hook's `additionalContext` as visible text at all. An automatic banner would be
  invisible in precisely the interface where a new user most needs it.

An on-demand command has neither problem. Keep it a genuine reference, not marketing.

## Item 3 — a push-time `qc-review` offer hook

**This is genuinely different from the `PostToolUse` auto-run rejected on
2026-06-28, and the difference is the whole reason it's worth building.** That
rejection rested on two specific objections: `PostToolUse` fires after every edit
rather than at a real completion checkpoint, and it structurally cannot block
because the edit has already happened. A `PreToolUse` hook matching `git push`
defeats both — a push is a real completion boundary, and `PreToolUse` can block.

Scope it carefully:
- **Push, not commit.** Commits are frequent and often mid-thought; a push is the
  publish boundary. Firing on every commit recreates the noise problem in a new place.
- **Offer, never auto-run.** `qc-review` spawns a subagent; running one on every push
  is real latency and cost. The hook should surface a suggestion, not execute.
- **Once per session at most**, and ideally only when the session touched paths that
  match `qc-review`'s own risk criteria (its Step 2 list).
- Validate it the way every Foundry hook is validated — pipe-test with synthetic
  stdin, confirm it does not fire on unrelated Bash commands — and add inline cases
  to `tests/run_fixtures.sh` alongside the Hook 3/4 suites.

Check the negative branch explicitly, per the standing Rule: what happens on a push
in a session that touched nothing risky, and what happens when the classification is
wrong in each direction.

## Item 4 — a committed calibration fixture for `qc-review`

**The shortcoming.** `qc-review`'s "no findings" result is unfalsifiable in exactly
the way `foundry-audit` was built to fix. A clean review is indistinguishable from a
review that did not look hard, and re-running it can never tell you which — the same
argument the CLAUDE.md verify-before-trust rule now makes in general form. Sessions 7
and 8 did plant known defects and confirm they were caught, which is the right idea,
but it happened once, ad hoc, and was never committed. Nothing re-establishes that
the skill's sensitivity has survived subsequent edits to its own instructions.

**What to build:** a committed fixture — a small file with N deliberately planted,
documented defects of the classes `qc-review` claims to catch (credential exposure,
missing confirmation before an irreversible action, a silent overwrite) — plus a
recorded procedure for pointing `qc-review` at it and comparing against the expected
findings.

**The honest limitation, which must be stated in the skill rather than glossed:**
unlike `foundry-audit`'s mutation tests, this *cannot* be a CI gate. `qc-review` runs
an LLM subagent — non-deterministic, costs real time and money, and cannot run in
GitHub Actions. So this is a **manual periodic calibration**, not an automated test,
and `tests/run_fixtures.sh` should not pretend to cover it. A partial-credit result
(finds 2 of 3) is meaningful data about sensitivity, not a pass/fail. Design for that
rather than forcing a binary.

Do not let item 4 turn into a rewrite of `qc-review`. The skill's design was
validated end-to-end in Sessions 7-8 and nothing here contradicts it; the gap is
purely that its sensitivity is asserted rather than periodically demonstrated.

---

## Finishing

Follow the repo's own conventions: a `DECISIONS.md` entry per real design choice
(Why / How to apply / Enforced at), a `SESSIONS.md` entry, `README.md`'s Roadmap
updated in the same change, `bash tests/run_fixtures.sh` re-run, and
`bash skills/foundry-audit/audit.sh` re-run before finishing — the doc set currently
audits clean, so any new finding is something this session introduced.

State explicitly, for each item, which category its verification falls into:
mutation-tested, manually verified, or prose with no mechanical surface. Do not let
an untestable item borrow credibility from a tested one — that distinction is the
single most load-bearing idea in the work this handoff follows.

Close with an `AskUserQuestion` covering what was built, what was verified, and what
was deferred.
