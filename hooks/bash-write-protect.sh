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
# NON-RM DESTRUCTIVE OPERATIONS — block universally dangerous commands
# =============================================================================

DANGEROUS=(
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

# =============================================================================
# RM SAFETY — allow single-file rm, block recursive rm
# =============================================================================

if echo "$COMMAND" | grep -qP '\brm\b'; then
  # Hard block: catastrophic patterns (always blocked, no exceptions)
  if [[ "$COMMAND" == *"rm -rf /"* ]] || [[ "$COMMAND" == *"rm -rf /*"* ]] || \
     [[ "$COMMAND" == *"rm -rf ~"* ]]; then
    echo "BLOCKED: Catastrophic rm pattern detected." >&2
    echo "This command is never allowed." >&2
    exit 2
  fi

  # Block recursive rm (any flag combination containing 'r')
  if echo "$COMMAND" | grep -qP '\brm\b.*(-[a-zA-Z]*r[a-zA-Z]*|--recursive)'; then
    echo "BLOCKED: rm with recursive flag requires user confirmation." >&2
    echo "Run this manually in your terminal." >&2
    exit 2
  fi

  # Allow single-file rm within allowed paths
  ALLOWED_PREFIXES=(
    "${HOME}/eam/"
    "${HOME}/personal/"
    "${HOME}/.kiro/"
  )

  # Extract rm targets (skip flags starting with -)
  TARGETS=()
  IN_RM=false
  for word in $COMMAND; do
    if [[ "$word" == "rm" ]]; then
      IN_RM=true
      continue
    fi
    if [[ "$IN_RM" == true ]] && [[ "$word" != -* ]]; then
      TARGETS+=("$word")
    fi
  done

  for target in "${TARGETS[@]}"; do
    RESOLVED=$(readlink -f "$target" 2>/dev/null || echo "$target")
    ALLOWED=false
    for prefix in "${ALLOWED_PREFIXES[@]}"; do
      if [[ "$RESOLVED" == "${prefix}"* ]]; then
        ALLOWED=true
        break
      fi
    done
    if [[ "$ALLOWED" != true ]]; then
      echo "BLOCKED: rm target '$target' is outside allowed paths." >&2
      echo "Allowed: ~/eam/, ~/personal/, ~/.kiro/" >&2
      exit 2
    fi
  done
fi

# Force push to main or master
if echo "$COMMAND" | grep -qE "git push.*(--force|-f)" && \
   echo "$COMMAND" | grep -qE "\b(main|master)\b"; then
  echo "BLOCKED: Force push to main/master is not allowed." >&2
  echo "Use a regular push or open a merge request." >&2
  exit 2
fi

exit 0
