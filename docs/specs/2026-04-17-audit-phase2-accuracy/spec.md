# Phase 2: Accuracy Fixes from Workflow Audit

**Date:** 2026-04-17
**Source:** `docs/specs/audit-current-workflow.md` (Round 3 final)
**Scope:** CRITICAL-04, HIGH-04/07, HIGH-14, HIGH (was C-09), base.json dd fix

---

## Goal

Fix accuracy gaps: add TDD skills to agents missing them, enable MCP on
subagents that need library docs, fix the ghost agent reference in
writing-plans, close the auto-capture keyword blind spot, and fix the
remaining base.json dd pattern.

---

## Group A: Mechanical Fixes

### A1: Add TDD skill to dev-frontend and dev-shell — CRITICAL-04

**Problem:** `dev-frontend` and `dev-shell` lack the TDD skill entirely.
The engineering philosophy is built on TDD but these agents can't do it.

**Files:**
- `agents/dev-frontend.json` — add TDD skill to resources
- `agents/dev-shell.json` — add TDD skill to resources
- `agents/prompts/frontend-dev.md` — add testing guidance
- `agents/prompts/shell-dev.md` — add testing guidance

**Changes to agent JSONs:** Add to each agent's `resources` array:
```
"skill://~/.kiro/skills/test-driven-development/SKILL.md"
```

**Changes to frontend-dev.md:** Add a testing section after the
verification checklist:

```markdown
## Testing

- Vitest + happy-dom for DOM unit tests
- Playwright for E2E tests (if project has Playwright config)
- If no test infrastructure exists, document expected behavior in code
  comments and report NEEDS_CONTEXT for test setup
```

**Changes to shell-dev.md:** Add a testing section after the workflow:

```markdown
## Testing

- bats-core for shell script testing (if project has bats setup)
- If no bats setup exists, add manual test cases as comments showing
  expected input/output and report NEEDS_CONTEXT for test setup
```

---

### A2: Fix "plan-reviewer" ghost reference — HIGH-14

**Problem:** `skills/writing-plans/SKILL.md` line 122 references
"plan-reviewer delegate" — no such agent exists.

**File:** `skills/writing-plans/SKILL.md`

**Change:** Line 122, replace:
```
1. Dispatch a plan-reviewer delegate to review the plan against the spec — provide the path to the plan document and the spec document, not your session history
```
with:
```
1. Dispatch dev-reviewer to review the plan against the spec — provide the path to the plan document and the spec document, not your session history
```

---

### A3: Fix base.json dd pattern — carried from Phase 1

**Problem:** `base.json` has `"dd if=/dev"` without `.*` suffix. With
`\A`/`\z` anchoring, this matches only the literal string — never a real
`dd if=/dev/zero of=/dev/sda` command.

**File:** `agents/base.json`

**Change:**
```
"dd if=/dev"  →  "dd if=/dev.*"
```

---

### A4: Enable MCP on subagents — HIGH-04/HIGH-07

**Problem:** All subagents have `"includeMcpJson": false` and no MCP tools
in their `tools` array. The orchestrator prompt falsely claims subagents
have MCP access.

**Design decision (user-approved):** Selective enablement per agent:

| Agent | includeMcpJson | MCP tools to add to `tools` array |
|---|---|---|
| dev-python | `true` | `@context7`, `@awslabs.aws-documentation-mcp-server` |
| dev-typescript | `true` | `@context7` |
| dev-frontend | `true` | `@context7`, `@playwright` |
| dev-shell | `true` | `@context7` |
| dev-refactor | `true` | `@context7` |
| dev-docs | `false` | none |
| dev-reviewer | `false` | none |
| dev-kiro-config | `false` | none |

For each enabled agent:
1. Change `"includeMcpJson": false` → `"includeMcpJson": true`
2. Add the MCP tool references to the `tools` array
3. Add the MCP tool references to the `allowedTools` array

**Files:** `agents/dev-python.json`, `agents/dev-typescript.json`,
`agents/dev-frontend.json`, `agents/dev-shell.json`, `agents/dev-refactor.json`

### A5: Fix orchestrator prompt MCP lie — HIGH-07

**Problem:** Orchestrator prompt line 118 says "Subagents CAN use: read,
write, shell, code, MCP tools." This is only partially true now — some
subagents have MCP, some don't.

**File:** `agents/prompts/orchestrator.md`

**Change:** Replace lines 117-118:
```
Subagents CANNOT use: web_search, web_fetch, use_aws, grep, glob, introspect.
Subagents CAN use: read, write, shell, code, MCP tools.
```
with:
```
Subagents CANNOT use: web_search, web_fetch, use_aws, grep, glob, introspect.
Subagents CAN use: read, write, shell, code, plus any MCP tools explicitly listed in their config's tools array.
```

---

## Group B: Hook Script Logic

### B1: Auto-capture keyword fallback — HIGH (was C-09)

**Problem:** `hooks/feedback/auto-capture.sh` line 23 silently drops
corrections when no keyword matches. Technologies not in the hardcoded
list are never captured.

**File:** `hooks/feedback/auto-capture.sh`

**Change:** Replace the empty-keyword exit (line 23):
```bash
[[ -z "$KEYWORDS" ]] && rm -f "$FLAG" && exit 0
```
with:
```bash
[[ -z "$KEYWORDS" ]] && KEYWORDS="general"
```

This tags unmatched corrections with `general` instead of dropping them.

### B2: Raise promotion threshold for general bucket — HIGH (was C-09)

**Problem:** The `general` bucket will be noisier than specific keywords.
It needs a higher bar for promotion to rules.

**File:** `hooks/_lib/distill.sh`

**Change:** In `distill_check()`, replace the single threshold:
```bash
    [[ ${kw_count[$kw]} -lt 3 ]] && continue
```
with a keyword-aware threshold:
```bash
    local threshold=3
    [[ "$kw" == "general" ]] && threshold=5
    [[ ${kw_count[$kw]} -lt $threshold ]] && continue
```

---

## Verification Criteria

After all changes:

1. `jq '.resources[]' agents/dev-frontend.json | grep 'test-driven'` → match
2. `jq '.resources[]' agents/dev-shell.json | grep 'test-driven'` → match
3. `grep 'plan-reviewer' skills/writing-plans/SKILL.md` → zero matches
4. `grep 'dev-reviewer' skills/writing-plans/SKILL.md` → match at line 122
5. `jq '.includeMcpJson' agents/dev-python.json` → `true`
6. `jq '.tools' agents/dev-python.json | grep 'context7'` → match
7. `jq '.includeMcpJson' agents/dev-reviewer.json` → `false`
8. `grep 'explicitly listed' agents/prompts/orchestrator.md` → match
9. `grep -c 'general' hooks/feedback/auto-capture.sh` → at least 1
10. `grep 'threshold=5' hooks/_lib/distill.sh` → match
11. `grep '"dd if=/dev\.\*"' agents/base.json` → match

> Note: as of v0.7.0, dev-* agents were renamed to devops-*. See docs/specs/2026-04-18-devops-terraform-and-rename/spec.md.
