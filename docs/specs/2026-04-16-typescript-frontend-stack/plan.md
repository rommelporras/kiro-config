# TypeScript & Frontend Stack — Implementation Plan

> **For agentic workers:** Use the subagent-driven-development skill to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add TypeScript backend and frontend capabilities to kiro-config — new agents, steering docs, audit skill, and orchestrator routing.

**Architecture:** Create 3 steering docs, 2 agents with prompts, 1 audit skill, and update orchestrator routing. Steering docs first (no restart needed), then agents + configs (restart needed).

**Tech Stack:** JSON (agent configs), Markdown (steering, prompts, skills)

**Spec:** `docs/specs/2026-04-16-typescript-frontend-stack/spec.md`

**Prerequisites:**
- Spec 2 must be complete (redesigned orchestrator, dev-kiro-config available)
- dev-kiro-config agent must be available for editing agents/, steering/

---

## Phase 1: Steering docs (no session restart needed)

### Task 1.1: Create typescript.md steering doc

**Files:**
- Create: `steering/typescript.md`

- [ ] **Step 1: Create the steering doc**

Create `steering/typescript.md` covering all items from the spec:
- Strict tsconfig.json (`strict: true`, `noUncheckedIndexedAccess: true`, no `any`)
- ESLint + Prettier configuration
- Vitest for testing
- Zod for runtime validation
- Typed request/response interfaces
- Error handling patterns (typed error classes)
- Import conventions
- Naming conventions (reverse notation)

Follow the format of existing steering docs (e.g., `python-boto3.md`):
header, bullet points, code examples where helpful.

- [ ] **Step 2: Report completion**

### Task 1.2: Create web-development.md steering doc

**Files:**
- Create: `steering/web-development.md`

- [ ] **Step 1: Create the steering doc**

Create `steering/web-development.md` covering:
- Express.js patterns (middleware, error handling, route organization)
- REST API design (naming, status codes, error response format)
- CORS configuration for local development
- Configuration management (environment-based)
- Request validation with Zod
- Structured logging (no console.log in production)

- [ ] **Step 2: Report completion**

### Task 1.3: Create frontend.md steering doc

**Files:**
- Create: `steering/frontend.md`

- [ ] **Step 1: Create the steering doc**

Create `steering/frontend.md` covering:
- HTML5 semantic markup
- CSS conventions: BEM naming (`.block__element--modifier`)
- Vanilla TypeScript DOM patterns
- Chart.js integration patterns
- Fetch API with typed responses
- Accessibility (WCAG 2.1 AA)
- Responsive design rules
- Error handling (API failures, loading states, empty states)
- Frontend verification checklist (from spec: HTML validation, accessibility,
  responsive, error states, chart rendering)

- [ ] **Step 2: Report completion**

### Task 1.4: Update tooling.md

**Files:**
- Modify: `steering/tooling.md`

- [ ] **Step 1: Add Node.js/TypeScript sections**

Add to tooling.md:

```markdown
## Node.js / TypeScript Quality
- **Package management:** `npm`. Commit `package-lock.json`.
- **Linting:** ESLint with TypeScript parser. Zero warnings.
- **Formatting:** Prettier. Run before commit.
- **Type checking:** `tsc --noEmit` with strict mode.
- **Testing:** Vitest. Run `npx vitest run` to verify.
- **No `any`** — use `unknown` + type guards instead.

## Project-Specific Environments
- Scripts in project repos may need project-specific venvs
  (e.g., `sre/.venv/bin/python`), not system Python or `uv run` from root.
- Check for `.venv/`, `node_modules/`, or project-level configs before
  assuming global tool availability.
```

- [ ] **Step 2: Report completion**

---

## Phase 2: Agents and prompts

> **SESSION BOUNDARY:** After this phase, commit and exit. Start a new session
> so dev-typescript and dev-frontend are loaded.

### Task 2.1: Create dev-typescript agent prompt

**Files:**
- Create: `agents/prompts/typescript-dev.md`

- [ ] **Step 1: Create the prompt**

Follow the pattern of `agents/prompts/python-dev.md` but for TypeScript:
- TypeScript 5+ strict mode patterns
- Express.js route handlers with typed req/res
- Vitest for testing (describe/it/expect, supertest for HTTP)
- Zod for request validation
- ESLint + Prettier after changes
- npm for package management
- Workflow: read → TDD → lint → verify → report status
- Constraints: no git push, no file modifications outside scope
- "Before editing any file" section (check imports, tests, consumers)
- Status reporting: DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED

- [ ] **Step 2: Report completion**

### Task 2.2: Create dev-frontend agent prompt

**Files:**
- Create: `agents/prompts/frontend-dev.md`

- [ ] **Step 1: Create the prompt**

- HTML5 semantic structure
- CSS layout and styling (BEM naming)
- Vanilla TypeScript for DOM manipulation
- Chart.js chart creation and configuration
- Fetch API for backend communication
- Accessibility (ARIA labels, keyboard navigation, color contrast)
- Responsive design (mobile-first, min 320px)
- Verification checklist: HTML validation, accessibility, responsive,
  error states, chart rendering
- Workflow: read → implement → verify checklist → report status
- Constraints: no git push, no Python/uv commands, no backend code
- Status reporting: DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED

- [ ] **Step 2: Report completion**

### Task 2.3: Create dev-typescript agent config

**Files:**
- Create: `agents/dev-typescript.json`

- [ ] **Step 1: Create the agent config**

Use the JSON from the spec. Key points:
- `model`: `claude-sonnet-4.6`
- `prompt`: `file://./prompts/typescript-dev.md`
- `tools`: read, write, shell, code
- `allowedTools`: read, write, code
- `deniedCommands`: copy full list from dev-python.json, keep identical
- `resources`: steering glob + TDD, debugging, verification, review skills
- `includeMcpJson`: false

- [ ] **Step 2: Verify JSON is valid**

```bash
jq empty agents/dev-typescript.json && echo "valid"
```

- [ ] **Step 3: Report completion**

### Task 2.4: Create dev-frontend agent config

**Files:**
- Create: `agents/dev-frontend.json`

- [ ] **Step 1: Create the agent config**

Use the JSON from the spec. Key points:
- `model`: `claude-sonnet-4.6`
- `prompt`: `file://./prompts/frontend-dev.md`
- `tools`: read, write, shell, code
- `allowedTools`: read, write, code
- `deniedCommands`: copy from dev-python.json + add `python3? .*`, `uv .*`, `pip .*`
- `resources`: steering glob + verification, review skills (no TDD)
- `includeMcpJson`: false

- [ ] **Step 2: Verify JSON is valid**

```bash
jq empty agents/dev-frontend.json && echo "valid"
```

- [ ] **Step 3: Report completion**

### Task 2.5: Update orchestrator config and prompt

**Files:**
- Modify: `agents/dev-orchestrator.json`
- Modify: `agents/prompts/orchestrator.md`

- [ ] **Step 1: Add agents to orchestrator availableAgents and trustedAgents**

Add `"dev-typescript"` and `"dev-frontend"` to both arrays.

- [ ] **Step 2: Add routing lanes to orchestrator prompt**

Add the three routing lanes from the spec:
- `→ dev-typescript` (TypeScript backend triggers)
- `→ dev-frontend` (frontend triggers)
- `→ dev-typescript + dev-frontend (parallel)` (full-stack triggers)

- [ ] **Step 3: Verify JSON is valid**

```bash
jq empty agents/dev-orchestrator.json
jq '.toolsSettings.subagent.availableAgents' agents/dev-orchestrator.json
```
Expected: array includes dev-typescript and dev-frontend

- [ ] **Step 4: Report completion**

### Task 2.6: Commit and exit

- [ ] **Step 1: Commit Phase 2**

```bash
git add agents/ steering/
git commit -m "feat: add dev-typescript and dev-frontend agents with steering docs"
```

- [ ] **Step 2: Exit session**

Tell user: "New agents committed. Exit (`/quit`) and start a new session.
Then say: 'Continue with Spec 3 Phase 3 — read the spec and plan.'"

---

## Phase 3: Audit skill and documentation

> **Prerequisite:** New session with dev-typescript and dev-frontend loaded.

### Task 3.1: Create typescript-audit skill

**Files:**
- Create: `skills/typescript-audit/SKILL.md`

- [ ] **Step 1: Create the skill**

Follow the pattern of `skills/python-audit/SKILL.md` but for TypeScript:
- Frontmatter: name, description with triggers
- Automated checks: eslint, tsc --noEmit, vitest run
- Manual review checklist: no `any`, no unjustified `as X`, Zod/TS alignment,
  error handling, Express middleware, no console.log
- Report format matching python-audit

- [ ] **Step 2: Report completion**

### Task 3.2: Add typescript-audit to dev-reviewer

**Files:**
- Modify: `agents/dev-reviewer.json`

- [ ] **Step 1: Add skill resource**

Add to resources array:
```json
"skill://~/.kiro/skills/typescript-audit/SKILL.md"
```

- [ ] **Step 2: Verify JSON is valid**

- [ ] **Step 3: Report completion**

### Task 3.3: Update documentation

**Files:**
- Modify: `docs/reference/skill-catalog.md`
- Modify: `docs/reference/creating-agents.md`
- Modify: `README.md`
- Modify: `docs/TODO.md`

- [ ] **Step 1: Update skill-catalog.md**

Add typescript-audit to the skill tables. Update agent assignment matrix
to include dev-typescript and dev-frontend.

- [ ] **Step 2: Update creating-agents.md**

Update the architecture diagram to include dev-typescript and dev-frontend.

- [ ] **Step 3: Update README.md**

Update agent count, steering doc count.

- [ ] **Step 4: Mark Spec 3 complete in docs/TODO.md**

- [ ] **Step 5: Report completion**

---

## Phase 4: Final verification

### Task 4.1: Run agent-audit

- [ ] **Step 1: Trigger agent-audit**

Verify:
- dev-typescript and dev-frontend configs are consistent with other subagents
- deniedCommands match across all subagents
- All skill resources point to existing files
- Routing table has no overlapping triggers
- Skill catalog matches reality
- README counts are accurate

- [ ] **Step 2: Fix any findings**

- [ ] **Step 3: Report completion**
