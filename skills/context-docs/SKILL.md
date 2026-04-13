---
name: context-docs
description: >
  Triggers on: 'create context docs', 'set up AI knowledge base',
  'docs/context', 'context knowledge base'
---

# Skill: context-docs

> **Handled DIRECTLY by the orchestrator — do not delegate to subagents.**

Creates a `docs/context/` AI knowledge base: structured markdown files any AI
tool (Kiro, Claude Code, Copilot) can use as quick-reference context.

## Principle

Context docs are tool-agnostic. `.kiro/` configs and agent prompts just point
at them. One source of truth, any consumer.

## Process

### Step 1 — Scan (get approval before proceeding)
Scan the project for existing context sources:
- Steering docs (`.kiro/steering/`)
- README and docs/
- Agent prompts and skill files
- Config files (`pyproject.toml`, `package.json`, etc.)

Report what you found. Ask user to confirm before continuing.

### Step 2 — Propose structure (get approval before proceeding)
Propose a topic-per-file layout. Always include `_Index.md`.

Default topics (adapt per project):
- `_Index.md` — entry point, quick links, current state
- `Infrastructure.md` — cloud resources, clusters, naming conventions
- `Environments.md` — env names, AWS profiles, regions
- `Tools.md` — CLI tools, package managers, linters, test runners
- `Conventions.md` — coding standards, naming, commit format
- `Workflows.md` — dev workflow, branching, deploy process

Add project-specific topics as needed. Present the list and get approval.

### Step 3 — Extract and write (get approval before proceeding)
Pull content from existing sources into context docs. Consolidate — don't
duplicate. Show the user the proposed content for each file before writing.

### Step 4 — Update references
Make steering docs thin pointers to `docs/context/`. Update agent prompts and
skills that referenced scattered info to point to the new files instead.

Show the diff of what will change. Get approval before writing.

### Step 5 — Verify
After all writes are complete:
- Check every link in `_Index.md` resolves to an existing file
- Grep steering docs for content that should have been replaced by pointers — flag any remaining duplication
- Grep agent prompts and skills for old paths that should now point to `docs/context/`
- Report any broken references or leftover duplication before declaring done

## File format

Each context doc:
```markdown
---
tags: [context, <topic>]
updated: YYYY-MM-DD
---

# Topic Title

Content organized with tables and code blocks for quick scanning.
```

## _Index.md format

```markdown
---
tags: [context, index]
updated: YYYY-MM-DD
---

# Project Context Index

> Canonical source of truth for AI tools. Last updated: YYYY-MM-DD.

| Need | Go To |
|------|-------|
| Cluster names / AWS setup | Infrastructure.md |
| Env names / profiles | Environments.md |
| ... | ... |

## Current State

| Item | Value |
|------|-------|
| Active env | ... |
| ... | ... |
```
