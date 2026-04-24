# Doc Structure — kiro-config

## Tracked categories
- `agents/` — agent JSON configs
- `skills/` — skill definitions
- `hooks/` — hook scripts
- `steering/` — steering docs

## Enumeration docs
| Doc file | What it enumerates |
|---|---|
| README.md | architecture diagram, feature counts, structure tree, skill matrix, policy table |
| docs/reference/skill-catalog.md | skill list, assignment matrix, design philosophy table, base-agent skill count |
| docs/reference/creating-agents.md | architecture diagram |
| docs/reference/security-model.md | agent deny-list mentions, Infrastructure Read-Only Policy table |
| docs/reference/audit-playbook.md | agent/hook/skill references, invariant checks |
| docs/setup/team-onboarding.md | architecture diagram, counts |
| docs/setup/kiro-cli-install-checklist.md | global/available skill counts |
| docs/setup/troubleshooting.md | steering file list, hook references |
| docs/reference/CHANGELOG.md | delivered artifacts per version |
| skills/agent-audit/SKILL.md | baseline counts (agents, skills, steering, hooks) |
| docs/usage/how-it-works.md | agent roster table, delegation statuses |
| docs/usage/workflows.md | workflow list with prompts |
| docs/usage/commands.md | CLI commands table, skill triggers table, MCP servers table |
| docs/reference/customizing.md | what to change vs not change, extension patterns |

## Discovery
Scan all *.md files not listed above for potential enumerations.
Flag any unlisted doc that references 3+ items from a tracked category.
If found, suggest adding it to this file.
