# Engineering Playbook for Foundry

Project-agnostic. Each entry below is a principle first, with a real example
compressed to one sentence — never the other way around. If a principle only
makes sense with its example attached, it isn't distilled enough yet; that's
a bug in this doc, not a reason to keep the example long.

**Living document.** Add to it the moment a new lesson earns its place (see
the bar in "What belongs here" below). Don't batch edits for later — a
lesson not written down within the session that produced it usually doesn't
get written down at all.

**For whoever incorporates this into Foundry**: treat every principle as a
default to wire into CLAUDE.md templates, hook scaffolding, or skill
instructions — not as trivia to leave in a doc nobody reads. Where a
principle implies a mechanical check (a grep sweep, a pre-commit hook, a
gating env var), that's the part worth turning into an actual template or
hook, not just prose.

## What belongs here

Add an entry only if it passes all three:
1. **Would apply on a different project in a different language.** If the
   lesson only makes sense with a specific file path or framework in mind,
   generalize it or cut it.
2. **Changes a decision, not just a fact.** "X was broken" isn't an entry.
   "Verify Y before trusting X, because X can be broken in this specific
   way" is.
3. **Survives the "so what" test.** If following the principle wouldn't have
   changed what happened, it's an observation, not a lesson.

---

## Quality & correctness

### 1. Quality is the non-negotiable, not a dial

Correct/secure/best-practice over fast is a *default*, not a per-task
judgment call — apply it without being asked, every time, not just when
someone's watching.

- **Never trust an automated resolver's output without reading what it
  actually proposes.** Dependency-conflict auto-fixers, `--force` flags, and
  "just apply the suggested fix" tooling can propose a technically-valid but
  practically-nonsensical change (e.g., a resolver downgrading a core
  dependency by several major versions to silence a transitive advisory,
  because the graph-solver found *a* fix, not a *sensible* one). Read the
  diff of what would actually change before applying it.
- **A security-relevant gap with no non-breaking fix should be flagged
  loudly and left undone** — not half-fixed with a workaround that gives a
  false sense of resolution. Write down precisely what the real fix is (a
  version upgrade, an architecture change) so it's plannable later, instead
  of silently accumulating as invisible risk.
- **Before adding a "quick" safety measure, check whether it's actually
  load-bearing against the current architecture, or theater.** A protection
  mechanism that looks correct in isolation can be entirely inert given how
  the surrounding system actually works (e.g., a database-row-level
  permission system that a privileged/service-level code path bypasses
  completely — adding it without also removing or gating the bypass
  produces a false sense of security, not actual security). Trace the
  mechanism all the way through before claiming it protects anything.

### 1b. The dominant failure mode is a confident conclusion from an incomplete search

Observed acutely in one session where an assistant reached **four** wrong
conclusions. Every one was independently plausible, none was careless in the
moment, and all four shared one shape: *a search that stopped early,
reported as a settled fact.* The specific shapes generalize:

- **Multiple secondary sources agreeing, all sharing one omission.** Three
  independent third-party references described a vendor's pricing formula,
  and so did a docstring inside the codebase. All four quoted the formula's
  coefficient; none mentioned that the multiplier it applies to defaults to
  zero in one case and one in the other. The primary document reversed the
  conclusion — and the conclusion was load-bearing for a strategy decision.
- **An absence found in one location, reported as absence everywhere.**
  A credential wasn't in its conventional directory, so the capability was
  declared lost. It was in a non-standard path the assistant never asked
  about.
- **Names trusted instead of the code behind them.** Two log lines were
  compared to conclude a subsystem had failed. Reading the emitting code
  showed one fired *after* the operation succeeded (so it counted successes,
  not attempts) and the other was emitted at a level filtered out of
  production entirely, so it could never appear regardless of health. The
  subsystem was fine.
- **A sequencing recommendation that never checked its own premise** —
  "prerequisites" ordered ahead of work they did not actually block.

**Rules that would have caught all four:**
1. **Agreement among secondary sources is not verification.** N sources
   derived from the same upstream summary fail identically. Get the primary
   document — the vendor's own specification, the RFC, the emitting code.
2. **A negative result needs a wider search than a positive one.** "I found
   X" is self-validating; "X doesn't exist" is a claim about everywhere you
   didn't look. Before writing one down, ask what would have to be true for
   it to be wrong, and check *that*.
3. **Never treat a log name, a metric name, or a comment as evidence of what
   it measures.** Read the code that emits it, including its level and its
   position relative to the operation it claims to describe.
4. **"Deployed" is not "confirmed live"; "the service is running" is not
   "the service is working."** Measure the thing itself.
5. **When a conclusion is expensive to be wrong about, state what would
   falsify it** — then spend one more step trying to falsify it.

**And when wrong, retract in the durable docs explicitly** — with the wrong
claim, the correction, and the reason it was wrong — rather than quietly
editing it away. A silently deleted error teaches nobody, and future readers
of the surrounding documents have no way to calibrate how much to trust
them. Retractions are also the only durable signal that a document's
confident-sounding claims were ever audited at all.

### 2. Any code path touching real, shared infrastructure needs an explicit safety argument

Anything — test, script, or application route — that writes to something
real, shared, and persistent outside the local/ephemeral scope (a shared
database, cloud storage, a payment processor, an email/SMS provider, a
third-party API with side effects) must have an explicit, stated reason it's
safe to run repeatedly and automatically. The reason is always at least one
of:

- It cleans up after itself (transactional, or has a teardown step), or
- It's gated behind deliberate, non-default opt-in (a flag nobody sets by
  accident).

**The most common way this fails silently: a test or script inherits
ambient configuration from the environment instead of setting explicitly
what it needs.** Whatever config selects "real infrastructure" vs.
"local/mock" should be set explicitly, per test/script, never left to
whatever the ambient environment happens to be configured for at the
moment — ambient defaults are exactly how a write-to-production bleed
survives silently for a long time before anyone notices, because it works
correctly on every machine where the ambient default happens to be safe.

**Remediation shape, once caught late**: separate a read-only *report* tool
(classifies/counts, changes nothing) from a *cleanup* tool that is dry-run
by default and requires an explicit confirmation flag to actually mutate
anything. Never skip straight to a destructive action — even with prior
authorization, since authorization is scoped to that moment, not to future
runs of the same script.

---

## Documentation

### 3. Duplication across docs is fine; drift is the actual enemy

If docs at different depths (a quick-glance overview vs. a deep
architecture/handoff doc) intentionally repeat some facts for different
readers, that duplication *will* drift unless something forces it to stay
in sync. Two mechanisms, needed together — they catch different failure
modes:

1. **A pre-commit hook that blocks a commit touching source unless at least
   one doc file is staged alongside it.** Catches "forgot to document
   entirely." Cheap, mechanical, high signal. Should be opt-in on an
   existing project — a repo-wide hook is a shared-state change and
   deserves the owner's explicit enable step, never silent
   auto-configuration.
2. **A grep sweep across every doc for the specific claim that just
   changed, run before considering the change done.** Catches "updated one
   doc, missed the other N with the same claim" — which the hook above
   cannot catch, since it only knows *some* doc changed, not that the
   *correct* fact changed in *every* doc that stated it. Concretely:
   `grep -rn "<the exact claim that changed>" <every doc file>` and fix
   every file that surfaces, not just the one already being edited.

Neither alone is sufficient: the hook catches omission, the grep catches
partial correction.

### 3b. Make the handoff document self-propagating, or the chain silently degrades

Entry 10 covers *writing* a bridge document at a handoff. The failure mode
it doesn't cover is the chain **thinning out** over successive sessions:
session N writes a good bridge, session N+1 writes a thinner one, and by
N+3 the accumulated operating knowledge — environment quirks, working
preferences, standing rules — has quietly evaporated, while the
project-specific content survives because it's obviously relevant.

Fix, proven across a long multi-session chain: **the bridge document
instructs its own successor to carry the same closing instruction forward.**
The last line of every bridge is, in effect, "write the next bridge, and
make sure it repeats this instruction." Cheap, and it makes the chain
self-sustaining rather than dependent on each session remembering.

Extend that to a standing **carry-forward block**, kept in every bridge and
added to rather than rewritten:

- **Environment/operating facts** the assistant cannot infer (auth paths,
  tools that fail in certain modes, permission-mode quirks) — see 9d.
- **Working preferences** (batch questions rather than ending turns; where
  fetched reference documents get stored; who decides what).
- **The one or two disciplines that actually produced results** on this
  project, stated as instructions rather than history — e.g. "verify one
  level deeper than feels necessary, especially on a negative" (see 1b).
  These are *behavioural* instructions and therefore exactly the kind of
  thing that evaporates if not restated each time, because unlike project
  facts they never look obviously relevant to the next task.

The distinction that matters: **project state belongs in the durable docs**
(CLAUDE.md / DECISIONS.md and equivalents) and should only be *pointed at*
from the bridge; **operating knowledge and behavioural discipline belong in
the bridge itself**, restated every time, because nothing else carries them.

---

## Security architecture

### 4. An audit trail must resolve the real principal, never the acting-as identity

Any system with impersonation, delegation, "sudo," or role-elevation must
resolve "who did this" for its audit trail via the real, originally
authenticated identity — resolved independently of whatever elevated or
delegated context the action ran under. Logging the elevated/delegated
identity as the actor lets the elevation mechanism falsify its own audit
trail, which is exactly what the audit trail exists to prevent.

Concretely: build one specific, named function that bypasses every
elevation/impersonation path *by construction*, and route every audit-log
write through it — don't trust each call site to remember to resolve
identity correctly on its own. A convention that has to be remembered at
every call site is a convention that will eventually be missed at one of
them.

**A real cost worth designing for up front, not discovering as debt**:
resolving "real identity" independently at every audit-log call site is
wasted, avoidable work if the surrounding request already resolved the same
identity earlier for an authorization check. Either memoize identity
resolution per-request (many web frameworks have a request-scoped cache
primitive for exactly this — e.g. React's `cache()` in Next.js) or thread
the already-resolved identity explicitly into the logging call. Decide
which up front; retrofitting it after a dozen call sites already exist is a
much bigger, riskier change than building it in from the first call site.

---

## Review & verification workflow

### 5. Parallelize review by angle; keep the raw reading out of the main context

When a review needs to check a change from several independent angles
(correctness, security, style/simplification, performance, architectural
fit), run each angle as a separate parallel pass rather than one long
sequential review — two shapes that both work well:

- **Generate-then-filter**: one pass generates candidate issues broadly: a
  second, *parallel* set of passes — one per candidate — independently
  filters each candidate against a strict rubric, so only high-confidence
  findings survive. Filtering in parallel, one issue per reviewer, is much
  cheaper than one reviewer sequentially re-litigating every candidate.
- **Same-input, different-lens**: N reviewers look at the *same* change
  from N different fixed angles simultaneously (e.g.: does this duplicate
  existing functionality; is this needlessly complex; does this waste
  compute/IO; is this fix at the right depth or a bandaid on top of the
  real problem). Each reports back compressed findings (location + one-line
  cost), not prose — the orchestrating pass applies fixes afterward,
  deduping overlapping findings.

**Why this specifically matters for context/token budget**: the expensive
part — reading a large diff and reasoning about it from one angle — happens
in each reviewer's own disposable context. The orchestrating thread only
ever holds the compressed output, never the exploration that produced it.
This is the single biggest lever for keeping a long-running session's own
context small: delegate anything that requires reading a lot to produce a
little, and only bring the little part back.

**Corollary — a real finding isn't automatically a same-session fix.** When
a review surfaces something true but non-trivial to fix safely (touches
many call sites, needs dedicated testing), write it down precisely (what,
where, why, a suggested approach) as its own scoped follow-up rather than
rushing it in — especially late in a long session, which is exactly when
remaining attention is lowest and a rushed broad change is most likely to
introduce a new problem while fixing the old one.

### 5b. A constrained runtime can be broken by a transitive import, not just a direct one

Some execution environments (edge functions, browser bundles, serverless
functions with a restricted module set) can't load certain dependencies —
but that restriction applies to the whole import graph, not just what a file
imports directly. Importing one small, seemingly-safe symbol from a shared
module can pull in that module's *other* top-level imports too, including
ones with no relation to the symbol actually needed. A module built for a
full-featured runtime (crypto, filesystem, arbitrary npm packages) will
silently break a constrained-runtime file the moment anything imports from
it, even a single string constant.

**Before adding a cross-module import into a file running under a
constrained runtime, check what that module's own imports pull in** — not
just whether the specific export needed looks safe in isolation. If a
shared module has any dependency incompatible with the constrained runtime,
duplicate the one small piece actually needed (a string constant, a tiny
pure function) directly in the constrained file instead of importing the
module. A short, explicit comment at the duplication site pointing back to
the canonical definition prevents the two from drifting silently.

### 6. A textbook-correct API can still be wrong for this codebase — verify against the real test/runtime setup before adopting it

"This is the documented best-practice API for X" is a different claim from
"this API works in this project's actual test/runtime setup." This applies
with extra force to any API that depends on ambient/request-scoped context
— thread-locals, dependency-injection containers, per-request caches,
"run this after the response is sent" hooks — since these are exactly the
APIs most likely to silently assume infrastructure a given test harness
doesn't actually provide (e.g., a framework's "route-scoped" helper failing
outright when tests invoke the underlying handler function directly instead
of through the framework's full request pipeline).

**Always run the existing test suite immediately after adopting an API like
this, before treating it as done.** If it fails for an infrastructural
reason unrelated to the change's actual logic, that's a signal the fix
belongs to a different, larger decision (e.g., changing how the whole test
suite invokes the code under test) — revert cleanly rather than working
around the test harness to force the optimization through, and record
precisely why it failed so a future attempt doesn't have to rediscover the
same incompatibility from scratch.

### 7. Exhaust a careful static read before asking for a live reproduction

Asking for a live reproduction (browser dev tools, exact request/response,
timing) is the right move once a bug is plausibly environmental — but it's
also more expensive for the other person than another few minutes of
careful reading would have been, so treat it as a fallback, not a first
resort. A conclusion of "this can't be diagnosed from the code" should be
reached only after a genuinely careful, end-to-end read of the relevant
code path — not a skim — especially the failure-handling paths (what
happens on a thrown exception, a rejected promise, a malformed response)
that a skim tends to skip over entirely.

A strong, cheap lead before reaching for a live repro: **grep for the same
shape of bug that was just found and fixed elsewhere in the same codebase.**
A missing error-handling path in one place is evidence the same category of
mistake may exist nearby, and it's a much faster check than a live
reproduction.

**When the symptom involves a third-party service (payments, webhooks,
external APIs), check that service's own record of what actually happened
before debugging your own code.** A pipeline that looks stuck can be a
genuine application bug, or it can be a local infrastructure/config
mismatch (wrong port, stale process, expired credential) that perfectly
mimics one — the two are often indistinguishable from symptoms alone. Most
third-party services expose an audit trail (a CLI, a dashboard, an events
API) that shows definitively what was sent, received, and its actual
status — querying that first can immediately rule out an entire category of
suspects (e.g., confirming a payment genuinely succeeded on the provider's
side means the bug can't be in payment logic, only in delivery/receipt).

### 8. Open question — is a bounded recursive review→fix→reverify loop worth building?

Not yet resolved; recorded as a hypothesis to test, not a settled lesson.
The idea: after applying a fix, automatically re-run the review that found
it (or a narrower version) to confirm the fix didn't introduce a new issue,
looping a bounded number of times.

Tentative shape, if tried: **bounded and opt-in for specifically
high-consequence changes (security-sensitive, data-migration, concurrency)
— not a default wrapped around every fix.** A single review pass plus an
existing automated test suite already gives adequate confidence for most
changes; applying a recursive loop indiscriminately is over-engineering
relative to the risk. If built: cap it at 1–2 re-review iterations, gate it
explicitly (never silently trigger it), and always terminate on "no new
findings" rather than a fixed iteration count.

*Update this entry once it's actually been tried — right now it's a
hypothesis, not a lesson. If someone reading this in Foundry has tried it,
replace this paragraph with what actually happened.*

---

## Working with a human collaborator

### 9. Structured decision points, not open-ended back-and-forth — but it's not free

Batching decisions into one structured prompt (clear options, a labeled
recommended default, an explicit escape hatch for "none of these") is
cheaper for the person answering than serial open-ended questions — but it
is still a real pause for a real decision, not a way to eliminate turns.
What it actually buys:

- The full decision space is visible at once, instead of reconstructed from
  a paragraph of prose.
- A labeled default lets the person answer with one click when they agree,
  instead of composing a reply.
- Several independent decisions resolve in one round-trip instead of
  several serial ones.

Use it specifically **at genuine decision points** — a real design
trade-off, a scope call, "should this continue or stop" — never as a
substitute for a judgment call the assistant is actually equipped to make
alone. Defaulting to it for everything just relocates the same number of
decisions to a different UI without reducing how many round-trips a session
needs; it also trains the person to stop reading the options carefully once
they notice most of them don't matter.

### 9b. Open question — measure the actual efficiency gain from structured decision points

Not yet resolved; recorded as a planned experiment, not a settled result.
Entry 9 above argues batching decisions into `AskUserQuestion`-style
structured prompts is cheaper than serial open-ended back-and-forth — but
that claim has only ever been asserted qualitatively, never measured. A
session heavy on this pattern (2026-07-31) also had real confounding
overhead (tool outages, a self-inflicted regression) that made an honest
before/after read impossible from that session alone.

**If tried**: run two comparable sessions on similar-sized tasks, one using
structured batched questions at decision points, one using plain
open-ended back-and-forth, and compare round-trip count / wall-clock time /
token usage. Report the actual numbers here once done — don't state a
percentage or "X% faster" claim without real instrumentation behind it (see
the "never fabricate a quantitative claim" entry below).

**First observational data point (2026-08-02).** Not the controlled
experiment above — one session, no control arm, no token instrumentation
available to the assistant — so this is qualitative structural evidence
only, explicitly not a measured efficiency claim.

The person's stated approach was: stay in one turn wherever possible, use a
structured question prompt instead of ending the turn, and hand off tasks
the assistant *can't* do (retrieving a rate-limited document, changing a
permission mode) through that same mechanism. Four such prompts covered a
direction fork, a sequencing/model/continuation triple, a
deploy/continue/hygiene triple, and a close-out. What that structurally
bought, observably:

- **Work continued across every decision.** The assistant never had to
  re-establish what it had read, verified, or half-finished, because the
  turn never ended. In a session spanning documentation, live API queries,
  server administration and a code change, that accumulated state was
  substantial.
- **Blocked work was unblocked in-line.** A rate-limited document fetch and
  a malfunctioning permission mode were both resolved mid-turn rather than
  by stopping. The document specifically **overturned a wrong conclusion the
  assistant had already committed** — a stop-and-restart workflow would have
  shipped that error into the next session to be built on.
- **Genuinely independent questions batched cleanly**; questions with a
  hidden dependency did not (see 9c).

Honest costs, same session:
- **One turn ran very long**, which pushes toward context summarization and
  detail loss. One-shot working and knowing when to hand off (entry 10) pull
  in opposite directions; they need balancing, not maximizing one.
- **One batched question was asked too early and had to be effectively
  re-asked** when later investigation changed its premise — see 9c.

**Tentative read pending real instrumentation**: the pattern's value appears
to come less from saving round-trips than from *preserving working state and
enabling mid-task unblocking*. If that holds, it argues for using it during
a task and still handing off cleanly between tasks — not for maximizing
turn length.

### 9c. Ask the decision question *after* the investigation that informs it

Sequencing failure worth naming, from the same session. The assistant put a
significant direction fork to the person early, with a recommendation
resting partly on a quantitative argument. An hour later, the primary source
for that argument showed it was built on a misread, and the fork had to be
reopened with a corrected premise.

The person had already answered. Their answer was made on information that
turned out to be wrong, which is worse than not having asked yet — it costs
a re-ask *and* spends credibility.

**Rule**: before putting a decision to a person, ask what would change the
answer, and whether any of it is cheaply checkable first. If the deciding
input is one API call or one document away, get it before asking. Batching
is about grouping *independent* questions into one round-trip — it is not a
reason to ask before the answer is knowable.

Corollary for the same reason: **don't batch questions where one answer
determines whether another is even relevant.** A dependent question in a
batch produces an answer to a hypothetical, and the person can't see the
dependency from the options alone.

### 9c-ii. If the person works in long single turns, close every turn with a question — not a summary

Small mechanical rule with an outsized cost when missed. Where the working
agreement is "stay in one turn, ask rather than stop," the assistant must
make a structured question the **final action of every turn**, including
turns where the work is plainly finished.

Ending with a summary instead — however complete — forces the person to
spend a full round-trip just to say "one more thing," which is precisely the
cost the working agreement exists to avoid. Observed failing twice in one
session, both times *because* the work looked done: a tidy closing summary
feels like a natural terminator, so the rule gets dropped exactly when it is
most needed.

Two supporting details:
- **State it as a hard rule in the handoff document, not a preference** —
  soft phrasing ("prefer to ask") loses to the pull of a natural ending.
- **Don't manufacture an "Other"/"something else" option** if the question
  tool already supplies one; adding it is noise, and telling the person to
  use a feature they already have is worse.

### 9c-iii. Agree an explicit autonomy list — it removes questions without removing control

The complement to entry 9. Batching questions makes each round-trip cheaper;
an autonomy list removes round-trips entirely, and costs the person nothing
they actually wanted.

Put two short lists in the project's handoff document:

**Decide without asking** — typically: adding or updating tests when
behaviour legitimately changed; documentation structure and wording; commit
granularity and messages; repo hygiene (ignore rules, untracking artifacts,
cleaning up temp files the assistant created); choices among equivalent
implementations; refactors confined to code already being changed.

**Always ask** — typically: direction or scope calls with a real trade-off;
anything that spends money, sends something outward, or goes live; deleting
or gutting existing work; production changes beyond a routine verified
deploy; and any case where two readings of the request produce materially
different work — asked *before* the work, not after.

Two conditions that make the delegated half safe:
- **Delegated actions must still be reported**, in the commit message and
  the session log. Autonomy is about not *pausing*, not about not *telling*.
- **Test changes specifically must state why the test changed.** A silently
  rewritten failing test is indistinguishable from fudging a result — the
  reason is what separates "the behaviour intentionally changed" from
  "I made the red go away."

### 9c-iv. Ask for the time budget once, at the start

"Quick one" versus "I have a few hours" changes scoping from the first move:
whether to open a large build at all, or to take a bounded piece and hand
off cleanly. It is one question, asked once, folded into the session's first
structured prompt — and it prevents the much more expensive failure of
starting something substantial that has to be abandoned half-finished.

### 9d. Front-load environment constraints — they are cheap to state and expensive to discover

Same session: shell calls intermittently failed due to a permission-mode
quirk in the harness, and an SSH key turned out to live outside the
conventional directory. Neither was knowable from the repository. The
assistant burned repeated retries on the first and — worse — drew a
confident wrong conclusion from the second ("remote access lost"), wrote it
into three documents, and committed it, before the person mentioned in
passing that they had just logged in normally.

Both facts would have fit in two lines of the initial prompt.

**For the person**: state environment quirks up front — auth paths, tools
that behave oddly, permission modes, anything the assistant cannot infer
from the code. **For the assistant**: when something looks absent or broken
in the environment, treat it as *unknown*, not *missing*, and ask. The cost
asymmetry is severe — asking costs one question, and a wrong environmental
conclusion propagates into documentation that later sessions trust.

Once discovered, these belong in the project's durable handoff document, not
just in the session — see the bridge-chain entry under Documentation.

### 10. Know when to hand off to a fresh context instead of continuing

A long-running session accumulates context that's expensive to re-derive
but also expensive to keep carrying forward. Signals it's time to suggest a
fresh start rather than continuing:

- The session has crossed several unrelated milestones, each retained
  mostly for provenance rather than because it's still load-bearing for the
  next task.
- The next task only needs the **outcome** of prior work (what's true now —
  which should live in the project's own durable docs), not the detailed
  path that produced it.
- A real external constraint (time, quota, a stated preference) has been
  flagged by the person.

**The mechanism that makes a handoff cheap**: write a short bridge
document at the transition point — not a transcript dump, but "here's
what's true right now, here's exactly what's next, here's the standing
preferences that apply" — pointing at the project's own durable docs as the
source of truth rather than restating their contents. Keep it current if
anything changes between writing it and the handoff actually happening.

---

## Small, standalone lessons

- **Don't run a build/verification process from an assistant session that
  shares mutable state (a build cache, a lock file, a long-lived process)
  with a process the human already has running.** Ask them to verify
  visually/interactively instead of risking a corrupted shared cache from
  two writers.
- **An enforcement mechanism that exists only as convention-level comments,
  with no actual tool installed to enforce it, is a real gap — not a style
  nit.** An unenforced convention rots silently and tends to be hiding a
  real bug by the time anyone checks (dead code, a genuine defect, or both).
- **Extract an obviously duplicated block into a small named helper
  immediately when it's noticed during a review pass, even if unrelated to
  the task at hand.** Cheap, low-risk, and a review pass is the moment the
  duplication's shape is clearest in memory — deferring it means re-finding
  it later.
- **Record the "why" behind a decision, not just the "what."** The
  reasoning is what lets a later reader correctly judge an edge case the
  original decision didn't anticipate — a rule with no stated reason gets
  either blindly reapplied somewhere it doesn't fit, or blindly ignored
  once the person who understood it moves on.
- **A mechanical refactor applying the same transformation at many call
  sites should be split into logically-grouped, independently-verified
  commits** (build + lint + test pass before moving to the next group),
  not one large diff. Each group stays small enough to review and bisect on
  its own; if one group breaks something, the failure is isolated to a
  handful of files instead of the whole refactor.
- **Never fabricate a quantitative claim (time saved, tokens saved, percent
  faster) when there's no actual instrumentation behind it.** A confident-
  sounding made-up number is worse than an honest "I don't have telemetry
  for that, here's my qualitative read, and here's what real measurement
  would take" — the fabricated version looks like data and gets treated
  like data by whoever reads it later.
- **Before committing to a design's scope/risk when asked "is this safe,
  how big is it" — actually sample a few real, representative examples of
  the code being changed, not just describe the design in the abstract.**
  Reading 2-3 concrete call sites surfaces edge cases (unusual control
  flow, an already-mutated response object) that shape the honest size/risk
  answer far better than reasoning about the change in the abstract would.

---
*Update in place as new lessons surface — don't let this go stale the same
way project docs do (§3). When revising, re-check every entry against "What
belongs here" above; cut anything that's drifted into being project trivia
rather than a portable principle.*
