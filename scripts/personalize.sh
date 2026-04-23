#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOCAL_PATHS="${REPO_DIR}/.local-paths"

# --- Load or prompt for config ---
if [[ -f "${LOCAL_PATHS}" ]]; then
  # shellcheck source=/dev/null
  source "${LOCAL_PATHS}"
  echo "Loaded config from .local-paths — re-applying paths..."
else
  echo "Where do your projects live? (space-separated, e.g. ~/projects ~/work)"
  read -r -p "> " raw_paths

  [[ -z "${raw_paths}" ]] && { echo "ERROR: no paths provided" >&2; exit 1; }

  user_paths_input="${raw_paths}"

  echo "Path to your kiro-config clone (Enter for: ${REPO_DIR}):"
  read -r -p "> " kiro_input
  kiro_input="${kiro_input:-${REPO_DIR}}"

  # Expand ~ in kiro path
  KIRO_CONFIG_PATH="${kiro_input/#\~/$HOME}"
  PROJECT_PATHS="${user_paths_input}"

  printf 'PROJECT_PATHS="%s"\nKIRO_CONFIG_PATH="%s"\n' \
    "${PROJECT_PATHS}" "${KIRO_CONFIG_PATH}" > "${LOCAL_PATHS}"
  echo "Saved to .local-paths"
fi

# --- Build path arrays from PROJECT_PATHS ---
user_paths=()
for p in ${PROJECT_PATHS}; do
  user_paths+=("${p}")
done

(( ${#user_paths[@]} == 0 )) && { echo "ERROR: PROJECT_PATHS is empty" >&2; exit 1; }

# Build JSON arrays
read_paths="$(printf '%s\n' "${user_paths[@]}" | jq -Rn '["~/.kiro"] + [inputs] + ["./**"]')"
write_paths="$(printf '%s\n' "${user_paths[@]}" | jq -Rn '[inputs | . + "/**"] + ["./**"]')"
write_paths_with_docs="$(printf '%s\n' "${user_paths[@]}" | jq -Rn '["docs/**"] + [inputs | . + "/**"] + ["./**"]')"
read_paths_bare="$(printf '%s\n' "${user_paths[@]}" | jq -Rn '["~/.kiro"] + [inputs]')"
kiro_write_paths="$(jq -n --arg p "${KIRO_CONFIG_PATH}/**" '[$p]')"

AGENTS_DIR="${REPO_DIR}/agents"

# --- Helper ---
update_file() {
  local file="$1" filter="$2"; shift 2
  local tmp; tmp="$(mktemp)"
  trap 'rm -f "${tmp}"' RETURN
  jq "$@" "${filter}" "${file}" > "${tmp}"
  mv "${tmp}" "${file}"
  echo "  updated: ${file#"${REPO_DIR}/"}"
}

echo ""
echo "Updating agent configs..."

# jq filter strings — $r and $w are jq --argjson variables, not shell variables
# shellcheck disable=SC2016
filter_rw='.toolsSettings.fs_read.allowedPaths = $r | .toolsSettings.fs_write.allowedPaths = $w'
# shellcheck disable=SC2016
filter_w='.toolsSettings.fs_write.allowedPaths = $w'
# shellcheck disable=SC2016
filter_r='.toolsSettings.fs_read.allowedPaths = $r'

# Read + Write: base.json
update_file "${AGENTS_DIR}/base.json" \
  "${filter_rw}" --argjson r "${read_paths}" --argjson w "${write_paths}"

# Read + Write: devops-orchestrator.json (keeps docs/**)
update_file "${AGENTS_DIR}/devops-orchestrator.json" \
  "${filter_rw}" --argjson r "${read_paths}" --argjson w "${write_paths_with_docs}"

# Write-only agents
for f in devops-docs.json devops-python.json devops-shell.json \
          devops-refactor.json devops-typescript.json devops-frontend.json; do
  update_file "${AGENTS_DIR}/${f}" \
    "${filter_w}" --argjson w "${write_paths}"
done

# Read-only: devops-terraform.json
update_file "${AGENTS_DIR}/devops-terraform.json" \
  "${filter_r}" --argjson r "${read_paths_bare}"

# Project-local: .kiro/agents/devops-kiro-config.json
update_file "${REPO_DIR}/.kiro/agents/devops-kiro-config.json" \
  "${filter_w}" --argjson w "${kiro_write_paths}"

# --- Update setup-knowledge.sh ---
first_path="${user_paths[0]}"
knowledge_script="${REPO_DIR}/scripts/setup-knowledge.sh"
tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT

# NOTE: sed replacement is one-shot — only works against the original author's
# hardcoded paths. Re-running with different paths won't find the original strings.
sed \
  -e "s|~/eam/eam-sre/rommel-porras|${first_path}|g" \
  -e "s|~/personal/kiro-config|${KIRO_CONFIG_PATH}|g" \
  "${knowledge_script}" > "${tmp}"
mv "${tmp}" "${knowledge_script}"
echo "  updated: scripts/setup-knowledge.sh"

echo ""
echo "Done."
echo "  PROJECT_PATHS     : ${PROJECT_PATHS}"
echo "  KIRO_CONFIG_PATH  : ${KIRO_CONFIG_PATH}"
