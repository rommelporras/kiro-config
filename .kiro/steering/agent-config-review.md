# Agent Config Review Checklist

Use when reviewing kiro-config agent JSON files, hook scripts, or skill definitions.

- Deny lists consistent across all subagents?
- tools vs allowedTools aligned (no tool in allowed but not in tools)?
- Prompt file referenced in JSON exists on disk?
- Skill resources referenced in JSON exist on disk?
- Hook scripts referenced in JSON exist on disk?
- includeMcpJson matches the agent's intended MCP access?
- hooks block present on agents with write or shell tools?
