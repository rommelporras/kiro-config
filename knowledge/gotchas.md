# Gotchas

Operational lessons learned. Updated manually or by the agent-audit skill.

## Subagent Limitations
- Subagents CANNOT use: web_search, web_fetch, introspect, use_aws, grep, glob
- Subagents CAN use: read, write, shell, code, and MCP tools
- If a task needs web search or AWS data, the orchestrator must gather it first and include in the briefing
- Subagent shell output is buffered, not streamed — long-running commands appear stuck until complete
- Interactive commands (rm -i, npm init, sudo, ssh host key prompts) don't work in subagent shell — no stdin
- Subagents are NOT protected by preToolUse hooks — their safety comes from deniedCommands and deniedPaths in toolsSettings

## AWS CLI in Shell
- Always add --no-cli-pager when running AWS CLI via shell (subagents use shell, not the use_aws tool)
- Always add --output json for parseable output
- Always pass --region explicitly — never assume default

## Kiro Platform
- subagent tool only supports blocking mode — background mode is "not yet implemented"
- /spawn exists for user-initiated parallel sessions but can't be triggered programmatically by agents
- stop hooks run after agent finishes — lightweight only, no blocking operations
- Shell commands in TUI are buffered (no streaming) — commands like npm install show no progress until done

## Knowledge System
- Episodes auto-promote to rules after 3 keyword occurrences (via distill.sh)
- Max 30 active episodes enforced by auto-capture.sh
- Correction detection patterns are regex-based — subtle corrections may not trigger capture
- context-enrichment.sh has a 60-second dedup — rapid corrections within 60s won't all inject rules
