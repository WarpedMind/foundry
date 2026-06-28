---
name: foundry-security
description: Set up a security baseline for a project that handles secrets/credentials — .gitignore patterns, a .env.example convention, and a check for already-committed secrets. Use when a project handles API keys, credentials, or other sensitive config, whether during initial Foundry scaffolding or retrofitted onto an existing project.
---

# foundry-security

Establishes the mechanical security baseline that CLAUDE.md's Security Rules section (written by `foundry-docs`) describes in prose. This skill makes those rules actually true on disk, rather than aspirational.

**`EXPLAIN_MODE`** (set by `foundry-init`, or ask if standalone): in `detailed` mode, explain step 3 (the already-committed-secrets check) clearly before running it — specifically that a credential is compromised the moment it's pushed anywhere, even if later deleted from the latest commit, because git history retains it; this is why rotation comes before history-scrubbing, not after. In `brief` mode, just run the checks.

## Steps

1. **`.gitignore` baseline.** Check the project's existing `.gitignore` (create one if absent). Ensure it includes, at minimum:
   ```
   .env
   .env.*
   !.env.example
   *.pem
   *.key
   config.yaml
   ```
   Adjust the last line to match whatever real-config filename the project actually uses (ask if unclear — don't guess a filename that doesn't exist in this project). Merge with existing `.gitignore` content; don't overwrite.

2. **`.env.example` convention.** If the project uses a `.env` file (or is about to), check whether a `.env.example` exists alongside it with the same variable names but placeholder/empty values. If `.env` exists but `.env.example` doesn't, offer to generate one by reading `.env`'s variable *names* only — never echo real values into the example file or into any tool output. If `.env` doesn't exist yet, this step is a no-op for now.

3. **Check for already-committed secrets.** Run `git log --all --full-history -- .env config.yaml '*.pem' '*.key'` (adjusted for the project's real filenames) to check whether any of these were ever committed, even if since deleted — git history retains them. If anything turns up:
   - Stop and tell the user immediately, plainly, without minimizing it.
   - Recommend: rotate the credential first (this is more urgent than cleaning git history — a credential in git history is compromised the moment it was pushed anywhere, regardless of whether it's later removed).
   - Only after rotation, offer `git filter-repo` (or equivalent) to scrub history — and confirm the user understands this rewrites history and requires a force-push, which needs their explicit confirmation per standing git-safety rules.

4. **Wire the secrets-guard pre-commit hook** by invoking `foundry-hooks` (Hook 2) if not already done.

## What this skill does NOT do

It does not scan for secrets accidentally hardcoded *in source code* (e.g. a string literal API key) — that's a different, harder problem (secret-pattern scanning tools exist for this, e.g. `gitleaks`, `trufflehog`; Foundry doesn't bundle one but can recommend wiring one in via a `PreToolUse` hook if the user wants that level of rigor — treat as a future addition, not assumed present).
