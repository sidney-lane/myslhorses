// ======================================================
// ROCKSTAR RANCH STAND TELEPORTER
// STRICT MODE – verified invariants
// ======================================================

string REQUIRED_DESC = "*Rockstar Ranch* Teleporter";
integer DEBUG = TRUE;
integer OWNER_DEBUG_CHANNEL;

// Shared channel
integer CHANNEL;
integer LISTEN;

// Registry: [object_key, base_name]
list TELEPORTERS;
integer STRIDE = 2;

list MENU_MAP; // [button_label, object_key]
integer MENU_PAGE = 0;
integer PAGE_SIZE = 10;
integer OWNER_MENU = FALSE;
integer RENAME_PENDING = FALSE;
integer CONTROL_CHANNEL;
integer PARTICLE_ENABLED = FALSE;
integer DEBUG_ENABLED = TRUE;
integer PERM_ANIM = FALSE;

string OWNER_MENU_LABEL = "Owner Menu";
string OWNER_BACK_LABEL = "Back";
string OWNER_RENAME_LABEL = "Rename";
string OWNER_RESET_LABEL = "Reset Scripts";
string OWNER_STOP_LABEL = "Stop Script";
string OWNER_START_LABEL = "Start Script";
string OWNER_PARTICLE_LABEL = "Particles";
string OWNER_DEBUG_LABEL = "Debug";

key sitter = NULL_KEY;
key pendingDest = NULL_KEY;
key teleportingAvatar = NULL_KEY;
integer awaitingUnsit = FALSE;
float BROADCAST_INTERVAL = 5.0;
float TIMER_INTERVAL = 1.0;
float lastBroadcast = 0.0;
key lastDebugSitter = NULL_KEY;

integer debugLog(string message)
{
    if (DEBUG && DEBUG_ENABLED)
        llRegionSayTo(llGetOwner(), OWNER_DEBUG_CHANNEL, "[Teleporter] " + message);
    return TRUE;
}

integer debugOnce(key av, string message)
{
    if (DEBUG && DEBUG_ENABLED && av != NULL_KEY && av != lastDebugSitter)
    {
        llRegionSayTo(llGetOwner(), OWNER_DEBUG_CHANNEL, "[Teleporter] " + message);
        lastDebugSitter = av;
    }
    return TRUE;
}

integer updateParticles()
{
    if (PARTICLE_ENABLED)
    {
        llParticleSystem([
            PSYS_PART_FLAGS, PSYS_PART_INTERP_COLOR_MASK | PSYS_PART_INTERP_SCALE_MASK |
                PSYS_PART_EMISSIVE_MASK | PSYS_PART_WIND_MASK,
            PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE,
            PSYS_SRC_TEXTURE, "",
            PSYS_SRC_MAX_AGE, 0.0,
            PSYS_PART_MAX_AGE, 1.8,
            PSYS_PART_START_COLOR, <0.6, 0.9, 1.0>,
            PSYS_PART_END_COLOR, <0.2, 0.6, 1.0>,
            PSYS_PART_START_ALPHA, 0.7,
            PSYS_PART_END_ALPHA, 0.0,
            PSYS_PART_START_SCALE, <0.05, 0.05, 0.0>,
            PSYS_PART_END_SCALE, <0.2, 0.2, 0.0>,
            PSYS_SRC_ANGLE_BEGIN, 0.0,
            PSYS_SRC_ANGLE_END, 6.283185,
            PSYS_SRC_OMEGA, <0.0, 0.0, 2.8>,
            PSYS_SRC_ACCEL, <0.0, 0.0, 1.2>,
            PSYS_SRC_BURST_RATE, 0.03,
            PSYS_SRC_BURST_PART_COUNT, 6,
            PSYS_SRC_BURST_SPEED_MIN, 0.2,
            PSYS_SRC_BURST_SPEED_MAX, 0.6,
            PSYS_SRC_BURST_RADIUS, 0.2,
            PSYS_SRC_TARGET_KEY, llGetKey()
        ]);
    }
    else
    {
        llParticleSystem([]);
    }
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
    if (id == llGetOwner() && OWNER_MENU)
    {
        list ownerButtons = [
            OWNER_RENAME_LABEL,
            OWNER_RESET_LABEL,
            OWNER_STOP_LABEL,
            OWNER_START_LABEL,
            OWNER_PARTICLE_LABEL,
            OWNER_BACK_LABEL
        ];
        if (id == llGetCreator())
            ownerButtons = llListInsertList(
                ownerButtons,
                [OWNER_DEBUG_LABEL],
                llGetListLength(ownerButtons) - 1
            );

        llDialog(
            id,
            "Owner controls:",
            ownerButtons,
            CHANNEL
        );
        return TRUE;
    }

    list buttons = [];
    list lines = [];
    list counts = [];
    integer i;
    integer total = llGetListLength(TELEPORTERS);
    integer totalPages = (total + (STRIDE * PAGE_SIZE) - 1) / (STRIDE * PAGE_SIZE);
    integer start = MENU_PAGE * STRIDE * PAGE_SIZE;
    integer end = start + (STRIDE * PAGE_SIZE);

    if (totalPages < 1)
        totalPages = 1;

    for (i = start; i < total && i < end; i += STRIDE)
    {
        key k = llList2Key(TELEPORTERS, i);
        string base = llList2String(TELEPORTERS, i + 1);
        integer idx = llListFindList(counts, [base]);
        integer suffix = 1;
        string label = base;

        if (idx == -1)
        {
            counts += [base, 1];
        }
        else
        {
            suffix = llList2Integer(counts, idx + 1) + 1;
            counts = llListReplaceList(counts, [suffix], idx + 1, idx + 1);
            label = base + " (" + (string)suffix + ")";
        }

        if (llStringLength(label) > 23)
            label = llGetSubString(label, 0, 23);

        MENU_MAP += [label, k];
        buttons += [label];
    }

    if (!llGetListLength(buttons))
    {
        llOwnerSay("No other teleporters found.");
        return FALSE;
    }

    if (totalPages > 1)
    {
        buttons += ["Prev", "Next"];
        lines += [
            "Page " + (string)(MENU_PAGE + 1) + " of " + (string)totalPages
        ];
    }

    if (id == llGetOwner())
        buttons += [OWNER_MENU_LABEL];

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

    if (llGetAgentSize(teleportingAvatar) == ZERO_VECTOR)
        return FALSE;

    if (llGetAgentInfo(teleportingAvatar) & AGENT_SITTING)
        return FALSE;

    list d = llGetObjectDetails(pendingDest, [OBJECT_POS]);
    if (llGetListLength(d) != 1)
    {
        llOwnerSay("Teleport failed: destination not found.");
        debugOnce(
            teleportingAvatar,
            "Teleport failed. Destination key not found: " + (string)pendingDest
        );
        pendingDest = NULL_KEY;
        teleportingAvatar = NULL_KEY;
        awaitingUnsit = FALSE;
        return FALSE;
    }

    debugOnce(
        teleportingAvatar,
        "Teleport target key " + (string)pendingDest +
            " at " + (string)llList2Vector(d, 0)
    );

    llTeleportAgent(
        teleportingAvatar,
        "",
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
        OWNER_DEBUG_CHANNEL = (integer)"-777777";
        CONTROL_CHANNEL = CHANNEL - 1;
        PARTICLE_ENABLED = FALSE;
        DEBUG_ENABLED = TRUE;
        PERM_ANIM = FALSE;
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
        if (c == CONTROL_CHANNEL && id == llGetOwner() && RENAME_PENDING)
        {
            if (llStringLength(msg))
                llSetObjectName(msg);
            RENAME_PENDING = FALSE;
            OWNER_MENU = TRUE;
            showMenu(id);
            return;
        }

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

        if (msg == OWNER_MENU_LABEL && id == llGetOwner())
        {
            OWNER_MENU = TRUE;
            MENU_MAP = [];
            showMenu(id);
            return;
        }

        if (OWNER_MENU && id == llGetOwner())
        {
            if (msg == OWNER_BACK_LABEL)
            {
                OWNER_MENU = FALSE;
                MENU_MAP = [];
                showMenu(id);
                return;
            }
            if (msg == OWNER_PARTICLE_LABEL)
            {
                PARTICLE_ENABLED = !PARTICLE_ENABLED;
                updateParticles();
                showMenu(id);
                return;
            }
            if (msg == OWNER_DEBUG_LABEL && id == llGetCreator())
            {
                DEBUG_ENABLED = !DEBUG_ENABLED;
                showMenu(id);
                return;
            }
            if (msg == OWNER_RENAME_LABEL)
            {
                RENAME_PENDING = TRUE;
                llTextBox(id, "Enter new teleporter name:", CONTROL_CHANNEL);
                return;
            }
            if (msg == OWNER_RESET_LABEL)
            {
                llResetScript();
                return;
            }
            if (msg == OWNER_STOP_LABEL)
            {
                llSetScriptState(llGetScriptName(), FALSE);
                return;
            }
            if (msg == OWNER_START_LABEL)
            {
                llSetScriptState(llGetScriptName(), TRUE);
                return;
            }
        }

        integer idx = llListFindList(MENU_MAP, [msg]);
        if (msg == "Next")
        {
            MENU_PAGE += 1;
            MENU_MAP = [];
            showMenu(id);
            return;
        }
        if (msg == "Prev")
        {
            if (MENU_PAGE > 0)
                MENU_PAGE -= 1;
            MENU_MAP = [];
            showMenu(id);
            return;
        }
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
                MENU_PAGE = 0;
                OWNER_MENU = FALSE;
                debugOnce(
                    sitter,
                    "Avatar sat. Region=" + llGetRegionName() +
                        " Channel=" + (string)CHANNEL
                );
                llRequestPermissions(sitter, PERMISSION_TRIGGER_ANIMATION);
                broadcast();
                showMenu(sitter);
            }
            else
            {
                sitter = NULL_KEY;
                if (PERM_ANIM)
                {
                    llStopAnimation("teleporter_anim");
                    PERM_ANIM = FALSE;
                }
                if (awaitingUnsit)
                    performTeleport();
                else
                    pendingDest = NULL_KEY;
            }
        }
    }

    run_time_permissions(integer perms)
    {
        if (perms & PERMISSION_TRIGGER_ANIMATION)
        {
            PERM_ANIM = TRUE;
            llStartAnimation("teleporter_anim");
        }

        if (!(perms & PERMISSION_TELEPORT)) return;
        if (sitter == NULL_KEY || pendingDest == NULL_KEY) return;

        teleportingAvatar = sitter;
        awaitingUnsit = TRUE;
        llUnSit(sitter);
    }
}
