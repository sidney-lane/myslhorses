I want to make a script that has the following script
Details:
- LSL secondlife script (or scripts)
- Placed in box object I make
- Other (no copy, no mod) Objects will be placed in the box

Script Functions
- Fetches name, description & owner of all objects in the box object that have "SUCCESSFUL_BUNDLE" string OR have "BOXED_BUNDLES" in description (this boxed bundles item will have a different script - later)
  - Saves to the Box Linkset as Data. (uses UUID of object for this)
- Counts number of objects in the box Object (alongside it)
   -> this MUST update if objects are taken OUT of the box. 
  -> saves this to linkset data 
- 

Linkset Data Object
- Metadata
  -> Total: Number of (valid) Objects (integer)
  -> UUID: key/ID of each (valid) Object (string?)
  -> Owner of Box (Owner_Object)
- Object Data
  -> UUID: key (integer) [fetched from description]
  -> Name: object Name (string)
  -> OwnerName (object owner)
  -> Stats (Stats_Object)
- Owner_Object
  -> Name (string)
  -> Id (string?)
- Stats_Object
  -> UUID: key/id (string)
  -> Description (string)
  -> Name (string)
  -> Price (positive integer) 
  -> Stats (long string - what is the char limit on SL string data?)
 
  


Script requirements
- Menu on Touch
 -> Start (owner only): starts the config / scripts
 -> Stop (owner only): stops the scripts
 -> Reset (owner only): resets the scripts & wipes saved linkset data
-> Name (owner only): names the box
-> Text On (owner only)
-> Text Off (owner only)
-> Set Logo (owner only)
-> Give Help Notecard (owner of box only)
-> Add Price (owner only) 
    - second menu 
        - Price One
        - Price All (will cycle through each object in the box for user to input a price)
        - 
-> Give Stats Notecard
-> Give Landmark


Useful references:
- https://community.secondlife.com/forums/topic/361128-can-you-use-a-script-to-write-text-to-a-notecard/
- https://wiki.secondlife.com/wiki/ 
- 




 
1. Enter Bundle Description of Object 
    -> share notecard help...  (important for my library)
1. Enter Stats (include name) from local chat 
    -> confirm UUID and stats (especially UUID)
