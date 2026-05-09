.PHONY: help install dev test lint format check clean hooks

.DEFAULT_GOAL := help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: hooks ## Install dependencies and git hooks
	pnpm install

hooks: ## Install git hooks
	@mkdir -p .git/hooks
	@cp scripts/git/pre-commit.sh .git/hooks/pre-commit
	@cp scripts/git/pre-push.sh .git/hooks/pre-push
	@chmod +x .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-push
	@echo "Git hooks installed"

dev: ## Run development server
	pnpm dev

test: ## Run tests
	pnpm test

lint: ## Run linter
	pnpm lint

format: ## Format code
	pnpm format

check: ## Run all quality checks
	pnpm check

skip: ## Skip a check: make skip check=filesize reason="Needs refactoring"
	@if [ -z "$(check)" ]; then echo "Error: check= required"; exit 1; fi
	@if [ -z "$(reason)" ]; then echo "Error: reason= required"; exit 1; fi
	@jq '.skip["$(check)"] = {"enabled": true, "status": "skip", "reason": "$(reason)", "files": []}' .config/checks-skip.json > .config/checks-skip.json.tmp
	@mv .config/checks-skip.json.tmp .config/checks-skip.json
	@echo "✓ Skipped $(check): $(reason)"

unskip: ## Unskip a check: make unskip check=filesize
	@if [ -z "$(check)" ]; then echo "Error: check= required"; exit 1; fi
	@jq 'del(.skip["$(check)"])' .config/checks-skip.json > .config/checks-skip.json.tmp
	@mv .config/checks-skip.json.tmp .config/checks-skip.json
	@echo "✓ Unskipped $(check)"

clean: ## Clean build artifacts
	rm -rf node_modules dist .tmp coverage
