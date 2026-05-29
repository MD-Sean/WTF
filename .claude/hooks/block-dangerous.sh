#!/usr/bin/env bash
# PreToolUse hook: Block dangerous Bash commands
set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

DENY_PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "git push.*--force.*main"
  "git push.*--force.*master"
  "git reset --hard"
  "git checkout -- \."
  "git clean -fd"
  "curl.*|.*\/bin\/sh"
  "curl.*|.*\/bin\/bash"
  "wget.*|.*\/bin\/sh"
  "wget.*|.*\/bin\/bash"
)

# Strip heredoc bodies (data between <<'EOF'/<<EOF and closing EOF) before matching
STRIPPED=$(echo "$COMMAND" | awk '/<<['"'"'"]?[A-Z_]+['"'"'"]?/{skip=1; print; next} /^[A-Z_]+$/ && skip{skip=0; next} !skip{print}')

COMMAND_LOWER=$(echo "$STRIPPED" | tr '[:upper:]' '[:lower:]')

for pattern in "${DENY_PATTERNS[@]}"; do
  if echo "$COMMAND_LOWER" | grep -qiE "$pattern"; then
    echo "Blocked: '$COMMAND' matches dangerous pattern '$pattern'. Propose a safer alternative." >&2
    exit 2
  fi
done

exit 0
