# Changelog

All notable changes to this project will be documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
