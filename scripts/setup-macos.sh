#!/usr/bin/env bash
# macOS setup - install tools via Homebrew

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

# Check if brew is installed
if ! command -v brew > /dev/null 2>&1; then
  echo "ERROR: Homebrew not found"
  echo "Install from: https://brew.sh"
  exit 1
fi

# Read versions from package.json
GITLEAKS_VERSION=$(node -p "require('./package.json').tools.required.gitleaks")
CLOC_VERSION=$(node -p "require('./package.json').tools.required.cloc")
SHELLCHECK_VERSION=$(node -p "require('./package.json').tools.optional.shellcheck")
RIPGREP_VERSION=$(node -p "require('./package.json').tools.optional.ripgrep")

echo "Installing required tools..."

# Install gitleaks
if ! command -v gitleaks > /dev/null 2>&1; then
  echo "  Installing gitleaks@${GITLEAKS_VERSION}..."
  brew install gitleaks
else
  echo "  gitleaks already installed"
fi

# Install cloc
if ! command -v cloc > /dev/null 2>&1; then
  echo "  Installing cloc@${CLOC_VERSION}..."
  brew install cloc
else
  echo "  cloc already installed"
fi

echo ""
echo "Installing optional tools..."

# Install shellcheck
if ! command -v shellcheck > /dev/null 2>&1; then
  echo "  Installing shellcheck@${SHELLCHECK_VERSION}..."
  brew install shellcheck
else
  echo "  shellcheck already installed"
fi

# Install ripgrep
if ! command -v rg > /dev/null 2>&1; then
  echo "  Installing ripgrep@${RIPGREP_VERSION}..."
  brew install ripgrep
else
  echo "  ripgrep already installed"
fi

echo ""
echo "macOS tools installed"
