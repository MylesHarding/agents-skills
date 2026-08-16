---
name: code-quality
description: "Baseline maintainability bar for any code change: apply DRY/KISS/YAGNI/SOLID, notice when a file is taking on an unrelated responsibility it's already too large for, balance the test pyramid toward behavior/integration coverage over brittle heavy mocking, and — for UI work — use design tokens and reusable/atomic components instead of one-off styling. Use whenever writing or reviewing code, especially when the person who will read the diff can't independently judge maintainability (a non-technical stakeholder, an unattended pipeline, or a reviewer who only checks that it works)."
---

# Code Quality: the maintainability bar nobody else is checking

Tests passing and acceptance criteria met answer "does it work." They don't answer "will
the next change to this area be easy or painful." When the person requesting the work can't
independently judge that — a non-technical stakeholder, an unattended dispatch pipeline, a
reviewer who only confirms behavior — the agent doing the work has to hold that bar itself.
Nobody else is going to.

This is a smell-detector, not a lint rule. None of this is mechanically enforced by a script
in this skill — it's judgment applied at the moment of writing or reviewing a change.

## Clean-code principles, applied at the moment of writing

- **DRY** — before adding a new function or component, search for one that already does the
  job. A third near-identical copy of the same logic is a sign to extract a shared helper,
  not write a third copy.
- **KISS** — pick the simplest design that satisfies the actual requirement in front of you.
  No speculative configuration options, no extra abstraction layer justified by "might need
  it later."
- **YAGNI** — the sibling of KISS: don't build for a requirement nobody has asked for yet.
  Building it later, when it's real, is cheaper than maintaining unused flexibility now.
- **SOLID**, mostly in its Single-Responsibility form for day-to-day work — a function or
  module should do one job. When a change would give an already-multi-purpose file a sixth
  purpose, that's the file-size signal below, not a reason to keep adding.

## File size: a signal to notice, not a hard limit

A hard line-count gate produces perverse results — a 501-line file mechanically split into
two 250-line files that still share one responsibility isn't an improvement. Use judgment
instead:

- **Before adding to a file, check its rough size.** A file already carrying substantial,
  unrelated logic taking on yet another unrelated responsibility is worth a second look:
  does the new code belong in its own module?
- **Growing a large file with more of the same responsibility is fine.** A big file that
  does one big job isn't automatically a problem; a big file doing five unrelated jobs is.
- **A real split is its own piece of work, not a rider.** If you notice an existing file has
  drifted into doing too many unrelated things, don't fix that inside an unrelated feature
  change — file it as its own follow-up (see the `gh-issue-filing` / `jira-issue-filing`
  skill) so the refactor gets reviewed and scoped on its own terms.
- **New code gets a new, appropriately-scoped file** rather than being appended to
  something already overloaded for an unrelated reason.

## Balanced test pyramid: behavior and integration over brittle heavy mocking

A test suite that's expensive to maintain slows every future change without necessarily
catching more real bugs. Aim for tests that pay for themselves:

- **Favor behavior over implementation structure.** A test that asserts "given this input,
  the user-visible outcome is X" survives a safe internal refactor. A test that asserts
  "internal helper A was called with these exact arguments" breaks on that same safe
  refactor and rarely catches a real regression — it's cost without benefit.
- **Prefer exercising the real code path over deep mock chains.** A test that mocks four
  internal collaborators to isolate a fifth is usually testing the mocks, not the code.
  Where practical, use a real (but isolated/disposable — e.g. a throwaway database file
  or fixture directory, never shared production state) instance of the dependency instead
  of a hand-built stand-in.
- **Don't chase a coverage percentage.** Tests should map to acceptance criteria and
  realistic failure modes. Three redundant tests for the same behavior cost maintenance
  time without adding protection a single one wouldn't already provide.
- **Verify live behavior when you can, not just the code path's existence.** Code that
  looks correct in a diff can still fail once real data flows through it — a wiring gap, a
  missed state update, an off-by-one in a query offset. When a change is interactively
  exercisable, run it and observe the actual output before calling it done.

## UI work: design tokens and reusable, atomic structure

The same discipline applies to visual work, whether or not the target codebase has a UI
framework:

- **Design tokens, not magic values.** Colors, spacing, and typography should come from
  whatever token/variable set the target codebase already defines, not hand-picked
  one-off values in a new component's styling.
- **Reusability over one-off markup.** Before writing new markup/styling for a card, badge,
  or panel, check whether an existing pattern in the codebase already does the same job and
  can be parameterized instead of duplicated.
- **Think in components, even without a framework.** Small, composable pieces assembled
  into larger views age better than one monolithic render function per screen — this holds
  in plain DOM/vanilla-JS codebases as much as in React/Vue.
- **Normalize on the framework's own idiom when one is chosen.** If a target codebase
  adopts a UI framework, follow *its* token and component conventions rather than carrying
  a prior ad-hoc approach forward out of habit.

## Where this applies

- **Implementers** self-apply this before opening a PR, as part of the same
  self-verification pass used for acceptance criteria — not a separate step someone else
  runs later.
- **Reviewers** treat an obvious DRY/SOLID violation, or a change that meaningfully grows an
  already-overloaded file's unrelated responsibilities, as a real finding — not a style nit
  to wave through because it isn't a correctness bug.
