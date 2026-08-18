---
name: foundry-audit
description: Run a mechanical structural audit of a project's documentation set — dangling decision references, a decision log out of its own stated order, broken file paths after a rename, unreachable docs, unclosed fences, decisions whose stated enforcement locus doesn't exist. Use when the user types /foundry-audit, before a release or handoff, after a rename or restructure, or (proactively, as an offer) when a session has made substantial doc changes. Standalone skill — works in any project, with or without Foundry's other scaffolding.
---

# foundry-audit

Documentation drift is not caught by reading. A dangling cross-reference, a decision-log entry filed out of order, a path that survived a rename — each one reads perfectly and is wrong. This skill exists because three careful read-through reviews of one real project's doc set missed defects that a fourth, mechanical pass found immediately.

**The checks live in a script, not in this file.** `audit.sh`, next to this SKILL.md. That is deliberate and it is the load-bearing design choice: a check written as prose instruction cannot be mutation-tested, because there is no artifact to inject a defect into and re-run. Every FAIL-capable check in `audit.sh` has a case in `tests/run_fixtures.sh` that injects a real instance of the defect it claims to catch and confirms it fires. A check nobody has ever seen fail is not evidence of anything, no matter how many times it has been re-run clean.

## This is not `qc-review`

The two are opposites, and the distinction is worth holding onto rather than blurring:

| | `qc-review` | `foundry-audit` |
|---|---|---|
| Subject | code and its behavior | documents and their structure |
| Mechanism | a fresh-context subagent applying adversarial judgment | a deterministic script producing identical output every run |
| Finds | what a reader with no investment would notice | what no reader notices, because it reads fine |

Neither substitutes for the other. Run `qc-review` before shipping risky code; run this before trusting a doc set.

## Entry points

- **`/foundry-audit`** — audit the current project's doc set.
- **`/foundry-audit <path>`** — audit another project (passes `--root`).
- **Proactive offer (a suggestion, never automatic)** — see below.

## Step 1 — run it

```bash
bash ~/.claude/skills/foundry-audit/audit.sh
```

Run from the project root. If the skill isn't installed via `install.sh`, it's at `skills/foundry-audit/audit.sh` in the Foundry checkout. Options: `--root DIR` to audit elsewhere, `--doc PATH` to add a file outside the default set (repeatable), `--numeric NOUN` to cross-check a counted claim (see Step 3).

Default document set: `CLAUDE.md`, `DECISIONS.md`, `SESSIONS.md`, `README.md`, `STACK.md`, `USER_GUIDE.md`, `CONTRIBUTING.md` (those that exist), plus every `.md` under `docs/`. Deliberately not "every Markdown file in the repo" — a vendored README or a skill's own SKILL.md is not this project's document set, and sweeping them in produces noise that teaches a reader to ignore the output.

## Step 2 — read the result states, and don't collapse them

Five states, and the third is the one that exists because of this repo's most-repeated failure:

- **PASS** — ran against a real input set, found nothing.
- **N/A** — the convention genuinely doesn't apply here (no ADR-style IDs anywhere, no `Enforced at:` field used yet). Not a gap; doesn't affect the exit code.
- **SKIP** — the check *should* have applied but its input set was unexpectedly empty: `DECISIONS.md` exists but no heading parsed, ADR IDs are referenced but none defined, no entry-point file to walk reachability from. **This counts as a finding.** A check that could not run is an unknown, not a pass. Foundry has found the opposite assumption — absence of a trigger treated as the safe case — eight separate times (see CLAUDE.md's standing Rules); this is the mechanism refusing to make it a ninth.
- **FAIL** — a real defect, listed under FINDINGS with the file it's in.
- **INFO** — surfaced for judgment, never a defect, never affects the exit code.

Exit codes: `0` clean, `1` findings, `2` harness error (no documents found, or `--doc` named a file that isn't there). A harness error is explicitly *not* a clean result and says so.

## Step 3 — the checks this script does NOT make mechanical

Stated plainly so these don't borrow credibility from the checks that are actually tested. Three of the classes in the originating proposal are judgment, not regex:

- **Absolute-rule coverage.** The script finds lines phrased absolutely (`never`, `non-negotiable`) in documents the SessionStart hook does *not* load, and reports them as INFO. Whether two differently-worded rules are the same rule is not mechanically decidable, so it does not decide. Known precision limit: on a README that *describes* a tool ("it never silently overwrites your files"), descriptive prose matches the same phrasing as a standing rule. Read the candidates; expect most to be prose.
- **Numeric-claim agreement.** The comparison is mechanical and tested (`--numeric questions` finds "seven questions" in one file and "eight questions" in another). Choosing *which* nouns are worth checking is judgment — that's why it's a flag rather than a fixed list. Ask what this project counts in more than one place.
- **Whether a pasteable prompt is self-contained, and whether a standards bullet is echoed anywhere actionable.** Not implemented. Both need a semantic judgment about whether one passage covers another, and a keyword-presence proxy would be a check that passes while the defect is present — the exact failure this skill is built against. Do these by hand if the project has pasteable prompts: read each fenced block as if you had no conversation history, and list what it assumes.

**Orphaned decisions** sit between the two. The mechanical half is tested: a decision naming an enforcement locus that doesn't exist is a FAIL. The other half — a count of decisions naming no locus at all — is INFO, because `Enforced at:` is optional by design. That count exists so the field's absence is *noticeable* rather than silently fine, which is exactly what DECISIONS.md's 2026-08-17 entry asked for and stopped short of building. Expect it to be large in any log predating the field; that is not a defect list.

## Step 4 — handle findings, and don't edit anything before showing them

**Show the output first, always.** This skill reads documents; it does not write them without a yes. Silently editing a project's docs is the same class of action `foundry-docs` guards against with its per-file overwrite question.

Then, unlike `qc-review`, **fix first and persist only what's deferred.** The reasoning for the difference, since the two skills otherwise share a lineage:

- `qc-review` verifies a CRITICAL/HIGH finding by reproducing it before writing it down, because a subagent's claim that something is broken is only a claim.
- A finding here has already reproduced itself. It names a file, a line, and a string that is or isn't there — re-deriving it adds nothing. What needs verifying in this skill is the *check*, not the finding, and that happens once in `tests/run_fixtures.sh`, not per run.
- And most findings here are one-line fixes. Routing a stale path through KNOWN DEBT costs more attention than the defect does.

So: fix the mechanical ones in the same pass once the user agrees. Anything needing a real decision (an unreachable doc that maybe shouldn't exist, an absolute rule that may or may not belong in CLAUDE.md) goes to KNOWN DEBT, read-then-append, labeled by source and date:

```
- [foundry-audit, <date>] <the finding> — <what's undecided about it>
```

If a false positive shows up, don't fix the document to appease the tool. Either add the path to `.foundry-audit-allow` (one path per line, `#` comments allowed — for files referenced deliberately before they exist), or treat the false positive as a bug in `audit.sh` and fix it there with a new mutation case. A tool tuned by editing the documents it audits is measuring itself.

## What was verified, and how

Every row marked mechanical has a mutation case in `tests/run_fixtures.sh` — a known defect of that class injected into a clean fixture, with the check confirmed to fire.

| Check | Status |
|---|---|
| Decision references resolve (by date) | mechanical, mutation-tested |
| ADR-NNN references resolve (auto-detected) | mechanical, mutation-tested |
| Decision log holds its stated newest-first order | mechanical, mutation-tested |
| Decision headings parse at all (empty-input guard) | mechanical, mutation-tested |
| `Enforced at:` names a path that exists | mechanical, mutation-tested |
| `Enforced at:` stated as prose with no checkable path | mechanical, mutation-tested (reported as INFO) |
| Repo-rooted file paths resolve | mechanical, mutation-tested (plus two precision guards) |
| Stale path after a rename (names where the file went) | mechanical, mutation-tested |
| Code fences balanced | mechanical, mutation-tested |
| Trailing newline present | mechanical, mutation-tested |
| Table column counts consistent | mechanical, mutation-tested |
| Placeholder markers left behind | mechanical, mutation-tested (plus a prose-mention true negative) |
| Every doc reachable from CLAUDE.md/README.md | mechanical, mutation-tested |
| No entry point to walk from (empty-input guard) | mechanical, mutation-tested |
| Numeric claims agree for a given noun | comparison mechanical and mutation-tested; noun choice is judgment |
| Absolute rules present in the auto-loaded file | judgment-assisted, **not** mutation-testable — surfaces candidates only |
| Decisions with no enforcement locus | informational count; whether an orphan matters is judgment |
| Standards bullets echoed somewhere actionable | **not implemented** — see Step 3 |
| Pasteable prompts self-contained | **not implemented** — see Step 3 |

Three of those cases are precision guards rather than defect injections — a bare example filename, a path under a directory the repo doesn't have, and a placeholder marker inside backticks must all stay quiet. They exist because each was a real false positive found by running this against Foundry's own documents, not a hypothetical.

The suite also proves the *harness* can fail, not just the checks: neutering a check in `audit.sh` and re-running was confirmed to turn the corresponding mutation case red. A green suite that stays green when the thing it tests is broken is the failure mode this whole skill argues against, so it was checked directly rather than assumed.

The evidence that matters most, though, is what it found on real prose rather than on a fixture built to exercise it. Pointed at Foundry's own repo, it caught two defects written by the very session that built it: a stale count (a decision entry claiming 23 mutation cases when the suite had grown to 28, via `--numeric "mutation cases"`), and a dangling reference to a decision dated `2026-06-30` when the entry is actually dated `2026-06-28`. The second is the better demonstration — that wrong date came from the handoff document this skill was built from, was copied into two files by a session that had read the decision log in full, and survived every subsequent re-read. Reading is not the mechanism that catches this. Running something is.

## Known limitations

- **The path check trades recall for precision, on purpose.** Only paths whose first segment is a real top-level entry produce a FAIL. A bare filename, or a path under a directory this repo doesn't have, is grouped into one INFO line. This came from running against a real doc set: Foundry's own documents discuss filenames as subject matter (`.gitignore` examples, fixture names), and treating those as references produced 35 findings of which roughly 20 were noise. A reference into a directory that was itself renamed away will land in INFO rather than FAIL — scan that line.
- **Reference forms are fixed.** A decision reference is recognized as an ISO date on a line mentioning `DECISIONS.md`/"decision log", or "the `<date>` entry/entries/decision". A reference phrased another way is invisible to the check. This is a pattern list, and pattern lists are permanently incomplete — the same structural point `foundry-security` makes about secrets filenames. Probing with new phrasings is worth more than re-running the existing suite.
- **It audits documents, not truth.** It can confirm that `DECISIONS.md`'s 2026-08-17 entry exists; it cannot confirm the entry describes what actually happened. A decision whose stated enforcement locus exists but doesn't enforce anything passes.
- **A path containing a space is audited, but cannot be referenced.** The file itself is scanned normally (an earlier version word-split it into two nonexistent documents and invented findings — fixed and regression-tested). But the patterns that recognise a reference don't span spaces, so `docs/my notes.md` will always report as unreachable even when something links to it. Renaming is the practical answer; the alternative is a reference pattern loose enough to swallow ordinary prose.
- **Bash 3.2 and BSD tools**, matching the rest of Foundry, plus `find`/`awk`/`sed`. No `jq` dependency, unlike the hooks.

## When to proactively offer (a suggestion, never automatic)

Offer it — as a question, and say which trigger applies — at these points:

- After a rename or restructure that moved documents or directories.
- Before a release, a public push, or handing the project to someone else.
- When a session has substantially rewritten the doc set, at wrap-up alongside the SESSIONS.md update.

Don't run it unasked. It's cheap, but an unrequested wall of output at the wrong moment is the noise problem in a different costume.

### The periodic-nudge variant, and why it isn't the default

The originating proposal suggested driving this from Hook 3 (the status hook) as a cheap periodic nudge. It's buildable — Hook 3 already reads `.claude/settings.json`, so a `foundry.lastAuditDate` field and a day-count comparison would do it — and it is deliberately not built, on the same reasoning that kept `qc-review`'s `PostToolUse` auto-run opt-in (`DECISIONS_ARCHIVE.md`, 2026-06-28). SessionStart is not a completion checkpoint; it fires when a session opens, which is before any drift this session will cause. And the threshold has no defensible value yet: nobody has data on how fast a doc set actually drifts, so any number picked today is invention. If a user wants it, wire it explicitly and pick the interval with them — don't ship a guessed default that trains people to skip past the status line.

## Closing out

An audit's findings list is a bad place to end a turn in prose, because the obvious next question ("so do we fix these?") has several genuinely different answers and the user shouldn't have to write out which. End with an `AskUserQuestion` built from what this specific run produced: fix the mechanical findings now, record the judgment ones in KNOWN DEBT and move on, add a false positive to `.foundry-audit-allow`, or work through the INFO list item by item. Two to four of those, whichever the run actually generated — "Other" is supplied by the tool.

The exception is narrow and specific to this skill: a run that exits 0 with an empty INFO section has produced nothing to decide about, and the honest response is one sentence naming what was checked. A four-option menu on top of a clean audit manufactures a decision where the tool's entire job was to establish that there isn't one. Where a clean exit code sits next to a long INFO list, though, that list *is* the question — don't let "RESULT: CLEAN" end the turn while judgment items go unmentioned.

One cross-offer earns a slot, narrowly. When this run was triggered by the pre-release or pre-handoff case listed above, `/qc-review` belongs beside the fix options, because everything certified here concerns documents and a release ships code. Nothing in a clean RESULT line speaks to an auth bypass or a race condition, and a green result being read more broadly than it deserves is the specific risk that makes naming the gap worth the space. Don't attach it to a mid-work audit run after a rename — that trigger says nothing about whether risky code is about to go out. The branch that needs writing down is the ordinary one: a user who typed `/foundry-audit` supplied no trigger at all, and the list above governs the proactive-offer path only. Resolve it from what the session was actually doing, and where there is nothing to resolve from — a fresh session whose first action is this command — **don't offer it.** That default is deliberate and it is the conservative one: an offer attached to every user-typed run is the unconditional menu entry this whole design rejects, while a missed offer costs one command the user can still type. Somebody auditing docs right before a public push usually says so, and that sentence is the trigger.

## Relationship to Foundry

Referenced, not owned — the same footing as `promptify` and `qc-review`. `foundry-init` mentions it exists; nothing invokes it automatically, and it is not part of the scaffolding sequence. It runs against any project with Markdown documentation, Foundry-scaffolded or not: checks tied to conventions a project doesn't use report `N/A` rather than failing it for having a different shape.
