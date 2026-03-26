#!/usr/bin/env bash
# Author: Rommel Porras
# PreToolUse hook — blocks writes to sensitive files.
# Prevents direct file writes to credential and key files.
#
# Exit 2 = block the tool call and show error to LLM.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')

if [[ -z "$FILE" ]]; then
  exit 0
fi

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
  if [[ "$FILE" == *"$pattern"* ]]; then
    echo "BLOCKED: $FILE matches sensitive file pattern '$pattern'." >&2
    echo "Edit this file manually in your terminal." >&2
    exit 2
  fi
done

exit 0
