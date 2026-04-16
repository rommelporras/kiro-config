# Spec 2: Orchestrator & Agent Framework Redesign

> Status: Approved
> Created: 2026-04-16
> Depends on: Spec 1 (file operations routing lane)
> Unblocks: Spec 3 (new agents need the redesigned framework)

## Purpose

The orchestrator has grown organically to 19 skills, a 250+ line prompt, and
workflow rules that get ignored because they're buried in the middle of the
prompt. Key automation (auto-review after implementation, refactor pipelines,
doc staleness checks) exists in the prompt but doesn't fire in practice.

This spec redesigns the orchestrator for reliability: shorter prompt, fewer
skills, automated workflows that actually trigger, and a continuous improvement
loop that captures friction for later fixes.

## Scope

### In scope

- Orchestrator prompt rewrite
- Skill consolidation (19 → 12)
- New post-implementation skill
- Codebase-audit rewrite
- Agent-audit rewrite (absorb meta-review)
- Commit skill enhancement
- dev-refactor and dev-reviewer prompt upgrades
- Delegation-protocol and aggregation folded into prompt
- `docs/improvements/` structure for friction capture
- Framework: project-aware quality gate, pre-dispatch hook
- Documentation updates (creating-agents.md, skill-catalog.md)

### Out of scope

- New language agents (Spec 3)
- New steering docs for TypeScript/frontend (Spec 3)
- Shell safety changes (Spec 1)
- Hook infrastructure changes (feedback hooks stay as-is)

## Design

### Phase 0: kiro-config self-modification permissions

#### Model strategy

Set explicit models on all agents to stop manual model switching:

| Agent | Model | Rationale |
|---|---|---|
| dev-orchestrator | `claude-opus-4.6` | Holds full session context, complex workflow rules, routing decisions. Needs 1M context window. |
| All subagents | `claude-sonnet-4.6` | Receive scoped briefings (<200k context). Cost-effective for implementation tasks. |
| base | `null` (default) | Fallback agent, uses Kiro default. |

Update `dev-orchestrator.json`: change `"model": null` to `"model": "claude-opus-4.6"`.
All subagent configs already have `"model": "claude-sonnet-4.6"` — no change needed.
New agents (dev-kiro-config, dev-typescript, dev-frontend) use `"claude-sonnet-4.6"`.

#### Problem

All agents have `~/.kiro/agents`, `~/.kiro/hooks`, `~/.kiro/steering` in
`fs_write.deniedPaths`. Since `~/.kiro/` is symlinked to
`~/personal/kiro-config/`, no agent can write to `agents/`, `hooks/`, or
`steering/` — even when deliberately working on kiro-config.

#### Solution: project-local subagent

Create `dev-kiro-config` — a project-local subagent that lives in
`~/personal/kiro-config/.kiro/agents/dev-kiro-config.json`. It only exists
in this repo and has elevated write permissions for kiro-config files.

The global orchestrator delegates kiro-config editing work to this agent.
The orchestrator itself stays locked down.

#### Agent config

```json
{
  "name": "dev-kiro-config",
  "description": "Edits kiro-config agent configs, prompts, hooks, steering, and skills. Project-local — only available in the kiro-config repo.",
  "prompt": "file://../../agents/prompts/docs.md",
  "model": "claude-sonnet-4.6",
  "tools": ["read", "write", "shell", "code"],
  "allowedTools": ["read", "write", "code"],
  "toolsSettings": {
    "fs_write": {
      "allowedPaths": [
        "~/personal/kiro-config/**"
      ],
      "deniedPaths": [
        "~/.ssh",
        "~/.aws",
        "~/.gnupg",
        "~/.config/gh",
        "~/.kiro/settings/cli.json"
      ]
    },
    "execute_bash": {
      "autoAllowReadonly": true,
      "deniedCommands": [
        "rm .*",
        "git push.*",
        "git push",
        "git add.*",
        "git commit.*"
      ]
    }
  },
  "resources": [
    "file://~/.kiro/steering/**/*.md",
    "skill://~/.kiro/skills/verification-before-completion/SKILL.md"
  ],
  "includeMcpJson": false
}
```

Key differences from dev-docs:
- `allowedPaths`: `~/personal/kiro-config/**` (covers agents/, hooks/, steering/, skills/)
- `deniedPaths`: does NOT include `~/.kiro/agents`, `~/.kiro/hooks`, `~/.kiro/steering`
- Reuses the dev-docs prompt (same role — edit text files, not code)

#### Orchestrator changes

Add `dev-kiro-config` to global `availableAgents` and `trustedAgents` in
`dev-orchestrator.json`. Add routing rule to orchestrator prompt:

```
### → dev-kiro-config

Triggers: edit agent config, update prompt, modify hook, update steering,
edit skill, kiro-config change

Route when: The task involves editing kiro-config files (agents/, hooks/,
steering/, skills/). This agent is project-local — only available when
working in the kiro-config repo. If not available, fall back to dev-docs
or handle directly via shell.
```

#### Files to create

| File | Purpose |
|---|---|
| `.kiro/agents/dev-kiro-config.json` | Project-local subagent with elevated permissions |

#### Files to modify

| File | Change |
|---|---|
| `agents/dev-orchestrator.json` | Add dev-kiro-config to availableAgents + trustedAgents |
| `agents/prompts/orchestrator.md` | Add dev-kiro-config routing lane |

#### Session boundary

Kiro loads agents at session start. After Phase 0 is committed:
1. Commit all Phase 0 changes
2. **Exit the session** (`/quit`)
3. Start a new session — dev-kiro-config will now be available
4. Verify: the orchestrator should be able to dispatch to dev-kiro-config
5. Continue with Phase 1+

Phases 1-11 CANNOT proceed in the same session as Phase 0. The new agent
must be loaded by starting a fresh session.

This also applies to any phase that creates new skills — if a new skill
is created (e.g., design-and-spec, post-implementation), it won't be
available to the orchestrator until the next session. Plan implementation
order accordingly:
- Phase 0: create dev-kiro-config → commit → new session
- Phases 1-8: implementation work (dev-kiro-config available)
- If new skills are created in Phase 1, they're available immediately
  to the orchestrator because skills are loaded from disk at activation
  time (lazy-loaded), not at session start — BUT the orchestrator's
  resources list in dev-orchestrator.json must reference them, and that
  JSON change requires a session restart to take effect
- So: update dev-orchestrator.json resources early, commit, restart if needed

### Phase 1: Skill consolidation

#### Merges

| From | To | Rationale |
|---|---|---|
| brainstorming + spec-workflow | design-and-spec | Both produce specs, both ask questions, both hand off to writing-plans. Merge into one skill with two entry modes: exploratory ("brainstorm") and directed ("spec out"). |
| meta-review → agent-audit | agent-audit (expanded) | 80% overlap. Both analyze kiro-config effectiveness. Agent-audit gains: skill coverage analysis, steering effectiveness, knowledge hygiene, routing review. |
| critical-thinking → design-and-spec | design-and-spec (phase) | Critical thinking is a mode during design, not a standalone skill. Design-and-spec challenges assumptions as part of the design process. |

**design-and-spec skill structure:**

The merged skill has two entry modes that converge:

```
Entry mode detection:
  "brainstorm", "let's think about", "I'm leaning toward" → Exploratory mode
  "spec out", "define requirements", "write a spec" → Directed mode

Exploratory mode:
  1. Explore project context (read files, docs, commits)
  2. Open discussion — present partial designs, iterate
  3. Propose 2-3 approaches when there's a fork in the road
  4. Challenge assumptions (from critical-thinking): before presenting
     a design, list 3 assumptions being made and question each
  5. Converge: "Ready to formalize into a spec, or keep exploring?"

Directed mode:
  1. Explore project context
  2. Ask clarifying questions (one at a time, prefer multiple choice)
  3. Propose 2-3 approaches with trade-offs
  4. Challenge assumptions (same as above)
  5. Present design in sections, get approval per section

Both modes converge to:
  6. Write spec to docs/specs/YYYY-MM-DD-<topic>/spec.md
  7. User reviews spec
  8. Hand off to writing-plans (terminal state — no other skill)
```

Key content preserved from each source skill:
- From brainstorming: collaborative mode, one-question-at-a-time, YAGNI
- From spec-workflow: phased structure (requirements → design → tasks)
- From critical-thinking: assumption challenging as a design phase step
- HARD GATE preserved: no implementation until design is approved

#### Fold into orchestrator prompt

| Skill | Rationale |
|---|---|
| delegation-protocol | 5-section briefing template is prompt-level instruction. Always needed, shouldn't be lazy-loaded. |
| aggregation | Result presentation format is prompt-level instruction. Always needed. |

#### Remove as standalone skills

| Skill | Replacement |
|---|---|
| research-practices | Orchestrator does this conversationally. Agent-audit can suggest "research X" in its report. |
| context-docs | Orchestrator suggests creating docs/context/ when entering a project without it. Not a skill. |
| project-architecture | Codebase-audit surfaces structural issues. Orchestrator handles restructuring conversationally. |

#### Final skill list (12)

| Skill | Type | Trigger |
|---|---|---|
| design-and-spec | Chain | "brainstorm", "spec out", "let's design", "define requirements" |
| writing-plans | Chain | Internal — after design-and-spec |
| execution-planning | Chain | Internal — before dispatching multi-task work |
| subagent-driven-development | Chain | Internal — executing plans via delegates |
| dispatching-parallel-agents | Coordination | Internal — parallel dispatch |
| post-implementation | Automation | Internal — after subagent returns DONE |
| codebase-audit | Standalone + auto | "health check", "codebase audit" + auto before refactor pipeline |
| agent-audit | Standalone | "audit agents", "review config", "what can we improve" |
| trace-code | Standalone | "trace this", "map the code flow" |
| explain-code | Standalone | "explain this", "how does this work" |
| commit | Git operation | "commit these changes" |
| push | Git operation | "push" |

### Phase 2: Orchestrator prompt rewrite

#### Structure (priority order — most important first)

1. **Identity** (~10 lines) — what you are, what you do, what you never do
   - Must include: "never write code", "delegate implementation", "manage git"
   - Must include: "after any subagent returns DONE, run post-implementation workflow"
2. **Routing table** (~40 lines) — pattern matching for agent dispatch, including workflows
   - Must include: all agent routing lanes with trigger words
   - Must include: refactor pipeline as a composite route
   - Must include: dev-kiro-config route (with fallback when unavailable)
3. **Workflow definitions** (~30 lines) — implementation pipeline, refactor pipeline
   - Must include: exact step sequence for each workflow
   - Must include: max 3 retry loops before escalating to user
4. **Delegation format** (~15 lines) — the 5-section briefing template (from delegation-protocol)
   - Must include: objective, context (file paths), constraints, definition of done, skill triggers
5. **Result presentation** (~10 lines) — how to present subagent results (from aggregation)
   - Must include: status, file list, concerns, next steps
6. **Improvement capture** (~10 lines) — when to log friction to docs/improvements/pending.md
   - Must include: trigger conditions (retries, corrections, missing context)
   - Must include: entry format
7. **Plan file convention** (~10 lines) — where specs and plans live
   - Must include: docs/specs/ structure, tracking doc update rules

Target: ~130 lines, down from ~250. Procedural details move to skills.

#### Routing table additions

```
### → Refactor pipeline (reviewer → user approval → refactor → reviewer)

Triggers: refactor, clean up, DRY, reduce duplication, simplify codebase,
remove dead code, God object, split this

Route when: User wants codebase-wide improvements. Run codebase-audit first,
then reviewer for deep analysis, present findings, dispatch refactor on
approved items, final reviewer check.

### → Handle directly (file operations)

Triggers: move file, rename file, delete file, organize files

Handle when: File move/rename/delete operations. Execute directly.
Confirm with user for rm -rf on directories.
```

#### Workflow definitions (in prompt, not skills)

**Implementation workflow:**
```
Subagent returns DONE → post-implementation skill activates automatically
```

**Refactor workflow:**
```
User requests refactor → codebase-audit (auto) → dev-reviewer (scan) →
present findings → user approves → dev-refactor (execute) →
dev-reviewer (final check) → present results
```

#### Improvement capture rule (in prompt)

```
When you observe friction during a session — retries, routing corrections,
missing context, subagent failures — append a brief entry to
~/personal/kiro-config/docs/improvements/pending.md with:
- Date and project path
- What went wrong
- Suggested fix (steering gap, routing issue, missing skill, etc.)
```

### Phase 3: Post-implementation skill (NEW)

**Trigger mechanism:** Skills activate on description matching, not on
subagent events. The post-implementation skill is triggered by an explicit
rule in the orchestrator prompt:

```
After ANY implementation subagent (dev-python, dev-typescript, dev-shell,
dev-refactor) returns DONE or DONE_WITH_CONCERNS, execute the
post-implementation workflow before presenting results to the user.
This is not optional. Do not skip it. Do not ask the user.
```

The skill provides the procedure. The orchestrator prompt provides the trigger.
The skill description should include: "Triggers when the orchestrator receives
DONE from an implementation subagent."

#### Document tracking (applies to all steps below)

After completing any task, phase, or stage, the orchestrator MUST update
the tracking documents immediately — not at the end, not when asked:

- Plan file: `- [ ]` → `- [x]` for completed tasks
- Spec acceptance criteria: `- [ ]` → `- [x]` for verified criteria
- Execution plan: mark completed stages
- `docs/TODO.md`: mark spec complete when all acceptance criteria pass

#### Plan divergence and task enrichment

Plans are living documents. The orchestrator MUST keep them accurate:

**Before dispatching each task:**
- Re-read the task description in the plan file
- Enrich it with context discovered from earlier tasks (new file paths,
  API signatures, config values, gotchas encountered)
- If the task description is too vague for a subagent to succeed, update
  the plan file with the enriched description BEFORE dispatching
- The plan file should always reflect what the subagent actually receives

**When implementation diverges from the plan:**
- If a task was done differently than planned, update the task description
  to reflect what actually happened (append a "Actual:" note)
- If a task was skipped or reordered, note why in the plan file
- If new tasks were added mid-implementation, add them to the plan file
- If the approach changed fundamentally, update the plan's architecture
  section — don't leave a plan that describes a different system

The plan file is the single source of truth for "what happened." Someone
reading it after implementation should understand both the intent and the
reality.

This also applies to the subagent-driven-development and execution-planning
skills — add explicit "update tracking docs" steps to both.

#### Workflow

```
Step 1: Quality gate
  - Detect project type from config files:
    pyproject.toml → Python (ruff check, ruff format --check, mypy, pytest)
    package.json → TypeScript (eslint, tsc --noEmit, vitest)
    *.sh files changed → Shell (shellcheck on changed .sh files)
  - Mixed projects (both pyproject.toml and package.json): run all applicable
  - No config files found: skip automated quality gate, warn user:
    "No pyproject.toml or package.json found — skipping automated quality checks.
    Consider adding a quality gate config."
  - Run appropriate quality commands
  - If failures → send back to implementer with specific error output
    (include the full command output, not just "tests failed")

Step 2: Doc staleness check
  - For each file modified by the implementer, grep docs/ for references
  - If any doc references a modified file, flag it
  - If staleness found → dispatch dev-docs to update, or flag for user

Step 3: Auto-review
  - Dispatch dev-reviewer with:
    - Files created/modified
    - What the implementation does
    - Implementer's concerns (if any)
  - Wait for verdict

Step 4: Handle review findings
  - CRITICAL → send back to implementer with fix list, loop (max 3 attempts —
    if implementer fails 3 times on the same finding, stop and surface to user:
    "Implementer couldn't resolve this after 3 attempts. Manual intervention needed.")
  - IMPORTANT → present to user, ask if they want fixes
  - SUGGESTIONS → include in summary
  - APPROVE → proceed

Step 5: Improvement capture
  - Did retries > 1? Log cause
  - Did routing get corrected? Log mismatch
  - Was context missing? Log what was needed
  - Append to ~/personal/kiro-config/docs/improvements/pending.md
    (accessible from any project — orchestrator's allowedPaths includes ~/personal/**)
  - Entry format:
    ```
    ## YYYY-MM-DD — session in <project path>

    ### <Category>: <short title>
    - What happened: <description>
    - Root cause: <steering gap | routing issue | missing skill | missing context>
    - Suggested fix: <specific action>
    ```
  - If the file doesn't exist or path is inaccessible, log to
    orchestrator's conversation instead — don't fail silently

Step 6: Present results
  - Summary of changes (files, key decisions)
  - Review verdict and findings
  - Doc staleness warnings (if any)
  - Concerns from implementer or reviewer
  - Next steps
```

### Phase 4: Codebase-audit rewrite

#### Current state
Generic health check with no structured output.

#### New capabilities

**Project-type detection:**
- `pyproject.toml` → Python project (run ruff, mypy, pytest, bandit)
- `package.json` → TypeScript/Node project (run eslint, tsc, vitest)
- `*.sh` files → Shell scripts (run shellcheck)
- Mixed → run all applicable

**Structured findings output:**
Each finding includes:
- Category: DRY violation | God object | stale test | dead code | dependency issue | structural problem | doc staleness
- Location: file:line
- Severity: high | medium | low
- Effort: small (< 30 min) | medium (1-2 hrs) | large (half day+)
- Agent: which agent would fix this (dev-python, dev-typescript, dev-refactor, dev-docs)

**Doc health section (new):**
- Check all internal links in docs/ resolve to existing files
- Check if specs in docs/specs/ have corresponding implemented code
- Check if docs/context/ files reference current file paths
- Flag docs not updated in 30+ days that reference actively-changing code
- Cross-reference README counts (skills, agents, steering) against actual

**Output feeds refactor pipeline:**
When codebase-audit runs as part of the refactor pipeline, its structured
output becomes the input for dev-reviewer's deep analysis and dev-refactor's
execution list.

### Phase 5: Agent-audit rewrite

#### Absorb from meta-review

- Skill coverage: are trigger descriptions matching real user phrasing?
- Steering effectiveness: are rules too vague? outdated?
- Knowledge hygiene: episodes → rules promotion candidates, stale rules
- Routing review: dead routes, overlapping triggers, missing patterns

#### New: improvements/pending.md integration

- Read `docs/improvements/pending.md` as primary input
- Cross-reference friction data against config files
- Produce actionable proposals: "add X to Y.md", "update routing trigger Z"
- After user approves fixes, move resolved items to `docs/improvements/resolved.md`

#### New: cross-project awareness

When run from kiro-config, also check:
- Read `docs/improvements/pending.md` for friction entries from other projects —
  these entries include the project path, so agent-audit can identify patterns
  like "3 entries from ~/eam/eam-sre mention TypeScript but no typescript.md
  steering doc exists"
- Check if steering docs cover languages mentioned in improvement entries
- Check if routing corrections in improvement entries suggest missing routes
- Do NOT scan ~/eam/ or ~/personal/ directories directly — use the
  improvements/pending.md data as the signal source

### Phase 6: Commit skill enhancement

Add doc reference check before committing:

```
For each staged file:
  - grep docs/ for references to that file
  - if a doc references the file but the doc is NOT staged → warn:
    "docs/context/Tools.md references scripts/collect-all.py which was
    modified but the doc wasn't updated. Continue anyway?"
```

### Phase 7: dev-refactor upgrade

#### Add TDD skill
dev-refactor currently has: verification, receiving-code-review.
Add: test-driven-development.

Refactoring must update tests alongside code. The TDD skill ensures:
- Run tests before refactoring (green baseline)
- After each refactoring move, run tests (still green)
- Update stale tests that test old structure
- Remove orphaned tests for deleted code

#### "Execute findings" mode

dev-refactor's prompt gets a new section:

```
## When receiving findings from a review

You receive a prioritized list of findings from dev-reviewer. For each:
1. Read the finding (file, line, what's wrong, suggested fix)
2. Understand the surrounding code context
3. Apply the fix
4. Run tests — must still pass
5. Move to next finding

Do NOT re-analyze the codebase. The analysis is done. Execute the fixes.
Report DONE_WITH_CONCERNS if a finding can't be fixed without changing
behavior.
```

#### Shared code awareness

Add to dev-refactor prompt:

```
## DRY and shared code

When fixing DRY violations:
- Look for existing shared modules before creating new ones
- If no shared module exists, create one in the appropriate location
  (utils/, shared/, common/ — follow project convention)
- Update all call sites to use the shared code
- Verify no circular imports are introduced
```

### Phase 8: dev-reviewer upgrade

#### Codebase scan mode

Add to dev-reviewer prompt:

```
## Codebase scan mode

When briefed with "scan this codebase" or "analyze this directory":
- Read source files in the target path (max depth 3, skip node_modules/,
  .venv/, __pycache__/, dist/, build/, .git/)
- For large codebases (>50 source files), prioritize:
  1. Files with recent git changes (last 30 days)
  2. Files over 300 lines (likely complexity hotspots)
  3. Files with no corresponding test file
- Apply structural quality checks to each file
- Produce a prioritized findings report (same format as single-file review)
- Group findings by category (DRY, God objects, complexity, etc.)
- Include effort estimates per finding
- Cap report at 20 findings — if more exist, note "N additional findings
  omitted, run targeted review on specific directories for more"
```

#### Doc accuracy review dimension

Add to review dimensions:

```
10. **Documentation** — Do docs referencing this code still accurately
    describe its behavior? Are there stale examples, wrong flag names,
    outdated file paths?
```

### Phase 9: Framework improvements

#### Project-aware quality gate

The post-implementation skill detects project type and runs the right
commands. But the orchestrator prompt's "run full quality suite" instruction
is generic. Replace with:

```
Quality suite is project-specific. Detect from config files:
- pyproject.toml → uv run ruff check . && uv run ruff format --check . && uv run mypy . && uv run pytest tests/ -q
- package.json → npm run lint && npm run typecheck && npm test
- Shell scripts → shellcheck scripts/*.sh hooks/*.sh
- kiro-config → shellcheck hooks/*.sh hooks/**/*.sh
```

#### Pre-dispatch prerequisite check

Before dispatching a subagent, the orchestrator prompt includes a check:

```
Before dispatching any implementation subagent, verify:
1. If the task involves Python: check `pyproject.toml` exists in the project
2. If the task involves TypeScript: check `package.json` exists in the project
3. If the task involves AWS: run `aws sts get-caller-identity` to verify auth

If a check fails, tell the user what's missing before dispatching.
Do not dispatch a subagent into a project that isn't set up for the work.
```

This is a prompt instruction, not a shell hook. Shell hooks can't inspect
the task intent. If the prompt instruction proves unreliable (orchestrator
skips it), convert the auth check to an agentSpawn hook in a future iteration.

### Phase 10: Documentation updates

#### creating-agents.md

Add section: "Domain-specific agent design patterns"
- Analyst/auditor/collector separation
- Structured JSON contracts between agents
- Retry-with-feedback loops
- Cross-language agents (reviewer, refactor) vs. language-specific agents

#### skill-catalog.md

- Update skill count and matrix
- Add "multi-agent pipeline" section documenting the implementation and
  refactor workflows
- Update trigger descriptions for merged/removed skills
- Add workflow chain diagram reflecting new skill structure

#### docs/improvements/ structure

Create:
- `docs/improvements/pending.md` — auto-captured friction from sessions
- `docs/improvements/resolved.md` — addressed items (audit trail)

### Phase 11: Update docs/TODO.md

Remove completed/dropped items:
- [x] finishing-a-development-branch skill (project-local, not global)
- [x] Pipeline agent pattern skill (removed)
- [x] dev-web evaluation (resolved: dev-typescript + dev-frontend)
- [x] Subagent tool limitations quick-ref (added to rules.md)
- [x] Post-implementation quality gate: make project-aware
- [x] Pre-dispatch hook
- [x] Update creating-agents.md
- [x] Add multi-agent pipeline section to skill-catalog.md
- [x] web-development.md steering doc (moved to Spec 3)

## Files to create

| File | Purpose |
|---|---|
| `.kiro/agents/dev-kiro-config.json` | Project-local subagent with elevated kiro-config write permissions |
| `skills/design-and-spec/SKILL.md` | Merged brainstorming + spec-workflow + critical-thinking |
| `skills/post-implementation/SKILL.md` | Auto-review, quality gate, doc staleness, improvement capture |
| `docs/improvements/pending.md` | Friction capture from sessions |
| `docs/improvements/resolved.md` | Addressed items audit trail |

## Files to modify

| File | Change |
|---|---|
| `agents/prompts/orchestrator.md` | Full rewrite — shorter, workflows front-loaded |
| `agents/dev-orchestrator.json` | Update resources (skill list changes) |
| `skills/codebase-audit/SKILL.md` | Rewrite — structured output, project detection, doc health |
| `skills/agent-audit/SKILL.md` | Rewrite — absorb meta-review, improvements/pending.md integration |
| `skills/commit/SKILL.md` | Add doc reference check |
| `skills/subagent-driven-development/SKILL.md` | Add mandatory "update plan checkboxes" step after each task |
| `skills/execution-planning/SKILL.md` | Add mandatory "update execution plan" step after each stage |
| `agents/prompts/refactor.md` | Add execute-findings mode, shared code awareness |
| `agents/dev-refactor.json` | Add TDD skill to resources |
| `agents/prompts/code-reviewer.md` | Add codebase scan mode, doc accuracy dimension |
| `knowledge/rules.md` | Add subagent tool limitations quick-ref |
| `docs/reference/creating-agents.md` | Add domain-specific patterns section |
| `docs/reference/skill-catalog.md` | Full update — new counts, matrix, workflows |
| `README.md` | Update skill/agent counts |
| `docs/TODO.md` | Mark completed items |

## Files to delete

| File | Reason |
|---|---|
| `skills/brainstorming/SKILL.md` | Merged into design-and-spec |
| `skills/spec-workflow/SKILL.md` | Merged into design-and-spec |
| `skills/critical-thinking/SKILL.md` | Folded into design-and-spec |
| `skills/meta-review/SKILL.md` | Absorbed into agent-audit |
| `skills/delegation-protocol/SKILL.md` | Folded into orchestrator prompt |
| `skills/aggregation/SKILL.md` | Folded into orchestrator prompt |
| `skills/research-practices/SKILL.md` | Removed — orchestrator handles conversationally |
| `skills/context-docs/SKILL.md` | Removed — orchestrator suggests when appropriate |
| `skills/project-architecture/SKILL.md` | Removed — codebase-audit surfaces issues |

## Acceptance criteria

- [ ] dev-kiro-config agent exists in .kiro/agents/ and can write to agents/, hooks/, steering/, skills/
- [ ] dev-orchestrator.json model set to claude-opus-4.6 (no more manual model switching)
- [ ] Orchestrator routes kiro-config editing tasks to dev-kiro-config when available
- [ ] Orchestrator falls back gracefully when dev-kiro-config is not available (other projects)
- [ ] Orchestrator prompt is under 150 lines
- [ ] Orchestrator loads 12 skills (down from 19)
- [ ] Post-implementation skill fires automatically after dev-python/dev-shell/dev-refactor returns DONE
- [ ] Quality gate detects project type and runs correct commands
- [ ] Doc staleness check flags docs referencing modified files
- [ ] Auto-review dispatches dev-reviewer without user intervention
- [ ] Improvement capture writes to docs/improvements/pending.md on friction
- [ ] Codebase-audit produces structured findings with severity/effort/agent
- [ ] Agent-audit reads docs/improvements/pending.md and produces actionable proposals
- [ ] Commit skill warns when docs reference changed files but weren't updated
- [ ] dev-refactor has TDD skill and execute-findings mode
- [ ] dev-reviewer has codebase scan mode and doc accuracy dimension
- [ ] All deleted skills have their functionality preserved in merged/folded locations
- [ ] Plan checkboxes auto-update to [x] after each task completes (subagent-driven-development)
- [ ] Task descriptions enriched with context from earlier tasks before dispatch (subagent-driven-development)
- [ ] Plan divergences recorded in the plan file when implementation differs from plan (subagent-driven-development)
- [ ] Execution plan stages auto-update after completion (execution-planning)
- [ ] Spec acceptance criteria auto-update when verified (post-implementation)
- [ ] docs/TODO.md auto-updates when a spec is fully complete (post-implementation)
- [ ] skill-catalog.md and creating-agents.md are updated
- [ ] README.md counts are accurate
- [ ] shellcheck clean on any modified hooks
