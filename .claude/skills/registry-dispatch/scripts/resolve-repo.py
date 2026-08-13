#!/usr/bin/env python3
"""resolve-repo.py — look up a registered repo in registry/repos.yaml.

Usage:
  resolve-repo.py <name> [--registry PATH]

Prints the matching entry as JSON on stdout and exits 0. Exits 1 with a message
on stderr if the registry file is missing, malformed, or has no entry with that
name — never guesses or falls back to a default repo. Callers (the
registry-dispatch skill) must treat a non-zero exit as "not dispatchable", the
same as any other issue-selection exclusion.
"""

import argparse
import json
import sys

try:
    import yaml
except ImportError:
    print("error: pyyaml not installed (pip install pyyaml)", file=sys.stderr)
    sys.exit(1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("name", help="registry entry name (repo:<name> label value)")
    parser.add_argument(
        "--registry",
        default="registry/repos.yaml",
        help="path to the registry file, relative to the meta repo root (default: registry/repos.yaml)",
    )
    args = parser.parse_args()

    try:
        with open(args.registry, "r") as f:
            data = yaml.safe_load(f) or {}
    except FileNotFoundError:
        print(f"error: registry file not found: {args.registry}", file=sys.stderr)
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"error: malformed registry YAML: {e}", file=sys.stderr)
        sys.exit(1)

    repos = data.get("repos") or []
    matches = [r for r in repos if r.get("name") == args.name]

    if not matches:
        print(f"error: no registry entry named '{args.name}'", file=sys.stderr)
        sys.exit(1)
    if len(matches) > 1:
        print(f"error: registry has {len(matches)} entries named '{args.name}' — names must be unique", file=sys.stderr)
        sys.exit(1)

    entry = matches[0]
    for required in ("name", "github_url", "default_branch", "worktree_base"):
        if not entry.get(required):
            print(f"error: registry entry '{args.name}' is missing required field '{required}'", file=sys.stderr)
            sys.exit(1)

    # engine defaults to claude when unset, per registry/schema.md
    entry.setdefault("engine", "claude")
    print(json.dumps(entry))


if __name__ == "__main__":
    main()
