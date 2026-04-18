#!/usr/bin/env bash
# Creates the workspace-scoped preflight marker.
# Called by devops-terraform agent after user confirms preflight checklist.

set -euo pipefail

WS="$(cat .terraform/environment 2>/dev/null || echo default)"
touch ".terraform/.preflight-confirmed-${WS}"
echo "Preflight marker created for workspace '${WS}'."
