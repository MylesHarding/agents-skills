---
name: technical-recon
description: "Technical recon of an already-groomed, stakeholder-accepted issue that the dev team has not yet vetted or sized — dispatch a read-only sub-agent (one per issue, in parallel for a batch) to trace the ask into the codebase, produce a verified implementation approach, assert a level-of-effort (LoE) estimate with confidence, surface risks/unknowns/dependencies, recommend a split when the work is too big for one PR, and pin the eventual dispatch model/effort/lane — then post the findings to the issue and move it to a dev-vetted state. Use whenever an engineering or project lead hands you one or more issue numbers/keys to 'recon', 'scope', 'size', 'estimate', 'tech-review', or 'assess implementation' before any code is written; also use when deciding whether a groomed issue is actually ready for a dev dispatch. This is the deeper dev-side pass, distinct from the cheap intake-triage recon in the issue-filing skill."
---

# Technical Recon: scope, size, and de-risk a groomed issue before dispatch

An issue can be fully groomed and accepted by stakeholders — clear symptom, desired behaviour, acceptance criteria — and still be unsafe to dispatch, because nobody on the dev team has confirmed *how* it would be built, how big it is, or what it might break. Technical recon closes that gap: a read-only sub-agent traces the ask into the actual codebase and returns an implementation approach, a level-of-effort estimate, the risks, and a dispatch recommendation. The issue moves from "stakeholders want this" to "the dev team knows what this costs and how to build it."

This is **not** the intake-triage recon in the issue-filing skill (gh-issue-filing / jira-issue-filing). That one runs a cheap model to classify *stub* issues into ready-to-dispatch / needs-spec-input / blocked by a five-rule decision tree, with a capped blast radius. Technical recon is the opposite end: the issue is already groomed, and the question is the engineering answer — design, cost, risk — which needs a capable model reading real code, not a cheap classifier. The two compose: intake-triage decides an issue is *specified*; technical recon decides it is *buildable* and *sized*.

Compose with the siblings: dispatch the recon agents with the dispatching-subagents skill; read the issue and post findings with the issue-filing skill's anatomy conventions; set the resulting labels/fields with the control-field skill (gh-issue-labels for GitHub, jira-issue-fields for Jira); and when recon clears an issue, the orchestrating-slots loop dispatches the implementation per the issue-locking skill (gh-issue-locking / jira-issue-locking). Recon itself never claims, never writes code, never opens a PR.

## Project bindings

Define these in the adopting project's CLAUDE.md; the body refers to them by placeholder.

| Binding | Meaning | Example |
|---|---|---|
| `<loe-scale>` | The LoE vocabulary the team estimates in | T-shirt `XS\|S\|M\|L\|XL` (below) |
| `<recon-model>` | Model tier for recon — a capable one, never the cheap tier | `sonnet` (escalate to `opus` for deep/cross-cutting asks) |
| `<vetted-state>` | The label/status meaning "dev-vetted, ready to dispatch" | `ready-to-dispatch` |
| `<needs-input-state>` | "a technical decision must be made before build" | `needs-spec-input` |
| `<blocked-state>` | "a dependency must land first" | `blocked` |
| `<loe-field>` | Where the size is recorded | a `loe:<size>` label, or the Jira Story-points / a custom field |
| `<shared-surfaces>` | Contention-prone files that mark the plumbing lane (see the issue-filing skill) | DB schema, API schema, shared types, design tokens, root manifest/lockfile |

Default `<loe-scale>` (override per project): **XS** ≈ <½ day, trivial/local; **S** ≈ ~1 day, one surface; **M** ≈ 2–3 days, a few surfaces; **L** ≈ ~1 week, multi-surface or migration; **XL** > 1 week → **must be split** (recon proposes the split rather than sizing it whole).

## The recon is read-only — the sandbox

A recon agent investigates and reports; it changes no code and no work-tracking state beyond its own findings on the one issue it was given.

Allowed:

- Read any repo file; `git grep`, `git log`, read the dependency graph and tests.
- Read the issue and its comments (`gh issue view` / `getJiraIssue`) — including its own prior recon questions and the lead's answers, on a rerun.
- Use the interactive ask-question tool, if the run provides one, to clarify direction with the lead (see the next section).
- Post the findings as ONE comment; when asking, post one emoji-answerable comment per open question (see below). On a rerun, read the reactions on your prior question comments.
- Set the LoE field and the verdict label/status on that issue (per the control-field skill).

Forbidden — on attempting any, stop and emit `TECH-RECON-ERROR: <what was attempted>`:

- Edit or write any repo file; open a branch or PR.
- Claim/assign the issue or set the active-lock marker — claiming is dispatch-time, owned by the orchestrator (see the issue-locking skill). Recon that self-assigns forges a claim other operators honour.
- Mutate any other issue, or any PR.
- End your turn with clarifying questions expressed only as plain assistant-message text, without having called either the interactive ask-question tool or `gh issue comment` — this is the sandbox-contract violation that the text-only-questions bug exists to prevent. Below 90% confidence, you must invoke one of the two channels or you have not actually asked the question.

## Reach ≥90% on direction before you size

A groomed issue says *what* stakeholders want; it rarely pins *how* they want it built when the codebase offers more than one defensible path, and the wrong path is a wrong estimate. So: **investigate first, then — for any ambiguity that materially changes the approach, scope, or LoE — get the lead's direction until you are ≥90% confident you are sizing the thing they actually want.** Investigating before asking is what makes the questions worth asking: each one is concrete and code-grounded, with options drawn from what the code actually allows — never a lazy open-ended "how should I build this?". Below 90%, ask; do not size.

Two channels, in priority order:

1. **Interactive ask-question tool, if the run has one.** Ask multiple-choice questions — each with a recommended option first and a write-in escape — looping until ≥90%. Then proceed in the same run to the full findings and verdict.

   **"If the run has one" means checking your actual available tools, never assuming from context.** Confirmed failure mode: a headlessly-spawned agent (e.g. `claude --print`, no lead attached) reasoned "this chat is the interactive channel" and asked its questions as plain assistant text — text nobody ever reads, since a headless run's output is only ever captured into a log, not a live conversation. That silently dead-ends the issue: no comment, no `<needs-input-state>`, run exits looking successful. Being able to produce narrative text is not evidence an interactive channel exists. Check whether an actual interactive ask-question tool is present in this run's tool list before using channel 1 — for a headless/dispatched invocation it never is, so treat channel 1 as absent unconditionally and go straight to channel 2.

   **HARD RULE: Ending your turn with clarifying questions expressed only in your own final assistant-message text — without having actually invoked either the interactive ask-question tool (channel 1) or `gh issue comment` (channel 2) — is itself a sandbox-contract violation, not a valid third option.** There is no "just tell them in my response" path. If you are below the 90% confidence threshold, your turn is not done until you have either called the ask-question tool, or made an actual `gh issue comment` call plus set `<needs-input-state>`. Printing the questions and stopping is exactly the bug this fix exists to prevent.
2. **No question tool available** — the usual case for a fanned-out sub-agent, which runs non-interactively. Ask through **emoji-answerable comments** so the lead replies in one click, no typing:
   - **One comment per question.** Reactions on a single comment can't disambiguate multiple questions, so each open question (or each proposed direction to confirm) gets its own comment. Quote the ambiguous part, then list each option on its own line tagged with the distinct reaction emoji the lead clicks to choose it; for a yes/no, use 👍 confirm / 👎 deny on the proposed-direction comment.
   - **Stay within the tracker's reaction set.** GitHub allows only eight reactions — 👍 👎 😄 🎉 😕 ❤️ 🚀 👀 — so map options onto those (e.g. 👍 = option A, 🎉 = B, 🚀 = C, 👀 = "none, see my reply") and never use number/letter emoji there; Jira's set is wider, but keep the mapping explicit either way.
   - **Before posting, check every emoji you're about to use against that exact eight-item list — not "does this emoji fit the meaning", but "is this literal character one of the eight."** Confirmed live: an agent picked emoji for how well they matched each option's *meaning* (🤔 "decide later", ✅/❌ for yes/no, ⏸️/🔄 for "before/parallel/after") instead of checking them against the tracker's actual reaction set — none of those five are real GitHub reactions, so the lead had no way to react to any of them and had to wait for a corrected comment. The eight-item list above is exhaustive, not illustrative — if the emoji you want isn't literally in it, pick one of the eight and say what it means in the legend instead of reaching for a better-fitting one.
   - **End every question comment with a one-line legend** stating exactly which emoji does what — e.g. `↩ React: 👍 keep current auth · 🎉 switch to sessions · 🚀 do both · 👀 none (reply below)`. The legend is mandatory; an un-legended emoji prompt is a guessing game.
   - **If you notice a question comment you already posted (this run or a prior one) used an invalid emoji or crammed more than one question into it, fix that exact comment — don't leave it live and post a replacement alongside it.** Get the comment's id from `gh issue view <N> --json comments` (or `getJiraIssue`), then edit it in place — `gh api -X PATCH repos/<owner>/<repo>/issues/comments/<comment_id> -f body=<corrected text>` (Jira: update the comment via its own API) — so there is exactly one live prompt per question, not an invalid original sitting above a comment that says "replaces earlier comment." Confirmed live: a corrected comment was posted as a new reply while the original, unreactable prompt stayed visible above it — the lead saw the broken one first and had already tried (and failed) to react to it before finding the fix further down the thread.
   - Set `<needs-input-state>` and **STOP — do not guess an LoE.**

   On rerun, recover the answers from each question comment's **reactions** (plus any written reply — a written reply always overrides a reaction), then continue.

   One question, one comment, shaped like this:

   ```markdown
   **Recon — 1 decision needed before I can size this:**

   The issue says: > <quoted ambiguous line, verbatim>

   Which direction do you want?
   - 👍 <option A — concrete, code-grounded>
   - 🎉 <option B — concrete>
   - 🚀 <option C — concrete>
   - 👀 none of these — I'll reply below

   ↩ React to choose: 👍 A · 🎉 B · 🚀 C · 👀 none (then reply). Re-run recon and I'll resume from your answer.
   ```

**Rerun to continue (resume, not restart).** When recon stalls on posted questions, the lead answers them in the issue and reruns the recon command. On rerun, the agent FIRST reads its prior questions and the answers from the issue comments — **fetch reactions explicitly via `gh api repos/<owner>/<repo>/issues/comments/<comment_id>/reactions` for each of your question comments** — folds them into its understanding (a written reply overrides a reaction), and — if now ≥90% — proceeds to the full findings and a `vetted`/`blocked` verdict. If gaps remain, it asks only the still-open questions (same two channels). Never re-ask an already-answered question. A `vetted` or `blocked` verdict is only legitimate once the ≥90% bar is met.

## What the findings comment must contain

The deliverable is a single comment, written so the lead can accept the estimate and an implementer can later build from it without re-deriving the design. Sections:

1. **Implementation approach** — the concrete plan in prose: which modules/functions change, the sequence, the pattern to follow (cite a prior PR/module if one sets precedent). Enough that the eventual dispatch brief can point at it.
2. **Affected code — verified `file:line`** — the touch-points, each verified by reading it (stale pointers are worse than none), same format as the issue-filing skill's evidence section. Mark "new file" where the change is additive.
3. **Level of effort** — one `<loe-scale>` size **plus a one-line justification** (what makes it that size), and a **confidence** (low/med/high). Low confidence is a finding, not a failure — it usually means a risk or unknown below.
4. **Risks, unknowns, open questions** — what could blow the estimate: hidden coupling, missing test coverage, perf/security/data-isolation concerns, ambiguous spec corners. Phrase decisions needed from a human as explicit `**Decision needed: …**` lines.
5. **Dependencies** — other issues/PRs/infra that must land first (`Depends on <ref>`); if any is open, the verdict is `<blocked-state>`.
6. **Split recommendation** — if **XL**, or if the work spans the plumbing lane and leaf work, propose the child issues (one theme each) with a one-line scope per child, so the lead can fan them out. Recon proposes; the lead/filing step creates them.
7. **Dispatch recommendation** — the suggested `model:<tier>` / `effort:<level>` and lane for the eventual implementation dispatch (see the control-field skill). A premium model is a *recommendation* here; the operator still gates the actual spend at dispatch (premium labels are operator-set).

Write sections 1, 4, and 6 as natural prose a human reviews — run them through the humanizer skill (see Token discipline). Keep `file:line`, the size token, and the contract line exact.

## Investigation issues — research-plan output (for `investigation` labeled issues)

When an issue carries the `investigation` label, technical-recon produces a **research plan** instead of an implementation approach and LoE. Investigation issues are top-of-funnel research asks ("go understand X") rather than build asks ("build X"). The research plan guides the human who will conduct the investigation and forms the findings when they post the research conclusion. Sections:

1. **Questions to answer** — the concrete research questions the investigation must resolve (not open-ended; grounded in what the lead flagged as unclear).
2. **Investigation approach** — scope (which areas of the codebase, which docs, which external systems), methods (how to examine them — code review, API profiling, load testing, vendor docs, etc.), and data sources to consult.
3. **Rough time-box** — estimated effort as a research time estimate, not an LoE estimate (e.g., "2–4 hours for a code/docs review and API profiling", not "S"). This guides the human's planning, not a dispatch estimate.
4. **Risks, unknowns, investigation-specific** — what could block the research: missing access, undocumented APIs, vendor latency, or systems that only exhibit behavior under load.
5. **Findings placeholder** — a sketch of what the research findings should include when the human posts the conclusion (e.g., "findings should address whether the vendor API guarantees atomicity and whether our current retry loop is adequate, plus any edge cases discovered").

Write all sections as natural prose — not a template, but a narrative plan the human can follow. Keep the questions and data sources explicit and concrete. When the investigation concludes, a human posts the findings (not a recon agent) to close the issue — findings are not auto-computed, they are the research result itself.

## Verdict — where the issue lands

Recon ends by moving the issue to exactly one state via the control-field skill:

| Verdict | When | State set |
|---|---|---|
| **vetted** | Approach is clear, sized, no open decision, no open dependency | `<vetted-state>` + `<loe-field>` + the dispatch-recommendation labels |
| **needs-spec-input** | A technical decision needs a human (architecture, product, security) before build, OR direction questions are pending the lead's answers (you were below the 90% bar) | `<needs-input-state>` + the questions / `**Decision needed**` comment; NOT `<vetted-state>`. The lead answers in the issue and reruns to continue. |
| **blocked** | A dependency issue/PR/infra must land first | `<blocked-state>` + the dependency named in the comment |

`<vetted-state>` here means dev-vetted, not merely groomed — the orchestrator's dispatch filter can now trust it. (If your project's `<vetted-state>` is the same `ready-to-dispatch` the intake recon uses, technical recon is what earns it for non-trivial work; treat a `ready-to-dispatch` with no recon comment and a non-trivial ask as not-yet-vetted.)

## Output contract and orchestrator validation

Each recon agent ends with exactly one line:

```
TECH-RECON <id>: loe=<XS|S|M|L|XL> confidence=<low|med|high> verdict=<vetted|blocked>[ split=<N>][ model:<tier>][ effort:<level>][ deps=<ref,...>]
TECH-RECON <id>: verdict=needs-spec-input questions=<N> (awaiting the lead's answers; rerun to continue)
TECH-RECON-ERROR: <message>
```

A `vetted` or `blocked` line is only emitted once direction confidence is ≥90%; otherwise the agent emits the `needs-spec-input questions=<N>` line and stops.

Validate the line against what was actually set (`gh issue view <N> --json labels,comments` / `getJiraIssue`) — an agent can report a verdict without performing the mutation (verify-then-trust, per the dispatching-subagents skill).

## Batch fan-out

A lead typically drops several issues at once. Dispatch **one recon agent per issue, in parallel, in a single message** (per the dispatching-subagents skill) — the per-issue sandbox keeps them non-interfering. Run recon on `<recon-model>`, escalating to `opus` for deep or cross-cutting asks. After they return, verify each contract line against the issue, then report one summary table to the lead: id, LoE, confidence, verdict, suggested model/effort, and any splits proposed. Surface the XLs and the blocked/needs-input ones first — those are the lead's decisions to make.

## Anti-patterns

- **Sizing without reading the code.** An LoE from the issue text alone is a guess; the whole point is the codebase pass. No `file:line` evidence → no estimate.
- **Estimating an XL whole.** Anything over a week gets a split proposal, not a heroic single number — large single PRs throttle the merge pipeline (see the issue-filing skill).
- **Marking `<vetted-state>` with an open `Decision needed`.** An unresolved decision is `<needs-input-state>`; vetting past it ships a guess.
- **Claiming or coding during recon.** Recon is read-only; it informs the dispatch, it is not the dispatch.
- **Burning the cheap tier on this.** Technical judgement on real code needs a capable model; the cheap tier is for the intake-triage recon, not this one.
- **Sizing below 90% direction confidence instead of asking.** An estimate for a design the lead didn't choose is worse than a stalled issue with clear questions.
- **An emoji prompt with no legend, or options mapped to emoji the tracker can't react with.** The lead can't answer what they can't decode; on GitHub, stay inside the eight allowed reactions — picking one because it fits the option's *meaning* (🤔, ✅, ❌, 🤷, ⏸️, 🔄, or any other emoji not literally in that list) is the same failure as no legend at all, just harder to notice while writing it.
- **Multiple questions crammed into one comment.** Reactions can't disambiguate which question they're answering when more than one lives in the same comment — one comment per question, always, even when several are related.
- **Leaving an invalid or malformed question comment live after posting a corrected one.** Fix the original comment in place (edit it) instead of adding a new comment beside it — the lead sees comments in order and will try to react to the first one they find.

## Token discipline: caveman working, humanizer for the findings

Recon runs in the same high-volume orchestration loop as the sibling skills — operate in **caveman mode** (load the `caveman` skill) for your working output (reasoning, the batch summary table, status) to conserve tokens, keeping machine-precise content byte-exact (labels/fields, JQL, `gh`/MCP commands, `file:line` refs, the `TECH-RECON` contract line, code blocks).

But the findings comment is a durable artifact a lead reads and an implementer builds from — its prose sections (implementation approach, risks/unknowns, split recommendation) are the story. NEVER write them in caveman. Draft them naturally and run them through the `humanizer` skill before posting, so the assessment reads human-written; leave the verified `file:line` evidence, the LoE token, and the contract line exactly as captured.
