---
name: foundry-governance
description: Write a real, project-specific REGULATORY CONTEXT and compliance/audit-trail section for projects in a regulated industry or otherwise subject to specific external rules. Use only when foundry-docs' questionnaire flags a project as regulated or handling sensitive data/money — never invoked for a generic project.
---

# foundry-governance

This skill exists specifically to resist generic compliance theater — section headers like "SOC 2 Compliant" or "GDPR Ready" with no actual content behind them are worse than no section at all, because they create false confidence. Every sentence this skill writes into a project's CLAUDE.md must be either a fact specific to that project, or explicitly marked as a placeholder pending real research.

**`EXPLAIN_MODE`** (set by `foundry-init`, or ask if standalone): in `detailed` mode, say the above paragraph's reasoning to the user before writing an honest placeholder, so a "not yet researched" section doesn't read as the assistant having failed at the task — it's a deliberate choice. In `brief` mode, just write the section.

## Step 0 — check for existing governance content first (mandatory)

If invoked standalone (not via `foundry-init` right after `foundry-docs` created a fresh placeholder), check whether CLAUDE.md already has a REGULATORY CONTEXT or COMPLIANCE / AUDIT TRAIL section with real content — not the placeholder text this skill itself writes. If it does, this is the same class of risk as `foundry-docs` overwriting a hand-maintained CLAUDE.md: **do not regenerate or overwrite it.** Read it, tell the user what's already there, and ask whether to leave it alone, append to it, or fully redo it — same three options and same "leave alone" default as `foundry-docs`'s Step 0. Only proceed to the steps below for a section that's genuinely a fresh placeholder or doesn't exist yet, or that the user explicitly asked to redo.

## Steps

1. **Ask, don't assume.** Find out specifically:
   - What regulatory body or framework actually applies (e.g. "CFTC" not "financial regulations" — a real trading-bot project's CLAUDE.md names the actual letter number and date of the relevant CFTC guidance, which is the right level of specificity).
   - What the project must NOT do as a result (e.g. a real prediction-market trading bot: "no MNPI, one exchange only in Phase 1" — concrete, checkable constraints, not abstract principles).
   - Whether there's a designated compliance contact, a logging requirement, or specific documentation the regulator expects to see.

2. **If the user doesn't know the specifics yet**, do not fabricate plausible-sounding regulatory language to fill the gap. Write the section honestly as: "Regulatory context not yet researched — do not treat this project as compliant until this section is filled in with verified, specific requirements." A known gap, stated plainly, is safer than confident-sounding filler that nobody will think to double check later.

3. **Audit trail / compliance logging conventions**, if the questionnaire flagged `HANDLES_DATA_OR_MONEY`:
   - Identify what specific events need to be logged for compliance purposes (trades? rejections? access to PII? all of the above?) — ask, don't assume "everything."
   - Specify where this log lives and its durability guarantee (append-only file? database table? — and is it backed up?).
   - State explicitly whether this logging is "never optional" (i.e. a code path that skips it is a bug) — a real trading-bot project's standing rule ("All trades, rejections, and leg failures must hit the audit trail — compliance logging is never optional") is the right level of forcefulness when it's actually true for the project.

4. **Write the REGULATORY CONTEXT section into CLAUDE.md** (coordinate with `foundry-docs`, which left this section's placeholder) with: the current state of relevant regulation/guidance (with dates, since regulatory guidance changes — don't write it as eternally true), what the project does to stay compliant, and any monitoring step (e.g. "operator should periodically check X for updates").

5. **Flag, don't resolve, genuine legal uncertainty.** If a question comes up that's actually a legal judgment call (not a factual lookup), say so plainly and recommend the user get real legal/compliance advice rather than treating the assistant's best guess as authoritative. This skill drafts structure and asks good questions; it is not a substitute for qualified review on anything with real regulatory stakes.

## What this skill does NOT do

It does not generate boilerplate compliance checklists from generic templates (e.g. a generic "GDPR checklist" copy-pasted regardless of whether the project even touches EU user data). Every line should trace back to something specific the user told this skill about their actual project and actual applicable rules.
