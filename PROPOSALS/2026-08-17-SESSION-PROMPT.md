# Prompt — evaluating the two external proposals

Paste the block below into a Claude Code session started in `~/Projects/foundry`.

**Model:** Sonnet is adequate for evaluation and for proposals 1–3. If you decide to build
`foundry-audit` (proposal 4), that is a new skill plus a mutation-test harness — consider a
stronger model, and consider making it its own session.

---

```
You are working on Foundry itself, in this repository.

FIRST — orientation:

1. Read CLAUDE.md, DECISIONS.md and SESSIONS.md.
2. Read these two files:
   - PROPOSALS/2026-08-17-doc-audit-and-security-gate.md
   - PROPOSALS/2026-08-17-oneshot-improvements.md

Both were written by a Claude instance in a different session that used Foundry's
conventions to scaffold a real project (~/Projects/loomer) and then audited the result
repeatedly. Each proposal names the concrete defect that motivated it.

WHY THEY WERE NOT APPLIED DIRECTLY — read this before deciding anything:

The author had permission to make the changes and deliberately did not. The reasoning was:

- Foundry has its own DECISIONS.md, SESSIONS.md, template mechanism and fixture suite, and
  changes here propagate to every project scaffolded from now on. Editing nine skills in
  the tail of an unrelated session — with no decision entry, no session entry, and no
  `bash tests/run_fixtures.sh` run — would violate precisely the discipline Foundry exists
  to enforce. Doing it "quickly" would have been the exact failure mode Foundry guards
  against.
- Foundry's own decision log (2026-08-10) records that self-directed process criticism
  needs the same evidence standard as any other claim. That applies to these proposals.
  They are one instance's observations from one session. They are not a mandate.
- The author read Foundry once, in a single pass, from ~/Projects/foundry. Some claims
  about how Foundry currently works may be wrong. **Verify every claim about existing
  Foundry behaviour against the actual files before acting on it.**

HOW TO EVALUATE:

Assess each proposal on its merits. Do NOT implement all of them by default — say plainly
if one is not worth the complexity it adds. Specific things to weigh:

- Proposal 1 (binding rules belong in an auto-loaded file) is small and mostly restates
  Hook 1's existing rationale one level up. Low risk. The cost is deliberate duplication
  between a template and a standards doc — decide whether that trade is right for Foundry.

- Proposal 2 (mandatory security/privacy declaration) adds a required section to the
  closing-out convention. Weigh it against question/section inflation, which DECISIONS.md
  already flags as a live risk. The argument for it is that qc-review is a single
  adversarial pass at the end, and nothing currently requires the *author* to declare a
  posture at all.

- Proposal 3 (decisions need an enforcement locus) changes the decision entry format. That
  affects every existing entry's shape. Consider whether an optional field or a periodic
  orphan check is the lighter answer.

- Proposal 4 (a `foundry-audit` skill) is by far the largest and may warrant being its own
  session. Note that its value claim is specific: in the source project, three passes over
  a carefully-written, already-reviewed doc set found fifteen real defects, and almost none
  were found by reading — they were found by running checks.

- The oneshot proposal carries a self-referential risk worth naming: it adds five rules to
  a skill whose own failure mode is over-elaboration and question inflation. Some of its
  suggestions may be better as one compressed paragraph than five sections. Judge that.

THE MOST TRANSFERABLE IDEA:

Independent of whether any proposal is adopted, one principle from the source session is
worth considering for Foundry generally:

  Do not report a verification as clean without evidence the verification can fail.

In the source session two consistency scans reported clean. Mutation testing — injecting
23 known defects, one per class the scan claimed to catch — found three walked straight
past. Two were genuine blind spots; chasing the third surfaced a real defect in the
documents. The clean result had been partly luck, and re-running the same scan any number
of times would never have revealed that.

This bears directly on qc-review and on the fixture suite: a check that silently tests
nothing passes forever and reads as reassurance, which is worse than no check at all. A
working mutation-tested implementation exists at ~/Projects/loomer/tools/audit.py if it is
useful as a reference.

IF YOU IMPLEMENT ANYTHING:

Follow Foundry's own conventions. Per-skill wording rather than pasted boilerplate; an
entry in DECISIONS.md with Why and How to apply; a SESSIONS.md entry; and
`bash tests/run_fixtures.sh` re-run afterward. If a change has no mechanical surface, say
so explicitly rather than letting the fixture run imply it was tested.

Use `oneshot` to batch any clarifying questions for Tom before you start.

Close with an AskUserQuestion listing the concrete steps that remain — which proposals were
adopted, which deferred, and what is left to wire.
```
