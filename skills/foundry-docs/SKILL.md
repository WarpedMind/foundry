---
name: foundry-docs
description: Scaffold a project's CLAUDE.md, DECISIONS.md, and SESSIONS.md from Foundry's templates, or safely add to/migrate existing versions of these files without losing real content. Use when a project needs these three docs created from scratch, or wants to retrofit Foundry's structure onto docs that already exist.
---

# foundry-docs

Generates `CLAUDE.md`, `DECISIONS.md`, and `SESSIONS.md` in the current project from the templates at `~/Projects/foundry/templates/` (or wherever this Foundry checkout lives — locate it by checking `~/Projects/foundry/templates/` first, then ask the user if not found).

**`EXPLAIN_MODE`** (set by `foundry-init`, or ask directly if this skill is invoked standalone): in `detailed` mode, briefly say why each file exists before generating it (e.g. "CLAUDE.md is the always-current snapshot; DECISIONS.md is for reasoning that should outlive the moment; SESSIONS.md is a session-by-session log for picking up cold — that's why they're three files, not one"). In `brief` mode, just generate them.

## Step 0 — never silently overwrite an existing file (mandatory, check before anything else)

Before rendering or writing anything: check whether `CLAUDE.md`, `DECISIONS.md`, or `SESSIONS.md` already exist in the project root. If **any** of them exist:

1. **Stop. Do not render or write yet.** Read the existing file(s) in full.
2. Tell the user plainly what already exists (e.g. "This project already has a CLAUDE.md with real content — running foundry-docs would overwrite it with template scaffolding unless we handle this carefully.").
3. Ask explicitly, via `AskUserQuestion`, what to do for each existing file:
   - **Leave it alone** — don't touch this file at all. (Almost always the right choice for an already-mature, hand-maintained CLAUDE.md like Karbot Rage's — it has real architecture notes, real status, real history that no template can regenerate.)
   - **Append a Foundry-standard section** (e.g. add a "Rules / Never do" entry about verify-before-trust if missing) without touching the rest of the file — a surgical addition, not a rewrite.
   - **Full re-render from the template**, using the existing file's content as the source for what goes in each section (a real migration, not a blank slate) — only do this if the user explicitly asks for it, understanding it's higher-effort and higher-risk than the other two options. Before writing anything for this option, see the mandatory pre-migration diff check below — a full re-render is not safe to do in one shot.
4. Never default to overwriting. If the user doesn't give a clear answer, the safe default is "leave it alone" — a missing Foundry convention is recoverable; a destroyed CLAUDE.md with months of real history is not.

This check applies independently per file — a project might have a real CLAUDE.md worth preserving but no DECISIONS.md yet, in which case DECISIONS.md can be created fresh from the template while CLAUDE.md is left untouched.

### Mandatory pre-migration diff check, before any "full re-render" of an existing file

A full re-render is lossy by a different mechanism than blind overwriting: the template has a fixed set of sections, and free-form hand-written content doesn't always map cleanly onto a `{{PLACEHOLDER}}`. Going straight from "user said redo it" to writing the new file risks silently dropping real content that simply doesn't fit any template slot — this is just as much a loss as overwriting, even though the user consented to the re-render, because they consented to "use the template structure," not "discard anything that doesn't fit it."

Before writing the re-rendered file:
1. Go section-by-section through the existing file and identify which existing content maps to which template placeholder.
2. Explicitly list anything in the existing file that does **not** map cleanly to any template section.
3. Show this list to the user and ask, for each item: which section should it go in (even if that means extending `{{ADDITIONAL_RULES}}` or another freeform section beyond what the template anticipates), or is it genuinely fine to drop.
4. Only proceed to write the re-rendered file once the user has confirmed a destination (or explicit removal) for every piece of unmapped content. Never silently drop something because "it didn't fit the template."

Only proceed to the steps below for files that don't already exist, or that the user explicitly asked to be re-rendered (and, for re-renders, only after the pre-migration diff check above is complete).

## Inputs this skill needs

If not already provided by a calling skill (e.g. `foundry-init`), ask the user directly:
1. Project name and a one-paragraph "what this is."
2. Tech stack (language, framework, major dependencies).
3. Does this project handle secrets/credentials/API keys? (`HANDLES_SECRETS`)
4. Does this project handle other people's data or money? (`HANDLES_DATA_OR_MONEY`)
5. Is this in a regulated industry or subject to specific external rules? (`REGULATED`) — if yes, ask what the regulatory context actually is (don't invent generic compliance text)
6. How does the project run today (commands, entry points)? If it doesn't exist yet, leave as a placeholder noting "to be filled in once the first runnable piece exists."

## Rendering CLAUDE.md.template (only for files cleared by Step 0 — i.e. don't exist yet, or user explicitly asked for a full re-render)

1. Read `templates/CLAUDE.md.template` in full.
2. For each `<!-- IF FLAG -->...<!-- ENDIF FLAG -->` block: if the corresponding flag is false, delete the entire block including both marker lines. If true, keep the content and strip just the two marker lines.
3. Fill every `{{PLACEHOLDER}}` with real content gathered from the user — never leave a placeholder un-filled, and never fill one with generic filler text ("appropriate security measures will be implemented"). If something is genuinely unknown yet, write that plainly: "Not yet decided — revisit once X exists." If this is a re-render of an existing file (per Step 0's "full re-render" option), source these from the existing file's actual content, not from scratch.
4. `{{KNOWN_DEBT}}` and `{{NEXT_PRIORITIES}}` start as `- None yet — this is a fresh scaffold.` for a brand-new project; for an existing project being retrofitted, ask the user what's currently known to be incomplete or wrong.
5. `{{ADDITIONAL_RULES}}` starts empty (just remove the placeholder line) — this section is meant to accumulate project-specific rules over time, not be pre-filled with guesses.
6. Write the result to `CLAUDE.md` in the project root. By the time this step runs, Step 0 has already confirmed this is safe — never reach this step for a pre-existing file without having gone through Step 0 first.

## Rendering DECISIONS.md.template and SESSIONS.md.template (only for files cleared by Step 0)

These have no placeholders to fill for a fresh project — they're header/instructions only, with the entry schema documented as comments. Copy them as-is to `DECISIONS.md` and `SESSIONS.md` in the project root (substitute `{{PROJECT_NAME}}` in SESSIONS.md's header).

For an **existing** project that already has informal session notes or a changelog (and Step 0 confirmed migration is wanted): offer to migrate the most recent few entries into the new schema rather than starting blank, but don't silently rewrite history — show the user what you're proposing first.

## After writing

1. Show the user the rendered CLAUDE.md and ask them to skim it before moving on — this is the file every future session anchors to, worth a real look rather than a rubber-stamp.
2. Do not commit. Leave that to the user or a later explicit step (per Foundry's "commit only when asked" rule, which this very skill is about to write into the project's own CLAUDE.md).
