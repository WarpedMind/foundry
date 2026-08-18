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

**Run items 1-3 as one Sonnet session and item 4 as a separate one.** They share no state
beyond the files being smaller, and splitting them is what keeps the cheap work cheap.

Every boundary command below was executed against the real files on 2026-08-18 and its
output recorded inline, so you are re-running verified commands rather than trusting
plausible ones. **Never read these files wholesale to move them** — extract by line range.
That is what keeps this task inexpensive regardless of model: ~300KB moves through `sed`,
not through context.

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

## Archive architecture — decided, do not redesign

Settled in `DECISIONS.md` (2026-08-18, top entry). Summary so you don't have to re-derive it:

- **No separate archive-index file.** A short pointer block inside CLAUDE.md *is* the index,
  because CLAUDE.md is the only thing guaranteed to load. An index that isn't auto-loaded
  needs its own pointer, which then has to describe the contents to be useful — at which
  point it is the pointer, one hop later, plus another file to keep in sync.
- **Nothing is ever summarised during a move.** Moves are verbatim. The only lossy step in
  this whole handoff is the small fresh `Current status` rewrite in item 1, and the full
  original sits in the archive beside it.
- **Archives are never auto-loaded and are read only on demand.** The rule governing that is
  already in `templates/CLAUDE.md.template`; item 1b adds the same rule to Foundry's own
  CLAUDE.md.
- **Order of operations matters mechanically:** create the archive file *first*, then add
  the pointer that references it. `audit.sh`'s file-path check **FAILs** on a backticked
  repo-rooted path that doesn't exist (verified — a `docs/`-prefixed name that is missing is
  a hard failure, not a warning). Writing a pointer to a not-yet-created file breaks the
  audit.

### Naming (decided — use exactly these)

| Archive | Holds |
|---|---|
| `SESSIONS_ARCHIVE.md` | older SESSIONS.md entries (item 2) |
| `DECISIONS_ARCHIVE.md` | older DECISIONS.md entries (item 3) |
| `PROJECT_HISTORY.md` | CLAUDE.md's old `Current status` log (item 1) |

Root level, bare names, matching their parents. Not `docs/` — root keeps them beside the
files they came from, and a bare name degrades more gracefully in the audit's path check if
something is ever mistyped.

### The literal pointer block (paste into CLAUDE.md, adjusting only the ranges)

Place it as its own section immediately after `Current status`. Fill the ranges from what
you actually moved — do not copy the example dates without checking them.

```markdown
## Where the history lives

Older material is archived out of this file to keep the SessionStart auto-load small. It is
**not** loaded into sessions and should not be opened unless the task genuinely needs it
(see the archive rule under Rules / Never do).

- `PROJECT_HISTORY.md` — the full per-session narrative log formerly in `Current status`,
  Sessions 4-20 (2026-06-28 → 2026-08-18). Open it to reconstruct how a mechanism reached
  its current shape, or what an earlier review round actually found.
- `SESSIONS_ARCHIVE.md` — session entries older than the newest two. Open it when tracing
  when and why something changed.
- `DECISIONS_ARCHIVE.md` — decision entries from 2026-06. Open it when a current rule looks
  arbitrary and you need the reasoning that produced it, or to check whether an approach was
  already tried and rejected.

Everything here is also in git history; these files exist so it is findable without knowing
to go looking.
```

### The Rules addition (paste into CLAUDE.md's `Rules / Never do`, above `{{ADDITIONAL_RULES}}`'s position)

Use the same text now in `templates/CLAUDE.md.template` — copy it from there verbatim so the
two cannot drift, rather than retyping it from this document.

---

## Item 1 — CLAUDE.md's `Current status` (do this first)

**Why first:** biggest single win, lowest risk, and it is the only one of the three that
fixes a correctness problem rather than just a size problem. `Current status` is 46KB of
per-session narrative log covering Sessions 4-20. `docs/HOWS_AND_WHYS.md` says CLAUDE.md
"should always be readable as a snapshot, not a history," and that section is a history.
The content is **already duplicated in SESSIONS.md**, which is the file whose actual job
it is — so this is largely removing a second copy, not discarding a record.

Do it in two mechanical steps, not as one synthesis. **Do not read the section into context
to move it** — extract by line range, which is why this is cheap on any model.

These boundary commands were run against the real file on 2026-08-18 and produced
`START=29`, `END=70`, body `46,331` bytes, with `## KNOWN DEBT` correctly following. Re-run
them rather than hardcoding those numbers — the file will have changed:

```bash
START=$(grep -n '^## Current status' CLAUDE.md | cut -d: -f1)
END=$(awk -v s="$START" 'NR>s && /^## /{print NR-1; exit}' CLAUDE.md)
sed -n "$((END+1))p" CLAUDE.md    # sanity: must print the NEXT '## ' heading
```

1. **Move verbatim, by line range.**
   ```bash
   { printf '# Project history\n\nThe per-session narrative log formerly in CLAUDE.md'\''s `Current status`.\nNot auto-loaded. See "Where the history lives" in CLAUDE.md.\n\n'
     sed -n "$((START+1)),${END}p" CLAUDE.md; } > PROJECT_HISTORY.md
   sed -i '' "$((START+1)),${END}d" CLAUDE.md    # macOS/BSD sed; GNU sed drops the ''
   ```
2. **Write a fresh `Current status`** under the now-empty heading — target 15-25 lines,
   answering only "what is true right now": what exists, what works, what is in flight.
   Not what happened, in what order, in which session. This is the one lossy step in the
   whole handoff, and the full original is in `PROJECT_HISTORY.md` beside it.

Then add the pointer block and the Rules line (both specified above), in that order.

**Verify the move was lossless** — the point is that this is checkable, not asserted:
```bash
grep -c 'Session 4' PROJECT_HISTORY.md      # early content survived the move
wc -c CLAUDE.md PROJECT_HISTORY.md          # CLAUDE.md down ~46KB
bash skills/foundry-audit/audit.sh          # reachability + path checks must stay clean
```

---

## Item 2 — SESSIONS.md archive split

The plan already exists and has been deferred three times (Sessions 15, 16, and again
since); it is not new design work. `SESSIONS_ARCHIVE.md`, newest-first like its parent.

**Cutover rule — decided, and measured rather than guessed: keep the newest TWO entries
inline.** Three was the original instinct, but the 2026-08-18 entries are unusually long, so
the numbers were checked: keeping two leaves 22,453 bytes inline and archives 137,283.
Keeping three would leave roughly 70KB inline and defeat most of the point. State the rule
in both files so the next session extends it rather than re-litigating it.

Entries begin with `^## 20`, so the boundary is mechanical (verified 2026-08-18: cut at
line 84, the third entry):

```bash
CUT=$(grep -n '^## 20' SESSIONS.md | sed -n '3p' | cut -d: -f1)
sed -n "${CUT}p" SESSIONS.md    # sanity: must be the 3rd '## 20' heading

{ printf '# Session archive\n\nSESSIONS.md entries older than the newest two. Not auto-loaded.\nNewest-first, same as its parent. See "Where the history lives" in CLAUDE.md.\n\n'
  tail -n +"$CUT" SESSIONS.md; } > SESSIONS_ARCHIVE.md
head -n "$((CUT-1))" SESSIONS.md > /tmp/sessions.new && mv /tmp/sessions.new SESSIONS.md
```

Then append the truncation pointer to SESSIONS.md (a single line naming
`SESSIONS_ARCHIVE.md` and the date range it starts from), and verify:

```bash
grep -c '^## 20' SESSIONS.md SESSIONS_ARCHIVE.md   # 2 inline, the rest archived
tail -3 SESSIONS_ARCHIVE.md                        # oldest entry survived intact
```

---

## Item 3 — DECISIONS.md archive split

Same shape, smaller payoff: the 2026-06 entries are 42% of the file (verified 2026-08-18 —
cut at line 195, leaving 51,660 inline and archiving 34,783). `DECISIONS_ARCHIVE.md`.

```bash
DCUT=$(grep -n '^## 2026-06' DECISIONS.md | head -1 | cut -d: -f1)
sed -n "${DCUT}p" DECISIONS.md    # sanity: must be the first 2026-06 heading

{ printf '# Decision archive\n\nDECISIONS.md entries from 2026-06. Not auto-loaded.\nNewest-first, same as its parent. See "Where the history lives" in CLAUDE.md.\n\n'
  tail -n +"$DCUT" DECISIONS.md; } > DECISIONS_ARCHIVE.md
head -n "$((DCUT-1))" DECISIONS.md > /tmp/decisions.new && mv /tmp/decisions.new DECISIONS.md
```

Note that DECISIONS.md stays the largest remaining file at ~52KB. That is deliberate — the
2026-08 entries are recent and actively load-bearing. Don't archive further to hit a number.

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
