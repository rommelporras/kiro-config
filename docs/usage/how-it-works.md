[Back to README](../../README.md) | [Workflows](workflows.md) | [Commands](commands.md) | [Tips](tips.md)

# How It Works

## Mental model

You talk to `devops-orchestrator`. It's the default agent — every `kiro-cli` session
starts with it. You don't pick specialist agents manually. The orchestrator decides
who handles what based on your request.

- **You** describe what you need in plain language
- **The orchestrator** plans, designs, delegates coding to specialists, and handles git
- **Specialists** write code, review, refactor — then report back
- **The orchestrator** runs quality checks automatically and presents results

You never need to say "use devops-python" — just say "write a Python script that..."
and the orchestrator routes it.

---

## Agent roster

| Agent | What it does | Access |
|-------|-------------|--------|
| devops-orchestrator | Plans, designs, delegates, git ops | Read + Write |
| devops-python | Python scripts, boto3, CLI tools | Write |
| devops-shell | Bash scripts, Makefiles, cron jobs | Write |
| devops-typescript | TypeScript/Express backends, Vitest | Write |
| devops-frontend | HTML, CSS, browser TypeScript, Chart.js | Write |
| devops-docs | Markdown, JSON, YAML, config files | Write |
| devops-refactor | Restructures code, preserves behavior | Write |
| devops-reviewer | Code review, security analysis | Read-only |
| devops-terraform | Terraform analysis, variable tracing | Read-only |
| base | Standalone agent for quick questions | Read + Write |

**base** is useful when you don't need orchestration — quick questions, one-off
lookups, or when you want to talk to the AI without the delegation overhead.

---

## Switching agents

- `/agent` — list all available agents
- `/agent <name>` — switch to a specific agent
- `ctrl+o` — keyboard shortcut to toggle back to the orchestrator
- `/agent base` — switch to the standalone base agent (no orchestration, good for quick questions)

---

## What happens automatically

You don't need to ask for these — they run on every relevant operation:

- Secret scanning on every file write
- Destructive command blocking (`rm -rf`, force push, infra mutations)
- Post-implementation quality checks (lint, type check, tests)
- Doc staleness detection after code changes
- Code review after every implementation

---

## What the orchestrator won't do

- Execute mutating infrastructure commands (`terraform apply`, `kubectl apply`, `helm install`)
- Commit or push without you explicitly asking
- Write to files outside your configured allowed paths
- Run `rm -rf` without confirmation

---

## How delegation looks

When the orchestrator delegates, you'll see it dispatch a subagent. When the
subagent finishes, it reports one of:

| Status | Meaning |
|--------|---------|
| **DONE** | Task complete, verified |
| **DONE_WITH_CONCERNS** | Complete but flagging something worth knowing |
| **NEEDS_CONTEXT** | Paused — needs more info from you |
| **BLOCKED** | Can't proceed — needs your help or a different approach |

After receiving DONE, the orchestrator automatically runs:
1. Quality gate (lint, type check, tests)
2. Doc staleness check
3. Code review via devops-reviewer
4. Improvement capture (logs friction for future config improvements)

You see the final consolidated result, not the raw subagent output.
