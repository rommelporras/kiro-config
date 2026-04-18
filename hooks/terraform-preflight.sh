#!/usr/bin/env bash
# PreToolUse hook — blocks terraform plan/validate/state/show unless
# workspace-scoped preflight marker exists.
# Exit 0 = allow, Exit 2 = block with message to LLM.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "${INPUT}" | jq -r '.tool_input.command // ""')

if [[ -z "${COMMAND}" ]]; then
  exit 0
fi

# Extract leading command token
FIRST_TOKEN=$(echo "${COMMAND}" | awk '{print $1}')

# Only gate terraform commands
if [[ "${FIRST_TOKEN}" != "terraform" ]]; then
  exit 0
fi

# Extract terraform subcommand
TF_SUB=$(echo "${COMMAND}" | awk '{print $2}')

# Commands that require preflight confirmation
case "${TF_SUB}" in
  plan|validate|state|show)
    # Read current workspace
    WS="$(cat .terraform/environment 2>/dev/null || echo default)"
    MARKER=".terraform/.preflight-confirmed-${WS}"

    if [[ ! -f "${MARKER}" ]]; then
      echo "BLOCKED: Preflight not completed for workspace '${WS}'." >&2
      echo "Complete the preflight checklist first:" >&2
      echo "  1. Verify AWS credentials: aws sts get-caller-identity" >&2
      echo "  2. Confirm symlinks are set up (if applicable)" >&2
      echo "  3. Run: terraform init" >&2
      echo "  4. Run: terraform workspace select <name>" >&2
      echo "  5. Confirm with the user, then: bash ~/.kiro/scripts/mark-preflight.sh" >&2
      exit 2
    fi
    ;;
  *)
    # All other terraform subcommands pass through
    exit 0
    ;;
esac

exit 0
