LSL script + supabase backend + write to github pages / cloudflare? so that we can put status on a media prim face

## Documentation
- Requirements: [REQUIREMENTS.md](./REQUIREMENTS.md)
- Technical Architecture: [TECHNICAL_ARCHITECTURE.md](./TECHNICAL_ARCHITECTURE.md)
- Build Steps: [BUILD_STEPS.md](./BUILD_STEPS.md)

### Display board (should be able to "link" to other display boards - ie there will be a "master" display board and then individual "pod" boards)
Board Has:
- Project/Pod Title
- Horses within (X)m range with status (see below)

#### Horse Status Displays
1. Gender, Age & Name of Horse
2. (if over 7 days) 
  - Pregnancy status (with time to drop) OR 
  - Fervour status with time to 100% OR
  - pregnancy recovery status with time to recovered OR
  (if under 7 days) 
  - Time of birth + time to 7 days old (if possible) 
3. 

### Board Requirements
- Using Faces of an oject (to minimise prims)
- Uses Media Display Textures (we need this to auto refresh itseld since media prims tend to turn "off")
- Must scan every minute? (dont want lag) for updates on the horses

#### Horse API

**Horse API** (in horse description field)
00000000-0000-0000-0000-000000000000:O111025:1359:0:99:0:100:1:0:0:214.97.51:0:V7.0

Specific-UUID:Settings info:age:hunger:energy:fervor:happiness:gender:pairing:pregval:home:breed:version

**SETTINGS Block:**
O - Mode: (O)wner (G)roup (A)ll
1 - Movement
1 - Animations
1 - Text
0 - Sounds
2 - Foodtype
5 - Range ( Can be 2 digits )

**Gender:**
1 is Male
2 is Female

#### Menu-driven (owner only / group only / all)
- start / stop / reset (scripts) > should start automatically if rezzed
- permissions (owner only / group only / all)
- set range (up to 15m) - integer
- change hover text color (8 options - cause fits on object)
- [stretch] confirm horses found (in a pod) - may want to ignore some found



## POC: Use hover text on faces first (max 15 horses)



#### MOAP (Media on a Prim) Issues
Media on a Prim (MOAP) frequently turning off in Second Life is usually caused by viewer settings, script issues, or network instability. Because MOAP relies on streaming content through the viewer's browser (slplugin.exe), it is easily interrupted. 
Here are the most common solutions, ranging from viewer settings to script fixes.

**1. Adjust Viewer Settings (Firestorm/Default)**
Enable Media Autoplay: Go to Preferences > Sound & Media. Make sure "Allow media auto-play" is checked.
Whitelist Media Plugins: If you use anti-virus or firewall software, ensure slplugin.exe is whitelisted.
Toggle "Touch to Play": Sometimes viewers do not respect autoplay. Try left-clicking the media face to "activate" it, which signals your viewer that you want to watch it.
Clear Cache: A corrupt cache can cause media to fail. Go to Preferences > Network & Cache > Clear Cache, then restart your viewer. 

**2. Fix Scripted Objects (If you own the media)**
If the TV or media player is not yours, you may need to ask the creator to check the script.
- Remove "Clear Media" Command: Ensure the script in the prim does not have a llClearPrimMedia() command triggered by a timer or script reset.
- Use Loop/Refresh Logic: Re-apply the media URL on a timer (e.g., every 60 seconds) to prevent it from stalling.
- Set Permissions: Ensure the prim is set to PRIM_MEDIA_PERMS_CONTROL for the owner, or NONE to prevent other users from accidentally turning it off. 

**3. Parcel and Network Fixes**
Remove Parcel Media Conflict: If the parcel has a music/video URL set in About Land > Media, it may conflict with the object-based media on a prim. Clear the URL in the parcel settings.
Check Bandwidth: If your bandwidth is set too high or too low, the stream will cut out. Try setting it to a default or moderate value (e.g., 1500–3000 kbps in Firestorm).
Check for Nearby "Spam" Media: Another, closer, or larger object might be stealing your browser's attention. If a neighboring parcel is running a high-bandwidth video, it can cause your own media to fail. 

**4. Direct Fixes for Common Issues**
- Object Disappears/Resets: **If the media turns off after a re-log, the script is likely not saving the state.** The script needs to be edited to remember the URL.
Black Screen/No Sound: Ensure Enable plugins is checked in Preferences > Network & Cache.

**Summary Checklist:**
Verify "Allow media auto-play" is checked.
Clear viewer cache.
Touch the screen to manually start it.
Check if the object script is resetting. 
