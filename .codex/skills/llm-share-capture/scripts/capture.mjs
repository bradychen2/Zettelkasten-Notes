import fs from "fs";
import path from "path";
import { chromium } from "playwright";

// This is the core capture script.
//
// It launches a headless Chromium browser (via Playwright), navigates to a share URL,
// waits a bit for client-side rendering, then writes the rendered page text to disk.
//
// Why a browser is needed:
// Many "public share" pages are JavaScript apps. If you fetch them with curl/requests,
// you often only get the HTML shell and none of the chat content. A browser executes
// the JS and renders the actual content.
//
// Output files (written into --out directory):
// - body.txt:    document.body.innerText (the rendered text on the page)
// - page.png:    full-page screenshot (useful for debugging when body is empty)
// - requests.txt:list of XHR/fetch URLs observed (helps confirm where data loads from)
// - title.txt:   page title + final URL after redirects
// - meta.json:   metadata about this capture run

function parseArgs(argv) {
  // Minimal argument parser.
  // Expected arguments (key/value pairs):
  //   --url <share-url>
  //   --out <output-directory>
  //   --wait-ms <milliseconds>
  //   --timeout-ms <milliseconds>
  //
  // Example:
  //   node capture.mjs --url 'https://...' --out '/tmp/x' --wait-ms 5000 --timeout-ms 60000
  const args = { url: null, out: null, waitMs: 5000, timeoutMs: 60000 };
  for (let i = 0; i < argv.length; i++) {
    const token = argv[i];
    if (token === "--url") args.url = argv[++i];
    else if (token === "--out") args.out = argv[++i];
    else if (token === "--wait-ms") args.waitMs = Number(argv[++i]);
    else if (token === "--timeout-ms") args.timeoutMs = Number(argv[++i]);
    else throw new Error(`Unknown arg: ${token}`);
  }

  // Basic validation so failures are obvious and early.
  if (!args.url) throw new Error("--url is required");
  if (!args.out) throw new Error("--out is required");
  if (!Number.isFinite(args.waitMs) || args.waitMs < 0)
    throw new Error("--wait-ms must be >= 0");
  if (!Number.isFinite(args.timeoutMs) || args.timeoutMs < 1)
    throw new Error("--timeout-ms must be >= 1");
  return args;
}

const { url, out, waitMs, timeoutMs } = parseArgs(process.argv.slice(2));

// Ensure output directory exists.
fs.mkdirSync(out, { recursive: true });

// Helper to build output paths.
const outFile = (name) => path.join(out, name);

// Start the headless browser.
// headless: true means "no visible window".
const browser = await chromium.launch({ headless: true });

// A browser context is like an "incognito profile" (separate cookies/storage).
// We also set a normal-looking user agent and viewport to reduce the chance of
// sites treating us differently.
const context = await browser.newContext({
  viewport: { width: 1280, height: 720 },
});

// A page is a tab.
const page = await context.newPage();

// We'll log XHR/fetch URLs because most apps load chat data via API calls.
const xhrFetchUrls = new Set();
page.on("request", (req) => {
  const rt = req.resourceType();
  if (rt === "xhr" || rt === "fetch") xhrFetchUrls.add(req.url());
});

// Variables to fill after navigation.
let title = "";
let finalUrl = url;
let bodyText = "";

try {
  // Load the page. We wait for "domcontentloaded" so the HTML is parsed.
  // We do NOT wait for "networkidle" because many apps keep long-polling open.
  await page.goto(url, { waitUntil: "domcontentloaded", timeout: timeoutMs });

  // Extra wait for JS-rendered content (React/Angular/etc.) to appear.
  await page.waitForTimeout(waitMs);

  // Collect information from the rendered page.
  title = await page.title();
  finalUrl = page.url();

  // The simplest and most general extraction:
  // get all visible text on the page.
  // Note: This can include headers/menus/buttons in addition to chat content.
  bodyText = await page.evaluate(() => document.body?.innerText ?? "");

  // Save a screenshot to help diagnose cases where bodyText is empty
  // (e.g., sign-in walls, bot detection, or slow rendering).
  await page.screenshot({ path: outFile("page.png"), fullPage: true });
} finally {
  // Always close the browser to avoid orphaned processes.
  await browser.close();
}

// Write artifacts to disk.
fs.writeFileSync(outFile("title.txt"), `${title}\n${finalUrl}\n`, "utf8");
fs.writeFileSync(outFile("body.txt"), bodyText, "utf8");
fs.writeFileSync(
  outFile("requests.txt"),
  Array.from(xhrFetchUrls).sort().join("\n") + "\n",
  "utf8",
);
fs.writeFileSync(
  outFile("meta.json"),
  JSON.stringify(
    {
      captured_at: new Date().toISOString(),
      url,
      final_url: finalUrl,
      title,
      body_chars: bodyText.length,
      wait_ms: waitMs,
      timeout_ms: timeoutMs,
    },
    null,
    2,
  ) + "\n",
  "utf8",
);

// Print a machine-readable summary (paths) for follow-up automation.
// capture.sh currently prints this JSON AND then prints the out dir as a one-liner.
console.log(
  JSON.stringify({
    out_dir: out,
    body_txt: outFile("body.txt"),
    page_png: outFile("page.png"),
    requests_txt: outFile("requests.txt"),
    title_txt: outFile("title.txt"),
    meta_json: outFile("meta.json"),
  }),
);
