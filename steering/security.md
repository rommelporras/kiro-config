# Security

## Secrets Management
- **Never hardcode secrets** — no API keys, passwords, tokens, or connection strings
  in code, configs, or environment files checked into git.
- **Use secret manager references** — AWS Secrets Manager, SSM Parameter Store
  (SecureString), or 1Password `op://` references. Inject at runtime.
- **Rotate credentials** — assume any credential older than 90 days is compromised.
  Automate rotation where possible.

## IAM & Access
- **Least privilege always** — no `*` actions or `*` resources in IAM policies.
  Scope to specific actions and ARNs.
- **No long-lived access keys** — use IAM roles with STS assume-role for automation.
  Use SSO/Identity Center for human access.
- **MFA on all human accounts** — no exceptions.

## Network & Infrastructure
- **No public S3 buckets** — use `BlockPublicAccess` on every bucket.
  Serve via CloudFront with OAC if public access is needed.
- **Encrypt at rest and in transit** — KMS for storage, TLS 1.2+ for transport.
  No self-signed certs in production.
- **Security groups: deny by default** — open only required ports. No `0.0.0.0/0`
  ingress except for ALB/NLB on 80/443.

## Code & CI
- **Scan dependencies** — run `safety check` (Python), `npm audit`, or Dependabot.
  Block merges with known critical CVEs.
- **No secrets in CI logs** — mask variables, use CI secret stores.

## Agent Security Model
- **Hooks only fire on the orchestrator** — subagents are NOT protected by
  preToolUse hooks (scan-secrets, protect-sensitive, bash-write-protect).
- **Subagent protection is via deny lists** — `deniedCommands` and `deniedPaths`
  in each agent's `toolsSettings` enforce boundaries.
- **Code-reviewer has no write tool** — enforced at the config level, not just prompt.
- **Always route through dev-reviewer** before committing new scripts or
  implementations touching 3+ files.
