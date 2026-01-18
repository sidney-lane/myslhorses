# Technical Architecture Plan (v1)

## Goals
- Provide near‑real‑time horse status to a media‑on‑a‑prim (MOAP) display board.
- Minimize in‑world script load by offloading rendering to hosted HTML.
- Ensure resilience when MOAP stops, scripts reset, or data is temporarily unavailable.

## Module Boundaries

### 1) LSL Script(s) (in‑world)
**Responsibilities**
- Scan nearby horses within configured radius.
- Parse Horse API description payload.
- Normalize horse data and publish to backend.
- Configure and refresh MOAP media URLs on prim faces.
- Persist configuration (range, permissions, board/pod ID) across resets.

**Interfaces**
- Outbound HTTP (llHTTPRequest) to webhook/edge function.
- Media URL set on prim faces with llSetPrimMediaParams.
- Owner menu commands (start/stop/reset, range, permissions).

**State/Persistence**
- Use llSetObjectDesc or llSetLinkPrimitiveParamsFast to store JSON config (board ID, range, color, permissions, last media URL). Persist on every change and on region change.

### 2) Webhook / Edge Function (Supabase Edge Function)
**Responsibilities**
- Validate incoming LSL payload (keyed by board ID + secret).
- Transform raw Horse API fields into a canonical JSON schema.
- Upsert per‑board state and per‑horse records in Supabase.
- Compute derived fields (age buckets, pregnancy status, timers) for faster render.

**Interfaces**
- HTTP POST from LSL.
- Supabase Postgres (tables) + storage of last update timestamps.

### 3) Hosting (GitHub Pages / Cloudflare)
**Responsibilities**
- Serve static HTML/CSS/JS for MOAP display.
- Fetch board/horse status JSON from Supabase REST endpoint.
- Render status tiles on prim faces (one page per face or a single page with paging/rotation).

**Interfaces**
- Client‑side fetch to Supabase REST (read‑only anon key or signed URL).
- Optional Cloudflare caching layer or edge KV for faster response.

## Data Flow

```
[LSL Scan] -> [Parse Horse API] -> [HTTP POST to Edge] -> [Supabase Tables]
                                                               |
                                                               v
                                                     [Hosted HTML]
                                                               |
                                                               v
                                                       [MOAP Faces]
```

1. **LSL scan loop** finds horses within configured range.
2. **LSL parse** converts the description field payload into structured values.
3. **LSL POST** sends a board snapshot (list of horses + board metadata) to the edge function.
4. **Edge function** validates, normalizes, and upserts records.
5. **MOAP HTML** fetches board data from Supabase, renders face layout.
6. **MOAP refresh** re‑applies media URLs on a timer to mitigate viewer drop‑outs.

## Data Formats

### Raw Horse API (description field)
```
<UUID>:<settings>:<age>:<hunger>:<energy>:<fervor>:<happiness>:<gender>:<pairing>:<pregval>:<home>:<breed>:<version>
```

### LSL → Edge Function Payload (JSON)
```json
{
  "board_id": "pod-01",
  "owner_key": "00000000-0000-0000-0000-000000000000",
  "range_m": 10,
  "updated_at": "2024-06-01T12:34:56Z",
  "horses": [
    {
      "horse_key": "uuid",
      "name": "Mare A",
      "age_days": 12,
      "gender": "F",
      "fervor": 72,
      "pregval": 0,
      "home": "214.97.51",
      "breed": "0",
      "raw": "<full description field>"
    }
  ]
}
```

### Supabase Tables (conceptual)
- `boards`
  - `board_id` (PK)
  - `owner_key`
  - `range_m`
  - `last_seen_at`
  - `config_json`
- `horses`
  - `horse_key` (PK)
  - `board_id` (FK)
  - `name`
  - `gender`
  - `age_days`
  - `fervor`
  - `pregval`
  - `status_label`
  - `updated_at`

### Hosted MOAP JSON (client fetch)
```
GET /rest/v1/horses?board_id=eq.pod-01&select=*
```

## Update Cadence
- **LSL scan**: every 60s (configurable), throttled to avoid lag.
- **Edge function**: on every POST; in‑order updates by `updated_at` to avoid stale writes.
- **MOAP fetch**: every 30–60s in JS, with cache‑busting query parameter.
- **MOAP re‑apply URL**: every 60–120s via LSL timer to reduce “media off” events.

## Failure & Recovery Handling

### LSL Script Reset / Region Restart
- Persist board config in object description; rehydrate on `state_entry`.
- Re‑send a full snapshot after reset to repopulate Supabase.
- Re‑apply media URLs on start and on timer.

### HTTP Failures / Backend Downtime
- LSL backs off on HTTP failure (exponential up to 5 minutes).
- LSL queues last snapshot for retry.
- MOAP client displays “Last updated X min ago” banner using `last_seen_at`.

### MOAP Media Drop‑out
- LSL re‑applies prim media settings periodically (refresh timer).
- Hosted page includes `window.location.reload()` fallback every 5–10 minutes.
- Viewer hints: user can touch media to re‑activate if autoplay blocked.

### Supabase Row Contention / Stale Data
- Edge function rejects out‑of‑order timestamps.
- Board records include `last_seen_at` for stale detection.
- MOAP client hides horses older than a TTL (e.g., 5–10 minutes).

## Security / Access
- Use a per‑board shared secret (stored in LSL) for webhook authentication.
- Supabase read access uses anon key with RLS limited to `board_id`.
- Write access only via edge function; direct writes blocked by RLS.

## Implementation Notes / Next Steps
- Define canonical mapping for `pregval` to pregnancy/recovery status.
- Determine max horse count per board and pagination strategy.
- Decide single vs. per‑face URL approach for performance.
- Add metrics (success/failure counts) in edge function logs.
