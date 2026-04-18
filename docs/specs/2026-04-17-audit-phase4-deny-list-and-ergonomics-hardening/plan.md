# Deny-list and Hook Hardening + dev-docs Ergonomics — Implementation Plan

> **For agentic workers:** Use the subagent-driven-development skill to
> implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax
> for tracking.

**Goal:** Ship v0.6.0 covering six deferred findings from the v0.5.1
audit backlog — four safety tightenings, one ergonomics loosening, one
docs addition. See `spec.md` for rationale.

**Architecture:** Pure config / script / markdown edits. No new files
except the new spec + CHANGELOG entry. No new features.

**Tech Stack:**
- JSON (`jq empty` validation) — agent configs
- Bash (`bash -n`, `scripts/test-hooks.sh`) — hook scripts
- Markdown — prompts, CHANGELOG

---

## File Structure

No new code files. Modifications and additions:

| File | Tasks | What changes |
|---|---|---|
| `agents/dev-orchestrator.json` | 3, 4 | Add 4 `aws s3` deny patterns; tighten `git add` allow |
| `agents/dev-docs.json` | 5 | Replace blanket `<lang> .*` denies with mutation-only patterns |
| `hooks/protect-sensitive.sh` | 1 | Extend PROTECTED array with 5 new patterns |
| `scripts/test-hooks.sh` | 1 | Add L-06 coverage tests |
| `hooks/feedback/correction-detect.sh` | 2 | Namespace `/tmp/kb-*` with `$USER` |
| `hooks/feedback/context-enrichment.sh` | 2 | Same |
| `hooks/feedback/auto-capture.sh` | 2 | Same |
| `agents/prompts/orchestrator.md` | 6 | Add "Subagent timeout and recovery" subsection |
| `docs/reference/CHANGELOG.md` | 7 | v0.6.0 entry |
| `docs/reference/audit-playbook.md` | 7 | §8 changelog entry + §1.1 invariants re-check |

---

## Branch & commit strategy

**Branch:** `feature/audit-phase4-deny-list-and-ergonomics-hardening` (per working rule: big changes get a branch).

**5 commits**, grouped by theme:

1. `fix(hooks): add missing credential types and namespace tmp flags` (Task 1 + Task 2, L-06 + M-12)
2. `fix(orchestrator): block aws s3 mutations and tighten git add allow` (Task 3 + Task 4, M-08 + L-01)
3. `feat(dev-docs): allow read-only interpreter and package-manager invocations` (Task 5, H-05)
4. `docs(orchestrator): add subagent timeout and recovery guidance` (Task 6, H-11)
5. `docs(changelog): v0.6.0 entry and playbook update` (Task 7)

PR from `feature/audit-phase4-deny-list-and-ergonomics-hardening` → `main` via `create-pr` skill. Merge, tag v0.6.0,
ship.

---

## Tasks

### Task 1 — Extend `protect-sensitive.sh` with missing credential types (L-06)

**Files:**
- Modify: `hooks/protect-sensitive.sh`
- Modify: `scripts/test-hooks.sh`

**Problem.** PROTECTED array at `protect-sensitive.sh:26-39` misses five
credential file types in active use: legacy SSH (`id_dsa`), PKCS#12
keystores (`*.p12`, `*.pfx`), Kubernetes credentials (`kubeconfig`),
Terraform state (`*.tfstate`).

**Change in `hooks/protect-sensitive.sh`.** Append after line 38
(existing `id_ecdsa` entry):

```bash
  "id_dsa"
  ".p12"
  ".pfx"
  "kubeconfig"
  ".tfstate"
```

**Change in `scripts/test-hooks.sh`.** Add six cases under the
`=== protect-sensitive.sh ===` block, after the existing `.env.bak`
test:

```bash
run_test "id_dsa blocked"            "protect-sensitive.sh" "$(fsw_input '.ssh/id_dsa' 'keydata')"                "block"
run_test "cert.p12 blocked"          "protect-sensitive.sh" "$(fsw_input 'certs/cert.p12' 'binarydata')"          "block"
run_test "cert.pfx blocked"          "protect-sensitive.sh" "$(fsw_input 'certs/cert.pfx' 'binarydata')"          "block"
run_test "kubeconfig blocked"        "protect-sensitive.sh" "$(fsw_input '.kube/kubeconfig' 'apiVersion: v1')"    "block"
run_test "tfstate blocked"           "protect-sensitive.sh" "$(fsw_input 'tf/terraform.tfstate' '{}')"            "block"
run_test "tfstate.example passes"    "protect-sensitive.sh" "$(fsw_input 'terraform.tfstate.example' '{}')"      "pass"
```

**Done when:**
- `grep -c '"id_dsa"' hooks/protect-sensitive.sh` → 1
- `grep -c '".tfstate"' hooks/protect-sensitive.sh` → 1
- `bash scripts/test-hooks.sh` exits 0 (all 33 prior + 6 new tests pass → 39)
- `bash -n hooks/protect-sensitive.sh` — no output

---

### Task 2 — Namespace `/tmp/kb-*` flag files with `$USER` (M-12)

**Files:**
- Modify: `hooks/feedback/correction-detect.sh` (1 line)
- Modify: `hooks/feedback/context-enrichment.sh` (3 lines)
- Modify: `hooks/feedback/auto-capture.sh` (1 line)

**Problem.** Bare `/tmp/kb-*` paths collide across users on shared
machines. `auto-capture.sh` writes a flag consumed by
`context-enrichment.sh`; both must change together.

**Change in `hooks/feedback/correction-detect.sh:32`:**
```diff
-  FLAG="/tmp/kb-correction-$(date +%s).flag"
+  FLAG="/tmp/kb-${USER}-correction-$(date +%s).flag"
```

**Change in `hooks/feedback/context-enrichment.sh:17`:**
```diff
-DEDUP_FILE="/tmp/kb-enrich-last"
+DEDUP_FILE="/tmp/kb-${USER}-enrich-last"
```

**Change in `hooks/feedback/context-enrichment.sh:28`:**
```diff
-if [[ -f /tmp/kb-changed.flag ]]; then
+if [[ -f "/tmp/kb-${USER}-changed.flag" ]]; then
```

**Change in `hooks/feedback/context-enrichment.sh:32`:**
```diff
-  rm -f /tmp/kb-changed.flag
+  rm -f "/tmp/kb-${USER}-changed.flag"
```

**Change in `hooks/feedback/auto-capture.sh:44`:**
```diff
-touch /tmp/kb-changed.flag
+touch "/tmp/kb-${USER}-changed.flag"
```

**Done when:**
- `grep -rnE '/tmp/kb-[a-z]' hooks/feedback/ | grep -v '\$\{USER\}\|\$USER'` → no matches
- `bash -n hooks/feedback/*.sh` — no errors
- Sanity: set a correction via live session, verify new flag name appears in `/tmp`

---

### Task 3 — Block `aws s3 cp/mv/rm/sync` in orchestrator (M-08)

**File:** `agents/dev-orchestrator.json`

**Problem.** Deny list uses hyphenated-action patterns (`aws .* create-.*`,
`delete-.*`, …). `aws s3 cp/mv/rm/sync` use verb-only form and slip through.

**Change.** Insert after the existing `"aws .* untag-.*",` line (line 133):

```json
      "aws s3 cp.*",
      "aws s3 mv.*",
      "aws s3 rm.*",
      "aws s3 sync.*",
```

**Done when:**
- `jq '.toolsSettings.execute_bash.deniedCommands | map(select(startswith("aws s3")))' agents/dev-orchestrator.json | jq 'length'` → 4
- `jq empty agents/dev-orchestrator.json` — no error

---

### Task 4 — Tighten `git add` allow pattern (L-01)

**File:** `agents/dev-orchestrator.json:77`

**Problem.** `"git add .*"` matches `git add -A`, `git add .`, `git add --all`.

**Change (Round 2 revised).** Replace with TWO allow patterns — the
first blocks flag/dot forms, the second permits the disambiguator form
for dotfile staging.
```diff
-        "git add .*",
+        "git add [^-.].*",
+        "git add -- .*",
```

**Regex verification** (Round 2 via Python `re.match` with `\A\Z`):

| Input | `[^-.].*` | `-- .*` | Result |
|---|---|---|---|
| `git add src/foo.py` | ✓ | — | allowed |
| `git add -- .env.example` | ✗ | ✓ | allowed |
| `git add -A` | ✗ | ✗ | blocked |
| `git add .` | ✗ | ✗ | blocked |
| `git add --all` | ✗ | ✗ | blocked |
| `git add -p file.txt` | ✗ | ✗ | blocked |

**Done when:**
- `jq '.toolsSettings.execute_bash.allowedCommands | map(select(test("^git add")))' agents/dev-orchestrator.json | jq 'length'` → 2
- `jq '.toolsSettings.execute_bash.allowedCommands[]' agents/dev-orchestrator.json | grep -E '^"git add (\[\^-\.\]\.\*|-- \.\*)"$'` → 2 matches
- Manual check: orchestrator running `git add src/foo.py` succeeds; `git add -A`, `git add --all`, `git add .` are denied
- Manual check: orchestrator running `git add -- .env.example` succeeds

**Canonical workaround for dotfiles.** `git add -- .env.example`.
Earlier-draft suggestion `git add ./.env.example` is WRONG — `./` fails
the first pattern.

---

### Task 5 — Loosen dev-docs for read-only invocations (H-05 + M-03) — ROUND 2 REVISED

**Files:**
- `agents/dev-docs.json` — `toolsSettings.execute_bash.deniedCommands` (remove 2 entries), `toolsSettings.execute_bash.allowedCommands` (new array), `allowedTools` (add `shell`)

**Problem.** `dev-docs` can't run `python3 --version` under the current
10-entry blanket-deny. Round 1 proposed enumerating mutating subcommands
(Option 1); Kiro counter-audit identified 31+ gaps. Round 2 inverts to
deny-by-default + explicit allow list.

Separately, `shell` is in `tools` but not in `allowedTools` — so even
commands that would pass the deny list still prompt for user approval.
Adding `shell` to `allowedTools` closes M-03 as part of the same change.

**Change 1 — remove 2 entries from `deniedCommands`.** Before: 19
entries. After: 17 entries.
```diff
-        "python3? .*",
-        "node .*",
```

The blanket denies `npm .*`, `uv .*`, `pip .*`, `terraform .*`,
`helm .*`, `kubectl .*`, `docker .*`, `aws .*` **remain unchanged**.
Mutating subcommands are caught by default.

**Change 2 — add new `allowedCommands` array** (27 entries) to
`toolsSettings.execute_bash`. Insert after the `autoAllowReadonly: true`
line:
```json
      "allowedCommands": [
        "python3? --version",
        "python3? -V",
        "node --version",
        "node -v",
        "npm audit.*",
        "npm ls.*",
        "npm outdated.*",
        "npm view.*",
        "npm explain.*",
        "npm fund.*",
        "npm doctor.*",
        "npm config list.*",
        "uv tree.*",
        "uv show.*",
        "uv version.*",
        "uv python list.*",
        "uv pip list.*",
        "uv pip show.*",
        "uv pip check.*",
        "uv pip freeze.*",
        "pip show.*",
        "pip list.*",
        "pip check.*",
        "pip freeze.*",
        "pip config list.*",
        "pip debug.*",
        "pip cache info.*"
      ],
```

**Change 3 — add `shell` to `allowedTools`:**
```diff
   "allowedTools": [
     "read",
     "write",
-    "code"
+    "code",
+    "shell"
   ],
```

**Semantics assumption.** When a command matches BOTH `allowedCommands`
and `deniedCommands`, Kiro CLI's allow-wins precedence applies. This is
the assumption for `npm audit` to pass (matches allow) while being
inside `npm .*` (matches deny). If runtime validation disproves this,
fallback: restore Round 1 enumerative deny approach with Kiro's
supplementary patterns added (~30 deny entries total).

**Done when:**
- `jq '.toolsSettings.execute_bash.deniedCommands | length' agents/dev-docs.json` → 17
- `jq '.toolsSettings.execute_bash.deniedCommands | any(. == "python3? .*")' agents/dev-docs.json` → false
- `jq '.toolsSettings.execute_bash.deniedCommands | any(. == "npm .*")' agents/dev-docs.json` → true
- `jq '.toolsSettings.execute_bash.allowedCommands | length' agents/dev-docs.json` → 27
- `jq '.toolsSettings.execute_bash.allowedCommands | any(. == "python3? --version")' agents/dev-docs.json` → true
- `jq '.allowedTools | any(. == "shell")' agents/dev-docs.json` → true
- `jq empty agents/dev-docs.json` — no error
- Runtime (allow-wins semantic check): dispatch dev-docs with "run python3 --version" → succeeds
- Runtime (allow-wins semantic check): dispatch dev-docs with "run npm ls" → succeeds
- Runtime (deny still holds): dispatch dev-docs with "run pip install foo" → blocked
- Runtime (deny still holds): dispatch dev-docs with "run npm init" → blocked

**Round 3 revision.** The hybrid deny+allow approach (Round 2) failed at
runtime — Kiro CLI's `allowedCommands` does not override `autoAllowReadonly`
gating. Implemented as enumerative deny instead. Blanket sub-prefix patterns
(`npm cache.*`, `npm pkg.*`, `uv cache.*`, `uv tool.*`, `pip cache.*`)
replaced with 15 specific mutating-subcommand patterns in commit 6.
Final `deniedCommands` length: 65.

---

### Task 6 — Add subagent timeout guidance to orchestrator prompt (H-11)

**File:** `agents/prompts/orchestrator.md`

**Problem.** No written guidance on stuck subagents. Retry limit (max 3)
covers fail-loops but not hang-loops.

**Change.** Insert a new subsection after the existing `### Retry limit`
block (around line 105):

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

**Done when:**
- `grep -c 'Subagent timeout' agents/prompts/orchestrator.md` → 1
- `grep -c 'stuck-without-erroring' agents/prompts/orchestrator.md` → 1

---

### Task 7 — Update CHANGELOG and audit playbook (docs)

**Files:**
- Modify: `docs/reference/CHANGELOG.md`
- Modify: `docs/reference/audit-playbook.md`
- Create: `docs/specs/audit-triage-v0.6.0.md`

**Change in `CHANGELOG.md`.** Add v0.6.0 entry above the v0.5.1 entry:

```markdown
## [v0.6.0] - 2026-04-17

Backlog remediation — closes six deferred findings from the v0.5.1 audit
backlog. Four safety tightenings, one ergonomics loosening, one
documentation addition. Zero new features.

### Added
- `hooks/protect-sensitive.sh` PROTECTED array: `id_dsa`, `*.p12`, `*.pfx`,
  `kubeconfig`, `*.tfstate` — covers legacy SSH, PKCS#12 keystores, Kubernetes
  credentials, and Terraform state. Six new cases added to `scripts/test-hooks.sh`.
- `agents/dev-orchestrator.json` deny list: `aws s3 cp/mv/rm/sync` — parallels
  the existing hyphenated-action pattern coverage.
- `agents/prompts/orchestrator.md` — "Subagent timeout and recovery"
  subsection. Names the currently-undefined behavior when a subagent
  appears stuck.

### Changed
- `agents/dev-docs.json` — replaced blanket `python3? .*`, `node .*`,
  `npm .*`, `uv .*`, `pip .*` denies with mutating-subcommand-only patterns.
  `dev-docs` can now run `python3 --version`, `npm ls`, `pip list`, etc.
  Mutation-form invocations still blocked.
- `agents/dev-orchestrator.json:77` — `git add .*` tightened to
  `git add [^-.].*`. Blocks `git add -A`, `git add .`, `git add --all`
  at the platform level.

### Fixed
- `hooks/feedback/*.sh` — `/tmp/kb-*` flag paths now namespaced with
  `$USER`. Prevents cross-user collision on shared hosts.

### Known limitations
- dev-docs `5a` narrow allow-list may miss read-only subcommands not
  enumerated here. New candidates will be added as friction surfaces.
- `~/.kube/config` (basename `config`) is NOT covered by the new
  kubeconfig pattern — `protect-sensitive.sh` is basename-only and doesn't
  see parent dirs. Use `~/.kube/kubeconfig` or run
  `chmod 600 ~/.kube/config` and rely on OS permissions.
```

**Change in `docs/reference/audit-playbook.md`.** Append to §8 change log:

```markdown
- **2026-04-17 (v0.6.0 backlog remediation):** Six findings closed from
  v0.5.1 backlog (H-05, H-11, M-08, M-12, L-01, L-06). Added invariant
  check for `aws s3` deny coverage in orchestrator.
```

Also extend §1.1 invariant S5 or add S10:
```markdown
| S10 | Orchestrator blocks `aws s3` mutating subcommands | `jq '.toolsSettings.execute_bash.deniedCommands \| map(select(startswith("aws s3")))' agents/dev-orchestrator.json \| jq 'length'` → 4 |
```

**Create `docs/specs/audit-triage-v0.6.0.md`.** Copy structure from
`audit-triage-v0.5.1.md`. Mark H-05, H-11, M-08, M-12, L-01, L-06 as
CLOSED with commit references. All other items retain their v0.5.1 status.

**Done when:**
- CHANGELOG has `## [v0.6.0] - 2026-04-17` header
- Audit playbook §8 has the new entry; S10 added to §1.1
- New triage doc exists with 6 newly-CLOSED rows
- Quick-check script still passes (`bash docs/reference/audit-playbook.md` section 2 equivalent)

---

## Parallel-safety

All seven tasks touch distinct files except:

- Task 3 and Task 4 both modify `agents/dev-orchestrator.json` → must be
  sequential (Task 3 → Task 4) or bundled in one edit.
- Tasks 1 and 2 edit different files → safe in parallel.
- Task 5 edits `dev-docs.json` alone → independent.
- Task 6 edits `orchestrator.md` alone → independent.
- Task 7 edits docs only → last, after all code changes.

Proposed order: Tasks 1, 2, 5, 6 in parallel (if implementer supports);
then Task 3 + Task 4 sequentially (single commit); then Task 7.

Given that this is small enough to be handled by `dev-kiro-config`
single-threaded, parallelism is optional.

---

## Verification before each commit

- `bash scripts/test-hooks.sh` → exit 0
- `jq empty agents/*.json .kiro/agents/*.json` → no errors
- `bash -n hooks/**/*.sh scripts/*.sh` → no syntax errors
- `git diff --stat` — only files listed in the File Structure table appear

---

## Post-merge verification

After merging `feature/audit-phase4-deny-list-and-ergonomics-hardening` and tagging v0.6.0:

1. Run audit playbook §2 quick health check — every invariant passes.
2. Runtime sanity: dispatch dev-docs with "run python3 --version" — confirms H-05.
3. Triage baseline (`docs/specs/audit-triage-v0.6.0.md`) lists 6 new CLOSED rows.
4. `git log --oneline main..v0.6.0` — 5 conventional-commit lines matching the §"Branch & commit strategy" plan.

— audit agent (Claude Code)

> Note: as of v0.7.0, dev-* agents were renamed to devops-*. See docs/specs/2026-04-18-devops-terraform-and-rename/spec.md.
