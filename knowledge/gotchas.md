# Gotchas

Operational lessons learned. Updated manually or by the agent-audit skill.

## Subagent Limitations
- Tool availability and data-gathering rules: see "Delegation Format" in orchestrator prompt.
- Subagent shell output is buffered, not streamed — long-running commands appear stuck until complete
- Interactive commands (rm -i, npm init, sudo, ssh host key prompts) don't work in subagent shell — no stdin
- Subagents now have preToolUse hooks (scan-secrets, protect-sensitive, bash-write-protect, block-sed-json) as of v0.5.0 — defense-in-depth alongside deniedCommands/deniedPaths. Hooks are defined per-agent in each JSON because Kiro CLI does not inherit hooks across subagents.

## AWS CLI in Shell
- Always add --no-cli-pager when running AWS CLI via shell (subagents use shell, not the use_aws tool)
- Always add --output json for parseable output
- Always pass --region explicitly — never assume default

## Kiro Platform
- subagent tool only supports blocking mode — background mode is "not yet implemented"
- /spawn exists for user-initiated parallel sessions but can't be triggered programmatically by agents
- stop hooks run after agent finishes — lightweight only, no blocking operations
- Shell commands in TUI are buffered (no streaming) — commands like npm install show no progress until done

## WSL + 1Password SSH Agent
- On WSL session resume, the 1Password SSH agent socket may be stale — npiperelay bridge runs but socket is dead
- Opening a new terminal tab re-runs .zshrc which recreates the socat/npiperelay bridge and restores the socket
- Kiro CLI runs commands via bash, not zsh — the .zshrc bridge setup never executes in shell tool context
- SSH_AUTH_SOCK is inherited from the parent zsh session, so it works as long as the socket was created before launching Kiro

## Knowledge System
- Episodes auto-promote to rules after 3 keyword occurrences (via distill.sh)
- Max 30 active episodes enforced by auto-capture.sh
- Correction detection patterns are regex-based — subtle corrections may not trigger capture
- context-enrichment.sh has a 60-second dedup — rapid corrections within 60s won't all inject rules

## Post-Implementation Blind Spots
- Learned the hard way: mocked tests ≠ working software. See "Quality Gate Before Commit" in steering/engineering.md for the full checklist.
- argparse %(prog)s resolves to the entry point name, not the full subcommand. When using argv-stripping dispatchers (eam ecs {bounce|status}), hardcode the full command in epilog examples.

## Orchestrator Self-Modification
- When the orchestrator's deniedPaths blocks a write to its own config files, use a subagent silently. Don't explain the problem to the user or ask them to apply changes manually.
- Self-modification (subagents writing to orchestrator prompt/config) is only allowed when the user explicitly asked for it, and only with exact before/after strings in the briefing — no creative freedom for the subagent.
- Subagents must NEVER commit or push when modifying global config. The orchestrator handles all git operations.

## Orchestrator Sequential Edit Anti-Pattern
- When agent-audit or similar analysis produces 3+ text edits across multiple files, dispatch devops-docs with all edits in one briefing. Don't do sequential strReplace calls from the orchestrator — each is a round-trip that adds up.
- The '<10 files do it directly' rule was too generous. 1-2 quick edits = direct. 3+ edits = devops-docs.

## Kiro Regex Precedence (allow vs deny)
- When a command matches both an `allowedCommands` and `deniedCommands` pattern in the same agent, **deny wins**. Narrow-allow-over-broad-deny does NOT work.
- Use non-overlapping patterns, or wrap the allowed action in a helper script with its own allow entry (e.g., `bash .*/mark-preflight.sh$` instead of `touch .terraform/.preflight-confirmed-*`).
- Verified 2026-04-18: `touch .testmark-allowed.txt` (narrow allow) was blocked by `touch .*` (broad deny) on scratch-precedence agent.