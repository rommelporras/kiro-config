# Kiro CLI Orchestrator Workflow — Migration Plan

> **Status: COMPLETED** — All phases implemented. Superseded by
> `docs/specs/2026-04-16-orchestrator-agent-framework-redesign/spec.md`
> which redesigns the orchestrator with skill consolidation (19→12),
> automated workflows, and new agents.

> **Purpose:** This document is the complete specification for migrating the
> `rommelporras/kiro-config` repository from a single `base` agent with 12
> globally-loaded skills to a multi-agent orchestrator pattern with curated
> skill assignments. It is designed to be fed to Kiro CLI (or any agentic
> tool) for analysis and implementation.

---

## Table of Contents

1. Current State Audit
2. Target Architecture
3. Migration Phases
4. Orchestrator Agent — Config + Prompt
5. Subagent Configs + Prompts
6. New Skills
7. Existing Skill Reassignment
8. Interaction Matrix
9. Security Analysis
10. File Operations Summary
11. Open Questions

---

## 1. Current State Audit

### Repository: `rommelporras/kiro-config`

Symlinked to `~/.kiro/` via:

```bash
for dir in steering agents skills settings hooks; do
  ln -sfn ~/personal/kiro-config/$dir ~/.kiro/$dir
done
```

### Current files

```
kiro-config/
├── agents/
│   ├── base.json                      # Active default agent
│   └── agent_config.json.example      # Template
├── skills/
│   ├── brainstorming/SKILL.md
│   ├── commit/SKILL.md
│   ├── dispatching-parallel-agents/SKILL.md
│   ├── explain-code/SKILL.md
│   ├── push/SKILL.md
│   ├── python-audit/SKILL.md
│   ├── receiving-code-review/SKILL.md
│   ├── subagent-driven-development/SKILL.md
│   ├── systematic-debugging/SKILL.md
│   ├── test-driven-development/SKILL.md
│   ├── verification-before-completion/SKILL.md
│   └── writing-plans/SKILL.md
├── steering/
│   ├── engineering.md
│   ├── tooling.md
│   └── universal-rules.md
├── settings/
│   ├── cli.json
│   └── mcp.json
├── hooks/
│   ├── scan-secrets.sh
│   ├── protect-sensitive.sh
│   ├── bash-write-protect.sh
│   └── notify.sh
└── docs/
    ├── setup/
    └── reference/
```

### Known issues in current state

1. **Tool name inconsistency.** `base.json` uses legacy names (`fs_read`,
   `fs_write`, `execute_bash`, `use_aws`). The `agent_config.json.example`
   uses current names (`read`, `write`, `shell`, `aws`). Kiro CLI has had
   bugs around `allowedTools` not loading with certain name variants
   (kirodotdev/Kiro#6714). Standardize to current names.

2. **All skills loaded globally.** `base.json` uses
   `skill://~/.kiro/skills/*/SKILL.md` — every skill loads for every session.
   Most never trigger because the base agent is a generalist.

3. **No system prompt.** `base.json` has `"prompt": null`. The agent has no
   identity, routing logic, or behavioral constraints.

4. **README says 11 skills.** There are 12 — `python-audit` is missing from
   the count.

5. **Existing skill chain is implicit.** `writing-plans` hands off to
   `subagent-driven-development`, which references `verification-before-completion`
   and `test-driven-development`. This chain works but is undocumented and
   never triggers because there's no orchestrator to drive it.

---

## 2. Target Architecture

### Design principles

- **One agent to talk to.** The orchestrator is the default. The user never
  swaps agents manually.
- **Orchestrator never writes code.** It converses, plans, routes, and
  aggregates. Code writing is always delegated.
- **Skills are curated per agent.** No global wildcard loading. Each agent
  gets only the skills relevant to its role.
- **Prompts live in markdown.** Agent JSON references `file://` prompts.
  The intelligence is portable; the JSON is Kiro-native wiring.
- **Security hooks protect the orchestrator.** Subagents are protected via
  `toolsSettings` restrictions since hooks don't fire in subagents.

### Target file tree

```
kiro-config/
├── agents/
│   ├── prompts/
│   │   ├── orchestrator.md            # NEW — routing, identity, boundaries
│   │   ├── python-dev.md              # NEW — Python specialist prompt
│   │   ├── shell-dev.md               # NEW — Shell/Bash specialist prompt
│   │   ├── code-reviewer.md           # NEW — Read-only reviewer prompt
│   │   └── refactor.md               # NEW — Refactoring specialist prompt
│   ├── orchestrator.json              # NEW — default agent
│   ├── python-dev.json                # NEW — subagent
│   ├── shell-dev.json                 # NEW — subagent
│   ├── code-reviewer.json             # NEW — subagent
│   ├── refactor.json                  # NEW — subagent
│   ├── base.json                      # MODIFIED — kept as standalone fallback
│   └── agent_config.json.example      # MODIFIED — updated template
├── skills/
│   ├── spec-workflow/SKILL.md         # NEW
│   ├── delegation-protocol/SKILL.md   # NEW
│   ├── aggregation/SKILL.md           # NEW
│   ├── brainstorming/SKILL.md         # KEEP — orchestrator skill
│   ├── commit/SKILL.md                # KEEP — orchestrator skill
│   ├── dispatching-parallel-agents/SKILL.md  # KEEP — orchestrator skill
│   ├── explain-code/SKILL.md          # KEEP — shared skill
│   ├── push/SKILL.md                  # KEEP — orchestrator skill
│   ├── python-audit/SKILL.md          # KEEP — code-reviewer + python-dev skill
│   ├── receiving-code-review/SKILL.md # KEEP — execution agent skill
│   ├── subagent-driven-development/SKILL.md  # KEEP — orchestrator skill
│   ├── systematic-debugging/SKILL.md  # KEEP — execution agent skill
│   ├── test-driven-development/SKILL.md      # KEEP — execution agent skill
│   ├── verification-before-completion/SKILL.md # KEEP — execution agent skill
│   └── writing-plans/SKILL.md         # KEEP — orchestrator skill
├── steering/                          # UNTOUCHED
├── settings/
│   ├── cli.json                       # MODIFIED — default agent → orchestrator
│   └── mcp.json                       # UNTOUCHED
├── hooks/                             # UNTOUCHED
└── docs/
    └── reference/
        ├── skill-catalog.md           # MODIFIED — updated for new skills + assignments
        ├── creating-agents.md         # MODIFIED — updated for orchestrator pattern
        └── ...
```

---

## 3. Migration Phases

### Phase 1: Normalize and fix (no behavior change)

1. Update `base.json` tool names: `fs_read` → `read`, `fs_write` → `write`,
   `execute_bash` → `shell`, `use_aws` → `aws`. Update `toolsSettings` keys
   to match.
2. Fix README skill count: 12 skills, not 11.
3. Test that `base.json` still works after rename.

### Phase 2: Create agent prompts

1. Create `agents/prompts/` directory.
2. Write all 5 prompt files (orchestrator, python-dev, shell-dev,
   code-reviewer, refactor).
3. No JSON changes yet — prompts are just files on disk.

### Phase 3: Create subagent JSON configs

1. Create `python-dev.json`, `shell-dev.json`, `code-reviewer.json`,
   `refactor.json` in `agents/`.
2. Each references its prompt via `file://` and has curated skill lists.
3. Test each subagent individually: `/agent swap python-dev` etc.

### Phase 4: Create orchestrator

1. Create `orchestrator.json` in `agents/`.
2. Update `settings/cli.json`: `"chat.defaultAgent": "orchestrator"`.
3. Test basic routing — does it delegate correctly?

### Phase 5: Create new skills

1. Create `skills/spec-workflow/SKILL.md`.
2. Create `skills/delegation-protocol/SKILL.md`.
3. Create `skills/aggregation/SKILL.md`.
4. Test each triggers in the orchestrator context.

### Phase 6: Update base agent

1. `base.json` becomes a standalone fallback agent (no subagent capability).
2. Update `agent_config.json.example` to reflect new patterns.
3. Update docs: `skill-catalog.md`, `creating-agents.md`.

---

## 4. Orchestrator Agent

### orchestrator.json

```json
{
  "name": "orchestrator",
  "description": "Primary agent — converses with user, plans work, delegates implementation to specialist subagents. Never writes code directly.",
  "prompt": "file://./prompts/orchestrator.md",
  "welcomeMessage": "Orchestrator active — I handle planning and conversation directly, and delegate coding to specialist subagents. What are we working on?",
  "model": null,

  "tools": [
    "read",
    "write",
    "shell",
    "subagent",
    "introspect",
    "grep",
    "glob",
    "web_fetch",
    "web_search",
    "code",
    "@context7",
    "@awslabs.aws-documentation-mcp-server",
    "@awslabs.aws-diagram-mcp-server"
  ],

  "allowedTools": [
    "read",
    "grep",
    "glob",
    "introspect",
    "web_fetch",
    "web_search",
    "code",
    "@context7",
    "@awslabs.aws-documentation-mcp-server",
    "@awslabs.aws-diagram-mcp-server"
  ],

  "toolAliases": {},

  "toolsSettings": {
    "read": {
      "allowedPaths": ["~/.kiro", "~/personal", "~/eam"],
      "deniedPaths": ["~/.ssh", "~/.aws/credentials", "~/.gnupg", "~/.config/gh", "~/.kiro/settings/cli.json"]
    },
    "write": {
      "allowedPaths": [".kiro/specs/**", "docs/**", "*.md"],
      "deniedPaths": ["~/.ssh", "~/.aws", "~/.gnupg", "~/.config/gh", "~/.kiro/settings/cli.json", "~/.kiro/agents", "~/.kiro/hooks", "~/.kiro/steering"]
    },
    "shell": {
      "autoAllowReadonly": true,
      "allowedCommands": [
        "git add .*",
        "git commit .*",
        "git stash.*",
        "git checkout .*",
        "git switch .*",
        "git branch.*",
        "git push .*",
        "readlink .*",
        "find .*"
      ],
      "deniedCommands": [
        "rm .*",
        "chmod -R 777 /",
        "mkfs\\.",
        "dd if=/dev",
        "> /dev/sd",
        "> /dev/nvme"
      ]
    },
    "subagent": {
      "availableAgents": [
        "python-dev",
        "shell-dev",
        "code-reviewer",
        "refactor"
      ],
      "trustedAgents": [
        "python-dev",
        "shell-dev",
        "code-reviewer",
        "refactor"
      ]
    }
  },

  "resources": [
    "file://~/.kiro/steering/**/*.md",
    "file://.kiro/steering/**/*.md",
    "skill://~/.kiro/skills/brainstorming/SKILL.md",
    "skill://~/.kiro/skills/commit/SKILL.md",
    "skill://~/.kiro/skills/push/SKILL.md",
    "skill://~/.kiro/skills/explain-code/SKILL.md",
    "skill://~/.kiro/skills/writing-plans/SKILL.md",
    "skill://~/.kiro/skills/dispatching-parallel-agents/SKILL.md",
    "skill://~/.kiro/skills/subagent-driven-development/SKILL.md",
    "skill://~/.kiro/skills/spec-workflow/SKILL.md",
    "skill://~/.kiro/skills/delegation-protocol/SKILL.md",
    "skill://~/.kiro/skills/aggregation/SKILL.md"
  ],

  "hooks": {
    "preToolUse": [
      {
        "matcher": "fs_write",
        "command": "bash ~/.kiro/hooks/scan-secrets.sh",
        "timeout_ms": 5000
      },
      {
        "matcher": "fs_write",
        "command": "bash ~/.kiro/hooks/protect-sensitive.sh",
        "timeout_ms": 3000,
        "cache_ttl_seconds": 60
      },
      {
        "matcher": "execute_bash",
        "command": "bash ~/.kiro/hooks/bash-write-protect.sh",
        "timeout_ms": 5000
      }
    ],
    "stop": [
      {
        "command": "bash ~/.kiro/hooks/notify.sh",
        "description": "Play notification sound when agent finishes"
      }
    ]
  },

  "includeMcpJson": true,
  "keyboardShortcut": "ctrl+o"
}
```

**Design notes:**

- `write` restricted to `.kiro/specs/**`, `docs/**`, and `*.md` — the
  orchestrator can create spec files and docs but NOT code files.
- `shell` includes `git push` (unlike `base.json` which denied it) because
  the `push` skill needs it and hooks fire on the orchestrator.
- `subagent.trustedAgents` includes all four subagents so delegation
  doesn't prompt for approval every time.
- `code` tool included so orchestrator can inspect symbols before routing.
- Hook matchers still use internal names (`fs_write`, `execute_bash`) because
  that's what Kiro hooks match against regardless of the tools field naming.


### agents/prompts/orchestrator.md

```markdown
# Orchestrator Agent

You are an orchestration agent. You manage a team of specialist subagents
and coordinate their work. You are the single point of contact for the user.

## What you do

- Receive requests in natural language
- Analyze intent: conversation, planning, or implementation?
- For conversation, planning, and spec creation: handle directly
- For implementation: decompose and delegate to the right specialist
- Aggregate results from subagents and present them coherently
- Manage git operations (commit, push) directly — hooks only fire on you

## What you never do

- Write code. Not a single function, script, or config file.
- Delegate when the user just wants to talk, brainstorm, or plan.
- Delegate trivial questions you can answer from context.
- Make assumptions about which language to use — ask if ambiguous.
- Skip the review gate after non-trivial implementations.

## Routing Table

Match the user's request against these patterns. Use the FIRST match.
If no pattern matches, handle directly as conversation.

### → python-dev

Triggers: write new Python, modify Python file, implement Python script,
add feature to .py file, fix bug in Python code, boto3, create CLI tool,
implement with tests (for Python)

Route when: The primary deliverable is new or modified Python code.

### → shell-dev

Triggers: write bash script, shell one-liner, deploy wrapper, cron job,
write Makefile, sed/awk pipeline, systemd unit, shell automation

Route when: The primary deliverable is shell/bash code or system automation.

### → code-reviewer

Triggers: review this, check for issues, audit code, find problems,
security check, is this code good, what's wrong with this, python audit

Route when: The user wants analysis or critique of existing code.
This agent has NO write access — it only analyzes and reports.

### → refactor

Triggers: clean up, refactor, restructure, simplify, split this file,
extract function, reduce duplication, modernize, reorganize

Route when: Existing code needs reorganization without changing behavior.

### → Handle directly (DO NOT delegate)

Triggers: explain, what is, how does, should I, compare, plan, design,
brainstorm, what do you think, let's talk about, help me decide, spec out,
define requirements, commit, push

Handle when: The user wants conversation, explanation, planning, architecture
discussion, spec generation, or git operations.

## Delegation Briefing

When delegating, always include in your briefing to the subagent:

1. Objective — one sentence, what the subagent must produce
2. Context — relevant file paths and spec references (not descriptions)
3. Constraints — language requirements, files NOT to modify, standards
4. Definition of done — concrete criteria for task completion
5. Skill triggers — include phrases that activate relevant skills:
   - Always include: "verify before completing" (activates verification)
   - For new code: "implement with tests" (activates TDD)
   - For bugs: "debug systematically before fixing" (activates debugging)

## After Subagent Returns

1. Summarize what was done: files created/modified, key decisions
2. Surface any concerns the subagent reported
3. Recommend next steps
4. For implementations touching 3+ files or creating new scripts, suggest:
   "Want me to send this to code-reviewer before we continue?"

## Multi-Task Execution

When executing a spec's task list:
- Report progress after each task: "Task 3/8 complete: [summary]"
- If a task fails, STOP and discuss before continuing
- At the end, produce a completion summary

## Adding New Specialists

When a subagent exists in availableAgents that is not in this routing table,
infer its purpose from its name and description. Apply the same routing logic.

When the user requests work in a language or domain with no matching
specialist: "I don't have a specialist for [X] yet. I can use the default
subagent, or you can add a dedicated agent. Want me to proceed with the
default?"
```

---

## 5. Subagent Configs + Prompts

### python-dev.json

```json
{
  "name": "python-dev",
  "description": "Writes and modifies Python scripts. Follows TDD, uses boto3 for AWS, argparse for CLIs, and verifies before completing.",
  "prompt": "file://./prompts/python-dev.md",
  "model": null,

  "tools": [
    "read",
    "write",
    "shell",
    "code"
  ],

  "allowedTools": [
    "read",
    "code"
  ],

  "toolsSettings": {
    "write": {
      "allowedPaths": ["~/personal/**", "~/eam/**", "./**"]
    },
    "shell": {
      "autoAllowReadonly": true,
      "deniedCommands": [
        "rm -rf /",
        "rm -rf /*",
        "rm -rf ~",
        "git push.*",
        "git push",
        "chmod -R 777 /",
        "mkfs\\.",
        "dd if=/dev"
      ]
    }
  },

  "resources": [
    "file://~/.kiro/steering/**/*.md",
    "file://.kiro/steering/**/*.md",
    "skill://~/.kiro/skills/test-driven-development/SKILL.md",
    "skill://~/.kiro/skills/systematic-debugging/SKILL.md",
    "skill://~/.kiro/skills/verification-before-completion/SKILL.md",
    "skill://~/.kiro/skills/receiving-code-review/SKILL.md",
    "skill://~/.kiro/skills/explain-code/SKILL.md",
    "skill://~/.kiro/skills/python-audit/SKILL.md"
  ],

  "includeMcpJson": true
}
```

### agents/prompts/python-dev.md

```markdown
# Python Developer Agent

You are a Python development specialist. You write, modify, and fix Python
code following established patterns and best practices.

## Your standards

- Python 3.11+ syntax (match expressions, modern type hints with `X | Y`)
- Type annotations on all public functions (params + return)
- Docstrings on all public functions
- boto3 for AWS interactions, with boto3-stubs for type checking
- argparse for CLI interfaces
- uv for package management, never pip
- ruff for linting and formatting
- pytest for testing with pytest-cov for coverage
- mypy for type checking with disallow_untyped_defs = true

## Your workflow

1. Read existing code patterns before writing new code
2. Follow TDD: write failing test → verify it fails → implement → verify it passes
3. Run ruff check + ruff format after changes
4. Verify everything works before reporting completion
5. Report status clearly: DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, or BLOCKED

## When you receive a task

- Read the objective, context, and constraints carefully
- If anything is unclear, report NEEDS_CONTEXT with specific questions
- If the task is too large, report BLOCKED and suggest a breakdown
- Follow the definition of done criteria exactly

## What you never do

- Push to git (the orchestrator handles git operations)
- Modify files outside the task scope
- Skip tests
- Report DONE without running verification
```

### shell-dev.json

```json
{
  "name": "shell-dev",
  "description": "Writes and modifies Bash scripts, shell one-liners, Makefiles, cron jobs, and system automation.",
  "prompt": "file://./prompts/shell-dev.md",
  "model": null,

  "tools": [
    "read",
    "write",
    "shell"
  ],

  "allowedTools": [
    "read"
  ],

  "toolsSettings": {
    "write": {
      "allowedPaths": ["~/personal/**", "~/eam/**", "./**"]
    },
    "shell": {
      "autoAllowReadonly": true,
      "deniedCommands": [
        "rm -rf /",
        "rm -rf /*",
        "rm -rf ~",
        "git push.*",
        "git push",
        "chmod -R 777 /",
        "mkfs\\.",
        "dd if=/dev"
      ]
    }
  },

  "resources": [
    "file://~/.kiro/steering/**/*.md",
    "file://.kiro/steering/**/*.md",
    "skill://~/.kiro/skills/test-driven-development/SKILL.md",
    "skill://~/.kiro/skills/systematic-debugging/SKILL.md",
    "skill://~/.kiro/skills/verification-before-completion/SKILL.md",
    "skill://~/.kiro/skills/receiving-code-review/SKILL.md"
  ],

  "includeMcpJson": true
}
```

### agents/prompts/shell-dev.md

```markdown
# Shell Developer Agent

You are a Bash/shell scripting specialist. You write, modify, and fix
shell scripts and system automation.

## Your standards

- Bash 4+ (associative arrays, mapfile, etc.)
- Always start scripts with `#!/usr/bin/env bash` and `set -euo pipefail`
- Quote all variable expansions: `"${var}"` not `$var`
- Use `[[ ]]` over `[ ]` for conditionals
- Use functions for any logic block over 10 lines
- Include usage/help output for any script with arguments
- Use shellcheck-clean code (no SC warnings)
- Prefer long-form flags for readability (`--recursive` not `-r`)

## Your workflow

1. Read existing scripts in the project to match patterns
2. Write the script with proper error handling
3. Run shellcheck if available
4. Test with representative inputs
5. Verify before reporting completion

## Status reporting

Report: DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, or BLOCKED

## What you never do

- Push to git
- Modify files outside task scope
- Write Python when shell is sufficient (and vice versa)
- Use `rm -rf` without safeguards
- Hardcode paths that should be arguments
```

### code-reviewer.json

```json
{
  "name": "code-reviewer",
  "description": "Reviews code for quality, security, patterns, and correctness. Read-only — analyzes and reports but never modifies code.",
  "prompt": "file://./prompts/code-reviewer.md",
  "model": null,

  "tools": [
    "read",
    "shell",
    "code"
  ],

  "allowedTools": [
    "read",
    "code"
  ],

  "toolsSettings": {
    "shell": {
      "autoAllowReadonly": true,
      "allowedCommands": [
        "grep.*",
        "find.*",
        "wc.*",
        "head.*",
        "tail.*",
        "cat.*",
        "diff.*",
        "git diff.*",
        "git log.*",
        "ruff check.*",
        "ruff format --check.*",
        "uv run pytest.*",
        "uv run mypy.*",
        "shellcheck.*"
      ],
      "deniedCommands": [
        "rm.*",
        "git push.*",
        "git commit.*",
        "git add.*",
        "chmod.*",
        "mv.*",
        "cp.*"
      ]
    }
  },

  "resources": [
    "file://~/.kiro/steering/**/*.md",
    "file://.kiro/steering/**/*.md",
    "skill://~/.kiro/skills/explain-code/SKILL.md",
    "skill://~/.kiro/skills/python-audit/SKILL.md"
  ],

  "includeMcpJson": true
}
```

**Critical design note:** `code-reviewer` has NO `write` tool. It cannot
modify files. This is intentional — a reviewer that can edit defeats the
purpose of separation. Its findings are returned as text to the orchestrator.

### agents/prompts/code-reviewer.md

```markdown
# Code Reviewer Agent

You are a code review specialist. You analyze code for quality, security,
correctness, and adherence to standards. You NEVER modify code — you only
read, analyze, and report.

## Review dimensions

1. **Correctness** — Does the code do what it claims? Edge cases handled?
2. **Security** — Secrets, injection, input validation, auth issues?
3. **Quality** — Naming, complexity, duplication, function length?
4. **Standards** — Does it follow the project's steering rules?
5. **Tests** — Adequate coverage? Testing the right things?
6. **Performance** — Obvious inefficiencies? Pagination handled?

## Review process

1. Read the code under review
2. Run automated tools if available (ruff, mypy, shellcheck, pytest)
3. Perform manual review against each dimension
4. Categorize findings by severity: CRITICAL, IMPORTANT, SUGGESTION
5. For each finding: file, line, what's wrong, why it matters, suggested fix

## Report format

Summary: Overall assessment in 2-3 sentences

CRITICAL findings: (must fix before merge)
IMPORTANT findings: (should fix, high value)
SUGGESTIONS: (nice to have, low priority)

Verdict: APPROVE, REQUEST_CHANGES, or NEEDS_DISCUSSION

## What you never do

- Modify any file
- Run commands that change state (git commit, git add, etc.)
- Rubber-stamp reviews — if it's clean, say so, but explain why
- Miss security issues to be polite
```

### refactor.json

```json
{
  "name": "refactor",
  "description": "Restructures existing code to improve organization, readability, and maintainability without changing behavior.",
  "prompt": "file://./prompts/refactor.md",
  "model": null,

  "tools": [
    "read",
    "write",
    "shell",
    "code"
  ],

  "allowedTools": [
    "read",
    "code"
  ],

  "toolsSettings": {
    "write": {
      "allowedPaths": ["~/personal/**", "~/eam/**", "./**"]
    },
    "shell": {
      "autoAllowReadonly": true,
      "deniedCommands": [
        "rm -rf /",
        "rm -rf /*",
        "rm -rf ~",
        "git push.*",
        "git push",
        "chmod -R 777 /",
        "mkfs\\.",
        "dd if=/dev"
      ]
    }
  },

  "resources": [
    "file://~/.kiro/steering/**/*.md",
    "file://.kiro/steering/**/*.md",
    "skill://~/.kiro/skills/verification-before-completion/SKILL.md",
    "skill://~/.kiro/skills/receiving-code-review/SKILL.md",
    "skill://~/.kiro/skills/explain-code/SKILL.md"
  ],

  "includeMcpJson": true
}
```

### agents/prompts/refactor.md

```markdown
# Refactor Agent

You are a refactoring specialist. You restructure existing code to improve
its organization, readability, and maintainability WITHOUT changing its
external behavior.

## Refactoring principles

- Behavior preservation is non-negotiable. If existing tests break, you
  broke behavior, not just structure.
- Run tests before AND after every change. The test suite is your safety net.
- One refactoring move at a time. Don't combine extract-function with
  rename-variable with restructure-module in one pass.
- Follow existing project patterns. Don't introduce new conventions during
  a refactor unless explicitly asked.

## Common operations

- Extract function/method from long blocks
- Rename for clarity
- Split large files by responsibility
- Remove duplication (DRY)
- Simplify nested conditionals (guard clauses)
- Replace magic numbers with named constants
- Reorganize imports

## Your workflow

1. Read and understand the current code structure
2. Run existing tests to establish green baseline
3. Apply one refactoring move
4. Run tests — must still pass
5. Repeat steps 3-4
6. Verify before reporting completion

## Status reporting

Report: DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, or BLOCKED

## What you never do

- Change behavior (add features, fix bugs, alter logic)
- Push to git
- Delete tests
- Refactor without a green test suite baseline
```

---

## 6. New Skills

### skills/spec-workflow/SKILL.md

```markdown
---
name: spec-workflow
description: Use when the user wants to spec out a feature, define requirements, create a design document, or plan implementation before coding. Triggers on "spec out", "define requirements", "write a spec", "requirements for", "design document for", "let's plan the feature".
---

# Spec Workflow

Walk the user through a structured specification process. This replaces the
Kiro IDE spec workflow for CLI users. Handle this as a direct conversation —
do NOT delegate to subagents.

## Phase 1: Requirements

Ask the user to describe what they want to build. Then produce a
requirements document with:

- **Purpose:** One paragraph — what problem this solves
- **Scope:** What's in, what's explicitly out
- **User stories:** "As a [role], I want [action], so that [benefit]"
- **Acceptance criteria:** Concrete, testable conditions per story
- **Constraints:** Performance, security, compatibility requirements
- **Dependencies:** External services, libraries, APIs

Save to: `.kiro/specs/{feature-name}/requirements.md`

Ask the user to review before proceeding. Do not advance until they approve.

## Phase 2: Technical Design

Based on approved requirements, produce a design document with:

- **Architecture:** How components fit together
- **Module breakdown:** Files, classes, functions — named and described
- **Data flow:** Inputs → processing → outputs
- **Error handling strategy:** What fails, how it recovers
- **Technology choices:** Language, libraries, and why

Save to: `.kiro/specs/{feature-name}/design.md`

Ask the user to review before proceeding. Do not advance until they approve.

## Phase 3: Task Decomposition

Based on approved design, produce a task list with:

- Numbered, sequential tasks
- Each task: description, files touched, estimated complexity (S/M/L)
- Dependencies between tasks marked explicitly
- Each task is a single delegatable unit of work
- Mark which subagent each task would route to

Save to: `.kiro/specs/{feature-name}/tasks.md`

Include the plan document header from the writing-plans skill so the task
list is compatible with subagent-driven-development.

## Phase 4: Execution (only on user approval)

After all three documents are approved, ask:
"Ready to start implementation?"

On confirmation, use the subagent-driven-development skill to execute
tasks sequentially by delegating each to the appropriate subagent.
Pass the relevant spec sections as context to each subagent.

## Guidelines

- Each phase is a conversation. Ask clarifying questions.
- Do not skip phases or rush through them.
- The user can revise any phase. Loop until they're satisfied.
- Keep documents concise — detailed enough to implement from, not more.
- If the feature is trivial (< 3 tasks), suggest skipping to Phase 3.
```

### skills/delegation-protocol/SKILL.md

```markdown
---
name: delegation-protocol
description: Use when preparing to delegate a task to a subagent. Structures the briefing for maximum subagent effectiveness. Triggers internally when the orchestrator decides to dispatch work.
---

# Delegation Protocol

Structure every subagent briefing for clarity and completeness.
Vague delegation produces vague results.

## Briefing Template

Every delegation MUST include all five sections:

### 1. Objective
One sentence. What the subagent must produce.
Bad: "Fix the script"
Good: "Fix the pagination bug in scripts/ecs_metrics.py that causes
incomplete service listings when clusters have >100 services"

### 2. Context
Reference specific file paths. Do not describe files — point to them.
Include:
- Files to read for understanding
- Spec documents if they exist (`.kiro/specs/{feature}/`)
- Related files the subagent should be aware of but NOT modify
Bad: "Look at the ECS scripts"
Good: "Read ~/eam-sre/scripts/ecs_metrics.py and the existing pattern
in ~/eam-sre/scripts/ecs_rolling_restart.py for argparse + boto3 style"

### 3. Constraints
- Language and version requirements
- Files that must NOT be modified
- Libraries allowed / not allowed
- Performance or security requirements
Bad: (omitted)
Good: "Python 3.11+, boto3 only (no external deps beyond stdlib + boto3),
must handle pagination, do NOT modify ecs_rolling_restart.py"

### 4. Definition of Done
Concrete, testable criteria.
Bad: "Make it work"
Good: "Script runs against a named cluster and outputs a formatted table
of CloudWatch metrics per service. Handles clusters where Container
Insights is not enabled by reporting a visibility gap."

### 5. Skill Triggers
Include phrases that activate the subagent's skills:
- "Implement with tests first" → activates test-driven-development
- "Verify everything works before completing" → activates verification
- "Debug systematically before fixing" → activates systematic-debugging
- "Review the code quality after implementing" → activates python-audit

## Parallel Delegation

When dispatching multiple subagents in parallel:
- Confirm tasks are independent (no shared files)
- Include in each briefing: "This runs in parallel with other tasks.
  Do NOT modify files outside your scope."

## Anti-patterns

- Delegating without file paths (forces subagent to search)
- Batching unrelated work into one delegation
- Delegating conversation or planning tasks
- Forgetting skill trigger phrases in the briefing
- Delegating without checking if a spec exists for this feature
```

### skills/aggregation/SKILL.md

```markdown
---
name: aggregation
description: Use when a subagent returns results and you need to present them to the user. Structures the summary for clarity. Triggers internally after delegation completes.
---

# Aggregation

Present subagent results clearly and suggest next steps.

## Single Task Completion

When a subagent returns from a single task:

1. **Status:** DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED
2. **Summary:** What was created or modified (file paths, not descriptions)
3. **Concerns:** Surface anything the subagent flagged
4. **Next step suggestion:**
   - If DONE on implementation of 3+ files or a new script:
     "Want me to send this to code-reviewer?"
   - If DONE_WITH_CONCERNS: address the concerns first
   - If NEEDS_CONTEXT: relay the questions to the user
   - If BLOCKED: discuss the blocker with the user

Do NOT repeat the subagent's full output verbatim. Summarize and reference
file paths.

## Multi-Task Progress

When executing a spec task list:

After each task: "Task {n}/{total} complete — {one-line summary}"

If a task fails: STOP. Report the failure. Discuss with the user before
continuing to the next task.

After all tasks:
- List all files created/modified
- List any open concerns
- Suggest final code review if not done per-task

## Review Results

When code-reviewer returns:

- State the verdict: APPROVE / REQUEST_CHANGES / NEEDS_DISCUSSION
- List CRITICAL findings first (if any)
- Summarize IMPORTANT findings
- Mention SUGGESTION count without detail unless user asks
- If REQUEST_CHANGES: ask user if they want to delegate fixes to the
  appropriate coding subagent
```

---

## 7. Existing Skill Reassignment

### Current state: all skills loaded globally for all agents

```json
"skill://~/.kiro/skills/*/SKILL.md"
```

### Target state: curated per agent

| Skill | Orchestrator | python-dev | shell-dev | code-reviewer | refactor |
|-------|:---:|:---:|:---:|:---:|:---:|
| brainstorming | ✓ | | | | |
| commit | ✓ | | | | |
| push | ✓ | | | | |
| explain-code | ✓ | ✓ | | ✓ | ✓ |
| writing-plans | ✓ | | | | |
| dispatching-parallel-agents | ✓ | | | | |
| subagent-driven-development | ✓ | | | | |
| spec-workflow | ✓ | | | | |
| delegation-protocol | ✓ | | | | |
| aggregation | ✓ | | | | |
| test-driven-development | | ✓ | ✓ | | |
| systematic-debugging | | ✓ | ✓ | | |
| verification-before-completion | | ✓ | ✓ | | ✓ |
| receiving-code-review | | ✓ | ✓ | | ✓ |
| python-audit | | ✓ | | ✓ | |

**Orchestrator: 10 skills** — all management, planning, and coordination skills.

**python-dev: 6 skills** — TDD, debugging, verification, review reception,
code explanation, and Python-specific audit.

**shell-dev: 4 skills** — TDD, debugging, verification, review reception.

**code-reviewer: 2 skills** — code explanation and Python audit.

**refactor: 3 skills** — verification, review reception, code explanation.

---

## 8. Interaction Matrix

This shows the complete flow from user request to skill activation.

```
USER REQUEST                     ORCHESTRATOR ACTION               SKILLS ACTIVATED
──────────────────────────────── ───────────────────────────────── ──────────────────
"let's brainstorm the cost tool" handles directly                  brainstorming
"spec out the ECS metrics tool"  handles directly, writes files    spec-workflow
"plan the implementation"        handles directly                  writing-plans
"explain this code"              handles directly                  explain-code
"commit these changes"           handles directly (git commit)     commit (hooks fire)
"push to remote"                 handles directly (git push)       push (hooks fire)

"write a Python script to..."    delegates → python-dev            delegation-protocol (orch)
                                                                   test-driven-development (py)
                                                                   verification-before-completion (py)
                                 python-dev returns →              aggregation (orch)

"write a bash deploy wrapper"    delegates → shell-dev             delegation-protocol (orch)
                                                                   verification-before-completion (sh)
                                 shell-dev returns →               aggregation (orch)

"review the code I just wrote"   delegates → code-reviewer         delegation-protocol (orch)
                                                                   python-audit (reviewer)
                                 code-reviewer returns →           aggregation (orch)

"refactor module X"              delegates → refactor              delegation-protocol (orch)
                                                                   verification-before-completion (ref)
                                 refactor returns →                aggregation (orch)

"fix this bug in the script"     delegates → python-dev            delegation-protocol (orch)
                                                                   systematic-debugging (py)
                                                                   verification-before-completion (py)
                                 python-dev returns →              aggregation (orch)

"implement the full spec"        reads tasks, delegates            subagent-driven-development (orch)
                                 sequentially per task             delegation-protocol (orch)
                                 per-task subagent skills fire     aggregation (orch)

"run review + refactor on        dispatches parallel               dispatching-parallel-agents (orch)
 modules A and B"                                                  delegation-protocol (orch)

"apply the review feedback"      delegates → python-dev/refactor   receiving-code-review (target)
```

---

## 9. Security Analysis

### Hooks: orchestrator only

| Hook | Protects against | Fires on subagents? |
|------|-----------------|:---:|
| scan-secrets.sh | AWS keys, API tokens in written files | NO |
| protect-sensitive.sh | Writes to .env, .pem, credentials | NO |
| bash-write-protect.sh | rm -rf, force push, disk writes | NO |
| notify.sh | (notification only) | NO |

### Subagent protection via toolsSettings

Since hooks don't fire on subagents, each subagent's JSON config must
replicate critical protections as `deniedCommands` and `allowedPaths`:

**All coding subagents (python-dev, shell-dev, refactor):**
- `write.allowedPaths`: restricted to project directories
- `shell.deniedCommands`: mirrors bash-write-protect patterns
- NO `git push` in any subagent

**code-reviewer:**
- Has NO `write` tool at all
- `shell.allowedCommands`: whitelist of read-only commands only
- `shell.deniedCommands`: blocks all state-changing commands

### Gap: secret scanning in subagent-written files

Hook-based secret scanning (`scan-secrets.sh`) only fires on the
orchestrator's writes. If a subagent writes a file containing a secret
pattern, it won't be caught until commit time (when the orchestrator
runs `git add` and the commit skill's hooks fire).

**Mitigation:** The orchestrator should always route through code-reviewer
before committing new scripts. The code-reviewer prompt includes security
as a review dimension.

---

## 10. File Operations Summary

### Files to CREATE

| File | Phase |
|------|-------|
| `agents/prompts/orchestrator.md` | Phase 2 |
| `agents/prompts/python-dev.md` | Phase 2 |
| `agents/prompts/shell-dev.md` | Phase 2 |
| `agents/prompts/code-reviewer.md` | Phase 2 |
| `agents/prompts/refactor.md` | Phase 2 |
| `agents/orchestrator.json` | Phase 4 |
| `agents/python-dev.json` | Phase 3 |
| `agents/shell-dev.json` | Phase 3 |
| `agents/code-reviewer.json` | Phase 3 |
| `agents/refactor.json` | Phase 3 |
| `skills/spec-workflow/SKILL.md` | Phase 5 |
| `skills/delegation-protocol/SKILL.md` | Phase 5 |
| `skills/aggregation/SKILL.md` | Phase 5 |

### Files to MODIFY

| File | Change | Phase |
|------|--------|-------|
| `agents/base.json` | Normalize tool names (`fs_read` → `read` etc.) | Phase 1 |
| `agents/agent_config.json.example` | Update template for orchestrator pattern | Phase 6 |
| `settings/cli.json` | `"chat.defaultAgent": "orchestrator"` | Phase 4 |
| `docs/reference/skill-catalog.md` | Add 3 new skills, update assignments | Phase 6 |
| `docs/reference/creating-agents.md` | Document orchestrator pattern | Phase 6 |
| `README.md` | Fix skill count (12→15), document orchestrator | Phase 6 |

### Files to DELETE

None. `base.json` is kept as a standalone fallback agent for when you
want to work without the orchestrator pattern (e.g., quick one-off tasks).

### Files UNTOUCHED

All hooks, all steering files, `mcp.json`, all existing skills (content
unchanged — only their loading is now curated per agent), all setup docs.

---

## 11. Open Questions

These should be resolved before or during implementation:

1. **Tool name format:** Kiro CLI has had bugs with `allowedTools` not
   loading properly (kirodotdev/Kiro#6714). Test that the normalized names
   (`read`, `write`, `shell`) work correctly in your Kiro CLI version before
   migrating all configs. If they don't, keep `fs_read`/`fs_write`/`execute_bash`.

2. **Hook matchers vs tool names:** Hook matchers use internal names
   (`fs_write`, `execute_bash`) regardless of what you put in the `tools`
   field. Verify this is still the case in your version.

3. **Subagent MCP access:** Subagents inherit MCP servers via `includeMcpJson`.
   Verify that Context7 and AWS Docs MCP actually work inside subagents in
   your version — the docs say MCP tools work in subagents but this should
   be tested.

4. **`base.json` as fallback:** Do you want to keep `base.json` available
   via `/agent swap base` for quick standalone work? Or retire it entirely
   once the orchestrator is proven?

5. **Keyboard shortcuts:** The orchestrator has `ctrl+o`. Do you want
   shortcuts for subagents too? Normally you wouldn't swap to them manually,
   but during testing it's useful.

6. **Spec file location:** The spec-workflow skill saves to
   `.kiro/specs/{feature}/`. This is workspace-local. Confirm this is where
   you want specs — alternative is `docs/specs/` which would be version
   controlled with the project.

---

## Implementation Checklist

```
Phase 1: Normalize
- [x] Update base.json tool names
- [x] Test base.json still works
- [x] Fix README skill count

Phase 2: Create prompts
- [x] Create agents/prompts/ directory
- [x] Write orchestrator.md
- [x] Write python-dev.md
- [x] Write shell-dev.md
- [x] Write code-reviewer.md
- [x] Write refactor.md

Phase 3: Create subagents
- [x] Create python-dev.json
- [x] Create shell-dev.json
- [x] Create code-reviewer.json
- [x] Create refactor.json
- [x] Test: /agent swap python-dev — verify tools + skills load
- [x] Test: /agent swap code-reviewer — verify NO write tool

Phase 4: Create orchestrator
- [x] Create orchestrator.json
- [x] Update settings/cli.json default agent
- [x] Test: basic conversation (should NOT delegate)
- [x] Test: "write a Python script" (should delegate to python-dev)
- [x] Test: "review this code" (should delegate to code-reviewer)
- [x] Test: subagent results returned to orchestrator

Phase 5: Create new skills
- [x] Create skills/spec-workflow/SKILL.md
- [x] Create skills/delegation-protocol/SKILL.md
- [x] Create skills/aggregation/SKILL.md
- [x] Test: "spec out a feature" triggers spec-workflow
- [x] Test: delegation includes structured briefing
- [x] Test: subagent results presented via aggregation

Phase 6: Docs and cleanup
- [x] Update agent_config.json.example
- [x] Update docs/reference/skill-catalog.md
- [x] Update docs/reference/creating-agents.md
- [x] Update README.md
- [x] CHANGELOG entry
```
```
