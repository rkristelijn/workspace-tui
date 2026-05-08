#!/usr/bin/env bash
set -euo pipefail
pnpm exec tsc -p .config/tsconfig.json --noEmit 2>&1
