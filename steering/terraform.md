# Terraform

## Analysis Rules

- Always `terraform fmt --check` before analyzing — formatting issues mask real problems.
- Trace variables through full chain: `terraform.tfvars` → `variables.tf` → `locals` → module input → resource attribute.
- Check `importvars.tf` / remote state data sources for cross-stack dependencies.
- For "missing variable" errors: (1) defined in `variables.tf`? (2) set in `.tfvars` or workspace file? (3) recently added in module but not propagated?
- Use `git log --oneline -20 -- <file>` for recent changes.
- For workspace issues, verify selected workspace before diagnosing.
- Never run mutating Terraform commands — analysis only.
- Resolve symlinks before analyzing — the actual source may be in a different directory.
- `terraform workspace select` writes `.terraform/environment` — acceptable for analysis but is technically a local state change.
