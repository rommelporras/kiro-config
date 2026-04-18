# Kiro Config — TODO

## Active Specs

- [x] **Spec 1: Shell Safety & File Operations** — `docs/specs/2026-04-16-shell-safety-file-operations/spec.md`
  - bash-write-protect.sh overhaul (mv, selective rm, rm -rf confirmation)
  - Orchestrator routing: file operations lane
  - devops-docs permission expansion

- [x] **Spec 2: Orchestrator & Agent Framework Redesign** — `docs/specs/2026-04-16-orchestrator-agent-framework-redesign/spec.md`
  - Orchestrator prompt rewrite (250 → ~130 lines)
  - Skill consolidation (19 → 12 skills)
  - New: design-and-spec skill (merged brainstorming + spec-workflow + critical-thinking)
  - New: post-implementation skill (auto-review, quality gate, doc staleness, improvement capture, refactor pipeline)
  - Rewrite: codebase-audit (structured output, project-type detection, doc health)
  - Rewrite: agent-audit (absorb meta-review, improvements/pending.md integration)
  - Enhancement: commit skill (doc reference check)
  - Upgrade: devops-refactor (TDD skill, execute-findings mode, shared code awareness)
  - Upgrade: devops-reviewer (codebase scan mode, doc accuracy dimension)
  - Fold into prompt: delegation-protocol, aggregation
  - Remove: research-practices, context-docs, project-architecture, meta-review, critical-thinking
  - Framework: project-aware quality gate, pre-dispatch hook
  - Create: docs/improvements/ structure (pending.md, resolved.md)
  - Docs: creating-agents.md, skill-catalog.md, README.md updates

- [x] **Spec 3: TypeScript & Frontend Stack** — `docs/specs/2026-04-16-typescript-frontend-stack/spec.md`
  - New steering: typescript.md, web-development.md, frontend.md
  - New agents: devops-typescript, devops-frontend
  - New skill: typescript-audit (for devops-reviewer)
  - Update: tooling.md (Node.js/npm, project-specific venvs)
  - Orchestrator routing: TypeScript + frontend lanes

## Bug Fixes

- [x] **doc-consistency.sh: regex doesn't match actual README/skill-catalog text**
  - `hooks/doc-consistency.sh` line 29: regex `loads \d+ of \d+ skills` fails because actual text is `loads 14 of the 18 global skills` (has "the" and "global" between the numbers)
  - Same issue line 43: regex `\d+ of the \d+ skills` fails because actual text is `14 of the 18 global skills` (has "global" before "skills")
  - Fix: update regexes to `loads \d+ of (the )?\d+ (global )?skills` and `\d+ of the \d+ (global )?skills`
  - Affects: quick health check (§2 in audit-playbook.md) reports false drift

- [x] **audit-playbook.md A1 check: post-impl trigger list comparison is too broad** — Fixed in v0.6.1 — narrowed grep to trigger line only
  - A1 compares all `dev-*` agent names in `skills/post-implementation/SKILL.md` against orchestrator lines 8-9
  - Skill mentions 8 agents (includes devops-reviewer for auto-review dispatch, devops-docs as reference)
  - Orchestrator lines 8-9 list only 6 implementation agents that trigger post-impl (excludes devops-reviewer and devops-docs — by design)
  - Fix: either narrow the grep on the skill side to only the trigger condition, or document the expected diff in §1.5 known limitations

## Dependency chain

```
Spec 1 (shell safety) ──┐
                         ├──▶ Spec 2 (framework redesign) ──▶ Spec 3 (TS + frontend)
                         │
                    (unblocks file operations routing)
```

## Completed / Resolved

- [x] ~~kubeconfig cross-region contamination~~ — Fixed in cost-optimizer Phase 12.3
- [x] ~~checklist-driven prompt improvement~~ — Documented in cost-optimizer v3 spec
- [x] ~~subagent dispatch for simple shell commands is unreliable~~ — Fixed in cost-optimizer Phase 12.1

## Dropped

- ~~finishing-a-development-branch skill~~ — Project-local to ~/eam/eam-sre/rommel-porras, not global
- ~~Pipeline agent pattern skill~~ — Removed from scope
- ~~dev-web agent evaluation~~ — Resolved: split into devops-typescript + devops-frontend
- ~~Flask vs FastAPI decision~~ — Resolved: Express.js + TypeScript
