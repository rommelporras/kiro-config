# Team Onboarding

[Back to README](../../README.md) | Related: [CLI install checklist](kiro-cli-install-checklist.md) | [Troubleshooting](troubleshooting.md)

Get this kiro-config working on your machine. Takes ~5 minutes.

## Prerequisites

- Kiro CLI installed ([install guide](kiro-cli-install-checklist.md))
- Git

## Step 1: Clone

Pick a location that suits your directory layout:

```bash
git clone git@github.com:rommelporras/kiro-config.git ~/your/path/kiro-config
```

The path you choose here is used in the next step — keep it in mind.

## Step 2: Symlink

Wire the config into `~/.kiro`:

```bash
# Back up any existing Kiro defaults
mv ~/.kiro/agents ~/.kiro/agents.bak 2>/dev/null
mv ~/.kiro/settings ~/.kiro/settings.bak 2>/dev/null

# Symlink — replace ~/your/path/kiro-config with your actual clone path
for dir in steering agents skills settings hooks docs; do
  ln -sfn ~/your/path/kiro-config/$dir ~/.kiro/$dir
done
```

## Step 3: Personalize

The config ships with paths (`~/personal`, `~/eam`) specific to the original author.
Run the setup script to replace them with yours:

```bash
bash ~/.kiro/scripts/personalize.sh
```

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
dev-orchestrator  ← default agent: plans, converses, delegates, handles git
    ├── dev-docs       config/docs/markdown editor
    ├── dev-python     Python specialist (TDD, debugging)
    ├── dev-shell      Bash/shell specialist
    ├── dev-reviewer   read-only code reviewer
    └── dev-refactor   restructures code, preserves behavior

base              standalone fallback for general questions
```

- **10 agents** — orchestrator + 8 specialists + base fallback
- **18 skills** — curated per agent: planning, delegation, TDD, debugging, code review, and more
- **8 hooks** — secret scanning, sensitive file protection, bash write protection, block sed/awk on JSON, self-learning pipeline
- **11 steering docs** — engineering standards injected into every session

For deeper reading:
- [Skill Catalog](../reference/skill-catalog.md) — all 18 skills with triggers and agent assignments
- [Security Model](../reference/security-model.md) — 3-layer defense: hooks, denied paths, denied commands
- [Creating Agents](../reference/creating-agents.md) — how to add new specialist agents

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
