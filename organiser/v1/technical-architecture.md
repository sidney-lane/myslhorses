# Bundle Viewer/Vendor — Technical Architecture

## 1. Purpose
This document defines the technical architecture needed to implement the requirements in `organiser/v1/requirements-and-plan.md`. It lists the LSL functions required, identifies known constraints, and provides alternate architecture options to support a decision on the best path forward.

---

## 2. Runtime Context & Constraints
- **Runtime**: Second Life LSL scripts inside a container prim (box).
- **Inventory**: No-copy/no-mod objects placed inside the box.
- **Storage**: Linkset data is used for persistence across script resets.
- **UI**: Touch-based dialog menus.

Known constraints to design around:
- LSL scripts are memory-limited and have string size constraints.
- Linkset data has key/value size and total size limits that may require truncation or chunking of large stats payloads.
- Inventory scanning must be done via LSL inventory functions; object metadata visibility is limited to what LSL exposes.

---

## 3. Architecture Overview (Recommended Baseline)

### 3.1 Components
1. **Indexer Script**
   - Responsible for inventory scanning, filtering, and persistence into linkset data.
2. **Menu/UX Script**
   - Owner-only and general dialogs, user input handling, and menu state.
3. **Pricing Script** (optional for Stage 3)
   - Handles per-object pricing flows and validation.
4. **Vendor/Viewer Script** (stretch)
   - Handles scrollable UI, image/texture mapping, and vending behaviors.

### 3.2 Data Flow
1. **Inventory Change Event** triggers scan.
2. **Indexer** reads inventory list, filters valid objects, writes metadata to linkset data.
3. **Menu/UX** reads from linkset data to provide totals and user-facing actions.
4. **Pricing** updates per-object price fields.
5. **Vendor/Viewer** uses linkset data to render UI and process purchase flows.

---

## 4. Required LSL Functions & Availability Checks

The table below lists the functions required by the architecture and notes any known constraints. These functions are standard LSL APIs and are expected to be available in Second Life. Where limits are uncertain, they are flagged for validation in Stage 0.

### 4.1 Inventory & Object Metadata
- **`llGetInventoryNumber(INVENTORY_OBJECT)`**
  - Used to count objects in inventory.
  - Constraint: Must iterate through inventory indices; performance depends on size.
- **`llGetInventoryName(INVENTORY_OBJECT, index)`**
  - Used to get object names.
- **`llGetInventoryDesc(name)`**
  - Used to read object description strings.
- **`llGetOwner()` / `llGetOwnerKey()`**
  - Used to identify the box owner.

### 4.2 Linkset Data
- **`llLinksetDataWrite(key, value)`**
  - Used to persist metadata.
  - Constraint: Key/value size and total storage limits; exact limits must be confirmed in Stage 0.
- **`llLinksetDataRead(key)`**
  - Used to read stored metadata.
- **`llLinksetDataDelete(key)`**
  - Used for reset and data cleanup.

### 4.3 Events & Timing
- **`changed(CHANGED_INVENTORY)`**
  - Used to detect inventory changes.
- **`state_entry()` / `on_rez()`**
  - Used for initialization and initial scan.
- **`llSetTimerEvent()`** (optional)
  - Used for debounce or deferred scanning.

### 4.4 Dialogs & User Input
- **`llDialog()`**
  - Used to present menus to users.
- **`listen()`**
  - Used to receive menu responses.
- **`llListenRemove()`**
  - Used to clean up listeners.
- **`llTextBox()`**
  - Used to capture price/name input.

### 4.5 Notecard & Landmark Delivery
- **`llGiveInventory()`**
  - Used to provide help and stats notecards and landmarks.

### 4.6 Location/Slurl (Optional)
- **`llGetRegionName()`**
  - Used to build an slurl.
- **`llGetPos()`**
  - Used to get coordinates for slurl.

**Verification Notes**
- The APIs above are part of the standard LSL function set. Stage 0 should validate:
  - Maximum linkset data capacity and key/value size limits.
  - Maximum string length for stats storage.
  - Whether object owner information is directly readable from inventory items.

---

## 5. Data Model

The architecture uses a prefix-based schema in linkset data to store metadata in a predictable, queryable form:

- `meta.total` → integer
- `meta.owner.id` → UUID
- `meta.owner.name` → string
- `meta.slurl` → string

Per object (UUID):
- `obj.<uuid>.name`
- `obj.<uuid>.desc`
- `obj.<uuid>.owner`
- `obj.<uuid>.price`
- `obj.<uuid>.stats`
- `obj.<uuid>.weblisting`

---

## 6. Execution Flow (Baseline)

1. **Initialization**
   - On rez or state entry, set active flag and run inventory scan.
2. **Inventory Scan**
   - Iterate inventory objects, fetch name/description.
   - Filter by `SUCCESSFUL_BUNDLE` or `BOXED_BUNDLES`.
   - Write metadata to linkset data under `obj.<uuid>.*`.
   - Update `meta.total`.
3. **Menu Interaction**
   - Owner touches → owner menu actions.
   - Non-owner touches → general menu actions.
4. **Reset**
   - Delete linkset data and re-run scan.

---

## 7. Alternate Architecture Options

### Option A — Single Script (All-in-One)
**Description**: One script handles inventory scanning, linkset data, menu UI, and pricing.

**Pros**
- Fewer scripts to manage.
- Simpler deployment.

**Cons**
- Higher memory usage per script.
- Harder to extend or test in isolation.
- UI changes can risk data logic stability.

**Best for**: Very small inventories and minimal feature set.

---

### Option B — Split Indexer + UI (Recommended)
**Description**: Two scripts: Indexer for inventory/data, UI for menu input.

**Pros**
- Separates concerns cleanly.
- Easier to add vendor features later.
- Less risk of UI changes breaking data logic.

**Cons**
- Requires inter-script messaging or shared linkset data.

**Best for**: MVP with future expansion.

---

### Option C — Event-Driven Indexer + Deferred Processing
**Description**: Use `changed(CHANGED_INVENTORY)` to trigger scans, with a debounce timer to limit repeated scans.

**Pros**
- Efficient under heavy inventory churn.
- Avoids excessive scans.

**Cons**
- Complexity of managing timer state.

**Best for**: Large inventory boxes or busy environments.

---

### Option D — External Web Index (Future)
**Description**: Offload large stats and search indexing to a web service, store only UUID references in linkset data.

**Pros**
- Minimal in-world storage.
- Faster in-world scripts.

**Cons**
- Requires HTTP integration and web hosting.
- External dependency and latency.

**Best for**: Advanced search and analytics on large collections.

---

## 8. Recommended Path Forward

1. Implement **Option B** for v1 MVP (Indexer + UI).
2. Add debounce logic from **Option C** if inventory change frequency causes performance issues.
3. Re-evaluate **Option D** once stats size limits are confirmed.

---

## 9. Stage 0 Verification Checklist

- Confirm maximum size for a linkset data value.
- Confirm total linkset data capacity per object.
- Confirm any LSL limits on `llGetInventoryDesc` length.
- Confirm whether inventory item owner is accessible or if only object owner (box owner) is accessible.
- Test `changed(CHANGED_INVENTORY)` behavior for add/remove events.

---

## 10. Glossary
- **Indexer**: Script that scans inventory and writes linkset data.
- **Linkset Data**: Persistent storage attached to an object’s linkset.
- **Bundle**: Amaretto Breedable Bundle object.
This technical architecture document defines how to implement the requirements in `requirements-and-plan.md` using LSL, including the core runtime components, data flows, event handling, and the LSL functions required. It also provides alternative architecture options so we can choose the most appropriate path forward.

---

## 2. Architecture Goals
- **Correctness**: reliably detect valid bundle objects and persist metadata.
- **Scalability within SL limits**: minimize memory usage, avoid linkset data overflow, avoid excessive timers.
- **Extensibility**: allow future boxed bundle parsing, stats enrichment, and vendor features.
- **Resilience**: survive script resets and inventory changes.

---

## 3. Primary Architecture (Recommended)

### 3.1 Components
1. **Indexer Script**
   - Handles inventory scans and linkset data storage.
   - Runs on rez, reset, and inventory change events.
   - Enforces filtering rules (`SUCCESSFUL_BUNDLE` / `BOXED_BUNDLES`).

2. **Menu/UI Script**
   - Owner-only touch menu for Start/Stop/Reset/Name/Text/Logo.
   - General menu for Stats Notecard and Landmark.
   - Sends commands to Indexer script via `llMessageLinked`.

3. **Optional Future Scripts**
   - **Pricing/Commerce Script**: handles `Add Price` workflows and vending.
   - **Viewer/Display Script**: scrollable UI, texture mapping, trait imagery.

### 3.2 Data Flow
1. **Inventory Change** → Indexer scans inventory.
2. **Filter Match** → metadata persisted to linkset data.
3. **Counts Updated** → `meta.total` updated in linkset data.
4. **Menu Action** → Menu sends command to Indexer to refresh/reset.

### 3.3 Linkset Data Strategy
- **Global metadata** stored under `meta.*` keys.
- **Object metadata** stored under `obj.<uuid>.*` keys.
- Use consistent prefixes to avoid collisions across scripts.
- Purge keys on Reset before reindexing to keep store clean.

---

## 4. Verified LSL Function Availability & Constraints
The following functions are expected to be available in LSL and map directly to required behaviors. Where relevant, constraints or uncertainties are noted and should be confirmed in Stage 0.

### 4.1 Inventory Discovery & Filtering
- `llGetInventoryNumber(INVENTORY_OBJECT)`
  - **Use**: get count of objects inside the box.
  - **Constraint**: only inventory items of type object are returned.

- `llGetInventoryName(INVENTORY_OBJECT, index)`
  - **Use**: get inventory object name.

- `llGetInventoryDesc(name)`
  - **Use**: get inventory object description string.
  - **Constraint**: description length and availability depend on SL limits.

- `llGetInventoryKey(name)`
  - **Use**: get asset UUID for the inventory object.
  - **Constraint**: may return `NULL_KEY` for items with restricted permissions; confirm behavior in Stage 0.

- `llSubStringIndex(haystack, needle)`
  - **Use**: test for `SUCCESSFUL_BUNDLE` or `BOXED_BUNDLES` in description.

### 4.2 Owner & Location Metadata
- `llGetOwner()`
  - **Use**: retrieve owner UUID of the container.

- `llKey2Name(key)`
  - **Use**: resolve owner UUID to name.
  - **Constraint**: name lookup may be rate-limited or return empty in some cases; confirm in Stage 0.

- `llGetRegionName()` + `llGetPos()`
  - **Use**: construct slurl (e.g., `secondlife://Region/x/y/z`).

### 4.3 Linkset Data Storage
- `llLinksetDataWrite(key, value)`
- `llLinksetDataRead(key)`
- `llLinksetDataDelete(key)`
- `llLinksetDataListKeys(pattern)`
  - **Use**: store, read, and wipe metadata.
  - **Constraint**: linkset data capacity is limited; keep values short and chunk large strings.

### 4.4 Menu & Interaction
- `llDialog(user, message, buttons, channel)`
- `llListen(channel, name, id, message)`
- `llListenRemove(handle)`
- `llSetText(text, color, alpha)`
  - **Use**: owner/general touch menus and hover text.

### 4.5 Notifications & Delivery
- `llGiveInventory(user, item)`
  - **Use**: give help notecard or landmark.
  - **Constraint**: notecard/landmark must exist in inventory.

### 4.6 Script Control & Events
- `state_entry()`
- `on_rez(integer start_param)`
- `changed(integer change)` with `CHANGED_INVENTORY`
- `timer()`
- `llResetScript()`
- `llMessageLinked(link, num, msg, id)`
  - **Use**: initialization, reset, inventory monitoring, and inter-script commands.

---

## 5. Alternate Architecture Options

### Option A — Single-Script Monolith
**Description**: One script handles indexing, UI, and pricing.

**Pros**
- Simple deployment (one script).
- Minimal inter-script coordination.

**Cons**
- Higher memory usage in one script.
- Harder to extend for vendor and UI features.

**Fit**: Small inventories and minimal future feature growth.

---

### Option B — Modular Multi-Script (Recommended)
**Description**: Separate scripts for Indexer, Menu/UI, and Pricing/Vendor.

**Pros**
- Cleaner separation of concerns.
- Easier future extension.
- More resilient to script memory limits.

**Cons**
- Requires link messaging conventions.

**Fit**: Long-term maintainability and feature growth.

---

### Option C — Hybrid with External Service
**Description**: Indexer stores data locally, but pushes metadata to a web service (myslhorses.com) via HTTP for search/analytics.

**Pros**
- Scales beyond linkset data limits.
- Enables richer search and analytics.

**Cons**
- Requires `llHTTPRequest` usage and external hosting.
- Added latency and reliability dependencies.

**Fit**: Larger inventories and advanced search requirements.

---

## 6. Risk & Mitigation (Architecture-Specific)
- **Linkset Data Limit**
  - Mitigation: store minimal metadata; chunk stats; use external service in Option C.
- **Inventory UUID Access**
  - Mitigation: verify `llGetInventoryKey` behavior for no-copy/no-mod items in Stage 0.
- **Menu Complexity**
  - Mitigation: keep menu interactions separate in Menu/UI script to avoid blocking indexing logic.

---

## 7. Implementation Notes
- Keep indexing logic event-driven (`CHANGED_INVENTORY`) with manual refresh on demand.
- Store `meta.total` and per-object keys only for valid objects.
- Use a deterministic key naming convention to avoid collisions.
- Gate owner-only menu actions by verifying `llGetOwner()` matches the toucher.

---

## 8. Decision Checklist
Before committing to the implementation path, decide:
1. **Architecture**: Option A vs B vs C.
2. **Scale**: expected maximum number of bundles.
3. **External Integration**: whether to add HTTP calls now or later.
4. **Stats Strategy**: in-world storage vs offloaded to notecards/web.

---

## 9. Next Actions
- Confirm Stage 0 findings for inventory UUID access and linkset data capacity.
- Choose preferred architecture option.
- Draft detailed script interfaces (linked message contract and key naming spec).
