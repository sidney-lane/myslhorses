# Build/Verification Plan (v1)

This document defines stepwise checkpoints for implementing the v1 horse system, including the exact in-world LSL outputs required to verify each step before advancing.

## Step 1: Hover Text Proof-of-Concept (max 15 horses)

**Goal:** Prove hover text updates for a capped set of horses (maximum 15) without relying on external parsing or API validation.

**Implementation checkpoints:**
- Maintain a local list of up to 15 horse IDs or entries.
- On update, display hover text for each horse in-world.

**Required verification output:**
- For each horse in the capped list, call `llSetText` with a concise status string.
- Also emit a debug confirmation:
  - `llOwnerSay("[BUILD STEP 1] Hover text updated for <HORSE_ID>")`

**Pass criteria:**
- Hover text is visible for each of the capped horses.
- The owner chat shows one confirmation per horse update.

## Step 2: Parse/Validate Horse API Fields

**Goal:** Parse API payload fields and validate the expected schema before rendering or other logic.

**Implementation checkpoints:**
- Parse the API response into structured fields (e.g., id, name, status, traits, media URLs).
- Validate required fields and handle missing/invalid values gracefully.

**Required verification output:**
- For each parsed horse record:
  - `llOwnerSay("[BUILD STEP 2] Parsed horse <HORSE_ID> name=<NAME> status=<STATUS>")`
- For any validation failure:
  - `llOwnerSay("[BUILD STEP 2] Validation failed for <HORSE_ID>: <REASON>")`

**Pass criteria:**
- Valid records emit a parsed confirmation with expected field values.
- Invalid records emit a validation failure message without crashing or misrendering.

## Step 3: Menu Options

**Goal:** Provide an owner menu (dialog) to control basic display options and behavior.

**Implementation checkpoints:**
- Create a dialog menu with at least: Refresh, Toggle Hover, Next/Prev Page (if paging is needed).
- Wire selections to internal state changes.

**Required verification output:**
- When the menu is shown:
  - `llOwnerSay("[BUILD STEP 3] Menu displayed")`
- When an option is selected:
  - `llOwnerSay("[BUILD STEP 3] Menu option selected: <OPTION>")`

**Pass criteria:**
- Menu appears and selections are reported in owner chat.
- Selected options trigger the intended state updates.

## Step 4: Media URL Refresh

**Goal:** Fetch/refresh media URLs (e.g., images) and confirm updated references.

**Implementation checkpoints:**
- Detect stale media URLs and refresh them via the API or refresh endpoint.
- Store refreshed URLs and apply them to relevant display data.

**Required verification output:**
- For each refreshed horse media item:
  - `llOwnerSay("[BUILD STEP 4] Media refreshed for <HORSE_ID>: <MEDIA_URL>")`
- If refresh fails:
  - `llOwnerSay("[BUILD STEP 4] Media refresh failed for <HORSE_ID>: <REASON>")`

**Pass criteria:**
- Successful refresh emits the new URL in owner chat.
- Failures are reported without blocking other updates.

## Step 5: Backend Integration

**Goal:** Connect all steps into the full backend flow: API fetch → parse/validate → media refresh → hover/menu updates.

**Implementation checkpoints:**
- Perform full API fetch cycle.
- Execute validation, menu configuration, and hover/media updates using real data.
- Confirm that API responses and updates are synchronized.

**Required verification output:**
- At the start of the cycle:
  - `llOwnerSay("[BUILD STEP 5] Backend sync শুরু")`
- After successful full-cycle completion:
  - `llOwnerSay("[BUILD STEP 5] Backend sync complete: <HORSE_COUNT> horses")`
- If any API fetch fails:
  - `llOwnerSay("[BUILD STEP 5] Backend sync failed: <REASON>")`

**Pass criteria:**
- A successful cycle logs start and completion with counts.
- Failure states are logged without causing script crashes.
