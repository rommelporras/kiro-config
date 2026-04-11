#!/usr/bin/env bash
# UserPromptSubmit hook — injects relevant rules from rules.md into agent context.
# STDOUT is added to agent context. Exit 0 always.

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')

[[ -z "$PROMPT" ]] && exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KB_DIR="$(cd "$SCRIPT_DIR/../../knowledge" 2>/dev/null && pwd)"
RULES="$KB_DIR/rules.md"

[[ ! -f "$RULES" ]] && exit 0

# 60-second dedup to avoid spamming
DEDUP_FILE="/tmp/kb-enrich-last"
if [[ -f "$DEDUP_FILE" ]]; then
  LAST=$(cat "$DEDUP_FILE")
  NOW=$(date +%s)
  if (( NOW - LAST < 60 )); then
    exit 0
  fi
fi
date +%s > "$DEDUP_FILE"

# Trigger distillation if kb-changed flag exists
if [[ -f /tmp/kb-changed.flag ]]; then
  source "$SCRIPT_DIR/../_lib/distill.sh"
  distill_check
  archive_promoted
  rm -f /tmp/kb-changed.flag
fi

# Collect rules to inject
INJECTED=()
CURRENT_SECTION=""
CURRENT_KEYWORDS=""

while IFS= read -r line; do
  if [[ "$line" =~ ^##\ \[(.+)\] ]]; then
    CURRENT_KEYWORDS="${BASH_REMATCH[1]}"
    continue
  fi
  if [[ "$line" =~ ^-\ 🔴 ]]; then
    INJECTED+=("$line")
  elif [[ "$line" =~ ^-\ 🟡 ]] && [[ -n "$CURRENT_KEYWORDS" ]]; then
    IFS=',' read -ra kws <<< "$CURRENT_KEYWORDS"
    for kw in "${kws[@]}"; do
      kw=$(echo "$kw" | xargs)
      if echo "$PROMPT" | grep -qiP "\b${kw}\b"; then
        INJECTED+=("$line")
        break
      fi
    done
  fi
done < "$RULES"

# Cap at 5 rules
if [[ ${#INJECTED[@]} -gt 5 ]]; then
  INJECTED=("${INJECTED[@]:0:5}")
fi

# Output to stdout (added to agent context)
if [[ ${#INJECTED[@]} -gt 0 ]]; then
  echo "[Knowledge Rules]"
  printf '%s\n' "${INJECTED[@]}"
fi

exit 0
