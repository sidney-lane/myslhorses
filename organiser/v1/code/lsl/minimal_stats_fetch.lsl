// minimal_stats_fetch.lsl
// Prints bundle name, owner, UUID (if available), and lineage URL.

string BUNDLE_URL = "https://amarettobreedables.com/bundleData.php?id=";
string HORSE_URL = "https://amarettobreedables.com/horseData.php?id=";

integer isValidBundle(string desc) {
    if (llSubStringIndex(desc, "SUCCESSFUL_BUNDLE") != -1) return TRUE;
    if (llSubStringIndex(desc, "BOXED_BUNDLES") != -1) return TRUE;
    return FALSE;
}

string extractUuidFromDesc(string desc) {
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
