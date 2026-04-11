---
name: aggregation
description: Use when a subagent returns results and you need to present them to the user. Structures the summary for clarity. Triggers internally after delegation completes.
---

# Aggregation

Present subagent results clearly and suggest next steps.

## Single Task Completion

When a subagent returns from a single task:

1. **Status:** DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED
2. **Summary:** What was created or modified (file paths, not descriptions)
3. **Concerns:** Surface anything the subagent flagged
4. **Next step suggestion:**
   - If DONE on implementation of 3+ files or a new script:
     "Want me to send this to code-reviewer?"
   - If DONE_WITH_CONCERNS: address the concerns first
   - If NEEDS_CONTEXT: relay the questions to the user
   - If BLOCKED: discuss the blocker with the user

Do NOT repeat the subagent's full output verbatim. Summarize and reference
file paths.

## Multi-Task Progress

When executing a spec task list:

After each task: "Task {n}/{total} complete — {one-line summary}"

If a task fails: STOP. Report the failure. Discuss with the user before
continuing to the next task.

After all tasks:
- List all files created/modified
- List any open concerns
- Suggest final code review if not done per-task

## Review Results

When code-reviewer returns:

- State the verdict: APPROVE / REQUEST_CHANGES / NEEDS_DISCUSSION
- List CRITICAL findings first (if any)
- Summarize IMPORTANT findings
- Mention SUGGESTION count without detail unless user asks
- If REQUEST_CHANGES: ask user if they want to delegate fixes to the
  appropriate coding subagent
