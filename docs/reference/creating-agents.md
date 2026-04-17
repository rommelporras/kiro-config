<!-- Author: Rommel Porras -->

# Creating Custom Agents

[Back to README](../../README.md) | Related: [Audit playbook](audit-playbook.md) | [CLI install checklist](../setup/kiro-cli-install-checklist.md) | [IDE + WSL2 setup](../setup/kiro-ide-wsl-setup.md)

Guide for creating Kiro CLI custom agents. See the
[official docs](https://kiro.dev/docs/cli/custom-agents/) for the full reference.

## Architecture: Orchestrator Pattern

This config uses a multi-agent orchestrator pattern:

```
User ↔ dev-orchestrator (plans, converses, coordinates)
            ├── dev-docs      (edits config, docs, markdown)
            ├── dev-python    (writes Python code)
            ├── dev-shell     (writes Bash/shell code)
            ├── dev-typescript (writes TypeScript/Express)
            ├── dev-frontend  (writes HTML/CSS/TS frontends)
            ├── dev-reviewer  (read-only analysis)
            ├── dev-refactor  (restructures code)
            └── dev-kiro-config (project-local: kiro-config editing)
```

The orchestrator is the default agent. It never writes executable code — config
and markdown edits are handled directly for small scope. Everything else is
delegated to specialists. The user never swaps agents manually.

### When to create a new subagent

| Signal | Action |
|---|---|
| New language/domain (Go, Rust, Terraform) | Create a specialist subagent |
| New review type (security audit, perf review) | Create a read-only reviewer |
| Project-specific workflow | Create a project-local agent |

### Adding a subagent

1. Create `agents/<name>.json` with tools, prompt, and curated skills
2. Create `agents/prompts/<name>.md` with specialist instructions
3. Add the agent name to `orchestrator.json` → `toolsSettings.subagent.availableAgents`
4. Add to `trustedAgents` if it should run without approval prompts
5. Update the routing table in `agents/prompts/orchestrator.md`
6. Run `agent-audit` to verify the new agent is consistent with existing agents

## Field reference

### Identity

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | no | Agent identifier. Derives from filename if omitted |
| `description` | string | no | Human-readable summary shown in agent picker |
| `welcomeMessage` | string | no | Displayed when switching to this agent |
| `model` | string | no | Model ID (e.g., `"claude-sonnet-4"`). Falls back to default if omitted |
| `keyboardShortcut` | string | no | Toggle shortcut (e.g., `"ctrl+r"`) |

### Tools

| Field | Type | Description |
|---|---|---|
| `tools` | array | Available tools. Use aliases (`read`, `write`, `shell`, `aws`) or MCP refs (`@server`, `@server/tool`) |
| `allowedTools` | array | Tools that run without user prompts. Supports glob patterns (`@server/read_*`) |
| `toolAliases` | object | Remap tool names to resolve collisions |

**Tool name convention:**
- `tools` and `allowedTools`: use aliases — `read`, `write`, `shell`, `aws`
- `toolsSettings`: use canonical names — `fs_read`, `fs_write`, `execute_bash`, `use_aws`
- Hook matchers: use canonical names — `fs_write`, `execute_bash`, `use_aws`

### Subagent tool limitations

Subagents run in a separate runtime. Not all tools are available:

| Available in subagents | NOT available in subagents |
|---|---|
| `read`, `write`, `shell`, `code` | `web_search`, `web_fetch`, `introspect` |
| MCP tools (via `includeMcpJson`) | `use_aws`, `grep`, `glob` |

If a subagent config lists unavailable tools, they're silently ignored.

### Context

| Field | Type | Description |
|---|---|---|
| `prompt` | string | System instructions. Supports `file://` URIs resolved relative to the agent JSON file |
| `resources` | array | Files and skills to load. `file://` for steering, `skill://` for skills. Supports globs and `~` |

### MCP

| Field | Type | Description |
|---|---|---|
| `mcpServers` | object | Agent-specific MCP server definitions |
| `includeMcpJson` | boolean | Load servers from global and workspace `mcp.json`. Default: true |

### Security

| Field | Type | Description |
|---|---|---|
| `hooks` | object | Commands at trigger points: `agentSpawn`, `userPromptSubmit`, `preToolUse`, `postToolUse`, `stop` |
| `toolsSettings` | object | Per-tool config using canonical names |

**Important:** Hooks only fire on the orchestrator (main agent), NOT on subagents.
Subagent security must be enforced via `toolsSettings` (deniedCommands, allowedPaths).

## Hook format

```json
{
  "hooks": {
    "preToolUse": [
      {
        "matcher": "fs_write",
        "command": "bash ~/.kiro/hooks/scan-secrets.sh",
        "timeout_ms": 5000
      }
    ],
    "userPromptSubmit": [
      {
        "command": "bash ~/.kiro/hooks/feedback/context-enrichment.sh",
        "timeout_ms": 5000
      }
    ]
  }
}
```

**Exit codes:** `0` = allow, `2` = block (preToolUse only), other = warn.

**Matchers:** `fs_read`, `fs_write`, `execute_bash`, `use_aws`, `@server/tool`, `*`, `@builtin`.

## Security baseline

Always inherit these when creating new agents:

1. **Hooks** — `scan-secrets.sh`, `protect-sensitive.sh`, `bash-write-protect.sh`, `block-sed-json.sh`
2. **Self-learning hooks** — `context-enrichment.sh`, `correction-detect.sh` (orchestrator only)
3. **Denied paths** — `~/.ssh`, `~/.aws/credentials`, `~/.gnupg`, `~/.config/gh`
4. **Denied commands** — `"rm -r.*"`, `"rm -f.*r.*"`, `"rm --recursive.*"` (blocks recursive rm; dev-reviewer keeps full `"rm .*"`), `chmod -R 777 /`, `mkfs.`, `dd if/dev`
5. **Global steering** — `"file://~/.kiro/steering/**/*.md"` in resources
6. **Agent-audit compatibility** — new agents should be added to the agent-audit skill's review scope (it reads all `agents/*.json` and `agents/prompts/` files automatically)

For subagents: replicate critical protections as `deniedCommands` since hooks don't fire.

## Domain-specific agent design patterns

### Analyst/auditor/collector separation

Split complex analysis workflows into three roles:
- **Collector** — gathers raw data (reads files, runs commands, queries APIs)
- **Analyst** — interprets data, identifies patterns, produces findings
- **Auditor** — validates findings against standards, produces pass/fail verdicts

This separation keeps each agent focused and makes retry-with-feedback loops practical.

### Structured JSON contracts between agents

When one agent's output feeds another agent's input, use structured JSON:

```json
{
  "status": "DONE",
  "findings": [
    { "severity": "high", "file": "agents/foo.json", "issue": "missing deniedPaths" }
  ],
  "next_action": "fix"
}
```

Unstructured prose output forces the orchestrator to parse intent. JSON contracts make routing deterministic.

### Retry-with-feedback loops

When a subagent returns `DONE_WITH_CONCERNS` or produces output that fails a quality gate, the orchestrator can re-dispatch with the failure reason appended to the briefing:

```
Previous attempt failed quality gate:
  - ruff: 3 errors in agents/foo.py
  - mypy: 1 type error

Fix these issues and re-run the quality gate before returning DONE.
```

Cap retries at 2. If still failing after 2 attempts, escalate to the user.

### Cross-language vs. language-specific agents

| Agent type | Examples | Scope |
|---|---|---|
| Cross-language | dev-reviewer, dev-refactor | Work on any language — focus on structure, patterns, quality |
| Language-specific | dev-python, dev-shell | Deep language expertise — TDD, linting, type checking |

Cross-language agents should not run language-specific quality tools (ruff, mypy, shellcheck). Delegate quality checks to the language-specific agent.

### Project-local agents (dev-kiro-config pattern)

Some projects need elevated permissions that would be unsafe to grant globally. Create a project-local agent:

1. Place the agent JSON in the project's `.kiro/agents/` directory (not `~/.kiro/agents/`)
2. Grant write access scoped to that project's directories only
3. Register it in the orchestrator's `availableAgents` list
4. The orchestrator routes project-specific tasks to it; falls back gracefully when unavailable in other projects

Example: `dev-kiro-config` has write access to `agents/`, `hooks/`, `steering/`, `skills/` within the kiro-config repo — permissions that would be too broad for a global agent.

## Tips

- Run `/agent` in Kiro CLI to see loaded agents and switch between them
- Run `/context show` to verify steering, skills, and resources are loading
- Run `/tools` to check which tools are available and auto-approved
- Use `/agent swap base` to fall back to the standalone agent for quick one-off tasks
