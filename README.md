<!-- Author: Rommel Porras -->

# kiro-config

Opinionated global [Kiro CLI](https://kiro.dev/docs/cli/) configuration — steering rules, security hooks, 11 workflow skills, and MCP servers. Symlinked into `~/.kiro/`.

## Quick start

```bash
git clone https://github.com/rommelporras/kiro-config.git ~/personal/kiro-config

# Symlink into ~/.kiro/
for dir in steering agents skills settings hooks; do
  ln -sfn ~/personal/kiro-config/$dir ~/.kiro/$dir
done
```

Then run `kiro-cli` in any project. Skills, steering, and hooks are active immediately.
See the [full install checklist](docs/setup/kiro-cli-install-checklist.md) for prerequisites and verification.

## What's included

| Component | What it does | Docs |
|---|---|---|
| **Steering** | Persistent rules and engineering philosophy | [catalog](https://kiro.dev/docs/cli/steering/) |
| **Skills** | 11 workflow skills ([Agent Skills](https://agentskills.io/specification) standard) | [catalog](docs/reference/skill-catalog.md) |
| **Agents** | Base agent with pre-approved tools and security hooks | [guide](docs/reference/creating-agents.md) |
| **Hooks** | Secret scanning, sensitive file protection, destructive command blocking | [model](docs/reference/security-model.md) |
| **MCP servers** | Context7, AWS Documentation, AWS Diagram | [config](https://kiro.dev/docs/cli/mcp/) |

## Prerequisites

- [Kiro CLI](https://kiro.dev/docs/cli/installation/) installed
- Node.js (for Context7 MCP via npx)
- Python 3 + [uv](https://docs.astral.sh/uv/) (for AWS MCP servers via uvx)

## Structure

```
kiro-config/
├── steering/                          # Global rules (loaded every session)
│   ├── universal-rules.md             #   No AI attribution, feature-branch only, security review
│   ├── engineering.md                 #   Evidence over assertions, TDD, plan before building
│   └── tooling.md                     #   uv not pip, conventional commits, Context7 for docs
├── agents/
│   ├── base.json                   # Base agent: pre-approved tools, security hooks, path trust
│   └── agent_config.json.example      # Template for creating new agents
├── skills/                            # 11 skills (auto-discovered by description matching)
│   ├── commit/                        #   Conventional commit with secret scan + branch safety
│   ├── push/                          #   Push with feature-branch gate + MR reminder
│   ├── explain-code/                  #   Explains code with analogies and ASCII diagrams
│   ├── brainstorming/                 #   Explores intent and design before implementation
│   ├── writing-plans/                 #   Decomposes work into tasks with verification steps
│   ├── test-driven-development/       #   RED-GREEN-REFACTOR enforcement
│   ├── systematic-debugging/          #   Root cause analysis before fixes
│   ├── verification-before-completion/ #  Evidence before claiming success
│   ├── receiving-code-review/         #   Technical rigor when processing feedback
│   ├── dispatching-parallel-agents/   #   Parallel task delegation
│   └── subagent-driven-development/   #   Per-task delegation with two-stage review
├── settings/
│   ├── cli.json                       # Model default (auto), checkpoints, base agent
│   └── mcp.json                       # Global MCP servers (Context7, AWS Docs, AWS Diagram)
├── hooks/
│   ├── scan-secrets.sh                # Blocks writes containing AWS keys, PEM keys, API tokens
│   ├── protect-sensitive.sh           # Blocks writes to .env, .pem, credentials files
│   ├── bash-write-protect.sh          # Blocks rm -rf /, force push to main, disk writes
│   └── notify.sh                      # Plays notification sound when agent completes a turn
└── docs/
    ├── setup/
    │   ├── kiro-cli-install-checklist.md   # Installation and symlink setup
    │   ├── kiro-ide-wsl-setup.md          # Kiro IDE + WSL2 remoting fix
    │   ├── troubleshooting.md             # Common issues and fixes
    │   └── rommel-porras-setup.md         # Maintainer's personal setup (chezmoi, dotfiles)
    └── reference/
        ├── skill-catalog.md               # All 11 skills: when to use, how they chain
        ├── security-model.md              # 3 defense layers: hooks, denied paths, denied commands
        └── creating-agents.md             # Field reference, security baseline, agent recipes
```

## Skills

Skills activate automatically — no slash commands needed. Describe what you want and Kiro
matches your request to the right skill by description.

| Skill | Triggers when you say... |
|---|---|
| `commit` | "commit these changes" |
| `push` | "push to remote" |
| `explain-code` | "explain how this works" |
| `brainstorming` | "let's design a new feature" |
| `writing-plans` | "plan how to implement this" |
| `test-driven-development` | "implement this with tests" |
| `systematic-debugging` | "I have a bug in..." |
| `verification-before-completion` | "verify everything works" |
| `receiving-code-review` | "here's feedback on my code" |
| `dispatching-parallel-agents` | "run these tasks in parallel" |
| `subagent-driven-development` | "implement the plan using delegates" |

See the [skill catalog](docs/reference/skill-catalog.md) for details on each skill and how they chain together.

## Security

The base agent includes three layers of protection. See the [security model](docs/reference/security-model.md) for full details.

**Hooks** (PreToolUse) — block dangerous operations before they execute:
- Secret patterns in file content (AWS, GitHub, GitLab, Slack, GCP, Anthropic, OpenAI keys)
- Writes to sensitive files (.env, .pem, credentials.json, SSH keys)
- Destructive shell commands (rm -rf /, force push to main/master, disk writes)

**Denied paths** — prevent reading/writing sensitive directories:
- `~/.ssh`, `~/.aws/credentials`, `~/.gnupg`, `~/.config/gh`

**Allowed paths** — restrict file operations to known-safe directories:
- Read: `~/.kiro`, `~/personal`, `~/eam`
- Write: `~/personal`, `~/eam`

> Customize paths in `agents/base.json` → `toolsSettings` to match your directory layout.

## MCP Servers

Global servers (loaded for every project):

| Server | Package | Purpose |
|---|---|---|
| Context7 | `@upstash/context7-mcp` | Library documentation lookup |
| AWS Documentation | `awslabs.aws-documentation-mcp-server` | AWS docs and API references |
| AWS Diagram | `awslabs.aws-diagram-mcp-server` | Architecture diagram generation |

Add project-specific MCP servers in your project's `.kiro/settings/mcp.json`.
Global servers load alongside project servers when `includeMcpJson: true` in the agent config.

## Per-project config

Create `.kiro/` in any project root for project-specific context:

```
your-project/
└── .kiro/
    ├── steering/          # Project rules (product.md, tech.md)
    ├── agents/            # Project agents (e.g. sre.json)
    ├── skills/            # Project skills
    └── settings/
        └── mcp.json       # Project MCP servers
```

Project config loads on top of global. Project steering and skills take priority on name
conflicts. See [steering docs](https://kiro.dev/docs/cli/steering/) and
[custom agents docs](https://kiro.dev/docs/cli/custom-agents/).

## Customization

**Fork this repo** and modify to fit your workflow:

- Edit `steering/*.md` to change engineering rules
- Add/remove skills in `skills/`
- Modify `agents/base.json` for tool permissions, hooks, and path trust
- Create new agents using `agents/agent_config.json.example` as a template (see [creating agents guide](docs/reference/creating-agents.md))
- Add MCP servers to `settings/mcp.json`

## Docs

| Doc | For | Purpose |
|---|---|---|
| [Install checklist](docs/setup/kiro-cli-install-checklist.md) | New users | Clone, symlink, verify — 4 steps |
| [Skill catalog](docs/reference/skill-catalog.md) | Everyone | All 11 skills, when to use each, how they chain |
| [Security model](docs/reference/security-model.md) | Customizers | 3 defense layers, how to add patterns/paths |
| [Creating agents](docs/reference/creating-agents.md) | Power users | Field reference, recipes, security baseline |
| [Troubleshooting](docs/setup/troubleshooting.md) | Everyone | Common issues and fixes |
| [IDE + WSL2 setup](docs/setup/kiro-ide-wsl-setup.md) | WSL2 IDE users | Extension fix, `kiro .` launcher |
| [Maintainer setup](docs/setup/rommel-porras-setup.md) | Maintainer | Chezmoi integration, dotfiles, AWS profiles |

**Official Kiro docs:**
[CLI](https://kiro.dev/docs/cli/) · [Installation](https://kiro.dev/docs/cli/installation/) · [Models](https://kiro.dev/docs/cli/models/) · [Steering](https://kiro.dev/docs/cli/steering/) · [Skills](https://kiro.dev/docs/cli/skills/) · [Custom agents](https://kiro.dev/docs/cli/custom-agents/) · [MCP](https://kiro.dev/docs/cli/mcp/) · [Hooks](https://kiro.dev/docs/cli/hooks/)

[Agent Skills specification](https://agentskills.io/specification)

## License

[MIT](LICENSE)
