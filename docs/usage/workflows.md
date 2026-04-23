# Workflows

[Back to README](../../README.md) | [How It Works](how-it-works.md) | [Tips](tips.md) | [Commands](commands.md)

A cookbook of real prompts for common tasks. Copy-paste and adapt.

---

## 1. Build a new feature (full lifecycle)

The signature workflow — from idea to committed code. You can enter at any step.

**Step 1: Brainstorm**

> Let's brainstorm a CLI tool that checks cloud costs across accounts.

The orchestrator explores your idea, challenges assumptions, and proposes 2-3 approaches. No code is written until you approve a design.

**Step 2: Write the spec**

> Spec this out.

Produces a formal spec in `docs/specs/<name>/spec.md`. Review and approve before continuing.

**Step 3: Create the implementation plan**

> Write a plan for this spec.

Breaks the spec into tasks with file assignments and test strategies.

**Step 4: Generate the execution plan**

> Plan execution for phase 1.

Maps tasks to agents, identifies what can run in parallel, adds review gates.

**Step 5: Execute**

> Execute the plan.

Dispatches specialists, tracks progress, runs post-implementation checks (lint, tests, code review), and presents results.

**Step 6: Commit**

> Commit these changes.

Runs branch safety check, secret scan, doc consistency check, then commits with conventional commit format.

- You can skip steps — have a spec already? Start at step 3. Know exactly what you want? Go straight to "write a Python script that does X."
- The orchestrator won't write code until a design is approved in the brainstorm phase.

---

## 2. Fix a bug

> The retry command fails when no services are running. Here's the error: [paste error]

- The systematic-debugging skill activates automatically — reproduces the bug, investigates root cause, writes a regression test, then fixes it.
- Paste the actual error message; the orchestrator routes better with the full stack trace.
- A regression test is written before the fix, not after.

---

## 3. Review code

> Review scripts/monitoring/ for issues.

- Routes to a read-only reviewer agent. No files are modified.
- Findings are returned as **CRITICAL** (must fix), **IMPORTANT** (should fix), and **SUGGESTIONS** (ask to see them).
- You can scope the review: "Review only the error handling in scripts/monitoring/collector.py."

**Next steps:** After review, say "fix the CRITICAL issues" to dispatch a specialist for the flagged items.

---

## 4. Refactor

> Refactor this codebase — find DRY violations and simplify.

- Triggers the full refactor pipeline: audit → review → you approve findings → refactor → final review.
- You see findings ranked by severity and choose which to fix before any code changes.
- The final review confirms behavior is preserved.

**Next steps:** After the audit presents findings, say "fix items 1, 2, and 4" to scope the refactor.

---

## 5. Understand code

**Trace (file-level map):**

> Trace how the retry command works end-to-end.

- The trace-code skill maps every file involved with `file:line` references and data flow.
- Useful when you're new to a codebase or debugging a complex interaction.

**Explain (conceptual):**

> Explain how the data processing pipeline works.

- The explain-code skill uses analogies and diagrams to make it click.
- Good for onboarding or writing documentation.

---

## 6. Terraform troubleshooting

> Terraform plan failed with this error: [paste error]
> Check the files in infra/modules/networking/

- Routes to a read-only Terraform analyst. No infrastructure is modified.
- Traces variables through the full chain: `terraform.tfvars` → `variables.tf` → `locals` → module → resource.
- Checks recent git changes and identifies root cause.

**Next steps:** After diagnosis, the analyst will suggest the fix. Apply it yourself or ask a specialist to update the `.tf` files.

---

## 7. Full-stack parallel

> Add a dashboard page with an API endpoint that returns monthly usage data.

- The orchestrator dispatches a backend specialist (API) and a frontend specialist (HTML/CSS/charts) in parallel — they work on independent file sets simultaneously.
- Results are consolidated before presenting to you.
- Useful when backend and frontend work don't share files.

---

## 8. Health check

> Run a health check on this codebase.

- The codebase-audit skill scans for: high-churn files, complexity hotspots, test coverage gaps, outdated dependencies, TODO/FIXME inventory, and doc health.
- Returns a structured report — never auto-fixes.
- Run this before a refactor or when onboarding to an unfamiliar repo.

**Next steps:** After the report, say "fix the top 3 issues" or "refactor the high-complexity files" to act on findings.

---

## 9. Check documentation

> Check my docs for drift.

- The doc-drift skill compares documentation against the actual codebase state.
- Detects stale counts, broken links, and outdated references.
- Auto-fixes minor drift (counts, paths); flags structural issues for your review.

**Next steps:** Review flagged items and say "fix the stale references in docs/reference/" to apply remaining fixes.

---

## 10. Quick question

> /agent base

> How does Python's `functools.lru_cache` handle unhashable arguments?

> /agent devops-orchestrator

Or use `ctrl+o` to toggle back to the orchestrator.

- Switch to the `base` agent for quick questions that don't need orchestration.
- No delegation overhead — direct answer, no subagents.
- Switch back with `ctrl+o` or `/agent devops-orchestrator` when you're done.
