#!/usr/bin/env bash
# Linux setup - install tools via apt

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

# Check if apt is available
if ! command -v apt > /dev/null 2>&1; then
  echo "ERROR: apt not found"
  echo "This script supports Debian/Ubuntu only"
  echo "For other distros, install tools manually"
  exit 1
fi

# Read versions from package.json
GITLEAKS_VERSION=$(node -p "require('./package.json').tools.required.gitleaks")
CLOC_VERSION=$(node -p "require('./package.json').tools.required.cloc")
SHELLCHECK_VERSION=$(node -p "require('./package.json').tools.optional.shellcheck")
RIPGREP_VERSION=$(node -p "require('./package.json').tools.optional.ripgrep")

echo "Installing required tools..."

# Install gitleaks (from GitHub releases)
if ! command -v gitleaks > /dev/null 2>&1; then
  echo "  Installing gitleaks@${GITLEAKS_VERSION}..."
  wget "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"
  tar -xzf "gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"
  sudo mv gitleaks /usr/local/bin/
  rm "gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"
else
  echo "  gitleaks already installed"
fi

# Install cloc
if ! command -v cloc > /dev/null 2>&1; then
  echo "  Installing cloc@${CLOC_VERSION}..."
  sudo apt update
  sudo apt install -y cloc
else
  echo "  cloc already installed"
fi

echo ""
echo "Installing optional tools..."

# Install shellcheck
if ! command -v shellcheck > /dev/null 2>&1; then
  echo "  Installing shellcheck@${SHELLCHECK_VERSION}..."
  sudo apt install -y shellcheck
else
  echo "  shellcheck already installed"
fi

# Install ripgrep
if ! command -v rg > /dev/null 2>&1; then
  echo "  Installing ripgrep@${RIPGREP_VERSION}..."
  sudo apt install -y ripgrep
else
  echo "  ripgrep already installed"
fi

echo ""
echo "Linux tools installed"
