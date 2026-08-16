#!/usr/bin/env bash
# ensure-worktree.sh — clone (or update) a registered repo and create/refresh a
# per-issue branch, ready for a dispatched sub-agent to cd into.
#
# Usage:
#   ensure-worktree.sh <worktree_base> <github_url> <default_branch> <branch_name>
#
#   worktree_base   Local path the repo should live at (registry's worktree_base
#                   field — a plain clone, not a git-worktree of this meta repo;
#                   the target repo has no relationship to the meta repo's own
#                   history). May be relative (resolved against this script's
#                   caller's cwd via `git -C`) or absolute. This script is always
#                   invoked by the ORCHESTRATOR's own session (Lead, or the
#                   coordinator) during resolution/worktree-provisioning, before
#                   any sub-agent is dispatched — never by an already-dispatched
#                   sub-agent from inside its own worktree. If the adopting
#                   project's registry entries use a relative worktree_base
#                   (the common case), their orchestrator's cwd must be that
#                   project's own meta-repo root when this runs.
#   github_url      Where to clone from if worktree_base doesn't exist yet.
#   default_branch  Branch to fetch/rebase onto before branching.
#   branch_name     Feature branch to create (or reset) off origin/<default_branch>
#                   for this dispatch. Convention: issue-<N>-<slug>.
#
# Idempotent: safe to re-run. If worktree_base already exists, it must be a git
# repo with an 'origin' remote pointing at github_url — mismatched origins abort
# rather than silently operating on the wrong checkout.
#
# Prints the absolute worktree_base path on stdout on success (the cwd the
# dispatch brief should use). Exits non-zero on any failure — never leaves a
# half-cloned or wrong-origin directory for the caller to mistake as ready.

set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "usage: ensure-worktree.sh <worktree_base> <github_url> <default_branch> <branch_name>" >&2
  exit 1
fi

WORKTREE_BASE="$1"
GITHUB_URL="$2"
DEFAULT_BRANCH="$3"
BRANCH_NAME="$4"

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

# Branch fresh off origin/<default_branch> every time — never reuse a stale
# local branch that might be missing upstream commits.
git -C "$WORKTREE_BASE" checkout --quiet -B "$BRANCH_NAME" "origin/$DEFAULT_BRANCH"

cd "$WORKTREE_BASE" && pwd
