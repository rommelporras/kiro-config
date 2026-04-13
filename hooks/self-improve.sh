#!/usr/bin/env bash
set -euo pipefail

KIRO="${HOME}/.kiro"
OUT="${KIRO}/knowledge/improvement-suggestions.md"
AGENTS="${KIRO}/agents"
mkdir -p "$(dirname "${OUT}")"

no_issues() { echo "## $1"$'\n'"No issues found."; }

check_orphaned_skills() {
  local findings=()
  while IFS= read -r f; do
    local name; name="$(basename "$(dirname "${f}")")"
    grep -rl "${name}" "${AGENTS}"/*.json &>/dev/null || findings+=("- ${name} — not referenced in any agent JSON")
  done < <(find -L "${KIRO}/skills" -name "SKILL.md" 2>/dev/null)
  (( ${#findings[@]} )) && { echo "## Orphaned Skills"; printf '%s\n' "${findings[@]}"; } || no_issues "Orphaned Skills"
}

check_routing_overlaps() {
  local orc="${AGENTS}/prompts/orchestrator.md"
  [[ -f "${orc}" ]] || { no_issues "Routing Overlaps"; return; }
  declare -A seen; local findings=() section=""
  while IFS= read -r line; do
    [[ "${line}" =~ ^###\ →\ (.+)$ ]] && section="${BASH_REMATCH[1]}" && continue
    [[ "${line}" =~ ^Triggers:\ (.+)$ ]] || continue
    IFS=',' read -ra words <<< "${BASH_REMATCH[1]}"
    for w in "${words[@]}"; do
      local word; word="$(echo "${w}" | tr -d ' ')"; [[ -z "${word}" ]] && continue
      if [[ -v seen["${word}"] ]] && [[ "${seen["${word}"]}" != "${section}" ]]; then
        findings+=("- \"${word}\" appears in both ${seen["${word}"]} and ${section}")
      else
        seen["${word}"]="${section}"
      fi
    done
  done < "${orc}"
  (( ${#findings[@]} )) && { echo "## Routing Overlaps"; printf '%s\n' "${findings[@]}"; } || no_issues "Routing Overlaps"
}

check_stale_steering() {
  local findings=()
  while IFS= read -r f; do
    local name; name="$(basename "${f}")"
    while IFS= read -r p; do
      [[ -e "${p}" ]] || findings+=("- ${name} references ${p}")
    done < <(grep -oP '(?<=`)([~.][a-zA-Z0-9_./-]*\/[a-zA-Z0-9_./-]+)(?=`)|(?<=file://)([~.][a-zA-Z0-9_./-]+)' "${f}" 2>/dev/null | grep -v '[*]' | sort -u || true)
  done < <(find -L "${KIRO}/steering" -name "*.md" 2>/dev/null)
  (( ${#findings[@]} )) && { echo "## Stale Paths (steering)"; printf '%s\n' "${findings[@]}"; } || no_issues "Stale Paths (steering)"
}

check_agent_paths() {
  local findings=()
  while IFS= read -r f; do
    local name; name="$(basename "${f}")"
    while IFS= read -r raw; do
      local uri_type="" stripped="${raw}"
      [[ "${raw}" == skill://* ]] && uri_type="skill" && stripped="${raw#skill://}"
      [[ "${raw}" == file://*  ]] && uri_type="file"  && stripped="${raw#file://}"
      [[ "${stripped}" == *'*'* ]] && continue
      local exp="${stripped/\~/${HOME}}"
      if [[ "${uri_type}" == "skill" ]]; then
        [[ -e "${exp}" ]] || findings+=("- ${name} references ${raw}")
      else
        local chk="${exp%%/**}"
        [[ -z "${chk}" ]] || [[ -e "${chk}" ]] || findings+=("- ${name} references ${raw}")
      fi
    done < <(jq -r '[.toolsSettings.fs_read.allowedPaths//[],.toolsSettings.fs_write.allowedPaths//[],[.resources[]?|if type=="object" then .source else . end],([.prompt//empty])]|flatten|.[]' "${f}" 2>/dev/null || true)
  done < <(find -L "${AGENTS}" -maxdepth 1 -name "*.json" 2>/dev/null)
  (( ${#findings[@]} )) && { echo "## Stale Paths (agents)"; printf '%s\n' "${findings[@]}"; } || no_issues "Stale Paths (agents)"
}

GEN="$(date '+%Y-%m-%d %H:%M')"
s1="$(check_orphaned_skills)"; s2="$(check_routing_overlaps)"
s3="$(check_stale_steering)"; s4="$(check_agent_paths)"

if [[ "${s1}${s2}${s3}${s4}" != *"- "* ]]; then
  printf '# Self-Improve Suggestions\n\nGenerated: %s\n\nNo issues found.\n' "${GEN}" > "${OUT}"
else
  printf '# Self-Improve Suggestions\n\nGenerated: %s\n\n%s\n\n%s\n\n%s\n\n%s\n' \
    "${GEN}" "${s1}" "${s2}" "${s3}" "${s4}" > "${OUT}"
fi
