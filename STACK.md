# Foundry — Tech Stack History

> Purpose: a fast, accurate reference for *what was actually used, when* — written so it can be pulled directly into a resume bullet, a skills list, or an interview answer ("walk me through your stack"). This is a career asset, not an engineering-process doc.
>
> Distinct from DECISIONS.md (the *why* behind a choice) and SESSIONS.md (the session-by-session narrative) — this doc exists purely to answer "what tools/languages/platforms have hands-on, verified use in this project, and since when." Update it any time a tool is added, replaced, or retired — see CLAUDE.md's Rules section for the update discipline.
>
> Verification discipline: only list something here as "in use" once it has been confirmed running (actually executed, not just written) — not the moment code referencing it is written. Items written but not yet verified should be marked "pending verification" until proven, or left off entirely.

---

## Current stack

| Category | Technology | Since | Notes |
|---|---|---|---|
| Skill definition format | Claude Code skills (Markdown `SKILL.md` + frontmatter) | Session 1 | Chosen over a compiled/scripted tool — skills are instructions a model follows, not code that runs deterministically, which is the whole mechanism Foundry depends on (e.g. `EXPLAIN_MODE` and per-project judgment calls wouldn't be possible in a rigid script) |
| Hook mechanism | Claude Code `SessionStart` hooks (`jq`-based JSON command output) | Session 1 | Built specifically because a written instruction to "always read these docs" was independently confirmed to get silently skipped in a real session — see DECISIONS.md / HOWS_AND_WHYS.md for the concrete incident |
| Templating | Plain-text `{{PLACEHOLDER}}` + `<!-- IF FLAG -->` markers, model-interpreted (no templating library) | Session 1 | Verified working via direct hand-rendering and a real end-to-end `/foundry-init` run (Session 1 and Session 4) rather than a parsing engine — see DECISIONS.md "EXPLAIN_MODE added now" entry for the general principle of preferring the cheap, already-working mechanism over new infrastructure |
| Install mechanism | Bash (`install.sh`), symlinks into `~/.claude/skills/` | Session 1 | Chosen over copying files so a `git pull` in this repo keeps installed skills current automatically; verified idempotent (run twice, confirmed no duplicate/broken state) |
| Secrets detection | `grep -E` (regex) for the commit-time hook; `.gitignore` glob patterns for the pre-commit baseline | Session 1, hardened Session 4 | Two different pattern languages for two different jobs, not interchangeable — gitignore's glob syntax can't word-boundary-match the way regex can, which caused a real false-positive bug (`secretary_notes.txt` matching a naive `*secret*` glob) caught only by testing the glob version separately rather than assuming the regex fix would transfer; see DECISIONS.md 2026-06-28 |
| Version control / hosting | Git + GitHub (public repo, MIT licensed) | Session 1 (git), Session 3 (public + license) | Chose public/open-source over private — no competitive reason to restrict it, and openness supports the project's stated portfolio/track-record goal; kept separate from any future commercial product decision under the "Preamble" brand umbrella (see DECISIONS.md "Naming" entry) |

---

## Planned / not yet built

| Category | Technology | Target version/milestone | Notes |
|---|---|---|---|
| Standalone fresh-context QC/adversarial-review skill | Claude Code subagent pattern (Agent tool, fresh context) | Future, roadmap item | Formalizes the review process used in Session 4 itself (spawn a zero-context subagent, instruct it to be adversarial, hunt for a specific class of problem) — deliberately scoped as a separate, Foundry-referenced-not-owned skill, same pattern as Promptify; see DECISIONS.md |
| Pluggable external skill-pack support | Claude Code plugin/marketplace mechanism | Future, roadmap item | Intentionally not bundling any named third-party pack until independently verified — see DECISIONS.md "No community/external skill packs" entry |

---

## Version/milestone snapshots

### Session 1 — initial build (2026-06-28)
- **Stack at this point:** Full 7-skill scaffold (later 8 with `foundry-stack` itself), 4 doc templates, `install.sh`, README + HOWS_AND_WHYS.md. Verified via hand-rendering against two scratch scenarios and a real end-to-end `/foundry-init` Skill-tool run.
- **What this version demonstrates:** designing a composable system (orchestrator + independently invocable sub-skills) rather than a monolith, specifically so each piece could be tested in isolation before being wired together — and actually doing that isolated testing (pipe-tested hooks, scratch-repo secrets tests) rather than just claiming it.

### Session 4 — independent safety review (2026-06-28)
- **Stack at this point:** Commissioned a fresh-context subagent to adversarially review every skill for destructive/silent-action risk. Found 14 issues, 2 CRITICAL — both involving security-relevant regex/glob patterns that earlier SKILL.md prose claimed were "tested" but were verified, independently, to actually miss realistic filenames (`secrets.env`, `config.yaml.bak`, etc.).
- **What this version demonstrates:** treating "I tested it" as a claim requiring evidence, not a fact to trust — every fix in this session was verified against a real adversarial fixture set in both directions (catches real positives, doesn't false-positive on legitimate files) before being trusted, and the fixture sets themselves are documented in the relevant SKILL.md files so a future reader can see exactly what was checked. Also demonstrates recognizing when a capability (the QC review pattern) is genuinely useful but doesn't belong inside the existing tool's scope — deferred to its own future skill rather than bolted on opportunistically.

---

## Skills gap — tools to incorporate in future work

| Tool / Technology | Why it matters | Target project / version |
|---|---|---|
| (none tracked yet) | | |

---

## How to use this for job hunting

- **Resume bullet seed:** "Designed and built a project-scaffolding framework as a set of composable Claude Code skills, including a self-auditing security mechanism — commissioned an independent adversarial review that found two critical gaps in security-relevant pattern matching (regex/glob filename detection), then fixed and re-verified both against adversarial test fixtures rather than relying on prior claims that they were 'tested.'"
- **Skills list, accurate as of Session 4:** Claude Code skill/agent design, prompt engineering for instruction-following reliability, Bash scripting, regex and gitignore glob pattern design (including adversarial test-fixture construction), git internals (history scrubbing tradeoffs, collaborator-safety checks before destructive operations), JSON hook configuration, technical documentation architecture (separating current-state/decision-log/session-narrative/career docs by audience and lifecycle), and structured self-review/independent-QA process design.
- **The "why this matters" framing for interviews:** the most interview-worthy part of this project isn't the scaffolding itself — it's the process discipline around it: building something, then deliberately seeking out an adversarial second opinion before trusting it was done correctly, and treating "tested" as a claim that needs evidence rather than a status to declare. That a real security bug was found and fixed this way, in a tool whose explicit purpose is to help other projects avoid exactly that kind of gap, is the concrete story.
