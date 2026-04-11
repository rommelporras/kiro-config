#!/usr/bin/env bash
set -euo pipefail
# Stop hook — appends session timestamp to log for agent-audit analysis.

LOG_DIR="$(cd "$(dirname "$(readlink -f "$0")")/../../knowledge" && pwd)" || { echo "Cannot resolve knowledge dir" >&2; exit 1; }
LOG_FILE="$LOG_DIR/session-log.txt"

mkdir -p "$LOG_DIR"
echo "$(date -Iseconds) | session-end" >> "$LOG_FILE"
