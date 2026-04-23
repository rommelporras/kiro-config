# Commands

[Back to README](../../README.md) | [How It Works](how-it-works.md) | [Workflows](workflows.md) | [Tips](tips.md)

---

## CLI commands

| Command | What it does |
|---------|-------------|
| `/agent` | List available agents |
| `/agent <name>` | Switch to a specific agent |
| `/context show` | See loaded steering files and skills |
| `/tools` | See available tools and trust status |
| `/tools trust-all` | Trust all tools for this session |
| `/mcp` | See MCP server status |
| `/guide` | Switch to built-in help agent for Kiro CLI questions |
| `/spawn` | Spawn a parallel agent session (independent work) |
| `/compact` | Compact conversation history (saves tokens on long sessions) |
| `/chat save <path>` | Save current conversation |
| `/chat load <path>` | Load a saved conversation |
| `/chat new` | Start a fresh conversation |
| `/model` | Switch model mid-session |
| `/hooks` | See configured hooks |

## Keyboard shortcuts

| Shortcut | What it does |
|----------|-------------|
| `ctrl+o` | Toggle back to the orchestrator from any agent |

## Skill triggers

Skills activate automatically when you use these phrases. See [Skill Catalog](../reference/skill-catalog.md) for full details on each skill.

### You say it → orchestrator handles it directly

| Phrase | Skill | What happens |
|--------|-------|--------------|
| "brainstorm" / "let's design" / "let's think about" | design-and-spec | Explores ideas, challenges assumptions, proposes approaches |
| "spec out" / "write a spec" / "define requirements" | design-and-spec | Writes formal spec to `docs/specs/` |
| "challenge this" / "poke holes" / "what am I missing" | design-and-spec | Critical analysis mode |
| "write a plan" | writing-plans | Implementation plan from spec |
| "plan execution" / "how should we execute this" | execution-planning | Parallel stages, agent routing, review gates |
| "explain this" / "how does this work" / "walk me through" | explain-code | Explains with analogies and diagrams |
| "trace this" / "map the code flow" / "what files are involved" | trace-code | Deep code flow with file:line references |
| "health check" / "codebase audit" / "technical debt" | codebase-audit | Structured codebase health report |
| "audit agents" / "review config" / "what can we improve" | agent-audit | Audits kiro-config for gaps |
| "check my docs" / "doc drift" / "audit docs" | doc-drift | Detects stale documentation |
| "commit" | commit | Branch safety + secret scan + conventional commit |
| "push" | push | Branch safety gate + auto `-u` on first push |

### Automatic on specialists (you don't trigger these)

| Skill | When it activates |
|-------|-------------------|
| test-driven-development | During feature/bugfix implementation |
| systematic-debugging | When encountering bugs or test failures |
| verification-before-completion | Before any agent claims work is done |
| receiving-code-review | When processing review feedback |
| post-implementation | After any specialist returns DONE |

### Domain-specific audits (on devops-reviewer or devops-terraform)

| Phrase | Skill |
|--------|-------|
| "audit Python code" / "lint" / "check code quality" | python-audit |
| "audit TypeScript" / "check TypeScript code" | typescript-audit |
| "diagnose terraform" / "why did plan fail" / "trace terraform issue" | terraform-audit |

## MCP servers

These are available in every session:

| Server | What it does | Example use |
|--------|-------------|-------------|
| Context7 | Library documentation lookup | "How do I use boto3 paginators?" — fetches current docs |
| AWS Docs | Search and read AWS documentation | "Find the S3 bucket naming rules" |
| AWS Diagram | Generate architecture diagrams | "Draw a diagram of this ECS architecture" |

The orchestrator uses these automatically when relevant. You can also ask directly:
"Look up the Context7 docs for Express.js middleware."

## Knowledge base commands

If configured, semantic search across your indexed codebase:

| Command | What it does |
|---------|-------------|
| `/knowledge show` | Show knowledge base status and indexed sources |
| `/knowledge search "query"` | Search across indexed codebase content |
