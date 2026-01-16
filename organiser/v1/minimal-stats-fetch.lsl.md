# Minimal LSL Script — Print Amaretto Lineage URL + Bundle Metadata

Use this **single script** in a box to **print the stats URL** for each valid bundle and show the **name, owner, and UUID**. This is a minimal feasibility check before building the full system. If the UUID is not available via `llGetInventoryKey` (common for no-copy/no-mod items), the script logs a warning so you can verify whether the UUID is embedded in the description and parse it instead.

```lsl
// minimal_stats_fetch.lsl
// Drop this into a box. It prints bundle name, owner, UUID, and the lineage URL.

string BUNDLE_URL = "https://amarettobreedables.com/bundleData.php?id=";
string HORSE_URL = "https://amarettobreedables.com/horseData.php?id=";

integer isValidBundle(string desc) {
    if (llSubStringIndex(desc, "SUCCESSFUL_BUNDLE") != -1) return TRUE;
    if (llSubStringIndex(desc, "BOXED_BUNDLES") != -1) return TRUE;
    return FALSE;
}

string extractUuidFromDesc(string desc) {
    // Expected format example:
    // SUCCESSFUL_BUNDLE:<uuid>!963!0!2!159!0!0!0!0!0!0!0!0!0:NULL:6.01
    integer start = llSubStringIndex(desc, "SUCCESSFUL_BUNDLE:");
    if (start == -1) return "";
    start += llStringLength("SUCCESSFUL_BUNDLE:");
    integer end = llSubStringIndex(desc, "!");
    if (end == -1 || end <= start) return "";
    return llGetSubString(desc, start, end - 1);
}

default
{
    state_entry()
    {
        integer count = llGetInventoryNumber(INVENTORY_OBJECT);
        integer i;

        llOwnerSay("Found " + (string)count + " inventory objects.");

        for (i = 0; i < count; i++) {
            string name = llGetInventoryName(INVENTORY_OBJECT, i);
            string desc = llGetInventoryDesc(name);

            if (!isValidBundle(desc)) {
                jump continue_loop;
            }

            key itemKey = llGetInventoryKey(name);
            if (itemKey == NULL_KEY) {
                llOwnerSay("UUID not available for: " + name);
                llOwnerSay("Desc (check for embedded UUID): " + desc);
                string parsedUuid = extractUuidFromDesc(desc);
                if (parsedUuid != "") {
                    llOwnerSay("Parsed UUID from description: " + parsedUuid);
                    llOwnerSay("Bundle URL: " + BUNDLE_URL + parsedUuid);
                    llOwnerSay("Horse URL (if needed): " + HORSE_URL + parsedUuid);
                }
                jump continue_loop;
            }

            string ownerName = llKey2Name(llGetOwner());

            llOwnerSay("Bundle Name: " + name);
            llOwnerSay("Owner Name: " + ownerName);
            llOwnerSay("Bundle UUID: " + (string)itemKey);
            llOwnerSay("Bundle URL: " + BUNDLE_URL + (string)itemKey);
            llOwnerSay("Horse URL (if needed): " + HORSE_URL + (string)itemKey);

@continue_loop;
        }
    }
}
```

## How to Use
1. Create a box and open **Contents**.
2. Paste the script into a new script named `minimal_stats_fetch.lsl`.
3. Drop bundles into the box contents.
4. Reset the script or re-rez the box.
5. Read the owner chat output — it prints the **URL to test** plus **name/owner/UUID**.

## What This Proves
- **UUID availability** from `llGetInventoryKey`.
- **Lineage URL format** for the Amaretto site.
- **Inventory parsing works** for `SUCCESSFUL_BUNDLE` or `BOXED_BUNDLES`.

## Description Format Notes (From Verified Bundle)
You shared a verified description like:\n
```\nSUCCESSFUL_BUNDLE:60211112-eaa0-668a-567b-6e8d93e1515a!963!0!2!159!0!0!0!0!0!0!0!0!0:NULL:6.01\n```\n
This confirms the UUID is **embedded right after `SUCCESSFUL_BUNDLE:`** and before the first `!`. The parser above extracts that UUID correctly.

The bundle API payload format you provided:\n
```\nSUCCESSFUL_BUNDLE:<uuid>!164!0!1!5!0!0!1!0!0!6!0!0!4:NULL:7.0\nSTATUS:key!breed!mane!tail!eye!gleam!hairgleam!luster!hairluster!gloom!hairgloom!opal!hairopal!branding:RSVD:Version\n```\n
This tells us we can parse the UUID from the **description string** even when `llGetInventoryKey` is `NULL_KEY`. We can later extend the script to parse the trait fields from this encoded string if needed.

## If You See “UUID not available”
This usually means the inventory item is **no-copy/no-mod** and LSL cannot access its asset key. In that case you have two options:
1. **Parse the UUID from the description** if Amaretto embeds it there (some bundles do).  
2. **Use an external/manual step** to map bundle names to UUIDs, then load those into the backend.  

If you can confirm the UUID is present in the description, we can add a small parser to extract it and proceed with the lineage URL fetch.
