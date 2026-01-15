# Project Details

---

## Overview

I want to create a script that performs the following functions.

---

## Project Requirements

### Details
- **Language:** LSL (Second Life script or scripts)
- **Container:** Script is placed inside a box object that I create
- **Contents:** Other objects (no-copy, no-mod) will be placed inside the box

---

## Script Functions

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

- Writing text to a notecard:  
  https://community.secondlife.com/forums/topic/361128-can-you-use-a-script-to-write-text-to-a-notecard/

- Second Life Wiki (LSL reference):  
  https://wiki.secondlife.com/wiki/

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
