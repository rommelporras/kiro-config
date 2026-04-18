# kiro-config

Personal Kiro CLI configuration with multi-agent orchestrator, multi-domain steering (Python, TypeScript, shell, infra), layered security, and a self-learning knowledge system.

## Architecture

```
User ↔ devops-orchestrator (plans, converses, coordinates, git ops)
            ├── devops-docs      (edits config, docs, markdown — no TDD)
            ├── devops-python    (writes Python code, TDD, debugging)
            ├── devops-shell     (writes Bash/shell, system automation)
            ├── devops-typescript (writes TypeScript/Express, TDD with Vitest)
            ├── devops-frontend  (writes HTML/CSS/TS, Chart.js, accessibility)
            ├── devops-reviewer  (read-only analysis, no write tool)
            ├── devops-refactor  (restructures code, preserves behavior)
            ├── devops-terraform (read-only Terraform analysis, preflight gate)
            └── devops-kiro-config (project-local: kiro-config editing)

base — standalone fallback for general questions (no orchestration)
```

The `devops-orchestrator` is the default agent. It never writes executable code — config and markdown edits are handled directly for small scope (<10 files), everything else is delegated to specialists. Skills are curated per agent (no global wildcard loading).

## Features

- **12 steering docs** — engineering, tooling, universal rules, AWS CLI, security, Python/boto3, Shell/Bash, TypeScript, web development, frontend, design principles, terraform
- **19 skills** — curated per agent: planning, delegation, TDD, debugging, code review, and more
- **11 hooks** — secret scanning, sensitive file protection, bash write protection, sed/awk block on JSON, doc consistency, workspace context injection, session notification, terraform preflight gate, self-learning pipeline (context enrichment, correction detection, auto-capture, distillation)
- **11 agents** — devops-orchestrator + 9 specialists + base fallback
- **Self-learning knowledge pipeline** — corrections auto-captured, keywords tracked, rules auto-promoted
- **Knowledge base integration** — semantic search across config with auto-indexing
- **Infrastructure is read-only** — Kiro writes code in files but never executes mutating infra commands

## Structure

```
├── agents/          # Agent configurations
│   ├── devops-orchestrator.json  # Default — plans, delegates, git ops
│   ├── devops-docs.json           # Config/docs editor subagent
│   ├── devops-python.json        # Python specialist subagent
│   ├── devops-shell.json         # Shell/Bash specialist subagent
│   ├── devops-typescript.json    # TypeScript/Express specialist subagent
│   ├── devops-frontend.json      # Frontend specialist subagent
│   ├── devops-reviewer.json      # Read-only reviewer subagent
│   ├── devops-refactor.json      # Refactoring specialist subagent
│   ├── devops-terraform.json    # Read-only Terraform analyst subagent
│   ├── devops-kiro-config.json   # Project-local kiro-config editor (in .kiro/agents/)
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
│   ├── terraform-preflight.sh
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

This config ships with paths like `~/personal` and `~/eam` that are specific to the original author. Run the setup script from your clone directory to replace them with yours:

```bash
bash ~/your/path/kiro-config/scripts/personalize.sh
```

The script interactively updates `fs_read.allowedPaths` and `fs_write.allowedPaths` in all agent configs plus the knowledge base paths in `scripts/setup-knowledge.sh`.

**Setup walkthroughs:**
- [Install Checklist](docs/setup/kiro-cli-install-checklist.md) — Kiro CLI install, clone, symlink, verify
- [Team Onboarding](docs/setup/team-onboarding.md) — full 4-step setup for teammates (~5 minutes)
- [Troubleshooting](docs/setup/troubleshooting.md) — steering not loading, broken symlinks, hook false positives

### What NOT to change

These are shared safety and behavior contracts — changing them weakens the system for everyone on the team:

- `~/.kiro/` paths — standard Kiro CLI paths, same for everyone
- `deniedPaths` — protect sensitive directories (SSH keys, credentials, Kiro config itself). See [Security Model](docs/reference/security-model.md).
- `deniedCommands` — block destructive operations (recursive rm, infrastructure mutations, force push to main). Patterns are regex-anchored with `\A`/`\z`; see [Audit Playbook](docs/reference/audit-playbook.md) §1.1 for invariants and §7 for real failure cases if you're tempted to "clean them up."
- `hooks` blocks in agent JSONs — scan secrets, block destructive shell commands, inject knowledge rules. Defined per-agent because Kiro CLI hooks don't inherit across subagents.
- `includeMcpJson` and `@`-prefixed MCP tools — selectively enabled per agent. Disabling on subagents breaks library-doc lookups via Context7.
- `steering/` files — universal engineering standards, not path-dependent.
- `skills/` files — universal agent workflows, not path-dependent.

### Extending beyond paths

- **Add project directories later** — re-run `personalize.sh` or edit agent JSONs directly. Use `jq` for JSON edits, never `sed`.
- **Add project-local overrides** — drop a `.kiro/` directory in any project repo with its own `agents/`, `steering/`, or `skills/`. Applied only when that directory is your CWD.
- **Add a new specialist agent** — see [Creating Agents](docs/reference/creating-agents.md) for schema and security baseline.
- **Maintain the config as it grows** — run the quick health check in [Audit Playbook](docs/reference/audit-playbook.md) §2 before major changes.

## Agent Skill Assignments

| Skill | devops-orchestrator | devops-docs | devops-python | devops-shell | devops-typescript | devops-frontend | devops-reviewer | devops-refactor | devops-terraform | devops-kiro-config |
|-------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| design-and-spec | ✓ | | | | | | | | | |
| writing-plans | ✓ | | | | | | | | | |
| execution-planning | ✓ | | | | | | | | | |
| subagent-driven-development | ✓ | | | | | | | | | |
| dispatching-parallel-agents | ✓ | | | | | | | | | |
| post-implementation | ✓ | | | | | | | | | |
| commit | ✓ | | | | | | | | | |
| push | ✓ | | | | | | | | | |
| explain-code | ✓ | | | | | | | | ✓ | |
| agent-audit | ✓ | | | | | | | | | |
| trace-code | ✓ | | | | | | | | ✓ | |
| codebase-audit | ✓ | | | | | | | | | |
| test-driven-development | | | ✓ | | ✓ | | | ✓ | | |
| systematic-debugging | | | ✓ | ✓ | ✓ | | | | ✓ | |
| verification-before-completion | | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| receiving-code-review | | | ✓ | ✓ | ✓ | ✓ | | ✓ | | |
| python-audit | | | ✓ | | | | ✓ | | | |
| typescript-audit | | | | | | | ✓ | | | |
| terraform-audit | | | | | | | | | ✓ | |

**base agent** loads 14 of the 19 global skills — all orchestrator skills except dispatching-parallel-agents, execution-planning, subagent-driven-development, and post-implementation, plus the subagent-only skills. See [Skill Catalog](docs/reference/skill-catalog.md) for the full list.

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
| Terraform | `plan`, `validate`, `fmt`, `init`, `state list/show`, `workspace list/show/select`, `show`, `output`, `graph` | `apply`, `destroy`, `import`, `taint`, `init -upgrade`, `providers lock`, `console` |
| Helm | `lint`, `template`, `diff`, `list`, `get`, `status` | `install`, `upgrade`, `delete`, `rollback` |
| kubectl | `get`, `describe`, `logs`, `top`, `explain`, `diff` | `apply`, `delete`, `edit`, `patch`, `scale` |
| Docker | `inspect`, `images`, `ps`, `scout`, `history` | `push`, `run`, `build`, `compose up` |
| AWS CLI | `describe-*`, `list-*`, `get-*` | `create-*`, `update-*`, `delete-*`, `put-*`, `modify-*` |

## License

MIT

## Documentation

- [Skill Catalog](docs/reference/skill-catalog.md) — all 19 skills with triggers and agent assignments
- [Creating Agents](docs/reference/creating-agents.md) — how to add new specialist agents
- [Security Model](docs/reference/security-model.md) — 3-layer defense: hooks, denied paths, denied commands
- [Audit Playbook](docs/reference/audit-playbook.md) — invariants, quick health check, deep audit protocol, historical failure patterns
- [Changelog](docs/reference/CHANGELOG.md) — version history and release notes
- [Team Onboarding](docs/setup/team-onboarding.md) — get a teammate running in 5 minutes
- [Install Checklist](docs/setup/kiro-cli-install-checklist.md) — get running in 4 steps
- [Troubleshooting](docs/setup/troubleshooting.md) — common issues and fixes
- [IDE + WSL2 Setup](docs/setup/kiro-ide-wsl-setup.md) — Kiro IDE on WSL2 with Open Remote extension
- [Personal Setup](docs/setup/rommel-porras-setup.md) — chezmoi integration and dotfiles layout
