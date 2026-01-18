# LSL Testing Suite (AI-ready)

This suite translates the constraints in `Testing/README.md` into a **repeatable, AI-friendly testing workflow** for LSL scripts. The goal is not to pretend LSL has a native test runner (it does not), but to provide **structured assets, templates, and checklists** that an AI agent can use to produce **consistent, verifiable test plans** across scripts.

## Why this exists

The current reality of LSL testing (static analysis + viewer compile + in-world/runtime checks) is captured in `Testing/README.md`. This suite packages that reality into:

* **A staged test pipeline** (static → compile → runtime).
* **Reusable LSL harness scripts** for runtime assertions.
* **Templates** for test plans and test cases.
* **Logging conventions** for AI to parse or compare.

## Folder layout

```
Testing/suite/
├─ README.md                (this file)
├─ lsl/
│  ├─ lsl_assert.lsl         (assert helpers)
│  └─ lsl_test_controller.lsl (example in-world test runner)
└─ templates/
   └─ test-plan.md           (AI-friendly test plan template)
```

## The staged testing pipeline

### Stage 1 — Static validation (CI-friendly)
**Goal:** Catch syntax/type issues early.

**Tooling:** `lslcomp` from the Sei-Lisa lsl-compiler project.

**AI checklist:**
1. Enumerate all `.lsl` files in the change set.
2. Run `lslcomp` on each file.
3. Record warnings and errors per file.

> Note: This does **not** guarantee Second Life compatibility; it only reduces obvious errors.

### Stage 2 — Viewer compile (authoritative)
**Goal:** Ensure compatibility with the actual Second Life compiler.

**Automation pattern:** Use Firestorm/SL viewer + UI automation (AutoHotkey, Hammerspoon, SikuliX) to upload scripts and parse compile results.

**AI checklist:**
1. For each script, upload to a test object in the viewer.
2. Capture and record compiler output.
3. Mark PASS/FAIL per script.

### Stage 3 — Runtime behavior (in-world or OpenSim)
**Goal:** Validate logic and permissions in a simulator.

**Options:**
* **OpenSim** (automatable, best for regression testing)
* **Second Life test region** (authoritative, less automatable)

Use the provided LSL test harness scripts to run assertions and report results via chat output.

## LSL harness components

### `lsl_assert.lsl`
Provides basic PASS/FAIL logging helpers. Copy/paste the functions into the script under test or into a shared include file if your build pipeline supports it.

### `lsl_test_controller.lsl`
An example test runner that:
* Fires tests on `state_entry`.
* Emits `PASS:`/`FAIL:` messages.
* Tracks totals and prints a summary.

## AI-friendly test plan template

Use `templates/test-plan.md` to generate a consistent plan per script. The plan includes:

* **Static checks**
* **Viewer compile checks**
* **Runtime test cases** with expected chat output

## Recommended logging format

All runtime tests should emit output in a consistent format to make AI parsing easier:

```
PASS: <test-id> - <message>
FAIL: <test-id> - <message>
SUMMARY: <passed>/<total> passed
```

## Suggested next steps for using this suite

1. Copy `templates/test-plan.md` and fill it per script.
2. Embed `lsl_assert.lsl` helpers into your scripts or test harness.
3. Use `lsl_test_controller.lsl` as a starter for runtime tests.
4. Automate Stage 1 in CI if possible.
5. Automate Stage 2/3 where your environment allows.

---

**Reminder:** This suite is grounded in the hard limitations of LSL testing. It is designed to be **honest, repeatable, and AI-operable** rather than pretending LSL has a native unit test runner.
