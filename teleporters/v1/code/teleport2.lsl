// ======================================================
// ROCKSTAR RANCH STAND TELEPORTER (STRICT, VERIFIED)
// ======================================================

string REQUIRED_DESC = "*Rockstar Ranch* Teleporter";

integer CHANNEL;
integer LISTEN;

// Registry: [object_key, display_name]
list TELEPORTERS;
integer STRIDE = 2;

key sitter = NULL_KEY;
key pendingDest = NULL_KEY;

// ------------------------------------------------------
integer deriveChannel()
{
    return -((integer)("0x" +
        llGetSubString(llMD5String(llGetObjectDesc(), 0), 0, 6)));
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
// Discovery
// ------------------------------------------------------
broadcast()
{
    llRegionSay(CHANNEL, "REG|" + llGetObjectName() + "|" + (string)llGetKey());
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
// Numbered menu (stable, no truncation issues)
// ------------------------------------------------------
showMenu(key id)
{
    list buttons = [];
    integer i;

    for (i = 0; i < llGetListLength(TELEPORTERS); i += STRIDE)
        buttons += [(string)((i / STRIDE) + 1)];

    if (!llGetListLength(buttons))
    {
        llOwnerSay("No other teleporters found.");
        return;
    }

    llDialog(
        id,
        "Teleport destinations:\n" +
        llDumpList2String(
            llList2ListStrided(TELEPORTERS, 1, -1, STRIDE),
            "\n"
        ),
        buttons,
        CHANNEL
    );
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

        llListenRemove(LISTEN);
        LISTEN = llListen(CHANNEL, "", NULL_KEY, "");

        llSitTarget(<0,0,0.01>, ZERO_ROTATION);

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

        integer sel = (integer)msg - 1;
        integer idx = sel * STRIDE;

        if (idx >= 0 && idx < llGetListLength(TELEPORTERS))
        {
            pendingDest = llList2Key(TELEPORTERS, idx);
            llUnSit(sitter);                // unsit first
            llRequestPermissions(            // REQUEST PERMISSION AGAIN
                sitter,
                PERMISSION_TELEPORT
            );
        }
    }

    changed(integer c)
    {
        if (c & CHANGED_LINK)
        {
            key av = llAvatarOnSitTarget();
            if (av != NULL_KEY)
            {
                sitter = av;
                showMenu(av);
            }
        }
    }

    run_time_permissions(integer perms)
    {
        if (!(perms & PERMISSION_TELEPORT)) return;
        if (sitter == NULL_KEY || pendingDest == NULL_KEY) return;

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

        // cleanup
        sitter = NULL_KEY;
        pendingDest = NULL_KEY;
    }
}
