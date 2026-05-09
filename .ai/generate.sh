#!/usr/bin/env bash
set -euo pipefail
# Generate provider-specific agent configs from .ai/agents.yaml
# Requires: yq + jq (no python)
# @see docs/adr/011-020/024-centralized-ai-agent-configuration.md

YAML=".ai/agents.yaml"
[[ -f "$YAML" ]] || { echo "ERROR: $YAML not found"; exit 1; }
command -v yq >/dev/null 2>&1 || { echo "ERROR: yq required (brew install yq)"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq required (brew install jq)"; exit 1; }

DATA=$(yq -o=json "$YAML")
AGENTS=$(echo "$DATA" | jq -r '.agents | keys[]')

echo ""
echo "Generating agent configs from .ai/agents.yaml..."
echo ""

for name in $AGENTS; do
  agent=$(echo "$DATA" | jq ".agents[\"$name\"]")
  prompt_file=$(echo "$agent" | jq -r '.prompt')
  prompt_content=$(cat "$prompt_file")
  description=$(echo "$agent" | jq -r '.description')

  # ── Kiro ──
  mkdir -p .kiro/agents
  kiro_tools=$(echo "$agent" | jq '.tools.kiro // []')
  kiro_allowed=$(echo "$agent" | jq '.allowed.kiro // []')
  kiro_resources=$(echo "$agent" | jq '[.resources[]? | "file://" + .]')
  kiro_shortcut=$(echo "$agent" | jq -r '.shortcuts.kiro // empty')
  kiro_hook=$(echo "$agent" | jq -r '.hooks.spawn // empty')
  kiro_welcome=$(echo "$agent" | jq -r '.welcome // empty')

  jq -n \
    --arg name "$name" \
    --arg desc "$description" \
    --arg prompt "file://$prompt_file" \
    --argjson tools "$kiro_tools" \
    --argjson allowed "$kiro_allowed" \
    --argjson resources "$kiro_resources" \
    '{name: $name, description: $desc, prompt: $prompt, tools: $tools, allowedTools: $allowed, resources: $resources}' | \
  jq --arg sc "$kiro_shortcut" 'if $sc != "" then .keyboardShortcut = $sc else . end' | \
  jq --arg hook "$kiro_hook" 'if $hook != "" then .hooks = {agentSpawn: [{command: $hook}]} else . end' | \
  jq --arg wm "$kiro_welcome" 'if $wm != "" then .welcomeMessage = $wm else . end' \
  > ".kiro/agents/${name}.json"
  echo "  kiro/$name.json        ✓"

  # ── Amazon Q ──
  mkdir -p .amazonq/agents
  q_tools=$(echo "$agent" | jq '.tools.q // []')
  q_allowed=$(echo "$agent" | jq '.allowed.q // []')

  jq -n \
    --arg name "workspace-tui-$name" \
    --arg desc "$description" \
    --arg prompt "$prompt_content" \
    --argjson tools "$q_tools" \
    --argjson allowed "$q_allowed" \
    --argjson resources "$kiro_resources" \
    '{name: $name, description: $desc, prompt: $prompt, tools: $tools, allowedTools: $allowed, resources: $resources, useLegacyMcpJson: false}' | \
  jq --arg hook "$kiro_hook" 'if $hook != "" then .hooks = {agentSpawn: [{command: $hook}]} else . end' \
  > ".amazonq/agents/workspace-tui-${name}.json"
  echo "  q/$name.json           ✓"
done

# ── Claude Code (.claude/settings.json) ──
mkdir -p .claude
claude_agents="{}"
for name in $AGENTS; do
  agent=$(echo "$DATA" | jq ".agents[\"$name\"]")
  prompt_file=$(echo "$agent" | jq -r '.prompt')
  prompt_content=$(cat "$prompt_file")
  description=$(echo "$agent" | jq -r '.description')
  claude_allowed=$(echo "$agent" | jq '.allowed.claude // []')

  claude_agents=$(echo "$claude_agents" | jq \
    --arg name "$name" \
    --arg desc "$description" \
    --arg prompt "$prompt_content" \
    --argjson allowed "$claude_allowed" \
    '.[$name] = {description: $desc, prompt: $prompt, allowedTools: $allowed}')
done
echo "$claude_agents" | jq '{agents: .}' > .claude/settings.json
echo "  claude/settings.json   ✓"

# ── CLI wrappers ──
mkdir -p scripts/ai
for name in $AGENTS; do
  prompt_file=$(echo "$DATA" | jq -r ".agents[\"$name\"].prompt")
  cat > "scripts/ai/${name}.sh" << EOF
#!/usr/bin/env bash
# @see docs/adr/011-020/024-centralized-ai-agent-configuration.md
set -euo pipefail
ROOT="\$(cd "\$(dirname "\$0")/../.." && pwd)"
PROMPT_FILE="\$ROOT/${prompt_file}"
if command -v kiro-cli >/dev/null 2>&1; then
  exec kiro-cli chat --agent "$name" "\$@"
elif command -v claude >/dev/null 2>&1; then
  exec claude --agent "$name" "\$@"
elif command -v q >/dev/null 2>&1; then
  exec q chat --agent "workspace-tui-$name" "\$@"
elif command -v tgpt >/dev/null 2>&1; then
  exec tgpt --preprompt "\$(cat "\$PROMPT_FILE")" "\$@"
elif command -v llama-cli >/dev/null 2>&1; then
  exec llama-cli --preprompt "\$(cat "\$PROMPT_FILE")" "\$@"
else
  echo "No AI CLI found. Install: kiro-cli, claude, q, or tgpt"; exit 1
fi
EOF
  chmod +x "scripts/ai/${name}.sh"
done
echo "  scripts/ai/*.sh        ✓"

echo ""
echo "Done. Generated for: kiro, claude, q, tgpt, llama-cli"
