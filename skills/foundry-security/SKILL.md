---
name: foundry-security
description: Set up a security baseline for a project that handles secrets/credentials — .gitignore patterns, a .env.example convention, and a check for already-committed secrets. Use when a project handles API keys, credentials, or other sensitive config, whether during initial Foundry scaffolding or retrofitted onto an existing project.
---

# foundry-security

Establishes the mechanical security baseline that CLAUDE.md's Security Rules section (written by `foundry-docs`) describes in prose. This skill makes those rules actually true on disk, rather than aspirational.

**`EXPLAIN_MODE`** (set by `foundry-init`, or ask if standalone): in `detailed` mode, explain step 3 (the already-committed-secrets check) clearly before running it — specifically that a credential is compromised the moment it's pushed anywhere, even if later deleted from the latest commit, because git history retains it; this is why rotation comes before history-scrubbing, not after. In `brief` mode, just run the checks.

## Steps

1. **`.gitignore` baseline.** Check the project's existing `.gitignore` (create one if absent). Ensure it includes, at minimum, this pattern set — independently verified against a 25-file adversarial fixture (catches `secrets.env`, `config.yaml.bak`, `real.key.txt`, `aws_credentials.json`, `my-credentials.yaml`, `src/config/secrets.yaml`, etc.; does not false-positive on `.env.example`, `secretary_notes.txt`, `api_keynote.md`, `the_keymaster.rb`, `monkey.py`, `notes.md`, `package.json`):
   ```
   .env
   .env.*
   !.env.example
   *.pem*
   *.key*
   config*.yaml*
   config*.yml*
   secret*.yaml
   secret*.yml
   secret*.env
   secret*.json
   *secret*.yaml
   *secret*.yml
   *secret*.json
   *_secret.*
   *-secret.*
   *credential*.yaml
   *credential*.yml
   *credential*.json
   *.credentials*
   ```
   An earlier version of this baseline used only the bare tokens (`.env`, `*.pem`, `*.key`, `config.yaml`, no wildcards around them) — an independent security review caught that this misses any filename with a suffix after the dangerous token (`.bak`, `.txt`, etc.) or a prefix before it (`secrets.env` vs. just `.env`). The pattern set above closes that gap; don't narrow it back to bare tokens for the sake of looking simpler.

   Note this baseline does **not** ignore source code files that merely contain "secret" in their name (e.g. `app_secret_key.rb`) — `.gitignore` glob syntax can't reliably distinguish that from a false-positive like `secretary_notes.txt` (bare `*secret*` would catch both). That class of risk — a real secret hardcoded inside an otherwise-legitimate source file — is handled by the secrets-guard commit hook (`foundry-hooks` Hook 2), which uses regex with proper word-boundary matching, not by `.gitignore`.

   Adjust/extend the config-filename patterns to match whatever real-config filename the project actually uses if it doesn't fit the patterns above (ask if unclear — don't guess a filename that doesn't exist in this project). Merge with existing `.gitignore` content; don't overwrite. Before trusting any addition to this baseline, verify it the same way this version was verified: build a small adversarial fixture set (secret-like names with suffixes/prefixes, and legitimate names that merely contain "key"/"secret"/"env" as substrings) and check both directions with `git check-ignore`, not just the one obvious case.

2. **`.env.example` convention.** If the project uses a `.env` file (or is about to), check whether a `.env.example` exists alongside it with the same variable names but placeholder/empty values. If `.env` exists but `.env.example` doesn't, offer to generate one by reading `.env`'s variable *names* only — never echo real values into the example file or into any tool output. If `.env` doesn't exist yet, this step is a no-op for now.

3. **Check for already-committed secrets.** This is the single most consequential check in this skill — a false negative here means telling the user their project is fine when a real credential is sitting in git history. Do not rely solely on a narrow, exact-filename search; an earlier version of this check only searched `.env config.yaml '*.pem' '*.key'` plus whatever filenames the user happened to name, which silently misses anything not on that list (e.g. `secrets.env`, `creds.json`, `config/prod.yaml` — exactly the kind of names a real project is likely to actually use). Do both:
   - **Targeted search** (the narrow check, still useful as a quick first pass): `git log --all --full-history -- .env config.yaml '*.pem' '*.key'`, adjusted for any project-specific filename already named in CLAUDE.md's Security Rules section.
   - **Broad historical scan** (the check that actually catches names you didn't think to ask about): `git log --all --diff-filter=A --name-only --format="" | sort -u | grep -iE 'env|secret|key|pem|cred|password|token|config'` — this lists every filename ever added across all history matching common secret-adjacent keywords. Show the **full candidate list** to the user and ask them to confirm or deny each one that isn't obviously safe (test files, `.example` files, and source files like `config.py` are usually fine; anything that looks like real config/credentials needs a direct answer, not an assumption).
   If anything turns up from either check:
   - Stop and tell the user immediately, plainly, without minimizing it.
   - Recommend: rotate the credential first (this is more urgent than cleaning git history — a credential in git history is compromised the moment it was pushed anywhere, regardless of whether it's later removed).
   - Before offering history-rewrite as a next step, check whether this is a shared/collaborative repo: are there other contributors (check `git log --format='%an' | sort -u` for multiple distinct authors), other branches that diverge from main, or any indication of branch protection on the remote. If any of these are true, rewriting history and force-pushing will break every other collaborator's local clone and any open PRs — say this plainly and recommend the user coordinate with collaborators or consult their platform's docs (e.g. GitHub's own secret-purging guidance) before proceeding, rather than just confirming git-safety rules and moving ahead.
   - Only after rotation, and only for projects confirmed solo/uncomplicated by the check above, offer `git filter-repo` (or equivalent) to scrub history — and confirm the user understands this rewrites history and requires a force-push, which needs their explicit confirmation per standing git-safety rules.

4. **Wire the secrets-guard pre-commit hook** by invoking `foundry-hooks` (Hook 2) if not already done.

## What this skill does NOT do

It does not scan for secrets accidentally hardcoded *in source code* (e.g. a string literal API key) — that's a different, harder problem (secret-pattern scanning tools exist for this, e.g. `gitleaks`, `trufflehog`; Foundry doesn't bundle one but can recommend wiring one in via a `PreToolUse` hook if the user wants that level of rigor — treat as a future addition, not assumed present).
