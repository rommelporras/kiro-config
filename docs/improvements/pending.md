# Improvement Backlog

Auto-captured friction from sessions. Reviewed during agent-audit.

<!-- Entries are appended by the orchestrator during sessions.
Format:
## YYYY-MM-DD — session in <project path>
### <Category>: <short title>
- What happened: <description>
- Root cause: <steering gap | routing issue | missing skill | missing context>
- Suggested fix: <specific action>
-->

---

## 2026-04-19 — session in /home/eam/personal/kiro-config

### Feature proposal: `doc-audit` skill with parallel specialist agents for structural doc drift

**Context — the v0.7.0 incident.** Spec `docs/specs/2026-04-18-devops-terraform-and-rename/` added a new agent (`devops-terraform`), a new skill (`terraform-audit`), a new hook (`terraform-preflight.sh`), a new helper script (`mark-preflight.sh`), and new steering (`terraform.md`). The spec enumerated the *artifacts being created* but did NOT enumerate the *existing docs that would become stale* because they enumerate/count/list the artifact categories being extended. After Phase 2 completed, a manual sweep found stale:

- `README.md` — architecture diagram missing `devops-terraform`, feature counts (10 agents, 18 skills, 11 steering, 11 hooks), structure tree, skill assignment matrix missing `devops-terraform` column, Infrastructure Read-Only Policy table's Terraform row was incomplete
- `docs/reference/skill-catalog.md` — "Quick reference for all 18 skills" stale, missing `terraform-audit` entry, assignment matrix missing `devops-terraform` column, design philosophy table missing the new failure mode, base-agent "14 of 18 global skills" denominator
- `docs/reference/creating-agents.md` — architecture diagram
- `docs/setup/team-onboarding.md` — architecture diagram, counts
- `skills/agent-audit/SKILL.md` — baseline counts (v0.5.0 → v0.7.0)
- `docs/reference/CHANGELOG.md` — v0.7.0 entry missing several delivered items
- `docs/reference/security-model.md` — `rm .*` deny-block agent list missing `devops-terraform`

**What happened:** human-side review caught the drift. Three automated layers that *should* have caught it all failed:

1. **writing-plans skill** — no rule requiring ripple-task enumeration when a plan creates new files in `agents/`, `skills/`, `hooks/`, or `steering/`. Author must remember.
2. **post-implementation skill, Step 3 (doc staleness check)** — scoped to "grep docs for references to modified files." A newly-created file is not a modification of existing files, so categories that enumerate "all agents" / "all skills" look clean at the file-reference level but are semantically stale.
3. **`hooks/doc-consistency.sh`** — exists, works, checks skills/agents/hooks count drift. But it is wired only into `skills/commit/SKILL.md:52` (commit Step 2.5). User's no-auto-commit review flow means the hook never fires until after manual review. Also: it does NOT check steering count (partial fix, flagged as M-13 PARTIAL in `audit-triage-v0.5.1.md`, still open).

Prior audit `docs/audit/audit-current-workflow.md:720-729` already diagnosed the hook-wire-up gap and wrote the fix: "Add a 'run doc-consistency.sh' step to the dev-docs prompt's completion phase." Never implemented. The related triage items M-03 (dev-docs couldn't run the hook) and M-13 (hook only checked skills) are both marked CLOSED in v0.6.0/v0.6.1, but the actual *wire-up into a pre-commit workflow step* was never shipped.

**Root cause:** missing skill + partial hook coverage + missing project-local steering.

- The numeric-drift class of bug is covered by `doc-consistency.sh` IF it gets wired into post-implementation (one-line fix, separate improvement).
- The **structural-drift class** (missing matrix columns, missing diagram nodes, missing policy table rows, missing skill category headings, incomplete CHANGELOG entries) is not covered by any existing mechanism. This class needs LLM judgment, not regex.

**Proposed feature: `doc-audit` skill with grouped specialist agents**

A new global skill, triggered after any session that creates/deletes artifacts in tracked categories (or on-demand). Rough shape:

1. **Inventory changed files** — the skill reads `git status` or the session's modification set. If no files changed in tracked categories (`agents/`, `skills/`, `hooks/`, `steering/`), skip entirely.
2. **Discover docs** — heuristic scan (primary): all `*.md` under `docs/`, plus `README.md`, plus any `CHANGELOG.md`. Project-local steering (optional enhancement) overrides with a curated list — see below.
3. **Dispatch 3 grouped specialist subagents**, one per cognitive task:
   - **Structural/tabular agent** — architecture diagrams, ASCII trees, assignment matrices, policy tables, directory/structure listings. (Parsing grids and trees.)
   - **Prose/content agent** — category headings, deny-list mentions in security-model, migration notes, agent-list enumerations in prose. (Reading meaning, not structure.)
   - **Metadata/numeric agent** — counts and totals (wraps/extends `doc-consistency.sh`), skill-baseline counts in `agent-audit/SKILL.md`, CHANGELOG completeness (cross-reference delivered artifacts against vN.N.N entry).
4. **Consolidate findings** — each specialist reports structured output (file, line, what's stale, suggested fix). Orchestrator aggregates.
5. **Dispatch devops-docs** to apply the consolidated fix list, or present to user.

**Why 3 groups, not 7 (and not 1).** Converged view after audit↔Kiro critique: parsing an ASCII tree, validating a markdown matrix, and cross-referencing a CHANGELOG against delivered files are *different cognitive tasks* — a single reviewer holding all 11 drift categories in one context window will suffer context fatigue (later checks get shallow). But 7 parallel dispatches is cost-excessive when many categories share a cognitive mode. 3 grouped specialists preserve separate contexts per task-type while keeping dispatch count reasonable.

**Simpler v1 option.** If cost dominates on first ship, start with **1 reviewer + structured checklist** covering all 11 drift categories. Expect ~60-70% coverage (will miss later-in-context items). Upgrade to 3 specialists if coverage proves insufficient. Not recommended as the target design, but viable as a time-to-ship compromise.

**Cross-project portability — heuristic primary, steering optional**

Different projects have different doc structures. `~/personal/kiro-config` enumerates in README/skill-catalog/creating-agents; `~/eam/eam-sre/rommel-porras` (SRE tools) would enumerate in runbooks, service catalogs, ADRs. The global skill shouldn't hardcode paths.

**Primary mode — heuristic (zero config):** scan all `*.md` under `docs/`, plus `README.md`, plus any `CHANGELOG.md`. LLM-based pass; works out of the box in any project. Coverage is "adequate for small/well-structured repos, partial for complex multi-artifact repos."

**Enhancement mode — project steering (optional):** `.kiro/steering/docs-structure.md` describes:
- Which doc files exist in this project (overrides the heuristic scan set)
- Which categories each doc enumerates (e.g., "README.md: architecture diagram, counts {agents, skills, hooks, steering}, structure tree, skill matrix, policy table")
- Stale-pattern regex hints for numeric checks (hands to `doc-consistency.sh`)
- Example "what a complete CHANGELOG entry looks like for this project"

The skill reads this steering when present to focus/tighten its audit. Adoption friction should be low — skill works zero-config; steering is only needed when heuristic mode underperforms. First-run UX: after a heuristic audit, skill offers to generate a starter `docs-structure.md` based on what it found.

**Why heuristic-first:** requiring steering before the skill works is a bootstrap barrier that prevents cross-project adoption. A skill that works out-of-the-box in any new project (degraded quality) is more valuable than one that requires setup (better quality, zero adoption).

**Drift categories the skill should handle (comprehensive list)**

| Category | Example | Detectable how |
|---|---|---|
| Numeric counts | "18 skills" | Regex (existing `doc-consistency.sh`) |
| Architecture diagrams | Tree with agent names | LLM — parse tree, check new agents present |
| Assignment matrices | Skill-to-agent matrix | LLM — check columns/rows present |
| Policy tables | Infrastructure Read-Only Policy | LLM — check row coverage |
| Category headings | New skill needs new section | LLM — reason about taxonomy |
| File/structure trees | README dir listing | Regex + LLM |
| CHANGELOG completeness | vN.N.N entry vs actual deliverables | LLM — cross-reference |
| Version/migration notes | Breaking change migration text | LLM |
| Skill metadata | `agent-audit/SKILL.md` baseline | Regex + LLM |
| Agent deny-list mentions | security-model agent enumerations | LLM |
| Example/sample docs | Sample JSON config with old names | Regex + LLM |

**Design decisions (pinned after audit↔Kiro critique)**

- **Trigger gating:** fire from `post-implementation` Step 3, gated on `git status` showing changed files in `agents/`, `skills/`, `hooks/`, or `steering/`. No tracked-category changes → skip entirely. Avoids over-triggering on pure code sessions; catches every structural addition.
- **Integration point:** `post-implementation` Step 3, as a structural safety net for the class of drift that Step 3's existing "modified file references" check doesn't catch. On-demand invocation also supported ("audit my docs" trigger phrase) for retroactive sweeps.
- **Bootstrap UX:** heuristic-first (see above). First-run offers to generate a starter `docs-structure.md`.

**Open design questions (still TBD when Tier 2 is specced)**

- **False-positive handling:** LLM-based analysis will sometimes flag "missing updates" that aren't actually stale. Options: review loop (dispatch devops-reviewer on the audit findings before applying), confidence scoring per finding (high/medium/low), or let devops-docs judge at application time. Pick one during brainstorm.
- **CHANGELOG staleness vs commit-time alternative:** one alternative considered during critique was "generate CHANGELOG draft from `git diff main..HEAD` at commit time, skip the doc-audit CHANGELOG check." Rejected for two reasons: (1) user's workflow is no-auto-commit with manual VS Code review, so commit-time checks fire *after* the human has already reviewed — redundant; (2) a CHANGELOG entry is narrative (WHAT + WHY from spec intent), not a file list from diffs — a diff can't produce "Renamed dev-* to devops-* to reflect DevOps Consultant team role." CHANGELOG completeness belongs in doc-audit's metadata/numeric specialist.
- **Cost cap:** even the 3-specialist design wants a budget per run. Propose: skip structural/tabular specialist if no new files in tracked categories (same gate as overall trigger). Skip prose/content if no security-model or migration-adjacent files touched. Always run metadata/numeric (cheap, catches counts).
- **Self-audit:** when doc-audit itself ships, its own SKILL.md needs a skill-catalog entry, creating-agents mention, and CHANGELOG note. Eat the dogfood.

**Related prior work to reference when designing**

- `docs/audit/audit-current-workflow.md:720-729` — diagnoses the hook-wire-up gap and proposes the interim fix
- `docs/audit/audit-triage-v0.5.1.md` M-03 and M-13 — history of partial fixes to doc-consistency
- `skills/agent-audit/SKILL.md` — existing structural audit skill; `doc-audit` should pattern-match its shape
- `skills/codebase-audit/SKILL.md` — also a structural audit skill, may share specialist-dispatch infrastructure
- `hooks/doc-consistency.sh` — existing numeric-drift hook; `doc-audit` should call it, not replace it

**Suggested fix — defense-in-depth, four layers (not tiered priorities)**

These are layers, not alternatives. Each catches a different class of drift. Dropping any layer weakens the system.

- **Tier 0 (prevention at design time, prompt change).** Add to `skills/design-and-spec` skill's convergence phase: "Before writing spec, list which existing docs enumerate the artifact category being added (agents, skills, hooks, steering). Include those docs in the spec's 'Files to Update' section." Prompt-level defense — cheap, preventive, but weakest layer (prompts drift under context load). Not a substitute for structural layers; additive defense.
- **Tier 1 (structural numeric check at post-implementation, zero new skill).** Wire `bash ~/.kiro/hooks/doc-consistency.sh` into `skills/post-implementation/SKILL.md` Step 3. Extend `doc-consistency.sh` to check steering counts (closes M-13 fully — currently "PARTIAL" in `audit-triage-v0.5.1.md`). Ship with v0.7.0 or v0.7.1. Solves numeric drift structurally; does not solve structural drift.
- **Tier 2 (structural LLM audit at post-implementation, new skill).** `doc-audit` skill with 3 grouped specialists (structural/tabular, prose/content, metadata/numeric) + optional `.kiro/steering/docs-structure.md` per-project override. Triggered from post-implementation Step 3 when tracked-category files change. New spec required — brainstorm → spec → plan → implement → validate across kiro-config + eam-sre.
- **Tier 3 (final check before merge, Audit Agent).** The human-side Audit Agent reviews PRs with doc-ripple in mind (see `memory/feedback_audit_doc_ripple.md`). Final safety net; catches what the automated layers miss.

Do not bundle Tier 2 into the v0.7.0 branch — scope creep on an already-reviewed feature. Keep Tier 2 as its own spec → plan → implementation cycle.

**Why not just Tier 0?** Prompts drift. The same reason we built the hook-enforced preflight gate for `devops-terraform` instead of relying on prompt discipline (see `feedback_safety_enforcement.md`). Tier 0 catches the spec author's first-pass attention; Tier 1/2 catch the drift Tier 0 missed.

**Budget estimate (post-critique, honest)**

- **Tier 0:** 15-30 minutes (prompt addition to `design-and-spec` SKILL.md)
- **Tier 1:** ~2 hours (wire-up in post-implementation + steering count extension in `doc-consistency.sh` + test)
- **Tier 2 (1-reviewer v1):** 4-6 days (trigger logic, heuristic discovery, structured reviewer prompt, output format, devops-docs handoff, test in kiro-config + eam-sre, self-referential doc updates, false-positive handling)
- **Tier 2 (3-specialist target):** 7-10 days (adds parallel dispatch, consolidation, cost-gating logic, per-specialist prompt design)
- **Tier 3:** ongoing per-audit, no discrete budget

Earlier estimates (1-2 weeks for Tier 2, 2-3 days from Kiro critique) were both off — first too padded, second too optimistic. 4-10 days depending on v1 scope is honest.
