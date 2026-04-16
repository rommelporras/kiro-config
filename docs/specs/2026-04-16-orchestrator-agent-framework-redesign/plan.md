# Orchestrator & Agent Framework Redesign — Implementation Plan

> **For agentic workers:** Use the subagent-driven-development skill to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the orchestrator for reliability — fewer skills (19→12), automated post-implementation workflows, continuous improvement capture, and smarter agent coordination.

**Architecture:** Multi-phase implementation. Phase 0 creates the dev-kiro-config agent (requires session restart). Remaining phases restructure skills, rewrite prompts, and add automation.

**Tech Stack:** JSON (agent configs), Markdown (prompts, skills, docs), Bash (hooks)

**Spec:** `docs/specs/2026-04-16-orchestrator-agent-framework-redesign/spec.md`

---

## Phase 0: Self-modification permissions + model strategy

> **SESSION BOUNDARY:** After this phase, commit and exit. Start a new session
> so dev-kiro-config is loaded. All subsequent phases require dev-kiro-config.

### Task 0.1: Create dev-kiro-config agent

**Files:**
- Create: `.kiro/agents/dev-kiro-config.json`

- [ ] **Step 1: Create the agent config**

Create `.kiro/agents/dev-kiro-config.json` with the config from the spec
(Phase 0 → Agent config section). Key points:
- `allowedPaths`: `~/personal/kiro-config/**`
- `deniedPaths`: does NOT include `~/.kiro/agents`, `~/.kiro/hooks`, `~/.kiro/steering`
- `prompt`: `file://../../agents/prompts/docs.md` (reuses dev-docs prompt)
- `model`: `claude-sonnet-4.6`

- [ ] **Step 2: Verify JSON is valid**

```bash
jq empty .kiro/agents/dev-kiro-config.json && echo "valid" || echo "INVALID"
```

- [ ] **Step 3: Report completion**

### Task 0.2: Update orchestrator config

**Files:**
- Modify: `agents/dev-orchestrator.json`

Note: This file is under deniedPaths for the orchestrator's write tool.
Use shell to edit, or do this task manually.

- [ ] **Step 1: Add dev-kiro-config to availableAgents and trustedAgents**

In `agents/dev-orchestrator.json`, add `"dev-kiro-config"` to both:
- `toolsSettings.subagent.availableAgents` array
- `toolsSettings.subagent.trustedAgents` array

- [ ] **Step 2: Set orchestrator model to opus-4.6**

In `agents/dev-orchestrator.json`, change:
- `"model": null` → `"model": "claude-opus-4.6"`

- [ ] **Step 3: Verify JSON is valid**

```bash
jq empty agents/dev-orchestrator.json && echo "valid" || echo "INVALID"
jq '.toolsSettings.subagent.availableAgents' agents/dev-orchestrator.json
jq '.model' agents/dev-orchestrator.json
```
Expected: valid, array includes "dev-kiro-config", model is "claude-opus-4.6"

- [ ] **Step 4: Report completion**

### Task 0.3: Add dev-kiro-config routing to orchestrator prompt

**Files:**
- Modify: `agents/prompts/orchestrator.md`

- [ ] **Step 1: Add routing lane**

Add before the dev-docs routing lane:

```markdown
### → dev-kiro-config

Triggers: edit agent config, update prompt, modify hook, update steering,
edit skill, kiro-config change

Route when: The task involves editing kiro-config files (agents/, hooks/,
steering/, skills/). This agent is project-local — only available when
working in the kiro-config repo. If not available, fall back to dev-docs
or handle directly via shell.
```

- [ ] **Step 2: Verify routing table order**

Read the routing table and confirm dev-kiro-config appears before dev-docs.

- [ ] **Step 3: Report completion**

### Task 0.4: Create docs/improvements structure

**Files:**
- Create: `docs/improvements/pending.md`
- Create: `docs/improvements/resolved.md`

- [ ] **Step 1: Create pending.md**

```markdown
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
```

- [ ] **Step 2: Create resolved.md**

```markdown
# Resolved Improvements

Items addressed from pending.md. Audit trail.

<!-- Move entries here after fixing. Include date resolved and what was done. -->
```

- [ ] **Step 3: Report completion**

### Task 0.5: Commit Phase 0 and exit

- [ ] **Step 1: Commit Phase 0 on feature branch**

```bash
git checkout -b feature/framework-redesign
git add .kiro/agents/dev-kiro-config.json agents/dev-orchestrator.json agents/prompts/orchestrator.md docs/improvements/
git commit -m "feat: add dev-kiro-config agent, set opus model, create improvements structure"
git push -u origin feature/framework-redesign
```

- [ ] **Step 2: Exit session**

Tell user: **"Phase 0 committed on `feature/framework-redesign`. Run `/quit` now. New session prompt:**
```
Continue docs/specs/2026-04-16-orchestrator-agent-framework-redesign/plan.md — Phase 1 through Phase 6. Also implement docs/specs/2026-04-16-shell-safety-file-operations/spec.md and plan.md.
```
**"**

⛔ **STOP HERE. Do not continue to Phase 1 in this session.**
dev-kiro-config and the orchestrator model change require a session restart.

---

## Phase 1: Skill consolidation

> **Prerequisite:** dev-kiro-config agent must be available (new session after Phase 0).
> Route all file edits in agents/, skills/, steering/ through dev-kiro-config.

### Task 1.1: Create design-and-spec skill

**Files:**
- Create: `skills/design-and-spec/SKILL.md`

- [ ] **Step 1: Read source skills**

Read these three skills to extract content:
- `skills/brainstorming/SKILL.md`
- `skills/spec-workflow/SKILL.md`
- `skills/critical-thinking/SKILL.md`

- [ ] **Step 2: Create the merged skill**

Create `skills/design-and-spec/SKILL.md` following the structure defined
in the spec (Phase 1 → design-and-spec skill structure):
- Frontmatter: name, description with both trigger sets
- Two entry modes: exploratory and directed
- Assumption challenging phase (from critical-thinking)
- Convergence to spec writing and writing-plans handoff
- HARD GATE: no implementation until design approved
- Key content preserved from each source skill

- [ ] **Step 3: Verify frontmatter is valid YAML**

- [ ] **Step 4: Report completion**

### Task 1.2: Create post-implementation skill

**Files:**
- Create: `skills/post-implementation/SKILL.md`

- [ ] **Step 1: Create the skill**

Create `skills/post-implementation/SKILL.md` with the full workflow from
the spec (Phase 3):
- Frontmatter: name, description mentioning "triggers when orchestrator
  receives DONE from implementation subagent"
- Document tracking rules (checkbox updates, plan divergence, task enrichment)
- Quality gate with project-type detection
- Doc staleness check
- Auto-review dispatch
- Review findings handling (max 3 retry loops)
- Improvement capture with entry format
- Result presentation

- [ ] **Step 2: Verify frontmatter is valid YAML**

- [ ] **Step 3: Report completion**

### Task 1.3: Delete old skills

**Files:**
- Delete: `skills/brainstorming/SKILL.md`
- Delete: `skills/spec-workflow/SKILL.md`
- Delete: `skills/critical-thinking/SKILL.md`
- Delete: `skills/meta-review/SKILL.md`
- Delete: `skills/delegation-protocol/SKILL.md`
- Delete: `skills/aggregation/SKILL.md`
- Delete: `skills/research-practices/SKILL.md`
- Delete: `skills/context-docs/SKILL.md`
- Delete: `skills/project-architecture/SKILL.md`

- [ ] **Step 1: Delete skill files and directories**

```bash
rm -r skills/brainstorming skills/spec-workflow skills/critical-thinking \
  skills/meta-review skills/delegation-protocol skills/aggregation \
  skills/research-practices skills/context-docs skills/project-architecture
```

Note: This requires the rm safety changes from Spec 1, or manual deletion.
If Spec 1 hasn't been implemented yet, delete manually or use git rm.

- [ ] **Step 2: Verify only 12 skill directories remain**

```bash
ls -d skills/*/  | wc -l
```
Expected: 12 (design-and-spec, post-implementation, writing-plans,
execution-planning, subagent-driven-development, dispatching-parallel-agents,
codebase-audit, agent-audit, trace-code, explain-code, commit, push)

- [ ] **Step 3: Report completion**

### Task 1.4: Update orchestrator resources

**Files:**
- Modify: `agents/dev-orchestrator.json`

- [ ] **Step 1: Replace skill resources list**

Replace the entire `resources` array skill entries with the new 12-skill list:
```json
"skill://~/.kiro/skills/design-and-spec/SKILL.md",
"skill://~/.kiro/skills/writing-plans/SKILL.md",
"skill://~/.kiro/skills/execution-planning/SKILL.md",
"skill://~/.kiro/skills/subagent-driven-development/SKILL.md",
"skill://~/.kiro/skills/dispatching-parallel-agents/SKILL.md",
"skill://~/.kiro/skills/post-implementation/SKILL.md",
"skill://~/.kiro/skills/codebase-audit/SKILL.md",
"skill://~/.kiro/skills/agent-audit/SKILL.md",
"skill://~/.kiro/skills/trace-code/SKILL.md",
"skill://~/.kiro/skills/explain-code/SKILL.md",
"skill://~/.kiro/skills/commit/SKILL.md",
"skill://~/.kiro/skills/push/SKILL.md"
```

Keep steering and knowledge base resources unchanged.

- [ ] **Step 2: Verify JSON is valid and skill count is 12**

```bash
jq empty agents/dev-orchestrator.json
jq '[.resources[] | select(type == "string") | select(startswith("skill://"))] | length' agents/dev-orchestrator.json
```
Expected: valid, 12

- [ ] **Step 3: Report completion**

> ⚠️ **Note:** The orchestrator resources list changed. New skills (design-and-spec,
> post-implementation) won't be available until next session. However, you can
> continue with Phases 2-6 in this session because those phases modify existing
> files — they don't need the new skills to be loaded. The new skills will be
> tested in the Phase 6 verification step, which should be done in a fresh session.

---

## Phase 2: Orchestrator prompt rewrite

### Task 2.1: Rewrite orchestrator prompt

**Files:**
- Modify: `agents/prompts/orchestrator.md`

- [ ] **Step 1: Read the current prompt and the spec's Phase 2 section**

Read both files to understand what exists and what the target structure is.

- [ ] **Step 2: Rewrite the prompt**

Follow the spec's Phase 2 structure (7 sections, ~130 lines target):
1. Identity (~10 lines) — must include post-implementation trigger rule
2. Routing table (~40 lines) — all agent lanes including refactor pipeline
3. Workflow definitions (~30 lines) — implementation + refactor pipelines
4. Delegation format (~15 lines) — 5-section briefing from delegation-protocol
5. Result presentation (~10 lines) — from aggregation
6. Improvement capture (~10 lines) — trigger conditions + entry format
7. Plan file convention (~10 lines) — docs/specs/ structure + tracking rules

Key rules that MUST be in the prompt (from spec):
- "After ANY implementation subagent returns DONE, execute post-implementation workflow"
- "Max 3 retry loops before escalating to user"
- Improvement capture entry format
- Document tracking: update checkboxes, record divergences

- [ ] **Step 3: Verify line count**

```bash
wc -l agents/prompts/orchestrator.md
```
Expected: under 150 lines

- [ ] **Step 4: Report completion**

---

## Phase 3: Skill rewrites

### Task 3.1: Rewrite codebase-audit skill

**Files:**
- Modify: `skills/codebase-audit/SKILL.md`

- [ ] **Step 1: Read current skill and spec Phase 4**

- [ ] **Step 2: Rewrite with structured output**

Add to the skill:
- Project-type detection (pyproject.toml, package.json, *.sh)
- Structured findings format (category, location, severity, effort, agent)
- Doc health section (link checking, spec-to-code alignment, age checking)
- Scope limits for large codebases (depth 3, prioritize recent changes, cap 20 findings)

- [ ] **Step 3: Report completion**

### Task 3.2: Rewrite agent-audit skill

**Files:**
- Modify: `skills/agent-audit/SKILL.md`

- [ ] **Step 1: Read current skill, meta-review skill, and spec Phase 5**

- [ ] **Step 2: Rewrite absorbing meta-review**

Add to the skill:
- Skill coverage analysis (from meta-review)
- Steering effectiveness check (from meta-review)
- Knowledge hygiene (from meta-review)
- Routing review (from meta-review)
- improvements/pending.md integration (read, cross-reference, propose fixes)
- Cross-project awareness via improvements data

- [ ] **Step 3: Report completion**

### Task 3.3: Enhance commit skill

**Files:**
- Modify: `skills/commit/SKILL.md`

- [ ] **Step 1: Read current skill and spec Phase 6**

- [ ] **Step 2: Add doc reference check**

Add step before committing:
```
For each staged file:
  - grep docs/ for references to that file
  - if a doc references the file but the doc is NOT staged → warn
```

- [ ] **Step 3: Report completion**

### Task 3.4: Update subagent-driven-development skill

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`

- [ ] **Step 1: Add document tracking steps**

After each task completion, add mandatory steps:
- Update plan file: `- [ ]` → `- [x]` for completed task
- If task diverged from plan, append "Actual:" note
- If task description was enriched before dispatch, update plan with enriched version

- [ ] **Step 2: Add task enrichment step**

Before dispatching each task:
- Re-read task description from plan file
- Enrich with context from earlier tasks
- Update plan file with enriched description if changed

- [ ] **Step 3: Report completion**

### Task 3.5: Update execution-planning skill

**Files:**
- Modify: `skills/execution-planning/SKILL.md`

- [ ] **Step 1: Add stage completion tracking**

After each stage completes, update the execution plan file to mark it done.

- [ ] **Step 2: Report completion**

---

## Phase 4: Agent prompt upgrades

### Task 4.1: Upgrade dev-refactor prompt

**Files:**
- Modify: `agents/prompts/refactor.md`
- Modify: `agents/dev-refactor.json`

- [ ] **Step 1: Add TDD skill to dev-refactor resources**

In `agents/dev-refactor.json`, add:
```json
"skill://~/.kiro/skills/test-driven-development/SKILL.md"
```

- [ ] **Step 2: Add execute-findings mode to prompt**

Add the "When receiving findings from a review" section from the spec (Phase 7).

- [ ] **Step 3: Add shared code awareness to prompt**

Add the "DRY and shared code" section from the spec (Phase 7).

- [ ] **Step 4: Report completion**

### Task 4.2: Upgrade dev-reviewer prompt

**Files:**
- Modify: `agents/prompts/code-reviewer.md`

- [ ] **Step 1: Add codebase scan mode**

Add the scan mode section from the spec (Phase 8) with scope limits.

- [ ] **Step 2: Add doc accuracy review dimension**

Add dimension 10: Documentation accuracy.

- [ ] **Step 3: Report completion**

---

## Phase 5: Framework improvements + documentation

### Task 5.1: Add subagent tool limitations to rules.md

**Files:**
- Modify: `knowledge/rules.md`

- [ ] **Step 1: Add quick-ref rule**

Add under `[subagent,delegate,spawn]`:
```markdown
- 🔴 Subagent tool limitations quick-ref: subagents CANNOT use web_search, web_fetch, use_aws, grep, glob, introspect. They CAN use read, write, shell, code, and MCP tools. If a task needs unavailable tools, gather data in the orchestrator first.
```

- [ ] **Step 2: Report completion**

### Task 5.2: Update creating-agents.md

**Files:**
- Modify: `docs/reference/creating-agents.md`

- [ ] **Step 1: Add domain-specific agent design patterns section**

Add section covering:
- Analyst/auditor/collector separation
- Structured JSON contracts between agents
- Retry-with-feedback loops
- Cross-language agents (reviewer, refactor) vs. language-specific
- Project-local agents (dev-kiro-config pattern)

- [ ] **Step 2: Update architecture diagram**

Update the agent tree to show current lineup including dev-kiro-config.

- [ ] **Step 3: Report completion**

### Task 5.3: Update skill-catalog.md

**Files:**
- Modify: `docs/reference/skill-catalog.md`

- [ ] **Step 1: Full rewrite of skill tables**

Update:
- Skill count (12, not 24)
- Workflow chain diagram (design-and-spec → writing-plans → execution-planning → subagent-driven-development)
- Skills by category tables (new skills, removed skills, merged skills)
- Agent assignment matrix
- Add "Automated workflows" section (implementation pipeline, refactor pipeline)

- [ ] **Step 2: Report completion**

### Task 5.4: Update README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update counts**

Update skill count, agent count, steering doc count to match reality.

- [ ] **Step 2: Report completion**

### Task 5.5: Update docs/TODO.md

**Files:**
- Modify: `docs/TODO.md`

- [ ] **Step 1: Mark Spec 2 items as complete**

Update all Spec 2 line items to `[x]`.

- [ ] **Step 2: Report completion**

### Task 5.6: Commit Phases 1-5 and restart for verification

- [ ] **Step 1: Commit Phases 1-5 on feature branch**

```bash
git add skills/ agents/ knowledge/ docs/ README.md
git commit -m "feat: orchestrator framework redesign — skill consolidation, prompt rewrite, automation"
git push origin feature/framework-redesign
```

- [ ] **Step 2: Exit session for verification**

Tell user: **"Phases 1-5 committed on `feature/framework-redesign`. Run `/quit` now. New session prompt:**
```
Run Phase 6 verification from docs/specs/2026-04-16-orchestrator-agent-framework-redesign/plan.md. Then merge feature/framework-redesign to main. Then implement docs/specs/2026-04-16-typescript-frontend-stack/spec.md and plan.md — Phases 1 and 2.
```
**"**

⛔ **STOP HERE. Phase 6 must run in a fresh session** so all new skills
and config changes are loaded.

---

## Phase 6: Final verification

### Task 6.1: Run agent-audit

- [ ] **Step 1: Run the updated agent-audit skill**

Trigger: "audit agents"

Verify:
- All agent JSON configs are consistent (deny lists, tools, allowedTools)
- All skill resources in agent configs point to existing files
- No orphaned skills on disk
- Skill catalog matches reality
- README counts are accurate

- [ ] **Step 2: Fix any findings**

- [ ] **Step 3: Push branch and report**

```bash
git add -A
git commit -m "fix: address agent-audit findings" # if there were fixes
git push origin feature/framework-redesign
```

Tell user: **"Spec 2 complete on `feature/framework-redesign`. All phases
committed and pushed. Review the branch, merge to main when ready, then
`ship it` for a versioned release."**

Spec 2 is complete.

- [ ] **Step 4: Report completion**
