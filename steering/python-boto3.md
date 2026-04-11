# Python & boto3

## boto3 Patterns
- **Use `boto3-stubs` for type safety** — install service-specific stubs
  (e.g., `boto3-stubs[s3,ec2,sts]`). Enables IDE completion and mypy checking.
- **Paginators over manual loops** — use `client.get_paginator()` instead of
  handling `NextToken` manually. Cleaner and less error-prone.
- **Waiters over sleep loops** — use `client.get_waiter()` for async operations
  (instance running, stack complete, etc.).
- **Session over default client** — create `boto3.Session(region_name=...)` explicitly.
  Don't rely on implicit default region.

## Error Handling
- **Catch specific exceptions** — use `botocore.exceptions.ClientError` and check
  `error.response['Error']['Code']`. Never bare `except`.
- **Retry with backoff** — use `botocore` built-in retries (`config=Config(retries=...)`)
  or `tenacity` for custom retry logic. Don't write manual retry loops.
- **Log the request ID** — on error, log `error.response['ResponseMetadata']['RequestId']`
  for AWS support troubleshooting.

## Project Standards
- **Type annotations on all functions** — use `mypy` with `disallow_untyped_defs`.
- **Structured logging** — use `structlog` or `logging` with JSON formatter.
  No `print()` for operational output.
- **Environment-based config** — use `pydantic-settings` or `os.environ` with
  explicit defaults. No hardcoded AWS account IDs or endpoints.
