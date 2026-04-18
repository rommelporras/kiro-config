---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Save plans to:** `docs/specs/<feature-name>/plan.md`
- If the spec folder already exists (`docs/specs/<feature-name>/spec.md`), save alongside it
- If no spec folder exists, create one: `docs/specs/<feature-name>/plan.md`
- Standalone plans (no spec) can still be flat files in `docs/specs/`

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during design-and-spec. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** Use the subagent-driven-development skill to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Report completion**

Subagent reports DONE to orchestrator. Orchestrator handles staging and committing.
````

## Remember
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Non-Code Tasks

Not all work is TDD code. For file moves, path updates, config edits,
and documentation changes:
- Use exact before/after strings instead of TDD steps
- Provide the literal `oldStr` and `newStr` for each replacement
- Verification is grep-based (zero stale references) not test-based
- These tasks route to devops-docs, not devops-python

## Plan Review Loop

After writing the complete plan:

1. Dispatch devops-reviewer to review the plan against the spec — provide the path to the plan document and the spec document, not your session history
2. If issues found: fix the issues, re-dispatch reviewer for the whole plan
3. If approved: proceed to execution handoff

**Review loop guidance:**
- Same agent that wrote the plan fixes it (preserves context)
- If loop exceeds 3 iterations, surface to human for guidance
- Reviewers are advisory — explain disagreements if you believe feedback is incorrect

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/specs/<name>/plan.md`. Ready to execute?"**

**If yes:**
- First, use the execution-planning skill to generate a phase execution
  plan (`phase-N.plan.md`) with parallel stages, agent routing, and
  review gates
- Then dispatch according to the execution plan — parallel stages first,
  review stage last
- For tasks requiring TDD within a stage, use subagent-driven-development
- Fresh delegate per task + two-stage review (spec compliance, then code quality)
