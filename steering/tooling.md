# Tooling

## Package Management
- **Python:** use `uv`, never `pip3` or `pip`. Run `uv lock` after dependency
  changes and commit `uv.lock`.
- **Node.js:** use `npm`. Commit `package-lock.json`.

## Python Quality
- **Linting:** `ruff check` and `ruff format` — configured in pyproject.toml.
- **Type checking:** `mypy` with `disallow_untyped_defs = true`. Use `boto3-stubs` for AWS types.
- **Testing:** `pytest` with `pytest-cov`. Run `uv run pytest tests/ -q` to verify.
- **Coverage:** don't let it drop. Add tests for new code.
- **All public functions** must have type annotations and docstrings.

## Shell Quality
- **Linting:** `shellcheck` on all `.sh` files. Zero warnings.
- **Formatting:** consistent 2-space indent, `shfmt` if available.
- **Header:** every script starts with `#!/usr/bin/env bash` and `set -euo pipefail`.
- **Quoting:** always quote variable expansions: `"${var}"` not `$var`.
- **Conditionals:** use `[[ ]]` over `[ ]`.

## Infrastructure Code
- **Terraform:** `terraform fmt` and `terraform validate` before committing.
  Never commit `.tfstate` files — use remote state with S3 + DynamoDB locking.
- **Docker:** use multi-stage builds. Pin base image versions. No `latest` tags.
- **Helm:** `helm lint` and `helm template` to validate before committing.

## Documentation
- Check Context7 (MCP) before WebFetch for library docs.
- Prefer official docs over blog posts or Stack Overflow.

## Commits
- Use conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `infra:`).
- Subject line max 72 chars, lowercase after type colon, no trailing period.

## JSON Files
- Never use `sed` or `awk` to manipulate JSON. Use `jq` for shell, or
  `json` module in Python.
