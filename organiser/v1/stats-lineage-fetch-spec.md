# Stats & Lineage Fetch Specification (Bundles in Box)

## 1. Goal
Define **how stats and lineage are fetched** for bundles in the box, including data sources, flow, constraints, and validation steps that prove feasibility.

---

## 2. High-Level Approach
Because LSL cannot read hover text or local chat logs, **stats and lineage must be fetched externally** using the bundle UUID, then synced back to the box via HTTP.

**Two-step approach**:
1. **LSL exports bundle UUID + metadata** to the backend.
2. **Backend fetches lineage/stats** from web sources using UUID and stores a concise `stats_text` for LSL.

---

## 3. Data Sources (Verified via README Requirements)
From the project requirements, there are known public lineage pages that accept UUIDs:
- **Bundle lineage page** (example): `https://amarettobreedables.com/bundleData.php?id=<UUID>`
- **Horse lineage page** (example): `https://amarettobreedables.com/horseData.php?id=<UUID>`

These pages are referenced as part of the current project documentation and are the **primary target for automated parsing**. The UUID is already available via `llGetInventoryKey` in LSL during indexing.

---

## 4. Detailed Fetch Flow (Step-by-Step)

### Step 1 — LSL Export (Bundle Metadata)
- During inventory scan, LSL obtains `bundle_uuid` from `llGetInventoryKey(name)`.
- LSL sends JSON to `/api/ingest` (Supabase or Cloudflare stack).

**Payload (minimum):**
```json
{
  "bundle_uuid": "<uuid>",
  "bundle": {
    "name": "Amaretto Breedable Bundle",
    "description": "SUCCESSFUL_BUNDLE ..."
  }
}
```

### Step 2 — Backend Enrichment Job
- Backend uses the UUID to fetch:
  - `https://amarettobreedables.com/bundleData.php?id=<UUID>`
- Fetch is done via server-side HTTP (Worker/Edge Function/CRON).
- Store raw HTML/JSON into `bundle-raw` storage.

### Step 3 — Parse and Normalize
- Parse traits and lineage from the response into structured JSON:
  - `trait_json` (coat, eyes, breed, etc.)
  - `lineage_json` (sire/dam UUIDs if available)
- Generate `stats_text` for LSL (short summary string).

### Step 4 — LSL Import (Stats Sync)
- LSL calls `/api/bundles/{uuid}/stats`.
- API returns `stats_text` and optional JSON traits.
- LSL writes stats to `obj.<uuid>.stats`.

---

## 5. Feasibility Check (Is It Possible?)
### ✅ Possible Because:
- UUID is **available in LSL** using `llGetInventoryKey` for inventory objects (already used in requirements and scripts).
- The lineage URLs accept UUID parameters (examples already documented).
- LSL can send/receive HTTP via `llHTTPRequest`.
- Supabase/Cloudflare can fetch and parse external HTML/JSON.

### ⚠️ Must Validate (Stage 0 tests)
1. **UUID availability** for no-copy/no-mod bundles (ensure `llGetInventoryKey` does not return `NULL_KEY`).
2. **Lineage page access**: confirm the site does not require auth or block automated access.
3. **Rate limits**: check for request limits from lineage site.

---

## 6. Parsing Strategy
### If data is HTML
- Use server-side HTML parser to extract fields (coat, eyes, generation, parents).
- Example: CSS selectors or regex for known labels in the lineage page.

### If data is JSON (preferred)
- Extract structured fields directly.
- Store as JSON without transformation, then map to `trait_json`.

---

## 7. Data Returned to LSL
**Keep it short** due to LSL string limits.

Example `stats_text`:
```
Breed: Friesian | Coat: Ebony | Eyes: Gold | Gen: 5 | Sire: <name> | Dam: <name>
```

---

## 8. Risks & Constraints

### 8.1 Technical Constraints
- **LSL HTTP limits**: per-script throttling, limited requests per second.
- **LSL string limits**: keep `stats_text` compact (≤ 1024 chars).
- **Linkset data capacity**: avoid storing large raw stats in-world.

### 8.2 External Dependencies
- **Lineage site availability**: if site is down, stats fetch fails.
- **HTML changes**: if the site changes layout, parsing breaks.
- **Anti-bot protections**: might block repeated automated requests.

### 8.3 Data Quality
- Some bundles may have missing or inconsistent lineage data.
- If UUID is not recognized, no stats are returned.

---

## 9. Mitigations
- Cache results in Supabase so each UUID is fetched once.
- Use exponential backoff for failures and store error in `sync_events`.
- Provide manual override/admin dashboard for missing stats.
- If site blocks scraping, negotiate API access or use user-provided data export.

---

## 10. Verification Checklist
1. **LSL can read UUID** from at least 10 test bundles.
2. **Backend fetch** returns valid content for UUIDs.
3. **Parser extracts known traits** (breed, coat, eyes, generation).
4. **LSL receives stats_text** and stores it under `obj.<uuid>.stats`.
5. **Failure handling** logs in `sync_events`.

---

## 11. Summary
Fetching stats and lineage is feasible using **UUID-based web lookups** and **backend parsing**, with **LSL acting only as a thin client** to export UUIDs and import concise summaries. The primary risks are external site access and parsing stability, which can be mitigated via caching, retries, and manual overrides.
