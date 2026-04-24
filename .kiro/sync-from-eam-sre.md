# Sync from eam-sre to personal kiro-config

## Trigger

User says: "sync to personal", "sync kiro-config", or "push to personal repo"

## Paths

- **Source:** `/home/eam/eam/eam-sre/rommel-porras/kiro-config/`
- **Target:** `/home/eam/personal/kiro-config/`

## How to sync — this is NOT a blind copy

Do NOT rsync or bulk-copy. Every file must be analyzed before syncing.

### Step 1: Identify what changed

Run `diff -rq <source> <target> --exclude='.git'` to see which files differ.

### Step 2: Classify each changed file

For each file that differs, determine:

1. **Safe to copy as-is** — no paths, no internal references, no team-specific content.
   Examples: steering docs, skill definitions, hook scripts, agent configs, settings.

2. **Needs sanitization** — contains eam-sre paths, internal project names, ticket
   numbers, or team-specific workflows. These must be adapted, not copied.

3. **Skip entirely** — the eam-sre version has changes that are intentionally different
   from the personal version (e.g., audit-playbook.md paths, internal service names
   in examples).

### Step 3: Sanitization rules

When adapting files, apply these substitutions:

| eam-sre content | Personal repo replacement |
|---|---|
| `~/eam/eam-sre/rommel-porras/kiro-config` | `~/your/path/kiro-config` |
| `~/eam/eam-sre/<your-name>/kiro-config` | `~/your/path/kiro-config` |
| `cp -r rommel-porras/kiro-config <your-name>/kiro-config` | `git clone` workflow |
| `cd ~/eam/eam-sre && git pull` then `cp -r` | `cd ~/your/path/kiro-config && git pull` |
| `sre/eam_sre/bounce/service.py` | `src/services/retry.py` (generic example) |
| `cost-collection pipeline` | `data processing pipeline` (generic example) |
| Any `MTOPS-*` ticket numbers | Remove the ticket prefix |
| Any `hexagon`, `alieam`, `eam-sre` org references | Remove or genericize |

### Step 4: What to NEVER touch in target

These exist only in the personal repo. Never overwrite, delete, or modify:

- `.git/`
- `.kiro/skills/` (personal-only skills: `ship`, `create-pr`)
- `.kiro/sync-from-eam-sre.md` (this file)
- `docs/specs/` (personal repo has its own spec history)
- `docs/TODO.md`
- `docs/audit/`
- `docs/setup/rommel-porras-setup.md`
- `docs/improvements/resolved.md`

### Step 5: Core config directories (usually safe to copy as-is)

These rarely contain path-specific content:

- `agents/` — agent JSON configs (check allowedPaths aren't eam-sre-specific)
- `skills/` — skill definitions
- `hooks/` — hook scripts
- `steering/` — engineering standards
- `settings/` — CLI and MCP config
- `knowledge/` — rules, gotchas, episodes
- `.kiro/agents/` — project-local agent config
- `.kiro/steering/` — project-local steering

### Step 6: Documentation (always needs review)

Docs frequently contain paths and examples. Always read the diff before copying:

- `docs/reference/` — check for hardcoded paths in examples
- `docs/setup/` — setup instructions reference distribution model (git clone vs cp -r)
- `docs/usage/` — examples may reference internal project names
- Root docs (`README.md`, `GETTING-STARTED.md`) — setup instructions differ

### Step 7: After sync

1. Run `git diff --stat` in the target repo
2. Run `git diff` and scan for any leaked internal references
3. Show the results to the user
4. Do NOT commit. Do NOT push.

## Safety rules

- Never bulk-copy without reading the diff first
- Never use `--delete` with rsync
- Never modify files listed in "What to NEVER touch"
- If unsure about a file, skip it and report what was skipped
- Always verify zero internal references after sync
