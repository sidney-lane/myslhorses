# Status Board Requirements (v1)

This document defines functional and non-functional requirements for the status board. Requirements reference the existing design notes in `status/v1/README.md` for parity with Horse API fields and board behavior. All details below should align with those sections unless explicitly expanded here.

## Functional Requirements

### Display Board: Required Data Fields
- **Board header** MUST display the **Project/Pod Title**. (Source: Display board section in `README.md`.)
- **Board body** MUST list **horses within configured range** and show a **status line per horse**. (Source: Display board section in `README.md`.)
- **Horse status line** MUST include:
  - **Gender, Age, and Name** of the horse. (Source: Horse Status Displays section.)
  - **Status timing block** based on age threshold:
    - If **over 7 days old**: show **Pregnancy** (with time to drop) **OR** **Fervour** (with time to 100%) **OR** **Pregnancy recovery** (with time to recovered). (Source: Horse Status Displays section.)
    - If **under 7 days old**: show **Time of birth** and **time to 7 days old** (if possible). (Source: Horse Status Displays section.)

### Horse API Field Parity
- Parsing MUST use the **Horse API** string from the horse description field with the documented order and meaning:
  - `Specific-UUID:Settings info:age:hunger:energy:fervor:happiness:gender:pairing:pregval:home:breed:version`. (Source: Horse API section.)
- **Settings block** MUST be interpreted as:
  - Mode (Owner/Group/All), Movement, Animations, Text, Sounds, Foodtype, and Range (two digits). (Source: SETTINGS Block section.)
- **Gender** MUST map to **1 = Male** and **2 = Female**. (Source: Gender section.)

### Scan Cadence
- The board MUST **scan for horses every minute** (or otherwise default to a 60s cadence) to minimize lag. (Source: Board Requirements section.)

### Range Limits
- The user-configurable scan range MUST be an **integer** and MUST support **up to 15m**. (Source: Menu-driven section.)
- Range in Settings block should honor the **two-digit range** field where applicable. (Source: SETTINGS Block section.)

### Menu Options & Permissions
- A menu MUST exist and be **permission-gated** (Owner only / Group only / All). (Source: Menu-driven section.)
- Menu MUST provide:
  - **Start / Stop / Reset** (scripts) with **auto-start on rez**. (Source: Menu-driven section.)
  - **Permissions** setting (Owner only / Group only / All). (Source: Menu-driven section.)
  - **Set range** (integer, up to 15m). (Source: Menu-driven section.)
  - **Change hover text color** (8 options). (Source: Menu-driven section.)
  - **[Stretch] confirm horses found** in a pod (optional). (Source: Menu-driven section.)

### Hover Text Constraints
- Hover text should be used as the initial **POC** display, with a maximum of **15 horses** shown in hover text. (Source: POC note.)
- Hover text color choices MUST be limited to the **8 menu options** described above. (Source: Menu-driven section.)

### MOAP (Media on a Prim) Behavior
- The board MUST use **media display textures** (MOAP) and SHOULD **auto-refresh** the media URL to prevent it from turning off. (Source: Board Requirements + MOAP Issues sections.)
- The board SHOULD respect standard MOAP constraints and avoid scripted resets that clear media state. (Source: MOAP Issues section.)

## Non-Functional Requirements

### Performance & Lag Constraints
- Scanning cadence SHOULD default to **once per minute** to reduce region/script load. (Source: Board Requirements section.)
- The board SHOULD minimize prim count by using **faces on a single object** where possible. (Source: Board Requirements section.)

### Prim/Face Usage
- Display SHOULD be implemented with **faces of an object** to minimize prim usage. (Source: Board Requirements section.)

### LSL Script Limits & Behavior
- Scripts SHOULD auto-start on rez and avoid excessive timers beyond the 60s scan cadence. (Source: Menu-driven + Board Requirements sections.)
- Scripts SHOULD avoid calling `llClearPrimMedia()` on a timer or reset, to prevent MOAP shutdown. (Source: MOAP Issues section.)

### Media Refresh & Resilience
- Media SHOULD be re-applied on a **timer (e.g., 60 seconds)** to prevent MOAP stalling. (Source: MOAP Issues section.)
- Media permissions SHOULD be set so only authorized users can control the media, or be set to **NONE** to prevent accidental disable. (Source: MOAP Issues section.)
- The board SHOULD tolerate viewer/parcel media conflicts and provide guidance for debugging if MOAP is off (e.g., touch to play, cache clear). (Source: MOAP Issues section.)
