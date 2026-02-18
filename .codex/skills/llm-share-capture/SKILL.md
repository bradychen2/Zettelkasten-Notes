---
name: llm-share-capture
description: Fetch public shared chat URLs (Gemini/ChatGPT/other LLM share pages) via headless Chromium and save the rendered body text + screenshot + request log into a /tmp capture folder.
---

# LLM Share Capture

Use this skill when the user pastes a **public** share URL (Gemini / ChatGPT / other LLM chat share pages) and wants the **actual rendered chat body** saved to temporary files.

This skill uses a consistent method:

1. Open the share URL in **headless Chromium** (Playwright)
2. Wait briefly for client-side rendering
3. Extract `document.body.innerText`
4. Save artifacts to a new temp directory

## Quick Start (Repeatable Procedure)

1. Bootstrap Playwright once (installs Node deps + Chromium):

```bash
bash .codex/skills/llm-share-capture/scripts/bootstrap.sh
```

2. Capture a share URL:

```bash
bash .codex/skills/llm-share-capture/scripts/capture.sh 'https://gemini.google.com/share/dea848184b75'
```

The command prints an output directory like `/tmp/llm_share_capture.XXXXXX` containing:

- `body.txt` rendered page text (chat body is inside here when public)
- `page.png` full-page screenshot
- `requests.txt` list of XHR/fetch requests observed
- `title.txt` page title + final URL
- `meta.json` capture metadata (timestamp, url)

Optional outputs:

- Archive (enabled by default): `/tmp/llm_share_chat/<capture-id>/...` (override with `--archive-root` or `LLM_SHARE_ARCHIVE_ROOT`, disable with `--no-archive`)
- Workspace copy (enabled by default): `./tmp/llm_share_chat/{service}-{id}/capture/...` under the current workspace root (disable with `--no-workspace-copy`, optional `--workspace-dir <dir>`)

## Notes / Failure Modes

- If the share is not truly public, `body.txt` typically contains “Sign in” or a minimal shell and not the chat content.
- Some sites do infinite network polling; this skill uses a fixed wait time (default `5000ms`) instead of `networkidle`.
- For very long chats, `body.txt` can be large; the script writes to disk, not stdout.

## Parameters

`capture.sh` supports:

- `--out <dir>`: write into a specific directory instead of creating `/tmp/llm_share_capture.*`
- `--wait-ms <ms>`: extra wait after initial load (default `5000`)
- `--timeout-ms <ms>`: navigation timeout (default `60000`)
- `--archive-root <dir>` / `--no-archive`
- `--workspace-copy` / `--workspace-dir <dir>`

`bootstrap.sh` supports (via env vars):

- `LLM_SHARE_NPM_CACHE_DIR`: where npm writes its cache (default: a fresh `/tmp/llm_share_capture_npm_cache.*`)
- `LLM_SHARE_PLAYWRIGHT_DOWNLOAD_HOSTS`: comma-separated Playwright download hosts to try (default: `,https://playwright-akamai.azureedge.net,https://playwright-verizon.azureedge.net`)
