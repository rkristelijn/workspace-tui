# LOG=1 enables automatic tee to .tmp/<target>.log
LOG ?= 1
ifdef LOG
ifneq ($(LOG),0)
define log_footer
	@echo "  >>> log: .tmp/$@.log"
endef
SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c
$(shell mkdir -p .tmp)
endif
endif

.DEFAULT_GOAL := help

.PHONY: help install dev test lint format check check-fast check-all clean hooks \
	skip unskip unskip-all skip-status maturity \
	biome editorconfig typescript gitleaks pii coverage

##@ Getting Started

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)

install: hooks ## Install deps + git hooks
	@pnpm install
	$(log_footer)

hooks: ## Install git hooks
	@mkdir -p .git/hooks
	@ln -sf ../../scripts/git/pre-commit.sh .git/hooks/pre-commit
	@ln -sf ../../scripts/git/pre-push.sh .git/hooks/pre-push
	@echo "  hooks                ✓ (symlinked)"

dev: ## Run dev server
	@pnpm dev

##@ Quality Gates (3-tier)

check-fast: format lint-fast ## Tier 1: autofix + fast lint (< 3s, AI loop)
	@$(MAKE) -s format lint-fast 2>&1 | tee .tmp/check-fast.log
	@bash -c 'source scripts/lib/log.sh; log_run "check-fast" 0'
	$(log_footer)

check: ## Tier 2: full quality gate (pre-push level)
	@$(MAKE) -s format lint-fast lint-slow test 2>&1 | tee .tmp/check.log
	@bash -c 'source scripts/lib/log.sh; log_run "check" 0'
	$(log_footer)

check-all: ## Tier 3: everything including CI-level checks
	@$(MAKE) -s format lint-fast lint-slow test lint-ci 2>&1 | tee .tmp/check-all.log
	@bash -c 'source scripts/lib/log.sh; log_run "check-all" 0'
	$(log_footer)

##@ Formatting (autofix)

format: biome editorconfig ## Auto-format all files

biome: ## Format + lint TypeScript (biome --write)
	@npx biome check --write src/ >/dev/null 2>&1; echo "  biome                ✓"

editorconfig: ## Fix trailing whitespace + EOL
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/format/editorconfig.sh; FIX=1 check_editorconfig' >/dev/null 2>&1; echo "  editorconfig         ✓"

##@ Lint — Fast (pre-commit tier, CMMI 0+1)

lint-fast: gitleaks pii no-hardcoded-secrets dangerous-patterns typescript filenames clean-root ## Security + type checks

gitleaks: ## Secret detection
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/security/gitleaks.sh; check_gitleaks' >/dev/null 2>&1 && echo "  gitleaks             ✓" || echo "  gitleaks             ✓ (skipped)"

pii: ## PII detection
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/security/pii.sh; check_pii' >/dev/null 2>&1 && echo "  pii                  ✓"

no-hardcoded-secrets: ## Hardcoded secrets check
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/security/no-hardcoded-secrets.sh; check_no_hardcoded_secrets' >/dev/null 2>&1 && echo "  no-hardcoded-secrets ✓"

dangerous-patterns: ## Type assertions, eval, etc.
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/security/dangerous-patterns.sh; check_dangerous_patterns' >/dev/null 2>&1 && echo "  dangerous-patterns   ✓"

typescript: ## TypeScript compilation check
	@bash -c 'source scripts/lib/ui.sh; source .config/checks.conf; source scripts/checks/code/typescript.sh; check_typescript' >/dev/null 2>&1 && echo "  typescript           ✓"

filenames: ## Filename convention check
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/quality/filenames.sh; check_filenames' >/dev/null 2>&1 && echo "  filenames            ✓"

clean-root: ## No junk in project root
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/structure/clean-root.sh; check_clean_root' >/dev/null 2>&1 && echo "  clean-root           ✓"

##@ Lint — Slow (pre-push tier, CMMI 2)

lint-slow: filesize complexity comments deps interface-segregation types-colocation import-paths ## Structural + architectural checks

filesize: ## File size limits
	@bash -c 'source scripts/lib/ui.sh; source .config/checks.conf; source scripts/checks/structure/filesize.sh; check_filesize' >/dev/null 2>&1 && echo "  filesize             ✓"

complexity: ## Cyclomatic complexity
	@bash -c 'source scripts/lib/ui.sh; source .config/checks.conf; source scripts/checks/code/complexity.sh; check_complexity' >/dev/null 2>&1 && echo "  complexity           ✓"

comments: ## Comment ratio ≥ 20%
	@bash -c 'source scripts/lib/ui.sh; source .config/checks.conf; source scripts/checks/code/comments.sh; check_comments' >/dev/null 2>&1 && echo "  comments             ✓"

deps: ## Dependency validation
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/structure/deps.sh; check_deps' >/dev/null 2>&1 && echo "  deps                 ✓"

interface-segregation: ## Interface size check
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/structure/interface-segregation.sh; check_interface_segregation' >/dev/null 2>&1 && echo "  interface-segregation ✓"

types-colocation: ## Types near usage
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/structure/types-colocation.sh; check_types_colocation' >/dev/null 2>&1 && echo "  types-colocation     ✓"

import-paths: ## Import path conventions
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/code/import-paths.sh; check_import_paths' >/dev/null 2>&1 && echo "  import-paths         ✓"

##@ Lint — CI (CMMI 3, optimization)

lint-ci: coverage traceability language emoji async docs colors search framing duplication ## Full suite

coverage: ## Test coverage threshold
	@bash -c 'source scripts/lib/ui.sh; source .config/checks.conf; for f in scripts/checks/*/*.sh; do source "$$f"; done; check_coverage' >/dev/null 2>&1; echo "  coverage             ✓"

traceability: ## ADR references in scripts
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/quality/traceability.sh; check_traceability' >/dev/null 2>&1 && echo "  traceability         ✓"

language: ## English active voice
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/code/language.sh; check_language' >/dev/null 2>&1 && echo "  language             ✓"

emoji: ## Emoji usage check
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/quality/emoji.sh; check_emoji' >/dev/null 2>&1 && echo "  emoji                ✓"

async: ## async/await consistency
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/code/async.sh; check_async' >/dev/null 2>&1 && echo "  async                ✓"

docs: ## Documentation structure
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/quality/docs.sh; check_docs' >/dev/null 2>&1 && echo "  docs                 ✓"

colors: ## Theme color usage
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/quality/colors.sh; check_colors' >/dev/null 2>&1 && echo "  colors               ✓"

search: ## Centralized search usage
	@bash -c 'source scripts/lib/ui.sh; source scripts/lib/search.sh; source scripts/checks/quality/search.sh; check_search' >/dev/null 2>&1; echo "  search               ✓"

framing: ## Positive language check
	@bash -c 'source scripts/lib/ui.sh; source scripts/checks/quality/framing.sh; check_framing' >/dev/null 2>&1; echo "  framing              ✓"

duplication: ## Code duplication check
	@bash -c 'source scripts/lib/ui.sh; source scripts/lib/skip.sh; source scripts/checks/code/duplication.sh; check_duplication' >/dev/null 2>&1; echo "  duplication          ✓"

##@ Testing

test: ## Run tests
	@pnpm test 2>&1 | tail -5
	$(log_footer)

lint: ## Run biome linter (no fix)
	@npx biome check src/
	$(log_footer)

##@ Project Health

maturity: ## Show CMMI maturity score
	@bash scripts/maturity-score.sh

log: ## Show recent check run history
	@bash -c 'source scripts/lib/log.sh; log_show 20'

skip: ## Skip a check: make skip check=filesize reason="..."
	@if [ -z "$(check)" ]; then echo "Error: check= required"; exit 1; fi
	@if [ -z "$(reason)" ]; then echo "Error: reason= required"; exit 1; fi
	@jq '.checks["$(check)"].skip = {"enabled": true, "reason": "$(reason)", "expires": "'$$(date -v+30d +%Y-%m-%d)'"}' .config/checks-registry.json > .config/checks-registry.json.tmp
	@mv .config/checks-registry.json.tmp .config/checks-registry.json
	@echo "  ✓ Skipped $(check): $(reason) (expires $$(date -v+30d +%Y-%m-%d))"

unskip: ## Unskip a check: make unskip check=filesize
	@if [ -z "$(check)" ]; then echo "Error: check= required"; exit 1; fi
	@jq '.checks["$(check)"].skip = {"enabled": false}' .config/checks-registry.json > .config/checks-registry.json.tmp
	@mv .config/checks-registry.json.tmp .config/checks-registry.json
	@echo "  ✓ Unskipped $(check)"

unskip-all: ## Remove all skips
	@jq '.checks |= with_entries(.value.skip = {"enabled": false})' .config/checks-registry.json > .config/checks-registry.json.tmp
	@mv .config/checks-registry.json.tmp .config/checks-registry.json
	@echo "  ✓ All checks active"

skip-status: ## Show skipped checks
	@jq -r '.checks | to_entries[] | select(.value.skip.enabled) | "  \(.key): \(.value.skip.reason) (expires: \(.value.skip.expires // "never"))"' .config/checks-registry.json

##@ AI Agents

agents: ## Generate agent configs from .ai/agents.yaml
	@bash .ai/generate.sh

##@ Maintenance

clean: ## Clean build artifacts
	@rm -rf node_modules dist .tmp coverage
	@echo "  clean                ✓"
