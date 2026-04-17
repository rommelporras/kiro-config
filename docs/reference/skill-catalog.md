<!-- Author: Rommel Porras -->

# Skill Catalog

[Back to README](../../README.md) | Related: [Creating agents](creating-agents.md) | [Security model](security-model.md) | [Audit playbook](audit-playbook.md)

Quick reference for all 18 skills — what they do, when they activate, and which agents load them.
12 skills load on dev-orchestrator; 6 are subagent-only.

## Workflow chain

The design-to-implementation flow chains skills through the orchestrator:

```
design-and-spec → writing-plans → execution-planning → subagent-driven-development
```

Each skill activates independently by description matching. The chain is optional.

## Skills by category

### Orchestrator — planning and coordination

| Skill | Agent(s) | What it does | Activates when you say... |
|---|---|---|---|
| **design-and-spec** | dev-orchestrator | Merged brainstorming + spec-workflow + critical-thinking. Two entry modes: exploratory ("brainstorm") and directed ("spec out"). Challenges assumptions, proposes 2-3 approaches, writes spec to `docs/specs/`. Hard gate: no code until design is approved. | "brainstorm", "spec out", "let's design", "define requirements" |
| **writing-plans** | dev-orchestrator | Decomposes a spec into bite-sized tasks. Each task is one action with exact file paths. | "plan how to implement this" |
| **execution-planning** | dev-orchestrator | Generates parallel execution plans from spec phases with agent routing, dependency tracking, and review gates. | "plan execution", "generate execution plan" |
| **subagent-driven-development** | dev-orchestrator | Executes a plan by dispatching one delegate per task with two-stage review. Updates plan checkboxes after each task. | "implement the plan using delegates" |
| **dispatching-parallel-agents** | dev-orchestrator | Dispatches multiple delegates concurrently for independent tasks. | "run these tasks in parallel" |
| **post-implementation** | dev-orchestrator | Automatic quality gate after subagent returns DONE: runs project-type-aware quality suite, checks doc staleness, dispatches dev-reviewer, captures friction to `docs/improvements/pending.md`. | (internal — fires automatically after subagent DONE) |
| **agent-audit** | dev-orchestrator | Audits agents, prompts, skills, and knowledge for gaps and inconsistencies. Reads `docs/improvements/pending.md`. Proposes changes. | "agent-audit", "audit agents", "review config" |
| **trace-code** | dev-orchestrator | Deep code flow tracing from entry point to output with file:line references. | "trace this", "map the code flow", "what files are involved in" |
| **codebase-audit** | dev-orchestrator | Periodic health check: git churn, complexity, coverage, deps, TODOs. Structured findings with severity/effort/agent. | "health check", "technical debt", "codebase audit" |

### Git operations

| Skill | Agent(s) | What it does | Activates when you say... |
|---|---|---|---|
| **commit** | dev-orchestrator | Conventional commit with branch safety gate, secret scan, doc reference check, specific file staging. | "commit these changes" |
| **push** | dev-orchestrator | Push with branch safety gate, auto `-u` on first push, merge request reminder. | "push to remote" |

### Understanding code

| Skill | Agent(s) | What it does | Activates when you say... |
|---|---|---|---|
| **explain-code** | dev-orchestrator | Structured explanation: summary → analogy → diagram → walkthrough → gotcha. | "explain how this works" |

### Implementation quality (subagent-only)

| Skill | Agent(s) | What it does | Activates when you say... |
|---|---|---|---|
| **test-driven-development** | dev-python, dev-typescript, dev-refactor | Enforces RED-GREEN-REFACTOR. Blocks code written before tests. | "implement with tests" |
| **systematic-debugging** | dev-python, dev-shell | 4 phases: investigation → pattern analysis → hypothesis → implementation. Blocks guessing. | "debug this", "why is this failing" |
| **verification-before-completion** | dev-python, dev-shell, dev-reviewer, dev-refactor | Gate before success claims: identify → run → read → verify → claim. | "verify everything works" |
| **receiving-code-review** | dev-python, dev-shell, dev-refactor | Processes review feedback with technical rigor. Push back when suggestions are wrong. | "here's feedback on my code" |
| **python-audit** | dev-python, dev-reviewer | Runs ruff, mypy, pytest. Reports quality metrics. | "audit code", "python audit" |
| **typescript-audit** | dev-reviewer | Runs ESLint, tsc --noEmit, Vitest. Reports TypeScript quality metrics. | "typescript audit", "audit TypeScript" |

## Skill assignment matrix

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

**Totals:** dev-orchestrator: 12, dev-docs: 1, dev-python: 5, dev-shell: 3, dev-typescript: 4, dev-frontend: 2, dev-reviewer: 3, dev-refactor: 3, dev-kiro-config: 1

**base agent** loads 14 of the 18 global skills — all orchestrator skills except dispatching-parallel-agents, execution-planning, subagent-driven-development, and post-implementation, plus the subagent-only skills. See `agents/base.json` for the full list.

## Automated workflows

### Implementation pipeline

After any subagent returns DONE, `post-implementation` fires automatically:

```
subagent DONE
    → quality gate (project-type detection: pyproject.toml / package.json / shellcheck)
    → doc staleness check (flags docs referencing modified files)
    → auto-review (dispatches dev-reviewer without user intervention)
    → improvement capture (friction written to docs/improvements/pending.md)
```

### Refactor pipeline

```
codebase-audit (structured findings)
    → dev-reviewer (validates findings)
    → user approval
    → dev-refactor (execute-findings mode)
    → dev-reviewer (post-refactor verification)
```

## Project-local skills

These skills live in `.kiro/skills/` (not `~/.kiro/skills/`) and only activate in the kiro-config repo.

| Skill | What it does | Activates when you say... |
|---|---|---|
| **create-pr** | Creates a GitHub pull request from the current feature branch. | "create pr", "open pr", "merge request" |
| **ship** | Creates a versioned release with tag, push, and GitHub release. | "ship", "release", "tag and release" |

## Design philosophy

Each skill addresses a specific failure mode:

| Failure mode | Skill that prevents it |
|---|---|
| Building the wrong thing | design-and-spec |
| Vague plans that can't be executed | writing-plans |
| No execution plan for multi-agent work | execution-planning |
| Context pollution in long sessions | subagent-driven-development |
| Sequential work on independent tasks | dispatching-parallel-agents |
| No quality gate after implementation | post-implementation |
| Stale config and drifting practices | agent-audit |
| Codebase health invisible until crisis | codebase-audit |
| Committing to main, leaking secrets | commit |
| Force-pushing, forgetting merge requests | push |
| Jargon-heavy explanations | explain-code |
| Code before tests | test-driven-development |
| Guessing at bugs instead of investigating | systematic-debugging |
| "It should work" without evidence | verification-before-completion |
| Blindly accepting bad review feedback | receiving-code-review |
