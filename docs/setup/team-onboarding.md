# Team Onboarding

[Back to README](../../README.md) | Related: [CLI install checklist](kiro-cli-install-checklist.md) | [Troubleshooting](troubleshooting.md)

Get this kiro-config working on your machine. Takes ~5 minutes.

## Prerequisites

- Kiro CLI installed ([install guide](kiro-cli-install-checklist.md))
- Git

## Step 1: Clone

```bash
git clone https://github.com/rommelporras/kiro-config.git ~/your/path/kiro-config
cd ~/your/path/kiro-config
```

## Step 2: Symlink and personalize

Wire the config into `~/.kiro` and set your project paths:

```bash
./setup.sh
./scripts/personalize.sh
```

`setup.sh` creates `~/.kiro` symlinks. `personalize.sh` prompts for your project
directories and updates all agent configs.

## Step 3: Verify

Start a `kiro-cli` session and run:

```
/context show
```

Expected output:
- **12 steering files** — `engineering.md`, `tooling.md`, `universal-rules.md`, `python-boto3.md`, `security.md`, `aws-cli.md`, `shell-bash.md`, `typescript.md`, `web-development.md`, `frontend.md`, `design-principles.md`, `terraform.md`
- **20 skills** loaded globally
- **4 MCP servers** — Context7, AWS Docs, AWS Diagram, Playwright

Also check:

```
/mcp      # MCP servers loaded
/tools    # Tools available and auto-approved
```

If anything is missing, see [Troubleshooting](troubleshooting.md).

## What you get

```
devops-orchestrator   ← default agent: plans, converses, delegates, handles git (ctrl+o)
    ├── devops-docs         config/docs/markdown editor
    ├── devops-python       Python specialist (TDD, debugging)
    ├── devops-shell        Bash/shell specialist
    ├── devops-typescript   TypeScript/Express backend (TDD with Vitest)
    ├── devops-frontend     HTML/CSS/TS, Chart.js, accessibility
    ├── devops-reviewer     read-only code reviewer
    ├── devops-refactor     restructures code, preserves behavior
    ├── devops-terraform    read-only Terraform analyst (preflight gate)
    └── devops-kiro-config  project-local kiro-config editor

base               standalone fallback for general questions
```

- **11 agents** — orchestrator + 9 specialists + base fallback
- **20 skills** — curated per agent: planning, delegation, TDD, debugging, code review, and more
- **11 hooks** — secret scanning, sensitive file protection, bash write protection, sed/awk block on JSON, doc consistency, workspace context injection, session notification, self-learning pipeline (context enrichment, correction detection, auto-capture, distillation)
- **12 steering docs** — engineering standards injected into every session
- **Keyboard shortcut** — press `ctrl+o` in any session to jump to the orchestrator

## What you'll see during delegation

Subagents report task status using one of four markers:

- **DONE** — task complete, verified
- **DONE_WITH_CONCERNS** — complete but flagging a design smell, edge case, or plan deviation
- **NEEDS_CONTEXT** — paused, needs more information before continuing
- **BLOCKED** — can't proceed; needs breakdown or manual intervention

The orchestrator surfaces these when delegation completes, so you'll see them in the conversation when a subagent finishes.

For deeper reading:
- [Skill Catalog](../reference/skill-catalog.md) — all 20 skills with triggers and agent assignments
- [Security Model](../reference/security-model.md) — 3-layer defense: hooks, denied paths, denied commands
- [Creating Agents](../reference/creating-agents.md) — how to add new specialist agents
- [Audit Playbook](../reference/audit-playbook.md) — invariants and health checks for maintaining the config over time

## Customizing further

**Project-specific agents** — if you need an agent scoped to a particular stack or repo,
see [Creating Agents](../reference/creating-agents.md).

**Adding trusted paths** — to let agents read/write a new directory, either re-run
`personalize.sh` or edit the agent JSON directly:

```bash
# Example: add ~/work/myproject to devops-orchestrator's write paths
# Edit agents/devops-orchestrator.json → toolsSettings.fs_write.allowedPaths
```

Use `jq` for edits — never `sed` on JSON files.

**Project-local overrides** — drop a `.kiro/` directory in any project repo to add
project-specific steering, skills, or agent overrides that only apply in that directory.

## Updating

```bash
cd ~/your/path/kiro-config && git pull
./scripts/personalize.sh   # re-applies your paths from .local-paths
```

Symlinks mean changes take effect on the next `kiro-cli` session — no re-linking needed.

## Exploring the config

Ask Kiro to help you understand the system:

```
Explain the agent architecture — what does each agent do?
```

```
What steering docs are loaded and what do they enforce?
```

```
Walk me through the security model — what's blocked and why?
```

```
What skills are available and how do I trigger them?
```

## Key docs

| Doc | What it covers |
|-----|---------------|
| [How It Works](../usage/how-it-works.md) | Agent architecture, hooks, steering, skills |
| [Workflows](../usage/workflows.md) | Common task patterns and delegation flows |
| [Tips](../usage/tips.md) | Practical usage tips |
| [Commands](../usage/commands.md) | Slash commands and keyboard shortcuts |
| [Customizing](../reference/customizing.md) | Adapting the config to your setup |
| [Team Onboarding](team-onboarding.md) | Full setup walkthrough |
| [Install Checklist](kiro-cli-install-checklist.md) | Kiro CLI installation |
| [Troubleshooting](troubleshooting.md) | Common issues and fixes |
| [Security Model](../reference/security-model.md) | 3-layer defense: hooks, denied paths, denied commands |
| [Skill Catalog](../reference/skill-catalog.md) | All skills with triggers |
| [Creating Agents](../reference/creating-agents.md) | How to add new specialist agents |
| [IDE + WSL2 Setup](kiro-ide-wsl-setup.md) | Kiro IDE on WSL2 |
