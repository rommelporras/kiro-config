#!/usr/bin/env bash
# Distillation library — sourced by context-enrichment.sh, not run standalone.
# Promotes episodes to rules when keyword frequency >= 3.

KB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../knowledge" 2>/dev/null && pwd)"
EPISODES="$KB_DIR/episodes.md"
RULES="$KB_DIR/rules.md"
ARCHIVE_DIR="$KB_DIR/archive"

distill_check() {
  [[ ! -f "$EPISODES" ]] && return

  # Count keyword frequency across active episodes
  declare -A kw_count
  while IFS='|' read -r date status keywords summary; do
    status=$(echo "$status" | xargs)
    [[ "$status" != "active" ]] && continue
    IFS=',' read -ra kws <<< "$(echo "$keywords" | xargs)"
    for kw in "${kws[@]}"; do
      kw=$(echo "$kw" | xargs)
      [[ -n "$kw" ]] && kw_count[$kw]=$(( ${kw_count[$kw]:-0} + 1 ))
    done
  done < <(grep '| active |' "$EPISODES" 2>/dev/null)

  for kw in "${!kw_count[@]}"; do
    local threshold=3
    [[ "$kw" == "general" ]] && threshold=5
    [[ ${kw_count[$kw]} -lt $threshold ]] && continue

    # Skip if rule section already exists
    grep -q "^## \[.*${kw}.*\]" "$RULES" 2>/dev/null && continue

    # Auto-detect severity from episode content
    local severity="🟡"
    if grep -i "| active |.*${kw}" "$EPISODES" | grep -qiP '(never|always|blocked|correction)'; then
      severity="🔴"
    fi

    # Collect summaries for the rule
    local summary
    summary=$(grep -i "| active |.*${kw}" "$EPISODES" | head -1 | awk -F'|' '{print $4}' | xargs)

    # Promote: add rule
    printf '\n## [%s]\n- %s %s\n' "$kw" "$severity" "$summary" >> "$RULES"

    # Mark source episodes as promoted
    awk -v kw="$kw" 'BEGIN{IGNORECASE=1} $0 ~ kw && /\| active \|/ {
      sub(/\| active \|/, "| promoted |")
    } 1' "$EPISODES" > "${EPISODES}.tmp" && mv "${EPISODES}.tmp" "$EPISODES"
  done
}

archive_promoted() {
  [[ ! -f "$EPISODES" ]] && return
  local month_file="$ARCHIVE_DIR/episodes-$(date +%Y-%m).md"
  mkdir -p "$ARCHIVE_DIR"

  grep '| promoted |\|| resolved |' "$EPISODES" >> "$month_file" 2>/dev/null
  grep -v '| promoted |\|| resolved |' "$EPISODES" > "${EPISODES}.tmp"
  mv "${EPISODES}.tmp" "$EPISODES"
}
