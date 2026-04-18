---
name: post-implementation
description: Automated post-implementation workflow. Triggers when the orchestrator receives DONE from an implementation subagent. Runs quality gate, doc staleness check, auto-review, and improvement capture.
---

## Trigger

Fires automatically after any implementation subagent (devops-python, devops-typescript, devops-shell, devops-refactor, devops-kiro-config, devops-frontend) returns DONE or DONE_WITH_CONCERNS. Do not skip. Do not ask the user.

## Step 1: Update tracking documents

- Plan file: `- [ ]` → `- [x]` for completed tasks
- If task diverged from plan, append `Actual:` note to the task entry
- If task description was enriched before dispatch, update plan with enriched version

## Step 2: Quality gate

Detect project type from config files:

| Config found | Commands to run |
|---|---|
| `pyproject.toml` | `uv run ruff check .` · `uv run ruff format --check .` · `uv run mypy .` · `uv run pytest tests/ -q` |
| `package.json` | `npm run lint` · `npm run typecheck` · `npm test` |
| `*.sh` files changed | `shellcheck` on each changed `.sh` file |
| Mixed (both) | Run all applicable |
| None found | Skip — warn user: "No pyproject.toml or package.json found — skipping automated quality checks." |

If failures → send back to implementer with full command output (not just "tests failed"). Max 3 retries. If still failing after 3 attempts, stop and surface to user: "Implementer couldn't resolve this after 3 attempts. Manual intervention needed."

## Step 3: Doc staleness check

- For each file modified by the implementer, `grep docs/` for references to that file
- If any doc references a modified file → flag it
- If staleness found → dispatch devops-docs to update, or flag for user
- **Metrics staleness:** After the quality gate, grep `docs/` and `README.md`
  for test counts and coverage percentages. If they don't match the current
  numbers from the test run, flag them for update. Common patterns:
  `\d+ tests`, `\d+%\s*coverage`, `\d+ passed`.

## Step 4: Auto-review

Dispatch devops-reviewer with:
- Files created/modified
- What the implementation does
- Implementer's concerns (if any)

Wait for verdict.

## Step 5: Handle review findings

| Verdict | Action |
|---|---|
| CRITICAL | Send back to implementer with fix list. Loop max 3 attempts — if still unresolved, surface to user: "Implementer couldn't resolve this after 3 attempts. Manual intervention needed." |
| IMPORTANT | Present to user, ask if they want fixes applied |
| SUGGESTIONS | Include in summary |
| APPROVE | Proceed |

## Step 6: Improvement capture

Check for friction during this session:
- Retries > 1? Log cause
- Routing corrected? Log mismatch
- Context missing? Log what was needed

Append to `~/.kiro/docs/improvements/pending.md`:

```
## YYYY-MM-DD — session in <project path>

### <Category>: <short title>
- What happened: <description>
- Root cause: <steering gap | routing issue | missing skill | missing context>
- Suggested fix: <specific action>
```

If file is inaccessible, log to conversation instead — do not fail silently.

## Step 7: Spec completion check

If this task completes the final phase of a spec:

1. Check if all plan checkboxes are `[x]`
2. Add `Status: COMPLETE (date)` to the spec header with final metrics
3. Update `docs/TODO.md` to mark the spec section done
4. Dispatch these as a parallel task alongside the review — don't wait
   for the user to ask

## Step 8: Present results

- Summary of changes (files modified, key decisions)
- Review verdict and findings
- Doc staleness warnings (if any)
- Concerns from implementer or reviewer
- Next steps
