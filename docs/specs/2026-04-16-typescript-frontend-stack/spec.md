# Spec 3: TypeScript & Frontend Stack

> Status: Approved
> Created: 2026-04-16
> Depends on: Spec 2 (redesigned framework, routing table, skill structure)
> Unblocks: Cost-optimizer Phase 13 (web dashboard)

## Purpose

The kiro-config framework currently supports Python, Bash, and documentation
editing. To build the cost-optimizer web dashboard (and future web projects),
the framework needs TypeScript backend and frontend capabilities: new agents,
steering docs, audit skills, and orchestrator routing.

## Scope

### In scope

- New steering docs: typescript.md, web-development.md, frontend.md
- New agents: dev-typescript, dev-frontend
- New skill: typescript-audit (for dev-reviewer)
- Orchestrator routing table updates
- tooling.md update (Node.js/npm conventions, project-specific venvs)

### Out of scope

- The cost-optimizer dashboard itself (that's a separate project spec)
- Python agent changes
- Shell agent changes
- Orchestrator prompt rewrite (done in Spec 2)

## Key decisions made during brainstorming

| Decision | Choice | Rationale |
|---|---|---|
| Runtime | Node.js | Already in tooling standards, battle-tested, no new tool to maintain |
| Language | TypeScript (strict) | Type safety, better IDE support, same language frontend + backend |
| Backend framework | Express.js | Simple, low ceremony, sufficient for local-only tools |
| Frontend approach | SPA (vanilla TS + Chart.js) | No build step, no framework overhead, clean API separation |
| Architecture | SPA frontend + JSON API backend | Clean separation, parallel development, independent testing |
| Agent split | dev-typescript (backend) + dev-frontend (frontend) | Different skill sets — API design vs. DOM/CSS/accessibility |
| Serving | Backend serves frontend as static files | Single `node app.js` to run everything |

## Design

### Steering docs

#### typescript.md (new, global)

Covers:
- Strict tsconfig.json — `strict: true`, `noUncheckedIndexedAccess: true`, no `any`
- ESLint + Prettier configuration
- Vitest for testing (native TS support, fast)
- Zod for runtime validation
- Typed request/response interfaces for Express
- Error handling patterns (typed error classes, middleware)
- Import conventions (path aliases, barrel exports)
- Naming conventions (consistent with existing reverse notation preference)

Loaded by: dev-typescript, dev-reviewer, dev-refactor

#### web-development.md (new, global)

Covers:
- Express.js patterns: middleware, error handling, route organization
- REST API design: naming, status codes, error response format
- CORS configuration for local development
- Configuration management (environment-based, no hardcoded values)
- API versioning strategy
- Request validation with Zod
- Logging (structured, same philosophy as Python — no console.log in production)

Loaded by: dev-typescript, dev-reviewer, dev-refactor

#### frontend.md (new, global)

Covers:
- HTML5 semantic markup
- CSS conventions: BEM naming for component styles (`.block__element--modifier`),
  utility classes only from a project-defined set (no Tailwind dependency)
- Vanilla TypeScript DOM patterns (no framework)
- Chart.js integration patterns
- Fetch API with typed responses
- Accessibility requirements (WCAG 2.1 AA)
- Responsive design rules
- Error handling (API failures, loading states, empty states)
- No console.log in production — use a lightweight logger or remove

Loaded by: dev-frontend, dev-reviewer, dev-refactor

#### Frontend verification strategy

dev-frontend has no TDD skill because frontend testing is fundamentally
different from backend unit testing. Instead, dev-frontend verifies via:

1. **HTML validation:** check semantic structure (no div soup, proper heading
   hierarchy, form labels present)
2. **Accessibility check:** verify ARIA attributes, keyboard navigation paths,
   color contrast ratios documented in comments
3. **Responsive check:** verify CSS handles narrow widths (min 320px) —
   no horizontal overflow, no truncated content
4. **Error states:** verify the UI handles: API unreachable, empty data,
   loading state, malformed response
5. **Chart rendering:** verify Chart.js config produces the expected chart
   type with sample data

The verification-before-completion skill handles the "verify before reporting
DONE" gate. The above checklist is added to the dev-frontend prompt so the
agent knows what to check.

#### tooling.md update

Add:
- Node.js/npm conventions (npm for package management, commit package-lock.json)
- Project-specific venvs: scripts in project repos may need project-specific
  venvs (e.g., `sre/.venv/bin/python`), not system Python or `uv run` from root
- TypeScript quality: ESLint + Prettier, `tsc --noEmit` for type checking, Vitest

### Agents

#### dev-typescript (new)

```json
{
  "name": "dev-typescript",
  "description": "Writes and modifies TypeScript code for Node.js/Express backends. Follows TDD with Vitest, strict TypeScript, and verifies before completing.",
  "prompt": "file://./prompts/typescript-dev.md",
  "model": "claude-sonnet-4.6",
  "tools": ["read", "write", "shell", "code"],
  "allowedTools": ["read", "write", "code"],
  "toolsSettings": {
    "fs_write": {
      "allowedPaths": ["~/personal/**", "~/eam/**", "./**"],
      "deniedPaths": [
        "~/.ssh", "~/.aws", "~/.gnupg", "~/.config/gh",
        "~/.kiro/settings/cli.json", "~/.kiro/agents",
        "~/.kiro/hooks", "~/.kiro/steering"
      ]
    },
    "execute_bash": {
      "autoAllowReadonly": true,
      "deniedCommands": [
        "rm -r.*",
        "rm -f.*r.*",
        "rm --recursive.*",
        "chmod -R 777 /",
        "mkfs\\\\.",
        "dd if/dev",
        "git push.*",
        "git push",
        "git add.*",
        "git commit.*",
        "kubectl apply.*",
        "kubectl create.*",
        "kubectl delete.*",
        "terraform apply.*",
        "terraform destroy.*",
        "helm install.*",
        "helm upgrade.*",
        "helm delete.*",
        "docker push.*",
        "docker run.*",
        "docker build.*"
      ]
    }
  },
  "resources": [
    "file://~/.kiro/steering/**/*.md",
    "file://.kiro/steering/**/*.md",
    "skill://~/.kiro/skills/test-driven-development/SKILL.md",
    "skill://~/.kiro/skills/systematic-debugging/SKILL.md",
    "skill://~/.kiro/skills/verification-before-completion/SKILL.md",
    "skill://~/.kiro/skills/receiving-code-review/SKILL.md"
  ],
  "includeMcpJson": false
}
```

Note: The full deny list should be copied from dev-python.json at
implementation time to ensure consistency. The above is the minimum set.

#### dev-typescript prompt (typescript-dev.md)

Covers:
- TypeScript 5+ strict mode patterns
- Express.js route handlers with typed req/res
- Vitest for testing (describe/it/expect, test clients with supertest)
- Zod for request validation
- ESLint + Prettier after changes
- npm for package management
- Same workflow as dev-python: read → TDD → lint → verify → report status
- Same constraints: no git push, no file modifications outside scope

#### dev-frontend (new)

```json
{
  "name": "dev-frontend",
  "description": "Writes HTML, CSS, and TypeScript for SPA frontends. Handles Chart.js, accessibility, responsive design. No backend code.",
  "prompt": "file://./prompts/frontend-dev.md",
  "model": "claude-sonnet-4.6",
  "tools": ["read", "write", "shell", "code"],
  "allowedTools": ["read", "write", "code"],
  "toolsSettings": {
    "fs_write": {
      "allowedPaths": ["~/personal/**", "~/eam/**", "./**"],
      "deniedPaths": [
        "~/.ssh", "~/.aws", "~/.gnupg", "~/.config/gh",
        "~/.kiro/settings/cli.json", "~/.kiro/agents",
        "~/.kiro/hooks", "~/.kiro/steering"
      ]
    },
    "execute_bash": {
      "autoAllowReadonly": true,
      "deniedCommands": [
        "rm -r.*",
        "rm -f.*r.*",
        "rm --recursive.*",
        "chmod -R 777 /",
        "mkfs\\\\.",
        "dd if/dev",
        "git push.*",
        "git push",
        "git add.*",
        "git commit.*",
        "python3? .*",
        "uv .*",
        "pip .*",
        "kubectl apply.*",
        "kubectl create.*",
        "kubectl delete.*",
        "terraform apply.*",
        "terraform destroy.*",
        "helm install.*",
        "helm upgrade.*",
        "helm delete.*",
        "docker push.*",
        "docker run.*",
        "docker build.*"
      ]
    }
  },
  "resources": [
    "file://~/.kiro/steering/**/*.md",
    "file://.kiro/steering/**/*.md",
    "skill://~/.kiro/skills/verification-before-completion/SKILL.md",
    "skill://~/.kiro/skills/receiving-code-review/SKILL.md"
  ],
  "includeMcpJson": false
}
```

Note: dev-frontend additionally blocks `python3?` and `uv` — it should
never run Python. Full deny list copied from dev-python.json at
implementation time, plus Python-specific blocks.

#### dev-frontend prompt (frontend-dev.md)

Covers:
- HTML5 semantic structure
- CSS layout and styling patterns
- Vanilla TypeScript for DOM manipulation
- Chart.js chart creation and configuration
- Fetch API for backend communication
- Accessibility (ARIA labels, keyboard navigation, color contrast)
- Responsive design (mobile-first, breakpoints)
- Same workflow: read → implement → verify → report status
- Verification checklist: HTML validation, accessibility, responsive,
  error states, chart rendering (see frontend.md steering doc)
- No TDD skill — uses the verification checklist above instead of
  test-first development

### Orchestrator routing updates

Add to routing table in orchestrator prompt:

```
### → dev-typescript

Triggers: write TypeScript, Express route, Node.js backend, API endpoint,
TypeScript server, implement with Vitest

Route when: The primary deliverable is TypeScript backend code (Express
routes, middleware, API logic, data processing).

### → dev-frontend

Triggers: HTML page, CSS styling, frontend component, chart, dashboard UI,
responsive layout, accessibility fix, DOM manipulation

Route when: The primary deliverable is frontend code (HTML, CSS, TypeScript
for browser, Chart.js visualizations).

### → dev-typescript + dev-frontend (parallel)

Triggers: full-stack feature, add page with API, new dashboard section

Route when: The feature requires both backend API changes and frontend UI
changes. Dispatch in parallel — they work on independent file sets.
```

Add dev-typescript and dev-frontend to:
- `dev-orchestrator.json` → `toolsSettings.subagent.availableAgents`
- `dev-orchestrator.json` → `toolsSettings.subagent.trustedAgents`

#### Session boundary

Creating new agents (dev-typescript, dev-frontend) and updating
dev-orchestrator.json requires a session restart for the changes to load.
Implementation order:
1. Create steering docs (no restart needed — loaded via glob)
2. Create agent JSON configs + prompts + update dev-orchestrator.json
3. Commit → exit session → new session
4. Verify: orchestrator can dispatch to dev-typescript and dev-frontend
5. Create typescript-audit skill + update dev-reviewer.json
6. Commit → exit session → new session (if dev-reviewer.json changed)
7. Update docs (skill-catalog, creating-agents, README)

### typescript-audit skill (new, for dev-reviewer)

Similar to python-audit but for TypeScript projects:

```
Steps:
1. Run automated checks:
   - npx eslint .
   - npx tsc --noEmit
   - npx vitest run
2. Manual review checklist:
   - No `any` types (use `unknown` + type guards)
   - No type assertions (`as X`) without justification
   - Zod schemas match TypeScript interfaces
   - Error handling: no unhandled promise rejections
   - Express middleware: proper next() calls, error middleware has 4 params
   - No console.log in production code
3. Report findings
```

Add to dev-reviewer.json resources.

### Shared API contract types

For projects with SPA frontend + Express backend, the API contract types
should be shared. Convention:

```
project/
  src/
    types/          ← shared TypeScript interfaces
      api.ts        ← request/response types used by both backend and frontend
    server/         ← Express backend (dev-typescript owns)
    public/         ← SPA frontend (dev-frontend owns)
```

Both agents reference `src/types/` but neither owns it exclusively.
Changes to shared types follow this protocol:

1. **Initial creation:** dev-typescript creates `src/types/api.ts` as part
   of the first backend task (it defines the API, so it defines the types)
2. **Backend needs new types:** dev-typescript modifies `src/types/api.ts`,
   then orchestrator dispatches dev-frontend to consume the new types
3. **Frontend needs new types:** dev-frontend reports NEEDS_CONTEXT to
   orchestrator, orchestrator dispatches dev-typescript to add the types,
   then re-dispatches dev-frontend
4. **Both need changes simultaneously:** orchestrator dispatches dev-typescript
   first (types are API-driven), waits for completion, then dispatches
   dev-frontend with the updated types

Rule: dev-typescript is the primary author of shared types. dev-frontend
is a consumer. This avoids conflicts.

## Files to create

| File | Purpose |
|---|---|
| `steering/typescript.md` | TypeScript conventions and patterns |
| `steering/web-development.md` | Express.js and API design patterns |
| `steering/frontend.md` | HTML/CSS/TS frontend conventions |
| `agents/dev-typescript.json` | TypeScript backend agent config |
| `agents/dev-frontend.json` | Frontend agent config |
| `agents/prompts/typescript-dev.md` | TypeScript agent prompt |
| `agents/prompts/frontend-dev.md` | Frontend agent prompt |
| `skills/typescript-audit/SKILL.md` | TypeScript quality audit for reviewer |

## Files to modify

| File | Change |
|---|---|
| `steering/tooling.md` | Add Node.js/npm conventions, project-specific venvs |
| `agents/dev-orchestrator.json` | Add dev-typescript + dev-frontend to availableAgents/trustedAgents |
| `agents/prompts/orchestrator.md` | Add TypeScript + frontend routing lanes |
| `agents/dev-reviewer.json` | Add typescript-audit skill to resources |
| `docs/reference/skill-catalog.md` | Add typescript-audit, update agent matrix |
| `docs/reference/creating-agents.md` | Add dev-typescript and dev-frontend to architecture diagram |
| `README.md` | Update agent/steering counts |
| `docs/TODO.md` | Mark completed items |

## Acceptance criteria

- [ ] dev-typescript can write Express routes with typed req/res and Vitest tests
- [ ] dev-frontend can write HTML/CSS/TS with Chart.js and accessibility compliance
- [ ] Orchestrator routes TypeScript backend work to dev-typescript
- [ ] Orchestrator routes frontend work to dev-frontend
- [ ] Orchestrator dispatches both in parallel for full-stack features
- [ ] dev-reviewer can audit TypeScript code using typescript-audit skill
- [ ] All three new steering docs are loaded by appropriate agents
- [ ] tooling.md includes Node.js/npm conventions and project-specific venv note
- [ ] deniedCommands on new agents match existing subagent security baseline
- [ ] dev-typescript and dev-frontend model set to claude-sonnet-4.6
- [ ] New agents appear in skill-catalog.md matrix
- [ ] shellcheck clean on any modified hooks
- [ ] Agent-audit passes with no inconsistencies after all changes

> Note: as of v0.7.0, dev-* agents were renamed to devops-*. See docs/specs/2026-04-18-devops-terraform-and-rename/spec.md.
