// ======================================================
// ROOT PRIM INVENTORY MONITOR — MENU DRIVEN (STRICT LSL)
// ======================================================

// -------- CONFIG --------
string LM_NAME = "*Rockstar Ranch*";
string HELP_NOTECARD = "*Rockstar Ranch* Bundle Organiser Help";

// -------- COLORS --------
vector COLOR_EMPTY = <1.0, 1.0, 1.0>;
vector COLOR_FULL  = <1.0, 0.5, 0.0>;

vector TEXT_GREEN   = <0.0, 1.0, 0.0>;
vector TEXT_BLUE    = <0.0, 0.0, 1.0>;
vector TEXT_YELLOW  = <1.0, 1.0, 0.0>;
vector TEXT_CYAN    = <0.0, 1.0, 1.0>;
vector TEXT_MAGENTA = <1.0, 0.0, 1.0>;
vector TEXT_WHITE   = <1.0, 1.0, 1.0>;
vector TEXT_BLACK   = <0.0, 0.0, 0.0>;
vector TEXT_RED     = <1.0, 0.0, 0.0>;

vector TEXT_COLOR = TEXT_CYAN;

// -------- LIMITS --------
integer DESC_HARD_MAX = 127;
integer HOVER_LINE_LEN = 80;

// -------- STATE --------
integer MENU_CHANNEL;
integer LISTEN_HANDLE;
key OWNER;
integer RUNNING = TRUE;

integer MODE_NONE        = 0;
integer MODE_SET_NAME    = 1;
integer MODE_SET_DESC    = 2;
integer MODE_APPEND_DESC = 3;
integer MODE_SET_COLOR   = 4;
integer MODE = 0;

// ----------------------------
// DESCRIPTION HELPERS
// ----------------------------
string clampDescription(string desc)
{
    if (llStringLength(desc) > DESC_HARD_MAX)
        return llGetSubString(desc, 0, DESC_HARD_MAX - 1);
    return desc;
}

// 3-line formatter (best-effort under 127-char limit)
string formatDescription(string desc)
{
    string out = "";
    integer len = llStringLength(desc);

    if (len > HOVER_LINE_LEN)
    {
        out += llGetSubString(desc, 0, HOVER_LINE_LEN - 1) + "\n";
        desc = llGetSubString(desc, HOVER_LINE_LEN, -1);
        len = llStringLength(desc);
    }

    if (len > HOVER_LINE_LEN)
    {
        out += llGetSubString(desc, 0, HOVER_LINE_LEN - 1) + "\n";
        desc = llGetSubString(desc, HOVER_LINE_LEN, -1);
    }

    out += desc;
    return out;
}

// ----------------------------
// STATUS UPDATE
// ----------------------------
updateStatus()
{
    if (!RUNNING) return;

    integer count = llGetInventoryNumber(INVENTORY_OBJECT);

    if (count > 0)
        llSetLinkColor(LINK_ROOT
