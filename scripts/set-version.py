#!/usr/bin/env python3
"""Stamp a version into the plugin and marketplace manifests.

Versions are CalVer with a patch counter — YYYY.M.D.N — so several releases on the
same day never collide (the first of a day is `.0`). The release workflow computes
the next free N by probing existing `v<version>` tags.

  python3 scripts/set-version.py 2026.7.11.0
"""
import json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERSION_RE = re.compile(r"^\d{4}\.\d{1,2}\.\d{1,2}\.\d+$")

PLUGIN_MANIFEST = os.path.join("plugins", "agents-skills", ".claude-plugin", "plugin.json")
MARKETPLACE_MANIFEST = os.path.join(".claude-plugin", "marketplace.json")


def main():
    version = sys.argv[1] if len(sys.argv) > 1 else ""
    if not VERSION_RE.match(version):
        print("Usage: python3 scripts/set-version.py <YYYY.M.D.N> (patch counter required)")
        sys.exit(1)

    def stamp_plugin(doc):
        doc["version"] = version

    def stamp_marketplace(doc):
        for plugin in doc.get("plugins", []):
            plugin["version"] = version

    for rel, mutate in ((PLUGIN_MANIFEST, stamp_plugin),
                        (MARKETPLACE_MANIFEST, stamp_marketplace)):
        path = os.path.join(ROOT, rel)
        with open(path) as f:
            doc = json.load(f)
        mutate(doc)
        with open(path, "w") as f:
            json.dump(doc, f, indent=2)
            f.write("\n")
        print(f"{rel} -> {version}")


if __name__ == "__main__":
    main()
