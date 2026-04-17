# Phase 4: Deny-list and Ergonomics Hardening

**Date:** 2026-04-17
**Target release:** v0.6.0
**Source:** `docs/specs/audit-triage-v0.5.1.md` §"Recommended v0.6.0 scope"
**Scope:** HIGH-05, HIGH-11, MEDIUM-03 (added Round 2), MEDIUM-08, MEDIUM-12, LOW-01, LOW-06
**Status:** ACK_WITH_CHANGES — Round 2 revision integrated, awaiting user approval.

---

## Goal

Close seven deferred findings from the v0.5.1 audit backlog (six originally
in scope; MEDIUM-03 pulled in during Round 2 because its fix is coupled to
HIGH-05 via the `shell` in `allowedTools` change). Four safety tightenings
(block aws s3 mutations, tighten git add allow, add missing credential file
types, namespace /tmp flag files), one ergonomics loosening (dev-docs
read-only invocations), one user-approval coupling fix (shell in
allowedTools), one documentation addition (orchestrator subagent-timeout
guidance).

After this phase, the audit backlog drops from **3 HIGH + 12 MEDIUM +
6 LOW** to **1 HIGH + 9 MEDIUM + 5 LOW**. No new features, no new
agents, no new skills.

---

## Group A: Mechanical Fixes (parallel-safe, no design decisions)

Exact find-and-replace / targeted edits with no ambiguity.

### A1: Extend `protect-sensitive.sh` PROTECTED array — LOW-06

**Problem:** PROTECTED array at `hooks/protect-sensitive.sh:26-39` misses
five credential file types in active use: legacy SSH (`id_dsa`), PKCS#12
keystores (`*.p12`, `*.pfx`), Kubernetes credentials (`kubeconfig`),
Terraform state (`*.tfstate`).

**Files:**
- `hooks/protect-sensitive.sh` — append 5 entries to PROTECTED array
- `scripts/test-hooks.sh` — add 6 test cases (5 blocks + 1 allowlist-still-works)

**Change in `protect-sensitive.sh`:** Insert after line 38 (`"id_ecdsa"`):
```bash
  "id_dsa"
  ".p12"
  ".pfx"
  "kubeconfig"
  ".tfstate"
```

**Change in `test-hooks.sh`:** Append under `=== protect-sensitive.sh ===`:
```bash
run_test "id_dsa blocked"            "protect-sensitive.sh" "$(fsw_input '.ssh/id_dsa' 'keydata')"                "block"
run_test "cert.p12 blocked"          "protect-sensitive.sh" "$(fsw_input 'certs/cert.p12' 'binarydata')"          "block"
run_test "cert.pfx blocked"          "protect-sensitive.sh" "$(fsw_input 'certs/cert.pfx' 'binarydata')"          "block"
run_test "kubeconfig blocked"        "protect-sensitive.sh" "$(fsw_input '.kube/kubeconfig' 'apiVersion: v1')"    "block"
run_test "tfstate blocked"           "protect-sensitive.sh" "$(fsw_input 'tf/terraform.tfstate' '{}')"            "block"
run_test "tfstate.example passes"    "protect-sensitive.sh" "$(fsw_input 'terraform.tfstate.example' '{}')"      "pass"
```

---

### A2: Namespace `/tmp/kb-*` flag files — MEDIUM-12

**Problem:** Bare `/tmp/kb-*` paths collide across users on shared
machines. `auto-capture.sh` writes a flag consumed by
`context-enrichment.sh`; both must change together.

**Files:**
- `hooks/feedback/correction-detect.sh` — 1 line (line 32)
- `hooks/feedback/context-enrichment.sh` — 3 lines (lines 17, 28, 32)
- `hooks/feedback/auto-capture.sh` — 1 line (line 44)

**Changes:**

`correction-detect.sh:32`:
```diff
-  FLAG="/tmp/kb-correction-$(date +%s).flag"
+  FLAG="/tmp/kb-${USER}-correction-$(date +%s).flag"
```

`context-enrichment.sh:17`:
```diff
-DEDUP_FILE="/tmp/kb-enrich-last"
+DEDUP_FILE="/tmp/kb-${USER}-enrich-last"
```

`context-enrichment.sh:28`:
```diff
-if [[ -f /tmp/kb-changed.flag ]]; then
+if [[ -f "/tmp/kb-${USER}-changed.flag" ]]; then
```

`context-enrichment.sh:32`:
```diff
-  rm -f /tmp/kb-changed.flag
+  rm -f "/tmp/kb-${USER}-changed.flag"
```

`auto-capture.sh:44`:
```diff
-touch /tmp/kb-changed.flag
+touch "/tmp/kb-${USER}-changed.flag"
```

All three files must land in the same commit; `auto-capture.sh` flag name
must match the consumer in `context-enrichment.sh`.

---

### A3: Block `aws s3 cp/mv/rm/sync` in orchestrator — MEDIUM-08

**Problem:** Orchestrator `deniedCommands` uses hyphenated-action patterns
(`aws .* create-.*`, `delete-.*`, …). The verb-form `aws s3 cp/mv/rm/sync`
is not matched. Orchestrator can mutate S3 state without tripping the
deny-list.

**Files:**
- `agents/dev-orchestrator.json` — insert 4 entries into `deniedCommands`

**Change:** Insert after the existing `"aws .* untag-.*",` line (line 133):
```json
      "aws s3 cp.*",
      "aws s3 mv.*",
      "aws s3 rm.*",
      "aws s3 sync.*",
```

`autoAllowReadonly: true` on `use_aws` still permits read-only S3 listing.

---

### A4: Tighten `git add` allow pattern — LOW-01

**Problem:** `agents/dev-orchestrator.json:77` has `"git add .*"`. With
Kiro CLI's `\A\z` anchoring, this matches `git add -A`, `git add .`,
`git add --all` — which can sweep in unrelated dirty files. The commit
skill forbids this in prose only.

**Files:**
- `agents/dev-orchestrator.json:77`

**Change.** Replace the single `"git add .*"` allow with a two-pattern
pair:
```diff
-        "git add .*",
+        "git add [^-.].*",
+        "git add -- .*",
```

**Why two patterns.** The first pattern `git add [^-.].*` requires the
first char after `git add ` to be neither `-` (blocks `-A`, `--all`,
`-p`, `-i`) nor `.` (blocks `.` and `./` dotfile ambiguity). That also
blocks legitimate dotfiles like `.env.example`. The second pattern
`git add -- .*` permits the git disambiguator form for dotfile staging.

**Verified via regex simulation** (Round 2, 2026-04-17):
| Input | `[^-.].*` | `-- .*` | Verdict |
|---|---|---|---|
| `git add src/foo.py` | ✓ | ✗ | allowed |
| `git add -- .env.example` | ✗ | ✓ | allowed |
| `git add -A` | ✗ | ✗ | blocked |
| `git add .` | ✗ | ✗ | blocked |
| `git add --all` | ✗ | ✗ | blocked |
| `git add -p file.txt` | ✗ | ✗ | blocked |

**Canonical workaround for dotfiles.** `git add -- .env.example`. The
earlier-draft suggestion `git add ./.env.example` is WRONG — `./` also
starts with `.` and fails the first pattern. Document only the
disambiguator form.

**Kiro's counter-proposal `[^-].*` rejected.** That relaxation allows
`git add .` (the exact failure mode this finding addresses). Kiro
acknowledged the trap when proposing it.

---

### A5: Add subagent timeout guidance to orchestrator prompt — HIGH-11

**Problem:** No written guidance for what the orchestrator does if a
subagent hangs. Retry limit (max 3) covers fail-loops but not
hang-loops. Current behavior: session blocks until subagent returns or
user aborts.

**Files:**
- `agents/prompts/orchestrator.md` — insert subsection after `### Retry limit`

**Change:** Insert a new subsection:
```markdown
### Subagent timeout and recovery

Subagents have no hard timeout. If a subagent appears stuck:

1. **Symptoms:** no status update for 2+ minutes, repeated similar tool
   calls, or the same file edited 3+ times with no forward progress.
2. **Recovery:** surface to the user immediately with a concrete status:
   "dev-<name> has been working on <task> for <duration> — appears stuck
   on <specific thing>. Abort or wait?"
3. **Never silently wait indefinitely.** If you have to wait, tell the
   user why and for how long.

The retry limit (3) covers correct-then-fail loops. This timeout guidance
covers stuck-without-erroring loops.
```

---

## Group B: Design Decisions Required (need approval before implementation)

### B1: Loosen dev-docs for read-only invocations — HIGH-05 + MEDIUM-03

**Problem:** `dev-docs` is the documentation agent. Writing docs about a
Python package currently can't run `python3 --version`. The current
deny-list at `agents/dev-docs.json:47-56` blocks the entire invocation
space for 10 language/tool prefixes (`python3? .*`, `node .*`, `npm .*`,
`uv .*`, `pip .*`, `terraform .*`, `helm .*`, `kubectl .*`, `docker .*`,
`aws .*`). Separately, `shell` is in `tools` but NOT in `allowedTools`
(MEDIUM-03 from triage), so every shell invocation requires user
approval even when it would otherwise pass the deny list.

**Round 2 revision (Kiro counter-audit).** The Round 1 enumerative
Option 1 had 31+ gaps (`npm init`, `npm ci`, `npm link`, `uv venv`,
`pip wheel`, etc. all passed through). Kiro proposed the correct shape:
**invert the logic — keep blanket `npm|uv|pip` denies, add an
`allowedCommands` section with explicit read-only subcommands.**
Deny-by-default + allow-by-exception scales better and has a bounded,
stable allow list.

#### Final approach (adopted after Kiro review)

**Three coordinated changes to `agents/dev-docs.json`:**

1. **Remove from `deniedCommands`:** `python3? .*` and `node .*`.
   Interpreter-only invocations don't mutate the filesystem on their
   own; any mutation via `-c` code is still caught by
   `scan-secrets.sh` + `protect-sensitive.sh` `fs_write` hooks.
2. **Keep in `deniedCommands`:** `npm .*`, `uv .*`, `pip .*` (blanket),
   plus `terraform|helm|kubectl|docker|aws .*`. Blanket deny catches
   mutating subcommands by default; read-only escapes via explicit
   allow.
3. **Add `allowedCommands` array** with read-only subcommands for
   npm/uv/pip:
   ```json
   "allowedCommands": [
     "python3? --version", "python3? -V",
     "node --version", "node -v",
     "npm audit.*", "npm ls.*", "npm outdated.*", "npm view.*",
     "npm explain.*", "npm fund.*", "npm doctor.*", "npm config list.*",
     "uv tree.*", "uv show.*", "uv version.*", "uv python list.*",
     "uv pip list.*", "uv pip show.*", "uv pip check.*", "uv pip freeze.*",
     "pip show.*", "pip list.*", "pip check.*", "pip freeze.*",
     "pip config list.*", "pip debug.*", "pip cache info.*"
   ]
   ```
4. **Add `shell` to `allowedTools`** so the allowed invocations don't
   trigger user-approval prompts (MEDIUM-03 coverage).

**Assumption to verify at runtime.** Kiro CLI's
`allowedCommands` vs `deniedCommands` precedence when both match:
allow-wins expected (standard semantics). If runtime check reveals
deny-wins, the approach re-scopes to: specify mutating subcommands in
deny list (restoring enumerative) — see §"Round 2 revision" note.

**Rejected alternatives:**

- *Round 1 Option 1 (enumerative deny)* — 31+ gaps per Kiro; high
  maintenance.
- *Round 1 Option 2 (broad deny removal)* — allows `python3 -c` with no
  allowedCommands filter. Acceptable but larger trust surface than
  needed.
- *Status quo* — daily friction; fails the ergonomics goal.

---

## File Change Summary

### Group A (mechanical, parallel-safe):

| File | A1 | A2 | A3 | A4 | A5 |
|---|---|---|---|---|---|
| `hooks/protect-sensitive.sh` | ✓ | | | | |
| `scripts/test-hooks.sh` | ✓ | | | | |
| `hooks/feedback/correction-detect.sh` | | ✓ | | | |
| `hooks/feedback/context-enrichment.sh` | | ✓ | | | |
| `hooks/feedback/auto-capture.sh` | | ✓ | | | |
| `agents/dev-orchestrator.json` | | | ✓ | ✓ | |
| `agents/prompts/orchestrator.md` | | | | | ✓ |

A3 and A4 both touch `agents/dev-orchestrator.json` — serialize or bundle.
All other Group A items are disjoint (parallel-safe).

### Group B (after approval):

| File | B1 |
|---|---|
| `agents/dev-docs.json` | ✓ |

---

## Verification Criteria

Release ships when:

- [ ] `bash scripts/test-hooks.sh` exits 0 (invariant S9).
- [ ] `for f in agents/*.json .kiro/agents/*.json; do jq empty "$f"; done` — no errors (invariant C6).
- [ ] `bash -n hooks/feedback/*.sh hooks/protect-sensitive.sh scripts/test-hooks.sh` — no syntax errors (invariant C7).
- [ ] `grep -rnE '/tmp/kb-[a-z]' hooks/feedback/ | grep -v '\$\{USER\}\|\$USER'` — no matches (A2).
- [ ] `grep -c 'Subagent timeout' agents/prompts/orchestrator.md` ≥ 1 (A5).
- [ ] `jq '.toolsSettings.execute_bash.deniedCommands | map(select(startswith("aws s3")))' agents/dev-orchestrator.json | jq 'length'` → 4 (A3).
- [ ] `jq '.toolsSettings.execute_bash.allowedCommands | map(select(test("^git add")))' agents/dev-orchestrator.json | jq 'length'` → 2 (A4 — both patterns present).
- [ ] `jq '.toolsSettings.execute_bash.deniedCommands | length' agents/dev-docs.json` → 17 (B1 — was 19; removed `python3? .*` and `node .*`).
- [ ] `jq '.toolsSettings.execute_bash.allowedCommands | length' agents/dev-docs.json` → 27 (B1 — new array).
- [ ] `jq '.allowedTools | any(. == "shell")' agents/dev-docs.json` → true (B1 / MEDIUM-03).
- [ ] Runtime check: dispatch dev-docs with "run python3 --version" → succeeds (B1).
- [ ] Runtime check: dispatch dev-docs with "run npm ls" → succeeds (B1; validates allow-wins precedence assumption).
- [ ] Runtime check: dispatch dev-docs with "run pip install foo" → blocked (B1; validates blanket deny still holds).
- [ ] Runtime check: dispatch dev-docs with "run git add -A" → blocked (A4 regression check).
- [ ] Runtime check: dispatch orchestrator with "run git add -- .env.example" → succeeds (A4 disambiguator).
- [ ] CHANGELOG v0.6.0 entry reflects the six closed findings.
- [ ] Audit playbook §8 has new change-log entry; §1.1 extended with S10 (aws s3 deny).
- [ ] New triage baseline `docs/specs/audit-triage-v0.6.0.md` written.

---

## Out of scope

- **MEDIUM-01** (scope steering per-agent). Risk of silent regression
  if an agent was implicitly relying on cross-domain steering.
  Deferred to v0.7.0 with per-agent verification.
- **MEDIUM-14** (create-pr default-branch detection). Adds runtime
  dependency on `gh repo view` succeeding. Needs fallback path for
  offline / unauthenticated cases. Deferred to v0.7.0 or later.
- **All remaining MEDIUM/LOW items** from v0.5.1 triage. No friction
  reported since v0.5.1.
- **117 improvement recommendations** from the original audit. Not a
  patch-release concern.

---

## Open questions (resolved in Round 2)

All six Round 1 open questions were answered by Kiro's counter-audit.
Outcomes captured inline above; full record in §"Round 2 revision"
below.

---

## Round 2 revision (Kiro counter-audit, 2026-04-17)

Kiro returned VERDICT: ACK_WITH_CHANGES with three correctness findings,
two completeness notes, and six explicit Open Question answers.
Reconciled outcomes:

### Accepted (spec updated)

- **A4 workaround docs wrong (HIGH).** Round 1 spec suggested
  `git add ./.env.example` and `git add -- .env.example` as workarounds
  for the `[^-.].*` regex. Independent regex simulation confirmed both
  fail. Fix: keep `git add [^-.].*` AND add second allow `git add -- .*`.
  Canonical workaround is now the disambiguator form. Kiro's alternative
  of relaxing to `[^-].*` was rejected because it lets `git add .` slip
  through (Kiro also noted this trap).
- **B1 count wrong (MEDIUM).** dev-docs deniedCommands is 19 entries,
  not 20. Round 1 Done-when numbers propagated the mistake.
  Verification commands in §"Verification Criteria" corrected to 17
  (post-change deny count, after removing `python3? .*` and `node .*`)
  and 27 (new allow count).
- **B1 enumerative has 31+ gaps (MEDIUM).** Kiro enumerated specific
  missing mutating commands (`npm init`, `npm ci`, `npm link`, `uv venv`,
  `pip wheel`, etc.). Switched to Kiro's proposed hybrid: blanket deny
  (`npm .*`, `uv .*`, `pip .*`) + explicit `allowedCommands` for
  read-only subcommands. Deny-by-default is safer and easier to maintain.
- **MEDIUM-03 (shell not in allowedTools).** Spec expanded to add
  `shell` to dev-docs `allowedTools` as part of B1. Without this, every
  shell command would still require user approval even when the deny
  list allowed it.

### Rejected (with rationale)

- **H-03 bundling rejected.** Kiro labeled H-03 "2 minutes, zero risk"
  and flagged the prompt-naming inconsistency as a missed opportunity.
  Independent check shows the problem is larger than Kiro's estimate:
  6 of 8 prompts are misnamed, AND `dev-kiro-config.json` SHARES
  `agents/prompts/docs.md` with `dev-docs` via
  `file://../../agents/prompts/docs.md`. Renaming requires a design
  decision on whether to split the shared prompt — that's a separate
  phase, not a 2-minute rename. Deferring to a future release stays
  correct.
- **Round 1 Option 2 (broad deny removal) reconsidered, still
  rejected.** Kiro's hybrid approach supersedes both Option 1 and
  Option 2 from Round 1.

### Nits addressed

- A5 insertion point wording already used "after the existing
  `### Retry limit` block" (not a line number) — no change needed. Plan
  originally said "around line 105"; corrected in plan.md.
- Task 7 CHANGELOG draft hardcodes 2026-04-17. If implementation lands
  later, update the date before committing.
- Execution plan Stage 2 gate: Kiro's Q1 answer (adopt hybrid) is now
  recorded; Stage 2 unblocked.

### Kiro's Open Question answers — incorporated

| # | Kiro's answer | Spec resolution |
|---|---|---|
| 1 (B1 option) | Hybrid: blanket deny + read-only allowedCommands | Adopted as final B1 approach |
| 2 (allow-list completeness) | Spec list correct; add `npm pack --dry-run`, `npm explain`, `npm fund`, `npm doctor`, `npm config list`, `uv pip freeze`, `pip config list`, `pip debug`, `pip cache info` | Added to allowedCommands |
| 3 (A3 anchoring) | Confirmed correct | No change |
| 4 (A4 `git add -p` block) | Acceptable | No change; disambiguator form documented for dotfile staging |
| 5 (L-06 kubeconfig) | Out of scope; document as limitation | No change |
| 6 (feature branch) | Agree, feature/audit-phase4-deny-list-and-ergonomics-hardening + PR | No change |

### Recurrent failure pattern scan (Kiro's check, independent)

Kiro ran through audit-playbook §7 patterns. All clean, with one noted
mitigation: §7.12 (parallel-safety) risk on `agents/dev-orchestrator.json`
shared between A3 and A4 — already mitigated by the execution plan
(Task 1.3+1.4 serialized into a single delegate).

---

## Definition of done (post-Round 2)

- All verification criteria in §"Verification Criteria" pass.
- This spec's Round 2 revision block reflects the final state.
- Plan and execution plan updated to match.
- User approval recorded before implementation begins.

## Round 3 revision (runtime verification pivot, 2026-04-17)

Kiro's implementation (commits 1-5) used the enumerative deny approach
from Round 2 fallback. Runtime verification in-session revealed that
Kiro CLI does NOT support allow-wins precedence for `allowedCommands`
vs `autoAllowReadonly` gating:

- **Observation:** `python3 --version` dispatched to dev-docs was blocked
  despite `python3? .*` being removed from `deniedCommands` and
  `python3? --version` being in `allowedCommands`. The command is not in
  Kiro CLI's internal "read-only" classification used by
  `autoAllowReadonly`. Full-path `/usr/bin/python3 --version` succeeded,
  confirming the deny pattern removal was correct but `allowedCommands`
  does not override the `autoAllowReadonly` gate.
- **Conclusion:** `allowedCommands` controls auto-approval (no user
  confirmation prompt), not deny-override. Commands not recognized by
  `autoAllowReadonly`'s internal classification are blocked regardless.

**Final approach (supersedes Round 2 "Final approach" section above):**
Enumerative deny — list specific mutating subcommands for npm/uv/pip.
`python3? .*` and `node .*` removed from deny list entirely (not in any
deny pattern = auto-allowed by Kiro CLI for commands it recognizes).

**B1 fix (commit 6):** Audit Agent's counter-audit identified 5 blanket
sub-prefix patterns that over-blocked read-only subcommands:
- `npm cache.*` blocked `npm cache verify` (read-only)
- `npm pkg.*` blocked `npm pkg get` (read-only)
- `uv cache.*` blocked `uv cache dir` (read-only)
- `uv tool.*` blocked `uv tool list` (read-only)
- `pip cache.*` blocked `pip cache info` / `pip cache list` (read-only)

Replaced with 15 specific mutating-subcommand patterns. Enumeration
derived from `npm cache --help`, `npm pkg --help`, `uv cache --help`,
`uv tool --help`, `pip cache --help`.

**Updated verification criteria:**
- `deniedCommands` length: 65 (was 17 in Round 2 hybrid; 55 in initial
  enumerative; 65 after B1 sub-prefix fix)
- `allowedCommands`: not present (array not added)
- `allowedTools` includes `shell`: true
- M-03 closed as part of H-05 via `shell` addition to `allowedTools`