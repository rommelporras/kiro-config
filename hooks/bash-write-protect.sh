#!/usr/bin/env bash
# Author: Rommel Porras
# PreToolUse hook — blocks shell commands that write to sensitive files
# or run universally destructive operations.
# Guards against shell writes to credential files and destructive operations.
#
# Exit 2 = block the tool call and show error to LLM.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Extract the leading command token (skip leading VAR=val assignments).
# Used to avoid false positives where destructive substrings appear inside
# commit messages, echo/grep arguments, or quoted strings.
FIRST_CMD=$(echo "$COMMAND" | awk '{for(i=1;i<=NF;i++) if ($i !~ /=/) {print $i; exit}}')

# Commands that handle text/files read-only — do not apply DANGEROUS substring
# checks since any match is descriptive, not an invocation. Still subject to
# the catastrophic rm and rm-safety checks below (handled separately).
#
# NOTE: `find` is deliberately EXCLUDED because `find -exec <cmd>` can
# delegate arbitrary commands. Same reason `sed`, `awk`, `tee`, `xargs` are
# not here — they can invoke or delegate, not just read.
is_readonly_command() {
  case "$1" in
    git|echo|printf|grep|egrep|fgrep|rg|cat|less|more|head|tail|diff|ls|jq|yq) return 0 ;;
    *) return 1 ;;
  esac
}

# =============================================================================
# SENSITIVE FILE WRITES — block redirects to credential files
# =============================================================================

PROTECTED=(
  ".env"
  ".env.local"
  ".env.production"
  ".env.development"
  ".env.staging"
  ".env.test"
  ".pem"
  "credentials.json"
  ".credentials.json"
  "id_rsa"
  "id_ed25519"
  "id_ecdsa"
)

for pattern in "${PROTECTED[@]}"; do
  if echo "$COMMAND" | grep -qE "(>{1,2}|tee(\s+-a)?)\s+['\"]?([^'\" ]*\/)?${pattern}['\"]?(\s*$|\s*[|&;])"; then
    echo "BLOCKED: Command writes to sensitive file matching '$pattern'." >&2
    echo "Edit this file manually in your terminal." >&2
    exit 2
  fi
done

# =============================================================================
# CATASTROPHIC RM — always block (not gated by FIRST_CMD or readonly-skip)
# =============================================================================
#
# These three patterns are narrow and specific enough to justify always
# checking. Catches compound-command bypasses like `echo hi && rm -rf /tmp`
# that would otherwise slip past the FIRST_CMD gate below.
#
# Trade-off: descriptive text containing these exact substrings (e.g. a
# commit message "fix rm -rf / bug") also blocks. Workaround: rephrase.

if [[ "$COMMAND" == *"rm -rf /"* ]] || [[ "$COMMAND" == *"rm -rf /*"* ]] || \
   [[ "$COMMAND" == *"rm -rf ~"* ]]; then
  echo "BLOCKED: Catastrophic rm pattern detected." >&2
  echo "This command is never allowed (even in compound/pipelined form)." >&2
  exit 2
fi

# =============================================================================
# NON-RM DESTRUCTIVE OPERATIONS — block universally dangerous commands
# =============================================================================
#
# Skipped for read-only / text-processing commands (git, echo, grep, cat, etc.)
# because a match on those is descriptive (commit message, grep query,
# echo'd warning) rather than an invocation. See is_readonly_command above.

DANGEROUS=(
  "> /dev/sd"
  "> /dev/nvme"
  "> /dev/hd"
  "of=/dev/sd"        # dd writing to disk (destructive form of dd)
  "of=/dev/nvme"      # dd writing to NVMe
  "of=/dev/hd"        # dd writing to legacy IDE
  "mkfs."
  "mkfs -t"           # older mkfs syntax (mkfs -t ext4 /dev/sda1)
  ":(){:|:&};:"
  "dd if=/dev"        # dd reading from devices (kept for defense-in-depth)
  "chmod -R 777 /"
)

if ! is_readonly_command "$FIRST_CMD"; then
  for pattern in "${DANGEROUS[@]}"; do
    if [[ "$COMMAND" == *"$pattern"* ]]; then
      echo "BLOCKED: Destructive command pattern detected: '$pattern'" >&2
      echo "Run this manually in your terminal if you are certain." >&2
      exit 2
    fi
  done
fi

# =============================================================================
# RM SAFETY — allow single-file rm, block recursive rm
# =============================================================================
#
# Only triggers when `rm` is the leading command. This avoids false positives
# on `git rm`, `docker rm`, `npm rm`, etc. — those are handled by their own
# tooling and are not the rm syscall.

if [[ "$FIRST_CMD" == "rm" ]]; then
  # (Catastrophic patterns are handled above, outside the FIRST_CMD gate,
  #  so compound commands like `echo hi && rm -rf /tmp` are caught.)

  # Block recursive rm (any flag combination containing 'r')
  if echo "$COMMAND" | grep -qP '^rm\b.*(-[a-zA-Z]*r[a-zA-Z]*|--recursive)'; then
    echo "BLOCKED: rm with recursive flag requires user confirmation." >&2
    echo "Run this manually in your terminal." >&2
    exit 2
  fi

  # Allow single-file rm within allowed paths
  ALLOWED_PREFIXES=(
    "${HOME}/eam/"
    "${HOME}/personal/"
    "${HOME}/.kiro/"
  )

  # Extract rm targets (skip flags starting with -)
  TARGETS=()
  IN_RM=false
  for word in $COMMAND; do
    if [[ "$word" == "rm" ]]; then
      IN_RM=true
      continue
    fi
    if [[ "$IN_RM" == true ]] && [[ "$word" != -* ]]; then
      TARGETS+=("$word")
    fi
  done

  for target in "${TARGETS[@]}"; do
    RESOLVED=$(readlink -f "$target" 2>/dev/null || echo "$target")
    ALLOWED=false
    for prefix in "${ALLOWED_PREFIXES[@]}"; do
      if [[ "$RESOLVED" == "${prefix}"* ]]; then
        ALLOWED=true
        break
      fi
    done
    if [[ "$ALLOWED" != true ]]; then
      echo "BLOCKED: rm target '$target' is outside allowed paths." >&2
      echo "Allowed: ~/eam/, ~/personal/, ~/.kiro/" >&2
      exit 2
    fi
  done
fi

# Force push to main or master
if echo "$COMMAND" | grep -qE "git push.*(--force|-f)" && \
   echo "$COMMAND" | grep -qE "\b(main|master)\b"; then
  echo "BLOCKED: Force push to main/master is not allowed." >&2
  echo "Use a regular push or open a merge request." >&2
  exit 2
fi

exit 0
