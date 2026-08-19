---
name: registry-dispatch
description: "Extends orchestrating-slots and gh-issue-labels for meta repos — repos that hold a registry/repos.yaml of external target repos instead of holding product code themselves. Use whenever the current repo has a registry/repos.yaml file and an issue being selected for dispatch carries a repo:<name> label: resolve the label against the registry, provision a local clone/worktree for that target repo, and scope the dispatch (cwd, PR target, cross-repo issue-closing) to it instead of the meta repo. Do not use on ordinary single-repo projects — orchestrating-slots and gh-issue-labels already cover those; this skill only adds the meta-repo indirection layer on top."
---

# Registry Dispatch

A **meta repo** tracks its backlog as GitHub issues on itself, but the actual code
changes for most of that backlog happen in *other* repos it doesn't hold code for
(see `architecture/overview.md` in the meta repo, and the "Meta-Repo Pattern" this
generalizes from). orchestrating-slots, gh-issue-labels, and dispatching-subagents
all assume the issue, the worktree, and the PR live in one `<repo-slug>` — this
skill is the indirection layer that resolves *which* repo an issue is actually
about before any of those single-repo mechanics run.

Companion skills: this composes with, not replaces, **orchestrating-slots** (the
slot loop), **gh-issue-labels** (the label taxonomy — this skill adds one label to
it), **dispatching-subagents** (the brief template — this skill changes what goes
in the cwd/scope fields), and **gh-issue-locking** (claim/release — unchanged,
still operates on the meta repo's issue).

## Project bindings

| Binding | Meaning | Example |
|---|---|---|
| `<meta-repo-slug>` | This repo's own `org/repo`, for cross-repo `Closes` syntax | `MylesHarding/meta-builder` |
| `<registry-path>` | Path to the registry file, relative to the meta repo root | `registry/repos.yaml` |

Per-target-repo values (`github_url`, `default_branch`, `worktree_base`, `engine`,
`agents_allowed`) are *not* project-wide bindings — they come from the registry
entry resolved per issue. See `registry/schema.md` in the meta repo for field
definitions.

## The `repo:<name>` label

Extends the gh-issue-labels taxonomy with one more entry:

| Label | Lives on | Who sets it | Who consumes it | Effect |
|---|---|---|---|---|
| `repo:<name>` | Issues (meta repo) | Operator or triage | Orchestrator, before locking | Identifies which registry entry this issue's work targets |

- **Present**: the issue's work happens in the named target repo. Resolve it
  (below) before doing anything else with the issue.
- **Absent**: the issue is about the meta repo itself (e.g. work on the
  orchestration assets, this skill, the registry schema) — dispatch normally,
  cwd stays the meta repo checkout, no resolution step needed.
- An issue whose `repo:<name>` value has no matching registry entry is **not
  dispatchable** — treat exactly like `do-not-dispatch` in the pre-dispatch
  filter (see gh-issue-labels) until the label is fixed or the registry is
  updated. Never guess the intended repo.

**Recognizing a target-repo finding before an issue even exists.** Any agent doing
review, audit, or read-only investigation work — not just the orchestrator selecting
issues to dispatch — can surface a real finding whose evidence lives under a registry
entry's `worktree_base` rather than in the meta repo's own code. Fixing it in place, or
noting it somewhere without filing it, both leave the finding with no path to a fix (the
target repo isn't polled by anything watching the meta repo's backlog). File a GitHub
issue on the **meta repo** with the matching `repo:<name>` label instead, so this skill's
normal resolution/dispatch flow picks it up — the finding needs a tracked issue exactly
as much as any other target-repo work, whether or not an agent happens to also be in the
middle of an orchestrator role that session.

## Resolution step (before lock, before dispatch)

Run once per candidate issue, after the normal gh-issue-labels exclusion filter
and immediately before the pre-lock assignee re-check:

```bash
python3 .claude/skills/registry-dispatch/scripts/resolve-repo.py <name>
# → prints the registry entry as JSON on stdout, exit 0
# → exit 1 with a message on stderr if <name> has no entry, a duplicate name,
#   or a malformed/missing registry.yaml — treat as not-dispatchable, same as
#   any other gh-issue-labels exclusion. Do not retry with a guessed name.
```

If `agents_allowed` is present on the resolved entry, the persona chosen for
this dispatch (per dispatching-subagents' model/persona selection) must be in
that list. If it isn't, this issue is not dispatchable by the current session —
comment why, leave the label, move to the next candidate (same posture as the
access-gated model fallback in gh-issue-labels: release, don't sit on it,
don't downgrade silently).

## Worktree provisioning — isolated per-task git worktrees

Once resolved, before writing the dispatch brief:

```bash
WORKTREE=$(.claude/skills/registry-dispatch/scripts/ensure-worktree.sh \
  "<worktree_base>" "<github_url>" "<default_branch>" "issue-<N>-<slug>")
```

This provisions a **per-task isolated git worktree** to prevent concurrent
dispatch work from colliding in the same checkout (see issue #555 for the
real incident — concurrent `/work` sessions racing a shared `forks/<name>/`
clone caused branch-checkout collisions).

**How it works:**
1. **Base clone setup** — Clones the target repo to `<worktree_base>` on first
   use, or just fetches + validates it on subsequent dispatches. Never touches
   the target repo if `worktree_base` already exists with a different origin
   (aborts loudly instead of silently operating on the wrong checkout).
2. **Per-task worktree creation** — Inside the base clone, creates a fresh
   `git worktree add` at `<worktree_base>/.worktrees/<branch-name>/`, isolated
   from concurrent tasks. If a worktree for this branch already exists (e.g.,
   on retry), it is cleaned up and re-created (idempotent).
3. **Branch checkout** — Checks out the feature branch fresh off
   `origin/<default_branch>` within the isolated worktree.

The printed path is the isolated worktree directory — the `cwd` for the
dispatched sub-agent — **not** the base clone or the meta repo. This is a
`git worktree` of the target repo (not of the meta repo), fully isolated per
task and safe for concurrent use.

**Cleanup**: When a fork-targeted dispatch completes (PR merged or closed), the
dispatched sub-agent's worktree should be manually removed to avoid accumulation:
`git -C <worktree_base> worktree remove <worktree_path>`. (This is distinct
from the meta repo's own `.worktrees/<name>` cleanup, which is automated by the
`pr-cleanup` lane. Fork-targeted worktrees are manual cleanup for now, since
fork repos have no equivalent of the meta repo's orchestrator loop.)

`agents_allowed` and `tags` from the registry entry travel into the dispatch
brief as scope/context, same as any other brief field in dispatching-subagents.

## Dispatch brief changes

Everything else in dispatching-subagents' brief template applies unchanged,
with these substitutions:

- **cwd**: the path `ensure-worktree.sh` printed, not the meta repo.
- **PR target**: the dispatched agent opens its PR against `<github_url>` /
  `<default_branch>` — never against the meta repo, which holds no product
  code to receive it.
- **Closing the tracking issue**: since the issue lives on the meta repo but
  the PR lands on the target repo, ordinary same-repo `Closes #N` does nothing.
  The brief must instruct the agent to include the cross-repo form in the PR
  body:

  ```
  Closes <meta-repo-slug>#<N>
  ```

  GitHub resolves `owner/repo#N` cross-repo closing keywords the same way as
  same-repo `#N`, as long as the account opening the PR can also close issues
  on the meta repo.
- **Gate-status posting (step 5)**: fill dispatching-subagents' `<repo-slug>`
  binding with the target repo's slug (the registry entry's `owner/repo`, from
  `github_url`), not the meta repo:

  ```
  tsx scripts/ensure-gate-statuses.ts <PR#> <target-repo-slug>
  ```

  This posts gate statuses on the PR in its own repo (e.g. squad#5 in
  MylesHarding/squad), not the meta repo. The meta-repo issue still auto-closes
  via the `Closes <meta-repo-slug>#<N>` keyword already in the PR body.

## Cross-repo PRs: tracking multiple PRs on one issue

When a registry-dispatch dispatch opens a companion PR in **another repo** (not the
meta repo), the originating tracker issue must track ALL PRs across all repos it
spawned. The dispatching agent or orchestrator must post or update a checklist on
the originating issue:

```markdown
## Cross-repo PRs
- [ ] ntsy-forge#<N> (this repo)
- [ ] agents-skills#<M>
```

Each line represents one PR in a different repo. Check off each line as that PR merges.
This checklist lives on the originating tracker issue (the meta repo), not split across
multiple repos — it is the at-a-glance record that more than one PR needs attention.

See `gh-issue-locking/SKILL.md` and `jira-issue-locking/SKILL.md`'s close-on-merge
sections: before closing an issue, those gates check for this checklist and verify
(via live `gh pr view` or equivalent) that EVERY listed PR is actually `MERGED` before
proceeding. If any listed PR is still open, close-on-merge is withheld — the issue stays
open, the checklist is updated to reflect current state, and a note names which PR(s)
are still outstanding. This prevents the tracking issue from appearing "done" while
real work is still in flight (the scenario issues #555 and #570 encountered).

## Close-on-merge and reconciliation implications

orchestrating-slots' close-on-merge step and PR-state polling (`gh pr view`,
`gh pr list`) must run scoped to **each target repo's** `github_url`, not the
meta repo — there is no meta-repo PR to poll in this flow, only the meta-repo
*issue* and the target-repo *PR*. When reconciling "PR merged" events, check
merge state via `gh pr list --repo <target-repo-slug> ...`, and confirm the
cross-repo `Closes` link actually fired by checking the meta-repo issue's state
directly (`gh issue view <N> --repo <meta-repo-slug> --json state`) rather than
assuming it did — a dropped `Closes` line (agent truncation, wrong casing on
the repo slug) leaves the issue open with real work already merged. Treat that
exactly like any other verify-then-trust gap: close it explicitly rather than
re-dispatching.

## Known simplification

Slot accounting in orchestrating-slots is per-orchestrator-session, not
per-target-repo — dispatching against five different registered repos still
counts against the same slot pool. A future `max_concurrent` field on a
registry entry could cap per-repo concurrency; not implemented here. Until
then, treat registry entries as sharing one slot pool, same as if they were
different areas of one repo.
