#!/usr/bin/env bash
set -euo pipefail

KIRO_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIRO_HOME="${HOME}/.kiro"
DIRS=(steering agents skills settings hooks docs)

mkdir -p "${KIRO_HOME}"

for dir in "${DIRS[@]}"; do
  target="${KIRO_HOME}/${dir}"
  source="${KIRO_CONFIG_DIR}/${dir}"

  if [[ -L "${target}" ]]; then
    # Already a symlink — re-point it
    ln -sfn "${source}" "${target}"
    echo "  relinked: ~/.kiro/${dir} -> ${source}"
  elif [[ -d "${target}" ]]; then
    # Real directory — back it up
    mv "${target}" "${target}.bak"
    echo "  backed up: ~/.kiro/${dir} -> ~/.kiro/${dir}.bak"
    ln -sfn "${source}" "${target}"
    echo "  linked:    ~/.kiro/${dir} -> ${source}"
  else
    ln -sfn "${source}" "${target}"
    echo "  linked: ~/.kiro/${dir} -> ${source}"
  fi
done

echo ""
echo "Next: run ./scripts/personalize.sh to set your project paths."
