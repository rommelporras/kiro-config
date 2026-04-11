#!/usr/bin/env bash
# PreToolUse hook on execute_bash — blocks sed/awk/perl on JSON files.
# Exit 2 = block with message to use jq instead.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

[[ -z "$COMMAND" ]] && exit 0

if echo "$COMMAND" | grep -qP '(sed|awk|perl)\s+[^|;]*\.json|\.json[^|;]*\|\s*(sed|awk|perl)'; then
  echo "BLOCKED: Do not use sed/awk/perl on JSON files. Use jq instead." >&2
  exit 2
fi

exit 0
