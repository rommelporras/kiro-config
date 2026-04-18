# Test Brief — Verify Spec Unknowns #2 and #3

**Audience:** Kiro (via `devops-orchestrator` or equivalent), executing in the kiro-config repo.
**Related spec:** `docs/specs/2026-04-18-devops-terraform-and-rename/spec.md` (v3).
**Why this exists:** Spec v3 has two unverified assumptions about Kiro internals. The outcome of each test determines a concrete spec change. Do NOT proceed to Phase 2 planning until both tests are resolved.

---

## Workflow

The user will restart Kiro between **Part A** and **Part B** so the new scratch agent and KB entry are picked up. Don't try to run the tests in the same session you use to create the setup — they won't be live yet.

- **Part A (current session):** create files, no agent switching needed. Report "Part A complete" and wait for the user to restart.
- **Part B (new session after restart):** execute the commands in Test 1 and Test 2, record observations, report results.

---

## Part A — Setup (do this NOW, in the current session)

### A.1 Create the scratch agent

Write `~/.kiro/agents/scratch-precedence.json`:

```json
{
  "name": "scratch-precedence",
  "description": "Throwaway agent for testing allow/deny regex precedence. Safe to delete after use.",
  "prompt": null,
  "model": "claude-sonnet-4.6",
  "tools": ["read", "shell"],
  "allowedTools": ["read", "shell"],
  "toolsSettings": {
    "execute_bash": {
      "autoAllowReadonly": true,
      "allowedCommands": [
        "touch \\.testmark-allowed\\.txt",
        "terraform init$"
      ],
      "deniedCommands": [
        "touch .*",
        "terraform init -upgrade.*"
      ]
    }
  },
  "includeMcpJson": false
}
```

### A.2 Create the tilde-expansion probe

```bash
mkdir -p ~/kiro-tilde-test
echo "tilde-probe-marker-xyz123" > ~/kiro-tilde-test/probe.md
```

### A.3 Add a temporary KB entry to the orchestrator

Edit `agents/dev-orchestrator.json` — append this entry to the `resources` array (keep the existing `kiro-config` KB entry intact):

```json
{
  "type": "knowledgeBase",
  "source": "file://~/kiro-tilde-test",
  "name": "tilde-test",
  "description": "Throwaway KB for tilde-expansion verification. Remove after test.",
  "indexType": "best",
  "autoUpdate": false
}
```

### A.4 Create a scratch working directory for Test 1

```bash
mkdir -p /tmp/precedence-test
```

### A.5 Report completion

Stop here. Respond: "Part A complete. Files created: `~/.kiro/agents/scratch-precedence.json`, `~/kiro-tilde-test/probe.md`, added tilde-test KB to `agents/dev-orchestrator.json`. Ready for restart."

Wait for the user to restart Kiro before proceeding.

---

## Part B — Run tests (do this in a NEW session after restart)

### Test 1 — Allow-vs-deny regex precedence

#### Procedure

1. Switch to the `scratch-precedence` agent (via Kiro's agent selector).
2. `cd /tmp/precedence-test`
3. Ask the agent to run each of the following commands. For each, record the observable Kiro behavior — one of: `allowed silently`, `prompted for approval`, or `blocked with message "<exact message>"`.

| # | Command | What it tests | Sanity expectation |
|---|---------|---------------|-------------------|
| 1a | `touch .testmark-allowed.txt` | **Key question:** narrow allow + broad deny when both patterns match | — (this is the answer we need) |
| 1b | `touch random.txt` | Broad deny with no allow match | Blocked |
| 1c | `terraform init` | Allow with `$` anchor, no deny overlap | Allowed |
| 1d | `terraform init -upgrade` | Deny match, no allow match | Blocked |

Only **1a** drives the decision. 1b/1c/1d are sanity controls; if any disagrees with the expectation, surface it.

### Test 2 — Tilde expansion in KB `file://` source

#### Procedure

1. Switch back to `devops-orchestrator` (or the renamed orchestrator post-Phase 1).
2. Check whether `tilde-test` appears as an indexed knowledge base. Ways to check:
   - Run `/context show` in Kiro (if available) and look for `tilde-test` with non-zero chunks.
   - Or: ask the agent "List indexed knowledge bases" and look for `tilde-test`.
3. Query the KB: ask the agent "Search the `tilde-test` knowledge base for the string `tilde-probe-marker-xyz123`. What do you find?"
4. Record two things:
   - **Indexed?** yes/no (+ chunk count if available)
   - **Search result:** the probe string returned, or no results, or an error

---

## Decision Criteria — What Spec Changes Follow

### Test 1 result → spec change

| 1a outcome | Interpretation | v4 spec change |
|-----------|---------------|----------------|
| **Allowed** | Narrow allow beats broad deny when both match | Keep v3 JSON config as-is. Update Unknown #3 row to: "**Verified: allow-wins-when-both-match.** Narrow allow + broad deny is a supported pattern in Kiro." The `terraform init$` anchor alone handles the `-upgrade` case; no contingency needed. |
| **Blocked** | Deny beats allow when both match | Apply all of: (1) Remove line 92 `"touch \\.terraform/\\.preflight-confirmed-.*"` from `allowedCommands`. (2) Create `scripts/mark-preflight.sh` containing: `#!/usr/bin/env bash`, `set -euo pipefail`, `WS="default"`, `[[ -f .terraform/environment ]] && WS=$(cat .terraform/environment)`, `touch ".terraform/.preflight-confirmed-${WS}"`. (3) Add `"bash .*/mark-preflight\\.sh$"` to `allowedCommands`. (4) Keep `"touch .*"` in `deniedCommands`. (5) Update Preflight Gate section (lines 231–315) to tell the agent to run `bash ~/.kiro/scripts/mark-preflight.sh` instead of `touch`. (6) Update hook draft block message (lines 289–295) to suggest the helper script. (7) Add `scripts/mark-preflight.sh` to Phase 2 deliverables. |
| **Prompted** | Kiro asks the user when patterns overlap | Same fix as "Blocked" — user-prompting breaks the automated preflight flow. Additionally: add a note to `docs/reference/security-model.md` documenting that allow+deny overlaps prompt rather than resolve deterministically. |

### Test 2 result → spec change

| Outcome | Interpretation | v4 spec change |
|---------|---------------|----------------|
| **KB indexed AND search returns `tilde-probe-marker-xyz123`** | Tilde expands correctly in `file://~/...` | Keep v3 Knowledge Base section as-is. Replace Unknown #2 row with: "**Verified: `~` expands in KB `file://` source.**" Remove the "if broken, personalize.sh must expand" caveat from the Personalization note. |
| **KB not indexed, OR indexed but search returns nothing, OR error** | Tilde is literal / path resolution fails | Update `scripts/personalize.sh` to expand `~` to `$HOME` before writing the `eam-terraform` KB entry. Add this snippet to the spec: `expanded_path="${terraform_repo/#\\~/$HOME}"` then inject `expanded_path` into the orchestrator JSON resources. Change the Personalization note (lines 447–449) from "Add a terraform repo path prompt" to "MUST expand `~` to `$HOME` before writing — Kiro does not expand tilde in `file://` URIs." |

---

## Cleanup (after Part B completes)

```bash
rm ~/.kiro/agents/scratch-precedence.json
rm -rf /tmp/precedence-test
rm -rf ~/kiro-tilde-test
```

Revert `agents/dev-orchestrator.json` — remove the `tilde-test` KB entry added in A.3.

---

## Report format

When Part B is complete, reply with exactly this shape (keeps results parseable for the next step):

```
## Test 1 results
1a: <allowed silently | prompted | blocked — "<exact message>">
1b: <same format>
1c: <same format>
1d: <same format>

## Test 2 results
Indexed: <yes — N chunks | no | error: <message>>
Search result: <probe string found in probe.md | no results | error: <message>>

## Spec change to apply
<name the column from each decision matrix above — e.g., "Test 1: Blocked column applies. Test 2: Verified column applies.">
```

With those results posted, the spec goes to v4 and then to `plan.md`.

> Note: as of v0.7.0, dev-* agents were renamed to devops-*. See docs/specs/2026-04-18-devops-terraform-and-rename/spec.md.
