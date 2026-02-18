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

It also copies the key artifacts into your repo workspace for longer-lived tracing:

- `./tmp/llm_share_chat/{service}_{id}/body.txt`
- `./tmp/llm_share_chat/{service}_{id}/title.txt` (if available)
- `./tmp/llm_share_chat/{service}_{id}/source_url.txt`
- `./tmp/llm_share_chat/{service}_{id}/original_capture_dir.txt`

## Notes / Failure Modes

- If the share is not truly public, `body.txt` typically contains “Sign in” or a minimal shell and not the chat content.
- Some sites do infinite network polling; this skill uses a fixed wait time (default `5000ms`) instead of `networkidle`.
- For very long chats, `body.txt` can be large; the script writes to disk, not stdout.

## Parameters

`capture.sh` supports:

- `--out <dir>`: write into a specific directory instead of creating `/tmp/llm_share_capture.*`
- `--wait-ms <ms>`: extra wait after initial load (default `5000`)
- `--timeout-ms <ms>`: navigation timeout (default `60000`)
