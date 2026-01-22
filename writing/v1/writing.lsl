// ================= CONFIG =================
key TEX_UUID = "40c75e2c-0e7c-7b85-5925-e8283ef633b4";
integer GRID = 16;

// Face counts
integer LINE_FACES  = 8;   // per mesh
integer LINE_MAX_CHARS;

// Line prim names
string LINE_PRIM_A = "Line1a";
string LINE_PRIM_B = "Line1b";

// Append Name
string NAME_APPEND = "*Rockstar Ranch* Text Sign: ";

// Text Colors
vector TEXT_GREEN   = <0.0, 1.0, 0.0>;
vector TEXT_BLUE    = <0.0, 0.0, 1.0>;
vector TEXT_YELLOW  = <1.0, 1.0, 0.0>;
vector TEXT_CYAN    = <0.0, 1.0, 1.0>;
vector TEXT_MAGENTA = <1.0, 0.0, 1.0>;
vector TEXT_WHITE   = <1.0, 1.0, 1.0>;
vector TEXT_BLACK   = <0.0, 0.0, 0.0>;
vector TEXT_RED     = <1.0, 0.0, 0.0>;

vector TEXT_COLOR = TEXT_CYAN;
integer SHOW_HOVERTEXT = TRUE;

// =========================================


// ================= ICON MAP =================
integer iconIndex(string iconName)
{
    if (iconName == "CROWN")     return 224;
    if (iconName == "DRAGON")    return 225;
    if (iconName == "HEADPIECE") return 226;
    if (iconName == "HORSESHOE") return 229;

    if (iconName == "UNICORN")  return 231;
    if (iconName == "UNICORN1") return 231;
    if (iconName == "UNICORN2") return 232;
    if (iconName == "UNICORN3") return 233;

    if (iconName == "HORSE")    return 228;
    if (iconName == "PEGASUS")  return 230;

    if (iconName == "HEARTS")   return 234;
    if (iconName == "HEART")    return 235;
    if (iconName == "WAND")     return 236;
    if (iconName == "MAGIC")    return 237;
    if (iconName == "STARS")    return 238;
    if (iconName == "BABY")     return 239;

    return -1;
}

// ===== MESSAGE HELPERS ======
string ICON_HELP = "Available Icons:\nCrown {CROWN}\nDragon {DRAGON}\nHeadpiece {HEADPIECE}\nHorseshoe {HORSESHOE}\nUnicorn {UNICORN}\nUnicorn 2 {UNICORN2}\nUnicorn 3 {UNICORN3}\nHorse {HORSE}\nPegasus {PEGASUS}\nHearts {HEARTS}\nHeart {HEART}\nWand {WAND}\nMagic {MAGIC}\nStars {STARS}\nBaby {BABY}";

string lineInputMessage()
{
    return "Enter line (max " + (string)LINE_MAX_CHARS + " chars)\n\n" + ICON_HELP;
}
// =============== LINK HELPER =================
integer linkByName(string name)
{
    integer i;
    for (i = 1; i <= llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name)
            return i;
    return -1;
}


// ================= PARSER =================
list parseText(string text)
{
    list out = [];
    integer i = 0;

    while (i < llStringLength(text))
    {
        if (llGetSubString(text, i, i) == "{")
        {
            integer end = llSubStringIndex(llGetSubString(text, i + 1, -1), "}");
            if (end != -1)
            {
                string name = llToUpper(llGetSubString(text, i + 1, i + end));
                integer idx = iconIndex(name);
                if (idx != -1)
                {
                    out += idx;
                    i += end + 2;
                    jump parsed;
                }
            }
        }

        integer a = llOrd(text, i);
        if (a >= 32 && a <= 126)
            out += (a - 32);

        i++;
@parsed;
    }

    return out;
}

string stripIcons(string text)
{
    string out = "";
    integer i = 0;

    while (i < llStringLength(text))
    {
        if (llGetSubString(text, i, i) == "{")
        {
            integer end = llSubStringIndex(llGetSubString(text, i + 1, -1), "}");
            if (end != -1)
            {
                string name = llToUpper(llGetSubString(text, i + 1, i + end));
                if (iconIndex(name) != -1)
                {
                    i += end + 2;
                    jump stripped;
                }
            }
        }

        out += llGetSubString(text, i, i);
        i++;
@stripped;
    }

    return out;
}

// ================= MESH RENDER =================
renderMesh(integer linkNum, integer faceCount, list glyphs)
{
    if (linkNum <= 0) return;

    float cell = 1.0 / GRID;
    integer i;

    for (i = 0; i < faceCount; i++)
    {
        vector scale  = <0,0,0>;
        vector offset = <0,0,0>;

        if (i < llGetListLength(glyphs))
        {
            integer idx = llList2Integer(glyphs, i);
            if (idx >= 0)
            {
                integer r = idx / GRID;
                integer c = idx % GRID;

                scale = <cell,cell,0>;
                offset = <
                    c * cell + cell/2 - 0.5,
                   -(r * cell + cell/2 - 0.5),
                    0
                >;
            }
        }

        llSetLinkPrimitiveParamsFast(
            linkNum,
            [PRIM_TEXTURE, i, TEX_UUID, scale, offset, 0.0,
             PRIM_COLOR, i, TEXT_COLOR, 1.0]
        );
    }
}

// ================= BODY LINE =================
renderLine(integer n, string text)
{
    list glyphs = parseText(text);
    integer max = LINE_FACES * 2;

    if (llGetListLength(glyphs) > max)
        glyphs = llList2List(glyphs, 0, max - 1);

    integer pad = (max - llGetListLength(glyphs)) / 2;
    list padded = [];
    integer i;

    for (i = 0; i < pad; i++) padded += -1;
    padded += glyphs;
    for (i = llGetListLength(padded); i < max; i++) padded += -1;

    renderMesh(linkByName(LINE_PRIM_A), LINE_FACES, llList2List(padded, 0, 7));
    renderMesh(linkByName(LINE_PRIM_B), LINE_FACES, llList2List(padded, 8, 15));
}

string lastLineText;

setTextColor(vector color)
{
    TEXT_COLOR = color;
    renderLine(1, lastLineText);
    if (SHOW_HOVERTEXT)
        llSetText(lastLineText, TEXT_COLOR, 1.0);
    else
        llSetText("", TEXT_COLOR, 0.0);
}

setHoverTextEnabled(integer enabled)
{
    SHOW_HOVERTEXT = enabled;
    if (SHOW_HOVERTEXT)
        llSetText(lastLineText, TEXT_COLOR, 1.0);
    else
        llSetText("", TEXT_COLOR, 0.0);
}

updateRootName(string text)
{
    string stripped = llStringTrim(stripIcons(text), STRING_TRIM);
    integer maxLen = 63;
    integer remaining = maxLen - llStringLength(NAME_APPEND);

    if (remaining <= 0)
        return;

    if (llStringLength(stripped) > remaining)
        stripped = llGetSubString(stripped, 0, remaining - 1);

    if (stripped != "")
        llSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_NAME, NAME_APPEND + stripped]);
}


// ================= MENU =================
integer dialogChan;
integer inputChan;
string pending;

showMainMenu()
{
    string hoverLabel = SHOW_HOVERTEXT ? "Hovertext Off" : "Hovertext On";
    llDialog(
        llGetOwner(),
        "\n\n Choose Message Line to Set:\n\n ◆ Line: max " + (string)LINE_MAX_CHARS + " characters \n\n",
        [
            "Set Line",
            "Text Color",
            "Name Prefix",
            hoverLabel
        ],
        dialogChan
    );
}

showColorMenu()
{
    llDialog(
        llGetOwner(),
        "\n\n Choose Text Color:\n\n",
        [
            "Green", "Blue", "Yellow",
            "Cyan", "Magenta", "White",
            "Black", "Red", "Back"
        ],
        dialogChan
    );
}

showNamePrefixMenu(key id)
{
    llTextBox(
        id,
        "Enter name prefix (current: " + NAME_APPEND + ")",
        inputChan
    );
}

// ================= MAIN =================
default
{
    state_entry()
    {
        // Initialise Vars
        LINE_MAX_CHARS  = LINE_FACES  * 2; // 16
    }

    touch_start(integer n)
    {
        dialogChan = -1 - (integer)llFrand(999999);
        inputChan = dialogChan - 1;
        llListen(dialogChan, "", llGetOwner(), "");
        llListen(inputChan, "", llGetOwner(), "");

        showMainMenu();
    }

    listen(integer ch, string name, key id, string msg)
    {
        if (ch == dialogChan)
        {
            pending = msg;
            if (pending == "Set Line")
                llTextBox(id, lineInputMessage(), inputChan);
            else if (pending == "Text Color")
                showColorMenu();
            else if (pending == "Name Prefix")
                showNamePrefixMenu(id);
            else if (pending == "Back")
                showMainMenu();
            else if (pending == "Green")   { setTextColor(TEXT_GREEN); showMainMenu(); }
            else if (pending == "Blue")    { setTextColor(TEXT_BLUE); showMainMenu(); }
            else if (pending == "Yellow")  { setTextColor(TEXT_YELLOW); showMainMenu(); }
            else if (pending == "Cyan")    { setTextColor(TEXT_CYAN); showMainMenu(); }
            else if (pending == "Magenta") { setTextColor(TEXT_MAGENTA); showMainMenu(); }
            else if (pending == "White")   { setTextColor(TEXT_WHITE); showMainMenu(); }
            else if (pending == "Black")   { setTextColor(TEXT_BLACK); showMainMenu(); }
            else if (pending == "Red")     { setTextColor(TEXT_RED); showMainMenu(); }
            else if (pending == "Hovertext Off") { setHoverTextEnabled(FALSE); showMainMenu(); }
            else if (pending == "Hovertext On")  { setHoverTextEnabled(TRUE); showMainMenu(); }
            return;
        }

        if (ch == inputChan && pending != "")
        {
            if (pending == "Set Line")
            {
                lastLineText = msg;
                renderLine(1, msg);
                if (SHOW_HOVERTEXT)
                    llSetText(lastLineText, TEXT_COLOR, 1.0);
                else
                    llSetText("", TEXT_COLOR, 0.0);
                updateRootName(msg);
            }
            else if (pending == "Name Prefix")
            {
                NAME_APPEND = msg;
                updateRootName(lastLineText);
                showMainMenu();
            }

            pending = "";
        }
    }
}
