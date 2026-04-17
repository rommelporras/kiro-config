# kiro-config

Personal Kiro CLI configuration with multi-agent orchestrator, SRE-focused steering, security hooks, and a self-learning knowledge system.

## Architecture

```
User ↔ dev-orchestrator (plans, converses, coordinates, git ops)
            ├── dev-docs      (edits config, docs, markdown — no TDD)
            ├── dev-python    (writes Python code, TDD, debugging)
            ├── dev-shell     (writes Bash/shell, system automation)
            ├── dev-typescript (writes TypeScript/Express, TDD with Vitest)
            ├── dev-frontend  (writes HTML/CSS/TS, Chart.js, accessibility)
            ├── dev-reviewer  (read-only analysis, no write tool)
            ├── dev-refactor  (restructures code, preserves behavior)
            └── dev-kiro-config (project-local: kiro-config editing)

base — standalone fallback for general questions (no orchestration)
```

The `dev-orchestrator` is the default agent. It never writes executable code — config and markdown edits are handled directly for small scope (<10 files), everything else is delegated to specialists. Skills are curated per agent (no global wildcard loading).

## Features

- **11 steering docs** — engineering, tooling, universal rules, AWS CLI, security, Python/boto3, Shell/Bash, TypeScript, web development, frontend, design principles
- **18 skills** — curated per agent: planning, delegation, TDD, debugging, code review, and more
- **8 hooks** — secret scanning, sensitive file protection, bash write protection, block sed/awk on JSON, self-learning pipeline
- **10 agents** — dev-orchestrator + 8 dev specialists + base fallback
- **Self-learning knowledge pipeline** — corrections auto-captured, keywords tracked, rules auto-promoted
- **Knowledge base integration** — semantic search across config with auto-indexing
- **Infrastructure is read-only** — Kiro writes code in files but never executes mutating infra commands

## Structure

```
├── agents/          # Agent configurations
│   ├── dev-orchestrator.json  # Default — plans, delegates, git ops
│   ├── dev-docs.json           # Config/docs editor subagent
│   ├── dev-python.json        # Python specialist subagent
│   ├── dev-shell.json         # Shell/Bash specialist subagent
│   ├── dev-typescript.json    # TypeScript/Express specialist subagent
│   ├── dev-frontend.json      # Frontend specialist subagent
│   ├── dev-reviewer.json      # Read-only reviewer subagent
│   ├── dev-refactor.json      # Refactoring specialist subagent
│   ├── dev-kiro-config.json   # Project-local kiro-config editor (in .kiro/agents/)
│   ├── base.json              # Standalone fallback (no orchestration)
│   └── prompts/               # Markdown prompts for each agent
├── hooks/           # Hook scripts
│   ├── security/    # PreToolUse gates
│   │   └── block-sed-json.sh
│   ├── feedback/    # Self-learning pipeline
│   │   ├── context-enrichment.sh
│   │   ├── correction-detect.sh
│   │   └── auto-capture.sh
│   ├── _lib/        # Shared libraries
│   │   └── distill.sh
│   ├── workspace-context.sh
│   ├── scan-secrets.sh
│   ├── protect-sensitive.sh
│   ├── bash-write-protect.sh
│   ├── doc-consistency.sh
│   └── notify.sh
├── knowledge/       # Self-evolving knowledge base
│   ├── rules.md     # Permanent rules (🔴 critical + 🟡 relevant)
│   ├── episodes.md  # Captured corrections
│   ├── gotchas.md   # Known gotchas and edge cases
│   └── archive/     # Monthly archives
├── scripts/         # Setup and maintenance
├── settings/        # CLI settings (cli.json, mcp.json)
├── skills/          # 18 agent skills (curated per agent)
│   ├── agent-audit/
│   ├── design-and-spec/
│   └── ...
├── steering/        # 11 persistent context docs (includes design-principles.md)
└── docs/            # Reference and setup docs
```

## Setup

```bash
# Symlink into ~/.kiro
for dir in steering agents skills settings hooks docs; do
  ln -sfn /path/to/kiro-config/$dir ~/.kiro/$dir
done

# Configure knowledge bases (run inside kiro-cli)
bash scripts/setup-knowledge.sh
```

## Personalizing for Your Setup

This config ships with paths like `~/personal` and `~/eam` that are specific to the original author. Run the setup script to replace them with yours:

```bash
bash scripts/personalize.sh
```

The script updates `allowedPaths` in all agent configs and knowledge base paths interactively. See [Team Onboarding](docs/setup/team-onboarding.md) for the full setup walkthrough.

### What NOT to change

- `~/.kiro` paths — these are standard Kiro CLI paths, same for everyone
- `deniedPaths` — these protect sensitive directories and should stay as-is
- `deniedCommands` — these block dangerous operations and should stay as-is. Subagents use `rm -r.*`, `rm -f.*r.*`, `rm --recursive.*` (blocks recursive rm); dev-reviewer keeps the full `rm .*` block.
- `steering/` files — these are universal best practices, not path-dependent
- `skills/` files — these are universal, not path-dependent
- `hooks/` scripts — these use relative paths from `~/.kiro` and work for everyone

## Agent Skill Assignments

| Skill | dev-orchestrator | dev-docs | dev-python | dev-shell | dev-typescript | dev-frontend | dev-reviewer | dev-refactor | dev-kiro-config |
|-------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| design-and-spec | ✓ | | | | | | | | |
| writing-plans | ✓ | | | | | | | | |
| execution-planning | ✓ | | | | | | | | |
| subagent-driven-development | ✓ | | | | | | | | |
| dispatching-parallel-agents | ✓ | | | | | | | | |
| post-implementation | ✓ | | | | | | | | |
| commit | ✓ | | | | | | | | |
| push | ✓ | | | | | | | | |
| explain-code | ✓ | | | | | | | | |
| agent-audit | ✓ | | | | | | | | |
| trace-code | ✓ | | | | | | | | |
| codebase-audit | ✓ | | | | | | | | |
| test-driven-development | | | ✓ | | ✓ | | | ✓ | |
| systematic-debugging | | | ✓ | ✓ | ✓ | | | | |
| verification-before-completion | | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| receiving-code-review | | | ✓ | ✓ | ✓ | ✓ | | ✓ | |
| python-audit | | | ✓ | | | | ✓ | | |
| typescript-audit | | | | | | | ✓ | | |

**base agent** loads 14 of the 18 global skills — all orchestrator skills except dispatching-parallel-agents, execution-planning, subagent-driven-development, and post-implementation, plus the subagent-only skills. See [Skill Catalog](docs/reference/skill-catalog.md) for the full list.

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

- [Skill Catalog](docs/reference/skill-catalog.md) — all 18 skills with triggers and agent assignments
- [Creating Agents](docs/reference/creating-agents.md) — how to add new specialist agents
- [Security Model](docs/reference/security-model.md) — 3-layer defense: hooks, denied paths, denied commands
- [Audit Playbook](docs/reference/audit-playbook.md) — invariants, quick health check, deep audit protocol, historical failure patterns
- [Changelog](docs/reference/CHANGELOG.md) — version history and release notes
- [Team Onboarding](docs/setup/team-onboarding.md) — get a teammate running in 5 minutes
- [Install Checklist](docs/setup/kiro-cli-install-checklist.md) — get running in 4 steps
- [Troubleshooting](docs/setup/troubleshooting.md) — common issues and fixes
- [IDE + WSL2 Setup](docs/setup/kiro-ide-wsl-setup.md) — Kiro IDE on WSL2 with Open Remote extension
- [Personal Setup](docs/setup/rommel-porras-setup.md) — chezmoi integration and dotfiles layout
