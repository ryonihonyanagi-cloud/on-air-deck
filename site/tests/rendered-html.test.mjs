import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import test from "node:test";

async function render() {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request("https://onairdeck.test/", { headers: { accept: "text/html" } }),
    { ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) } },
    { waitUntil() {}, passThroughOnException() {} },
  );
}

test("server-renders the complete ON AIR Deck landing page", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

  const html = await response.text();
  assert.match(html, /<html lang="ja">/);
  assert.match(html, /<title>ON AIR Deck — Turn your podcast into a real radio performance<\/title>/);
  assert.match(html, /ポッドキャストを、/);
  assert.match(html, /本物のラジオへ。/);
  assert.match(html, /公開30日で 500 STARS/);
  assert.match(html, /LIVE MODE/);
  assert.match(html, /REC MODE/);
  assert.match(html, /12 SAMPLE PADS/);
  assert.match(html, /https:\/\/github\.com\/ryonihonyanagi-cloud\/on-air-deck/);
  assert.match(html, /property="og:image" content="https:\/\/on-air-deck\.ryonihonyanagi\.chatgpt\.site\/og\.png"/);
  assert.doesNotMatch(html, /codex-preview|Your site is taking shape|Building your site/);
});

test("ships the production assets and four-language copy", async () => {
  const [page, layout, packageJson] = await Promise.all([
    readFile(new URL("../app/page.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/layout.tsx", import.meta.url), "utf8"),
    readFile(new URL("../package.json", import.meta.url), "utf8"),
    access(new URL("../public/on-air-deck-console.jpg", import.meta.url)),
    access(new URL("../public/og.png", import.meta.url)),
    access(new URL("../public/app-icon.png", import.meta.url)),
  ]);

  assert.match(page, /type Language = "ja" \| "en" \| "zh" \| "ko"/);
  assert.match(page, /Turn your podcast into/);
  assert.match(page, /让你的播客/);
  assert.match(page, /팟캐스트를/);
  assert.match(page, /GITHUB_URL = "https:\/\/github\.com\/ryonihonyanagi-cloud\/on-air-deck"/);
  assert.match(layout, /images: \[\{ url: "\/og\.png", width: 1200, height: 630/);
  assert.doesNotMatch(packageJson, /react-loading-skeleton/);
  await assert.rejects(access(new URL("../app/_sites-preview/", import.meta.url)));
});
