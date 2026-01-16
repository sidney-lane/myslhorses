// bundle_menu.lsl
// Owner/general menu, controls indexer via linked messages.

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
