# Changelog

All notable changes to this project will be documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.6.1] - 2026-04-18

Patch release — log accuracy rule, skill step additions, and doc corrections.

### Added
- `steering/engineering.md` — "Logs are operational data" rule: log entries must be accurate, never log fake success/failure counts
- `hooks/doc-consistency.sh` — extended to check agent and hook counts (was skill-only)
- `skills/post-implementation/SKILL.md` — Step 7 "Spec completion check" for marking specs complete after final phase
- `skills/post-implementation/SKILL.md` — metrics staleness grep in Step 3 (test counts, coverage percentages in docs/)
- `skills/execution-planning/SKILL.md` — atomic dispatch rule for load-bearing task ordering
- `agents/prompts/dev-python.md` — "After removing code" section: grep tests for removed symbols, verify argparse help text
- `agents/prompts/orchestrator.md` — TDD override for packaged code in delegation format
- `docs/audit/audit-triage-v0.5.1.md` — definitive triage of all 48 audit findings with verification commands

### Fixed
- `hooks/doc-consistency.sh` — regex patterns updated to match actual README/skill-catalog text ("loads N of the N global skills")
- `docs/reference/audit-playbook.md` — A1 invariant check narrowed to trigger line only (was matching all `dev-*` mentions in skill file)
- Prompt file naming inconsistency — renamed 7 prompt files to match agent names (e.g., `docs.md` → `dev-docs.md`), updated all 8 JSON config `file://` refs, and fixed stale `code-reviewer` references in `steering/security.md` and `skills/subagent-driven-development/SKILL.md`

### Changed
- `docs/improvements/pending.md` — ECS session items moved to resolved.md (pending now empty)
- `docs/improvements/resolved.md` — 8 resolved items from ECS refactoring session added
- `docs/TODO.md` — documented doc-consistency.sh regex bug and audit-playbook A1 comparison issue
- `.kiro/skills/create-pr/SKILL.md` — `--base main` replaced with dynamic default branch detection via `gh repo view`
- `docs/audit/audit-triage-v0.5.1.md` and `docs/audit/audit-triage-v0.6.0.md` — 8 findings reclassified (7 INTENTIONAL, 1 OBSOLETE); PARTIAL miscounting corrected
- Audit documents moved from `docs/specs/` to `docs/audit/` — `audit-current-workflow.md`, `audit-triage-v0.5.1.md`, `audit-triage-v0.6.0.md`

## [v0.6.0] - 2026-04-17

Backlog remediation — closes seven deferred findings from the v0.5.1 audit
backlog. Four safety tightenings, one ergonomics loosening, one
documentation addition, plus M-03 (shell in allowedTools) coupled to H-05. Zero new features.

### Added
- `hooks/protect-sensitive.sh` PROTECTED array: `id_dsa`, `.p12`, `.pfx`,
  `kubeconfig`, `.tfstate` — covers legacy SSH, PKCS#12 keystores, Kubernetes
  credentials, and Terraform state. Six new test cases in `scripts/test-hooks.sh`.
- `agents/dev-orchestrator.json` deny list: `aws s3 cp/mv/rm/sync` — parallels
  the existing hyphenated-action pattern coverage.
- `agents/prompts/orchestrator.md` — "Subagent timeout and recovery"
  subsection for stuck-subagent detection and user escalation.

### Changed
- `agents/dev-docs.json` — replaced blanket `python3? .*`, `node .*`,
  `npm .*`, `uv .*`, `pip .*` denies with mutating-subcommand-only patterns
  (enumerative approach). `dev-docs` can now run `python3 --version`,
  `npm ls`, `pip list`, etc. Mutation-form invocations (`npm install`,
  `pip install`, `uv run`, etc.) still blocked. `shell` added to
  `allowedTools` (closes M-03 — shell was in tools but not allowedTools, requiring user approval for every invocation).
- `agents/dev-orchestrator.json` — `git add .*` tightened to two patterns:
  `git add [^-.].*` + `git add -- .*`. Blocks `git add -A`, `git add .`,
  `git add --all` at the platform level. Dotfile staging via
  `git add -- .env.example`.

### Fixed
- `hooks/feedback/*.sh` — `/tmp/kb-*` flag paths now namespaced with
  `$USER`. Prevents cross-user collision on shared hosts.

### Known limitations
- dev-docs enumerative deny list may miss newly-added mutating subcommands
  for npm/uv/pip. New candidates will be added as friction surfaces.
- `~/.kube/config` (basename `config`) is NOT covered by the new
  kubeconfig pattern — `protect-sensitive.sh` is basename-only.
- Hybrid deny+allow approach (blanket deny + allowedCommands override)
  was tested and rejected: Kiro CLI does not support allow-wins precedence
  for `allowedCommands` vs `autoAllowReadonly` gating. Enumerative deny
  is the working fallback.

## [v0.5.1] - 2026-04-17

Post-release hardening — hook false-positive fixes, protection gaps closed
via Kiro counter-audit, onboarding UX improvements, and stale-reference
cleanup across reference docs. Adds `audit-playbook.md` as the living
reference for invariant-based health checks and a `scripts/test-hooks.sh`
regression suite (33 tests) wired into the playbook's S9 invariant.

### Added
- `docs/reference/audit-playbook.md` — invariants (security/accuracy/consistency/documentation),
  15-minute quick health check, deep audit protocol, design rules for new config, and 18 historical
  failure patterns. Cross-linked from README and all related reference docs.
- `scripts/test-hooks.sh` — 33-test functional regression suite for hook behavior (known-safe
  commands pass, known-dangerous commands block). Referenced by playbook invariant S9.
- Known-limitations section (playbook §1.5) documenting `dev-kiro-config` project-local scoping,
  rm first-token trade-off, shell-indirection bypass, and `base.json` design choice.
- `bash-write-protect.sh` now blocks additional destructive forms: `of=/dev/sd`, `of=/dev/nvme`,
  `of=/dev/hd` (dd writing to devices — the actually-destructive form), `mkfs -t` (older syntax),
  `> /dev/hd` (shell redirect to legacy IDE devices).

### Changed
- README: "multi-domain steering" tagline replaces stale "SRE-focused" framing (steering now covers
  Python, TypeScript, shell, infra, web, frontend).
- README: hook count corrected from 8 to 11 with expanded description.
- README: "Personalizing for Your Setup" section rewritten — clarified `personalize.sh` invocation
  path, added setup-walkthrough links, added `hooks`/`includeMcpJson`/MCP to "What NOT to change",
  added "Extending beyond paths" subsection.
- team-onboarding.md: fixed broken `~/.kiro/scripts/personalize.sh` path (scripts/ isn't symlinked —
  now uses the clone path directly); expanded directory backup to cover all 6 symlinked dirs with
  `ln -sfn` re-run safety; added HTTPS clone alternative; completed agent tree diagram (was missing
  dev-typescript, dev-frontend, dev-kiro-config); added `ctrl+o` shortcut mention; added 4-status
  delegation protocol section; linked audit playbook.
- kiro-cli-install-checklist.md: expanded backup loop, cross-linked `personalize.sh` step for users
  on non-default paths, added audit playbook to Next steps.
- orchestrator.md: strengthened `dev-kiro-config` routing with explicit project-local Scope block
  (in-repo dispatches work; out-of-repo falls back to dev-docs).
- security-model.md: Layer 3 denied-commands section rewritten to reflect actual current state
  (4-pattern rm deny, orchestrator rm coverage, dd pattern anchoring, defense-in-depth via hooks).
- creating-agents.md: new-agent recipe updated with current rm/dd patterns (was propagating
  v0.5.0's pre-fix patterns to any newly-created agent).
- knowledge/gotchas.md: corrected false claim that subagents have no preToolUse hooks (Phase 1
  added 4 hooks to every subagent; hooks don't inherit — defined per-agent).
- agent-audit SKILL.md Phase 8: stale example counts updated to v0.5.0 baseline (11 steering,
  18 skills, 11 hooks, 10 agents).
- audit-playbook.md D1 invariant: extended from skill-only to skill+agent+hook count verification;
  quick-check script runs all three.

### Fixed
- **Hook false positives:**
  - Commit messages containing descriptive text like `dd if=/dev`, `mkfs.`, `chmod -R 777 /` no
    longer blocked by `bash-write-protect.sh` when the invoking command is read-only (git, echo,
    printf, grep, cat, etc.).
  - `git rm`, `docker rm`, `npm rm` no longer caught by rm safety — the rm path-check now gates
    on the first command token rather than word-boundary `\brm\b`.
  - `.env.example`, `.env.sample`, `.pem.template`, `credentials.json.dist` no longer blocked by
    `protect-sensitive.sh` (basename matching with safe-suffix allowlist; `.env.bak` intentionally
    still blocked — it's a credential backup).
  - Documented placeholders (`"your_password_here"`, `"CHANGEME_before_deploy"`, AWS IAM example
    keys) no longer blocked by `scan-secrets.sh` (whole-value placeholder check replaces the naive
    substring filter).
- **Hook protection gaps (found during Kiro counter-audit):**
  - `dd of=/dev/sda` — the actually-destructive form of dd (writing TO a device) now blocked.
    Previously only `dd if=/dev` (reading FROM a device) was caught.
  - `mkfs -t ext4 /dev/sda1` (older syntax) now blocked.
  - Compound commands like `echo hi && rm -rf /tmp` now blocked — catastrophic rm checks run
    unconditionally rather than gated on the leading command.
  - `find -exec <destructive>` no longer slips through the readonly allowlist — `find` removed
    since its `-exec` can delegate arbitrary commands.
  - Adversarial placeholder bypass (value containing a placeholder marker alongside real-looking
    content) now blocked via whole-value matching plus a 3-digit entropy heuristic.
- **Stale documentation patterns:**
  - `docs/reference/creating-agents.md` new-agent recipe no longer propagates pre-Phase-1 rm
    and dd patterns.
  - `docs/reference/security-model.md` no longer claims the orchestrator has no rm deny
    (Phase 1 added patterns).
  - `docs/setup/troubleshooting.md` replaced hardcoded `~/personal/kiro-config/docs/` with
    portable `~/.kiro/docs/`.
  - README "SRE-focused" tagline and "8 hooks" count corrected.

### Infrastructure
- All shell files (`hooks/*.sh`, `scripts/test-hooks.sh`) shellcheck-clean.
- `bash scripts/test-hooks.sh` integrated into the playbook's §2 quick health check.

## [v0.5.0] - 2026-04-17

Major audit remediation release. Addresses 5 CRITICAL, 16 HIGH, and several
MEDIUM findings from the workflow audit (`docs/audit/audit-current-workflow.md`).

### Added
- Design principles steering document (`steering/design-principles.md`)
- TDD skill on dev-frontend and dev-shell (frontend: Vitest + happy-dom + Playwright; shell: bats-core)
- Selective MCP access for subagents: Context7 (5 agents), AWS Documentation (dev-python), Playwright (dev-frontend)
- Security hooks (scan-secrets, protect-sensitive, bash-write-protect, block-sed-json) on all subagents
- File-conflict pre-check rule in execution-planning skill
- Project-level `.kiro/steering/agent-config-review.md` checklist
- Workflow audit document (`docs/audit/audit-current-workflow.md`) as living reference
- `~/.kiro/docs` symlink in setup docs so future installs get the docs directory
- Auto-capture fallback to `general` keyword bucket (no more silent drops)
- Systematic-debugging skill on dev-refactor

### Changed
- All 8 agent prompts deduplicated against steering (prompts now reference steering as authority)
- Post-implementation trigger list synced with orchestrator (now includes dev-kiro-config, dev-frontend)
- Orchestrator prompt corrected to accurately describe subagent MCP access
- Knowledge distillation: `general` bucket requires 5 occurrences to promote (vs 3 for specific keywords)
- `writing-plans` skill references `dev-reviewer` (was ghost reference to nonexistent `plan-reviewer`)
- Improvement capture path moved from `~/personal/kiro-config/...` to `~/.kiro/docs/improvements/pending.md`
- Steering doc count updated 10 → 11 in README, team-onboarding, install-checklist

### Fixed
- `dd if/dev` typo in 8 agent deny-lists (was matching literal only, not real commands); added to dev-docs and dev-kiro-config which lacked the pattern
- `rm -f.*r.*` regex false positive (blocked any `rm -f` with 'r' in filename)
- Orchestrator missing `rm -r.*` and `rm --recursive.*` deny patterns
- Regex injection vulnerability in `context-enrichment.sh` (keywords now escaped)
- `distill.sh` sed command corrupting episode format (replaced with awk; added archive_promoted regression fix)
- Orchestrator `fs_write.allowedPaths` overly broad (`*.md` removed; scoped to project dirs)

## [v0.4.1] - 2026-04-16

Agent audit fixes — documentation drift, knowledge cleanup, security hardening.

### Added
- Directory tree and feature count verification in agent-audit Phase 8
- Project-local skills section in skill-catalog (create-pr, ship)
- Infrastructure deny patterns for dev-kiro-config (kubectl, terraform, helm, docker, AWS mutating)

### Changed
- `knowledge/rules.md` slimmed from 17 rules to 6 — removed 11 rules duplicating steering docs
- README hooks directory tree now shows all scripts (added doc-consistency.sh, auto-capture.sh, distill.sh)
- Skill-catalog and README: base agent description corrected (claimed 5 skills, actual 14)
- Skill-catalog and README: dev-refactor TDD checkmark added, totals updated (2 → 3)
- Skill-catalog: TDD agent list corrected (added dev-typescript, dev-refactor)
- `agents/base.json` welcomeMessage corrected (16 → 14 skills)

### Removed
- `hooks/self-improve.sh` — dead code, unreferenced by any agent or script
- 3 resolved gotchas from `knowledge/gotchas.md` (Agent Selection, Orchestrator Direct Work, Subagent Dispatch Batching)
- 7 noise episodes from `knowledge/episodes.md`

## [v0.4.0] - 2026-04-16

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
- `dev-typescript` agent - TypeScript/Express backend specialist with TDD via Vitest
- `dev-frontend` agent - HTML/CSS/TypeScript frontend specialist with Chart.js and accessibility
- `typescript-audit` skill - TypeScript quality audit for dev-reviewer (ESLint, tsc, Vitest, manual checklist)
- `steering/typescript.md` - TypeScript conventions (strict mode, Zod, ESLint, Vitest, naming)
- `steering/web-development.md` - Express.js patterns, REST API design, CORS, Zod validation
- `steering/frontend.md` - HTML/CSS/TS frontend conventions, Chart.js, accessibility, verification checklist
- Smart rm detection in `bash-write-protect.sh` - allows single-file rm within allowed paths, blocks recursive rm
- File operations routing lane in orchestrator - handles move/rename/delete directly
- TypeScript and frontend routing lanes in orchestrator
- Parallel dispatch lane for full-stack features (dev-typescript + dev-frontend)

### Changed
- Orchestrator prompt rewritten (250+ lines to ~138 lines) with 7 clear sections
- Skills consolidated from 19 to 17 (removed 9, added 2, kept 5 subagent-only skills)
- Orchestrator model set to claude-opus-4.6
- Ship skill Step 1.5 delegates to create-pr skill instead of inline PR logic
- Codebase-audit skill rewritten with project-type detection and structured findings format
- Agent-audit skill rewritten absorbing meta-review (skill coverage, steering effectiveness, knowledge hygiene)
- Execution-planning skill adds stage completion tracking
- Skill catalog fully rewritten for new 17-skill lineup
- README updated with accurate counts (18 skills, 10 agents, 10 steering docs)
- `deniedCommands` updated across all agents: `rm .*` replaced with `rm -r.*`, `rm -f.*r.*`, `rm --recursive.*` (except dev-reviewer which keeps full block)
- Orchestrator `rm .*` removed from deniedCommands (protected by hook instead)
- `tooling.md` updated with Node.js/TypeScript quality section and project-specific environments
- Skill catalog updated with typescript-audit and new agent columns
- Creating-agents.md updated with dev-typescript and dev-frontend in architecture diagram
- dev-reviewer resources updated with typescript-audit skill

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
