// =====================================================
// CONFIG
// =====================================================

string SUPA_URL = "https://xbzyzxafepdnqwwikmyi.supabase.co/rest/v1/horse_board?id=eq.1";
string SUPA_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhienl6eGFmZXBkbnF3d2lrbXlpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDY0OTE1MCwiZXhwIjoyMDgwMjI1MTUwfQ.yyeGB3pIf1lzeS2uxztVCWUsggOJG4H5mP0HWanVzsE";
// string CUSTOM_HEADER = "api: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhienl6eGFmZXBkbnF3d2lrbXlpIiwicm9zZSI6InNlcnZpY2Vfcm9zZSIsImlhdCI6MTc2NDY0OTE1MCwiZXhwIjoyMDgwMjI1MTUwfQ.yyeGB3pIf1lzeS2uxztVCWUsggOJG4H5mP0HWanVzsE";

// Media texture = board URL
// https://xbzyzxafepdnqwwikmyi.supabase.co/storage/v1/object/public/horseboard/board.png

// =====================================================
// GLOBALS
// =====================================================

integer DISPLAY_LINK = LINK_THIS; //unused
float   gScanRange   = 40.0;
float   gUpdateInterval = 60.0;

integer gAutoUpdate  = TRUE;
integer gDialogChan;
integer gListen;

key gOwner;
key gHttpReq;
integer gHttpBusy = FALSE;

list gRows;   // packed rows for Supabase


// =====================================================
// TABLES
// =====================================================

list F_PCT   = [1,10,20,30,40,50,60,70,80,90,95,96,97,98,99];
list F_HOURS = [
    63.354, 57.600, 51.200, 44.800, 38.400, 32.000,
    25.600, 19.200, 12.800, 6.400, 3.200, 2.550,
    1.917, 1.267, 0.633
];


// =====================================================
// FUNCTIONS
// =====================================================

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

integer randChannel()
{
    integer r = (integer)llFrand(999999.0);
    if (r < 1) r = 1;
    return -r;
}

closeMenu()
{
    if (gListen)
    {
        llListenRemove(gListen);
        gListen = 0;
    }
}

openMenu()
{
    closeMenu();
    gDialogChan = randChannel();
    gListen     = llListen(gDialogChan, "", gOwner, "");

    string autoStr;
    if (gAutoUpdate) autoStr = "On";
    else             autoStr = "Off";

    list buttons = ["REFRESH","RANGE","AUTO ("+autoStr+")","CLOSE"];

    llDialog(
        gOwner,
        "Horse Board\nRange "+(string)((integer)gScanRange)+"m",
        buttons,
        gDialogChan
    );
}

openRangeMenu()
{
    closeMenu();
    gDialogChan = randChannel();
    gListen = llListen(gDialogChan, "", gOwner, "");
    llDialog(gOwner, "Select scan range", ["10","20","30","40","BACK"], gDialogChan);
}

sendToSupabase()
{
    if (gHttpBusy) return;
    gHttpBusy = TRUE;

    string rowsJson = llList2Json(JSON_ARRAY, gRows);

    string payload =
        "{\"updated\":" + (string)llGetUnixTime() +
        ",\"rows\":" + rowsJson + "}";

    string body = "{\"payload\":" + payload + "}";

    gHttpReq = llHTTPRequest(
        SUPA_URL,
        [
            HTTP_METHOD, "PATCH",
            HTTP_MIMETYPE, "application/json",
            HTTP_BODY_MAXLENGTH, 16384,
            HTTP_CUSTOM_HEADER, "apikey", SUPA_KEY,
            HTTP_CUSTOM_HEADER, "Prefer", "return=representation",
            HTTP_CUSTOM_HEADER, "Content-Profile", "public" 
        ],
        body
    );
}

startScan()
{
    gRows = [];
    llSensor("", NULL_KEY, ACTIVE | PASSIVE, gScanRange, TWO_PI);
}


// =====================================================
// STATE
// =====================================================

default
{
    state_entry()
    {
        gOwner = llGetOwner();
        llSetClickAction(CLICK_ACTION_TOUCH);

        if (gAutoUpdate)
            llSetTimerEvent(gUpdateInterval);
        else
            llSetTimerEvent(0.0);

        llOwnerSay("Board ready. Touch for menu.");
    }

    touch_start(integer n)
    {
        if (llDetectedKey(0) == gOwner)
            openMenu();
    }

    listen(integer chan, string name, key id, string msg)
    {
        if (chan != gDialogChan || id != gOwner) return;

        if (msg == "REFRESH")
        {
            startScan();
            closeMenu();
        }
        else if (msg == "RANGE")
        {
            openRangeMenu();
        }
        else if (msg == "BACK")
        {
            openMenu();
        }
        else if (msg == "CLOSE")
        {
            closeMenu();
        }
        else if (llSubStringIndex(msg,"AUTO") == 0)
        {
            gAutoUpdate = !gAutoUpdate;

            if (gAutoUpdate)
                llSetTimerEvent(gUpdateInterval);
            else
                llSetTimerEvent(0.0);

            openMenu();
        }
        else if (msg == "10" || msg == "20" || msg == "30" || msg == "40")
        {
            gScanRange = (float)((integer)msg);
            openMenu();
        }
    }

    timer()
    {
        if (gAutoUpdate)
            startScan();
    }

    sensor(integer num)
    {
        integer i;

        for (i = 0; i < num; ++i)
        {
            key k = llDetectedKey(i);
            list d = llGetObjectDetails(k, [OBJECT_DESC]);
            string desc = llList2String(d, 0);
            list parts = llParseString2List(desc, [":"], []);

            // validate horse
            if (llGetListLength(parts) < 13) jump skipHorse;
            if (llSubStringIndex(llList2String(parts,12), "V") != 0) jump skipHorse;

            string name = llDetectedName(i);

            integer age    = (integer)llList2String(parts, 2);
            integer energy = (integer)llList2String(parts, 4);
            integer ferv   = (integer)llList2String(parts, 5);
            integer happy  = (integer)llList2String(parts, 6);
            integer gender = (integer)llList2String(parts, 7);
            integer pairF  = (integer)llList2String(parts, 8);
            integer preg   = (integer)llList2String(parts, 9);

            // Fervor time
            float fH = 0.0;
            string fStr = "--";

            if (ferv >= 100)
            {
                fStr = "READY";
            }
            else if (age >= 7 && happy >= 75 && energy > 0)
            {
                fH   = fervorHours(ferv);
                fStr = (string)((integer)fH) + "H";
            }

            // Pregnancy time
            float pH = 0.0;
            string pStr = "--";

            if (preg > 0 && gender == 2)
            {
                pH   = pregnancyHours(preg);
                pStr = (string)((integer)pH) + "H";
            }

            gRows += [
                name,
                ferv,
                fStr,
                preg,
                pStr,
                age,
                pairF
            ];

@skipHorse;
        }

        sendToSupabase();
    }

    no_sensor()
    {
        gRows = [];
        sendToSupabase();
    }

    http_response(key req, integer status, list meta, string body)
    {
        if (req != gHttpReq) return;

        gHttpBusy = FALSE;

        if (status >= 200 && status < 300)
            llOwnerSay("Board updated.");
        else
            llOwnerSay("Supabase error: " + (string)status + " | " + body);
    }
}
