# Full Project Implementation (Code + Instructions)

This guide provides **complete code** (LSL + Cloudflare Worker) and **step-by-step setup instructions**.

---

## 1. LSL Scripts (Drop Into Box)
Location: `organiser/v1/code/lsl/`

### 1.1 `bundle_indexer.lsl`
- Scans box inventory and stores metadata in linkset data.

### 1.2 `bundle_menu.lsl`
- Provides owner/general menu and triggers indexer actions.

### 1.3 `bundle_pricing.lsl`
- Price One / Price All workflows.

### 1.4 `minimal_stats_fetch.lsl`
- Feasibility script: prints name, UUID, and lineage URL.

---

## 2. Cloudflare Worker (Backend Fetch + Cache)
Location: `organiser/v1/code/worker/`

### 2.1 Worker Code
- `src/index.ts` implements:
  - `POST /api/ingest`
  - `GET /api/bundles/:uuid/stats`

### 2.2 Wrangler Config
- `wrangler.toml` includes KV binding.

---

## 3. Setup Instructions

### Step A — LSL In-World Setup
1. Rez a box in Second Life.
2. Open **Contents** and drop in these scripts:
   - `bundle_indexer.lsl`
   - `bundle_menu.lsl`
   - `bundle_pricing.lsl`
3. Add notecards/landmark:
   - `Help Notecard`
   - `Stats Notecard`
   - `Landmark`
4. Add bundles to the box contents.
5. Touch the box → **Start**.

### Step B — Minimal Feasibility Check
1. Drop `minimal_stats_fetch.lsl` into the box.
2. Reset the script.
3. Confirm output:
   - UUID parsed from description.
   - Bundle URL printed.

### Step C — Cloudflare Worker Setup
1. Create Worker project:
   ```bash
   npm create cloudflare@latest bundle-stats-worker
   cd bundle-stats-worker
   npm install
   ```
2. Replace `src/index.ts` with `organiser/v1/code/worker/src/index.ts`.
3. Update `wrangler.toml` with your KV ID:
   ```bash
   wrangler kv:namespace create "STATS_CACHE"
   ```
4. Deploy:
   ```bash
   wrangler deploy
   ```

### Step D — LSL HTTP Integration
Use the stubs in `organiser/v1/api-stubs-sl-export.md`:
- `POST /api/ingest`
- `GET /api/bundles/:uuid/stats`

---

## 4. Notes
- `llGetInventoryKey` may be `NULL_KEY`; the description parser is the fallback.
- HTML parsing in the Worker must be tuned to the actual bundle page markup.
- For production, add retries and rate limiting.
