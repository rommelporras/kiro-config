---
name: agent-audit
description: Audits agents, prompts, skills, and knowledge for gaps, inconsistencies, and improvement opportunities. Proposes changes for user approval. Triggers on "agent-audit", "audit agents", "review config", "what can we improve".
---

# Agent Audit

Analyze the current kiro-config and propose improvements.

**Announce at start:** "Running agent-audit against current kiro-config."

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

## Agent Audit Report — YYYY-MM-DD

### Gaps Found
- [ ] [file] — description of gap

### Inconsistencies
- [ ] [file vs file] — description of inconsistency

### Stale Items
- [ ] [file:line] — what's stale and why

### Proposed Changes
For each finding, include:
- File to modify
- What to change
- Why

### No Action Needed
Items reviewed and found current.

5. **Present to user for approval.** Never auto-apply changes.

## Proactive Suggestions

When running agent-audit, also check:
- Are there new Kiro CLI features (check /help, introspect) that could improve the config?
- Are there patterns in recent sessions that suggest a new rule or gotcha?

If findings exist, append a "Proactive Suggestions" section to the report.
