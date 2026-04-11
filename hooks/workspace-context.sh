#!/usr/bin/env bash
# AgentSpawn hook — injects workspace context at session start.
# STDOUT is added to agent context. Runs once per session.

INPUT=$(cat)
CWD=$(echo "${INPUT}" | jq -r '.cwd // ""')
[[ -z "${CWD}" ]] && CWD="$(pwd)"

echo "[Workspace Context]"
echo "- Directory: ${CWD}"

# Git info
if git -C "${CWD}" rev-parse --is-inside-work-tree &>/dev/null; then
  BRANCH=$(git -C "${CWD}" branch --show-current 2>/dev/null)
  LAST_COMMIT=$(git -C "${CWD}" log -1 --format='%h %s (%cr)' 2>/dev/null)
  DIRTY=$(git -C "${CWD}" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  echo "- Branch: ${BRANCH:-detached}"
  echo "- Last commit: ${LAST_COMMIT:-unknown}"
  (( DIRTY > 0 )) && echo "- Uncommitted changes: ${DIRTY} files"
fi

# Python project detection
if [[ -f "${CWD}/pyproject.toml" ]] || [[ -f "${CWD}/setup.py" ]]; then
  PY_VER=$(python3 --version 2>/dev/null | awk '{print $2}')
  [[ -n "${PY_VER}" ]] && echo "- Python: ${PY_VER}"
  [[ -d "${CWD}/.venv" ]] && echo "- Venv: .venv present"
fi

# Local steering detection
[[ -d "${CWD}/.kiro/steering" ]] && echo "- Project steering: yes"
[[ -d "${CWD}/.kiro/agents" ]] && echo "- Project agents: yes"

exit 0
