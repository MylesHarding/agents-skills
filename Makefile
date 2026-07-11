.PHONY: sync sync-commands sync-agents sync-skills build-plugin check check-commands check-agents check-skills check-plugin

# Regenerate every mirror and the plugin payload from the canonical Claude sources.
sync: sync-commands sync-agents sync-skills build-plugin

# Fail if any mirror or the plugin payload is out of date — wire into CI or a pre-commit hook.
check: check-commands check-agents check-skills check-plugin

# Commands: .claude/commands -> .cursor/commands + .github/prompts
sync-commands:
	python3 scripts/sync-commands.py
check-commands:
	python3 scripts/sync-commands.py --check

# Agents: .claude/agents -> .cursor/agents + .github/agents + .kiro/agents + .opencode/agents
sync-agents:
	python3 scripts/sync-agents.py
check-agents:
	python3 scripts/sync-agents.py --check

# Skills: symlink .kiro/skills + .opencode/skills -> .claude/skills (Cursor/Copilot read it directly)
sync-skills:
	python3 scripts/sync-skills.py
check-skills:
	python3 scripts/sync-skills.py --check

# Plugin: .claude/{skills,agents,commands} -> plugins/agents-skills (published as a Claude plugin)
build-plugin:
	python3 scripts/build-plugin.py
check-plugin:
	python3 scripts/build-plugin.py --check
