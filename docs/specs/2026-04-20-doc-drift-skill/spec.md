# Spec: doc-drift skill

**Status:** COMPLETE (2026-04-20)
**Created:** 2026-04-20
**Scope:** Global skill + integration into post-implementation + design-and-spec + doc-consistency.sh extension

## Problem

When new artifacts are added to tracked categories (agents, skills, hooks, steering), existing documentation that enumerates those categories goes stale silently. Three existing defense layers all have gaps:

1. **design-and-spec** — no prompt requiring ripple-task enumeration for docs that list artifact categories
2. **post-implementation Step 3** — greps for references to *modified* files; newly *created* files aren't referenced by existing docs, so numeric/structural drift is invisible
3. **doc-consistency.sh** — catches numeric drift but only runs at commit time (too late in manual-review workflow), doesn't check steering counts, and can't detect structural drift (missing matrix columns, diagram nodes, table rows)

Evidence: v0.7.0 added `devops-terraform` — 7 docs went stale across counts, matrices, diagrams, and policy tables. All caught manually.

## Solution

A 4-layer defense-in-depth approach:

- **Tier 0** — Prompt addition to `design-and-spec` (prevention at spec time)
- **Tier 1** — Wire `doc-consistency.sh` into post-implementation + extend with steering count
- **Tier 2** — New `doc-drift` skill with 3 parallel specialist reviewers
- **Tier 3** — Human review (existing, no deliverable)

## Tier 0: design-and-spec ripple awareness

Add to the convergence checklist in `skills/design-and-spec/SKILL.md` (step within convergence, not a precondition):

> As part of writing the spec, list which existing docs enumerate the artifact category being added (agents, skills, hooks, steering). Include those docs in the spec's "Files to Update" section.

## Tier 1: doc-consistency.sh improvements

1. Wire `bash ~/.kiro/hooks/doc-consistency.sh` into `skills/post-implementation/SKILL.md` Step 3
2. Extend `doc-consistency.sh` to count steering files and check against docs (closes M-13)

## Tier 2: doc-drift skill

### Overview

Global skill at `~/.kiro/skills/doc-drift/SKILL.md`. Detects documentation drift after structural changes and dispatches fixes.

### Triggers

- **Auto:** post-implementation Step 3, gated on `git status` showing created/deleted files in tracked categories. Tracked categories are defined in `docs-structure.md`. When no steering file exists, auto-trigger is DISABLED — only on-demand works. This incentivizes generating `docs-structure.md` on first run.
- **Manual:** "check my docs", "audit docs", "doc drift", "check doc drift"

The orchestrator's routing table: add "doc drift, check my docs, audit docs" to the existing "Handle directly (DO NOT delegate)" triggers line. The orchestrator runs the skill itself (which internally dispatches reviewers + devops-docs).

### Discovery — where to look

Lookup order for steering file:

1. `${CWD}/.kiro/steering/docs-structure.md` (project-local — this is the standard location)
2. If not found → heuristic mode (scan all `*.md` under `docs/`, `README.md`, `CHANGELOG.md`)

When steering file exists:
- **Targeted pass** — check every doc in the enumeration table against its declared types
- **Discovery pass** — scan remaining `*.md` not in the table; flag any that reference 3+ items from a tracked category; suggest adding to `docs-structure.md` (always suggest-only, never auto-update)

When steering file does not exist:
- Full heuristic scan on all `*.md` (use filesystem state as ground truth, not git diff)
- After completing, offer to generate `docs-structure.md`: "For more precise doc-drift detection in this project, I can generate a `.kiro/steering/docs-structure.md` based on what I found. Want me to create it?"

On-demand mode always runs regardless of git status — the user explicitly asked for a check.

### docs-structure.md format

```markdown
# Doc Structure — <project name>

## Tracked categories
- `agents/` — agent JSON configs
- `skills/` — skill definitions
- `hooks/` — hook scripts
- `steering/` — steering docs

## Enumeration docs
| Doc file | What it enumerates |
|---|---|
| README.md | architecture diagram, feature counts, structure tree, skill matrix, policy table |
| docs/reference/skill-catalog.md | skill list, assignment matrix, design philosophy table |
| docs/reference/security-model.md | agent deny-list mentions |
| ... | ... |

## Discovery
Scan all *.md files not listed above for potential enumerations.
Flag any unlisted doc that references 3+ items from a tracked category.
If found, suggest adding it to this file.
```

### Detection — 3 parallel specialist reviewers

Dispatch 3 `devops-reviewer` instances in parallel, each with a different cognitive focus:

| Specialist | Focus | Example drift |
|---|---|---|
| Structural/tabular | ASCII trees, matrices, policy tables, directory listings | Missing column in skill matrix, missing node in architecture diagram |
| Prose/content | Category headings, deny-list mentions, agent enumerations in prose | security-model missing agent in deny-list, missing skill category heading |
| Metadata/numeric | Counts, CHANGELOG completeness, baselines, version refs | "18 skills" when actual is 19, incomplete CHANGELOG entry |

Each specialist receives:
- List of changed files (what was added/removed)
- Its assigned subset of docs from `docs-structure.md` (or full list in heuristic mode)
- Its cognitive focus description
- The current filesystem state for verification

Each specialist outputs structured findings:
```
- file: <path>
- line: <number or range>
- category: <structural|prose|numeric>
- what's stale: <description>
- suggested fix: <concrete change>
- confidence: <high|medium|low>
```

### Remediation — parallel devops-docs instances

After consolidating findings from all 3 specialists:

1. Group findings by file
2. Classify each finding:
   - **Auto-fix** (no approval needed): numeric count updates, matrix row/column additions, tree node additions, table row additions
   - **Present for approval**: prose rewrites, architecture diagram overhauls, CHANGELOG narrative
3. Dispatch devops-docs instances in parallel — one per file (prevents merge conflicts)
4. Doc-drift does NOT run its own sanity check after fixes — post-implementation Step 4 (auto-review) already covers verification of all changes including doc-drift's fixes. No double-review.

### Failure handling

- devops-docs gets one attempt per finding
- If post-implementation Step 4 (auto-review) flags a doc-drift fix as problematic: the normal Step 5 flow handles it (CRITICAL → retry, IMPORTANT → present to user)
- This avoids a separate retry loop inside doc-drift itself

### Run stats logging

After each execution, append to `~/.kiro/logs/doc-drift.md`:

```markdown
## YYYY-MM-DD — <project path>

- Trigger: <post-implementation | on-demand>
- Changed files: <list of files that triggered the run>
- Structural specialist: N findings (brief list)
- Prose specialist: N findings (brief list)
- Numeric specialist: N findings (brief list)
- Auto-fixed: N/total
- Flagged for user: N (reasons)
- False positives: N (user-dismissed findings + reviewer-rejected fixes)
```

**False positive counting:** A finding is a false positive when:
- The user explicitly dismisses it ("that's intentional", "not stale")
- Post-implementation Step 4 reviewer rejects the applied fix

This log is NOT committed to any repo. Lives at `~/.kiro/logs/doc-drift.md` to avoid leaking project structure into git. The skill creates `~/.kiro/logs/` on first run if it doesn't exist (`mkdir -p`).

### Self-audit checkpoint

At 1-3 months after deployment, review `~/.kiro/logs/doc-drift.md`:
- Any specialist consistently finding 0 issues? → Consider removing
- Any specialist with high false-positive rate? → Refine its prompt or remove
- Are 2 specialists finding the same things? → Merge them

Decision: reduce specialist count only with evidence from the log.

## Drift categories covered

| Category | Specialist | Detection method |
|---|---|---|
| Numeric counts | Metadata/numeric | Regex (`doc-consistency.sh`) + LLM |
| Architecture diagrams | Structural/tabular | LLM — parse tree, check nodes |
| Assignment matrices | Structural/tabular | LLM — check columns/rows |
| Policy tables | Structural/tabular | LLM — check row coverage |
| Directory/structure trees | Structural/tabular | LLM + filesystem comparison |
| Category headings | Prose/content | LLM — reason about taxonomy |
| Agent deny-list mentions | Prose/content | LLM — check agent coverage |
| CHANGELOG completeness | Metadata/numeric | LLM — cross-reference deliverables |
| Skill metadata/baselines | Metadata/numeric | LLM + regex |
| Version/migration notes | Prose/content | LLM |
| Example/sample docs | Structural/tabular | Regex + LLM |

## Files to create

- `skills/doc-drift/SKILL.md` — skill definition with full workflow
- `.kiro/steering/docs-structure.md` — kiro-config's own enumeration steering file (eat the dogfood, project-local)

## Files to modify

- `skills/post-implementation/SKILL.md` — add doc-drift trigger gate to Step 3, wire `doc-consistency.sh`
- `skills/design-and-spec/SKILL.md` — add ripple-awareness to convergence checklist
- `hooks/doc-consistency.sh` — add steering file count check
- `agents/devops-orchestrator.json` — add `skill://~/.kiro/skills/doc-drift/SKILL.md` to resources
- `agents/prompts/orchestrator.md` — add doc-drift triggers to "Handle directly (DO NOT delegate)" line
- `docs/reference/skill-catalog.md` — add doc-drift entry
- `README.md` — update skill count, add to skill matrix, add to structure tree
- `docs/TODO.md` — add this spec as active
- `docs/improvements/pending.md` — move existing doc-audit proposal to resolved.md (superseded by this spec)

## Existing docs that enumerate the artifact categories being extended

Per Tier 0 ripple-awareness (eating our own dogfood):
- `README.md` — skill count, skill matrix, structure tree
- `docs/reference/skill-catalog.md` — skill list, assignment matrix
- `docs/setup/kiro-cli-install-checklist.md` — skill counts, steering counts
- `skills/agent-audit/SKILL.md` — baseline counts (skills AND steering)
- `docs/setup/team-onboarding.md` — skill counts

## Testing strategy

### Skill collision test (pre-implementation)

Before building, verify Kiro's behavior with same-name skills at global vs project-local paths:
1. Create `~/.kiro/skills/test-collision/SKILL.md` (says "GLOBAL fired")
2. Create `.kiro/skills/test-collision/SKILL.md` (says "PROJECT-LOCAL fired")
3. Add global reference to orchestrator resources
4. New session → trigger → observe which fires
5. Clean up

### Functional tests

1. **Numeric drift:** Manually change a count in README.md, run doc-drift on-demand, verify it detects and fixes
2. **Structural drift:** Remove a matrix column, run doc-drift, verify detection
3. **Heuristic mode:** Remove `docs-structure.md`, run doc-drift, verify it still finds issues and offers to generate the steering file
4. **Cross-project:** Run in a project without `docs-structure.md`, verify heuristic mode works
5. **No-op run:** Run when nothing changed in tracked categories, verify it skips cleanly
6. **Auto-fix vs approval:** Verify numeric fixes auto-apply, prose changes get presented

## Non-goals

- Checking doc *quality* (grammar, clarity, completeness of explanations) — that's a different concern
- Replacing `doc-consistency.sh` — the hook continues to exist for fast numeric checks; doc-drift wraps/extends it
- Enforcing doc structure or style — only checks factual accuracy of enumerations

## Decisions made (from brainstorm session)

- **Name:** `doc-drift` (not doc-audit — "drift" captures the root cause better)
- **Trigger mode:** Option C — both auto post-implementation and on-demand. Auto-trigger requires `docs-structure.md` to exist (defines what to watch). First on-demand run offers to generate it, enabling auto-trigger for subsequent sessions.
- **Discovery:** steering file if present, heuristic fallback if not. Discovery pass is MANDATORY — always reports whether new enumeration docs were found.
- **Specialist count:** 3 from day one, evaluate reduction at 1-3 months with log data. Parallel dispatch is not optional — must be 3 separate instances with labeled output.
- **Findings handling:** auto-fix numeric/structural, present prose/diagram for approval
- **docs-structure.md location:** project-local at `.kiro/steering/docs-structure.md` (NOT global `steering/` — global steering loads into every session, wrong for project-specific data)
- **docs-structure.md updates:** always suggest-only, never auto-update
- **Log location:** `~/.kiro/logs/doc-drift.md` (not committed to any repo). Enhanced format includes: steering path used, docs checked count, discovery pass results, drift age.
- **Sanity check:** auto mode delegates to post-implementation Step 4. On-demand mode runs `doc-consistency.sh` after fixes (since post-impl doesn't fire).
- **Skill collision:** tested — global skill with explicit `skill://` reference wins over project-local with same name. No error, no dual-fire.

## Dependency

- Tier 0 and Tier 1 have no dependencies — can ship immediately
- Tier 2 depends on Tier 1 (doc-consistency.sh extension) being in place so the metadata/numeric specialist can call it
- Skill collision test should run before Tier 2 implementation begins
