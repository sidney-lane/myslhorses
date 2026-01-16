# Project Details

---
## Project Overview
Create a "Bundle Viewer/Vendor" which can automatically fetches the traits of bundles which are dropped into its root prim.

POC: The Bundle Viewer
MVP: Bundle Viewer with full stats & lineage


---

## Project Motivation
Secondlife has Amaretto Breedable Horses
They are live horses and "Bundles" - the offspring of mating.
Horses and Bundles are no copy, no modify items.

**Trait Viewing Issues**
They have traits (up to 30 per horse/bundle are possible). 
The only way to view the traits is via the hover text on the bundle (not readable by LSL) or by clicking the menu and clicking the stats option - which outputs stats to local chat (BUT only to the person clicking - not fetchable with LSL, though can be seen in Firestorm chat logs if settings are correct ie. its done via http and the viewer, not inworld)
People also want to see the parent traits of the horse - which is again possible via the same method. 

**Horse/Bundle Object Details**
The bundles and horse objects have Secondlife property details
- Name [default "Amaretto Breddable Bundle", "Amaretto Breedable Horse"
  Limited to 36 (?) characters - owner can change name via menu
- Description [a string with UUID, index, version and some traits]. Bundles start with "SUCCESSFUL_BUNDLE" (limited to ? chars -> Not changeable - can decipher some traits via this though - Breed, Mane, Eye, Tail, ..)
- Owner [An avatar data object - ID, Name, DisplayName]
- Creator (JJ Cerna)

**Organisation Issues**
These bundles are a hassle to organise by trait, and its incredibly difficult to find the traits you need when a competion comes up or you want to breed specific lines.

**Prim Constraints**
Secondlife also has prim limits on land - and people run out of prims quickly. So ideally you don't want all your bundles out - but this is really the only way to search them (if named well)

**Conclusion**
So - we need a "Viewer" Object that can hold multiple bundles while still exposing the traits for either area search or a search on a website we own (myslhorses.com)

**Objectives**
- Limit Prims on Land
- Make search for specific traits easy
- Make Viewer you can scroll through for bundles. (like a texture viewer)
- Stretch: Automatically add a coat or trait image  in the vendor 
- Stretch: Make Vendor for horses

---

## Project Requirements

### Details
- **Language:** LSL (Second Life script or scripts)
- **Container:** Script is placed inside a box object that I create
- **Contents:** Other objects (no-copy, no-mod) will be placed inside the box

---

## Script Functions
I want to create a script or scripts / tech stack that performs the following functions.

- **Object Discovery & Filtering**
  - Fetch the **name**, **description**, and **owner** of all objects inside the box that:
    - Contain the string `"SUCCESSFUL_BUNDLE"` **OR**
    - Contain `"BOXED_BUNDLES"` in the description  
      - (Note: boxed bundles will use a different script later)
  - Save this data to **Linkset Data**
  - Use the **UUID of each object** as the primary identifier

- **Object Counting**
  - Count the total number of objects in the box
  - This **must update dynamically** if objects are removed from the box
  - Save the count to **Linkset Data**

---

## Linkset Data Shape

### Metadata
- `Total`  
  - Number of valid objects (integer)
- `UUID`  
  - Key/ID of each valid object (string?)
- `Owner_Object`  
  - Owner of the box
- `SlURL`
 - Location or Last Location of this Object

### Object Data
- `UUID`  
  - Key (integer) — fetched from description
- `Name`  
  - Object name (string)
- `OwnerName`  
  - Object owner name
- `Stats`  
  - `Stats_Object`

### Owner_Object
- `Name`  
  - Owner name (string)
- `Id`  
  - Owner ID (string?)

### Stats_Object
- `UUID`  
  - Key/ID (string)
- `Description`  
  - Object description (string)
- `Name`  
  - Object name (string)
- `Price`  
  - Positive integer
- `Stats`  
  - Long string  
  - ❓ *What is the character limit on SL string data?*
- `WebLising`
  - Associated [Amaretto Lineage Page](https://amarettobreedables.com/horse-lineage) for this horse 
  - Example (Bundle with UUID `0c9b8a1c-ad7b-c16a-0f51-41d809e5b6e5`): `https://amarettobreedables.com/bundleData.php?id=0c9b8a1c-ad7b-c16a-0f51-41d809e5b6e5`
  - Example (Horse with UUID `00c7a030-9664-fccf-667e-0b497cf0f2f3`): `https://amarettobreedables.com/horseData.php?id=00c7a030-9664-fccf-667e-0b497cf0f2f3`
- `Location` (opt)
  - Will be the same as the slurl for the box. So may not be necessary.
  - Example slurl: `secondlife://Anarchy/143/164/4005`

---

## Script Requirements

### Touch Menu

- **Owner-only options**
  - `Start` — starts configuration/scripts
  - `Stop` — stops scripts
  - `Reset` — resets scripts and wipes saved linkset data
  - `Name` — set the box name
  - `Text On`
  - `Text Off`
  - `Set Logo`
  - `Give Help Notecard`
  - `Add Price`
    - Sub-menu:
      - `Price One`
      - `Price All`  
        - Cycles through each object in the box and prompts the user to input a price

- **General options**
  - `Give Stats Notecard`
  - `Give Landmark`

---

## Useful References

- [Second Life LSL Portal](https://wiki.secondlife.com/wiki/LSL_Portal) (LSL scripting reference): Ensure Any scripts can be run

- [Secondlife Forum](https://community.secondlife.com/forums) : Lots of questions on how to script different things and possibilities for getting around the limits of secondlife

- [Secondlife Wiki](https://wiki.secondlife.com/wiki/) : useful reference

- [Amaretto Horse & Bundle API](https://horse.amaretto.wiki/index.php/API_Info) : Read Only - useful decoder of *some* traits 

- [Amaretto Lineage Site](https://amarettobreedables.com/horse-lineage/) : Shows lineage of horses and can search by UUID (unsure if auth is required)

- [Amaretto Traits](https://horse.amaretto.wiki/index.php/List_of_Horse_Traits) : 1000s of Amaretto horse traits listed here

- [Amaretto Main Website](https://amarettobreedables.com/) : Monthly competitions and new limited edition horses + other info

- [Writing text to a notecard forum reference](https://community.secondlife.com/forums/topic/361128-can-you-use-a-script-to-write-text-to-a-notecard/) : How to get data in and out of secondlife 

- [Running Bots](https://community.secondlife.com/forums/topic/489794-run-own-bot-from-home-server-without-smartbots/) : May be needed to fully automate other projects or future features

---

# DEPRECATED NOTES

## User Input Flow

1. **Enter Bundle Description**
   - Enter bundle description for the object
   - Provide a help notecard  
     *(Important for my library)*

2. **Enter Stats**
   - Stats (including name) are captured from local chat
   - Confirm:
     - UUID
     - Stats (especially UUID correctness)
