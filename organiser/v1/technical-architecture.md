# Bundle Viewer/Vendor — Technical Architecture

## 1. Purpose
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
