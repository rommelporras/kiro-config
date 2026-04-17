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

BASENAME=$(basename "$FILE")

# Skip known-safe suffixes — template/example/sample files that happen to
# share the sensitive pattern name but are not actual credential files.
# NOTE: .bak is intentionally excluded — .env.bak is still a credential
# backup. NOTE: .md is intentionally excluded — if you're writing a markdown
# file named after a credential pattern, rename it.
case "$BASENAME" in
  *.example|*.sample|*.template|*.dist) exit 0 ;;
esac

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
  # Match if basename is exactly the pattern, ends with the pattern as an
  # extension (e.g., "key.pem" ends with ".pem"), or contains the pattern
  # followed by a suffix (e.g., ".env.bak", ".env.local.gpg", "credentials.json.backup").
  # The safe-suffix filter above already exempted template/example files.
  if [[ "$BASENAME" == "$pattern" \
     || "$BASENAME" == *"$pattern" \
     || "$BASENAME" == "$pattern".* \
     || "$BASENAME" == *"$pattern".* ]]; then
    echo "BLOCKED: $FILE matches sensitive file pattern '$pattern'." >&2
    echo "Edit this file manually in your terminal." >&2
    exit 2
  fi
done

exit 0
