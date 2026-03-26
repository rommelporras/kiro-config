<!-- Author: Rommel Porras -->

# Skill Catalog

[Back to README](../../README.md) | Related: [Creating agents](creating-agents.md) | [Security model](security-model.md)

Quick reference for all 11 global skills — what they do, when they activate, and how they connect.

## Workflow chain

Most skills are standalone, but the design-to-implementation flow chains them:

```
brainstorming → writing-plans → subagent-driven-development
     ↓                              ↓
  writes spec              dispatches delegates
  to docs/specs/           per task with two-stage
                           review (spec + quality)
```

You don't have to follow the chain. Each skill activates independently by description matching.

## Skills by category

### Git operations

| Skill | What it does | Activates when you say... |
|---|---|---|
| **commit** | Conventional commit with branch safety gate (blocks main/master), secret scan, specific file staging. Never adds AI attribution. | "commit these changes", "commit" |
| **push** | Push with branch safety gate (blocks main/master), auto `-u` on first push, merge request reminder. | "push to remote", "push" |

### Understanding code

| Skill | What it does | Activates when you say... |
|---|---|---|
| **explain-code** | Structured explanation: one-sentence summary → analogy → ASCII diagram → line-by-line walkthrough → common gotcha. | "explain how this works", "walk me through this" |

### Design and planning

| Skill | What it does | Activates when you say... |
|---|---|---|
| **brainstorming** | Explores intent before implementation. Asks one question at a time, proposes 2-3 approaches with trade-offs, writes spec to `docs/specs/`, runs spec-reviewer delegate loop (max 3 iterations). Hard gate: no code until design is approved. | "let's design a new feature", "brainstorm" |
| **writing-plans** | Decomposes a spec into bite-sized tasks (2-5 min each). Maps file structure, writes plan to `docs/plans/`, runs plan-reviewer delegate loop. Each task is one action with exact file paths and expected output. | "plan how to implement this", "write an implementation plan" |

### Implementation

| Skill | What it does | Activates when you say... |
|---|---|---|
| **test-driven-development** | Enforces RED-GREEN-REFACTOR. Write failing test → watch it fail → write minimal code → verify green. Blocks code written before tests ("delete it, start over"). No mocks unless unavoidable. | "implement this with tests", "use TDD" |
| **subagent-driven-development** | Executes a plan by dispatching one delegate per task. Two-stage review after each: spec compliance first, then code quality. Model selection guidance (cheap for mechanical, capable for design). | "implement the plan using delegates", "delegate-driven development" |
| **dispatching-parallel-agents** | Dispatches multiple delegates concurrently for independent tasks. One delegate per problem domain, isolated context, results aggregated and checked for conflicts. | "run these tasks in parallel", "dispatch parallel agents" |

### Quality gates

| Skill | What it does | Activates when you say... |
|---|---|---|
| **systematic-debugging** | 4 mandatory phases: root cause investigation → pattern analysis → hypothesis testing → implementation. Blocks guessing. "3 attempts then STOP — it's architectural." | "I have a bug", "debug this", "why is this failing" |
| **verification-before-completion** | Gate function before any success claim: IDENTIFY what proves it → RUN the command → READ full output → VERIFY it confirms the claim → ONLY THEN claim success. Blocks "should work" without evidence. | "verify everything works", "make sure it's working" |
| **receiving-code-review** | Processes review feedback with technical rigor. Verify before implementing. Blocks performative agreement ("You're absolutely right!"). Push back when suggestions are wrong. YAGNI check on "implement properly" suggestions. | "here's feedback on my code", "process this code review" |

## Design philosophy

**Why these 11?** Each skill addresses a specific failure mode:

| Failure mode | Skill that prevents it |
|---|---|
| Building the wrong thing | brainstorming |
| Vague plans that can't be executed | writing-plans |
| Code before tests | test-driven-development |
| Guessing at bugs instead of investigating | systematic-debugging |
| "It should work" without evidence | verification-before-completion |
| Blindly accepting bad review feedback | receiving-code-review |
| Context pollution in long sessions | subagent-driven-development |
| Sequential work on independent tasks | dispatching-parallel-agents |
| Committing to main, leaking secrets | commit |
| Force-pushing, forgetting merge requests | push |
| Jargon-heavy explanations | explain-code |

**What's NOT here** (intentionally):
- **executing-plans** — removed; subagent-driven-development supersedes it
- **requesting-code-review** — removed; already embedded in subagent-driven-development
- **finishing-a-development-branch** — deferred to project-specific config
