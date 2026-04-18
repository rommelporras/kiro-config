# Dev-Orchestrator Workflow Audit

**Date:** 2026-04-17
**Scope:** Full audit of dev-orchestrator subagent system — agents, steering,
skills, hooks, knowledge, prompts, security, and workflow correctness.
**Priority:** Accuracy, speed, full automation with guardrails.
**Context:** This is a global Kiro config deployed across multiple projects
(production, staging, pre-production). Must be foolproof.

---

## Executive Summary

The system is architecturally sound — the orchestrator pattern with specialist
subagents, layered security, and self-learning knowledge pipeline is
well-designed for AI-driven development. After three rounds of review
(including counter-audit by Kiro CLI), the final counts are: **5 critical
issues, 16 high-severity issues, 17 medium-severity issues, and 7 low**
that should be addressed for production readiness. The most dangerous
problems are: subagent hook gap (no secret scanning), TDD skill gaps on
two agents, `dd` deny-list typo on most agents, post-implementation trigger
mismatch, and knowledge pipeline bugs that corrupt data.

**Verdict:** Close to production-ready for a single operator. The CRITICAL
items are genuine safety and accuracy gaps that should be fixed. The system
works well today because the author's implicit knowledge compensates for
config gaps — but deploying across teams without fixes risks silent failures.

**Round 2 note (2026-04-17):** All 7 original CRITICAL claims were independently
verified against the actual files. Kiro CLI official documentation was
consulted for platform behavior (regex anchoring, hook inheritance, MCP
availability in subagents). 2 new CRITICALs, 4 new HIGHs, 6 new MEDIUMs,
and 3 new LOWs were added. See "Kiro CLI Platform Insights" section for
documentation-based corrections.

**Round 3 note (2026-04-17):** Kiro CLI counter-audited this document.
4 CRITICALs downgraded to HIGH (severity was overstated for a single-
operator system). 3 factual errors corrected. 3 missed items added.
See "Round 3: Kiro CLI Counter-Audit" section at the end for full details.

---

## Findings

### CRITICAL-01: Prompt-Steering Duplication Creates Guaranteed Drift

**What:** Every agent prompt duplicates content from steering documents that
the same agent already loads via `file://~/.kiro/steering/**/*.md`.

| Agent Prompt | Duplicates From Steering |
|---|---|
| `python-dev.md` | `python-boto3.md`, `tooling.md`, `design-principles.md` |
| `shell-dev.md` | `shell-bash.md`, `tooling.md` |
| `typescript-dev.md` | `typescript.md`, `tooling.md` |
| `frontend-dev.md` | `frontend.md` |
| `code-reviewer.md` | `design-principles.md`, `engineering.md` |
| `refactor.md` | `design-principles.md` |
| `orchestrator.md` | `engineering.md`, `universal-rules.md` |

**Why this is CRITICAL:** When you update a pattern in steering (e.g., change
`npm` to `bun` in `tooling.md`), the prompt still says `npm`. The subagent
now receives two contradictory instructions. Which wins depends on context
window ordering — unpredictable behavior.

**Evidence:** `steering/design-principles.md` lists 7 principles. These same
principles appear verbatim in `code-reviewer.md` (lines ~40-60), `refactor.md`
(design principles section), and `python-dev.md` (design principles section).
If you edit one, you must remember to edit all — and history shows you won't.

**Fix:** Prompts should contain ONLY agent-specific behavioral instructions
(identity, workflow, status reporting). Domain knowledge belongs in steering.
The prompt should reference steering authority: "Follow design principles from
steering docs" rather than restating them. Each prompt drops to ~40-60 lines.

**Duplication that IS good:** The denied commands lists in agent JSONs SHOULD
be duplicated across agents because they're security-critical and each agent
may have different deny patterns. Don't consolidate these.

---

### CRITICAL-02: Subagents Have Zero Runtime Security Hooks

**What:** Hooks only fire on the orchestrator. Subagents have NO preToolUse
hooks — no secret scanning, no write protection, no sed-on-JSON blocking.

**Why this is CRITICAL:** A subagent writing a file with a hardcoded secret
will succeed silently. The `scan-secrets.sh` hook never fires. The only
defense is the `deniedPaths` list, which doesn't inspect content.

**Attack surface:**
- `dev-python` writing `config.py` with `AWS_SECRET = "AKIA..."` → no hook fires
- `dev-shell` writing `deploy.sh` with `export TOKEN=sk-ant-...` → no hook fires
- `dev-docs` writing `config.json` with embedded credentials → no hook fires

**Current mitigation:** `security-model.md` acknowledges this as a design
decision: "Subagent security is enforced via deniedCommands and deniedPaths."
But deniedPaths/deniedCommands don't scan file content.

**Fix options:**
1. **Add hooks to every subagent JSON** — the `scan-secrets.sh` and
   `protect-sensitive.sh` hooks should be in every agent, not just orchestrator.
   This is the correct fix.
2. **Post-write scan in post-implementation** — add a `grep -rP` for secret
   patterns across all files modified by the subagent. This is defense-in-depth
   but catches secrets after they're written (already in git staging area).
3. **Both** — hooks prevent the write, post-implementation catches anything
   that slips through.

---

### CRITICAL-03: Deny List Bypass via Shell Indirection

**What:** `security-model.md` documents this: "Commands wrapped in
`bash -c '...'`, `sh -c '...'`, or executed via script files are not
inspected for denied patterns."

**Why this is CRITICAL for production:** A subagent that writes a shell
script and then executes it bypasses ALL denied commands. The sequence:
1. Write `temp.sh` containing `git push --force origin main`
2. Execute `bash temp.sh`
3. Denied commands never see the actual push

This isn't theoretical — LLMs regularly use intermediate scripts when
direct commands are complex.

**Current mitigation:** "Subagents are trusted agents operating within a
controlled environment" — this is fine for personal use but NOT for
production deployment across teams.

**Fix:** The `bash-write-protect.sh` hook should also:
1. Block `bash -c`, `sh -c`, `eval`, and `source` on unvetted paths
2. Block execution of any file written in the same session (track via
   a session state file)

This won't be perfect (defense in depth never is), but it closes the
most obvious bypass.

---

### CRITICAL-04: TDD Enforcement is Inconsistent and Overridable

**What:** Three related problems:

1. **`dev-frontend` has NO TDD skill** — only `verification-before-completion`
   and `receiving-code-review`. Frontend code is never tested.

2. **`dev-shell` has NO TDD skill** — shell scripts are never test-driven.
   Only `systematic-debugging`, `verification-before-completion`, and
   `receiving-code-review`.

3. **Global Kiro rule overrides project TDD** — documented in
   `docs/improvements/pending.md`: "The global Kiro implicit instruction
   says 'DO NOT automatically add tests unless explicitly requested.' The
   global rule always wins because it's framed as a hard constraint, so TDD
   never triggers." This means the TDD skill loaded on `dev-python`,
   `dev-typescript`, and `dev-refactor` is effectively dead.

**Why this is CRITICAL:** The entire engineering philosophy (`steering/engineering.md`)
is built on TDD. The skills are elaborate (350-line TDD skill with Iron Laws
and rationalization prevention). But in practice, TDD never fires because:
- Frontend/shell agents don't have the skill
- Other agents have the skill but it's overridden by a global platform rule

**Fix:**
1. Add TDD skill to `dev-frontend` (using Playwright or Vitest for DOM testing)
   and `dev-shell` (using bats-core or shunit2).
2. The global "no auto tests" Kiro rule must be overridden in the orchestrator
   prompt with an explicit: "For any code in a project with a test directory,
   TDD is mandatory. The 'no auto tests' platform default does not apply to
   projects with existing test infrastructure." This must be in the
   orchestrator's delegation format, not just steering.
3. The delegation format (orchestrator.md line 112-116) should change the
   skill trigger from "implement with tests" to "implement with TDD — write
   the failing test FIRST, verify it fails, then implement. This is mandatory."

---

### CRITICAL-05: Post-Implementation Trigger List is Incomplete

**What:** `post-implementation/SKILL.md` line 8 says it fires after:
"dev-python, dev-typescript, dev-shell, dev-refactor". But the orchestrator
prompt (line 8-9) says it fires after: "dev-python, dev-shell, dev-refactor,
dev-kiro-config, dev-typescript, dev-frontend".

Missing from the skill: `dev-kiro-config`, `dev-frontend`, `dev-docs`.

**Why this is CRITICAL:** If `dev-frontend` completes work, the skill says
it doesn't apply. The orchestrator says it does. Which one wins depends on
how the LLM resolves the conflict — unpredictable. If the skill wins,
frontend changes skip quality gates, review, and improvement capture entirely.

Similarly, `dev-docs` returning DONE would skip post-implementation entirely
(arguably correct for pure docs, but not for JSON configs that affect behavior).

**Fix:** The skill trigger list must exactly match the orchestrator prompt's
list. Add `dev-kiro-config`, `dev-frontend`. Consider adding `dev-docs` with
a lightweight quality gate (JSON validation, markdown lint).

---

### CRITICAL-06: No File Conflict Detection for Parallel Agents

**What:** Both `dispatching-parallel-agents` and `subagent-driven-development`
support parallel dispatch. Neither has a mechanism to prevent two agents from
modifying the same file.

**Evidence:** `dispatching-parallel-agents/SKILL.md` line 181-182: "Check for
conflicts — Did delegates edit same code?" — this is a post-hoc check after
the damage is done. `subagent-driven-development/SKILL.md` line 217: "Dispatch
multiple implementation delegates in parallel on SHARED files (conflicts)" is
in the "Never" list, but there's no enforcement mechanism.

**Why this is CRITICAL:** The orchestrator is an LLM. "Never" instructions
are probabilistic, not deterministic. In a complex plan with many tasks, the
orchestrator will eventually dispatch two agents that touch the same file.
Last-write-wins, and the first agent's work is silently destroyed.

**Fix:** Add a pre-dispatch verification step to the `execution-planning`
skill: before marking tasks as parallel-safe, list all files each task
will touch (from the plan's file structure mapping). If any file appears
in two parallel tasks, they MUST be sequential. Make this a hard gate,
not a suggestion.

---

### CRITICAL-07: Knowledge Rules Violate Their Own Header Directive

**What:** `knowledge/rules.md` line 4: "NOTE: Do NOT duplicate steering docs
here. Only operational lessons not covered elsewhere."

But lines 22-27 duplicate `steering/design-principles.md` verbatim:
- "Rule of Three: only extract after 3 duplications" — word for word from steering
- "KISS over DRY" — word for word from steering
- "Fail Fast: library code must never call sys.exit()" — word for word from steering
- "Predictable: get_*/describe_*" — word for word from steering

**Why this is CRITICAL:** These rules are keyword-matched and injected via
`context-enrichment.sh` on EVERY prompt containing those keywords. So the
agent gets the same instruction 3 times: once from the steering doc, once
from the prompt (which duplicates the steering doc per CRITICAL-01), and
once from the knowledge rule injection. Triple injection wastes context
tokens and increases the risk of the LLM treating repeated instructions
as more important than other instructions that appear only once.

**Fix:** Remove the last two rule groups (`[refactor,extract,...]` and
`[library,module,...]`) from `knowledge/rules.md`. They are already in
steering. Knowledge rules should only contain operational lessons:
subagent limitations, dispatch optimization, commit workflow, audit triggers.

---

### CRITICAL-08: `dd if/dev` Typo in ALL Agent Configs — Protection is Dead

**What:** Every agent JSON (orchestrator, base, dev-python, dev-shell,
dev-docs, dev-reviewer, dev-refactor, dev-typescript, dev-frontend) has:
```json
"dd if/dev"
```

The actual dangerous command is `dd if=/dev/zero` or `dd if=/dev/random`.
The pattern is missing the `=` sign.

**Why this is CRITICAL:** Per Kiro CLI documentation, `deniedCommands`
patterns are **anchored with `\A` and `\z`**. So this pattern matches only
the exact string `dd if/dev` — which no one would ever type. The real
command `dd if=/dev/zero of=/dev/sda` does NOT match because it starts
with `dd if=` (with equals), not `dd if/` (with slash).

The `bash-write-protect.sh` hook correctly uses `"dd if=/dev"` (with `=`),
so the hook provides protection. But the deniedCommands in ALL agent
configs are ineffective for this pattern — and subagents don't have hooks.

**Fix:** Change to `"dd if=/dev.*"` in every agent JSON. Include the `.*`
suffix because the anchoring requires matching the full command string.

---

### CRITICAL-09: Auto-Capture Keyword List Creates Knowledge Blind Spots

**What:** `hooks/feedback/auto-capture.sh` has a hardcoded list of ~50
technology keywords for episode tagging. If a correction involves a
technology not in the list, the keyword extraction returns empty and
the episode is **silently dropped** (line 23: empty keywords → exit 0).

**Missing from the keyword list:** `rust`, `go`, `java`, `typescript`,
`javascript`, `node`, `npm`, `bun`, `react`, `next`, `vite`, `webpack`,
`gradle`, `maven`, `cdk`, `cloudformation`, `zsh`, `bash`, `make`,
`nix`, `pulumi`, `prisma`, `express`, `fastapi`, `django`, `flask`,
`redis`, `postgresql`, `sqlite`, `mongodb`.

**Why this is CRITICAL:** The self-learning pipeline is a core
differentiator of this system. A keyword blind spot means the system
cannot learn from corrections about unlisted technologies. The pipeline
silently drops valid corrections rather than capturing them with a
generic tag. This creates a bias where the system only improves in
areas it already knows about.

**Fix:** Two options:
1. **Default keyword fallback:** If no specific keyword matches, use
   `"general"` as the keyword instead of dropping the episode.
2. **LLM-assisted extraction:** Since the correction text is available,
   use a simple heuristic (extract words that appear in file extensions,
   import statements, or tool names) rather than a fixed list.

---

### HIGH-01: Steering Count Discrepancy (Doc Drift Already Happening)

**What:** `design-principles.md` is a new unstaged file (shown in `git status`
as `?? steering/design-principles.md`). This makes 11 steering docs, but:
- README says "10 steering docs"
- `kiro-cli-install-checklist.md` verifies "10 steering docs"
- `team-onboarding.md` says "10 steering docs"
- `doc-consistency.sh` hook presumably checks counts

**Why this matters:** The doc-consistency hook should have caught this on the
next commit. But since it's an unstaged file, the count hasn't been updated
yet. This is a live example of the drift problem described in CRITICAL-01.

**Fix:** Before committing `design-principles.md`, update all count references.
Verify the `doc-consistency.sh` hook catches this.

---

### HIGH-02: `dev-kiro-config` Ghost Agent in Non-Kiro-Config Repos

**What:** The orchestrator lists `dev-kiro-config` in `availableAgents` and
`trustedAgents` (lines 161-179 of `dev-orchestrator.json`). The routing
table (orchestrator.md line 20-23) routes kiro-config edits to it. But this
agent only exists in `.kiro/agents/dev-kiro-config.json` — a project-local
file that only loads when working inside the kiro-config repo.

In every other project, the orchestrator will try to dispatch to a
non-existent agent. The prompt says "Fall back to dev-docs if unavailable,"
but this fallback is a natural-language instruction, not a programmatic one.

**Why this matters:** In production projects, if someone asks "update the
steering doc," the orchestrator may attempt to spawn `dev-kiro-config`,
fail, and either error out or silently fall back — depending on Kiro CLI
behavior for missing agents.

**Fix:** Either:
1. Remove `dev-kiro-config` from the global `availableAgents`/`trustedAgents`
   and only add it via project-local overrides in `.kiro/agents/`, OR
2. Move `dev-kiro-config.json` to the global agents directory with a
   `deniedPaths` that blocks everything except `~/.kiro/` paths, OR
3. Add error handling to the orchestrator prompt: "If agent dispatch fails,
   retry with dev-docs. Never surface agent-not-found errors to the user."

Option 1 is cleanest.

---

### HIGH-03: Prompt Naming Inconsistency Makes Mapping Non-Obvious

**What:** Agent files use one naming convention, prompt files use another:

| Agent JSON | Prompt File | Mismatch? |
|---|---|---|
| `dev-docs.json` | `docs.md` | Missing `dev-` prefix |
| `dev-python.json` | `python-dev.md` | Reversed: `-dev` suffix |
| `dev-shell.json` | `shell-dev.md` | Reversed: `-dev` suffix |
| `dev-reviewer.json` | `code-reviewer.md` | Different name entirely |
| `dev-typescript.json` | `typescript-dev.md` | Reversed: `-dev` suffix |
| `dev-frontend.json` | `frontend-dev.md` | Reversed: `-dev` suffix |
| `dev-refactor.json` | `refactor.md` | Missing `dev-` prefix |
| `dev-orchestrator.json` | `orchestrator.md` | Missing `dev-` prefix |

**Why this matters:** When debugging agent behavior, you need to quickly find
the prompt. Inconsistent naming forces you to check every time. At scale
(new team members, more agents), this becomes a maintenance tax.

**Fix:** Rename all prompts to match their agent: `dev-docs.md`,
`dev-python.md`, `dev-shell.md`, `dev-reviewer.md`, `dev-typescript.md`,
`dev-frontend.md`, `dev-refactor.md`, `dev-orchestrator.md`. Update the
`file://` references in each agent JSON.

---

### HIGH-04: Subagents Cannot Access MCP (Context7, AWS Docs)

**What:** All subagents have `"includeMcpJson": false`. This means no
subagent can use Context7 for library documentation lookups.

**Why this matters:** A `dev-typescript` agent implementing Express
middleware cannot look up the current Express API docs. A `dev-python` agent
writing boto3 code cannot check the AWS documentation server. They're
working blind on library APIs, relying entirely on training data.

**The orchestrator prompt says** (line 118): "Subagents CAN use: read,
write, shell, code, MCP tools." But this contradicts the JSON config which
disables MCP for all subagents.

**Impact on accuracy:** This is the single biggest accuracy hit in the
system. Library API details are where LLMs make the most mistakes, and
the MCP servers that would fix this are disabled for the agents that need
them most.

**Fix:** Enable `"includeMcpJson": true` for at least `dev-python`,
`dev-typescript`, and `dev-frontend`. Add `@context7` to their `tools`
array. The AWS documentation MCP is optional but Context7 is essential
for accuracy. Update the orchestrator prompt to remove the false claim
about MCP availability.

---

### HIGH-05: `dev-docs` Deny List Inconsistency Creates Routing Dead Ends

**What:** `dev-docs` uses a simplified deny list compared to other subagents:
```json
"python3? .*", "node .*", "npm .*", "uv .*", "pip .*",
"terraform .*", "helm .*", "kubectl .*", "docker .*", "aws .*"
```

These are broader patterns that block ALL usage of these tools, including
read-only operations. Other subagents use specific mutating-command patterns
(e.g., `kubectl apply.*` but not `kubectl get.*`).

**Why this matters:** `dev-docs` cannot run `npm ls` to check dependency
versions, `uv pip list` to verify Python packages, or `aws s3 ls` to
check bucket names — all legitimate read-only operations needed when
updating documentation about those systems.

**Also:** `dev-docs` blocks all `rm` variants (recursive and single-file),
which is documented in the orchestrator prompt. But it also blocks
`git add` and `git commit`, which is correct but undocumented in the prompt.

**Fix:** Change `dev-docs` deny list to match the specific mutating-command
patterns used by other subagents, rather than blanket tool blocking. Or
add explicit documentation in the orchestrator prompt about what `dev-docs`
cannot do so the orchestrator pre-gathers data.

---

### HIGH-06: Quality Gate in Post-Implementation Uses `npm` Unconditionally

**What:** `post-implementation/SKILL.md` Step 2 Quality Gate says:
"package.json → `npm run lint` · `npm run typecheck` · `npm test`"

But the user's global CLAUDE.md (and `steering/tooling.md`) say to use
different tools per project. Some projects use `bun`, some use `npm`.
The quality gate hardcodes `npm`.

**Why this matters:** On a bun project, `npm run lint` will either fail
(no node_modules) or use the wrong package manager's resolution algorithm.
This would trigger the retry loop, wasting 3 attempts before surfacing
to the user.

**Fix:** The quality gate should detect the package manager from lock files:
- `bun.lockb` → `bun run lint`, `bun run typecheck`, `bun test`
- `package-lock.json` → `npm run lint`, etc.
- `yarn.lock` → `yarn run lint`, etc.
- `pnpm-lock.yaml` → `pnpm run lint`, etc.

---

### HIGH-07: Orchestrator Prompt Claims Subagents Have MCP Tools They Don't

**What:** Orchestrator prompt line 118: "Subagents CAN use: read, write,
shell, code, MCP tools." But every subagent has `"includeMcpJson": false`.
This is either a documentation lie or a config bug.

**Why this matters:** The orchestrator uses this list to decide what to
pre-gather. If it believes subagents have MCP access, it won't pre-fetch
library docs — and the subagent will work without them.

**Fix:** Either enable MCP on subagents (HIGH-04) or fix the prompt to say
"Subagents CAN use: read, write, shell, code. They CANNOT use MCP tools —
pre-fetch library documentation with Context7 before delegating."

---

### HIGH-08: `dev-refactor` Has No Debugging Skill

**What:** `dev-refactor` loads: `verification-before-completion`,
`receiving-code-review`, `test-driven-development`. It does NOT load
`systematic-debugging`.

**Why this matters:** Refactoring frequently breaks things. When a
refactoring move causes test failures, `dev-refactor` has no systematic
methodology for diagnosing the root cause. It will attempt ad-hoc fixes,
which violates the engineering philosophy.

**Fix:** Add `systematic-debugging` to `dev-refactor`'s resources.

---

### HIGH-09: Orchestrator `fs_write.allowedPaths` Allows Broad Write Access

**What:** The orchestrator's `fs_write.allowedPaths`:
```json
"docs/**", "*.md", "~/personal/**", "~/eam/**"
```

The `*.md` pattern allows writing ANY markdown file ANYWHERE on the system.
The `~/personal/**` and `~/eam/**` patterns allow writing to any file in
those trees, not just the current project.

**Why this matters:** The orchestrator "never writes code" (per its prompt),
but its config allows writing to any Python file under `~/eam/`. A prompt
injection or confused routing could cause the orchestrator to write code
directly, bypassing the subagent security model entirely.

**Fix:** Tighten the orchestrator's write paths:
- Remove `*.md` (too broad — allows writing anywhere)
- Replace with project-specific paths or `./**/*.md` for current project only
- The orchestrator should only write to: plan files, spec files, improvement
  logs, and tracking documents. Everything else goes through subagents.

---

### HIGH-10: `rm -f` Regex Pattern Is Suspicious

**What:** In multiple agent deny lists:
```json
"rm -f.*r.*"
```

This pattern is supposed to catch `rm -fr`, `rm -fR`, and `rm -f --recursive`.
But it also matches: `rm -f report.txt` (contains 'r' in filename),
`rm -f readme.md`, `rm -f requirements.txt`.

**Why this matters:** Any single-file removal of a file with 'r' in its name
will be incorrectly blocked. The agent will report "denied" and fail the task,
triggering unnecessary retries.

**Fix:** Change to: `"rm -f[rR].*"` or `"rm -fr.*"` plus `"rm -fR.*"` as
separate patterns. Or better: `"rm -(rf|fr|fR|Rf).*"` and
`"rm --force --recursive.*"`.

---

### HIGH-11: No Explicit Timeout/Resource Limits on Subagent Execution

**What:** The orchestrator dispatches subagents with no documented timeout
or resource constraints. A subagent stuck in an infinite retry loop
(e.g., tests that never pass) will run indefinitely.

**Why this matters:** In production usage, a stuck subagent blocks the
orchestrator. The retry limit (max 3 in post-implementation) only applies
to the post-implementation review loop, not to the subagent's internal
execution.

**Fix:** Document expected execution timeframes per agent type. Consider
adding guidance to the orchestrator: "If a subagent hasn't returned after
N minutes, investigate."

---

### HIGH-12: Improvement Capture Path is Hardcoded to Personal Directory

**What:** `orchestrator.md` line 140:
```
Append to `~/personal/kiro-config/docs/improvements/pending.md`
```

`post-implementation/SKILL.md` line 61:
```
Append to `~/personal/kiro-config/docs/improvements/pending.md`
```

**Why this matters:** This path is specific to the author's machine.
On any other team member's machine (after team-onboarding), this path
won't exist. The skill says "If file is inaccessible, log to conversation
instead," which is a good fallback, but it means improvement capture
silently stops working for everyone except the author.

**Fix:** Use a relative path from the kiro-config symlink:
`~/.kiro/docs/improvements/pending.md` or detect the config root
dynamically.

---

### HIGH-13: `dev-kiro-config` Has No Hooks and Reuses Generic `docs.md` Prompt

**What:** `.kiro/agents/dev-kiro-config.json` has no `hooks` key and
reuses `file://../../agents/prompts/docs.md` as its prompt.

**Why this matters:**
1. **No security hooks:** This agent can write to `~/.kiro/agents/`,
   `~/.kiro/hooks/`, `~/.kiro/steering/`, and `~/.kiro/skills/` — the
   most sensitive files in the system. Yet it has zero preToolUse hooks.
   No secret scanning, no write protection, no sed-on-JSON blocking.
2. **Generic prompt:** The docs.md prompt says "You edit config files
   and documentation" with no knowledge of agent JSON schema, hook
   conventions, SKILL.md frontmatter format, or steering document
   patterns. For the agent that modifies the agent system itself, this
   is insufficient.

**Fix:** Create a dedicated `kiro-config-dev.md` prompt with:
- Agent JSON schema awareness (tools, deniedCommands, resources patterns)
- Hook script conventions (exit codes, stdin format, jq parsing)
- SKILL.md frontmatter requirements
- Steering doc structure
Add hooks: at minimum `scan-secrets.sh` and `block-sed-json.sh`.

---

### HIGH-14: `writing-plans` References "plan-reviewer" — Not a Real Agent

**What:** `skills/writing-plans/SKILL.md` line 122 says:
"Dispatch a plan-reviewer delegate to review the plan against the spec."

There is no agent named `plan-reviewer`. The closest is `dev-reviewer`,
but the skill doesn't use that name.

**Why this matters:** The orchestrator must infer that "plan-reviewer
delegate" means "dispatch dev-reviewer with plan review instructions."
This inference is probabilistic. In some contexts, the orchestrator
may attempt to spawn a nonexistent agent, fail silently (per Kiro CLI's
apparent degradation pattern), and skip plan review entirely.

**Fix:** Change to "Dispatch dev-reviewer with the plan and spec for
review" — using the actual agent name.

---

### HIGH-15: `context-enrichment.sh` Has Regex Injection via Keywords

**What:** Line 51 of `hooks/feedback/context-enrichment.sh`:
```bash
if echo "$PROMPT" | grep -qiP "\b${kw}\b"; then
```

The `$kw` variable comes from `knowledge/rules.md` keyword headers.
Keywords like `sys.exit` contain regex metacharacters (`.` matches any
character in PCRE). The keyword is interpolated directly into the regex
without escaping.

**Impact:** `sys.exit` would match `sys_exit`, `sysAexit`, `sys exit`,
etc. The keyword `god object` has a space which interacts with word
boundary `\b` matching. If anyone adds a keyword containing `(`, `)`,
`+`, `*`, `?`, or `[`, the grep will either fail or match unintended
patterns.

**Fix:** Escape regex metacharacters in keywords before interpolation:
```bash
escaped_kw=$(printf '%s' "$kw" | sed 's/[.[\*^$()+?{|\\]/\\&/g')
```

---

### HIGH-16: `distill.sh` Corrupts Episode Format via sed

**What:** `hooks/_lib/distill.sh` line 45:
```bash
sed -i "s/| active |.*${kw}/\0 [promoted]/" "$EPISODES"
```

This inserts `[promoted]` in the middle of the line at the keyword
match position, not at the end. The pipe-delimited format
(`DATE | STATUS | KEYWORDS | SUMMARY`) gets corrupted because `[promoted]`
is inserted after the keyword within the KEYWORDS field, pushing the
rest of the line out of alignment.

Additionally, the keyword variable is unescaped in the sed regex,
creating the same metacharacter problem as HIGH-15.

**Fix:** Replace with an awk-based approach that properly appends
`[promoted]` to the STATUS field while preserving the line structure:
```bash
awk -v kw="$kw" 'tolower($0) ~ tolower(kw) && /\| active \|/ {
  sub(/\| active \|/, "| promoted |")
} 1' "$EPISODES" > "${EPISODES}.tmp" && mv "${EPISODES}.tmp" "$EPISODES"
```

---

### MEDIUM-01: Steering Documents Load Into Every Agent Including Irrelevant Ones

**What:** Every agent loads `file://~/.kiro/steering/**/*.md` — ALL 11
steering docs. This means `dev-frontend` receives `python-boto3.md`,
`shell-bash.md`, and `aws-cli.md`. `dev-python` receives `frontend.md`
and `typescript.md`.

**Impact:** Wasted context tokens. 11 steering docs at ~30-80 lines each
is ~500-800 lines of irrelevant content per agent. For Sonnet subagents
with limited context, this matters.

**Fix:** Load only relevant steering per agent:
- All agents: `universal-rules.md`, `engineering.md`, `security.md`,
  `design-principles.md`, `tooling.md`
- `dev-python`: + `python-boto3.md`
- `dev-shell`: + `shell-bash.md`
- `dev-typescript`: + `typescript.md`, `web-development.md`
- `dev-frontend`: + `frontend.md`, `typescript.md`
- `dev-docs`: no domain-specific steering needed
- `dev-reviewer`: ALL (needs to review any language)
- `dev-refactor`: ALL (needs to refactor any language)

---

### MEDIUM-02: Skill Chain Dependencies Are Not Enforced

**What:** The workflow chain is:
`design-and-spec` -> `writing-plans` -> `execution-planning` -> `subagent-driven-development`

Each skill's description says "hand off to next skill" but there's no
enforcement. The orchestrator could skip `execution-planning` and go
directly from `writing-plans` to `subagent-driven-development`.

**Impact:** Skipping `execution-planning` means no parallel stage
identification, no dependency verification, no review gates defined.
The implementation proceeds but without the safety analysis that
execution-planning provides.

**Fix:** Add explicit "Prerequisites" to each skill:
```
## Prerequisites
This skill requires a completed execution plan from the execution-planning skill.
If no execution plan exists at docs/specs/<name>/execution/, STOP and run
execution-planning first.
```

---

### MEDIUM-03: `dev-docs` Cannot Run Doc-Consistency Check

**What:** The `commit` skill (Step 2.5) runs
`bash ~/.kiro/hooks/doc-consistency.sh`. But `dev-docs` blocks
`bash` as a denied command pattern via `"rm -r.*"` — wait, actually
`dev-docs` doesn't block `bash` itself. However, `dev-docs` cannot
run `git add` or `git commit`, so it can never trigger the commit skill.

The real issue: `dev-docs` makes documentation changes, but the
doc-consistency check only runs at commit time. Between editing and
committing, there's no validation that counts are correct.

**Fix:** Add a "run doc-consistency.sh" step to the `dev-docs` prompt's
verification workflow, so it validates documentation counts before
reporting DONE.

---

### MEDIUM-04: Knowledge Enrichment Has a 60-Second Dedup Window

**What:** `context-enrichment.sh` has a 60-second dedup. If two prompts
within 60 seconds both contain the keyword "subagent," only the first
gets the injected rules.

**Impact:** In rapid-fire conversations about subagent issues (common
during debugging), the second and subsequent messages lose their
knowledge context. This is exactly when you need the rules most.

**Fix:** Make the dedup per-keyword-set, not per-invocation. Or remove
the dedup entirely — the overhead of injecting 5 rules is negligible
compared to the cost of missing relevant context.

---

### MEDIUM-05: Correction Detection Regex May Be Too Broad

**What:** `correction-detect.sh` uses 16 regex patterns including "no,"
at the start of a message and "wrong". These will fire on:
- "No, I think we should use a different approach" (genuine correction)
- "No worries, that looks good" (false positive)
- "The wrong version was deployed" (false positive — describing a problem,
  not correcting the agent)

**Impact:** False positive corrections pollute `episodes.md` with noise,
diluting the signal for the 3-occurrence promotion threshold.

**Fix:** Add a secondary filter: after regex match, check if the matched
line contains a correction target (a previous agent suggestion or action).
Or increase the promotion threshold to 5 occurrences.

---

### MEDIUM-06: Session Log Has No Rotation or Cleanup

**What:** `knowledge/session-log.txt` has 7 entries from 2026-04-12, all
within 8 minutes. This file will grow indefinitely.

**Impact:** Minor — the file is gitignored. But it's loaded as part of
the knowledge base, so it will consume indexing resources.

**Fix:** Add rotation in `notify.sh` — keep only the last 30 entries.
Or exclude it from knowledge indexing entirely.

---

### MEDIUM-07: No Skill for Handling CI/CD Failures

**What:** The skill catalog covers: design, planning, execution, TDD,
debugging, verification, review, audit, commit, push. But there's no
skill for when a CI pipeline fails after push.

**Impact:** When CI fails, the orchestrator has no structured workflow.
It falls back to ad-hoc debugging, which the engineering philosophy
explicitly discourages.

**Fix:** Consider a `ci-failure` skill that: reads CI logs, identifies
failing step, routes to appropriate subagent (dev-python for pytest
failures, dev-typescript for ESLint failures, dev-shell for build script
issues), and follows the systematic-debugging methodology.

---

### MEDIUM-08: Orchestrator `tools` Array Includes `aws` But Steering Says Read-Only

**What:** The orchestrator has `"aws"` in both `tools` and `allowedTools`
(auto-approved). `steering/universal-rules.md` says infrastructure is
read-only. The `deniedCommands` list blocks mutating AWS CLI commands.

But having `aws` as an auto-allowed tool means the orchestrator can
execute `aws sts get-session-token`, `aws s3 cp`, or other commands
that don't match the denied patterns but still have side effects.

**Impact:** `aws s3 cp` copies files between S3 buckets — a mutating
operation not caught by the deny list (it's not `create-`, `delete-`,
`update-`, etc.).

**Fix:** Add these to the orchestrator's denied commands:
```json
"aws s3 cp.*",
"aws s3 mv.*",
"aws s3 rm.*",
"aws s3 sync.*",
"aws s3api put-object.*"
```

---

### MEDIUM-09: No Explicit Handling of Multi-Language Projects

**What:** The routing table routes by primary language. But a project
with Python backend + TypeScript frontend + shell scripts has no
unified routing strategy.

The closest is the "full-stack" route: `dev-typescript` + `dev-frontend`
in parallel. But this doesn't cover Python + TypeScript or Python + Shell.

**Impact:** The orchestrator must infer multi-language routing on the
fly. For experienced users this works; for new team members, the lack
of explicit guidance causes inconsistent routing.

**Fix:** Add a "Multi-language routing" section to the orchestrator prompt:
"For tasks spanning multiple languages, decompose into single-language
subtasks and dispatch to the appropriate specialist. If a task requires
changes in both Python and TypeScript, dispatch dev-python first (backend),
then dev-typescript (API layer), then dev-frontend if needed."

---

### MEDIUM-10: `base.json` Agent Is a Maintenance Orphan

**What:** `base.json` loads 14 skills (different set from orchestrator's 12).
It has no prompt. It's documented as "standalone fallback" but:
- It's not referenced in the orchestrator routing table
- It's not in `availableAgents`/`trustedAgents`
- Its skill set is a superset of some agent skills but a subset of others
- It has no `subagent` tool (works solo)

**Impact:** If someone uses `base` (via `/agent swap base`), they get a
different behavior profile than the orchestrator. Skills that work one way
in the orchestrator may work differently (or not at all) in base.

**Fix:** Either: formalize `base.json` as the "manual mode" agent with
its own documented purpose and maintenance cadence, or deprecate it and
remove it to avoid confusion.

---

### LOW-01: `git add .*` in Orchestrator `allowedCommands` Is Overly Permissive

The `git add .*` allowed command pattern means the orchestrator can
`git add -A` or `git add .`, which the commit skill explicitly warns
against ("never git add -A"). The allowedCommands enables what the
skill forbids — relying on the LLM to follow the skill over the config.

**Fix:** Change to `git add [^-.].*` to block `git add -A` and `git add .`
at the config level.

---

### LOW-02: `dev-reviewer` Loads `python-audit` and `typescript-audit` But Not `shell-audit`

There's no shell-audit skill. Shell scripts are reviewed using the
code-reviewer prompt's built-in shell checklist. This is fine — shell
scripts are simpler — but it's an asymmetry worth documenting.

**Fix:** Either create a `shell-audit` skill wrapping `shellcheck` +
`shfmt` with a manual checklist, or document in skill-catalog.md that
shell review is handled inline by code-reviewer.md's shell checklist.

---

### LOW-03: Graphviz Diagrams in Skills Won't Render

Multiple skills use `dot` graphviz syntax for decision diagrams. These
are useful for LLM consumption but won't render in markdown viewers.
Team members reading skill files won't see the diagrams.

**Fix:** Either add rendered PNG/SVG versions alongside the dot source,
or convert to ASCII diagrams that render everywhere.

---

### LOW-04: `steering/tooling.md` Says `npm` for Node.js

The user's personal CLAUDE.md says "use `bun`, never `npm`." The
kiro-config steering says `npm`. These are for different tools
(Claude Code vs Kiro CLI), but when both configs are active on the
same machine, confusion is inevitable.

**Fix:** Document the package manager choice as project-specific rather
than global. The steering should say: "Check project lockfile to
determine package manager. Default to npm for new Kiro projects."

---

### MEDIUM-11: Orchestrator Missing `rm` from `deniedCommands` (Single Layer Defense)

**What:** The orchestrator's `deniedCommands` have no `rm` patterns at all.
Subagents deny `rm -r.*`, `rm -f.*r.*`, `rm --recursive.*`. The orchestrator
relies entirely on `bash-write-protect.sh` hook for rm safety.

**Impact:** If the hook has a bug, times out (5s limit), or is bypassed via
indirection, the orchestrator has zero deny-list protection against recursive rm.
Defense-in-depth principle says both layers should be present.

**Fix:** Add `rm -r.*`, `rm --recursive.*` to orchestrator deniedCommands.
Keep `rm -f` single-file allowed since the routing table says the orchestrator
handles file deletions directly.

---

### MEDIUM-12: `/tmp` Files Have No User-Namespace Isolation

**What:** The feedback hooks write to bare `/tmp/` paths:
- `context-enrichment.sh` → `/tmp/kb-enrich-last`
- `correction-detect.sh` → `/tmp/kb-correction-*.flag`
- `auto-capture.sh` → `/tmp/kb-changed.flag`

On a multi-user system, these files collide between users. Any process
can create `/tmp/kb-changed.flag` to trigger distillation, or write to
`/tmp/kb-enrich-last` to suppress context enrichment for 60 seconds.

**Fix:** Use `$TMPDIR` or `/tmp/kiro-${USER}-*` for all temp files.

---

### MEDIUM-13: `doc-consistency.sh` Only Checks Skill Counts

**What:** The commit skill runs `doc-consistency.sh` to validate docs.
But the script only checks that skill counts match across README,
skill-catalog, install-checklist, and base.json welcomeMessage.

**Not checked:** Agent counts, hook counts, steering doc counts (which is
why HIGH-01 happened — adding `design-principles.md` wasn't caught),
skill names (a rename would pass), routing table entries vs actual
available agents.

**Fix:** Extend doc-consistency.sh to also count steering docs and
agent JSON files, comparing against documentation references.

---

### MEDIUM-14: `create-pr` Skill Hardcodes `--base main`

**What:** `.kiro/skills/create-pr/SKILL.md` line 69:
```bash
gh pr create --base main --draft
```

Repositories using `master` or other default branches would create PRs
targeting the wrong branch or fail entirely.

**Fix:** Use `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`
to detect the default branch dynamically.

---

### MEDIUM-15: `auto-capture.sh` Race Condition Between Concurrent Corrections

**What:** The dedup check (grep) and the append (echo >>) in auto-capture.sh
are not atomic. If two correction-detect hooks fire within the same second,
both background auto-capture processes check dedup, both find no match, both
append — creating duplicates. The flag filename uses `date +%s` (second
granularity), so same-second corrections also overwrite each other's flags.

**Fix:** Use `flock` for atomic read-check-write, or accept the rare
duplicate as acceptable since the 3-occurrence promotion threshold
self-corrects.

---

### MEDIUM-16: `auto-capture.sh` Dedup Uses Only First 120 Chars

**What:** Dedup logic: `head -1 | cut -c1-120` then `grep -qiF`. Two
different corrections starting with the same 120 characters are
incorrectly deduped. The same correction rephrased bypasses dedup entirely.

**Impact:** Low individually, but compounds with the 30-episode cap —
duplicate entries waste slots while unique rephrasings of the same issue
accumulate without being recognized as related.

**Fix:** Use a more robust similarity check, or hash the full normalized
text for dedup.

---

### LOW-05: `correction-detect.sh` Has 14 Patterns, Not 16

The code has 14 regex patterns, but internal comments or documentation
may reference 16. Minor doc inaccuracy. Some patterns have false-positive
risk:
- `wrong` matches "what's wrong with this code?" (a question, not correction)
- `I said` matches "I said that looks great" (agreement)
- `should (be|have|use)` matches "what should be done?" (a question)
- Missing patterns for common corrections: "please change", "fix this",
  "revert", "undo", "that is incorrect" (without apostrophe).

**Fix:** Add missing correction patterns. Add a secondary context filter
to reduce false positives (e.g., skip if matched line is a question).

---

### LOW-06: `protect-sensitive.sh` Missing Some Credential File Types

Neither `protect-sensitive.sh` nor `bash-write-protect.sh` protect:
- `id_dsa` (older DSA keys)
- `.p12`/`.pfx` certificate files
- `kubeconfig` files
- `*.tfstate` (Terraform state, contains secrets)
- `.env.*.local` pattern (like `.env.staging.local`)

**Fix:** Add these patterns to both `protect-sensitive.sh` PROTECTED
array and `bash-write-protect.sh` PROTECTED array.

---

### LOW-07: Skill Resources Reference Tools Subagents Don't Have

The `python-audit` skill references `bandit` (security scanner) and
`mypy` (type checker). The `typescript-audit` skill references `eslint`
and `vitest`. These tools must be installed in the project for the
skills to work. If they're not installed, the skill's automated checks
fail silently or with unhelpful errors.

**Fix:** Add a pre-check to each audit skill: "If tool X is not
installed, skip its automated check and note 'X not available — manual
review required' in the report."

---

---

## Kiro CLI Platform Insights

The following behaviors were confirmed from Kiro CLI official documentation
(https://kiro.dev/docs/cli/). These affect the accuracy of audit findings
and should be referenced when implementing fixes.

### Regex Anchoring

`deniedCommands` patterns are **anchored with `\A` and `\z`** and do NOT
support look-around. This means:
- `"git push"` matches ONLY the exact string `git push` — not
  `git push --force` or `git push origin main`
- Patterns need `.*` suffix to match commands with arguments
- The `rm -f.*r.*` pattern (HIGH-10) is still problematic even with
  anchoring — it matches any full command starting with `rm -f` where
  the remainder contains `r` anywhere

### Hook Inheritance

**No hook inheritance exists.** Hooks are per-agent only. There is no
global hook mechanism and no way for subagents to inherit parent hooks.
This confirms CRITICAL-02 — subagent security via hooks requires
explicitly defining hooks in each subagent JSON.

### MCP in Subagents

Per docs, subagents CAN access MCP tools. However, this depends on the
agent config having `includeMcpJson: true` and the relevant MCP tools
in the `tools` array. Since all subagent configs set
`includeMcpJson: false`, MCP is effectively disabled (HIGH-04).

### Subagent Tool Restrictions

Officially unavailable in subagents: `web_search`, `web_fetch`,
`introspect`, `thinking`, `todo_list`, `use_aws`, `grep`, `glob`.
Available: `read`, `write`, `shell`, `code`, MCP tools.

The orchestrator prompt correctly lists the unavailable tools (except
it says "MCP tools" are available, which conflicts with the config).

### Subagent Concurrency

The built-in tools reference page says "up to 4 subagents simultaneously,"
but this appears outdated or inaccurate — the config author has observed
10+ concurrent subagents in practice. The actual concurrency limit is
either higher than documented or configurable. No configuration parameter
for a concurrency cap exists in the docs. Treat the "4" as unreliable.

### trustedAgents vs availableAgents

- `availableAgents`: access control — only listed agents can be spawned
- `trustedAgents`: auto-approval — listed agents bypass permission prompts
- Both support glob patterns

### Missing Agent Behavior

The docs do not explicitly state what happens when `availableAgents`
references a nonexistent agent. The general pattern suggests **silent
degradation** rather than hard errors, but this should be tested.

### Skill Loading

- `file://` resources are loaded into context at spawn time (eager)
- `skill://` resources load metadata at spawn, full content on invocation
  (lazy)

This means the 12 skills on the orchestrator only consume full context
tokens when activated, not at session start. The context budget estimate
should be revised downward for skills.

### Recommendation: Reference Kiro Docs During Implementation

When fixing findings from this audit, consult the official Kiro CLI docs:
- Custom agents: https://kiro.dev/docs/cli/custom-agents/
- Configuration reference: https://kiro.dev/docs/cli/custom-agents/configuration-reference/
- Hooks: https://kiro.dev/docs/cli/hooks/
- Subagents: https://kiro.dev/docs/cli/chat/subagents/
- Built-in tools: https://kiro.dev/docs/cli/reference/built-in-tools/
- Troubleshooting: https://kiro.dev/docs/cli/custom-agents/troubleshooting/

---

## Workflow Analysis: What Happens When You Use This

### Scenario 1: "Add a new Python feature with tests"

**Expected flow:**
1. User asks → orchestrator activates `design-and-spec` skill
2. Design approved → `writing-plans` creates plan
3. Plan reviewed → `execution-planning` generates stages
4. Stages dispatched via `subagent-driven-development`
5. `dev-python` implements with TDD
6. Post-implementation: quality gate, review, improvement capture
7. User approves → orchestrator commits via commit skill

**What actually happens:**
- Step 5: TDD may not fire due to global "no auto tests" rule (CRITICAL-04)
- Step 5: `dev-python` can't look up library docs via Context7 (HIGH-04)
- Step 6: Post-implementation fires but doesn't list `dev-python`... wait,
  it does list `dev-python`. OK, this works.
- Step 7: Quality gate runs `uv run pytest` → this works.

**Verdict:** Works mostly, but TDD is unreliable.

### Scenario 2: "Fix this bug in the shell script"

**Expected flow:**
1. User reports bug → orchestrator routes to `dev-shell`
2. `dev-shell` uses `systematic-debugging` skill
3. Debug → fix → verify
4. Post-implementation runs

**What actually happens:**
- Step 2: `dev-shell` has `systematic-debugging` → good
- Step 3: No TDD skill means the bug fix has no regression test (CRITICAL-04)
- Step 4: Quality gate runs `shellcheck` on changed files → good

**Verdict:** Bug gets fixed but regression testing is missing.

### Scenario 3: "Refactor this large Python module"

**Expected flow:**
1. Orchestrator runs codebase-audit
2. Dispatches dev-reviewer for deep analysis
3. User approves findings
4. Dispatches dev-refactor with approved items
5. Post-refactor review

**What actually happens:**
- Step 4: `dev-refactor` has TDD but no debugging skill (HIGH-08)
- Step 4: If refactoring breaks something, no systematic diagnosis methodology
- Step 4: `dev-refactor` loads ALL 11 steering docs including irrelevant ones (MEDIUM-01)

**Verdict:** Works but debugging gaps and wasted context.

### Scenario 4: Team member on a different machine uses this

**Expected flow:**
1. Clone, symlink, personalize, verify
2. Start working

**What actually happens:**
- Improvement capture writes to `~/personal/kiro-config/docs/...` which
  doesn't exist on their machine (HIGH-12)
- `dev-kiro-config` ghost agent in available list (HIGH-02)
- If they use `bun` projects, quality gate hardcodes `npm` (HIGH-06)

**Verdict:** Partially broken for team use.

---

## Prompt, Steering, and Skill Improvement Analysis

This section provides detailed improvement recommendations for every prompt,
steering document, and skill. Each item is specific enough for Kiro CLI to
generate implementation plans and specs from.

---

### PROMPTS: Cross-Cutting Issues

These issues affect ALL or MOST subagent prompts and should be resolved
systematically rather than per-agent.

#### PROMPT-CROSS-01: No Subagent Self-Awareness

**Problem:** No subagent prompt states: "You are a subagent invoked by an
orchestrator. You receive tasks in a 5-section delegation format (Objective,
Context, Constraints, Definition of Done, Skill Triggers). You report back
using one of: DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED."

**Impact:** The agent doesn't know it's operating in a managed context, doesn't
know the user isn't talking to it directly, and cannot reliably parse the
delegation format because it was never told what format to expect.

**Fix:** Add a standard preamble block to every subagent prompt:
```
## Operating Context
You are a specialist subagent invoked by an orchestrator agent. You receive
tasks in a structured delegation format with: Objective, Context, Constraints,
Definition of Done, and Skill Triggers. The user does not interact with you
directly — the orchestrator mediates all communication.
```

#### PROMPT-CROSS-02: Zero Tool Awareness

**Problem:** Not a single subagent prompt lists the tools available to it.
The orchestrator prompt mentions tool constraints (line 117-118) but subagents
themselves are never told. A subagent might attempt to use `grep` or `glob`
(unavailable), or might not know it has `shell` access.

**Fix:** Add to each subagent prompt:
```
## Available Tools
You have: read (files), write (files), shell (bash commands), code (search).
You do NOT have: web_search, web_fetch, grep, glob, introspect, aws.
If you need data from tools you lack, report NEEDS_CONTEXT.
```

#### PROMPT-CROSS-03: DONE_WITH_CONCERNS Never Defined

**Problem:** Every prompt lists DONE_WITH_CONCERNS as a valid status but no
prompt defines what constitutes a "concern." Only refactor.md says "if a
finding can't be fixed without changing behavior." All other prompts leave
it undefined, causing inconsistent usage.

**Fix:** Add a standard definition:
```
Report DONE_WITH_CONCERNS when: the task is complete but you observed
something the orchestrator should know — a design smell, a potential
edge case, a limitation in the approach, or a deviation from the plan.
Include a "Concerns:" section listing each item.
```

#### PROMPT-CROSS-04: NEEDS_CONTEXT Lifecycle Undefined

**Problem:** Subagents can report NEEDS_CONTEXT, and the orchestrator
receives it. But the full lifecycle is undefined:
- Subagent: what happens after reporting? Wait? Terminate?
- Orchestrator: gather what context? Re-delegate with same or new briefing?

**Fix:** Define in both the orchestrator prompt and subagent preamble:
- Subagent: "After reporting NEEDS_CONTEXT, include exactly what information
  you need and why. Then stop — do not proceed with assumptions."
- Orchestrator: "When receiving NEEDS_CONTEXT, gather the requested
  information, add it to the Context section, and re-dispatch."

#### PROMPT-CROSS-05: No Error Recovery Guidance

**Problem:** Most subagent prompts have near-zero error handling. What to
do when: tests fail after implementation? A required tool isn't installed?
A shell command fails? A file can't be found? An edit produces invalid syntax?

**Fix:** Add a standard error handling block:
```
## When Things Go Wrong
- Tool not installed (ruff, mypy, eslint, etc.): report DONE_WITH_CONCERNS
  noting which checks were skipped. Do not fail the entire task.
- Tests fail after implementation: debug systematically (if you have the
  debugging skill) or report DONE_WITH_CONCERNS with the failure output.
- File not found: report NEEDS_CONTEXT with the expected path.
- Shell command error: read the error message, attempt one fix, and if
  that fails, report BLOCKED with full error output.
```

#### PROMPT-CROSS-06: No "Too Large" Threshold

**Problem:** Several prompts say "If the task is too large, report BLOCKED"
but never define "too large." The LLM interprets this differently every time.

**Fix:** Add a concrete heuristic:
```
Report BLOCKED if the task requires modifying more than 10 files, or if you
estimate it would take more than 15 minutes of focused work. Suggest a
breakdown into smaller tasks.
```

#### PROMPT-CROSS-07: Orchestrator Doesn't Know Its Own Write Constraints

**Problem:** The orchestrator prompt says "You never write code" but doesn't
communicate the `fs_write.allowedPaths` constraints from its JSON config.
The LLM doesn't know it can only write to docs/markdown/plan files. With
`~/personal/**` and `~/eam/**` in allowedPaths, it technically CAN write
code files — contradicting its own prompt.

**Fix:** Add to orchestrator prompt:
```
## Your Write Scope
You may write to: plan files, spec files, improvement logs, and
documentation (markdown, JSON configs). You must NOT write source code
(.py, .ts, .sh, .html, .css) — delegate all code changes to subagents.
```

---

### PROMPTS: Per-Agent Improvements

#### orchestrator.md

| # | Issue | Improvement |
|---|---|---|
| O-1 | "If none match, handle directly" is unbounded | Add: "If no routing pattern matches and the task involves writing code, ask the user which specialist to use. Never attempt code yourself." |
| O-2 | Post-implementation referenced but not inlined | Add a 3-line summary: "Post-implementation runs: quality gate (lint/test), auto-review (dev-reviewer), doc staleness check, improvement capture. Do not skip." |
| O-3 | No handling for subagent crashes/hangs | Add: "If a subagent does not return within a reasonable time, investigate by checking the task scope. Consider re-dispatching to a different agent." |
| O-4 | "Adding New Specialists" tells LLM to guess | Change to: "If an available agent is not in this routing table, ask the user for routing guidance before dispatching." |
| O-5 | Subagent tool list claims MCP access | Fix line 118 to: "Subagents CAN use: read, write, shell, code. They CANNOT use: web_search, web_fetch, use_aws, grep, glob, introspect, MCP tools. Pre-fetch library docs if the task needs them." (Or enable MCP on subagents — see HIGH-04.) |
| O-6 | dev-reviewer has no write tool but prompt says subagents "CAN use write" | Add footnote: "Exception: dev-reviewer is read-only — no write tool." |
| O-7 | No mention of hooks protecting tool calls | Add: "Your shell and file-write operations are guarded by security hooks (secret scanning, write protection). If a hook blocks an action, read the block message and adjust — do not retry." |

#### python-dev.md (after dedup with steering — target ~40-60 lines)

| # | Issue | Improvement |
|---|---|---|
| P-1 | Duplicates ~15 rules from steering | Remove all rules already in `python-boto3.md`, `tooling.md`, and `design-principles.md`. Keep ONLY: identity, workflow, status reporting, "before editing" block, "what you never do" list. Reference: "Follow Python standards from steering docs." |
| P-2 | "Verify everything works" is vague | Replace with: "Run `uv run ruff check .`, `uv run pytest tests/ -q`, and `uv run mypy .` before reporting DONE. If any tool is not installed, note it in your report." |
| P-3 | No prohibition on adding dependencies | Add to "never do": "Add new dependencies without including them in the Objective. If a task requires a new package, report NEEDS_CONTEXT." |
| P-4 | No file-count guardrail | Add: "If your changes touch more than 8 files, pause and report DONE_WITH_CONCERNS explaining the scope." |
| P-5 | "ruff check" — unclear if auto-fix | Clarify: "Run `ruff check .` to identify issues, then `ruff check --fix .` to auto-fix safe issues. Report any remaining issues." |

#### shell-dev.md (after dedup — target ~40-50 lines)

| # | Issue | Improvement |
|---|---|---|
| S-1 | Duplicates ~12 rules from steering | Remove all rules already in `shell-bash.md` and `tooling.md`. Keep ONLY: identity, workflow, status reporting, "what you never do." |
| S-2 | Near-zero error handling guidance | Add the standard error handling block (PROMPT-CROSS-05). |
| S-3 | No status protocol explanation | Add full status definitions with guidance on when to use each. |
| S-4 | Missing guardrail: script content safety | Add to "never do": "Write scripts containing `rm -rf`, hardcoded credentials, or commands that modify production infrastructure. Scripts should be safe to run." |
| S-5 | "Test with representative inputs" is vague | Replace with: "Run the script with at least one valid input and one edge case (empty input, missing file, invalid argument). Verify exit codes." |
| S-6 | Missing TDD consideration | Add: "If the project uses bats-core or shunit2 for shell testing, write tests first following the TDD skill. If no test framework exists, test manually and note the lack of automated tests in your report." |

#### typescript-dev.md (after dedup — target ~40-50 lines)

| # | Issue | Improvement |
|---|---|---|
| T-1 | Duplicates ~14 rules from steering | Remove all rules already in `typescript.md`, `tooling.md`, and `web-development.md`. Keep ONLY: identity, workflow, status reporting, "before editing," "what you never do." |
| T-2 | No prohibition on modifying tsconfig.json | Add to "never do": "Modify `tsconfig.json` to weaken type checking (e.g., disabling `strict`, adding `skipLibCheck`)." |
| T-3 | Assumes eslint/prettier are configured | Add: "If ESLint or Prettier config is not present, skip those checks and note it in your report. Do not create linting configs unless the task requires it." |

#### frontend-dev.md (after dedup — target ~40-50 lines)

| # | Issue | Improvement |
|---|---|---|
| F-1 | Duplicates ~12 rules from steering | Remove all rules already in `frontend.md`. Keep ONLY: identity, workflow, verification checklist, status reporting, "what you never do." |
| F-2 | "No console.log in production code" — ambiguous | Replace with: "No `console.log`. Use structured error reporting for error states. Remove all debug logging before reporting DONE." |
| F-3 | No mention of build tooling | Add: "Check for existing build config (vite.config.ts, webpack.config.js). Follow the project's build setup — do not introduce a new bundler." |
| F-4 | "Vanilla TypeScript only" not scoped as project-default | Reframe: "Default to vanilla TypeScript for DOM manipulation. If the project uses a framework (React, Vue, etc.), follow the existing framework patterns." |
| F-5 | No CDN/external script prohibition | Add to "never do": "Include external scripts via CDN without explicit approval. Prefer local dependencies." |
| F-6 | Missing browser compatibility guidance | Add: "Target evergreen browsers (Chrome, Firefox, Safari, Edge — latest 2 versions). If the project has a `.browserslistrc`, follow it." |

#### code-reviewer.md

| # | Issue | Improvement |
|---|---|---|
| R-1 | "Rubber-stamp reviews" grammar ambiguity | Change the "never do" list to use explicit format: "Never: approve without justification (rubber-stamp). Never: soften security findings to be polite." |
| R-2 | NEEDS_DISCUSSION has no mapping to status protocol | Add: "After your review, report your status: APPROVE → DONE, REQUEST_CHANGES → DONE_WITH_CONCERNS (include findings), NEEDS_DISCUSSION → NEEDS_CONTEXT (include the questions that need discussion)." |
| R-3 | "Agent config checklist" is kiro-config-specific | Move to project-level `.kiro/steering/` or a kiro-config-specific steering doc. The reviewer prompt should be project-agnostic. |
| R-4 | No guidance on running tools safely | Add: "When running linters/test suites for review, be aware that tests may have side effects (database writes, API calls). Review test code before executing. If tests appear to modify external state, report this as a finding rather than running them." |
| R-5 | No guidance for unreadable/too-large codebases | Add: "If the codebase exceeds your context capacity, prioritize: files changed in the last 30 days, files >300 lines, files with no tests. Cap report at 20 findings." (This exists in the prompt but only for "codebase scan mode" — make it the default behavior.) |

#### refactor.md

| # | Issue | Improvement |
|---|---|---|
| RF-1 | "One refactoring move" undefined | Add examples: "One move = one rename, one extract-function, one inline-variable, or one move-to-file. A move that touches call sites in other files counts as one move if the signature is unchanged." |
| RF-2 | Boy-Scout Rule conflicts with "don't introduce new conventions" | Resolve: "Fix lint warnings and formatting in files you touch (Boy-Scout Rule). Do NOT change coding patterns, naming conventions, or architectural approaches unless that is the explicit refactoring goal." |
| RF-3 | No escalation when reviewer findings are wrong | Add: "If a review finding seems incorrect, verify it by reading the code. If the finding is indeed wrong, report DONE_WITH_CONCERNS explaining why you believe the finding is a false positive. Do not silently skip findings." |
| RF-4 | Missing debugging skill noted in HIGH-08 | Add systematic-debugging skill to resources. Add to workflow: "If a refactoring move causes test failures, use the systematic-debugging skill before attempting further moves." |

#### docs.md (WEAKEST PROMPT — needs the most work)

| # | Issue | Improvement |
|---|---|---|
| D-1 | Identity too vague ("file editor") | Change to: "You are a documentation and configuration specialist. You edit markdown, JSON, YAML, TOML, and text files. You do not write executable code." |
| D-2 | No status protocol at all | Add the full 4-status block with definitions. |
| D-3 | No "what you never do" section | Add: "Never: run Python/Node/shell scripts, install packages, modify source code (.py, .ts, .sh), push to git, commit, delete files (use NEEDS_CONTEXT to ask the orchestrator to handle deletions)." |
| D-4 | Doesn't know it can't delete files | Add: "You cannot delete files — your shell deny list blocks `rm`. If a task requires file deletion, report NEEDS_CONTEXT and the orchestrator will handle it." |
| D-5 | No "before editing" block | Add the standard 3-question block used by other dev agents: "Before editing any file: 1. Read it first. 2. What is the minimal change? 3. Will this break any references?" |
| D-6 | "strReplace" is tool-specific jargon | Replace with: "Use targeted text replacements (find-and-replace), not full file rewrites. Only rewrite a file if more than 50% of its content changes." |
| D-7 | Only 30 lines total | After adding the above, target ~50-60 lines — still the most lightweight prompt, but no longer the thinnest. |

---

### STEERING: Cross-Cutting Issues

#### STEER-CROSS-01: No Priority Hierarchy

**Problem:** No document declares its rank. When `universal-rules.md` says
infrastructure is read-only but `engineering.md` says "test every flag
end-to-end," which wins? No tiebreaker exists.

**Fix:** Add to the top of `universal-rules.md`:
```
## Priority
This document overrides all other steering documents when in conflict.
Priority order: universal-rules.md > security.md > engineering.md >
design-principles.md > domain-specific docs (python-boto3, typescript, etc.).
Project-level .kiro/steering/ overrides global steering for that project.
```

#### STEER-CROSS-02: No Override Mechanism for Projects

**Problem:** Rules like "no framework — vanilla TypeScript only" and "no
Tailwind" in `frontend.md` are presented as absolute. Projects that
legitimately need React, Tailwind, or `docker build` have no documented
escape hatch.

**Fix:** Add a standard override clause to each opinionated rule:
```
Default: vanilla TypeScript for DOM manipulation.
Override: If the project uses a framework (check for react, vue, svelte
in package.json), follow the framework patterns instead.
```

Also add to `universal-rules.md`:
```
## Project Overrides
Project-level `.kiro/steering/` files can override global steering rules
for that project. When a project steering doc contradicts a global doc,
the project doc wins for work within that project.
```

#### STEER-CROSS-03: Duplicate Content Across Domain Docs and tooling.md

**Problem:** `tooling.md` duplicates rules from `shell-bash.md`,
`typescript.md`, `web-development.md`, and `python-boto3.md`. This creates
guaranteed drift.

**Fix:** Make `tooling.md` a reference index that NAMES the tools and
points to the domain doc for rules:
```
## Python
Tools: uv, ruff, mypy, pytest, bandit. See python-boto3.md for patterns.

## Shell
Tools: shellcheck, shfmt. See shell-bash.md for patterns.
```

Keep ONLY cross-cutting rules in `tooling.md`: conventional commits, JSON
via jq, project-specific env detection, Context7 before WebFetch.

---

### STEERING: Per-Document Improvements

#### universal-rules.md

| # | Issue | Improvement |
|---|---|---|
| U-1 | No priority declaration | Add priority hierarchy (STEER-CROSS-01) |
| U-2 | `show-*` absent from AWS allow table but present in aws-cli.md | Add `show-*` to the universal-rules allow list, or remove from aws-cli.md |
| U-3 | No override mechanism | Add project-override clause (STEER-CROSS-02) |
| U-4 | AWS `s3` verbs not covered | Add `s3 ls`, `s3 presign` as allowed; `s3 cp`, `s3 mv`, `s3 rm`, `s3 sync` as blocked |

#### engineering.md

| # | Issue | Improvement |
|---|---|---|
| E-1 | "Fix ALL lint errors everywhere" vs design-principles incrementalism | Resolve: "Fix lint errors in files you modified. For pre-existing errors in untouched files, fix only if the change is trivial (unused import, trailing whitespace)." |
| E-2 | "3+ steps = plan first" — what counts as a "step"? | Clarify: "A step is a distinct unit of work that could be delegated independently. Renaming a variable across 5 files = 1 step. Adding a new feature with tests and docs = 3+ steps." |
| E-3 | TDD declared absolute with no exceptions | Add: "TDD applies to all code in projects with existing test infrastructure. For one-shot scripts, infrastructure configs, and documentation, TDD does not apply." |
| E-4 | "Test every CLI flag end-to-end" impractical for production envs | Add: "End-to-end testing should target development/staging environments. Never test against production resources. If no dev environment exists, test with --dry-run or mocked endpoints." |
| E-5 | Missing rollback strategy | Add: "If a deployed change fails, the first action is `git revert` to the last known good state, not debugging in production." |

#### design-principles.md

| # | Issue | Improvement |
|---|---|---|
| DP-1 | Python-specific examples in a language-agnostic doc | Generalize `sys.exit()` example: "Library code returns errors, never terminates the process. Only entry points (main, CLI handlers) may exit." Add language-neutral examples alongside Python ones. |
| DP-2 | 300-line threshold — counts comments? blank lines? | Clarify: "300 lines of non-comment, non-blank code. Use `wc -l` as a rough guide, not an exact threshold." |
| DP-3 | No concurrency/state management principles | Add if relevant to current projects: "Prefer immutable data. Isolate mutable state. Use explicit synchronization (locks, queues) over implicit shared state." |
| DP-4 | No priority between conflicting principles | Add: "When KISS and SoC conflict (splitting a file increases complexity), prefer the option that makes the code easier to understand in 6 months." |

#### security.md

| # | Issue | Improvement |
|---|---|---|
| SEC-1 | No logging/audit requirements | Add: "All security-relevant actions must be logged: authentication attempts, authorization failures, data access, configuration changes." |
| SEC-2 | No HTTP security headers | Add: "Web applications must set: Content-Security-Policy, X-Content-Type-Options: nosniff, Strict-Transport-Security, X-Frame-Options." |
| SEC-3 | "Self-signed certs" too absolute | Change to: "No self-signed certs without a private CA. Internal service mesh using private CA with mTLS is acceptable." |
| SEC-4 | No environment-specific relaxation | Add: "Development and sandbox environments may relax MFA and IAM restrictions. Staging must mirror production security. Pre-production and production are strict." |

#### tooling.md (after dedup)

| # | Issue | Improvement |
|---|---|---|
| TL-1 | Duplicates shell-bash, typescript, python-boto3 | Convert to a reference index per STEER-CROSS-03. Keep only cross-cutting rules. |
| TL-2 | "sed/awk on JSON" — what about YAML/TOML? | Extend: "Never use sed/awk on structured data formats (JSON, YAML, TOML). Use `jq` for JSON, `yq` for YAML, purpose-built parsers for TOML." |
| TL-3 | No mention of when to add vs avoid dependencies | Add: "Prefer stdlib over third-party when functionality is equivalent. New dependencies require justification in the plan or commit message." |
| TL-4 | Package manager should be lockfile-detected | Change: "Check project lockfile to determine package manager: `bun.lockb` → bun, `package-lock.json` → npm, `yarn.lock` → yarn, `pnpm-lock.yaml` → pnpm. Default to npm for new projects." |

#### aws-cli.md

| # | Issue | Improvement |
|---|---|---|
| AWS-1 | Only 24 lines — too thin for primary cloud platform | Expand with: s3 verb coverage, sts command guidance, expired SSO handling, `--profile` usage, CloudWatch Logs query patterns |
| AWS-2 | No LocalStack or dev environment guidance | Add: "For local development with LocalStack, use `--endpoint-url http://localhost:4566`." |
| AWS-3 | No guidance on `--profile` | Add: "Use named profiles (`--profile dev-admin`) rather than default credentials. Never assume the default profile is correct." |

#### typescript.md

| # | Issue | Improvement |
|---|---|---|
| TS-1 | Internal conflict: reverse notation snake_case vs camelCase | Resolve: Either adopt `usersActive` (camelCase reversed) or declare reverse notation uses snake_case as an exception to the camelCase rule. Recommend: drop reverse notation for TypeScript — it fights the ecosystem. |
| TS-2 | Express patterns duplicated with web-development.md | Move ALL Express patterns to `web-development.md`. Keep `typescript.md` focused on language-level rules (types, strict mode, ESLint, Vitest). |
| TS-3 | "Interfaces over type aliases" is outdated advice | Update: "Use interfaces for object shapes that may be extended. Use type aliases for unions, intersections, mapped types, and utility types. Both are acceptable for simple object shapes." |
| TS-4 | No guidance on monorepo configs | Add if relevant: "For monorepos, use project references in tsconfig.json. Each package gets its own tsconfig extending a shared base." |

#### frontend.md

| # | Issue | Improvement |
|---|---|---|
| FE-1 | `as HTMLInputElement` conflicts with typescript.md "no as" | Add scope clarifier to typescript.md: "Never use `as` to bypass data validation (API responses, user input). Type assertions are acceptable for DOM element narrowing after a null check." |
| FE-2 | "No framework" not scoped as default | Change: "Default: vanilla TypeScript. Override: if project uses a framework, follow its patterns." |
| FE-3 | Chart.js section is oddly narrow | Generalize to: "Data Visualization" with Chart.js as the default, and guidance for when other libraries (D3, Recharts) are in the project. |
| FE-4 | Missing build/bundle guidance | Add: "Follow the project's existing build configuration. Do not introduce a new bundler." |
| FE-5 | No testing guidance | Add: "If the project uses Vitest + happy-dom or jsdom for DOM testing, write tests for interactive components. If no DOM testing setup exists, note this in your verification report." |
| FE-6 | Verification Checklist pattern is excellent | Consider replicating this pattern in other domain steering docs. |

#### web-development.md

| # | Issue | Improvement |
|---|---|---|
| WD-1 | Significant Express pattern overlap with typescript.md | After TS-2, this becomes the single source for Express patterns. Verify no orphaned references. |
| WD-2 | Missing pagination patterns | Add: "API list endpoints must support pagination. Default: cursor-based with `?cursor=X&limit=N`. Include `next_cursor` in response." |
| WD-3 | Missing health check endpoint | Add: "Every service must expose `GET /health` returning 200 with `{ status: "ok" }`. Include dependency health checks (database, cache)." |
| WD-4 | Missing rate limiting | Add: "Public API endpoints should have rate limiting. Use express-rate-limit or equivalent middleware." |
| WD-5 | No graceful shutdown | Add: "Handle SIGTERM: stop accepting new requests, complete in-flight requests (30s timeout), then exit." |

#### python-boto3.md

| # | Issue | Improvement |
|---|---|---|
| PB-1 | Missing client vs resource guidance | Add: "Prefer `boto3.client()` over `boto3.resource()` for explicitness. Resource is acceptable for S3 file operations where the API is simpler." |
| PB-2 | Missing ThrottlingException handling | Add: "Handle `ThrottlingException` explicitly with exponential backoff. Use `botocore.config.Config(retries={'max_attempts': 5, 'mode': 'adaptive'})` as default." |
| PB-3 | Missing test mocking guidance | Add: "Use `moto` for boto3 mocking in tests. Prefer `moto` over `stubber` for integration-level tests. Use `stubber` only for unit-testing specific error paths." |
| PB-4 | No Lambda vs long-running distinction | Add: "Lambda functions: use module-level client initialization for connection reuse. Long-running services: create clients per-request or use connection pooling." |

#### shell-bash.md

| # | Issue | Improvement |
|---|---|---|
| SH-1 | Missing temp file patterns | Add: "Use `mktemp` for temporary files. Always pair with `trap 'rm -f "$tmpfile"' EXIT`. Never hardcode `/tmp/myfile`." |
| SH-2 | Missing parallel execution guidance | Add: "For parallel operations, prefer `xargs -P` over background jobs with `&`. Always set a concurrency limit." |
| SH-3 | macOS Bash 3.2 compatibility gap | Add: "Scripts targeting macOS must account for Bash 3.2 (no associative arrays, no `|&`, no `readarray`). Use `#!/usr/bin/env bash` with a minimum version check if Bash 4+ features are required." |

---

### SKILLS: Cross-Cutting Issues

#### SKILL-CROSS-01: "Fix any failures before proceeding" Anti-Pattern

**Problem:** Appears in `python-audit`, `typescript-audit`, and
`codebase-audit`. It compresses an entire debugging/fixing workflow into
one sentence, forcing the LLM to improvise.

**Fix:** Replace each occurrence with: "If automated checks fail, report
the failures in your audit findings with severity CRITICAL. Do not attempt
to fix them — the orchestrator will dispatch the appropriate specialist."

#### SKILL-CROSS-02: Inconsistent Retry/Loop Limits

**Problem:** Three skills have explicit caps (post-implementation: 3,
writing-plans: 3, systematic-debugging: 3). Two have implicit infinite
loops (subagent-driven-development review loops, design-and-spec revision
loops).

**Fix:** Add to `subagent-driven-development`: "Max 3 review iterations
per task. If spec compliance or code quality still fails after 3 rounds,
surface to user."

Add to `design-and-spec`: "Max 5 design iterations. If the user hasn't
approved after 5 rounds, stop and ask: 'We've iterated 5 times. Should
we continue refining, simplify the scope, or take a different approach?'"

#### SKILL-CROSS-03: No "Skill Not Applicable" Handling

**Problem:** Most skills assume they're appropriate for the current context.
If invoked incorrectly, they proceed anyway.

**Fix:** Add to each skill a pre-check:
```
## Applicability Check
Before proceeding, verify this skill applies:
- [skill-specific condition]
If this skill does not apply, say so and suggest the correct skill.
```

#### SKILL-CROSS-04: Duplicated Quality Gate Logic

**Problem:** The quality gate (ruff/pytest/mypy for Python; eslint/tsc/vitest
for TS) is defined in post-implementation, python-audit, typescript-audit,
and codebase-audit. Four places to update when a command changes.

**Fix:** Have post-implementation reference the audit skills rather than
duplicating: "For Python projects, invoke the python-audit quality checks.
For TypeScript, invoke the typescript-audit quality checks." This makes
the audit skills the single source of truth for tool commands.

#### SKILL-CROSS-05: Missing Rationalization Prevention in 14 of 18 Skills

**Problem:** Only 4 skills have strong anti-bypass language: TDD,
verification-before-completion, systematic-debugging, receiving-code-review.
The other 14 are vulnerable to the LLM taking shortcuts.

Skills most at risk:
- `python-audit`/`typescript-audit`: can report "no issues" without
  completing the checklist
- `dispatching-parallel-agents`: can parallelize dependent tasks
- `trace-code`: can produce a shallow trace
- `agent-audit`: can produce a thin report

**Fix:** Add a minimum anti-bypass clause to every skill:
```
## Completion Integrity
Do not skip steps. If a step cannot be completed, explain why rather than
silently omitting it. Every section of the output must contain findings
OR an explicit "No issues found — checked [what was checked]" statement.
```

---

### SKILLS: Per-Skill Improvements

#### post-implementation/SKILL.md

| # | Issue | Improvement |
|---|---|---|
| PI-1 | Trigger list mismatches orchestrator (CRITICAL-05) | Add `dev-kiro-config` and `dev-frontend` to trigger list |
| PI-2 | Quality gate duplicates audit skills | Replace hardcoded commands with: "Run the python-audit or typescript-audit quality checks based on project type" |
| PI-3 | Step 3 "dispatch dev-docs or flag for user" is ambiguous | Change to: "Flag stale docs for the user. Do not auto-dispatch dev-docs — let the user decide whether doc updates are needed now or later." |
| PI-4 | No explicit exit statement | Add: "After presenting results (Step 7), you are DONE. Do not continue to the next task — the orchestrator decides what's next." |

#### subagent-driven-development/SKILL.md

| # | Issue | Improvement |
|---|---|---|
| SDD-1 | No review loop limit | Add: "Max 3 review iterations per task (spec + quality combined). After 3 rounds, surface unresolved issues to user." |
| SDD-2 | Model selection is aspirational | Either remove or add: "Note: model selection may be constrained by platform. If you cannot control the model, proceed with the available model." |
| SDD-3 | "Concerns about correctness vs observations" unclear | Add examples: "Correctness concern: 'The edge case for empty input is not handled.' Observation: 'This file is growing large and might benefit from splitting later.'" |

#### design-and-spec/SKILL.md

| # | Issue | Improvement |
|---|---|---|
| DS-1 | No iteration cap on design revision | Add: "Max 5 design iterations before asking user to simplify scope or take a different approach." |
| DS-2 | No spec template | Add a minimal template showing required sections: Problem, Constraints, Proposed Design, Alternatives Considered, Open Questions, Approval Gate. |
| DS-3 | "Have strong opinions, held loosely" is vague | Replace with: "Propose your recommended approach first. If the user pushes back, present alternatives. After 2 rounds of disagreement, implement the user's preference." |

#### execution-planning/SKILL.md

| # | Issue | Improvement |
|---|---|---|
| EP-1 | "Skip for trivial tasks" conflicts with writing-plans always invoking it | Add: "If the plan has only 1-2 tasks for a single agent, skip execution-planning and dispatch directly via subagent-driven-development." Update writing-plans to match. |
| EP-2 | No filled-in example plan | Add a concrete example showing a real 3-stage plan with parallel tasks, dependencies, and review gates. |
| EP-3 | Routing table reference is implicit | Add: "Use the orchestrator's routing table (in the orchestrator prompt) to assign agents. If unsure, default to dev-python for .py, dev-typescript for .ts, dev-shell for .sh, dev-docs for .md/.json." |

#### systematic-debugging/SKILL.md

| # | Issue | Improvement |
|---|---|---|
| SD-1 | No requirement to capture initial state | Add to Phase 1: "Before making any changes, capture the current state: `git stash` or `git diff > /tmp/debug-baseline.diff`. You must be able to return to this state." |
| SD-2 | No hypothesis iteration limit (separate from fix limit) | Add: "Max 5 hypotheses before escalating. If 5 different hypotheses all fail to explain the behavior, the problem is likely architectural." |

#### writing-plans/SKILL.md

| # | Issue | Improvement |
|---|---|---|
| WP-1 | "plan-reviewer" is not a real agent (HIGH-14) | Change to: "Dispatch dev-reviewer with the plan and spec for review." |
| WP-2 | "Follow established patterns" vs "prefer smaller files" conflict | Resolve: "Follow the codebase's existing file organization. Only restructure files if that is explicitly part of the plan." |
| WP-3 | No complete plan example | Add a short but complete example plan (3-4 tasks) showing the full format with TDD steps, file mappings, and before/after grep targets. |

#### commit/SKILL.md

| # | Issue | Improvement |
|---|---|---|
| CM-1 | Branch naming assumes `feature/TICKET-ID` | Generalize: "Extract ticket ID from branch name by taking the segment after the last `/`. Works for: `feature/JIRA-123`, `fix/BUG-456`, `chore/TASK-789`." |
| CM-2 | Secret patterns are hardcoded | Add: "These patterns cover common secret types. If the project has custom secret formats, add them to `~/.kiro/hooks/scan-secrets.sh`." |

#### push/SKILL.md

| # | Issue | Improvement |
|---|---|---|
| PU-1 | "Read project steering for push constraints" is vague | Change to: "Check `steering/universal-rules.md` for branch and push constraints. Check project-level `.kiro/steering/` for additional restrictions." |
| PU-2 | Hardcodes `origin` as remote name | Change to: "Push to the tracking remote (usually `origin`). If no tracking remote is set, list remotes with `git remote -v` and push to the primary remote." |
| PU-3 | No handling for diverged branches | Add: "If the push is rejected because the remote has new commits, report BLOCKED: 'Remote has diverged. Pull and resolve before pushing.'" |

#### python-audit/SKILL.md and typescript-audit/SKILL.md

| # | Issue | Improvement |
|---|---|---|
| AUD-1 | "Fix any failures before proceeding" (SKILL-CROSS-01) | Replace with: "Report failures as findings. Do not fix." |
| AUD-2 | No pre-check for tool availability | Add Step 0: "Verify tools are installed: run `which ruff mypy pytest` (Python) or `npx --yes eslint --version` (TS). Skip unavailable checks and note them in report." |
| AUD-3 | No rationalization prevention | Add: "You must complete EVERY checklist item. For each item, report either a finding or 'Checked — no issues.' Do not skip items." |
| AUD-4 | `<package>/` placeholder unexplained in python-audit | Add: "Replace `<package>` with the project's main package directory (found in `pyproject.toml` under `[tool.mypy]` or as the directory containing `__init__.py`)." |

#### agent-audit/SKILL.md

| # | Issue | Improvement |
|---|---|---|
| AA-1 | Phase 9.5 numbering is awkward | Renumber to sequential phases (1-11). |
| AA-2 | No report size cap | Add: "Cap total report at 30 findings. Prioritize by severity: CRITICAL first, then IMPORTANT, then SUGGESTION." |
| AA-3 | "Check /help, introspect" — runtime commands in a file-reading context | Remove or replace with: "Review the Kiro CLI docs for new features that may affect the config." |
| AA-4 | No anti-bypass clause | Add: "Every phase must produce findings OR an explicit 'No issues found' with what was checked." |

#### dispatching-parallel-agents/SKILL.md

| # | Issue | Improvement |
|---|---|---|
| DPA-1 | No delegate failure handling | Add: "If a delegate fails: assess whether the failure affects other delegates. If yes, halt all delegates. If no, continue with successful delegates and re-dispatch or escalate the failed one." |
| DPA-2 | No partial failure protocol | Add: "If some delegates succeed and others fail: commit successful changes, then address failures separately. Do not roll back successful work." |
| DPA-3 | No documented concurrency guidance | Add: "When dispatching many parallel delegates, monitor for resource contention (file locks, shared test databases). If delegates interfere, reduce concurrency or sequence dependent groups." |
| DPA-4 | "3+ test files" chicken-and-egg for parallelization | Clarify: "You don't need to diagnose root causes before parallelizing. If failures are in different files/subsystems, they are likely independent. Parallelize first; if delegates discover shared causes, consolidate." |

#### trace-code/SKILL.md and explain-code/SKILL.md

| # | Issue | Improvement |
|---|---|---|
| TC-1 | No depth limit for tracing | Add: "Trace to a maximum depth of 5 call levels. For deeper chains, summarize the lower levels rather than tracing line-by-line." |
| TC-2 | No handling for code too large to trace | Add: "If the codebase exceeds context capacity, trace only the critical path. Note which branches were not traced." |
| EC-1 | No handling for large/complex code | Add: "If the code is too large for a single explanation, break it into logical sections and explain each. Tell the user: 'This is section 1 of N.'" |

---

## Duplication Assessment

### Good Duplication (Keep)

| What | Why Keep |
|---|---|
| `deniedCommands` across agent JSONs | Security-critical, per-agent variance |
| `deniedPaths` across agent JSONs | Security-critical, per-agent variance |
| "verify before completing" in every agent | Reinforcement is correct for safety |
| Retry limits (max 3) in multiple skills | Consistent behavior expectation |

### Bad Duplication (Remove)

| What | Where Duplicated | Source of Truth |
|---|---|---|
| Design principles (7) | `design-principles.md`, `code-reviewer.md`, `refactor.md`, `python-dev.md`, `rules.md` | `steering/design-principles.md` |
| Python standards | `python-dev.md`, `python-boto3.md`, `tooling.md` | `steering/python-boto3.md` + `steering/tooling.md` |
| Shell standards | `shell-dev.md`, `shell-bash.md`, `tooling.md` | `steering/shell-bash.md` + `steering/tooling.md` |
| TypeScript standards | `typescript-dev.md`, `typescript.md`, `tooling.md` | `steering/typescript.md` + `steering/tooling.md` |
| Frontend standards | `frontend-dev.md`, `frontend.md` | `steering/frontend.md` |
| TDD methodology | `engineering.md`, `test-driven-development/SKILL.md` | `skills/test-driven-development/SKILL.md` |
| Systematic debugging | `engineering.md`, `systematic-debugging/SKILL.md` | `skills/systematic-debugging/SKILL.md` |
| "No AI attribution" | `universal-rules.md`, likely in commits | `steering/universal-rules.md` |
| Post-impl trigger list | `orchestrator.md`, `post-implementation/SKILL.md` | Should be ONE source |

---

## Recommended Priority Order

### Phase 1: Safety — Immediate (Do First)
1. CRITICAL-08: Fix `dd if/dev` → `dd if=/dev.*` in ALL agent JSONs
2. CRITICAL-02: Add `scan-secrets.sh` + `protect-sensitive.sh` hooks to subagents
3. CRITICAL-03: Block `bash -c`, `sh -c`, `eval` in bash-write-protect.sh
4. HIGH-13: Add hooks to dev-kiro-config.json
5. HIGH-10: Fix `rm -f.*r.*` → `rm -f[rR].*` regex in all agents
6. HIGH-09: Tighten orchestrator `fs_write.allowedPaths`
7. MEDIUM-11: Add `rm -r.*` to orchestrator deniedCommands
8. MEDIUM-12: Namespace `/tmp` files with `$USER`

### Phase 2: Accuracy — Core Behavior (Do Second)
9. CRITICAL-04: Fix TDD enforcement (add skills, override global rule)
10. CRITICAL-05: Sync post-implementation trigger list with orchestrator
11. CRITICAL-09: Fix auto-capture keyword blind spots
12. HIGH-04/HIGH-07: Enable MCP on subagents or correct prompt lie
13. HIGH-06: Detect package manager in quality gate
14. HIGH-14: Fix "plan-reviewer" → "dev-reviewer" in writing-plans
15. HIGH-15: Escape regex metacharacters in context-enrichment.sh
16. HIGH-16: Fix distill.sh sed corruption

### Phase 3: Consistency — Reduce Drift (Do Third)
17. CRITICAL-01: Remove prompt/steering duplication (prompts → 40-60 lines)
18. CRITICAL-07: Remove knowledge rule duplication
19. CRITICAL-06: Add file conflict pre-check to execution-planning
20. HIGH-01: Fix steering count in all docs
21. HIGH-03: Standardize prompt naming
22. HIGH-12: Fix hardcoded improvement capture path

### Phase 4: Polish
23. Remaining HIGH items (02, 05, 08, 11)
24. MEDIUM items in order (01-10 original, 13-16 new)
25. LOW items as convenient (01-07)

---

## Context Budget Estimate

**Note:** Per Kiro CLI docs, `skill://` resources use lazy loading — metadata
at spawn, full content on invocation. This means skills don't consume full
context tokens at session start. The estimates below reflect worst case
(all skills activated during a session).

Current estimated context consumption at session start (before user message):

| Source | Est. Lines | Est. Tokens |
|---|---|---|
| Orchestrator prompt | 170 | ~800 |
| 12 skill metadata (lazy) | ~60 | ~300 |
| 11 steering docs (eager) | ~650 | ~3,200 |
| Knowledge base (if loaded) | ~100 | ~500 |
| Agent JSON (tool config) | ~260 | ~1,300 |
| Hooks (injected context) | ~10-30 | ~100 |
| **Startup total** | **~1,250** | **~6,200** |

When skills are activated during a session:

| Source | Est. Lines | Est. Tokens |
|---|---|---|
| All 12 skills fully loaded | ~2,400 | ~12,000 |
| **Peak total** | **~3,600** | **~18,000** |

For subagents (Sonnet):

| Source | Est. Lines | Est. Tokens |
|---|---|---|
| Agent prompt | ~80 | ~400 |
| 3-5 skill metadata (lazy) | ~15-25 | ~100 |
| 11 steering docs (eager, all loaded) | ~650 | ~3,200 |
| Orchestrator briefing | ~30-50 | ~200 |
| **Startup total** | **~775-805** | **~3,900** |
| 3-5 skills fully loaded | ~800-1,400 | ~4,000-7,000 |
| **Peak total** | **~1,560-2,180** | **~7,800-10,800** |

After fixing CRITICAL-01 (removing prompt duplication) and MEDIUM-01
(loading only relevant steering), subagent peak drops to ~4,000-6,000
tokens — a 30-45% reduction. Startup stays lean regardless.

---

## Summary Table

| ID | Severity | Category | Issue | Verified |
|---|---|---|---|---|
| CRITICAL-01 | CRITICAL | Drift | Prompt-steering duplication | Round 2: CONFIRMED (all 6 pairs) |
| CRITICAL-02 | CRITICAL | Security | No hooks on subagents | Round 2: CONFIRMED (0/7 subagents have hooks) |
| CRITICAL-03 | CRITICAL | Security | Shell indirection bypass | Round 1 |
| CRITICAL-04 | CRITICAL | Accuracy | TDD not enforced | Round 2: CONFIRMED (resources arrays checked) |
| CRITICAL-05 | CRITICAL | Accuracy | Post-impl trigger list incomplete | Round 2: CONFIRMED (4 vs 6 agents) |
| CRITICAL-06 | CRITICAL | Safety | No file conflict detection | Round 1 |
| CRITICAL-07 | CRITICAL | Waste | Knowledge rules duplicate steering | Round 2: CONFIRMED (5/7 principles restated) |
| CRITICAL-08 | CRITICAL | Security | `dd if/dev` typo — protection dead | Round 2: NEW (all 9 agent JSONs affected) |
| CRITICAL-09 | CRITICAL | Accuracy | Auto-capture keyword blind spots | Round 2: NEW (silently drops corrections) |
| HIGH-01 | HIGH | Drift | Steering count discrepancy | Round 1 |
| HIGH-02 | HIGH | Reliability | Ghost agent reference | Round 1 |
| HIGH-03 | HIGH | Maintenance | Prompt naming inconsistency | Round 1 |
| HIGH-04 | HIGH | Accuracy | Subagents can't use MCP | Round 2: CONFIRMED (all includeMcpJson: false) |
| HIGH-05 | HIGH | Routing | dev-docs deny list too broad | Round 1 |
| HIGH-06 | HIGH | Accuracy | Hardcoded npm in quality gate | Round 1 |
| HIGH-07 | HIGH | Trust | Prompt claims MCP access subagents don't have | Round 2: CONFIRMED (line 118 vs configs) |
| HIGH-08 | HIGH | Reliability | dev-refactor has no debugging skill | Round 1 |
| HIGH-09 | HIGH | Security | Orchestrator write paths too broad | Round 1 |
| HIGH-10 | HIGH | Correctness | rm regex false positives | Round 2: CONFIRMED (even with \A\z anchoring) |
| HIGH-11 | HIGH | Reliability | No subagent timeout guidance | Round 1 |
| HIGH-12 | HIGH | Portability | Hardcoded improvement path | Round 1 |
| HIGH-13 | HIGH | Security | dev-kiro-config has no hooks, generic prompt | Round 2: NEW |
| HIGH-14 | HIGH | Routing | writing-plans references nonexistent agent | Round 2: NEW |
| HIGH-15 | HIGH | Security | Regex injection in context-enrichment.sh | Round 2: NEW |
| HIGH-16 | HIGH | Correctness | distill.sh sed corrupts episode format | Round 2: NEW |
| MEDIUM-01 | MEDIUM | Efficiency | Irrelevant steering loaded everywhere | Round 1 |
| MEDIUM-02 | MEDIUM | Reliability | Skill chain not enforced | Round 1 |
| MEDIUM-03 | MEDIUM | Accuracy | dev-docs can't run doc-consistency | Round 1 |
| MEDIUM-04 | MEDIUM | Accuracy | Knowledge dedup too aggressive | Round 1 |
| MEDIUM-05 | MEDIUM | Accuracy | Correction detection false positives | Round 1 |
| MEDIUM-06 | MEDIUM | Maintenance | Session log no rotation | Round 1 |
| MEDIUM-07 | MEDIUM | Coverage | No CI failure skill | Round 1 |
| MEDIUM-08 | MEDIUM | Security | AWS S3 mutations not blocked | Round 1 |
| MEDIUM-09 | MEDIUM | Routing | No multi-language routing | Round 1 |
| MEDIUM-10 | MEDIUM | Maintenance | base.json orphaned | Round 1 |
| MEDIUM-11 | MEDIUM | Security | Orchestrator missing rm from deniedCommands | Round 2: NEW |
| MEDIUM-12 | MEDIUM | Security | /tmp files no user namespace | Round 2: NEW |
| MEDIUM-13 | MEDIUM | Accuracy | doc-consistency only checks skill counts | Round 2: NEW |
| MEDIUM-14 | MEDIUM | Portability | create-pr hardcodes --base main | Round 2: NEW |
| MEDIUM-15 | MEDIUM | Reliability | auto-capture race condition | Round 2: NEW |
| MEDIUM-16 | MEDIUM | Accuracy | auto-capture dedup uses first 120 chars | Round 2: NEW |
| LOW-01 | LOW | Safety | git add .* too permissive | Round 1 |
| LOW-02 | LOW | Coverage | No shell-audit skill | Round 1 |
| LOW-03 | LOW | DX | Graphviz won't render | Round 1 |
| LOW-04 | LOW | Consistency | npm vs bun across configs | Round 1 |
| LOW-05 | LOW | Accuracy | correction-detect has 14 patterns, not 16 | Round 2: NEW |
| LOW-06 | LOW | Coverage | Missing credential file types in hooks | Round 2: NEW |
| LOW-07 | LOW | Reliability | Skills reference tools that may not be installed | Round 2: NEW |

### Improvement Counts (Prompt/Steering/Skill Analysis)

| Category | Items | Key Themes |
|---|---|---|
| Prompt cross-cutting | 7 | Subagent awareness, tool awareness, status protocol, error recovery |
| Prompt per-agent | 38 | Dedup with steering, missing guardrails, vague instructions |
| Steering cross-cutting | 3 | Priority hierarchy, override mechanism, dedup with domain docs |
| Steering per-document | 31 | Conflicts, completeness gaps, context sensitivity |
| Skill cross-cutting | 5 | Fix-before-proceed anti-pattern, loop limits, rationalization prevention |
| Skill per-skill | 33 | Trigger lists, templates, escalation paths, platform limits |
| **Total improvements** | **117** | |

---

## Round 3: Kiro CLI Counter-Audit

Kiro CLI reviewed this audit document and provided critical feedback.
This section documents every correction, severity adjustment, and missed
item. The goal is an accurate final state, not defending original claims.

### Severity Downgrades (Accepted)

| Finding | Original | Revised | Rationale |
|---|---|---|---|
| CRITICAL-01 | CRITICAL | **HIGH** | Duplication hasn't actually diverged yet. Instructions are consistent today — risk is future drift, not active harm. Becomes CRITICAL only when they actually contradict. |
| CRITICAL-03 | CRITICAL | **HIGH** | Requires LLM to deliberately circumvent its own constraints via write-then-execute. This is a defense-in-depth gap, not a realistic exploit path for a single operator. |
| CRITICAL-06 | CRITICAL | **HIGH** | The orchestrator prompt, execution-planning skill, and dispatching-parallel-agents skill all warn against shared-file conflicts. Probability of collision is low for a single operator. The warnings are probabilistic guardrails but they work in practice. |
| CRITICAL-09 | CRITICAL | **HIGH** | Self-learning pipeline is a nice-to-have optimization, not a safety mechanism. Silent episode drops don't cause incorrect behavior — they just slow down self-improvement. |

**Net effect:** 9 CRITICALs → 5 CRITICALs. The 4 downgraded findings move to HIGH.

**Remaining CRITICALs (confirmed):**
- CRITICAL-02: Subagents have zero security hooks (no content scanning)
- CRITICAL-04: TDD skills missing on dev-frontend and dev-shell (confirmed)
- CRITICAL-05: Post-implementation trigger list mismatch
- CRITICAL-07: Knowledge rules violate their own no-duplication header
- CRITICAL-08: `dd if/dev` typo disables protection on most agents

### Severity Downgrade (Accepted)

| Finding | Original | Revised | Rationale |
|---|---|---|---|
| HIGH-03 | HIGH | **LOW** | Each agent JSON has an explicit `file://` reference to its prompt. You never need to guess — just read the JSON. Cosmetic maintenance issue, not a reliability problem. |

### CRITICAL-04 Nuance: Global Rule vs TDD

Kiro correctly notes the "global Kiro rule kills TDD" claim is overstated.
When the orchestrator's delegation format says "implement with tests,"
that IS an explicit request, which should satisfy the "only add tests when
explicitly requested" platform rule. The conflict is real but not as
deterministic as originally stated.

**Revised assessment:** The TDD-vs-global-rule tension is a risk factor,
not a hard override. The confirmed issue is: `dev-frontend` and `dev-shell`
lack the TDD skill entirely — this part stands at CRITICAL.

### HIGH-09 Nuance: Orchestrator Write Paths

Kiro correctly notes that `~/personal/**` and `~/eam/**` are the author's
actual project directories — the orchestrator needs to write plan files
and specs there. The real concern is only `*.md` allowing writes to any
markdown file anywhere on the system. The rest is intentional.

**Revised assessment:** Change fix to: "Remove `*.md` from allowedPaths
(too broad). Keep `~/personal/**` and `~/eam/**` — these are intentional.
Add `docs/**/*.md` and `./**/*.md` for project-scoped markdown writes."

### Factual Errors Corrected

#### ERROR-1: `base.json` Does NOT Have the `dd` Typo

The audit claimed "every agent JSON" has `dd if/dev` (missing `=`).
`base.json` actually has `dd if=/dev` (correct). The typo exists in the
orchestrator and all 7 subagent configs, but NOT in base.json.

**Correction:** CRITICAL-08 remains valid for 8 of 9 agent configs.
base.json is the exception.

#### ERROR-2: HIGH-06 npm Hardcoding Is Consistent With Steering

The audit flagged `post-implementation` hardcoding `npm` as a bug.
But `steering/tooling.md` explicitly says to use `npm` for Node.js
projects. The quality gate is consistent with the project's own steering.
The "bun project" scenario is hypothetical — no current project uses bun
within this Kiro config's scope.

**Correction:** HIGH-06 downgraded to **MEDIUM**. It's a portability
concern for future projects, not a current bug. The fix (lockfile
detection) is still a good improvement but not urgent.

#### ERROR-3: LOW-05 Phantom Discrepancy

The audit said correction-detect.sh has "14 patterns, but internal
comments or documentation may reference 16." No such reference to 16
exists anywhere. The pattern count is simply 14.

**Correction:** LOW-05 removed. There is no discrepancy to report.

### Items the Audit Missed

#### MISSED-01: Steering Docs Loaded Twice in kiro-config Repo

Every agent loads both `file://.kiro/steering/**/*.md` (project-local)
AND `file://~/.kiro/steering/**/*.md` (global). Since `~/.kiro` is
symlinked to the kiro-config repo, when working inside the kiro-config
repo itself, the same steering docs are loaded twice — once from the
project directory, once from the global symlink.

**Severity:** MEDIUM (context waste, potential for subtle ordering effects)

**Fix:** In `.kiro/` project-local config, either remove the global
steering resource (since project-local covers it) or document this as
expected behavior. For other projects, the dual loading is correct
(project-local may add steering that global doesn't have).

#### MISSED-02: dev-kiro-config Has Stricter rm Deny (Positive)

The audit focused on security gaps but didn't note that
`dev-kiro-config` has `"rm .*"` in its deny list — blocking ALL rm, not
just recursive. This is stricter than other subagents and is correct
for the agent that edits the agent system itself.

**Severity:** N/A — this is a positive finding that should be preserved.

#### MISSED-03: fs_write.deniedPaths vs git add Distinction

The orchestrator's `fs_write.deniedPaths` blocks writes to `~/.kiro/agents`,
`~/.kiro/hooks`, `~/.kiro/steering`. But the orchestrator handles git
operations directly, and `git add` is a shell command (execute_bash), not
an fs_write. So the orchestrator can still `git add` files in those paths
even though it can't write to them via the write tool.

**Severity:** LOW (this is fine — the orchestrator shouldn't be writing
new agent configs, but it should be able to stage existing changes for
commit). Worth documenting in the security model.

### Revised Summary Table

After Round 3 adjustments:

| Severity | Original Count | Adjusted Count | Changes |
|---|---|---|---|
| CRITICAL | 9 | **5** | -4 downgraded to HIGH |
| HIGH | 16 | **20** | +4 from CRITICAL downgrades, +1 from MISSED-01 promotion (was untracked) |
| MEDIUM | 16 | **17** | +1 from HIGH-06 downgrade, +1 MISSED-01 |
| LOW | 7 | **7** | +1 MISSED-03, -1 LOW-05 removed, +1 HIGH-03 downgrade → LOW (net +1 then -1 = same, but LOW-05 removed and HIGH-03 added so net 7) |

### Revised Priority Order

#### Phase 1: Safety — Immediate
1. CRITICAL-08: Fix `dd if/dev` → `dd if=/dev.*` in 8 agent JSONs (not base)
2. CRITICAL-02: Add `scan-secrets.sh` + `protect-sensitive.sh` hooks to subagents
3. HIGH-10: Fix `rm -f.*r.*` regex in all agents
4. HIGH-13: Add hooks to dev-kiro-config.json
5. HIGH (was C-03): Block `bash -c` / `sh -c` in bash-write-protect.sh
6. MEDIUM-11: Add `rm -r.*` to orchestrator deniedCommands
7. MEDIUM-12: Namespace `/tmp` files with `$USER`

#### Phase 2: Accuracy — Core Behavior
8. CRITICAL-04: Add TDD skill to dev-frontend and dev-shell
9. CRITICAL-05: Sync post-implementation trigger list with orchestrator
10. HIGH-04/HIGH-07: Enable MCP on subagents or correct prompt lie
11. HIGH-14: Fix "plan-reviewer" → "dev-reviewer" in writing-plans
12. HIGH-15: Escape regex metacharacters in context-enrichment.sh
13. HIGH-16: Fix distill.sh sed corruption
14. HIGH (was C-09): Fix auto-capture keyword blind spots

#### Phase 3: Consistency — Reduce Drift
15. HIGH (was C-01): Remove prompt/steering duplication (prompts → 40-60 lines)
16. CRITICAL-07: Remove knowledge rule duplication
17. HIGH (was C-06): Add file conflict pre-check to execution-planning
18. HIGH-01: Fix steering count in all docs
19. HIGH-12: Fix hardcoded improvement capture path
20. HIGH-09: Remove `*.md` from orchestrator write paths (keep project dirs)

#### Phase 4: Polish
21. Remaining HIGH items
22. MEDIUM items (including MISSED-01 double steering load)
23. LOW items (including MISSED-03 documentation)

> Note: as of v0.7.0, dev-* agents were renamed to devops-*. See docs/specs/2026-04-18-devops-terraform-and-rename/spec.md.
