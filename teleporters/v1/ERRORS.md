# Rockstar Ranch Stand Teleporter — Error Log & Audit

This file documents observed errors, verified root causes, and hardened fixes per the
requirements in `teleporters/v1/README.md`. It also includes an audit of the scripts for
compliance and potential risks.

## Error Log

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
