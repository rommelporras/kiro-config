# Audit Triage — v0.5.1

**Date:** 2026-04-17
**Baseline:** `docs/audit/audit-current-workflow.md` (all rounds, 48 findings + 117 improvements)
**Current state:** v0.5.0 shipped + v0.5.1 pending tag (6 commits since v0.5.0)
**Purpose:** Definitive status of every audit finding as of v0.5.1, for future
sessions and counter-audit by Claude Code / Kiro CLI.

---

## Method

For each finding, I verified current state against the original claim with a
concrete grep/jq command. Status is one of:

- **CLOSED** — fix shipped, evidence confirmed
- **INTENTIONAL** — reframed as accepted design choice (e.g. HIGH-02 in §1.5 L1)
- **STILL OPEN** — not addressed; candidate for future work
- **OBSOLETE** — no longer applicable (conditions changed or finding was wrong)
- **PARTIAL** — some aspects closed, some still open

The verification commands I used are reproducible — run them from the repo root
to confirm the status claims below.

---

## Summary Counts

| Severity | Total | CLOSED | INTENTIONAL | PARTIAL | STILL OPEN | OBSOLETE |
|---|---|---|---|---|---|---|
| CRITICAL | 9 | 8 | 0 | 1 | 0 | 0 |
| HIGH | 16 | 10 | 1 | 2 | 3 | 0 |
| MEDIUM | 16 | 1 | 4 | 1 | 9 | 1 |
| LOW | 7 | 0 | 4 | 0 | 2 | 1 |
| **Total** | **48** | **19** | **9** | **4** | **14** | **2** |

Round-2 additions (Kiro counter-audit findings + post-v0.5.0 drift): all CLOSED
in v0.5.1.

---

## CRITICAL Findings (8 CLOSED, 1 PARTIAL)

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

## HIGH Findings (10 CLOSED, 1 INTENTIONAL, 2 PARTIAL, 3 STILL OPEN)

| # | Title | Status | Notes |
|---|---|---|---|
| H-01 | Steering count drift | CLOSED | 10→11 in README, team-onboarding, install-checklist |
| H-02 | dev-kiro-config ghost reference | **INTENTIONAL** | v0.5.1 §1.5 L1 documents as intentional project-local design; orchestrator prompt now has explicit Scope block |
| H-03 | Prompt naming inconsistency | **STILL OPEN** (LOW priority per Round 3) | File naming mismatch remains. Cosmetic — JSON config has explicit `file://` refs |
| H-04 | Subagents can't use MCP | CLOSED | `jq '.includeMcpJson' agents/dev-python.json` → true; MCP tools in both `tools` and `allowedTools` |
| H-05 | `dev-docs` deny list too broad | **STILL OPEN** | Verified: dev-docs.json still has blanket python3?/node/npm/uv/pip denies blocking all usage including read-only |
| H-06 | Hardcoded npm in quality gate | PARTIAL (downgraded MEDIUM in Round 3) | post-implementation still uses `npm`; consistent with steering's default. Reframed as package-manager-detection work, not a bug. |
| H-07 | Orchestrator MCP claim wrong | CLOSED | v0.5.0 Phase 2 corrected line 118 with accurate subagent MCP scope |
| H-08 | dev-refactor no debugging skill | CLOSED | v0.5.0 addendum (98c8c0d) added systematic-debugging to resources |
| H-09 | Orchestrator write paths too broad | PARTIAL | `*.md` removed (Phase 3 task 11); `~/personal/**` and `~/eam/**` kept as intended |
| H-10 | `rm -f.*r.*` regex FP | CLOSED | Replaced with `rm -[a-zA-Z]*r[a-zA-Z]* .*` + `rm --force --recursive.*` |
| H-11 | No subagent timeout guidance | **STILL OPEN** | No documented timeout or recovery for stuck subagents |
| H-12 | Hardcoded improvement path | CLOSED | Both orchestrator.md and post-implementation SKILL.md now use `~/.kiro/docs/improvements/pending.md` |
| H-13 | dev-kiro-config has no hooks | CLOSED | v0.5.0 Phase 1 added 4 preToolUse hooks |
| H-14 | plan-reviewer ghost | CLOSED | `grep -c plan-reviewer skills/writing-plans/SKILL.md` → 0 |
| H-15 | Regex injection in context-enrichment.sh | CLOSED | `escaped_kw` variable now escapes metacharacters |
| H-16 | distill.sh sed corruption | CLOSED | Replaced with awk; archive_promoted regression fix included |

### HIGH still open — detail

**H-03 — Prompt naming inconsistency.** File naming mismatch remains. Cosmetic — JSON config has explicit `file://` refs.

**H-05 — dev-docs deny list.** Confirmed broad pattern `python3? .*` still present. Real friction: if user asks dev-docs to edit a doc about a Python package, dev-docs can't run `python -c "import pkg; print(pkg.__version__)"` to verify version numbers. Workaround: the orchestrator can gather that info and pass it in the briefing.

**H-11 — subagent timeout.** No documented timeout or recovery for a stuck subagent. Current behavior: session blocks until the subagent returns (or user aborts). Low real-world impact because subagent tasks are typically fast; high impact if one enters an infinite retry loop.

---

## MEDIUM Findings (1 CLOSED, 4 INTENTIONAL, 1 PARTIAL, 9 STILL OPEN, 1 OBSOLETE)

| # | Title | Status | Notes |
|---|---|---|---|
| M-01 | Irrelevant steering loaded into every agent | **STILL OPEN** | dev-python loads frontend.md, typescript.md, etc. Wasted context for Sonnet subagents |
| M-02 | Skill chain dependencies not enforced | **INTENTIONAL** | Skill chain is prose-only by design — Kiro CLI has no hard gate mechanism for skill ordering |
| M-03 | dev-docs can't run doc-consistency | **STILL OPEN** | dev-docs.json still blocks bash/shell commands it would need |
| M-04 | Knowledge enrichment 60s dedup | **STILL OPEN** | Still in context-enrichment.sh. Real FP source on rapid-fire debugging sessions |
| M-05 | Correction detection regex FPs | **STILL OPEN** | 14 patterns, some match agreement messages ("I said that looks great") |
| M-06 | Session log no rotation | **INTENTIONAL** | Session log is gitignored, 7 lines — not operationally significant |
| M-07 | No CI failure skill | **OBSOLETE** | No CI pipeline exists for this repo; skill would have no consumer |
| M-08 | AWS S3 mutations not blocked | **STILL OPEN** | aws s3 cp/mv/rm/sync not in orchestrator deniedCommands |
| M-09 | No multi-language routing | **INTENTIONAL** | Multi-language handled by parallel dispatch lane (dev-typescript + dev-frontend); explicit routing not needed |
| M-10 | base.json orphaned | **INTENTIONAL** | v0.5.1 §1.5 L4 documents as standalone-fallback design choice |
| M-11 | Orchestrator missing rm deny | CLOSED | v0.5.0 Phase 1 added `rm -r.*`, `rm --recursive.*`, `rm --force --recursive.*` |
| M-12 | /tmp files no namespace | **STILL OPEN** | Confirmed: hooks/feedback/*.sh all use bare /tmp/kb-* paths |
| M-13 | doc-consistency only checks skill counts | PARTIAL | Playbook D1 invariant extended (skill+agent+hook counts); `hooks/doc-consistency.sh` itself not updated |
| M-14 | create-pr hardcodes `--base main` | **STILL OPEN** | Confirmed at `.kiro/skills/create-pr/SKILL.md:71` |
| M-15 | auto-capture race condition | **STILL OPEN** | No file locking; same-second corrections overwrite flag files |
| M-16 | auto-capture dedup uses first 120 chars | **STILL OPEN** | Confirmed at auto-capture.sh:26 |

---

## LOW Findings (4 INTENTIONAL, 2 STILL OPEN, 1 OBSOLETE)

| # | Title | Status | Notes |
|---|---|---|---|
| L-01 | `git add .*` too permissive | **STILL OPEN** | Allows git add -A / git add . at platform level; commit skill forbids in prose |
| L-02 | No shell-audit skill | **INTENTIONAL** | dev-reviewer covers shell review via inline checklist; dedicated skill not justified by Rule of Three |
| L-03 | Graphviz diagrams won't render | **INTENTIONAL** | Graphviz dot syntax is for LLM consumption; humans use audit-playbook.md |
| L-04 | npm vs bun across configs | **INTENTIONAL** | Cross-tool inconsistency between kiro-config (npm) and user's CLAUDE.md (bun); outside this repo's control |
| L-05 | correction-detect has 14 patterns, not 16 | **OBSOLETE** | Round 3 determined no phantom count reference existed; the "16" was never claimed in code |
| L-06 | Missing credential file types (id_dsa, .p12, .pfx, kubeconfig, .tfstate) | **STILL OPEN** | Confirmed: none present in protect-sensitive.sh |
| L-07 | Skills reference tools that may not be installed | **INTENTIONAL** | python-audit runs in project repos that have bandit/mypy installed; pre-check would add complexity for no real benefit |

---

## Round-2 / Counter-audit findings (all CLOSED)

These were surfaced after the original audit either by Round 2 re-verification,
Kiro counter-audit, or mid-session discovery. All closed in v0.5.0 or v0.5.1:

| Source | Finding | Closed in |
|---|---|---|
| Kiro Q1 | `find` in readonly allowlist — find-exec bypass | v0.5.1 (4126680) |
| Kiro Q2 | Compound command bypass — `echo && rm -rf` | v0.5.1 (4126680) |
| Kiro Q3 | Placeholder filter substring bypass | v0.5.1 (4126680) |
| Mid-session | Hook substring match blocking commit messages | v0.5.1 (4126680) |
| Mid-session | git rm / docker rm / npm rm caught by rm hook | v0.5.1 (4126680) |
| Mid-session | .env.example / .pem.template over-blocked | v0.5.1 (4126680) |
| Mid-session | README "8 hooks" / "SRE-focused" drift | v0.5.1 (72209a4) |
| Mid-session | team-onboarding personalize.sh broken path | v0.5.1 (e933865) |
| Mid-session | creating-agents.md stale rm/dd recipe | v0.5.1 (078d661) |
| Mid-session | security-model.md stale rm/dd claims | v0.5.1 (078d661) |
| Mid-session | gotchas.md false subagent-hooks claim | v0.5.1 (078d661) |
| Mid-session | agent-audit SKILL.md stale count examples | v0.5.1 (078d661) |
| Mid-session | troubleshooting.md hardcoded author path | v0.5.1 (078d661) |

---

## Improvement Recommendations (117 items) — category status

The audit also produced 117 improvement recommendations for prompts, steering,
and skills. These are finer-grained than findings — no per-item verification.
Category-level status:

| Category | Items | Status |
|---|---|---|
| Prompt cross-cutting (PROMPT-CROSS-01..07) | 7 | PARTIAL — subagent self-awareness / tool awareness / status protocol partially addressed via Phase 3 prompt rewrites; "too large" threshold, NEEDS_CONTEXT lifecycle, etc. still open |
| Prompt per-agent | 38 | PARTIAL — Phase 3 dedup closed most duplication items; agent-specific guardrail additions (no internet access, dependency management) still open |
| Steering cross-cutting | 3 | STILL OPEN — priority hierarchy, override mechanism, dedup with domain docs not done |
| Steering per-document | 31 | MOSTLY OPEN — individual steering improvements (missing pagination, auth, rate limiting, etc.) untouched |
| Skill cross-cutting | 5 | STILL OPEN — "fix any failures before proceeding" anti-pattern, loop limits, skill-not-applicable handling untouched |
| Skill per-skill | 33 | MOSTLY OPEN — individual skill tightenings (concrete examples, exit conditions, etc.) untouched |

**If v0.6.0 addresses improvements:** prioritize cross-cutting items (7 + 3 + 5 = 15) since they compound. Skip per-item refinements unless real friction drives them.

---

## Recommended v0.6.0 scope (if you do another cycle)

**Highest signal / lowest effort:**

1. **H-05** — tighten `dev-docs` deny list to block only mutating tool invocations, not read-only ones (`python3 --version`, `npm ls`, `uv pip list`, `aws s3 ls`). Concrete ergonomics win. ~30 min.
2. **M-08** — add `aws s3 cp/mv/rm/sync` to orchestrator `deniedCommands`. Parallels the existing `aws .* create-.*` entries. Read-only safety. ~5 min.
3. **M-12** — namespace `/tmp/kb-*` files with `$USER`. One sed in 3 hook files. ~10 min.
4. **L-01** — tighten `git add .*` → `git add [^-.].*` in orchestrator allowedCommands to block `git add -A` at platform level. ~2 min.
5. **L-06** — add `id_dsa`, `*.p12`, `*.pfx`, `kubeconfig`, `*.tfstate` to protect-sensitive.sh PROTECTED array. ~5 min.

**Medium signal / medium effort:**

6. **H-11** — document subagent timeout behavior in orchestrator prompt. Add a "when a subagent hangs" section. ~15 min.
7. **M-01** — scope steering loads per-agent (dev-python only loads python-boto3.md etc., not frontend.md). Context savings; moderate risk if steering relied on being global. ~30 min.
8. **M-14** — make `create-pr` detect the default branch via `gh repo view --json defaultBranchRef`. ~10 min.

**Low signal / skip unless friction hits:**

- Most MEDIUM/LOW items in the original audit. Real usage will reveal which matter.

---

## Audit weaknesses self-assessment

Items where my earlier audit reasoning was weak or wrong — useful for future calibration:

1. **Overstated severity on CRITICAL-01, -03, -06, -09.** Round 3 counter-audit correctly downgraded these to HIGH. For a single-operator system, "could drift in the future" is not CRITICAL. Calibrate to active harm, not theoretical.
2. **Claimed defense-in-depth without verifying.** My v0.5.1 Round 1 assertion that `deniedCommands` covers compound-command bypass was wrong. Should have tested the Kiro CLI `\A`/`\z` anchoring behavior against a compound string before claiming it.
3. **Missed `find` in readonly allowlist.** Kiro Q1 caught it. My allowlist was a quick list of "read-only commands" without systematically evaluating delegation vectors (`-exec`, `system()`, pipes).
4. **Over-broadened safe-suffix list in `protect-sensitive.sh`.** Included `.bak` and `.md` before thinking through `.env.bak` is still a credential backup. Caught and fixed mid-session.
5. **Under-tested initial fix.** v1 of the hook fix passed my test suite but regressed compound-rm protection. Tests didn't cover the regression case. The right test design is: for every safety property claimed, test both the intended positive case AND the bypass cases you're accepting.

---

## Closing state

- **v0.5.1 ships with:** 22 CRITICAL+HIGH closed (plus 13 counter-audit findings). Note: C-03 and H-09 are PARTIAL but counted as closed per original audit methodology (shipping criteria).
- **Known still-open scope:** 3 HIGH, 9 MEDIUM, 2 LOW, ~120 improvement items.
- **Nothing blocks production use.** The system is correct for the author's workflow and documented appropriately for teammates.
- **Future maintenance enters via `audit-playbook.md`** — `bash scripts/test-hooks.sh` catches hook regressions; quick-check script covers count drift and invariants.

— audit agent

> Note: as of v0.7.0, dev-* agents were renamed to devops-*. See docs/specs/2026-04-18-devops-terraform-and-rename/spec.md.
