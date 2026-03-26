<!-- Author: Rommel Porras -->

# Security Model

[Back to README](../../README.md) | Related: [Creating agents](creating-agents.md) | [Troubleshooting](../setup/troubleshooting.md)

The base agent uses three defense layers. Each layer catches what the others miss.

## Layer 1 — Hooks (PreToolUse)

Hooks run **before** a tool executes. Exit code 2 blocks the operation and tells the
agent why. The agent sees the block message and adjusts — it doesn't retry.

### scan-secrets.sh

Blocks file writes containing hardcoded secrets.

| Pattern | What it catches |
|---|---|
| `-----BEGIN (RSA\|EC\|OPENSSH )?PRIVATE KEY-----` | PEM private keys |
| `AKIA[0-9A-Z]{16}` | AWS access key IDs |
| `gh[pousr]_[A-Za-z0-9]{36,255}` | GitHub tokens (classic + fine-grained) |
| `sk-ant-api\d{2}-...` | Anthropic API keys |
| `sk-proj-...` | OpenAI project keys |
| `ctx7sk-...` | Context7 API keys |
| `glpat-...` | GitLab personal access tokens |
| `xox[bpas]-...` | Slack tokens (bot, user, app-level) |
| `"type": "service_account"` | Google Cloud service account keys |
| `(password\|secret\|token\|api_key)=...` | Generic hardcoded secrets |

**To add a new pattern:** Edit `hooks/scan-secrets.sh`, add a `check` call:
```bash
check "Description" 'regex-pattern'
```

### protect-sensitive.sh

Blocks file writes to sensitive file paths. Cached for 60 seconds (path-based, safe to cache).

**Protected patterns:** `.env`, `.env.local`, `.env.production`, `.env.development`,
`.env.staging`, `.env.test`, `.pem`, `credentials.json`, `.credentials.json`,
`id_rsa`, `id_ed25519`, `id_ecdsa`

### bash-write-protect.sh

Blocks dangerous shell commands.

**Sensitive file redirects:** Blocks `>` or `tee` to any protected file pattern (same list as protect-sensitive.sh).

**Destructive operations:** `rm -rf /`, `rm -rf ~`, `> /dev/sd*`, `mkfs.`, `dd if=/dev`,
`chmod -R 777 /`, fork bomb.

**Force push to main/master:** Blocks `git push --force` targeting `main` or `master`.

## Layer 2 — Denied paths (toolsSettings)

Path restrictions in `base.json` prevent reading/writing sensitive directories,
even if no hook would catch the content.

| Scope | Denied paths |
|---|---|
| **Read + Write** | `~/.ssh`, `~/.gnupg`, `~/.config/gh`, `~/.kiro/settings/cli.json` |
| **Read** | `~/.aws/credentials` |
| **Write** | `~/.aws` (entire directory) |

| Scope | Allowed paths |
|---|---|
| **Read** | `~/.kiro`, `~/personal`, `~/eam` |
| **Write** | `~/personal`, `~/eam` |

Files outside allowed paths require user approval per operation.

## Layer 3 — Denied commands (toolsSettings)

Shell-level blocks in `execute_bash` settings. Defense-in-depth alongside bash-write-protect.sh hook.

**Denied:** `rm -rf /`, `rm -rf /*`, `rm -rf ~`, `chmod -R 777 /`, `mkfs.`,
`dd if=/dev`, `> /dev/sd`, `> /dev/nvme`

## How the layers interact

```
User request → Agent decides to use a tool
                    ↓
            [Layer 3: denied commands?] → BLOCKED (shell only)
                    ↓
            [Layer 2: denied path?] → BLOCKED
                    ↓
            [Layer 1: hook runs] → exit 2 = BLOCKED
                    ↓
            Tool executes
```

A single operation can be checked by all three layers. For example, `echo "AKIA..." > ~/.env`:
1. **Layer 3** checks if the shell command is denied
2. **Layer 2** checks if `~/.env` is in a denied path
3. **Layer 1** (`bash-write-protect.sh`) checks for redirect to sensitive file
4. **Layer 1** (`scan-secrets.sh`) checks content for AWS key pattern

## Customizing for your team

### Adding denied paths

Edit `agents/base.json` → `toolsSettings`:
```json
"fs_read": {
  "deniedPaths": ["~/.ssh", "~/.aws/credentials", "~/your-sensitive-dir"]
}
```

### Adding secret patterns

Edit `hooks/scan-secrets.sh`, add before the `if [[ $BLOCKED` check:
```bash
# Your service tokens
check "Service X token" 'svc_[A-Za-z0-9]{32,}'
```

### Removing false positives

If a hook blocks legitimate content, you have two options:
1. **Narrow the pattern** — make the regex more specific
2. **Use the steering** — add a rule in project steering telling the agent to use environment variables instead

Don't disable hooks globally. If a project genuinely needs to write secrets (e.g., test fixtures), override in the project agent config.

## What's NOT covered

- **Network requests** — no hook validates URLs or prevents data exfiltration
- **Runtime secrets** — hooks check file content, not environment variables passed to commands
- **MCP tool output** — hooks don't inspect what MCP servers return
- **Subagent actions** — subagents inherit the agent config but may have different tool access

These are acceptable trade-offs for a CLI development tool. For production security, use proper secret management (1Password, AWS Secrets Manager, etc.).
