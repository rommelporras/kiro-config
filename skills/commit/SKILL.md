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

Commit message format — `TICKET-ID - type: short description`

Extract the ticket ID from the current branch name. For example:
- Branch `feature/MTOPS-5324` → ticket ID is `MTOPS-5324`
- Branch `feature/PROJ-123` → ticket ID is `PROJ-123`

Pattern: strip the prefix before the last `/` to get the ticket ID.

Format: `<TICKET-ID> - <type>: <description>`

| Type | When to use |
|---|---|
| `feat:` | New feature or capability |
| `fix:` | Bug fix |
| `docs:` | Documentation only |
| `refactor:` | Code restructure, no behavior change |
| `chore:` | Build, tooling, config, dependencies |
| `infra:` | Infrastructure, deployment, CI/CD |

Examples:
- `MTOPS-5324 - feat: add eam-ecs-bounce safe ECS rolling restart tool`
- `MTOPS-5324 - docs: restructure README and add per-script docs`
- `MTOPS-4450 - fix: correct NiFi pod restart timeout handling`

Rules:
- Subject line: max 72 characters, lowercase after the type colon, no trailing period
- Wrap body lines at 72 chars
- **NEVER add AI attribution** — no "Co-Authored-By" AI lines, no "Generated with" AI tool names, no AI references of any kind

### When to add a commit body

Use the diff size and nature to decide — not every commit needs a body.

| Condition | Body? | Why |
|---|---|---|
| 1-3 files, simple change | No | Subject line is enough |
| 4+ files or new feature/tool | Yes | Summarize what it does and key capabilities |
| Bug fix with non-obvious root cause | Yes | Explain what was wrong and why the fix works |
| Refactor touching many files | Yes | Explain the motivation and what changed structurally |
| Docs-only reorganization | No | The diff is self-explanatory |

Body format — blank line after subject, then:
- **feat/refactor**: 2-4 lines summarizing capabilities or structural changes
- **fix**: 1-2 lines explaining root cause and fix approach
- Stats line (optional): test count, file count, or other concrete metrics if significant

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
