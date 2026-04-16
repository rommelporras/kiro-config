---
name: create-pr
description: Create a GitHub pull request from the current feature branch. Use when the user says "create pr", "open pr", "merge request", "create mr", "open mr".
---

# Create PR

Create a GitHub pull request from the current feature branch.

## Step 1 - Check prerequisites

```bash
git branch --show-current
git status --short
gh auth status 2>&1
```

Hard stops:
- On `main` or `master` - ABORT ("Switch to a feature branch first.")
- `gh` not authenticated - ABORT ("Run `gh auth login` first.")
- Dirty working tree - WARN but continue

Check if PR already exists:

```bash
gh pr list --head "$(git branch --show-current)" --json number,url --jq '.[0]'
```

If PR exists, show URL and stop.

## Step 2 - Gather context

Collect all available context for the PR body:

1. **Branch name** - extract feature name from `feature/<name>`
2. **Commit log** - `git log main..HEAD --oneline`
3. **Spec detection** - search `docs/specs/` for a directory whose name contains keywords from the branch name. If found, read the spec's Purpose and Scope sections.

## Step 3 - Compose PR

Build the PR title and body:

**Title**: Use the most recent commit's conventional commit message. If multiple specs/features, use a summary title.

**Body structure** (use all available context):

```markdown
## Summary

<One paragraph from spec Purpose section if found, otherwise summarize from commits.>

## Changes

<Bullet list from commit log, grouped by conventional commit type (feat, fix, refactor, docs, chore). Each bullet is the commit subject.>

## Spec

<If spec found: link to spec file path. If not: omit this section entirely.>
```

## Step 4 - Confirm and create

Show the full PR preview (title + body) and ask for confirmation.

On confirmation:

```bash
gh pr create \
  --title "<title>" \
  --body "<body>" \
  --base main \
  --draft
```

## Step 5 - Report

```
PR created:
  URL:    <url>
  Title:  <title>
  Status: Draft
  Base:   main
```
