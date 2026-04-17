# Phase 2: Accuracy Fixes — Implementation Plan

> **For agentic workers:** Use the subagent-driven-development skill to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix accuracy gaps in TDD coverage, MCP access, ghost agent references, auto-capture blind spots, and the remaining base.json dd pattern.

**Architecture:** Config edits (agent JSONs, prompts, skill files) plus two small hook script logic changes. All modifications to existing files.

**Tech Stack:** JSON (agent configs), Markdown (prompts, skills), Bash (hook scripts).

---

## File Structure

| File | Tasks | What Changes |
|---|---|---|
| `agents/dev-frontend.json` | 1, 4 | add TDD skill resource, enable MCP, add tools |
| `agents/dev-shell.json` | 1, 4 | add TDD skill resource, enable MCP, add tools |
| `agents/dev-python.json` | 4 | enable MCP, add tools |
| `agents/dev-typescript.json` | 4 | enable MCP, add tools |
| `agents/dev-refactor.json` | 4 | enable MCP, add tools |
| `agents/prompts/frontend-dev.md` | 1 | add testing section |
| `agents/prompts/shell-dev.md` | 1 | add testing section |
| `agents/prompts/orchestrator.md` | 5 | fix MCP claim |
| `skills/writing-plans/SKILL.md` | 2 | fix plan-reviewer reference |
| `agents/base.json` | 3 | fix dd pattern |
| `hooks/feedback/auto-capture.sh` | 6 | add general fallback |
| `hooks/_lib/distill.sh` | 7 | add general-bucket threshold |

---

### Task 1: Add TDD skill to dev-frontend and dev-shell (CRITICAL-04)

**Files:**
- Modify: `agents/dev-frontend.json`
- Modify: `agents/dev-shell.json`
- Modify: `agents/prompts/frontend-dev.md`
- Modify: `agents/prompts/shell-dev.md`

- [x] **Step 1: Add TDD skill resource to dev-frontend.json**

In the `resources` array, add after the last `skill://` entry:

oldStr:
```
    "skill://~/.kiro/skills/receiving-code-review/SKILL.md"
```
newStr:
```
    "skill://~/.kiro/skills/receiving-code-review/SKILL.md",
    "skill://~/.kiro/skills/test-driven-development/SKILL.md"
```

- [x] **Step 2: Add TDD skill resource to dev-shell.json**

In the `resources` array, add after the last `skill://` entry:

oldStr:
```
    "skill://~/.kiro/skills/receiving-code-review/SKILL.md"
```
newStr:
```
    "skill://~/.kiro/skills/receiving-code-review/SKILL.md",
    "skill://~/.kiro/skills/test-driven-development/SKILL.md"
```

- [x] **Step 3: Add testing section to frontend-dev.md**

Add after the "## What you never do" section at the end of the file:

```markdown

## Testing

- Vitest + happy-dom for DOM unit tests
- Playwright for E2E tests (if project has Playwright config)
- If no test infrastructure exists, document expected behavior in code
  comments and report NEEDS_CONTEXT for test setup
```

- [x] **Step 4: Add testing section to shell-dev.md**

Add after the "## What you never do" section at the end of the file:

```markdown

## Testing

- bats-core for shell script testing (if project has bats setup)
- If no bats setup exists, add manual test cases as comments showing
  expected input/output and report NEEDS_CONTEXT for test setup
```

- [x] **Step 5: Verify**

Run: `jq '.resources[]' agents/dev-frontend.json | grep 'test-driven'`
Expected: one match.

Run: `jq '.resources[]' agents/dev-shell.json | grep 'test-driven'`
Expected: one match.

Run: `grep -c 'Testing' agents/prompts/frontend-dev.md`
Expected: at least 1.

Run: `grep -c 'bats-core' agents/prompts/shell-dev.md`
Expected: 1.

---

### Task 2: Fix plan-reviewer ghost reference (HIGH-14)

**File:**
- Modify: `skills/writing-plans/SKILL.md`

- [x] **Step 1: Replace plan-reviewer with dev-reviewer**

oldStr:
```
1. Dispatch a plan-reviewer delegate to review the plan against the spec — provide the path to the plan document and the spec document, not your session history
```
newStr:
```
1. Dispatch dev-reviewer to review the plan against the spec — provide the path to the plan document and the spec document, not your session history
```

- [x] **Step 2: Verify**

Run: `grep 'plan-reviewer' skills/writing-plans/SKILL.md`
Expected: zero matches.

Run: `grep -n 'dev-reviewer' skills/writing-plans/SKILL.md`
Expected: match at line 122.

---

### Task 3: Fix base.json dd pattern (carried from Phase 1)

**File:**
- Modify: `agents/base.json`

- [x] **Step 1: Add .* suffix to dd pattern**

oldStr:
```
        "dd if=/dev",
```
newStr:
```
        "dd if=/dev.*",
```

- [x] **Step 2: Verify**

Run: `jq '.toolsSettings.execute_bash.deniedCommands[]' agents/base.json | grep 'dd if'`
Expected: `"dd if=/dev.*"`

---

### Task 4: Enable MCP on subagents (HIGH-04/HIGH-07)

**Files:**
- Modify: `agents/dev-python.json`
- Modify: `agents/dev-typescript.json`
- Modify: `agents/dev-frontend.json`
- Modify: `agents/dev-shell.json`
- Modify: `agents/dev-refactor.json`

All 5 agents currently have identical tools/allowedTools arrays. Each step
below uses the full array as oldStr to avoid ambiguity (both arrays contain
`"code"` — bare `"code"` would match twice).

- [x] **Step 1: dev-python.json — add MCP tools and enable**

Tools array — oldStr:
```json
  "tools": [
    "read",
    "write",
    "shell",
    "code"
  ],
```
newStr:
```json
  "tools": [
    "read",
    "write",
    "shell",
    "code",
    "@context7",
    "@awslabs.aws-documentation-mcp-server"
  ],
```

AllowedTools array — oldStr:
```json
  "allowedTools": [
    "read",
    "write",
    "code"
  ],
```
newStr:
```json
  "allowedTools": [
    "read",
    "write",
    "code",
    "@context7",
    "@awslabs.aws-documentation-mcp-server"
  ],
```

Change: `"includeMcpJson": false` → `"includeMcpJson": true`

- [x] **Step 2: dev-typescript.json — add MCP tools and enable**

Tools array — oldStr:
```json
  "tools": [
    "read",
    "write",
    "shell",
    "code"
  ],
```
newStr:
```json
  "tools": [
    "read",
    "write",
    "shell",
    "code",
    "@context7"
  ],
```

AllowedTools array — oldStr:
```json
  "allowedTools": [
    "read",
    "write",
    "code"
  ],
```
newStr:
```json
  "allowedTools": [
    "read",
    "write",
    "code",
    "@context7"
  ],
```

Change: `"includeMcpJson": false` → `"includeMcpJson": true`

- [x] **Step 3: dev-frontend.json — add MCP tools and enable**

Tools array — oldStr:
```json
  "tools": [
    "read",
    "write",
    "shell",
    "code"
  ],
```
newStr:
```json
  "tools": [
    "read",
    "write",
    "shell",
    "code",
    "@context7",
    "@playwright"
  ],
```

AllowedTools array — oldStr:
```json
  "allowedTools": [
    "read",
    "write",
    "code"
  ],
```
newStr:
```json
  "allowedTools": [
    "read",
    "write",
    "code",
    "@context7",
    "@playwright"
  ],
```

Change: `"includeMcpJson": false` → `"includeMcpJson": true`

- [x] **Step 4: dev-shell.json — add MCP tools and enable**

Tools array — oldStr:
```json
  "tools": [
    "read",
    "write",
    "shell",
    "code"
  ],
```
newStr:
```json
  "tools": [
    "read",
    "write",
    "shell",
    "code",
    "@context7"
  ],
```

AllowedTools array — oldStr:
```json
  "allowedTools": [
    "read",
    "write",
    "code"
  ],
```
newStr:
```json
  "allowedTools": [
    "read",
    "write",
    "code",
    "@context7"
  ],
```

Change: `"includeMcpJson": false` → `"includeMcpJson": true`

- [x] **Step 5: dev-refactor.json — add MCP tools and enable**

Tools array — oldStr:
```json
  "tools": [
    "read",
    "write",
    "shell",
    "code"
  ],
```
newStr:
```json
  "tools": [
    "read",
    "write",
    "shell",
    "code",
    "@context7"
  ],
```

AllowedTools array — oldStr:
```json
  "allowedTools": [
    "read",
    "write",
    "code"
  ],
```
newStr:
```json
  "allowedTools": [
    "read",
    "write",
    "code",
    "@context7"
  ],
```

Change: `"includeMcpJson": false` → `"includeMcpJson": true`

- [x] **Step 6: Verify MCP enablement**

Run: `for f in agents/dev-python.json agents/dev-typescript.json agents/dev-frontend.json agents/dev-shell.json agents/dev-refactor.json; do echo "=== $f ==="; jq '.includeMcpJson' "$f"; jq '.tools' "$f" | grep context7; done`
Expected: all show `true` and `@context7`.

Run: `jq '.tools' agents/dev-python.json | grep 'aws-documentation'`
Expected: match.

Run: `jq '.tools' agents/dev-frontend.json | grep 'playwright'`
Expected: match.

Run: `for f in agents/dev-docs.json agents/dev-reviewer.json .kiro/agents/dev-kiro-config.json; do echo "=== $f ==="; jq '.includeMcpJson' "$f"; done`
Expected: all show `false`.

Run: `for f in agents/*.json .kiro/agents/*.json; do jq empty "$f" && echo "$f OK" || echo "$f BROKEN"; done`
Expected: all OK.

---

### Task 5: Fix orchestrator prompt MCP claim (HIGH-07)

**File:**
- Modify: `agents/prompts/orchestrator.md`

- [x] **Step 1: Replace the MCP tools line**

oldStr:
```
Subagents CANNOT use: web_search, web_fetch, use_aws, grep, glob, introspect.
Subagents CAN use: read, write, shell, code, MCP tools.
```
newStr:
```
Subagents CANNOT use: web_search, web_fetch, use_aws, grep, glob, introspect.
Subagents CAN use: read, write, shell, code, plus any MCP tools explicitly listed in their config's tools array.
```

- [x] **Step 2: Verify**

Run: `grep 'explicitly listed' agents/prompts/orchestrator.md`
Expected: one match.

Run: `grep 'MCP tools\.' agents/prompts/orchestrator.md`
Expected: zero matches (old phrasing gone).

---

### Task 6: Auto-capture keyword fallback (HIGH, was C-09)

**File:**
- Modify: `hooks/feedback/auto-capture.sh`

- [x] **Step 1: Replace the empty-keyword exit with fallback**

oldStr:
```
[[ -z "$KEYWORDS" ]] && rm -f "$FLAG" && exit 0
```
newStr:
```
[[ -z "$KEYWORDS" ]] && KEYWORDS="general"
```

- [x] **Step 2: Verify**

Run: `grep 'general' hooks/feedback/auto-capture.sh`
Expected: one match showing the fallback.

Run: `grep -c 'KEYWORDS="general"' hooks/feedback/auto-capture.sh`
Expected: 1 (new fallback present).

Run: `bash -n hooks/feedback/auto-capture.sh`
Expected: exits 0.

---

### Task 7: General-bucket promotion threshold (HIGH, was C-09)

**File:**
- Modify: `hooks/_lib/distill.sh`

- [x] **Step 1: Add keyword-aware threshold**

In `distill_check()`, replace:
```bash
    [[ ${kw_count[$kw]} -lt 3 ]] && continue
```
with:
```bash
    local threshold=3
    [[ "$kw" == "general" ]] && threshold=5
    [[ ${kw_count[$kw]} -lt $threshold ]] && continue
```

- [x] **Step 2: Verify**

Run: `grep 'threshold=5' hooks/_lib/distill.sh`
Expected: one match.

Run: `grep 'threshold=3' hooks/_lib/distill.sh`
Expected: one match.

Run: `bash -n hooks/_lib/distill.sh`
Expected: exits 0.
