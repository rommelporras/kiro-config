# Kiro Config — TODO

## Active Specs

- [ ] **Spec 1: Shell Safety & File Operations** — `docs/specs/2026-04-16-shell-safety-file-operations/spec.md`
  - bash-write-protect.sh overhaul (mv, selective rm, rm -rf confirmation)
  - Orchestrator routing: file operations lane
  - dev-docs permission expansion

- [ ] **Spec 2: Orchestrator & Agent Framework Redesign** — `docs/specs/2026-04-16-orchestrator-agent-framework-redesign/spec.md`
  - Orchestrator prompt rewrite (250 → ~130 lines)
  - Skill consolidation (19 → 12 skills)
  - New: design-and-spec skill (merged brainstorming + spec-workflow + critical-thinking)
  - New: post-implementation skill (auto-review, quality gate, doc staleness, improvement capture, refactor pipeline)
  - Rewrite: codebase-audit (structured output, project-type detection, doc health)
  - Rewrite: agent-audit (absorb meta-review, improvements/pending.md integration)
  - Enhancement: commit skill (doc reference check)
  - Upgrade: dev-refactor (TDD skill, execute-findings mode, shared code awareness)
  - Upgrade: dev-reviewer (codebase scan mode, doc accuracy dimension)
  - Fold into prompt: delegation-protocol, aggregation
  - Remove: research-practices, context-docs, project-architecture, meta-review, critical-thinking
  - Framework: project-aware quality gate, pre-dispatch hook
  - Create: docs/improvements/ structure (pending.md, resolved.md)
  - Docs: creating-agents.md, skill-catalog.md, README.md updates

- [ ] **Spec 3: TypeScript & Frontend Stack** — `docs/specs/2026-04-16-typescript-frontend-stack/spec.md`
  - New steering: typescript.md, web-development.md, frontend.md
  - New agents: dev-typescript, dev-frontend
  - New skill: typescript-audit (for dev-reviewer)
  - Update: tooling.md (Node.js/npm, project-specific venvs)
  - Orchestrator routing: TypeScript + frontend lanes

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
- ~~dev-web agent evaluation~~ — Resolved: split into dev-typescript + dev-frontend
- ~~Flask vs FastAPI decision~~ — Resolved: Express.js + TypeScript
