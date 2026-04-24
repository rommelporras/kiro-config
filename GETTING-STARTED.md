# Getting Started

A multi-agent AI assistant with engineering guardrails, pre-configured for your projects.
Talk to it like a senior engineer — it delegates to the right specialist, reviews its own
work, and enforces safety rules automatically.

## What it does

- Orchestrator receives your request and delegates to the right specialist agent
- Automatic code review, test checks, and doc drift checks after every change
- Safety hooks: secret scanning, destructive command blocking, infra mutation blocking
- Skills for brainstorming, systematic debugging, refactoring, and tracing code flows
- Infrastructure is read-only — Terraform, kubectl, Helm, and AWS CLI never mutate

## Prerequisites

- [Kiro CLI](https://kiro.dev) installed (`kiro-cli --help` to verify)
- Node.js (required by Kiro CLI)
- Python 3 + uv: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- `jq` (`jq --version` to verify)

## Setup

```bash
git clone https://github.com/rommelporras/kiro-config.git ~/your/path/kiro-config
cd ~/your/path/kiro-config
./setup.sh
```

`setup.sh` creates `~/.kiro` symlinks pointing into your clone. Run this first —
it's required before kiro-cli can load the config.

Then personalize (choose one):

**Option A: Let Kiro do it** — open a new `kiro-cli chat` session inside your kiro-config folder and say:

> *Help me set up this kiro-config. Read GETTING-STARTED.md for instructions. My projects live in ~/work ~/repos.*

Replace the paths with your actual project directories (space-separated).

**Option B: Do it yourself** — run the interactive script:

```bash
./scripts/personalize.sh
```

It prompts for your project paths, saves them to `.local-paths`, and updates all agent configs.

---

## Personalization Guide (for AI agents)

> **For AI agents:** When a user asks to personalize this config, read this
> section to understand what needs changing and how.

### What to update

The config ships with the original author's paths. A new user needs their own
project directories in the agent configs so Kiro can read and write their files.

The preferred method is `./scripts/personalize.sh` which handles everything automatically.
If the user wants manual control, the `jq` commands below work. The script saves answers
to `.local-paths` (gitignored) so re-runs after `git pull` are silent and automatic.

#### Quick path: write `.local-paths` and run the script

If you know the user's project paths, create `.local-paths` directly and run the script
non-interactively:

```bash
# Write the config (space-separated project paths, absolute kiro-config path)
cat > .local-paths << 'EOF'
PROJECT_PATHS="~/work ~/repos"
KIRO_CONFIG_PATH="/home/username/your/path/kiro-config"
EOF

# Apply — reads .local-paths, updates all agent JSONs + knowledge paths
./scripts/personalize.sh
```

Replace the paths with the user's actual directories. `PROJECT_PATHS` are
space-separated directories where agents should be allowed to read and write.
`KIRO_CONFIG_PATH` is the absolute path to this kiro-config directory.

#### 1. Agent JSON — `allowedPaths` (required)

These files contain `fs_read.allowedPaths` and/or `fs_write.allowedPaths` arrays
that control where agents can access files. Replace the author's paths with the
user's paths.

**Read + Write paths (2 files):**
- `agents/base.json`
- `agents/devops-orchestrator.json`

In these files, update both:
- `toolsSettings.fs_read.allowedPaths` — add the user's project directories
- `toolsSettings.fs_write.allowedPaths` — add the user's project directories with `/**` suffix

**Write-only paths (6 files):**
- `agents/devops-docs.json`
- `agents/devops-python.json`
- `agents/devops-shell.json`
- `agents/devops-refactor.json`
- `agents/devops-typescript.json`
- `agents/devops-frontend.json`

In these files, update:
- `toolsSettings.fs_write.allowedPaths` — add the user's project directories with `/**` suffix

**Read-only paths (1 file):**
- `agents/devops-terraform.json`

In this file, update:
- `toolsSettings.fs_read.allowedPaths` — add the user's project directories

#### Path format rules

- Read paths: bare directory (e.g., `~/work`)
- Write paths: directory with glob suffix (e.g., `~/work/**`)
- Always keep `~/.kiro` in read paths and `./**` in write paths — these are universal
- Always keep `docs/**` in the orchestrator's write paths
- Use `jq` to edit JSON files, never `sed`

Example `jq` command to add a path:

```bash
jq '.toolsSettings.fs_read.allowedPaths += ["~/work"]' agents/base.json > tmp.json && mv tmp.json agents/base.json
```

#### 2. Knowledge base paths (optional)

`scripts/setup-knowledge.sh` contains hardcoded paths for semantic search indexing.
Update the paths in the `/knowledge add` commands to point to the user's project
directories and their kiro-config location.

#### 3. What NOT to change

These are shared safety contracts — do not modify:

- `deniedPaths` — protects SSH keys, credentials, Kiro settings
- `deniedCommands` — blocks destructive operations (rm -rf, force push, infra mutations)
- `hooks` blocks in agent JSONs — security gates
- `steering/` files — universal engineering standards
- `skills/` files — universal agent workflows
- `settings/cli.json` — shared CLI settings
- `settings/mcp.json` — shared MCP server config

#### 4. Project-local agent

`.kiro/agents/devops-kiro-config.json` is a write agent scoped to this kiro-config
directory. `personalize.sh` updates its write path automatically using the kiro-config
path you provide during setup. If you skip `personalize.sh` and set up manually, update
`toolsSettings.fs_write.allowedPaths` to point to wherever this kiro-config directory
lives on your machine (with `/**` suffix).

#### 5. Cosmetic (low priority)

These have hardcoded paths in messages but don't affect behavior:
- `hooks/bash-write-protect.sh` line 162 — error message mentions allowed paths
- `hooks/workspace-context.sh` line 34 — checks for a specific path in base.json

---

## How to use it

Just talk naturally. The orchestrator figures out which specialist to use.

> "Walk me through how this module works end-to-end."

> "There's a bug — here's the error: [paste error]"

> "Review this directory for code quality issues."

> "Refactor this — there's a lot of duplication."

> "Add a new endpoint and wire it to the frontend."

> "Check my docs for drift against the current code."

> "Run a health check on this codebase."

---

## Where to learn more

| Doc | What it covers |
|-----|---------------|
| [How It Works](docs/usage/how-it-works.md) | Mental model, agent roster, delegation flow |
| [Workflows](docs/usage/workflows.md) | Cookbook — real prompts for common tasks |
| [Tips](docs/usage/tips.md) | Getting better results, common mistakes, gotchas |
| [Commands](docs/usage/commands.md) | CLI commands, keyboard shortcuts, skill triggers |
| [Security Model](docs/reference/security-model.md) | 3-layer defense: hooks, denied paths, denied commands |
| [Skill Catalog](docs/reference/skill-catalog.md) | All skills with triggers |
| [Customizing](docs/reference/customizing.md) | How to extend and adapt the config |
| [Creating Agents](docs/reference/creating-agents.md) | How to add new specialist agents |

## Updating

```bash
cd ~/your/path/kiro-config && git pull
./scripts/personalize.sh   # re-applies your paths from .local-paths
```

`.local-paths` is gitignored, so your paths survive pulls. Re-running `personalize.sh`
reads `.local-paths` silently and re-applies without prompting.
