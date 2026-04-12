<!-- Author: Rommel Porras -->

# Skill Catalog

[Back to README](../../README.md) | Related: [Creating agents](creating-agents.md) | [Security model](security-model.md)

Quick reference for all 20 skills — what they do, when they activate, and which agents load them.

## Workflow chain

The design-to-implementation flow chains skills through the orchestrator:

```
spec-workflow → writing-plans → subagent-driven-development
     ↓                              ↓
  writes spec              dispatches delegates via
  to docs/specs/           delegation-protocol, aggregates
                           results via aggregation
```

Each skill activates independently by description matching. The chain is optional.

## Skills by category

### Orchestrator — planning and coordination

| Skill | Agent(s) | What it does | Activates when you say... |
|---|---|---|---|
| **spec-workflow** | dev-orchestrator | Structured spec process: requirements → design → tasks → execution. Saves to `docs/specs/`. | "spec out", "define requirements", "write a spec" |
| **brainstorming** | dev-orchestrator | Explores intent before implementation. Proposes 2-3 approaches with trade-offs. Hard gate: no code until design is approved. | "let's design", "brainstorm" |
| **writing-plans** | dev-orchestrator | Decomposes a spec into bite-sized tasks. Each task is one action with exact file paths. | "plan how to implement this" |
| **delegation-protocol** | dev-orchestrator | Structures subagent briefings: objective, context, constraints, definition of done, skill triggers. | (internal — triggers when orchestrator delegates) |
| **aggregation** | dev-orchestrator | Presents subagent results: status, summary, concerns, next steps. | (internal — triggers when subagent returns) |
| **subagent-driven-development** | dev-orchestrator | Executes a plan by dispatching one delegate per task with two-stage review. | "implement the plan using delegates" |
| **dispatching-parallel-agents** | dev-orchestrator | Dispatches multiple delegates concurrently for independent tasks. | "run these tasks in parallel" |
| **agent-audit** | dev-orchestrator | Audits agents, prompts, skills, and knowledge for gaps and inconsistencies. Proposes changes. | "agent-audit", "audit agents", "review config" |
| **research-practices** | dev-orchestrator | Researches best practices for a topic via web search and Context7. Proposes config updates. | "research practices", "best practices for" |
| **critical-thinking** | dev-orchestrator | Socratic questioning mode. Challenges assumptions one question at a time. No solutions, no code. | "challenge this", "poke holes", "what am I missing", "think critically" |
| **trace-code** | dev-orchestrator | Deep code flow tracing from entry point to output with file:line references. | "trace this", "map the code flow", "what files are involved in" |
| **codebase-audit** | dev-orchestrator | Periodic health check: git churn, complexity, coverage, deps, TODOs. | "health check", "technical debt", "codebase audit" |

### Git operations

| Skill | Agent(s) | What it does | Activates when you say... |
|---|---|---|---|
| **commit** | dev-orchestrator | Conventional commit with branch safety gate, secret scan, specific file staging. | "commit these changes" |
| **push** | dev-orchestrator | Push with branch safety gate, auto `-u` on first push, merge request reminder. | "push to remote" |

### Understanding code

| Skill | Agent(s) | What it does | Activates when you say... |
|---|---|---|---|
| **explain-code** | dev-orchestrator | Structured explanation: summary → analogy → diagram → walkthrough → gotcha. | "explain how this works" |

### Implementation quality

| Skill | Agent(s) | What it does | Activates when you say... |
|---|---|---|---|
| **test-driven-development** | dev-python | Enforces RED-GREEN-REFACTOR. Blocks code written before tests. | "implement with tests" |
| **systematic-debugging** | dev-python, dev-shell | 4 phases: investigation → pattern analysis → hypothesis → implementation. Blocks guessing. | "debug this", "why is this failing" |
| **verification-before-completion** | dev-python, dev-shell, dev-reviewer, dev-refactor | Gate before success claims: identify → run → read → verify → claim. | "verify everything works" |
| **receiving-code-review** | dev-python, dev-shell, dev-refactor | Processes review feedback with technical rigor. Push back when suggestions are wrong. | "here's feedback on my code" |
| **python-audit** | dev-python, dev-reviewer | Runs ruff, mypy, pytest. Reports quality metrics. | "audit code", "python audit" |

## Skill assignment matrix

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

**Totals:** dev-orchestrator: 15, dev-python: 5, dev-shell: 3, dev-reviewer: 2, dev-refactor: 2, base: 16

**base agent** loads 16 of the 20 skills - everything except the 4 orchestrator-only delegation skills (delegation-protocol, aggregation, subagent-driven-development, dispatching-parallel-agents).

## Design philosophy

Each skill addresses a specific failure mode:

| Failure mode | Skill that prevents it |
|---|---|
| Building the wrong thing | brainstorming, spec-workflow |
| Vague plans that can't be executed | writing-plans |
| Vague delegation that produces vague results | delegation-protocol |
| Code before tests | test-driven-development |
| Guessing at bugs instead of investigating | systematic-debugging |
| "It should work" without evidence | verification-before-completion |
| Blindly accepting bad review feedback | receiving-code-review |
| Context pollution in long sessions | subagent-driven-development |
| Sequential work on independent tasks | dispatching-parallel-agents |
| Committing to main, leaking secrets | commit |
| Force-pushing, forgetting merge requests | push |
| Jargon-heavy explanations | explain-code |
| Unclear subagent results | aggregation |
| Stale config and drifting practices | agent-audit |
| Outdated patterns, missing best practices | research-practices |
