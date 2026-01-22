// ================= CONFIG =================
key TEX_UUID = "40c75e2c-0e7c-7b85-5925-e8283ef633b4";
integer GRID = 16;

// Face counts
integer TITLE_FACES = 6;   // per mesh
integer LINE_FACES  = 8;   // per mesh
integer TITLE_MAX_CHARS;
integer LINE_MAX_CHARS;

// Back Logo
string LOGO_PRIM_NAME = "Full Logo";
integer LOGO_FACE = 2;

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

string titleInputMessage()
{
    return "Enter title (max " + (string)TITLE_MAX_CHARS + " chars)\n\n" + ICON_HELP;
}

string lineInputMessage()
{
    return "Enter line (max " + (string)LINE_MAX_CHARS + " chars)\n\n" + ICON_HELP;
}

string logoInputMessage()
{
    return "Set logo texture\nPaste texture UUID only";
}

// ===== GLYPH HELPER FOR ALL LINES ======
list wrapGlyphs(list glyphs, integer perLine, integer maxLines)
{
    list out = [];
    integer i;

    for (i = 0; i < perLine * maxLines; i++)
    {
        if (i < llGetListLength(glyphs))
            out += llList2Integer(glyphs, i);
        else
            out += -1;
    }
    return out;
}



// =============== BACK LOGO HELPER =================
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
            [PRIM_TEXTURE, i, TEX_UUID, scale, offset, 0.0]
        );
    }
}

// ================= SET LOGO =================
setHeroTexture(key tex)
{
    llSetLinkPrimitiveParamsFast(
        LINK_ROOT,
        [PRIM_TEXTURE, 4, tex, <1.0,1.0,0.0>, <0.0,0.0,0.0>, 0.0]
    );
}

// ================= SET BACK LOGO =================
setLogoTexture(string tex)
{
    integer link = linkByName(LOGO_PRIM_NAME);
    if (link == -1)
    {
        llInstantMessage(llGetOwner(), "Logo prim not found: " + LOGO_PRIM_NAME);
        return;
    }

    llSetLinkPrimitiveParamsFast(
        link,
        [PRIM_TEXTURE, LOGO_FACE, (key)tex, <1.0,1.0,0>, <0.0,0.0,0>, 0.0]
    );
}


// ================= TITLE (CENTERED) =================
renderTitle(string text)
{
    list glyphs = parseText(text);
    integer max = TITLE_FACES * 2;

    if (llGetListLength(glyphs) > max)
    {
        llInstantMessage(llGetOwner(),
            "Title too long (" + (string)llGetListLength(glyphs)
            + " / " + (string)max + "). Not applied.");
        return;
    }

    integer pad = (max - llGetListLength(glyphs)) / 2;
    list padded = [];

    integer i;
    for (i = 0; i < pad; i++) padded += -1;
    padded += glyphs;

    renderMesh(linkByName("Title1a"), TITLE_FACES, llList2List(padded, 0, 5));
    renderMesh(linkByName("Title1b"), TITLE_FACES, llList2List(padded, 6, 11));
}

// ================= SUBTITLE (CENTERED) =================
renderTitle2(string text)
{
    list glyphs = parseText(text);
    integer max = TITLE_FACES * 2;

    if (llGetListLength(glyphs) > max)
    {
        llInstantMessage(llGetOwner(),"Title 2 too long.");
        return;
    }

    integer pad = (max - llGetListLength(glyphs)) / 2;
    list padded = [];
    integer i;
    for (i = 0; i < pad; i++) padded += -1;
    padded += glyphs;

    renderMesh(linkByName("Title2a"), TITLE_FACES, llList2List(padded,0,5));
    renderMesh(linkByName("Title2b"), TITLE_FACES, llList2List(padded,6,11));
}


// ================= BODY LINE =================
renderLine(integer n, string text)
{
    list glyphs = parseText(text);
    integer max = LINE_FACES * 2;

    if (llGetListLength(glyphs) > max)
        glyphs = llList2List(glyphs, 0, max - 1);

    renderMesh(linkByName("Line" + (string)n + "a"), LINE_FACES, llList2List(glyphs, 0, 7));
    renderMesh(linkByName("Line" + (string)n + "b"), LINE_FACES, llList2List(glyphs, 8, 15));
}


// ================= NEW: GLYPH LINE RENDER (FIX) =================
renderLineGlyphs(integer n, list glyphs)
{
    integer max = LINE_FACES * 2;
    if (llGetListLength(glyphs) > max)
        glyphs = llList2List(glyphs, 0, max - 1);

    renderMesh(linkByName("Line" + (string)n + "a"), LINE_FACES, llList2List(glyphs, 0, 7));
    renderMesh(linkByName("Line" + (string)n + "b"), LINE_FACES, llList2List(glyphs, 8, 15));
}


// ================= MENU =================
integer dialogChan;
string pending;


// ================= MAIN =================
default
{
    state_entry()
    {
        // Initialise Vars
        TITLE_MAX_CHARS = TITLE_FACES * 2; // 12
        LINE_MAX_CHARS  = LINE_FACES  * 2; // 16
        llListen(0, "", llGetOwner(), "");
    }

    touch_start(integer n)
    {
        dialogChan = -1 - (integer)llFrand(999999);
        llListen(dialogChan, "", llGetOwner(), "");

        llDialog(
            llGetOwner(),
            "\n\n Choose Message Line to Set:\n\n ◆ Title: max " + (string)TITLE_MAX_CHARS + " characters \n ◆ Subtitle: max " + (string)TITLE_MAX_CHARS + " characters \n ◆ Specific Line: max " + (string)LINE_MAX_CHARS + " characters \n ◆ All Lines (4): total max " + (string)(LINE_MAX_CHARS*4) + " characters \n ◆ Logo (UUID) \n\n",
            [
                "Line 4", "All Lines", "Set Logo",
                "Line 1", "Line 2", "Line 3",
                "Hero Logo",  "Set Title", "Set Subtitle"
            ],
            dialogChan
        );
    }

    listen(integer ch, string name, key id, string msg)
    {
        if (ch == dialogChan)
        {
            pending = msg;
            if (pending == "Set Title 1" || pending == "Set Title 2")
                llTextBox(id, titleInputMessage(), 0);
            else if (pending == "Line 1" || pending == "Line 2" || pending == "Line 3" || pending == "Line 4")
                llTextBox(id, lineInputMessage(), 0);
            else if (pending == "Hero Logo")
                llTextBox(id, logoInputMessage(), 0);
            else if (pending == "Set Logo")
                llTextBox(id, logoInputMessage(), 0);
            else
                llTextBox(id, lineInputMessage(), 0);
            return;
        }

        if (ch == 0 && pending != "")
        {
            if (pending == "Hero Logo") setHeroTexture(msg);
            if (pending == "Set Title") renderTitle(msg);
            if (pending == "Set Subtitle") renderTitle2(msg);
            if (pending == "Line 1")    renderLine(1, msg);
            if (pending == "Line 2")    renderLine(2, msg);
            if (pending == "Line 3")    renderLine(3, msg);
            if (pending == "Line 4")    renderLine(4, msg);
            if (pending == "Set Logo") setLogoTexture(msg);

            if (pending == "All Lines")
            {
                list glyphs = parseText(msg);
                list flat = wrapGlyphs(glyphs, LINE_FACES * 2, 4);

                renderLineGlyphs(1, llList2List(flat,  0, 15));
                renderLineGlyphs(2, llList2List(flat, 16, 31));
                renderLineGlyphs(3, llList2List(flat, 32, 47));
                renderLineGlyphs(4, llList2List(flat, 48, 63));
            }

            pending = "";
        }
    }
}
