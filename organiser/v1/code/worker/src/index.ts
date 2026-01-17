export interface Env {
  STATS_CACHE: KVNamespace;
}

const BUNDLE_URL = "https://amarettobreedables.com/bundleData.php?id=";

function extractSection(html: string, header: string): string {
  const headerIndex = html.indexOf(header);
  if (headerIndex === -1) return "";
  const slice = html.slice(headerIndex);
  const endIndex = slice.indexOf("</p>");
  if (endIndex === -1) return "";
  return slice.slice(0, endIndex);
}

function extractField(section: string, label: string): string | null {
  const regex = new RegExp(`${label}\\s*:\\s*([^<]+)<br`, "i");
  const match = section.match(regex);
  return match ? match[1].trim() : null;
}

function extractStats(html: string): { statsText: string; traits: Record<string, string> } {
  const traits: Record<string, string> = {};
  const bundleSection = extractSection(html, "The Bundle");
  if (!bundleSection) {
    return { statsText: "", traits };
  }

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

  const res = await fetch(BUNDLE_URL + bundleUuid);
  const html = await res.text();
  const parsed = extractStats(html);

  await env.STATS_CACHE.put(
    bundleUuid,
    JSON.stringify({
      bundle_uuid: bundleUuid,
      stats_text: parsed.statsText,
      traits: parsed.traits,
      updated_at: new Date().toISOString(),
    })
  );

  return new Response(
    JSON.stringify({
      status: "ok",
      bundle_uuid: bundleUuid,
      stats_ready: true,
    }),
    {
      headers: { "Content-Type": "application/json" },
    }
  );
}

async function handleStats(env: Env, bundleUuid: string): Promise<Response> {
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
      return handleStats(env, statsMatch[1]);
    }

    return new Response("Not Found", { status: 404 });
  },
};
