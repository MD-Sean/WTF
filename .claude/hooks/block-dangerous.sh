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

COMMAND_LOWER=$(echo "$COMMAND" | tr '[:upper:]' '[:lower:]')

for pattern in "${DENY_PATTERNS[@]}"; do
  if echo "$COMMAND_LOWER" | grep -qiE "$pattern"; then
    echo "Blocked: '$COMMAND' matches dangerous pattern '$pattern'. Propose a safer alternative." >&2
    exit 2
  fi
done

exit 0
