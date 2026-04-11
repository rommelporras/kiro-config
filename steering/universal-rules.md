# Universal Rules

- **NO AI attribution** — no "Co-Authored-By" AI lines, "Generated with" AI tool names,
  "AI-assisted", or any AI reference in commits, PRs, code comments, or docs.
- **NO automatic git commits or pushes** — only commit when the user explicitly asks.
- **Security review before every commit** — scan all changed files for leaked
  secrets before staging. Use secret manager references only, never hardcoded values.
- **No destructive operations without confirmation** — `rm -rf`, force pushes,
  `kubectl delete`, `helm uninstall`, or anything that destroys data requires
  explicit user confirmation before running.
- **Branching: feature-branch only** — never commit or push to `main` or `master`.
  All work happens on `feature/<name>` branches. Merge requests are
  created manually on GitLab/Github.

## Infrastructure is Read-Only

Never execute mutating infrastructure commands. Kiro writes infrastructure code
in files but all execution is manual. This is enforced by deny lists in agent configs.

| Tool | Allowed (read-only) | Blocked (mutating) |
|------|---------------------|--------------------|
| Terraform | `plan`, `validate`, `fmt`, `state list/show`, `output`, `graph` | `apply`, `destroy`, `import`, `taint`, `state rm/mv/push` |
| Helm | `lint`, `template`, `diff`, `list`, `get`, `status` | `install`, `upgrade`, `delete`, `rollback` |
| kubectl | `get`, `describe`, `logs`, `top`, `explain`, `diff` | `apply`, `create`, `delete`, `edit`, `patch`, `scale`, `exec`, `drain`, `cordon`, `taint`, `run`, `cp`, `set`, `label`, `annotate`, `replace`, `rollout restart/undo` |
| Docker | `inspect`, `images`, `ps`, `scout`, `history` | `push`, `run`, `build`, `rm`, `rmi`, `stop`, `kill`, `compose up/down` |
| AWS CLI | `describe-*`, `list-*`, `get-*` | `create-*`, `delete-*`, `update-*`, `put-*`, `modify-*`, `start-*`, `stop-*`, `terminate-*`, `run-*`, `invoke`, `register-*`, `deregister-*`, `enable-*`, `disable-*`, `attach-*`, `detach-*`, `tag-*`, `untag-*` |

## Orchestrator Pattern

- The orchestrator is the single point of contact. It plans, converses, and delegates.
- Subagents write code. The orchestrator never writes code.
- Only the orchestrator runs git operations (commit, push) — hooks only fire on it.
- Subagents report status (DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED)
  and the orchestrator presents results to the user.
