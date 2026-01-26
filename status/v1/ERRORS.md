## Errors

1. **Not finding all horses within range** <br/>
Check:
- check sensor logic and range logic.
- check distance measurements
- check sensor "shape" (should be a circle -> or perhaps add the shape "type" to the menu if easy)
- Ideally rez a particle field at the edge of the sensor field when setting range so its easy to see whats included

See `Sensoring in LSL notes`

---

## **Pregnancy & Fervor Information**

- For accurate fervor and pregnancy calculations: [see this page](https://amarettobreedables.com/connections/news/%F0%9F%93%85-the-ultimate-guide-to-amaretto-horse-pregnancy-and-fervor-calculators-%F0%9F%90%8E%F0%9F%92%9A-r816/) 

- Fervor Times Image:
<img width="346" height="725" alt="image" src="https://github.com/user-attachments/assets/6c3d8587-b449-46b7-b4a8-1fd11c0cf655" />

- Pregnancy Times Image:
<img width="466" height="607" alt="image" src="https://github.com/user-attachments/assets/9a1c6252-382d-411a-a1ef-99126cd30a04" />

- Pregancy Contraints (**Important Information**): [See this guide](https://amarettobreedables.com/connections/news/amaretto-breeding-times-r527/)
  - Horses can start breeding at 7 days old
  - Horses need 100% fervor to breed
  - Fervor takes 2-3 days to go from 0 to 100% (timings above)
  - (mares only) Pregnancy takes **3 days**
  - (mares only) Pregnancy Recovery (after birthing a "bundle") is **4 days**
    - The average time a female takes to breed is therefore about **9 days** (fervor: 2-3 -> pregnancy: 3 -> pregnancy recovery -> 4)
  - Horses can breed until they are 120 days old
  - Horses can be given consumables to increase fervor, shorten pregnancy decrease hunger and other settings.

  Additional notes:
  - Happiness must be 75% to gain fervor

- Interesting - **but not relevant to calculation**: [Festive Drops Info](https://amarettobreedables.com/connections/news/smart-breeding-101-r931/)

---


## Sensoring in LSL notes
In Second Life (LSL), if `llSensor` or `llSensorRepeat` are missing objects, it is likely due to limitations in how the simulator processes them, particularly regarding object center points, attachment detection, or rate limits. 

Here are the best ways to sense objects, ranging from improved sensor usage to more reliable methods:

1. **Optimize `llSensor` (The Quickest Fix)**
Sensors only detect objects if the center of their root prim is within the cone, and they cannot detect attachments on avatars. To improve reliability: 
- Avoid using llSensor in a timer event. Use llSensorRepeat instead, as it is generally more stable.
- Increase the range and arc: Use a full sphere (PI) and a reasonable range (up to 96m).
- Filter explicitly: Use AGENT | ACTIVE | PASSIVE to ensure you are catching everything (physical, non-physical, and avatars).
- Handle "No Sensor": Always use the no_sensor event to reset your logic when the object moves away.


2. [TRY] **Use `llGetRegionCollidingObjects` (Most Reliable for Physical)**
If you are trying to detect **physical objects** (like balls in a game), `llGetRegionCollidingObjects` **is superior**. It checks for collision volumes within a bounding box rather than a cone-shaped sensor field.


3. [NO] Collision/Attachment Events (Best for Immediate Interaction)
If the object you are sensing is meant to touch your sensor, or if you are trying to detect an avatar's proximity:
collision_start / collision_end: These are instantaneous and do not rely on a sweep timer.
touch_start: Allows user-initiated interaction. 


4. [NOT FOR NO-MOD?] Direct Communication (Best for Known Objects)
If you are trying to detect **objects that you have rezzed or own** (e.g., in a, vendor or **breedable system**), _do not use a sensor at all._ 
- `llRegionSay` / `llRegionSayTo`: Have the detected object send its location to your controller object. This is 100% accurate and instant, bypassing all sensor limitations. 


5. [NO] `llGetAgentList` (Best for Avatar Sensing) 
If you need to know which avatars are nearby, llGetAgentList is much faster and more accurate than llSensor. 


Why Your Sensor is Missing Objects (Common Caveats)
- [NO] Attachment Issue: Sensors cannot detect attachments (HUDs, jewelry, etc.).
- [NO] Center Point Failure: Only the center of the root prim counts. A huge object can be right next to you, but if its center is 1cm outside your range, it is not detected.
- [NO] Sim Crossing: Sensors can miss items near sim borders or across them.
- [NO] Too Fast: If you are rezzing objects, you must wait a few seconds before the sensor will detect them. 


### Summary Recommendation:
- For avatars, use llGetAgentList.
- For **physical objects**, use `llGetRegionCollidingObjects` or _collision_start_.
- For generic objects, use `llSensorRepeat` **with 360-degree range**, ensuring the target object's center is within that radius. 
