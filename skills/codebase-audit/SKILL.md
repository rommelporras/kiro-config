---
name: codebase-audit
description: Periodic codebase health check. Use when the user says "health check", "technical debt", "what needs attention", "codebase audit", "codebase health".
---

# Codebase Audit

Run a health check on the current repository and report findings.

**Announce at start:** "Running codebase audit on [repo name]."

## Project-Type Detection

Before running any checks, detect the project type from config files:

- `pyproject.toml` present → Python project (run ruff, mypy, pytest, bandit)
- `package.json` present → TypeScript/Node project (run eslint, tsc, vitest)
- `*.sh` files present → Shell scripts (run shellcheck)
- Multiple indicators → run all applicable toolchains
- None found → skip automated quality gate, warn: "No pyproject.toml or package.json found — skipping automated quality checks."

## Scope Limits (large codebases)

- Scan to depth 3 only
- Prioritize files changed in the last 30 days (`git log --since="30 days ago" --name-only`)
- Cap findings at 20 — if more exist, note "N additional findings omitted"

## Checks (run in order)

### 1. Churn Analysis
```bash
git log --format=format: --name-only --since="90 days ago" | sort | uniq -c | sort -rn | head -20
```
Most-changed files = highest risk for bugs and complexity growth.

### 2. Complexity Hotspots
Run the appropriate linter for the detected project type. Flag:
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

### 6. Doc Health

Check documentation integrity:

- **Internal links:** For each `.md` file in `docs/`, verify that relative links resolve to existing files.
- **Spec implementation:** For each spec in `docs/specs/`, check that the files it describes actually exist in the codebase.
- **README counts:** Extract counts mentioned in `README.md` (skills, agents, steering docs) and compare against actual counts on disk.
- **Stale docs:** Flag any doc in `docs/` not modified in 30+ days that references files changed in the last 30 days.

```bash
# Find docs not updated in 30+ days
find docs/ -name "*.md" -not -newer "$(date -d '30 days ago' +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d)" 2>/dev/null
```

## Structured Findings Format

Each finding must include all five fields:

| Field | Values |
|---|---|
| **Category** | `DRY violation` \| `God object` \| `stale test` \| `dead code` \| `dependency issue` \| `structural problem` \| `doc staleness` |
| **Location** | `file:line` |
| **Severity** | `high` \| `medium` \| `low` |
| **Effort** | `small` (< 30 min) \| `medium` (1-2 hrs) \| `large` (half day+) |
| **Agent** | Which agent would fix this: `devops-python`, `devops-typescript`, `devops-refactor`, `devops-docs`, `devops-shell` |

## Report Format

```
## Codebase Audit — [repo] — YYYY-MM-DD

### Project Type
Detected: [Python | TypeScript/Node | Shell | Mixed]

### Churn (top 10 most-changed files)
| File | Changes (90d) | Concern |

### Findings (max 20)
| # | Category | Location | Severity | Effort | Agent | Description |

### Doc Health
| Doc | Issue | Severity |

### Dependencies
| Package | Current | Latest | Behind |

### Debt Markers
TODO: X | FIXME: Y | HACK: Z

### Summary
2-3 sentence overall assessment with top 3 recommended actions.
```

## Guidelines

- Run commands, don't guess — show real numbers
- Present to user for review — never auto-fix
- When running as part of the refactor pipeline, structured findings feed directly into devops-reviewer's analysis and devops-refactor's execution list
