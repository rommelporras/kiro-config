# Audit Playbook

Reference doc for auditing the kiro-config system. Covers invariants,
quick health checks, deep audit protocol, design rules, and historical
failure patterns.

**Audience:** AI agents (Claude Code, Kiro CLI, Gemini CLI) and IT-level
humans maintaining this repo.

**Companion docs:**
- `docs/specs/audit-current-workflow.md` — detailed 2000+ line audit findings from v0.5.0 (reference audit)
- `docs/improvements/pending.md` — live improvement backlog
- `docs/reference/creating-agents.md` — agent schema reference
- `docs/reference/security-model.md` — three-layer defense detail
- `docs/reference/skill-catalog.md` — skill inventory

**When to use this doc:**
- Before every release (tag bump)
- After adding/modifying an agent, hook, or skill
- Quarterly maintenance
- When system behavior feels off but you can't pinpoint why
- Onboarding a new agent or contributor

---

## 1. Healthy System Invariants

These properties must hold at all times. If any fails, the system has
drifted. Each invariant has a concrete check command.

### 1.1 Security invariants

| # | Invariant | Check |
|---|---|---|
| S1 | Every write+shell subagent has 4 `preToolUse` hooks | `for f in agents/dev-{python,shell,frontend,typescript,refactor,docs}.json .kiro/agents/dev-kiro-config.json; do [ "$(jq '.hooks.preToolUse \| length' $f)" = "4" ] \|\| echo "FAIL $f"; done` |
| S2 | `dev-reviewer` has 2 `preToolUse` hooks (no `fs_write` hooks) | `[ "$(jq '.hooks.preToolUse \| length' agents/dev-reviewer.json)" = "2" ]` |
| S3 | `dev-reviewer` has no `write` tool | `! jq '.tools' agents/dev-reviewer.json \| grep -q '"write"'` |
| S4 | No agent JSON has `dd if/dev` (missing `=`) | `! grep -rn '"dd if/dev"' agents/ .kiro/agents/` |
| S5 | All agents block recursive `rm` (either `rm .*` or the combined-flag pattern) | `for f in agents/dev-*.json .kiro/agents/dev-*.json; do jq '.toolsSettings.execute_bash.deniedCommands' $f \| grep -qE '"rm .*\*"\|"rm -\[' \|\| echo "FAIL $f"; done` |
| S6 | Orchestrator `fs_write.allowedPaths` doesn't contain `*.md` (too broad) | `! jq '.toolsSettings.fs_write.allowedPaths' agents/dev-orchestrator.json \| grep -q '"\*\.md"'` |
| S7 | Every sensitive credential pattern in `scan-secrets.sh` still matches known tokens | manual — see §3.2 test vectors |
| S8 | Every agent `denyCommands` regex is fully anchored (Kiro CLI uses `\A`/`\z`) — patterns for commands with args must end in `.*` | grep for patterns lacking `.*` suffix (excluding literal-only commands) |

### 1.2 Accuracy invariants

| # | Invariant | Check |
|---|---|---|
| A1 | Post-implementation skill trigger list matches orchestrator's list | `diff <(grep -oE 'dev-[a-z-]+' skills/post-implementation/SKILL.md \| sort -u) <(sed -n '8,9p' agents/prompts/orchestrator.md \| grep -oE 'dev-[a-z-]+' \| sort -u)` — no diff |
| A2 | Every subagent that claims MCP access in its prompt has `includeMcpJson: true` AND the tool in both `tools` and `allowedTools` | see §3.3 |
| A3 | `dev-frontend` and `dev-shell` have `test-driven-development` skill in resources | `jq '.resources[]' agents/dev-frontend.json \| grep test-driven && jq '.resources[]' agents/dev-shell.json \| grep test-driven` |
| A4 | No prompt enumerates design principles (they're in steering) | `! grep -rE 'Rule of Three\|Fail Fast\|KISS over DRY\|Least Knowledge\|Boy-Scout\|Least Astonishment' agents/prompts/*.md` — zero matches |
| A5 | `writing-plans` skill references `dev-reviewer`, not `plan-reviewer` | `! grep 'plan-reviewer' skills/writing-plans/SKILL.md` |
| A6 | No hardcoded author-specific paths in skill or prompt files | `! grep -r 'personal/kiro-config' skills/ agents/prompts/` |

### 1.3 Consistency invariants

| # | Invariant | Check |
|---|---|---|
| C1 | Steering count in docs matches actual count | `[ "$(ls -1 steering/*.md \| wc -l)" = "$(grep -oE '[0-9]+ steering' README.md \| head -1 \| grep -oE '[0-9]+')" ]` |
| C2 | Every `skill://` reference in agent configs points to a file that exists | see §3.4 |
| C3 | Every `file://` prompt reference in agent configs points to a file that exists | see §3.4 |
| C4 | Agent prompts don't restate steering content — reference it instead | manual scan for dedup violations (§3.5) |
| C5 | `~/.kiro/docs` symlink exists on any installed machine | `test -L ~/.kiro/docs && test -d ~/.kiro/docs` |
| C6 | All JSON files are valid | `for f in agents/*.json .kiro/agents/*.json settings/*.json; do jq empty $f \|\| echo "BROKEN $f"; done` |
| C7 | All bash scripts pass syntax check | `for f in hooks/**/*.sh scripts/*.sh; do bash -n $f \|\| echo "BROKEN $f"; done` |

### 1.4 Documentation invariants

| # | Invariant | Check |
|---|---|---|
| D1 | Skill count in README and skill-catalog matches actual skill directory count | `ls -1 skills/ \| wc -l` vs. counts in docs |
| D2 | Every agent referenced in orchestrator routing exists in its JSON dir | §3.6 |
| D3 | Improvement backlog has an entry for every known TODO/deferred issue | manual review |
| D4 | CHANGELOG has an entry for the current version tag | `git tag -l \| tail -1` matches top entry in `docs/reference/CHANGELOG.md` |

---

## 2. Quick Health Check (15 minutes)

Run these commands in order. Zero failures = system healthy. Any
failure triggers a deep audit of the affected area (§4).

```bash
cd ~/personal/kiro-config

# S1-S3: Security hook presence
for f in agents/dev-{python,shell,frontend,typescript,refactor,docs}.json .kiro/agents/dev-kiro-config.json; do
  count=$(jq '.hooks.preToolUse | length // 0' "$f")
  [ "$count" = "4" ] || echo "FAIL S1: $f has $count hooks (expected 4)"
done
[ "$(jq '.hooks.preToolUse | length' agents/dev-reviewer.json)" = "2" ] || echo "FAIL S2: dev-reviewer wrong hook count"
jq '.tools' agents/dev-reviewer.json | grep -q '"write"' && echo "FAIL S3: dev-reviewer has write tool"

# S4: dd typo check
grep -rn '"dd if/dev"' agents/ .kiro/agents/ 2>/dev/null && echo "FAIL S4: dd typo present"

# S5: Recursive rm blocked
for f in agents/dev-*.json .kiro/agents/dev-*.json; do
  jq '.toolsSettings.execute_bash.deniedCommands // []' "$f" 2>/dev/null \
    | grep -qE '"rm .*\*"|"rm -\[' \
    || echo "FAIL S5: $f missing recursive rm block"
done

# S6: Orchestrator write scope
jq '.toolsSettings.fs_write.allowedPaths' agents/dev-orchestrator.json | grep -q '"\*\.md"' \
  && echo "FAIL S6: orchestrator has overly-broad *.md write"

# A1: Post-impl trigger list sync
skill_agents=$(grep -oE 'dev-[a-z-]+' skills/post-implementation/SKILL.md | sort -u)
orch_agents=$(sed -n '8,11p' agents/prompts/orchestrator.md | grep -oE 'dev-[a-z-]+' | sort -u)
[ "$skill_agents" = "$orch_agents" ] || echo "FAIL A1: trigger list mismatch"

# A3: TDD on frontend and shell
for f in agents/dev-frontend.json agents/dev-shell.json; do
  jq '.resources[]' "$f" | grep -q test-driven || echo "FAIL A3: $f missing TDD"
done

# A4: No design principles in prompts
count=$(grep -rE 'Rule of Three|Fail Fast|KISS over DRY' agents/prompts/*.md 2>/dev/null | wc -l)
[ "$count" = "0" ] || echo "FAIL A4: $count design-principle refs in prompts"

# A5: Plan-reviewer ghost gone
grep -q 'plan-reviewer' skills/writing-plans/SKILL.md && echo "FAIL A5: plan-reviewer ghost still present"

# A6: No hardcoded author paths
grep -rq 'personal/kiro-config' skills/ agents/prompts/ && echo "FAIL A6: hardcoded author path"

# C1: Steering count matches
actual=$(ls -1 steering/*.md | wc -l)
claimed=$(grep -oE '[0-9]+ steering' README.md | head -1 | grep -oE '[0-9]+')
[ "$actual" = "$claimed" ] || echo "FAIL C1: steering count drift ($actual actual vs $claimed claimed)"

# C5: Docs symlink (machine-specific)
[ -L ~/.kiro/docs ] && [ -d ~/.kiro/docs ] || echo "FAIL C5: ~/.kiro/docs symlink missing"

# C6: JSON validity
for f in agents/*.json .kiro/agents/*.json settings/*.json; do
  jq empty "$f" 2>/dev/null || echo "FAIL C6: $f invalid JSON"
done

# C7: Bash syntax
for f in hooks/*.sh hooks/**/*.sh scripts/*.sh; do
  [ -f "$f" ] && (bash -n "$f" 2>/dev/null || echo "FAIL C7: $f syntax error")
done

echo "Health check complete."
```

Save this as a runnable script for reuse. Every failure output tells you which invariant failed — §4 tells you how to dig in.

---

## 3. Verification Methods (detail for specific checks)

### 3.1 Regex anchoring awareness

Kiro CLI anchors `deniedCommands` regex with `\A` and `\z`. The pattern
must match the entire command string, not a substring. Consequences:

- `"git push"` matches ONLY the literal 7-char string, never `git push --force`
- Patterns for commands with arguments need `.*` suffix: `"git push.*"`
- Substring patterns (e.g., `"dd if=/dev"` from a hook script substring-matching context) do NOT work as deny-list regex

When reviewing a new deny pattern, ask: "does this match the full command with its arguments?" If in doubt, append `.*`.

### 3.2 Secret pattern test vectors

`hooks/scan-secrets.sh` patterns should be tested against known-good and
known-bad inputs periodically. Maintain a `tests/secret-vectors.txt` with
examples (redacted) of patterns that SHOULD and SHOULD NOT trigger. Rerun
after any edit to `scan-secrets.sh`.

Currently covered: PEM keys, AWS access keys, GitHub tokens (classic +
fine-grained), Anthropic keys, OpenAI keys, Context7 keys, GitLab tokens,
Slack tokens, GCP service accounts, generic `password|secret|token|api_key` assignments.

### 3.3 MCP tool alignment

For every subagent with `"includeMcpJson": true`, verify:
1. The `tools` array contains the MCP tool references (e.g., `@context7`)
2. The `allowedTools` array contains the same MCP tool references
3. The MCP servers exist in `settings/mcp.json`

```bash
for f in agents/dev-*.json; do
  mcp_enabled=$(jq '.includeMcpJson' "$f")
  [ "$mcp_enabled" = "true" ] || continue
  mcp_tools=$(jq '.tools[]' "$f" | grep '@')
  [ -z "$mcp_tools" ] && echo "FAIL: $f enables MCP but has no @ tools in tools[]"
  while read tool; do
    bare=$(echo "$tool" | tr -d '"@')
    jq ".mcpServers | has(\"$bare\")" settings/mcp.json | grep -q true \
      || echo "FAIL: $f references MCP server '$bare' not in mcp.json"
  done <<< "$mcp_tools"
done
```

### 3.4 Resource reference integrity

Every `skill://` and `file://` reference in agent configs must point to a
file that exists on disk:

```bash
for f in agents/*.json .kiro/agents/*.json; do
  jq -r '.resources[]? | select(type == "string")' "$f" \
    | grep -oE '(skill|file)://[^"]+' \
    | while read ref; do
        path="${ref#*://}"
        path="${path/\~/$HOME}"
        # glob patterns like **/*.md need special handling — skip them
        echo "$path" | grep -q '\*' && continue
        [ -f "$path" ] || echo "FAIL: $f references missing $ref"
      done
done
```

### 3.5 Prompt duplication scan

Prompts should reference steering, not restate it. Red flags:
- A prompt has a section named `## Design principles`, `## Design principle checks`, or similar enumeration
- A prompt has more than ~10 lines of content that could be moved to a steering doc
- A prompt has bullet lists that duplicate steering doc bullet lists (diff them)

Quick detection:
```bash
for p in agents/prompts/*.md; do
  size=$(wc -l < "$p")
  [ "$size" -gt 80 ] && [ "$p" != "agents/prompts/orchestrator.md" ] && [ "$p" != "agents/prompts/code-reviewer.md" ] \
    && echo "LARGE: $p is $size lines — check for duplication"
done
```

### 3.6 Routing table validation

Every agent referenced in the orchestrator's routing table must have a
corresponding JSON file (global or project-local):

```bash
# Extract agent names from orchestrator prompt routing table
grep -oE 'dev-[a-z-]+' agents/prompts/orchestrator.md | sort -u | while read agent; do
  [ -f "agents/$agent.json" ] || [ -f ".kiro/agents/$agent.json" ] \
    || echo "FAIL: routing table references $agent but no JSON file found"
done
```

---

## 4. Deep Audit Protocol

When the quick check fails or a release/major-change triggers a full audit.

### Round 1: Discovery

- Read every file in the affected area (agent JSONs, prompts, hooks, skills)
- Cross-reference claims with actual files — never trust summaries or prior output
- Categorize findings by severity: **CRITICAL / HIGH / MEDIUM / LOW**
- Write findings to `docs/specs/YYYY-MM-DD-audit-<topic>.md`
- Each finding must have: What / Why it matters / Fix / Verification method

### Round 2: Self-verification

- Re-read round-1 findings with fresh eyes
- Run verification commands for each claimed issue
- Consult platform docs (Kiro CLI docs at https://kiro.dev/docs/cli/) for behavior claims
- Mark each finding: CONFIRMED / PARTIALLY CORRECT / WRONG / SUPERSEDED
- Remove/adjust any finding that fails verification

### Round 3: Counter-audit

- Have a second agent (different instance or different platform — Claude Code reviewing Kiro output, or vice versa) independently evaluate the audit
- Severity calibration: am I overstating risk? A CRITICAL for a single-operator system might be HIGH.
- Factual errors: did I miss something? Did I mischaracterize a file?
- Update the audit doc with Round 3 corrections marked clearly (don't rewrite — append "Round 3: DOWNGRADED" / "Round 3: ERROR" / "Round 3: MISSED")

### Remediation

- Group findings into phases by type: Safety → Accuracy → Consistency → Polish
- Each phase gets its own spec + plan + execution-plan under `docs/specs/YYYY-MM-DD-audit-phase<N>-<name>/`
- Dispatch mechanical fixes in parallel where file sets are independent
- Verify every change with the `Done when:` criteria before accepting
- Each phase commits separately; release bundles all phases under one version tag

### Lessons from the v0.5.0 audit (apply in future audits)

1. **Never trust your own prior output between rounds.** Re-read actual files. A finding that was true in Round 1 may have been fixed between rounds, or was based on uncommitted changes that got discarded.
2. **Counter-audit produces real signal.** The v0.5.0 counter-audit downgraded 4 CRITICALs to HIGH, caught 3 factual errors, and surfaced 3 missed items. Budget time for it.
3. **Severity depends on operational context.** "Prompt drift from steering" is CRITICAL for a team-deployed system, HIGH for a single-operator one. State the context up front.
4. **Platform-behavior assumptions need doc verification.** The `\A\z` regex anchoring of `deniedCommands` changes how every deny pattern must be analyzed. Read the platform docs before asserting.
5. **Prefer atomic verification commands over compound ones.** `grep -c foo` returns a number; `grep foo | wc -l` adds variance. Compound checks make failures harder to diagnose.
6. **Each delegate briefing needs unambiguous oldStr.** If two `"code"` strings exist in the same JSON, a bare `"code"` anchor is non-deterministic. Include enough surrounding context to make oldStr unique.

---

## 5. Design Rules for New Config

### 5.1 Adding a new agent

Required fields in the JSON:
- `name`, `description`, `prompt`, `model`
- `tools` and `allowedTools` — list every tool, ensure `allowedTools ⊆ tools`
- `toolsSettings` with at minimum `fs_write.allowedPaths`, `fs_write.deniedPaths`, `execute_bash.deniedCommands`
- `resources` — steering globs + skill URIs
- `includeMcpJson` — explicit true/false (don't rely on defaults)

Required hooks block if the agent has `write` or `shell`:
- `scan-secrets.sh` and `protect-sensitive.sh` on `fs_write`
- `bash-write-protect.sh` and `block-sed-json.sh` on `execute_bash`

The prompt file must:
- State operating context ("you are a subagent invoked by an orchestrator")
- List available tools explicitly
- Reference steering for domain standards, not restate them
- Define the 4-status protocol (DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED)
- Include a "What you never do" list

Size target: 40-80 lines. Over 80 lines is a smell — check for steering duplication.

### 5.2 Adding a new skill

SKILL.md must:
- Start with YAML frontmatter: `name` and `description`
- Have a clear "## When to use" block at the top
- Use checkbox step syntax `- [ ]` for trackable workflow
- Include verification criteria — what makes each step complete
- Define exit conditions (`Done when:` or equivalent)
- Reference related skills explicitly

The description determines when the skill activates — phrase it to match real user language, not internal jargon.

### 5.3 Adding a new hook

Hook scripts must:
- Use `#!/usr/bin/env bash` and `set -euo pipefail`
- Read tool input via `jq` from stdin (see existing hooks for pattern)
- Exit 0 to allow, exit 2 to block with stderr message
- Have a timeout ≤ 5 seconds
- Test on known-good and known-bad inputs before deploying

Register the hook in every agent JSON that should use it. Remember: **hooks do not inherit** — each agent defines its own hooks block.

### 5.4 Adding a new steering doc

Steering docs must:
- Be testable (rules with verification commands preferred)
- Avoid duplicating other steering docs — cross-reference instead
- State priority explicitly if it conflicts with another doc
- Acknowledge context sensitivity (dev vs prod, different projects)

After adding a new steering doc:
- Update steering count in README.md, team-onboarding.md, kiro-cli-install-checklist.md
- Update `doc-consistency.sh` if it checks the count
- Run a full prompt audit for new duplication opportunities

### 5.5 Enabling MCP on an agent

Default stance: MCP disabled. Enable only when the agent needs external
documentation lookups that can't be pre-fetched by the orchestrator.

Current selective enablement:
- `dev-python`: Context7 + AWS Documentation
- `dev-typescript`, `dev-shell`, `dev-refactor`, `dev-frontend`: Context7 (frontend also Playwright)
- `dev-docs`, `dev-reviewer`, `dev-kiro-config`: no MCP

When enabling on a new agent:
1. `"includeMcpJson": true`
2. Add tool names to both `tools` AND `allowedTools`
3. Tool names must match `settings/mcp.json` server keys exactly, prefixed with `@`

---

## 6. Stopping Criteria

An audit is complete when:

- All quick-check invariants pass
- Every CRITICAL and HIGH finding has either been fixed or explicitly deferred with written justification
- CHANGELOG reflects the work
- Tests/verification commands in done-when criteria all pass
- A counter-audit or second-agent review has been performed

Do NOT continue past diminishing returns. MEDIUM and LOW items can track
as backlog. A clean v0.5.0 with 5 CRITICAL and 16 HIGH fixed is more
valuable than a v0.5.0 attempting all 48+ findings and introducing
regressions.

---

## 7. Historical Failure Patterns (Appendix)

Case studies from real bugs. Use as pattern-match fuel when auditing.

### 7.1 `dd if/dev` — missing `=` in regex

**Symptom:** Agent deny-list contains `"dd if/dev"` but the real command is `dd if=/dev/zero of=/dev/sda`.
**Root cause:** Author typed `/` thinking it's a path separator, but `dd` uses `if=` (key=value syntax).
**Fix pattern:** `"dd if=/dev.*"` — include `=` AND `.*` for anchoring.
**How to detect:** `grep -rn '"dd if/dev"' agents/` — any hit is broken.

### 7.2 `rm -f.*r.*` — false positive on filenames containing 'r'

**Symptom:** `rm -f report.txt` gets blocked even though it's a single-file delete.
**Root cause:** `.*r.*` matches any character including filename chars. With `\A\z` anchoring, the full command `rm -f report.txt` matches because 'r' appears in 'report'.
**Fix pattern:** `"rm -[a-zA-Z]*r[a-zA-Z]* .*"` with the space before `.*` — ensures 'r' is in the flag cluster, not the filename.
**How to detect:** Test the regex against `rm -f benign_filename_with_r.txt` — should NOT match.

### 7.3 Prompt/steering duplication

**Symptom:** Agent prompt has a `## Design principles` section enumerating Rule of Three, Fail Fast, etc. Same content exists in `steering/design-principles.md`.
**Root cause:** Prior author added principles inline for "visibility." Now two sources, drift risk.
**Fix pattern:** Prompt has a single reference line: `Follow design principles from steering/design-principles.md`. No enumeration.
**How to detect:** `grep -rE 'Rule of Three|Fail Fast|Boy-Scout' agents/prompts/*.md` — zero expected.

### 7.4 Ghost agent reference in skill

**Symptom:** `writing-plans/SKILL.md` says "dispatch a plan-reviewer delegate." No such agent exists.
**Root cause:** Skill was written before agent names were finalized; never updated.
**Fix pattern:** Use actual agent names: `dispatch dev-reviewer`.
**How to detect:** Extract all agent names referenced in skills, verify each exists in the agent JSON dirs.

### 7.5 Regex injection via unescaped keyword interpolation

**Symptom:** `hooks/feedback/context-enrichment.sh` had `grep -qiP "\b${kw}\b"` where `$kw` could be `sys.exit` (with literal `.`). The `.` in PCRE matches any char.
**Root cause:** Interpolating user-controlled strings into regex without escaping metacharacters.
**Fix pattern:** `escaped_kw=$(printf '%s' "$kw" | sed 's/[.[\*^$()+?{|\\]/\\&/g')` before the grep.
**How to detect:** Grep for `grep.*\$\{[a-z]*\}` — user-interpolated regex is a smell.

### 7.6 `sed -i` corrupting pipe-delimited format

**Symptom:** `distill.sh` was using `sed -i "s/| active |.*${kw}/\0 [promoted]/"` to mark episodes promoted. The substitution inserted `[promoted]` at the keyword match position, mid-field, breaking the `DATE | STATUS | KEYWORDS | SUMMARY` format.
**Root cause:** `\0` backreference includes only the matched portion, not the rest of the line. The replacement text went in the wrong place.
**Fix pattern:** Use `awk` with `sub(/\| active \|/, "| promoted |")` to change only the STATUS field.
**How to detect:** Parse a sample file with the substitution applied; check field count stays 4.

### 7.7 Hardcoded author-specific path

**Symptom:** `skills/post-implementation/SKILL.md` had `Append to ~/personal/kiro-config/docs/improvements/pending.md`. Works for the author, fails for every other user.
**Root cause:** Path hardcoded during initial authoring.
**Fix pattern:** Use platform-standard paths: `~/.kiro/docs/improvements/pending.md` (symlinked on install).
**How to detect:** `grep -r 'personal/kiro-config' skills/ agents/prompts/` — any hit is non-portable.

### 7.8 Subagent hook inheritance assumption

**Symptom:** Assumed subagents inherit the orchestrator's security hooks. They don't — Kiro CLI hooks are per-agent only.
**Root cause:** Mental model mismatch with platform behavior.
**Fix pattern:** Every subagent JSON explicitly defines its own hooks block.
**How to detect:** `jq '.hooks' agents/dev-*.json` — every write+shell subagent should show 4 hooks.

### 7.9 Ambiguous `oldStr` in delegate briefing

**Symptom:** Delegate task says replace `"code"` in a JSON file. That string appears twice (once in `tools`, once in `allowedTools`). Delegate either errors on non-unique match or replaces the wrong one.
**Root cause:** Author didn't verify uniqueness of `oldStr` before including it in the plan.
**Fix pattern:** Include enough surrounding context (the full array, or the preceding key) to make `oldStr` unique.
**How to detect:** For each `oldStr` in a plan, grep the target file — expect exactly 1 match.

### 7.10 Stream-of-consciousness scratchwork in final plan

**Symptom:** Plan had two `oldStr`/`newStr` pairs separated by "Wait — that duplicates identity. Let me restructure:". Delegate sees both and can't decide which is final.
**Root cause:** Author's thinking process leaked into the deliverable.
**Fix pattern:** Only include the final version. Delete scratchwork before publishing.
**How to detect:** Grep plans for self-reference words: `Wait|Let me|Actually|Hmm` — any hit is a smell.

### 7.11 Ghost task targeting the wrong file

**Symptom:** Task 12 of Phase 3 claimed to add docs symlink to `scripts/personalize.sh`. Verification showed `personalize.sh` doesn't create symlinks at all — they're documented in setup docs.
**Root cause:** Author assumed without reading the target file.
**Fix pattern:** Read the target file first. Verify the oldStr anchor exists. Reroute if necessary.
**How to detect:** Before dispatch, grep the target file for the proposed anchor. Zero matches = task is broken.

### 7.12 Parallel-safety violated by shared files

**Symptom:** Tasks 10 and 12 both claimed parallel dispatch. Both touched `team-onboarding.md` and `kiro-cli-install-checklist.md`. Race condition on the same file.
**Root cause:** File lists not cross-checked across parallel tasks.
**Fix pattern:** Before marking tasks parallel-safe, list all files each task touches. If any file appears in two tasks, they must be sequential (or merged).
**How to detect:** Extract file lists from all parallel tasks; compute intersection; must be empty.

### 7.13 Auto-commit violating explicit user rule

**Symptom:** Plan's "## Commit" section said "After stages pass, commit with..." — could be interpreted as auto-commit. User's rule: "only commit when explicitly asked."
**Root cause:** Template inherited from other tooling that supports auto-commit.
**Fix pattern:** "After stages pass verification, present results to user for commit approval. Do not commit without explicit user approval."
**How to detect:** Search plans for `commit` sections — explicit approval language must be present.

### 7.14 Blanket `git add -A` sweeping in pre-existing dirty files

**Symptom:** Blanket-staging would have committed 7 pre-existing dirty files alongside a phase's work, polluting commit scope.
**Root cause:** Convenience of `git add -A` vs. discipline of naming files.
**Fix pattern:** Stage files by explicit path. Inspect `git status` before every commit.
**How to detect:** Read `git status` before staging; identify files NOT part of current work; exclude them.

---

## 8. Change Log for This Playbook

- **2026-04-17 (v0.5.0 audit):** Initial playbook drafted from Phase 1-3 audit findings and remediation sessions. 14 historical failure patterns documented.
