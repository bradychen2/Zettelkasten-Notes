#!/usr/bin/env bash
set -euo pipefail

# This script is the "friendly CLI wrapper" around the Node/Playwright capture code.
#
# What it does:
# 1. Parses a URL + optional flags from the command line.
# 2. Chooses an output directory (default: a new /tmp/llm_share_capture.XXXXXX folder).
# 3. Calls the Node script (capture.mjs) that actually drives headless Chromium.
# 4. Prints the output directory path at the end so you can open it quickly.
#
# Example:
#   bash .codex/skills/llm-share-capture/scripts/capture.sh 'https://gemini.google.com/share/...'
#
# Note: This requires you to have run bootstrap.sh at least once to install Playwright.

# Resolve the skill's root directory no matter where you run this from.
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# Keep the caller's working directory so we can choose sensible defaults later.
CALLER_PWD="$(pwd)"

usage() {
  cat <<'EOF'
Usage:
  capture.sh <url> [--out <dir>] [--wait-ms <ms>] [--timeout-ms <ms>] [--archive-root <dir>] [--no-archive] [--workspace-copy] [--no-workspace-copy] [--workspace-dir <dir>]

Examples:
  capture.sh 'https://gemini.google.com/share/dea848184b75'
  capture.sh 'https://chat.openai.com/share/...' --wait-ms 8000
  capture.sh 'https://gemini.google.com/share/...' --workspace-dir ./tmp/llm_share_chat
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 2
fi

# First positional argument is always the URL we want to capture.
URL="$1"
shift

# Defaults for optional flags.
# WAIT_MS:
#   Extra "sleep" after the page loads, to give JS apps time to render the chat.
# TIMEOUT_MS:
#   Max time allowed for the initial page navigation.
OUT_DIR=""
WAIT_MS="5000"
TIMEOUT_MS="60000"
ARCHIVE_ROOT="${LLM_SHARE_ARCHIVE_ROOT:-/tmp/llm_share_chat}"
DO_ARCHIVE="1"
# Default to copying into the workspace, because the whole point of this tool is
# to keep a traceable artifact under version-controlled paths (or at least under
# the repo workspace) instead of relying on /tmp lifetime.
#
# Disable with:
#   --no-workspace-copy
# or:
#   export LLM_SHARE_WORKSPACE_COPY=0
DO_WORKSPACE_COPY="${LLM_SHARE_WORKSPACE_COPY:-1}"
WORKSPACE_DIR="${LLM_SHARE_WORKSPACE_DIR:-}"

# Parse optional flags.
# We accept:
#   --out <dir>        write artifacts into a specific directory
#   --wait-ms <ms>     additional wait time after initial load
#   --timeout-ms <ms>  navigation timeout
#   --archive-root <d> archive root (default: /tmp/llm_share_chat or $LLM_SHARE_ARCHIVE_ROOT)
#   --no-archive       disable /tmp archiving entirely
#   --workspace-copy   copy body/title into a workspace folder (disabled by default)
#   --workspace-dir <d>workspace destination root (default: $LLM_SHARE_WORKSPACE_DIR or current directory)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      OUT_DIR="${2:-}"
      shift 2
      ;;
    --wait-ms)
      WAIT_MS="${2:-}"
      shift 2
      ;;
    --timeout-ms)
      TIMEOUT_MS="${2:-}"
      shift 2
      ;;
    --archive-root)
      ARCHIVE_ROOT="${2:-}"
      shift 2
      ;;
    --no-archive)
      DO_ARCHIVE="0"
      shift 1
      ;;
    --workspace-copy)
      DO_WORKSPACE_COPY="1"
      shift 1
      ;;
    --no-workspace-copy)
      DO_WORKSPACE_COPY="0"
      shift 1
      ;;
    --workspace-dir)
      WORKSPACE_DIR="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 2
      ;;
  esac
done

# Decide where to write output artifacts.
# If you didn't pass --out, we create a brand new unique /tmp folder.
if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="$(mktemp -d /tmp/llm_share_capture.XXXXXX)"
else
  # If you did pass --out, ensure the directory exists.
  mkdir -p "$OUT_DIR"
fi

# Run from the skill root so node can find scripts/ and node_modules/.
cd "$ROOT_DIR"

# Safety check: make sure dependencies exist.
# If node_modules is missing, the user probably forgot to run bootstrap.sh.
if [[ ! -d node_modules ]]; then
  echo "Missing dependencies. Run: bash $ROOT_DIR/scripts/bootstrap.sh" >&2
  exit 2
fi

# Run the Playwright capture program.
# It prints a JSON object with full paths to artifacts (body.txt, page.png, etc.).
node "$ROOT_DIR/scripts/capture.mjs" \
  --url "$URL" \
  --out "$OUT_DIR" \
  --wait-ms "$WAIT_MS" \
  --timeout-ms "$TIMEOUT_MS"

# Parse URL -> host + id (best-effort). Used for archive/workspace naming.
URL_NO_FRAG="${URL%%#*}"
URL_NO_QUERY="${URL_NO_FRAG%%\\?*}"
URL_CLEAN="${URL_NO_QUERY%/}"
URL_NO_PROTO="${URL_CLEAN#*://}"
URL_HOST="${URL_NO_PROTO%%/*}"
URL_ID="${URL_CLEAN##*/}"

SERVICE="llm"
case "$URL_HOST" in
  gemini.google.com) SERVICE="gemini" ;;
  chat.openai.com|chatgpt.com) SERVICE="chatgpt" ;;
  *) SERVICE="${URL_HOST%%.*}" ;;
esac

CAPTURE_ID="$(basename "$OUT_DIR")"

# Optional archive step: copy key artifacts to a stable temp directory.
if [[ "$DO_ARCHIVE" == "1" && -n "${ARCHIVE_ROOT:-}" ]]; then
  ARCHIVE_DIR="$ARCHIVE_ROOT/$CAPTURE_ID"
  if mkdir -p "$ARCHIVE_DIR"; then
    if [[ "$ARCHIVE_DIR" != "$OUT_DIR" ]]; then
      [[ -f "$OUT_DIR/body.txt" ]] && cp -f "$OUT_DIR/body.txt" "$ARCHIVE_DIR/body.txt"
      [[ -f "$OUT_DIR/title.txt" ]] && cp -f "$OUT_DIR/title.txt" "$ARCHIVE_DIR/title.txt"
      printf '%s\n' "$OUT_DIR" > "$ARCHIVE_DIR/original_capture_dir.txt"
      printf '%s\n' "$URL" > "$ARCHIVE_DIR/source_url.txt"
    fi
    echo "Archived to: $ARCHIVE_DIR" >&2
  else
    echo "Warning: failed to create archive dir: $ARCHIVE_DIR" >&2
  fi
fi

# Optional workspace copy step:
# Writes into: <workspace-dir>/{service}_{id}/...
# Defaults:
# - if --workspace-dir is not set and $LLM_SHARE_WORKSPACE_DIR is empty, uses
#   ./tmp/llm_share_chat under the caller's current workspace root
copy_dir() {
  # Copy directory contents from $1 into $2 (creates $2 if needed).
  #
  # Prefer rsync when available because it's consistent across platforms.
  # Fallback to cp -R -p for minimal environments.
  local src="$1"
  local dst="$2"

  mkdir -p "$dst"

  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "${src%/}/" "${dst%/}/"
  else
    # macOS cp doesn't support -a; use -R (recursive) + -p (preserve mode/times).
    # We copy "contents" (src/.) rather than the directory itself.
    rm -rf "$dst"
    mkdir -p "$dst"
    cp -R -p "$src/." "$dst/"
  fi
}

if [[ "$DO_WORKSPACE_COPY" == "1" ]]; then
  WORKSPACE_CHAT_ROOT="$WORKSPACE_DIR"
  if [[ -z "${WORKSPACE_CHAT_ROOT:-}" ]]; then
    WORKSPACE_CHAT_ROOT="$CALLER_PWD/tmp/llm_share_chat"
  fi

  WORKSPACE_DEST="$WORKSPACE_CHAT_ROOT/${SERVICE}-${URL_ID}"

  if mkdir -p "$WORKSPACE_DEST"; then
    # Copy the entire capture result directory into the workspace for future tracing.
    # This keeps screenshots/requests/meta alongside the extracted body/title.
    copy_dir "$OUT_DIR" "$WORKSPACE_DEST/capture"

    # Add small pointer files for convenience (these are not part of the capture output).
    printf '%s\n' "$URL" > "$WORKSPACE_DEST/source_url.txt"
    printf '%s\n' "$OUT_DIR" > "$WORKSPACE_DEST/original_capture_dir.txt"

    echo "Copied to workspace: $WORKSPACE_DEST" >&2
  else
    echo "Warning: failed to create workspace dir: $WORKSPACE_DEST" >&2
  fi
fi

# Print the output directory last as a simple one-liner for humans.
# You can:
#   ls "$OUT_DIR"
#   cat "$OUT_DIR/body.txt"
#   open "$OUT_DIR/page.png"
echo "$OUT_DIR"
