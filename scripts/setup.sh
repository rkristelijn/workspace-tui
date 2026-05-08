#!/usr/bin/env bash
# Setup orchestrator - detects platform and installs tools
# Reads tool versions from package.json

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

cd "$(dirname "$0")/.."

# Detect platform
if [[ "$(uname -s)" == "Darwin" ]]; then
  PLATFORM="macos"
elif [[ "$(uname -s)" == "Linux" ]]; then
  PLATFORM="linux"
else
  echo "Unsupported platform: $(uname -s)"
  echo "Supported: macOS, Linux"
  exit 1
fi

echo "Platform: $PLATFORM"
echo "Installing development tools..."

# Run platform-specific installer
bash "scripts/setup-${PLATFORM}.sh"

echo ""
echo "Setup complete!"
