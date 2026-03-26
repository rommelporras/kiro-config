#!/usr/bin/env bash
# Author: Rommel Porras
# PreToolUse hook — blocks shell commands that write to sensitive files
# or run universally destructive operations.
# Guards against shell writes to credential files and destructive operations.
#
# Exit 2 = block the tool call and show error to LLM.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# =============================================================================
# SENSITIVE FILE WRITES — block redirects to credential files
# =============================================================================

PROTECTED=(
  ".env"
  ".env.local"
  ".env.production"
  ".env.development"
  ".env.staging"
  ".env.test"
  ".pem"
  "credentials.json"
  ".credentials.json"
  "id_rsa"
  "id_ed25519"
  "id_ecdsa"
)

for pattern in "${PROTECTED[@]}"; do
  if echo "$COMMAND" | grep -qE "(>{1,2}|tee(\s+-a)?)\s+['\"]?([^'\" ]*\/)?${pattern}['\"]?(\s*$|\s*[|&;])"; then
    echo "BLOCKED: Command writes to sensitive file matching '$pattern'." >&2
    echo "Edit this file manually in your terminal." >&2
    exit 2
  fi
done

# =============================================================================
# DESTRUCTIVE OPERATIONS — block universally dangerous commands
# =============================================================================

DANGEROUS=(
  "rm -rf /"
  "rm -rf /*"
  "rm -rf ~"
  "> /dev/sd"
  "> /dev/nvme"
  "mkfs."
  ":(){:|:&};:"
  "dd if=/dev"
  "chmod -R 777 /"
)

for pattern in "${DANGEROUS[@]}"; do
  if [[ "$COMMAND" == *"$pattern"* ]]; then
    echo "BLOCKED: Destructive command pattern detected: '$pattern'" >&2
    echo "Run this manually in your terminal if you are certain." >&2
    exit 2
  fi
done

# Force push to main or master
if echo "$COMMAND" | grep -qE "git push.*(--force|-f)" && \
   echo "$COMMAND" | grep -qE "\b(main|master)\b"; then
  echo "BLOCKED: Force push to main/master is not allowed." >&2
  echo "Use a regular push or open a merge request." >&2
  exit 2
fi

exit 0
