---
name: commit
description: Create a git commit following conventional commit format. Use when the user explicitly asks to commit changes.
---

Create a git commit following these rules exactly. Work through each step in order and stop immediately if a step reveals a problem.

## Arguments

If the user provides a commit message in their request, use it as the commit message (still apply formatting rules and run all steps).
If no message is given, determine the message from the staged/modified changes.

## Step 1 — Understand current state

Run these in parallel:
- `git status` — identify staged, unstaged, and untracked files
- `git diff` — unstaged changes
- `git diff --cached` — staged changes
- `git log --oneline -5` — confirm commit style convention in use

If there are no changes at all (nothing staged, nothing modified), stop here and say so. Do not create an empty commit.

## Step 1.5 — Branch safety check

Read the current branch from the `git status` output above.

If the branch is `main` or `master`:
- **STOP immediately. Do not ask. Do not proceed.**
- Say exactly: "BLOCKED: You are on `<branch>`. Commits to main/master are not allowed. Switch to a `feature/*` branch first."
- Do not stage, do not commit, do not continue.

Only allow commits on branches matching `feature/*`.

## Step 2 — Secret scan

Before staging anything, scan all modified and untracked files for leaked secrets. Check for:
- Private key headers: `-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----`
- AWS access key IDs: `AKIA[0-9A-Z]{16}`
- GitHub tokens: `gh[pousr]_[A-Za-z0-9]{36,}`
- Anthropic API keys: `sk-ant-api`
- OpenAI project keys: `sk-proj-`

Use `git diff` and `git diff --cached` output — do not scan binary files.

If a secret pattern is found, **stop immediately**. Report the file and pattern. Do not proceed to staging.

## Step 3 — Draft the commit message

Conventional commit format — `type: short description`:

| Type | When to use |
|---|---|
| `feat:` | New feature or capability |
| `fix:` | Bug fix |
| `docs:` | Documentation only |
| `refactor:` | Code restructure, no behavior change |
| `chore:` | Build, tooling, config, dependencies |
| `infra:` | Infrastructure, deployment, CI/CD |

Rules:
- Subject line: max 72 characters, lowercase after the colon, no trailing period
- Body (optional): explain **why**, not what — blank line after subject, wrap at 72 chars
- **NEVER add AI attribution** — no "Co-Authored-By" AI lines, no "Generated with" AI tool names, no AI references of any kind

## Step 4 — Stage specific files

Stage files by name. **Never use `git add -A` or `git add .`** — they risk including unintended files.

Only stage files that are directly part of this commit's intent. If there are unrelated changes mixed in, ask the user what to include before staging.

## Step 5 — Create the commit

Pass the message via HEREDOC to preserve formatting:

```bash
git commit -m "$(cat <<'EOF'
type: subject line

Optional body explaining why.
EOF
)"
```

## Step 6 — Verify

Run `git log --oneline -1` and `git status`. Show both outputs so the user can confirm.

## Hard stops

- **Pre-commit hook failure** — do not retry with `--no-verify`. Report the failure and ask the user how to proceed.
- **No changes** — do not create an empty commit.
- **Secret found** — stop before staging. Never suppress or bypass.
- **Never push** unless the user explicitly asks after the commit is created.
