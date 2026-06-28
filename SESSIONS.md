# Foundry Session Summary
# Entries are ordered newest-to-oldest. Most recent session is at the top.

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

### What to do first next session
- Exercise the status hook's dismiss path through a real invocation — still open from Session 2/4.
- Test `/promptify` against at least one non-debugging shape (e.g. an architecture decision or writing task) to confirm the new role-framing element actually fires correctly when it should, since this session's test only confirmed it correctly stayed silent when it shouldn't.
- Consider running `/foundry-init` next on a genuinely different, less-similar real project (not another Foundry-built tool) to test the questionnaire path on something with a different risk profile (e.g. actual secrets handling).
- Decide whether the user wants to actually act on the "create a game" demo prompt, or whether it was purely illustrative for this test.

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
  - The already-committed-secrets check (`foundry-security` step 3) only searched a fixed filename list — added a broader historical scan (`git log --all --diff-filter=A --name-only ... | grep -iE 'env|secret|key|pem|cred|password|token|config'`) as a second pass, tested against a real repo (Karbot Rage) to confirm it produces a sane, reviewable candidate list rather than noise.
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
- The broader historical-secrets-scan command verified against a real repo (Karbot Rage) to confirm it produces a usable, non-noisy candidate list.
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
- **`foundry-stack` skill + `STACK.md.template`** (new 8th skill): career/portfolio tech-stack tracking, distinct in audience and lifecycle from CLAUDE.md/DECISIONS.md/SESSIONS.md. Modeled directly on a proven real pattern (`jobhunting/lazy-larry/STACK.md`) rather than invented from scratch — same section structure (current stack table, planned/not-yet-built, version snapshots with "what this demonstrates," skills-gap-vs-job-postings, ready-to-paste resume bullet). Added a mandatory why-linkage rule after the user flagged that an early draft only covered what/when, not why: every non-trivial row must state the alternative/reason inline or cross-reference the relevant DECISIONS.md entry by date. Wired into `foundry-init`'s questionnaire (`TRACK_STACK` flag) and call sequence.
- **Status/offer SessionStart hook** (`templates/settings.status.json.template`, Hook 3 in `foundry-hooks`): three states — scaffolded (silent "Foundry: Active (scaffolded <date>)"), dismissed (completely silent), neither (one-line offer to run `/foundry-init`). `foundry.scaffolded`/`scaffoldedDate` are written by `foundry-init` on successful completion (Step 2.5); `foundry.dismissed` is written by a new dismiss path if the user declines the offer. The status hook itself only reads these fields, never writes them.
- **Context-checkpoint rule** added to `CLAUDE.md.template`'s standing Rules: proactively suggest a SESSIONS.md/memory update plus `/clear` when a session has drifted across many unrelated subtasks or run long — prompted by the user asking whether Foundry enforces good context-management practice, noticing in the moment that this very build session hadn't been proactively flagged for a checkpoint despite running long across several different subtasks.
- Roadmap additions (correctly deferred, documented rather than dropped): `foundry-update` (pulling template improvements into an already-scaffolded project), a persistent `statusLine` indicator as an alternative/complement to the SessionStart-only status message, and a note on multi-machine dismiss-state consistency if that state ever moves to personal/gitignored settings.

### What was decided
See DECISIONS.md for full entries. Summary: STACK.md built in full now rather than as a placeholder, because the per-project record is the data layer any future job-hunting tool would need regardless; the cross-project rollup stayed correctly out of scope. The status hook needed three states, not a binary, to avoid being either presumptuous (re-offering on an already-scaffolded project) or naggy (re-offering after an explicit decline). The context-checkpoint rule is framed around recognizing drift/scope sprawl, not a fixed context-percentage threshold, since the real mechanism that keeps long-running work reliable is re-anchoring on the docs after a clear, not hitting a specific number.

### Verification
- `foundry-stack`/STACK.md.template: hand-rendered against a real project's actual history (Karbot Rage — the Session 13/15 Kalshi work) at the same quality bar as the Lazy Larry reference pattern it's modeled on; confirmed the why-linkage rule produces genuinely interview-worthy notes, not technology-name restatements.
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
- `foundry-repo-hygiene`: the docs-freshness `git log -1 --format=%ci` pattern was run against a real existing repo (Karbot Rage) and produced a real, interpretable timestamp gap, not just syntactically-valid-but-meaningless output.
- `foundry-init`: ran an actual end-to-end test by invoking the Skill tool directly (not hand-simulated) against two real scratch directories — a throwaway CSV-to-JSON script and a regulated fintech compliance tool ("ComplianceBot"). Confirmed: the minimal scenario produced exactly 1 file with 3 sections; the regulated scenario produced 4 files (including a validated `.claude/settings.json` hook) with 14 sections, including a governance section that correctly stated "NOT YET RESEARCHED" rather than fabricating SEC-specific compliance language.
- `install.sh`: run for real (not dry-run) — confirmed all 7 skills symlinked correctly, confirmed idempotent on a second run, and confirmed via the harness's own system reminder that all 7 skills were recognized and listed as available immediately afterward.

### What to do first next session
- Confirm repo name/visibility with the user, then push the initial commit (this session ends before that step — see KNOWN DEBT in CLAUDE.md).
- Exercise `/promptify` against a handful of real rough prompts — its shape-classification logic has been designed but not yet run against real varied input.
- Decide on a license before any public announcement.
- Consider whether the Markdown-instruction approach to template rendering (asking the model to follow IF-block stripping steps) holds up well after more real-world use, or whether a literal parsing script would be more reliable at scale.
