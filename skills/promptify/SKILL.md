---
name: promptify
description: Rewrite a rough, informal task description into a clear, structured, effective prompt, with an explanation of what changed and why. Use when the user types /promptify followed by a rough idea, or /promptify! for the same rewrite applied immediately without a review step. Standalone skill — not specific to any one project type.
---

# promptify

Two entry points, same rewriting logic, different trust level:
- **`/promptify <rough idea>`** — rewrite, explain, wait for approval. Default and recommended mode.
- **`/promptify! <rough idea>`** — rewrite, then immediately proceed to execute the improved prompt in the same turn. Use only once the user has seen enough `/promptify` output from this kind of request to trust the rewrite without reviewing it first.

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

Keep the rewrite as short as it can be while still being unambiguous — a structured prompt that's 3x longer than necessary is its own failure mode.

## Step 4 — explain (always, even in `!` mode)

Accompany the rewritten prompt with a short explanation of what changed and why, e.g.:
- "Added explicit success criteria — the original didn't say how you'd know this was done."
- "Scoped this to the auth module specifically — the original could have been read as touching the whole app."
- "Separated the research question from the implementation ask — the original mixed 'figure out why X is slow' with 'fix it,' which are better done as two checkpoints."

This explanation is the point, not a courtesy — the user has said they want to learn the underlying patterns over time, not just get a black-box rewrite.

## Step 5a — `/promptify` mode: wait

Present the rewritten prompt + explanation. Ask whether to run it as-is, edit it, or get another pass. Do not act on it yet.

## Step 5b — `/promptify!` mode: proceed

Present the rewritten prompt + explanation (still — this is never skipped), then immediately continue as if the user had submitted that rewritten prompt as their actual message.

## Improving over time

If the user gives feedback on a rewrite (either direction — "that was too verbose" or "that was exactly right"), treat it the same way any standing feedback would be treated: it should inform future rewrites of similar-shaped requests, not just this one. If a durable pattern emerges (e.g. "for this user, debugging prompts should always include 'what have you already ruled out'"), that's worth persisting as a preference, not re-deriving each time — using whatever cross-session memory mechanism is available (e.g. Claude Code's memory system), scoped as a general user preference about prompt style, not as project-specific content. Be deliberate about scope: a preference about *how the user likes prompts structured* is reasonably general and safe to apply across projects; anything that's actually specific to one project's domain or conventions should stay local to that project (e.g. in its own CLAUDE.md) rather than being written to global/cross-project memory, where it would leak into unrelated future work.

## Standalone use

This skill has no dependency on Foundry's other skills and works in any project. Foundry's `foundry-init` mentions its availability but does not call it automatically — promptify is opt-in per use, not part of the scaffolding sequence.
