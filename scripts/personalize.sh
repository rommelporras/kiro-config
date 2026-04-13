#!/usr/bin/env bash
set -euo pipefail

[[ "${TRACE:-}" == "1" ]] && set -x

KIRO_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS_DIR="${KIRO_CONFIG_DIR}/agents"

# --- Collect project paths ---
echo "Where do your projects live? (space-separated paths, e.g. ~/projects ~/work)"
read -r -p "> " raw_paths

user_paths=()
for p in ${raw_paths}; do
  expanded="${p/#\~/$HOME}"
  [[ ! -d "${expanded}" ]] && echo "  WARNING: '${expanded}' does not exist yet"
  user_paths+=("${p}")
done

(( ${#user_paths[@]} == 0 )) && { echo "ERROR: no paths provided" >&2; exit 1; }

# Build JSON arrays via jq
read_paths="$(printf '%s\n' "${user_paths[@]}" | jq -Rn '["~/.kiro"] + [inputs] + ["./**"]')"
write_paths="$(printf '%s\n' "${user_paths[@]}" | jq -Rn '[inputs | . + "/**"] + ["./**"]')"

# --- Update agent JSON files ---
update_file() {
  local file="$1" filter="$2"; shift 2
  local tmp; tmp="$(mktemp)"
  trap 'rm -f "${tmp}"' RETURN
  jq "$@" "${filter}" "${file}" > "${tmp}"
  mv "${tmp}" "${file}"
  echo "  updated: $(basename "${file}")"
}

echo ""
echo "Updating agent configs..."

for f in base.json dev-orchestrator.json; do
  update_file "${AGENTS_DIR}/${f}" \
    '.toolsSettings.fs_read.allowedPaths = $r | .toolsSettings.fs_write.allowedPaths = $w' \
    --argjson r "${read_paths}" --argjson w "${write_paths}"
done

for f in dev-docs.json dev-python.json dev-shell.json dev-refactor.json; do
  update_file "${AGENTS_DIR}/${f}" \
    '.toolsSettings.fs_write.allowedPaths = $w' \
    --argjson w "${write_paths}"
done

# --- Update setup-knowledge.sh ---
echo ""
echo "Path to your main project repo (for knowledge base, or press Enter to skip):"
read -r -p "> " project_repo

echo "Path to your kiro-config clone (press Enter for: ${KIRO_CONFIG_DIR}):"
read -r -p "> " kiro_path
kiro_path="${kiro_path:-${KIRO_CONFIG_DIR}}"
kiro_path="${kiro_path/#\~/$HOME}"

knowledge_script="${KIRO_CONFIG_DIR}/scripts/setup-knowledge.sh"
tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT

cp "${knowledge_script}" "${tmp}"
if [[ -n "${project_repo}" ]]; then
  project_repo="${project_repo/#\~/$HOME}"
  sed -i "s|~/eam/eam-sre/rommel-porras|${project_repo}|g" "${tmp}"
fi
sed -i "s|~/personal/kiro-config|${kiro_path}|g" "${tmp}"
mv "${tmp}" "${knowledge_script}"
echo "  updated: scripts/setup-knowledge.sh"

echo ""
echo "Done."
echo "  fs_read.allowedPaths  : ${read_paths}"
echo "  fs_write.allowedPaths : ${write_paths}"
