# Foundation Hardening & Self-Review Implementation Plan

> **Status: COMPLETED** — All 8 tasks implemented. Self-review skill evolved
> into agent-audit. Superseded by
> `docs/specs/2026-04-16-orchestrator-agent-framework-redesign/spec.md`
> which rewrites agent-audit, upgrades reviewer/refactor prompts, and adds
> automated post-implementation workflows.

> **For agentic workers:** Use the subagent-driven-development skill to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden existing agent prompts with missing guidance, create a gotchas knowledge file, update rules.md, and add a self-review skill.

**Architecture:** Direct updates to existing markdown prompts, knowledge files, and creation of one new skill. No new agents needed — self-review is an orchestrator-handled skill.

**Tech Stack:** Markdown, JSON (agent configs), Bash (stop hook)

---

### Task 1: Create knowledge/gotchas.md

Seed the gotchas file with known operational gotchas discovered through usage.

**Files:**
- Create: `knowledge/gotchas.md`

- [x] **Step 1: Create gotchas.md with known gotchas**

```markdown
# Gotchas

Operational lessons learned. Updated manually or by the self-review skill.

## Subagent Limitations
- Subagents CANNOT use: web_search, web_fetch, introspect, use_aws, grep, glob
- Subagents CAN use: read, write, shell, code, and MCP tools
- If a task needs web search or AWS data, the orchestrator must gather it first and include in the briefing
- Subagent shell output is buffered, not streamed — long-running commands appear stuck until complete
- Interactive commands (rm -i, npm init, sudo, ssh host key prompts) don't work in subagent shell — no stdin
- Subagents are NOT protected by preToolUse hooks — their safety comes from deniedCommands and deniedPaths in toolsSettings

## AWS CLI in Shell
- Always add --no-cli-pager when running AWS CLI via shell (subagents use shell, not the use_aws tool)
- Always add --output json for parseable output
- Always pass --region explicitly — never assume default

## Kiro Platform
- subagent tool only supports blocking mode — background mode is "not yet implemented"
- /spawn exists for user-initiated parallel sessions but can't be triggered programmatically by agents
- stop hooks run after agent finishes — lightweight only, no blocking operations
- Shell commands in TUI are buffered (no streaming) — commands like npm install show no progress until done

## Knowledge System
- Episodes auto-promote to rules after 3 keyword occurrences (via distill.sh)
- Max 30 active episodes enforced by auto-capture.sh
- Correction detection patterns are regex-based — subtle corrections may not trigger capture
- context-enrichment.sh has a 60-second dedup — rapid corrections within 60s won't all inject rules
```

- [x] **Step 2: Verify file is valid markdown**

Run: `cat knowledge/gotchas.md | head -5`
Expected: Shows the header and first section

- [x] **Step 3: Report completion**

---

### Task 2: Update knowledge/rules.md with subagent rules

Add critical rules about subagent limitations that should always be injected.

**Files:**
- Modify: `knowledge/rules.md`

- [x] **Step 1: Add subagent limitation rules**

Append to rules.md:

```markdown

## [subagent,delegate,spawn]
- 🔴 Subagents cannot use web_search, web_fetch, introspect, use_aws, grep, or glob. Gather data in orchestrator first.
- 🔴 Always add --no-cli-pager and --output json when subagents run AWS CLI via shell.
```

- [x] **Step 2: Verify rules.md is valid**

Run: `grep -c '🔴' knowledge/rules.md`
Expected: Count increases by 2

- [x] **Step 3: Report completion**

---

### Task 3: Harden dev-python prompt

Add missing guidance for pathlib, async patterns, and AWS CLI in shell.

**Files:**
- Modify: `agents/prompts/python-dev.md`

- [x] **Step 1: Add missing patterns to Critical patterns section**

Append these to the "Critical patterns" section:

```markdown
- `pathlib.Path` over `os.path` — modern, chainable, type-safe
- When running AWS CLI via shell: always include `--no-cli-pager --output json --region <region>`
- `mktemp` for temp files with `try/finally` cleanup — never hardcode /tmp paths
```

- [x] **Step 2: Verify the file reads correctly**

Run: `grep -c 'pathlib' agents/prompts/python-dev.md`
Expected: 1

- [x] **Step 3: Report completion**

---

### Task 4: Harden dev-shell prompt

Add missing guidance for AWS CLI, temp files, and debug mode.

**Files:**
- Modify: `agents/prompts/shell-dev.md`

- [x] **Step 1: Add missing patterns to Critical patterns section**

Append these to the "Critical patterns" section:

```markdown
- AWS CLI in scripts: always `--no-cli-pager --output json --region "$REGION"`
- Temp files: use `mktemp` and clean up with `trap 'rm -f "$tmpfile"' EXIT`
- Debug mode: support `TRACE=1` env var with `[[ "${TRACE:-}" == "1" ]] && set -x`
```

- [x] **Step 2: Verify the file reads correctly**

Run: `grep -c 'no-cli-pager' agents/prompts/shell-dev.md`
Expected: 1

- [x] **Step 3: Report completion**

---

### Task 5: Harden dev-reviewer prompt

Add shell-specific and AWS CLI review checklist items.

**Files:**
- Modify: `agents/prompts/code-reviewer.md`

- [x] **Step 1: Add shell and AWS review checklist**

Append after the "Review process" section:

```markdown

## Shell script checklist
- shellcheck clean (no SC warnings)?
- All variables quoted ("${var}")?
- set -euo pipefail present?
- trap cleanup for temp files?
- AWS CLI calls include --no-cli-pager?

## AWS CLI checklist
- --no-cli-pager on every call?
- --output json for parseable output?
- --region explicitly passed?
- No mutating operations (create/update/delete)?
```

- [x] **Step 2: Verify the file reads correctly**

Run: `grep -c 'checklist' agents/prompts/code-reviewer.md`
Expected: 2 (shell + AWS)

- [x] **Step 3: Report completion**

---

### Task 6: Create self-review skill

Create the skill that reads current config and proposes improvements.

**Files:**
- Create: `skills/self-review/SKILL.md`

- [x] **Step 1: Create the skill file**

```markdown
---
name: self-review
description: Reviews current kiro-config for gaps, inconsistencies, and improvement opportunities. Proposes changes for user approval. Triggers on "self-review", "review config", "what can we improve".
---

# Self-Review

Analyze the current kiro-config and propose improvements.

**Announce at start:** "Running self-review against current kiro-config."

## Process

1. **Read current state:**
   - All files in `agents/prompts/`
   - All files in `agents/*.json`
   - `knowledge/rules.md`
   - `knowledge/gotchas.md`
   - `knowledge/episodes.md`
   - All files in `steering/`

2. **Check for gaps:**
   - Agent prompts missing guidance that exists in steering docs
   - Rules in steering that aren't reflected in agent deny lists
   - Gotchas that should be promoted to rules
   - Episodes that have been sitting active for too long
   - Inconsistencies between agents (e.g., one has a deny rule another lacks)
   - Skills referenced in agent configs that don't exist
   - Skills that exist but aren't referenced by any agent

3. **Check for staleness:**
   - Rules that may be outdated (platform changes, new features)
   - Gotchas that have been resolved by config changes
   - Agent prompts that reference deprecated patterns

4. **Output a structured proposal:**

## Self-Review Report — YYYY-MM-DD

### Gaps Found
- [x] [file] — description of gap

### Inconsistencies
- [x] [file vs file] — description of inconsistency

### Stale Items
- [x] [file:line] — what's stale and why

### Proposed Changes
For each finding, include:
- File to modify
- What to change
- Why

### No Action Needed
Items reviewed and found current.

5. **Present to user for approval.** Never auto-apply changes.

## Proactive Suggestions

When running self-review, also check:
- Are there new Kiro CLI features (check /help, introspect) that could improve the config?
- Are there patterns in recent sessions that suggest a new rule or gotcha?

If findings exist, append a "Proactive Suggestions" section to the report.
```

- [x] **Step 2: Verify skill file exists and is valid**

Run: `head -5 skills/self-review/SKILL.md`
Expected: Shows the frontmatter

- [x] **Step 3: Report completion**

---

### Task 7: Register self-review skill in orchestrator

Add the self-review skill to the orchestrator's resources and update the routing table.

**Files:**
- Modify: `agents/dev-orchestrator.json` — add skill resource
- Modify: `agents/prompts/orchestrator.md` — add to "Handle directly" triggers

- [x] **Step 1: Add skill resource to dev-orchestrator.json resources array**

Add: `"skill://~/.kiro/skills/self-review/SKILL.md"`

- [x] **Step 2: Update orchestrator prompt "Handle directly" triggers**

Add `self-review, review config, what can we improve` to the triggers line.

- [x] **Step 3: Verify both files updated**

Run: `grep 'self-review' agents/dev-orchestrator.json agents/prompts/orchestrator.md`
Expected: Matches in both files

- [x] **Step 4: Report completion**

---

### Task 8: Add session-end observation hook

Create a lightweight stop hook that logs session end timestamps.

**Files:**
- Create: `hooks/feedback/session-log.sh`
- Modify: `agents/dev-orchestrator.json` — add stop hook

- [x] **Step 1: Create the session log hook**

```bash
#!/usr/bin/env bash
set -euo pipefail
# Stop hook — appends session timestamp to log for self-review analysis.

LOG_DIR="$(cd "$(dirname "$0")/../../knowledge" 2>/dev/null && pwd)"
LOG_FILE="$LOG_DIR/session-log.txt"

echo "$(date -Iseconds) | session-end" >> "$LOG_FILE"
```

- [x] **Step 2: Add stop hook to orchestrator config hooks.stop array**

Add:
```json
{
  "command": "bash ~/.kiro/hooks/feedback/session-log.sh",
  "description": "Log session end timestamp for self-review analysis"
}
```

- [x] **Step 3: Verify hook syntax and config**

Run: `bash -n hooks/feedback/session-log.sh && echo "syntax ok"`
Expected: "syntax ok"

Run: `jq '.hooks.stop | length' agents/dev-orchestrator.json`
Expected: 2

- [x] **Step 4: Report completion**
