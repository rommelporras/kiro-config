---
name: codebase-audit
description: Periodic codebase health check. Use when the user says "health check", "technical debt", "what needs attention", "codebase audit", "codebase health".
---

# Codebase Audit

Run a health check on the current repository and report findings.

**Announce at start:** "Running codebase audit on [repo name]."

## Checks (run in order)

### 1. Churn Analysis
```bash
git log --format=format: --name-only --since="90 days ago" | sort | uniq -c | sort -rn | head -20
```
Most-changed files = highest risk for bugs and complexity growth.

### 2. Complexity Hotspots
Run ruff or language-appropriate linter. Flag:
- Functions over 30 lines
- Cyclomatic complexity > 10
- Files over 300 lines

### 3. Test Coverage
```bash
uv run pytest tests/ -q --cov --cov-report=term-missing 2>/dev/null || echo "No pytest found"
```
Flag modules with < 70% coverage.

### 4. Dependency Health
```bash
uv pip list --outdated 2>/dev/null || pip list --outdated 2>/dev/null || echo "No pip found"
```
Flag packages > 2 major versions behind.

### 5. TODO/FIXME Inventory
```bash
grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.py" --include="*.sh" . | grep -v .venv | grep -v __pycache__
```
Count and list untracked debt markers.

## Report Format

## Codebase Audit — [repo] — YYYY-MM-DD

### Churn (top 10 most-changed files)
| File | Changes (90d) | Concern |

### Complexity Hotspots
| File:Line | Issue | Severity |

### Test Coverage
Overall: X% | Gaps: [list uncovered modules]

### Dependencies
| Package | Current | Latest | Behind |

### Debt Markers
TODO: X | FIXME: Y | HACK: Z

### Summary
2-3 sentence overall assessment with top 3 recommended actions.

## Guidelines

- Run commands, don't guess — show real numbers
- Severity: CRITICAL (fix now), IMPORTANT (next sprint), LOW (backlog)
- Present to user for review — never auto-fix
