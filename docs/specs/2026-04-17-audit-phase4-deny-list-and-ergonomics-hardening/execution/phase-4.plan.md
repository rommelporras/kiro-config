# Phase 4 Execution Plan

> Generated from: `docs/specs/2026-04-17-audit-phase4-deny-list-and-ergonomics-hardening/spec.md`
> Plan:  `docs/specs/2026-04-17-audit-phase4-deny-list-and-ergonomics-hardening/plan.md`
> Date: 2026-04-17

## Goal

Close six deferred audit findings via five commits on `feature/audit-phase4-deny-list-and-ergonomics-hardening`.
Group A tasks (mechanical, parallel-safe) dispatched in Stage 1. Group B
task (design decision) dispatched in Stage 2 after Kiro approves
B1 Option 1 (or Option 2). Docs finalization in Stage 3.

---

## Stage 1 (parallel) — Group A mechanical fixes

Three independent delegates. File lists are disjoint except for
`agents/dev-orchestrator.json` (Task 1.3 and Task 1.4 serialize into a
single delegate).

**Independence proof:**
- Task 1.1: `hooks/protect-sensitive.sh`, `scripts/test-hooks.sh`
- Task 1.2: `hooks/feedback/correction-detect.sh`, `hooks/feedback/context-enrichment.sh`, `hooks/feedback/auto-capture.sh`
- Task 1.3+1.4: `agents/dev-orchestrator.json` (single file, two logical changes — one delegate)
- Task 1.5: `agents/prompts/orchestrator.md`

Zero file overlap between delegates.

### Task 1.1: Extend `protect-sensitive.sh` + tests (Spec A1 / LOW-06)

- **Agent:** dev-kiro-config
- **Objective:** Add 5 credential patterns to PROTECTED array and 6 corresponding test cases.
- **Files:**
  - Modify: `hooks/protect-sensitive.sh` — insert 5 entries after `"id_ecdsa"` (line 38)
  - Modify: `scripts/test-hooks.sh` — append 6 test cases under the `=== protect-sensitive.sh ===` block
- **Briefing context:**
  - `docs/specs/2026-04-17-audit-phase4-deny-list-and-ergonomics-hardening/spec.md` §A1 (exact insert blocks)
- **Constraints:**
  - Do NOT reorder existing PROTECTED entries.
  - Do NOT modify the safe-suffix allowlist at line 22.
  - Run `bash scripts/test-hooks.sh` after the change — it must exit 0 with PASS=39, FAIL=0 (was 33).
- **Done when:**
  - `grep -c '"id_dsa"\|".p12"\|".pfx"\|"kubeconfig"\|".tfstate"' hooks/protect-sensitive.sh` → 5
  - `grep -c 'id_dsa blocked\|cert.p12 blocked\|cert.pfx blocked\|kubeconfig blocked\|tfstate blocked\|tfstate.example passes' scripts/test-hooks.sh` → 6
  - `bash scripts/test-hooks.sh` exits 0
  - `bash -n hooks/protect-sensitive.sh scripts/test-hooks.sh` — no syntax errors
- **Skill triggers:** "verify before completing"

### Task 1.2: Namespace `/tmp/kb-*` flags (Spec A2 / MEDIUM-12)

- **Agent:** dev-kiro-config
- **Objective:** Replace bare `/tmp/kb-*` paths with `/tmp/kb-${USER}-*` across 3 hook scripts.
- **Files:**
  - Modify: `hooks/feedback/correction-detect.sh` (line 32)
  - Modify: `hooks/feedback/context-enrichment.sh` (lines 17, 28, 32)
  - Modify: `hooks/feedback/auto-capture.sh` (line 44)
- **Briefing context:**
  - `docs/specs/2026-04-17-audit-phase4-deny-list-and-ergonomics-hardening/spec.md` §A2 (5 exact diffs)
- **Constraints:**
  - All 3 files must land in the same commit. `auto-capture.sh` writes
    the flag consumed by `context-enrichment.sh`; name mismatch between
    producer and consumer would silently break the enrichment pipeline.
  - Do NOT introduce a shared helper / sourced lib. KISS — inline
    `${USER}` in each file.
  - Quote the paths: `"/tmp/kb-${USER}-..."` — unquoted would break on
    unset USER.
- **Done when:**
  - `grep -rnE '/tmp/kb-[a-z]' hooks/feedback/ | grep -v '\$\{USER\}\|\$USER'` → no output
  - `grep -c '\${USER}' hooks/feedback/correction-detect.sh` → 1
  - `grep -c '\${USER}' hooks/feedback/context-enrichment.sh` → 3
  - `grep -c '\${USER}' hooks/feedback/auto-capture.sh` → 1
  - `bash -n hooks/feedback/*.sh` — no syntax errors
- **Skill triggers:** "verify before completing"

### Task 1.3 + 1.4: Orchestrator deny-list + git add allow (Spec A3+A4 / MEDIUM-08, LOW-01)

- **Agent:** dev-kiro-config
- **Objective:** Add 4 `aws s3` mutation deny patterns AND replace `git add .*` allow with `git add [^-.].*` — single commit, single file.
- **Files:**
  - Modify: `agents/dev-orchestrator.json` (two logical changes, one file)
- **Briefing context:**
  - `docs/specs/2026-04-17-audit-phase4-deny-list-and-ergonomics-hardening/spec.md` §A3, §A4
- **Constraints:**
  - Do NOT modify any other entry in `deniedCommands` or `allowedCommands`.
  - Preserve JSON formatting — `jq empty agents/dev-orchestrator.json` must still succeed.
  - A3 insert goes AFTER `"aws .* untag-.*"` (line 133 pre-edit).
  - A4 REPLACES the exact string `"git add .*",` at line 77 with TWO lines:
    ```
        "git add [^-.].*",
        "git add -- .*",
    ```
    (Round 2 revision — Kiro confirmed the single-pattern version broke both
    documented dotfile workarounds.)
- **Done when:**
  - `jq '.toolsSettings.execute_bash.deniedCommands | map(select(startswith("aws s3")))' agents/dev-orchestrator.json | jq 'length'` → 4
  - `jq '.toolsSettings.execute_bash.allowedCommands | map(select(test("^git add")))' agents/dev-orchestrator.json | jq 'length'` → 2
  - `jq '.toolsSettings.execute_bash.allowedCommands | any(. == "git add [^-.].*")' agents/dev-orchestrator.json` → true
  - `jq '.toolsSettings.execute_bash.allowedCommands | any(. == "git add -- .*")' agents/dev-orchestrator.json` → true
  - `jq empty agents/dev-orchestrator.json` — no error
- **Skill triggers:** "verify before completing"

### Task 1.5: Orchestrator prompt — subagent timeout section (Spec A5 / HIGH-11)

- **Agent:** dev-docs
- **Objective:** Insert "Subagent timeout and recovery" subsection after the existing `### Retry limit` block in the orchestrator prompt.
- **Files:**
  - Modify: `agents/prompts/orchestrator.md`
- **Briefing context:**
  - `docs/specs/2026-04-17-audit-phase4-deny-list-and-ergonomics-hardening/spec.md` §A5 (exact markdown block)
- **Constraints:**
  - Do NOT renumber or restructure any other sections.
  - Insert position: immediately after the `### Retry limit` block, before `## Delegation Format` heading.
  - Preserve the surrounding heading hierarchy (`###` under `## Workflow Definitions`).
- **Done when:**
  - `grep -c '### Subagent timeout and recovery' agents/prompts/orchestrator.md` → 1
  - `grep -c 'stuck-without-erroring' agents/prompts/orchestrator.md` → 1
  - File renders cleanly (no broken markdown — eyeball check for adjacent headings)
- **Skill triggers:** "verify before completing"

---

## Stage 2 — Group B design decision (Round 2 revised, ungated)

Round 1 of this plan gated Stage 2 on Kiro's choice between Option 1
(enumerative) and Option 2 (broad). Kiro's Round 2 counter-audit
rejected both and proposed a hybrid (blanket deny + explicit
`allowedCommands`). Stage 2 is now unblocked and implements the hybrid.

### Task 2.1: Loosen dev-docs — hybrid deny + allow (Spec B1 / HIGH-05 + MEDIUM-03)

- **Agent:** dev-kiro-config
- **Objective:** In `agents/dev-docs.json`: (1) remove `python3? .*` and `node .*` from `deniedCommands`, (2) insert new `allowedCommands` array with 27 read-only subcommand patterns, (3) add `shell` to `allowedTools`.
- **Files:**
  - Modify: `agents/dev-docs.json`
- **Briefing context:**
  - `docs/specs/2026-04-17-audit-phase4-deny-list-and-ergonomics-hardening/spec.md` §B1 (final approach after Round 2)
  - `docs/specs/2026-04-17-audit-phase4-deny-list-and-ergonomics-hardening/plan.md` Task 5 (exact JSON blocks)
- **Constraints:**
  - Do NOT modify any `deniedCommands` entry OTHER than removing the two named interpreter patterns.
  - Blanket denies `npm .*`, `uv .*`, `pip .*`, `terraform .*`, `helm .*`, `kubectl .*`, `docker .*`, `aws .*` MUST REMAIN.
  - `allowedCommands` array goes inside `toolsSettings.execute_bash`, directly after the `autoAllowReadonly: true` line.
  - `allowedTools` order preserved; `shell` appended last, after `code`.
  - Preserve JSON formatting and 2-space indentation — match existing file.
- **Done when:**
  - `jq '.toolsSettings.execute_bash.deniedCommands | length' agents/dev-docs.json` → 17
  - `jq '.toolsSettings.execute_bash.deniedCommands | any(. == "python3? .*")' agents/dev-docs.json` → false
  - `jq '.toolsSettings.execute_bash.deniedCommands | any(. == "node .*")' agents/dev-docs.json` → false
  - `jq '.toolsSettings.execute_bash.deniedCommands | any(. == "npm .*")' agents/dev-docs.json` → true
  - `jq '.toolsSettings.execute_bash.allowedCommands | length' agents/dev-docs.json` → 27
  - `jq '.toolsSettings.execute_bash.allowedCommands | any(. == "python3? --version")' agents/dev-docs.json` → true
  - `jq '.toolsSettings.execute_bash.allowedCommands | any(. == "npm audit.*")' agents/dev-docs.json` → true
  - `jq '.allowedTools | any(. == "shell")' agents/dev-docs.json` → true
  - `jq empty agents/dev-docs.json` — no error
- **Runtime verification (orchestrator-driven — also validates allow-wins precedence assumption):**
  - Dispatch dev-docs: "run python3 --version" → succeeds
  - Dispatch dev-docs: "run npm ls" → succeeds
  - Dispatch dev-docs: "run npm audit" → succeeds
  - Dispatch dev-docs: "run pip install foo" → blocked
  - Dispatch dev-docs: "run npm init" → blocked (validates gap coverage — Kiro's specific gap example)
  - Dispatch dev-docs: "run terraform apply" → blocked
- **If allow-wins assumption fails at runtime** (all dispatches blocked despite allow match): fallback is to restore Round 1 Option 1 enumerative deny approach, supplemented with Kiro's 23 additional mutating patterns. Spec §B1 "Rejected alternatives" has the fallback list.
- **Skill triggers:** "verify before completing"

**Round 3 outcome.** Allow-wins assumption failed at runtime. Implemented
enumerative deny fallback. Blanket sub-prefix patterns over-blocked 5
read-only subcommands (Audit Agent counter-audit); fixed in commit 6 with
15 specific mutating-subcommand patterns. Final `deniedCommands` length: 65.

---

## Stage 3 (sequential, after Stages 1 + 2 land) — docs + release

### Task 3.1: CHANGELOG + audit playbook (Plan Task 7)

- **Agent:** dev-docs
- **Objective:** Add v0.6.0 entry to CHANGELOG, extend audit playbook with new invariant S10 and §8 change-log entry, create new triage baseline doc.
- **Files:**
  - Modify: `docs/reference/CHANGELOG.md` — insert v0.6.0 entry above v0.5.1
  - Modify: `docs/reference/audit-playbook.md` — append §8 entry; add S10 to §1.1
  - Create: `docs/specs/audit-triage-v0.6.0.md` — new triage baseline
- **Briefing context:**
  - `docs/specs/2026-04-17-audit-phase4-deny-list-and-ergonomics-hardening/plan.md` Task 7 (exact blocks)
  - Previous triage for structure: `docs/specs/audit-triage-v0.5.1.md`
- **Constraints:**
  - Follow Keep-a-Changelog format exactly. Use `[v0.6.0] - 2026-04-17`.
  - Triage doc must use the same row format as v0.5.1 triage — mark H-05, H-11, M-08, M-12, L-01, L-06 as CLOSED with commit hashes (fill after merge).
  - Do NOT delete the v0.5.1 triage; it remains as historical record.
- **Done when:**
  - `grep -c '## \[v0.6.0\]' docs/reference/CHANGELOG.md` → 1
  - `grep -c 'v0.6.0 backlog remediation' docs/reference/audit-playbook.md` → 1
  - `grep -c 'S10' docs/reference/audit-playbook.md` → 1 (new invariant)
  - New file `docs/specs/audit-triage-v0.6.0.md` exists with ≥ 6 CLOSED rows for the Phase 4 findings
- **Skill triggers:** "verify before completing"

---

## Commit strategy

On branch `feature/audit-phase4-deny-list-and-ergonomics-hardening`:

| # | Commit message | Tasks |
|---|---|---|
| 1 | `fix(hooks): add missing credential types and namespace tmp flags` | 1.1 + 1.2 |
| 2 | `fix(orchestrator): block aws s3 mutations and tighten git add allow` | 1.3 + 1.4 |
| 3 | `feat(dev-docs): allow read-only interpreter and package-manager invocations` | 2.1 (after Kiro approval) |
| 4 | `docs(orchestrator): add subagent timeout and recovery guidance` | 1.5 |
| 5 | `docs(changelog): v0.6.0 entry and playbook update` | 3.1 |

Commits 1, 2, 4 can land without Kiro approval (mechanical). Commit 3
waits for Kiro's B1 option choice. Commit 5 runs last.

PR from `feature/audit-phase4-deny-list-and-ergonomics-hardening` → `main` via `create-pr` skill. Merge, tag
`v0.6.0`, ship via `/ship`.

---

## Pre-commit gates (run before each commit)

- `bash scripts/test-hooks.sh` → exit 0 (invariant S9)
- `for f in agents/*.json .kiro/agents/*.json; do jq empty "$f" || echo BROKEN; done` → no BROKEN
- `for f in hooks/**/*.sh scripts/*.sh; do bash -n "$f" || echo BROKEN; done` → no BROKEN
- `git diff --stat` — only files listed in spec §"File Change Summary" appear

## Post-merge verification

1. Audit playbook §2 quick-check script → zero failures.
2. Runtime: orchestrator dispatches dev-docs with "run python3 --version" → succeeds.
3. `docs/specs/audit-triage-v0.6.0.md` lists 6 newly-CLOSED rows.
4. `git log --oneline main..v0.6.0` → 5 conventional-commit lines matching the table above.

> Note: as of v0.7.0, dev-* agents were renamed to devops-*. See docs/specs/2026-04-18-devops-terraform-and-rename/spec.md.
