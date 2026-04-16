---
name: ship
description: Create a versioned release with tag, push, and GitHub release. Use when the user says "ship", "release", "tag and release", "create release", "ship it".
---

# Ship

Tag, push, and create a GitHub release. On feature branches, creates a PR first. Orchestrator-handled - no delegation.

**Announce at start:** "Preparing release."

## Step 1 - Check state

```bash
git branch --show-current   # Must be on main
git status                  # Must be clean
git log --oneline -10
git describe --tags --abbrev=0 2>/dev/null || echo "No tags yet"
```

Hard stops:
- Dirty working tree - ABORT ("Commit or stash changes first.")

If on a `feature/*` branch, switch to **PR creation mode** (Step 1.5). If on `main`, continue to Step 2.

## Step 1.5 - PR creation mode (feature branch only)

Triggered when `ship` is called from a feature branch.

Delegate to the **create-pr** skill. It handles prerequisite checks, context gathering, PR composition, and creation.

After the PR is created, stop. Do not proceed to Step 2.

**STOP here.** Do not proceed to tagging or releasing.

## Step 2 - Remote tag collision check

> From this point forward, all steps require being on `main`.

```bash
git fetch origin --tags
git tag -l "v<VERSION>"
```

If tag exists - ABORT and suggest next available version.

## Step 3 - Determine version and title

Title format: `v<VERSION> - <Short Title>` (regular hyphen, never em dash).

If user provided version: use it.
If not: auto-bump from commits since last tag:
- `feat:` - minor (v0.1.0 - v0.2.0)
- `fix:`, `docs:`, `chore:`, `refactor:`, `infra:` - patch
- `BREAKING CHANGE` - major
- No previous tags - default to `v0.1.0`

Auto-generate short title from commit analysis if not provided.

## Step 4 - Check CHANGELOG

```bash
grep "v<VERSION>" docs/reference/CHANGELOG.md
```

- Entry found - use it for release notes
- No entry - WARN ("No CHANGELOG entry for v<VERSION>. Write one before releasing?")

Do NOT auto-create CHANGELOG entries.

## Step 5 - Build release notes

Read `docs/reference/CHANGELOG.md` for the version entry AND analyze commits.

**GitHub release format:**

```markdown
## Summary

<One paragraph - what this release contains and why it matters.
Derived from CHANGELOG entry. No bullet lists here.>

## What's Included

### <Meaningful Category - e.g. "Multi-Agent Orchestrator", "Security">
- **Feature name** - what it does and why it matters

### <Another Category>
- **Item** - brief description

Full details: [CHANGELOG](docs/reference/CHANGELOG.md)
```

Rules:
- `## Summary` is required - always a paragraph
- Categories are project-specific, not generic (feat/fix/docs)
- No `## Commits` section - GitHub shows the diff automatically
- CHANGELOG link at the bottom
- No em dashes anywhere - use regular hyphens
- No AI attribution

## Step 6 - Show plan and confirm

```
Release Plan:
  Version:    v<VERSION>
  Title:      v<VERSION> - <Short Title>
  Commits:    <N> since <last-tag>
  CHANGELOG:  Entry found / Missing
  Remote:     origin

Release notes preview:
  <full markdown preview>

Proceed? (waiting for confirmation)
```

**Do NOT proceed until user confirms.**

## Step 7 - Execute

```bash
# Create annotated tag
git tag -a v<VERSION> -m "<tag annotation>"

# Push
git push origin main
git push origin v<VERSION>

# Verify tag on remote
git ls-remote origin refs/tags/v<VERSION>

# Create GitHub release
gh release create v<VERSION> \
  --title "v<VERSION> - <Short Title>" \
  --notes "<release notes>"
```

If push fails - ABORT before creating release.

## Step 8 - Branch cleanup

After release succeeds, prune stale remote refs and check for merged feature branches:

```bash
git fetch --prune
git branch --merged main | grep 'feature/' | head -5
```

If merged feature branches exist, ask:
"Delete local branch `feature/<name>`?"

On confirmation:
```bash
git branch -d feature/<name>
```

Use `-d` (not `-D`) - git will refuse if the branch isn't fully merged. This is a safety net.

Note: remote branch is typically already deleted by GitHub's "Delete branch" button on merge. `git fetch --prune` cleans up the stale tracking ref. If the remote branch still exists, also run `git push origin --delete feature/<name>`.

## Step 9 - Report

```
Release complete:
  Tag:       v<VERSION>
  Title:     v<VERSION> - <Short Title>
  Release:   <URL>
  CHANGELOG: docs/reference/CHANGELOG.md
  Cleanup:   feature/<name> deleted (local + remote) / skipped
```
