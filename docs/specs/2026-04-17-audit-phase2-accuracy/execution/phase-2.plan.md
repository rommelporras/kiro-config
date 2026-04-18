# Phase 2 Execution Plan

> Generated from: `docs/specs/2026-04-17-audit-phase2-accuracy/spec.md`
> Plan: `docs/specs/2026-04-17-audit-phase2-accuracy/plan.md`
> Date: 2026-04-17

## Goal

Fix accuracy gaps: TDD skills, MCP access, ghost agent reference, auto-capture blind spots, base.json dd pattern.

## Stage 1 (parallel) — completed 2026-04-17

Two independent delegates. No shared files between them.

**Independence proof:**
- Delegate A: agent JSONs (`dev-frontend.json`, `dev-shell.json`, `dev-python.json`, `dev-typescript.json`, `dev-refactor.json`), agent prompts (`frontend-dev.md`, `shell-dev.md`), `base.json`
- Delegate B: `skills/writing-plans/SKILL.md`, `agents/prompts/orchestrator.md`, `hooks/feedback/auto-capture.sh`, `hooks/_lib/distill.sh`

Zero file overlap.

### Task 1.1: Agent config + prompt changes (Plan Tasks 1, 3, 4)

- **Agent:** dev-kiro-config
- **Objective:** Add TDD skill to dev-frontend and dev-shell (resources + prompt sections), enable MCP on 5 subagents (tools, allowedTools, includeMcpJson), and fix base.json dd pattern.
- **Files:**
  - Modify: `agents/dev-frontend.json` — add TDD skill resource, add MCP tools, enable MCP
  - Modify: `agents/dev-shell.json` — add TDD skill resource, add MCP tools, enable MCP
  - Modify: `agents/dev-python.json` — add MCP tools, enable MCP
  - Modify: `agents/dev-typescript.json` — add MCP tools, enable MCP
  - Modify: `agents/dev-refactor.json` — add MCP tools, enable MCP
  - Modify: `agents/prompts/frontend-dev.md` — add Testing section
  - Modify: `agents/prompts/shell-dev.md` — add Testing section
  - Modify: `agents/base.json` — dd pattern fix
- **Briefing context:**
  - `docs/specs/2026-04-17-audit-phase2-accuracy/plan.md` — Tasks 1, 3, and 4 (full before/after strings)
- **Constraints:**
  - Tasks 1 and 4 share `dev-frontend.json` and `dev-shell.json` — apply Task 1 changes (TDD resource) BEFORE Task 4 changes (MCP tools) on each file
  - Do NOT enable MCP on dev-docs, dev-reviewer, or dev-kiro-config — they stay `"includeMcpJson": false`
  - Do NOT modify any fields other than `tools`, `allowedTools`, `resources`, `includeMcpJson` in agent JSONs
  - Prompt additions go at the END of each prompt file (after "What you never do")
- **Done when:**
  - `jq '.resources[]' agents/dev-frontend.json | grep 'test-driven'` → match
  - `jq '.resources[]' agents/dev-shell.json | grep 'test-driven'` → match
  - `grep 'bats-core' agents/prompts/shell-dev.md` → match
  - `grep 'Vitest.*happy-dom' agents/prompts/frontend-dev.md` → match
  - `for f in agents/dev-python.json agents/dev-typescript.json agents/dev-frontend.json agents/dev-shell.json agents/dev-refactor.json; do jq '.includeMcpJson' "$f"; done` → all `true`
  - `jq '.tools' agents/dev-python.json | grep 'aws-documentation'` → match
  - `jq '.tools' agents/dev-frontend.json | grep 'playwright'` → match
  - `jq '.includeMcpJson' agents/dev-docs.json` → `false`
  - `jq '.includeMcpJson' agents/dev-reviewer.json` → `false`
  - `grep '"dd if=/dev\.\*"' agents/base.json` → match
  - `for f in agents/*.json .kiro/agents/*.json; do jq empty "$f" && echo "$f OK" || echo "$f BROKEN"; done` → all OK
- **Skill triggers:** "verify before completing"

### Task 1.2: Skill, prompt, and hook fixes (Plan Tasks 2, 5, 6, 7)

- **Agent:** dev-kiro-config
- **Objective:** Fix plan-reviewer ghost reference, correct orchestrator MCP claim, add auto-capture keyword fallback, and raise general-bucket promotion threshold.
- **Files:**
  - Modify: `skills/writing-plans/SKILL.md` — replace plan-reviewer with dev-reviewer
  - Modify: `agents/prompts/orchestrator.md` — fix MCP tools line
  - Modify: `hooks/feedback/auto-capture.sh` — general fallback
  - Modify: `hooks/_lib/distill.sh` — keyword-aware threshold
- **Briefing context:**
  - `docs/specs/2026-04-17-audit-phase2-accuracy/plan.md` — Tasks 2, 5, 6, and 7 (exact before/after strings)
- **Constraints:**
  - Only change the specific lines identified in the plan
  - Do not restructure or refactor surrounding code
- **Done when:**
  - `grep 'plan-reviewer' skills/writing-plans/SKILL.md` → zero matches
  - `grep -n 'dev-reviewer' skills/writing-plans/SKILL.md` → match at line 122
  - `grep 'explicitly listed' agents/prompts/orchestrator.md` → match
  - `grep 'general' hooks/feedback/auto-capture.sh` → match
  - `grep -c 'KEYWORDS="general"' hooks/feedback/auto-capture.sh` → 1
  - `grep 'threshold=5' hooks/_lib/distill.sh` → match
  - `bash -n hooks/feedback/auto-capture.sh` → exits 0
  - `bash -n hooks/_lib/distill.sh` → exits 0
- **Skill triggers:** "verify before completing"

## Stage 2: Review — completed 2026-04-17 (APPROVED, no findings)

### Task 2.1: Review all changes

- **Agent:** dev-reviewer
- **Depends on:** Task 1.1, Task 1.2
- **Objective:** Review all modified files for correctness and no unintended changes.
- **Files to review:**
  - `agents/dev-frontend.json`, `agents/dev-shell.json`, `agents/dev-python.json`, `agents/dev-typescript.json`, `agents/dev-refactor.json`
  - `agents/base.json`
  - `agents/prompts/frontend-dev.md`, `agents/prompts/shell-dev.md`, `agents/prompts/orchestrator.md`
  - `skills/writing-plans/SKILL.md`
  - `hooks/feedback/auto-capture.sh`, `hooks/_lib/distill.sh`
- **Focus areas:**
  - JSON validity on all agent configs
  - MCP tool names match `settings/mcp.json` server names exactly (`context7`, `awslabs.aws-documentation-mcp-server`, `playwright`)
  - MCP tools appear in BOTH `tools` and `allowedTools` for enabled agents
  - `includeMcpJson` is `true` only for the 5 specified agents, `false` for the other 3
  - TDD skill resource path is correct and appears in dev-frontend + dev-shell only
  - Prompt testing sections are appropriate for each agent's domain (frontend vs shell)
  - auto-capture.sh fallback uses `KEYWORDS="general"` not `exit 0`
  - distill.sh threshold logic correctly applies 5 only to `"general"` keyword, 3 to everything else
  - No unintended changes anywhere
- **Done when:** APPROVE or findings listed with severity

## Verification

After all stages complete:

- [ ] `jq '.resources[]' agents/dev-frontend.json | grep 'test-driven'` → match
- [ ] `jq '.resources[]' agents/dev-shell.json | grep 'test-driven'` → match
- [ ] `grep 'plan-reviewer' skills/writing-plans/SKILL.md` → zero matches
- [ ] `jq '.includeMcpJson' agents/dev-python.json` → `true`
- [ ] `jq '.tools' agents/dev-python.json | grep 'context7'` → match
- [ ] `jq '.includeMcpJson' agents/dev-reviewer.json` → `false`
- [ ] `grep 'explicitly listed' agents/prompts/orchestrator.md` → match
- [ ] `grep 'general' hooks/feedback/auto-capture.sh` → match
- [ ] `grep 'threshold=5' hooks/_lib/distill.sh` → match
- [ ] `grep '"dd if=/dev\.\*"' agents/base.json` → match
- [ ] All JSON files valid

## Commit

After all stages pass verification, present results to user for commit approval:
- **Suggested type:** fix
- **Suggested scope:** agents, skills, hooks
- **Suggested message:** `fix: add TDD skills, enable selective MCP, fix auto-capture blind spots and ghost references`

> Note: as of v0.7.0, dev-* agents were renamed to devops-*. See docs/specs/2026-04-18-devops-terraform-and-rename/spec.md.
