# Audit Triage — v0.6.0

**Date:** 2026-04-17
**Baseline:** `docs/audit/audit-triage-v0.5.1.md` (22 CLOSED, 3 HIGH + 12 MEDIUM + 6 LOW still open)
**Current state:** v0.5.1 shipped + v0.6.0 backlog remediation (feature/audit-phase4 commit 1)
**Purpose:** Definitive status of every audit finding as of v0.6.0, for future
sessions and counter-audit by Claude Code / Kiro CLI.

---

## Method

Carries forward all v0.5.1 statuses. Six findings from the v0.5.1 recommended
scope were addressed in this cycle. Status changes from v0.5.1 are marked
**[NEW in v0.6.0]**.

---

## Summary Counts

| Severity | Total | CLOSED | INTENTIONAL | PARTIAL | STILL OPEN | OBSOLETE |
|---|---|---|---|---|---|---|
| CRITICAL | 9 | 8 | 0 | 1 | 0 | 0 |
| HIGH | 16 | 13 | 1 | 2 | 0 | 0 |
| MEDIUM | 16 | 6 | 4 | 0 | 5 | 1 |
| LOW | 7 | 2 | 4 | 0 | 0 | 1 |
| **Total** | **48** | **29** | **9** | **3** | **5** | **2** |

---

## CRITICAL Findings (8 CLOSED, 1 PARTIAL)

Unchanged from v0.5.1. 8 CLOSED, C-03 remains PARTIAL (shell indirection — documented limitation).

| # | Title | Status | Closed in | Evidence |
|---|---|---|---|---|
| C-01 | Prompt-steering duplication | CLOSED | v0.5.0 Phase 3 (a303d7c) | `! grep -rE 'Rule of Three\|Fail Fast' agents/prompts/*.md` → 0 matches |
| C-02 | Subagents have zero preToolUse hooks | CLOSED | v0.5.0 Phase 1 (3818e5f) | `jq '.hooks.preToolUse \| length' agents/dev-python.json` → 4 |
| C-03 | Deny list bypass via shell indirection | PARTIAL (downgraded HIGH in Round 3) | v0.5.1 | Readonly-command allowlist reduces FP; `bash -c` / `sh -c` indirection still possible but documented as limitation in audit-playbook.md §1.5 L3 |
| C-04 | TDD enforcement inconsistent | CLOSED | v0.5.0 Phase 2 (32793b3) + v0.5.0 addendum (98c8c0d) | TDD skill added to dev-frontend, dev-shell, dev-refactor |
| C-05 | Post-implementation trigger list mismatch | CLOSED | v0.5.0 Phase 1 (3818e5f) | Skill line 8 now lists all 6 implementation agents matching orchestrator |
| C-06 | No file conflict detection for parallel | CLOSED | v0.5.0 Phase 3 (a303d7c) | `grep 'cross-check file lists' skills/execution-planning/SKILL.md` → 1 match |
| C-07 | Knowledge rules duplicate steering | CLOSED | Mid-session discard | `grep -cE 'Rule of Three\|Fail Fast' knowledge/rules.md` → 0 |
| C-08 | `dd if/dev` typo in all agents | CLOSED | v0.5.0 Phase 1 + v0.5.1 base.json verified | `grep -rn '"dd if/dev"' agents/ .kiro/agents/` → 0; all have `dd if=/dev.*` |
| C-09 | Auto-capture keyword blind spots | CLOSED | v0.5.0 Phase 2 (32793b3) | `grep 'general' hooks/feedback/auto-capture.sh` → fallback present |

---

## HIGH Findings (13 CLOSED, 1 INTENTIONAL, 2 PARTIAL)

| # | Title | Status | Notes |
|---|---|---|---|
| H-01 | Steering count drift | CLOSED | 10→11 in README, team-onboarding, install-checklist |
| H-02 | dev-kiro-config ghost reference | **INTENTIONAL** | v0.5.1 §1.5 L1 documents as intentional project-local design |
| H-03 | Prompt naming inconsistency | CLOSED [v0.6.1] | Renamed 7 prompt files to match agent names (docs.md → dev-docs.md, etc.) and updated all JSON refs |
| H-04 | Subagents can't use MCP | CLOSED | `jq '.includeMcpJson' agents/dev-python.json` → true |
| H-05 | `dev-docs` deny list too broad | **CLOSED** [NEW in v0.6.0] | Replaced blanket `python3? .*`, `node .*`, `npm .*`, `uv .*`, `pip .*` with mutating-subcommand-only patterns. `shell` added to `allowedTools`. (feature/audit-phase4 commit 2) |
| H-06 | Hardcoded npm in quality gate | PARTIAL (downgraded MEDIUM in Round 3) | post-implementation still uses `npm`; consistent with steering's default |
| H-07 | Orchestrator MCP claim wrong | CLOSED | v0.5.0 Phase 2 corrected line 118 with accurate subagent MCP scope |
| H-08 | dev-refactor no debugging skill | CLOSED | v0.5.0 addendum (98c8c0d) added systematic-debugging to resources |
| H-09 | Orchestrator write paths too broad | PARTIAL | `*.md` removed (Phase 3 task 11); `~/personal/**` and `~/eam/**` kept as intended |
| H-10 | `rm -f.*r.*` regex FP | CLOSED | Replaced with `rm -[a-zA-Z]*r[a-zA-Z]* .*` + `rm --force --recursive.*` |
| H-11 | No subagent timeout guidance | **CLOSED** [NEW in v0.6.0] | "Subagent timeout and recovery" subsection added to `agents/prompts/orchestrator.md`. (feature/audit-phase4 commit 3) |
| H-12 | Hardcoded improvement path | CLOSED | Both orchestrator.md and post-implementation SKILL.md now use `~/.kiro/docs/improvements/pending.md` |
| H-13 | dev-kiro-config has no hooks | CLOSED | v0.5.0 Phase 1 added 4 preToolUse hooks |
| H-14 | plan-reviewer ghost | CLOSED | `grep -c plan-reviewer skills/writing-plans/SKILL.md` → 0 |
| H-15 | Regex injection in context-enrichment.sh | CLOSED | `escaped_kw` variable now escapes metacharacters |
| H-16 | distill.sh sed corruption | CLOSED | Replaced with awk; archive_promoted regression fix included |

---

## MEDIUM Findings (6 CLOSED, 4 INTENTIONAL, 5 STILL OPEN, 1 OBSOLETE)

| # | Title | Status | Notes |
|---|---|---|---|
| M-01 | Irrelevant steering loaded into every agent | **STILL OPEN** | dev-python loads frontend.md, typescript.md, etc. Wasted context for Sonnet subagents |
| M-02 | Skill chain dependencies not enforced | **INTENTIONAL** | Skill chain is prose-only by design — Kiro CLI has no hard gate mechanism for skill ordering |
| M-03 | dev-docs can't run doc-consistency | CLOSED (via H-05 fix) [NEW in v0.6.0] | `shell` added to `allowedTools`; enumerative deny allows read-only shell commands |
| M-04 | Knowledge enrichment 60s dedup | **STILL OPEN** | Still in context-enrichment.sh. Real FP source on rapid-fire debugging sessions |
| M-05 | Correction detection regex FPs | **STILL OPEN** | 14 patterns, some match agreement messages |
| M-06 | Session log no rotation | **INTENTIONAL** | Session log is gitignored, 7 lines — not operationally significant |
| M-07 | No CI failure skill | **OBSOLETE** | No CI pipeline exists for this repo; skill would have no consumer |
| M-08 | AWS S3 mutations not blocked | **CLOSED** [NEW in v0.6.0] | `aws s3 cp`, `aws s3 mv`, `aws s3 rm`, `aws s3 sync` added to `dev-orchestrator.json` deniedCommands. (feature/audit-phase4 commit 4) |
| M-09 | No multi-language routing | **INTENTIONAL** | Multi-language handled by parallel dispatch lane (dev-typescript + dev-frontend); explicit routing not needed |
| M-10 | base.json orphaned | **INTENTIONAL** | v0.5.1 §1.5 L4 documents as standalone-fallback design choice |
| M-11 | Orchestrator missing rm deny | CLOSED | v0.5.0 Phase 1 added `rm -r.*`, `rm --recursive.*`, `rm --force --recursive.*` |
| M-12 | /tmp files no namespace | **CLOSED** [NEW in v0.6.0] | `/tmp/kb-*` paths in `hooks/feedback/*.sh` now namespaced with `$USER`. (feature/audit-phase4 commit 5) |
| M-13 | doc-consistency only checks skill counts | CLOSED [v0.6.1] | `hooks/doc-consistency.sh` extended to check agent and hook counts; includes `.kiro/agents/` in agent count |
| M-14 | create-pr hardcodes `--base main` | CLOSED [v0.6.1] | Replaced `--base main` with dynamic `gh repo view --json defaultBranchRef` detection |
| M-15 | auto-capture race condition | **STILL OPEN** | No file locking; same-second corrections overwrite flag files |
| M-16 | auto-capture dedup uses first 120 chars | **STILL OPEN** | Confirmed at auto-capture.sh:26 |

---

## LOW Findings (2 CLOSED, 4 INTENTIONAL, 1 OBSOLETE)

| # | Title | Status | Notes |
|---|---|---|---|
| L-01 | `git add .*` too permissive | **CLOSED** [NEW in v0.6.0] | Tightened to `git add [^-.].*` + `git add -- .*` in `dev-orchestrator.json`. Blocks `git add -A`, `git add .`, `git add --all`. (feature/audit-phase4 commit 6) |
| L-02 | No shell-audit skill | **INTENTIONAL** | dev-reviewer covers shell review via inline checklist; dedicated skill not justified by Rule of Three |
| L-03 | Graphviz diagrams won't render | **INTENTIONAL** | Graphviz dot syntax is for LLM consumption; humans use audit-playbook.md |
| L-04 | npm vs bun across configs | **INTENTIONAL** | Cross-tool inconsistency between kiro-config (npm) and user's CLAUDE.md (bun); outside this repo's control |
| L-05 | correction-detect has 14 patterns, not 16 | **OBSOLETE** | Round 3 determined no phantom count reference existed |
| L-06 | Missing credential file types (id_dsa, .p12, .pfx, kubeconfig, .tfstate) | **CLOSED** [NEW in v0.6.0] | All five patterns added to `hooks/protect-sensitive.sh` PROTECTED array. Six new test cases in `scripts/test-hooks.sh`. (feature/audit-phase4 commit 7) |
| L-07 | Skills reference tools that may not be installed | **INTENTIONAL** | python-audit runs in project repos that have bandit/mypy installed; pre-check would add complexity for no real benefit |

---

## Round-2 / Counter-audit findings

All carry-forward from v0.5.1 — unchanged. See `docs/audit/audit-triage-v0.5.1.md`
for the full table. All 13 counter-audit findings remain CLOSED.

---

## Closing state

- **v0.6.0 ships with:** 29 CLOSED, 9 INTENTIONAL, 3 PARTIAL — 5 remain open (all MEDIUM)
- **Known still-open scope:** 5 MEDIUM still open (M-01, M-04, M-05, M-15, M-16)
- **Nothing blocks production use.** All CRITICAL and HIGH are resolved or accepted-PARTIAL (C-03 shell indirection, H-06 npm hardcoding, H-09 write paths — all documented limitations).
- **Future maintenance enters via `audit-playbook.md`** — S10 invariant now covers aws s3 deny; `bash scripts/test-hooks.sh` covers new protect-sensitive patterns.

— audit agent

> Note: as of v0.7.0, dev-* agents were renamed to devops-*. See docs/specs/2026-04-18-devops-terraform-and-rename/spec.md.
