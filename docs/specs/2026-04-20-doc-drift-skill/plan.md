# doc-drift Implementation Plan

> **For agentic workers:** Use the subagent-driven-development skill to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Ship a 4-tier defense-in-depth system that ensures documentation stays in sync with structural changes across any project.

**Architecture:** Tier 0 (prompt addition) and Tier 1 (hook wire-up + extension) are quick config changes. Tier 2 is a new global skill that dispatches 3 parallel reviewer specialists to detect drift, then parallel devops-docs instances to fix it. The skill adapts per-project via an optional `docs-structure.md` steering file.

**Tech Stack:** Bash (hook extension), Markdown (skill definition, steering file), JSON (agent config)

---

## Phase 1: Tier 0 + Tier 1 (no dependencies, ship immediately)

### Task 1: Add ripple-awareness to design-and-spec

**Files:**
- Modify: `skills/design-and-spec/SKILL.md`

- [x] **Step 1: Add ripple-awareness step to convergence section**

In the "Convergence (both modes)" section, insert before step 1 ("Write spec to..."):

```markdown
0. **Ripple check** — list which existing docs enumerate the artifact category being added (agents, skills, hooks, steering). Include those docs in the spec's "Files to Update" section. If unsure, grep `docs/` and `README.md` for artifact names from the category.
```

- [x] **Step 2: Verify the addition reads naturally in context**

Read the full Convergence section to confirm the new step flows logically before "Write spec."

- [x] **Step 3: Report completion**

### Task 2: Extend doc-consistency.sh with steering count

**Files:**
- Modify: `hooks/doc-consistency.sh`

- [x] **Step 1: Add steering count variable**

After the `hooks=` line (line 9), add:

```bash
steering=$(find "${KIRO_CONFIG_DIR}/steering" -name '*.md' | wc -l | tr -d ' ')
```

- [x] **Step 2: Add steering count check against README**

After the existing hooks check (line 71, `check "README.md" ... hooks`), add:

```bash
# README.md — **NN steering docs**
check "README.md" '\*\*\d+ steering docs\*\*' "${steering}" "steering docs"
```

- [x] **Step 3: Update the success message to include steering count**

Change the final echo to:
```bash
echo "Doc consistency: all counts match (${total} skills, ${base} base, ${agents} agents, ${hooks} hooks, ${steering} steering)"
```

- [x] **Step 4: Run the hook to verify it passes**

Run: `bash hooks/doc-consistency.sh`
Expected: may report DRIFT on README.md structure tree comment (line 77 says "11 persistent context docs" but actual is 12). This is a pre-existing bug — will be fixed in Task 8 Step 2 along with the 12→13 update for the new `docs-structure.md` file.

- [x] **Step 5: Report completion**

### Task 3: Wire doc-consistency.sh into post-implementation Step 3

**Files:**
- Modify: `skills/post-implementation/SKILL.md`

- [x] **Step 1: Add doc-consistency.sh invocation to Step 3**

After the existing "Metrics staleness" paragraph in Step 3, add:

```markdown
- **Numeric drift check:** Run `bash ~/.kiro/hooks/doc-consistency.sh`. If it reports DRIFT, flag the drifted files for update (dispatch devops-docs or include in doc-drift findings if the skill is active).
```

- [x] **Step 2: Verify Step 3 reads coherently with the addition**

Read full Step 3 to confirm logical flow: file-reference check → metrics staleness → numeric drift check.

- [x] **Step 3: Report completion**

---

## Phase 2: Tier 2 — doc-drift skill + steering file (depends on Phase 1)

### Task 4: Create steering/docs-structure.md for kiro-config

**Files:**
- Create: `steering/docs-structure.md`

- [x] **Step 1: Write the kiro-config docs-structure steering file**

```markdown
# Doc Structure — kiro-config

## Tracked categories
- `agents/` — agent JSON configs
- `skills/` — skill definitions
- `hooks/` — hook scripts
- `steering/` — steering docs

## Enumeration docs
| Doc file | What it enumerates |
|---|---|
| README.md | architecture diagram, feature counts, structure tree, skill matrix, policy table |
| docs/reference/skill-catalog.md | skill list, assignment matrix, design philosophy table, base-agent skill count |
| docs/reference/creating-agents.md | architecture diagram |
| docs/reference/security-model.md | agent deny-list mentions, Infrastructure Read-Only Policy table |
| docs/setup/team-onboarding.md | architecture diagram, counts |
| docs/setup/kiro-cli-install-checklist.md | global/available skill counts |
| docs/reference/CHANGELOG.md | delivered artifacts per version |
| skills/agent-audit/SKILL.md | baseline counts (agents, skills, steering, hooks) |

## Discovery
Scan all *.md files not listed above for potential enumerations.
Flag any unlisted doc that references 3+ items from a tracked category.
If found, suggest adding it to this file.
```

- [x] **Step 2: Verify all listed docs exist on disk**

Run: check each path in the table exists.

- [x] **Step 3: Report completion**

### Task 5: Create skills/doc-drift/SKILL.md

**Files:**
- Create: `skills/doc-drift/SKILL.md`

- [x] **Step 1: Write the skill definition**

```markdown
---
name: doc-drift
description: Detects documentation drift after structural changes. Dispatches parallel specialist reviewers and auto-fixes. Triggers on "check my docs", "audit docs", "doc drift", "check doc drift", or auto from post-implementation when tracked categories change.
---

# Doc Drift

Detect and fix documentation that has drifted from the current state of the codebase.

**Announce at start:** "Running doc-drift detection."

## Trigger Gate (auto mode)

When triggered from post-implementation Step 3:

1. Run `git status --porcelain` to get changed files
2. Read `docs-structure.md` (lookup order: `${CWD}/.kiro/steering/docs-structure.md` → `steering/docs-structure.md`)
3. If no `docs-structure.md` found → SKIP auto mode. Log: "No docs-structure.md found — auto-trigger disabled. Run doc-drift on-demand to generate one."
4. Check if any changed files are in tracked categories (from docs-structure.md)
5. If no tracked-category changes → SKIP. Log: "No tracked-category changes detected."
6. If tracked-category changes found → proceed to Detection phase

## On-Demand Mode

When triggered manually ("check my docs", "audit docs", "doc drift"):

1. Skip the git status gate — always proceed regardless of whether files have changed. The user explicitly asked for a check.
2. Read `docs-structure.md` (same lookup order)
3. If found → proceed to Detection phase with targeted + discovery passes
4. If NOT found → proceed to Detection phase with full heuristic scan (use filesystem state as ground truth)
5. After completing, if no `docs-structure.md` exists, offer: "For more precise doc-drift detection in this project, I can generate a `.kiro/steering/docs-structure.md` based on what I found. Want me to create it?"

## Detection Phase — 3 Parallel Specialists

Dispatch 3 `devops-reviewer` instances in parallel:

### Specialist 1: Structural/Tabular

**Briefing:** "Review these docs for structural completeness. Focus ONLY on: ASCII architecture diagrams, assignment matrices, policy tables, directory/structure trees. For each, verify all current artifacts from [tracked categories] are represented. Report missing entries."

**Receives:**
- List of changed files (added/removed)
- Docs assigned: those with enumeration types matching structural patterns
- Current filesystem listing of tracked category directories

### Specialist 2: Prose/Content

**Briefing:** "Review these docs for prose accuracy. Focus ONLY on: category headings that should list new items, deny-list mentions that should include new agents, agent/skill enumerations in running text, version/migration notes. Report stale prose."

**Receives:**
- List of changed files (added/removed)
- Docs assigned: those with enumeration types matching prose patterns
- Names and descriptions of new/removed artifacts

### Specialist 3: Metadata/Numeric

**Briefing:** "Review these docs for numeric accuracy. Focus ONLY on: artifact counts and totals, CHANGELOG completeness (cross-reference delivered artifacts against version entry), skill/agent baseline counts, version references. Also run `bash ~/.kiro/hooks/doc-consistency.sh` and include its output."

**Receives:**
- List of changed files (added/removed)
- Docs assigned: those with enumeration types matching numeric patterns
- Output of `doc-consistency.sh`
- Current actual counts from filesystem

### Specialist Output Format

Each specialist returns structured findings:
```
- file: <path>
- line: <number or range>
- category: <structural|prose|numeric>
- what's stale: <description>
- suggested fix: <concrete change>
- confidence: <high|medium|low>
```

## Discovery Pass (runs after targeted pass)

If `docs-structure.md` exists, scan remaining `*.md` files not in the enumeration table:
- Flag any that reference 3+ items from a tracked category
- Report: "Discovered potential enumeration doc: <path> — references [list]. Consider adding to docs-structure.md."
- Never auto-update docs-structure.md — suggest only

## Consolidation Phase

After all 3 specialists return:

1. Merge findings, deduplicate (same file + same line = keep highest confidence)
2. Group findings by file
3. Classify each finding:
   - **Auto-fix:** numeric count updates, matrix row/column additions, tree node additions, table row additions
   - **Present for approval:** prose rewrites, architecture diagram overhauls, CHANGELOG narrative

## Remediation Phase

For auto-fix findings:
1. Dispatch devops-docs instances in parallel — one per file (prevents merge conflicts)
2. Each devops-docs instance receives: the file path + all findings for that file + suggested fixes
3. Do NOT run a separate sanity check — post-implementation Step 4 (auto-review) handles verification

For present-for-approval findings:
1. Show to user with file, line, what's stale, and suggested fix
2. User approves/dismisses each
3. Approved items → dispatch devops-docs (same parallel-by-file pattern)
4. Dismissed items → count as false positives in log

## Run Stats Logging

After execution completes, create `~/.kiro/logs/` if it doesn't exist (`mkdir -p ~/.kiro/logs`), then append to `~/.kiro/logs/doc-drift.md`:

```markdown
## YYYY-MM-DD — <project path>

- Trigger: <post-implementation | on-demand>
- Changed files: <list>
- Structural specialist: N findings (brief list)
- Prose specialist: N findings (brief list)
- Numeric specialist: N findings (brief list)
- Auto-fixed: N/total
- Flagged for user: N (reasons)
- False positives: N (user-dismissed + reviewer-rejected)
```

## Self-Audit Checkpoint

At 1-3 months after deployment, review `~/.kiro/logs/doc-drift.md`:
- Specialist consistently finding 0 issues → consider removing
- Specialist with high false-positive rate → refine prompt or remove
- Two specialists finding same things → merge them

Reduce specialist count only with evidence from the log.
```

- [x] **Step 2: Review the skill for internal consistency**

Verify: trigger gate logic, discovery lookup order, specialist briefings, output format, remediation flow, and logging all align with the spec.

- [x] **Step 3: Report completion**

### Task 6: Add doc-drift to orchestrator config

**Files:**
- Modify: `agents/devops-orchestrator.json`
- Modify: `agents/prompts/orchestrator.md`

- [x] **Step 1: Add skill resource to orchestrator JSON**

Add to the `resources` array in `agents/devops-orchestrator.json`:
```json
"skill://~/.kiro/skills/doc-drift/SKILL.md"
```

- [x] **Step 2: Add triggers to orchestrator routing table**

In `agents/prompts/orchestrator.md`, find the line:
```
Triggers: explain, what is, how does, should I, compare, plan, design, brainstorm,
spec out, define requirements, commit, push, agent-audit, trace, map code flow,
health check, codebase audit, restructure repo, create context docs, set up AI knowledge base, execution plan
```

Add `doc drift, check my docs, audit docs` to this list.

- [x] **Step 3: Verify JSON is valid**

Run: `jq . agents/devops-orchestrator.json > /dev/null`
Expected: exit 0

- [x] **Step 4: Report completion**

### Task 7: Add doc-drift trigger to post-implementation Step 3

**Files:**
- Modify: `skills/post-implementation/SKILL.md`

- [x] **Step 1: Add doc-drift trigger gate after the numeric drift check (added in Task 3)**

After the "Numeric drift check" paragraph, add:

```markdown
- **Doc-drift detection:** If `git status --porcelain` shows created or deleted files, invoke the doc-drift skill (auto mode). The skill checks whether changes are in tracked categories and runs detection if so. If no `docs-structure.md` exists in the project, skip — doc-drift auto mode requires it.
```

- [x] **Step 2: Verify Step 3 flow is coherent**

Read full Step 3: file-reference check → metrics staleness → numeric drift check → doc-drift detection.

- [x] **Step 3: Report completion**

---

## Phase 3: Documentation updates (depends on Phase 2)

### Task 8: Update skill-catalog, README, TODO, pending.md

**Files:**
- Modify: `docs/reference/skill-catalog.md`
- Modify: `README.md`
- Modify: `docs/TODO.md`
- Modify: `docs/improvements/pending.md`
- Modify: `docs/improvements/resolved.md`
- Modify: `docs/setup/kiro-cli-install-checklist.md`
- Modify: `skills/agent-audit/SKILL.md`

- [x] **Step 1: Add doc-drift entry to skill-catalog.md**

Add a row to the skill table and update the assignment matrix with doc-drift (orchestrator-only).

- [x] **Step 2: Update README.md**

- Update skill count (19 → 20)
- Update steering count (12 → 13, for new `docs-structure.md`)
- Fix structure tree comment on line 77: `# 11 persistent context docs` → `# 13 persistent context docs` (pre-existing drift at 11, now 13 with new file)
- Add `doc-drift` to skill matrix (orchestrator column only)
- Add `skills/doc-drift/` to structure tree
- Add `steering/docs-structure.md` to structure tree

- [x] **Step 3: Update docs/TODO.md**

Add under Active Specs:
```markdown
- [x] **Spec: doc-drift skill** — `docs/specs/2026-04-20-doc-drift-skill/spec.md`
  - Tier 0: design-and-spec ripple awareness
  - Tier 1: doc-consistency.sh steering count + post-implementation wire-up
  - Tier 2: doc-drift skill with 3 parallel specialists
  - steering/docs-structure.md for kiro-config
```

- [x] **Step 4: Move pending.md proposal to resolved.md**

DELETE the entire "doc-audit skill" entry from `docs/improvements/pending.md` (everything from the `## 2026-04-19` header through the end of that entry). APPEND to `docs/improvements/resolved.md`:

```markdown
## 2026-04-20 — doc-audit proposal superseded by doc-drift skill
- Original: Feature proposal for `doc-audit` skill with parallel specialist agents
- Fix: Superseded by `docs/specs/2026-04-20-doc-drift-skill/spec.md` — implemented as `doc-drift` skill with 3 parallel specialists, auto/on-demand trigger, and `docs-structure.md` steering.
```

- [x] **Step 5: Update kiro-cli-install-checklist.md skill counts**

Update global/available skill counts (19 → 20).

- [x] **Step 6: Update agent-audit baseline counts**

Update the baseline in `skills/agent-audit/SKILL.md` line 130 from v0.7.0 counts to reflect changes: 12→13 steering docs, 19→20 skills. New baseline: "13 steering docs, 20 skills, 11 hooks, 11 agents."

- [x] **Step 7: Run doc-consistency.sh to verify all counts are correct**

Run: `bash hooks/doc-consistency.sh`
Expected: all counts match

- [x] **Step 8: Report completion**

---

## Phase 4: Verification (depends on Phase 3)

> **Note:** Phase 3 MUST complete before Phase 4. Task 4 creates `steering/docs-structure.md` (steering count 12→13) and Task 8 updates all doc counts. Phase 4's `doc-consistency.sh` run will fail if counts aren't updated first.

### Task 9: End-to-end verification

- [x] **Step 1: Run doc-consistency.sh**

Run: `bash hooks/doc-consistency.sh`
Expected: exit 0, all counts match

- [x] **Step 2: Verify all files referenced in spec exist**

Check every path in "Files to create" and "Files to modify" exists and has the expected content.

- [x] **Step 3: Verify orchestrator JSON is valid**

Run: `jq . agents/devops-orchestrator.json > /dev/null`
Expected: exit 0

- [x] **Step 4: Verify skill frontmatter is parseable**

Check that `skills/doc-drift/SKILL.md` has valid YAML frontmatter with `name` and `description`.

- [x] **Step 5: Shellcheck the modified hook**

Run: `shellcheck hooks/doc-consistency.sh`
Expected: zero warnings

- [x] **Step 6: Report completion**

---

## Post-Plan Implementation Notes

Changes made after the initial plan was executed, based on testing and review:

### docs-structure.md location correction
- **Original plan:** `steering/docs-structure.md` (global)
- **Actual:** `.kiro/steering/docs-structure.md` (project-local)
- **Reason:** Global steering loads into every session regardless of CWD. docs-structure.md is project-specific data — each project needs its own. Moved to project-local `.kiro/steering/` and reverted steering count from 13 back to 12.

### Skill definition reinforcements (post-testing)
- Discovery pass marked MANDATORY with dedicated output section format
- Parallel dispatch instruction strengthened: "This is not optional" — must be 3 separate instances
- Per-specialist labeled output sections required (### Structural Findings, etc.)
- On-demand verification added: runs `doc-consistency.sh` after fixes (post-impl Step 4 doesn't fire in on-demand mode)
- Run stats logging enhanced: added steering path, docs checked count, discovery pass results, drift age

### docs-structure.md expanded (from discovery pass)
- `docs/reference/audit-playbook.md` and `docs/setup/troubleshooting.md` added to enumeration table (discovered by doc-drift's own discovery pass — 10 docs now tracked)

### Additional drift caught by doc-drift during testing
- team-onboarding.md: 3 stale "19 skills" references
- kiro-cli-install-checklist.md: steering count 11→12 (missing terraform.md from v0.7.0)
- README.md + skill-catalog.md: TDD and systematic-debugging matrix rows had incorrect agent assignments
