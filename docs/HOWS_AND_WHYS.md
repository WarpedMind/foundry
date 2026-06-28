# How and why

This document explains, for each piece of Foundry, the specific failure it prevents — not just what it does. The goal is for someone using Foundry (including future-you) to understand *why* the scaffolding looks the way it does, well enough to extend it correctly or know when to deviate.

## Why three separate files (CLAUDE.md, DECISIONS.md, SESSIONS.md) instead of one

Each answers a different question, and mixing them makes all three worse at their job:

- **CLAUDE.md** answers "what is true about this project right now" — current architecture, current status, current rules. It should always be readable as a snapshot, not a history.
- **DECISIONS.md** answers "why did we choose X over Y" — a log of reasoning that stays useful long after the decision is old news, specifically because it's *not* mixed into the current-state file (which would otherwise accumulate stale justifications nobody re-reads).
- **SESSIONS.md** answers "what happened, in order" — a narrative log of work sessions, useful for picking up cold after time away, distinct from both the snapshot and the decision log.

A single combined file tends to degrade into a single most-recently-edited section getting attention while everything else goes stale, because there's no structural separation forcing "this is current state" apart from "this is history."

## Why a SessionStart hook instead of just writing "remember to read these three files"

This is not a hypothetical concern — it happened. In a real session, the standing instruction was explicit: "read CLAUDE.md, DECISIONS.md, and SESSIONS.md at the start of every session." Two of the three files were pasted directly into the prompt; the third (DECISIONS.md) was not. The assistant proceeded to work without reading it, despite the explicit, unambiguous instruction to do so.

The mechanism behind this failure is worth understanding, not just the fact of it: when part of an instruction is satisfied by what's *visibly* in front of the model in a given turn, the unsatisfied part doesn't raise an error — it just silently doesn't happen. There's no failure signal. A written rule that depends on the assistant noticing its own gap, every session, indefinitely, will eventually get missed — not because the assistant is careless on average, but because nothing forces the check.

A `SessionStart` hook converts "the assistant should remember to read X" into "the harness reads X automatically, every time, regardless of what's already in the prompt." This is strictly more reliable, because it doesn't depend on anyone — human or AI — remembering anything in the moment.

## Why a questionnaire instead of named presets

An earlier draft of this idea considered named presets — "base," "advanced," "mobile," "regulated-mobile-advanced." The problem: these dimensions (regulatory load, platform, team size, project complexity) are mostly independent of each other, and naming their combinations produces a combinatorial explosion of presets that nobody can remember the contents of six months later. "Why does the `advanced` preset include a compliance section?" is a question a preset name can't answer; a questionnaire answer ("yes, this project handles money") can.

The one exception — a single "minimal" fast-path, skipped straight to from a yes/no question rather than reached via the full questionnaire — exists because a large fraction of real projects (personal scripts, weekend experiments) genuinely don't need any of the optional sections, and forcing them through seven questions to arrive at "none of the above" is friction with no payoff.

## Why composable skills instead of one big script

`/foundry-init` calling smaller skills (`/foundry-docs`, `/foundry-hooks`, `/foundry-security`, `/foundry-governance`, `/foundry-repo-hygiene`) rather than doing everything inline means each piece is independently useful later. A project that already has CLAUDE.md/DECISIONS.md/SESSIONS.md from some other process but wants the SessionStart hook can run `/foundry-hooks` alone. A project that didn't think about secrets at the start but now handles an API key can run `/foundry-security` alone, after the fact. A monolithic script forecloses this — it's all-or-nothing, every time.

It also makes each piece independently verifiable: during Foundry's own build, each skill's logic was tested in isolation (a rendered `.gitignore` merge checked for idempotency, a hook's command piped synthetic stdin and checked for valid JSON output, a secrets-detection pattern tested against a scratch git repo with a real staged `.env` file) before being wired into the orchestrator. A monolith makes this kind of isolated testing much harder.

## Why verify-before-trust is a default rule baked into the template, not just a one-off lesson

A real example, from the same session that motivated the SessionStart hook: a bot's Kalshi market-data fetch returned zero usable markets. The first fix (a wrong field name, missing pagination) looked correct — tests passed locally. Deployed live, it still returned zero markets — the unfiltered API response turned out to be dominated by over 12,000 consecutive irrelevant results before any usable one, a fact that wasn't in the obvious documentation and had to be found by directly querying the live API. The fix for *that* (a documented filter parameter) also looked complete — but deploying it revealed a third, deeper bug: the code's assumption about the live data format itself was wrong, silently dropping every message before any log line could reveal the problem. That bug was only resolved by capturing real live traffic and reasoning from the actual bytes on the wire, because the official documentation was itself ambiguous on the two questions that mattered.

Three "looks fixed" checkpoints in a row, each insufficient, in a single bug. The lesson generalizes: local tests verify your code against your own assumptions about the world; they cannot catch a wrong assumption. Documentation can be incomplete, stale, or genuinely ambiguous on the question that matters most. A task brief or third-party claim can simply be wrong. None of these are caught by "it compiles" or "the test suite is green" — only by checking the actual external behavior, ideally live, before trusting a fix is complete.

This is why Foundry's generated CLAUDE.md always includes this as a standing rule, not something the user has to remember to add.

## Why promptify is a separate skill, not embedded in foundry-init

Promptify (rewriting a rough task description into a clearer one) is useful in literally any project, at any time, independent of whether that project ever runs `/foundry-init` at all. Embedding it inside the scaffolding flow would make it harder to extract later (e.g. if it becomes its own standalone tool, as planned) and would imply a dependency on Foundry that doesn't actually exist. Foundry references it — tells new projects it's available — without owning it.

## Why governance/compliance sections default to "not yet researched" instead of plausible-sounding text

Generic compliance language that sounds right but isn't specifically verified is worse than an honest gap, because it creates false confidence that nobody thinks to double-check later. A section that says "GDPR Compliant ✓" with no specifics behind it will be believed by a future reader exactly as much as a section that says "this is real" — the difference only shows up when it matters, which is too late. An honest placeholder that says "not yet researched, get this reviewed" can't be mistaken for a verified guarantee. Foundry's governance skill is built to fail loud (an obvious, marked gap) rather than fail quiet (confident-sounding text nobody questions).
