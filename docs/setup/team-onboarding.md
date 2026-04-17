# Team Onboarding

[Back to README](../../README.md) | Related: [CLI install checklist](kiro-cli-install-checklist.md) | [Troubleshooting](troubleshooting.md)

Get this kiro-config working on your machine. Takes ~5 minutes.

## Prerequisites

- Kiro CLI installed ([install guide](kiro-cli-install-checklist.md))
- Git

## Step 1: Clone

Pick a location that suits your directory layout. Use SSH if you have GitHub
SSH keys configured, otherwise HTTPS works without setup:

```bash
# SSH (requires GitHub SSH keys):
git clone git@github.com:rommelporras/kiro-config.git ~/your/path/kiro-config

# HTTPS (works everywhere):
git clone https://github.com/rommelporras/kiro-config.git ~/your/path/kiro-config
```

The path you choose here is used in the next step — keep it in mind.

## Step 2: Symlink

Wire the config into `~/.kiro`:

```bash
# Back up any existing Kiro defaults (all 6 directories the loop will replace)
for dir in steering agents skills settings hooks docs; do
  [ -e ~/.kiro/$dir ] && [ ! -L ~/.kiro/$dir ] && mv ~/.kiro/$dir ~/.kiro/$dir.bak
done

# Symlink — replace ~/your/path/kiro-config with your actual clone path
for dir in steering agents skills settings hooks docs; do
  ln -sfn ~/your/path/kiro-config/$dir ~/.kiro/$dir
done
```

The `[ ! -L ]` check skips existing symlinks so re-runs don't clobber valid links.

## Step 3: Personalize

The config ships with paths (`~/personal`, `~/eam`) specific to the original author.
Run the setup script to replace them with yours:

```bash
bash ~/your/path/kiro-config/scripts/personalize.sh
```

(Run from the clone path — `scripts/` is not symlinked into `~/.kiro/` because
it's a one-shot setup utility, not a runtime resource.)

The script will ask for:
- Your clone path (where you ran `git clone` in Step 1)
- Your project root(s) — directories where agents should be allowed to read/write

It updates:
- All agent configs (`allowedPaths` in `fs_read` and `fs_write`) — controls where agents can read and write files
- Knowledge base paths in `scripts/setup-knowledge.sh`

If you need to add more trusted paths later, re-run `personalize.sh` or edit the relevant agent JSON directly — update `toolsSettings.fs_read.allowedPaths` and `toolsSettings.fs_write.allowedPaths`.

## Step 4: Verify

Start a `kiro-cli` session and run:

```
/context show
```

Expected output:
- **11 steering files** — `engineering.md`, `tooling.md`, `universal-rules.md`, `python-boto3.md`, `security.md`, `aws-cli.md`, `shell-bash.md`, `typescript.md`, `web-development.md`, `frontend.md`, `design-principles.md`
- **18 skills** loaded globally
- **4 MCP servers** — Context7, AWS Docs, AWS Diagram, Playwright

Also check:

```
/mcp      # MCP servers loaded
/tools    # Tools available and auto-approved
```

If anything is missing, see [Troubleshooting](troubleshooting.md).

## What you get

```
dev-orchestrator   ← default agent: plans, converses, delegates, handles git (ctrl+o)
    ├── dev-docs         config/docs/markdown editor
    ├── dev-python       Python specialist (TDD, debugging)
    ├── dev-shell        Bash/shell specialist
    ├── dev-typescript   TypeScript/Express backend (TDD with Vitest)
    ├── dev-frontend     HTML/CSS/TS, Chart.js, accessibility
    ├── dev-reviewer     read-only code reviewer
    ├── dev-refactor     restructures code, preserves behavior
    └── dev-kiro-config  project-local kiro-config editor

base               standalone fallback for general questions
```

- **10 agents** — orchestrator + 8 specialists + base fallback
- **18 skills** — curated per agent: planning, delegation, TDD, debugging, code review, and more
- **11 hooks** — secret scanning, sensitive file protection, bash write protection, sed/awk block on JSON, doc consistency, workspace context injection, session notification, self-learning pipeline (context enrichment, correction detection, auto-capture, distillation)
- **11 steering docs** — engineering standards injected into every session
- **Keyboard shortcut** — press `ctrl+o` in any session to jump to the orchestrator

## What you'll see during delegation

Subagents report task status using one of four markers:

- **DONE** — task complete, verified
- **DONE_WITH_CONCERNS** — complete but flagging a design smell, edge case, or plan deviation
- **NEEDS_CONTEXT** — paused, needs more information before continuing
- **BLOCKED** — can't proceed; needs breakdown or manual intervention

The orchestrator surfaces these when delegation completes, so you'll see them in the conversation when a subagent finishes.

For deeper reading:
- [Skill Catalog](../reference/skill-catalog.md) — all 18 skills with triggers and agent assignments
- [Security Model](../reference/security-model.md) — 3-layer defense: hooks, denied paths, denied commands
- [Creating Agents](../reference/creating-agents.md) — how to add new specialist agents
- [Audit Playbook](../reference/audit-playbook.md) — invariants and health checks for maintaining the config over time

## Customizing further

**Project-specific agents** — if you need an agent scoped to a particular stack or repo,
see [Creating Agents](../reference/creating-agents.md).

**Adding trusted paths** — to let agents read/write a new directory, either re-run
`personalize.sh` or edit the agent JSON directly:

```bash
# Example: add ~/work/myproject to dev-orchestrator's write paths
# Edit agents/dev-orchestrator.json → toolsSettings.fs_write.allowedPaths
```

Use `jq` for edits — never `sed` on JSON files.

**Project-local overrides** — drop a `.kiro/` directory in any project repo to add
project-specific steering, skills, or agent overrides that only apply in that directory.

## Updating

```bash
cd ~/your/path/kiro-config && git pull
```

Symlinks mean changes take effect on the next `kiro-cli` session — no re-linking needed.
