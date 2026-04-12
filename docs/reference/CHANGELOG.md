# Changelog

All notable changes to this project will be documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.2.1] - 2026-04-12

Post-release audit fixes for v0.2.0 — documentation drift prevention, auto-review gate, and structural quality checks.

### Added
- `hooks/doc-consistency.sh` — pre-commit skill count drift checker (verifies docs match disk)
- Commit skill Step 2.5 — runs doc-consistency check before staging when config files change
- Structural quality checks in code-reviewer prompt (god objects >300 lines, SRP >10 methods, long functions >50 lines, deep nesting >3 levels, DRY >5 duplicate lines, parameter bloat >5 params)
- Auto-review gate in orchestrator — dev-reviewer runs automatically after subagent implementations
- Knowledge rule: run agent-audit after config changes to catch documentation drift

### Changed
- `agents/base.json` — curated 16 skills (replaced wildcard loading), added `code` tool, added `aws-documentation-mcp-server`
- `skills/agent-audit/SKILL.md` — expanded to 5 phases with documentation consistency checks (skill counts, matrix parity, description drift, file path validation, tool alignment, welcome message accuracy)
- `settings/mcp.json` — enabled `aws-documentation-mcp-server` (was disabled)
- `docs/reference/skill-catalog.md` — fixed stale `.kiro/specs/` path in workflow diagram, added base agent totals and note

### Fixed
- Stale `.kiro/specs/` path in skill-catalog workflow diagram (actual: `docs/specs/`)
- Dead `.kiro/specs/**` entry in orchestrator `fs_write.allowedPaths`
- `grep` silent abort bug in `doc-consistency.sh` under `set -euo pipefail` (added `|| true` to all pipelines)

### Removed
- Empty `skills/ship/` directory (SKILL.md was never created)

## [v0.2.0] - 2026-04-12

Multi-agent orchestrator, self-learning knowledge system, curated skill assignments, and AgentSpawn workspace context.

### Added
- Multi-agent orchestrator: dev-orchestrator delegates to dev-python, dev-shell, dev-reviewer, dev-refactor
- 6 agent configs with curated skill assignments (no wildcard loading)
- Agent prompts: `orchestrator.md`, `python-dev.md`, `shell-dev.md`, `code-reviewer.md`, `refactor.md`
- 3 new skills: `critical-thinking` (Socratic questioning), `trace-code` (code flow tracing with file:line refs), `codebase-audit` (periodic health check: churn, complexity, coverage, deps, TODOs)
- 7 orchestrator skills: `spec-workflow`, `delegation-protocol`, `aggregation`, `agent-audit`, `research-practices`, `brainstorming`, `writing-plans`
- Self-learning knowledge pipeline: correction detection → auto-capture → distillation → context enrichment
- Knowledge foundation: `rules.md` (7 rules), `episodes.md`, `gotchas.md`, `archive/`
- AgentSpawn hook: `workspace-context.sh` — injects git branch, last commit, Python version, project steering at session start
- Security hook: `block-sed-json.sh` — blocks sed/awk/perl on JSON files
- 4 new steering docs: `aws-cli.md`, `security.md`, `python-boto3.md`, `shell-bash.md`
- Infrastructure read-only policy with explicit allow/deny lists for terraform, helm, kubectl, docker, AWS CLI
- THINK FIRST pre-edit checklist in dev-python, dev-shell, dev-refactor prompts
- Architecture review dimension (#7) in dev-reviewer prompt
- Python 3.12+ patterns: PEP 695 type params, generator expressions, functools.cache
- Personalization guide in README for team onboarding
- `agent_config.json.example` with curated resources, full deny lists, and security deniedPaths
- Project-local `ship` skill (`.kiro/skills/ship/`) for release automation with branch cleanup

### Changed
- Subagents pinned to `claude-sonnet-4.6`; orchestrator and base remain on `auto`
- Skill assignments curated per agent (20 skills total, each agent gets only what it needs)
- README updated: 20 skills, 7 steering docs, updated skill assignment matrix, added Documentation section with links to all docs, added agentSpawn to hook chain, fixed stale structure tree
- Install checklist: 7 steering files, 20 skills
- Troubleshooting: 7 steering files listed
- Skill catalog: 20 skills with 3 new orchestrator entries

### Removed
- `steering/terraform-helm.md` — infra is read-only, mutation guidance not needed
- `steering/docker.md` — same reason
- `hooks/feedback/session-log.sh` — nothing consumed its output
- Dead `section_cap_enforce()` stub from `distill.sh`
- Removed misplaced skill assignments: explain-code from dev-python/dev-reviewer/dev-refactor, test-driven-development from dev-shell, python-audit from dev-refactor

## [v0.1.0](https://github.com/rommelporras/kiro-config/releases/tag/v0.1.0) - 2026-03-26

First release of kiro-config — opinionated global Kiro CLI configuration with 11 workflow skills, 3-layer security, and engineering steering.

### Added
- 11 auto-activating workflow skills: commit, push, explain-code, brainstorming, writing-plans, test-driven-development, systematic-debugging, verification-before-completion, receiving-code-review, dispatching-parallel-agents, subagent-driven-development
- 3-layer security: PreToolUse hooks (secret scanning, sensitive file protection, destructive command blocking), denied paths, denied commands
- Engineering steering rules: evidence over assertions, TDD, plan before building, conventional commits
- Base agent (`base.json`) with pre-approved read-only tools and security hooks
- MCP servers: Context7, AWS Documentation, AWS Diagram
- Documentation: install checklist, IDE + WSL2 setup, troubleshooting, skill catalog, security model, custom agent guide
