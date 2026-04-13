---
name: execution-planning
description: Takes a spec phase and generates an execution plan with parallel stages, agent routing, review gates, and verification criteria. Use before dispatching implementation work. Triggers on "plan execution", "generate execution plan", "how should we execute this", or internally when the orchestrator is about to implement a spec phase.
---

# Execution Planning

Generate an execution plan from a spec phase. The plan decomposes work
into parallel stages with agent routing, dependencies, review gates,
and verification criteria.

**Announce at start:** "I'm using the execution-planning skill to create
the execution plan for this phase."

## When to Use

Before implementing any spec phase that involves 2+ subtasks or 2+ agents.
Skip for trivial single-agent tasks.

## Inputs

1. The spec file — check for `docs/specs/<name>/spec.md` first, fall
   back to `docs/specs/<name>.md` for specs created before the folder
   convention
2. The codebase state — understand what exists now
3. The routing table — know which agents handle what

## Process

### Step 1: Read the spec phase

Read the spec and extract:
- What must be produced (deliverables)
- What files are created/modified/deleted
- What verification is required

### Step 2: Decompose into subtasks

Break the phase into the smallest independent units of work.
Each subtask should:
- Have a single agent owner
- Touch a distinct set of files (no overlap with other subtasks)
- Be verifiable independently

Also scan for related metadata that may have drifted: test counts,
version numbers, coverage targets, tool names in prose. Include these
as additions to the most relevant task or as a separate "drift fixes" task.

### Step 3: Identify dependencies

For each subtask, determine:
- Can it start immediately? (no dependencies)
- Does it depend on another subtask's output?
- Does it share files with another subtask? (forces sequencing)

### Step 4: Assign agents

Route each subtask using the orchestrator's routing table:
- Code changes → dev-python, dev-shell, or dev-refactor
- Config/docs/markdown → dev-docs
- Review → dev-reviewer
- Research/web lookups → orchestrator (pre-gather for subagents)

### Step 5: Build the stage map

Group subtasks into stages:
- **Stage 1**: All subtasks with no dependencies (run in parallel)
- **Stage 2**: Subtasks that depend on Stage 1 outputs
- **Stage N**: Continue until all subtasks are placed
- **Review stage**: Always the last stage before commit

### Step 6: Define verification

For each subtask and for the phase overall:
- What command proves it worked?
- What grep/check proves no regressions?
- What the reviewer should focus on

## Output Format

Save to: `docs/specs/<spec-name>/execution/phase-N.plan.md`

Use whatever phase identifier the spec uses. If the spec says "Phase 2",
the file is `phase-2.plan.md`. If it says "Migration Step A", use
`migration-step-a.plan.md`. Match the spec, don't force numeric naming.

````markdown
# Phase N Execution Plan

> Generated from: `docs/specs/<spec-name>/spec.md` — Phase N
> Date: YYYY-MM-DD

## Goal

One sentence from the spec.

## Stage 1 (parallel)

### Task 1.1: [name]
- **Agent:** dev-python
- **Objective:** [one sentence]
- **Files:** create/modify/delete list
- **Briefing context:** [file paths the agent needs to read]
- **Constraints:** [what NOT to touch]
- **Done when:** [concrete criteria]
- **Skill triggers:** "implement with tests", "verify before completing"

### Task 1.2: [name]
- **Agent:** dev-docs
- **Objective:** [one sentence]
- **Files:** create/modify list
- **Briefing context:** [file paths]
- **Constraints:** [scope limits]
- **Done when:** [concrete criteria]

## Stage 2 (after Stage 1)

### Task 2.1: [name]
- **Agent:** dev-reviewer
- **Depends on:** Task 1.1, Task 1.2
- **Objective:** Review all changes from Stage 1
- **Files to review:** [list from Stage 1]
- **Focus areas:** [what matters most]
- **Done when:** approved or issues listed

## Verification

- [ ] [test command and expected result]
- [ ] [grep check for stale references]
- [ ] [any other concrete check]

## Commit

After all stages pass verification:
- **Type:** feat/refactor/fix
- **Scope:** [what changed]
````

## Plan Quality Requirements

A good execution plan is self-contained — a new session reads only the plan,
not the spec. Every task must be mechanical — subagents execute, they don't
design.

For each task, include:

1. **Current state snapshot** — exact file content or line numbers being
   changed. Don't say "update references" — show the exact before/after
   strings.
2. **Before → after for every change** — literal string replacements so
   the subagent can do mechanical find-and-replace without re-reading files.
3. **Per-task verification** — a specific grep, diff, or command that proves
   this individual task is correct. Don't rely only on the global check.
4. **Dependency proof** — if tasks are marked parallel, explain WHY they're
   independent (no shared files, no output dependencies).

The test: could a subagent execute this task with ZERO judgment calls?
If not, the plan needs more detail.

## Rules

- Every plan must have at least one review stage
- Subtasks in the same stage must not share files
- The orchestrator handles git operations — never assign commit to a subagent
- If a subtask needs web_search, use_aws, grep, or glob, mark it as
  "orchestrator pre-work" — the orchestrator gathers that data before
  dispatching the subagent
- Keep subtasks focused — if a subtask touches more than 10 files,
  consider splitting it
- Include the briefing context (file paths) so the orchestrator can
  construct the delegation without re-reading the spec

## Proportionality

Match plan detail to task complexity. Not every phase needs 500 lines.

- **Bulk find-and-replace** (rename paths, update references): a replacement
  table + file list is sufficient. Don't enumerate every individual instance.
  Example: "Replace `eam-ecs-bounce` with `eam ecs bounce` in these 7 files"
  — not 50 lines of before/after per file.
- **New feature implementation**: detailed specs with file structure, function
  signatures, test requirements, and acceptance criteria.
- **Mechanical file moves**: file list with source → destination. No per-file
  before/after strings needed.

Rule of thumb: if the execution plan is longer than the actual diff would be,
it's over-specified.

## Anti-patterns

- Planning a single-subtask phase (just dispatch directly)
- Putting dependent tasks in the same parallel stage
- Skipping the review stage
- Assigning orchestrator-only tools (grep, web_search) to subagents
- Making the plan so detailed it duplicates the spec
- DoD grep patterns that match filenames containing the old name
  (e.g., `docs/tools/eam-ecs-bounce.md` is a filename, not a stale ref).
  List expected false positives explicitly in the DoD.

## Related Skills

- **writing-plans** — Creates the implementation plan this skill decomposes
  into parallel stages. writing-plans defines *what* tasks exist;
  execution-planning defines *how* to run them (parallelism, agents, gates).
- **subagent-driven-development** — Executes individual tasks with TDD and
  review loops. Use within a stage when tasks need test-driven implementation.
  execution-planning handles the stage-level orchestration above it.
- **delegation-protocol** — Template for individual subagent briefings.
  Each task in the execution plan becomes a delegation using this protocol.
- **dispatching-parallel-agents** — General-purpose parallel dispatch.
  execution-planning is the structured version that produces a plan file
  and integrates with the spec workflow.
