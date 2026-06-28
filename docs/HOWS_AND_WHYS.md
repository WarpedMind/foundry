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

## Why the context-checkpoint rule is framed around drift, not a fixed percentage

A common piece of advice circulating about long AI sessions is some version of "only use 40-50% of your context window, then start fresh." It's worth being precise about what that advice actually gets right and where it's a misconception, because Foundry's rule is deliberately framed differently.

What's true: as a conversation's context fills, the model has to attend to more material, and at the limit the harness force-summarizes it (compaction), which loses detail. Clearing and re-anchoring on durable state (files, not conversation memory) at a natural boundary is a real, useful practice — this is exactly what the SessionStart hook is for, and Foundry's own build session used it deliberately once, at a real checkpoint (after a separate piece of work was verified and pushed).

What's a misconception: treating it as a fixed percentage target, or as something specific to "chat" interfaces as opposed to Claude Code. The actual mechanism doesn't care about a number — it cares about *whether a fresh start would re-anchor on something better than what's accumulated in conversation so far*. A short, single-purpose session can run to 90% of its context productively, because there's no drift to escape. A session that has sprawled across several unrelated subtasks can be worth clearing at 20%, because the problem isn't context volume, it's accumulated unrelated context competing for relevance.

This is why the rule Foundry writes into every project's CLAUDE.md is framed around recognizing scope sprawl and session length in *subtasks*, not a context-percentage number: "if this session has covered several unrelated subtasks, or has run long, proactively suggest a checkpoint." A number is precise-sounding but measures the wrong thing; the actual signal is whether the conversation has drifted, not how full it is.

## Why a "tested" claim in a SKILL.md is worthless without a real adversarial fixture

The original secrets-guard commit hook (`foundry-hooks` Hook 2) shipped with a regex and a sentence claiming it was "tested against a scratch repo: blocks when `.env` is staged, allows when only safe files are staged." That sentence was true. It was also nearly useless, because the only thing it verified was the single most obvious case — and the regex it described missed `secrets.env`, `.env.production.local`, `config.yaml.bak`, and `real.key.txt`, all realistic filenames that any real project might actually use. This was caught by an independent reviewer (a fresh subagent with no context on the build), who didn't just read the regex and reason about it — they actually staged those files in a scratch repo and ran the exact command, and reported back the literal output.

The lesson generalizes past this one hook: a prose claim of "verified" or "tested" tells a reader nothing about *what* was tested. If the test only covers the one case someone happened to think of while writing the code, "tested" is doing the same epistemic work as "trust me." The fix that was actually applied here required building an adversarial fixture set deliberately — filenames designed to break the regex in both directions (real secrets with extra suffixes/prefixes that should be caught; legitimate files containing "key" or "secret" as an innocent substring, like `secretary_notes.txt` or `the_keymaster.rb`, that should NOT be caught) — and running the actual command against all of them, not reasoning about it abstractly. The `.gitignore` baseline fix needed a second, separate round of this same process, because gitignore's glob syntax can't do the same word-boundary trick regex can, so the regex fix's logic didn't transfer directly — assuming it would have been its own quiet failure.

Foundry's own skill files now state explicitly what fixture set was used to verify a security-relevant pattern, specifically so a future maintainer can see what was actually checked rather than trusting the word "verified" on faith — the same problem this lesson is about, applied to itself.

## Why an independent reviewer with zero context found things two rounds of self-review missed

Before any code in this section was fixed, this same builder did a deliberate, careful self-review pass — re-reading every skill specifically hunting for destructive actions — and still missed several real things that a fresh subagent caught minutes later: a second instance of the regex-pattern gap (in the `.gitignore` baseline, not just the commit hook), a lossy-migration risk hiding inside an already-safe-looking "ask the user first" flow, an ambiguous cross-reference between two skills that could cause one of them to run a step twice or skip it, and a missing recovery mechanism for a project that outgrew its original "throwaway" classification.

None of these were exotic. All of them were findable by careful reading. The reason a second pass by the same person/instance is structurally worse at finding them than a fresh reviewer is not about skill — it's about familiarity. By the time you've built something, you've already mentally resolved every ambiguity in the direction you intended, so re-reading your own instructions tends to confirm what you meant rather than surface what they could be misread to mean. A reviewer with no investment in the existing design, explicitly told to be skeptical and hunt for the worst case, doesn't have that resolved-ambiguity blind spot — they read the literal words, not the intent behind them.

This is the same principle behind the "oversight instance" pattern discussed earlier in this project's history (a second model instance reviewing work with no stake in how it was built) — just applied here to a security review specifically, where the cost of a missed finding is highest.
