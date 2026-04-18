# Audit Report — Spec: `devops-terraform Agent + dev-* → devops-* Rename`

**Audit Agent:** Claude Opus 4.7 (1M context)
**Audit date:** 2026-04-18
**Spec path:** `docs/specs/2026-04-18-devops-terraform-and-rename/spec.md`
**Verdict:** `REQUEST_CHANGES` — directionally sound, but the implementation details are under-specified in ways that will bite during execution. 12 material findings below.

## Summary

The spec is well-scoped at the strategic level: the rename motivation is clear, the new agent's role is well-bounded (read-only Terraform analysis), and the phasing (rename → new agent → verify) is correct ordering. However, as a **written implementation contract for a subagent**, it leaves too many concrete decisions to the implementer. Several of those decisions are ones where getting them wrong silently breaks the agent (deny-list regex), breaks the rename (relative prompt paths), or quietly loses historical accuracy (audit docs rewrite).

Strengths worth preserving: correct recognition that `dev-kiro-config` is project-local, good preflight-gate discipline for AWS/workspace/init state, phasing the rename before the new agent, and the explicit zero-stale-refs grep at the end.

---

## CRITICAL findings (must fix before execution)

### C1. The `dev-kiro-config.json` → `dev-docs.md` cross-reference is not called out

`.kiro/agents/dev-kiro-config.json:4` currently contains:

```json
"prompt": "file://../../agents/prompts/dev-docs.md"
```

This is the **only** JSON in the repo with a relative cross-tree prompt reference. The spec's Rename Strategy step 3 ("Update all `prompt` file references in JSON configs") covers it generically, but the implementer scanning for `"prompt": "file://./prompts/dev-<name>.md"` will miss the `../../agents/prompts/` form. Enumerate it explicitly as:

> `devops-kiro-config.json` prompt field must be updated to `file://../../agents/prompts/devops-docs.md` (depends on `devops-docs.md` existing first — sequence with the prompt-file rename step).

### C2. Prompt-file rename list is incomplete

Spec only enumerates `dev-refactor.md → devops-refactor.md` under "Prompt files (rename file)", then hand-waves "Other prompt files that are referenced by filename in agent JSON". For a 53-file rename, enumerate all seven:

```
agents/prompts/dev-docs.md       → agents/prompts/devops-docs.md
agents/prompts/dev-frontend.md   → agents/prompts/devops-frontend.md
agents/prompts/dev-python.md     → agents/prompts/devops-python.md
agents/prompts/dev-refactor.md   → agents/prompts/devops-refactor.md
agents/prompts/dev-reviewer.md   → agents/prompts/devops-reviewer.md
agents/prompts/dev-shell.md      → agents/prompts/devops-shell.md
agents/prompts/dev-typescript.md → agents/prompts/devops-typescript.md
```

Note: `agents/prompts/orchestrator.md` is **not** renamed (no `dev-` prefix) — only its contents update. State this explicitly so no one renames it.

### C3. `orchestrator.md` has embedded agent names in *prose*, not just the routing table

Spec step 8 handles this via bulk text replace, but the orchestrator prompt's **Routing Table** is what spec calls out. Two other sites need discipline:

- `orchestrator.md:8-10` — flow paragraph listing `dev-python, dev-shell, dev-refactor, dev-kiro-config, dev-typescript, dev-frontend` for the post-implementation trigger. **Decision required:** does `devops-terraform` join this list? It's read-only, so probably **no** — but the spec doesn't say, and the post-implementation skill will trigger if added. Write the decision down.
- `orchestrator.md:33` — `dev-docs CANNOT delete files (shell deny list blocks rm)`. Text replace will catch it, but flag it in the plan so the rewritten sentence still reads naturally.

### C4. The new agent's shell allow/deny lists are prose, not JSON — and they contradict the tool table

Tool table line: `aws: ❌ Not as a tool — AWS CLI via shell with deny list`. Shell Allow List: `aws sts get-caller-identity`, `aws ... describe-*`, `aws ... list-*`, `aws ... get-*`. But the spec never writes out the `deniedCommands` entries for `aws .* create-.*`, `aws .* delete-.*`, `aws .* update-.*`, etc. — which every other agent has. Without those, the allow list + `autoAllowReadonly` is a partial fence.

**Ask:** why not use the native `use_aws` tool with `autoAllowReadonly: true` (as the orchestrator and base do)? That's the established pattern. If there's a reason (e.g. terraform-related AWS subcommands that the tool doesn't expose cleanly), state it. Otherwise, switch to `use_aws` and delete the shell-AWS section.

Also missing from the spec: the standard infrastructure deny list that every agent duplicates (kubectl, helm, docker, terraform mutating, aws mutating, rm variants, `mkfs.`, `dd if=/dev.*`). Spec says "Standard infrastructure deny list (same as all agents)" — name the reference agent (e.g., "copy from `dev-reviewer.json`, add terraform-specific denies"), because `base.json`, `dev-orchestrator.json`, `dev-reviewer.json`, and `dev-kiro-config.json` all differ slightly.

### C5. `terraform init` allow + `terraform init -upgrade` deny — regex precedence unspecified

Kiro's `execute_bash` regex is anchored (`\A`/`\z`, per `docs/reference/security-model.md:79`). Writing allow-list `terraform init` and deny-list `terraform init -upgrade.*` should work *if* deny wins when both match, but the spec provides no regex — just prose. Same issue for `terraform providers` (allowed) vs `terraform providers lock` (denied), and `terraform plan`/`terraform show` (allowed) vs `terraform console` (denied — but `terraform console` wouldn't match any allow pattern anyway, so this one is trivially denied-by-default).

Write the actual regex into the spec, e.g.:

```json
"allowedCommands": [
  "terraform init",
  "terraform plan.*",
  "terraform validate.*",
  "terraform providers",
  "terraform providers schema.*",
  ...
],
"deniedCommands": [
  "terraform init -upgrade.*",
  "terraform init --upgrade.*",
  "terraform providers lock.*",
  "terraform console.*",
  ...
]
```

And test the precedence on a scratch config before merging.

### C6. Historical audit/spec docs rewrite destroys the historical record

Spec's "Audit/spec docs (historical — update for accuracy)" rewrites:

```
docs/audit/audit-triage-v0.5.1.md
docs/audit/audit-triage-v0.6.0.md
docs/specs/2026-04-12-foundation-hardening/plan.md
docs/specs/2026-04-16-*/**
docs/specs/2026-04-17-audit-phase{1..4}-*/**
```

These documents record *what was true at the time they were written*. Rewriting `dev-reviewer` → `devops-reviewer` in a v0.5.1 audit triage is factually incorrect — the agent wasn't called that then. Two defensible options:

1. **Preferred:** leave historical docs as-is. Add a one-line footer to each: `> Note: as of v0.7.0, dev-* agents were renamed to devops-* (see 2026-04-18 spec).`
2. Accept the rewrite but record the decision in CHANGELOG so the intent is preserved even if the historical text no longer is.

The spec as written silently chooses option 2 without calling out the tradeoff. Make the choice explicit.

---

## IMPORTANT findings (should address)

### I1. The new agent's `code` tool "AST search across HCL files" is unverified

Kiro's code tool supports tree-sitter languages commonly: Python, TypeScript, Go, etc. HCL AST support is not confirmed in this repo's docs. If unsupported, grep-based search is fine — but the spec shouldn't promise AST. Either verify against Kiro docs (via `@context7` or official docs) or soften to: "code tool (AST where supported; grep/ripgrep otherwise)".

### I2. No full JSON config for `devops-terraform` agent

Every other agent in `agents/` has a complete JSON config with `tools`, `allowedTools`, `toolsSettings`, `hooks`, `resources`, `includeMcpJson`, `model`, plus prompt path. The spec describes the shape in prose but doesn't include the full file. At minimum, answer:

- Are the standard four `preToolUse` hooks (`scan-secrets`, `protect-sensitive`, `bash-write-protect`, `block-sed-json`) applied to `devops-terraform`? `dev-reviewer` has them; `dev-kiro-config` has them. The new agent should unless there's reason otherwise.
- `resources` block: which skills and steering globs? Spec lists skills in a table but doesn't show the `skill://~/.kiro/skills/...` URI list.
- `fs_read.allowedPaths` and `fs_write.allowedPaths`? Writing is denied, but read paths need `~/eam` for the knowledge base target, plus any project-local overrides.
- `model`: spec says `claude-sonnet-4.6` — confirm this is the currently preferred model (matches `dev-reviewer`).

A concrete JSON block in the spec de-risks the implementation.

### I3. Knowledge base URI pattern is unverified

Spec proposes `"source": "file://~/eam/eam-terraform"`. Existing orchestrator KB uses `"source": "file://~/.kiro"`. Confirm `~` expansion works inside a `file://` URI in Kiro (vs. requiring `/home/eam/eam/eam-terraform`). If it doesn't, the spec quietly ships a broken KB reference that needs a `personalize.sh`-style expansion.

Related: `scripts/personalize.sh` has no logic to swap `~/eam/eam-terraform` for a team-specific path. If this spec lands as-is, every new team member who runs `personalize.sh` inherits the author's personal path. Either add a prompt to `personalize.sh` for the terraform repo path, or explicitly scope this KB as "author-only, not committed to main" and handle it in local overrides.

### I4. `terraform-audit` skill is described but not structured

Spec says "Create `skills/terraform-audit/SKILL.md`" and gives a 7-step workflow. Existing skills have a specific frontmatter and structure (see `skills/codebase-audit/SKILL.md`, `skills/trace-code/SKILL.md`). The spec should either include the SKILL.md draft or point to a template. Otherwise, the implementer will guess the shape and likely drift from convention.

### I5. Routing-table insertion order unspecified

Spec gives the `→ devops-terraform` block but doesn't say *where* in `orchestrator.md` it goes. Order matters — `→ devops-docs` is currently the catch-all for config/markdown edits, and .tf files are text. If `devops-terraform` is below `devops-docs` in the table, "edit this terraform file" could route to docs first. Recommend: place `devops-terraform` entry above `devops-docs`, with explicit triggers that clearly distinguish analysis (read-only) from edits (still `devops-docs` because no dev-terraform write agent exists).

### I6. Boundary between `devops-terraform` (read) and `devops-docs` (write) on .tf files

Spec doesn't define: when the user says "fix this terraform variable typo", who handles it? `devops-terraform` can't write. `devops-docs` doesn't understand variable chains. The likely answer is: `devops-terraform` diagnoses, orchestrator briefs `devops-docs` with the exact fix. State this handoff explicitly in the spec — it's the main interaction pattern and it's not obvious.

### I7. No versioning or CHANGELOG entry plan

v0.6.1 just shipped. This spec is a user-visible rename + new agent — it warrants v0.7.0. CHANGELOG is listed as a "text replace" target but there's no plan to *add* a v0.7.0 entry describing the rename and new agent. Add to the plan:

- Bump version (likely in `README.md` / `docs/reference/CHANGELOG.md` / wherever version is declared).
- Draft CHANGELOG entry: "BREAKING: renamed dev-* agents to devops-*; added devops-terraform analysis agent; added terraform-audit skill and terraform.md steering."
- Migration note for existing users who have `chat.defaultAgent: dev-orchestrator` in their own `settings/cli.json` overrides.

### I8. Missing file: `agents/agent_config.json.example`

`agents/` contains an `agent_config.json.example` reference file. Spec doesn't list it. Grep confirms no `dev-*` refs currently, but verify during execution and add to the rename pass if it grows them.

### I9. Phase 3 grep command will miss `.kiro/` and dotfiles

The verification grep in Phase 3 doesn't specify `-r` flags or include-paths. `grep -r "dev-orchestrator\|..."` runs from cwd and skips nothing by default — fine. But the repo has a `.kiro/agents/dev-kiro-config.json` which is inside a dotdir. `grep -r` does follow dotdirs by default, so this works — but pin the command: `grep -rE "dev-(orchestrator|reviewer|python|shell|docs|refactor|typescript|frontend|kiro-config)" --exclude-dir=.git` and show expected output: zero lines.

Also: the grep will false-positive on words like `dev-environment` or `independent-`. Tighten the regex or use `-w` for word boundaries: e.g., `grep -rE "\bdev-(orchestrator|...)\b"`.

---

## SUGGESTIONS (nice-to-have)

### S1. Steering filename consistency

`steering/aws-cli.md` is domain-specific by tool name. `steering/terraform.md` is generic. Consider `steering/terraform-cli.md` or `steering/terraform-analysis.md` for pattern parity. Minor.

### S2. Separate PRs for rename vs. new-agent

The spec bundles them "in one pass". The phasing already separates them logically (Phase 1 = rename, Phase 2 = new agent). Shipping them as two PRs makes revert surgery easier if Phase 2 has issues after Phase 1 merges. Optional — call out the tradeoff.

### S3. Preflight gate enforcement is prompt-level only

The 4 preflight checks (creds, symlinks, init, workspace) are enforced by the agent reading its own prompt. There's no hook or hard block. If the agent gets briefed with "skip preflight, just run plan", it will. Acceptable for now (matches other agents' prompt-level discipline), but consider: (a) a hook that blocks `terraform plan` until a marker file exists from the preflight step, or (b) just flag "preflight is prompt-discipline, not a hard block" in the spec so expectations are set.

### S4. The memory note about "Audit Agent" identity

Your memory (`feedback_audit_agent_identity.md`) says: in Kiro-facing prompts/specs/CHANGELOG, the reviewer side should be called "Audit Agent". The rename `dev-reviewer → devops-reviewer` is orthogonal (it's branding the subagent, not the human-side reviewer role), but worth a sanity pass during the spec execution: the CHANGELOG v0.7.0 entry for this rename should refer to the audit-facing role as "Audit Agent" if it talks about review workflows.

---

## UNKNOWNS requiring verification before implementation

1. Does Kiro's `code` tool support HCL AST? → check Kiro docs / try on a scratch `.tf` file.
2. Does `file://~/path` expand `~` in knowledge base `source`? → test with a throwaway KB entry.
3. Deny-wins-over-allow precedence when both regex patterns match? → confirmed in security-model.md **for denied patterns**, but unclear when an allow pattern + a deny pattern both match the same command. Test `terraform init -upgrade` against a temporary agent before relying on it.
4. Does `terraform workspace select <name>` qualify as "mutating"? It writes `.terraform/environment`. Spec allows it. Probably fine for analysis but worth confirming.
5. `terraform graph` in the allow list — emits DOT to stdout, harmless, but confirm it doesn't require network/API calls depending on provider.

---

## Recommended rewrites to the spec

Before implementing, update the spec to:

1. **Add** a complete `agents/devops-terraform.json` block (full JSON, not prose).
2. **Enumerate** all seven prompt-file renames and the `.kiro/agents/devops-kiro-config.json` cross-reference update.
3. **Decide** and record: does `devops-terraform` belong in the orchestrator prompt's post-implementation trigger list? (Recommend: no, read-only.)
4. **Resolve** the `use_aws` tool vs. shell-AWS contradiction. Pick one.
5. **Write** the actual regex for allow/deny lists, not prose descriptions.
6. **Pick** an approach for historical audit docs (footer vs. rewrite) and document the choice.
7. **Add** version bump plan + CHANGELOG v0.7.0 draft entry to Phase 3.
8. **Pin** the Phase 3 verification grep command and expected output.
9. **Add** a `terraform-audit/SKILL.md` draft following existing skill structure.
10. **Verify** the three Unknowns above before merging the new agent.

Once those updates land, the spec is implementable as a single focused dispatch. In current form, it's a good design document but not yet an implementable contract.

> Note: as of v0.7.0, dev-* agents were renamed to devops-*. See docs/specs/2026-04-18-devops-terraform-and-rename/spec.md.
