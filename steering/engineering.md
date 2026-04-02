# Engineering Philosophy

- **Evidence over assertions** — Never claim something works without showing proof.
  Don't say "tests pass" or "the fix works" — run the command and show the output.
  No "should work", "probably fixed", or satisfaction before verification.
- **Read before writing** — Understand existing patterns in the codebase before
  modifying or adding code.
- **Systematic over ad-hoc** — Understand root cause before acting. When stuck,
  step back and rethink — never retry the same failing approach with minor variations.
- **Minimal, focused changes** — Solve exactly what was asked. No gold-plating,
  no unrequested refactors, no speculative abstractions.

## Plan Before Building

- For any non-trivial task (3+ steps or architectural decisions), write a plan
  before touching code. Write detailed specs upfront to reduce ambiguity.
- If an approach goes sideways, **STOP and re-plan immediately** — don't keep pushing.
  Two failures on the same approach = mandatory re-plan.
- For creative work (new features, components, behavior changes), explore intent and
  design before implementation. Propose 2-3 approaches with trade-offs. Get user
  approval before writing code.

## Test-Driven Development

- Write the failing test first. Watch it fail. Write minimal code to pass. Verify green.
- No production code without a failing test first. Code before test? Delete it, start over.
- Bug fixes require a regression test that reproduces the bug before writing the fix.
- Tests use real code — mocks only when unavoidable (external APIs, etc.).

## Skill Execution

- When a skill is triggered (commit, push, audit, etc.), execute ALL steps
  in one pass. Don't split across messages or stop halfway.
- Follow the skill's step order exactly. Don't skip steps, reorder, or
  "already know" the answer from earlier context.
- If a step fails or blocks, stop and report — don't silently skip it.

## Systematic Debugging

- No fixes without root cause investigation first. Read error messages completely.
  Reproduce consistently. Check recent changes. Trace data flow.
- One hypothesis at a time. Make the smallest possible change to test it.
  Don't fix multiple things at once.
- If 3+ fix attempts fail, STOP — it's likely an architectural problem, not a bug.
  Discuss with the user before attempting more fixes.
