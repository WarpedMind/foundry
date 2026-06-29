---
name: promptify
description: Rewrite a rough, informal task description into a clear, structured, effective prompt, with an explanation of what changed and why. Use when the user types /promptify followed by a rough idea, /promptify! for the same rewrite applied immediately without a review step, or bare /promptify with no content for a guided build-from-scratch mode. Standalone skill — not specific to any one project type.
---

# promptify

Three entry points:
- **`/promptify <rough idea>`** — rewrite an existing rough idea, explain, wait for approval. Default and recommended mode. Covered by Steps 1-5 below.
- **`/promptify! <rough idea>`** — same rewrite, then immediately proceed to execute the improved prompt in the same turn. Use only once the user has seen enough `/promptify` output from this kind of request to trust the rewrite without reviewing it first.
- **`/promptify` with no content** — guided build-from-scratch mode, for when the user doesn't have a rough idea typed yet and wants to construct the prompt collaboratively instead of writing one alone and rewriting it after. See "Build-from-scratch mode" below, before Step 1 — this is a different flow, not a variant of the rewrite steps.

## Build-from-scratch mode (`/promptify` with no arguments)

This exists specifically to reduce the number of conversational round trips needed to build a prompt collaboratively — batching the structural questions into one call instead of asking them one at a time. This is *relatively* cheaper than the fully-conversational alternative it replaces (fewer total turns), not free or context-neutral in absolute terms — every skill invocation (which loads this entire file into context), every question, and every answer is still a normal turn consuming real context, the same as any other exchange. The savings is in turn count, not in some special low-cost mechanism.

**Step A — ask the genuinely open-ended question as plain text, not via `AskUserQuestion`.** `AskUserQuestion` requires 2-4 concrete options per question and cannot represent a true free-text answer — forcing "what do you want this to accomplish?" into that format would mean inventing arbitrary placeholder options for a question that has none. Ask in a normal message: "What do you want this prompt to accomplish? Describe the goal in your own words." Wait for the answer before continuing — this is the one genuinely sequential step, since everything else depends on knowing the goal first.

**Step B — once the goal is known, batch the remaining structural questions into a single `AskUserQuestion` call** (up to 4 questions per call; if more than 4 are relevant, prioritize the ones that matter most for this specific goal rather than asking all of them every time). Candidate questions, chosen based on what's actually relevant to the stated goal — don't ask all of these every time, only the ones that matter for this request:
- Should I take on a specific role/persona for this? (e.g. "skeptical senior reviewer," "explain to a beginner," or "no, not needed")
- Is there anything else you want bundled into this same prompt, so it's one request instead of several follow-ups?
- Does the order of what you described match what you actually want done first, or should something be reprioritized?
- What should the output look like — prose explanation, code, a diff, a structured list/table, or something else?
- (For implementation/debugging-shaped goals) Anything already ruled out, or specific files/areas to focus on or avoid?

Always include real, meaningful options per question (not filler) — the user can also answer via `AskUserQuestion`'s built-in "Other" mechanism for anything that doesn't fit the given choices, which is preferable to them typing a full free-text tangent, since picking "Other" with a short note is cheaper than a new back-and-forth turn.

**Step C — build the prompt from the goal (Step A) + answers (Step B)**, applying the same structural-elements judgment as Step 3 of the rewrite flow below (goal/success criteria, scope, context, role only if warranted, domain-risk-flagging if relevant, verification expectation, etc.) — this is the same quality bar, just assembled from direct answers instead of inferred from a rough rewrite.

**Step D — present + explain, same as Step 4 below, then wait for approval like the no-bang rewrite mode** (build-from-scratch mode has no `!` variant — if the user wants instant execution, they already have enough of a prompt in mind to use `/promptify!` with content instead).

## Step 1 — classify the request shape

Before rewriting, identify which shape the rough input is closest to (don't ask the user to pick — infer from content, ask only if genuinely ambiguous between two shapes):
- **Research question** — wants information/analysis, no code changes.
- **Implementation task** — wants code written/changed.
- **Debugging investigation** — something is broken, wants root cause + fix.
- **Architecture/design decision** — wants a recommendation between approaches, not immediate execution.
- **Writing/communication task** — wants prose (docs, messages, summaries) produced.

This classification determines which structural elements matter most in the rewrite (e.g. an implementation task needs explicit scope/file boundaries; a debugging investigation needs explicit reproduction steps and what's already been ruled out; a research question needs explicit "what would change my answer" criteria).

## Step 2 — ask clarifying questions if needed

If the rough input is missing something load-bearing for that shape — e.g. an implementation task with no mention of which files/area of the codebase, or a debugging task with no symptom description — ask via `AskUserQuestion` before rewriting. Don't guess at specifics that materially change the prompt's meaning (e.g. don't assume which file "the bug" is in). Do proceed without asking for things that are genuinely minor or that the rewrite can mark as an open assumption instead.

## Step 3 — rewrite

Produce a structured prompt appropriate to the classified shape. General structural elements to apply (not all apply to every shape):
- Explicit goal/success criteria — what does "done" look like.
- Explicit scope — what's in bounds, what's explicitly out of bounds (prevents scope creep in either direction).
- Relevant context the rewrite surfaces from the conversation/repo that the rough version left implicit.
- For implementation/debugging: named files or areas if known, or an explicit instruction to locate them first if not.
- Verification expectation — how the requester (or the assistant) will know the result is correct, not just "looks done."
- **Role/persona framing, only when it changes the quality of the response** — e.g. "review this as a skeptical senior engineer" for an architecture decision, or "explain as if to someone who's never seen this codebase" for a writing/communication task. Skip this for shapes where it adds nothing (most debugging/implementation tasks don't benefit from a persona — the model already knows it's debugging).
- **Domain-aware risk flagging, when the request touches a sensitive area** — if the rough input involves auth, payments, credentials/secrets, data deletion, or other code where a quick fix could introduce a security or correctness regression, add an explicit guardrail naming the specific risk (e.g. "don't modify session-secret or password-hashing logic without flagging it first" for a login bug) rather than leaving this to the assistant to notice unprompted. Infer the relevant domain from the request's content — don't ask the user to classify it themselves.
- **Hypothesis enumeration for debugging tasks specifically** — when a bug could plausibly have multiple distinct root causes, ask for them to be enumerated and ruled out (or ruled in) before committing to a fix, rather than letting the first plausible cause become the fix path by default.
- **Existing test/verification infrastructure** — for implementation/debugging tasks, ask whether to run the existing test suite and/or add a regression test for this specific case, rather than leaving "verification expectation" purely behavioral with no mention of what's already in place to check it.
- **Model/effort suggestion, as a one-line recommendation, not an automatic switch.** Claude Code has no mechanism for a skill to dynamically change the active model or thinking effort mid-conversation per-request — this is a suggestion the user can act on (via `/model` or their own judgment), not something Promptify does for them. Base the suggestion on the same shape/complexity classification already used for the rest of the rewrite: a simple, well-defined, low-ambiguity task (e.g. a single clear lookup, a small mechanical edit) → suggest a smaller/faster model (e.g. Haiku) is likely sufficient; a multi-file architectural decision, a debugging investigation with several plausible root causes, or anything genuinely ambiguous or high-stakes → suggest a larger model (e.g. Opus) or higher thinking effort. Routine, moderate-complexity tasks need no suggestion at all — only add this line when the task is clearly toward one end of the spectrum, not for every rewrite (same anti-padding discipline as the rest of this skill). Name the actual model/effort level and give a one-line reason, e.g. "This is a single, well-defined lookup — Haiku would likely be sufficient and cheaper" or "This touches several files with no clear single cause yet — consider Opus or higher thinking effort." If the project's CLAUDE.md or session context already states a model preference, don't contradict it without saying so explicitly.

Keep the rewrite as short as it can be while still being unambiguous — a structured prompt that's 3x longer than necessary is its own failure mode. Not every element above applies to every request — apply judgment about which actually improve this specific prompt rather than mechanically including all of them every time, which would reintroduce the "3x longer than necessary" failure mode this rule already warns against.

## Step 4 — explain (always, even in `!` mode)

Accompany the rewritten prompt with a short explanation of what changed and why, e.g.:
- "Added explicit success criteria — the original didn't say how you'd know this was done."
- "Scoped this to the auth module specifically — the original could have been read as touching the whole app."
- "Separated the research question from the implementation ask — the original mixed 'figure out why X is slow' with 'fix it,' which are better done as two checkpoints."
- "This is a simple, well-scoped lookup — Haiku would likely handle it fine and save cost, if you want to switch."

This explanation is the point, not a courtesy — the user has said they want to learn the underlying patterns over time, not just get a black-box rewrite.

## Step 5a — `/promptify` mode: wait

Present the rewritten prompt + explanation. Ask whether to run it as-is, edit it, or get another pass. Do not act on it yet.

## Step 5b — `/promptify!` mode: proceed

Present the rewritten prompt + explanation (still — this is never skipped), then immediately continue as if the user had submitted that rewritten prompt as their actual message.

## Improving over time

If the user gives feedback on a rewrite (either direction — "that was too verbose" or "that was exactly right"), treat it the same way any standing feedback would be treated: it should inform future rewrites of similar-shaped requests, not just this one. If a durable pattern emerges (e.g. "for this user, debugging prompts should always include 'what have you already ruled out'"), that's worth persisting as a preference, not re-deriving each time — using whatever cross-session memory mechanism is available (e.g. Claude Code's memory system), scoped as a general user preference about prompt style, not as project-specific content. Be deliberate about scope: a preference about *how the user likes prompts structured* is reasonably general and safe to apply across projects; anything that's actually specific to one project's domain or conventions should stay local to that project (e.g. in its own CLAUDE.md) rather than being written to global/cross-project memory, where it would leak into unrelated future work.

## Standalone use

This skill has no dependency on Foundry's other skills and works in any project. Foundry's `foundry-init` mentions its availability but does not call it automatically — promptify is opt-in per use, not part of the scaffolding sequence.
