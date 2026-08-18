# Proposal — improvements to the `oneshot` skill, from one long live session

**Date:** 2026-08-17
**Source:** a single ~20-turn session that used `oneshot` throughout — roughly 16
`AskUserQuestion` calls carrying ~22 questions. Everything below is stated
project-agnostically; the observations came from one project but none of them depend on it.

**Status: proposal, not applied.**

---

## The headline finding: the two halves of `oneshot` do not perform equally

The skill has two mechanisms. They should not be treated as equally valuable, and
currently the skill implies they are.

**Front-loading (Step 2) earned its keep by a wide margin.** A four-question opening batch
settled the architectural approach, the target audience, a major posture decision and the
deliverable format *before* any work started. Two of those four answers contradicted what
would otherwise have been the default assumption. Had the work proceeded on those
defaults, the entire first deliverable and everything derived from it would have been
built on a wrong foundation. The counterfactual cannot be proven, but the magnitude is not
close.

**The always-close-with-a-question convention (Step 5) roughly broke even.** Of ~16 calls,
about six were semantically near-identical variations on *"ready to proceed?"*. Each cost
a full round trip. Direct savings from batching across the whole session was about six
turns; the redundant closers gave much of that back. In a long session — where every turn
re-reads the entire conversation — a redundant closing question is one of the more
expensive things you can do.

**Suggested change.** State the asymmetry explicitly in the skill, and let it direct
effort: spend real design thought on the opening batch's options, and treat closing
questions as lightweight. Add a guard along these lines:

> **Do not re-ask a question you have already asked in substance.** If the previous turn
> closed with "ready to proceed?" and the user chose more work instead, the next closing
> question must offer *materially different* options — not a rephrasing. Three consecutive
> closers that all reduce to "shall we start now?" is the filler-menu failure this skill
> is supposed to prevent, in its most common form.

---

## 1. Option text must be self-explanatory to someone who has not read the turn

**Observed:** the user asked, separately, what a "handoff block" was, what a "spike" was,
and what a "mission brief" was — each after those exact terms had appeared inside option
labels or descriptions. The terms had been introduced earlier in the conversation, and
each time the assistant had assumed they had landed.

Options are read differently from prose. They are scanned, often on a phone, sometimes
after a gap of days. Any term of art inside an option is effectively unglossed.

**Suggested change.** Add to Step 2's option guidance:

> Write every option label and description so it is comprehensible to someone who has not
> read the surrounding turn. Do not use a term of art inside an option unless it is either
> universally understood or re-glossed in the same sentence. If a concept needs
> explanation, explain it in the prose *above* the question, not inside the options — and
> if you cannot compress it, that is a signal the user is not yet ready to choose.

---

## 2. Accidental submission is a real failure mode and needs a recovery path

**Observed:** the user submitted an `AskUserQuestion` by pressing enter unintentionally,
losing the option set, and had to ask for it to be re-offered. The pattern makes this
easy — the question arrives as an interactive prompt in the flow of typing.

**Suggested change.** Add to Step 5:

> If a reply to a closing question maps to no offered option, does not read as a directive,
> and does not engage with the question's subject, treat accidental submission as a live
> possibility. Re-offer the question rather than picking the closest option and proceeding.
> The cost of re-offering is one round trip; the cost of proceeding on a phantom answer is
> the work that follows it.

---

## 3. "Is that actually your recommendation?" is a signal, not a question

**Observed twice in one session.** Foundry's decision log already identifies this as the
symptom of a devalued "(Recommended)" label. Confirmed here — and the useful part is what
happened next.

The correct response is not to defend the recommendation. On one occasion the honest
answer was *"it was a real recommendation, but you have exposed a flaw in it, and here is
the revision"*; on another it was *"you are right and I was wrong, here is why."* Both
restored the label's credibility. A confident restatement would have destroyed it.

**Suggested change.** Add to the recommendation guidance:

> When a user asks whether a recommendation is genuine, that is a report that the label has
> lost credibility — not a request for reassurance. Re-derive the recommendation from
> scratch and say plainly what you find, including "you are right and I was wrong."
> Restating a recommendation more confidently in response to this question is the single
> fastest way to make the label worthless.

---

## 4. A standing directive should suppress the closing question

**Observed:** the user said, in effect, *"proceed however you recommend."* The skill's
Step 5 requires closing with a permission question regardless — which asks the user to
make the choice they just delegated. This creates a real tension the skill does not
currently acknowledge.

**Suggested change.** Add an explicit carve-out:

> When the user has just delegated the decision ("proceed however you recommend", "your
> call", "you decide"), do not close by asking them to choose. State the decision you made
> and why, do the work, and close with a lighter confirmation that reports what happened
> and offers a genuine fork only if one now exists. Honouring the letter of the
> always-close rule while ignoring an explicit delegation is worse than not asking.

---

## 5. Verification claims need the same evidence standard as any other claim

**Observed, and this was the sharpest lesson of the session.** The assistant ran two full
consistency scans over a document set and reported both clean. The user asked whether the
scans were *genuinely* clean or merely not looking hard enough.

The scans were then **mutation-tested**: 23 known defects, one per class the scan claimed
to detect, were injected and the scan re-run on each. **Three escaped.** Two were genuine
blind spots in the checks; chasing the third surfaced a real defect in the documents.

The clean result had been partly luck, and no amount of re-running the same scan would
have revealed that — a check that silently tests nothing passes forever, and reads as
reassurance.

**Suggested change.** This generalizes past `oneshot`, but the closing-out convention is
where it becomes visible, because that is where results get reported:

> Do not report a verification as clean without evidence the verification can fail.
> Where the check is mechanical, prove it by injecting a known defect of each class it
> claims to catch and confirming detection. Where it is judgment-based, say so explicitly
> rather than letting it inherit the authority of a mechanical result. "I checked and found
> nothing" and "I checked with something demonstrated to find this class of thing, and
> found nothing" are very different claims, and only the second should be offered as
> assurance.

---

## Not proposed

**Reducing the number of questions per batch.** Four-question batches were answered
substantively in this session, including the fourth. Foundry's decision log already records
that an assistant's discomfort with the shape of its own output is not evidence about that
output's usefulness — and that guard held up here. No change warranted.
