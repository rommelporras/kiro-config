# AWS CLI

## Command Standards
- **Always use `--no-cli-pager`** — prevents commands from hanging in non-interactive contexts.
- **Always use `--output json`** — consistent, parseable output. Use `jq` for filtering.
- **Use `--query` for server-side filtering** — cheaper and faster than piping through `jq`
  for simple extractions. Combine with `jq` for complex transforms.
- **Prefer `--filters` over client-side grep** — let the API do the work
  (e.g., `aws ec2 describe-instances --filters "Name=tag:Name,Values=prod-*"`).

## Read-Only Operations Only
- **Only run read commands** — `describe-*`, `list-*`, `get-*`, `show-*`.
  Never run `create-*`, `update-*`, `delete-*`, `put-*`, `modify-*`, `start-*`,
  `stop-*`, `terminate-*`, or any mutating API call.
- **Region-explicit commands** — always pass `--region`. Never assume the default.
- **Never hardcode account IDs or ARNs** — use `aws sts get-caller-identity` or
  variables. Treat account IDs as semi-sensitive.

## Patterns
- **Waiter over polling loops** — use `aws <service> wait <condition>` instead of
  sleep-and-retry loops.
- **Pagination** — use `--no-paginate` only when you know the result set is small.
  For large sets, let the CLI auto-paginate or use `--page-size`.
