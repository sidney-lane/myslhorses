# LSL Test Plan: <script-name>.lsl

## Scope
* **Script:** `<script-name>.lsl`
* **Purpose:** <one-line summary>
* **Dependencies:** <other scripts, notecards, permissions, prim setup>

---

## Stage 1 — Static validation

**Command(s):**
```
lslcomp <script-name>.lsl
```

**Expected:**
* No syntax/type errors.
* Warnings recorded (if any).

**Notes:**
* Static analysis is not authoritative; proceed to Stage 2.

---

## Stage 2 — Viewer compile (authoritative)

**Steps:**
1. Upload `<script-name>.lsl` into the target object via Firestorm/SL viewer.
2. Capture compile output.

**Expected:**
* No compile errors or warnings.

**Evidence to record:**
* Screenshot or log text of compile output.

---

## Stage 3 — Runtime verification

### Test environment
* **Region:** <OpenSim or SL region name>
* **Object setup:** <prim name, permissions, contents>
* **Avatar actions:** <click, touch, chat, sit, etc.>

### Test cases

| ID | Setup | Action | Expected Output |
|----|-------|--------|-----------------|
| tc-001 | <state> | <action> | PASS: tc-001 - <message> |
| tc-002 | <state> | <action> | PASS: tc-002 - <message> |

### Output summary
**Expected format:**
```
PASS: <test-id> - <message>
FAIL: <test-id> - <message>
SUMMARY: <passed>/<total> passed
```

---

## Results

* **Stage 1:** <pass/fail + notes>
* **Stage 2:** <pass/fail + notes>
* **Stage 3:** <pass/fail + notes>
