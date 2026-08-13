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

## Worktree provisioning

Once resolved, before writing the dispatch brief:

```bash
WORKTREE=$(.claude/skills/registry-dispatch/scripts/ensure-worktree.sh \
  "<worktree_base>" "<github_url>" "<default_branch>" "issue-<N>-<slug>")
```

This clones the target repo on first use, or fetches + re-branches on
subsequent dispatches — it never touches the target repo if the local
`worktree_base` already exists with a *different* origin (aborts loudly
instead of silently operating on the wrong checkout). The printed path is the
`cwd` for the dispatched sub-agent — **not** the meta repo's own working
directory. This is a plain clone of the target repo, unrelated to the meta
repo's git history; don't confuse it with a `git worktree` of the meta repo
itself.

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
