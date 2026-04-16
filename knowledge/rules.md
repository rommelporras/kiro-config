# Knowledge Rules
# Severity: 🔴 CRITICAL (always injected) | 🟡 RELEVANT (keyword-matched)
# Format: ## [keyword1,keyword2] followed by rules with severity prefix
# NOTE: Do NOT duplicate steering docs here. Only operational lessons not covered elsewhere.

## [subagent,delegate,spawn]
- 🔴 Subagent tool limitations quick-ref: subagents CANNOT use web_search, web_fetch, use_aws, grep, glob, introspect. They CAN use read, write, shell, code, and MCP tools. If a task needs unavailable tools, gather data in the orchestrator first.
- 🔴 Always add --no-cli-pager and --output json when subagents run AWS CLI via shell.

## [subagent,delegate,config,markdown,json,yaml,docs]
- 🟡 Do NOT dispatch dev-python for non-code file edits (markdown, JSON, YAML, config updates, path replacements). Use dev-docs or dev-kiro-config.
- 🟡 Minimize dispatch count — group related edits into fewer, larger dispatches. Each dispatch has initialization overhead.

## [commit,push,git]
- 🔴 Always use the commit skill when committing. Never do ad-hoc git add/commit. The skill enforces: branch safety, secret scan, doc consistency, specific file staging, and verification.

## [agent-audit,skills,steering,docs,drift]
- 🟡 Run agent-audit after any change to agent JSON, skills, or steering files to catch documentation drift.
