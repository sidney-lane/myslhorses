# Bundle Viewer/Vendor — Requirements & Delivery Plan

## 1. Purpose & Goals
Create a Second Life "Bundle Viewer/Vendor" object that can ingest Amaretto bundles (and later horses), extract their traits/metadata, store them in linkset data, and expose them via an in-world UI for searching, browsing, and vending. Primary goals are to reduce prim usage on land, make trait-based search easy, and provide a scrollable viewer UI. Stretch goals include trait/coat imagery and a vendor for horses. This document expands the v1 README requirements into a comprehensive, implementable specification and a staged delivery plan. The stages allow incremental delivery while preserving backward compatibility as features grow.

---

## 2. Scope
### In Scope (v1 MVP)
- Script(s) inside a container prim (box) that accepts no-copy/no-mod bundles (objects) as contents.
- Discovery/filtering of valid bundle objects.
- Metadata extraction (name, description, owner) and persistent storage in linkset data.
- Dynamic count of valid objects in the box.
- Owner-only touch menu to control start/stop/reset and basic settings.
- General menu items to provide stats notecard and landmark.

### Future Scope (v1+ / Stretch)
- Support boxed bundles via alternate parsing rules.
- Trait/coat image integration (texture fetch or local mapping).
- Vendor capabilities (for bundles and horses).
- External web integration (myslhorses.com search/indexing).

---

## 3. Definitions & Assumptions
- **Bundle**: Amaretto Breedable Bundle object with description containing `SUCCESSFUL_BUNDLE`.
- **Boxed Bundle**: Bundle object with description containing `BOXED_BUNDLES` (handled in later scripts).
- **Linkset Data**: Persistent key/value storage for an object’s linkset.
- **Valid Object**: Any object in the box that matches the filtering rules.
- **Owner**: The avatar who owns the container box.

Assumptions:
- The container prim is owned by a single avatar and maintains permissions consistent with standard SL scripting behavior.
- LSL limits for string size, memory, and linkset data keys/values apply and must be respected.
- Hover text and in-world menu-based stat output are not readable by LSL; parsing relies on name/description fields and any available APIs.

---

## 4. Requirements

### 4.1 Functional Requirements

#### A. Object Discovery & Filtering
1. On initialization or when contents change, scan the box’s inventory for objects.
2. For each object, fetch:
   - Name
   - Description
   - Owner
3. Filter objects that:
   - Contain `SUCCESSFUL_BUNDLE` in description **OR**
   - Contain `BOXED_BUNDLES` in description
4. Use the object UUID as the primary identifier.
5. Store each valid object’s metadata in linkset data.

#### B. Object Counting
6. Maintain a `Total` count of valid objects.
7. Update `Total` dynamically when objects are added/removed.
8. Persist `Total` in linkset data.

#### C. Linkset Data Shape
9. Store metadata at a predictable schema (see Section 4.3).
10. Store container owner information.
11. Store the container’s slurl/location if available.
12. Store each object’s stats payload (if later enriched).

#### D. Touch Menu (Owner-only)
13. Menu options:
   - Start (begin scanning and data population)
   - Stop (disable scanning, stop timers/listeners)
   - Reset (wipe linkset data and reset state)
   - Name (set box name)
   - Text On / Text Off (toggle floating text)
   - Set Logo (set logo texture or image ID)
   - Give Help Notecard
   - Add Price
     - Price One (set price for a selected object)
     - Price All (iterate all objects and set price per object)

#### E. Touch Menu (General)
14. General options:
   - Give Stats Notecard
   - Give Landmark

#### F. Error Handling & Validation
15. Gracefully handle objects missing required description strings.
16. Avoid exceeding linkset data limits; if data is too large, store references or truncated data.
17. Ensure menu interaction is restricted to owner-only options and general options for others.

---

### 4.2 Non-Functional Requirements

- **Performance**: Inventory scanning should be efficient and avoid excessive timers.
- **Reliability**: Linkset data must remain consistent after resets, object removals, and script restarts.
- **Maintainability**: Script(s) structured for future extension (boxed bundles, vendor logic, web hooks).
- **Security/Permissions**: Owner-only controls enforced for configuration and destructive actions.
- **UX**: Menu structure should be predictable and responsive, with clear prompts for user input.

---

### 4.3 Linkset Data Schema (Proposed)

**Global Metadata Keys**
- `meta.total` → integer
- `meta.owner.id` → UUID
- `meta.owner.name` → string
- `meta.slurl` → string

**Per-Object Keys (per UUID)**
- `obj.<uuid>.name` → string
- `obj.<uuid>.desc` → string
- `obj.<uuid>.owner` → string
- `obj.<uuid>.price` → integer
- `obj.<uuid>.stats` → string (optional)
- `obj.<uuid>.weblisting` → string (optional)

---

### 4.4 Constraints & Open Questions

- Maximum string sizes in LSL/linkset data must be respected; large stats payloads may need truncation or chunking.
- Whether owner name can be resolved reliably with available LSL functions.
- Whether slurl can be built from region data reliably and stored once.
- Interaction with future web integrations should be decoupled from the core scanning and storage logic.

---

## 5. Delivery Plan (Staged)

### Stage 0 — Discovery & Validation
**Goals**
- Validate LSL constraints (string size, linkset capacity, inventory events).
- Confirm object name/description/owner access from inventory items.

**Outputs**
- Short technical note on limits and any workarounds.

---

### Stage 1 — Core Inventory Indexer (MVP)
**Goals**
- Implement object discovery, filtering, and metadata persistence.
- Populate `meta.total` and per-object keys.
- Support reset and start/stop behavior.

**Deliverables**
- Script that scans on rez and on inventory change.
- Linkset data populated according to schema.

---

### Stage 2 — Owner Menu & Configuration
**Goals**
- Implement owner-only menu with Start/Stop/Reset/Name/Text On/Off/Set Logo/Help Notecard.
- Implement general menu with stats notecard and landmark.

**Deliverables**
- Scripted menu system.
- Notecard/landmark delivery.

---

### Stage 3 — Pricing Workflow
**Goals**
- Add `Add Price` submenu (Price One / Price All).
- Store price metadata per object.

**Deliverables**
- Dialog prompts for price input.
- Validation and persistence in linkset data.

---

### Stage 4 — Stats Enrichment (Optional)
**Goals**
- Capture or import stats beyond name/description/owner.
- Store stats strings and optional web listing URLs.

**Deliverables**
- Schema expansion for stats.
- Documentation for workflow (manual or automated).

---

### Stage 5 — UI Viewer & Vendor (Stretch)
**Goals**
- Provide scrollable viewer UI for bundles.
- Integrate optional images for traits/coat.
- Add vendor behaviors (selling bundles/horses).

**Deliverables**
- UI script(s) and texture mapping system.
- Vendor flow documentation.

---

## 6. Acceptance Criteria (MVP)
- When bundles are dropped into the box, valid objects are detected and stored.
- `meta.total` reflects the number of valid objects and updates on changes.
- Owner-only menu controls operate as specified.
- General menu items provide notecard and landmark.
- Linkset data schema is adhered to and survives script reset.

---

## 7. Implementation Notes
- Consider splitting scripts by concern:
  - **Indexer** (inventory scanning, storage)
  - **Menu/UX** (dialog UI and user input)
  - **Vendor** (future stage)
- Use linkset data prefixes to prevent collisions.
- Use event-driven scans on inventory changes where possible to minimize polling.

---

## 8. Risks & Mitigations
- **Risk**: Linkset data limit exceeded.
  - **Mitigation**: Store minimal metadata; chunk large strings.
- **Risk**: Inventory change detection missed.
  - **Mitigation**: Manual refresh command in owner menu.
- **Risk**: LSL string limits block stats storage.
  - **Mitigation**: Truncate or offload stats to notecard or external web storage.

---

## 9. Next Actions
- Confirm Stage 0 findings and finalize LSL limits.
- Implement Stage 1 prototype and validate with sample bundles.
- Iterate with owner menu and price workflow.
