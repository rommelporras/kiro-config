# Tooling

## Package Management
- **Python projects with external dependencies:** use `uv`, never `pip3` or `pip`.
- **Lock files:** always run `uv lock` after dependency changes and commit `uv.lock`.

## Python Quality
- **Linting:** `ruff check` and `ruff format` — configured in pyproject.toml.
- **Type checking:** `mypy` with `disallow_untyped_defs = true`. Use `boto3-stubs` for AWS types.
- **Testing:** `pytest` with `pytest-cov`. Run `uv run pytest tests/ -q` to verify.
- **Coverage:** don't let it drop. Add tests for new code.
- **All public functions** must have type annotations and docstrings.

## Documentation
- Check Context7 (MCP) before WebFetch for library docs.

## Commits
- Use conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `infra:`).
