---
name: project-architecture
description: >
  Restructure a project's folder layout, package organization, and cross-reference
  updates. Triggers on: 'restructure', 'reorganize repo', 'improve folder structure',
  'project layout', 'set up for AI', 'repo architecture'
---

# Skill: Project Architecture

> **Handled DIRECTLY by the orchestrator.** Do not delegate to subagents — this
> skill requires iterative user approval and cross-file coordination.

## Why structure matters for AI-driven development

Clear boundaries reduce errors: one venv, one package dir, one test command,
predictable paths. Ambiguity causes agents to guess wrong locations.

## Process

### Phase 1 — Audit current structure

- Read the full directory tree (depth 3+)
- Identify pain points: scattered files, multiple venvs, mixed concerns,
  loose scripts at root, generated output mixed with source

### Phase 2 — Map cross-references

Grep config files (`.kiro/`, `README*`, `pyproject.toml`, `*.yaml`, `*.sh`)
for any paths that would break if files move.

Produce an impact table:

| File | Hit count | What references |
|------|-----------|-----------------|
| ...  | ...       | ...             |

### Phase 3 — Propose target structure

Show before/after directory trees side by side, then a 'What moved where' table:

| From | To | Why |
|------|----|-----|
| ...  | .. | ... |

### Phase 4 — Phased migration plan

Each phase must have:
- A single goal statement
- Numbered steps
- A verification step (command to run to confirm success)

**Phase 0 is always mechanical moves + config updates — zero code changes.**
Code changes (imports, paths in source) come in later phases.

### Phase 5 — User approval gate

- Present the full plan
- Iterate based on feedback
- Create `docs/plans/` if it doesn't exist, then save final plan to `docs/plans/<name>.md` before executing

## Key principles

- No code changes in the restructure phase (Phase 0)
- Verify cross-references before moving anything, and again after
- Each phase must be independently verifiable — don't bundle phases
- If a move would require touching source code, it belongs in Phase 1+, not Phase 0
