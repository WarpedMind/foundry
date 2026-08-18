# Calibration log — `qc-review` against `subject_deploy.py`

Append a row per run. Keep old rows; a log that only records good runs is a
marketing document. Grading rules are in `EXPECTED.md`; the procedure and the
reasons this is not a CI gate are in `README.md`.

Record the skill revision as a **commit SHA**, not a prose label. `README.md`
asks a future reader to diff the skill against the revision in the last good
row, and a phrase naming an edit cannot be diffed. Where a run happened against
an uncommitted tree, say so explicitly and add the SHA once it lands.

| Date | Skill rev | Reviewer | D1 | D2 | D3 | D4 | D5 | FP | Notes |
|---|---|---|---|---|---|---|---|---|---|
| 2026-08-18 | `SKILL.md` at the 2026-08-18 conditional-offer edit | fresh `general-purpose` subagent, Opus 5 | ✅ | ✅ | ✅ | ✅ | ✅ | 0 | 5/5. See the run notes below. |
| 2026-08-18 | same revision, same prompt | second fresh `general-purpose` subagent, Opus 5 | ✅ | ✅ | ✅ | ✅ | ✅ | 0 | 5/5. Independent second sample; same D1/D2 severity inversion. |
| 2026-08-18 | post-round-11 fixture (token literal changed) — uncommitted | third fresh `general-purpose` subagent, Opus 5 | ✅ | ✅ | ✅ | ✅ | ✅ | 0 | 5/5. **Severity pattern did not hold** — see notes. |

## Run notes — 2026-08-18 (first recorded run)

**5 of 5 found, 0 false positives on the precision probe.** The fixture and this
log were written in the same session that ran the calibration, which is the
weakest position to measure from; the answer key was kept out of the subagent's
prompt and the subagent was instructed to read no other file in the directory,
but that is a procedural control, not a mechanical one. Read this first row
accordingly — the rows that will carry real weight are the later ones, run by
sessions that did not build the fixture.

Detail worth keeping:

- **D3 and D4 came back merged into one finding**, not two. The single finding
  states both the missing guard on the recursive delete and the `/` default that
  supplies its target, so both grading criteria are met and both are scored
  found. A future run that reports only the delete without connecting the
  default is a D4 miss, per the answer key's wording.
- **The two top severities are inverted** against the plant: D1 (hardcoded
  credentials) came back HIGH where it was planted CRITICAL, and D2 (password
  logged at INFO) came back CRITICAL where it was planted HIGH. Nothing a reader
  would act on differently, so under the answer key's rule this is recorded and
  not counted. Arguably the review is right and the plant is wrong — a secret
  reaching a log aggregator has a wider blast radius than one sitting in a file
  whose access is already controlled.
- **Four unplanted findings came back**, all substantive rather than padding:
  the destructive step running before the recoverable ones with no rollback and
  a success-shaped log line on a failed migration; captured subprocess output
  never read, so migration errors are invisible; `ignore_errors=True` turning a
  partial wipe into a reported success; and the API token flowing out of
  `_api_headers()` with no masking discipline in a module that demonstrably logs
  credentials elsewhere. Two of these were anticipated in `EXPECTED.md` as
  adjacent observations. None are false positives, and none were counted as
  hits.
- **On the precision probe:** the review did not claim shell injection through
  `subprocess.run`. It correctly read the fixed argument list, and instead
  argued that `psql -f` executes `\!` meta-commands, so an attacker-influenced
  `script_path` yields command execution through psql rather than through the
  shell. That is a sharper version of the adjacent observation the answer key
  anticipated, not the false positive it was probing for. Scored FP 0.

**What this row establishes, and what it does not.** It establishes that on one
occasion, with these instructions and this model, every planted class was found.
It does not establish that the skill is reliable, and one row cannot: the value
of this fixture is entirely in the comparison between rows, which is why the
answer key's per-defect columns matter more than the total.

## Run notes — 2026-08-18 (second run, same revision)

Run immediately after the first, same prompt, a separate subagent with no
knowledge of the first result. **5 of 5 found, 0 false positives** again.

What the second sample adds that the first could not:

- **The D1/D2 severity inversion reproduced exactly.** Both runs put
  credentials-in-source at HIGH and password-in-logs at CRITICAL, the reverse of
  the plant, without any contact between them. Two independent reviews agreeing
  against the answer key is evidence the key is wrong, not the reviews — a
  credential reaching a log aggregator escapes into a system with different
  retention and much broader read access, while one sitting in a source file is
  behind whatever already gates the repo. The planted severities are left as
  written so this data point stays visible; `EXPECTED.md` now records the
  disagreement rather than quietly resolving it.
- **D3 and D4 merged again**, in the same way, into a single finding covering
  both the unguarded delete and the `/` default that supplies its target. That
  is now a property of the fixture's shape rather than a one-run artifact: the
  two defects sit on adjacent lines in one function, so a reviewer that sees
  either sees both. Worth remembering when reading a future row — a run that
  reports them separately is not doing better, and a run that reports only one
  is a real D4 miss.
- **Two unplanted findings the first run did not produce**: that `clean_target()`
  can delete the very directory the relative `open()` in `write_release_index()`
  resolves against, and that `psql` is never given a password, so on a
  password-authenticating server it prompts and — with output captured, stdin
  unattended, and no timeout — blocks forever, after the wipe has already
  happened. Neither is planted; both are real properties of the fixture. The
  variation between runs is in the unplanted findings, not the planted ones,
  which is the pattern one would hope for.
- **On the probe:** again no claim of shell injection through `subprocess.run`.
  This run read the fixed argv correctly and raised the unvalidated `script_path`
  as arbitrary SQL execution instead — the adjacent observation the key
  anticipates. Scored FP 0.

**What two rows establish.** Consistency at n=2 on one revision, which is more
than n=1 and still not much. Both rows were produced by the session that built
the fixture; neither can speak to whether sensitivity survives a future edit to
the skill, because no such edit has happened yet. That is what the third row is
for.

## Fixture and key revised after rows 1 and 2 — what that does to them

A tenth adversarial review round, run against this session's own work, changed
the fixture directory after both rows above were recorded. What changed, and
whether the rows survive it:

- **`subject_deploy.py`: one string literal.** The fake token's shape
  (`wgt_live_sk_` plus a hex suffix) was what provider-agnostic secret scanners
  match, so anyone following this repo's own README advice to run `gitleaks` or
  `trufflehog` would get a standing false alert on a public repo. Replaced with
  a shape nothing pattern-matches. No planted defect changed; D1 is still two
  hardcoded credential literals in module scope. Whether rows 1 and 2 still
  describe the current fixture was, for one revision of this file, simply
  asserted — which is the exact move this whole artifact exists to attack, made
  inside it. Row 3 below was run specifically to replace that assertion with a
  measurement, and the new literals read `EXAMPLE-PLACEHOLDER-…`, which could
  plausibly move D1 detection or severity in either direction.
- **`EXPECTED.md`: three grading rules added, none altered.** A branch for
  unanticipated findings (there was none, and the first grader resolved two by
  assertion); a precise statement of what the precision probe is actually
  probing for; and an explicit note that Step 2's hook-misfire class is absent
  rather than covered. These make the *grading* reproducible. They do not
  change what either row scored, but both rows were graded before the rules
  existed, which is worth knowing when comparing a future row against them.
- **`README.md`: the procedure now stops before Step 5.** See below.

**The procedure both rows were run under was not the procedure as written.**
Step 1 said to follow the skill, and the skill's Step 5 appends findings to the
real CLAUDE.md's KNOWN DEBT. Neither run did that — correctly, but by judgment
rather than by instruction, and the log presented them as faithful runs. An
operator following the old text literally would have written five fabricated
defects into this project's live debt list. The instruction now says to stop
at Step 4 and why. Rows 1 and 2 were, in effect, run under the corrected
procedure before it was written down.

## Run notes — 2026-08-18 (third run, post-round-11 fixture)

Run after an adversarial round changed the fixture's token literal, specifically
to replace the assertion that rows 1 and 2 survived that change with a
measurement. **5 of 5 found, 0 false positives.** The planted defects are intact
and still detectable with the de-shaped placeholder literals; rows 1 and 2 are
comparable to this one on the found/missed columns.

**The more useful result is that this row breaks a conclusion drawn from row 2.**
Row 2's notes argued that because runs 1 and 2 both inverted D1 and D2 against
the plant, "two independent reviews agreeing against the answer key is evidence
the key is wrong." Row 3 did not invert them: it rated D2 (password in logs) HIGH,
matching the plant, and D1 HIGH against a planted CRITICAL. It also rated D5 HIGH
against a planted MEDIUM, which neither earlier run did.

So the pattern at n=2 was not a pattern. What n=3 shows is that **severity
assignment is the noisy dimension of this measurement and the found/missed
columns are the stable one** — which is precisely why the answer key excludes
severity from the count, and is a better argument for that rule than the one
originally written for it. The key's note recording the "reproduced" D1/D2
disagreement is now overstated by its own evidence and should be read as one
sample of a spread, not a finding.

The general lesson is worth more than the fixture: two agreeing samples felt like
confirmation and got written up as one. It took the third to show it was
variance. This artifact exists because a single clean result proves nothing —
and the first thing it did was tempt its own author into treating two into a
conclusion.
