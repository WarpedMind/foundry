# Decision Log
# Entries are ordered newest-to-oldest. Most recent decision is at the top.

## 2026-06-28 — Initial build session

### EXPLAIN_MODE added now, not deferred to roadmap
- The user raised that newer developers need to understand *why*, not just *what*, by default — and asked whether this should be built now or deferred since "easy to add" wasn't certain.
- **Why:** Most of the underlying reasoning already existed in each skill's own SKILL.md (each skill already explains its own rationale internally) — the actual gap was surfacing that reasoning to the user in the moment, not authoring new explanations from scratch. That made it cheap to add now: one extra question in `foundry-init`, one short instruction added to each of the 5 sub-skills. A full adaptive/configurable help system (per-skill verbosity levels, persisted preference, etc.) would have been a much bigger scope addition and was correctly identified as not "easy" — that stayed deferred.
- **How to apply:** When a feature request turns out to be "surface reasoning that's already written down" rather than "invent new reasoning," it's usually cheap and worth doing immediately rather than deferring. When it requires new infrastructure (persistence, new config surface, testing both modes thoroughly), treat it as a separate scoped addition.

### Naming: Foundry (tool) under Preamble (brand umbrella)
- Considered renaming the whole project to "Preamble" mid-build after the idea came up in a separate conversation. Decided instead: Foundry stays the name of this specific tool; Preamble becomes the umbrella brand for this and future tools (Promptify, etc.), with a domain like preamblefoundry.com tying them together.
- **Why:** "Foundry" already fits the metaphor (forging the foundational scaffolding a project is built on) precisely, and renaming mid-build for a name that fits a different kind of product (a "preamble" is the framing statement *before* the real content — better suited to a chat/conversation-framing product) would have been rework without a clear improvement.
- **How to apply:** Don't rename Foundry again without a concrete reason; new tools built later can adopt the Preamble umbrella naming pattern (`Preamble<ToolName>` or similar) without touching this repo.

### Configuration derived from a questionnaire, not named presets
- Considered offering named presets (e.g. "base," "advanced," "mobile," "regulated") as a faster path to configuring a new project.
- **Why:** Presets bundle unrelated dimensions (regulatory load, platform, team size) into a single name, which becomes unmaintainable and opaque quickly — nobody remembers what "advanced-mobile" actually configures six months later. A short questionnaire derives the same configuration transparently, traceable to specific yes/no answers.
- **How to apply:** Resist adding named presets later even if requested for convenience — if a fast-path is needed for a common case, prefer a single binary fast-path question (like the existing minimal/throwaway check) over a named preset system.

### Proactive code-review agents deferred to roadmap, not built now
- Considered building dedicated security-review and code-quality-review agents that run proactively (e.g. via `PostToolUse` hooks) as part of this initial build.
- **Why:** This needs its own design pass (blocking vs. advisory, noise tuning, which existing tools to invoke rather than duplicate — e.g. a project's own `/code-review` or security-review skills) and would have expanded this build's scope significantly. Better to ship the core scaffolding solidly and design this properly later than rush both.
- **How to apply:** Listed explicitly in README.md's Roadmap so it isn't lost; don't build it opportunistically inside an unrelated change — give it its own planning pass when picked up.

### Governance sections default to "not yet researched" rather than generic compliance language
- Considered having `foundry-governance` generate generic compliance boilerplate (e.g. a standard "GDPR checklist") to fill a regulatory section when specifics aren't known yet.
- **Why:** Generic-but-plausible compliance text creates false confidence — a reader can't tell it apart from a verified statement, and the gap only becomes visible when it matters (i.e. too late). An explicit, marked placeholder ("not yet researched, get this reviewed by counsel") can't be mistaken for a real guarantee.
- **How to apply:** Standing rule for `foundry-governance`: never fabricate plausible regulatory/compliance content to fill a gap. State the gap plainly instead. Verified in the end-to-end test (ComplianceBot scenario) — the rendered CLAUDE.md explicitly says "NOT YET RESEARCHED" rather than inventing SEC-specific language.

### No community/external skill packs bundled by default
- Considered baking in a specific named third-party skill pack (mentioned informally as something "people recommend") during initial design.
- **Why:** No independent verification was available of what that specific pack actually contains — bundling it on reputation alone would mean recommending something unverified. Foundry is designed to support pluggable external skill packs via Claude Code's plugin/marketplace mechanism, but none are bundled by default.
- **How to apply:** Any future addition of a named external pack should go through independent review of what it actually does first, documented in this log, not added on the strength of a recommendation alone.
