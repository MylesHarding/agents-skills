---
name: grooming-issues
description: "Groom an issue that is not yet ready for development — resolve the intent, scope, and direction of the ask using the best available evidence (repo conventions, precedent, the issue's own text), documenting each assumption made, then fill the issue body to the six-section groomed anatomy. Default is to proceed on your best interpretation, not to stall on a question; only escalate to the lead when a decision is irreversible/costly to get wrong or the ask gives no reasonable default to guess from. Captures the WHAT and WHY (product/spec intent), upstream of the technical-recon skill which decides the HOW and the LoE. Hard rule: never modify acceptance criteria that have already been written unless the operator explicitly asks — existing AC is an approved contract. Use whenever a lead hands you one or more raw, vague, or half-written issues to 'groom', 'flesh out', 'clarify', 'tighten the story', or 'get ready for tech review' before any technical recon or dispatch. For the narrow set of decisions that do warrant escalation, asks via an interactive question tool when one is available, otherwise via emoji-answerable issue comments, and resumes on rerun once the lead answers."
---

# Grooming Issues: capture the intent before anyone sizes or builds it

An issue can exist — a title, a paragraph, maybe a stakeholder's wish — long before it is buildable. Grooming is the pass that turns that into a story the team can trust: it resolves the intent, scope, and direction — by default using your own best judgment against repo conventions and precedent, not by stopping to ask — until the written issue **reflects the most reasonable interpretation of the ask**, then writes that into the body in the six-section groomed shape. It captures the *what* and *why*. It deliberately does **not** decide the *how* or the cost — that is the technical-recon skill, which runs next.

The pipeline: a raw issue → **grooming** (this skill: intent resolved, body groomed) → **technical-recon** (dev-side approach + LoE) → dispatch (per the orchestrating-slots and issue-locking skills). Grooming hands a clean story to recon; recon hands a sized, vetted issue to dispatch.

Compose with the siblings: the six-section anatomy and label taxonomy come from the issue-filing skill (gh-issue-filing / jira-issue-filing); the emoji-answerable clarification loop is the same one the technical-recon skill documents (reuse its comment format and template); when grooming completes, the technical-recon skill picks the issue up.

## Project bindings

Define in the adopting project's CLAUDE.md; referred to by placeholder.

| Binding | Meaning | Example |
|---|---|---|
| `<groomed-state>` | Label/status meaning "story is groomed, ready for technical recon" | a `groomed` label, or a `Ready for Tech Review` status |
| `<needs-input-state>` | "questions are pending the lead's answers" | `needs-spec-input` |
| `<ac-section-heading>` | The heading that marks the acceptance-criteria block in the body | `## Acceptance criteria` |

Grooming reuses the issue-filing skill's body anatomy and the technical-recon skill's question channels; it adds no labels of its own beyond the two states above.

## The one hard rule: do not touch existing acceptance criteria

If the issue already has acceptance criteria written, **leave them exactly as they are** — verbatim — unless the operator explicitly tells you to change them in this run. Existing AC is a contract that stakeholders may have negotiated and approved; an agent silently rewriting, tightening, or "improving" it changes the scope of work without anyone agreeing to the change. This has shipped the wrong thing in practice.

So:

- **AC already present** → preserve it byte-for-byte. If grooming surfaces that the AC looks wrong, incomplete, or contradicts the lead's stated intent, do **not** edit it — raise it as a question (`**Decision needed: the current AC says X but you described Y — keep / replace / add?**`) and let the lead decide. Only act on AC when the operator's answer authorizes it.
- **No AC yet** → you may draft acceptance criteria as part of grooming, but each item must be independently testable (issue-filing skill), cleared through the sweep below, and presented for the lead's confirmation rather than treated as settled.
- **Operator says "rewrite the AC"** (or similar explicit instruction this run) → then, and only then, edit it; record `ac=operator-edited` in the contract and note what changed in a comment.

Everything else in the body — title, symptom/context, desired behaviour, out-of-scope, open-questions-now-resolved, traceability hint — grooming may write and improve freely toward the issue-filing anatomy.

## Before finalizing AC: sweep for every instance, check live data

Two symptom shapes recur and need their own check before AC is considered final, not just a description review:

- **"X shows generic/wrong/missing content" — a repeated-defect shape, not a single-location bug.** When the symptom is "shows the wrong thing" rather than "this one line is wrong," AC drafted from only the first instance found systematically misses siblings — the same defect at every other call site with the same shape. Before finalizing, grep the codebase for every other location that emits/reads/renders the same kind of content, and either list every location found (for recon to cover in one pass) or state explicitly in the issue why only a subset is in scope this round.
- **AC whose correctness depends on the shape of real production data.** A criterion like "matches on X" that was checked only against the feature's own code, never against what live data actually looks like, can pass while doing nothing useful in production. Before finalizing AC that depends on data shape, pull a live sample (a query, a log excerpt, a real record) and confirm the AC's assumption holds against it.

Skip the sweep only when the symptom is provably a single-location defect (one call site, no siblings by construction) — say so explicitly in the issue rather than silently omitting the check.

## Default: resolve it yourself, document the assumption, move on

Most ambiguity in a raw issue has a reasonable default — an existing repo convention, precedent from a similar closed issue, or simply the most common-sense reading of what was asked. When you hit that kind of ambiguity, resolve it yourself: pick the interpretation you're most confident in, write it into the issue body under an explicit **Assumptions** subsection (one line per assumption, plain language, e.g. "Assuming this applies to the web client only, since the issue's examples are all browser screenshots and no mobile surface is mentioned"), and proceed straight to `<groomed-state>` in the same pass. This is the default path, not a fallback — treat the question channel below as the exception, reached only when a specific decision clears the escalation bar, not as the normal way grooming resolves intent.

Read the issue and any linked context first — the actual intent behind the request, scope boundaries, the definition of success, edge cases and error behaviour, affected users/surfaces, and any conflict between the existing text and other evidence — and resolve as much of it as you reasonably can from that evidence before ever reaching for a question.

**Escalate to the lead only when at least one of these is true for a specific decision:**

- **Irreversible or expensive to get wrong** — a data-model or security/permissions choice, deleting or overwriting something, or a fork in direction that gates a large amount of downstream work on picking correctly.
- **No reasonable default exists to guess from** — the text is self-contradictory, or names something (a system, a format, a destination) with no clue anywhere in the issue, its history, or the codebase as to which one is meant. Guessing here isn't a judgment call, it's fabrication.
- **The lead's own prior comments on this exact issue ask to decide it together** (e.g. "let's discuss before you build this").

Below that bar, you are not being asked for certainty — you're being asked to make the same call a competent engineer on the team would make without escalating, and to leave a visible paper trail (the Assumptions section) so a wrong guess is a one-line correction later, not a silent miss. A stalled issue costs a real slot of throughput waiting on a reply; a documented assumption costs nothing if it turns out right and is cheap to fix if it turns out wrong.

When escalation is warranted, questions go through the same two channels as the technical-recon skill, in priority order:

1. **Interactive ask-question tool, if the run has one** — multiple-choice with a recommended option and a write-in escape, then write the body in the same pass once answered.
2. **No question tool** (the usual fanned-out sub-agent case) — ask via **emoji-answerable comments**: one comment per question, each option tagged with a reaction emoji the lead clicks, a one-line legend at the bottom, kept within the tracker's reaction set (GitHub allows only 👍 👎 😄 🎉 😕 ❤️ 🚀 👀). Use the technical-recon skill's question-comment template verbatim. Then set `<needs-input-state>` and stop.

**"If the run has one" means checking your actual available tools, never assuming.** Confirmed failure mode: an agent running headlessly (spawned non-interactively, e.g. `claude --print`, with no lead attached) reasoned "this chat is the interactive question channel" and asked its questions as plain assistant text — which nobody ever reads, since a headless run's text output is only ever captured into a log, not a two-way conversation. That silently dead-ends the issue: no comment, no `<needs-input-state>`, and the run exits looking successful. Producing narrative text is not evidence an interactive channel exists. Before asking anything, check whether an actual interactive ask-question tool is present in this run's tool list. If it is not — which is always true for a headless/dispatched invocation — channel 1 does not exist for this run, full stop; go straight to channel 2 regardless of what the run "feels" like.

**HARD RULE: Ending your turn with clarifying questions expressed only in your own final assistant-message text — without having actually invoked either the interactive ask-question tool (channel 1) or `gh issue comment` (channel 2) — is itself a sandbox-contract violation, not a valid third option.** There is no "just tell them in my response" path. If a decision has genuinely cleared the escalation bar above, your turn is not done until you have either called the ask-question tool, or made an actual `gh issue comment` call plus set `<needs-input-state>`. Printing the questions and stopping is exactly the bug this fix exists to prevent.

**Rerun to continue (resume, not restart).** When grooming stalls on posted questions, the lead reacts/answers and reruns the groom command. On rerun, read your prior questions and the lead's reactions/replies first — **fetch reactions explicitly via `gh api repos/<owner>/<repo>/issues/comments/<comment_id>/reactions` for each of your question comments** — fold them in (a written reply overrides a reaction), then write the groomed body and move to `<groomed-state>`. Never re-ask an answered question.

## The sandbox

Allowed: read the issue, its comments, and linked context (lightly read the repo only for the context needed to ask good questions — deep code tracing is recon's job, not grooming's); use the interactive ask-question tool if present; post emoji-answerable question comments; edit the issue body's non-AC sections toward the groomed anatomy; set `<groomed-state>` / `<needs-input-state>`.

Forbidden — stop and emit `GROOM-ERROR: <what was attempted>`:

- Modify existing acceptance criteria without an explicit operator instruction this run (the hard rule above).
- Assert a technical approach or a level-of-effort — that is the technical-recon skill; grooming that pre-judges the build biases the estimate.
- Claim/assign the issue, write code, or open a PR.
- Mark the issue ready-to-dispatch — grooming earns `<groomed-state>`, not dispatch-readiness; technical-recon earns that.
- End your turn with clarifying questions expressed only as plain assistant-message text, without having called either the interactive ask-question tool or `gh issue comment` — this is the sandbox-contract violation that the text-only-questions bug exists to prevent. If a decision cleared the escalation bar, you must invoke one of the two channels or you have not actually asked the question.

## Verdict and handoff

| Verdict | When | State set |
|---|---|---|
| **groomed** | Intent resolved (by direct evidence or a documented assumption); body meets the six-section anatomy; existing AC preserved (or operator-authorized edits applied) | `<groomed-state>` — the issue is ready for `/gh-issue-recon` or `/jira-issue-recon` |
| **needs-spec-input** | A specific decision cleared the escalation bar (irreversible/costly, or no reasonable default exists) and is pending the lead's answer | `<needs-input-state>` + the question comments; rerun to continue |

## Output contract

Each grooming agent ends with exactly one line:

```
GROOM <id>: verdict=groomed ac=<preserved|added|operator-edited> assumptions=<N>
GROOM <id>: verdict=needs-spec-input questions=<N> (awaiting the lead's answers; rerun to continue)
GROOM-ERROR: <message>
```

Validate against what was actually written (`gh issue view <N>` / `getJiraIssue`): the body changed, existing AC is byte-identical unless `ac=operator-edited`, the state moved, and `assumptions=<N>` matches the number of lines actually written under the Assumptions subsection (0 if the ask had no material ambiguity to resolve).

**Before reporting `questions=<N>` where N > 1, re-fetch your own posted comments and count them.** A confirmed failure mode: two distinct open questions landed in a single comment instead of two separate ones — reactions on one comment can't disambiguate which question they answer (worse when both questions happened to reuse the same emoji for different meanings), silently breaking the lead's ability to respond. If the count doesn't match N, split the offending comment into separate ones now, in this same turn, before stopping.

## Anti-patterns

- **Rewriting approved acceptance criteria** because it "reads better" — the headline failure this skill exists to prevent.
- **Escalating a decision that had a reasonable default.** Stalling the queue on a question a competent engineer would have just answered defeats the point of this skill — resolve it and document the assumption instead.
- **Guessing on a decision that actually cleared the escalation bar.** An irreversible/costly call, or one with no reasonable default to guess from, is fabrication if you paper over it with confident-sounding text instead of asking.
- **An Assumptions section with no real assumption in it**, or a material assumption made but not written down — either way the paper trail that makes a wrong guess cheap to fix is gone.
- **Doing recon's job.** Implementation approach and LoE belong to the technical-recon skill; grooming that asserts them biases the later estimate.
- **Inventing scope.** Out-of-scope and success criteria never grounded in evidence or a documented assumption become accidental requirements once they are in the body.

## Token discipline: caveman working, humanizer for the story

Grooming runs in the same high-volume loop as the sibling skills — operate in **caveman mode** (load the `caveman` skill) for working output (reasoning, the batch summary, status), keeping machine-precise content byte-exact (labels/fields, JQL, `gh`/MCP commands, the `GROOM` contract line, and any existing acceptance-criteria text — which is byte-exact by rule anyway).

But the body you write into the issue is the story a human reads and an implementer builds from — its prose (symptom/context, desired behaviour) is not caveman. Draft it naturally and run it through the `humanizer` skill before saving, so the groomed issue reads human-written. Leave existing AC, any `file:line` refs, and the contract line exactly as captured.
