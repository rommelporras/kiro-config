<!-- Author: Rommel Porras -->

# Creating Custom Agents

[Back to README](../../README.md) | Related: [CLI install checklist](../setup/kiro-cli-install-checklist.md) | [IDE + WSL2 setup](../setup/kiro-ide-wsl-setup.md)

Guide for creating Kiro CLI custom agents. See the
[official docs](https://kiro.dev/docs/cli/custom-agents/) for the full reference.

## When to create an agent

| Use case | Scope | Example |
|---|---|---|
| Task-specific workflow | Project | `sre.json` — ECS/EKS operations with AWS tools only |
| Code review delegate | Project | `reviewer.json` — read-only, no shell access |
| Read-only auditor | Global | `auditor.json` — can read and search, cannot write or execute |
| Domain expert | Project | `backend.json` — backend-specific steering and MCP servers |

**Global agents** (`~/.kiro/agents/`) load for every project. Use for cross-cutting
concerns like auditing or documentation.

**Project agents** (`.kiro/agents/`) load only for that project. Use for
project-specific tools, steering, and MCP servers. Project agents take precedence
on name conflicts.

## Field reference

### Identity

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | no | Agent identifier. Derives from filename if omitted |
| `description` | string | no | Human-readable summary shown in agent picker |
| `welcomeMessage` | string | no | Displayed when switching to this agent |
| `model` | string | no | Model ID (e.g., `"claude-sonnet-4"`). Falls back to default if omitted |
| `keyboardShortcut` | string | no | Toggle shortcut (e.g., `"ctrl+shift+r"`) |

### Tools

| Field | Type | Description |
|---|---|---|
| `tools` | array | Available tools. Use aliases (`read`, `write`, `shell`) or MCP refs (`@server`, `@server/tool`) |
| `allowedTools` | array | Tools that run without user prompts. Supports glob patterns (`@server/read_*`) |
| `toolAliases` | object | Remap tool names to resolve collisions (`{"@github-mcp/get_issues": "github_issues"}`) |

**Built-in tool aliases:** `read`, `write`, `shell`, `aws`, `report`, `introspect`,
`knowledge`, `thinking`, `todo`, `delegate`, `grep`, `glob`, `web_fetch`, `web_search`

**Canonical names** (used in `toolsSettings`): `fs_read`, `fs_write`, `execute_bash`,
`use_aws`

### Context

| Field | Type | Description |
|---|---|---|
| `prompt` | string | System instructions. Supports `file://` URIs (e.g., `"file://./prompts/sre.md"`) |
| `resources` | array | Files and skills to load. `file://` for steering, `skill://` for skills. Supports globs and `~` |

### MCP

| Field | Type | Description |
|---|---|---|
| `mcpServers` | object | Agent-specific MCP server definitions (same format as `mcp.json`) |
| `includeMcpJson` | boolean | Load servers from global and workspace `mcp.json`. Default: true |

### Security

| Field | Type | Description |
|---|---|---|
| `hooks` | object | Commands at trigger points: `agentSpawn`, `userPromptSubmit`, `preToolUse`, `postToolUse`, `stop` |
| `toolsSettings` | object | Per-tool config using canonical names. Supports `allowedPaths`, `deniedPaths`, `deniedCommands`, `autoAllowReadonly` |

### Subagents

| Field | Type | Description |
|---|---|---|
| `toolsSettings.subagent.availableAgents` | array | Which agents can be spawned as subagents. Supports globs |
| `toolsSettings.subagent.trustedAgents` | array | Subagents that run without permission prompts |

## Hook format

```json
{
  "hooks": {
    "preToolUse": [
      {
        "matcher": "fs_write",
        "command": "bash ~/.kiro/hooks/scan-secrets.sh",
        "timeout_ms": 5000,
        "cache_ttl_seconds": 0
      }
    ],
    "postToolUse": [],
    "stop": [],
    "agentSpawn": [],
    "userPromptSubmit": []
  }
}
```

**Exit codes:** `0` = allow, `2` = block (PreToolUse only), other = warn.

**Matchers:** `fs_read`, `fs_write`, `execute_bash`, `use_aws`, `@server/tool`, `*` (all), `@builtin` (built-in only).

## Security baseline

Always inherit these from the base agent when creating new agents:

1. **Hooks** — `scan-secrets.sh`, `protect-sensitive.sh`, `bash-write-protect.sh`
2. **Denied paths** — `~/.ssh`, `~/.aws/credentials`, `~/.gnupg`, `~/.config/gh`
3. **Denied commands** — `rm -rf /`, `chmod -R 777 /`, `mkfs.`, `dd if=/dev`
4. **Global steering** — `"file://~/.kiro/steering/**/*.md"` in resources

Copy the `hooks`, `toolsSettings`, and first resource entry from `base.json`
into your new agent. Then customize tools, prompt, and model.

## Recipes

### Read-only auditor

```json
{
  "name": "auditor",
  "description": "Read-only agent for code review and analysis",
  "tools": ["read", "grep", "glob", "web_fetch", "@context7"],
  "allowedTools": ["read", "grep", "glob", "@context7"],
  "resources": [
    "file://~/.kiro/steering/**/*.md",
    "file://.kiro/steering/**/*.md",
    "skill://~/.kiro/skills/*/SKILL.md"
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
      }
    ]
  },
  "toolsSettings": {
    "fs_read": {
      "deniedPaths": ["~/.ssh", "~/.aws/credentials", "~/.gnupg", "~/.config/gh"]
    }
  },
  "includeMcpJson": true
}
```

### SRE operations (project-specific)

```json
{
  "name": "sre",
  "description": "ECS/EKS operations agent with AWS access",
  "prompt": "file://.kiro/steering/product.md",
  "model": "claude-sonnet-4",
  "tools": ["read", "write", "shell", "aws", "grep", "glob", "delegate"],
  "allowedTools": ["read", "grep", "glob", "aws"],
  "resources": [
    "file://~/.kiro/steering/**/*.md",
    "file://.kiro/steering/**/*.md"
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
    ]
  },
  "toolsSettings": {
    "fs_read": {
      "deniedPaths": ["~/.ssh", "~/.aws/credentials", "~/.gnupg"]
    },
    "fs_write": {
      "deniedPaths": ["~/.ssh", "~/.aws", "~/.gnupg"]
    },
    "execute_bash": {
      "autoAllowReadonly": true,
      "deniedCommands": ["rm -rf /", "rm -rf /*", "chmod -R 777 /"]
    },
    "use_aws": {
      "autoAllowReadonly": true
    }
  },
  "includeMcpJson": true
}
```

## Tips

- Run `/agent` in Kiro CLI to see loaded agents and switch between them
- Run `/context show` to verify steering, skills, and resources are loading
- Run `/tools` to check which tools are available and auto-approved
- Test new agents in a scratch project before deploying to the team
