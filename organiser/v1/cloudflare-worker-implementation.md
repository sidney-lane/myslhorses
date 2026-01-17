# Cloudflare Worker Implementation (Bundle Stats Fetch)

This document provides a **Cloudflare Worker** implementation that:
1. Accepts bundle UUIDs from Second Life (`POST /api/ingest`).
2. Fetches bundle stats from `bundleData.php?id=<UUID>`.
3. Parses bundle stats from the HTML response by locating the **The Bundle** header and reading the next `<p class="dataOutput">` block (fields like `Name`, `Breed`, `Eye`, `Mane`, `Tail`, `UUID`, `Version`).
4. Returns a concise `stats_text` to LSL (`GET /api/bundles/:uuid/stats`).

> Note: Parsing depends on the current HTML structure of the Amaretto site. If HTML changes, update the regex/selectors.

---

## 1. Worker Code (TypeScript)
Create a Worker project with Wrangler and use the following `src/index.ts`:

```ts
export interface Env {
  STATS_CACHE: KVNamespace;
}

const BUNDLE_URL = "https://amarettobreedables.com/bundleData.php?id=";

function extractStats(html: string): { statsText: string; traits: Record<string, string> } {
  const traits: Record<string, string> = {};

  const bundleSection = extractSection(html, "The Bundle");
  if (!bundleSection) return { statsText: "", traits };

  const name = extractField(bundleSection, "Name");
  const gender = extractField(bundleSection, "Gender");
  const age = extractField(bundleSection, "Age");
  const owner = extractField(bundleSection, "Current Owner");
  const breed = extractField(bundleSection, "Breed");
  const eye = extractField(bundleSection, "Eye");
  const mane = extractField(bundleSection, "Mane");
  const tail = extractField(bundleSection, "Tail");
  const uuid = extractField(bundleSection, "UUID");
  const version = extractField(bundleSection, "Version");

  if (name) traits.name = name;
  if (gender) traits.gender = gender;
  if (age) traits.age = age;
  if (owner) traits.owner = owner;
  if (breed) traits.breed = breed;
  if (eye) traits.eye = eye;
  if (mane) traits.mane = mane;
  if (tail) traits.tail = tail;
  if (uuid) traits.uuid = uuid;
  if (version) traits.version = version;

  const statsText = [
    breed ? `Breed: ${breed}` : null,
    eye ? `Eye: ${eye}` : null,
    mane ? `Mane: ${mane}` : null,
    tail ? `Tail: ${tail}` : null,
    gender ? `Gender: ${gender}` : null,
    version ? `Version: ${version}` : null,
  ]
    .filter(Boolean)
    .join(" | ");

  return { statsText, traits };
}

async function handleIngest(request: Request, env: Env): Promise<Response> {
  const body = await request.json();
  const bundleUuid = body.bundle_uuid as string | undefined;

  if (!bundleUuid) {
    return new Response(JSON.stringify({ status: "error", message: "bundle_uuid required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Fetch and parse immediately (you can also enqueue for async processing)
  const res = await fetch(BUNDLE_URL + bundleUuid);
  const html = await res.text();
  const parsed = extractStats(html);

  await env.STATS_CACHE.put(bundleUuid, JSON.stringify({
    bundle_uuid: bundleUuid,
    stats_text: parsed.statsText,
    traits: parsed.traits,
    updated_at: new Date().toISOString(),
  }));

  return new Response(JSON.stringify({
    status: "ok",
    bundle_uuid: bundleUuid,
    stats_ready: true,
  }), {
    headers: { "Content-Type": "application/json" },
  });
}

async function handleStats(request: Request, env: Env, bundleUuid: string): Promise<Response> {
  const cached = await env.STATS_CACHE.get(bundleUuid, "text");
  if (!cached) {
    return new Response(JSON.stringify({ status: "missing", bundle_uuid: bundleUuid }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(cached, {
    headers: { "Content-Type": "application/json" },
  });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === "POST" && url.pathname === "/api/ingest") {
      return handleIngest(request, env);
    }

    const statsMatch = url.pathname.match(/^\/api\/bundles\/([^/]+)\/stats$/);
    if (request.method === "GET" && statsMatch) {
      return handleStats(request, env, statsMatch[1]);
    }

    return new Response("Not Found", { status: 404 });
  },
};
```

---

## 2. Wrangler Setup
```bash
npm create cloudflare@latest bundle-stats-worker
cd bundle-stats-worker
npm install
```

### `wrangler.toml`
```toml
name = "bundle-stats-worker"
main = "src/index.ts"
compatibility_date = "2024-01-01"

kv_namespaces = [
  { binding = "STATS_CACHE", id = "<YOUR_KV_NAMESPACE_ID>" }
]
```

Create KV:
```bash
wrangler kv:namespace create "STATS_CACHE"
```

---

## 3. Deployment
```bash
wrangler deploy
```

---

## 4. LSL Integration
Use the existing LSL export/import stubs from `api-stubs-sl-export.md`:
- `POST /api/ingest`
- `GET /api/bundles/<uuid>/stats`

---

## 5. Notes & Constraints
- HTML parsing is fragile; update regex once you inspect actual markup.
- Consider adding Cloudflare Queue + Cron to avoid rate limits.
- Cache results in KV to reduce repeated fetches.
