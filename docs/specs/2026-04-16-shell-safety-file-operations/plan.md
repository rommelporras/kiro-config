# Shell Safety & File Operations — Implementation Plan

> **For agentic workers:** Use the subagent-driven-development skill to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the blunt `rm .*` deny pattern with smart shell safety rules that allow safe file operations while blocking destructive ones.

**Architecture:** Rewrite bash-write-protect.sh hook with path-aware rm detection, update deniedCommands in all agent JSON configs, add file operations routing to orchestrator prompt.

**Tech Stack:** Bash (hook), JSON (agent configs), Markdown (orchestrator prompt)

**Spec:** `docs/specs/2026-04-16-shell-safety-file-operations/spec.md`

**Session boundary:** This spec modifies agent JSON configs. After committing, exit and start a new session for changes to take effect.

---

### Task 1: Rewrite bash-write-protect.sh rm detection

**Files:**
- Modify: `hooks/bash-write-protect.sh`

- [x] **Step 1: Read the current hook**

Read `hooks/bash-write-protect.sh` to understand existing structure.

- [x] **Step 2: Replace the DESTRUCTIVE OPERATIONS section**

Keep the existing SENSITIVE FILE WRITES section and force-push block unchanged.
Replace the DESTRUCTIVE OPERATIONS section with smart rm detection:

```bash
# =============================================================================
# RM SAFETY — allow single-file rm, block recursive rm
# =============================================================================

if echo "$COMMAND" | grep -qP '\brm\b'; then
  # Hard block: catastrophic patterns (always blocked, no exceptions)
  CATASTROPHIC=(
    "rm -rf /"
    "rm -rf /*"
    "rm -rf ~"
    "rm -rf \$HOME"
  )
  for pattern in "${CATASTROPHIC[@]}"; do
    if [[ "$COMMAND" == *"$pattern"* ]]; then
      echo "BLOCKED: Catastrophic rm pattern detected: '$pattern'" >&2
      echo "This command is never allowed." >&2
      exit 2
    fi
  done

  # Block recursive rm (any flag combination containing 'r')
  if echo "$COMMAND" | grep -qP '\brm\b.*(-[a-zA-Z]*r[a-zA-Z]*|--recursive)'; then
    echo "BLOCKED: rm with recursive flag requires user confirmation." >&2
    echo "Run this manually in your terminal." >&2
    exit 2
  fi

  # Allow single-file rm within allowed paths
  ALLOWED_PREFIXES=(
    "${HOME}/eam/"
    "${HOME}/personal/"
    "${HOME}/.kiro/"
  )

  # Extract rm targets (skip flags starting with -)
  TARGETS=()
  IN_RM=false
  for word in $COMMAND; do
    if [[ "$word" == "rm" ]]; then
      IN_RM=true
      continue
    fi
    if [[ "$IN_RM" == true ]] && [[ "$word" != -* ]]; then
      TARGETS+=("$word")
    fi
  done

  for target in "${TARGETS[@]}"; do
    # Resolve to absolute path
    RESOLVED=$(readlink -f "$target" 2>/dev/null || echo "$target")
    ALLOWED=false
    for prefix in "${ALLOWED_PREFIXES[@]}"; do
      if [[ "$RESOLVED" == "$prefix"* ]]; then
        ALLOWED=true
        break
      fi
    done
    if [[ "$ALLOWED" != true ]]; then
      echo "BLOCKED: rm target '$target' is outside allowed paths." >&2
      echo "Allowed: ~/eam/, ~/personal/, ~/.kiro/" >&2
      exit 2
    fi
  done
fi

# Keep existing: force push to main/master block
```

- [x] **Step 3: Keep existing blocks that aren't rm-related**

Preserve the existing blocks:
- Force push to main/master detection (at the bottom of the file)
- The SENSITIVE FILE WRITES section (at the top)

Remove the old DANGEROUS array and its loop — replaced by the new rm detection above.

- [x] **Step 4: Verify shellcheck clean**

Run: `shellcheck hooks/bash-write-protect.sh`
Expected: zero warnings

- [x] **Step 5: Test the hook manually**

```bash
# Should ALLOW:
echo '{"tool_input":{"command":"rm docs/old-file.md"}}' | bash hooks/bash-write-protect.sh
echo $?  # Expected: 0

# Should BLOCK:
echo '{"tool_input":{"command":"rm -rf docs/"}}' | bash hooks/bash-write-protect.sh
echo $?  # Expected: 2

# Should BLOCK:
echo '{"tool_input":{"command":"rm -rf /"}}' | bash hooks/bash-write-protect.sh
echo $?  # Expected: 2

# Should ALLOW:
echo '{"tool_input":{"command":"mv file1.md file2.md"}}' | bash hooks/bash-write-protect.sh
echo $?  # Expected: 0
```

- [x] **Step 6: Report completion**

---

### Task 2: Update deniedCommands in all agent JSON configs

**Files:**
- Modify: `agents/dev-orchestrator.json`
- Modify: `agents/dev-python.json`
- Modify: `agents/dev-shell.json`
- Modify: `agents/dev-docs.json`
- Modify: `agents/dev-refactor.json`
- Modify: `agents/base.json`
- Verify: `agents/dev-reviewer.json` (keep rm fully blocked)

Note: These files are under `~/.kiro/agents` via symlink. Use the
dev-kiro-config agent if available, otherwise edit via shell.

- [x] **Step 1: Read current deniedCommands from all agents**

Read each agent JSON and note the current `"rm .*"` pattern.

- [x] **Step 2: Update orchestrator deniedCommands**

In `agents/dev-orchestrator.json`, replace `"rm .*"` with nothing — remove
the rm entry entirely. The orchestrator is protected by the hook (hooks fire
on the orchestrator). Keep all other deny patterns unchanged.

- [x] **Step 3: Update subagent deniedCommands (dev-python, dev-shell, dev-refactor)**

In each of these files, replace `"rm .*"` with these three patterns:
```json
"rm -r.*",
"rm -f.*r.*",
"rm --recursive.*"
```
This blocks recursive rm but allows single-file `rm path/to/file`. Hooks
don't fire on subagents, so the deny patterns are the safety net.

- [x] **Step 4: Update dev-docs deniedCommands**

Same as Step 3 — replace `"rm .*"` with the three recursive-blocking patterns.

- [x] **Step 5: Update base.json deniedCommands**

Same as Step 3 — replace `"rm .*"` with the three recursive-blocking patterns.

- [x] **Step 6: Verify dev-reviewer keeps rm fully blocked**

Read `agents/dev-reviewer.json` and confirm `"rm .*"` is still present.
Do NOT modify dev-reviewer — it's read-only, no deletions ever.

- [x] **Step 7: Verify all changes are consistent**

```bash
# Should show rm patterns for each agent
for f in agents/*.json; do
  echo "=== $(basename $f) ==="
  jq -r '.toolsSettings.execute_bash.deniedCommands // .toolsSettings."execute_bash".deniedCommands | .[] | select(startswith("rm"))' "$f"
done
```

Expected:
- dev-orchestrator: no rm entries
- dev-reviewer: `rm .*`
- All others: `rm -r.*`, `rm -f.*r.*`, `rm --recursive.*`

- [x] **Step 8: Report completion**

---

### Task 3: Add file operations routing to orchestrator prompt

**Files:**
- Modify: `agents/prompts/orchestrator.md`

- [x] **Step 1: Read the current routing table**

Read `agents/prompts/orchestrator.md` and find the routing table section.

- [x] **Step 2: Add file operations lane**

Add before the "Handle directly (DO NOT delegate)" section:

```markdown
### → Handle directly (file operations)

Triggers: move file, rename file, delete file, organize files,
move directory, clean up files

Handle when: The user wants to move, rename, or delete files.
Use shell commands directly. For rm -rf on directories, confirm
with user first. Single-file rm within allowed paths is safe.
```

- [x] **Step 3: Verify the routing table is well-ordered**

Read the full routing table and confirm:
- File operations lane exists before "Handle directly (DO NOT delegate)"
- No duplicate triggers between lanes
- The "Handle directly" section doesn't include file operation triggers

- [x] **Step 4: Report completion**

---

### Task 4: Verify end-to-end

- [x] **Step 1: Run shellcheck on all modified hooks**

```bash
shellcheck hooks/bash-write-protect.sh
```
Expected: zero warnings

- [x] **Step 2: Verify all agent JSON files are valid JSON**

```bash
for f in agents/*.json; do
  jq empty "$f" && echo "$f: valid" || echo "$f: INVALID"
done
```
Expected: all valid

- [x] **Step 3: Grep for stale `"rm .*"` patterns**

```bash
grep -rn '"rm \.\*"' agents/*.json
```
Expected: only dev-reviewer.json matches

- [x] **Step 4: Report completion**
