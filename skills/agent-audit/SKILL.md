---
name: agent-audit
description: Audits agents, prompts, skills, knowledge, and documentation for gaps, inconsistencies, and improvement opportunities. Proposes changes for user approval. Triggers on "agent-audit", "audit agents", "review config", "what can we improve".
---

# Agent Audit

Analyze the current kiro-config and propose improvements.

**Announce at start:** "Running agent-audit against current kiro-config."

## Process

### Phase 1: Read current state

Read all of these files:
- All files in `agents/prompts/`
- All files in `agents/*.json`
- `knowledge/rules.md`
- `knowledge/gotchas.md`
- `knowledge/episodes.md`
- All files in `steering/`
- All files in `skills/*/SKILL.md` (frontmatter only — name, description)
- `docs/reference/skill-catalog.md`
- `docs/reference/security-model.md`
- `docs/reference/creating-agents.md`
- `README.md`

### Phase 2: Check agent and skill consistency

- Agent prompts missing guidance that exists in steering docs
- Rules in steering that aren't reflected in agent deny lists
- Gotchas that should be promoted to rules
- Episodes that have been sitting active for too long
- Inconsistencies between agents (e.g., one has a deny rule another lacks)
- Skills referenced in agent configs that don't exist on disk
- Skills that exist on disk but aren't referenced by any agent
- deniedCommands lists that differ between subagents (should be identical)

### Phase 3: Check documentation consistency

Cross-reference documentation files against source-of-truth config files:

**Skill counts:**
- Count `skills/*/SKILL.md` files on disk
- Compare against counts in `README.md`, agent welcome messages,
  `docs/reference/skill-catalog.md`, and any other files that mention
  skill counts
- Flag mismatches

**Skill assignment matrix:**
- For each agent JSON, extract the `skill://` entries from `resources`
- Compare against the matrix in `docs/reference/skill-catalog.md`
- Compare against the matrix in `README.md`
- Flag any agent that has a skill in its JSON but not in the matrix
  (or vice versa)

**Skill descriptions:**
- For each skill in `docs/reference/skill-catalog.md`, compare the
  "Activates when you say..." column against the actual SKILL.md
  `description` frontmatter
- Flag descriptions that have drifted

**File paths in docs:**
- Check that file paths mentioned in skill-catalog (e.g., "Saves to
  `docs/specs/`") match the actual paths in the skill's SKILL.md content
- Check that file paths in steering docs reference files that exist
- Check that hook scripts referenced in agent JSON hooks exist on disk

**Steering and MCP counts:**
- Count `steering/*.md` files on disk
- Count MCP servers across all agent configs
- Compare against counts mentioned in README or docs
- Flag mismatches

**Agent tool alignment:**
- For each agent JSON, verify every tool in `allowedTools` is also
  in `tools`
- Flag any tool in `allowedTools` that is not in `tools`
- Cross-check MCP servers: if an agent references an MCP tool, verify
  the MCP server is available (via `includeMcpJson` or inline config)

**Welcome message accuracy:**
- Check that counts in welcome messages (skill count, steering count)
  match actual counts for that agent's loaded resources

### Phase 4: Check for staleness

- Rules that may be outdated (platform changes, new features)
- Gotchas that have been resolved by config changes
- Agent prompts that reference deprecated patterns

### Phase 5: Output structured report

## Agent Audit Report — YYYY-MM-DD

### Config Gaps
- [ ] [file] — description of gap

### Documentation Drift
- [ ] [doc file vs source file] — what's inconsistent

### Stale Items
- [ ] [file:line] — what's stale and why

### Proposed Changes
For each finding, include:
- File to modify
- What to change
- Why

### No Action Needed
Items reviewed and found current.

Present to user for approval. Never auto-apply changes.

## Proactive Suggestions

When running agent-audit, also check:
- Are there new Kiro CLI features (check /help, introspect) that could
  improve the config?
- Are there patterns in recent sessions that suggest a new rule or gotcha?

If findings exist, append a "Proactive Suggestions" section to the report.
