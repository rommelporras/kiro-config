# Phase 1: Safety Fixes — Implementation Plan

> **For agentic workers:** Use the subagent-driven-development skill to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all confirmed safety bugs in agent deny lists, hook scripts, and skill trigger lists.

**Architecture:** Pure config/script edits — no new files, no new features. Each task is a targeted find-and-replace or small code edit in existing files. Group A tasks (1-6) have no design decisions. Group B (Task 7) adds security hooks to subagent configs.

**Tech Stack:** JSON (agent configs), Bash (hook scripts), Markdown (skill files). Use `jq` for JSON verification, `grep` for text verification.

---

## File Structure

No new files created. All modifications to existing files:

| File | Tasks | What Changes |
|---|---|---|
| `agents/dev-orchestrator.json` | 1, 2, 6 | dd pattern, rm pattern, add rm deny |
| `agents/dev-python.json` | 1, 2, 7 | dd pattern, rm pattern, add hooks |
| `agents/dev-shell.json` | 1, 2, 7 | dd pattern, rm pattern, add hooks |
| `agents/dev-frontend.json` | 1, 2, 7 | dd pattern, rm pattern, add hooks |
| `agents/dev-typescript.json` | 1, 2, 7 | dd pattern, rm pattern, add hooks |
| `agents/dev-refactor.json` | 1, 2, 7 | dd pattern, rm pattern, add hooks |
| `agents/dev-reviewer.json` | 1, 7 | dd pattern, add hooks (bash only) |
| `agents/dev-docs.json` | 1, 2, 7 | add dd pattern, rm pattern, add hooks |
| `agents/base.json` | 2 | rm pattern only (dd already correct) |
| `.kiro/agents/dev-kiro-config.json` | 1, 7 | add dd pattern, add hooks |
| `hooks/feedback/context-enrichment.sh` | 3 | escape regex metacharacters |
| `hooks/_lib/distill.sh` | 4 | replace sed with awk |
| `skills/post-implementation/SKILL.md` | 5 | sync trigger list |

---

### Task 1: Fix `dd` deny-list typo (CRITICAL-08)

**Files:**
- Modify: `agents/dev-orchestrator.json`
- Modify: `agents/dev-python.json`
- Modify: `agents/dev-shell.json`
- Modify: `agents/dev-frontend.json`
- Modify: `agents/dev-typescript.json`
- Modify: `agents/dev-refactor.json`
- Modify: `agents/dev-reviewer.json`
- Modify: `agents/dev-docs.json` (add new entry)
- Modify: `.kiro/agents/dev-kiro-config.json` (add new entry)

- [x] **Step 1: Fix the typo in 7 agent JSONs that have the wrong pattern**

In each of these 7 files, replace:
```
"dd if/dev"
```
with:
```
"dd if=/dev.*"
```

Files: `dev-orchestrator.json`, `dev-python.json`, `dev-shell.json`,
`dev-frontend.json`, `dev-typescript.json`, `dev-refactor.json`,
`dev-reviewer.json`

- [x] **Step 2: Add `dd` pattern to dev-docs.json**

`dev-docs.json` has no `dd` pattern at all. Add `"dd if=/dev.*"` to its
`deniedCommands` array, after the existing `"rm --recursive.*"` entry:

oldStr (in deniedCommands):
```
        "rm --recursive.*",
```
newStr:
```
        "rm --recursive.*",
        "dd if=/dev.*",
```

- [x] **Step 3: Add `dd` pattern to dev-kiro-config.json**

`.kiro/agents/dev-kiro-config.json` has no `dd` pattern. Add `"dd if=/dev.*"`
to its `deniedCommands` array, after `"rm .*"`:

oldStr:
```
        "rm .*",
```
newStr:
```
        "rm .*",
        "dd if=/dev.*",
```

- [x] **Step 4: Verify — no old pattern remains**

Run: `grep -r '"dd if' agents/ .kiro/agents/`

Expected: every match shows `"dd if=/dev.*"`. Zero matches for `"dd if/dev"`.

Also verify `base.json` still has its correct `"dd if=/dev"` (no `.*` suffix
needed — base.json uses a different deny-list style, leave it as-is).

---

### Task 2: Fix `rm` regex false positives (HIGH-10)

**Files:**
- Modify: `agents/dev-python.json`
- Modify: `agents/dev-shell.json`
- Modify: `agents/dev-frontend.json`
- Modify: `agents/dev-typescript.json`
- Modify: `agents/dev-refactor.json`
- Modify: `agents/dev-docs.json`
- Modify: `agents/dev-orchestrator.json` (add new entries — Task 6 combined here)
- Modify: `agents/base.json`

- [x] **Step 1: Replace `rm -f.*r.*` in 6 subagent JSONs**

In each of these 6 files, replace:
```
        "rm -f.*r.*",
```
with:
```
        "rm -[a-zA-Z]*r[a-zA-Z]* .*",
        "rm --force --recursive.*",
```

Files: `dev-python.json`, `dev-shell.json`, `dev-frontend.json`,
`dev-typescript.json`, `dev-refactor.json`, `dev-docs.json`

- [x] **Step 2: Replace `rm -f.*r.*` in base.json**

Same replacement in `agents/base.json`:
```
        "rm -f.*r.*",
```
→
```
        "rm -[a-zA-Z]*r[a-zA-Z]* .*",
        "rm --force --recursive.*",
```

- [x] **Step 3: Add `rm` deny patterns to dev-orchestrator.json (MEDIUM-11)**

**Dependency:** This step uses the corrected `"dd if=/dev.*"` pattern from
Task 1 as an anchor. Task 1 must complete on `dev-orchestrator.json` before
this step runs. Tasks 1 and 2 must be sequential, not parallel.

The orchestrator has zero `rm` patterns. Add after the `"dd if=/dev.*"` line
(which Task 1 just fixed):

oldStr:
```
        "dd if=/dev.*",
```
newStr:
```
        "dd if=/dev.*",
        "rm -[a-zA-Z]*r[a-zA-Z]* .*",
        "rm --recursive.*",
```

- [x] **Step 4: Verify**

Run: `grep -rn 'rm -f.*r\.\*' agents/ .kiro/agents/`
Expected: zero matches (old pattern gone).

Run: `grep -rn 'rm -\[a-zA-Z\]' agents/`
Expected: matches in all 7 files that had the old pattern, plus orchestrator.

---

### Task 3: Fix regex injection in context-enrichment.sh (HIGH-15)

**File:**
- Modify: `hooks/feedback/context-enrichment.sh`

- [x] **Step 1: Add PCRE metacharacter escaping before the grep**

Find the keyword matching block inside the `while` loop. Current code:

```bash
      if echo "$PROMPT" | grep -qiP "\b${kw}\b"; then
```

Replace with:

```bash
      escaped_kw=$(printf '%s' "$kw" | sed 's/[.[\*^$()+?{|\\]/\\&/g')
      if echo "$PROMPT" | grep -qiP "\b${escaped_kw}\b"; then
```

- [x] **Step 2: Verify**

Run: `grep 'escaped_kw' hooks/feedback/context-enrichment.sh`
Expected: two matches (the assignment and the grep usage).

Run: `grep 'grep -qiP.*\${kw}' hooks/feedback/context-enrichment.sh`
Expected: zero matches (raw `$kw` no longer used in grep).

---

### Task 4: Fix distill.sh sed corruption (HIGH-16)

**File:**
- Modify: `hooks/_lib/distill.sh`

- [x] **Step 1: Replace the sed promotion line with awk**

In the `distill_check()` function, find:

```bash
    sed -i "s/| active |.*${kw}/\0 [promoted]/" "$EPISODES"
```

Replace with:

```bash
    awk -v kw="$kw" 'BEGIN{IGNORECASE=1} $0 ~ kw && /\| active \|/ {
      sub(/\| active \|/, "| promoted |")
    } 1' "$EPISODES" > "${EPISODES}.tmp" && mv "${EPISODES}.tmp" "$EPISODES"
```

- [x] **Step 2: Verify**

Run: `grep -n 'sed.*promoted' hooks/_lib/distill.sh`
Expected: zero matches (sed line gone).

Run: `grep -n 'awk.*promoted' hooks/_lib/distill.sh`
Expected: one match showing the new awk command.

---

### Task 5: Sync post-implementation trigger list (CRITICAL-05)

**File:**
- Modify: `skills/post-implementation/SKILL.md`

- [x] **Step 1: Update the trigger line**

Find:

```
Fires automatically after any implementation subagent (dev-python, dev-typescript, dev-shell, dev-refactor) returns DONE or DONE_WITH_CONCERNS.
```

Replace with:

```
Fires automatically after any implementation subagent (dev-python, dev-typescript, dev-shell, dev-refactor, dev-kiro-config, dev-frontend) returns DONE or DONE_WITH_CONCERNS.
```

- [x] **Step 2: Verify**

Run: `grep 'dev-frontend' skills/post-implementation/SKILL.md`
Expected: one match in the trigger line.

Run: `grep 'dev-kiro-config' skills/post-implementation/SKILL.md`
Expected: one match in the trigger line.

Cross-check against orchestrator prompt:
Run: `grep 'dev-python.*dev-shell.*dev-refactor.*dev-kiro-config.*dev-typescript.*dev-frontend' agents/prompts/orchestrator.md`
Expected: one match — confirming the lists are now identical.

---

### Task 6: (Combined into Task 2, Step 3)

The orchestrator `rm` deny patterns are added as part of Task 2 to avoid
touching `dev-orchestrator.json` in two separate tasks.

---

### Task 7: Add security hooks to subagent configs (CRITICAL-02)

**Prerequisite:** Tasks 1-2 must be complete (they modify the same JSON files).

**Files:**
- Modify: `agents/dev-python.json`
- Modify: `agents/dev-shell.json`
- Modify: `agents/dev-frontend.json`
- Modify: `agents/dev-typescript.json`
- Modify: `agents/dev-refactor.json`
- Modify: `agents/dev-docs.json`
- Modify: `agents/dev-reviewer.json`
- Modify: `.kiro/agents/dev-kiro-config.json`

- [x] **Step 1: Add full preToolUse hooks to 6 agents with write + shell**

Add the following `hooks` block to each of these 6 agent JSONs. Place it
after the `"resources"` array and before `"includeMcpJson"`:

Agents: `dev-python.json`, `dev-shell.json`, `dev-frontend.json`,
`dev-typescript.json`, `dev-refactor.json`, `dev-docs.json`

```json
  "hooks": {
    "preToolUse": [
      {
        "matcher": "fs_write",
        "command": "bash ~/.kiro/hooks/scan-secrets.sh",
        "timeout_ms": 5000
      },
      {
        "matcher": "fs_write",
        "command": "bash ~/.kiro/hooks/protect-sensitive.sh",
        "timeout_ms": 3000,
        "cache_ttl_seconds": 60
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
```

For each file, the insertion point is:

oldStr:
```
  "includeMcpJson": false
```
newStr:
```
  "hooks": {
    "preToolUse": [
      {
        "matcher": "fs_write",
        "command": "bash ~/.kiro/hooks/scan-secrets.sh",
        "timeout_ms": 5000
      },
      {
        "matcher": "fs_write",
        "command": "bash ~/.kiro/hooks/protect-sensitive.sh",
        "timeout_ms": 3000,
        "cache_ttl_seconds": 60
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
```

- [x] **Step 2: Add bash-only hooks to dev-reviewer.json**

`dev-reviewer` has no `write` tool — only `read`, `shell`, `code`. Add
only the `execute_bash` hooks. Since dev-reviewer has no `"includeMcpJson"`
line, add the hooks block after the `"resources"` array closing bracket:

oldStr:
```
  ],
  "includeMcpJson": false
```
(the `]` closing the resources array)

newStr:
```
  ],
  "hooks": {
    "preToolUse": [
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
```

- [x] **Step 3: Add full hooks to dev-kiro-config.json**

`.kiro/agents/dev-kiro-config.json` has write + shell. Same insertion
pattern as other subagents — add hooks before `"includeMcpJson"`:

oldStr:
```
  "includeMcpJson": false
}
```

newStr:
```
  "hooks": {
    "preToolUse": [
      {
        "matcher": "fs_write",
        "command": "bash ~/.kiro/hooks/scan-secrets.sh",
        "timeout_ms": 5000
      },
      {
        "matcher": "fs_write",
        "command": "bash ~/.kiro/hooks/protect-sensitive.sh",
        "timeout_ms": 3000,
        "cache_ttl_seconds": 60
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

- [x] **Step 4: Verify all agents have hooks**

Run: `for f in agents/dev-*.json .kiro/agents/dev-*.json; do echo "=== $f ==="; jq 'has("hooks")' "$f"; done`

Expected: every agent shows `true`.

Run: `jq '.hooks.preToolUse | length' agents/dev-reviewer.json`
Expected: `2` (bash hooks only).

Run: `jq '.hooks.preToolUse | length' agents/dev-python.json`
Expected: `4` (all hooks).

- [x] **Step 5: Validate JSON syntax**

Run: `for f in agents/*.json .kiro/agents/*.json; do jq empty "$f" && echo "$f OK" || echo "$f BROKEN"; done`

Expected: all files show OK. Zero BROKEN.
