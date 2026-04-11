#!/usr/bin/env bash
# Setup knowledge bases for kiro-cli.
# Run inside a kiro-cli session or configure manually.
set -euo pipefail

echo "=== Kiro Knowledge Base Setup ==="
echo ""
echo "Run these commands inside a kiro-cli chat session:"
echo ""
echo "# 1. Configure knowledge settings"
echo 'kiro-cli settings knowledge.indexType Best'
echo 'kiro-cli settings knowledge.chunkSize 1024'
echo 'kiro-cli settings knowledge.chunkOverlap 256'
echo "kiro-cli settings knowledge.defaultExcludePatterns '[\"*.tfstate\",\"*.tfstate.backup\",\".terraform/**\",\"node_modules/**\",\"__pycache__/**\",\".git/**\",\"*.pyc\"]'"
echo ""
echo "# 2. Add SRE project knowledge base"
echo '/knowledge add --name "eam-sre" --path ~/eam/eam-sre/rommel-porras --include "*.sh" --include "*.py" --include "*.tf" --include "*.yaml" --include "*.yml" --include "*.md" --include "*.json" --include "*.toml" --exclude ".terraform/**" --exclude "*.tfstate*" --index-type Best'
echo ""
echo "# 3. Add kiro-config knowledge base"
echo '/knowledge add --name "kiro-config" --path ~/personal/kiro-config --include "*.md" --include "*.sh" --include "*.json" --index-type Best'
echo ""
echo "# 4. Verify"
echo '/knowledge show'
