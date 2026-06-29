# Foundry — User Guide

This is the "what do I actually type" doc. The [README](README.md) is the pitch; [`docs/HOWS_AND_WHYS.md`](docs/HOWS_AND_WHYS.md) is the reasoning behind each design choice. This doc is the walkthrough — what happens, step by step, the first time you use this and every time after.

## Why this exists (read this if you're new to any of this)

If you already know what a "hook" is and why secrets shouldn't be committed to git, skip to [Install](#install-one-time-on-your-machine) below. This section is for everyone else — including non-developers who want to understand what they're actually getting, not just how to type the commands.

**The problem this solves.** When you work with an AI coding assistant (like Claude Code) across many separate sessions, it has no memory of your project between conversations unless something explicitly reminds it. Without that, every new session starts from zero: it doesn't know your project's history, what's already been decided and why, what's already broken and being tracked, or any standing rules you've set (like "never commit secrets" or "always ask before deleting data"). People have genuinely lost work, leaked credentials, or had an assistant repeat a mistake it had already "agreed" to avoid in a previous session — not because the AI is unreliable in general, but because nothing forced that context to carry forward. Foundry exists to make that *not depend on memory* — yours or the assistant's.

**What a "hook" actually is, in plain terms.** A hook is a small, automatic action that the AI coding tool runs at a specific moment — not something the AI decides to do on its own, and not something you have to remember to ask for. Foundry's main hook runs automatically at the start of every session and loads your project's key documents into the assistant's context before you've even typed anything. The difference between "the assistant is supposed to remember to read these docs" and "the system mechanically loads them every time, whether anyone remembers or not" is the entire reason this is more reliable than just writing good instructions and hoping they get followed.

**Why "secrets" handling matters, even if you're not a security expert.** A "secret" here means anything like a password, an API key, or a database connection string — something that, if it ends up in your project's public git history, anyone can find and use against you (drain a cloud bill, access a database, impersonate your app). It's an extremely common, extremely avoidable mistake — people commit a `.env` file by accident constantly, because nothing stopped them in the moment. Foundry's secrets handling exists to make that mistake structurally hard to make, not just to warn you about it after the fact.

**Why "regulated" or "handles other people's data" gets special treatment.** If your project touches health data, financial data, or anything else with real legal/compliance weight, getting that wrong has consequences beyond a bug — fines, lawsuits, loss of user trust. Foundry doesn't try to be your lawyer. What it does is make sure that question gets asked explicitly up front, and that if nobody's actually verified the real requirements yet, the project's documentation says so honestly ("not yet researched — get this reviewed") instead of staying silent or inventing something that sounds plausible but isn't checked. The goal is making the gap visible, not pretending to close it for you.

**Who benefits from this, concretely.**
- **If you're coding solo with AI assistance**: you get a project that doesn't quietly drift or repeat old mistakes every time you start a new session.
- **If you're working with a team (human or AI)**: everyone — and every new AI session — starts from the same shared, current understanding of the project, not whatever happened to be in one person's head.
- **If you're job-hunting or building a portfolio**: the optional `STACK.md` keeps an honest, interview-ready record of what you actually built and why, instead of trying to reconstruct it from memory months later.
- **If you're not a developer at all** but you're directing an AI assistant to build something for you: Foundry is what keeps that assistant honest and consistent across the (probably many) separate conversations it'll take to get something real built — without you needing to understand the mechanics yourself.

## Install (one-time, on your machine)

```bash
git clone https://github.com/WarpedMind/foundry ~/Projects/foundry
~/Projects/foundry/install.sh
```

This symlinks every skill into `~/.claude/skills/`, so they're available in **every** Claude Code project on your machine — not just the Foundry repo itself. You don't reinstall per-project. A `git pull` inside `~/Projects/foundry` later updates every project's skills at once, since they're symlinks, not copies.

If you ever update Foundry and a skill doesn't seem to have changed, run `/hooks` once in an open Claude Code session, or start a fresh session — newly-installed or updated skills sometimes need that to be picked up.

## Your first run: `/foundry-init`

Open Claude Code in any project directory (new or existing) and type:

```
/foundry-init
```

Here's exactly what happens, in order:

### 1. A location check (silent, automatic)

Before asking you anything, Foundry checks whether you're actually standing in one project's root, not a folder full of unrelated projects (like `~` or `~/Projects`). If it looks wrong, it stops and asks you to `cd` into the right place first. You won't usually see this — it only speaks up if something looks off.

### 2. "Is this throwaway, or a real project?"

If you say **throwaway**: Foundry writes a 3-line CLAUDE.md (what this is, stack, how to run) and stops. No hooks, no security setup, no questionnaire. This is the "I don't want to think about this" path for a 10-line script.

If you say **real project**: continue below.

### 3. "Brief or detailed explanations?"

**Brief** (the default) just does things. **Detailed** explains the *why* behind each non-obvious step as it happens (e.g. why `.gitignore` has to be written before the first commit, not after). Pick detailed if you're newer to this kind of setup, or just curious. You can ask to switch mid-run at any point.

### 4. The questionnaire

A handful of questions, asked through Claude Code's normal multiple-choice prompts:
- What's this project, in a sentence or two?
- What's the tech stack?
- Does it handle secrets/credentials/API keys?
- Does it handle other people's data or money?
- Is it in a regulated industry, or subject to specific external rules?
- Solo project, or will others (people or other AI instances) work on it too?
- Where does it run (local, a server, mobile, not yet decided)?
- Do you want to track this project's tech stack for resume/portfolio purposes?

There's no "preset" to pick (no `--advanced-mobile-regulated` flag). Your answers just turn into flags, and each flag turns on exactly the pieces that are relevant. Answering "yes" to both secrets *and* regulated doesn't trigger some special combined mode — it's just two flags being true at once.

### 5. Foundry builds, in dependency order

You don't have to do anything during this part except watch and answer the rare follow-up question. In order:

1. **`.gitignore`** gets written first, before anything is staged to git — this is deliberate (see "Why this order matters" below).
2. **Secrets setup** (only if you said yes to secrets) — a real `.gitignore` baseline, a `.env.example` convention, a check for already-committed secrets in git history, and a commit-time guard hook that blocks `git commit` if something secret-looking is staged.
3. **CLAUDE.md / DECISIONS.md / SESSIONS.md** get created — the three docs every Foundry project shares. Optional sections (Security Rules, Regulatory Context, Compliance/Audit Trail) only appear if your answers said they're relevant.
4. **Governance content** (only if regulated or handles data/money) — either real, project-specific regulatory text, or an honest "not yet researched, get this reviewed before relying on it" placeholder. Foundry never invents a plausible-sounding compliance framework it can't actually verify applies to you.
5. **Hooks wired into `.claude/settings.json`** — the SessionStart doc-loader (always), the status hook (always), the secrets-guard (only if you handle secrets).
6. **`STACK.md`** (only if you opted into career tracking) — starts empty except for what's actually been verified running, not speculatively pre-filled.
7. **Repo-hygiene rules** added to CLAUDE.md (keep docs current, fix the README when it drifts, etc.)

### 6. A final review — nothing commits automatically

Foundry shows you a list of everything it created or changed, then asks if you want to commit now. It will not commit without you saying yes.

### 7. Two more skills get mentioned (not run)

Once scaffolding is done, Foundry tells you that `/promptify` and `/qc-review` exist and when they're useful — it doesn't run either one for you. See their own sections below.

## Why this order matters (the short version)

`.gitignore` goes in *before* the first `git add`/`git commit` — not after — because the entire point is to make sure a real secret can never be staged in the first place. Writing `.gitignore` after you've already committed a `.env` file doesn't un-commit it; it just stops the *next* mistake. Foundry sequences this correctly automatically — you don't have to remember to do it in the right order yourself.

## Every session after the first

You don't run `/foundry-init` again. Two hooks do their job silently:

- **The doc-loader hook** loads CLAUDE.md, DECISIONS.md, and SESSIONS.md into context at the start of every session, automatically — so the assistant doesn't have to remember to read them, and you don't have to remember to ask it to.
- **The status hook** shows a one-line confirmation ("Foundry: Active") if the project's already scaffolded, stays completely silent if you've dismissed Foundry for this project, or offers `/foundry-init` if neither has happened yet.

If you ever see the offer and don't want it, just say **"skip Foundry for this project."** That's a real recognized phrase — it writes a dismissal flag and the offer goes away for good (until you explicitly run `/foundry-init` yourself later, which always works regardless of a prior dismissal).

## Running one piece on its own

`/foundry-init` is just an orchestrator — every piece it calls is also a standalone skill you can run by itself, on an existing project that only needs one thing:

- `/foundry-docs` — just the CLAUDE.md/DECISIONS.md/SESSIONS.md scaffolding.
- `/foundry-security` — just the `.gitignore` baseline, `.env.example`, and secrets-guard hook.
- `/foundry-governance` — just the regulatory/compliance sections.
- `/foundry-hooks` — just the SessionStart and status hooks.
- `/foundry-repo-hygiene` — just the "keep docs current" discipline.
- `/foundry-stack` — just the career/portfolio tracking doc.

Each of these checks for existing content first and asks before overwriting anything — none of them will silently clobber a CLAUDE.md you've already hand-written, even if you run them on a project Foundry didn't originally scaffold.

## Promptify — turning a rough idea into a good prompt

Three ways to use it:

| You type | What happens |
|---|---|
| `/promptify <rough idea>` | Rewrites your idea into a clearer, more structured prompt, explains what changed and why, then **waits** — it does not act on it yet. |
| `/promptify! <rough idea>` | Same rewrite, same explanation — but immediately proceeds to execute it in the same turn. |
| `/promptify` (nothing after it) | Guided build-from-scratch mode — for when you don't have a rough idea typed yet at all. Asks what you want to accomplish, then a short batch of follow-up questions, then builds the prompt with you. |

**When to use plain `/promptify` vs. `/promptify!`**: use plain `/promptify` the first several times you try it for any given *kind* of request (debugging, a research question, a writing task) — you want to see and approve the rewrite before trusting it. Once you've seen enough rewrites of that shape and they're consistently good, `/promptify!` skips the wait for routine, already-trusted patterns. There's no universal "always use `!`" — it's about how much you've already verified this specific kind of rewrite.

**What it actually changes**, concretely: it adds explicit success criteria ("what does done look like"), explicit scope (what's in/out of bounds), surfaces context you left implicit, and — only when it actually helps — a role/persona framing, a domain-risk flag (e.g. "this touches auth, be careful not to weaken session handling"), or a request to enumerate hypotheses before committing to a debugging fix. It does not add all of these every time; a rewrite that's 3x longer than your original idea for no reason is its own failure mode, and the skill is built to avoid that.

## qc-review — an adversarial second opinion, not a general code review

This is **not** the same thing as a general `/code-review`, if your project has one. It exists for one narrow purpose: hunting for the specific mistakes that are expensive to miss — destructive actions, security gaps, silent overwrites, secrets handling — not style, not general code quality, not test coverage.

**How to run it:**

| You type | What happens |
|---|---|
| `/qc-review` | Reviews everything changed in the *current session* (not since your last git commit — since the conversation started). |
| `/qc-review <file/module/description>` | Reviews exactly what you named instead. |

**The mechanism, and why it matters**: this runs as a **fresh subagent with zero memory of your conversation** — it has never seen the code being written, has no investment in it already being correct, and is told explicitly to be skeptical and hunt for one specific class of problem. This is the entire reason it works: the same conversation that just wrote the code is a weaker reviewer of that code than a cold, adversarial one. If it finds something, expect a severity rating (CRITICAL/HIGH/MEDIUM/LOW) and a concrete scenario, not a vague "consider reviewing this." If it finds nothing, it says so in one line — it does not pad the response to seem thorough.

**Where findings go**: verified findings (the assistant re-checks CRITICAL/HIGH claims directly before trusting them — a subagent's claim isn't treated as fact on its own) get written into your project's CLAUDE.md, under `KNOWN DEBT`, labeled `[QC review, <date>]` — so anyone reading it later (including a future AI session) can tell at a glance this came from an adversarial pass, not from someone noticing it during normal work.

**When to run it**: it'll be suggested — never run automatically — right before you'd treat security-sensitive code (auth, payments, credentials) as finished, right before a destructive-capable script (data deletion, migrations) is considered done, or right before a new hook gets wired in. You can also just run it any time you want a second, skeptical look at something.

**One honest thing worth knowing**: getting an actual "found nothing" result is rarer than you might expect for any file with real logic in it. In testing, two rounds of fixing real issues in a sample auth file *still* turned up another real, legitimate bug each time. That's the adversarial review doing its job, not a sign something's wrong with the tool or your code specifically — expect it to keep looking past the obvious fix.

## Decision guide — quick answers to "should I say yes or no here"

- **Brief vs. detailed explain mode?** Detailed if you're newer to this kind of setup or want to understand the why, not just the what. Otherwise brief — you can switch mid-run.
- **Dismiss the status hook's offer, or run `/foundry-init`?** If the project will stay a one-off script forever, dismiss it. If there's any real chance it grows (most things do), run init — the minimal/throwaway path is also a few seconds, and it's much cheaper to do this on day one than to retrofit months of work later.
- **`/promptify` or `/promptify!`?** See above — plain mode until you trust the pattern, `!` once you do.
- **Opt into qc-review's mechanical auto-run hook, or just use it on demand?** Stick with on-demand and the proactive offer (the default) unless you have one specific, unusually high-risk file or directory where you genuinely want a nag after every single edit. The mechanical hook fires after every edit, not at a real "I'm done" checkpoint — for most people, most files, this is more noise than signal.
- **Track STACK.md or not?** Yes if this is a portfolio project or anything you might discuss in an interview later. Skip it for work-for-hire you don't own the narrative of, or anything you wouldn't want to talk about publicly.

## What Foundry does NOT do (read this before you rely on it)

- **It is not a security audit.** The secrets-guard hook catches realistic filename patterns (`.env`, `*.pem`, `config.yaml`, etc.) — it does not catch a secret hardcoded inside an otherwise-ordinary source file, a secret pasted into a file with an innocuous name, or anything already committed before Foundry was set up (there's a separate check for that last one, but it's a scan, not a guarantee).
- **`qc-review` is not a substitute for a real security review** by someone qualified, especially for anything genuinely high-stakes (payments, health data, anything regulated). It's a fast, free, adversarial second opinion — a real and useful one — but treat a clean result as "nothing obvious was found," not as a certification.
- **Governance/compliance sections are a starting structure, not legal advice.** When Foundry writes "not yet researched — get this reviewed before relying on it," that sentence is the actual point, not boilerplate. Foundry will never fabricate a specific regulatory framework it can't verify applies to your project, and you shouldn't either.
- **The doc-loader hook only loads docs into context — it doesn't enforce that anyone reads or follows them.** A standing rule in CLAUDE.md is still just a rule; it works because the harness loads it automatically every session, not because anything stops an AI session (or a human) from ignoring it.
- **Foundry only touches the single directory you run it from.** It will not cascade into subdirectories, and it checks first whether you're actually in a project root rather than a folder full of unrelated projects.
- **Nothing here replaces your own judgment about what to commit, push, or deploy.** Foundry never commits automatically; it always asks first.

---

Built by [Tom Grow](https://www.linkedin.com/in/tomgrow/) — see the [README](README.md) for more, including how to reach out.
