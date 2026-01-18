// ======================================================
// ROCKSTAR RANCH STAND TELEPORTER
// STRICT MODE – verified invariants
// ======================================================

string REQUIRED_DESC = "*Rockstar Ranch* Teleporter";

// Shared channel
integer CHANNEL;
integer LISTEN;

// Registry: [object_key, base_name]
list TELEPORTERS;
integer STRIDE = 2;

key sitter = NULL_KEY;
key pendingDest = NULL_KEY;

// ------------------------------------------------------
integer deriveChannel()
{
    return -((integer)("0x" +
        llGetSubString(
            llMD5String(llGetObjectDesc(), 0),
            0, 6
        )));
}

// ------------------------------------------------------
integer indexByKey(key k)
{
    integer i;
    for (i = 0; i < llGetListLength(TELEPORTERS); i += STRIDE)
        if (llList2Key(TELEPORTERS, i) == k)
            return i;
    return -1;
}

addTeleporter(key k, string name)
{
    if (indexByKey(k) == -1)
        TELEPORTERS += [k, name];
}

// ------------------------------------------------------
// Discovery (handshake, convergent)
// ------------------------------------------------------
broadcast()
{
    llRegionSay(
        CHANNEL,
        "REG|" + llGetObjectName() + "|" + (string)llGetKey()
    );
}

sendReg(key target)
{
    llRegionSayTo(
        target,
        CHANNEL,
        "REG|" + llGetObjectName() + "|" + (string)llGetKey()
    );
}

// ------------------------------------------------------
// Build menu with embedded keys
// ------------------------------------------------------
list buildMenu()
{
    list menu = [];
    list counts = [];
    integer i;

    for (i = 0; i < llGetListLength(TELEPORTERS); i += STRIDE)
    {
        key k = llList2Key(TELEPORTERS, i);
        string base = llList2String(TELEPORTERS, i + 1);

        integer idx = llListFindList(counts, [base]);
        string label;

        if (idx == -1)
        {
            counts += [base, 1];
            label = base;
        }
        else
        {
            integer n = llList2Integer(counts, idx + 1) + 1;
            counts = llListReplaceList(counts, [n], idx + 1, idx + 1);
            label = base + " (" + (string)n + ")";
        }

        menu += [label + "|" + (string)k];
    }
    return menu;
}

// ------------------------------------------------------
showMenu(key id)
{
    list raw = buildMenu();
    list buttons = [];
    integer i;

    for (i = 0; i < llGetListLength(raw); ++i)
    {
        string e = llList2String(raw, i);
        buttons += llGetSubString(e, 0, llSubStringIndex(e, "|") - 1);
    }

    if (!llGetListLength(buttons))
    {
        llOwnerSay("No other teleporters found.");
        return;
    }

    llDialog(id, "Teleport to:", buttons, CHANNEL);
}

// ------------------------------------------------------
default
{
    state_entry()
    {
        if (llGetObjectDesc() != REQUIRED_DESC)
            llOwnerSay("ERROR: Description must be exactly:\n" + REQUIRED_DESC);

        CHANNEL = deriveChannel();
        TELEPORTERS = [];
        pendingDest = NULL_KEY;

        llListenRemove(LISTEN);
        LISTEN = llListen(CHANNEL, "", NULL_KEY, "");

        llSitTarget(<0.0, 0.0, 0.01>, ZERO_ROTATION);

        llSetTimerEvent(5.0);
        broadcast();
    }

    on_rez(integer p) { llResetScript(); }

    timer() { broadcast(); }

    listen(integer c, string n, key id, string msg)
    {
        list p = llParseString2List(msg, ["|"], []);

        // Registration
        if (llList2String(p, 0) == "REG")
        {
            key obj = llList2Key(p, 2);
            if (obj != llGetKey())
            {
                addTeleporter(obj, llList2String(p, 1));
                sendReg(obj);
            }
            return;
        }

        if (id != sitter) return;

        // Menu selection → key
        list menu = buildMenu();
        integer i;
        for (i = 0; i < llGetListLength(menu); ++i)
        {
            string e = llList2String(menu, i);
            if (llGetSubString(e, 0, llSubStringIndex(e, "|") - 1) == msg)
            {
                pendingDest = (key)llGetSubString(
                    e,
                    llSubStringIndex(e, "|") + 1,
                    -1
                );
                llRequestPermissions(id, PERMISSION_TELEPORT);
                return;
            }
        }
    }

    changed(integer c)
    {
        if (c & CHANGED_LINK)
        {
            sitter = llAvatarOnSitTarget();
            if (sitter != NULL_KEY)
                showMenu(sitter);
            else
                pendingDest = NULL_KEY;
        }
    }

    run_time_permissions(integer perms)
    {
        if (!(perms & PERMISSION_TELEPORT)) return;
        if (sitter == NULL_KEY || pendingDest == NULL_KEY) return;

        // LIVE destination verification (same region)
        list d = llGetObjectDetails(pendingDest, [OBJECT_POS]);
        if (llGetListLength(d) != 1)
        {
            llOwnerSay("Teleport failed: destination not found.");
            return;
        }

        llTeleportAgent(
            sitter,
            llGetRegionName(),
            llList2Vector(d, 0),
            ZERO_VECTOR
        );
    }
}
