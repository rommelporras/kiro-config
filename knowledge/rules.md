# Knowledge Rules
# Severity: 🔴 CRITICAL (always injected) | 🟡 RELEVANT (keyword-matched)
# Format: ## [keyword1,keyword2] followed by rules with severity prefix

## [aws,cli,pager]
- 🔴 Always use --no-cli-pager with AWS CLI commands to prevent hanging in non-interactive contexts.

## [json,sed,awk,jq]
- 🔴 Never use sed or awk to manipulate JSON files. Use jq instead.

## [git,branch,main,master]
- 🔴 Never commit or push directly to main/master. All work on feature branches.

## [terraform,state,tfstate]
- 🟡 Never commit .tfstate files. Use remote state with S3 + DynamoDB locking.

## [terraform,helm,kubectl,docker,infrastructure]
- 🔴 Infrastructure is read-only. Never execute mutating commands (apply, install, delete, push, scale, patch). Only read/analyze commands allowed: terraform plan/validate/fmt/state show, helm lint/template/diff/list/status, kubectl get/describe/logs/top/explain.

## [subagent,delegate,spawn]
- 🔴 Subagent tool limitations: see orchestrator prompt "Subagent Tool Limitations" section.
- 🔴 Subagent tool limitations quick-ref: subagents CANNOT use web_search, web_fetch, use_aws, grep, glob, introspect. They CAN use read, write, shell, code, and MCP tools. If a task needs unavailable tools, gather data in the orchestrator first.
- 🔴 Always add --no-cli-pager and --output json when subagents run AWS CLI via shell.

## [agent-audit,skills,steering,docs,drift]
- 🟡 Run agent-audit after any change to agent JSON, skills, or steering files to catch documentation drift.

## [subagent,delegate,config,markdown,json,yaml,docs]
- 🟡 Do NOT dispatch dev-python for non-code file edits (markdown, JSON, YAML, config updates, path replacements). dev-python loads TDD/debugging/audit skills that are irrelevant.
- 🟡 For mechanical bulk edits (strReplace across <10 files), the orchestrator should do it directly instead of delegating.
- 🟡 Minimize dispatch count — group related edits into fewer, larger dispatches. Each dispatch has initialization overhead.

## [commit,quality,lint,mypy,test]
- 🔴 Run full quality suite before commit — see "Quality Gate Before Commit" in steering/engineering.md.

## [cli,display,ui,terminal,argparse]
- 🟡 After implementing CLI/display work, test every flag end-to-end. See quality gate in steering/engineering.md.
- 🟡 When using argv-stripping dispatchers, don't use %(prog)s in argparse epilog — hardcode the full command name.

## [move,rename,restructure,path]
- 🔴 After any file move or rename, grep the ENTIRE repo for the old path. See quality gate in steering/engineering.md.

## [commit,push,git]
- 🔴 Always use the commit skill when committing. Never do ad-hoc git add/commit. The skill enforces: branch safety, secret scan, doc consistency, ticket ID prefix, specific file staging, and verification.
- 🔴 Subagent briefings must include "Do NOT commit or push" — subagents have no deniedCommands for git by default.

## [orchestrator,delegate,edit,strReplace,dev-docs]
- 🟡 For 3+ text edits across multiple files, dispatch dev-docs with a single briefing. Don't do sequential strReplace from the orchestrator.