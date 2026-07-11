#!/usr/bin/env python3
"""Assemble the Claude plugin payload from the canonical .claude sources.

This repo doubles as its own Claude Code plugin marketplace. The plugin that gets
published is a *generated* copy of the canonical artifacts — it must be real files
(not symlinks), because Claude Code installs the plugin directory on its own and a
link escaping that directory would dangle.

Canonical source            ->  Plugin payload (generated, committed)
  .claude/skills/<name>/          plugins/agents-skills/skills/<name>/     (dirs with a SKILL.md)
  .claude/agents/<name>.md        plugins/agents-skills/agents/<name>.md
  .claude/commands/<name>.md      plugins/agents-skills/commands/<name>.md

The payload dirs are wiped and rebuilt so upstream deletions/renames propagate. The
plugin manifest (plugins/agents-skills/.claude-plugin/plugin.json) is hand-maintained
and version-stamped by scripts/set-version.py — this script never touches it.

  python3 scripts/build-plugin.py          # rebuild the payload
  python3 scripts/build-plugin.py --check  # exit 1 if the payload is out of date
"""
import filecmp, os, shutil, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, ".claude")
PLUGIN = os.path.join(ROOT, "plugins", "agents-skills")

# payload subdir -> (canonical source dir, kind)
PAYLOAD = {
    "skills": (os.path.join(SRC, "skills"), "skill-dirs"),
    "agents": (os.path.join(SRC, "agents"), "md-files"),
    "commands": (os.path.join(SRC, "commands"), "md-files"),
}


def collect():
    """Return {relpath-under-plugin: absolute-source-path} for every payload file."""
    files = {}
    for sub, (src, kind) in PAYLOAD.items():
        if not os.path.isdir(src):
            continue
        if kind == "md-files":
            for f in sorted(os.listdir(src)):
                if f.endswith(".md"):
                    files[os.path.join(sub, f)] = os.path.join(src, f)
        else:  # skill-dirs: a skill is a directory containing a SKILL.md
            for name in sorted(os.listdir(src)):
                d = os.path.join(src, name)
                if not os.path.isdir(d) or not os.path.isfile(os.path.join(d, "SKILL.md")):
                    continue  # skips helper dirs like _evals
                for dirpath, _, filenames in os.walk(d):
                    for f in sorted(filenames):
                        full = os.path.join(dirpath, f)
                        rel = os.path.relpath(full, src)
                        files[os.path.join(sub, rel)] = full
    return files


def existing():
    """Return the set of relpaths currently in the committed payload dirs."""
    out = set()
    for sub in PAYLOAD:
        base = os.path.join(PLUGIN, sub)
        for dirpath, _, filenames in os.walk(base):
            for f in filenames:
                out.add(os.path.relpath(os.path.join(dirpath, f), PLUGIN))
    return out


def main():
    check = "--check" in sys.argv
    want = collect()
    if not want:
        print("build-plugin FAILED — no canonical artifacts found under .claude/")
        sys.exit(1)

    if check:
        have = existing()
        missing = sorted(set(want) - have)
        extra = sorted(have - set(want))
        changed = sorted(
            rel for rel in set(want) & have
            if not filecmp.cmp(os.path.join(PLUGIN, rel), want[rel], shallow=False)
        )
        if missing or extra or changed:
            print("plugin payload OUT OF DATE — run: python3 scripts/build-plugin.py")
            for rel in missing:
                print("   missing:", rel)
            for rel in extra:
                print("   stale:  ", rel)
            for rel in changed:
                print("   changed:", rel)
            sys.exit(1)
        skills = len({r.split(os.sep)[1] for r in want if r.startswith("skills" + os.sep)})
        agents = sum(1 for r in want if r.startswith("agents" + os.sep))
        cmds = sum(1 for r in want if r.startswith("commands" + os.sep))
        print(f"plugin payload in sync ({skills} skills, {agents} agents, {cmds} commands)")
        return

    # Wipe and rebuild so deletions and renames propagate.
    for sub in PAYLOAD:
        shutil.rmtree(os.path.join(PLUGIN, sub), ignore_errors=True)
    for rel, src in want.items():
        dst = os.path.join(PLUGIN, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(src, dst)

    skills = len({r.split(os.sep)[1] for r in want if r.startswith("skills" + os.sep)})
    agents = sum(1 for r in want if r.startswith("agents" + os.sep))
    cmds = sum(1 for r in want if r.startswith("commands" + os.sep))
    print(f"built plugin payload -> plugins/agents-skills "
          f"({skills} skills, {agents} agents, {cmds} commands)")


if __name__ == "__main__":
    main()
