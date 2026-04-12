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
- 🔴 Subagents cannot use web_search, web_fetch, introspect, use_aws, grep, or glob. Gather data in orchestrator first.
- 🔴 Always add --no-cli-pager and --output json when subagents run AWS CLI via shell.

## [agent-audit,skills,steering,docs,drift]
- 🟡 Run agent-audit after any change to agent JSON, skills, or steering files to catch documentation drift.
