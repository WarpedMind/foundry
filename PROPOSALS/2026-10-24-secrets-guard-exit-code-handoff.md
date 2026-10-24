# Handoff — Hook 2's secrets-guard does not block, and the suite that "covers" it never ran it

**Date written:** 2026-10-24. **Status: DONE, all six items, 2026-10-24** (same day). See
SESSIONS.md and DECISIONS.md's entries for that date. Kept for the record; nothing here is
outstanding.

**Corrections to this document, found while executing it.** (1) The Prerequisite note below was
already stale when written — the archive pass it describes as uncommitted had been committed as
`bbaf6b2`; only `skills/oneshot/SKILL.md` was dirty, and it was left untouched. (2) Item 3's
premise was too pessimistic: scanning `~/Projects` found seven projects carrying the hook and
only **one** still broken (`karbotrage/karbotrage_v1`, repaired in this pass). Three had been
hand-fixed to `exit 2` and three to a JSON `deny` — six sessions improvising six repairs without
ever correcting the skill, which reframed the root cause from "wrong exit code" to "a retyped
snippet with no single point of correction", and is why Hook 2 now has a template. (3) Item 4's
sweep of the other hooks found a real second defect, not just reassurance: Hook 5 was emitting
`permissionDecision: "allow"` on an advisory, which skips the permission prompt. Fixed here.
(4) One question in item 4 could not be settled from the docs and is now tracked in CLAUDE.md's
KNOWN DEBT rather than closed: whether `systemMessage` is actually surfaced on `PreToolUse`.

**Original status line:** OPEN. Nothing in this document has been executed.

**Prerequisite:** none, but note the working tree already carries the 2026-10-24 archive pass
(DECISIONS.md/DECISIONS_ARCHIVE.md/CLAUDE.md/SESSIONS.md/README.md/`.foundry-audit-allow`)
uncommitted, plus a pre-existing uncommitted edit to `skills/oneshot/SKILL.md` that predates
all of it. Stage specific files; never `git add -A`. Commit only when the user asks.

**Suggested model: a strong one, high effort.** Item 1 is a security fix whose whole failure
mode was a plausible-looking mechanism nobody executed, and item 2 has to prove the new test
can fail. Item 4 is design work against this repo's mutation-case rule. Items 5-6 are small.

---

## Item 1 — Make the secrets-guard actually block (the only live defect)

**The defect.** `skills/foundry-hooks/SKILL.md`'s Hook 2 (two copies of the snippet, the
historical one and the current full pattern) ends with:

```bash
if [ -n "$FORBIDDEN" ]; then echo "BLOCKED: forbidden files staged: $FORBIDDEN"; exit 1; fi
```

Verified against Claude Code's published hook contract (`https://code.claude.com/docs/en/hooks`),
not assumed: for `PreToolUse`, **exit 2** blocks the tool call and stderr carries the reason;
**exit 1 with no valid JSON on stdout is a non-blocking error — the action goes ahead**; and
plain-text stdout is not shown in the transcript for `PreToolUse`. The docs say this in as many
words: "If your hook is meant to enforce a policy, use `exit 2`." So the guard neither blocks
the commit nor delivers its message. It has been inert in every project scaffolded with
`HANDLES_SECRETS`, while `skills/foundry-hooks/SKILL.md` line 40 calls it "an actually-enforced
`PreToolUse` hook" — re-read that line and fix the claim too, not just the code.

Found by another session that ran `/foundry-init` on a real project (`~/Projects/spatialwebsite`),
noticed the exit code, deviated from the skill, and said so in its summary. That project's
`.claude/settings.json` therefore already carries a hand-written JSON-deny version — look at it
before writing a new one, but do not assume it is right; verify it the way item 2 requires.

**Pick one mechanism and say why in DECISIONS.md.** Both work; the repo needs the reasoning on
record, not just the fix.
- `exit 2` with the message on **stderr** (`>&2`). Simplest inside a settings.json command
  string — no nested JSON quoting — and the docs make stderr the block reason.
- `exit 0` plus a JSON object on stdout with `hookSpecificOutput.hookEventName: "PreToolUse"`,
  `permissionDecision: "deny"`, `permissionDecisionReason: "<which files>"`. More explicit and
  surfaces a structured reason, at the cost of generating valid JSON inside a JSON file —
  build it with `jq -n` rather than by hand, the way `templates/settings.hooks.json.template`
  already does. The docs warn against mixing the two approaches in one hook: choose.

Note Hook 2 has **no template file** (unlike Hooks 1/3/5) — it is assembled from the prose in
`skills/foundry-hooks/SKILL.md`. Consider whether it should get one
(`templates/settings.secretsguard.json.template`) as part of this fix, since a snippet that is
retyped per project is exactly how an unexecuted command survives this long. That is a judgment
call for this session; if you add one, update CLAUDE.md's Architecture list in the same change
(repo rule) and keep the escaping validated by `jq -e '.'`.

## Item 2 — The fixture case must assert blocking, not classification

`tests/run_fixtures.sh` has been green throughout. It tests whether the **regex** classifies
filenames correctly (lines ~73-89 against `tests/fixtures/secrets-guard-cases.txt`) and has
never executed the hook, so the exit code was never in its field of view. That is this repo's
own documented trap: a tested surface standing in for the untested behaviour beside it.

Add inline cases, in the shape the Hook 3/4/5 cases already use in that script:
1. A forbidden staged file produces a **blocking** outcome — assert the exit code (2) or the
   parsed JSON decision (`deny`), whichever item 1 chose, and assert the reason names the file.
2. A legitimate staged file (`.env.example`, `package.json`) produces no block and no noise.
3. **Mutation case, required:** put `exit 1` back (or strip the JSON) and confirm case 1 fails.
   A green suite proves nothing about a check nobody has watched fail — and this defect is the
   proof of that rule, so do not skip it because the fix looks obvious.

Then update the counts: `README.md` and any `Enforced at:` line that states a mutation-case
number, and re-run `bash skills/foundry-audit/audit.sh --numeric "mutation cases"`, which has
caught stale counts twice.

## Item 3 — Say what already-scaffolded projects need

Every project scaffolded with `HANDLES_SECRETS` has the broken command written into its own
`.claude/settings.json`; fixing this repo does not fix them. Add a short remediation note where
a user would actually find it (`USER_GUIDE.md`'s hooks/limitations section, and
`skills/foundry-hooks/SKILL.md` so a standalone invocation offers to re-wire an existing
project's Hook 2). Ask the user which of their projects have it rather than guessing — at least
`~/Projects/spatialwebsite` (already hand-fixed) and whichever others used the secrets path.

## Item 4 — Root cause: the validation step tells you to check output, not behaviour

`skills/foundry-hooks/SKILL.md` step 3 says to pipe-test with synthetic stdin and run the
fixture suite. A pipe test shows the message; nothing in that step asks whether the tool call
was actually stopped. Rewrite the step so hook validation asserts the **effect** — exit code or
decision — for every hook that claims to block, and state explicitly that a hook which only
prints has not been validated. Then apply the same question to the hooks that do not block, and
check each against the same docs page rather than by reading the JSON: Hook 1/3's
`additionalContext`, Hook 4's logging, Hook 5's `systemMessage` advisory. Confirm each field is
real for its event and actually surfaces; if one does not, that is the same class of defect.
(Session 20 already found that the VSCode extension does not render a SessionStart hook's
`additionalContext` as visible text — so "the field exists" and "the user sees it" have already
diverged once in this repo.)

## Item 5 — Carried over from the 2026-10-24 archive pass

Give `foundry-audit`'s decision-reference check an **archive-aware tier**: a citation that
resolves to a `## <date>` heading in `DECISIONS_ARCHIVE.md` should not be reported as dangling
and should not need allowlisting. Two dates (`2026-08-11`, `2026-08-17`) are allowlisted in
`.foundry-audit-allow` purely because of this gap, each with its deletion condition written out
— delete those entries as part of the fix. Note the second half of the gap while you are in
there: the check greps for lines mentioning "DECISIONS.md" over a filename-prefixed
concatenation, so every line of `DECISIONS.md` matches and every ISO date anywhere in that file
counts as a reference. Mutation case required in the same change (repo rule for `audit.sh`), and
if any part of this needs semantic judgment it belongs in `SKILL.md` labelled as judgment, not
in the script.

## Item 6 — SESSIONS.md's own archive pass is due

Its header says entries older than the newest two are archived; it now holds four. Move the
oldest two into `SESSIONS_ARCHIVE.md` **verbatim** (reconstruct the original by concatenation
and `cmp` it against a pre-move copy, as the 2026-10-24 DECISIONS.md pass did), keep
CLAUDE.md's "Where the history lives" pointer and the file's own header in sync, and re-run the
audit for dangling references afterwards.

---

**Done looks like:** the guard blocks a real forbidden commit and the suite would catch it if it
stopped blocking; `bash tests/run_fixtures.sh` and `bash skills/foundry-audit/audit.sh` both
clean; DECISIONS.md carries an entry naming the mechanism chosen and why; SESSIONS.md and
CLAUDE.md's status/KNOWN DEBT updated in the same work, not as a later pass; and every claim
that the hook is "enforced" matches what it now does.
