#!/usr/bin/env bash
set -euo pipefail

KIRO_CONFIG_DIR="${KIRO_CONFIG_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

total=$(find "${KIRO_CONFIG_DIR}/skills" -name "SKILL.md" | wc -l | tr -d ' ')
base=$(jq '[.resources[] | select(type == "string" and startswith("skill://"))] | length' "${KIRO_CONFIG_DIR}/agents/base.json")
agents=$(find "${KIRO_CONFIG_DIR}/agents" "${KIRO_CONFIG_DIR}/.kiro/agents" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')
hooks=$(find "${KIRO_CONFIG_DIR}/hooks" -name '*.sh' | wc -l | tr -d ' ')

drift=0

check() {
  local file="$1" pattern="$2" expected="$3" label="$4"
  local found
  found=$(grep -oP "${pattern}" "${KIRO_CONFIG_DIR}/${file}" | grep -oP '\d+' | head -1 || true)
  if [[ -z "${found}" ]]; then
    echo "DRIFT: ${file} — pattern '${label}' not found, expected ${expected}"
    drift=1
    return
  fi
  if [[ "${found}" != "${expected}" ]]; then
    echo "DRIFT: ${file} — says ${found} ${label}, actual is ${expected}"
    drift=1
  fi
}

# README.md — **NN skills** (total)
check "README.md" '\*\*\d+ skills\*\*' "${total}" "skills"
# README.md — loads NN of NN skills (base of total)
found_loads=$(grep -oP 'loads \d+ of (the )?\d+ (global )?skills' "${KIRO_CONFIG_DIR}/README.md" | grep -oP '\d+' | head -1 || true)
if [[ -z "${found_loads}" ]]; then
  echo "DRIFT: README.md — 'loads N of N skills' pattern not found, expected base=${base}"
  drift=1
elif [[ "${found_loads}" != "${base}" ]]; then
  echo "DRIFT: README.md — says ${found_loads} skills (base in 'loads N of N'), actual is ${base}"
  drift=1
fi
# README.md — all NN skills (total)
check "README.md" 'all \d+ skills' "${total}" "skills"

# skill-catalog.md — all NN skills (total)
check "docs/reference/skill-catalog.md" 'all \d+ skills' "${total}" "skills"
# skill-catalog.md — NN of the NN skills (base of total)
found_cat=$(grep -oP '\d+ of the \d+ (global )?skills' "${KIRO_CONFIG_DIR}/docs/reference/skill-catalog.md" | grep -oP '\d+' | head -1 || true)
if [[ -z "${found_cat}" ]]; then
  echo "DRIFT: docs/reference/skill-catalog.md — 'N of the N skills' pattern not found, expected base=${base}"
  drift=1
elif [[ "${found_cat}" != "${base}" ]]; then
  echo "DRIFT: docs/reference/skill-catalog.md — says ${found_cat} skills (base in 'N of the N'), actual is ${base}"
  drift=1
fi

# kiro-cli-install-checklist.md — NN global skills (total)
check "docs/setup/kiro-cli-install-checklist.md" '\d+ global skills' "${total}" "skills"
# kiro-cli-install-checklist.md — NN available skills (total)
check "docs/setup/kiro-cli-install-checklist.md" '\d+ available skills' "${total}" "skills"

# agents/base.json — welcomeMessage NN skills (base)
welcome_count=$(jq -r '.welcomeMessage' "${KIRO_CONFIG_DIR}/agents/base.json" | grep -oP '\d+ skills' | grep -oP '\d+' | head -1 || true)
if [[ -z "${welcome_count}" ]]; then
  echo "DRIFT: agents/base.json — welcomeMessage skill count pattern not found, expected ${base}"
  drift=1
elif [[ "${welcome_count}" != "${base}" ]]; then
  echo "DRIFT: agents/base.json — welcomeMessage says ${welcome_count} skills, actual is ${base}"
  drift=1
fi

# README.md — **NN agents**
check "README.md" '\*\*\d+ agents\*\*' "${agents}" "agents"
# README.md — **NN hooks**
check "README.md" '\*\*\d+ hooks\*\*' "${hooks}" "hooks"

if (( drift == 0 )); then
  echo "Doc consistency: all counts match (${total} skills, ${base} base, ${agents} agents, ${hooks} hooks)"
fi

exit "${drift}"
