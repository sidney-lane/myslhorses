# API Stubs + Second Life Export/Import Approach

This document outlines **API endpoints (stubs)** and a practical approach for **exporting from** and **importing to** Second Life (LSL) using `llHTTPRequest`.

---

## 1. Data Flow Overview
1. **LSL → API (Export)**: Box sends bundle metadata on scan.
2. **API → Supabase**: Store/Upsert owner, container, bundle.
3. **Backend Enrichment**: Server fetches lineage data and creates stats.
4. **LSL ← API (Import)**: Box requests concise stats text when needed.

---

## 2. API Endpoints (Stubs)

### 2.1 POST `/api/ingest`
**Purpose**: Upsert owner, container, and bundle metadata.

**Request (JSON)**
```json
{
  "bundle_uuid": "0c9b8a1c-ad7b-c16a-0f51-41d809e5b6e5",
  "container": {
    "sl_object_id": "<box-uuid>",
    "name": "My Bundle Box",
    "slurl": "secondlife://Anarchy/143/164/4005"
  },
  "owner": {
    "sl_avatar_id": "<avatar-uuid>",
    "sl_avatar_name": "Owner Resident"
  },
  "bundle": {
    "name": "Amaretto Breedable Bundle",
    "description": "SUCCESSFUL_BUNDLE ...",
    "bundle_type": "bundle",
    "price_l$": 0
  }
}
```

**Response (JSON)**
```json
{
  "status": "ok",
  "bundle_uuid": "0c9b8a1c-ad7b-c16a-0f51-41d809e5b6e5",
  "bundle_id": "<internal-uuid>",
  "stats_ready": false
}
```

---

### 2.2 GET `/api/bundles/{bundle_uuid}/stats`
**Purpose**: Return concise stats text for LSL hover/menu display.

**Response (JSON)**
```json
{
  "bundle_uuid": "0c9b8a1c-ad7b-c16a-0f51-41d809e5b6e5",
  "stats_text": "Breed: Friesian | Coat: Ebony | Eyes: Gold | Gen: 5",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

---

### 2.3 POST `/api/bundles/{bundle_uuid}/price`
**Purpose**: Update bundle price from in-world pricing script.

**Request (JSON)**
```json
{
  "price_l$": 5000
}
```

**Response (JSON)**
```json
{
  "status": "ok",
  "bundle_uuid": "0c9b8a1c-ad7b-c16a-0f51-41d809e5b6e5",
  "price_l$": 5000
}
```

---

### 2.4 POST `/api/bundles/{bundle_uuid}/status`
**Purpose**: Mark bundle as sold or archived.

**Request (JSON)**
```json
{
  "status": "sold"
}
```

---

### 2.5 POST `/api/containers/{sl_object_id}/heartbeat`
**Purpose**: Keep container "last seen" updated.

**Request (JSON)**
```json
{
  "slurl": "secondlife://Anarchy/143/164/4005",
  "bundle_count": 12
}
```

---

## 3. LSL Export (Second Life → API)

### 3.1 LSL Request Stub
```lsl
string API_URL = "https://your-endpoint.example/api/ingest";

sendIngest(string bundleUuid, string name, string desc, string ownerName, string slurl) {
    string body = "{\"bundle_uuid\":\"" + bundleUuid + "\"," +
                  "\"container\":{\"sl_object_id\":\"" + (string)llGetKey() + "\",\"name\":\"" + llGetObjectName() + "\",\"slurl\":\"" + slurl + "\"}," +
                  "\"owner\":{\"sl_avatar_id\":\"" + (string)llGetOwner() + "\",\"sl_avatar_name\":\"" + ownerName + "\"}," +
                  "\"bundle\":{\"name\":\"" + name + "\",\"description\":\"" + desc + "\",\"bundle_type\":\"bundle\",\"price_l$\":0}}";

    llHTTPRequest(API_URL, [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/json"], body);
}
```

### 3.2 Export Timing
- After each inventory scan, export **each valid bundle** to `/api/ingest`.
- If rate-limited, queue requests and send 1 per second.

---

## 4. LSL Import (API → Second Life)

### 4.1 LSL Stats Fetch Stub
```lsl
string STATS_URL = "https://your-endpoint.example/api/bundles/";

requestStats(string bundleUuid) {
    llHTTPRequest(STATS_URL + bundleUuid + "/stats", [HTTP_METHOD, "GET"], "");
}
```

### 4.2 Handling Response
- Parse `stats_text` from the response.
- Store in `obj.<uuid>.stats` via `llLinksetDataWrite`.
- Display in hover text or menu response.

---

## 5. Retry & Failure Handling
- LSL should detect failures in `http_response` event and retry later.
- Use `sync_events` table in Supabase for logging failures.
- If HTTP fails, keep linkset data as source of truth.

---

## 6. Security & Limits
- Use an **API key** or signed token for write endpoints.
- Keep `stats_text` concise (≤ 1024 chars).
- Rate-limit LSL HTTP calls (LSL has per-script limits).

---

## 7. Minimal Implementation Checklist
1. Deploy `/api/ingest` endpoint (upsert bundles).
2. Add a simple enrichment job (manual or cron) to fill `bundle_stats`.
3. Implement `/api/bundles/{uuid}/stats` for LSL fetch.
4. Add retry logic in LSL for HTTP failures.
