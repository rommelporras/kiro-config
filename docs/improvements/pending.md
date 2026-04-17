# Improvement Backlog

Auto-captured friction from sessions. Reviewed during agent-audit.

<!-- Entries are appended by the orchestrator during sessions.
Format:
## YYYY-MM-DD — session in <project path>
### <Category>: <short title>
- What happened: <description>
- Root cause: <steering gap | routing issue | missing skill | missing context>
- Suggested fix: <specific action>
-->

## 2026-04-17 — session in ~/eam/eam-sre/rommel-porras

### Steering conflict: TDD vs "no auto tests" rule

- What happened: Built entire `eam ecs versions` module (collector.py, display.py, cli.py — ~300 lines) without any tests. User had to explicitly ask for tests after implementation was complete. Tests were written retroactively, not TDD.
- Root cause: Steering gap — two contradictory rules. Project steering says "Write the failing test first. No production code without a failing test." But the global Kiro implicit instruction says "DO NOT automatically add tests unless explicitly requested." The global rule always wins because it's framed as a hard constraint, so TDD never triggers.
- Suggested fix: Three changes needed:
  1. **Orchestrator prompt**: Add a routing rule that for `sre/` package code (anything under `sre/eam_sre/`), tests are ALWAYS included in the implementation plan. The "no auto tests" rule only applies to standalone scripts, docs, config, and infra code.
  2. **Plan template**: Every implementation plan for `sre/` code should include a "Tests" task before the "Quality gate" task, not after. Tests come first (TDD), then implementation, then quality gate.
  3. **Subagent briefing**: When delegating to dev-python for `sre/` package work, always include "implement with TDD — write failing tests first" in the skill triggers section. Currently the briefing says "verify before completing" but not "test first."
