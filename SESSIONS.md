# Foundry Session Summary
# Entries are ordered newest-to-oldest. Most recent session is at the top.

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
