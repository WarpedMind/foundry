---
name: qc-review
description: Run an adversarial, fresh-context quality/security review against recent changes, hunting specifically for destructive actions, security gaps, silent overwrites, and similar high-cost mistakes — not a general code review. Use when the user types /qc-review, when the user asks for a second opinion or adversarial check on risky work, or (proactively, as a suggestion, never silently) right before treating security-sensitive, destructive-capable, or hard-to-reverse work as finished. Standalone skill — not specific to any one project type.
---

# qc-review

This formalizes a pattern that already found real bugs once: spawning a subagent with zero prior context on a piece of work, telling it to be explicitly skeptical, and having it hunt for a specific class of problem rather than write a general-purpose review. The fresh-context property is the entire mechanism — a model with no investment in the code already being correct is structurally more willing to find fault in it than the same conversation that just wrote it.

**This is not `/code-review`.** `/code-review` (if present in this environment) is a general-purpose review. This skill exists for a narrower, adversarial purpose: actively hunting for the specific failure classes that are expensive to miss (destructive actions, security gaps, silent data loss, secrets handling, irreversible operations) — not style, not general correctness, not test coverage. If both exist in a project, don't duplicate `/code-review`'s job; defer to it for anything outside this narrower scope.

## Entry points

- **`/qc-review`** — review whatever changed in the current session (default scope, see below).
- **`/qc-review <description>`** — review a specific named scope instead (a file, a module, "the auth changes from last week," a design doc) — use this when the user wants something other than the session-diff default.
- **Proactive offer (not automatic execution)** — see "When to proactively offer" below.

## Step 1 — determine scope

Default scope, if the user didn't specify one: everything changed since the start of the current conversation/session, not since the last git commit. This matches the user's own mental model of "what we just did" — session work that's already been committed should still be in scope, and pre-existing uncommitted changes the session didn't touch should not be.

Concretely: track (or reconstruct from the conversation) which files were actually written/edited this session. If git is available and helps confirm this, `git diff` against the state at session start is a useful cross-check, but the session's own edit history is the source of truth, not git status, since not everything edited this session is necessarily the only thing uncommitted.

If the user gave an explicit scope instead (a file, a module, a description), use that verbatim — don't second-guess it down to a diff.

## Step 2 — determine review focus, with a chance to redirect

Infer the likely focus from what's actually in scope — same domain-inference judgment `promptify`'s risk-flagging already uses:
- Touches auth, sessions, password/credential handling → focus on credential exposure, auth bypass, session fixation
- Touches payments, billing → focus on amount/currency handling, idempotency, race conditions on money-moving operations
- Touches data deletion, destructive migrations, `rm`/`DROP`/force-push-style operations → focus on irreversibility, missing confirmation, blast radius
- Touches secrets/config files, `.gitignore`, anything that could leak credentials → focus on exactly what `foundry-security`'s own adversarial fixture testing already covers (does this actually catch realistic filenames, not just the obvious case)
- Touches a hook, a script with `PostToolUse`/`PreToolUse` triggers, or anything that runs automatically → focus on whether it could silently do the wrong thing, fire on unintended input, or block legitimate work
- General/unclear → default to a broader pass: silent overwrites of user content, missing confirmation before irreversible actions, secrets in logs/output, anything that contradicts this project's own CLAUDE.md Security Rules if present

State the inferred focus plainly before proceeding (e.g. "This touches auth — focusing on credential/session handling risks") and give a real chance to redirect or add to it, rather than silently locking it in. Don't turn this into a blocking question every time — a brief statement with an implicit "let me know if you want a different focus" is enough; only stop and ask outright if the scope is genuinely ambiguous between two very different risk classes.

## Step 3 — run the review as a fresh subagent with zero prior context

This is the load-bearing mechanism — do not run this review inline in the current conversation. Use the `Agent` tool (a `general-purpose` or `Explore`-type agent, whichever can read the relevant files) and write a self-contained prompt that:
- Names the specific scope (exact files/diff/description from Step 1) — the subagent has no access to this conversation's history, so it needs the scope spelled out in full, not referenced implicitly ("the changes we just discussed" means nothing to a fresh agent).
- States the focus area from Step 2 explicitly, and instructs it to actively hunt for that class of problem — not write a general summary of what the code does.
- Instructs it to report **only gaps/findings**, not a clean bill of health narrative — if it finds nothing, it should say that plainly and briefly, not pad the response. A real finding should name the exact file/line and the specific scenario that would trigger it, not a vague "consider reviewing this area" hedge.
- Instructs it to rate severity (e.g. CRITICAL/HIGH/MEDIUM/LOW) so findings can be triaged rather than treated as uniformly urgent — modeled directly on how Session 4's safety review was itself triaged in this repo's own DECISIONS.md.

## Step 4 — verify findings before trusting them, don't just relay them

Per Foundry's own standing verify-before-trust principle: a subagent's claim that something is broken is itself a claim, not yet a confirmed fact. Before writing anything to KNOWN DEBT (Step 5), spot-check at least the CRITICAL/HIGH findings — reproduce the failure directly if it's the kind of thing that can be (a regex that doesn't match a claimed filename, a hook that doesn't block a claimed input) rather than taking the subagent's assertion on faith. This mirrors exactly how this repo's own Session 4 findings were handled: verified independently before being fixed, not fixed on the strength of the review alone.

If a finding doesn't reproduce, say so plainly rather than silently dropping it — note it as "claimed by review, not reproduced" so it isn't lost, but don't write it into KNOWN DEBT as a confirmed gap either.

## Step 5 — persist findings into KNOWN DEBT, labeled by source

Findings that survive Step 4's verification get appended to the project's CLAUDE.md KNOWN DEBT section (read-then-append, same discipline as every other multi-writer section in Foundry-generated docs — never blind-replace). Each entry must be labeled with its source and date, so a future reader (human or AI session) can immediately tell this came from an adversarial review pass, not from someone noticing something during normal work:

```
- [QC review, <date>] <the finding, specific enough to act on> — <why it matters / what could go wrong>
```

This is the same evidentiary-source discipline already used for this repo's own Session 4 findings — don't let a finding read as an unexplained fact with no indication of how it was discovered or how seriously to weight it.

If the project doesn't have a Foundry-style CLAUDE.md with a KNOWN DEBT section, ask where findings should go instead rather than assuming a location.

## When to proactively offer (suggestion only, never silent, never automatic by default)

Suggest running this — as a question, not an automatic action — at natural checkpoints:
- Right before treating security-sensitive code (auth, payments, credential handling) as finished
- Right before treating a destructive-capable script/operation (data deletion, migrations, force-push-style git operations) as finished
- Right before a hook or other automatically-triggered mechanism is wired into `.claude/settings.json` and considered done

State why you're suggesting it (which of the above applies) and let the user decide — exactly the same pattern as `foundry-init`'s Step 3 mentioning Promptify's availability without invoking it automatically. Do not run the review without being asked, even when you're confident it's warranted.

## Optional: mechanical auto-run via a hook (opt-in only, not the default)

A `PostToolUse` hook that mechanically triggers this review after every edit to a risky file was considered and deliberately rejected as the default, for a concrete reason: `PostToolUse` fires after every single edit, not at a real completion checkpoint, so it would re-review the same half-finished function repeatedly during normal iterative editing — pure noise and cost with no way to distinguish "still mid-edit" from "actually done." It also can't block (the edit already happened by the time `PostToolUse` fires), so the most it could do is nag.

If a user explicitly wants this anyway (some users may prefer the noise tradeoff for a specific high-risk file or directory), it's possible to wire a `PostToolUse`/`Edit|Write` hook scoped to specific path patterns that appends a reminder via `additionalContext` rather than blocking — but this is opt-in, offered only if asked for, never part of the default Foundry scaffolding sequence. If built, validate it the same way every other Foundry hook is validated (pipe-test with synthetic stdin, confirm it doesn't fire on unrelated files) before wiring it in.

## Relationship to Foundry

This skill is referenced by `foundry-init` (see its Step 3) the same way Promptify is: Foundry mentions it exists and when it's worth running, but does not own it, call it automatically, or make it part of the default scaffolding sequence. Works standalone in any project, with or without Foundry's other scaffolding — the KNOWN DEBT-append step in Step 5 degrades gracefully (asks where to put findings) if the project has no Foundry-style CLAUDE.md.
