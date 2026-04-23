[Back to README](../../README.md) | [Creating Agents](creating-agents.md) | [Security Model](security-model.md)

# Customizing kiro-config

> **For AI agents:** When a user asks to customize, extend, or adapt this config, read this document for guidance on what's safe to change and how.

How to extend and adapt the kiro-config system without breaking shared safety contracts.

---

## 1. What's yours to change

These are personal to your copy — change freely:

- **`allowedPaths`** in agent JSONs — add your project directories so agents can read/write your files. Use `personalize.sh` or edit with `jq` directly.
- **Project-local steering** — drop `.kiro/steering/` files in any project repo to add context loaded only in that directory.
- **Project-local agents** — drop `.kiro/agents/` files in any project repo to add or override agents for that project.
- **New skills** — add skills to `skills/` and assign them to agents in their JSON configs.
- **Knowledge base** — seed `knowledge/rules.md` and `knowledge/gotchas.md` with project-specific rules. The self-learning pipeline adds to these automatically.
- **MCP servers** — add entries to `settings/mcp.json` and enable them per-agent with `includeMcpJson`.

---

## 2. What's shared — don't change

These are safety and behavior contracts. Changing them weakens the system:

- **`deniedPaths`** — protects SSH keys, credentials, and Kiro's own config from accidental writes. See [Security Model](security-model.md).
- **`deniedCommands`** — blocks destructive operations: recursive deletes, force pushes to main, infrastructure mutations. Patterns use `\A`/`\z` anchors — see [Audit Playbook](audit-playbook.md) §1.1 before editing.
- **`hooks` blocks in agent JSONs** — secret scanning, destructive command blocking, JSON protection. Defined per-agent because Kiro CLI doesn't inherit hooks across subagents.
- **`steering/` files** — universal engineering standards (Python, TypeScript, shell, security, etc.). Not path-dependent.
- **`skills/` files** — universal agent workflows. Not path-dependent.
- **`settings/cli.json` and `settings/mcp.json`** — shared CLI and MCP config.

---

## 3. Adding project-local steering

Drop a `.kiro/steering/` directory in any project repo. Files there are loaded only when that directory is your working directory — they don't affect other projects.

Use case: a project uses a non-standard framework, has specific naming conventions, or has deployment rules that don't belong in global steering.

```
my-project/
└── .kiro/
    └── steering/
        └── project-conventions.md   # loaded only when CWD is my-project/
```

The file format is the same as global steering docs — plain markdown, no special syntax.

---

## 4. Adding project-local agents

Drop a `.kiro/agents/` directory in any project repo. Agents defined there are available only in that project's context.

The `devops-kiro-config.json` agent in this repo is an example — it's a write agent scoped to the kiro-config directory itself, not loaded globally.

See [Creating Agents](creating-agents.md) for the agent JSON schema, required security baseline (`deniedPaths`, `deniedCommands`), and how to assign skills.

---

## 5. Adding skills

Skills are reusable instruction sets that activate on trigger phrases. To add one:

1. Create a directory under `skills/` with a `SKILL.md` file.
2. Assign it to agents by adding the skill path to the `skills` array in their JSON config.
3. Skills are curated per agent — only assign skills relevant to that agent's role.

See [Skill Catalog](skill-catalog.md) for all 20 existing skills, their trigger phrases, and current agent assignments. Use existing skills as templates for new ones.

---

## 6. Tuning the orchestrator

The orchestrator's routing table (which agent handles which task), delegation format, and post-implementation flow are all defined in `agents/prompts/devops-orchestrator.md`. These are tunable if you need to change routing behavior or add new delegation patterns.

See [README.md](../../README.md) §Architecture and the orchestrator prompt directly for details. Keep changes minimal — the orchestrator prompt is the most load-bearing file in the system.

---

## 7. Self-learning

When you correct the AI, the correction is automatically captured to `knowledge/episodes.md`. After a pattern appears 3+ times, `distill.sh` promotes it to `knowledge/rules.md` as a permanent rule. Rules are injected into agent context on every prompt via `context-enrichment.sh`.

You can also seed rules manually by editing `knowledge/rules.md` directly — useful for project-specific constraints you want enforced immediately without waiting for the promotion threshold.

See [README.md](../../README.md) §Self-Learning Pipeline for the full architecture and hook chain.

---

## 8. Maintaining your copy

As the reference copy evolves, keep your copy current:

- **Diff against upstream** — after pulling updates, diff your copy against the latest to see what changed. Re-run `personalize.sh` to apply your paths to any new agent files.
- **Re-run personalize.sh after updates** — `.local-paths` is preserved, so re-runs are silent and apply your paths to any new agent files.
- **Run agent-audit periodically** — triggers the `agent-audit` skill to check for stale paths, missing security baselines, and skill assignment drift.
- **Check doc drift** — the `doc-drift` skill flags docs that reference deleted files or stale counts.
- **Review `knowledge/gotchas.md`** — add operational lessons as you encounter them. The self-learning pipeline captures corrections but not all context.
