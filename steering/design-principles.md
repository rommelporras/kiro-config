# Design Principles

## Fail Fast
- **Return errors, never exit** — library code must never call `sys.exit()`.
  Only CLI entry points (`main()`) may exit. Library functions return
  `Result | None` or raise typed exceptions. Callers decide how to handle errors.
- **Validate at boundaries** — check inputs at the public API surface.
  Internal functions can trust their callers.

## Predictable (No Surprises)
- **No hidden side effects** — if a function is named `get_*` or `describe_*`,
  it must not mutate state. Functions that mutate should be named accordingly
  (`enrich_*`, `update_*`, `apply_*`).
- **No magic** — explicit is better than implicit. Pass dependencies as
  arguments, don't reach into global state.

## Rule of Three
- **Don't extract until 3 duplications** — two copies are tolerable.
  Three copies = extract into a shared module. One copy = never pre-extract.
- **KISS over DRY** — if the abstraction is harder to understand than the
  duplication, keep the duplication.

## Separation of Concerns
- **One reason to change per module** — a file mixing display logic, API calls,
  and business rules has three reasons to change. Split by responsibility.
- **No god objects** — any file over 300 lines likely violates SoC.
  Not a hard rule, but a signal to investigate.

## Least Knowledge (Law of Demeter)
- **Modules know only their immediate collaborators** — don't reach through
  objects to call methods on their internals.
- **No cross-layer calls** — library code doesn't import CLI concerns.
  CLI code doesn't import display internals.

## Least Astonishment
- **Same operation, same pattern everywhere** — if `bounce` uses
  `discovery.describe_services`, `status` should too. Don't reinvent
  the same function with a different name in each subcommand.
- **Consistent error handling** — all subcommands handle missing env,
  expired SSO, and API errors the same way.

## Boy-Scout Rule
- **Leave code cleaner than you found it** — small improvements per commit,
  not big-bang rewrites. Tests pass after every file change.
- **Fix what you touch** — if you modify a file and see a lint warning,
  fix it. "Pre-existing" is not an excuse.
