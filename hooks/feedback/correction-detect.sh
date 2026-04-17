#!/usr/bin/env bash
# UserPromptSubmit hook — detects user corrections and triggers auto-capture.
# Reads JSON with .prompt field from stdin.
# Exit 0 always (informational hook, never blocks).

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')

[[ -z "$PROMPT" ]] && exit 0

# Correction patterns (case-insensitive)
PATTERNS=(
  "no,? (use|try|do)"
  "wrong"
  "not what I"
  "try again"
  "instead of"
  "don't use"
  "do not use"
  "use .+ not "
  "use .+ instead"
  "that's (wrong|incorrect|not right)"
  "I said"
  "I meant"
  "stop using"
  "should (be|have|use)"
)

JOINED=$(IFS='|'; echo "${PATTERNS[*]}")

if echo "$PROMPT" | grep -qiP "$JOINED"; then
  FLAG="/tmp/kb-${USER}-correction-$(date +%s).flag"
  echo "$PROMPT" > "$FLAG"
  # Trigger auto-capture
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  bash "$SCRIPT_DIR/auto-capture.sh" "$FLAG" 2>/dev/null &
fi

exit 0
