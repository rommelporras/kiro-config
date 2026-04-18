# Resolved Improvements

Items addressed from pending.md. Audit trail.

<!-- Move entries here after fixing. Include date resolved and what was done. -->

## 2026-04-16 — agent-audit directory tree and feature count verification
- Original: agent-audit Phase 8 didn't verify README directory trees or feature counts against filesystem
- Fix: Added "Directory tree verification" and "Feature count verification" checks to Phase 8 in `skills/agent-audit/SKILL.md`

## 2026-04-18 — ECS refactoring session improvements (batch resolution)

### Resolved: Load-bearing ordering → atomic dispatch
- Original: Orchestrator dispatched Phase 2 tasks separately despite load-bearing ordering
- Fix: Added atomic dispatch rule to `skills/execution-planning/SKILL.md`

### Resolved: Log accuracy rule
- Original: Orchestrator dismissed fake dry-run log data as "minor"
- Fix: Added "Logs are operational data" rule to `steering/engineering.md`

### Resolved: Doc metrics staleness grep
- Original: Stale test counts in 4 doc files not caught proactively
- Fix: Added metrics staleness step to `skills/post-implementation/SKILL.md` Step 3

### Resolved: Grep for tests of removed symbols
- Original: No-op test left behind after removing `dry_run` parameter
- Fix: Added "After removing code" section to `agents/prompts/dev-python.md`

### Resolved: Argparse help text check
- Original: `--allow-downtime` behavior fixed but argparse help text not updated
- Fix: Added argparse help text rule to `agents/prompts/dev-python.md`

### Resolved: TDD briefing for packaged code
- Original: TDD never triggered because global "no auto tests" rule overrides project steering
- Fix: Added TDD override rule to orchestrator delegation format in `agents/prompts/orchestrator.md`

### Resolved: Specs not marked complete
- Original: Spec header not updated after all phases complete
- Fix: Added Step 7 "Spec completion check" to `skills/post-implementation/SKILL.md`

### Resolved: `--allow-downtime` argparse help text
- Original: CLI `--help` still said old description after B1 behavior fix
- Fix: Updated `sre/eam_sre/bounce/cli.py:155` help text to match new behavior. Also added argparse check rule to `agents/prompts/dev-python.md`.
