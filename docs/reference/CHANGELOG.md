# Changelog

All notable changes to this project will be documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.3.0] - 2026-04-12

Multi-agent orchestrator with agent-audit, research-practices, and foundation hardening.

### Added
- Multi-agent orchestrator pattern: dev-orchestrator delegates to dev-python, dev-shell, dev-reviewer, dev-refactor
- Agent prompts: `agents/prompts/orchestrator.md`, `python-dev.md`, `shell-dev.md`, `code-reviewer.md`, `refactor.md`
- 6 agent configs: `dev-orchestrator.json`, `dev-python.json`, `dev-shell.json`, `dev-reviewer.json`, `dev-refactor.json`, `base.json`
- `skills/agent-audit/` — audits agents, prompts, skills, and knowledge for gaps and inconsistencies
- `skills/research-practices/` — researches best practices via web search and Context7, proposes config updates
- `skills/spec-workflow/` — structured spec process for feature design
- `skills/delegation-protocol/` — structures subagent briefings
- `skills/aggregation/` — presents subagent results to user
- `knowledge/gotchas.md` — operational lessons (subagent limitations, AWS CLI in shell, Kiro platform, knowledge system)
- `hooks/feedback/session-log.sh` — stop hook logging session timestamps for audit analysis
- Personalization guide in README.md for team onboarding
- Implementation plan: `docs/plans/2026-04-12-foundation-hardening-and-self-review.md`

### Changed
- `knowledge/rules.md` — added 2 🔴 subagent limitation rules (total: 7)
- `agents/prompts/python-dev.md` — added pathlib, AWS CLI --no-cli-pager, mktemp patterns
- `agents/prompts/shell-dev.md` — added AWS CLI --no-cli-pager, mktemp, TRACE debug patterns
- `agents/prompts/code-reviewer.md` — added shell script, AWS CLI, and agent config review checklists
- `agents/dev-orchestrator.json` — added shell+write to allowedTools, registered new skills and session-log hook
- `hooks/security/block-sed-json.sh` — tightened regex to avoid false positives on compound commands
- README.md — updated feature counts (17 skills, 8 hooks), added personalization guide, updated structure

## [v0.2.0] - 2026-04-06

Best practices upgrade with self-learning knowledge system, SRE-focused steering, and read-only infrastructure policy.

### Added
- Self-learning knowledge pipeline: correction detection → auto-capture → distillation → context enrichment
  - `hooks/feedback/correction-detect.sh` — detects user corrections via userPromptSubmit hook
  - `hooks/feedback/auto-capture.sh` — 4-gate pipeline (filter, keyword extract, dedup, capacity)
  - `hooks/feedback/context-enrichment.sh` — injects 🔴 CRITICAL rules always, 🟡 RELEVANT by keyword match
  - `hooks/_lib/distill.sh` — auto-promotes episodes to rules after 3 keyword occurrences
- Knowledge foundation: `knowledge/rules.md` (5 seeded rules), `knowledge/episodes.md`, `knowledge/archive/`
- Security hook: `hooks/security/block-sed-json.sh` — blocks sed/awk/perl on JSON files
- 3 new steering docs: `aws-cli.md`, `security.md`, `python-boto3.md`
- Infrastructure read-only policy in `universal-rules.md` — explicit allowlist for terraform, helm, kubectl, docker, AWS CLI
- Infrastructure read-only 🔴 CRITICAL knowledge rule — auto-injected on any infra keyword
- `/knowledge` setup script: `scripts/setup-knowledge.sh`
- Updated README with hook chain table, self-learning pipeline diagram, and read-only policy matrix

### Changed
- `agents/base.json` — added userPromptSubmit hooks (context-enrichment, correction-detect) and block-sed-json preToolUse hook
- `universal-rules.md` — expanded with infrastructure read-only enforcement
- Welcome message updated to reflect new capabilities

### Removed
- `steering/terraform-helm.md` — removed; infra is read-only, mutation guidance not needed
- `steering/docker.md` — removed; same reason

## [v0.1.0](https://github.com/rommelporras/kiro-config/releases/tag/v0.1.0) - 2026-03-26

First release of kiro-config — opinionated global Kiro CLI configuration with 11 workflow skills, 3-layer security, and engineering steering.

### Added
- 11 auto-activating workflow skills: commit, push, explain-code, brainstorming, writing-plans, test-driven-development, systematic-debugging, verification-before-completion, receiving-code-review, dispatching-parallel-agents, subagent-driven-development
- 3-layer security: PreToolUse hooks (secret scanning, sensitive file protection, destructive command blocking), denied paths, denied commands
- Engineering steering rules: evidence over assertions, TDD, plan before building, conventional commits
- Base agent (`base.json`) with pre-approved read-only tools and security hooks
- MCP servers: Context7, AWS Documentation, AWS Diagram
- Documentation: install checklist, IDE + WSL2 setup, troubleshooting, skill catalog, security model, custom agent guide
