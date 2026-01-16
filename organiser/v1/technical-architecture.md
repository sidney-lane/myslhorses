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
