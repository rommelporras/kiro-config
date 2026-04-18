# devops-terraform Agent + dev-* → devops-* Rename — Implementation Plan

> **Status: COMPLETE (2026-04-19)** — executed in single multi-agent dispatch session. Per-task checkboxes were not updated live during parallel execution. See CHANGELOG v0.7.0 for delivered scope.

> **For agentic workers:** Use the subagent-driven-development skill to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename all `dev-*` agents to `devops-*` and add a new read-only `devops-terraform` analysis agent with hook-enforced preflight gate.

**Architecture:** Phase 1 renames 9 agent JSONs, 7 prompt files, and updates all references across ~50 files. Phase 2 creates the new terraform agent, helper scripts, hook, skill, and steering. Phase 3 verifies zero stale refs and tests the preflight hook.

**Tech Stack:** Kiro CLI agent configs (JSON), Markdown prompts/skills/steering, Bash hooks/scripts.

**Spec:** `docs/specs/2026-04-18-devops-terraform-and-rename/spec.md` (v4)

---

## Phase 1: Rename dev-* → devops-*

### Task 1: Rename prompt files

**Files:**
- Rename: `agents/prompts/dev-docs.md` → `agents/prompts/devops-docs.md`
- Rename: `agents/prompts/dev-frontend.md` → `agents/prompts/devops-frontend.md`
- Rename: `agents/prompts/dev-python.md` → `agents/prompts/devops-python.md`
- Rename: `agents/prompts/dev-refactor.md` → `agents/prompts/devops-refactor.md`
- Rename: `agents/prompts/dev-reviewer.md` → `agents/prompts/devops-reviewer.md`
- Rename: `agents/prompts/dev-shell.md` → `agents/prompts/devops-shell.md`
- Rename: `agents/prompts/dev-typescript.md` → `agents/prompts/devops-typescript.md`

**`agents/prompts/orchestrator.md` is NOT renamed** — no `dev-` prefix. Contents updated in Task 5.

- [ ] **Step 1: Rename all 7 prompt files**

```bash
cd /home/eam/personal/kiro-config
git mv agents/prompts/dev-docs.md agents/prompts/devops-docs.md
git mv agents/prompts/dev-frontend.md agents/prompts/devops-frontend.md
git mv agents/prompts/dev-python.md agents/prompts/devops-python.md
git mv agents/prompts/dev-refactor.md agents/prompts/devops-refactor.md
git mv agents/prompts/dev-reviewer.md agents/prompts/devops-reviewer.md
git mv agents/prompts/dev-shell.md agents/prompts/devops-shell.md
git mv agents/prompts/dev-typescript.md agents/prompts/devops-typescript.md
```

- [ ] **Step 2: Verify renames**

```bash
ls agents/prompts/
```
Expected: `devops-docs.md devops-frontend.md devops-python.md devops-refactor.md devops-reviewer.md devops-shell.md devops-typescript.md orchestrator.md`

### Task 2: Rename agent JSON files

**Files:**
- Rename: `agents/dev-orchestrator.json` → `agents/devops-orchestrator.json`
- Rename: `agents/dev-reviewer.json` → `agents/devops-reviewer.json`
- Rename: `agents/dev-python.json` → `agents/devops-python.json`
- Rename: `agents/dev-shell.json` → `agents/devops-shell.json`
- Rename: `agents/dev-docs.json` → `agents/devops-docs.json`
- Rename: `agents/dev-refactor.json` → `agents/devops-refactor.json`
- Rename: `agents/dev-typescript.json` → `agents/devops-typescript.json`
- Rename: `agents/dev-frontend.json` → `agents/devops-frontend.json`
- Rename: `.kiro/agents/dev-kiro-config.json` → `.kiro/agents/devops-kiro-config.json`

- [ ] **Step 1: Rename all 9 agent JSON files**

```bash
cd /home/eam/personal/kiro-config
git mv agents/dev-orchestrator.json agents/devops-orchestrator.json
git mv agents/dev-reviewer.json agents/devops-reviewer.json
git mv agents/dev-python.json agents/devops-python.json
git mv agents/dev-shell.json agents/devops-shell.json
git mv agents/dev-docs.json agents/devops-docs.json
git mv agents/dev-refactor.json agents/devops-refactor.json
git mv agents/dev-typescript.json agents/devops-typescript.json
git mv agents/dev-frontend.json agents/devops-frontend.json
git mv .kiro/agents/dev-kiro-config.json .kiro/agents/devops-kiro-config.json
```

- [ ] **Step 2: Verify renames**

```bash
ls agents/*.json .kiro/agents/*.json
```
Expected: all `devops-*` names, plus `base.json` and `agent_config.json.example`.

### Task 3: Update `name` and `prompt` fields inside each agent JSON

**Files:**
- Modify: `agents/devops-orchestrator.json`
- Modify: `agents/devops-reviewer.json`
- Modify: `agents/devops-python.json`
- Modify: `agents/devops-shell.json`
- Modify: `agents/devops-docs.json`
- Modify: `agents/devops-refactor.json`
- Modify: `agents/devops-typescript.json`
- Modify: `agents/devops-frontend.json`
- Modify: `.kiro/agents/devops-kiro-config.json`

- [ ] **Step 1: Update name fields in all 9 agent JSONs**

For each file, replace `"name": "dev-<x>"` with `"name": "devops-<x>"`. Use `jq` per file:

```bash
cd /home/eam/personal/kiro-config
for agent in orchestrator reviewer python shell docs refactor typescript frontend; do
  jq '.name = "devops-'"${agent}"'"' "agents/devops-${agent}.json" > /tmp/agent-tmp.json \
    && mv /tmp/agent-tmp.json "agents/devops-${agent}.json"
done
jq '.name = "devops-kiro-config"' .kiro/agents/devops-kiro-config.json > /tmp/agent-tmp.json \
  && mv /tmp/agent-tmp.json .kiro/agents/devops-kiro-config.json
```

- [ ] **Step 2: Update prompt file references in agent JSONs**

Each agent JSON has `"prompt": "file://./prompts/dev-<x>.md"` — update to `devops-`:

```bash
cd /home/eam/personal/kiro-config
for agent in orchestrator reviewer python shell docs refactor typescript frontend; do
  jq '.prompt = (.prompt | gsub("dev-'"${agent}"'"; "devops-'"${agent}"'"))' \
    "agents/devops-${agent}.json" > /tmp/agent-tmp.json \
    && mv /tmp/agent-tmp.json "agents/devops-${agent}.json"
done
```

Note: `orchestrator.json` prompt is `file://./prompts/orchestrator.md` (no `dev-` prefix) — the loop's gsub will be a no-op, which is correct.

- [ ] **Step 3: Update cross-tree prompt reference in devops-kiro-config.json (CRITICAL)**

```bash
jq '.prompt = "file://../../agents/prompts/devops-docs.md"' \
  .kiro/agents/devops-kiro-config.json > /tmp/agent-tmp.json \
  && mv /tmp/agent-tmp.json .kiro/agents/devops-kiro-config.json
```

- [ ] **Step 4: Verify all name and prompt fields**

```bash
for f in agents/devops-*.json .kiro/agents/devops-kiro-config.json; do
  echo "=== $(basename "$f") ==="
  jq '{name: .name, prompt: .prompt}' "$f"
done
```

Expected: all names start with `devops-`, all prompts reference `devops-` files. `devops-kiro-config.json` prompt is `file://../../agents/prompts/devops-docs.md`.

### Task 4: Update orchestrator JSON internals

**Files:**
- Modify: `agents/devops-orchestrator.json`

- [ ] **Step 1: Update availableAgents array**

Replace all `dev-` entries with `devops-` and add `devops-terraform`:

```bash
cd /home/eam/personal/kiro-config
jq '.toolsSettings.subagent.availableAgents = [
  "devops-docs", "devops-python", "devops-shell", "devops-reviewer",
  "devops-refactor", "devops-kiro-config", "devops-typescript",
  "devops-frontend", "devops-terraform"
]' agents/devops-orchestrator.json > /tmp/agent-tmp.json \
  && mv /tmp/agent-tmp.json agents/devops-orchestrator.json
```

- [ ] **Step 2: Update trustedAgents array**

```bash
jq '.toolsSettings.subagent.trustedAgents = [
  "devops-docs", "devops-python", "devops-shell", "devops-reviewer",
  "devops-refactor", "devops-kiro-config", "devops-typescript",
  "devops-frontend", "devops-terraform"
]' agents/devops-orchestrator.json > /tmp/agent-tmp.json \
  && mv /tmp/agent-tmp.json agents/devops-orchestrator.json
```

- [ ] **Step 3: Verify**

```bash
jq '.toolsSettings.subagent' agents/devops-orchestrator.json
```

Expected: both arrays contain 9 entries, all `devops-*`, including `devops-terraform`.

### Task 5: Update orchestrator prompt content

**Files:**
- Modify: `agents/prompts/orchestrator.md`

- [ ] **Step 1: Bulk replace dev- agent names in orchestrator prompt**

Replace all agent name references. Use `sed` (this is markdown, not JSON):

```bash
cd /home/eam/personal/kiro-config
sed -i \
  -e 's/dev-orchestrator/devops-orchestrator/g' \
  -e 's/dev-kiro-config/devops-kiro-config/g' \
  -e 's/dev-typescript/devops-typescript/g' \
  -e 's/dev-frontend/devops-frontend/g' \
  -e 's/dev-reviewer/devops-reviewer/g' \
  -e 's/dev-refactor/devops-refactor/g' \
  -e 's/dev-python/devops-python/g' \
  -e 's/dev-shell/devops-shell/g' \
  -e 's/dev-docs/devops-docs/g' \
  agents/prompts/orchestrator.md
```

- [ ] **Step 2: Add devops-terraform routing entry ABOVE devops-docs**

Insert the following block before the `→ devops-docs` section in `agents/prompts/orchestrator.md`:

```markdown
### → devops-terraform
Triggers: terraform error, plan failed, missing variable, state drift,
what changed in terraform, trace terraform variable, explain terraform stack,
terraform workspace issue, why did this break, analyze .tf files,
terraform diagnose, HCL analysis
Route when: the issue involves Terraform code, state, or infrastructure-as-code analysis.
Note: read-only — no write access. Dispatched with error messages and file paths.
```

- [ ] **Step 3: Verify post-implementation trigger list does NOT include devops-terraform**

Check the paragraph near the top listing implementation subagents. It should read:
`devops-python, devops-shell, devops-refactor, devops-kiro-config, devops-typescript, devops-frontend`

- [ ] **Step 4: Verify no stale dev- references remain**

```bash
grep -n "dev-" agents/prompts/orchestrator.md | grep -v "devops-"
```

Expected: zero lines.

### Task 6: Update settings and scripts

**Files:**
- Modify: `settings/cli.json`
- Modify: `scripts/personalize.sh`

- [ ] **Step 1: Update settings/cli.json**

```bash
cd /home/eam/personal/kiro-config
jq '."chat.defaultAgent" = "devops-orchestrator"' settings/cli.json > /tmp/cli-tmp.json \
  && mv /tmp/cli-tmp.json settings/cli.json
```

- [ ] **Step 2: Update scripts/personalize.sh**

Replace `dev-` agent filenames with `devops-`:

```bash
sed -i \
  -e 's/dev-orchestrator/devops-orchestrator/g' \
  -e 's/dev-docs/devops-docs/g' \
  -e 's/dev-python/devops-python/g' \
  -e 's/dev-shell/devops-shell/g' \
  -e 's/dev-refactor/devops-refactor/g' \
  scripts/personalize.sh
```

- [ ] **Step 3: Verify**

```bash
grep "devops-" settings/cli.json scripts/personalize.sh
grep "dev-" scripts/personalize.sh | grep -v "devops-"
```

Expected: `devops-orchestrator` in cli.json, all `devops-*` in personalize.sh, zero stale `dev-` refs.

### Task 7: Update living documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/TODO.md`
- Modify: `docs/reference/creating-agents.md`
- Modify: `docs/reference/security-model.md`
- Modify: `docs/reference/skill-catalog.md`
- Modify: `docs/setup/team-onboarding.md`

- [ ] **Step 1: Bulk replace in living docs**

```bash
cd /home/eam/personal/kiro-config
for f in README.md docs/TODO.md docs/reference/creating-agents.md \
  docs/reference/security-model.md docs/reference/skill-catalog.md \
  docs/setup/team-onboarding.md; do
  sed -i \
    -e 's/dev-orchestrator/devops-orchestrator/g' \
    -e 's/dev-kiro-config/devops-kiro-config/g' \
    -e 's/dev-typescript/devops-typescript/g' \
    -e 's/dev-frontend/devops-frontend/g' \
    -e 's/dev-reviewer/devops-reviewer/g' \
    -e 's/dev-refactor/devops-refactor/g' \
    -e 's/dev-python/devops-python/g' \
    -e 's/dev-shell/devops-shell/g' \
    -e 's/dev-docs/devops-docs/g' \
    "$f"
done
```

- [ ] **Step 2: Verify zero stale refs in living docs**

```bash
grep -rn "\bdev-\(orchestrator\|reviewer\|python\|shell\|docs\|refactor\|typescript\|frontend\|kiro-config\)\b" \
  README.md docs/TODO.md docs/reference/creating-agents.md \
  docs/reference/security-model.md docs/reference/skill-catalog.md \
  docs/setup/team-onboarding.md
```

Expected: zero lines.

### Task 8: Add footer to historical documentation

**DO NOT rewrite agent names in these files.** Add a one-line footer only.

**Files (append footer):**
- `docs/audit/audit-current-workflow.md`
- `docs/audit/audit-triage-v0.5.1.md`
- `docs/audit/audit-triage-v0.6.0.md`
- `docs/improvements/resolved.md`
- `docs/reference/CHANGELOG.md`
- `docs/reference/audit-playbook.md`
- `docs/specs/2026-04-12-foundation-hardening/plan.md`
- `docs/specs/2026-04-16-orchestrator-agent-framework-redesign/plan.md`
- `docs/specs/2026-04-16-orchestrator-agent-framework-redesign/spec.md`
- `docs/specs/2026-04-16-shell-safety-file-operations/plan.md`
- `docs/specs/2026-04-16-shell-safety-file-operations/spec.md`
- `docs/specs/2026-04-16-typescript-frontend-stack/plan.md`
- `docs/specs/2026-04-16-typescript-frontend-stack/spec.md`
- All files in `docs/specs/2026-04-17-audit-phase1-safety/`
- All files in `docs/specs/2026-04-17-audit-phase2-accuracy/`
- All files in `docs/specs/2026-04-17-audit-phase3-consistency/`
- All files in `docs/specs/2026-04-17-audit-phase4-deny-list-and-ergonomics-hardening/`

- [ ] **Step 1: Append footer to all historical docs**

Footer text:
```
> Note: as of v0.7.0, dev-* agents were renamed to devops-*. See docs/specs/2026-04-18-devops-terraform-and-rename/spec.md.
```

```bash
cd /home/eam/personal/kiro-config
FOOTER=$'\n> Note: as of v0.7.0, dev-* agents were renamed to devops-*. See docs/specs/2026-04-18-devops-terraform-and-rename/spec.md.'

# Explicit list of historical files
HIST_FILES=(
  docs/audit/audit-current-workflow.md
  docs/audit/audit-triage-v0.5.1.md
  docs/audit/audit-triage-v0.6.0.md
  docs/improvements/resolved.md
  docs/reference/CHANGELOG.md
  docs/reference/audit-playbook.md
  docs/specs/2026-04-12-foundation-hardening/plan.md
  docs/specs/2026-04-16-orchestrator-agent-framework-redesign/plan.md
  docs/specs/2026-04-16-orchestrator-agent-framework-redesign/spec.md
  docs/specs/2026-04-16-shell-safety-file-operations/plan.md
  docs/specs/2026-04-16-shell-safety-file-operations/spec.md
  docs/specs/2026-04-16-typescript-frontend-stack/plan.md
  docs/specs/2026-04-16-typescript-frontend-stack/spec.md
)

# Add phase audit specs (all .md files in each dir)
for dir in docs/specs/2026-04-17-audit-phase{1,2,3,4}-*/; do
  for f in "${dir}"*.md "${dir}"execution/*.md; do
    [[ -f "$f" ]] && HIST_FILES+=("$f")
  done
done

for f in "${HIST_FILES[@]}"; do
  echo "$FOOTER" >> "$f"
done
```

- [ ] **Step 2: Verify footers were added (spot check)**

```bash
tail -1 docs/audit/audit-triage-v0.5.1.md
tail -1 docs/specs/2026-04-17-audit-phase1-safety/spec.md
```

Expected: both end with the footer note.

### Task 9: Update skills, steering, and knowledge

**Files:**
- Modify: `skills/codebase-audit/SKILL.md`
- Modify: `skills/execution-planning/SKILL.md`
- Modify: `skills/post-implementation/SKILL.md`
- Modify: `skills/subagent-driven-development/SKILL.md`
- Modify: `skills/writing-plans/SKILL.md`
- Modify: `steering/security.md`
- Modify: `knowledge/gotchas.md`
- Modify: `knowledge/rules.md`

- [ ] **Step 1: Bulk replace in skills, steering, knowledge**

```bash
cd /home/eam/personal/kiro-config
for f in skills/codebase-audit/SKILL.md skills/execution-planning/SKILL.md \
  skills/post-implementation/SKILL.md skills/subagent-driven-development/SKILL.md \
  skills/writing-plans/SKILL.md steering/security.md \
  knowledge/gotchas.md knowledge/rules.md; do
  sed -i \
    -e 's/dev-orchestrator/devops-orchestrator/g' \
    -e 's/dev-kiro-config/devops-kiro-config/g' \
    -e 's/dev-typescript/devops-typescript/g' \
    -e 's/dev-frontend/devops-frontend/g' \
    -e 's/dev-reviewer/devops-reviewer/g' \
    -e 's/dev-refactor/devops-refactor/g' \
    -e 's/dev-python/devops-python/g' \
    -e 's/dev-shell/devops-shell/g' \
    -e 's/dev-docs/devops-docs/g' \
    "$f"
done
```

- [ ] **Step 2: Check agent_config.json.example for stale refs**

```bash
grep "dev-" agents/agent_config.json.example | grep -v "devops-"
```

If any hits, apply the same sed pattern. If zero, no action needed.

- [ ] **Step 3: Final Phase 1 verification grep**

```bash
grep -rE "\bdev-(orchestrator|reviewer|python|shell|docs|refactor|typescript|frontend|kiro-config)\b" \
  --exclude-dir=.git \
  /home/eam/personal/kiro-config
```

Expected: zero lines. Historical docs have the footer note text which uses `dev-*` in prose ("dev-* agents were renamed") — this is intentional and the `\b` boundary won't match it inside the sentence.

- [ ] **Step 4: Report Phase 1 completion**

Subagent reports DONE. Orchestrator handles `git add` and commit:
```
feat: rename dev-* agents to devops-* (v0.7.0)
```

---

## Phase 2: New Agent + Steering + Skill + Hook

**Sequence matters:** `mark-preflight.sh` → `terraform-preflight.sh` → agent JSON → routing update. The agent's allow list references the helper script, so it must exist first.

### Task 10: Create helper script — mark-preflight.sh

**Files:**
- Create: `scripts/mark-preflight.sh`

- [ ] **Step 1: Create the script**

```bash
cat > /home/eam/personal/kiro-config/scripts/mark-preflight.sh << 'EOF'
#!/usr/bin/env bash
# Creates the workspace-scoped preflight marker.
# Called by devops-terraform agent after user confirms preflight checklist.

set -euo pipefail

WS="$(cat .terraform/environment 2>/dev/null || echo default)"
touch ".terraform/.preflight-confirmed-${WS}"
echo "Preflight marker created for workspace '${WS}'."
EOF
```

- [ ] **Step 2: Make executable**

```bash
chmod +x /home/eam/personal/kiro-config/scripts/mark-preflight.sh
```

- [ ] **Step 3: Verify**

```bash
head -5 scripts/mark-preflight.sh && ls -la scripts/mark-preflight.sh
```

Expected: shebang present, executable bit set.

### Task 11: Create preflight hook — terraform-preflight.sh

**Files:**
- Create: `hooks/terraform-preflight.sh`

- [ ] **Step 1: Create the hook**

```bash
cat > /home/eam/personal/kiro-config/hooks/terraform-preflight.sh << 'HOOKEOF'
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
HOOKEOF
```

- [ ] **Step 2: Make executable**

```bash
chmod +x /home/eam/personal/kiro-config/hooks/terraform-preflight.sh
```

- [ ] **Step 3: Verify**

```bash
head -5 hooks/terraform-preflight.sh && ls -la hooks/terraform-preflight.sh
```

Expected: shebang present, executable bit set.

### Task 12: Create devops-terraform agent config

**Files:**
- Create: `agents/devops-terraform.json`

- [ ] **Step 1: Create the agent JSON**

Create `agents/devops-terraform.json` with the complete config from spec v4 section "Complete Agent JSON Config". Key points:
- `"prompt": "file://./prompts/devops-terraform.md"`
- `allowedCommands` includes `"bash .*/mark-preflight\\.sh$"` (NOT `touch`)
- `deniedCommands` includes full AWS shell deny block + `touch .*`
- `use_aws` with `autoAllowReadonly: true`
- `includeMcpJson: false`
- Hook: `terraform-preflight.sh` first, then `bash-write-protect.sh`, then `block-sed-json.sh`

- [ ] **Step 2: Verify JSON is valid**

```bash
jq '.' agents/devops-terraform.json > /dev/null && echo "valid JSON"
jq '{name: .name, prompt: .prompt, tools: .tools, model: .model}' agents/devops-terraform.json
```

Expected: valid JSON, name=`devops-terraform`, prompt=`file://./prompts/devops-terraform.md`, tools=`[read, shell, code, aws]`, model=`claude-sonnet-4.6`.

### Task 13: Create devops-terraform prompt

**Files:**
- Create: `agents/prompts/devops-terraform.md`

- [ ] **Step 1: Create the prompt file**

Content must include (per spec v4 "Prompt Structure"):
- Identity: read-only Terraform analyst, subagent of devops-orchestrator
- Preflight gate: the 4 checks, instruction to run `bash ~/.kiro/scripts/mark-preflight.sh` after user confirms
- Symlink awareness: always `ls -la` and `readlink -f` before analyzing
- Workspace awareness: verify workspace before running plan
- Variable tracing methodology (tfvars → variables → locals → module → resource)
- Remote state dependency awareness (importvars.tf pattern)
- Report format: root cause → affected files → git history → suggested fix
- What it never does: modify files, run mutating commands, apply changes
- Handoff pattern: report exact change needed, orchestrator briefs devops-docs

- [ ] **Step 2: Verify file exists and is non-empty**

```bash
wc -l agents/prompts/devops-terraform.md
```

Expected: >30 lines.

### Task 14: Create Terraform steering

**Files:**
- Create: `steering/terraform.md`

- [ ] **Step 1: Create steering file**

Content (from spec v4 "New Steering" section):

```markdown
# Terraform

## Analysis Rules
- Always `terraform fmt --check` before analyzing — formatting issues mask real problems.
- Trace variables through full chain: `terraform.tfvars` → `variables.tf` → `locals` → module input → resource attribute.
- Check `importvars.tf` / remote state data sources for cross-stack dependencies.
- For "missing variable" errors: (1) defined in `variables.tf`? (2) set in `.tfvars` or workspace file? (3) recently added in module but not propagated?
- Use `git log --oneline -20 -- <file>` for recent changes.
- For workspace issues, verify selected workspace before diagnosing.
- Never run mutating Terraform commands — analysis only.
- Resolve symlinks before analyzing — the actual source may be in a different directory.
- `terraform workspace select` writes `.terraform/environment` — acceptable for analysis but is technically a local state change.
```

- [ ] **Step 2: Verify**

```bash
test -f steering/terraform.md && echo "exists"
```

### Task 15: Create terraform-audit skill

**Files:**
- Create: `skills/terraform-audit/SKILL.md`

- [ ] **Step 1: Create skill directory and file**

```bash
mkdir -p /home/eam/personal/kiro-config/skills/terraform-audit
```

Content: use the complete SKILL.md draft from spec v4 section "New Skill: terraform-audit" (includes frontmatter, process, output format, guidelines).

- [ ] **Step 2: Verify**

```bash
head -3 skills/terraform-audit/SKILL.md
```

Expected: YAML frontmatter with `name: terraform-audit`.

### Task 16: Update orchestrator routing and resources

**Files:**
- Modify: `agents/devops-orchestrator.json`

- [ ] **Step 1: Verify devops-terraform is already in availableAgents/trustedAgents**

(Done in Task 4. Verify it survived.)

```bash
jq '.toolsSettings.subagent.availableAgents | index("devops-terraform")' agents/devops-orchestrator.json
```

Expected: a number (not null).

- [ ] **Step 2: Report Phase 2 completion**

Subagent reports DONE. Orchestrator handles `git add` and commit:
```
feat: add devops-terraform agent, terraform-audit skill, terraform steering, preflight hook
```

---

## Phase 3: Verification + Version

### Task 17: Verification

- [ ] **Step 1: Zero stale refs grep**

```bash
cd /home/eam/personal/kiro-config
grep -rE "\bdev-(orchestrator|reviewer|python|shell|docs|refactor|typescript|frontend|kiro-config)\b" \
  --exclude-dir=.git .
```

Expected: zero lines.

- [ ] **Step 2: Preflight hook test — blocks without marker**

```bash
mkdir -p /tmp/tf-hook-test/.terraform
cd /tmp/tf-hook-test
echo '{"tool_use_id":"test","tool_name":"execute_bash","tool_input":{"command":"terraform plan"}}' \
  | bash ~/.kiro/hooks/terraform-preflight.sh
echo "exit code: $?"
```

Expected: stderr contains `BLOCKED: Preflight not completed for workspace 'default'`, exit code 2.

- [ ] **Step 3: Preflight hook test — allows with correct marker**

```bash
cd /tmp/tf-hook-test
bash ~/.kiro/scripts/mark-preflight.sh
echo '{"tool_use_id":"test","tool_name":"execute_bash","tool_input":{"command":"terraform plan"}}' \
  | bash ~/.kiro/hooks/terraform-preflight.sh
echo "exit code: $?"
```

Expected: `Preflight marker created for workspace 'default'.`, then exit code 0.

- [ ] **Step 4: Preflight hook test — blocks after workspace switch**

```bash
cd /tmp/tf-hook-test
echo "staging" > .terraform/environment
echo '{"tool_use_id":"test","tool_name":"execute_bash","tool_input":{"command":"terraform plan"}}' \
  | bash ~/.kiro/hooks/terraform-preflight.sh
echo "exit code: $?"
```

Expected: stderr contains `BLOCKED: Preflight not completed for workspace 'staging'`, exit code 2. The `default` marker exists but doesn't match `staging`.

- [ ] **Step 5: Cleanup test dir**

```bash
find /tmp/tf-hook-test -delete
```

### Task 18: Version bump + CHANGELOG

**Files:**
- Modify: `docs/reference/CHANGELOG.md`

- [ ] **Step 1: Add v0.7.0 entry to CHANGELOG**

Prepend to `docs/reference/CHANGELOG.md` (after any header):

```markdown
## v0.7.0 — 2026-04-19

### BREAKING
- Renamed all `dev-*` agents to `devops-*` to reflect DevOps Consultant team role
- `settings/cli.json` default agent changed to `devops-orchestrator`
- Migration: update any local `chat.defaultAgent` overrides from `dev-orchestrator` to `devops-orchestrator`

### Added
- `devops-terraform` — read-only Terraform analysis agent with hook-enforced preflight gate
- `terraform-audit` skill — structured Terraform error diagnosis workflow
- `steering/terraform.md` — general Terraform analysis rules
- `hooks/terraform-preflight.sh` — hard block on terraform plan/validate/state without preflight confirmation
- `scripts/mark-preflight.sh` — workspace-scoped preflight marker helper (deny-wins-over-allow workaround)
- eam-terraform knowledge base support in orchestrator (via personalize.sh)
- `knowledge/gotchas.md` — documented Kiro regex precedence: deny wins over allow when both match

### Changed
- Historical docs receive rename footer note instead of text rewrite (preserves historical accuracy)
```

- [ ] **Step 2: Verify**

```bash
head -20 docs/reference/CHANGELOG.md
```

Expected: v0.7.0 entry at top.

- [ ] **Step 3: Report completion**

Subagent reports DONE. Orchestrator handles final commit:
```
docs: add v0.7.0 CHANGELOG entry
```
