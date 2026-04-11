#!/usr/bin/env bash
# Auto-capture — filters, extracts keywords, deduplicates, writes to episodes.md.
# Called by correction-detect.sh with flag file path as $1.

FLAG="$1"
[[ ! -f "$FLAG" ]] && exit 0

CORRECTION=$(cat "$FLAG")
KB_DIR="$(cd "$(dirname "$0")/../../knowledge" 2>/dev/null && pwd)"
[[ ! -d "$KB_DIR" ]] && exit 0
EPISODES="$KB_DIR/episodes.md"
RULES="$KB_DIR/rules.md"

# Gate 1: Filter questions and no-action messages
if echo "$CORRECTION" | grep -qiP '^\s*(what|where|when|how|why|who|can you|could you)\b.*\?'; then
  rm -f "$FLAG"
  exit 0
fi

# Gate 2: Extract technical keywords (max 3)
KEYWORDS=$(echo "$CORRECTION" | grep -oiP '\b(jq|sed|awk|perl|json|yaml|toml|terraform|helm|docker|kubectl|aws|boto3|python|pip|uv|git|branch|main|master|pager|cli|s3|ec2|iam|lambda|rds|ecs|eks|cfn|ssm|kms|vpc|alb|nlb|sg|acm|route53|cloudfront|sqs|sns|dynamodb|secrets|tfstate|compose|dockerfile|ruff|mypy|pytest)\b' | tr '[:upper:]' '[:lower:]' | sort -u | head -3 | paste -sd',' -)

[[ -z "$KEYWORDS" ]] && rm -f "$FLAG" && exit 0

# Gate 3: Deduplicate against rules.md and existing episodes
SUMMARY=$(echo "$CORRECTION" | head -1 | cut -c1-120)
if grep -qiF "$SUMMARY" "$EPISODES" 2>/dev/null; then
  rm -f "$FLAG"
  exit 0
fi

# Gate 4: Capacity check (max 30 active episodes)
ACTIVE=$(grep -c '| active |' "$EPISODES" 2>/dev/null || echo 0)
if [[ "$ACTIVE" -ge 30 ]]; then
  rm -f "$FLAG"
  exit 0
fi

# Append episode
DATE=$(date +%Y-%m-%d)
echo "$DATE | active | $KEYWORDS | $SUMMARY" >> "$EPISODES"

# Signal distillation
touch /tmp/kb-changed.flag

rm -f "$FLAG"
exit 0
