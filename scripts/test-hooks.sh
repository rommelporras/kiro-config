#!/usr/bin/env bash
# Author: Rommel Porras
# Functional tests for preToolUse hooks (bash-write-protect, protect-sensitive,
# scan-secrets). Exercises known-safe and known-dangerous inputs to catch
# false-positive regressions and protection-gap regressions.
#
# Usage:   bash scripts/test-hooks.sh
# Exit 0 = all tests pass; exit 1 = one or more failures.
#
# Referenced by audit-playbook.md §1.1 S9 invariant.

set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

PASS=0
FAIL=0
FAILED_TESTS=()

# Build literal AWS example keys at runtime to avoid triggering secret
# scanners (the outer Claude Code hooks) on this test file itself.
AWS_PREFIX="AKIA"
AWS_EXAMPLE="${AWS_PREFIX}IOSFODNN7EXAMPLE"
AWS_REAL="${AWS_PREFIX}1234567890ABCDEF"

run_test() {
  local label="$1"
  local hook="$2"
  local input="$3"
  local expect="$4"   # "pass" or "block"

  local exit_code
  echo "$input" | bash "hooks/$hook" >/dev/null 2>&1
  exit_code=$?

  local actual="pass"
  [ $exit_code -eq 2 ] && actual="block"

  if [ "$actual" = "$expect" ]; then
    PASS=$((PASS+1))
  else
    FAIL=$((FAIL+1))
    FAILED_TESTS+=("[$hook] $label: got '$actual', expected '$expect'")
  fi
}

bwp_input() { jq -n --arg c "$1" '{tool_input: {command: $c}}'; }
fsw_input() { jq -n --arg f "$1" --arg c "$2" '{tool_input: {file_path: $f, content: $c}}'; }

echo "=== bash-write-protect.sh ==="

# False-positive prevention (should PASS)
run_test "commit with dd in msg"         "bash-write-protect.sh" "$(bwp_input 'git commit -m "fix dd if=/dev pattern"')" "pass"
run_test "grep for dd pattern"           "bash-write-protect.sh" "$(bwp_input "grep 'dd if=/dev' README.md")"             "pass"
run_test "echo about chmod"              "bash-write-protect.sh" "$(bwp_input 'echo "never run chmod -R 777 / on prod"')" "pass"
run_test "git rm file"                   "bash-write-protect.sh" "$(bwp_input 'git rm some-file.txt')"                    "pass"
run_test "docker rm container"           "bash-write-protect.sh" "$(bwp_input 'docker rm my-container')"                  "pass"
run_test "npm rm package"                "bash-write-protect.sh" "$(bwp_input 'npm rm lodash')"                           "pass"

# Legitimate blocks (should BLOCK)
run_test "dd if=/dev (destructive)"      "bash-write-protect.sh" "$(bwp_input 'dd if=/dev/zero of=/dev/sda bs=1M')"      "block"
run_test "dd of=/dev (destructive)"      "bash-write-protect.sh" "$(bwp_input 'dd of=/dev/sda if=./iso.img')"            "block"
run_test "mkfs -t older syntax"          "bash-write-protect.sh" "$(bwp_input 'mkfs -t ext4 /dev/sda1')"                 "block"
run_test "mkfs.ext4 modern"              "bash-write-protect.sh" "$(bwp_input 'mkfs.ext4 /dev/sda1')"                    "block"
run_test "chmod -R 777 / catastrophic"   "bash-write-protect.sh" "$(bwp_input 'chmod -R 777 /')"                         "block"
run_test "force push to main"            "bash-write-protect.sh" "$(bwp_input 'git push --force origin main')"           "block"

# Compound-command bypass prevention (regression tests — these bypassed v1 of the fix)
run_test "compound: echo && rm -rf /tmp" "bash-write-protect.sh" "$(bwp_input 'echo hi && rm -rf /tmp/somedir')"         "block"
run_test "compound: cat && rm -rf ~"     "bash-write-protect.sh" "$(bwp_input 'cat foo.txt && rm -rf ~/scratch')"        "block"
run_test "find -exec destructive"        "bash-write-protect.sh" "$(bwp_input 'find /tmp -exec mkfs.ext4 /dev/sda1 {} ;')" "block"
run_test "find -exec rm -rf /"           "bash-write-protect.sh" "$(bwp_input 'find / -exec rm -rf / {} ;')"             "block"

echo ""
echo "=== protect-sensitive.sh ==="

# FP prevention (template/example files)
run_test ".env.example passes"           "protect-sensitive.sh" "$(fsw_input '.env.example' 'FOO=bar')"                   "pass"
run_test ".env.sample passes"            "protect-sensitive.sh" "$(fsw_input 'config/.env.sample' 'FOO=bar')"             "pass"
run_test ".pem.template passes"          "protect-sensitive.sh" "$(fsw_input 'certs/ca.pem.template' 'placeholder')"      "pass"
run_test "credentials.json.dist passes"  "protect-sensitive.sh" "$(fsw_input 'tests/credentials.json.dist' '{}')"         "pass"

# Real protection (should BLOCK)
run_test ".env blocked"                  "protect-sensitive.sh" "$(fsw_input '.env' 'SECRET=x')"                          "block"
run_test ".env.local blocked"            "protect-sensitive.sh" "$(fsw_input 'project/.env.local' 'SECRET=x')"            "block"
run_test "key.pem blocked"               "protect-sensitive.sh" "$(fsw_input 'certs/key.pem' 'pem-data')"                 "block"
run_test "credentials.json blocked"      "protect-sensitive.sh" "$(fsw_input '.aws/credentials.json' '{}')"               "block"
run_test "id_rsa blocked"                "protect-sensitive.sh" "$(fsw_input '.ssh/id_rsa' 'keydata')"                    "block"
run_test ".env.bak still blocked"        "protect-sensitive.sh" "$(fsw_input '.env.bak' 'SECRET=x')"                      "block"

echo ""
echo "=== scan-secrets.sh ==="

# FP prevention (documented placeholders / examples)
run_test "AWS example key in content"    "scan-secrets.sh" "$(fsw_input 'doc.md' "Example ${AWS_EXAMPLE} value")"         "pass"
run_test "placeholder password"          "scan-secrets.sh" "$(fsw_input 'doc.md' 'password: "your_password_here"')"       "pass"
run_test "CHANGEME placeholder"          "scan-secrets.sh" "$(fsw_input 'doc.md' 'token: "CHANGEME_before_deploy"')"      "pass"

# Real secrets (should BLOCK)
run_test "real AWS key blocked"          "scan-secrets.sh" "$(fsw_input 'config.py' "$AWS_REAL")"                         "block"
run_test "real password blocked"         "scan-secrets.sh" "$(fsw_input 'config.py' 'password: "ProductionSecret_xyz123"')" "block"

# Placeholder-bypass regression: value that CONTAINS a placeholder marker but
# isn't a pure placeholder — adversarial-style bypass that v1 of the filter passed.
run_test "bypass: CHANGEME_realsecret"   "scan-secrets.sh" "$(fsw_input 'config.py' 'password: "CHANGEME_actually_real_secret_xyz987"')" "block"
BYPASS_AWS="your_prefix_${AWS_REAL}"
run_test "bypass: your_prefix_realkey"   "scan-secrets.sh" "$(fsw_input 'config.py' "secret: \"${BYPASS_AWS}\"")"                         "block"

echo ""
echo "=== Summary ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
if [ $FAIL -gt 0 ]; then
  echo ""
  echo "Failures:"
  for f in "${FAILED_TESTS[@]}"; do echo "  - $f"; done
  exit 1
fi
exit 0
