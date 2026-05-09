#!/usr/bin/env bash
# @see docs/adr/011-020/024-centralized-ai-agent-configuration.md
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PROMPT_FILE="$ROOT/.ai/prompts/plan.md"
if command -v kiro-cli >/dev/null 2>&1; then
  exec kiro-cli chat --agent "plan" "$@"
elif command -v claude >/dev/null 2>&1; then
  exec claude --agent "plan" "$@"
elif command -v q >/dev/null 2>&1; then
  exec q chat --agent "workspace-tui-plan" "$@"
elif command -v tgpt >/dev/null 2>&1; then
  exec tgpt --preprompt "$(cat "$PROMPT_FILE")" "$@"
elif command -v llama-cli >/dev/null 2>&1; then
  exec llama-cli --preprompt "$(cat "$PROMPT_FILE")" "$@"
else
  echo "No AI CLI found. Install: kiro-cli, claude, q, or tgpt"; exit 1
fi
