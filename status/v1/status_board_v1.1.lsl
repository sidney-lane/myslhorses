// Status Board v1 Script
// Implements build steps for hover text, parsing, menus, media refresh, and backend sync.

integer MAX_HORSES = 10;
integer MENU_CHANNEL = -90001;
integer listenHandle;

integer PERM_OWNER = 0;
integer PERM_GROUP = 1;
integer PERM_OPEN = 2;

integer gRunning = TRUE;
integer gHoverEnabled = TRUE;
integer gPermissions = 0;
integer gPendingRangeInput = FALSE;
integer gDebugEnabled = FALSE;
integer gPendingScanInput = FALSE;
string gPendingColorTarget = "";
integer gHoverNameLink = 0;
integer gHoverStatsLink = 0;

float gRangeMeters = 10.0;
integer gScanMinutes = 1;
string gBoardId = "pod-01";
string gBackendUrl = "";
string gLastMediaUrl = "";

list gHorseKeys = [];
list gHorseNames = [];
list gHorseRaw = [];

vector TEXT_GREEN   = <0.0, 1.0, 0.0>;
vector TEXT_BLUE    = <0.0, 0.5, 1.0>;
vector TEXT_YELLOW  = <1.0, 1.0, 0.0>;
vector TEXT_CYAN    = <0.0, 1.0, 1.0>;
vector TEXT_MAGENTA = <1.0, 0.0, 1.0>;
vector TEXT_WHITE   = <1.0, 1.0, 1.0>;
vector TEXT_BLACK   = <0.0, 0.0, 0.0>;
vector TEXT_RED     = <1.0, 0.0, 0.0>;

string HOVER_NAME_PRIM = "HoverName";
string HOVER_STATS_PRIM = "HoverStats";

list gTextColorNames = [
    "Green", "Blue", "Yellow",
    "Cyan", "Magenta", "White",
    "Black", "Red"
];
list gTextColors = [
    TEXT_GREEN, TEXT_BLUE, TEXT_YELLOW,
    TEXT_CYAN, TEXT_MAGENTA, TEXT_WHITE,
    TEXT_BLACK, TEXT_RED
];
integer gNameColorIndex = 5;
integer gStatusColorIndex = 5;
integer MAX_HOVER_LINE_CHARS = 80;
list F_PCT   = [1,10,20,30,40,50,60,70,80,90,95,96,97,98,99];
list F_HOURS = [
    63.354, 57.600, 51.200, 44.800, 38.400, 32.000,
    25.600, 19.200, 12.800, 6.400, 3.200, 2.550,
    1.917, 1.267, 0.633
];

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

integer linkByName(string name)
{
    integer i;
    for (i = 1; i <= llGetNumberOfPrims(); i++)
    {
        if (llGetLinkName(i) == name)
        {
            return i;
        }
    }
    return 0;
}

float pregnancyHours(integer preg)
{
    if (preg >= 100) return 0.0;
    if (preg <= 0)   return 72.0;
    return 72.0 * (1.0 - ((float)preg / 100.0));
}

float fervorHours(integer F)
{
    if (F >= 100) return 0.0;

    integer len = llGetListLength(F_PCT);

    if (F <= llList2Integer(F_PCT, 0))
        return llList2Float(F_HOURS, 0);

    integer i;
    for (i = 1; i < len; i++)
    {
        integer p1 = llList2Integer(F_PCT, i);

        if (F <= p1)
        {
            integer p0 = llList2Integer(F_PCT, i - 1);
            float h0 = llList2Float(F_HOURS, i - 1);
            float h1 = llList2Float(F_HOURS, i);

            float t = ((float)F - (float)p0) / ((float)p1 - (float)p0);
            return h0 + (h1 - h0) * t;
        }
    }

    integer pLast = llList2Integer(F_PCT, len - 1);
    float   hLast = llList2Float(F_HOURS, len - 1);
    float   t2    = ((float)F - (float)pLast) / (100.0 - (float)pLast);

    return hLast * (1.0 - t2);
}

string hoursLabel(float hours)
{
    if (hours <= 0.0)
    {
        return "READY";
    }
    return (string)((integer)hours) + "H";
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
    string pregLabel = "--";
    string fervorLabel = "--";

    if (ageDays < 7)
    {
        integer remainingDays = 7 - ageDays;
        pregLabel = "Birth +" + (string)remainingDays + "d";
        fervorLabel = hoursLabel(fervorHours(0));
        line2 = pregLabel + " | Fervor " + fervorLabel;
        return [line1, line2];
    }

    if (pregval > 0 && gender == 2)
    {
        pregLabel = hoursLabel(pregnancyHours(pregval));
    }
    if (fervor < 100)
    {
        fervorLabel = hoursLabel(fervorHours(fervor));
    }
    else
    {
        fervorLabel = "READY";
    }

    if (pregLabel == "--" && fervorLabel == "--")
    {
        line2 = "Recovery";
        return [line1, line2];
    }

    line2 = "Preg " + pregLabel + " | Fervor " + fervorLabel;
    return [line1, line2];
}

list parseHorseApi(string raw, string name)
{
    list fields = llParseString2List(raw, [":"], []);
    if (llGetListLength(fields) < 12)
    {
        debugSay("[BUILD STEP 2] Validation failed for " + name + ": invalid field count");
        return [];
    }

    string horseKey = llList2String(fields, 0);
    integer age = (integer)llList2String(fields, 2);
    integer fervor = (integer)llList2String(fields, 5);
    integer gender = (integer)llList2String(fields, 7);
    integer pregval = (integer)llList2String(fields, 9);

    debugSay(
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

debugSay(string message)
{
    if (gDebugEnabled)
    {
        llOwnerSay(message);
    }
}

integer colorIndexFromName(string name)
{
    return llListFindList(gTextColorNames, [name]);
}

setHoverTextOnLink(integer link, string text, vector color, float alpha)
{
    if (link > 0)
    {
        llSetLinkPrimitiveParamsFast(link, [PRIM_TEXT, text, color, alpha]);
    }
}

showColorMenu(key agent, string target)
{
    gPendingColorTarget = target;
    llDialog(
        agent,
        "\n\n Choose Text Color (" + target + "):\n\n",
        [
            "Green", "Blue", "Yellow",
            "Cyan", "Magenta", "White",
            "Black", "Red", "Back"
        ],
        MENU_CHANNEL
    );
}

sayStats(key agent)
{
    string runningLabel = "No";
    if (gRunning)
    {
        runningLabel = "Yes";
    }
    string permLabel = "Owner";
    if (gPermissions == PERM_GROUP)
    {
        permLabel = "Group";
    }
    else if (gPermissions == PERM_OPEN)
    {
        permLabel = "Open";
    }
    string nameColorLabel = llList2String(gTextColorNames, gNameColorIndex);
    string statusColorLabel = llList2String(gTextColorNames, gStatusColorIndex);

    llRegionSayTo(agent, 0, "Status Board Stats:");
    llRegionSayTo(agent, 0, "Running: " + runningLabel);
    llRegionSayTo(agent, 0, "Range: " + (string)gRangeMeters + "m");
    llRegionSayTo(agent, 0, "Scan: " + (string)gScanMinutes + " min");
    llRegionSayTo(agent, 0, "Permissions: " + permLabel);
    llRegionSayTo(agent, 0, "Text Color: " + nameColorLabel);
    llRegionSayTo(agent, 0, "Text Color (Stats): " + statusColorLabel);
    llRegionSayTo(agent, 0, "Horses: " + (string)llGetListLength(gHorseKeys));
}

persistConfig()
{
    string config = llJsonSetValue("{}", ["board_id"], gBoardId);
    config = llJsonSetValue(config, ["range_m"], (string)gRangeMeters);
    config = llJsonSetValue(config, ["scan_min"], (string)gScanMinutes);
    config = llJsonSetValue(config, ["permissions"], (string)gPermissions);
    config = llJsonSetValue(config, ["name_color_index"], (string)gNameColorIndex);
    config = llJsonSetValue(config, ["status_color_index"], (string)gStatusColorIndex);
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
    if (llJsonValueType(config, ["scan_min"]) != JSON_INVALID)
    {
        gScanMinutes = (integer)llJsonGetValue(config, ["scan_min"]);
    }
    if (llJsonValueType(config, ["permissions"]) != JSON_INVALID)
    {
        gPermissions = (integer)llJsonGetValue(config, ["permissions"]);
    }
    if (llJsonValueType(config, ["name_color_index"]) != JSON_INVALID)
    {
        gNameColorIndex = (integer)llJsonGetValue(config, ["name_color_index"]);
    }
    if (llJsonValueType(config, ["status_color_index"]) != JSON_INVALID)
    {
        gStatusColorIndex = (integer)llJsonGetValue(config, ["status_color_index"]);
    }
    if (llJsonValueType(config, ["media_url"]) != JSON_INVALID)
    {
        gLastMediaUrl = llJsonGetValue(config, ["media_url"]);
    }
}

integer hasPermission(key agent)
{
    if (agent == llGetOwner())
    {
        return TRUE;
    }
    if (gPermissions == PERM_OPEN)
    {
        return TRUE;
    }
    if (gPermissions == PERM_GROUP)
    {
        return llSameGroup(agent);
    }
    return FALSE;
}

showMenu(key agent)
{
    if (!hasPermission(agent) && agent != llGetCreator())
    {
        return;
    }

    gPendingColorTarget = "";
    list buttons = [];
    if (agent == llGetCreator())
    {
        if (gDebugEnabled)
        {
            buttons += ["Debug Off"];
        }
        else
        {
            buttons += ["Debug On"];
        }
    }
    if (agent == llGetOwner())
    {
        buttons += [
            "Start",
            "Stop",
            "Reset",
            "Set Range",
            "Set Scan",
            "See Stats",
            "Text Color"
        ];
    }
    else if (hasPermission(agent))
    {
        buttons += ["See Stats"];
    }
    if (listenHandle)
    {
        llListenRemove(listenHandle);
    }
    listenHandle = llListen(MENU_CHANNEL, "", agent, "");
    llDialog(agent, "Status Board Menu", buttons, MENU_CHANNEL);
    debugSay("[BUILD STEP 3] Menu displayed");
}

handleMenuSelection(key agent, string message)
{
    debugSay("[BUILD STEP 3] Menu option selected: " + message);

    if (message == "Start")
    {
        if (agent == llGetOwner())
        {
            gRunning = TRUE;
            llSetTimerEvent((float)(gScanMinutes * 60));
        }
    }
    else if (message == "Stop")
    {
        if (agent == llGetOwner())
        {
            gRunning = FALSE;
            llSetTimerEvent(0.0);
        }
    }
    else if (message == "Reset")
    {
        if (agent == llGetOwner())
        {
            llResetScript();
        }
    }
    else if (message == "Set Range")
    {
        if (agent == llGetOwner())
        {
            gPendingRangeInput = TRUE;
            llTextBox(agent, "Enter range (1-10m):", MENU_CHANNEL);
        }
    }
    else if (message == "Set Scan")
    {
        if (agent == llGetOwner())
        {
            gPendingScanInput = TRUE;
            llTextBox(agent, "Enter scan time (1-60 min):", MENU_CHANNEL);
        }
    }
    else if (message == "See Stats")
    {
        sayStats(agent);
    }
    else if (message == "Text Color")
    {
        if (agent == llGetOwner())
        {
            showColorMenu(agent, "All");
        }
    }
    else if (message == "Back")
    {
        gPendingColorTarget = "";
        showMenu(agent);
    }
    else if (message == "Debug On")
    {
        if (agent == llGetCreator())
        {
            gDebugEnabled = TRUE;
        }
    }
    else if (message == "Debug Off")
    {
        if (agent == llGetCreator())
        {
            gDebugEnabled = FALSE;
        }
    }
    else
    {
        integer colorIndex = colorIndexFromName(message);
        if (colorIndex != -1 && agent == llGetOwner())
        {
            if (gPendingColorTarget == "All")
            {
                gNameColorIndex = colorIndex;
                gStatusColorIndex = colorIndex;
                persistConfig();
                updateHoverText();
                gPendingColorTarget = "";
                showMenu(agent);
            }
        }
    }
}

updateHoverText()
{
    if (!gHoverEnabled)
    {
        setHoverTextOnLink(gHoverNameLink, "", llList2Vector(gTextColors, gNameColorIndex), 0.0);
        setHoverTextOnLink(gHoverStatsLink, "", llList2Vector(gTextColors, gStatusColorIndex), 0.0);
        if (gHoverNameLink == 0 && gHoverStatsLink == 0)
        {
            llSetText("", llList2Vector(gTextColors, gNameColorIndex), 0.0);
        }
        return;
    }

    list nameLines = [];
    list statsLines = [];
    list combinedLines = [];
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
            if (llGetListLength(lines) >= 2)
            {
                string nameLine = llList2String(lines, 0);
                string statsLine = llList2String(lines, 1);
                nameLines += [nameLine];
                statsLines += [statsLine];
                combinedLines += [nameLine, statsLine];
            }
            debugSay("[BUILD STEP 1] Hover text updated for " + horseKey);
        }
        i += 1;
    }

    string nameCombined = llDumpList2String(nameLines, "\n");
    string statsCombined = llDumpList2String(statsLines, "\n");
    if (gHoverNameLink > 0 || gHoverStatsLink > 0)
    {
        setHoverTextOnLink(gHoverNameLink, nameCombined, llList2Vector(gTextColors, gNameColorIndex), 1.0);
        setHoverTextOnLink(gHoverStatsLink, statsCombined, llList2Vector(gTextColors, gStatusColorIndex), 1.0);
    }
    else
    {
        string combined = llDumpList2String(combinedLines, "\n");
        llSetText(combined, llList2Vector(gTextColors, gNameColorIndex), 1.0);
    }
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
        debugSay("[BUILD STEP 4] Media refreshed for " + horseKey + ": " + gLastMediaUrl);
        i += 1;
    }
}

backendSync()
{
    if (gBackendUrl == "")
    {
        return;
    }

    debugSay("[BUILD STEP 5] Backend sync শুরু");

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

    debugSay("[BUILD STEP 5] Backend sync complete: " + (string)count + " horses");
}

default
{
    state_entry()
    {
        loadConfig();
        llSetClickAction(CLICK_ACTION_TOUCH);
        gHoverNameLink = linkByName(HOVER_NAME_PRIM);
        gHoverStatsLink = linkByName(HOVER_STATS_PRIM);
        if (gRunning)
        {
            llSetTimerEvent((float)(gScanMinutes * 60));
        }
    }

    on_rez(integer start_param)
    {
        gRunning = TRUE;
        llSetClickAction(CLICK_ACTION_TOUCH);
        gHoverNameLink = linkByName(HOVER_NAME_PRIM);
        gHoverStatsLink = linkByName(HOVER_STATS_PRIM);
        llSetTimerEvent((float)(gScanMinutes * 60));
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
            if (newRange >= 1 && newRange <= 10)
            {
                gRangeMeters = (float)newRange;
                persistConfig();
            }
            gPendingRangeInput = FALSE;
            return;
        }
        if (gPendingScanInput)
        {
            integer newMinutes = (integer)message;
            if (newMinutes >= 1 && newMinutes <= 60)
            {
                gScanMinutes = newMinutes;
                persistConfig();
                if (gRunning)
                {
                    llSetTimerEvent((float)(gScanMinutes * 60));
                }
            }
            gPendingScanInput = FALSE;
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
            debugSay("[BUILD STEP 5] Backend sync failed: " + (string)status);
        }
    }
}
