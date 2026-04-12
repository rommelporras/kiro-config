# kiro-config

Personal Kiro CLI configuration with multi-agent orchestrator, SRE-focused steering, security hooks, and a self-learning knowledge system.

## Architecture

```
User ↔ dev-orchestrator (plans, converses, coordinates, git ops)
            ├── dev-python    (writes Python code, TDD, debugging)
            ├── dev-shell     (writes Bash/shell, system automation)
            ├── dev-reviewer  (read-only analysis, no write tool)
            └── dev-refactor  (restructures code, preserves behavior)

base — standalone fallback for general questions (no orchestration)
```

The `dev-orchestrator` is the default agent. It never writes code — it delegates to specialists. Skills are curated per agent (no global wildcard loading).

## Features

- **7 steering docs** — engineering, tooling, universal rules, AWS CLI, security, Python/boto3, Shell/Bash
- **20 skills** — curated per agent: planning, delegation, TDD, debugging, code review, and more
- **8 security hooks** — secret scanning, sensitive file protection, bash write protection, block sed/awk on JSON, self-learning pipeline
- **6 agents** — dev-orchestrator + 4 dev specialists + base fallback
- **Self-learning knowledge pipeline** — corrections auto-captured, keywords tracked, rules auto-promoted
- **Knowledge base integration** — semantic search across config with auto-indexing
- **Infrastructure is read-only** — Kiro writes code in files but never executes mutating infra commands

## Structure

```
├── agents/          # Agent configurations
│   ├── dev-orchestrator.json  # Default — plans, delegates, git ops
│   ├── dev-python.json        # Python specialist subagent
│   ├── dev-shell.json         # Shell/Bash specialist subagent
│   ├── dev-reviewer.json      # Read-only reviewer subagent
│   ├── dev-refactor.json      # Refactoring specialist subagent
│   ├── base.json              # Standalone fallback (no orchestration)
│   └── prompts/               # Markdown prompts for each agent
├── hooks/           # Hook scripts
│   ├── security/    # PreToolUse gates
│   ├── feedback/    # Self-learning pipeline
│   ├── _lib/        # Shared libraries
│   ├── workspace-context.sh
│   ├── scan-secrets.sh
│   ├── protect-sensitive.sh
│   ├── bash-write-protect.sh
│   └── notify.sh
├── knowledge/       # Self-evolving knowledge base
│   ├── rules.md     # Permanent rules (🔴 critical + 🟡 relevant)
│   ├── episodes.md  # Captured corrections
│   ├── gotchas.md   # Known gotchas and edge cases
│   └── archive/     # Monthly archives
├── scripts/         # Setup and maintenance
├── settings/        # CLI settings (cli.json, mcp.json)
├── skills/          # 20 agent skills (curated per agent)
│   ├── agent-audit/
│   ├── research-practices/
│   └── ...
├── steering/        # 7 persistent context docs
└── docs/            # Reference and setup docs
```

## Setup

```bash
# Symlink into ~/.kiro
for dir in steering agents skills settings hooks; do
  ln -sfn /path/to/kiro-config/$dir ~/.kiro/$dir
done

# Configure knowledge bases (run inside kiro-cli)
bash scripts/setup-knowledge.sh
```

## Personalizing for Your Setup

This config ships with paths like `~/personal` and `~/eam` that are specific to the original author. You MUST update these to match your own directory structure before using it.

### What to change

**Agent configs** — these control where agents can read/write files:

| File | Settings to update |
|------|-------------------|
| `agents/base.json` | `fs_read.allowedPaths`, `fs_write.allowedPaths` |
| `agents/dev-orchestrator.json` | `fs_read.allowedPaths`, `fs_write.allowedPaths` |
| `agents/dev-python.json` | `fs_write.allowedPaths` |
| `agents/dev-shell.json` | `fs_write.allowedPaths` |
| `agents/dev-refactor.json` | `fs_write.allowedPaths` |

In each file, replace `~/personal` and `~/eam` with your own project directories. For example, if your projects live in `~/projects`:

```json
"allowedPaths": [
  "~/projects/**",
  "./**"
]
```

The `./**` entry allows agents to work in whatever directory you launch Kiro from.

**Setup script:**

| File | What to change |
|------|---------------|
| `scripts/setup-knowledge.sh` | Update knowledge base paths to your project directories |

**Symlink command** — update the clone path in the setup step:

```bash
# Replace ~/personal/kiro-config with wherever you cloned this repo
for dir in steering agents skills settings hooks; do
  ln -sfn /path/to/your/kiro-config/$dir ~/.kiro/$dir
done
```

### What NOT to change

- `~/.kiro` paths — these are standard Kiro CLI paths, same for everyone
- `deniedPaths` — these protect sensitive directories and should stay as-is
- `deniedCommands` — these block dangerous operations and should stay as-is
- `steering/` files — these are universal best practices, not path-dependent
- `skills/` files — these are universal, not path-dependent
- `hooks/` scripts — these use relative paths from `~/.kiro` and work for everyone

## Agent Skill Assignments

| Skill | dev-orchestrator | dev-python | dev-shell | dev-reviewer | dev-refactor |
|-------|:---:|:---:|:---:|:---:|:---:|
| spec-workflow | ✓ | | | | |
| brainstorming | ✓ | | | | |
| writing-plans | ✓ | | | | |
| delegation-protocol | ✓ | | | | |
| aggregation | ✓ | | | | |
| subagent-driven-development | ✓ | | | | |
| dispatching-parallel-agents | ✓ | | | | |
| commit | ✓ | | | | |
| push | ✓ | | | | |
| explain-code | ✓ | | | | |
| agent-audit | ✓ | | | | |
| research-practices | ✓ | | | | |
| critical-thinking | ✓ | | | | |
| trace-code | ✓ | | | | |
| codebase-audit | ✓ | | | | |
| test-driven-development | | ✓ | | | |
| systematic-debugging | | ✓ | ✓ | | |
| verification-before-completion | | ✓ | ✓ | ✓ | ✓ |
| receiving-code-review | | ✓ | ✓ | | ✓ |
| python-audit | | ✓ | | ✓ | |

**base agent** loads 16 of 20 skills (all except the 4 orchestrator-only delegation skills). See [Skill Catalog](docs/reference/skill-catalog.md) for details.

## Self-Learning Pipeline

```
User correction → correction-detect.sh → auto-capture.sh → episodes.md
                                                                ↓
                                              (3+ keyword occurrences)
                                                                ↓
context-enrichment.sh ← distill.sh ← rules.md (auto-promoted)
        ↓
  Injected into agent context on every prompt
```

## Hook Chain

| Hook Type | Matcher | Script | Purpose |
|-----------|---------|--------|---------|
| agentSpawn | — | workspace-context.sh | Inject git branch, Python version, project context |
| preToolUse | fs_write | scan-secrets.sh | Block hardcoded secrets |
| preToolUse | fs_write | protect-sensitive.sh | Block writes to .env, .pem, etc. |
| preToolUse | execute_bash | bash-write-protect.sh | Block destructive commands |
| preToolUse | execute_bash | block-sed-json.sh | Block sed/awk on JSON files |
| userPromptSubmit | * | context-enrichment.sh | Inject knowledge rules |
| userPromptSubmit | * | correction-detect.sh | Detect and capture corrections |
| stop | * | notify.sh | Notification sound |

**Note:** Hooks only fire on the orchestrator (main agent). Subagent security is enforced via `toolsSettings` (deniedCommands, allowedPaths).

## Infrastructure Read-Only Policy

Kiro may write infrastructure code in files but **never executes mutating commands**.

| Tool | Allowed (read-only) | Blocked (mutating) |
|------|---------------------|--------------------|
| Terraform | `plan`, `validate`, `fmt`, `state list`, `state show` | `apply`, `destroy`, `import`, `taint` |
| Helm | `lint`, `template`, `diff`, `list`, `get`, `status` | `install`, `upgrade`, `delete`, `rollback` |
| kubectl | `get`, `describe`, `logs`, `top`, `explain`, `diff` | `apply`, `delete`, `edit`, `patch`, `scale` |
| Docker | `inspect`, `images`, `ps`, `scout`, `history` | `push`, `run`, `build`, `compose up` |
| AWS CLI | `describe-*`, `list-*`, `get-*` | `create-*`, `update-*`, `delete-*`, `put-*`, `modify-*` |

## License

MIT

## Documentation

- [Skill Catalog](docs/reference/skill-catalog.md) — all 20 skills with triggers and agent assignments
- [Creating Agents](docs/reference/creating-agents.md) — how to add new specialist agents
- [Security Model](docs/reference/security-model.md) — 3-layer defense: hooks, denied paths, denied commands
- [Changelog](docs/reference/CHANGELOG.md) — version history and release notes
- [Install Checklist](docs/setup/kiro-cli-install-checklist.md) — get running in 4 steps
- [Troubleshooting](docs/setup/troubleshooting.md) — common issues and fixes
- [IDE + WSL2 Setup](docs/setup/kiro-ide-wsl-setup.md) — Kiro IDE on WSL2 with Open Remote extension
- [Personal Setup](docs/setup/rommel-porras-setup.md) — chezmoi integration and dotfiles layout
