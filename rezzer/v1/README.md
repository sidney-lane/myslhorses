# Horse Pod Rezzer

This script will rezz horses (no copy, no mod) in formations as defined by the user (6 horses only) from a box prim they are dropped in.

The script will rez (copy) ojects in the position chosen by the user when chosen, so a user can see where items will rez.
These ojects will be derezzed (killed) once the user selects "Rez" to rez horses instead.

Formations (6 horses)
1. Star
M   M   M

    S
   
M      M

3. T
M  M  M  M

    SM

5. Triangle
M  M  M

 M  M
 
   S

7. Line
M  M  SM  M  M

8. Up/Down
Up: M  M  M  M

Down: SM


Script will
- Auto detect the Male horse (and rez it in "S" - Stud position (if more than one - will just use first stud)
- Auto detect mare with most fervour to place in "primary" position near stud

Menu driven
- start/stop/reset (Scripts)
- pod/all (either rez a pod with a stud and mares OR just rezz all horses)

#### Data: Horse API
**Horse API:**

00000000-0000-0000-0000-000000000000:O111025:1359:0:99:0:100:1:0:0:214.97.51:0:V7.0

Specific ID:Settings info:age:hunger:energy:fervor:happiness:gender:pairing:pregval:home:breed:version

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

#### Notes on rez/derez

Rezzer stores COPY items in inventory
- llRezObject() places them in-world
- Derez = llDie() on the rezzed objects (ONLY THE COPY OBJECTS)


# Bundle Rezzer
- Bundle (no copy, no mod) items
- related to organiser project
