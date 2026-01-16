# ELI5 Guide — Step 1 Scripts + Test (Super Simple)

This guide explains **exactly how to install the first scripts and test them**, in plain language. Think “I’ve never done this before.”

---

## What You Are Building (ELI5)
You are making a **magic storage box** in Second Life. When you drop bundles into it, the box **reads their names/descriptions** and **stores those details inside itself** (linkset data). You can then **check that it worked**.

---

## What You Need
- A **box object** (a prim) in Second Life.
- The three scripts from `implementation-scripts.md`:
  - `bundle_indexer.lsl`
  - `bundle_menu.lsl`
  - `bundle_pricing.lsl`
- At least **one bundle object** to test.

---

## Step 1 — Create the Box
1. In Second Life, **rez a box** (build → create → click the ground).
2. **Right-click the box** → **Edit**.
3. In the Edit window, click the **Contents** tab.

**Why?** This is where you put scripts and inventory into the box.

---

## Step 2 — Add the Scripts
1. Create three new scripts in your inventory (or paste into new scripts):
   - `bundle_indexer.lsl`
   - `bundle_menu.lsl`
   - `bundle_pricing.lsl`
2. Copy the script code from `implementation-scripts.md` into each script.
3. Drag each script into the **Contents** tab of the box.

**What happens now?**
- The box now has a “brain” (Indexer) and “buttons” (Menu + Pricing).

---

## Step 3 — Add Test Bundles
1. Drag **one or more bundle objects** into the box’s Contents.
2. Make sure their **Description** contains:
   - `SUCCESSFUL_BUNDLE` (or `BOXED_BUNDLES`).

**Why?** The Indexer only records items with those keywords.

---

## Step 4 — Run the Indexer (Start)
1. **Touch the box**.
2. If you are the owner, you will see the **Owner Menu**.
3. Click **Start**.

**What happens now?**
- The Indexer scans all objects in the box.
- It stores any valid bundles in linkset data.

---

## Step 5 — Test That It Worked (Simple Test)
We want to confirm the box really stored the data. There are two easy ways:

### Option A — Quick Debug Script (Recommended)
Create a temporary script named `debug_read.lsl` and drop it into the box.

```lsl
// debug_read.lsl
// Prints the total count of valid bundles.

default
{
    state_entry()
    {
        string total = llLinksetDataRead("meta.total");
        llOwnerSay("Total valid bundles = " + total);
    }
}
```

1. Drop this script into the box.
2. It will immediately print a message to you:
   - Example: **“Total valid bundles = 3”**

If the number matches the bundles you dropped in, it worked.

### Option B — Use the Owner Menu (Visible Behavior)
1. Touch the box again.
2. Click **Reset**.
3. Click **Start**.

If it doesn’t error, the scan is working.

---

## Step 6 — Common Problems (Simple Fixes)
### Problem: It says 0 bundles
- Check bundle descriptions include `SUCCESSFUL_BUNDLE` or `BOXED_BUNDLES`.
- Check that the objects are inside the **Contents** of the box.

### Problem: It doesn’t show Owner Menu
- Make sure you are the owner of the box.
- Re-rez the box if you transferred ownership.

### Problem: Script errors
- Check you pasted the **full script** into each file.
- Make sure scripts are **not set to “No Script”** region-wide.

---

## Done ✅
If you can see a correct **“Total valid bundles”** message, you finished Step 1 successfully.

---

## Next (After Step 1)
- Add the **Menu + Pricing workflows** (already installed).
- Later, add HTTP export for automated stats.
