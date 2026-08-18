---
name: oneshot
description: Front-load every clarifying question a non-trivial task needs into a single batched AskUserQuestion call (or the fewest calls possible) instead of asking one at a time across multiple turns. Use whenever a request has real ambiguity, several open decisions, or would benefit from upfront scoping before real work begins — proactively, not just when the user asks for it by name.
---

# oneshot

The pattern: don't dribble out clarifying questions one per turn. Figure out everything genuinely unclear about a request up front, then resolve as much of it as possible in one round-trip.

## Why this exists

Every unresolved ambiguity that surfaces mid-task costs a full round trip and risks work done on a wrong assumption having to be redone. Picking from options is also cheaper for the user than composing free-text answers. This skill formalizes a pattern already proven out in practice (see `promptify`'s build-from-scratch mode, which uses the same two-step shape) as a general-purpose habit, not tied to prompt-writing specifically.

## The two mechanisms aren't equally valuable

Front-loading (Step 2) is where the real savings live — a well-designed opening batch can prevent an entire deliverable from being built on a wrong assumption, which no amount of later course-correction fully recovers from. The closing-out convention (Step 5) is comparatively low-stakes: in a long conversation, several closing questions tend to collapse into near-identical variations of "ready to proceed?", and each one costs a full round trip for very little in return. Spend real design thought on the opening batch's options; treat closing questions as lightweight. Don't re-ask one in substance — if the previous turn closed with essentially "ready to proceed?" and the user chose more work instead, the next closing question needs materially different options, not a rephrasing. Three consecutive closers that all reduce to "shall we start now?" is the filler-menu failure this skill exists to prevent, in its most common form.

## Step 1 — separate the genuinely open-ended question from the structural ones

If there's a real free-text question — "what do you actually want this to accomplish," a goal, a direction with no natural small set of options — ask that first, as plain text, not via `AskUserQuestion`. That tool requires 2-4 concrete options and cannot represent true open-ended input; forcing it would mean inventing arbitrary placeholder options for a question that has none. Wait for the answer before continuing, since everything else likely depends on knowing this first.

If there's no such open-ended question — the task is already well-scoped and every remaining unknown is a fork between a small number of real choices — skip straight to Step 2.

## Step 2 — batch every remaining clarifying/scoping question into one `AskUserQuestion` call

Once the shape of the task is known, identify every genuinely load-bearing unknown — something that would materially change what gets built or how — and ask all of them in a single `AskUserQuestion` call, up to 4 questions per call. Don't ask about things that are minor enough to proceed on a sensible default and just state the assumption instead.

For each question:
- Give 2-4 real, meaningful options — not filler choices that only exist to pad the list.
- Put the option you'd actually recommend first, and label it "(Recommended)" if there is a genuine default worth nudging toward.
- Trust the tool's built-in "Other" for anything that doesn't fit — that's cheaper for the user than a new back-and-forth turn, so don't try to enumerate every conceivable answer.
- Write every option's label and description so someone who hasn't read the surrounding turn could still understand it — options get scanned, not read closely, often out of context or after a gap. Don't rely on a term of art introduced earlier in the conversation landing correctly inside an option; either avoid it or re-gloss it in the same sentence. If a concept needs real explanation, put that in the prose above the question, not inside the option text — and if you can't compress it, that's a sign the user isn't ready to choose yet.

If more than 4 questions are genuinely relevant, prioritize the ones that most change the shape of the work and defer the rest — either fold them into a second batched round only if the first round's answers make them newly relevant, or note them as open assumptions in the eventual output rather than blocking on them.

## Step 3 — don't re-ask what's already decided

Once a question has been answered, don't circle back to it "just to confirm" unless a later discovery genuinely changes its premise (e.g., research turns up something that invalidates an earlier assumption — see the negative-branch discipline below). Re-litigating settled decisions costs the same round-trip this skill exists to avoid.

## Step 4 — proceed directly into the work

After the batched questions are answered, move straight into execution. Don't add another confirmation loop ("does this plan look right?") unless the answers themselves revealed a fork that genuinely couldn't have been anticipated before seeing them.

## Step 5 — close out the same way

When a piece of substantial work finishes and there's a natural next step, end the turn with an `AskUserQuestion` offering 2-4 concrete, specific next-step options rather than open-ended prose asking "what would you like to do next?" Picking costs fewer round-trips than composing. Every `AskUserQuestion` call automatically includes a built-in "Other" free-text option regardless of what options are listed — don't add a redundant explicit "something else" option, the mechanism already covers it.

**Delegation suppresses the closing question:** if the user has just delegated the decision outright ("proceed however you recommend," "your call," "you decide"), don't close by asking them to choose again — that hands back the exact decision they just handed you. State what you decided and why, do the work, and close with a lighter confirmation that reports what happened rather than a fresh menu; offer a genuine fork only if one now actually exists. And if a reply to a closing question doesn't map to any offered option, doesn't read as a directive, and doesn't engage with the question's subject at all, treat accidental submission (e.g. an errant Enter) as a live possibility — re-offer the question rather than guessing the closest match and proceeding on it; the cost of re-offering is one round trip, the cost of guessing wrong is the work that follows it.

**Anti-filler guard (default case):** don't manufacture a question when there's nothing real to ask. If a single small task is fully resolved and there's no meaningful fork in what happens next, a plain summary sentence is correct and a closing question would be padding. This mirrors the discipline already required of Foundry's other skills (e.g. `qc-review` must not invent a question when a review found nothing) — the goal is fewer round-trips overall, not a question appended to every message on principle.

**Continuous-session override:** if the user has set a standing expectation to keep working this way for a stretch of the conversation — e.g. "let's keep going like this until I say we're done," or the same intent in other words — that instruction overrides the anti-filler guard for the rest of that stretch. In that mode, don't let a turn end in silence just because there's no single obvious next step: close with a question offering the real forks available (continue deeper in the current direction, pivot to an adjacent open item, or wrap up) rather than a bare summary. The anti-filler guard still applies to *manufacturing fake options within that question* — the options offered should be genuinely different real paths, not padding — but the turn itself should still end with a question, not silence, until the user says otherwise.

## The negative branch

If a batched question's answer reveals that an earlier assumption (yours or an earlier answer) no longer holds, don't silently proceed on the stale assumption — surface it and ask again, scoped narrowly to just what changed. This is the one case where re-asking is correct: the alternative is producing work built on a premise the user never actually confirmed.

## Standalone use

This skill has no dependency on Foundry's other skills and works in any project or any Claude surface (Claude Code, Cowork, or elsewhere `AskUserQuestion` — or an equivalent structured-choice mechanism — is available). It codifies a way of working, not a domain-specific process.
