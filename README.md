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

`/promptify <rough idea>` rewrites a rough task description into a clearer, more effective prompt and explains what changed and why — meant to be educational, not a black box. `/promptify! <rough idea>` does the same rewrite and immediately proceeds to execute it, for routine patterns you've already learned to trust. Promptify is a fully standalone skill; Foundry just makes sure new projects know it exists.

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

## Design principles

- **Derive, don't preset.** No `--preset=advanced-mobile-regulated`. A short questionnaire derives which optional pieces apply — except a single "minimal" fast-path for throwaway scripts, which skips the questionnaire entirely.
- **Composable over monolithic.** Every piece foundry-init calls is independently useful and independently invocable later.
- **Mechanism over reminder.** If something needs to always happen, it's a hook the harness enforces — not a written rule that depends on an AI session remembering it. (This rule exists because that exact failure happened — see HOWS_AND_WHYS.md.)
- **Verify, don't assume.** Every hook and template in this repo was tested against real input before being trusted — pipe-tested commands, rendered template diffs checked by hand, an actual end-to-end run comparing two real scenarios. The same standard applies to what Foundry-generated projects should do with their own external dependencies and claims.

See [`docs/HOWS_AND_WHYS.md`](docs/HOWS_AND_WHYS.md) for the reasoning behind each of these, with real examples.

## Roadmap

- [ ] Proactive code-review agents (security-focused, quality-focused) wired via `PostToolUse` hooks — deliberately deferred out of the initial build to avoid scope creep; needs its own design pass (blocking vs. advisory, noise tuning, and which existing tools — e.g. a project's own `/code-review` or `/owasp-security`/security-review skills — to invoke rather than duplicate).
- [ ] Pluggable external skill-pack support (Claude Code's plugin/marketplace mechanism) for community-contributed additions — intentionally not bundling any specific named third-party pack until independently verified.
- [ ] Promptify prompt-shape library expansion and possibly splitting into its own standalone repo/tool.
- [ ] `foundry doctor` — an audit command for existing (non-Foundry-initialized) projects, checking which pieces are present/missing/stale without requiring a full re-init.
- [ ] `foundry-update` — a way to pull template/skill improvements into a project that was already scaffolded by an earlier version of Foundry, without a full re-init. Currently a scaffolded project is frozen at whatever Foundry looked like the day it ran `/foundry-init`.
- [ ] Persistent `statusLine` "Foundry: ✓" indicator (visible every turn, not just at session start) as an alternative/complement to the current SessionStart-only status message — deferred because it's a separate Claude Code mechanism (statusLine config) deserving its own design pass, and a toggle between the two needs its own settings surface.
- [ ] Multi-machine dismiss-state consistency: the per-project "skip Foundry" dismissal currently lives in committed `.claude/settings.json` (so it's consistent across clones), but if a future version moves any of this state into personal/gitignored `.claude/settings.local.json`, that would need its own per-machine consistency story. Not an issue today, worth remembering if that changes.
- [ ] Cross-project aggregation tool — pulls STACK.md (career data) and DECISIONS.md (decisions/lessons) from every Foundry project into one place. Deliberately not a per-project doc: the value isn't in concatenating entries side by side, it's in *synthesis* — surfacing that the same lesson (e.g. verify-before-trust) has independently proven itself correct across multiple unrelated projects, which a per-project doc structurally can't show. Same deferred category as the STACK.md cross-project master rollup — Foundry itself stays disciplined to one project at a time; this is a separate tool's job.

## License

MIT — see [LICENSE](LICENSE).
