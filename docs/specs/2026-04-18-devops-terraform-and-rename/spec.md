# Spec: devops-terraform Agent + dev-* → devops-* Rename

**Date:** 2026-04-18
**Status:** Draft (v4 — unknowns #2 and #3 resolved via testing, helper script approach)
**Author:** orchestrator + user brainstorm
**Version target:** v0.7.0

## Overview

Two changes in one pass:

1. **New agent:** `devops-terraform` — a read-only Terraform analysis agent that can diagnose errors, trace variable chains, check git history, run `terraform plan`, and suggest fixes. General enough for any Terraform project.
2. **Rename:** All `dev-*` agents renamed to `devops-*` to reflect the team's DevOps Consultant role.

---

## Part 1: devops-terraform Agent

### Identity

- **Name:** `devops-terraform`
- **Role:** Read-only Terraform analysis and diagnostics
- **Model:** `claude-sonnet-4.6` (matches devops-reviewer)
- **Location:** Global agent at `~/.kiro/agents/devops-terraform.json`
- **MCP:** `includeMcpJson: false` — no MCP tools needed; orchestrator enriches briefings

### Tools

| Tool | Access | Notes |
|------|--------|-------|
| `read` | ✅ | `.tf`, `.tfvars`, symlink targets, modules |
| `shell` | ✅ | Read-only commands only (see JSON config below) |
| `code` | ✅ | Grep/ripgrep search (HCL AST not supported — verified) |
| `use_aws` | ✅ | `autoAllowReadonly: true` — read-only AWS API calls for drift detection |
| `write` | ❌ | No file modifications |

**Decision: `use_aws` over shell-AWS.** The `use_aws` tool with `autoAllowReadonly: true` is the established pattern (used by orchestrator and base). This is cleaner than shell-based AWS CLI with regex deny lists.

### Complete Agent JSON Config

```json
{
  "name": "devops-terraform",
  "description": "Read-only Terraform analysis agent. Diagnoses errors, traces variable chains, checks git history, runs terraform plan, and suggests fixes. Never modifies files or infrastructure.",
  "prompt": "file://./prompts/devops-terraform.md",
  "model": "claude-sonnet-4.6",
  "tools": [
    "read",
    "shell",
    "code",
    "aws"
  ],
  "allowedTools": [
    "read",
    "code"
  ],
  "toolsSettings": {
    "fs_read": {
      "allowedPaths": [
        "~/.kiro",
        "~/personal",
        "~/eam"
      ],
      "deniedPaths": [
        "~/.ssh",
        "~/.aws/credentials",
        "~/.gnupg",
        "~/.config/gh",
        "~/.kiro/settings/cli.json"
      ]
    },
    "execute_bash": {
      "autoAllowReadonly": true,
      "allowedCommands": [
        "terraform init$",
        "terraform init -backend-config=.*",
        "terraform plan.*",
        "terraform validate.*",
        "terraform fmt -check.*",
        "terraform fmt --check.*",
        "terraform workspace list.*",
        "terraform workspace select .*",
        "terraform workspace show.*",
        "terraform state list.*",
        "terraform state show .*",
        "terraform show.*",
        "terraform output.*",
        "terraform providers$",
        "terraform providers schema.*",
        "terraform graph.*",
        "terraform version.*",
        "bash .*/mark-preflight\\.sh$",
        "readlink .*",
        "find .*"
      ],
      "deniedCommands": [
        "terraform apply.*",
        "terraform destroy.*",
        "terraform import.*",
        "terraform taint.*",
        "terraform untaint.*",
        "terraform state rm.*",
        "terraform state mv.*",
        "terraform state push.*",
        "terraform state pull.*",
        "terraform force-unlock.*",
        "terraform init -upgrade.*",
        "terraform init --upgrade.*",
        "terraform providers lock.*",
        "terraform console.*",
        "terraform login.*",
        "terraform logout.*",
        "rm .*",
        "mv .*",
        "cp .*",
        "mkdir.*",
        "touch .*",
        "tee .*",
        "chmod -R 777 /",
        "mkfs\\\\.",
        "dd if=/dev.*",
        "> /dev/sd",
        "> /dev/nvme",
        "git add.*",
        "git commit.*",
        "git push.*",
        "git push",
        "aws .* create-.*",
        "aws .* delete-.*",
        "aws .* update-.*",
        "aws .* put-.*",
        "aws .* modify-.*",
        "aws .* start-.*",
        "aws .* stop-.*",
        "aws .* terminate-.*",
        "aws .* run-.*",
        "aws .* invoke.*",
        "aws .* register-.*",
        "aws .* deregister-.*",
        "aws .* enable-.*",
        "aws .* disable-.*",
        "aws .* attach-.*",
        "aws .* detach-.*",
        "aws .* associate-.*",
        "aws .* disassociate-.*",
        "aws .* tag-.*",
        "aws .* untag-.*",
        "aws s3 cp.*",
        "aws s3 mv.*",
        "aws s3 rm.*",
        "aws s3 sync.*",
        "kubectl apply.*",
        "kubectl create.*",
        "kubectl delete.*",
        "kubectl edit.*",
        "kubectl patch.*",
        "kubectl scale.*",
        "kubectl drain.*",
        "kubectl cordon.*",
        "kubectl uncordon.*",
        "kubectl taint.*",
        "kubectl exec.*",
        "kubectl run.*",
        "kubectl cp.*",
        "kubectl rollout undo.*",
        "kubectl rollout restart.*",
        "kubectl replace.*",
        "kubectl set.*",
        "kubectl label.*",
        "kubectl annotate.*",
        "helm install.*",
        "helm upgrade.*",
        "helm delete.*",
        "helm uninstall.*",
        "helm rollback.*",
        "docker push.*",
        "docker run.*",
        "docker build.*",
        "docker compose up.*",
        "docker compose down.*",
        "docker rm.*",
        "docker rmi.*",
        "docker stop.*",
        "docker kill.*"
      ]
    },
    "use_aws": {
      "autoAllowReadonly": true
    }
  },
  "resources": [
    "file://~/.kiro/steering/**/*.md",
    "file://.kiro/steering/**/*.md",
    "skill://~/.kiro/skills/trace-code/SKILL.md",
    "skill://~/.kiro/skills/explain-code/SKILL.md",
    "skill://~/.kiro/skills/systematic-debugging/SKILL.md",
    "skill://~/.kiro/skills/verification-before-completion/SKILL.md",
    "skill://~/.kiro/skills/terraform-audit/SKILL.md"
  ],
  "hooks": {
    "preToolUse": [
      {
        "matcher": "execute_bash",
        "command": "bash ~/.kiro/hooks/terraform-preflight.sh",
        "timeout_ms": 5000
      },
      {
        "matcher": "execute_bash",
        "command": "bash ~/.kiro/hooks/bash-write-protect.sh",
        "timeout_ms": 5000
      },
      {
        "matcher": "execute_bash",
        "command": "bash ~/.kiro/hooks/security/block-sed-json.sh",
        "timeout_ms": 3000
      }
    ]
  },
  "includeMcpJson": false
}
```

**Notes on config:**
- No `fs_write` hooks (scan-secrets, protect-sensitive) — agent has no write tool
- `terraform-preflight.sh` hook fires before any shell command — blocks `terraform plan/validate/state` unless workspace-scoped preflight marker exists
- `use_aws` with `autoAllowReadonly: true` — same pattern as orchestrator/base
- `code` tool for grep-based search only (HCL AST not supported, verified)
- Deny list copied from `devops-reviewer.json` as base, with terraform-specific additions and full AWS shell deny block (defense-in-depth — shell bypasses `use_aws` entirely)
- Preflight marker created via `scripts/mark-preflight.sh` helper (not `touch`) — Kiro's deny-wins-over-allow precedence means `touch .*` deny blocks even narrow `touch` allows. Helper script sidesteps the overlap entirely.

### Preflight Gate — Hook-Enforced

**Not prompt-discipline — a hard block via `terraform-preflight.sh` hook.**

LLMs drift with long contexts. A prompt-only gate for "which workspace are you about to run `terraform plan` against" is a real risk. The hook enforces it.

**Marker is workspace-scoped:** `.terraform/.preflight-confirmed-<workspace>` (e.g., `.terraform/.preflight-confirmed-prod`). Switching workspaces invalidates the previous preflight — the agent must re-confirm for the new workspace.

**Hook behavior (`hooks/terraform-preflight.sh`):**

1. Intercepts every `execute_bash` call
2. If the command starts with `terraform plan`, `terraform validate`, `terraform state`, or `terraform show` (commands that require correct workspace/init state):
   - Read current workspace from `.terraform/environment` (default: `default`)
   - Check for marker file `.terraform/.preflight-confirmed-<workspace>`
   - If marker missing → exit 2 with message: "Preflight not completed for workspace '<workspace>'. Run the preflight checklist first, then run `bash ~/.kiro/scripts/mark-preflight.sh`."
3. If the command is `terraform init`, `terraform workspace list`, `terraform workspace show`, `terraform workspace select`, `terraform fmt`, `terraform version`, `terraform graph`, `terraform output`, or any non-terraform command → pass through (exit 0)
4. The marker file is created by the agent running `bash ~/.kiro/scripts/mark-preflight.sh` after the user confirms all preflight checks passed

**Helper script (`scripts/mark-preflight.sh`):**

```bash
#!/usr/bin/env bash
# Creates the workspace-scoped preflight marker.
# Called by devops-terraform agent after user confirms preflight checklist.

set -euo pipefail

WS="$(cat .terraform/environment 2>/dev/null || echo default)"
touch ".terraform/.preflight-confirmed-${WS}"
echo "Preflight marker created for workspace '${WS}'."
```

**Hook draft (`hooks/terraform-preflight.sh`):**

```bash
#!/usr/bin/env bash
# PreToolUse hook — blocks terraform plan/validate/state/show unless
# workspace-scoped preflight marker exists.
# Exit 0 = allow, Exit 2 = block with message to LLM.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "${INPUT}" | jq -r '.tool_input.command // ""')

if [[ -z "${COMMAND}" ]]; then
  exit 0
fi

# Extract leading command token
FIRST_TOKEN=$(echo "${COMMAND}" | awk '{print $1}')

# Only gate terraform commands
if [[ "${FIRST_TOKEN}" != "terraform" ]]; then
  exit 0
fi

# Extract terraform subcommand
TF_SUB=$(echo "${COMMAND}" | awk '{print $2}')

# Commands that require preflight confirmation
case "${TF_SUB}" in
  plan|validate|state|show)
    # Read current workspace
    WS="$(cat .terraform/environment 2>/dev/null || echo default)"
    MARKER=".terraform/.preflight-confirmed-${WS}"

    if [[ ! -f "${MARKER}" ]]; then
      echo "BLOCKED: Preflight not completed for workspace '${WS}'." >&2
      echo "Complete the preflight checklist first:" >&2
      echo "  1. Verify AWS credentials: aws sts get-caller-identity" >&2
      echo "  2. Confirm symlinks are set up (if applicable)" >&2
      echo "  3. Run: terraform init" >&2
      echo "  4. Run: terraform workspace select <name>" >&2
      echo "  5. Confirm with the user, then: bash ~/.kiro/scripts/mark-preflight.sh" >&2
      exit 2
    fi
    ;;
  *)
    # All other terraform subcommands pass through
    exit 0
    ;;
esac

exit 0
```

**Preflight checklist (agent asks user to confirm):**

1. **"Are AWS credentials active?"** — agent runs `aws sts get-caller-identity` to verify
2. **"Are symlinks set up for this stack?"** — relevant for projects using symlinked workspace configs
3. **"Has `terraform init` been run?"** — agent can run it after user confirms
4. **"Which workspace should I analyze?"** — agent shows `terraform workspace list` and `terraform workspace show`, user confirms correct workspace

After user confirms all 4, agent runs `bash ~/.kiro/scripts/mark-preflight.sh` and proceeds.

### New Skill: terraform-audit

**File:** `skills/terraform-audit/SKILL.md`

```markdown
---
name: terraform-audit
description: Terraform-specific diagnostic workflow. Use when the user pastes a terraform error, plan failure, missing variable, or state drift issue. Triggers on "diagnose terraform", "why did plan fail", "trace terraform issue", "what broke in terraform", "missing variable".
---

# Terraform Audit

Diagnose Terraform errors by tracing through code, state, and git history.

**Announce at start:** "Diagnosing: [error summary]."

## Preflight

Before any terraform commands, verify the preflight gate is satisfied.
If not, ask the user to complete the preflight checklist and wait.

## Process

1. **Parse** — extract error type, affected resource/variable/module from the error message
2. **Locate** — find relevant `.tf` files; resolve symlinks with `readlink -f`
3. **Trace** — follow variable dependency chain:
   `terraform.tfvars` → `variables.tf` → `locals {}` → module input → resource attribute
4. **History** — `git log --oneline -20 -- <affected files>` and `git diff HEAD~1 -- <file>`
5. **Cross-stack** — check `importvars.tf` / `terraform_remote_state` data sources for upstream breakage
6. **State** — if credentials available, compare declared config vs actual AWS state via `use_aws` read-only calls
7. **Report** — present findings in structured format below

## Output Format

### Error
Original error message, verbatim.

### Root Cause
One-paragraph explanation of why this happened.

### Affected Files
- `path/to/file.tf:42` — what's wrong at this line
- `path/to/variables.tf:15` — where the variable is defined (or missing)

### Git History
- `abc1234 (2026-04-15)` — commit that introduced the change, with `git blame` output

### Cross-Stack Dependencies
- Remote state `eam_farm` from `importvars.tf:25` — status of upstream stack

### Suggested Fix
Concrete steps to resolve. Never apply — describe what the user should change and where.

## Guidelines

- Always resolve symlinks before analyzing — the actual source may be elsewhere
- Check workspace selection before diagnosing workspace-specific issues
- For "missing variable" errors: (1) defined in variables.tf? (2) set in .tfvars? (3) recently added in module but not propagated?
- Use `terraform fmt --check` early — formatting issues mask real problems
```

### New Steering: steering/terraform.md

General Terraform rules loaded by all agents via steering:

- Always `terraform fmt --check` before analyzing — formatting issues mask real problems
- Trace variables through full chain: `terraform.tfvars` → `variables.tf` → `locals` → module input → resource attribute
- Check `importvars.tf` / remote state data sources for cross-stack dependencies
- For "missing variable" errors: (1) defined in `variables.tf`? (2) set in `.tfvars` or workspace file? (3) recently added in module but not propagated?
- Use `git log --oneline -20 -- <file>` for recent changes
- For workspace issues, verify selected workspace before diagnosing
- Never run mutating Terraform commands — analysis only
- Resolve symlinks before analyzing — the actual source may be in a different directory
- `terraform workspace select` writes `.terraform/environment` — this is acceptable for analysis but is technically a local state change

### Prompt Structure (agents/prompts/devops-terraform.md)

The prompt should include:

- Identity: read-only Terraform analyst, subagent of devops-orchestrator
- Preflight gate: the 4 checks, with instruction to run `bash ~/.kiro/scripts/mark-preflight.sh` after user confirms
- Symlink awareness: always `ls -la` and `readlink -f` before analyzing a stack
- Workspace awareness: always verify workspace before running plan
- Variable tracing methodology (tfvars → variables → locals → module → resource)
- Remote state dependency awareness (importvars.tf pattern)
- Report format: root cause → affected files → git history → suggested fix
- What it never does: modify files, run mutating commands, apply changes
- Handoff pattern: when a fix is needed, report the exact change needed — the orchestrator will brief devops-docs with the fix

### Routing in devops-orchestrator

**Insertion order: ABOVE devops-docs** (so `.tf` analysis routes correctly before the docs catch-all).

```
### → devops-terraform
Triggers: terraform error, plan failed, missing variable, state drift,
what changed in terraform, trace terraform variable, explain terraform stack,
terraform workspace issue, why did this break, analyze .tf files,
terraform diagnose, HCL analysis
Route when: the issue involves Terraform code, state, or infrastructure-as-code analysis.
Note: read-only — no write access. Dispatched with error messages and file paths.
```

**Decision: `devops-terraform` does NOT join the post-implementation trigger list.** It's read-only — there's nothing to post-implement. The orchestrator prompt line listing implementation subagents remains: `devops-python, devops-shell, devops-refactor, devops-kiro-config, devops-typescript, devops-frontend`.

### Read/Write Boundary for .tf Files

When the user needs a Terraform fix applied:

1. `devops-terraform` diagnoses the issue and reports the exact fix (file, line, what to change)
2. Orchestrator briefs `devops-docs` with the specific fix from the diagnosis
3. `devops-docs` applies the mechanical edit

This handoff is the primary interaction pattern. `devops-terraform` never writes; `devops-docs` doesn't need to understand variable chains because the diagnosis already specifies the exact change.

### Knowledge Base

Add `~/eam/eam-terraform` as a knowledge base in the orchestrator config:

```json
{
  "type": "knowledgeBase",
  "source": "file://~/eam/eam-terraform",
  "name": "eam-terraform",
  "description": "EAM Terraform infrastructure — farm stacks, modules, scripts. Search for resource definitions, variable chains, and module configurations.",
  "indexType": "best",
  "autoUpdate": true
}
```

**Personalization note:** The `~/eam/eam-terraform` path is user-specific. `scripts/personalize.sh` MUST expand `~` to `$HOME` before writing the KB entry — Kiro's tilde handling in `file://` URIs is unreliable (tested: KB with `file://~/...` source failed to index). Use: `expanded_path="${terraform_repo/#\~/$HOME}"` then inject `expanded_path` into the orchestrator JSON resources. The KB entry should NOT be committed with a hardcoded path.

---

## Part 2: dev-* → devops-* Rename

### Mapping

| Current | New |
|---------|-----|
| `dev-orchestrator` | `devops-orchestrator` |
| `dev-reviewer` | `devops-reviewer` |
| `dev-python` | `devops-python` |
| `dev-shell` | `devops-shell` |
| `dev-docs` | `devops-docs` |
| `dev-refactor` | `devops-refactor` |
| `dev-typescript` | `devops-typescript` |
| `dev-frontend` | `devops-frontend` |
| `dev-kiro-config` | `devops-kiro-config` |

### Files to Update

#### Agent JSON files (rename file + update `name` field)

- `agents/dev-orchestrator.json` → `agents/devops-orchestrator.json`
- `agents/dev-reviewer.json` → `agents/devops-reviewer.json`
- `agents/dev-python.json` → `agents/devops-python.json`
- `agents/dev-shell.json` → `agents/devops-shell.json`
- `agents/dev-docs.json` → `agents/devops-docs.json`
- `agents/dev-refactor.json` → `agents/devops-refactor.json`
- `agents/dev-typescript.json` → `agents/devops-typescript.json`
- `agents/dev-frontend.json` → `agents/devops-frontend.json`
- `.kiro/agents/dev-kiro-config.json` → `.kiro/agents/devops-kiro-config.json`

#### Prompt files (rename file)

All seven prompt files with `dev-` prefix:

- `agents/prompts/dev-docs.md` → `agents/prompts/devops-docs.md`
- `agents/prompts/dev-frontend.md` → `agents/prompts/devops-frontend.md`
- `agents/prompts/dev-python.md` → `agents/prompts/devops-python.md`
- `agents/prompts/dev-refactor.md` → `agents/prompts/devops-refactor.md`
- `agents/prompts/dev-reviewer.md` → `agents/prompts/devops-reviewer.md`
- `agents/prompts/dev-shell.md` → `agents/prompts/devops-shell.md`
- `agents/prompts/dev-typescript.md` → `agents/prompts/devops-typescript.md`

**`agents/prompts/orchestrator.md` is NOT renamed** — it has no `dev-` prefix. Only its contents are updated.

#### Cross-tree prompt reference (CRITICAL)

`.kiro/agents/devops-kiro-config.json` prompt field must be updated:

```
"file://../../agents/prompts/dev-docs.md" → "file://../../agents/prompts/devops-docs.md"
```

This depends on `devops-docs.md` existing first — sequence the prompt-file rename before this JSON update.

#### Orchestrator config (internal references)

- `availableAgents` array — all entries updated to `devops-*`
- `trustedAgents` array — all entries updated to `devops-*`
- Add `devops-terraform` to both arrays

#### Orchestrator prompt (`agents/prompts/orchestrator.md`) — content updates

- All routing table entries: `dev-*` → `devops-*`
- Post-implementation trigger list (line ~8-10): update agent names, do NOT add `devops-terraform`
- `devops-docs CANNOT delete files` note (line ~33): verify sentence reads naturally after replace
- Timeout recovery message template: `devops-<name>` format
- Add `devops-terraform` routing entry (above `devops-docs`)

#### Settings

- `settings/cli.json` — `chat.defaultAgent`: `dev-orchestrator` → `devops-orchestrator`

#### Scripts

- `scripts/personalize.sh` — update references to `dev-orchestrator.json`, `dev-docs.json`, `dev-python.json`, `dev-shell.json`, `dev-refactor.json`

#### Living documentation (text replacement)

These are actively referenced docs — update to current names:

- `README.md`
- `docs/TODO.md`
- `docs/reference/creating-agents.md`
- `docs/reference/security-model.md`
- `docs/reference/skill-catalog.md`
- `docs/setup/team-onboarding.md`

#### Historical documentation (DO NOT rewrite)

These record what was true when written. **Leave agent names as-is.** Add a one-line footer to each:

> `> Note: as of v0.7.0, dev-* agents were renamed to devops-*. See docs/specs/2026-04-18-devops-terraform-and-rename/spec.md.`

Files receiving footer only:

- `docs/audit/audit-current-workflow.md`
- `docs/audit/audit-triage-v0.5.1.md`
- `docs/audit/audit-triage-v0.6.0.md`
- `docs/improvements/resolved.md`
- `docs/reference/CHANGELOG.md` (existing entries — new v0.7.0 entry uses new names)
- `docs/reference/audit-playbook.md`
- `docs/specs/2026-04-12-foundation-hardening/plan.md`
- `docs/specs/2026-04-16-orchestrator-agent-framework-redesign/plan.md`
- `docs/specs/2026-04-16-orchestrator-agent-framework-redesign/spec.md`
- `docs/specs/2026-04-16-shell-safety-file-operations/plan.md`
- `docs/specs/2026-04-16-shell-safety-file-operations/spec.md`
- `docs/specs/2026-04-16-typescript-frontend-stack/plan.md`
- `docs/specs/2026-04-16-typescript-frontend-stack/spec.md`
- `docs/specs/2026-04-17-audit-phase1-safety/` (spec, plan, execution)
- `docs/specs/2026-04-17-audit-phase2-accuracy/` (spec, plan, execution)
- `docs/specs/2026-04-17-audit-phase3-consistency/` (spec, plan, execution)
- `docs/specs/2026-04-17-audit-phase4-deny-list-and-ergonomics-hardening/` (spec, plan, execution)

#### Skills (text replacement)

- `skills/codebase-audit/SKILL.md`
- `skills/execution-planning/SKILL.md`
- `skills/post-implementation/SKILL.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/writing-plans/SKILL.md`

#### Steering (text replacement)

- `steering/security.md`

#### Knowledge (text replacement)

- `knowledge/gotchas.md`
- `knowledge/rules.md`

#### Verify during execution

- `agents/agent_config.json.example` — check for `dev-*` refs, update if found

### Rename Strategy (ordered)

1. Rename all prompt files first (`git mv agents/prompts/dev-*.md agents/prompts/devops-*.md`)
2. Rename all agent JSON files (`git mv agents/dev-*.json agents/devops-*.json`)
3. Rename `.kiro/agents/dev-kiro-config.json` → `.kiro/agents/devops-kiro-config.json`
4. Update `name` field inside each agent JSON
5. Update `prompt` file references in all agent JSON configs — **including** `devops-kiro-config.json`'s cross-tree reference (`../../agents/prompts/devops-docs.md`)
6. Update `availableAgents`/`trustedAgents` in orchestrator JSON
7. Update `settings/cli.json` default agent
8. Update `scripts/personalize.sh`
9. Bulk text replace in living docs, skills, steering, knowledge
10. Add footer to historical docs
11. Final verification grep

---

## Phasing

### Phase 1: Rename (dev-* → devops-*)

All existing agents get renamed per the strategy above. One logical commit.

### Phase 2: New agent + steering + skill + hook

- Create `~/.kiro/agents/devops-terraform.json` (full JSON from this spec)
- Create `agents/prompts/devops-terraform.md`
- Create `steering/terraform.md`
- Create `skills/terraform-audit/SKILL.md`
- Create `hooks/terraform-preflight.sh` — workspace-scoped marker at `.terraform/.preflight-confirmed-<workspace>` (where `<workspace>` is read from `.terraform/environment`, defaulting to `default`). Hook blocks `terraform plan/validate/state/show` unless the marker matching the *current* workspace exists. Switching workspaces invalidates the previous preflight; the agent must re-run the 4 checks before resuming analysis.
- Create `scripts/mark-preflight.sh` — helper script that creates the workspace-scoped marker. Used instead of `touch` because Kiro's deny-wins-over-allow precedence blocks `touch .*` even with a narrow allow.
- Add routing entry to orchestrator prompt (above devops-docs)
- Add `devops-terraform` to orchestrator's `availableAgents`/`trustedAgents`
- Add eam-terraform knowledge base to orchestrator resources (via personalize.sh)

One logical commit.

### Phase 3: Verification + Version

- Run verification grep:
  ```bash
  grep -rE "\bdev-(orchestrator|reviewer|python|shell|docs|refactor|typescript|frontend|kiro-config)\b" \
    --exclude-dir=.git \
    /home/eam/personal/kiro-config
  ```
  Expected output: zero lines (historical docs have footer text, not the bare agent names).

- Verify `devops-orchestrator` can dispatch each renamed agent
- Verify `devops-terraform` preflight hook blocks `terraform plan` without workspace-scoped marker
- Verify `devops-terraform` preflight hook allows `terraform plan` after `bash ~/.kiro/scripts/mark-preflight.sh` creates marker
- Verify `devops-terraform` preflight hook blocks `terraform plan` after workspace switch (stale marker for previous workspace)

- **Version bump to v0.7.0**
- **CHANGELOG entry:**
  ```
  ## v0.7.0 — 2026-04-18

  ### BREAKING
  - Renamed all `dev-*` agents to `devops-*` to reflect DevOps Consultant team role
  - `settings/cli.json` default agent changed to `devops-orchestrator`
  - Migration: update any local `chat.defaultAgent` overrides from `dev-orchestrator` to `devops-orchestrator`

  ### Added
  - `devops-terraform` — read-only Terraform analysis agent with hook-enforced preflight gate
  - `terraform-audit` skill — structured Terraform error diagnosis workflow
  - `steering/terraform.md` — general Terraform analysis rules
  - `hooks/terraform-preflight.sh` — hard block on terraform plan/validate/state without preflight confirmation
  - eam-terraform knowledge base support in orchestrator (via personalize.sh)

  ### Changed
  - Historical docs receive rename footer note instead of text rewrite (preserves historical accuracy)
  ```

---

## Unknowns — Verify Before Merging Phase 2

| # | Unknown | How to verify | Blocking? |
|---|---------|---------------|-----------|
| 1 | ~~HCL AST support in code tool~~ | ~~Try pattern_search with language=hcl~~ | **Verified: NOT supported.** Spec updated to grep-only. |
| 2 | ~~`file://~/path` tilde expansion in KB source~~ | ~~Test with throwaway KB entry~~ | **Resolved via defensive expansion.** KB with `file://~/...` failed to index (root cause not isolated — could be tilde or KB subsystem). `personalize.sh` expands `~` to `$HOME` before writing. |
| 3 | ~~Deny-wins-over-allow regex precedence~~ | ~~Test `touch` with narrow allow + broad deny~~ | **Verified: deny wins.** When both `allowedCommands` and `deniedCommands` match, deny takes precedence. Preflight marker uses helper script (`mark-preflight.sh`) to avoid overlap. |
| 4 | `terraform workspace select` writes `.terraform/environment` | Confirm acceptable for analysis | No — documented as acceptable in steering |
| 5 | `terraform graph` network calls | Run on a simple stack, check for API calls | No — worst case remove from allow list |

---

## Risks

| Risk | Mitigation |
|------|------------|
| Missed reference in rename | Final grep with word boundaries; zero stale refs required |
| `terraform init` side effects | Deny `terraform init -upgrade`; allow plain `init` with `$` anchor |
| Agent runs plan against wrong workspace | Hook-enforced preflight gate (not prompt-discipline) with workspace-scoped marker |
| Stale preflight after workspace switch | Marker filename includes workspace name (`.preflight-confirmed-<workspace>`); switching workspaces makes the existing marker non-matching, forcing re-preflight before the hook unblocks `terraform plan/validate/state/show` |
| Expired AWS credentials mid-analysis | Preflight gate checks `aws sts get-caller-identity` first |
| Historical docs become inaccurate | Footer-only approach preserves original text |
| Cross-tree prompt path breaks | Explicitly enumerated in rename strategy step 5 |
| KB path hardcoded per-user | Handled via personalize.sh, not committed to main |

## Out of Scope

- Writing or modifying Terraform code (devops-terraform is read-only)
- Running `terraform apply/destroy` (permanently denied)
- Creating Terraform modules or new stacks
- Multi-repo Terraform analysis in a single session (one project at a time)
- Hook-based enforcement for non-terraform agents (existing agents keep prompt-discipline)
