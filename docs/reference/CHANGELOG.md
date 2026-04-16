# Changelog

All notable changes to this project will be documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.4.0] - Unreleased

Orchestrator framework redesign, shell safety improvements, and TypeScript/frontend stack.

### Added
- `dev-kiro-config` agent - project-local agent for editing kiro-config files (agents, hooks, steering, skills)
- `design-and-spec` skill - merged brainstorming + spec-workflow + critical-thinking into single design skill
- `post-implementation` skill - automated quality gate, doc staleness check, auto-review, and improvement capture
- `create-pr` skill (project-local) - smart PR creation with spec-aware body generation via `gh pr create`
- `docs/improvements/` structure - auto-captured friction from sessions, reviewed during agent-audit
- Improvement capture in orchestrator - auto-appends friction to `docs/improvements/pending.md`
- Refactor pipeline workflow - reviewer -> user approval -> refactor -> reviewer
- Post-implementation automation - triggers on every subagent DONE, runs quality gate + review
- Retry limit (max 3) on review findings before escalating to user
- Doc reference check in commit skill - warns when staged files have unstaged doc references
- Task enrichment in subagent-driven-development - re-reads and enriches task context before dispatch
- Document tracking in subagent-driven-development - checkbox updates and divergence notes
- Codebase scan mode in dev-reviewer - depth-limited scan with structured findings
- Documentation accuracy review dimension (#10) in dev-reviewer
- Execute-findings mode in dev-refactor - processes review findings with TDD
- Shared code awareness in dev-refactor prompt
- Domain-specific agent design patterns in creating-agents.md
- Subagent tool limitations quick-ref in knowledge/rules.md

### Changed
- Orchestrator prompt rewritten (250+ lines to ~138 lines) with 7 clear sections
- Skills consolidated from 19 to 17 (removed 9, added 2, kept 5 subagent-only skills)
- Orchestrator model set to claude-opus-4.6
- Ship skill Step 1.5 delegates to create-pr skill instead of inline PR logic
- Codebase-audit skill rewritten with project-type detection and structured findings format
- Agent-audit skill rewritten absorbing meta-review (skill coverage, steering effectiveness, knowledge hygiene)
- Execution-planning skill adds stage completion tracking
- Skill catalog fully rewritten for new 17-skill lineup
- README updated with accurate counts (17 skills, 8 agents)

### Removed
- `brainstorming` skill (merged into design-and-spec)
- `spec-workflow` skill (merged into design-and-spec)
- `critical-thinking` skill (merged into design-and-spec)
- `meta-review` skill (absorbed into agent-audit)
- `delegation-protocol` skill (folded into orchestrator prompt)
- `aggregation` skill (folded into orchestrator prompt)
- `research-practices` skill (content moved to steering)
- `context-docs` skill (rarely used, content in steering)
- `project-architecture` skill (rarely used, content in steering)

## [v0.3.1] - 2026-04-13

Ship skill PR creation mode.

### Added
- Ship skill: PR creation mode when called from a feature branch - creates PR via `gh pr create` with changelog-derived body, then stops

### Changed
- Ship skill: "not on main" is no longer a hard stop - triggers PR creation instead
- Ship skill: branch cleanup uses `git fetch --prune` + local delete only (remote branch assumed deleted by GitHub on merge)

## [v0.3.0] - 2026-04-13

Orchestrator evolution — dev-docs agent, execution planning, quality gates, and 4 new orchestrator skills.

### Added
- `dev-docs` agent — lightweight specialist for config files, documentation, and mechanical text edits (no TDD, no linting)
- `agents/prompts/docs.md` — dev-docs system prompt
- `execution-planning` skill — generates parallel execution plans with agent routing, dependency tracking, and review gates
- `meta-review` skill — analyzes kiro-config effectiveness and proposes improvements
- `context-docs` skill — creates `docs/context/` AI knowledge base for any project
- `project-architecture` skill — restructures project folder layouts with phased migration plans
- `hooks/self-improve.sh` — maintenance script that checks for orphaned skills, routing overlaps, stale paths, and agent reference issues
- Post-implementation quality gate in orchestrator — full quality suite, end-to-end testing, stale reference audit, rendered output inspection
- Project context discovery in orchestrator — checks `docs/context/_Index.md`, `.kiro/steering/`, `README.md` in order
- Collaborative Design mode in brainstorming skill — iterative architectural brainstorming with user-driven convergence
- Plan file convention: `docs/specs/<name>/execution/phase-N.plan.md` for execution plans
- Phase 3.5 (execution planning) in spec-workflow between implementation planning and execution
- Content duplication check in agent-audit (Phase 4.6) — flags gotchas/rules that duplicate steering content
- Pre-dispatch checklist in dispatching-parallel-agents — extract file deletions, web searches, grep/glob for orchestrator
- Edge case checklist in delegation-protocol for CLI/display work
- Non-code task guidance in writing-plans — before/after strings and grep-based verification for file moves and config edits
- Quality Gate Before Commit section in steering/engineering.md
- `scripts/personalize.sh` — interactive setup script that replaces hardcoded paths in all agent configs
- `docs/setup/team-onboarding.md` — 5-minute teammate onboarding guide
- First-run personalization nudge in workspace-context.sh hook

### Changed
- Orchestrator direct-edit threshold tightened: 1-2 quick edits done directly, 3+ edits dispatched to dev-docs in a single briefing (was: <10 files)
- dev-refactor routing: bare `restructure`/`reorganize` stays with dev-refactor; only `restructure repo`/`reorganize repo` handled directly
- Auto-review gate: skip for dev-docs changes unless execution plan includes review stage (was: skip all docs-only changes)
- Spec workflow saves to `spec.md` (was `requirements.md`), design phase skippable when spec already covers it
- Writing-plans saves to `docs/specs/<name>/plan.md` (was `docs/plans/YYYY-MM-DD-<name>.md`)
- Subagent-driven-development: parallel dispatch OK for distinct files (was: never parallel)
- Gotchas and rules slimmed to pointers for quality gate content (canonical source: steering/engineering.md)
- README "Personalizing" section slimmed to point at `personalize.sh` and team-onboarding doc
- MCP server count in docs updated from 3 to 4 (Playwright was undocumented)
- Stale gotchas slimmed to pointers: "Agent Selection", "Orchestrator Direct Work", "Dispatch Batching", "Subagent Limitations" — all now resolved or codified in prompt/skills
- Orchestrator sequential edit anti-pattern captured in gotchas and rules — batch to dev-docs instead of sequential strReplace

### Fixed
- `git add.*` and `git commit.*` added to deniedCommands for all 4 implementation subagents (dev-docs, dev-python, dev-shell, dev-refactor) — previously only dev-reviewer blocked these
- `hooks/doc-consistency.sh` — hardcoded personal path replaced with portable `BASH_SOURCE` fallback
- `hooks/self-improve.sh` — false positives from unstripped `skill://`/`file://` URI prefixes and backtick-quoted non-path strings
- Execution-planning skill missing from orchestrator.json resources
- Plan file convention inconsistency (orchestrator prompt vs execution-planning skill)

## [v0.2.2] - 2026-04-12

Python quality hardening — bandit security scanning, robustness/testability review dimensions, and codified style rules.

### Added
- `bandit` security scanning added to `steering/tooling.md` as required Python tool
- `bandit -r <package>/ -q` step added to `python-audit` skill automated checks
- Security manual checklist (beyond bandit) in `python-audit` skill: eval/exec, pickle, hardcoded creds, shell injection, HTTP vs HTTPS, SQL injection
- Robustness (#8) and Testability (#9) review dimensions in code-reviewer prompt
- Naming rule: prefer reverse notation (`elements_active` not `active_elements`) in `steering/tooling.md`
- Logging rule: use `logging`/`structlog` over `print()` in production code in `steering/tooling.md`

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
