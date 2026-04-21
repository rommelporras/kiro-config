<!-- Author: Rommel Porras -->

# Skill Catalog

[Back to README](../../README.md) | Related: [Creating agents](creating-agents.md) | [Security model](security-model.md) | [Audit playbook](audit-playbook.md)

Quick reference for all 20 skills — what they do, when they activate, and which agents load them.
12 skills load on devops-orchestrator; 8 are subagent-only.

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
| **design-and-spec** | devops-orchestrator | Merged brainstorming + spec-workflow + critical-thinking. Two entry modes: exploratory ("brainstorm") and directed ("spec out"). Challenges assumptions, proposes 2-3 approaches, writes spec to `docs/specs/`. Hard gate: no code until design is approved. | "brainstorm", "spec out", "let's design", "define requirements" |
| **writing-plans** | devops-orchestrator | Decomposes a spec into bite-sized tasks. Each task is one action with exact file paths. | "plan how to implement this" |
| **execution-planning** | devops-orchestrator | Generates parallel execution plans from spec phases with agent routing, dependency tracking, and review gates. | "plan execution", "generate execution plan" |
| **subagent-driven-development** | devops-orchestrator | Executes a plan by dispatching one delegate per task with two-stage review. Updates plan checkboxes after each task. | "implement the plan using delegates" |
| **dispatching-parallel-agents** | devops-orchestrator | Dispatches multiple delegates concurrently for independent tasks. | "run these tasks in parallel" |
| **post-implementation** | devops-orchestrator | Automatic quality gate after subagent returns DONE: runs project-type-aware quality suite, checks doc staleness, dispatches devops-reviewer, captures friction to `docs/improvements/pending.md`. | (internal — fires automatically after subagent DONE) |
| **agent-audit** | devops-orchestrator | Audits agents, prompts, skills, and knowledge for gaps and inconsistencies. Reads `docs/improvements/pending.md`. Proposes changes. | "agent-audit", "audit agents", "review config" |
| **trace-code** | devops-orchestrator | Deep code flow tracing from entry point to output with file:line references. | "trace this", "map the code flow", "what files are involved in" |
| **codebase-audit** | devops-orchestrator | Periodic health check: git churn, complexity, coverage, deps, TODOs. Structured findings with severity/effort/agent. | "health check", "technical debt", "codebase audit" |
| **doc-drift** | devops-orchestrator | Detects documentation drift after structural changes. Dispatches 3 parallel specialists (structural/tabular, prose/content, metadata/numeric) to audit docs against tracked categories (agents, skills, hooks, steering). Auto-triggers from post-implementation when tracked-category files change; also on-demand. | "audit my docs", "check doc drift", "docs out of date" |

### Git operations

| Skill | Agent(s) | What it does | Activates when you say... |
|---|---|---|---|
| **commit** | devops-orchestrator | Conventional commit with branch safety gate, secret scan, doc reference check, specific file staging. | "commit these changes" |
| **push** | devops-orchestrator | Push with branch safety gate, auto `-u` on first push, merge request reminder. | "push to remote" |

### Understanding code

| Skill | Agent(s) | What it does | Activates when you say... |
|---|---|---|---|
| **explain-code** | devops-orchestrator | Structured explanation: summary → analogy → diagram → walkthrough → gotcha. | "explain how this works" |

### Infrastructure analysis (subagent-only)

| Skill | Agent(s) | What it does | Activates when you say... |
|---|---|---|---|
| **terraform-audit** | devops-terraform | Diagnoses Terraform errors: parses error, traces variable chains, checks git history, compares state, reports root cause + suggested fix. | "diagnose terraform", "why did plan fail", "trace terraform issue", "what broke" |

### Implementation quality (subagent-only)

| Skill | Agent(s) | What it does | Activates when you say... |
|---|---|---|---|
| **test-driven-development** | devops-python, devops-shell, devops-typescript, devops-frontend, devops-refactor | Enforces RED-GREEN-REFACTOR. Blocks code written before tests. | "implement with tests" |
| **systematic-debugging** | devops-python, devops-shell, devops-typescript, devops-refactor, devops-terraform | 4 phases: investigation → pattern analysis → hypothesis → implementation. Blocks guessing. | "debug this", "why is this failing" |
| **verification-before-completion** | devops-python, devops-shell, devops-reviewer, devops-refactor | Gate before success claims: identify → run → read → verify → claim. | "verify everything works" |
| **receiving-code-review** | devops-python, devops-shell, devops-refactor | Processes review feedback with technical rigor. Push back when suggestions are wrong. | "here's feedback on my code" |
| **python-audit** | devops-python, devops-reviewer | Runs ruff, mypy, pytest. Reports quality metrics. | "audit code", "python audit" |
| **typescript-audit** | devops-reviewer | Runs ESLint, tsc --noEmit, Vitest. Reports TypeScript quality metrics. | "typescript audit", "audit TypeScript" |

## Skill assignment matrix

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
| test-driven-development | | | ✓ | ✓ | ✓ | ✓ | | ✓ | | |
| systematic-debugging | | | ✓ | ✓ | ✓ | | | ✓ | ✓ | |
| verification-before-completion | | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| receiving-code-review | | | ✓ | ✓ | ✓ | ✓ | | ✓ | | |
| python-audit | | | ✓ | | | | ✓ | | | |
| typescript-audit | | | | | | | ✓ | | | |
| terraform-audit | | | | | | | | | ✓ | |
| doc-drift | ✓ | | | | | | | | | |

**Totals:** devops-orchestrator: 13, devops-docs: 1, devops-python: 5, devops-shell: 4, devops-typescript: 4, devops-frontend: 3, devops-reviewer: 3, devops-refactor: 4, devops-terraform: 5, devops-kiro-config: 1

**base agent** loads 14 of the 20 global skills — all orchestrator skills except dispatching-parallel-agents, execution-planning, subagent-driven-development, and post-implementation, plus the subagent-only skills. See `agents/base.json` for the full list.

## Automated workflows

### Implementation pipeline

After any subagent returns DONE, `post-implementation` fires automatically:

```
subagent DONE
    → quality gate (project-type detection: pyproject.toml / package.json / shellcheck)
    → doc staleness check (flags docs referencing modified files)
    → auto-review (dispatches devops-reviewer without user intervention)
    → improvement capture (friction written to docs/improvements/pending.md)
```

### Refactor pipeline

```
codebase-audit (structured findings)
    → devops-reviewer (validates findings)
    → user approval
    → devops-refactor (execute-findings mode)
    → devops-reviewer (post-refactor verification)
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
| Terraform errors diagnosed by guessing | terraform-audit |
| Documentation drifting after structural changes | doc-drift |
