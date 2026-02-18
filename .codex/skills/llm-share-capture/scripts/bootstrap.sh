#!/usr/bin/env bash
set -euo pipefail

# This script prepares the "llm-share-capture" skill to run.
# What it does:
# 1. Installs Node dependencies (Playwright) into this skill folder.
# 2. Installs a Chromium browser binary that Playwright will drive headlessly.
#
# You typically run this once per machine (or whenever dependencies change):
#   bash .codex/skills/llm-share-capture/scripts/bootstrap.sh

# If something fails, we want a clear error message (especially for newbies).
die() {
  echo "bootstrap.sh error: $*" >&2
  exit 1
}

# Print tips that commonly explain install failures in sandboxed/agent environments.
print_permission_hint() {
  cat >&2 <<'EOF'
Troubleshooting hints:
- If you're running inside a coding agent / sandbox, ensure the agent is allowed network access.
- This bootstrap step needs to download:
  - npm packages from registry.npmjs.org
  - browser binaries from a Playwright CDN mirror
- If you see EACCES/permission errors, your environment may not allow writing to your home directory.
  This script uses a local npm cache under this skill folder to avoid that, but the folder must be writable.
EOF
}

# Basic dependency checks (clearer than "command not found" mid-script).
command -v node >/dev/null 2>&1 || die "node is required but not found in PATH"
command -v npm >/dev/null 2>&1 || die "npm is required but not found in PATH"

# Resolve the skill's root directory no matter where you run this from.
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Run commands from the skill root so relative paths work.
cd "$ROOT_DIR"

# Use a local npm cache so installs don't depend on (or write to) ~/.npm.
# This prevents common failures like:
# - "permission denied" writing /Users/<you>/.npm/_logs
# - locked-down home directory in sandboxed environments
NPM_CACHE_DIR="$ROOT_DIR/.npm-cache"
if ! mkdir -p "$NPM_CACHE_DIR"; then
  print_permission_hint
  die "failed to create npm cache dir: $NPM_CACHE_DIR"
fi
export npm_config_cache="$NPM_CACHE_DIR"
export npm_config_update_notifier="false"

# Install Node packages into ./node_modules if not already present.
# - We keep dependencies local to the skill folder so it's self-contained.
if [[ ! -d node_modules ]]; then
  echo "Installing npm dependencies into: $ROOT_DIR/node_modules"
  if ! npm install --no-fund --no-audit; then
    print_permission_hint
    # If npm produced a log in our local cache, point the user to it.
    if [[ -d "$NPM_CACHE_DIR/_logs" ]]; then
      latest_log="$(ls -t "$NPM_CACHE_DIR/_logs" 2>/dev/null | head -n 1 || true)"
      if [[ -n "${latest_log:-}" ]]; then
        echo "npm log: $NPM_CACHE_DIR/_logs/$latest_log" >&2
      fi
    fi
    die "npm install failed"
  fi
fi

# Download/install a compatible Chromium for Playwright.
# - Playwright caches browser binaries, so re-running is usually fast.
# - This is required even if you already have Chrome installed, because
#   Playwright uses its own managed browser builds by default.
#
# Sometimes the default Playwright CDN endpoint can fail (e.g., corporate networks,
# regional routing issues, older browser revisions). We try a small set of mirrors.
install_chromium() {
  local download_host="${1:-}"
  if [[ -n "$download_host" ]]; then
    echo "Installing Chromium via Playwright (download host: $download_host)"
    PLAYWRIGHT_DOWNLOAD_HOST="$download_host" npx -s playwright install chromium
  else
    echo "Installing Chromium via Playwright (default download host)"
    npx -s playwright install chromium
  fi
}

if ! install_chromium ""; then
  if ! install_chromium "https://playwright-akamai.azureedge.net"; then
    if ! install_chromium "https://playwright-verizon.azureedge.net"; then
      print_permission_hint
      die "Playwright Chromium install failed"
    fi
  fi
fi

# Print a small confirmation so you know where things were installed.
echo "Bootstrap complete:"
echo "- root: $ROOT_DIR"
PLAYWRIGHT_VERSION="unknown"
if [[ -f "$ROOT_DIR/node_modules/playwright/package.json" ]]; then
  PLAYWRIGHT_VERSION="$(node -e 'console.log(require("./node_modules/playwright/package.json").version)' 2>/dev/null || echo unknown)"
fi
echo "- playwright: $PLAYWRIGHT_VERSION"
