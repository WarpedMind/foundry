# Decision Log
# Entries are ordered newest-to-oldest. Most recent decision is at the top.

## 2026-06-28 — USER_GUIDE.md needed a why/benefits layer, not just steps

### A pure step-by-step walkthrough assumes too much prior knowledge for a public launch
- The first draft of `USER_GUIDE.md` explained exactly what happens during `/foundry-init` but never explained *why* any of it matters — what a hook is, why session-to-session memory loss is a real problem, why a leaked secret is costly, why "regulated" gets special handling. The user caught this directly: "do we explain WHY this was created, how it works... any educational things as well for those who don't know this stuff (even non-devs)?"
- **Why:** a user guide for something about to be publicly announced needs to work for readers who don't already believe the premise or know the jargon, not just readers who already get it and need the exact command syntax. "What you'll be asked" and "why any of this matters" are different needs, and the first draft only served the first one.
- **How to apply:** added a "Why this exists" section at the very top of the guide, written in plain language, with an explicit skip-link for readers who already know this stuff — so the doc serves both audiences without forcing either to wade through content meant for the other.

## 2026-06-28 — "Looks clean" and "is clean" are different claims, even for test fixtures

### A hand-written "clean" test file is itself a claim that needs verification, not an assumption
- Building a true-negative test fixture for `qc-review` (a deliberately well-written auth file, to confirm the skill correctly reports "no findings") produced a file that looked correct but had a real bug: a `_failed_attempts` dict that was declared with an obviously rate-limiting-shaped name but never actually read or written anywhere — purely decorative.
- **Why:** the same verify-before-trust discipline that applies to external API claims, doc pages, and task briefs elsewhere in this repo's standing rules applies just as much to code written specifically to *be* a clean baseline. Writing code that looks like it has a safety mechanism is not the same as it having one — exactly the gap this skill exists to catch, which means a test fixture for it needed to survive the same scrutiny as production code, not be assumed correct because it was written second.
- **How to apply:** when constructing a "this should be clean" test case for any verification tool, don't treat your own authorship as a substitute for actually checking it — run the same review/test against your fixture that you'd run against real code, and expect it to occasionally fail, the way this one did.

### A genuine true-negative result requires a file with no real surface area, not just hardened code
- After fixing the decorative rate-limiting bug, the "clean" auth file still wasn't clean on re-review — it had a real CRITICAL (unbound-by-IP lockout enabling a legitimate-user DoS, independently reproduced by scripting the actual attack) and a real TOCTOU race condition (confirmed by inspection). Only a genuinely trivial, stateless utility function (date formatting, no auth/state/secrets surface at all) produced an actual "no findings" result.
- **Why:** `qc-review`'s adversarial framing is working as intended if it keeps finding legitimate second-order issues as the obvious ones get fixed — this isn't a bug in the skill or the test, it's evidence the skill doesn't stop digging once the first layer looks fixed. The practical implication: "no findings" is a genuinely rare result for any file with real logic, not a baseline a moderately-careful implementation should expect to hit.
- **How to apply:** don't read a `qc-review` finding on a "this should be fine" file as a sign the test fixture was poorly chosen — read it as the skill doing its job. Reserve true-negative testing for code with no meaningful logic at all if the goal is specifically to confirm the "report nothing, plainly" behavior in isolation from "is there actually nothing to find."

## 2026-06-28 — qc-review: mechanical auto-run rejected as the default trigger

### PostToolUse-triggered review fires at the wrong granularity to be the default
- The user's first instinct was "all of the above" for trigger modes, including a `PostToolUse` hook that mechanically runs the review after every edit to a risky file. Pushed back on this specific piece rather than accepting it as given.
- **Why:** `PostToolUse` fires after every single tool call, not at a real completion checkpoint — it would re-review the same half-finished function repeatedly during ordinary iterative editing (pure noise/cost, no signal). It also structurally cannot block: the edit has already happened by the time `PostToolUse` fires, so the most it could ever do is nag after the fact, unlike a `PreToolUse` hook (e.g. the secrets-guard) which can actually stop something before it happens.
- **How to apply:** on-demand (`/qc-review`) and a proactive *offer* (a suggestion Claude makes and waits on, never auto-executed) are both the default. The mechanical hook variant is documented as a real, buildable option but explicitly opt-in only, offered if asked for — same treatment Foundry already gives Hook 4 (the directory-drift logger). When a user's first instinct for "when should this run" includes a mechanism with a structural limitation like this, it's worth surfacing the limitation and asking rather than building exactly what was first described.

### Findings get verified before being written down, not just relayed
- `qc-review`'s Step 4 requires reproducing CRITICAL/HIGH findings directly before persisting them, rather than trusting the fresh-context subagent's report as fact.
- **Why:** a subagent's claim that something is broken is itself just a claim — the entire reason `qc-review` exists is to catch real problems, and writing unverified claims into KNOWN DEBT would undermine that doc's trustworthiness the same way an unverified "tested" claim already did earlier in this repo's own history (the Session 4 regex/glob findings, which were verified independently before being fixed, not fixed on the strength of the review alone).
- **How to apply:** this was tested for real, not assumed — the live test run reproduced the CRITICAL finding (confirmed identical-input-identical-hash behavior and a real rainbow-table match) and the HIGH finding (confirmed the literal `==` comparison in source) directly, rather than copying the subagent's report verbatim into the findings file.

## 2026-06-28 — Closing remaining debt for a "bulletproof, portfolio-quality" bar

### Unit-verified and integration-verified are different claims — close both, not just one
- The user wants Foundry to be genuinely bulletproof, not just "tested" in the loose sense. Most KNOWN DEBT items going into this pass had already passed isolated mechanism tests (a hook validated alone, a regex checked alone) but had never been exercised together, in sequence, on a real project.
- **Why:** a piece working in isolation doesn't guarantee the pieces work correctly *together*, in the real order they actually run, against a real project with real stakes (a real `.env`, a genuinely uncertain regulatory question, a true day-one stack with nothing yet verified). Several of this session's earlier bugs (the regex/glob gaps, the trailing-space parsing bug) were found specifically by testing the real, full mechanism rather than trusting a simplified version — this is the same principle, scaled up from one hook to a full end-to-end run.
- **How to apply:** when closing out a debt list, distinguish "mechanism verified in isolation" from "exercised end-to-end on a real, different project" as two separate bars, and don't mark something fully closed until both are met. The end-to-end run in this session found zero new bugs — but that's only meaningful evidence of robustness because it happened *after* the individual pieces were already hardened, not instead of doing that work.

### A genuinely uncertain test case is more valuable than a clean-cut one
- The test project for this pass was deliberately given a genuinely ambiguous regulatory status ("possibly health-data-adjacent") rather than a clean yes/no, specifically to stress-test `foundry-governance`'s anti-fabrication rule under real uncertainty, not just its documented intent.
- **Why:** a skill that handles "obviously regulated" and "obviously not regulated" correctly hasn't actually proven it resists the temptation to fabricate confidence in the harder, more realistic case — most real projects' regulatory status isn't a clean binary.
- **How to apply:** the correct output was an honest "not yet researched, get this reviewed" placeholder, not a guessed framework — confirmed that's what was actually produced. When designing a test case for an anti-fabrication or honesty-preserving rule, prefer genuinely ambiguous inputs over clean-cut ones; they're the actual stress test.

---

## 2026-06-28 — CwdChanged superseded: detect command-level drift, not cwd-change events

### A deferred item should be re-attempted with real triggers before being accepted as permanently blocked
- The previous entry below left `CwdChanged` deferred as "designed but unverified." The user pushed back on accepting that as final and asked to actually try triggering it for real, offering to help.
- **Why:** "couldn't verify it inside one conversation" was true at the time, but wasn't actually exhausted — there were real untried mechanisms (a Bash-tool `cd`, `EnterWorktree`) worth attempting before settling. Two real attempts (external shell `cd`, Bash-tool `cd`) produced informative negative results rather than a dead end.

### The investigation itself revealed the real problem was misdiagnosed
- Attempting `EnterWorktree` as a third trigger (its docs state it changes the session's working directory) produced "not in a git repository" — surprising, since the session had been doing extensive work inside a real git repo for hours. Investigating that error revealed the actual cause: every Foundry-related command this whole session had been path-qualified (`cd ~/Projects/foundry && ...`), never a persistent directory change — so the harness's own tracked session root had silently never moved from the conversation's original directory the entire time.
- **Why this matters:** it means `CwdChanged`, even if it had been built correctly against a verified payload, would not have fired during the exact session that motivated wanting it — the harness's own "cwd" never changed, even though the actual work clearly drifted across projects. The original diagnosis (detect when cwd changes) was solving the wrong problem.
- **How to apply:** the real, observed failure mode is path-qualified command drift, not a literal working-directory change — built a `PreToolUse`/`Bash` hook that detects a leading `cd` to an out-of-project path and logs it, which directly catches the actual pattern that happened, verified against 6 real test cases (including one real bug — a trailing-space parsing error — caught only by `bash -x` tracing). When an investigation reveals the original framing of a problem was wrong, redesign around what was actually observed, don't force the original mechanism to fit.

---

## 2026-06-28 — Cross-project drift mechanism: written rule shipped, hook deferred unverified

### Don't write a hook against a guessed payload shape, even when the hook event itself is confirmed real
- The user identified a genuine gap: this very conversation started in an earlier, unrelated project, then drifted into Foundry's own work for hours with nothing flagging the handoff — exactly the scenario where stale/cross-project context bleed is most likely. The natural fix is a `CwdChanged` hook. `CwdChanged` is confirmed as a real, valid Claude Code hook event (present in the settings schema enum) — but attempting to verify its actual stdin payload shape (does it provide old/new cwd explicitly?) found that it can't be pipe-tested with synthetic input the way `Bash`/`Write` hooks can; it requires a genuine harness-level directory-change event to fire.
- **Why:** writing bash logic against a guessed payload shape and calling it done would be the exact same mistake independently caught and fixed in Session 4 — a "this should work" claim with no real verification behind it, for a hook whose only job is to fire reliably and correctly.
- **How to apply:** shipped the weaker, written-rule-only half of this idea now (the CLAUDE.md template's context-checkpoint rule extended with an explicit directory-change trigger, alongside the existing session-length trigger) since that's verifiable today — a written instruction either is or isn't in the file. The actual hook stays explicitly on the roadmap as designed-but-unverified, with the specific blocker stated (payload shape unconfirmed), rather than either building it on a guess or pretending the idea was dropped.

---

## 2026-06-28 — Build-from-scratch promptify mode added; cost claim corrected

### Bare `/promptify` (no arguments) added as a third, distinct mode
- The user proposed it directly: when there's no rough idea typed yet, ask a structured series of questions (goal, role, scope, output format) to build the prompt collaboratively, rather than typing something rough first and rewriting it after.
- **Why:** this is a genuinely different use case from the existing two modes — both of those assume the user has already typed *something*, even if rough. A bare invocation has nothing to rewrite, so it needs its own flow, not a variant of the rewrite steps.
- **How to apply:** split the question-gathering into two parts based on a real technical constraint: the open-ended goal question must be plain conversational text, because `AskUserQuestion` requires 2-4 concrete options per question and structurally cannot represent free text (confirmed directly — this exact limitation was hit earlier in this session trying to ask "which project is this in?" as a question). Everything after the goal is known gets batched into one `AskUserQuestion` call to minimize round trips. Verified with a real test ("I guess I want to create a game") — the flow worked, including a free-text detail supplied via "Other" correctly carrying through to the final prompt.

### Don't let a "this saves context" framing overstate what's actually true
- After the build-from-scratch mode test, the user asked directly: was that back-and-forth free, or "just substeps"?
- **Why:** the honest answer is no — every skill invocation, question, and answer in that exchange was a normal conversational turn with real context cost (the skill's full SKILL.md text gets loaded into context on each invocation, same as any other skill call). The mode is *relatively* cheaper than the alternative it replaces (fewer total turns than asking the same 4 questions one at a time conversationally), which is a real and worth-stating benefit — but the skill's own original wording ("avoid the context cost," "as few round trips as possible") could be read as implying something closer to free, which isn't accurate.
- **How to apply:** rewrote the build-from-scratch mode's framing to state the comparison precisely (fewer turns than the conversational alternative; not free or context-neutral in absolute terms) rather than leaving an overstated claim in place just because it sounded good. Same standing discipline as the rest of this project: a confident-sounding claim needs to be checked against what's actually true, not left alone because correcting it feels like a downgrade.

---

## 2026-06-28 — "Promptify auto mode" idea recorded as deferred (was at risk of being lost)

### A real, previously-discussed feature wasn't written down anywhere in the repo

### A real, previously-discussed feature wasn't written down anywhere in the repo
- Earlier in this same overall work, the user proposed a "Promptify auto mode" — automatically running any sufficiently complex/heavy prompt through promptify's rewrite step, without explicitly typing `/promptify` each time. This was discussed and deliberately deferred (correctly — it needs real design work on the hard part, reliably classifying "heavy" vs. "simple" prompts). But the decision to defer it was never actually committed to README.md's Roadmap or DECISIONS.md — it only existed in conversation history.
- **Why this matters:** a deferred idea that's only in conversation history is functionally the same as a dropped idea once that conversation ends or gets compacted — the entire point of this repo's "every finding gets fixed or explicitly, visibly deferred, never silently dropped" rule (see the Session 4 entry below) applies just as much to feature ideas as it does to safety findings. This one nearly fell through that exact gap.
- **How to apply:** added to README.md's Roadmap with enough detail to pick up later (the likely mechanism — a `UserPromptSubmit` hook with a lightweight classifier — and the specific hard part still undesigned, complexity classification with acceptable false-positive/negative rates). Confirmed directly to the user: this capability does not exist today; `/promptify`/`/promptify!` are always explicit, opt-in invocations.

---

## 2026-06-28 — First real exercise of /foundry-init and /promptify

### "Tested by design review" is not the same as "tested" — applies past the security context too
- After the first real `/foundry-init` run succeeded, ran `/promptify` for the first time against a real rough prompt rather than treating its KNOWN DEBT status as acceptable to leave open indefinitely.
- **Why:** the same lesson from the Session 4 security review (a "tested" claim needs actual evidence, not just confident-sounding design) turned out to apply here too, just for a different kind of correctness: promptify's Step 3 instructions *looked* complete on paper (5 structural elements, all individually reasonable), but running it against one real input surfaced 4 concrete gaps a careful reader of the instructions alone would not have predicted — no role-framing element at all, no domain-risk-flagging mechanism, no hypothesis enumeration for debugging, no test-infrastructure awareness. None of these were "bugs" in the sense of broken logic; the instructions just hadn't been pointed at a real case yet.
- **How to apply:** for any skill whose quality depends on judgment applied per-invocation (not a literal template with fixed output), "designed but not exercised" should be treated as "unverified," not "probably fine" — the design quality of the instructions is not a substitute for seeing real output. Re-run the same test after a fix to confirm the change actually worked, not just that the new instruction text reads well.

### Promptify's structural-elements list expanded: role-framing, domain-risk-flagging, hypothesis enumeration, test-awareness
- The user's own mental checklist for a good prompt (order, structure, no contradictions, specificity, "using roles," explicit desired action) included role/persona framing — which promptify's Step 3 didn't have as an option at all before this fix.
- **Why:** role-framing genuinely changes output quality for some shapes (architecture review, writing/communication) and does nothing for others (most debugging/implementation tasks) — the fix had to add it as a conditional element ("only when it changes response quality"), not a mandatory one, to avoid the "3x longer than necessary" failure mode the skill already warns against. Domain-risk-flagging (auth/payments/secrets/deletion) was added because a generic structural checklist has no way to know a specific request touches security-sensitive code unless something explicitly prompts for that inference. Hypothesis enumeration and test-awareness were added because the first test output, while structurally fine, defaulted to one fix path and had no connection to existing verification infrastructure — both are real-world necessities for debugging specifically, not generic prompt hygiene.
- **How to apply:** verified directly via before/after comparison on the identical test input — confirmed the second pass added hypothesis enumeration, a concrete named security guardrail, and test guidance, while correctly NOT adding role-framing (since it wouldn't have helped this debugging-shaped request), proving the "apply judgment, don't apply everything mechanically" instruction is actually followed.

---

## 2026-06-28 — Independent safety review before public release

### A future QC/adversarial-review skill should be referenced by Foundry, not owned by it
- Right after the independent-review process in this same session proved valuable, the user asked whether this should become a permanent part of Foundry's own toolset.
- **Why:** the review process that just worked (spawn a fresh-context subagent, instruct it to be adversarial, hunt for a specific class of problem) is genuinely useful, but it's not a scaffolding concern — it requires deeply understanding whatever it's reviewing, which means it can't be a generic template the way CLAUDE.md is. This is the exact same shape of decision already made for Promptify: a real, useful capability that doesn't belong baked into `foundry-init`'s sequence, because doing so would blur Foundry's actual scope (project scaffolding) with a fundamentally different one (code/content review).
- **How to apply:** added to README.md's Roadmap as its own standalone skill, and added a forward-looking note in `foundry-init`'s "mention Promptify" step describing the intended integration once it exists (Foundry surfaces it, doesn't own or auto-invoke it) — without referencing it by a specific command name, since the skill doesn't exist yet and claiming otherwise would be a false statement in the orchestrator's own instructions. Don't let "this would be useful" by itself justify expanding Foundry's scope — check whether the capability is actually a scaffolding concern first.

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
- The user already has a working manual pattern (a STACK.md from one of their other projects) and asked whether Foundry should incorporate a simplified version now, pending a separate future job-hunting tool, or build it properly now.
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
