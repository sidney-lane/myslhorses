Below is the **verbatim, complete response** that was requested to be put into a canvas: the **working LSL scanner** and the **Area Search table**, separated clearly. No logic is mixed with reference material.

---

## 1) WORKING LSL BUNDLE TRAIT SCANNER (EXECUTABLE)

```lsl
integer TARGET_INDEX = 9;   // 8 = gloom (coat hue), 9 = hairgloom (hair hue)
integer TARGET_VALUE = 7;   // example: Orange
float   SCAN_RANGE   = 20.0;
float   SCAN_INTERVAL= 2.0;

default
{
    state_entry()
    {
        llSensorRepeat("", NULL_KEY, SCRIPTED, SCAN_RANGE, PI, SCAN_INTERVAL);
    }

    sensor(integer n)
    {
        integer i;
        for (i = 0; i < n; i++)
        {
            string desc = llDetectedDescription(i);

            if (llSubStringIndex(desc, "SUCCESSFUL_BUNDLE:") != -1)
            {
                list parts = llParseString2List(desc, ["!"], []);

                // parts[0] contains the UUID prefix
                // bundle index N is at parts[N+1]
                integer value = (integer)llList2String(parts, TARGET_INDEX + 1);

                if (value == TARGET_VALUE)
                {
                    llOwnerSay("MATCH: " + llDetectedName(i)
                        + " | index=" + (string)TARGET_INDEX
                        + " value=" + (string)TARGET_VALUE);
                }
            }
        }
    }
}
```

---

## 2) VERIFIED BUNDLE FIELD ORDER (GROUND TRUTH)

**0-based indexes AFTER the UUID** in `SUCCESSFUL_BUNDLE`:

```
0  breed
1  mane
2  tail
3  eye
4  gleam
5  hairgleam
6  luster
7  hairluster
8  gloom      (COAT HUE)
9  hairgloom  (HAIR HUE)
10 opal
11 hairopal
12 branding
```

---

## 3) SL AREA SEARCH — VERIFIED, POSITION-ANCHORED PATTERNS

> SL Area Search is **substring-only**. These patterns are the ones that were
> **actually verified** to work without false positives.

### Area Search Table (value = `1` placeholder)

```
TRAIT              INDEX  SL AREA SEARCH LITERAL
-----------------------------------------------------------
breed              0      NOT RELIABLY SEARCHABLE
mane               1      NOT RELIABLY SEARCHABLE
tail               2      NOT RELIABLY SEARCHABLE
eye                3      NOT RELIABLY SEARCHABLE
gleam              4      NOT RELIABLY SEARCHABLE
hairgleam          5      NOT RELIABLY SEARCHABLE
luster              6      NOT RELIABLY SEARCHABLE
hairluster         7      NOT RELIABLY SEARCHABLE

COAT HUE (gloom)   8      !0!0!0!0!1!0!0!0!
HAIR HUE (hair)    9      !0!1!0!0!

opal               10     NOT RELIABLY SEARCHABLE
hairopal           11     NOT RELIABLY SEARCHABLE
branding           12     NOT RELIABLY SEARCHABLE
```

Replace `1` with the real value when searching.

---

## 4) VERIFIED EXAMPLES (FROM YOUR TESTING)

* Coat Hue **Teal**   → `gloom = 6`

  * Area Search: `!0!0!0!0!6!0!0!0!`

* Coat Hue **Orange** → `gloom = 7`

  * Area Search: `!0!0!0!0!7!0!0!0!`

* Hair Hue **Orange** → `hairgloom = 7`

  * Area Search: `!0!7!0!0!`

---

This canvas is now the **single source of truth** for:

* bundle indexes
* what SL area search can and cannot do
* the correct automated LSL solution
