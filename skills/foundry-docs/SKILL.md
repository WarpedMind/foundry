---
name: foundry-docs
description: Scaffold or refresh a project's CLAUDE.md, DECISIONS.md, and SESSIONS.md from Foundry's templates. Use when a project needs these three docs created from scratch, or when checking an existing project's docs against the standard Foundry structure.
---

# foundry-docs

Generates `CLAUDE.md`, `DECISIONS.md`, and `SESSIONS.md` in the current project from the templates at `~/Projects/foundry/templates/` (or wherever this Foundry checkout lives — locate it by checking `~/Projects/foundry/templates/` first, then ask the user if not found).

**`EXPLAIN_MODE`** (set by `foundry-init`, or ask directly if this skill is invoked standalone): in `detailed` mode, briefly say why each file exists before generating it (e.g. "CLAUDE.md is the always-current snapshot; DECISIONS.md is for reasoning that should outlive the moment; SESSIONS.md is a session-by-session log for picking up cold — that's why they're three files, not one"). In `brief` mode, just generate them.

## Inputs this skill needs

If not already provided by a calling skill (e.g. `foundry-init`), ask the user directly:
1. Project name and a one-paragraph "what this is."
2. Tech stack (language, framework, major dependencies).
3. Does this project handle secrets/credentials/API keys? (`HANDLES_SECRETS`)
4. Does this project handle other people's data or money? (`HANDLES_DATA_OR_MONEY`)
5. Is this in a regulated industry or subject to specific external rules? (`REGULATED`) — if yes, ask what the regulatory context actually is (don't invent generic compliance text)
6. How does the project run today (commands, entry points)? If it doesn't exist yet, leave as a placeholder noting "to be filled in once the first runnable piece exists."

## Rendering CLAUDE.md.template

1. Read `templates/CLAUDE.md.template` in full.
2. For each `<!-- IF FLAG -->...<!-- ENDIF FLAG -->` block: if the corresponding flag is false, delete the entire block including both marker lines. If true, keep the content and strip just the two marker lines.
3. Fill every `{{PLACEHOLDER}}` with real content gathered from the user — never leave a placeholder un-filled, and never fill one with generic filler text ("appropriate security measures will be implemented"). If something is genuinely unknown yet, write that plainly: "Not yet decided — revisit once X exists."
4. `{{KNOWN_DEBT}}` and `{{NEXT_PRIORITIES}}` start as `- None yet — this is a fresh scaffold.` for a brand-new project; for an existing project being retrofitted, ask the user what's currently known to be incomplete or wrong.
5. `{{ADDITIONAL_RULES}}` starts empty (just remove the placeholder line) — this section is meant to accumulate project-specific rules over time, not be pre-filled with guesses.
6. Write the result to `CLAUDE.md` in the project root.

## Rendering DECISIONS.md.template and SESSIONS.md.template

These have no placeholders to fill for a fresh project — they're header/instructions only, with the entry schema documented as comments. Copy them as-is to `DECISIONS.md` and `SESSIONS.md` in the project root (substitute `{{PROJECT_NAME}}` in SESSIONS.md's header).

For an **existing** project that already has informal session notes or a changelog: offer to migrate the most recent few entries into the new schema rather than starting blank, but don't silently rewrite history — show the user what you're proposing first.

## After writing

1. Show the user the rendered CLAUDE.md and ask them to skim it before moving on — this is the file every future session anchors to, worth a real look rather than a rubber-stamp.
2. Do not commit. Leave that to the user or a later explicit step (per Foundry's "commit only when asked" rule, which this very skill is about to write into the project's own CLAUDE.md).
