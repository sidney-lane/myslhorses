// bundle_indexer.lsl
// Scans inventory, filters bundles, writes metadata to linkset data.

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
