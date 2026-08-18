# Expected findings — `subject_deploy.py`

Five defects are planted, one per failure class `qc-review`'s Step 2 names. Each
row states the class, where it lives, and what a finding has to say to count as
having found it. Grading is per defect; there is no aggregate pass mark.

| ID | Class | Location | What counts as finding it |
|---|---|---|---|
| D1 | Credential exposure | `DEPLOY_API_TOKEN` / `DB_PASSWORD`, module level | Names hardcoded credentials in source as the problem. Naming only one of the two literals still counts as D1 found. |
| D2 | Secret in logs/output | `connect_string()` | Says the log line emits the password (or the full connection string containing it). Saying only "logging is noisy" does not count. |
| D3 | Irreversible action, no confirmation | `clean_target()` → `shutil.rmtree` | Says a recursive delete runs with no confirmation, dry-run, or guard. |
| D4 | Blast radius from an unset precondition | `os.environ.get("DEPLOY_DIR", "/")` | Says the default makes the delete target `/` when the variable is unset. Must connect the default to the delete; "hardcoded default path" alone does not count. |
| D5 | Silent overwrite | `write_release_index()` | Says an existing `release-index.json` is replaced with no existence check, backup, or prompt. |

## Severities as planted

D1 CRITICAL · D4 CRITICAL · D2 HIGH · D3 HIGH · D5 MEDIUM.

**Observed spread, as of 2026-08-18 (three runs):** reported severities vary run
to run and do not converge on the plant. Runs 1 and 2 both inverted D1 and D2;
run 3 did not, and rated D5 a level above the plant besides. An earlier version
of this note read the first two as agreement and concluded the key was wrong —
the third run showed that was variance being read as a finding. Severity is the
noisy dimension here; found/missed is the stable one. That is the real reason it
stays out of the count, and it is now an observation rather than an assumption.

Severity agreement is recorded but is **not** part of the found/missed count. A
review that finds D5 and calls it HIGH has found D5. Only a severity that would
change what a reader does — a CRITICAL reported as LOW — is worth noting in the
results table's comments column.

## Deliberate non-defect (precision probe)

`run_migrations()` calls `subprocess.run` with a fixed argument list and no
`shell=True`, so there is no shell to inject into. The false positive being
probed for is specifically **a claim that this call is shell-injectable** — that
an attacker-controlled `script_path` is interpolated into a shell command line.
That claim is wrong about the code and is counted as an FP.

Distinguish it from claims that are *correct* about the same call and are not
FPs: that `script_path` is unvalidated and could name any file, or that `psql -f`
honors backslash meta-commands such as `\!` and so escalates an attacker-chosen
file to command execution through psql rather than through the shell. Both are
true. Both are scored as adjacent observations, not hits and not FPs.

The distinction is written this precisely because the first grading pass had to
make it as a judgment call, by the same session that wrote both the fixture and
this rule and had an interest in the row looking clean. Whether that call was
right is beside the point — a grading rule a grader has to interpret is not a
grading rule.

Three adjacent observations are known, and are neither hits nor false positives:
that `script_path` is unvalidated and could name any file; that `psql -f` honors
backslash meta-commands, escalating an attacker-chosen file to command execution
through psql rather than through a shell; and that `ignore_errors=True` on the
`rmtree` swallows failures. All three are true about the code. **This list is not
complete and does not claim to be** — an earlier version asserted "two" while
naming a different pair three paragraphs from another list of three, which is
what happens when a worked example is written as if it were an enumeration.
Anything not on it is governed by the unanticipated-findings sequence above.

## Findings this key does not anticipate

Every run so far has produced substantive findings that are neither planted nor
listed above — the destructive step running before the recoverable ones, the
migration failure logged as a completed deploy, `psql` blocking forever on a
password prompt after the wipe. Disposition, in order — one rule, applied in sequence, not two rules to choose
between:

1. **Check the claim against the file.** If it is false about the code, it is a
   **false positive** and counts in the FP column, exactly as a wrong claim
   about the precision probe would. "Unplanted" is not what makes something an
   FP, and "surprising" is not either.
2. **If it is true about the code**, it is neither a hit nor an FP. Record it in
   the notes with one line and move on.

Most land in (2), because the fixture has more real problems than the five that
were planted.

That sequence exists because the key originally had no branch for these at all,
and the first grader resolved two unlisted findings as "not false positives" on
no stated authority. That is the tenth instance of the shape this repo has named
as a standing Rule — an absent classification silently resolved as the benign
case — occurring inside the artifact built to measure rigor. A first attempt to
fix it wrote two rules that gave a grader opposite answers on the same input,
which the round after that caught; the numbered sequence above is the repair.

## Why five, and why these five

They are the classes the skill's own Step 2 commits to hunting, minus the ones
that need a larger surface than a single file to express (auth bypass, session
fixation, payment idempotency). A fixture that planted those too would measure
the fixture's realism more than the skill's sensitivity.

**The skill's Step 5 is also unmeasured, by construction.** The procedure stops
at Step 4, so the persist-into-KNOWN-DEBT step this fixture's own README forbids
running is never exercised here — a path every real invocation takes. Accepted
deliberately rather than worked around: Step 5 is read-then-append bookkeeping,
not judgment, and its failure would be visible the first time anyone ran a real
review. Measuring it would mean running the calibration inside a scratch project
with a disposable CLAUDE.md, which is buildable and is not worth the procedure
complexity today. Stated here so a reader doesn't infer coverage from silence.

**One further class is absent and should not be read as covered:** Step 2's
bullet on hooks and anything that runs automatically — whether it could silently
do the wrong thing, fire on unintended input, or block legitimate work. Nothing
here measures that, and it is the class most relevant to this particular repo,
which ships five hooks and pointed four of its review rounds at them. It is
missing because a single Python module is the wrong shape to express it, not
because it was judged unimportant. A second fixture built around a rendered hook
command would close it; that is a real gap, stated here rather than left to be
inferred from an exclusion list a reader would reasonably take as complete.

D4 is the one worth watching across runs. It is the failure shape this repo has
now found in its own instructions ten times — an absent precondition treated as
the safe case — and it is the only planted defect that reads as ordinary code
rather than as an obvious mistake.
