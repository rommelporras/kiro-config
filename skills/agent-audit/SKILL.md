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
- `docs/improvements/pending.md` ← **primary input** (read first if it exists)

### Phase 2: improvements/pending.md analysis

If `docs/improvements/pending.md` exists, process it before any other analysis:

- Read every entry — each has a date, project path, what went wrong, and a suggested fix
- Group entries by root cause type: `steering gap` | `routing issue` | `missing skill` | `missing context`
- Identify patterns: 3+ entries with the same root cause = high-priority fix
- Cross-reference each entry against the current config files to check if it's already been resolved
- Entries that are already resolved → move to `docs/improvements/resolved.md` (after user approval)
- Entries still unresolved → produce actionable proposals: "add X to Y.md", "update routing trigger Z"

**Cross-project awareness:** Improvement entries include the project path where friction occurred. Use this to identify patterns across projects without scanning those directories directly:
- Multiple entries from the same project mentioning a language → check if a steering doc exists for that language
- Routing corrections in entries → check if the routing table has the missing pattern
- Missing context entries → check if a context doc or gotcha covers that gap

### Phase 3: Skill coverage analysis

For each skill in `skills/*/SKILL.md`:
- Read the `description` frontmatter — this is what the orchestrator matches against
- Compare trigger phrases against how users actually phrase requests (use improvement entries as signal)
- Flag triggers that are too narrow (miss common phrasings) or too broad (overlap with other skills)
- Check: does the trigger description match real user phrasing, or is it written in system terminology?

### Phase 4: Check agent and skill consistency

- Agent prompts missing guidance that exists in steering docs
- Rules in steering that aren't reflected in agent deny lists
- Gotchas that should be promoted to rules
- Episodes that have been sitting active for too long
- Inconsistencies between agents (e.g., one has a deny rule another lacks)
- Skills referenced in agent configs that don't exist on disk
- Skills that exist on disk but aren't referenced by any agent
- deniedCommands lists that differ between subagents (should be identical)

### Phase 5: Steering effectiveness check

For each file in `steering/`:
- Are the rules specific enough to act on, or are they vague guidance?
- Do any rules reference tools, APIs, or patterns that no longer exist?
- Are there rules that contradict each other across steering docs?
- Flag rules that are too vague: "be careful" → needs a concrete action
- Flag rules that are outdated: reference deprecated patterns or old file paths

### Phase 6: Knowledge hygiene

Review `knowledge/episodes.md` and `knowledge/rules.md`:
- **Promotion candidates:** Episodes that have recurred 2+ times → propose promoting to a rule
- **Stale rules:** Rules that reference resolved issues, deprecated tools, or old file structures
- **Duplication:** Any section in `knowledge/gotchas.md` or `knowledge/rules.md` longer than 3 lines that substantially overlaps with content in steering docs or agent prompts — gotchas and rules should be short pointers, not full copies of checklists

### Phase 7: Routing review

Examine the orchestrator's routing table:
- **Dead routes:** Triggers that haven't fired recently (use improvement entries as signal)
- **Overlapping triggers:** Two routes with similar trigger words — which one wins?
- **Missing patterns:** Improvement entries with "routing correction" root cause → what trigger was missing?
- **Skill trigger drift:** Compare skill `description` frontmatter against the routing table entries that reference them

### Phase 8: Check documentation consistency

Cross-reference documentation files against source-of-truth config files:

**Skill counts:**
- Count `skills/*/SKILL.md` files on disk
- Compare against counts in `README.md`, agent welcome messages, `docs/reference/skill-catalog.md`
- Flag mismatches

**Skill assignment matrix:**
- For each agent JSON, extract the `skill://` entries from `resources`
- Compare against the matrix in `docs/reference/skill-catalog.md` and `README.md`
- Flag any agent that has a skill in its JSON but not in the matrix (or vice versa)

**Skill descriptions:**
- For each skill in `docs/reference/skill-catalog.md`, compare the "Activates when you say..." column against the actual SKILL.md `description` frontmatter
- Flag descriptions that have drifted

**File paths in docs:**
- Check that file paths mentioned in skill-catalog match the actual paths in the skill's SKILL.md content
- Check that file paths in steering docs reference files that exist
- Check that hook scripts referenced in agent JSON hooks exist on disk

**Steering and MCP counts:**
- Count `steering/*.md` files on disk
- Count MCP servers across all agent configs
- Compare against counts mentioned in README or docs

**Agent tool alignment:**
- For each agent JSON, verify every tool in `allowedTools` is also in `tools`
- Cross-check MCP servers: if an agent references an MCP tool, verify the MCP server is available

**Welcome message accuracy:**
- Check that counts in welcome messages match actual counts for that agent's loaded resources

**Directory tree verification:**
- For each directory tree in README.md, verify every listed file exists on disk
- Check for files on disk that exist in listed directories but are missing from the tree
- Flag any mismatch (file listed but missing, or file exists but unlisted)

**Feature count verification:**
- For each count in the Features section (e.g., "10 steering docs", "18 skills", "8 hooks"), verify the number against the actual filesystem
- Flag any count that doesn't match

### Phase 9: Check for staleness

- Rules that may be outdated (platform changes, new features)
- Gotchas that have been resolved by config changes
- Agent prompts that reference deprecated patterns

### Phase 9.5: Project-level .kiro/ audit

When the current workspace has a `.kiro/` directory (project-level config), also check:

- **Path validity:** Do `allowedPaths` in agent JSON files reference directories that actually exist?
- **Knowledge base sources:** Do `knowledgeBase` `source` paths point to directories that exist?
- **Prompt file references:** Do file paths mentioned in agent prompts reference files that exist?
- **Stale structure references:** Do prompts or skills reference folder patterns from a previous project structure?
- **docs/context/ alignment:** If `docs/context/` exists, check that steering docs point to it rather than duplicating its content.

Skip this phase if the workspace has no `.kiro/` directory.

### Phase 10: Output structured report

```
## Agent Audit Report — YYYY-MM-DD

### Improvements Backlog (from pending.md)
- [ ] [entry date + project] — proposed fix

### Skill Coverage Gaps
- [ ] [skill] — trigger mismatch or missing phrasing

### Steering Effectiveness
- [ ] [file:rule] — too vague / outdated

### Knowledge Hygiene
- [ ] [episode/rule] — promotion candidate or stale

### Routing Issues
- [ ] [route] — dead / overlapping / missing

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

### Resolved (pending.md items already fixed)
Items that can be moved to resolved.md.

### No Action Needed
Items reviewed and found current.
```

Present to user for approval. Never auto-apply changes.
After user approves resolved items, move them from `docs/improvements/pending.md` to `docs/improvements/resolved.md`.

## Proactive Suggestions

When running agent-audit, also check:
- Are there new Kiro CLI features (check /help, introspect) that could improve the config?
- Are there patterns in recent sessions that suggest a new rule or gotcha?

If findings exist, append a "Proactive Suggestions" section to the report.
