---
name: terraform-audit
description: Terraform-specific diagnostic workflow. Use when the user pastes a terraform error, plan failure, missing variable, or state drift issue. Triggers on "diagnose terraform", "why did plan fail", "trace terraform issue", "what broke in terraform", "missing variable".
---

# Terraform Audit

Diagnose Terraform errors by tracing through code, state, and git history.

**Announce at start:** "Diagnosing: [error summary]."

## Preflight

Before any terraform commands, verify the preflight gate is satisfied.
If not, ask the user to complete the preflight checklist and wait.

## Process

1. **Parse** — extract error type, affected resource/variable/module from the error message
2. **Locate** — find relevant `.tf` files; resolve symlinks with `readlink -f`
3. **Trace** — follow variable dependency chain:
   `terraform.tfvars` → `variables.tf` → `locals {}` → module input → resource attribute
4. **History** — `git log --oneline -20 -- <affected files>` and `git diff HEAD~1 -- <file>`
5. **Cross-stack** — check `importvars.tf` / `terraform_remote_state` data sources for upstream breakage
6. **State** — if credentials available, compare declared config vs actual AWS state via `use_aws` read-only calls
7. **Report** — present findings in structured format below

## Output Format

### Error
Original error message, verbatim.

### Root Cause
One-paragraph explanation of why this happened.

### Affected Files
- `path/to/file.tf:42` — what's wrong at this line
- `path/to/variables.tf:15` — where the variable is defined (or missing)

### Git History
- `abc1234 (2026-04-15)` — commit that introduced the change, with `git blame` output

### Cross-Stack Dependencies
- Remote state `eam_farm` from `importvars.tf:25` — status of upstream stack

### Suggested Fix
Concrete steps to resolve. Never apply — describe what the user should change and where.

## Guidelines

- Always resolve symlinks before analyzing — the actual source may be elsewhere
- Check workspace selection before diagnosing workspace-specific issues
- For "missing variable" errors: (1) defined in variables.tf? (2) set in .tfvars? (3) recently added in module but not propagated?
- Use `terraform fmt --check` early — formatting issues mask real problems
