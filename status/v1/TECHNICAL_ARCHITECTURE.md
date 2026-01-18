# MSL Horses Status Board v1 Technical Architecture

## Overview
The solution has three layers:
1. **In-world LSL scripts**: scan nearby horses, decode their description API string, and emit a compact status payload.
2. **Backend service** (Supabase or similar): receive status updates, persist a short-lived snapshot, and expose a public JSON endpoint.
3. **Status page** (GitHub Pages/Cloudflare Pages): render the snapshot for MOAP display.

This design minimizes in-world script load and uses MOAP for richer layout while providing a hover-text-only validation path.

## Component Design

### 1) LSL Scanner Script (Master Board)
**Responsibilities**
- Run a periodic scan within a configured range.
- For each detected horse, read the object description and parse the API string:
  `UUID:Settings:Age:Hunger:Energy:Fervor:Happiness:Gender:Pairing:PregVal:Home:Breed:Version`
- Compute derived status fields (pregnancy, fervor, recovery, or birth-to-7-days window).
- Aggregate up to a capped number of horses per scan.
- Post the compact payload to the backend endpoint.
- Push a summary to hover text for phase-1 validation.

**Key LSL Functions (per LSL Portal)**
- `llSensor` / `llSensorRepeat` to detect objects in range.
- `llDetectedName`, `llDetectedKey`, `llGetObjectDetails` to access descriptions.
- `llParseString2List` and `llList2String` to decode the API string.
- `llHTTPRequest` to POST data to the backend.
- `llSetText` for hover text output.
- `llSetTimerEvent` to manage refresh cadence.

**Data Flow**
1. Timer fires every 60s.
2. Sensor scan within `range` (<= 15m) for horse objects.
3. Parse description API for each detection.
4. Build a compact JSON-like string (or CSV) payload.
5. POST payload to backend.
6. Update hover text.

### 2) LSL Pod Script (Slave Board)
**Responsibilities**
- Receive updates from master (link message or backend poll).
- Render hover text or set MOAP URL.

**Options**
- **Link messaging**: master and pods are linked; master sends payload using `llMessageLinked`.
- **Backend polling**: pod boards poll the backend URL every 60–120s and update their MOAP face.

### 3) Backend Service
**Responsibilities**
- Accept POSTs from LSL (master board).
- Store most recent snapshot by board ID.
- Expose a JSON endpoint per board ID.

**Implementation Notes**
- Minimal schema: `board_id`, `updated_at`, `payload`.
- Use a very small response body to respect LSL HTTP limits.
- Provide a CORS-friendly endpoint for the status page.

### 4) Status Page (MOAP)
**Responsibilities**
- Fetch the latest JSON payload.
- Render a compact status board UI (HTML/CSS).
- Auto-refresh on a timer (e.g., 60s).

## Payload Design (Example)
```json
{
  "board_id": "main-pod-01",
  "updated_at": 1710000000,
  "horses": [
    {"name":"Ginger","gender":"F","age_days":12,"status":"Pregnant: 3d 2h"},
    {"name":"Ash","gender":"M","age_days":2,"status":"Foal: 5d 4h to 7d"}
  ]
}
```

## LSL Portal Constraints & Adjustments
The implementation must conform to LSL Portal rules:
- **Sensor limits**: `llSensor` returns up to 16 results per call and has a max range of 96m. Use a 15m range and be prepared to handle partial lists by prioritizing nearest horses.
- **HTTP throttles**: `llHTTPRequest` is throttled per script. Keep POST frequency <= 1/minute and payloads small.
- **Memory**: Mono scripts have limited memory; avoid large strings and store only essential fields.
- **Timers**: avoid rapid timers; use 60s intervals to reduce lag.
- **MOAP**: `llSetPrimMediaParams` should be re-applied periodically to mitigate viewer media stalls.
- **Permissions**: use `llSameGroup` or owner key comparisons to enforce menu permissions.

## Error Handling & Resilience
- If no horses are found, report "No horses in range" and post an empty list.
- If an API string is malformed, skip the entry and log via `llOwnerSay` in debug mode.
- On rez or reset, load settings from `llGetObjectDesc` or `llGetObjectName` tag storage and start the timer.

## Implementation Notes
- **Phase 1 validation**: hover text only (max 15 horses) to verify parsing logic.
- **Phase 2 MOAP**: deploy status page and switch to media display once the hover text output matches expected values.
- **Debug toggles**: include a menu option to enable verbose logging for development.
