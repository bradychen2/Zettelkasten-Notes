#!/usr/bin/env bash
set -euo pipefail

# This script prepares the "llm-share-capture" skill to run.
# What it does:
# 1. Installs Node dependencies (Playwright) into this skill folder.
# 2. Installs a Chromium browser binary that Playwright will drive headlessly.
#
# You typically run this once per machine (or whenever dependencies change):
#   bash .codex/skills/llm-share-capture/scripts/bootstrap.sh

# Resolve the skill's root directory no matter where you run this from.
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Run commands from the skill root so relative paths work.
cd "$ROOT_DIR"

# Install Node packages into ./node_modules if not already present.
# - We keep dependencies local to the skill folder so it's self-contained.
if [[ ! -d node_modules ]]; then
  npm -s install --no-fund --no-audit
fi

# Download/install a compatible Chromium for Playwright.
# - Playwright caches browser binaries, so re-running is usually fast.
# - This is required even if you already have Chrome installed, because
#   Playwright uses its own managed browser builds by default.
# Chromium install is cached by Playwright, so repeating this is usually cheap.
npx -s playwright install chromium

# Print a small confirmation so you know where things were installed.
echo "Bootstrap complete:"
echo "- root: $ROOT_DIR"
echo "- playwright: $(node -p \"require('./node_modules/playwright/package.json').version\")"
