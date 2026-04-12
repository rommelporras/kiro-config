---
name: python-audit
description: Use when reviewing Python code quality — run ruff, check types, verify tests, flag common issues. Trigger on "audit", "code quality", "lint", "check code".
---

# Python Audit

Quick quality check for Python projects. Run the automated tools, flag what they miss.

## Steps

### 1. Run automated checks

```bash
# Lint
uv run ruff check <package>/ tests/

# Format check
uv run ruff format --check <package>/ tests/

# Tests with coverage
uv run pytest tests/ -q

# Type check (if mypy configured)
uv run mypy <package>/

# Security scan
uv run bandit -r <package>/ -q
```

Fix any failures before proceeding. If ruff has auto-fixable issues, run `ruff check --fix`.

### 2. Manual review checklist

After automated tools pass, check these (tools can't catch them):

**Error handling:**
- [ ] No silent `except: pass` or `except Exception: pass` — every handler logs or re-raises
- [ ] Broad `except Exception:` has a justifying comment
- [ ] Custom exceptions defined centrally, inherit from proper base

**Design:**
- [ ] No functions over ~30 lines — suggest extraction
- [ ] No functions with 5+ parameters — suggest config objects
- [ ] No deep nesting (>3 levels) — suggest guard clauses
- [ ] No mutable default arguments (`def foo(items=[])`)

**Types:**
- [ ] All public functions have type annotations (params + return)
- [ ] Modern syntax: `X | Y`, `list[str]`, not `Union`, `List`
- [ ] No unparameterized generics (`deque` → `deque[str]`)

**Tests:**
- [ ] Every public module has a test file
- [ ] Coverage didn't drop from last commit
- [ ] No `print()` in tests — use assertions
- [ ] No `time.sleep()` for synchronization — use events/polling

**Concurrency:**
- [ ] `ThreadPoolExecutor` has explicit `max_workers` — never unbounded
- [ ] `threading.Event` checked in loops with `event.wait(timeout=)` — not busy-spinning
- [ ] `subprocess.run()` has `timeout=` parameter — no hanging on external commands
- [ ] No `subprocess` with `shell=True` — use args list for safety
- [ ] No bare `thread.start()` without join or executor context manager

**Security (beyond bandit):**
- [ ] No `eval()` or `exec()` on user input
- [ ] No `pickle.load()` on untrusted data
- [ ] No hardcoded credentials, tokens, or connection strings
- [ ] `subprocess` calls use args list, never `shell=True` with user input
- [ ] HTTP requests use `https://`, not `http://` for external APIs
- [ ] SQL queries use parameterized queries, never f-strings

### 3. Report

For each finding: file, line, what's wrong, suggested fix, priority (High/Medium/Low).

Group by: automated tool failures first, then manual findings.
