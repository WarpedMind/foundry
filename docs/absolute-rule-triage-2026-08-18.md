# Absolute-rule candidate triage — 2026-08-18

Closes the `foundry-audit` KNOWN DEBT item recorded 2026-08-18: `bash
skills/foundry-audit/audit.sh`'s check 9 (absolute-rule coverage, judgment-assisted)
surfaces bullet lines containing `never` / `must never` / `under no circumstances`
/ `non-negotiable` that live in a doc the SessionStart hook does not auto-load.
The check never decides anything by design — it reports `INFO` and stops. This
note is the first time anyone has gone through the candidates it flagged and
recorded a disposition per line, per
`PROPOSALS/2026-08-18-absolute-rule-triage.md`.

## Count discrepancy, noted rather than silently corrected

The handoff document said 16 candidates. Re-running the exact regex the script
uses (`^[[:space:]]*[-*][[:space:]].*(\bnever\b|\bmust never\b|\bunder no
circumstances\b|\bnon-negotiable\b)`, excluding CLAUDE.md/DECISIONS.md/SESSIONS.md)
at triage time found **17**: 11 in `README.md`, 3 in `USER_GUIDE.md`, 3 in
`docs/context-efficiency-playbook.md`. The extra line is a Roadmap entry added
to `README.md` after the handoff was written (same 2026-08-18 session, later
edit) — not a bug in the check or in the handoff, just a doc that kept moving.
The number below is the one the check reports right now.

## Criterion (from the handoff)

- **(A)** Standing rule directed at a future assistant session → restate in
  `CLAUDE.md`'s Rules section.
- **(B)** Descriptive prose about what something does → no action.
- **(C)** Rule whose audience is the human user, not the assistant → no action,
  correctly placed where the user reads it.
- **(D)** Another project's finding, recorded in the playbook → no action.

## Disposition, all 17

### README.md (11) — all (B)

Every candidate here is either a feature description or a Roadmap changelog
entry recording what was built/investigated. None instructs a future assistant
session to do anything; each records what Foundry (the software) does or did.

| Line | Text (start) | Class | Note |
|---|---|---|---|
| 19 | "...never as noise" | B | describes status-hook's 3-state behavior |
| 22 | "It never fabricates plausible-sounding compliance language" | B | describes `foundry-governance`'s anti-fabrication behavior, which is already a scoped rule inside `skills/foundry-governance/SKILL.md` for when that skill runs — not a general rule every session needs |
| 68 | "It never silently overwrites an existing CLAUDE.md..." | B | the one case the handoff flagged as worth slowing down for. Real guarantee, but the enforcement lives in `skills/foundry-docs/SKILL.md`'s Step 0 ("never silently overwrite an existing file (mandatory, check before anything else)") — confirmed present at `skills/foundry-docs/SKILL.md:12` — not in a restated CLAUDE.md rule. Restating it in CLAUDE.md's Rules would duplicate, not add, enforcement. |
| 70 | "...never dependent on Foundry continuing to run" | B | architecture description |
| 85 | Roadmap: Hook 5, "never blocks, never auto-runs" | B | changelog entry describing shipped behavior |
| 87 | Roadmap: qc-review calibration, "never will be [a CI gate]" | B | changelog entry |
| 91 | Roadmap: qc-review skill, "never automatic" | B | changelog entry |
| 102 | Roadmap: "VSCode panel never shows..." | B | changelog entry title, describes a documented platform gap |
| 104 | Roadmap: readme-discipline fix, "would never get re-asked" | B | changelog entry describing a prior bug, now fixed |
| 114 | Roadmap: numeric-check item, "has never once run unasked" | B | changelog entry stating a current fact about the tool |
| 121 | Roadmap: CwdChanged investigation | B | changelog entry recording an investigation's findings |

### USER_GUIDE.md (3)

| Line | Text (start) | Class | Note |
|---|---|---|---|
| 239 | "Foundry will never fabricate a specific regulatory framework...and you shouldn't either" | C | the actionable clause ("you shouldn't either") addresses the human reader of the guide; the Foundry-behavior half restates `foundry-governance`'s own already-scoped anti-fabrication rule, not a new general one |
| 241 | "Always open new sessions inside the exact scaffolded project folder, not a folder above it" | C | real and load-bearing (matches the spot-check's own read), but the actor is the person choosing a folder in their terminal/IDE — Claude Code cannot control which directory a session opens in, so restating this in CLAUDE.md's Rules would not enforce anything |
| 242 | "Foundry never commits automatically; it always asks first" | **already satisfied** | this is (A)-shaped, but the rule already exists in CLAUDE.md's Rules section verbatim in substance: "Commit only when explicitly asked; never use destructive git operations... without explicit confirmation." No new edit — recorded here so it isn't re-flagged as an open (A) later. |

### docs/context-efficiency-playbook.md (3) — all (D)

| Line | Text (start) | Class | Note |
|---|---|---|---|
| 86 | "A sequencing recommendation that never checked its own premise" | D | retrospective finding from a different project |
| 573 | "Work continued across every decision. The assistant never had to..." | D | retrospective finding |
| 798 | "Distinguish...from 'this was never...'" | D | retrospective finding |

## Result

**Zero new edits to `CLAUDE.md`.** All 17 candidates are (B), (C), or (D); the
one (A)-shaped line (USER_GUIDE.md:242) turned out to already be covered by an
existing Rule. This confirms rather than contradicts the handoff's own spot-check
hypothesis, though the spot-check was explicitly offered as unverified and had
to be re-derived line-by-line against the actual regex output, not inherited —
per this repo's own verify-before-trust standard.

## On narrowing `audit.sh`'s pattern

Not narrowed. The false-positive rate here (17/17 confirmed non-actionable) is
exactly the class the check's own Known Limitations text already predicts, and
the handoff is explicit that tuning the pattern to make the INFO count drop
would be "tuning the tool by the documents it audits," which the skill forbids.
The check will keep reporting INFO on this doc set going forward — that is
correct behavior, not a defect: it surfaced 17 real candidates, a human/assistant
looked at all 17, and 0 needed action. The signal did its job. If a future
`never`/`non-negotiable` line gets added to README/USER_GUIDE/the playbook, it
will re-surface and should get the same one-line disposition treatment, not be
assumed to be one of the categories above without checking.

## Verification class

**Prose, no mechanical surface.** This is a triage against a criterion applied
by reading, not a script. `tests/run_fixtures.sh` and `skills/foundry-audit/audit.sh`
were both re-run after this note was written and neither changed (audit.sh
itself was not modified — no new mutation case needed). A green fixture suite
does not and cannot validate this disposition; only re-reading the 17 lines
against the criterion would.
