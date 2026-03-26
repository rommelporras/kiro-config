#!/usr/bin/env bash
# Author: Rommel Porras
# PreToolUse hook — blocks fs_write if content contains known secret patterns.
# Scans content for hardcoded secrets before allowing writes.
#
# Exit 2 = block the tool call and show error to LLM.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // ""')

if [[ -z "$CONTENT" ]]; then
  exit 0
fi

BLOCKED=0

check() {
  local name="$1"
  local pattern="$2"
  if printf '%s' "$CONTENT" | grep -qP -- "$pattern"; then
    echo "BLOCKED: Detected potential ${name} in content being written to '${FILE:-file}'." >&2
    BLOCKED=1
  fi
}

# PEM private keys (RSA, EC, OpenSSH)
check "private key" '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'

# AWS access key IDs
check "AWS access key" 'AKIA[0-9A-Z]{16}'

# GitHub personal access tokens (classic and fine-grained)
check "GitHub token" 'gh[pousr]_[A-Za-z0-9]{36,255}'

# Anthropic API keys
check "Anthropic API key" 'sk-ant-api\d{2}-[A-Za-z0-9\-_]{80,}'

# OpenAI project keys
check "OpenAI API key" 'sk-proj-[A-Za-z0-9\-_]{40,}'

# Context7 API keys
check "Context7 API key" 'ctx7sk-[a-f0-9\-]{36}'

# GitLab personal access tokens
check "GitLab token" 'glpat-[A-Za-z0-9\-_]{20,}'

# Slack tokens (bot, user, app-level)
check "Slack token" 'xox[bpas]-[A-Za-z0-9\-]{10,}'

# Google Cloud service account keys
check "GCP service account key" '"type"\s*:\s*"service_account"'

# Generic secret assignments (password=, secret=, token= with quoted values)
check "hardcoded secret" '(password|secret|token|api_key|apikey)\s*[=:]\s*["\x27][^\s"'\'']{8,}'

if [[ $BLOCKED -eq 1 ]]; then
  echo "Use environment variables or a secret manager (e.g. 1Password op:// references) instead." >&2
  exit 2
fi

exit 0
