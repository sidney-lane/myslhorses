export interface Env {
  STATS_CACHE: KVNamespace;
}

const BUNDLE_URL = "https://amarettobreedables.com/bundleData.php?id=";

function extractStats(html: string): { statsText: string; traits: Record<string, string> } {
  const traits: Record<string, string> = {};

  const breedMatch = html.match(/Breed\s*:\s*<[^>]*>([^<]+)/i);
  const coatMatch = html.match(/Coat\s*:\s*<[^>]*>([^<]+)/i);
  const eyesMatch = html.match(/Eyes\s*:\s*<[^>]*>([^<]+)/i);
  const genMatch = html.match(/Gen(?:eration)?\s*:\s*<[^>]*>([^<]+)/i);

  if (breedMatch) traits.breed = breedMatch[1].trim();
  if (coatMatch) traits.coat = coatMatch[1].trim();
  if (eyesMatch) traits.eyes = eyesMatch[1].trim();
  if (genMatch) traits.generation = genMatch[1].trim();

  const statsText = [
    traits.breed ? `Breed: ${traits.breed}` : null,
    traits.coat ? `Coat: ${traits.coat}` : null,
    traits.eyes ? `Eyes: ${traits.eyes}` : null,
    traits.generation ? `Gen: ${traits.generation}` : null,
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
