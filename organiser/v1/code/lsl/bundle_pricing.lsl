// bundle_pricing.lsl
// Set per-bundle prices and persist to linkset data.

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

        string uuid = llList2String(bundleKeys, 0);
        storePrice(uuid, message);
        llOwnerSay("Price set for " + getBundleName(uuid));
    }
}
