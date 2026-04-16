# TypeScript

## Compiler Configuration
- **Strict mode always** — `strict: true` in tsconfig.json. Non-negotiable.
- **`noUncheckedIndexedAccess: true`** — array and object index access returns `T | undefined`.
  Forces explicit null checks instead of silent runtime errors.
- **No `any`** — use `unknown` + type guards instead. `any` defeats the type system.
- **`noEmit` for type checking** — run `tsc --noEmit` to verify types without building.

## Linting & Formatting
- **ESLint with TypeScript parser** — `@typescript-eslint/parser` and
  `@typescript-eslint/eslint-plugin`. Zero warnings before commit.
- **Prettier for formatting** — run before commit. Consistent style, no debates.
- **No inline disable comments** — if ESLint flags something, fix it or justify
  the suppression in a code comment above the disable line.

## Testing
- **Vitest for all tests** — native TypeScript support, no transpile step, fast.
  Run `npx vitest run` to verify.
- **Test file naming** — `*.test.ts` co-located with source, or in `tests/` directory.
- **Supertest for Express** — use `supertest` to test HTTP handlers without
  starting a real server.

## Runtime Validation
- **Zod for all external input** — validate request bodies, env vars, config files,
  and API responses with Zod schemas. Never trust unvalidated input.
- **Schema-first** — define the Zod schema first, derive the TypeScript type with
  `z.infer<typeof Schema>`. Single source of truth.
- **Parse, don't cast** — use `schema.parse()` or `schema.safeParse()`.
  Never `as SomeType` to bypass validation.

## Express Patterns
- **Typed request/response** — extend Express types:
  `Request<Params, ResBody, ReqBody, Query>` for full type coverage on handlers.
- **Typed error classes** — extend `Error` with a `statusCode` field.
  Use a single error-handling middleware (4-param: `err, req, res, next`).
- **Async handlers** — wrap async route handlers to catch rejections and
  forward to `next(err)`. Unhandled promise rejections crash the process.

## Import Conventions
- **Path aliases** — configure `paths` in tsconfig.json (e.g., `@/types`, `@/utils`)
  to avoid `../../../` chains. Mirror in `eslint` and build config.
- **Barrel exports** — use `index.ts` to re-export from a directory only when
  the directory is a stable public API. Avoid barrels inside implementation dirs
  (creates circular dependency risk).
- **Explicit extensions** — for ESM output, include `.js` extensions in imports
  (TypeScript resolves `.ts` → `.js` at emit time).

## Naming Conventions
- **Reverse notation** — `users_active` not `active_users`, `errors_validation`
  not `validation_errors`. Consistent with Python steering — groups related
  names together in autocomplete and sorted listings.
- **Interfaces over type aliases for objects** — `interface UserResponse {}` not
  `type UserResponse = {}`. Interfaces are extendable and produce clearer errors.
- **`SCREAMING_SNAKE_CASE` for constants** — `MAX_RETRY_COUNT`, `DEFAULT_PORT`.
- **`PascalCase` for types/interfaces/classes**, `camelCase` for variables and functions.
