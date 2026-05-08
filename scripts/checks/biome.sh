#!/usr/bin/env bash
set -euo pipefail
pnpm exec biome check --write . > /dev/null 2>&1
