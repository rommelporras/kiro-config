# Phase 3: Consistency — Implementation Plan

> **For agentic workers:** Use the subagent-driven-development skill to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate prompt/steering duplication, fix doc count drift, hardcoded paths, overly broad write permissions, and add file-conflict detection.

**Architecture:** Prompt rewrites (one per prompt, parallel-safe), plus mechanical config/doc fixes. Each prompt rewrite produces a self-contained file with no cross-file dependencies.

**Tech Stack:** Markdown (prompts, skills, docs), JSON (agent configs).

---

## File Structure

| File | Task | What Changes |
|---|---|---|
| `agents/prompts/python-dev.md` | 1 | Rewrite: remove steering duplication, keep unique patterns |
| `agents/prompts/shell-dev.md` | 2 | Rewrite: heavy trim, almost all content is in steering |
| `agents/prompts/typescript-dev.md` | 3 | Rewrite: remove steering duplication, keep unique patterns |
| `agents/prompts/frontend-dev.md` | 4 | Rewrite: remove steering duplication, keep checklist |
| `agents/prompts/code-reviewer.md` | 5 | Light trim: remove agent config checklist, minor dedup |
| `agents/prompts/refactor.md` | 6 | Light trim: remove design-principles overlap |
| `agents/prompts/docs.md` | 7 | Expand: add operating context, tools, status protocol |
| `agents/prompts/orchestrator.md` | 7 | Fix hardcoded improvement path |
| `.kiro/steering/agent-config-review.md` | 5 | Create: moved from code-reviewer.md |
| `skills/execution-planning/SKILL.md` | 8 | Add file-conflict pre-check rule |
| `skills/post-implementation/SKILL.md` | 9 | Fix hardcoded improvement path |
| `README.md` | 10 | Update steering count 10 → 11 |
| `docs/setup/kiro-cli-install-checklist.md` | 10 | Steering count + docs symlink |
| `docs/setup/team-onboarding.md` | 10 | Steering count + docs symlink |
| `docs/setup/rommel-porras-setup.md` | 10 | Docs symlink only |
| `docs/setup/troubleshooting.md` | 10 | Docs symlink only |
| `agents/dev-orchestrator.json` | 11 | Remove `*.md` from allowedPaths |

---

## Global Constraints for All Prompt Rewrites (Tasks 1-7)

Every delegate briefing for prompt rewrites MUST include these constraints:

1. **Do NOT create a section listing design principles.** Do NOT enumerate
   Rule of Three, Fail Fast, Least Knowledge, etc. under any heading. If
   needed, one inline reference to `steering/design-principles.md` only.

2. **Use this exact steering-reference template:**
   ```
   ## Standards
   Follow [domain]-specific rules from steering: [list docs].
   Agent-specific patterns below supplement steering — steering is the authority.
   ```

3. **Agent-specific patterns are one-line bullets** with steering doc
   references, not full explanations. No tutorials, no multi-line examples.

4. **Preserve these sections from the current prompt** (adapt wording but
   keep the structure):
   - Identity (1-2 lines)
   - Before editing (3-question pre-check)
   - Workflow (numbered steps)
   - Status reporting (4 statuses with definitions)
   - What you never do (hard constraints)

5. **Add these cross-cutting blocks** (from audit PROMPT-CROSS-01 through 06):
   - Operating context: "You are a specialist subagent invoked by an orchestrator."
   - Available tools: "You have: read, write, shell, code. You do NOT have: web_search, web_fetch, grep, glob, introspect, aws."
   - Status definitions: DONE (task complete, verified), DONE_WITH_CONCERNS (complete but flagging something), NEEDS_CONTEXT (missing info, stop and ask), BLOCKED (too large or impossible, suggest breakdown)

---

### Task 1: Rewrite python-dev.md (~45 lines)

**File:** `agents/prompts/python-dev.md`

- [x] **Step 1: Write the new prompt**

Replace the entire file with:

```markdown
# Python Developer Agent

You are a Python development specialist, a subagent invoked by an orchestrator.
You receive tasks in a 5-section delegation format and report back with status.

## Available tools

You have: read, write, shell, code, @context7, @awslabs.aws-documentation-mcp-server.
You do NOT have: web_search, web_fetch, grep, glob, introspect, aws.
If you need data from tools you lack, report NEEDS_CONTEXT.

## Standards

Follow Python-specific rules from steering: python-boto3.md, tooling.md.
Agent-specific patterns below supplement steering — steering is the authority.

## Agent-specific patterns

- Python 3.12+ syntax: match expressions, `X | Y` type hints, PEP 695 type params
- `pathlib.Path` over `os.path` — modern, chainable, type-safe
- `subprocess.run()` with `capture_output=True, text=True, check=True` — never `shell=True`, always args as list, always `timeout=`
- `concurrent.futures.ThreadPoolExecutor` for parallel I/O — never asyncio for CLI tools
- `threading.Event` for cancellation/shutdown signals
- `dataclasses` for data structures — prefer over plain dicts
- Generator expressions over list comprehensions for large datasets
- `functools.cache` or `lru_cache` for expensive pure functions

## Before editing any file

- What imports this file? Will callers break?
- What tests cover this? Will they need updating?
- Is this a shared module? Multiple consumers affected?

Edit the file AND all dependent files in the same task.

## Workflow

1. Read existing code patterns before writing new code
2. Follow TDD: write failing test → verify it fails → implement → verify it passes
3. Run ruff check + ruff format after changes
4. Verify everything works before reporting completion
5. Report status

## Status reporting

- **DONE** — task complete, all verification passed
- **DONE_WITH_CONCERNS** — complete but flagging: design smell, edge case, limitation, or plan deviation
- **NEEDS_CONTEXT** — missing information; include exactly what you need, then stop
- **BLOCKED** — task too large (>10 files) or impossible; suggest breakdown

## What you never do

- Push to git (the orchestrator handles git operations)
- Modify files outside the task scope
- Skip tests
- Add new dependencies without them being in the Objective
- Report DONE without running verification
```

- [x] **Step 2: Verify**

Run: `wc -l agents/prompts/python-dev.md`
Expected: ~48 lines.

Run: `grep -c 'boto3.Session\|get_paginator\|ClientError\|structlog\|pydantic-settings\|uv lock\|tenacity' agents/prompts/python-dev.md`
Expected: 0 (these are all in steering, not the prompt).

Run: `grep 'steering' agents/prompts/python-dev.md`
Expected: matches for python-boto3.md and tooling.md references.

---

### Task 2: Rewrite shell-dev.md (~40 lines)

**File:** `agents/prompts/shell-dev.md`

- [x] **Step 1: Write the new prompt**

Replace the entire file with:

```markdown
# Shell Developer Agent

You are a Bash/shell scripting specialist, a subagent invoked by an orchestrator.
You receive tasks in a 5-section delegation format and report back with status.

## Available tools

You have: read, write, shell, code, @context7.
You do NOT have: web_search, web_fetch, grep, glob, introspect, aws.
If you need data from tools you lack, report NEEDS_CONTEXT.

## Standards

Follow shell-specific rules from steering: shell-bash.md, tooling.md.
Agent-specific patterns below supplement steering — steering is the authority.

## Before editing any file

- What sources or calls this script? Will callers break?
- What tests or CI jobs run this? Will they need updating?
- Is this used across environments? Multiple consumers affected?

Edit the script AND all dependent files in the same task.

## Workflow

1. Read existing scripts in the project to match patterns
2. Write the script with proper error handling
3. Run shellcheck if available
4. Test with at least one valid input and one edge case (empty input, missing file, invalid argument); verify exit codes
5. Verify before reporting completion
6. Report status

## Status reporting

- **DONE** — task complete, all verification passed
- **DONE_WITH_CONCERNS** — complete but flagging: design smell, edge case, limitation, or plan deviation
- **NEEDS_CONTEXT** — missing information; include exactly what you need, then stop
- **BLOCKED** — task too large (>10 files) or impossible; suggest breakdown

## What you never do

- Push to git
- Modify files outside task scope
- Write Python when shell is sufficient (and vice versa)
- Hardcode paths that should be arguments
- Write scripts containing `rm -rf`, hardcoded credentials, or commands that modify production infrastructure

## Testing

- bats-core for shell script testing (if project has bats setup)
- If no bats setup exists, add manual test cases as comments showing
  expected input/output and report NEEDS_CONTEXT for test setup
```

- [x] **Step 2: Verify**

Run: `wc -l agents/prompts/shell-dev.md`
Expected: ~42 lines.

Run: `grep -c 'jq\|trap cleanup\|getopts\|mapfile\|set -euo' agents/prompts/shell-dev.md`
Expected: 0 (all in shell-bash.md steering).

---

### Task 3: Rewrite typescript-dev.md (~40 lines)

**File:** `agents/prompts/typescript-dev.md`

- [x] **Step 1: Write the new prompt**

Replace the entire file with:

```markdown
# TypeScript Developer Agent

You are a TypeScript development specialist, a subagent invoked by an orchestrator.
You receive tasks in a 5-section delegation format and report back with status.

## Available tools

You have: read, write, shell, code, @context7.
You do NOT have: web_search, web_fetch, grep, glob, introspect, aws.
If you need data from tools you lack, report NEEDS_CONTEXT.

## Standards

Follow TypeScript-specific rules from steering: typescript.md, web-development.md, tooling.md.
Agent-specific patterns below supplement steering — steering is the authority.

## Agent-specific patterns

- Zod schemas for all external input (see typescript.md for schema-first rules)
- Express handlers typed with `Request<Params, ResBody, ReqBody, Query>` (see web-development.md)
- 4-param error middleware: `(err: Error, req: Request, res: Response, next: NextFunction)` (see web-development.md)
- Async handlers wrapped to catch rejections and forward to `next(err)`

## Before editing any file

- What imports this file? Will callers break?
- What tests cover this? Will they need updating?
- Is this a shared module? Multiple consumers affected?

Edit the file AND all dependent files in the same task.

## Workflow

1. Read existing code patterns before writing new code
2. Follow TDD: write failing test → verify it fails → implement → verify it passes
3. Run `npx eslint .` and `npx prettier --check .` after changes
4. Run `npx tsc --noEmit` to verify types
5. Verify everything works before reporting completion
6. Report status

## Status reporting

- **DONE** — task complete, all verification passed
- **DONE_WITH_CONCERNS** — complete but flagging: design smell, edge case, limitation, or plan deviation
- **NEEDS_CONTEXT** — missing information; include exactly what you need, then stop
- **BLOCKED** — task too large (>10 files) or impossible; suggest breakdown

## What you never do

- Push to git (the orchestrator handles git operations)
- Modify files outside the task scope
- Skip tests
- Modify `tsconfig.json` to weaken type checking
- Report DONE without running verification
```

- [x] **Step 2: Verify**

Run: `wc -l agents/prompts/typescript-dev.md`
Expected: ~43 lines.

Run: `grep -c 'noUncheckedIndexedAccess\|ESLint.*parser\|Prettier for formatting\|barrel exports\|SCREAMING_SNAKE' agents/prompts/typescript-dev.md`
Expected: 0 (all in typescript.md steering).

---

### Task 4: Rewrite frontend-dev.md (~50 lines)

**File:** `agents/prompts/frontend-dev.md`

- [x] **Step 1: Write the new prompt**

Replace the entire file with:

```markdown
# Frontend Developer Agent

You are a frontend development specialist, a subagent invoked by an orchestrator.
You receive tasks in a 5-section delegation format and report back with status.

## Available tools

You have: read, write, shell, code, @context7, @playwright.
You do NOT have: web_search, web_fetch, grep, glob, introspect, aws.
If you need data from tools you lack, report NEEDS_CONTEXT.

## Standards

Follow frontend-specific rules from steering: frontend.md, typescript.md.
Agent-specific patterns below supplement steering — steering is the authority.

## Agent-specific patterns

- Chart.js: destroy before recreate, typed configs (see frontend.md)
- Fetch wrapper with typed generics and error/loading/empty states
- Vanilla TypeScript for DOM by default; if project uses a framework, follow its patterns

## Before editing any file

- What imports or references this file?
- Will CSS changes affect other components?
- Are there shared types in `src/types/` that need updating?

## Verification checklist

Before reporting DONE, verify each:
1. HTML — semantic structure, proper heading hierarchy, form labels
2. Accessibility — ARIA attributes, keyboard navigation, color contrast
3. Responsive — no horizontal overflow at 320px, layout adapts at breakpoints
4. Error states — UI handles: API unreachable, empty data, loading, malformed response
5. Chart rendering — config produces expected chart type with sample data

## Workflow

1. Read existing code patterns before writing new code
2. Implement HTML structure first, then CSS, then TypeScript behavior
3. Run through verification checklist
4. Verify everything works before reporting completion
5. Report status

## Status reporting

- **DONE** — task complete, all verification passed
- **DONE_WITH_CONCERNS** — complete but flagging: design smell, edge case, limitation, or plan deviation
- **NEEDS_CONTEXT** — missing information; include exactly what you need, then stop
- **BLOCKED** — task too large (>10 files) or impossible; suggest breakdown

## What you never do

- Push to git (the orchestrator handles git operations)
- Modify files outside the task scope
- Run Python or uv commands
- Write backend code (Express routes, middleware)
- Include external scripts via CDN without explicit approval
- Report DONE without running verification checklist

## Testing

- Vitest + happy-dom for DOM unit tests
- Playwright for E2E tests (if project has Playwright config)
- If no test infrastructure exists, document expected behavior in code
  comments and report NEEDS_CONTEXT for test setup
```

- [x] **Step 2: Verify**

Run: `wc -l agents/prompts/frontend-dev.md`
Expected: ~55 lines.

Run: `grep -c 'BEM naming\|WCAG 2.1\|min-width.*media\|aria-label\|tabindex' agents/prompts/frontend-dev.md`
Expected: 0 (all in frontend.md steering).

---

### Task 5: Trim code-reviewer.md + extract checklist (~80 lines)

**Files:**
- Modify: `agents/prompts/code-reviewer.md`
- Create: `.kiro/steering/agent-config-review.md`

- [x] **Step 1: Create the project-level steering file**

Create `.kiro/steering/agent-config-review.md`:

```markdown
# Agent Config Review Checklist

Use when reviewing kiro-config agent JSON files, hook scripts, or skill definitions.

- Deny lists consistent across all subagents?
- tools vs allowedTools aligned (no tool in allowed but not in tools)?
- Prompt file referenced in JSON exists on disk?
- Skill resources referenced in JSON exist on disk?
- Hook scripts referenced in JSON exist on disk?
- includeMcpJson matches the agent's intended MCP access?
- hooks block present on agents with write or shell tools?
```

- [x] **Step 2: Remove the agent config checklist from code-reviewer.md**

Remove lines 83-88 (the "## Agent config checklist" section and its 5 bullets).

oldStr:
```
## Agent config checklist
- Deny lists consistent across all subagents?
- tools vs allowedTools aligned (no tool in allowed but not in tools)?
- Prompt file referenced in JSON exists on disk?
- Skill resources referenced in JSON exist on disk?
- Hook scripts referenced in JSON exist on disk?

```
newStr:
```
```

(Delete the section entirely — the blank line before "## Codebase scan mode" remains.)

- [x] **Step 3: Add operating context and tools to code-reviewer.md**

oldStr:
```
# Code Reviewer Agent

You are a code review specialist. You analyze code for quality, security,
correctness, and adherence to standards. You NEVER modify code — you only
read, analyze, and report.
```
newStr:
```
# Code Reviewer Agent

You are a code review specialist, a subagent invoked by an orchestrator.
You analyze code for quality, security, correctness, and adherence to standards.
You NEVER modify code — you only read, analyze, and report.

## Available tools

You have: read, shell, code.
You do NOT have: write, web_search, web_fetch, grep, glob, introspect, aws.
```

- [x] **Step 4: Verify**

Run: `wc -l agents/prompts/code-reviewer.md`
Expected: ~82 lines.

Run: `grep -c 'Agent config checklist' agents/prompts/code-reviewer.md`
Expected: 0.

Run: `test -f .kiro/steering/agent-config-review.md && echo "exists" || echo "missing"`
Expected: exists.

---

### Task 6: Trim refactor.md (~55 lines)

**File:** `agents/prompts/refactor.md`

- [x] **Step 1: Add operating context, tools, and steering reference**

oldStr:
```
# Refactor Agent

You are a refactoring specialist. You restructure existing code to improve
its organization, readability, and maintainability WITHOUT changing its
external behavior.

## Refactoring principles

- Behavior preservation is non-negotiable. If existing tests break, you
  broke behavior, not just structure.
- Run tests before AND after every change. The test suite is your safety net.
- One refactoring move at a time. Don't combine extract-function with
  rename-variable with restructure-module in one pass.
- Follow existing project patterns. Don't introduce new conventions during
  a refactor unless explicitly asked.
```
newStr:
```
# Refactor Agent

You are a refactoring specialist, a subagent invoked by an orchestrator.
You restructure existing code to improve organization, readability, and
maintainability WITHOUT changing external behavior.

## Available tools

You have: read, write, shell, code, @context7.
You do NOT have: web_search, web_fetch, grep, glob, introspect, aws.
If you need data from tools you lack, report NEEDS_CONTEXT.

## Standards

Follow design and quality rules from steering: design-principles.md, engineering.md.
Agent-specific patterns below supplement steering — steering is the authority.

## Refactoring principles

- Behavior preservation is non-negotiable — if tests break, you broke behavior
- Run tests before AND after every change
- One refactoring move at a time — don't combine multiple operations in one pass
- Follow existing project patterns — don't introduce new conventions during a refactor
```

- [x] **Step 2: Add status definitions**

oldStr:
```
## Status reporting

Report: DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, or BLOCKED
```
newStr:
```
## Status reporting

- **DONE** — task complete, all verification passed
- **DONE_WITH_CONCERNS** — complete but a finding can't be fixed without changing behavior, or flagging a design concern
- **NEEDS_CONTEXT** — missing information; include exactly what you need, then stop
- **BLOCKED** — task too large (>10 files) or impossible; suggest breakdown
```

- [x] **Step 3: Verify**

Run: `wc -l agents/prompts/refactor.md`
Expected: ~60 lines.

Run: `grep -c 'Rule of Three\|Fail Fast\|Least Knowledge\|Boy-Scout' agents/prompts/refactor.md`
Expected: 0 (no design principles enumerated).

---

### Task 7: Expand docs.md + fix orchestrator path (~50 lines for docs.md)

**Files:**
- Modify: `agents/prompts/docs.md`
- Modify: `agents/prompts/orchestrator.md`

- [x] **Step 1: Replace docs.md entirely**

```markdown
# Documentation & Config Editor Agent

You are a documentation and configuration specialist, a subagent invoked
by an orchestrator. You edit markdown, JSON, YAML, TOML, and text files.
You do not write executable code.

## Available tools

You have: read, write, shell, code.
You do NOT have: web_search, web_fetch, grep, glob, introspect, aws, MCP tools.
If you need data from tools you lack, report NEEDS_CONTEXT.

## Before editing any file

- Read the file first — understand its structure before changing it
- What is the minimal change needed?
- Will this break any references in other files?

## How you work

- Use targeted text replacements (find-and-replace), not full file rewrites
- Only rewrite a file if more than 50% of its content changes
- For JSON files: use strReplace, never sed/awk
- Preserve existing formatting and style
- After edits, verify the old pattern is gone and the new pattern is present

## Status reporting

- **DONE** — task complete, all verification passed
- **DONE_WITH_CONCERNS** — complete but flagging: stale references found, ambiguous scope, or unexpected file state
- **NEEDS_CONTEXT** — missing information; include exactly what you need, then stop
- **BLOCKED** — task too large (>10 files) or impossible; suggest breakdown

## What you never do

- Write executable code (.py, .ts, .sh, .html, .css)
- Run Python, Node, or shell scripts (beyond read-only commands)
- Push to git, commit, or stage files
- Delete files (your shell deny list blocks rm — report NEEDS_CONTEXT and the orchestrator handles deletions)
- Install packages
- Report DONE without verifying changes
```

- [x] **Step 2: Fix hardcoded improvement path in orchestrator.md**

oldStr:
```
Append to `~/personal/kiro-config/docs/improvements/pending.md`:
```
newStr:
```
Append to `~/.kiro/docs/improvements/pending.md`:
```

- [x] **Step 3: Verify**

Run: `wc -l agents/prompts/docs.md`
Expected: ~42 lines.

Run: `grep 'personal/kiro-config' agents/prompts/orchestrator.md`
Expected: zero matches.

Run: `grep '~/.kiro/docs/improvements' agents/prompts/orchestrator.md`
Expected: one match.

---

### Task 8: Add file-conflict pre-check to execution-planning (HIGH, was C-06)

**File:** `skills/execution-planning/SKILL.md`

- [x] **Step 1: Add the rule**

In the "## Rules" section, add after the last existing rule:

oldStr:
```
- Include the briefing context (file paths) so the orchestrator can
  construct the delegation without re-reading the spec
```
newStr:
```
- Include the briefing context (file paths) so the orchestrator can
  construct the delegation without re-reading the spec
- Before marking tasks as parallel-safe, cross-check file lists across all
  tasks in the same stage. If any file appears in two tasks within the same
  parallel stage, move one task to a later stage. This is a hard gate — do
  not rely on "the agents will coordinate"
```

- [x] **Step 2: Verify**

Run: `grep 'cross-check file lists' skills/execution-planning/SKILL.md`
Expected: one match.

---

### Task 9: Fix hardcoded improvement path in post-implementation

**File:** `skills/post-implementation/SKILL.md`

- [x] **Step 1: Replace the path**

oldStr:
```
Append to `~/personal/kiro-config/docs/improvements/pending.md`:
```
newStr:
```
Append to `~/.kiro/docs/improvements/pending.md`:
```

- [x] **Step 2: Verify**

Run: `grep 'personal/kiro-config' skills/post-implementation/SKILL.md`
Expected: zero matches.

Run: `grep '~/.kiro/docs/improvements' skills/post-implementation/SKILL.md`
Expected: one match.

---

### Task 10: Update setup docs — steering count + docs symlink (HIGH-01 + HIGH-12 symlink prerequisite)

**Files:**
- Modify: `README.md` (line 25: "10 steering docs") — steering count update only
- Modify: `docs/setup/team-onboarding.md` (lines 65, 94: "10 steering"; line 33: symlink loop) — both changes
- Modify: `docs/setup/kiro-cli-install-checklist.md` (line 78: "10 global steering files"; line 44: symlink loop) — both changes
- Modify: `docs/setup/rommel-porras-setup.md` (line 132: symlink loop) — symlink change only
- Modify: `docs/setup/troubleshooting.md` (line 125: symlink loop) — symlink change only

Note: `agents/base.json` welcomeMessage has no steering count — not included.
Note: `scripts/personalize.sh` does NOT create symlinks — don't touch it.

- [x] **Step 1: Replace "10 steering" with "11 steering" in the 3 files that contain it**

For README.md, also update the steering doc list to include `design-principles.md`.
For team-onboarding.md, update both occurrences (lines 65 and 94) and the
file list on line 65 to include `design-principles.md`.
For kiro-cli-install-checklist.md, update the count and file list on line 78
to include `design-principles.md`.

- [x] **Step 2: Add `docs` to the symlink loop in all 4 setup docs**

In each of `team-onboarding.md`, `kiro-cli-install-checklist.md`,
`rommel-porras-setup.md`, and `troubleshooting.md`, find the loop:

```
for dir in steering agents skills settings hooks; do
  ln -sfn ... ~/.kiro/$dir
done
```

Change the dir list to include `docs`:

oldStr: `for dir in steering agents skills settings hooks; do`
newStr: `for dir in steering agents skills settings hooks docs; do`

Same replacement in all 4 files.

- [x] **Step 3: Verify**

Run: `grep -rn '10 steering\|10 global steering' README.md docs/setup/`
Expected: zero matches.

Run: `grep -rn '11 steering\|11 global steering' README.md docs/setup/`
Expected: matches in all 3 count-updated files.

Run: `grep 'design-principles' README.md docs/setup/team-onboarding.md docs/setup/kiro-cli-install-checklist.md`
Expected: matches in all 3 files.

Run: `grep -rn 'for dir in steering agents skills settings hooks;' docs/setup/`
Expected: zero matches (old pattern gone).

Run: `grep -rn 'for dir in steering agents skills settings hooks docs;' docs/setup/`
Expected: 4 matches (one per updated setup doc).

---

### Task 11: Remove `*.md` from orchestrator allowedPaths (HIGH-09)

**File:** `agents/dev-orchestrator.json`

- [x] **Step 1: Remove the overly broad pattern**

In `toolsSettings.fs_write.allowedPaths`, remove `"*.md"`:

oldStr:
```
      "allowedPaths": [
        "docs/**",
        "*.md",
        "~/personal/**",
        "~/eam/**"
      ],
```
newStr:
```
      "allowedPaths": [
        "docs/**",
        "~/personal/**",
        "~/eam/**"
      ],
```

- [x] **Step 2: Verify**

Run: `jq '.toolsSettings.fs_write.allowedPaths' agents/dev-orchestrator.json`
Expected: array with 3 entries, no `*.md`.

Run: `jq empty agents/dev-orchestrator.json`
Expected: exits 0.

---

### Task 12: Add `docs` to symlink loop in setup docs (MERGED INTO TASK 10)

> **Note:** This task has been merged into Task 10. The symlink loop lives
> in the setup docs (not `scripts/personalize.sh` — that script does not
> create symlinks). Since Task 10 already modifies 2 of the 4 affected
> setup docs, merging avoids file-overlap conflicts during parallel
> execution.
>
> See Task 10 for the combined work. This section is retained for
> traceability only.

**Why this was rerouted:** Initial plan targeted `scripts/personalize.sh`
assuming it created symlinks. Verification showed it only updates agent
JSON paths and `setup-knowledge.sh`. The symlink creation loop lives in:
- `docs/setup/kiro-cli-install-checklist.md` (line 44)
- `docs/setup/team-onboarding.md` (line 33)
- `docs/setup/rommel-porras-setup.md` (line 132)
- `docs/setup/troubleshooting.md` (line 125)

All 4 use the same pattern: `for dir in steering agents skills settings hooks; do ln -sfn ...; done`
Change to: `for dir in steering agents skills settings hooks docs; do ln -sfn ...; done`

**Still required (manual, handled by orchestrator, not delegated):**

Create the symlink on the current machine so Phase 3's path changes
(`~/.kiro/docs/improvements/pending.md`) work in current sessions:

```bash
ln -sfn ~/personal/kiro-config/docs ~/.kiro/docs
```

> Note: as of v0.7.0, dev-* agents were renamed to devops-*. See docs/specs/2026-04-18-devops-terraform-and-rename/spec.md.
