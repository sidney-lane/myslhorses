# Project Readme — Status Board v1.1 (Design + Current State)

## Purpose
Status board that scans nearby horses, parses the description payload, renders hover text, and optionally syncs to backend. The v1.1 update introduces a storage‑prim architecture for per‑horse persistence (bundle cooldown timestamps and extended traits).

---

## Current Implementation (status_board_v1.1.lsl)
- **Scan**: `llSensor` on a timer; max horses capped by `MAX_HORSES` (currently 10).
- **Parse**: description format is parsed by `parseHorseApi`.
- **Hover Text**:
  - Line 1: name + gender + age
  - Line 2: pregnancy + fervor info
- **Menu** (owner unless noted):
  - Start / Stop / Reset
  - Set Range (1–10m)
  - Set Scan (1–60 min)
  - Text Color (single color)
  - See Stats
  - Debug On/Off (creator only)
- **Config persistence**: stored in root prim description JSON
  - `board_id`, `range_m`, `scan_min`, `permissions`, `name_color_index`, `status_color_index`, `media_url`
- **Backend**: `llHTTPRequest` with JSON payload if `gBackendUrl` is set.

### Description Field Format (current)
`Settings info:age:hunger:energy:fervor:happiness:gender:pairing:pregval:home:breed:version`
- Example:
  `00000000-0000-0000-0000-000000000000:O111025:1359:0:99:0:100:1:0:0:214.97.51:0:V7.0`

### Pregnancy + Fervor Logic (current)
- Pregnancy time uses 72h scale based on `pregval` percent.
- Fervor time uses the existing `F_PCT` / `F_HOURS` table.
- If age < 7 days, line 2 shows `Birth +Xd` and fervor calculated from 0.

---

## New Storage Architecture (planned v1.1 update)
Because horse descriptions do not include bundle drop timestamps, we will persist timestamps and extended stats inside the board’s **linked child prims** (manual storage boxes).

### Storage Prim Model
- You will add **10 child prims** named `horse_storage`.
- Script will rename each storage prim to `horse_storage:<horse_key>` when assigned.
- Storage prim description will hold a JSON payload.

### Storage Prim JSON (planned)
```json
{
  "horse_key": "ae6f387e-466e-cf14-f32c-aaeaf9eb59ca",
  "base_desc": "<full horse desc string>",
  "last_desc": "<last seen desc>",
  "last_bundle": 1700000000,
  "bundles": [
    {"time": 1700000000, "desc": "<bundle desc>"}
  ],
  "traits": {
    "Coat": "Russet Lusitano",
    "Eye": "Dragon Knight Sapphire",
    "Mane": "Normal",
    "Tail": "Long",
    "Horn Style": "Dragon",
    "Horn Color": "Sapphire"
  }
}
```
Notes:
- `last_bundle` is Unix time at pregnancy completion (pregval >= 100).
- `bundles` is a history list (trim to reasonable length).
- `traits` is extended user‑supplied stats.

### Bundle Drop Detection (planned)
- Bundle drop occurs when **pregnancy reaches 100%** for mares.
- We will compare current `pregval` and stored `last_desc` to detect the transition.
- When detected, store `last_bundle = llGetUnixTime()` and append to `bundles`.

### Cooldown + Fervor Rules (planned)
- No separate “fervor cooldown.”
- Fervor only increases after **4 days** (96h) from last bundle drop.
- When not pregnant:
  - show **cooldown remaining** = `max(0, last_bundle + 4d - now)`
  - then show **fervor hours** only after cooldown is complete

---

## Extra Stats Input (planned)
Add menu flow to store extended traits per horse.

### Requirements
- A menu item **Extra Stats**.
- User selects a horse from list, then pastes full stats text.
- Stats can have up to ~30 traits; need **dialog channel + multi‑message capture** (not a single `llTextBox`).

### Input Example
```
DOUBLE DRAGON KNIGHT SAPPHIRE
Version 7.0
Age 5
Gender female
Nourishment 1%
Energy 4%
Happiness 88%
Fervor 0%
Coat: Russet Lusitano
Eye: Dragon Knight Sapphire
Mane: Normal
Tail: Long
Horn Style: Dragon
Horn Color: Sapphire
ae6f387e-466e-cf14-f32c-aaeaf9eb59ca
```
- Ignore fields already in base desc (version/age/gender/nourishment/energy/happiness/fervor).
- Persist traits + (optional) horse UUID as backup.

---

## Next Steps to Implement
1. Rename storage prims and maintain `horse_storage:<horse_key>` mapping.
2. Implement storage JSON read/write per storage prim.
3. Detect bundle drop from `pregval` transition to 100.
4. Display cooldown + fervor logic in line 2.
5. Add Extra Stats menu flow with horse selection + multi‑message capture.
6. Add pruning rules for bundle history and JSON size limits.

---

## Files
- `myslhorses/status/v1/status_board_v1.1.lsl` (working copy of script)
- `myslhorses/status/v1/status_board.lsl` (original v1)
