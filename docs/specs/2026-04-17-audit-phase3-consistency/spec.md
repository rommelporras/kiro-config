# Phase 3: Consistency — Reduce Drift

**Date:** 2026-04-17
**Source:** `docs/specs/audit-current-workflow.md` (Round 3 final)
**Scope:** HIGH (was C-01), CRITICAL-07, HIGH (was C-06), HIGH-01, HIGH-12, HIGH-09

---

## Goal

Eliminate prompt/steering duplication so updates to steering docs don't
create contradictions. Fix doc count drift, hardcoded paths, overly broad
write permissions, and add file-conflict detection to execution planning.

---

## Item 1: Prompt Dedup — HIGH (was CRITICAL-01)

### Current State Analysis

| Prompt | Lines | Duplicates from steering | Agent-specific content |
|---|---|---|---|
| python-dev.md | 70 | ~30 lines from python-boto3.md, tooling.md | Python 3.12+ syntax list, boto3 patterns, subprocess patterns |
| shell-dev.md | 63 | ~20 lines from shell-bash.md, tooling.md | (almost entirely duplicated — very little unique) |
| typescript-dev.md | 61 | ~20 lines from typescript.md, tooling.md | Zod patterns, Express typed handlers |
| frontend-dev.md | 73 | ~15 lines from frontend.md | Verification checklist (excellent, keep) |
| code-reviewer.md | 100 | ~10 lines from engineering.md | Review dimensions, structural checks, checklists, scan mode |
| refactor.md | 75 | ~5 lines from design-principles.md | Refactoring operations, finding-handling workflow |
| docs.md | 29 | 0 | (too thin — needs expansion, not reduction) |
| orchestrator.md | 169 | ~10 lines from engineering.md, universal-rules.md | Routing table, delegation format, workflows |

### Design Decision: What stays vs what goes

**Target structure for each prompt (from audit):**
1. Identity (1-2 lines: who you are)
2. Workflow (numbered steps: how you work)
3. Status reporting (DONE/DONE_WITH_CONCERNS/NEEDS_CONTEXT/BLOCKED)
4. Before editing (3-question pre-check)
5. What you never do (hard constraints)
6. Steering reference ("Follow [domain] standards from steering docs")
7. Agent-specific sections that DON'T exist in steering

**What gets removed (duplicated with steering):**
- "Your standards" bullet lists that restate steering rules
- "Critical patterns" sections that restate steering rules
- Tool-specific rules already in tooling.md (uv, ruff, npm, shellcheck, etc.)

**What stays (agent-specific, NOT in steering):**
- python-dev.md: subprocess patterns, pathlib preference, PEP 695 syntax,
  concurrent.futures/threading patterns — these are Python-specific
  implementation patterns not in python-boto3.md or tooling.md
- typescript-dev.md: Zod schema-first pattern, Express typed handlers,
  error middleware signature — not in typescript.md
- frontend-dev.md: verification checklist, Chart.js specifics — not in frontend.md
- code-reviewer.md: review dimensions, structural quality checks, checklists,
  scan mode — almost entirely unique (this prompt barely needs trimming)
- refactor.md: refactoring operations list, finding-handling workflow — unique
- shell-dev.md: almost nothing unique — heaviest trim candidate
- docs.md: needs EXPANSION not reduction (too thin at 29 lines)

### Design Decision: One task per prompt vs batch

**Recommendation: one task per prompt.** Reasons:
- Each prompt has different duplication patterns — no single template works
- Safer rollback if one rewrite goes wrong
- Easier review (reviewer can focus on one prompt at a time)
- Parallel-safe (each task touches exactly one file)

**Exception:** docs.md expansion and orchestrator.md fixes are small enough
to combine into one task.

### Design Decision: Agent-specific interpretations

Some prompts have agent-specific *interpretations* of steering rules that
add value beyond the steering doc. These should be preserved as brief
one-line bullet references, not full explanations or tutorials.

**Standardized steering-reference template (all prompts use this exact phrasing):**

```markdown
## Standards
Follow <domain>-specific rules from steering: <list applicable steering docs>.
Agent-specific patterns below are interpretations — steering is the authority.
```

**Hard constraint on design principles:** Do NOT create a section listing
design principles. Do NOT enumerate Rule of Three, Fail Fast, etc. under
any heading. If needed, one inline reference to `steering/design-principles.md`
only. This applies to all prompts.

**Agent-specific patterns are one-line bullets with steering references:**

Example for typescript-dev.md:
```markdown
## Agent-specific patterns
- Zod schemas for all external input (see typescript.md for schema-first rules)
- Express handlers typed with `Request`/`Response` generics (see web-development.md)
- 4-param error middleware pattern (see web-development.md)
```

Example for frontend-dev.md:
```markdown
## Agent-specific patterns
- Chart.js: destroy before recreate, typed configs (see frontend.md)
- Fetch wrapper with typed generics and error/loading/empty states
```

### Design Decision: docs.md expansion

docs.md is the thinnest prompt (29 lines) and needs expansion, not reduction.
Target ~50 lines. Content from audit PROMPT-CROSS-01 through PROMPT-CROSS-07:

- Operating context block (subagent invoked by orchestrator, 5-section
  delegation format, status reporting)
- Available tools (read, write, shell, code — no MCP, no grep/glob/web_search)
- Full status protocol with definitions for each status
- "What you never do" (no source code, no git, no file deletions — NEEDS_CONTEXT)
- Before-editing block (read first, minimal change, check references)
- Error recovery guidance (tool not installed → skip and note, file not found → NEEDS_CONTEXT)

### Design Decision: code-reviewer.md agent config checklist

Per audit finding R-3, the "Agent config checklist" section (lines 83-88)
is kiro-config-specific and doesn't belong in the reviewer prompt. Move it
to `.kiro/steering/agent-config-review.md` as project-level steering.
Reviewer drops from ~100 to ~80 lines.

### Design Decision: One task per prompt

Each prompt gets its own delegate task. Parallel-safe since each touches
one file. Exception: docs.md expansion and orchestrator.md path fix are
small changes on different files — combine into one task.

---

## Item 2: Knowledge Rules Dedup — CRITICAL-07

**Status: ALREADY DONE.** The duplicated rule groups (refactor/extract and
library/module) were discarded in the pre-Phase 3 cleanup. Verified:
`knowledge/rules.md` has no content duplicating `steering/design-principles.md`.

No work needed. Mark as resolved.

---

## Item 3: File Conflict Pre-Check — HIGH (was CRITICAL-06)

**Problem:** `execution-planning/SKILL.md` has no enforcement mechanism to
prevent parallel tasks from touching the same file.

**File:** `skills/execution-planning/SKILL.md`

**Change:** Add to the "Rules" section:

```markdown
- Before marking tasks as parallel-safe, cross-check file lists across all
  tasks in the same stage. If any file appears in two tasks within the same
  parallel stage, move one task to a later stage. This is a hard gate — do
  not rely on "the agents will coordinate."
```

---

## Item 4: Steering Count — HIGH-01

**Problem:** README.md, kiro-cli-install-checklist.md, team-onboarding.md,
and base.json welcomeMessage all say "10 steering docs." Actual count is
now 11 (design-principles.md was added).

**Files:**
- `README.md`
- `docs/setup/kiro-cli-install-checklist.md`
- `docs/setup/team-onboarding.md`
- `agents/base.json` (welcomeMessage field)

**Change:** Replace "10 steering" with "11 steering" in all 4 files.

---

## Item 5: Hardcoded Improvement Path — HIGH-12

**Problem:** `orchestrator.md` and `post-implementation/SKILL.md` both
hardcode `~/personal/kiro-config/docs/improvements/pending.md`.

**Files:**
- `agents/prompts/orchestrator.md`
- `skills/post-implementation/SKILL.md`

**Change:** Replace with `~/.kiro/docs/improvements/pending.md` in both
files. Requires a new `~/.kiro/docs` symlink (see Item 7 below).

**Prerequisite:** A `docs` symlink must be added to `~/.kiro/` pointing to
the repo's `docs/` directory, matching the existing pattern (agents, hooks,
skills, settings, steering are all symlinked). This is handled by updating
`scripts/personalize.sh` to create the symlink.

---

## Item 6: Orchestrator Write Paths — HIGH-09

**Problem:** `dev-orchestrator.json` has `"*.md"` in `fs_write.allowedPaths`,
which matches any markdown file anywhere on the system.

**File:** `agents/dev-orchestrator.json`

**Change:** Remove `"*.md"` from `allowedPaths`. The remaining paths
(`"docs/**"`, `"~/personal/**"`, `"~/eam/**"`) already cover all legitimate
orchestrator write targets.

---

## Verification Criteria

After all changes:

1. Each prompt file is 40-60 lines (except orchestrator ~165, code-reviewer ~95,
   docs ~50 — these have legitimate unique content)
2. `grep -r '10 steering' README.md docs/setup/` → zero matches
3. `grep -r '11 steering' README.md docs/setup/` → matches in all 3 files
4. `grep 'personal/kiro-config' agents/prompts/orchestrator.md skills/post-implementation/SKILL.md` → zero matches
5. `grep '~/.kiro/docs/improvements' agents/prompts/orchestrator.md skills/post-implementation/SKILL.md` → matches in both
6. `jq '.toolsSettings.fs_write.allowedPaths' agents/dev-orchestrator.json` → no `*.md` entry
7. `grep 'cross-check file lists' skills/execution-planning/SKILL.md` → match
8. No steering content restated verbatim in any prompt

> Note: as of v0.7.0, dev-* agents were renamed to devops-*. See docs/specs/2026-04-18-devops-terraform-and-rename/spec.md.
