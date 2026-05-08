.PHONY: help install dev test lint format check clean hooks

.DEFAULT_GOAL := help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: hooks ## Install dependencies and git hooks
	pnpm install

hooks: ## Install git hooks
	@mkdir -p .git/hooks
	@cp scripts/git/pre-commit.sh .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
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

clean: ## Clean build artifacts
	rm -rf node_modules dist .tmp coverage
