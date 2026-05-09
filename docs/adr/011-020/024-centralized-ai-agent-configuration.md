# ADR-024: Centralized AI Agent Configuration

*Status*: Accepted · *Date*: 2026-05-09 · *Chosen*: Option B (generator)

## Context

We use multiple AI CLI tools for development:

| Tool | Config location | Format | Discovery |
|------|----------------|--------|-----------|
| **Kiro** | `.kiro/agents/*.json` | JSON (name, prompt, tools, resources, hooks) | Local project |
| **Amazon Q** | `~/.aws/amazonq/agents/*.json` | JSON (same schema as Kiro) | Global only |
| **llama-cli** | None (flags only) | CLI args: `--preprompt`, `--model` | N/A |
| **tgpt** | None (flags only) | CLI args: `--preprompt`, `--provider`, `--model` | N/A |

### Challenges

1. **Duplication** — Same prompt/context repeated across Kiro, Q, and CLI wrappers
2. **Drift** — Update one agent, forget the others
3. **No cold start** — New contributor must configure each tool separately
4. **No shared context** — Each tool gets different project knowledge

## Decision

### Option A: Symlink Strategy (minimal, works today)

```
.ai/
  prompts/
    build.md          # Shared system prompt
    plan.md           # Shared planning prompt
    test.md           # Shared test prompt
  context/
    project.md        # Shared project context (≈ CLAUDE.md)
    conventions.md    # Coding conventions
    quality.md        # Quality framework summary

.kiro/agents/
  build.json          # prompt: "file://.ai/prompts/build.md"
  plan.json           # prompt: "file://.ai/prompts/plan.md"
  test.json           # prompt: "file://.ai/prompts/test.md"

.amazonq/agents/
  workspace-tui.json  # prompt: references .ai/prompts/build.md content

scripts/
  ai/
    q-build.sh        # q chat --agent workspace-tui "$@"
    tgpt-ask.sh       # tgpt --preprompt "$(cat .ai/prompts/build.md)" "$@"
    llama-ask.sh      # llama-cli --preprompt "$(cat .ai/prompts/build.md)" "$@"
```

**Pros**: Works immediately, no tooling changes needed
**Cons**: Q doesn't support `file://` in prompt field, requires wrapper scripts

### Option B: Generator Script (DRY, single source)

```
.ai/
  agents.yaml         # Single source of truth for all agents
  generate.sh         # Generates provider-specific configs

# .ai/agents.yaml
agents:
  build:
    description: "Implementation agent"
    prompt: prompts/build.md
    context:
      - CLAUDE.md
      - docs/process/plan-remove-skips-stabilize.md
      - .config/checks-registry.json
      - Makefile
    tools:
      kiro: [fs_read, fs_write, execute_bash, grep, glob, code]
      q: [fsRead, fsWrite, fsReplace, executeBash, fileSearch]
    shortcuts:
      kiro: ctrl+shift+b
    hooks:
      spawn: "make maturity 2>/dev/null | tail -5"

  plan:
    description: "Read-only planning agent"
    prompt: prompts/plan.md
    context:
      - CLAUDE.md
      - docs/process/workflow.md
    tools:
      kiro: [fs_read, grep, glob, code]
      q: [fsRead, listDirectory, fileSearch]
    shortcuts:
      kiro: ctrl+shift+p

  test:
    description: "Quality validation agent"
    prompt: prompts/test.md
    context:
      - CLAUDE.md
      - .config/checks-registry.json
    tools:
      kiro: [fs_read, fs_write, execute_bash, grep, glob, code]
      q: [fsRead, fsWrite, executeBash, fileSearch]
    shortcuts:
      kiro: ctrl+shift+t
    hooks:
      spawn: "make skip-status 2>/dev/null"
```

Run `make agents` → generates `.kiro/agents/*.json` + `.amazonq/agents/*.json` + `scripts/ai/*.sh`

**Pros**: True single source, no drift, easy to add new providers
**Cons**: Requires generator script, YAML dependency, extra build step

### Option C: Makefile Wrappers Only (pragmatic)

Keep provider configs as-is, add Makefile targets for unified access:

```makefile
##@ AI Agents

ai-plan: ## Start planning session (auto-selects available tool)
	@if command -v kiro-cli >/dev/null; then kiro-cli chat --agent plan; \
	elif command -v q >/dev/null; then q chat --agent workspace-tui; \
	else tgpt --preprompt "$$(cat .ai/prompts/plan.md)"; fi

ai-build: ## Start build session
	@if command -v kiro-cli >/dev/null; then kiro-cli chat --agent build; \
	elif command -v q >/dev/null; then q chat --agent workspace-tui; \
	else tgpt --preprompt "$$(cat .ai/prompts/build.md)"; fi

ai-test: ## Start test/validation session
	@if command -v kiro-cli >/dev/null; then kiro-cli chat --agent test; \
	elif command -v q >/dev/null; then q chat --agent workspace-tui; \
	else tgpt --preprompt "$$(cat .ai/prompts/test.md)"; fi
```

**Pros**: Zero new dependencies, works with any tool, graceful fallback
**Cons**: Still duplicated configs, Makefile grows

## Recommendation

**Option B** (generator) for long-term, but start with **Option A** (symlinks + shared prompts) today.

Migration path:
1. Now: Create `.ai/prompts/` with shared prompts, reference via `file://` in Kiro
2. Next: Add `scripts/ai/` wrappers for Q/tgpt/llama-cli
3. Later: Build generator when we have 3+ projects using this pattern

## Prompt Architecture

```
.ai/prompts/build.md:
  ┌─────────────────────────────────────┐
  │ ## Identity                          │  ← Who am I?
  │ ## Project Context                   │  ← What project?
  │ ## Conventions                       │  ← How do we work?
  │ ## Current Plan                      │  ← What are we doing?
  │ ## Quality Rules                     │  ← What are the gates?
  │ ## Delegation                        │  ← When to use sub-agents?
  └─────────────────────────────────────┘
```

Each section can `<!-- include: path -->` for composition (future generator feature).

## Provider Syntax Reference

### Kiro (.kiro/agents/*.json)

```json
{
  "name": "build",
  "prompt": "file://.ai/prompts/build.md",
  "tools": ["fs_read", "fs_write", "execute_bash", "grep", "glob", "code"],
  "allowedTools": ["fs_read", "grep", "glob", "code"],
  "resources": ["file://CLAUDE.md", "file://Makefile"],
  "hooks": { "agentSpawn": [{"command": "make maturity 2>/dev/null | tail -5"}] },
  "keyboardShortcut": "ctrl+shift+b",
  "welcomeMessage": "Build agent ready."
}
```

### Amazon Q (.amazonq/agents/*.json or ~/.aws/amazonq/agents/*.json)

```json
{
  "name": "workspace-tui",
  "prompt": "Inline prompt text (file:// not supported)",
  "tools": ["fsRead", "fsWrite", "fsReplace", "executeBash", "fileSearch"],
  "allowedTools": ["fsRead", "listDirectory", "fileSearch"],
  "resources": ["file://CLAUDE.md"],
  "hooks": { "agentSpawn": [{"command": "make maturity 2>/dev/null | tail -5"}] },
  "useLegacyMcpJson": false
}
```

Note: Q uses camelCase tool names. Global install: `~/.aws/amazonq/agents/`. Local discovery unreliable.

### tgpt (CLI flags)

```bash
tgpt --preprompt "$(cat .ai/prompts/build.md)" "your question"
tgpt --provider openai --model gpt-4 --preprompt "..." "question"
```

### llama-cli (CLI flags)

```bash
llama-cli --preprompt "$(cat .ai/prompts/build.md)" "your question"
```

## File Structure (Option A — immediate)

```
.ai/
  prompts/
    build.md        # Build agent system prompt
    plan.md         # Plan agent system prompt
    test.md         # Test agent system prompt
  README.md         # This ADR's practical guide

.kiro/agents/       # Kiro-specific (references .ai/prompts via file://)
  plan.json
  build.json
  test.json

.amazonq/agents/    # Q-specific (inline prompt, same intent)
  workspace-tui.json

CLAUDE.md           # Shared project context (read by all agents)
```

## Enforcement

- `make agents` validates all agent configs exist and are valid JSON
- Pre-commit: if `.ai/prompts/*.md` changes, warn if agent configs are stale
- Quality check: `traceability` verifies agents reference this ADR

## Consequences

- Contributors get working AI agents on clone (zero setup for Kiro)
- Q requires global install (`cp .amazonq/agents/*.json ~/.aws/amazonq/agents/`)
- Prompts are version-controlled and reviewable
- Adding a new AI tool = add one wrapper script or generator template
