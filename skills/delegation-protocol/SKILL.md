---
name: delegation-protocol
description: Use when preparing to delegate a task to a subagent. Structures the briefing for maximum subagent effectiveness. Triggers internally when the orchestrator decides to dispatch work.
---

# Delegation Protocol

Structure every subagent briefing for clarity and completeness.
Vague delegation produces vague results.

## Briefing Template

Every delegation MUST include all five sections:

### 1. Objective
One sentence. What the subagent must produce.
Bad: "Fix the script"
Good: "Fix the pagination bug in scripts/ecs_metrics.py that causes
incomplete service listings when clusters have >100 services"

### 2. Context
Reference specific file paths. Do not describe files — point to them.
Include:
- Files to read for understanding
- Spec documents if they exist (`docs/specs/{feature}/`)
- Related files the subagent should be aware of but NOT modify

### 3. Constraints
- Language and version requirements
- Files that must NOT be modified
- Libraries allowed / not allowed
- Performance or security requirements

### 4. Definition of Done
Concrete, testable criteria.
Bad: "Make it work"
Good: "Script runs against a named cluster and outputs a formatted table
of CloudWatch metrics per service. Handles clusters where Container
Insights is not enabled by reporting a visibility gap."

### 5. Skill Triggers
Include phrases that activate the subagent's skills:
- "Implement with tests first" → activates test-driven-development
- "Verify everything works before completing" → activates verification
- "Debug systematically before fixing" → activates systematic-debugging
- "Review the code quality after implementing" → activates python-audit

Note: dev-docs has no TDD or linting skills. Do not include "implement
with tests" in dev-docs briefings — use "verify before completing" instead.

## Subagent Tool Limitations

Remember: subagents CANNOT use web_search, web_fetch, introspect, use_aws,
grep, or glob. If the task needs these, gather the information yourself
first and include it in the briefing context.

## Parallel Delegation

When dispatching multiple subagents in parallel:
- Confirm tasks are independent (no shared files)
- Include in each briefing: "This runs in parallel with other tasks.
  Do NOT modify files outside your scope."

## File Deletions

Subagents cannot delete files (shell deny lists block `rm`). Handle
file deletions yourself with `git rm` before or after dispatching.
If an execution plan includes file deletions, extract them into a
pre-dispatch or post-dispatch step for the orchestrator.

## Edge Cases (include for display/CLI work)

When delegating CLI or display work, always include these in the briefing:
- What does the output look like with zero items? (empty lists, no results)
- What does --help show? Is the full command name correct?
- What happens on Ctrl+C? Clean exit?
- What happens with invalid/expired AWS credentials?
- What does the output look like at narrow terminal widths?

## Anti-patterns

- Delegating without file paths (forces subagent to search)
- Batching unrelated work into one delegation
- Delegating conversation or planning tasks
- Forgetting skill trigger phrases in the briefing
- Delegating without checking if a spec exists for this feature
