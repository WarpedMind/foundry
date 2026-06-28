# Foundry

Foundry scaffolds software projects with the documentation structure, hooks, and guardrails that make AI-assisted development reliable across many sessions — derived from a short questionnaire per project, not a fixed one-size-fits-all template.

Part of **Preamble** — where you forge the foundation of how you work with AI.

## What it does

`/foundry-init` asks a handful of questions about your project — does it handle secrets? other people's data or money? is it regulated? solo or team? — and scaffolds exactly what's relevant, nothing more:

- **`CLAUDE.md`, `DECISIONS.md`, `SESSIONS.md`** — a fixed core structure every Foundry project shares, with optional sections (Security Rules, Regulatory Context, Compliance/Audit Trail) added only when the questionnaire says they're actually relevant. A 10-line personal script gets 3 lines of CLAUDE.md, not a compliance checklist.
- **A `SessionStart` hook** that loads those docs into context automatically at the start of every session — not dependent on the assistant remembering to ask, because that dependency has already failed in practice (see [`docs/HOWS_AND_WHYS.md`](docs/HOWS_AND_WHYS.md)).
- **A status hook** that, on every future session, silently confirms "Foundry: Active" if the project is already scaffolded, stays silent if you've explicitly dismissed it, or offers `/foundry-init` if neither — so you see the offer exactly when it's relevant, never as noise.
- **A `.gitignore` baseline and secrets-guard pre-commit hook**, only for projects that actually handle credentials.
- **Repo hygiene**: correct sequencing for a brand-new repo (`.gitignore` before the first commit, not after) and a standing discipline for keeping README/SESSIONS.md honest as the project changes.
- **Honest governance scaffolding**: when a project is flagged as regulated, Foundry writes either real, project-specific regulatory context, or an explicit "not yet researched — get this reviewed before relying on it" placeholder. It never fabricates plausible-sounding compliance language to fill a gap.
- **Optional `STACK.md`**: a career/portfolio record of what was actually used, when, and why — for resume bullets and interview prep, distinct in audience and lifecycle from the other docs. Every non-trivial entry has to state why that choice over the alternatives (inline, or cross-referenced to DECISIONS.md), not just name a technology.

Each piece above is also an independently invocable skill (`/foundry-docs`, `/foundry-hooks`, `/foundry-security`, `/foundry-governance`, `/foundry-repo-hygiene`, `/foundry-stack`) — `/foundry-init` is a thin orchestrator over them, so you can run just one piece on an existing project instead of the whole sequence.

`/foundry-init` also asks upfront whether you want brief or detailed/educational explanations as it works — detailed mode states the reasoning behind each non-obvious step (most of which already lives in this repo's `docs/HOWS_AND_WHYS.md`), useful if you're newer to this kind of project setup; brief mode just does the thing. You can ask to switch at any point.

## Promptify

`/promptify <rough idea>` rewrites a rough task description into a clearer, more effective prompt and explains what changed and why — meant to be educational, not a black box. `/promptify! <rough idea>` does the same rewrite and immediately proceeds to execute it, for routine patterns you've already learned to trust. Bare `/promptify` with no content switches to a guided build-from-scratch mode — useful when you don't have a rough idea typed yet: it asks what you want to accomplish, then batches the remaining structural questions (role, scope, output format, etc.) into one round of questions before producing the prompt, rather than going back and forth one question at a time. (This batching is genuinely fewer turns than the conversational alternative, but it's not free — every question and answer is still a normal turn with real context cost, same as any other exchange.) Promptify is a fully standalone skill; Foundry just makes sure new projects know it exists.

## Install

```bash
git clone <this-repo-url> ~/Projects/foundry
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

- [ ] Proactive code-review agents (security-focused, quality-focused) wired via `PostToolUse` hooks — deliberately deferred out of the initial build to avoid scope creep; needs its own design pass (blocking vs. advisory, noise tuning, and which existing tools — e.g. a project's own `/code-review` or `/owasp-security`/security-review skills — to invoke rather than duplicate).
- [ ] Standalone fresh-context QC/adversarial-review skill, NOT Foundry-specific — formalizes the pattern used to find this repo's own pre-launch safety issues (spawn a subagent with zero prior context on a piece of work, instruct it to be explicitly skeptical and hunt for a specific class of problem, e.g. destructive actions or security gaps, and report only gaps rather than a full summary). Reusable on any project, any time, not tied to a scaffolding step — could live alongside Promptify as a referenced-not-owned tool in this repo, same pattern as Promptify itself. Same deferred category as the proactive-review-agents item above: needs its own design (what triggers it — on demand only, or also periodically; how findings get tracked so they aren't lost between sessions; how it avoids duplicating `/code-review`).
- [ ] Pluggable external skill-pack support (Claude Code's plugin/marketplace mechanism) for community-contributed additions — intentionally not bundling any specific named third-party pack until independently verified.
- [ ] Promptify prompt-shape library expansion and possibly splitting into its own standalone repo/tool.
- [ ] **"Promptify auto mode"** — a mode where any sufficiently complex/heavy prompt (as opposed to a simple question) is automatically run through `/promptify`'s rewrite step before being processed as a normal request, without the user having to type `/promptify` explicitly each time. Does NOT exist today — currently `/promptify`/`/promptify!` are always explicit, opt-in invocations; nothing auto-detects prompt complexity or intercepts a normal message. This is a real, distinct feature from the explicit-invocation modes already built, deliberately deferred rather than built opportunistically: it needs its own design for the hard part, which is reliably classifying "heavy" vs. "simple" without being either too aggressive (rewriting things that didn't need it, adding friction) or too conservative (missing genuinely complex requests). Likely mechanism: a `UserPromptSubmit` hook that runs a lightweight classification pass — but that design (what counts as "heavy," false-positive/negative tolerance, how to make it easy to override per-message) hasn't been done yet.
- [ ] Harden the SessionStart hook templates' shell substitution to use proper quoted arrays rather than bare word-splitting (`for f in {{DOC_FILES}}`) — currently safe only because the doc filenames are hardcoded (`CLAUDE.md`/`DECISIONS.md`/`SESSIONS.md`) and never contain spaces/shell metacharacters; flagged by an independent safety review as a latent issue if this is ever generalized to user-named files.
- [ ] `foundry-stack` should cross-check CLAUDE.md's REGULATORY CONTEXT/compliance section (if present) for confidentiality language before offering to set up career/portfolio tracking — currently relies entirely on the user remembering to connect those two things themselves. Flagged by an independent safety review.
- [ ] `foundry doctor` — an audit command for existing (non-Foundry-initialized) projects, checking which pieces are present/missing/stale without requiring a full re-init.
- [ ] `foundry-update` — a way to pull template/skill improvements into a project that was already scaffolded by an earlier version of Foundry, without a full re-init. Currently a scaffolded project is frozen at whatever Foundry looked like the day it ran `/foundry-init`.
- [ ] Persistent `statusLine` "Foundry: ✓" indicator (visible every turn, not just at session start) as an alternative/complement to the current SessionStart-only status message — deferred because it's a separate Claude Code mechanism (statusLine config) deserving its own design pass, and a toggle between the two needs its own settings surface.
- [ ] Multi-machine dismiss-state consistency: the per-project "skip Foundry" dismissal currently lives in committed `.claude/settings.json` (so it's consistent across clones), but if a future version moves any of this state into personal/gitignored `.claude/settings.local.json`, that would need its own per-machine consistency story. Not an issue today, worth remembering if that changes.
- [ ] Cross-project aggregation tool — pulls STACK.md (career data) and DECISIONS.md (decisions/lessons) from every Foundry project into one place. Deliberately not a per-project doc: the value isn't in concatenating entries side by side, it's in *synthesis* — surfacing that the same lesson (e.g. verify-before-trust) has independently proven itself correct across multiple unrelated projects, which a per-project doc structurally can't show. Same deferred category as the STACK.md cross-project master rollup — Foundry itself stays disciplined to one project at a time; this is a separate tool's job.

## License

MIT — see [LICENSE](LICENSE).
