---
name: push
description: Push the current branch to the configured remote. Use when the user explicitly asks to push changes.
---

Push the current branch to the remote. Work through each step in order and stop immediately if a hard stop condition is met.

## Step 1 — Understand current state

Run in parallel:
- `git branch --show-current` — current branch name
- `git status --short` — check for uncommitted changes
- `git remote -v` — list configured remotes

Then run: `git log @{u}..HEAD --oneline 2>/dev/null` — show unpushed commits. If this fails (no upstream set), note that this is the first push for this branch.

If there are **no configured remotes**, stop here and say so.

If **already up to date** (zero unpushed commits AND upstream exists), report "already up to date" and stop — do not push unnecessarily.

If the **working tree is dirty** (uncommitted changes exist), warn the user but do not block.

## Step 1.5 — Branch safety check

If the branch is `main` or `master`:
- **STOP immediately. Do not ask. Do not proceed.**
- Say exactly: "BLOCKED: You are on `<branch>`. Pushing to main/master is not allowed. Switch to a `feature/*` branch first."
- Do not push, do not continue.

Only allow pushes on branches matching `feature/*`.

## Step 2 — Check push constraints

Read the project steering files for any remote or branch push constraints. Look for:
- Protected remotes on specific branches
- Branches that should never be pushed directly

Note any constraints — apply them in Step 3.

## Step 3 — Push

Push the current branch to `origin`:

```bash
# First push (no upstream set):
git push -u origin <branch>

# Subsequent pushes (upstream already set):
git push origin <branch>
```

Rules:
- **Never use `--force` or `-f`** unless the user explicitly requested it in their message
- If a constraint from Step 2 blocks the push, **stop** and explain why

## Step 4 — Report results

Show a clear summary:

```
Push Results:
- Branch: <branch>
- origin (<url>): ✓ pushed  /  ✗ failed: <error>
- Commits pushed: <n>
```

Then remind: **"Create a merge request on GitLab if one doesn't exist yet."**

## Hard stops

- **No remotes configured** — stop immediately.
- **On main/master** — stop immediately, do not push.
- **Force push** — never add `--force` or `-f` without explicit user instruction.
