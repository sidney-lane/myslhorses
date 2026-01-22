The idea of this script is to lock all HORSE AND/OR Bundle objects (in the object properties tab) TO HELP PREVENT accidental deletion or return of horses.

## Function
It should
- only lock horse and or bundle objects (verified by their description string
- only lock food salt, and other consumable objects (verified by description string)

## Implementation Details
- May be able to select by creator for ALL rather than need to find them (`JJ Cerna`)
- Use Config flags for variables that may change or could be modular.
- 

## Menu
It should be menu driven and include
- start / stop / reset (script) buttons
- Unlock / Lock selections. followed by:
    - select: Lock Horses, Bundles, Consumables, All
    - lock/unlock by owner/group /all (maybe if possible)
    - list objects to lock (save it to linkset data maybe) 
    - Ask for user approval to lock/unlock the list (output to chat or similar)
- ? set range [or other way to find the objects to lock - parcel? land? owner? group?) (a range for locking NOTE: make sure you verify how many objects you can fetch within a range - otherwise a 96m range that does not get ALL objects in that range is useless)


## Data Information:
NOTE: some versions may have slightly different formats.. for now limit to v7.0

Horse API: **Description Field of Object**

DescriptionDataStringFormat: `00000000-0000-0000-0000-000000000000:O111025:1359:0:99:0:100:1:0:0:214.97.51:0:V7.0`

Translation: `Specific ID:Settings info:age:hunger:energy:fervor:happiness:gender:pairing:pregval:home:breed:version`

Bundle API: **Description Field of Object**

DescriptionDataStringFormat: `SUCCESSFUL_BUNDLE:00000000-0000-0000-0000-000000000000!164!0!1!5!0!0!1!0!0!6!0!0!4:NULL:7.0`

`STATUS:key!breed!mane!tail!eye!gleam!hairgleam!luster!hairluster!gloom!hairgloom!opal!hairopal!branding:RSVD:Version`

SETTINGS Block:

- O - Mode: (O)wner (G)roup (A)ll
- 1 - Movement
- 1 - Animations
- 1 - Text
- 0 - Sounds
- 2 - Foodtype
- 5 - Range ( Can be 2 digits )

Gender:
- 1 is Male
- 2 is Female

## Data Examples

Bundles see repo root/data/bundle file
