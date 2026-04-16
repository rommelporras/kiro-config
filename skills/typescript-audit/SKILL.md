---
name: typescript-audit
description: Use when reviewing TypeScript code quality — run ESLint, check types, verify tests, flag common issues. Trigger on "audit", "typescript audit", "lint", "check TypeScript code".
---

# TypeScript Audit

Quick quality check for TypeScript projects. Run the automated tools, flag what they miss.

## Steps

### 1. Run automated checks

```bash
# Lint
npx eslint .

# Type check
npx tsc --noEmit

# Tests
npx vitest run
```

Fix any failures before proceeding.

### 2. Manual review checklist

After automated tools pass, check these (tools can't catch them):

**Types:**
- [ ] No `any` types — use `unknown` + type guards
- [ ] No type assertions (`as X`) without justifying comment
- [ ] Zod schemas match TypeScript interfaces (`z.infer<typeof Schema>`)
- [ ] No unparameterized generics

**Error handling:**
- [ ] No unhandled promise rejections — async handlers wrapped
- [ ] Express error middleware has 4 params (`err, req, res, next`)
- [ ] No silent `catch {}` blocks — every handler logs or re-throws

**Express patterns:**
- [ ] Middleware mounted in correct order (parsers before routes, error handler last)
- [ ] Routes use proper HTTP methods and status codes
- [ ] Request bodies validated with Zod before use
- [ ] `next()` called correctly in middleware chains

**Code quality:**
- [ ] No `console.log` in production code
- [ ] No hardcoded ports, URLs, or credentials
- [ ] Functions under ~30 lines
- [ ] No deep nesting (>3 levels)

**Security:**
- [ ] No `eval()` or `Function()` on user input
- [ ] CORS configured with explicit origins (no `*` in production)
- [ ] No secrets in code or config files
- [ ] Dependencies checked with `npm audit`

### 3. Report

For each finding: file, line, what's wrong, suggested fix, priority (High/Medium/Low).

Group by: automated tool failures first, then manual findings.
