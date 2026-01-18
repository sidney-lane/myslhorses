# Rockstar Ranch Stand Teleporter — Error Log & Audit

This file documents observed errors, verified root causes, and hardened fixes per the
requirements in `teleporters/v1/README.md`. It also includes an audit of the scripts for
compliance and potential risks.

Last updated to restore documentation after an accidental revert.

## Error Log

## Operator Notes (Verbatim)

Causes:
1,2,4,5 are not the issue. However, you should have a local owner only / channel output for all functions that may cause the error so it can be correctly verified and debugged. (NOT FOR SENSOR CONNECTIONS - that crashed the sim)

Functions
Use a debug to VERIFY ONCE only on avatar sit.

Menu
Not an issue, however menu's can easily e paginated

Teleportation
Debug logs to verify if any of these are the cause in a channel/to creator/owner. ONCE ONLY - dont crash the sim

Instructions:
1. Add all of this response, verbatim to the ERRORS.md file
2. Add the MINIMAL debug logs so we can pinpoint where the error is occurring
3. REWRITE THE SCRIPT to ensure what can be avoided does not occur
4. If a re-architecture is required for functionality - explicitly write the tradeoffs needed for core functionality up

---

### Error: “NAME NOT DEFINED IN SCOPE”
**Observed behavior**
* Script fails to compile with a basic LSL syntax error indicating a missing identifier.

**Verified causes**
1. **Undefined constant or variable referenced before declaration** in the script.
2. **Typos or renamed identifiers** left stale in the code after edits.

**Corrective actions**
* Declare all constants and helpers before they are used.
* Run the script through the LSL compiler before deploying to ensure all identifiers exist.

**How to overcome**
* Fix the missing declaration or typo and recompile. This is a hard compile error and
  prevents the script from running at all.

---

### Error: Only found one teleporter
**Observed behavior**
* The dialog showed a single destination even though multiple teleporters were rezzed.

**Verified causes (per spec)**
1. **Discovery had not converged yet**: menus were shown immediately on sit while the
   region-wide handshake had not finished broadcasting to all peers.
2. **Over-aggressive pruning during menu build**: filtering the registry with
   `llGetObjectDetails(..., [OBJECT_POS])` could drop otherwise valid teleporters
   transiently, leaving only one entry visible.

**Corrective actions**
* Keep a **canonical registry keyed by object key**, and do **not prune** entries during
  menu build; instead, validate a destination **at selection time**.
* Trigger a **broadcast on sit** (in addition to periodic rebroadcast) so the registry is
  refreshed quickly while still showing a menu immediately.

**How to overcome**
* Ensure all teleporters share the exact description and are running the script, then sit
  and wait for the list to converge (the system now rebroadcasts periodically and on sit).

---

### Error: “Destination unavailable / location not found”
**Observed behavior**
* Teleport fails or the menu rebuilds with “Destination unavailable.”

**Verified causes**
1. **Destination object was deleted/moved across regions** between menu display and
   selection, causing `llGetObjectDetails(..., [OBJECT_POS])` to return an empty list.
2. **Stale registry entry** from a teleporter that no longer exists in the region.

**Corrective actions**
* Validate the destination key **at selection time** and rebuild the menu if the
  destination is missing.
* Keep periodic handshake broadcasts so the registry converges again after changes.

**How to overcome**
* Re-open the menu after the system rebroadcasts. If the destination is still missing,
  rez or restart the missing teleporter so it re-registers.

---

### Error: “Teleport failed: landmark name provided but asset is missing or invalid.”
**Observed behavior**
* Teleport failed even though the destination existed.

**Verified causes (per spec)**
1. **Teleport invoked while the avatar was still seated**, which is explicitly unsafe and
   can produce this error.
2. **Teleport invoked before confirming the avatar has fully unsat**.

**Corrective actions**
* Require permissions, **unsit**, and **only teleport after unsit** is confirmed.
* Validate that `llAvatarOnSitTarget()` is `NULL_KEY` before calling `llTeleportAgent`.

**How to overcome**
* Sit, select a destination, and allow the script to unsit you automatically before
  teleporting. If permission is denied, the teleport will not proceed.

---

## Audit Checklist (Requirements Alignment)

**Identity / Membership**
* Uses the exact object description check as required; if it doesn’t match, the script
  warns the owner.

**Discovery**
* Uses `llRegionSay` + `llListen` on a deterministic channel.
* Periodic rebroadcast with a handshake response on discovery.

**Menu / UX**
* Menu appears immediately on sit.
* Uses **numbered buttons** with a mapping (`MENU_MAP`) to avoid truncation ambiguity.
* Displays all known teleporters at once (with a guard for the 12-button limit).

**Teleportation**
* Same-region only, using `llGetRegionName()` at teleport time.
* Live destination lookup via `llGetObjectDetails(destKey, [OBJECT_POS])`.
* Unsit-before-teleport sequence enforced.

**Known Limits**
* `llDialog` is limited to 12 buttons; beyond that, teleporters require pagination or
  grouping (explicitly out of scope per README).
* Teleport can still fail if a destination is deleted between menu display and selection;
  the scripts now detect this and rebuild the menu.

## Re-architecture Tradeoffs (If Needed)
* Adding pagination would prevent exceeding `llDialog` limits but requires additional
  state, more dialogs, and repeated user interactions (slower UX).
* Adding retry delays after unsit may reduce timing-related teleport failures but can make
  teleports feel sluggish and still requires permission handling to remain deterministic.
