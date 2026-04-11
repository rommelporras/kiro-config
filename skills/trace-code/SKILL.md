---
name: trace-code
description: Deep code flow tracing with file:line references. Use when the user says "trace this", "how does this feature work end-to-end", "map the code flow", "what files are involved in", "walk through the execution".
---

# Trace Code

Trace a feature's implementation from entry point to output, through all layers.

**Announce at start:** "Tracing [feature/flow name]."

## Process

1. **Find entry points** — CLI commands, API endpoints, script main blocks
2. **Follow call chains** — trace each function call with file:line references
3. **Map data flow** — what goes in, how it transforms, what comes out
4. **Identify dependencies** — external libraries, AWS services, config files
5. **Note cross-cutting concerns** — error handling, logging, auth, retries

## Output Format

### Entry Point
`file.py:42` — description of where execution starts

### Execution Flow
1. `file.py:42` → `module.py:15` — what happens at each step
2. `module.py:15` → `aws.py:88` — data transformation or side effect

### Key Components
- `component.py` — responsibility summary

### Dependencies
- External: boto3, rich, etc.
- Config: files or env vars read

### Essential Files
List of files someone must read to understand this feature.

## Guidelines

- Always include file:line references — never describe without pointing to code
- Trace the happy path first, then note error/edge case branches
- Keep it factual — describe what the code does, not what it should do
