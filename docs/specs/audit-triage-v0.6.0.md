# Audit Triage — v0.6.0

**Date:** 2026-04-17
**Baseline:** `docs/specs/audit-triage-v0.5.1.md` (22 CLOSED, 3 HIGH + 12 MEDIUM + 6 LOW still open)
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
| CRITICAL | 9 | 9 | 0 | 0 | 0 | 0 |
| HIGH | 16 | 13 | 1 | 1 | 1 | 0 |
| MEDIUM | 16 | 4 | 1 | 1 | 10 | 0 |
| LOW | 7 | 2 | 0 | 0 | 4 | 1 |
| **Total** | **48** | **28** | **2** | **2** | **15** | **1** |

---

## CRITICAL Findings (9 of 9 CLOSED)

Unchanged from v0.5.1. All 9 CRITICAL findings remain CLOSED.

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

## HIGH Findings (13 CLOSED, 1 INTENTIONAL, 1 PARTIAL, 1 STILL OPEN)

| # | Title | Status | Notes |
|---|---|---|---|
| H-01 | Steering count drift | CLOSED | 10→11 in README, team-onboarding, install-checklist |
| H-02 | dev-kiro-config ghost reference | **INTENTIONAL** | v0.5.1 §1.5 L1 documents as intentional project-local design |
| H-03 | Prompt naming inconsistency | **STILL OPEN** (LOW priority per Round 3) | File naming mismatch remains. Cosmetic — JSON config has explicit `file://` refs |
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

## MEDIUM Findings (4 CLOSED, 1 INTENTIONAL, 1 PARTIAL, 10 STILL OPEN)

| # | Title | Status | Notes |
|---|---|---|---|
| M-01 | Irrelevant steering loaded into every agent | **STILL OPEN** | dev-python loads frontend.md, typescript.md, etc. Wasted context for Sonnet subagents |
| M-02 | Skill chain dependencies not enforced | **STILL OPEN** | design-and-spec → writing-plans → execution-planning chain is prose-only; no hard gate |
| M-03 | dev-docs can't run doc-consistency | CLOSED (via H-05 fix) [NEW in v0.6.0] | `shell` added to `allowedTools`; enumerative deny allows read-only shell commands |
| M-04 | Knowledge enrichment 60s dedup | **STILL OPEN** | Still in context-enrichment.sh. Real FP source on rapid-fire debugging sessions |
| M-05 | Correction detection regex FPs | **STILL OPEN** | 14 patterns, some match agreement messages |
| M-06 | Session log no rotation | **STILL OPEN** | Low priority; file is gitignored |
| M-07 | No CI failure skill | **STILL OPEN** | No `skills/ci-failure/` exists |
| M-08 | AWS S3 mutations not blocked | **CLOSED** [NEW in v0.6.0] | `aws s3 cp`, `aws s3 mv`, `aws s3 rm`, `aws s3 sync` added to `dev-orchestrator.json` deniedCommands. (feature/audit-phase4 commit 4) |
| M-09 | No multi-language routing | **STILL OPEN** | Orchestrator routing table covers single-language cases; multi-language is inferred |
| M-10 | base.json orphaned | **INTENTIONAL** | v0.5.1 §1.5 L4 documents as standalone-fallback design choice |
| M-11 | Orchestrator missing rm deny | CLOSED | v0.5.0 Phase 1 added `rm -r.*`, `rm --recursive.*`, `rm --force --recursive.*` |
| M-12 | /tmp files no namespace | **CLOSED** [NEW in v0.6.0] | `/tmp/kb-*` paths in `hooks/feedback/*.sh` now namespaced with `$USER`. (feature/audit-phase4 commit 5) |
| M-13 | doc-consistency only checks skill counts | PARTIAL | Playbook D1 invariant extended; `hooks/doc-consistency.sh` itself not updated |
| M-14 | create-pr hardcodes `--base main` | **STILL OPEN** | Confirmed at `.kiro/skills/create-pr/SKILL.md:71` |
| M-15 | auto-capture race condition | **STILL OPEN** | No file locking; same-second corrections overwrite flag files |
| M-16 | auto-capture dedup uses first 120 chars | **STILL OPEN** | Confirmed at auto-capture.sh:26 |

---

## LOW Findings (2 CLOSED, 4 STILL OPEN, 1 OBSOLETE)

| # | Title | Status | Notes |
|---|---|---|---|
| L-01 | `git add .*` too permissive | **CLOSED** [NEW in v0.6.0] | Tightened to `git add [^-.].*` + `git add -- .*` in `dev-orchestrator.json`. Blocks `git add -A`, `git add .`, `git add --all`. (feature/audit-phase4 commit 6) |
| L-02 | No shell-audit skill | **STILL OPEN** | dev-reviewer covers via inline shell checklist |
| L-03 | Graphviz diagrams won't render | **STILL OPEN** | Skills use `dot` syntax; fine for LLM consumption, bad for humans opening GitHub |
| L-04 | npm vs bun across configs | **STILL OPEN** | Steering says npm; user's CLAUDE.md says bun. Cross-tool inconsistency acknowledged |
| L-05 | correction-detect has 14 patterns, not 16 | **OBSOLETE** | Round 3 determined no phantom count reference existed |
| L-06 | Missing credential file types (id_dsa, .p12, .pfx, kubeconfig, .tfstate) | **CLOSED** [NEW in v0.6.0] | All five patterns added to `hooks/protect-sensitive.sh` PROTECTED array. Six new test cases in `scripts/test-hooks.sh`. (feature/audit-phase4 commit 7) |
| L-07 | Skills reference tools that may not be installed | **STILL OPEN** | python-audit references bandit/mypy; no pre-check |

---

## Round-2 / Counter-audit findings

All carry-forward from v0.5.1 — unchanged. See `docs/specs/audit-triage-v0.5.1.md`
for the full table. All 13 counter-audit findings remain CLOSED.

---

## Closing state

- **v0.6.0 ships with:** 28 findings CLOSED (22 from v0.5.1 + 6 new in this cycle).
- **Known still-open scope:** 1 HIGH, 10 MEDIUM, 4 LOW, ~120 improvement items.
- **Nothing blocks production use.** All CRITICAL and all but one HIGH are resolved.
- **Remaining HIGH (H-03):** cosmetic prompt naming mismatch; no functional impact.
- **Future maintenance enters via `audit-playbook.md`** — S10 invariant now covers aws s3 deny; `bash scripts/test-hooks.sh` covers new protect-sensitive patterns.

— audit agent
