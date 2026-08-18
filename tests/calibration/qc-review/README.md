# `qc-review` calibration fixture

## What this is for

`qc-review`'s clean result is unfalsifiable. A review that found nothing and a
review that did not look hard produce the same output, and running it again
cannot tell them apart — the same problem `foundry-audit` was built as a script
to escape. Sessions 7 and 8 did plant defects and confirm the skill caught them,
which was the right instinct, but it happened once and nothing was committed, so
no later edit to the skill's own instructions has ever been checked against it.

This fixture is the standing version of that check. Point the skill at a file
whose defects are known and written down, then compare what came back.

## What this is emphatically not

**It cannot be a CI gate, and `tests/run_fixtures.sh` does not run it.** The
skill dispatches an LLM subagent: non-deterministic, billed, minutes not
milliseconds, and unavailable inside GitHub Actions. Two runs of an unchanged
skill against an unchanged fixture can legitimately differ. Anything built on
top of this that reports pass/fail would be asserting a determinism the
mechanism does not have.

So this is a **manual periodic calibration**. It measures sensitivity on one
occasion. It does not certify it.

## Procedure

1. From the repo root, run the skill against the fixture with an explicit scope
   so it does not fall back to the session diff:

   ```
   /qc-review tests/calibration/qc-review/subject_deploy.py
   ```

   Follow the skill through Step 4 — in particular Step 3's requirement that
   the review run in a fresh subagent with no prior context. A review performed
   inline by a session that has read `EXPECTED.md` measures nothing.

   **Stop before Step 5, always.** Step 5 appends surviving findings to the
   project's CLAUDE.md KNOWN DEBT, and run from the repo root that is the real
   CLAUDE.md. Five fabricated defects in a file nothing imports would land in a
   live debt list as though they were this project's actual debt, labeled
   indistinguishably from real ones. The findings from a calibration run belong
   in `RESULTS.md` and nowhere else. This is the one place the calibration
   deliberately departs from the skill it measures, which is why it is written
   here rather than left to the operator to notice.

2. **Do not read `EXPECTED.md` into the reviewing context.** It is the answer
   key. Keep it out of the subagent's prompt and out of any file list handed to
   it. If the session driving the calibration has already read it, that session
   can still dispatch the subagent, but must not summarise, hint at, or scope
   toward its contents.

3. Grade against `EXPECTED.md`: one line per planted defect, found or missed,
   plus a count of false positives against the precision probe recorded there.

4. Append a row to `RESULTS.md`. Record the run whatever it says. A calibration
   whose bad results go unlogged is worse than none, because it manufactures a
   record of reliability out of selective reporting.

## Reading a result

Design for partial credit; there is no threshold that turns this into a verdict.

- **4 or 5 of 5** — consistent with the sensitivity Sessions 7-8 observed.
- **A miss** — data, not a failure. Note *which* defect and compare against
  earlier rows: the same defect missed twice running is a signal about the
  skill's instructions; a different one each time is closer to sampling noise.
- **A false positive on the precision probe** — worth as much attention as a
  miss. A review that flags safe code teaches its reader to discount it, and a
  discounted review finds nothing regardless of how sensitive it is.
- **A drop after the skill's instructions were edited** — the one result this
  fixture exists to make visible at all. Diff the skill against the revision
  used in the last good row before concluding anything about the model.

## When to run it

Not on a schedule. Three occasions, all of them changes to what is being
measured rather than to the calendar:

- After editing `skills/qc-review/SKILL.md`, particularly Steps 2 or 3.
- When the model behind the subagent changes.
- Before relying on a clean `qc-review` for something that actually matters — a
  public release, a handoff, a security-sensitive merge.

## Files

- `subject_deploy.py` — the fixture. Five planted defects, one deliberate
  non-defect. Never imported, never executed, not on any import path.
- `EXPECTED.md` — the answer key, and the grading rules.
- `RESULTS.md` — the log. Append-only in practice; keep old rows.

## Known biases in this measurement

Stated so a good row is not over-read:

- **The fixture is short and its defects are dense.** Five in sixty-five lines
  is nothing like the ratio in real work, where the same defect hides in a file
  that is mostly fine. Sensitivity here is an upper bound on sensitivity there.
- **Context primes, in two ways, and the second was undisclosed for a while.**
  The subject sits under `tests/calibration/` and says it is a fixture; a
  reviewer that infers defects are expected looks harder than one reviewing a
  file it believes is production code. The path is visible in the scope line and
  cannot be hidden without lying about what the file is. Separately — and this
  is the sharper hint — the docstring's line about the credential literals being
  fabricated points straight at D1's location. It stays because the alternative
  is a public repo containing an unlabelled credential-shaped string, but it
  means D1 is the least honestly measured of the five, and a D1 hit should be
  weighted accordingly.
- **The answer key is one directory away.** Step 2 of the procedure forbids
  reading it, and the instruction is given to the subagent explicitly, but this
  is enforced by wording rather than by a sandbox. A run whose grading looks
  suspiciously perfect is worth re-checking against the subagent's tool calls.
- **One row is one sample.** The mechanism is non-deterministic by construction,
  so a single result — good or bad — is weak evidence in either direction.
