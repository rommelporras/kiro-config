# Web Development

## Express.js Patterns
- **Middleware order matters** — mount body parsers, CORS, and auth before routes.
  Mount error-handling middleware last (4-param signature: `err, req, res, next`).
- **Route organization** — group routes by resource in separate router files.
  Mount under a versioned prefix: `app.use('/api/v1/users', usersRouter)`.
- **Async error forwarding** — wrap async handlers: `router.get('/', asyncHandler(fn))`.
  Never let unhandled promise rejections reach the process.
- **Single error handler** — one 4-param middleware catches all errors.
  Map `statusCode` from typed error classes to HTTP response status.

## REST API Design
- **Noun resources, not verbs** — `/api/v1/reports` not `/api/v1/getReports`.
- **Standard status codes** — `200` success, `201` created, `400` bad request,
  `404` not found, `422` validation error, `500` internal error.
- **Consistent error response** — always return `{ error: { code, message } }`.
  Never expose stack traces or internal details in production responses.
- **Plural resource names** — `/users`, `/reports`, `/metrics`. Consistent and predictable.

## CORS
- **Explicit origins** — never use `origin: '*'` in production. For local dev,
  allow `http://localhost:<port>` explicitly via the `cors` package.
- **Credentials flag** — set `credentials: true` only when cookies or auth headers
  are required. Pair with a specific origin, not wildcard.

## Configuration Management
- **Environment variables only** — no hardcoded ports, URLs, or credentials.
  Use `process.env.PORT` with explicit defaults (`process.env.PORT ?? '3000'`).
- **Validate at startup** — use Zod to parse `process.env` on boot. Fail fast
  with a clear error if required vars are missing.
- **No `.env` in git** — commit `.env.example` with placeholder values only.

## Request Validation
- **Zod on every route** — parse `req.body`, `req.params`, and `req.query`
  with Zod schemas before touching the data. Return `422` on parse failure.
- **Schema-first types** — derive TypeScript types from Zod schemas with
  `z.infer<typeof Schema>`. Don't duplicate type definitions.

## Logging
- **No `console.log` in production** — use `pino` or `winston` with structured
  JSON output. Consistent with Python steering (no `print()` in production).
- **Log at the right level** — `info` for requests, `warn` for recoverable issues,
  `error` for failures with stack traces. Never log secrets or PII.
- **Request logging middleware** — log method, path, status, and duration for
  every request. Use a middleware (e.g., `pino-http`), not per-route logging.
