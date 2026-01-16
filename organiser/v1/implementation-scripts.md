# Bundle Viewer/Vendor — Implementation Guide (LSL First)

## Architecture Overview
This implementation follows the **Option B (Modular Multi-Script)** architecture recommended in the technical architecture doc, with a clear upgrade path to **Option C (Hybrid External Service)**. It starts with in-world LSL scripts (Indexer + Menu/UI + Pricing) and then adds optional HTTP export for automated stats and web indexing.

**Core scripts (start here):**
1. **Indexer**: Inventory scanning, filtering, linkset storage.
2. **Menu/UI**: Owner/general menus, start/stop/reset, notecard/landmark delivery.
3. **Pricing**: Price input workflows (Price One / Price All).

---

## LSL Scripts (Start Here)
> Drop these scripts into the same root prim (box). The scripts communicate via `llMessageLinked`.

### 1) Indexer Script (Inventory Scanner + Linkset Data)
**Script name:** `bundle_indexer.lsl`

```lsl
// bundle_indexer.lsl
// Purpose: Scan inventory, filter bundles, and store metadata in linkset data.

integer IDX_RUNNING = TRUE;
string META_TOTAL = "meta.total";
string META_OWNER_ID = "meta.owner.id";
string META_OWNER_NAME = "meta.owner.name";
string META_SLURL = "meta.slurl";

string KEY_PREFIX = "obj.";

integer isValidBundle(string desc) {
    if (llSubStringIndex(desc, "SUCCESSFUL_BUNDLE") != -1) return TRUE;
    if (llSubStringIndex(desc, "BOXED_BUNDLES") != -1) return TRUE;
    return FALSE;
}

string buildSlurl() {
    vector pos = llGetPos();
    return "secondlife://" + llGetRegionName() + "/" +
        (string)llRound(pos.x) + "/" + (string)llRound(pos.y) + "/" + (string)llRound(pos.z);
}

clearObjectKeys() {
    list keys = llLinksetDataListKeys(KEY_PREFIX + "*");
    integer i;
    for (i = 0; i < llGetListLength(keys); i++) {
        llLinksetDataDelete(llList2String(keys, i));
    }
}

writeMeta() {
    key ownerId = llGetOwner();
    llLinksetDataWrite(META_OWNER_ID, (string)ownerId);
    llLinksetDataWrite(META_OWNER_NAME, llKey2Name(ownerId));
    llLinksetDataWrite(META_SLURL, buildSlurl());
}

scanInventory() {
    if (!IDX_RUNNING) return;

    integer count = llGetInventoryNumber(INVENTORY_OBJECT);
    integer valid = 0;
    integer i;

    clearObjectKeys();

    for (i = 0; i < count; i++) {
        string name = llGetInventoryName(INVENTORY_OBJECT, i);
        string desc = llGetInventoryDesc(name);
        if (!isValidBundle(desc)) {
            jump continue_loop;
        }

        key itemKey = llGetInventoryKey(name);
        if (itemKey == NULL_KEY) {
            // Skip items that do not expose keys (permissions/limits).
            jump continue_loop;
        }

        string base = KEY_PREFIX + (string)itemKey + ".";
        llLinksetDataWrite(base + "name", name);
        llLinksetDataWrite(base + "desc", desc);
        llLinksetDataWrite(base + "owner", llKey2Name(llGetOwner()));
        // Price/stats are written by other scripts when available.

        valid++;
@continue_loop;
    }

    llLinksetDataWrite(META_TOTAL, (string)valid);
    writeMeta();
}

resetAll() {
    llLinksetDataWrite(META_TOTAL, "0");
    llLinksetDataDelete(META_OWNER_ID);
    llLinksetDataDelete(META_OWNER_NAME);
    llLinksetDataDelete(META_SLURL);
    clearObjectKeys();
}

// Linked message protocol
// num=100: START
// num=101: STOP
// num=102: RESET
// num=103: REFRESH

link_command(integer num) {
    if (num == 100) {
        IDX_RUNNING = TRUE;
        scanInventory();
    } else if (num == 101) {
        IDX_RUNNING = FALSE;
    } else if (num == 102) {
        resetAll();
        scanInventory();
    } else if (num == 103) {
        scanInventory();
    }
}

default
{
    state_entry()
    {
        scanInventory();
    }

    on_rez(integer start_param)
    {
        scanInventory();
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY) {
            scanInventory();
        }
    }

    link_message(integer sender, integer num, string msg, key id)
    {
        link_command(num);
    }
}
```

**Implementation notes**
- Uses `llGetInventoryKey()` for UUID; if `NULL_KEY`, it skips (permissions edge case).
- Stores metadata under `obj.<uuid>.*` with `meta.*` globals.
- Will re-scan on inventory changes automatically.

---

### 2) Menu/UI Script (Owner + General Menus)
**Script name:** `bundle_menu.lsl`

```lsl
// bundle_menu.lsl
// Purpose: Owner/general menu, controls indexer via linked messages.

integer MENU_CHANNEL = -9999;
integer listenHandle;
key lastUser;

list OWNER_MENU = ["Start", "Stop", "Reset", "Name", "Text On", "Text Off", "Set Logo", "Help", "Add Price"];
list GENERAL_MENU = ["Stats", "Landmark"];

showMenu(key user) {
    lastUser = user;
    if (listenHandle) llListenRemove(listenHandle);
    listenHandle = llListen(MENU_CHANNEL, "", user, "");

    if (user == llGetOwner()) {
        llDialog(user, "Bundle Viewer — Owner Menu", OWNER_MENU, MENU_CHANNEL);
    } else {
        llDialog(user, "Bundle Viewer — Menu", GENERAL_MENU, MENU_CHANNEL);
    }
}

sendToIndexer(integer num) {
    llMessageLinked(LINK_SET, num, "", NULL_KEY);
}

default
{
    touch_start(integer total_number)
    {
        key user = llDetectedKey(0);
        showMenu(user);
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel != MENU_CHANNEL) return;

        if (id == llGetOwner()) {
            if (message == "Start") sendToIndexer(100);
            else if (message == "Stop") sendToIndexer(101);
            else if (message == "Reset") sendToIndexer(102);
            else if (message == "Name") llOwnerSay("Rename the box manually or add a name setter here.");
            else if (message == "Text On") llSetText("Bundle Viewer", <1,1,1>, 1.0);
            else if (message == "Text Off") llSetText("", <1,1,1>, 0.0);
            else if (message == "Set Logo") llOwnerSay("Set Logo: add texture UUID handling here.");
            else if (message == "Help") llGiveInventory(id, "Help Notecard");
            else if (message == "Add Price") {
                llMessageLinked(LINK_SET, 200, "", id);
            }
        } else {
            if (message == "Stats") llGiveInventory(id, "Stats Notecard");
            else if (message == "Landmark") llGiveInventory(id, "Landmark");
        }
    }
}
```

**Implementation notes**
- Owner-only options are gated by `llGetOwner()`.
- “Help”, “Stats”, and “Landmark” require inventory items with matching names.
- Add a name setter or custom logo handler if needed.

---

### 3) Pricing Script (Price One / Price All)
**Script name:** `bundle_pricing.lsl`

```lsl
// bundle_pricing.lsl
// Purpose: Set per-bundle prices and persist to linkset data.

integer PRICE_CHANNEL = -8888;
integer listenHandle;
key activeUser;
list bundleKeys;
integer modeAll = FALSE;
integer indexPos = 0;

string KEY_PREFIX = "obj.";

list getBundleKeys() {
    list keys = llLinksetDataListKeys(KEY_PREFIX + "*.name");
    list uuids;
    integer i;
    for (i = 0; i < llGetListLength(keys); i++) {
        string keyName = llList2String(keys, i);
        list parts = llParseString2List(keyName, ["."], []);
        if (llGetListLength(parts) >= 3) {
            uuids += llList2String(parts, 1);
        }
    }
    return llList2List(uuids, 0, -1);
}

string getBundleName(string uuid) {
    return llLinksetDataRead(KEY_PREFIX + uuid + ".name");
}

promptPriceSingle(string uuid) {
    string name = getBundleName(uuid);
    if (listenHandle) llListenRemove(listenHandle);
    listenHandle = llListen(PRICE_CHANNEL, "", activeUser, "");
    llTextBox(activeUser, "Enter price for: " + name, PRICE_CHANNEL);
}

promptPriceAll() {
    if (indexPos >= llGetListLength(bundleKeys)) {
        llOwnerSay("Price All complete.");
        return;
    }
    string uuid = llList2String(bundleKeys, indexPos);
    promptPriceSingle(uuid);
}

storePrice(string uuid, string input) {
    integer price = (integer)input;
    if (price < 0) price = 0;
    llLinksetDataWrite(KEY_PREFIX + uuid + ".price", (string)price);
}

link_command(integer num, key user) {
    if (num != 200) return;
    activeUser = user;
    bundleKeys = getBundleKeys();
    if (llGetListLength(bundleKeys) == 0) {
        llOwnerSay("No bundles found to price.");
        return;
    }

    modeAll = FALSE;
    indexPos = 0;
    llDialog(activeUser, "Pricing Options", ["Price One", "Price All"], PRICE_CHANNEL);
}

default
{
    link_message(integer sender, integer num, string msg, key id)
    {
        link_command(num, id);
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel != PRICE_CHANNEL) return;
        if (id != activeUser) return;

        if (message == "Price One") {
            modeAll = FALSE;
            bundleKeys = getBundleKeys();
            if (llGetListLength(bundleKeys) > 0) {
                string uuid = llList2String(bundleKeys, 0);
                promptPriceSingle(uuid);
            }
            return;
        }
        if (message == "Price All") {
            modeAll = TRUE;
            bundleKeys = getBundleKeys();
            indexPos = 0;
            promptPriceAll();
            return;
        }

        if (modeAll) {
            string uuidAll = llList2String(bundleKeys, indexPos);
            storePrice(uuidAll, message);
            indexPos++;
            promptPriceAll();
            return;
        }

        // Price One: set for the first bundle in list
        string uuid = llList2String(bundleKeys, 0);
        storePrice(uuid, message);
        llOwnerSay("Price set for " + getBundleName(uuid));
    }
}
```

**Implementation notes**
- Uses `llTextBox` for numeric input.
- `Price One` uses the first bundle in list; expand to prompt selection in future.
- `Price All` iterates over all bundles.

---

## Step-by-Step Implementation Instructions

### Step 1 — Create the Box
1. Create a root prim box.
2. Drop in the 3 scripts above.
3. Add required inventory items: `Help Notecard`, `Stats Notecard`, `Landmark`.

### Step 2 — Load Bundles
1. Drop bundle objects into the box inventory.
2. Confirm indexing by clicking the box and selecting **Start**.

### Step 3 — Validate Linkset Data
1. Use a debug script (optional) to read `meta.total`.
2. Confirm keys like `obj.<uuid>.name` and `obj.<uuid>.desc` are present.

### Step 4 — Pricing
1. Owner touches the box → **Add Price**.
2. Choose **Price One** or **Price All**.

### Step 5 — Optional External Automation (Phase 3+)
1. Add a new script or extend `bundle_indexer.lsl` to `llHTTPRequest` metadata on changes.
2. Send JSON payload `{ uuid, name, desc, owner, price, slurl }`.
3. Use Cloudflare or Supabase to auto-enrich and store stats.

---

## Optional HTTP Export (Stub Example)
Use this stub in `bundle_indexer.lsl` when you move to Option C:

```lsl
string API_URL = "https://your-endpoint.example/ingest";

sendMetadata(string uuid, string name, string desc, string owner, string slurl) {
    string body = "{\"uuid\":\"" + uuid + "\",\"name\":\"" + name + "\",\"desc\":\"" + desc + "\",\"owner\":\"" + owner + "\",\"slurl\":\"" + slurl + "\"}";
    llHTTPRequest(API_URL, [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/json"], body);
}
```

---

## Known Constraints & Follow-Ups
- **Inventory UUIDs**: `llGetInventoryKey` may return `NULL_KEY` for some items. Document in Stage 0 tests.
- **Linkset Capacity**: store minimal data; move stats to the external backend.
- **Menu UX**: implement bundle selection for `Price One` if needed.

---

## Next Actions
1. Run Stage 0 feasibility tests (UUID access + linkset limits).
2. Deploy the three scripts and validate basic indexing.
3. Add HTTP export if you want automated stats and web search.
