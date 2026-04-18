# Phase 3 Execution Plan

> Generated from: `docs/specs/2026-04-17-audit-phase3-consistency/spec.md`
> Plan: `docs/specs/2026-04-17-audit-phase3-consistency/plan.md`
> Date: 2026-04-17

## Goal

Eliminate prompt/steering duplication, fix doc count drift, hardcoded paths, overly broad write permissions, and add file-conflict detection.

## Stage 1 (parallel — all 11 tasks) — completed 2026-04-17

All tasks touch independent file sets. No shared files between any two tasks.

**Independence proof:**
- Tasks 1.1-1.4: each touches one prompt file (python-dev.md, shell-dev.md, typescript-dev.md, frontend-dev.md)
- Task 1.5: code-reviewer.md + creates .kiro/steering/agent-config-review.md (new file)
- Task 1.6: refactor.md
- Task 1.7: docs.md + orchestrator.md (path fix only)
- Task 1.8: skills/execution-planning/SKILL.md
- Task 1.9: skills/post-implementation/SKILL.md
- Task 1.10: README.md, team-onboarding.md, kiro-cli-install-checklist.md, rommel-porras-setup.md, troubleshooting.md (steering count + symlink loop updates — Tasks 10 and 12 merged)
- Task 1.11: agents/dev-orchestrator.json

Zero file overlap across all 11 tasks.

### Task 1.1: Rewrite python-dev.md (Plan Task 1)

- **Agent:** dev-kiro-config
- **Objective:** Replace python-dev.md with a deduplicated version that references steering instead of restating it.
- **Files:** Modify: `agents/prompts/python-dev.md`
- **Briefing context:** `docs/specs/2026-04-17-audit-phase3-consistency/plan.md` — Task 1 (complete replacement text provided)
- **Constraints:** Do NOT create a section listing design principles. Do NOT enumerate Rule of Three, Fail Fast, etc. One inline reference to steering/design-principles.md only if needed. Use the exact steering-reference template from the plan's Global Constraints.
- **Done when:** `wc -l` shows ~48 lines; zero matches for `boto3.Session`, `get_paginator`, `ClientError`, `structlog`, `pydantic-settings`, `uv lock`, `tenacity`; steering references present
- **Skill triggers:** "verify before completing"

### Task 1.2: Rewrite shell-dev.md (Plan Task 2)

- **Agent:** dev-kiro-config
- **Objective:** Replace shell-dev.md with a deduplicated version. Heaviest trim — almost all content is in steering.
- **Files:** Modify: `agents/prompts/shell-dev.md`
- **Briefing context:** `docs/specs/2026-04-17-audit-phase3-consistency/plan.md` — Task 2
- **Constraints:** Same design-principles ban. Preserve the Testing section added in Phase 2.
- **Done when:** `wc -l` shows ~42 lines; zero matches for `jq`, `trap cleanup`, `getopts`, `mapfile`, `set -euo`; Testing section with bats-core present
- **Skill triggers:** "verify before completing"

### Task 1.3: Rewrite typescript-dev.md (Plan Task 3)

- **Agent:** dev-kiro-config
- **Objective:** Replace typescript-dev.md with a deduplicated version referencing typescript.md and web-development.md.
- **Files:** Modify: `agents/prompts/typescript-dev.md`
- **Briefing context:** `docs/specs/2026-04-17-audit-phase3-consistency/plan.md` — Task 3
- **Constraints:** Same design-principles ban. Agent-specific patterns are one-line bullets with steering references.
- **Done when:** `wc -l` shows ~43 lines; zero matches for `noUncheckedIndexedAccess`, `ESLint.*parser`, `Prettier for formatting`, `barrel exports`, `SCREAMING_SNAKE`
- **Skill triggers:** "verify before completing"

### Task 1.4: Rewrite frontend-dev.md (Plan Task 4)

- **Agent:** dev-kiro-config
- **Objective:** Replace frontend-dev.md with a deduplicated version. Preserve verification checklist and Testing section.
- **Files:** Modify: `agents/prompts/frontend-dev.md`
- **Briefing context:** `docs/specs/2026-04-17-audit-phase3-consistency/plan.md` — Task 4
- **Constraints:** Same design-principles ban. Verification checklist stays. Testing section (Phase 2) stays.
- **Done when:** `wc -l` shows ~55 lines; zero matches for `BEM naming`, `WCAG 2.1`, `min-width.*media`, `aria-label`, `tabindex`; verification checklist present; Testing section present
- **Skill triggers:** "verify before completing"

### Task 1.5: Trim code-reviewer.md + extract checklist (Plan Task 5)

- **Agent:** dev-kiro-config
- **Objective:** Remove agent config checklist from code-reviewer.md (move to project-level steering), add operating context and tools block.
- **Files:**
  - Modify: `agents/prompts/code-reviewer.md`
  - Create: `.kiro/steering/agent-config-review.md`
- **Briefing context:** `docs/specs/2026-04-17-audit-phase3-consistency/plan.md` — Task 5 (exact oldStr/newStr for each step)
- **Constraints:** Do not modify review dimensions, structural quality checks, or codebase scan mode sections. Only remove the agent config checklist and add the operating context block.
- **Done when:** `wc -l` shows ~82 lines; zero matches for `Agent config checklist` in code-reviewer.md; `.kiro/steering/agent-config-review.md` exists; `Available tools` section present in code-reviewer.md
- **Skill triggers:** "verify before completing"

### Task 1.6: Trim refactor.md (Plan Task 6)

- **Agent:** dev-kiro-config
- **Objective:** Add operating context, tools, steering reference, and status definitions to refactor.md.
- **Files:** Modify: `agents/prompts/refactor.md`
- **Briefing context:** `docs/specs/2026-04-17-audit-phase3-consistency/plan.md` — Task 6 (exact oldStr/newStr)
- **Constraints:** Same design-principles ban. Do not modify the refactoring operations list or finding-handling workflow.
- **Done when:** `wc -l` shows ~60 lines; zero matches for `Rule of Three`, `Fail Fast`, `Least Knowledge`, `Boy-Scout`; `Available tools` and `Standards` sections present
- **Skill triggers:** "verify before completing"

### Task 1.7: Expand docs.md + fix orchestrator path (Plan Task 7)

- **Agent:** dev-kiro-config
- **Objective:** Replace docs.md with expanded version (operating context, tools, status protocol, constraints) and fix the hardcoded improvement path in orchestrator.md.
- **Files:**
  - Modify: `agents/prompts/docs.md`
  - Modify: `agents/prompts/orchestrator.md`
- **Briefing context:** `docs/specs/2026-04-17-audit-phase3-consistency/plan.md` — Task 7 (complete replacement for docs.md, exact oldStr/newStr for orchestrator.md)
- **Constraints:** For orchestrator.md, only change the improvement capture path — do not modify any other content.
- **Done when:** `wc -l agents/prompts/docs.md` shows ~42 lines; `grep 'personal/kiro-config' agents/prompts/orchestrator.md` returns zero; `grep '~/.kiro/docs/improvements' agents/prompts/orchestrator.md` returns one match
- **Skill triggers:** "verify before completing"

### Task 1.8: Add file-conflict pre-check (Plan Task 8)

- **Agent:** dev-kiro-config
- **Objective:** Add a hard-gate rule to execution-planning skill requiring file-list cross-checks before marking tasks parallel.
- **Files:** Modify: `skills/execution-planning/SKILL.md`
- **Briefing context:** `docs/specs/2026-04-17-audit-phase3-consistency/plan.md` — Task 8 (exact oldStr/newStr)
- **Constraints:** Only add the new rule — do not modify existing rules.
- **Done when:** `grep 'cross-check file lists' skills/execution-planning/SKILL.md` returns one match
- **Skill triggers:** "verify before completing"

### Task 1.9: Fix post-implementation improvement path (Plan Task 9)

- **Agent:** dev-kiro-config
- **Objective:** Replace hardcoded `~/personal/kiro-config/docs/improvements/pending.md` with `~/.kiro/docs/improvements/pending.md`.
- **Files:** Modify: `skills/post-implementation/SKILL.md`
- **Briefing context:** `docs/specs/2026-04-17-audit-phase3-consistency/plan.md` — Task 9 (exact oldStr/newStr)
- **Constraints:** Only change the path — do not modify any other content.
- **Done when:** `grep 'personal/kiro-config' skills/post-implementation/SKILL.md` returns zero; `grep '~/.kiro/docs/improvements' skills/post-implementation/SKILL.md` returns one match
- **Skill triggers:** "verify before completing"

### Task 1.10: Update setup docs — steering count + docs symlink (Plan Tasks 10 + 12, merged)

- **Agent:** dev-kiro-config
- **Objective:** Two coordinated changes across setup docs:
  1. Update steering doc count from 10 to 11 in 3 files and add `design-principles.md` to file lists (Plan Task 10).
  2. Add `docs` to the symlink loop in 4 setup docs so future setups create `~/.kiro/docs` automatically (Plan Task 12, corrected).
- **Files:**
  - Modify: `README.md` — steering count update only
  - Modify: `docs/setup/team-onboarding.md` — steering count update AND symlink loop update
  - Modify: `docs/setup/kiro-cli-install-checklist.md` — steering count update AND symlink loop update
  - Modify: `docs/setup/rommel-porras-setup.md` — symlink loop update only
  - Modify: `docs/setup/troubleshooting.md` — symlink loop update only
- **Briefing context:** `docs/specs/2026-04-17-audit-phase3-consistency/plan.md` — Task 10 for steering count. For the symlink loop update, change `for dir in steering agents skills settings hooks` to `for dir in steering agents skills settings hooks docs` in each occurrence.
- **Constraints:**
  - Do not modify any other content in these files.
  - base.json is NOT included (no steering count in welcomeMessage).
  - `scripts/personalize.sh` is NOT the target — symlink creation lives in the setup docs, not scripts.
- **Done when:**
  - `grep -rn '10 steering\|10 global steering' README.md docs/setup/` returns zero
  - `grep 'design-principles' README.md docs/setup/team-onboarding.md docs/setup/kiro-cli-install-checklist.md` returns matches in all 3
  - `grep -rn 'for dir in steering agents skills settings hooks$' docs/setup/` returns zero (old pattern gone)
  - `grep -rn 'steering agents skills settings hooks docs' docs/setup/` returns 4 matches
- **Skill triggers:** "verify before completing"

### Task 1.11: Remove *.md from orchestrator allowedPaths (Plan Task 11)

- **Agent:** dev-kiro-config
- **Objective:** Remove the overly broad `"*.md"` pattern from the orchestrator's fs_write.allowedPaths.
- **Files:** Modify: `agents/dev-orchestrator.json`
- **Briefing context:** `docs/specs/2026-04-17-audit-phase3-consistency/plan.md` — Task 11 (exact oldStr/newStr)
- **Constraints:** Only remove `"*.md"` — do not modify any other allowedPaths entries.
- **Done when:** `jq '.toolsSettings.fs_write.allowedPaths' agents/dev-orchestrator.json` shows 3 entries, no `*.md`; `jq empty agents/dev-orchestrator.json` exits 0
- **Skill triggers:** "verify before completing"

## Orchestrator Manual Step (after Stage 1, before Stage 2)

Create the `~/.kiro/docs` symlink on the current machine:
```bash
ln -sf ~/personal/kiro-config/docs ~/.kiro/docs
```
This is a one-time local operation, not delegated.

## Stage 2: Review — completed 2026-04-17

Review found 1 IMPORTANT (README.md symlink loop missing 'docs'). Fixed.

### Task 2.1: Review all changes

- **Agent:** dev-reviewer
- **Depends on:** All Stage 1 tasks
- **Objective:** Review all modified files for correctness and no unintended changes.
- **Files to review:** All files from Stage 1 (8 prompts, 1 new steering file, 2 skills, 5 setup docs, 1 agent JSON)
- **Focus areas:**
  - Each prompt follows the target structure: identity, tools, standards reference, agent-specific patterns, before-editing, workflow, status reporting, what you never do
  - NO design principles enumerated in any prompt (Rule of Three, Fail Fast, etc.)
  - Steering-reference template used consistently across all prompts
  - Agent-specific patterns are one-line bullets, not tutorials
  - docs.md has operating context, tools, status protocol, before-editing, what-you-never-do
  - code-reviewer.md agent config checklist is gone; .kiro/steering/agent-config-review.md exists
  - Hardcoded `~/personal/kiro-config` paths gone from orchestrator.md and post-implementation SKILL.md
  - Steering count is 11 in all 3 doc files with design-principles.md in lists
  - `*.md` removed from orchestrator allowedPaths
  - personalize.sh has docs symlink line
  - All JSON files valid
- **Done when:** APPROVE or findings listed with severity

## Verification

After all stages complete:

- [ ] Each prompt 40-60 lines (except orchestrator ~165, code-reviewer ~82, docs ~42)
- [ ] `grep -rn '10 steering\|10 global steering' README.md docs/setup/` → zero matches
- [ ] `grep -rn '11 steering\|11 global steering' README.md docs/setup/` → matches in 3 files
- [ ] `grep 'personal/kiro-config' agents/prompts/orchestrator.md skills/post-implementation/SKILL.md` → zero matches
- [ ] `grep '~/.kiro/docs/improvements' agents/prompts/orchestrator.md skills/post-implementation/SKILL.md` → matches in both
- [ ] `jq '.toolsSettings.fs_write.allowedPaths' agents/dev-orchestrator.json` → no `*.md`
- [ ] `grep 'cross-check file lists' skills/execution-planning/SKILL.md` → match
- [ ] `test -f .kiro/steering/agent-config-review.md` → exists
- [ ] `test -L ~/.kiro/docs` → symlink exists
- [ ] All JSON files valid

## Commit

After all stages pass verification, present results to user for commit approval:
- **Suggested type:** refactor
- **Suggested scope:** prompts, skills, docs, agents
- **Suggested message:** `refactor: deduplicate prompts with steering, fix doc counts, hardcoded paths, and write permissions`

> Note: as of v0.7.0, dev-* agents were renamed to devops-*. See docs/specs/2026-04-18-devops-terraform-and-rename/spec.md.
