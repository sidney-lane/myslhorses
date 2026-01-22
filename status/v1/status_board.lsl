// Status Board v1 Script
// Implements build steps for hover text, parsing, menus, media refresh, and backend sync.

integer MAX_HORSES = 15;
integer SCAN_INTERVAL = 60;
integer MENU_CHANNEL = -90001;
integer listenHandle;

integer PERM_OWNER = 0;
integer PERM_GROUP = 1;
integer PERM_OPEN = 2;

integer gRunning = TRUE;
integer gHoverEnabled = TRUE;
integer gPermissions = 0;
integer gPendingRangeInput = FALSE;

float gRangeMeters = 10.0;
string gBoardId = "pod-01";
string gBackendUrl = "";
string gLastMediaUrl = "";

list gHorseKeys = [];
list gHorseNames = [];
list gHorseRaw = [];

list gColorNames = [
    "White", "Red", "Green", "Blue",
    "Yellow", "Cyan", "Magenta", "Orange"
];
list gColors = [
    <1.0, 1.0, 1.0>,
    <1.0, 0.2, 0.2>,
    <0.2, 1.0, 0.2>,
    <0.2, 0.4, 1.0>,
    <1.0, 1.0, 0.2>,
    <0.2, 1.0, 1.0>,
    <1.0, 0.2, 1.0>,
    <1.0, 0.6, 0.2>
];
integer gColorIndex = 0;
integer MAX_HOVER_LINE_CHARS = 80;

string truncateName(string name, integer maxLen)
{
    integer nameLen = llStringLength(name);
    if (nameLen <= maxLen)
    {
        return name;
    }
    if (maxLen <= 3)
    {
        return llGetSubString(name, 0, maxLen - 1);
    }
    return llGetSubString(name, 0, maxLen - 4) + "...";
}

list buildStatusLines(string name, integer ageDays, integer gender, integer pregval, integer fervor)
{
    string genderLabel = "U";
    if (gender == 1)
    {
        genderLabel = "M";
    }
    else if (gender == 2)
    {
        genderLabel = "F";
    }

    string suffix = " " + genderLabel + " " + (string)ageDays + "d";
    integer maxNameLen = MAX_HOVER_LINE_CHARS - llStringLength(suffix);
    if (maxNameLen < 1)
    {
        maxNameLen = 1;
    }
    string safeName = truncateName(name, maxNameLen);
    string line1 = safeName + suffix;
    string line2 = "";
    if (ageDays < 7)
    {
        integer remainingDays = 7 - ageDays;
        line2 = "Birth + " + (string)remainingDays + "d to 7d";
        return [line1, line2];
    }

    if (pregval > 0)
    {
        line2 = "Pregnant (" + (string)pregval + "%)";
        return [line1, line2];
    }
    if (fervor < 100)
    {
        line2 = "Fervor " + (string)fervor + "%";
        return [line1, line2];
    }

    line2 = "Recovery";
    return [line1, line2];
}

list parseHorseApi(string raw, string name)
{
    list fields = llParseString2List(raw, [":"], []);
    if (llGetListLength(fields) < 12)
    {
        llOwnerSay("[BUILD STEP 2] Validation failed for " + name + ": invalid field count");
        return [];
    }

    string horseKey = llList2String(fields, 0);
    integer age = (integer)llList2String(fields, 2);
    integer fervor = (integer)llList2String(fields, 5);
    integer gender = (integer)llList2String(fields, 7);
    integer pregval = (integer)llList2String(fields, 9);

    llOwnerSay(
        "[BUILD STEP 2] Parsed horse " + horseKey +
        " name=" + name +
        " status=age:" + (string)age +
        " gender=" + (string)gender
    );

    return [horseKey, name, age, gender, pregval, fervor, raw];
}

string buildHoverText(list entries)
{
    integer count = llGetListLength(entries);
    integer i = 0;
    list lines = [];
    while (i < count)
    {
        list entry = llList2List(entries, i, i);
        string line = llList2String(entry, 0);
        lines += [line];
        i += 1;
    }
    return llDumpList2String(lines, "\n");
}

persistConfig()
{
    string config = llJsonSetValue("{}", ["board_id"], gBoardId);
    config = llJsonSetValue(config, ["range_m"], (string)gRangeMeters);
    config = llJsonSetValue(config, ["permissions"], (string)gPermissions);
    config = llJsonSetValue(config, ["color_index"], (string)gColorIndex);
    config = llJsonSetValue(config, ["media_url"], gLastMediaUrl);
    llSetObjectDesc(config);
}

loadConfig()
{
    string config = llGetObjectDesc();
    if (llJsonValueType(config, ["board_id"]) != JSON_INVALID)
    {
        gBoardId = llJsonGetValue(config, ["board_id"]);
    }
    if (llJsonValueType(config, ["range_m"]) != JSON_INVALID)
    {
        gRangeMeters = (float)llJsonGetValue(config, ["range_m"]);
    }
    if (llJsonValueType(config, ["permissions"]) != JSON_INVALID)
    {
        gPermissions = (integer)llJsonGetValue(config, ["permissions"]);
    }
    if (llJsonValueType(config, ["color_index"]) != JSON_INVALID)
    {
        gColorIndex = (integer)llJsonGetValue(config, ["color_index"]);
    }
    if (llJsonValueType(config, ["media_url"]) != JSON_INVALID)
    {
        gLastMediaUrl = llJsonGetValue(config, ["media_url"]);
    }
}

integer hasPermission(key agent)
{
    if (gPermissions == PERM_OPEN)
    {
        return TRUE;
    }
    if (gPermissions == PERM_GROUP)
    {
        return llSameGroup(agent);
    }
    return (agent == llGetOwner());
}

showMenu(key agent)
{
    if (!hasPermission(agent))
    {
        return;
    }

    list buttons = [
        "Refresh",
        "Toggle Hover",
        "Start",
        "Stop",
        "Reset",
        "Set Range",
        "Permissions",
        "Color"
    ];
    if (listenHandle)
    {
        llListenRemove(listenHandle);
    }
    listenHandle = llListen(MENU_CHANNEL, "", agent, "");
    llDialog(agent, "Status Board Menu", buttons, MENU_CHANNEL);
    llOwnerSay("[BUILD STEP 3] Menu displayed");
}

handleMenuSelection(key agent, string message)
{
    llOwnerSay("[BUILD STEP 3] Menu option selected: " + message);

    if (message == "Refresh")
    {
        llSensor("", NULL_KEY, ACTIVE | PASSIVE, gRangeMeters, PI);
    }
    else if (message == "Toggle Hover")
    {
        gHoverEnabled = !gHoverEnabled;
        if (!gHoverEnabled)
        {
            llSetText("", <1.0, 1.0, 1.0>, 1.0);
        }
    }
    else if (message == "Start")
    {
        gRunning = TRUE;
        llSetTimerEvent((float)SCAN_INTERVAL);
    }
    else if (message == "Stop")
    {
        gRunning = FALSE;
        llSetTimerEvent(0.0);
    }
    else if (message == "Reset")
    {
        llResetScript();
    }
    else if (message == "Set Range")
    {
        gPendingRangeInput = TRUE;
        llTextBox(agent, "Enter range (1-15m):", MENU_CHANNEL);
    }
    else if (message == "Permissions")
    {
        gPermissions = (gPermissions + 1) % 3;
        persistConfig();
    }
    else if (message == "Color")
    {
        gColorIndex = (gColorIndex + 1) % llGetListLength(gColors);
        persistConfig();
    }
}

updateHoverText()
{
    if (!gHoverEnabled)
    {
        return;
    }

    list statusLines = [];
    integer i = 0;
    integer count = llGetListLength(gHorseKeys);
    while (i < count)
    {
        string horseKey = llList2String(gHorseKeys, i);
        string horseName = llList2String(gHorseNames, i);
        string raw = llList2String(gHorseRaw, i);
        list parsed = parseHorseApi(raw, horseName);
        if (llGetListLength(parsed) > 0)
        {
            integer age = llList2Integer(parsed, 2);
            integer gender = llList2Integer(parsed, 3);
            integer pregval = llList2Integer(parsed, 4);
            integer fervor = llList2Integer(parsed, 5);
            list lines = buildStatusLines(horseName, age, gender, pregval, fervor);
            statusLines += lines;
            llOwnerSay("[BUILD STEP 1] Hover text updated for " + horseKey);
        }
        i += 1;
    }

    string combined = llDumpList2String(statusLines, "\n");
    llSetText(combined, llList2Vector(gColors, gColorIndex), 1.0);
}

refreshMedia()
{
    if (gLastMediaUrl == "")
    {
        return;
    }

    integer face = 0;
    list params = [
        PRIM_MEDIA_CURRENT_URL, gLastMediaUrl,
        PRIM_MEDIA_HOME_URL, gLastMediaUrl,
        PRIM_MEDIA_AUTO_PLAY, TRUE,
        PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_OWNER
    ];
    llSetPrimMediaParams(face, params);

    integer i = 0;
    integer count = llGetListLength(gHorseKeys);
    while (i < count)
    {
        string horseKey = llList2String(gHorseKeys, i);
        llOwnerSay("[BUILD STEP 4] Media refreshed for " + horseKey + ": " + gLastMediaUrl);
        i += 1;
    }
}

backendSync()
{
    if (gBackendUrl == "")
    {
        return;
    }

    llOwnerSay("[BUILD STEP 5] Backend sync শুরু");

    list horses = [];
    integer i = 0;
    integer count = llGetListLength(gHorseKeys);
    while (i < count)
    {
        string horseKey = llList2String(gHorseKeys, i);
        string horseName = llList2String(gHorseNames, i);
        string raw = llList2String(gHorseRaw, i);
        list parsed = parseHorseApi(raw, horseName);
        if (llGetListLength(parsed) > 0)
        {
            integer age = llList2Integer(parsed, 2);
            integer gender = llList2Integer(parsed, 3);
            integer pregval = llList2Integer(parsed, 4);
            integer fervor = llList2Integer(parsed, 5);
            string horseJson = llJsonSetValue("{}", ["horse_key"], horseKey);
            horseJson = llJsonSetValue(horseJson, ["name"], horseName);
            horseJson = llJsonSetValue(horseJson, ["age_days"], (string)age);
            horseJson = llJsonSetValue(horseJson, ["gender"], (string)gender);
            horseJson = llJsonSetValue(horseJson, ["pregval"], (string)pregval);
            horseJson = llJsonSetValue(horseJson, ["fervor"], (string)fervor);
            horseJson = llJsonSetValue(horseJson, ["raw"], raw);
            horses += [horseJson];
        }
        i += 1;
    }

    string payload = llJsonSetValue("{}", ["board_id"], gBoardId);
    payload = llJsonSetValue(payload, ["owner_key"], (string)llGetOwner());
    payload = llJsonSetValue(payload, ["range_m"], (string)gRangeMeters);
    payload = llJsonSetValue(payload, ["updated_at"], llGetTimestamp());
    payload = llJsonSetValue(payload, ["horses"], llList2Json(JSON_ARRAY, horses));

    llHTTPRequest(
        gBackendUrl,
        [
            HTTP_METHOD, "POST",
            HTTP_MIMETYPE, "application/json"
        ],
        payload
    );

    llOwnerSay("[BUILD STEP 5] Backend sync complete: " + (string)count + " horses");
}

default
{
    state_entry()
    {
        loadConfig();
        if (gRunning)
        {
            llSetTimerEvent((float)SCAN_INTERVAL);
        }
    }

    on_rez(integer start_param)
    {
        gRunning = TRUE;
        llSetTimerEvent((float)SCAN_INTERVAL);
    }

    touch_start(integer total_number)
    {
        key agent = llDetectedKey(0);
        showMenu(agent);
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel != MENU_CHANNEL)
        {
            return;
        }

        if (gPendingRangeInput)
        {
            integer newRange = (integer)message;
            if (newRange >= 1 && newRange <= 15)
            {
                gRangeMeters = (float)newRange;
                persistConfig();
            }
            gPendingRangeInput = FALSE;
            return;
        }

        handleMenuSelection(id, message);
    }

    timer()
    {
        if (!gRunning)
        {
            return;
        }
        llSensor("", NULL_KEY, ACTIVE | PASSIVE, gRangeMeters, PI);
        refreshMedia();
    }

    sensor(integer detected)
    {
        gHorseKeys = [];
        gHorseNames = [];
        gHorseRaw = [];

        integer i = 0;
        while (i < detected && i < MAX_HORSES)
        {
            key target = llDetectedKey(i);
            list details = llGetObjectDetails(target, [OBJECT_DESC, OBJECT_NAME]);
            string raw = llList2String(details, 0);
            string name = llList2String(details, 1);
            if (raw != "")
            {
                gHorseKeys += [(string)target];
                gHorseNames += [name];
                gHorseRaw += [raw];
            }
            i += 1;
        }

        updateHoverText();
        backendSync();
    }

    no_sensor()
    {
        gHorseKeys = [];
        gHorseNames = [];
        gHorseRaw = [];
        updateHoverText();
    }

    http_response(key request_id, integer status, list metadata, string body)
    {
        if (status < 200 || status >= 300)
        {
            llOwnerSay("[BUILD STEP 5] Backend sync failed: " + (string)status);
        }
    }
}
