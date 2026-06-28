# Decision Log
# Entries are ordered newest-to-oldest. Most recent decision is at the top.

## 2026-06-28 — Independent safety review before public release

### Do not trust "tested" claims in skill prose without re-verifying the actual command
- The secrets-guard hook's SKILL.md claimed it was "tested against a scratch repo: blocks when `.env` is staged, allows when only safe files are staged" — true for that one case, but an independent review found the regex missed `secrets.env`, `.env.production.local`, `config.yaml.bak`, and `real.key.txt`, all realistic filenames.
- **Why:** a narrow test that only checks the one obvious case can pass while the underlying logic is still broken for adjacent realistic inputs. The prose claim of "verified" created false confidence in exactly the same way `foundry-governance`'s anti-fabrication rule warns against for compliance sections — an unverified-but-confident claim is worse than an honest "not yet tested," because nobody thinks to double-check it.
- **How to apply:** going forward, any claim of "tested"/"verified" in a SKILL.md must be backed by a real adversarial fixture set (both false-negative and false-positive directions), not a single happy-path check — and that fixture set should be described in the SKILL.md itself (as the secrets-guard and `.gitignore` sections now do) so a future reader can see exactly what was checked, not just trust the word "verified."

### Commission a genuinely independent reviewer before public release, not just a self-review
- After fixing two destructive-action gaps the user personally caught (existing-file overwrite, wrong-directory scaffolding), did a careful self-review pass, then spawned a fresh subagent with zero prior context to independently hunt for the same class of risk.
- **Why:** the agent that built a system is structurally bad at finding its own blind spots — by the time you've written something, you've already convinced yourself the obvious failure modes are handled, which is exactly when you stop looking for non-obvious ones. A reviewer with no context, no investment in the existing design, and explicit instructions to be skeptical caught real things (a second instance of the regex/glob gap, a lossy-migration risk in full re-renders, sequencing ambiguity between two skills, a missing recovery path for outgrown "minimal" projects) that two rounds of this same builder's own review had missed.
- **How to apply:** before any future public release or major version of Foundry (or any other project), commission this same pattern — a fresh, context-free, explicitly skeptical review — rather than relying solely on the builder's own re-read, no matter how careful that re-read feels in the moment.

### Every finding gets fixed or explicitly, visibly deferred — never silently dropped
- The independent review produced 14 findings of varying severity. Given the volume, there was a real temptation to fix the obvious top few and let the rest fade into "we looked into it."
- **Why:** the user explicitly asked for this not to happen ("cover our butts in documentation as well") — and the cost of silently dropping a known-but-unfixed risk is that nobody, including future sessions, will know it was ever found, so it never gets revisited.
- **How to apply:** every finding from a safety/security review gets one of two outcomes, both visible: fixed now (with verification), or explicitly added to README.md's Roadmap with the reason it's deferred and which review caught it. Nothing gets quietly forgotten.

---

## 2026-06-28 — Post-launch additions (same day as initial build)

### STACK.md built in full now, not as a "lite" placeholder for a future tool
- The user already has a working manual pattern (`jobhunting/lazy-larry/STACK.md`) and asked whether Foundry should incorporate a simplified version now, pending a separate future job-hunting tool, or build it properly now.
- **Why:** the per-project stack record is the data layer a future aggregation/job-hunting tool would need anyway — building it as a deliberately simplified placeholder now would mean either re-deriving it properly later (wasted work) or the future tool working from sloppy data (worse outcome). The cross-project master rollup (aggregating multiple repos) is the part that's genuinely a different, separate tool's job — that stayed out of scope, but the per-project piece did not.
- **How to apply:** when a "simplified version now vs. separate tool later" question comes up, check whether the "simplified" version is actually a different thing (skip it / build the full thing) or really is the foundation the later thing depends on (build it properly now, don't half-do it).

### STACK.md requires "why this over alternatives," not just "what was used"
- The user flagged that an early draft of STACK.md's design only covered what/when, not why — and that the why is often the most interview-valuable part.
- **Why:** a stack entry that just names a technology gives an interviewer nothing to ask a follow-up about. The real value is in "chose X over Y because Z" — recognizing a limitation and reacting to it is the actual signal of engineering judgment, not the technology name itself.
- **How to apply:** every non-trivial STACK.md row must either state the alternative/reason inline (if short) or cross-reference the relevant DECISIONS.md entry by date (if long) — never just a bare technology name with a notes field that restates it.

### Status/offer hook added — three states, not a binary
- Considered a simple binary ("show a message every session" vs. "show nothing") for surfacing whether a project has Foundry set up.
- **Why:** a binary doesn't handle the real cases — a project that's already scaffolded shouldn't be re-asked; a project where the user deliberately said no shouldn't be nagged every session either. Three states (scaffolded/dismissed/neither) cover the actual decision space without being presumptuous in someone else's repo or annoying in your own.
- **How to apply:** `foundry.scaffolded`/`foundry.dismissed` are written by `foundry-init`'s own flow (Step 2.5 and the dismiss path respectively) — the status hook only reads them, never writes them, keeping the read/write responsibility cleanly separated between the hook (cheap, runs every session) and the orchestrator (runs once, on a real user action).

### Context-checkpoint discipline added as a standing CLAUDE.md rule
- The user asked whether Foundry enforces good context-management practice (checkpointing, clearing at natural boundaries) the way it enforces verify-before-trust — prompted by noticing this build session itself had run long across several different subtasks without a proactive suggestion to checkpoint.
- **Why:** this is the same category of thing as verify-before-trust — a good practice that depends on an assistant remembering to apply it in the moment is exactly the failure mode the SessionStart hook already exists to prevent for "read the docs." The actual mechanism that makes long-running work reliable is re-anchoring on CLAUDE.md/DECISIONS.md/SESSIONS.md after a clear, not hitting a specific context-percentage number — so the rule is framed around recognizing drift/scope sprawl, not a numeric threshold.
- **How to apply:** added to the CLAUDE.md template's standing Rules section, so every Foundry-scaffolded project carries this expectation by default rather than only the projects where a user happens to ask about it.

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
