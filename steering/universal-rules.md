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
  All work happens on `feature/<ticket-id>` branches. Merge requests are
  created manually on GitLab/Github.
