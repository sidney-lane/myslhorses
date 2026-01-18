# MSL Horses Status Board v1 Build Steps

These steps are structured to validate logic early (hover text first) and only move to MOAP once parsing and status derivation are correct.

## Step 1: Create the Master Board Script Skeleton
**Goal:** Timer-driven scan with placeholder hover text.
- Add `llSetTimerEvent(60.0)` on `state_entry`.
- On `timer`, call `llSensor` for horse objects (range configurable; start with 10m).
- In `sensor`, set hover text to a simple count: `"Horses found: X"`.

**Verification**
- Rez the board in-world.
- Confirm hover text updates every minute.
- If `sensor` returns 0, ensure hover text changes to `"No horses in range"`.

## Step 2: Parse the Description API
**Goal:** Extract fields from the horse API string.
- In `sensor`, call `llGetObjectDetails` for each detected object.
- Use `llParseString2List` on `description` using `":"` as delimiter.
- Map indices to fields and log with `llOwnerSay` in debug mode.

**Verification**
- Compare logged output against known horse description values.
- Ensure missing or malformed entries are skipped without crashing.

## Step 3: Compute Derived Status
**Goal:** Show the correct status string for each horse.
- Implement logic:
  - If age < 7 days: show time to 7 days.
  - Else if preg value > 0: show pregnancy time remaining.
  - Else if fervor < 100: show time to 100%.
  - Else if recovery > 0: show recovery time remaining.
- Render each horse as `Name (Gender, Age): Status`.

**Verification**
- Hover text lists each horse with a derived status.
- Compare to known horse states in-world.

## Step 4: Add Configuration Menu
**Goal:** Owner/group/all permissions and range settings.
- Implement dialog-based menu.
- Store settings in object description or script memory.
- Enforce access via `llSameGroup` or owner key.

**Verification**
- As non-owner, confirm access matches permission setting.
- Range change updates sensor distance.

## Step 5: Master/Pod Linking
**Goal:** Provide data to pod boards.
- Option A: use `llMessageLinked` to broadcast the payload from master to pods.
- Option B: pods poll the backend endpoint every 60–120s.

**Verification**
- Pod boards display the same horse list as master.

## Step 6: Backend Endpoint
**Goal:** Store and serve a compact snapshot.
- Build a POST endpoint accepting board payloads.
- Store the latest payload keyed by board ID.
- Add a GET endpoint returning JSON for the status page.

**Verification**
- From LSL, POST a test payload and confirm successful HTTP response.
- From a browser, load the GET endpoint and see the JSON.

## Step 7: MOAP Status Page
**Goal:** Render the payload on a media face.
- Create a static HTML page that fetches JSON and displays a compact grid.
- Add auto-refresh (60s) to re-render.
- Use `llSetPrimMediaParams` in LSL to set the URL for the media face.

**Verification**
- In-world, the media face shows the status board.
- When the backend payload changes, the board updates within 60s.

## Step 8: MOAP Reliability Refresh
**Goal:** Ensure MOAP stays active.
- Re-apply `llSetPrimMediaParams` every 60–120s.
- Provide a manual "refresh" action in the menu.

**Verification**
- Leave the board running for 10+ minutes and confirm it keeps updating.

## Step 9: Final Checklist
- Hover text matches known horse states.
- MOAP view renders correctly and refreshes.
- Permissions enforced.
- No excessive script time or HTTP errors.
