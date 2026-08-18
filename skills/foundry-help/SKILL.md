---
name: foundry-help
description: On-demand explainer for what Foundry is, what each skill does, and when to reach for which. Use when the user types /foundry-help, asks "what is Foundry," "what does this project do," "which /foundry-* command do I need," or otherwise seems unsure what's available. Deliberately never triggered automatically at session start — see the skill body for why. Standalone — works whether or not the project is Foundry-scaffolded.
---

# foundry-help

An on-demand reference. Explains what Foundry is, what each skill does, and which one to reach for — nothing more. Not a sales pitch, not a tutorial, not a substitute for reading a specific skill's own `SKILL.md` when the user actually needs that skill's detail.

## Why this is on-demand only, never an automatic banner

Two things about this project already settle this, deliberately, before this skill existed:

1. **Hook 3 (the status/offer hook, `skills/foundry-hooks/SKILL.md`) already owns the SessionStart slot.** Its three-state design — scaffolded (silent "Active" confirmation), dismissed (completely silent), neither (a one-line offer to run `/foundry-init`) — exists specifically to avoid nagging (DECISIONS.md, 2026-06-28: "a binary doesn't handle the real cases... three states cover the actual decision space without being presumptuous in someone else's repo or annoying in your own"). A second automatic message competing for the same moment would reintroduce exactly the noise that decision rejected — either duplicating Hook 3's offer or drowning it out.
2. **Session 20 established that the VSCode extension's chat panel has no documented UI element for rendering a SessionStart hook's `additionalContext` as visible text** — no banner, message bubble, or icon (confirmed against Claude Code's own docs/changelog, not assumed; see SESSIONS.md's Session 20 entry and USER_GUIDE.md's platform notes). The terminal/CLI happens to render this as visible transcript text; VSCode does not, silently. An automatic explainer wired the same way Hook 3 is would be invisible in exactly the interface where a new user — the one who most needs "what is this project" explained — is likeliest to be working.

An on-demand command has neither problem: it only runs when explicitly invoked, so there's no nagging to guard against, and its output is a normal assistant response (not hook `additionalContext`), so it renders as visible text on every platform, including VSCode. This is the same reasoning `qc-review` and `foundry-audit` already apply to themselves — on-demand plus an optional proactive *offer*, never a forced automatic action — extended to the one gap neither of those covers: a user who doesn't yet know Foundry has commands at all.

## What Foundry is

One paragraph, not the full CLAUDE.md "What this is" section — point there for more:

Foundry scaffolds software projects with the documentation structure (CLAUDE.md/DECISIONS.md/SESSIONS.md), hooks, and guardrails that make AI-assisted development reliable across many sessions — derived from a short per-project questionnaire (`/foundry-init`) rather than a fixed template. It's part of the "Preamble" brand: Preamble is the umbrella, Foundry is this tool, Promptify is a separate related tool that also lives in this repo.

## The skills, and when to reach for each

Read each skill's own `SKILL.md` for the full detail — this is a map, not a replacement.

**Getting started**
- **`/foundry-init`** — the orchestrator. Run this first on a project that has nothing yet. Three paths: throwaway/script (minimal CLAUDE.md only), new real project (full questionnaire, calls everything below in sequence), or existing project (pick specific pieces to retrofit without redoing the whole sequence). If unsure where to start, start here.

**What `foundry-init` calls, in sequence (each also works standalone)**
- **`foundry-docs`** — writes CLAUDE.md/DECISIONS.md/SESSIONS.md from Foundry's templates, or safely merges into versions that already exist without losing real content.
- **`foundry-hooks`** — wires the SessionStart doc-loader (Hook 1), the status/offer hook (Hook 3), the secrets-guard pre-commit check (Hook 2, only if the project handles secrets), the directory-drift logger (Hook 4, optional), and the push-time `qc-review` offer (Hook 5, optional) into `.claude/settings.json`.
- **`foundry-security`** — `.gitignore` baseline, `.env.example` convention, and a check for secrets already committed. Only relevant if the project handles credentials.
- **`foundry-repo-hygiene`** — correct commit sequencing for a brand-new repo's first commit, plus a standing discipline for keeping README/SESSIONS.md from drifting out of date as the project changes.
- **`foundry-governance`** — a real, project-specific REGULATORY CONTEXT section, with an explicit anti-fabrication rule: states "not yet researched" rather than inventing plausible-sounding compliance language. Only invoked when a project is actually flagged as regulated or handling sensitive data/money — never for a generic project.
- **`foundry-stack`** — STACK.md, a career/portfolio record of what tech was actually used and why, distinct from CLAUDE.md/DECISIONS.md/SESSIONS.md (which serve the assistant's working context, not a human reader later).

**Standalone, not part of the default `foundry-init` sequence**
- **`/foundry-audit`** — mechanical, script-driven structural audit of a project's doc set: dangling decision references, a decision log out of its own stated order, broken file paths after a rename, unreachable docs, unclosed code fences, `Enforced at:` targets that don't exist. Deterministic — it cannot judge anything, and cannot find a bug in your code. Worth running before a release/handoff, after a rename or restructure, or when a session has made substantial doc changes.
- **`/qc-review`** — the opposite kind of check: an adversarial, fresh-context subagent review hunting specifically for destructive actions, security gaps, silent overwrites, and similar high-cost mistakes in *code*, not docs. Not a general code review (defer to `/code-review` for that, if present) — narrower and adversarial on purpose. Worth running before treating security-sensitive or destructive-capable work as finished.
- **`/promptify`** (or `/promptify!`, or bare `/promptify`) — rewrites a rough task description into a clear, structured prompt, with an explanation of what changed. Not project-scaffolding-specific; works on any prompt, in any project.
- **`oneshot`** — not a slash command by itself, but a standing convention this repo (and any Foundry-scaffolded project) follows: batch clarifying questions into one `AskUserQuestion` up front instead of asking one at a time, and close substantial turns with a batched next-step question instead of open prose.

**`foundry-audit` vs. `qc-review`, since these two get conflated:** `foundry-audit` reads documents and runs deterministic checks — mutation-tested, cannot find a security bug, cannot judge anything semantic. `qc-review` reads code and applies adversarial judgment via a fresh-context subagent — the opposite trade: it can find a real bug, but a clean result is inherently harder to verify than a script's. Neither replaces the other; see DECISIONS.md's 2026-08-17 entries if the full reasoning is wanted.

## Quick picks

- Nothing set up yet, starting fresh → `/foundry-init`
- Docs already exist by hand, want Foundry's structure without redoing everything → `/foundry-init`, choose the existing-project path
- Project handles secrets and you're not sure the `.gitignore`/secrets-guard is solid → `/foundry-security` (standalone) or re-run `tests/run_fixtures.sh` if you're inside this repo specifically
- Docs feel like they've drifted (renamed files, stale cross-references) → `/foundry-audit`
- About to call security-sensitive or destructive-capable work done → `/qc-review`
- Have a rough prompt idea and want it sharpened before running it → `/promptify`
- Not sure which of the above applies → describe what you're trying to do and ask; this skill can route you, it doesn't have to be self-service

## Closing out

End with an `AskUserQuestion` offering concrete next moves rather than leaving the explanation to trail off: run `/foundry-init` now, explain one specific skill from the list above in more depth, or stop here since the reference answered the question. Give 2-4 real options; `AskUserQuestion` supplies "Other" for anything else. If the user's original message already named a specific next action (e.g. "what does foundry-audit do" and nothing else), a full options menu is filler on top of an answer that already closed the loop — just answer and stop, per the standing anti-filler guidance.

No conditional `/qc-review` or `/foundry-audit` option attaches here, and that is a decision rather than an omission. This skill produces an explanation and changes no file, so its turn contains no edit for either command to examine — it may well read a `SKILL.md` to answer a follow-up, which creates nothing to review. Recommending them as *answers* is already handled by Quick picks above; repeating them in the closing menu would put them on screen every single invocation, which is the unconditional-offer failure every other closing section in this repo is written to avoid.
