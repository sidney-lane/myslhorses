// ======================================================
// ROCKSTAR RANCH STAND TELEPORTER
// STRICT MODE – verified invariants
// ======================================================

string REQUIRED_DESC = "*Rockstar Ranch* Teleporter";
integer DEBUG = TRUE;

// Shared channel
integer CHANNEL;
integer LISTEN;

// Registry: [object_key, base_name]
list TELEPORTERS;
integer STRIDE = 2;

list MENU_MAP; // [button_label, object_key]

key sitter = NULL_KEY;
key pendingDest = NULL_KEY;
key teleportingAvatar = NULL_KEY;
integer awaitingUnsit = FALSE;
float BROADCAST_INTERVAL = 5.0;
float TIMER_INTERVAL = 1.0;
float lastBroadcast = 0.0;

integer debugLog(string message)
{
    if (DEBUG)
        llOwnerSay("[Teleporter] " + message);
    return TRUE;
}

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

integer addTeleporter(key k, string name)
{
    if (indexByKey(k) == -1)
    {
        TELEPORTERS += [k, name];
    }
    return TRUE;
}

// ------------------------------------------------------
// Discovery (handshake, convergent)
// ------------------------------------------------------
integer broadcast()
{
    llRegionSay(
        CHANNEL,
        "REG|" + llGetObjectName() + "|" + (string)llGetKey()
    );
    return TRUE;
}

integer sendReg(key target)
{
    llRegionSayTo(
        target,
        CHANNEL,
        "REG|" + llGetObjectName() + "|" + (string)llGetKey()
    );
    return TRUE;
}

// ------------------------------------------------------
// Build menu with embedded keys
// ------------------------------------------------------
integer showMenu(key id)
{
    list buttons = [];
    list lines = [];
    integer i;
    integer total = llGetListLength(TELEPORTERS);

    for (i = 0; i < total; i += STRIDE)
    {
        key k = llList2Key(TELEPORTERS, i);
        string base = llList2String(TELEPORTERS, i + 1);
        integer number = llGetListLength(buttons) + 1;
        string label = (string)number;

        MENU_MAP += [label, k];
        buttons += [label];
        lines += [label + ". " + base];
    }

    if (!llGetListLength(buttons))
    {
        llOwnerSay("No other teleporters found.");
        return FALSE;
    }

    if (llGetListLength(buttons) > 12)
    {
        llOwnerSay("Too many teleporters for a single menu (max 12).");
        return FALSE;
    }

    llDialog(
        id,
        "Teleport destinations:\n" + llDumpList2String(lines, "\n"),
        buttons,
        CHANNEL
    );
    return TRUE;
}

// ------------------------------------------------------
integer performTeleport()
{
    if (teleportingAvatar == NULL_KEY || pendingDest == NULL_KEY)
        return FALSE;

    if (llAvatarOnSitTarget() == teleportingAvatar)
        return FALSE;

    list d = llGetObjectDetails(pendingDest, [OBJECT_POS]);
    if (llGetListLength(d) != 1)
    {
        llOwnerSay("Teleport failed: destination not found.");
        debugLog("Teleport failed. Destination key not found: " + (string)pendingDest);
        pendingDest = NULL_KEY;
        teleportingAvatar = NULL_KEY;
        awaitingUnsit = FALSE;
        return FALSE;
    }

    debugLog("Teleporting to key " + (string)pendingDest +
        " at " + (string)llList2Vector(d, 0));

    llTeleportAgent(
        teleportingAvatar,
        llGetRegionName(),
        llList2Vector(d, 0),
        ZERO_VECTOR
    );

    pendingDest = NULL_KEY;
    teleportingAvatar = NULL_KEY;
    awaitingUnsit = FALSE;
    return TRUE;
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
        MENU_MAP = [];
        pendingDest = NULL_KEY;
        teleportingAvatar = NULL_KEY;
        awaitingUnsit = FALSE;
        lastBroadcast = llGetTime();

        llListenRemove(LISTEN);
        LISTEN = llListen(CHANNEL, "", NULL_KEY, "");

        llSitTarget(<0.0, 0.0, 0.01>, ZERO_ROTATION);

        llSetTimerEvent(TIMER_INTERVAL);
        broadcast();
    }

    on_rez(integer p) { llResetScript(); }

    timer()
    {
        if ((llGetTime() - lastBroadcast) >= BROADCAST_INTERVAL)
        {
            broadcast();
            lastBroadcast = llGetTime();
        }

        if (awaitingUnsit)
            performTeleport();
    }

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

        integer idx = llListFindList(MENU_MAP, [msg]);
        if (idx != -1)
        {
            key target = llList2Key(MENU_MAP, idx + 1);
            if (llGetListLength(llGetObjectDetails(target, [OBJECT_POS])) != 1)
            {
                llOwnerSay("Destination unavailable. Rebuilding menu.");
                pendingDest = NULL_KEY;
                MENU_MAP = [];
                showMenu(id);
                return;
            }

            pendingDest = target;
            llRequestPermissions(id, PERMISSION_TELEPORT);
        }
    }

    changed(integer c)
    {
        if (c & CHANGED_LINK)
        {
            key current = llAvatarOnSitTarget();
            if (current != NULL_KEY)
            {
                sitter = current;
                MENU_MAP = [];
                broadcast();
                showMenu(sitter);
            }
            else
            {
                sitter = NULL_KEY;
                if (awaitingUnsit)
                    performTeleport();
                else
                    pendingDest = NULL_KEY;
            }
        }
    }

    run_time_permissions(integer perms)
    {
        if (!(perms & PERMISSION_TELEPORT)) return;
        if (sitter == NULL_KEY || pendingDest == NULL_KEY) return;

        teleportingAvatar = sitter;
        awaitingUnsit = TRUE;
        llUnSit(sitter);
    }
}
