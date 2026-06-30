# Contributing to Foundry

Foundry is a set of Claude Code skills (Markdown `SKILL.md` files), not compiled code — most "development" here is editing prose/bash inside a skill file and re-verifying it actually does what it claims.

## Setup

1. Fork and clone the repo.
2. Run `./install.sh` to symlink `skills/*` into `~/.claude/skills/` so the skills you're editing are live in any project on your machine.
3. Test changes against a disposable scratch directory (`mkdir /tmp/foundry-scratch && cd /tmp/foundry-scratch`), not against a real project — several skills write files and `.claude/settings.json` hooks, and you want to be able to throw the result away.

## Before opening a PR

- **If you touched the secrets-guard hook or `.gitignore` baseline regex** (`skills/foundry-hooks/SKILL.md` Hook 2, or `skills/foundry-security/SKILL.md` step 1): add a case to the relevant file in `tests/fixtures/` and run `./tests/run_fixtures.sh`. Both directions matter — a case that should be caught, and a similarly-named case that should NOT be (false positives block legitimate commits, false negatives let secrets through). This isn't optional ceremony: this exact suite has already caught one real regex gap (`config/prod.yaml` slipping past an earlier version of the pattern) that a single manual test case had missed.
- **If you touched any hook** (anything under `hooks.*` in a generated `.claude/settings.json`): pipe-test the raw command with synthetic stdin before trusting it (e.g. `echo '{}' | bash -c "<command>"`), and validate the rendered JSON with `jq -e`. The methodology is documented inline in `skills/foundry-hooks/SKILL.md` — follow the same steps for any new or modified hook.
- **If you added or changed a skill**, update `CLAUDE.md`'s Architecture section in the same change — this repo holds itself to its own rule of not letting that doc drift from reality.
- **If you changed something the README or USER_GUIDE.md describes**, update those in the same PR. Don't leave user-facing docs describing behavior that no longer matches the code.
- **Don't fabricate "tested" claims.** If you can't verify something (e.g. a hook event whose exact stdin payload isn't documented), say so plainly in the skill file rather than asserting it was verified. This repo has a standing rule against inventing plausible-sounding claims to fill a gap — see `skills/foundry-governance/SKILL.md`'s anti-fabrication rule for the same principle applied elsewhere.

## Running the test suite

```bash
./tests/run_fixtures.sh
```

This re-runs five adversarial fixture suites: the `.gitignore` baseline and secrets-guard pre-commit regex (case lists in `tests/fixtures/`), Hook 4's directory-drift detection, Hook 3's status/offer logic, and the Hook 1/3 SessionStart merge guard (the latter three as inline cases in the script itself, since they parse structured input rather than matching a static filename against a pattern). It's also run automatically on every push/PR via `.github/workflows/fixtures.yml`. Prose-only skills (`foundry-governance`, `foundry-stack`, `foundry-repo-hygiene`'s sequencing) have no mechanical command to test this way and are still verified by direct invocation against a scratch directory or by re-reading the applied instruction text for internal consistency (see each skill's own `SKILL.md` for its specific verification steps).

## What Foundry deliberately does NOT do

Before proposing a feature, check `README.md`'s Roadmap section and `USER_GUIDE.md`'s "What Foundry does NOT do" section — several gaps (content-based secret scanning, a persistent statusline indicator, proactive review agents) are known and intentionally deferred, not overlooked. A PR that closes one of these is welcome; a PR that silently routes around a documented limitation without updating the docs is not.

## Questions / proposing a larger change

For anything bigger than a small fix (a new skill, a change to the questionnaire flow, a new hook), open an issue first to discuss the approach before investing time in an implementation — this mirrors Foundry's own standing rule of getting sign-off before non-trivial work rather than building first and asking later.
