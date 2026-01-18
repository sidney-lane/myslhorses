# Rockstar Ranch Stand Teleporter

**Project Description, Requirements, Constraints & Failure Analysis**

---

## 1. Project Overview

The **Rockstar Ranch Stand Teleporter** is an in-world Second Life teleportation system implemented entirely in **LSL**, intended to connect multiple rezzed teleport prims within a region.

The system is designed for **stand-style teleportation** (no visible sitting animation) and must dynamically discover all other teleporters in the network, present them to the user in a menu, and teleport the avatar reliably—even if teleporters are moved after rez.

This project explicitly **does not rely on sensors**, **does not cache world positions**, and **does not assume rez events imply final location**.

---

## 2. Functional Requirements

### 2.1 Identity & Network Membership

A prim participates in the teleporter network **if and only if**:

* Its object description is exactly:

  ```
  *Rockstar Ranch* Teleporter
  ```
* The asterisks (`*`) are **literal characters**, not wildcards.

---

### 2.2 Discovery Requirements

* Teleporters must discover **all other teleporters** in the same region.
* Discovery must:

  * Work regardless of rez order
  * Work regardless of distance (within region)
  * Not rely on physics or sensors
* Discovery must **converge** even with message loss.

**Required mechanism**:

* `llRegionSay` + `llListen`
* Deterministic shared channel
* Periodic rebroadcast
* Handshake response on discovery

---

### 2.3 Menu & UX Requirements

* Avatar interacts by **sitting** on the teleporter.
* On sit:

  * A menu appears immediately.
  * No extra “Teleport” confirmation step.
* Menu must:

  * Show all teleporters with **human-readable destination names**.
  * Handle duplicate names safely.
  * Avoid button truncation or ambiguity.
  * Support pagination when more than 12 buttons are required.

---

### 2.4 Teleportation Requirements

* Teleport must be **same-region only**.
* Teleport must:

  * Use live object position at teleport time
  * Work even if destination object has been moved
* Avatar must **not be seated during teleport**.

Required sequence:

1. Avatar sits
2. Menu selection made
3. Avatar is **unsat**
4. Teleport occurs

---

## 3. Hard Constraints (LSL / Second Life)

These are **non-negotiable platform constraints**, verified against the LSL Portal.

---

### 3.1 No Region Data in Object Queries

There is **no** LSL constant to retrieve another object’s region name.

* ❌ `OBJECT_REGION` does **not exist**
* ❌ No region data in linkset params
* ✅ Region name must come from:

  ```lsl
  llGetRegionName()
  ```

**Reference**:
[https://wiki.secondlife.com/wiki/LlGetObjectDetails](https://wiki.secondlife.com/wiki/LlGetObjectDetails)

---

### 3.2 Object Positions Must Be Queried Live

Objects can be:

* Moved
* Linked
* Shifted
* Aligned

**Rez position is not authoritative.**

Correct method:

```lsl
llGetObjectDetails(destKey, [OBJECT_POS])
```

**Reference**:
[https://wiki.secondlife.com/wiki/LlGetObjectDetails](https://wiki.secondlife.com/wiki/LlGetObjectDetails)

---

### 3.3 Teleporting While Seated Is Unsafe

Teleporting an avatar **while they are still sitting** can result in:

* Silent failure
* Landmark resolution fallback
* Error:

  > *Teleport failed: landmark name provided but asset is missing or invalid.*

Correct behavior:

* Unsit avatar **before** teleporting.

**Related references**:

* [https://wiki.secondlife.com/wiki/LlUnSit](https://wiki.secondlife.com/wiki/LlUnSit)
* [https://wiki.secondlife.com/wiki/LlTeleportAgent](https://wiki.secondlife.com/wiki/LlTeleportAgent)

---

### 3.4 Dialog Constraints

`llDialog` limitations directly affect discovery UX:

* Max **12 buttons**
* Button text **truncation**
* No metadata binding
* No stable ordering guarantees

**Implication**:
Menus must avoid truncation ambiguity and rely on a stable mapping between button labels
and teleporter keys, with pagination when necessary.

**Reference**:
[https://wiki.secondlife.com/wiki/LlDialog](https://wiki.secondlife.com/wiki/LlDialog)

---

## 4. Errors Encountered During Development

This section documents **actual failures observed in this chat**, with root causes.

---

### Error 1: “Not finding all teleporters”

**Observed behavior**:

* Only one or a subset of teleporters appeared.

**Root causes**:

* Menu reconstruction collapsing entries
* Index-based inference from dynamic menus
* Dialog truncation hiding entries
* Non-canonical registry mapping

**Resolution**:

* Canonical registry keyed by `object key`
* Stable mapping between menu selection and object key
* No index math based on regenerated menus

---

### Error 2:

**“Teleport failed: landmark name provided but asset is missing or invalid.”**

**Observed behavior**:

* Teleport fails despite correct position data.

**Root causes**:

* Attempting to teleport while avatar was seated
* Teleport invoked after state drift
* Invalid or empty region string at call time

**Resolution**:

* Always unsit avatar before teleport
* Same-region teleport only
* Use `llGetRegionName()` at teleport time
* Perform teleport atomically after unsit

---

### Error 3: Compilation Errors (“NAME NOT DEFINED WITHIN SCOPE”)

**Observed behavior**:

* Scripts failing to compile.

**Root cause**:

* Use of non-existent constants (e.g. `OBJECT_REGION`)

**Resolution**:

* Strict verification against LSL Portal
* Only documented constants used

---

### Error 4: Stale Teleport Positions

**Observed behavior**:

* Teleporting to old positions after objects moved.

**Root cause**:

* Cached `<x,y,z>` values

**Resolution**:

* Never cache position
* Always query `OBJECT_POS` live

---

## 5. Final Locked Invariants

These invariants define a **correct implementation**:

1. Same-region teleport only
2. No sensors
3. No cached position data
4. Object discovery via region chat + handshake
5. Registry keyed by object key
6. Avatar unsat before teleport
7. Menu selections map directly to keys
8. Only LSL-Portal-documented functions/constants used

Any implementation violating **any** of the above will reproduce the failures seen in this chat.

---

## 6. Key References (Authoritative)

* LSL Portal (main):
  [https://wiki.secondlife.com/wiki/LSL_Portal](https://wiki.secondlife.com/wiki/LSL_Portal)

* `llGetObjectDetails`:
  [https://wiki.secondlife.com/wiki/LlGetObjectDetails](https://wiki.secondlife.com/wiki/LlGetObjectDetails)

* `llTeleportAgent`:
  [https://wiki.secondlife.com/wiki/LlTeleportAgent](https://wiki.secondlife.com/wiki/LlTeleportAgent)

* `llUnSit`:
  [https://wiki.secondlife.com/wiki/LlUnSit](https://wiki.secondlife.com/wiki/LlUnSit)

* `llDialog`:
  [https://wiki.secondlife.com/wiki/LlDialog](https://wiki.secondlife.com/wiki/LlDialog)

* `llRegionSay`:
  [https://wiki.secondlife.com/wiki/LlRegionSay](https://wiki.secondlife.com/wiki/LlRegionSay)

* `llListen`:
  [https://wiki.secondlife.com/wiki/LlListen](https://wiki.secondlife.com/wiki/LlListen)

---

## 7. Future Feature Ideas (Non-Core, Optional)

The following features are **explicitly out of scope for the core teleporter**, but can be layered on safely once the locked invariants above are satisfied:

### 7.1 Visual & UX Enhancements

* Teleport departure animation (e.g. brief fade, glow, dissolve)
* Arrival animation at destination
* Particle beam or arc between source and destination
* Ground decals or light rings indicating teleport pad

### 7.2 Audio Feedback

* Activation sound on sit
* Teleport “charge-up” sound
* Arrival confirmation sound

### 7.3 Access Control

# Only need to give permission once to teleporter - shouldn't need to ask every time.
* Owner-only teleporters
* Group-only teleporters
* Role-based access via group titles

### 7.4 UI Improvements

* Paginated menus for large networks
* Alphabetical sorting of destinations
* Category or zone grouping (Barn, Arena, House, etc.)

### 7.5 Diagnostics & Debugging

* Owner-only debug menu
* Live dump of discovered teleporters
* Visual debug text showing last handshake time

All future features **must preserve**:

* live position lookup
* unsit-before-teleport sequence
* canonical object-key registry

Any feature violating these must be rejected by design.

---

## 8. Status

At the end of this chat:

* Requirements are now **explicit**
* Platform constraints are **correctly identified**
* Prior failures are **fully explained**
* Any future implementation can be validated **mechanically** against this document

This document should be treated as the **authoritative specification** for the Rockstar Ranch Stand Teleporter system.
