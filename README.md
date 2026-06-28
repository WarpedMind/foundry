# Foundry

Foundry scaffolds software projects with the documentation structure, hooks, and guardrails that make AI-assisted development reliable across many sessions — derived from a short questionnaire per project, not a fixed one-size-fits-all template.

Part of **Preamble** — where you forge the foundation of how you work with AI.

## What it does

`/foundry-init` asks a handful of questions about your project — does it handle secrets? other people's data or money? is it regulated? solo or team? — and scaffolds exactly what's relevant, nothing more:

- **`CLAUDE.md`, `DECISIONS.md`, `SESSIONS.md`** — a fixed core structure every Foundry project shares, with optional sections (Security Rules, Regulatory Context, Compliance/Audit Trail) added only when the questionnaire says they're actually relevant. A 10-line personal script gets 3 lines of CLAUDE.md, not a compliance checklist.
- **A `SessionStart` hook** that loads those docs into context automatically at the start of every session — not dependent on the assistant remembering to ask, because that dependency has already failed in practice (see [`docs/HOWS_AND_WHYS.md`](docs/HOWS_AND_WHYS.md)).
- **A `.gitignore` baseline and secrets-guard pre-commit hook**, only for projects that actually handle credentials.
- **Repo hygiene**: correct sequencing for a brand-new repo (`.gitignore` before the first commit, not after) and a standing discipline for keeping README/SESSIONS.md honest as the project changes.
- **Honest governance scaffolding**: when a project is flagged as regulated, Foundry writes either real, project-specific regulatory context, or an explicit "not yet researched — get this reviewed before relying on it" placeholder. It never fabricates plausible-sounding compliance language to fill a gap.

Each piece above is also an independently invocable skill (`/foundry-docs`, `/foundry-hooks`, `/foundry-security`, `/foundry-governance`, `/foundry-repo-hygiene`) — `/foundry-init` is a thin orchestrator over them, so you can run just one piece on an existing project instead of the whole sequence.

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

## License

Not yet decided — to be added before any public release/announcement.
