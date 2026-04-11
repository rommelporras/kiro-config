---
name: research-practices
description: Researches current best practices for a specific topic and proposes kiro-config updates. Triggers on "research practices", "best practices for", "what's the latest on".
---

# Research Practices

Research current best practices for a specific topic and propose config improvements.

**Announce at start:** "Researching best practices for [topic]."

## When to Use

- Agent-audit identified a gap with no clear fix
- User asks about best practices for a tool or pattern
- Proactive check on whether current steering rules are still current

## Process

1. **Clarify scope:** What specific topic? (e.g., "boto3 error handling", "shellcheck rules", "Terraform module patterns")

2. **Research using available tools (in order of preference):**
   - Context7 for library-specific docs
   - web_search for broader patterns
   - web_fetch for specific URLs from official docs

3. **Compare findings against current config:**
   - Read relevant steering files, agent prompts, and rules
   - Identify gaps between current practices and researched best practices
   - Note any current rules that contradict findings

4. **Output a structured proposal:**

## Research Report — [Topic]

### Sources Consulted
- [source 1]
- [source 2]

### Key Findings
- Finding 1
- Finding 2

### Current State in Config
- What we already cover
- What we're missing

### Proposed Changes
For each change:
- File to modify
- What to add/change
- Source justification

5. **Present to user for approval.** Never auto-apply changes.

## Scope Limits

- One topic per research session — don't boil the ocean
- Prefer official docs over blog posts or Stack Overflow
- If findings conflict with existing rules, present both sides — don't assume the new way is better
- Cap research at 3 web searches + 3 Context7 queries to avoid rabbit holes
