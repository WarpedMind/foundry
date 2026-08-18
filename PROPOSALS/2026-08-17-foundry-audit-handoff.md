# Handoff — build `foundry-audit` (proposal 4)

**Date written:** 2026-08-17. **Status:** ready to hand to a fresh session. This is the one
proposal from the 2026-08-17 review round that was deliberately *not* folded into that
session — it's the largest of the four by a wide margin (a new skill plus a mutation-test
harness, not a template edit) and deserves to be built without time pressure from an
unrelated session's tail end.

**Suggested model:** a stronger model than Sonnet is worth considering here — this is new
skill design plus a mutation-testing harness, not template prose editing.

---

## Paste this into a fresh Claude Code session started in `~/Projects/foundry`

```
You are building a new Foundry skill: `foundry-audit`.

FIRST — orientation, in this order:

1. Read CLAUDE.md, DECISIONS.md, and SESSIONS.md in full.
2. Read PROPOSALS/2026-08-17-doc-audit-and-security-gate.md — section 4 ("Ship a mechanical
   doc audit — foundry-audit") is the proposal you're building. Read the whole file anyway;
   sections 1-3 give context for decisions already made (see step 3 below).
3. Read DECISIONS.md's 2026-08-17 entries in full — a prior session already evaluated and
   applied three related proposals (1: absolute rules belong in the auto-loaded CLAUDE.md;
   2: a conditional security/privacy declaration rule; 3: an optional `Enforced at:` field
   on decision entries) and deliberately deferred this one, proposal 4, to you. Don't
   re-litigate 1-3 — they're done. Do notice where your work on proposal 4 interacts with
   them: proposal 3 stopped at an optional field rather than building a mechanism to check
   it; an audit skill is a natural place for that mechanism to live if it makes sense once
   you're actually building this.
4. Read CLAUDE.md's own "Rules / Never do" section, specifically the standing rule about
   checking the negative branch of every conditional safeguard, and the rule (added
   2026-08-17) about not reporting a verification as clean without evidence it can fail.
   Both apply directly to what you're building — an audit skill IS a verification mechanism,
   so it needs to survive being pointed at itself.

VERIFY BEFORE TRUSTING THE PROPOSAL:

The proposal document was written by a different instance after one pass over Foundry. Some
of its claims about how Foundry currently works, or about what would be easy to build, may
be wrong or stale by the time you read this. Check anything load-bearing against the actual
files before designing around it — this is a standing Foundry discipline
(DECISIONS.md/CLAUDE.md), not a one-off instruction for this task.

THE CORE IDEA:

Foundry's doc set (CLAUDE.md, DECISIONS.md, SESSIONS.md, and any project-specific docs a
project has) accumulates drift that looks fine on a read-through and is only caught by
running checks — dangling references, a decision-log index that's drifted from its bodies,
absolute rules present in one doc but not the auto-loaded one, orphaned decisions nothing
references, stale file paths after a rename, numeric claims that disagree across files. In
the source project (~/Projects/loomer), three read-through-style reviews of an
already-carefully-written doc set missed real defects that a fourth, mechanical pass caught
immediately. The value claim is specific and worth re-verifying, not just quoting: three
passes found fifteen real defects, almost none by reading.

THE HARDEST PART, AND WHY IT'S THE POINT:

The proposal's most important idea generalizes past this one skill: a check that would pass
even if the defect it claims to catch were present gives false confidence, and running it
repeatedly will never reveal that on its own. So `foundry-audit` cannot ship on the strength
of "I wrote checks for these classes of defect and they didn't fire" — that's exactly the
failure mode the proposal describes happening to a previous, unverified pass at this same
problem (two scans reported clean; mutation-testing them — injecting one known defect per
class each scan claimed to catch — found three that walked straight past undetected).

Before treating any individual check as done, mutation-test it: construct or inject a real
instance of the specific defect class it claims to catch, run the check, and confirm it's
actually caught. Do this for every check class in the table in the proposal (dangling
decision references, decision-index/body drift, broken file-path references, stale renamed
files, missing-from-auto-loaded-file absolute rules, orphaned decisions, unenforced
standards bullets, malformed code fences/tables/TODOs, unreachable docs, disagreeing numeric
claims across files, non-self-contained pasteable prompts). If a check can't be reliably
mutation-tested (some of these are closer to LLM judgment calls than mechanical regex), say
so explicitly in the skill's own SKILL.md rather than letting it borrow the credibility of
the checks that can be.

A working reference implementation exists at `~/Projects/loomer/tools/audit.py` — read it
for the actual mechanics (which checks are regex/structural vs. which need judgment), but
verify it actually does what its own code claims before trusting it as a template; it was
written ad hoc during one project's audit, not built to Foundry's own bar.

DESIGN QUESTIONS TO RESOLVE (use `oneshot` to batch these for Tom before building):

- Is this a new standalone skill (`foundry-audit`, alongside `qc-review`/`promptify` as a
  referenced-not-owned tool) or a mode of `qc-review`? The proposal's suggested framing
  ("qc-review covers code adversarially; nothing covers the documents structurally") argues
  for standalone, but check whether that's actually right once you understand both skills'
  actual scope, not just the one-line pitch.
- Trigger mode: on-demand only, or also a periodic nudge from Hook 3 (the status hook), as
  the proposal suggests? Consider the same trade already decided for qc-review's own
  mechanical-hook question (DECISIONS.md, 2026-06-30) — a hook that fires too often is noise,
  one that never fires might as well not exist.
- What's genuinely project-specific vs. genuinely Foundry-wide in this check set? The
  proposal names the decision-ID regex and a known-future-files allowlist as the only
  project-specific parts — verify that's actually true once you're implementing, not just
  assumed from the proposal's own framing.
- Findings handling: same pattern as `qc-review` (verify CRITICAL/HIGH findings by
  reproduction before writing them into KNOWN DEBT, label with source and date), or does a
  structural doc-consistency finding need a different verification bar than a security
  finding? Decide and state the reasoning.

FOLLOW FOUNDRY'S OWN CONVENTIONS WHILE BUILDING:

- A DECISIONS.md entry (Why / How to apply / Enforced at — use the new optional field from
  the 2026-08-17 entries, since this is exactly the kind of decision that has one) for each
  real design choice, not just a summary at the end.
- A SESSIONS.md entry.
- If you add or change anything with a mechanical surface (a regex, a rendered command),
  add cases to the right place and run `bash tests/run_fixtures.sh` — read CONTRIBUTING.md
  first for how that suite is organized (some things fit `tests/fixtures/*.txt`, some are
  inline cases in the script itself, some are prose with no mechanical surface at all; say
  explicitly which category `foundry-audit`'s own checks fall into, don't leave it
  ambiguous).
- Update CLAUDE.md's Architecture section (new skill) and README.md's Roadmap (mark this
  item done, with what was actually built and verified) in the same change — not as
  follow-up cleanup.
- Update `skills/foundry-init/SKILL.md`'s Step 3 (where it currently mentions `qc-review`
  and `promptify` as referenced-not-owned tools) if `foundry-audit` should be mentioned
  there too — check what that step currently says before assuming it needs the same
  treatment.

WHEN YOU'RE DONE — REEVALUATE, DON'T JUST STOP:

Building `foundry-audit` means spending real time inside Foundry's actual doc/decision/
session structure with an adversarial, mechanical mindset — a different vantage point than
either normal feature work or a read-through review. Before closing out, deliberately ask
whether anything you noticed while building this (a real inconsistency you found in
Foundry's own docs while testing the tool against them, a check that revealed something
about Foundry's own structure worth fixing, a design tension the proposal didn't anticipate)
should become its own tracked item — fixed now if cheap, or added to README.md's Roadmap
with reasoning if not, following the same "every finding gets fixed or explicitly deferred,
never silently dropped" discipline this repo has followed since Session 4. This mirrors
what the 2026-08-17 session did for proposals 1-3: it didn't just apply them, it asked what
they implied beyond their literal text (e.g. deciding proposal 3's field should say
explicitly that omitting it is noticeable, not safe-by-default, which the proposal itself
didn't spell out).

Also run `foundry-audit` against Foundry's own doc set once it exists (CLAUDE.md,
DECISIONS.md, SESSIONS.md, README.md) as its first real test — not a scratch fixture. If it
finds something real, that's both a genuine test of the tool and a genuine fix to make.

Use `oneshot` to batch clarifying questions for Tom before starting substantial design work,
and close with an `AskUserQuestion` listing what was built, what was verified (including the
mutation-test results per check class), and what — if anything — got deferred.
```
