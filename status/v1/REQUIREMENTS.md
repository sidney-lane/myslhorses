# MSL Horses Status Board v1 Requirements

## Purpose
Provide an in-world status board that scans nearby MSL horses, reads their encoded API string from the description field, and renders a lightweight status display on a media face (MOAP) with a hover-text fallback for early validation.

## In Scope
- **Board types**: one "master" display and optional linked "pod" boards that receive the master data feed.
- **Display content**:
  - Project/pod title.
  - Horses within configured range and their status derived from the API string.
- **Horse status fields** (from description API):
  - Gender, age, and horse name.
  - If age >= 7 days: pregnancy OR fervor OR pregnancy recovery status (with time remaining).
  - If age < 7 days: time of birth + time to 7 days.
- **Configuration menu**:
  - Start/stop/reset.
  - Permissions: owner/group/all.
  - Range (integer meters, <= 15m).
  - Hover text color (preset options).
  - Optional: allow ignoring specific horses.

## Out of Scope
- Breeding automation or altering horse data.
- Any viewer-side installation steps or custom viewer requirements.

## Functional Requirements
1. **Scan cadence**: board scans for horses no more than once per minute by default.
2. **Horse detection**: detect horses within the configured range and parse the description API string.
3. **Status derivation**: compute status labels from the API values (age, pregnancy/fervor/recovery).
4. **Display output**:
   - Phase 1: hover text on faces or floating text for max 15 horses.
   - Phase 2: MOAP panel fed by a hosted status page.
5. **Master/pod linking**: pod boards can subscribe to the master feed or receive updates from the master.
6. **Permissions**: actions respect the configured access mode (owner/group/all).
7. **Resilience**: on rez or reset, the board should start automatically using last saved configuration.

## Non-Functional Requirements
- **Performance**: avoid lag by limiting scan frequency and minimizing HTTP requests.
- **Reliability**: MOAP refresh must re-apply media URL periodically to avoid viewer stalls.
- **Security**: do not accept inbound commands without permission checks.
- **Compatibility**: adhere to LSL Portal functions and limitations.

## Acceptance Criteria
- Board reliably lists horses within range and hides those outside.
- Status fields match the decoded API values.
- Hover-text mode displays a readable list for <= 15 horses.
- MOAP mode shows a live-updating status page without manual activation (subject to viewer settings).
- Menu settings persist across reset/re-rez.
