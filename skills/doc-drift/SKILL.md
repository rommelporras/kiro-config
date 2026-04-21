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
2. Read `docs-structure.md` (location: `${CWD}/.kiro/steering/docs-structure.md`)
3. If no `docs-structure.md` found → SKIP auto mode. Log: "No docs-structure.md found — auto-trigger disabled. Run doc-drift on-demand to generate one."
4. Check if any changed files are in tracked categories (from docs-structure.md)
5. If no tracked-category changes → SKIP. Log: "No tracked-category changes detected."
6. If tracked-category changes found → proceed to Detection phase

## On-Demand Mode

When triggered manually ("check my docs", "audit docs", "doc drift"):

1. Skip the git status gate — always proceed regardless of whether files have changed. The user explicitly asked for a check.
2. Read `docs-structure.md` (location: `${CWD}/.kiro/steering/docs-structure.md`)
3. If found → proceed to Detection phase with targeted + discovery passes
4. If NOT found → proceed to Detection phase with full heuristic scan (use filesystem state as ground truth)
5. After completing, if no `docs-structure.md` exists, offer: "For more precise doc-drift detection in this project, I can generate a `.kiro/steering/docs-structure.md` based on what I found. Want me to create it?"

## Detection Phase — 3 Parallel Specialists

Dispatch 3 `devops-reviewer` instances in parallel. **This is not optional** — do not collapse into a single pass. Each specialist has a distinct cognitive focus that prevents context fatigue on large doc sets. Label each specialist's findings clearly in the output (e.g., "### Structural Findings", "### Prose Findings", "### Numeric Findings").

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

Each specialist returns structured findings, clearly labeled by specialist name:
```
### Structural Findings (or Prose Findings, or Numeric Findings)
- file: <path>
- line: <number or range>
- category: <structural|prose|numeric>
- what's stale: <description>
- suggested fix: <concrete change>
- confidence: <high|medium|low>
```

This labeling is required for the run stats log — per-specialist finding counts must be accurate.

## Discovery Pass (runs after targeted pass — MANDATORY)

If `docs-structure.md` exists, scan remaining `*.md` files not in the enumeration table:
- Flag any that reference 3+ items from a tracked category
- **Always include a dedicated "Steering File Updates" section at the end of the report** with:
  ```
  ## docs-structure.md Updates Suggested
  The following docs were found to enumerate tracked-category items but are NOT in your docs-structure.md:
  - <path> — enumerates: <what it lists>
  - <path> — enumerates: <what it lists>
  Add these to `.kiro/steering/docs-structure.md` for future targeted detection.
  ```
- If no new enumeration docs were discovered, report: "Discovery pass: no new enumeration docs found outside docs-structure.md."
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
3. **In auto mode (post-implementation):** do NOT run a separate sanity check — post-implementation Step 4 (auto-review) handles verification
4. **In on-demand mode:** after fixes are applied, run `bash ~/.kiro/hooks/doc-consistency.sh` as a quick sanity check. If it reports drift, flag for user.

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
- Steering: <path to docs-structure.md used | heuristic mode>
- Docs checked: N (list file names)
- Changed files: <list>
- Structural specialist: N findings (brief list)
- Prose specialist: N findings (brief list)
- Numeric specialist: N findings (brief list)
- Auto-fixed: N/total
- Flagged for user: N (reasons)
- False positives: N (user-dismissed + reviewer-rejected)
- Discovery pass: <N new enumeration docs suggested | none>
- Drift age: <when drift was likely introduced, if detectable from git log or CHANGELOG>
```

## Self-Audit Checkpoint

At 1-3 months after deployment, review `~/.kiro/logs/doc-drift.md`:
- Specialist consistently finding 0 issues → consider removing
- Specialist with high false-positive rate → refine prompt or remove
- Two specialists finding same things → merge them

Reduce specialist count only with evidence from the log.
