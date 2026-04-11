# Shell & Bash

## Script Standards
- **Header:** `#!/usr/bin/env bash` and `set -euo pipefail` on every script.
- **Quoting:** always quote variable expansions: `"${var}"` not `$var`.
- **Conditionals:** use `[[ ]]` over `[ ]`. Use `(( ))` for arithmetic.
- **Functions:** extract any logic block over 10 lines into a named function.
- **Arguments:** include `usage()` function for any script with arguments.
  Use `getopts` or manual parsing with `case` — not positional-only.
- **Long flags:** prefer `--recursive` over `-r` for readability in scripts.

## Error Handling
- **`set -euo pipefail`** catches most failures. For commands that are allowed
  to fail, use `|| true` explicitly.
- **Trap cleanup:** use `trap cleanup EXIT` for temp files, lock files, etc.
- **Exit codes:** use meaningful exit codes. 0 = success, 1 = general error,
  2 = usage error. Document non-standard codes.

## Quality
- **shellcheck:** zero warnings. Run `shellcheck <script>` before committing.
- **No useless use of cat** — `grep pattern file` not `cat file | grep pattern`.
- **No parsing ls** — use `find` or glob patterns instead.
- **Prefer built-ins** — `[[ -f file ]]` over `test -f file`, `${var%.*}` over
  `echo "$var" | sed 's/\..*//'`.

## JSON Handling
- **Never use sed/awk on JSON** — use `jq` for all JSON manipulation.
- **jq patterns:** `.field`, `.[] | select(.key == "val")`, `--arg` for variables.

## Portability
- **Target Bash 4+** — associative arrays, `mapfile`, `readarray` are available.
- **Avoid bashisms when targeting sh** — but for scripts in this repo, Bash is fine.
- **Use `env` in shebang** — `#!/usr/bin/env bash` for portability across systems.
