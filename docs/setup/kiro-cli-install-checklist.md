<!-- Author: Rommel Porras -->

# Kiro CLI Installation Checklist

[Back to README](../../README.md) | Related: [IDE + WSL2 setup](kiro-ide-wsl-setup.md) | [Troubleshooting](troubleshooting.md)

Get Kiro CLI running with this global config in 4 steps.

## Prerequisites

- [Kiro CLI](https://kiro.dev/docs/cli/installation/) installed
- Node.js (for Context7 MCP via `npx`)
- Python 3 + [uv](https://docs.astral.sh/uv/) (for AWS MCP servers via `uvx`)

## 1. Install Kiro CLI

```bash
curl -fsSL https://cli.kiro.dev/install | bash
```

First run triggers browser authentication:

```bash
kiro-cli
```

Verify the install:

```bash
kiro-cli doctor
```

## 2. Clone and symlink

```bash
git clone https://github.com/rommelporras/kiro-config.git ~/personal/kiro-config

# Back up existing Kiro defaults (all 6 directories the loop will replace)
for dir in steering agents skills settings hooks docs; do
  [ -e ~/.kiro/$dir ] && [ ! -L ~/.kiro/$dir ] && mv ~/.kiro/$dir ~/.kiro/$dir.bak
done

# Symlink into ~/.kiro/
for dir in steering agents skills settings hooks docs; do
  ln -sfn ~/personal/kiro-config/$dir ~/.kiro/$dir
done
```

That's it. Settings (`cli.json`), hooks, steering, skills, and agent config are all
included in the symlinks — no manual `kiro-cli settings` commands needed.

> **If you're using paths other than `~/personal` or `~/eam`:** run `bash ~/personal/kiro-config/scripts/personalize.sh` to update agent allowedPaths to your project directories. See [Team Onboarding → Step 3](team-onboarding.md#step-3-personalize) for details.

## 3. Set AWS profile (if using AWS MCP servers)

MCP servers inherit `AWS_PROFILE` from the shell — no profile or region is hardcoded.

```bash
export AWS_PROFILE=<your-profile>
kiro-cli
```

If MCP servers fail to load, re-authenticate:

```bash
aws sso login --profile <your-profile>
```

> Skip this step if you don't use AWS. The Context7 MCP server works without any
> AWS configuration.

## 4. Verify

Inside a Kiro CLI session, run:

```
/context show
```

**Expected:**
- 11 global steering files (`engineering.md`, `tooling.md`, `universal-rules.md`, `python-boto3.md`, `security.md`, `aws-cli.md`, `shell-bash.md`, `typescript.md`, `web-development.md`, `frontend.md`, `design-principles.md`)
- 18 global skills
- 4 global MCP servers (Context7, AWS Docs, AWS Diagram, Playwright)

Also check:

```
/mcp       # MCP servers loaded
/tools     # Tools available and auto-approved
```

### What's auto-approved

The base agent pre-approves read-only tools (`read`, `grep`, `glob`, `web_fetch`,
`web_search`, Context7, AWS docs) so they run without prompts. Write and shell operations
still require approval — press `t` to trust a tool for the session.

### Trusted paths

- **Read:** `~/.kiro`, `~/personal`, `~/eam`
- **Write:** `~/personal`, `~/eam`

> Customize paths in `agents/base.json` → `toolsSettings` to match your directory layout.

## Updating

Pull the latest config:

```bash
cd ~/personal/kiro-config && git pull
```

Symlinks mean changes take effect on the next `kiro-cli` session — no re-linking needed.

## Kiro IDE (optional)

If you use Kiro IDE (not just CLI) on WSL2, see [IDE + WSL2 setup](kiro-ide-wsl-setup.md)
for the required extension fix.

## Next steps

- [Skill catalog](../reference/skill-catalog.md) — understand the 18 available skills
- [Security model](../reference/security-model.md) — how the 3 defense layers work
- [Creating custom agents](../reference/creating-agents.md) — build project-specific agents
- [Audit playbook](../reference/audit-playbook.md) — invariants and health checks for ongoing maintenance
- [Troubleshooting](troubleshooting.md) — when things break
