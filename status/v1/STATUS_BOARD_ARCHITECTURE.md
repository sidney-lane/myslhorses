# Status Board Architecture (Low Lag)

## Goals
- Minimal script time per scan.
- Fewer chat/listen events.
- Avoid repeated heavy parsing and hovertext updates.
- Keep configuration reliable and fast to load.

## Recommended Split (3 scripts)
1. **Scanner + Cache**
   - Responsibilities: llSensor/llSensorRepeat, read object desc, parse fields once.
   - Outputs: per-horse cached structs (key, name, age, gender, preg, fervor, etc.).
   - Emits link messages on updates only.

2. **Renderer (Hover + Media)**
   - Responsibilities: build display strings, set hover text, update media only when needed.
   - Input: link messages from Scanner with summarized data.

3. **Menu + Config**
   - Responsibilities: dialogs, permissions, config persistence, debug toggles.
   - Writes config to object description (fast) and signals Scanner/Renderer via link messages.

This keeps scanning and rendering decoupled so hover updates don’t block sensor cycles and menu traffic doesn’t interfere with scan timing.

## Config Strategy
- **Primary**: object description JSON (fast, local, no dataserver delay).
- **Optional defaults**: a notecard (read once at startup, only if you need human-editable defaults).
- Avoid using notecards for frequently changed values (updates require manual edit + reset).

## Performance Tips
- Use **llSensorRepeat** for steady intervals (lower overhead than manual timers + llSensor).
- Cache parsed results and **only update hover text when the output actually changes**.
- Avoid frequent `llOwnerSay` (debug only) and avoid list growth without clearing.
- Limit list sizes and avoid building large JSON every frame; send only changed rows.
- Use `llGetObjectDetails` with minimal fields; avoid extra calls.
- Prefer integer math and precomputed tables for timings (already used for fervor).

## Hover Text Colors
- LSL hover text is one color per prim. For dual-color lines, use **two prims**:
  - `HoverName` for line 1 (names)
  - `HoverStats` for line 2 (stats)
- Renderer sets PRIM_TEXT on each prim with its own color.

## Network / Backend
- Debounce outbound HTTP: throttle updates to once per scan interval or only on change.
- If Supabase or external APIs fail, backoff rather than retry immediately.

## Suggested Message Protocol (Link Messages)
- `CFG|range=10|scan=2|color1=5|color2=3|debug=0`
- `DATA|key=...|name=...|age=...|gender=...|preg=...|fervor=...`

This keeps each script focused and predictable, minimizes unnecessary work, and reduces lag spikes during scans.
