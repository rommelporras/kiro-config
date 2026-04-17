# Phase 1: Safety Fixes from Workflow Audit

**Date:** 2026-04-17
**Source:** `docs/specs/audit-current-workflow.md` (Round 3 final)
**Scope:** CRITICAL-02, CRITICAL-08, HIGH-10, HIGH-15, HIGH-16, CRITICAL-05, MEDIUM-11

---

## Goal

Fix all confirmed safety and correctness bugs in agent configs and hooks.
After this phase, deny-list patterns actually match dangerous commands,
subagents have content-scanning hooks, regex injection is eliminated,
the knowledge pipeline doesn't corrupt data, and the post-implementation
trigger list matches reality.

---

## Group A: Mechanical Fixes (parallel-safe, no design decisions)

These are exact find-and-replace or targeted edits with no ambiguity.

### A1: Fix `dd` deny-list typo — CRITICAL-08

**Problem:** `"dd if/dev"` (missing `=`) in 8 agent JSONs. With `\A`/`\z`
anchoring, this matches only the literal string `dd if/dev` — never the
real command `dd if=/dev/zero`. `base.json` already has the correct pattern.

**Files to change (8):**
- `agents/dev-orchestrator.json`
- `agents/dev-python.json`
- `agents/dev-shell.json`
- `agents/dev-frontend.json`
- `agents/dev-typescript.json`
- `agents/dev-refactor.json`
- `agents/dev-reviewer.json`
- `.kiro/agents/dev-kiro-config.json`

**Change:** In each file's `deniedCommands` array:
```
"dd if/dev"  →  "dd if=/dev.*"
```

The `.*` suffix is required because `\A`/`\z` anchoring means the pattern
must match the entire command string, not just a prefix.

**Note:** `dev-kiro-config.json` doesn't currently have `dd` in its deny
list at all. Add `"dd if=/dev.*"` to its `deniedCommands`.

**Note:** `dev-docs.json` also doesn't have `dd` in its deny list (it uses
broader tool-blocking patterns instead). Add `"dd if=/dev.*"` there too.

**Verification:** `grep -r '"dd if' agents/ .kiro/agents/` — every match
should show `dd if=/dev.*`.

---

### A2: Fix `rm` regex false positives — HIGH-10

**Problem:** `"rm -f.*r.*"` matches any `rm -f` command where the filename
contains `r` (e.g., `rm -f report.txt`). With `\A`/`\z` anchoring, the
full command must match, so `rm -f report.txt` matches because `report.txt`
satisfies `.*r.*`.

**Files to change (7):** All agents that have this pattern:
- `agents/dev-python.json`
- `agents/dev-shell.json`
- `agents/dev-frontend.json`
- `agents/dev-typescript.json`
- `agents/dev-refactor.json`
- `agents/dev-docs.json`
- `agents/base.json`

**Not affected:** `dev-orchestrator.json` (has no `rm` deny patterns),
`dev-reviewer.json` (uses `"rm .*"` which blocks all rm),
`.kiro/agents/dev-kiro-config.json` (uses `"rm .*"` which blocks all rm).

**Change:** Replace the single pattern:
```
"rm -f.*r.*"
```
with two precise patterns:
```
"rm -[a-zA-Z]*r[a-zA-Z]* .*"
"rm --force --recursive.*"
```

The first pattern matches `rm -fr`, `rm -fR`, `rm -rf`, `rm -rfi`, etc. —
any flag combination containing `r`. The space before `.*` ensures we're
matching flags, not filenames. The second catches the long-form variant.

**Verification:** The pattern `rm -f report.txt` should NOT match (no `r`
in the flags portion). The pattern `rm -fr /tmp/stuff` SHOULD match.

---

### A3: Fix regex injection in context-enrichment.sh — HIGH-15

**Problem:** Keywords from `knowledge/rules.md` are interpolated directly
into `grep -qiP "\b${kw}\b"` without escaping. Keywords like `sys.exit`
contain `.` (matches any char in PCRE).

**File:** `hooks/feedback/context-enrichment.sh`

**Change:** Before the grep, escape PCRE metacharacters in `$kw`:

```bash
# Current (line ~51 area, inside the for loop):
if echo "$PROMPT" | grep -qiP "\b${kw}\b"; then

# Replace with:
escaped_kw=$(printf '%s' "$kw" | sed 's/[.[\*^$()+?{|\\]/\\&/g')
if echo "$PROMPT" | grep -qiP "\b${escaped_kw}\b"; then
```

**Verification:** The keyword `sys.exit` should match `sys.exit` but NOT
`sys_exit` or `sysAexit`.

---

### A4: Fix distill.sh sed corruption — HIGH-16

**Problem:** `sed -i "s/| active |.*${kw}/\0 [promoted]/"` inserts
`[promoted]` mid-line at the keyword match position, corrupting the
pipe-delimited format. Also, `$kw` is unescaped in the sed regex.

**File:** `hooks/_lib/distill.sh`

**Change:** Replace the sed line (inside the `for kw` loop in
`distill_check()`) with awk that properly changes the status field:

```bash
# Current:
sed -i "s/| active |.*${kw}/\0 [promoted]/" "$EPISODES"

# Replace with:
awk -v kw="$kw" 'BEGIN{IGNORECASE=1} $0 ~ kw && /\| active \|/ {
  sub(/\| active \|/, "| promoted |")
} 1' "$EPISODES" > "${EPISODES}.tmp" && mv "${EPISODES}.tmp" "$EPISODES"
```

This changes the status from `active` to `promoted` (clean field value)
instead of appending `[promoted]` mid-line. The awk approach also avoids
the regex metacharacter problem since awk's `~` operator handles the
keyword as a regex but `kw` values from the episode file are simple
technology words (jq, sed, git, etc.) without metacharacters.

**Verification:** After promotion, episode lines should have
`| promoted |` in the status field with no `[promoted]` text anywhere.
The pipe-delimited format should remain intact (4 fields separated by `|`).

---

### A5: Sync post-implementation trigger list — CRITICAL-05

**Problem:** The skill says it fires after "dev-python, dev-typescript,
dev-shell, dev-refactor". The orchestrator prompt says it fires after
"dev-python, dev-shell, dev-refactor, dev-kiro-config, dev-typescript,
dev-frontend". Missing from skill: `dev-kiro-config`, `dev-frontend`.

**File:** `skills/post-implementation/SKILL.md`

**Change:** Line 8 (the trigger line), replace:
```
Fires automatically after any implementation subagent (dev-python, dev-typescript, dev-shell, dev-refactor) returns DONE or DONE_WITH_CONCERNS.
```
with:
```
Fires automatically after any implementation subagent (dev-python, dev-typescript, dev-shell, dev-refactor, dev-kiro-config, dev-frontend) returns DONE or DONE_WITH_CONCERNS.
```

This matches the orchestrator prompt exactly. `dev-docs` is intentionally
excluded — pure doc edits don't need the full quality gate.

**Verification:** Diff the trigger list in the skill against the
orchestrator prompt (line 8-9 of `agents/prompts/orchestrator.md`). They
must be identical.

---

### A6: Add `rm` deny patterns to orchestrator — MEDIUM-11

**Problem:** The orchestrator has no `rm` patterns in `deniedCommands`.
It relies entirely on `bash-write-protect.sh` for rm safety — single
layer of defense.

**File:** `agents/dev-orchestrator.json`

**Change:** Add to the `deniedCommands` array:
```json
"rm -[a-zA-Z]*r[a-zA-Z]* .*",
"rm --recursive.*"
```

Single-file `rm` stays allowed — the orchestrator handles file deletions
directly per the routing table.

**Verification:** `jq '.toolsSettings.execute_bash.deniedCommands | map(select(startswith("rm")))' agents/dev-orchestrator.json` should show the two new patterns.

---

## Group B: Design Decisions Required (need approval before implementation)

### B1: Add security hooks to subagent configs — CRITICAL-02

**Problem:** Zero subagents have preToolUse hooks. No secret scanning,
no write protection, no sed-on-JSON blocking on any subagent.

**Platform constraint (from Kiro CLI docs):** Hooks are per-agent. No
inheritance. Each subagent JSON must define its own hooks explicitly.

**Design question: Which hooks on which agents?**

#### Option 1: Full hook parity (recommended)

Add all 4 preToolUse hooks to every subagent that has `write` or `shell`
in its tools:

| Agent | Has `write`? | Has `shell`? | Hooks to add |
|---|---|---|---|
| dev-python | ✅ | ✅ | scan-secrets, protect-sensitive, bash-write-protect, block-sed-json |
| dev-shell | ✅ | ✅ | scan-secrets, protect-sensitive, bash-write-protect, block-sed-json |
| dev-typescript | ✅ | ✅ | scan-secrets, protect-sensitive, bash-write-protect, block-sed-json |
| dev-frontend | ✅ | ✅ | scan-secrets, protect-sensitive, bash-write-protect, block-sed-json |
| dev-refactor | ✅ | ✅ | scan-secrets, protect-sensitive, bash-write-protect, block-sed-json |
| dev-docs | ✅ | ✅ | scan-secrets, protect-sensitive, bash-write-protect, block-sed-json |
| dev-kiro-config | ✅ | ✅ | scan-secrets, protect-sensitive, bash-write-protect, block-sed-json |
| dev-reviewer | ❌ | ✅ | bash-write-protect, block-sed-json (no write tool → no fs_write hooks) |

The hook block to add to each agent JSON:

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
}
```

**Exception: dev-reviewer** — has no `write` tool, so skip the two
`fs_write` hooks. Only add the two `execute_bash` hooks:

```json
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
}
```

#### Option 2: Minimal — scan-secrets only

Add only `scan-secrets.sh` (fs_write matcher) to agents with write access.
Skip bash hooks. Rationale: the deny lists already cover shell commands;
the biggest gap is content scanning on file writes.

**Pros:** Smaller change, less hook overhead per tool call.
**Cons:** Leaves bash-write-protect gap on subagents. A subagent could
still write a script with `dd if=/dev/zero` and execute it (the deny list
catches `dd` directly, but not via script execution).

#### Option 3: Hooks + userPromptSubmit hooks too

Add preToolUse hooks (as in Option 1) PLUS the feedback hooks
(context-enrichment, correction-detect) to subagents.

**Not recommended:** Subagents don't interact with the user directly.
The orchestrator mediates all communication. Feedback hooks on subagents
would fire on the orchestrator's delegation briefing, not on user
corrections. This would generate false-positive corrections.

**My recommendation: Option 1.** Full preToolUse parity. The overhead
is negligible (hooks run in <5s, cached for 60s on protect-sensitive).
The security benefit is significant — every write and shell command on
every agent gets content-scanned.

---

## File Change Summary

### Group A (mechanical, parallel-safe):

| Task | Files Modified | Type |
|---|---|---|
| A1: dd typo | 8 agent JSONs + 2 additions | find-replace |
| A2: rm regex | 7 agent JSONs + base.json | find-replace |
| A3: regex escape | 1 hook script | 2-line edit |
| A4: distill.sh | 1 hook script | replace sed with awk |
| A5: trigger list | 1 skill file | 1-line edit |
| A6: orchestrator rm | 1 agent JSON | add 2 entries |

### Group B (after approval):

| Task | Files Modified | Type |
|---|---|---|
| B1: subagent hooks | 8 agent JSONs | add hooks block |

---

## Verification Criteria

After all changes:

1. `grep -r '"dd if' agents/ .kiro/agents/` → every match shows `dd if=/dev.*`
2. `grep -r 'rm -f.*r' agents/ base.json` → no matches for old pattern
3. `grep 'escaped_kw' hooks/feedback/context-enrichment.sh` → escaping present
4. `grep 'promoted' hooks/_lib/distill.sh` → uses awk, not sed
5. `grep 'dev-frontend' skills/post-implementation/SKILL.md` → present in trigger list
6. `grep 'dev-kiro-config' skills/post-implementation/SKILL.md` → present in trigger list
7. `jq '.toolsSettings.execute_bash.deniedCommands' agents/dev-orchestrator.json | grep 'rm '` → shows rm patterns
8. For B1: `jq '.hooks' agents/dev-python.json` → shows preToolUse hooks
9. For B1: `jq '.hooks' agents/dev-reviewer.json` → shows only execute_bash hooks (no fs_write)
