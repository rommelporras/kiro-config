# Phase 1 Execution Plan

> Generated from: `docs/specs/2026-04-17-audit-phase1-safety/spec.md`
> Plan: `docs/specs/2026-04-17-audit-phase1-safety/plan.md`
> Date: 2026-04-17

## Goal

Fix all confirmed safety bugs in agent deny lists, hook scripts, skill trigger lists, and add security hooks to subagents.

## Stage 1 (parallel) — completed 2026-04-17

Three independent delegates. No shared files between them.

**Independence proof:**
- Task 1+2: touches `agents/*.json`, `.kiro/agents/*.json`
- Task 3: touches `hooks/feedback/context-enrichment.sh`
- Task 4+5: touches `hooks/_lib/distill.sh`, `skills/post-implementation/SKILL.md`

Zero file overlap.

### Task 1.1: Fix deny-list patterns in agent JSONs (Plan Tasks 1 + 2)

- **Agent:** dev-kiro-config
- **Objective:** Fix the `dd if/dev` typo in 8 agent JSONs, replace `rm -f.*r.*` with precise patterns in 7 agent JSONs + base.json, and add `rm` deny patterns to the orchestrator.
- **Files:**
  - Modify: `agents/dev-orchestrator.json` — dd fix, add rm deny patterns
  - Modify: `agents/dev-python.json` — dd fix, rm fix
  - Modify: `agents/dev-shell.json` — dd fix, rm fix
  - Modify: `agents/dev-frontend.json` — dd fix, rm fix
  - Modify: `agents/dev-typescript.json` — dd fix, rm fix
  - Modify: `agents/dev-refactor.json` — dd fix, rm fix
  - Modify: `agents/dev-reviewer.json` — dd fix only (uses `"rm .*"`)
  - Modify: `agents/dev-docs.json` — add dd pattern, rm fix
  - Modify: `agents/base.json` — rm fix only (dd already correct)
  - Modify: `.kiro/agents/dev-kiro-config.json` — add dd pattern (uses `"rm .*"`)
- **Briefing context:**
  - `docs/specs/2026-04-17-audit-phase1-safety/plan.md` — Tasks 1 and 2 (full before/after strings)
- **Constraints:**
  - Do NOT modify `base.json`'s `dd` pattern — it's already correct (`"dd if=/dev"`)
  - Do NOT modify `dev-reviewer.json` or `dev-kiro-config.json` rm patterns — they use `"rm .*"` which is intentionally stricter
  - Do NOT add or remove any other deny-list entries
  - Task 1 (dd fixes) must complete on `dev-orchestrator.json` BEFORE Task 2 Step 3 (rm additions) runs — the rm additions use the corrected dd pattern as an anchor
- **Done when:**
  - `grep -r '"dd if' agents/ .kiro/agents/` shows only `"dd if=/dev.*"` or `"dd if=/dev"` (base.json) — zero `"dd if/dev"` matches
  - `grep -rn 'rm -f\.\*r' agents/` returns zero matches (old pattern gone)
  - `jq '.toolsSettings.execute_bash.deniedCommands' agents/dev-orchestrator.json | grep '"rm '` shows the two new rm patterns
  - `for f in agents/*.json .kiro/agents/*.json; do jq empty "$f" && echo "$f OK" || echo "$f BROKEN"; done` — all OK
- **Skill triggers:** "verify before completing"

### Task 1.2: Fix hook scripts (Plan Tasks 3 + 4)

- **Agent:** dev-kiro-config
- **Objective:** Escape regex metacharacters in context-enrichment.sh and replace the corrupted sed promotion in distill.sh with awk.
- **Files:**
  - Modify: `hooks/feedback/context-enrichment.sh` — add PCRE escaping before grep
  - Modify: `hooks/_lib/distill.sh` — replace sed with awk in `distill_check()`
- **Briefing context:**
  - `docs/specs/2026-04-17-audit-phase1-safety/plan.md` — Tasks 3 and 4 (exact before/after)
- **Constraints:**
  - Only change the specific lines identified in the plan
  - Do not restructure or refactor surrounding code
  - The awk replacement uses `BEGIN{IGNORECASE=1}` — this is intentional (GNU awk on target system)
- **Done when:**
  - `grep 'escaped_kw' hooks/feedback/context-enrichment.sh` returns 2 matches
  - `grep 'grep -qiP.*\${kw}' hooks/feedback/context-enrichment.sh` returns zero matches (raw `$kw` no longer in grep)
  - `grep -n 'sed.*promoted' hooks/_lib/distill.sh` returns zero matches
  - `grep -n 'awk.*promoted' hooks/_lib/distill.sh` returns 1 match
  - `bash -n hooks/feedback/context-enrichment.sh` exits 0 (valid syntax)
  - `bash -n hooks/_lib/distill.sh` exits 0 (valid syntax)
- **Skill triggers:** "verify before completing"

### Task 1.3: Sync post-implementation trigger list (Plan Task 5)

- **Agent:** dev-docs
- **Objective:** Add `dev-kiro-config` and `dev-frontend` to the post-implementation skill's trigger list to match the orchestrator prompt.
- **Files:**
  - Modify: `skills/post-implementation/SKILL.md` — update trigger line
- **Briefing context:**
  - `docs/specs/2026-04-17-audit-phase1-safety/plan.md` — Task 5 (exact before/after)
  - `agents/prompts/orchestrator.md` — lines 8-9 (source of truth for the agent list)
- **Constraints:**
  - Only change the trigger line — do not modify any other content in the skill
- **Done when:**
  - `grep 'dev-frontend' skills/post-implementation/SKILL.md` returns 1 match
  - `grep 'dev-kiro-config' skills/post-implementation/SKILL.md` returns 1 match
- **Skill triggers:** "verify before completing"

## Stage 2 (after Stage 1) — completed 2026-04-17

### Task 2.1: Add security hooks to all subagent configs (Plan Task 7)

- **Agent:** dev-kiro-config
- **Depends on:** Task 1.1 (modifies the same agent JSON files)
- **Objective:** Add preToolUse hooks (scan-secrets, protect-sensitive, bash-write-protect, block-sed-json) to all 8 subagent configs.
- **Files:**
  - Modify: `agents/dev-python.json` — add 4-hook block
  - Modify: `agents/dev-shell.json` — add 4-hook block
  - Modify: `agents/dev-frontend.json` — add 4-hook block
  - Modify: `agents/dev-typescript.json` — add 4-hook block
  - Modify: `agents/dev-refactor.json` — add 4-hook block
  - Modify: `agents/dev-docs.json` — add 4-hook block
  - Modify: `agents/dev-reviewer.json` — add 2-hook block (execute_bash only, no write tool)
  - Modify: `.kiro/agents/dev-kiro-config.json` — add 4-hook block
- **Briefing context:**
  - `docs/specs/2026-04-17-audit-phase1-safety/plan.md` — Task 7 (exact insertion points and JSON blocks)
- **Constraints:**
  - dev-reviewer gets only 2 hooks (bash-write-protect, block-sed-json) — it has no write tool
  - All other agents get all 4 hooks
  - Insert hooks block before `"includeMcpJson": false` in every file
  - Do NOT modify any other fields in the agent configs
- **Done when:**
  - `for f in agents/dev-*.json .kiro/agents/dev-*.json; do echo "=== $f ==="; jq 'has("hooks")' "$f"; done` — all show `true`
  - `jq '.hooks.preToolUse | length' agents/dev-reviewer.json` returns `2`
  - `jq '.hooks.preToolUse | length' agents/dev-python.json` returns `4`
  - `jq '.hooks.preToolUse | length' .kiro/agents/dev-kiro-config.json` returns `4`
  - `for f in agents/*.json .kiro/agents/*.json; do jq empty "$f" && echo "$f OK" || echo "$f BROKEN"; done` — all OK

- **Skill triggers:** "verify before completing"

## Stage 3: Review — completed 2026-04-17

Review found 1 CRITICAL (archive_promoted regression) and 1 IMPORTANT
(orchestrator missing rm --force --recursive). Both fixed and verified.

### Task 3.1: Review all changes

- **Agent:** dev-reviewer
- **Depends on:** Task 1.1, Task 1.2, Task 1.3, Task 2.1
- **Objective:** Review all modified files for correctness, JSON validity, and no unintended changes.
- **Files to review:**
  - All `agents/*.json` and `.kiro/agents/*.json`
  - `hooks/feedback/context-enrichment.sh`
  - `hooks/_lib/distill.sh`
  - `skills/post-implementation/SKILL.md`
- **Focus areas:**
  - JSON syntax validity across all agent configs
  - Deny-list patterns use correct regex (anchored with `\A`/`\z`, need `.*` suffix for prefix matching)
  - Hook blocks are structurally identical to the orchestrator's hooks (same matchers, same paths, same timeouts)
  - dev-reviewer has exactly 2 hooks (no fs_write hooks)
  - The awk replacement in distill.sh preserves the pipe-delimited episode format
  - The regex escaping in context-enrichment.sh handles all PCRE metacharacters
  - No unintended changes to any file (diff should be minimal and targeted)
- **Done when:** APPROVE or findings listed with severity

## Verification

After all stages complete:

- [ ] `grep -r '"dd if' agents/ .kiro/agents/` — every match shows `dd if=/dev.*` or `dd if=/dev` (base.json only)
- [ ] `grep -rn 'rm -f\.\*r' agents/` — zero matches
- [ ] `grep 'escaped_kw' hooks/feedback/context-enrichment.sh` — present
- [ ] `grep -n 'sed.*promoted' hooks/_lib/distill.sh` — zero matches
- [ ] `grep 'dev-frontend' skills/post-implementation/SKILL.md` — present
- [ ] `grep 'dev-kiro-config' skills/post-implementation/SKILL.md` — present
- [ ] `jq '.toolsSettings.execute_bash.deniedCommands' agents/dev-orchestrator.json | grep '"rm '` — shows patterns
- [ ] `for f in agents/dev-*.json .kiro/agents/dev-*.json; do jq '.hooks.preToolUse | length' "$f"; done` — all return 4 except dev-reviewer (2)
- [ ] `for f in agents/*.json .kiro/agents/*.json; do jq empty "$f" && echo OK || echo BROKEN; done` — all OK

## Commit

After all stages pass verification, present results to user for commit approval:
- **Suggested type:** fix
- **Suggested scope:** agents, hooks, skills
- **Suggested message:** `fix: patch deny-list patterns, add security hooks to subagents, fix knowledge pipeline bugs`

> Note: as of v0.7.0, dev-* agents were renamed to devops-*. See docs/specs/2026-04-18-devops-terraform-and-rename/spec.md.
