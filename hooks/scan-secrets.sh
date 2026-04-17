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

# Whole-value placeholder check. A match is exempted only if the VALUE
# portion (inside quotes, or the matched token itself) is recognizably a
# placeholder — not merely that it CONTAINS a placeholder word.
#
# This prevents an adversarial bypass like
# `password: "CHANGEME_actually_real_secret_xyz987"` which would have passed
# a naive substring filter because of the "CHANGEME" prefix.
#
# AWS's documented example keys are fixed literals. We match them with a
# case-insensitive suffix check for "EXAMPLE" which is how AWS marks them.

is_placeholder_value() {
  local v="$1"
  # Empty value is trivially a placeholder
  [[ -z "$v" ]] && return 0
  # Strip surrounding quotes if present
  v="${v#\"}"; v="${v%\"}"
  v="${v#\'}"; v="${v%\'}"

  # AWS's documented example keys always end with "EXAMPLE" (authoritative) —
  # exempt even though they contain digits.
  case "$v" in
    *EXAMPLE|*EXAMPLEKEY) return 0 ;;
  esac

  # Entropy signal: 3+ consecutive digits in the value indicates real-looking
  # content, not a placeholder. Blocks the bypass
  # `"CHANGEME_actually_real_secret_xyz987"` — the digit run signals a real secret
  # even though the value starts with a placeholder marker.
  if [[ "$v" =~ [0-9]{3,} ]]; then
    return 1
  fi

  # Explicit placeholder markers — whole value starts with / is one of these.
  # Allows stylistic extensions like "your_password_here" or
  # "CHANGEME_before_deploy" as long as they pass the digit-entropy check above.
  case "$v" in
    [Yy]our_*|[Yy]our-*|\<*\>|\{*\}|\$\{*\}|\[*\]) return 0 ;;
    [Pp]laceholder|[Pp]laceholder_*) return 0 ;;
    [Cc][Hh][Aa][Nn][Gg][Ee][Mm][Ee]|[Cc][Hh][Aa][Nn][Gg][Ee][Mm][Ee]_*) return 0 ;;
    [Rr][Ee][Pp][Ll][Aa][Cc][Ee]_[Mm][Ee]|[Rr]eplace[Mm]e|[Rr]eplace[Mm]e_*) return 0 ;;
    [Tt][Oo][Dd][Oo]|[Ff][Ii][Xx][Mm][Ee]|[Dd]ummy|[Ff]ake|[Rr][Ee][Dd][Aa][Cc][Tt][Ee][Dd]) return 0 ;;
    *_here|*_value|*_placeholder|*_example) return 0 ;;
  esac
  return 1
}

check() {
  local name="$1"
  local pattern="$2"
  local matches
  matches=$(printf '%s' "$CONTENT" | grep -oP -- "$pattern" 2>/dev/null)
  if [[ -z "$matches" ]]; then
    return
  fi

  # Process each match: extract the value and check if it's a whole
  # placeholder. Block if ANY match has a real-looking value.
  local found_real=0
  while IFS= read -r match; do
    [[ -z "$match" ]] && continue
    # Extract the value portion. For keyed matches like
    # `password: "CHANGEME_before_deploy` the secret regex stops at the
    # closing quote, so we strip everything up to and including the first
    # quote character. For bare-token matches like `AKIA...`, there's no
    # quote to strip, and the fallback leaves the value as the whole match.
    local value
    value=$(printf '%s' "$match" | sed -E 's/^[^"\x27]*["\x27]//; s/["\x27]$//')
    [[ -z "$value" ]] && value="$match"

    if ! is_placeholder_value "$value"; then
      found_real=1
      break
    fi
  done <<< "$matches"

  if [[ $found_real -eq 1 ]]; then
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
  echo "If this is a documented example/placeholder, mark the value with 'your_', 'example', 'CHANGEME', 'REDACTED', etc." >&2
  exit 2
fi

exit 0
