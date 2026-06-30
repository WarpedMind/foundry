# Foundry

Foundry scaffolds software projects with the documentation structure, hooks, and guardrails that make AI-assisted development reliable across many sessions — derived from a short questionnaire per project, not a fixed one-size-fits-all template.

Part of **Preamble** — where you forge the foundation of how you work with AI.

**New here?** Read the [User Guide](USER_GUIDE.md) for a full walkthrough of what actually happens when you run this — what you'll be asked, what gets created, and how to decide between the options. This README is the pitch; the guide is the how-to.

## About

I'm Tom Grow, a certified CAIO and founding partner of [CAIO Consultants](https://caioconsultants.com). I built Foundry for my own projects and client work — open-sourcing it felt like the right move.

## What it does

`/foundry-init` asks a handful of questions about your project — does it handle secrets? other people's data or money? is it regulated? solo or team? — and scaffolds exactly what's relevant, nothing more:

- **`CLAUDE.md`, `DECISIONS.md`, `SESSIONS.md`** — a fixed core structure every Foundry project shares, with optional sections (Security Rules, Regulatory Context, Compliance/Audit Trail) added only when the questionnaire says they're actually relevant. A 10-line personal script gets 3 lines of CLAUDE.md, not a compliance checklist.
- **A `SessionStart` hook** that loads those docs into context automatically at the start of every session — not dependent on the assistant remembering to ask, because that dependency has already failed in practice (see [`docs/HOWS_AND_WHYS.md`](docs/HOWS_AND_WHYS.md)).
- **A status hook** that, on every future session, silently confirms "Foundry: Active" if the project is already scaffolded, stays silent if you've explicitly dismissed it, or offers `/foundry-init` if neither — so you see the offer exactly when it's relevant, never as noise.
- **A `.gitignore` baseline and secrets-guard pre-commit hook**, only for projects that actually handle credentials. **Important limitation:** this catches secret-adjacent filenames (`.env`, `*.pem`, `config.yaml`, etc.) and already-committed secrets in those files — it does **not** scan file contents for a hardcoded secret sitting in an otherwise-ordinary source file (e.g. an API key string literal in a `.py`/`.js` file). For that, pair Foundry with a dedicated secret-scanning tool like [gitleaks](https://github.com/gitleaks/gitleaks) or [trufflehog](https://github.com/trufflesecurity/trufflehog). See [What Foundry does NOT do](USER_GUIDE.md#what-foundry-does-not-do-read-this-before-you-rely-on-it) for the full list of limitations.
- **Repo hygiene**: correct sequencing for a brand-new repo (`.gitignore` before the first commit, not after) and a standing discipline for keeping README/SESSIONS.md honest as the project changes.
- **Honest governance scaffolding**: when a project is flagged as regulated, Foundry writes either real, project-specific regulatory context, or an explicit "not yet researched — get this reviewed before relying on it" placeholder. It never fabricates plausible-sounding compliance language to fill a gap.
- **Optional `STACK.md`**: a career/portfolio record of what was actually used, when, and why — for resume bullets and interview prep, distinct in audience and lifecycle from the other docs. Every non-trivial entry has to state why that choice over the alternatives (inline, or cross-referenced to DECISIONS.md), not just name a technology.

Each piece above is also an independently invocable skill (`/foundry-docs`, `/foundry-hooks`, `/foundry-security`, `/foundry-governance`, `/foundry-repo-hygiene`, `/foundry-stack`) — `/foundry-init` is a thin orchestrator over them, so you can run just one piece on an existing project instead of the whole sequence.

`/foundry-init` also asks upfront whether you want brief or detailed/educational explanations as it works — detailed mode states the reasoning behind each non-obvious step (most of which already lives in this repo's `docs/HOWS_AND_WHYS.md`), useful if you're newer to this kind of project setup; brief mode just does the thing. You can ask to switch at any point.

## Promptify

`/promptify <rough idea>` rewrites a rough task description into a clearer, more effective prompt and explains what changed and why — meant to be educational, not a black box. `/promptify! <rough idea>` does the same rewrite and immediately proceeds to execute it, for routine patterns you've already learned to trust. Bare `/promptify` with no content switches to a guided build-from-scratch mode — useful when you don't have a rough idea typed yet: it asks what you want to accomplish, then batches the remaining structural questions (role, scope, output format, etc.) into one round of questions before producing the prompt, rather than going back and forth one question at a time. (This batching is genuinely fewer turns than the conversational alternative, but it's not free — every question and answer is still a normal turn with real context cost, same as any other exchange.) Promptify is a fully standalone skill; Foundry just makes sure new projects know it exists. See the [User Guide](USER_GUIDE.md#promptify-turning-a-rough-idea-into-a-good-prompt) for when to use plain `/promptify` vs. `/promptify!`.

## qc-review

`/qc-review` runs an adversarial, fresh-context review against whatever changed in the current session (or a scope you name explicitly), hunting specifically for destructive actions, security gaps, and silent overwrites — not a general code review. It formalizes the exact pattern that found this repo's own pre-launch safety issues: spawn a subagent with zero prior context, tell it to be skeptical, have it hunt for one specific failure class and report only gaps, not a clean-bill-of-health narrative. Verified findings get appended to the project's CLAUDE.md `KNOWN DEBT` section, labeled with their source (`[QC review, <date>]`) so a later reader can tell this came from an adversarial pass rather than ordinary work. Like Promptify, this is a fully standalone skill — Foundry surfaces that it exists and suggests running it at natural checkpoints (before treating security-sensitive or destructive-capable work as finished), but never runs it automatically. See the [User Guide](USER_GUIDE.md#qc-review-an-adversarial-second-opinion-not-a-general-code-review) for what it is **not** a substitute for, and when to consider the opt-in mechanical hook.

## Install

**Prerequisites:** `jq` and Bash (`/bin/bash`). Every hook Foundry wires into a project's `.claude/settings.json` shells out to `jq` to read/write hook payloads — without it, hooks degrade silently (e.g. the status hook falls back to "not set up" with no indication `jq` itself is the actual problem) rather than erroring loudly. Most macOS/Linux dev machines already have both; if `jq -h` fails, install it first (`brew install jq` / `apt install jq` / etc.).

```bash
git clone https://github.com/WarpedMind/foundry ~/Projects/foundry
~/Projects/foundry/install.sh
```

This symlinks each skill into `~/.claude/skills/`, so they're available in every project on your machine, and stay current with a `git pull` in this repo (no copying).

## Quickstart

In any project directory, in Claude Code:

```
/foundry-init
```

Answer the questions; review what gets generated before committing.

## Safety: this is designed to be non-destructive

Foundry is built to be safe to try on a project you already care about, including one with real, hand-written documentation already in place:

- **It never silently overwrites an existing CLAUDE.md, DECISIONS.md, SESSIONS.md, STACK.md, `.gitignore`, or `.claude/settings.json`.** If any of these already exist, Foundry reads them, tells you plainly what it found, and asks per-file whether to leave it alone, append to it, or fully re-render it — defaulting to "leave it alone" if you don't give a clear answer. A hand-maintained doc with months of real project history is not something a template can regenerate if it gets clobbered, so this is treated as a hard rule, not a suggestion.
- **It only touches the single directory you run it from.** It does not cascade into subdirectories or affect sibling projects. `/foundry-init` checks first whether the current location actually looks like one project's root, versus a container folder holding several unrelated projects (like `~` or `~/Projects`) — if it looks wrong, it stops and asks you to confirm the right directory rather than guessing.
- **Turning it off is fully reversible and non-destructive.** Foundry's hooks only *read* files into context at session start — the docs themselves are always just plain Markdown, never dependent on Foundry continuing to run. Delete the hook entries from `.claude/settings.json` (or stop using the `/foundry-*` skills) and nothing breaks: CLAUDE.md, DECISIONS.md, SESSIONS.md, STACK.md remain exactly as they were, fully readable, fully yours, with no embedded dependency on Foundry itself. (Note: CLAUDE.md specifically is still auto-loaded by Claude Code's own built-in memory feature regardless of Foundry — that's a Claude Code behavior, not something Foundry adds or can remove.)
- **Nothing commits automatically.** Every skill shows you what it's about to write before writing it, and `/foundry-init` explicitly asks before committing anything to git. You can always review and discard before anything touches version control.

## Design principles

- **Derive, don't preset.** No `--preset=advanced-mobile-regulated`. A short questionnaire derives which optional pieces apply — except a single "minimal" fast-path for throwaway scripts, which skips the questionnaire entirely.
- **Composable over monolithic.** Every piece foundry-init calls is independently useful and independently invocable later.
- **Mechanism over reminder.** If something needs to always happen, it's a hook the harness enforces — not a written rule that depends on an AI session remembering it. (This rule exists because that exact failure happened — see HOWS_AND_WHYS.md.)
- **Verify, don't assume.** Every hook and template in this repo was tested against real input before being trusted — pipe-tested commands, rendered template diffs checked by hand, an actual end-to-end run comparing two real scenarios. The same standard applies to what Foundry-generated projects should do with their own external dependencies and claims.

See [`docs/HOWS_AND_WHYS.md`](docs/HOWS_AND_WHYS.md) for the reasoning behind each of these, with real examples.

## Roadmap

- [x] ~~Document `jq` as a hard prerequisite~~ — **done.** A fourth fresh-eyes review (Session 16) found that every Foundry hook silently degrades (rather than erroring) if `jq` is missing from `PATH`, with no doc anywhere stating it's required. Added a Prerequisites note above Install.
- [ ] Proactive code-review agents (security-focused, quality-focused) wired via `PostToolUse` hooks — deliberately deferred out of the initial build to avoid scope creep; needs its own design pass (blocking vs. advisory, noise tuning, and which existing tools — e.g. a project's own `/code-review` or `/owasp-security`/security-review skills — to invoke rather than duplicate).
- [x] ~~Standalone fresh-context QC/adversarial-review skill~~ — **built (`qc-review`)**. Lives alongside Promptify as a referenced-not-owned tool, same pattern. Default trigger: on-demand (`/qc-review`) plus a proactive offer at natural checkpoints (never automatic) — a mechanical `PostToolUse` auto-run mode was deliberately scoped as opt-in-only, not the default, since it would fire on every edit rather than at a real completion checkpoint, with no way to block (the edit already happened by the time `PostToolUse` fires). Findings are verified (reproduced, not just relayed — same verify-before-trust standard as the rest of Foundry) before being appended to CLAUDE.md's `KNOWN DEBT`, labeled `[QC review, <date>]` so the source is never ambiguous to a later reader.
- [ ] Pluggable external skill-pack support (Claude Code's plugin/marketplace mechanism) for community-contributed additions — intentionally not bundling any specific named third-party pack until independently verified.
- [ ] Promptify prompt-shape library expansion and possibly splitting into its own standalone repo/tool.
- [ ] A deeper, standalone model/effort-selection command (beyond Promptify's one-line suggestion) — deliberately not built yet. Considered and scoped down: a "detailed analysis" version would need real data to reason over (actual cost/performance tradeoffs per model, historical task outcomes) that isn't currently available to a skill, so a separate command today would just be a longer-winded restatement of the same judgment the one-liner already makes, not a genuinely deeper one. Worth revisiting if Claude Code exposes more of this (e.g. usage/cost introspection, or a way for a skill to act on a recommendation rather than just state it) as the platform evolves.
- [ ] **"Promptify auto mode"** — a mode where any sufficiently complex/heavy prompt (as opposed to a simple question) is automatically run through `/promptify`'s rewrite step before being processed as a normal request, without the user having to type `/promptify` explicitly each time. Does NOT exist today — currently `/promptify`/`/promptify!` are always explicit, opt-in invocations; nothing auto-detects prompt complexity or intercepts a normal message. This is a real, distinct feature from the explicit-invocation modes already built, deliberately deferred rather than built opportunistically: it needs its own design for the hard part, which is reliably classifying "heavy" vs. "simple" without being either too aggressive (rewriting things that didn't need it, adding friction) or too conservative (missing genuinely complex requests). Likely mechanism: a `UserPromptSubmit` hook that runs a lightweight classification pass — but that design (what counts as "heavy," false-positive/negative tolerance, how to make it easy to override per-message) hasn't been done yet.
- [x] ~~Harden the SessionStart hook templates' shell substitution~~ — **fixed.** Confirmed the bug for real (bare word-splitting genuinely breaks on a filename with spaces, verified directly in bash). Fixed with a properly quoted bash array substitution; re-verified against spaces-in-filename, the normal case, and missing-file degradation, then applied to both the template and Foundry's own live settings.json.
- [x] ~~`foundry-stack` confidentiality cross-check~~ — **added.** Checks CLAUDE.md's REGULATORY CONTEXT/COMPLIANCE section for confidentiality language before the generic fit question, surfacing the connection explicitly rather than relying on the user to notice it themselves.
- [x] ~~Hook 1/3 SessionStart merge guard~~ — **fixed (Session 17).** A fifth fresh-eyes review found the install step's merge instruction hard-fails if `hooks.SessionStart` already exists as a bare object rather than an array (`jq: error: object and array cannot be added`) — a real, reproducible exit-5 error blocking the whole install for an older/hand-written settings shape. Fixed with a type-checked `jq` merge handling array/object/missing-key cases; verified against all plausible shapes plus the original failure.
- [x] ~~`foundry-governance`/`foundry-stack` anti-fabrication and evidence gaps~~ — **fixed (Session 18).** A sixth fresh-eyes review, the first to probe prose-only skills with no rendered command, found three instances of the same shape: a safeguard whose trigger condition had an unguarded edge where the *absence* of the trigger was silently treated as the safe case. Extended `foundry-governance`'s flag-don't-fabricate rule to confident-but-vague answers (not just explicit "I don't know"); added an explicit cite-the-evidence instruction to `foundry-stack`'s verification step; added a one-line confidentiality check to `foundry-stack` for when no governance section exists yet.
- [x] ~~Missing `.gitignore` for non-secrets projects~~ — **fixed (Session 19).** A seventh fresh-eyes review, pointed at `foundry-init`'s own orchestration logic, found that a project with `HANDLES_SECRETS=false` got no `.gitignore` at all — the only writer was `foundry-security`'s secrets-pattern baseline, gated entirely on that flag. `foundry-repo-hygiene` now writes a universal, stack-agnostic OS/build-junk baseline unconditionally before the first commit, with `foundry-security`'s secrets patterns merged on top only when relevant.
- [x] ~~README changelog/roadmap discipline~~ — **added (post-Session-19).** Caught directly (not a fresh-eyes review) when this Roadmap section itself had silently fallen 3 sessions behind real fixes already tracked in CLAUDE.md/SESSIONS.md. Added a `foundry.readmeChangelogDiscipline` setting to `foundry-repo-hygiene` Part 2 — asked once, the first time a push would update CLAUDE.md/SESSIONS.md without a corresponding README change, defaulting to recommended-on but always the user's explicit, recorded choice rather than assumed.
- [x] ~~README discipline's own skip-path gap~~ — **fixed.** An eighth fresh-eyes review found the new discipline above had the exact same gap-shape it exists to prevent: skipping for a section-less README left the setting unset rather than recording an explicit "not applicable yet" state, so a README that later grows a Roadmap section would never get re-asked. Fixed by recording `foundry.readmeChangelogDiscipline: "not-applicable-yet"` on skip, with a freshness-check item that re-asks if the precondition later changes.
- [x] ~~Standing rule: check the negative branch of every conditional safeguard~~ — **added.** Eight straight review rounds in this repo found the same failure shape every time — absence of a trigger condition silently treated as the safe case instead of "unknown, flag it." Added a CLAUDE.md Rules entry naming this explicitly as a structural risk of writing multi-branch instructions in prose for an LLM to execute, so it's checked deliberately on every future conditional safeguard rather than caught only when a review happens to find it.
- [ ] `foundry doctor` — an audit command for existing (non-Foundry-initialized) projects, checking which pieces are present/missing/stale without requiring a full re-init.
- [ ] `foundry-update` — a way to pull template/skill improvements into a project that was already scaffolded by an earlier version of Foundry, without a full re-init. Currently a scaffolded project is frozen at whatever Foundry looked like the day it ran `/foundry-init`.
- [ ] Persistent `statusLine` "Foundry: ✓" indicator (visible every turn, not just at session start) as an alternative/complement to the current SessionStart-only status message — deferred because it's a separate Claude Code mechanism (statusLine config) deserving its own design pass, and a toggle between the two needs its own settings surface.
- [ ] Multi-machine dismiss-state consistency: the per-project "skip Foundry" dismissal currently lives in committed `.claude/settings.json` (so it's consistent across clones), but if a future version moves any of this state into personal/gitignored `.claude/settings.local.json`, that would need its own per-machine consistency story. Not an issue today, worth remembering if that changes.
- [ ] Cross-project aggregation tool — pulls STACK.md (career data) and DECISIONS.md (decisions/lessons) from every Foundry project into one place. Deliberately not a per-project doc: the value isn't in concatenating entries side by side, it's in *synthesis* — surfacing that the same lesson (e.g. verify-before-trust) has independently proven itself correct across multiple unrelated projects, which a per-project doc structurally can't show. Same deferred category as the STACK.md cross-project master rollup — Foundry itself stays disciplined to one project at a time; this is a separate tool's job.
- [x] ~~`CwdChanged`-based cross-project drift detection hook~~ — **investigated and superseded.** `CwdChanged` is a real, valid Claude Code hook event, but its stdin payload could not be verified: it requires a genuine harness-level cwd change to fire, and testing revealed that this session's own extensive cross-project work (running many `cd ~/Projects/other-project && ...`-qualified commands) never actually triggered a harness-level cwd change at all — confirmed when `EnterWorktree` reported "not in a git repository" despite hours of real work inside one, revealing the session's tracked root had silently never moved. This means `CwdChanged` would not have caught the exact scenario that motivated this idea in the first place. **Built a working substitute instead**: a `PreToolUse`/`Bash` hook (Hook 4 in `foundry-hooks`, optional/offered not forced) that detects a leading `cd` to a directory outside the project and logs it to `.claude/drift.log` — verified against 6 real test cases. Two known, stated limitations: only catches `cd` as the first token in a command (a later `cd` in a chain is missed, confirmed by test), and a relative `cd ..` resolves against actual shell state the hook can't independently verify. The written-rule version (proactively suggesting a checkpoint on directory change, in the CLAUDE.md template's standing Rules) remains in place as a complementary, judgment-based layer alongside this mechanical log.

## Get in touch

If Foundry was useful, a star or a follow on [GitHub](https://github.com/WarpedMind) is always appreciated — no pressure, just genuinely nice to know it landed somewhere.

I'm also open to dev work and consulting — feel free to connect on [LinkedIn](https://www.linkedin.com/in/tomgrow/) or reach me at [tom@caioconsultants.com](mailto:tom@caioconsultants.com). CAIO Consultants provides fractional and full-time Chief AI Officer services for companies serious about AI — strategy, governance, and implementation oversight without the full-time executive overhead. More at [caioconsultants.com](https://caioconsultants.com).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for dev setup, the test suite, and what to check before opening a PR.

## License

MIT — see [LICENSE](LICENSE). If you use or fork this, a credit/link back is appreciated (not required).
