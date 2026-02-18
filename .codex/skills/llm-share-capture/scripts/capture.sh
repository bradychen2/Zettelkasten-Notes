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

usage() {
  cat <<'EOF'
Usage:
  capture.sh <url> [--out <dir>] [--wait-ms <ms>] [--timeout-ms <ms>]

Examples:
  capture.sh 'https://gemini.google.com/share/dea848184b75'
  capture.sh 'https://chat.openai.com/share/...' --wait-ms 8000
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

# Parse optional flags.
# We accept:
#   --out <dir>        write artifacts into a specific directory
#   --wait-ms <ms>     additional wait time after initial load
#   --timeout-ms <ms>  navigation timeout
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

# Mandatory "archive" step for future source tracing:
# Copy key artifacts into a stable directory: /tmp/llm_share_chat/<capture-id>/
# We use the basename of OUT_DIR as the capture-id so you can trace it back easily.
#
# Example:
#   OUT_DIR=/tmp/llm_share_capture.A1b2C3
#   ARCHIVE_DIR=/tmp/llm_share_chat/llm_share_capture.A1b2C3
#
# If you passed --out, the basename of that directory is used.
ARCHIVE_ROOT="/tmp/llm_share_chat"
ARCHIVE_DIR="$ARCHIVE_ROOT/$(basename "$OUT_DIR")"

if ! mkdir -p "$ARCHIVE_DIR"; then
  echo "Warning: failed to create archive dir: $ARCHIVE_DIR" >&2
  # Don't fail the whole capture if archiving isn't possible.
  ARCHIVE_DIR=""
fi

# Avoid copying onto itself if the user picked --out inside ARCHIVE_ROOT.
if [[ -n "$ARCHIVE_DIR" && "$ARCHIVE_DIR" != "$OUT_DIR" ]]; then
  # Copy the minimum requested files.
  # - -f overwrites existing files if you re-run a capture with the same OUT_DIR name.
  # - We only copy files that exist to avoid failing the whole script on partial runs.
  [[ -f "$OUT_DIR/body.txt" ]] && cp -f "$OUT_DIR/body.txt" "$ARCHIVE_DIR/body.txt"
  [[ -f "$OUT_DIR/title.txt" ]] && cp -f "$OUT_DIR/title.txt" "$ARCHIVE_DIR/title.txt"

  # Small pointer file so you can find the original capture directory later.
  printf '%s\n' "$OUT_DIR" > "$ARCHIVE_DIR/original_capture_dir.txt"
fi

# Print where the archive lives (stderr so it doesn't break simple scripting
# that expects stdout to contain the capture output).
if [[ -n "$ARCHIVE_DIR" ]]; then
  echo "Archived to: $ARCHIVE_DIR" >&2
fi

# Workspace copy step (requested):
# Copy the extracted body into the current repo workspace so it can be kept/grepped
# without relying on /tmp lifetime.
#
# Destination pattern:
#   ./tmp/llm_share_chat/{llm-service}_{id}/body.txt
#
# - {llm-service} is inferred from the URL host (gemini/chatgpt/...)
# - {id} is inferred from the last path segment (e.g. /share/<id>)
WORKSPACE_ROOT="$(cd -- "$ROOT_DIR/../../.." && pwd)"
WORKSPACE_CHAT_ROOT="$WORKSPACE_ROOT/tmp/llm_share_chat"

# Parse URL -> host + id (best-effort).
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

WORKSPACE_DIR="$WORKSPACE_CHAT_ROOT/${SERVICE}_${URL_ID}"

if mkdir -p "$WORKSPACE_DIR"; then
  if [[ -f "$OUT_DIR/body.txt" ]]; then
    cp -f "$OUT_DIR/body.txt" "$WORKSPACE_DIR/body.txt"
    printf '%s\n' "$URL" > "$WORKSPACE_DIR/source_url.txt"
    printf '%s\n' "$OUT_DIR" > "$WORKSPACE_DIR/original_capture_dir.txt"
    [[ -f "$OUT_DIR/title.txt" ]] && cp -f "$OUT_DIR/title.txt" "$WORKSPACE_DIR/title.txt"
  fi
  echo "Copied to workspace: $WORKSPACE_DIR" >&2
else
  echo "Warning: failed to create workspace dir: $WORKSPACE_DIR" >&2
fi

# Print the output directory last as a simple one-liner for humans.
# You can:
#   ls "$OUT_DIR"
#   cat "$OUT_DIR/body.txt"
#   open "$OUT_DIR/page.png"
echo "$OUT_DIR"
