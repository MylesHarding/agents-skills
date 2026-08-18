#!/usr/bin/env bash
# ensure-worktree.sh — clone (or update) a registered repo and create/refresh an
# isolated per-task git worktree, ready for a dispatched sub-agent to cd into.
#
# Usage:
#   ensure-worktree.sh <worktree_base> <github_url> <default_branch> <branch_name>
#
#   worktree_base   Local path the repo's base clone should live at (registry's
#                   worktree_base field — a plain clone, not a git-worktree of
#                   this meta repo; the target repo has no relationship to the
#                   meta repo's own history). May be relative (resolved against
#                   this script's caller's cwd via `git -C`) or absolute. This
#                   script is always invoked by the ORCHESTRATOR's own session
#                   (Lead, or the coordinator) during resolution/worktree-
#                   provisioning, before any sub-agent is dispatched — never by
#                   an already-dispatched sub-agent from inside its own worktree.
#                   If the adopting project's registry entries use a relative
#                   worktree_base (the common case), their orchestrator's cwd
#                   must be that project's own meta-repo root when this runs.
#   github_url      Where to clone from if worktree_base doesn't exist yet.
#   default_branch  Branch to fetch/rebase onto before branching.
#   branch_name     Feature branch to create in an isolated worktree off
#                   origin/<default_branch> for this dispatch. Convention:
#                   issue-<N>-<slug>. Each branch_name gets its own `git
#                   worktree`, enabling concurrent dispatch work to the same
#                   fork without checkout collision.
#
# Idempotent: safe to re-run. If worktree_base already exists, it must be a git
# repo with an 'origin' remote pointing at github_url — mismatched origins abort
# rather than silently operating on the wrong checkout. Per-task worktrees are
# removed and re-created on each run (idempotent cleanup).
#
# Prints the absolute path to the per-task git worktree on stdout on success
# (the cwd the dispatch brief should use). Exits non-zero on any failure —
# never leaves a half-cloned, wrong-origin, or orphaned-worktree directory for
# the caller to mistake as ready.

set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "usage: ensure-worktree.sh <worktree_base> <github_url> <default_branch> <branch_name>" >&2
  exit 1
fi

WORKTREE_BASE="$1"
GITHUB_URL="$2"
DEFAULT_BRANCH="$3"
BRANCH_NAME="$4"

# Ensure the base clone exists and has correct origin, then fetch.
if [ -d "$WORKTREE_BASE/.git" ]; then
  ACTUAL_ORIGIN="$(git -C "$WORKTREE_BASE" remote get-url origin 2>/dev/null || true)"
  if [ "$ACTUAL_ORIGIN" != "$GITHUB_URL" ]; then
    echo "error: $WORKTREE_BASE exists but origin is '$ACTUAL_ORIGIN', not '$GITHUB_URL' — refusing to touch it" >&2
    exit 1
  fi
  git -C "$WORKTREE_BASE" fetch origin "$DEFAULT_BRANCH" --quiet
else
  mkdir -p "$(dirname "$WORKTREE_BASE")"
  git clone --quiet "$GITHUB_URL" "$WORKTREE_BASE"
  git -C "$WORKTREE_BASE" fetch origin "$DEFAULT_BRANCH" --quiet
fi

# Create a per-task worktree directory inside worktree_base to hold all
# task-specific worktrees. Use a fixed name so cleanup is straightforward.
WORKTREE_POOL="$WORKTREE_BASE/.worktrees"
mkdir -p "$WORKTREE_POOL"

# Derive the full path to this task's worktree. Keep branch_name suitable for
# filesystem use (already convention is issue-<N>-<slug>, which is safe).
TASK_WORKTREE="$WORKTREE_POOL/$BRANCH_NAME"

# Clean up any stale worktree (idempotent). On re-run, this ensures a fresh,
# unlocked worktree for a retry or repeat dispatch of the same branch_name.
if [ -d "$TASK_WORKTREE" ]; then
  git -C "$WORKTREE_BASE" worktree remove --force "$TASK_WORKTREE" 2>/dev/null || true
fi

# Create a fresh, isolated git worktree for this task. Use --detach to avoid
# auto-tracking in a multi-task scenario, then check out the branch explicitly.
git -C "$WORKTREE_BASE" worktree add --detach "$TASK_WORKTREE" "origin/$DEFAULT_BRANCH" --quiet

# Check out the branch, creating it fresh if needed or resetting if it already
# exists in the repo. This handles idempotence on retry or same-branch re-dispatch.
git -C "$TASK_WORKTREE" checkout --quiet -B "$BRANCH_NAME" "origin/$DEFAULT_BRANCH"

# Print the full path to the per-task worktree for the orchestrator to use as
# the dispatch brief's cwd.
echo "$TASK_WORKTREE"
