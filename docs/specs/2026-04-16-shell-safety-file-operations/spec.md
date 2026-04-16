# Spec 1: Shell Safety & File Operations

> Status: Approved
> Created: 2026-04-16
> Depends on: Nothing (foundational)
> Unblocks: Spec 2 (file operations routing lane)

## Purpose

The current `rm .*` deny pattern blocks ALL rm commands across all agents,
including safe single-file deletions within the working tree. The `mv` command
is blocked on dev-reviewer but not consistently handled elsewhere. File
operations (move, rename, delete) have no routing lane in the orchestrator —
they fall through to "handle directly" which can't execute them reliably.

This spec fixes the shell safety rules to distinguish between safe and
dangerous file operations, and adds proper orchestrator routing for file work.

## Scope

### In scope

- Rewrite `bash-write-protect.sh` deny patterns for `rm` and `mv`
- Update `deniedCommands` in all agent JSON configs
- Add "file operations" routing lane to orchestrator prompt
- Evaluate and expand dev-docs write permissions for file reorganization

### Out of scope

- New agents or skills
- Steering doc changes
- Hook infrastructure changes beyond bash-write-protect.sh

## Design

### Shell safety tiers

| Operation | Rule | Enforcement |
|---|---|---|
| `mv` within allowed paths | ALLOW | Remove from deny list; allowedPaths already constrains |
| `rm` on specific files within allowed paths | ALLOW with path check | bash-write-protect.sh validates target is a single file in allowed paths |
| `rm -rf` on directories | BLOCK — require user confirmation | bash-write-protect.sh detects recursive flag + directory target |
| `rm -rf /`, `rm -rf ~`, `rm -rf /*` | BLOCK always | bash-write-protect.sh hard block (existing) |

### bash-write-protect.sh changes

Current `rm .*` regex in agent deniedCommands blocks everything. Replace with
smarter detection in the hook:

**Implementation approach:**

The hook receives the full command string via stdin JSON (`.tool_input.command`).
It uses regex to detect rm invocations and classify them:

```bash
# Extract the rm command and its arguments
# Handle combined flags: -rf, -fr, -Rf, etc.
# Detect --recursive or any flag combo containing 'r'
IS_RECURSIVE=false
if echo "$COMMAND" | grep -qP '\brm\b.*(-[a-zA-Z]*r[a-zA-Z]*|--recursive)'; then
  IS_RECURSIVE=true
fi
```

**Path whitelist (hardcoded in hook, not read from agent config):**
```bash
ALLOWED_PREFIXES=(
  "$HOME/eam/"
  "$HOME/personal/"
  "$HOME/.kiro/"
)
```
The hook resolves the target path with `readlink -f` and checks it starts
with one of these prefixes. This is independent of the agent's allowedPaths —
the hook is a safety net, not the primary access control.

**Decision logic:**

1. If command matches catastrophic patterns (`rm -rf /`, `rm -rf ~`, etc.)
   → BLOCK always (existing, unchanged)
2. If `IS_RECURSIVE` is true → BLOCK with message:
   "rm with recursive flag requires user confirmation. Run manually."
3. If target is outside ALLOWED_PREFIXES → BLOCK with message:
   "rm target is outside allowed paths."
4. If `rm -d` (remove empty directory) → ALLOW (harmless)
5. If target is a single file within allowed paths → ALLOW
6. If multiple targets → check each individually, BLOCK if any fails

### Agent deniedCommands changes

All agent JSON files currently have `"rm .*"` in deniedCommands. Replace with:
- Remove `"rm .*"` from deniedCommands in all agents EXCEPT dev-reviewer
- For subagents (where hooks don't fire), add narrower patterns:
  `"rm -r.*"`, `"rm -f.*r.*"`, `"rm --recursive.*"` — blocks recursive
  but allows single-file deletion
- dev-reviewer keeps `"rm .*"` (read-only agent, no deletions ever)
- The orchestrator relies on the hook (hooks fire on orchestrator) so it
  only needs the catastrophic patterns in deniedCommands

### Orchestrator routing: file operations lane

Add to orchestrator prompt routing table:

```
### → Handle directly (file operations)

Triggers: move file, rename file, delete file, organize files,
move directory, clean up files

Handle when: The user wants to move, rename, or delete files.
Use shell commands directly. For rm -rf on directories, confirm
with user first.
```

File operations stay on the orchestrator (not delegated) because:
- They're usually 1-2 commands
- They often need user confirmation
- The orchestrator has the full context of what's safe

### dev-docs permission expansion

Current dev-docs deniedCommands has `"rm .*"` which blocks all rm. Change to:
- Remove `"rm .*"` from dev-docs deniedCommands
- The bash-write-protect.sh hook handles safety (but note: hooks don't fire
  on subagents, so dev-docs also needs a narrower deny pattern)
- Add `"rm -r.*"` and `"rm -f.*-r.*"` to dev-docs deniedCommands — blocks
  recursive deletion but allows single-file `rm path/to/file.txt`
- dev-docs `allowedPaths` stays unchanged (`~/personal/**`, `~/eam/**`, `./**`)
- This enables dev-docs to `rm old-file.md` after creating a replacement,
  but not `rm -rf directory/`

## Files to modify

| File | Change |
|---|---|
| `hooks/bash-write-protect.sh` | Rewrite rm detection logic |
| `agents/dev-orchestrator.json` | Update deniedCommands (rm pattern) |
| `agents/dev-python.json` | Update deniedCommands (rm pattern) |
| `agents/dev-shell.json` | Update deniedCommands (rm pattern) |
| `agents/dev-docs.json` | Update deniedCommands (rm pattern) |
| `agents/dev-refactor.json` | Update deniedCommands (rm pattern) |
| `agents/dev-reviewer.json` | Keep rm fully blocked (read-only) |
| `agents/base.json` | Update deniedCommands (rm pattern) |
| `agents/prompts/orchestrator.md` | Add file operations routing lane |

## Acceptance criteria

- [ ] `mv file1 file2` works within allowed paths for all agents except dev-reviewer
- [ ] `rm specific-file.txt` works within allowed paths for all agents except dev-reviewer
- [ ] `rm -rf directory/` is blocked by bash-write-protect.sh with confirmation message
- [ ] `rm -rf /`, `rm -rf ~` remain hard-blocked
- [ ] dev-reviewer cannot rm or mv anything
- [ ] Orchestrator routes "move this file" and "delete this file" correctly
- [ ] All existing safety tests still pass (catastrophic patterns blocked)
- [ ] shellcheck clean on bash-write-protect.sh
