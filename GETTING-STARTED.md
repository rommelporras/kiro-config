# Getting Started

Get this kiro-config running on your machine.

## Prerequisites

- [Kiro CLI](https://kiro.dev/docs/cli/installation/) installed (`kiro-cli --help` to verify)
- `jq` installed (`jq --version` to verify)
- Git

## Quick Setup

### 1. Clone

```bash
git clone https://github.com/rommelporras/kiro-config.git ~/your/path/kiro-config
cd ~/your/path/kiro-config
```

### 2. Create symlinks

```bash
./setup.sh
```

Creates `~/.kiro/{steering,agents,skills,settings,hooks,docs}` symlinks pointing
into this repo. Backs up any existing non-symlink directories. Idempotent — safe to re-run.

### 3. Personalize paths

```bash
./scripts/personalize.sh
```

First run: prompts for your project directories, saves answers to `.local-paths`
(gitignored), then updates all agent JSON configs via `jq`.

### 4. Verify

```bash
# Check symlinks resolve
ls -la ~/.kiro/steering
ls -la ~/.kiro/agents

# In a kiro-cli session
/context show
```

You should see steering files and skills loaded.

### Or: Let Kiro Help You

Open a `kiro-cli` session inside this directory and say:

```
I just cloned this kiro-config. Read GETTING-STARTED.md and help me set it up.
My projects live in ~/work and ~/repos.
```

## Updating

```bash
cd ~/your/path/kiro-config && git pull
./scripts/personalize.sh   # re-applies your paths from .local-paths
```

`.local-paths` is gitignored, so your paths survive pulls. Re-running `personalize.sh`
reads `.local-paths` silently and re-applies without prompting.

## What You Get

```
devops-orchestrator   ← default agent: plans, converses, delegates, handles git
    ├── devops-docs         config/docs/markdown editor
    ├── devops-python       Python specialist (TDD, debugging)
    ├── devops-shell        Bash/shell specialist
    ├── devops-typescript   TypeScript/Express backend (TDD with Vitest)
    ├── devops-frontend     HTML/CSS/TS, Chart.js, accessibility
    ├── devops-reviewer     read-only code reviewer
    ├── devops-refactor     restructures code, preserves behavior
    ├── devops-terraform    read-only Terraform analyst
    └── devops-kiro-config  project-local kiro-config editor

base                  standalone fallback for general questions
```

- **11 agents** — orchestrator + 9 specialists + base fallback
- **20 skills** — planning, delegation, TDD, debugging, code review, and more
- **11 hooks** — secret scanning, destructive command blocking, self-learning pipeline
- **12 steering docs** — engineering standards injected into every session

See [USAGE-GUIDE.md](USAGE-GUIDE.md) for how to use the orchestrator, trigger skills,
and common workflows.

## Personalization Guide (for Kiro agents)

> **For AI agents:** When a user asks to personalize this config, read this
> section to understand what needs changing and how.

### What to update

The config ships with the original author's paths. A new user needs their own
project directories in the agent configs so Kiro can read and write their files.

The preferred method is `./scripts/personalize.sh` which handles everything automatically.
If the user wants manual control, use `jq` — never `sed` on JSON files.

#### Agent JSON — `allowedPaths`

These files contain `fs_read.allowedPaths` and/or `fs_write.allowedPaths` arrays.
Replace the author's paths with the user's paths.

**Read + Write (2 files):**
- `agents/base.json` — `fs_read.allowedPaths` + `fs_write.allowedPaths`
- `agents/devops-orchestrator.json` — `fs_read.allowedPaths` + `fs_write.allowedPaths`

**Write-only (6 files):**
- `agents/devops-docs.json`
- `agents/devops-python.json`
- `agents/devops-shell.json`
- `agents/devops-refactor.json`
- `agents/devops-typescript.json`
- `agents/devops-frontend.json`

**Read-only (1 file):**
- `agents/devops-terraform.json`

**Project-local (1 file):**
- `.kiro/agents/devops-kiro-config.json` — `personalize.sh` updates this automatically. If setting up manually, point the write path to your kiro-config clone location (with `/**` suffix).

#### Path format rules

- Read paths: bare directory (e.g., `~/work`)
- Write paths: directory with glob suffix (e.g., `~/work/**`)
- Always keep `~/.kiro` in read paths and `./**` in write paths
- Always keep `docs/**` in the orchestrator's write paths

#### Knowledge base paths (optional)

`scripts/setup-knowledge.sh` contains paths for semantic search indexing.
Update to point to the user's project directories.

#### What NOT to change

- `deniedPaths` — protects SSH keys, credentials, Kiro settings
- `deniedCommands` — blocks destructive operations
- `hooks` blocks in agent JSONs — security gates
- `steering/` and `skills/` files — universal, not path-dependent
- `settings/` — shared CLI and MCP config

## Next Steps

- [USAGE-GUIDE.md](USAGE-GUIDE.md) — how to use the orchestrator, skills, and workflows
- [Team Onboarding](docs/setup/team-onboarding.md) — detailed setup walkthrough
- [Troubleshooting](docs/setup/troubleshooting.md) — common issues and fixes
- [Security Model](docs/reference/security-model.md) — how the 3 defense layers work
- [Skill Catalog](docs/reference/skill-catalog.md) — all 20 skills with triggers
