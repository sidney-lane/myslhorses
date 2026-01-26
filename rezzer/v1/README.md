# Horse Pod Rezzer

This script will rezz horses (no copy, no mod) in formations as defined by the user (6 horses only) from a box prim they are dropped in.

The script will rez (copy) ojects in the position chosen by the user when chosen, so a user can see where items will rez.
The user will be able to select from a predefined pattern (below) OR custom placement (X number of prims - chosen by user (up to 10) can be rezzed in custom mode - the user will put them in the pattern the want and this custom pattern can be saved with a name in the script also for future use).

They will rezz within a 5m radius. for Formation 1-4. For 5: up/down - up should be at 6m above down.

These prim ojects will be derezzed (killed) once the user selects "Rez" and the horses (dropped into root prim) will be rezzed in their position instead. 

#### Formations (6 horses)

Key: 
- S = Male / STUD
- M = Female / Mare
- PM = Primary female/mare (mare with most fevor)

1. Star

```
M      M

  S PM
   
M      M
```

2. T

```
M  M  M  M

   S PM
```

3. Triangle

```
M  M  M

 PM  M
 
  S
```

4. Line

```
M  M  PM S  M  M
```

5. Up/Down

```
Up: M  M  M  M

Down: S PM
```

6. Cutom Mode (described above)
   
Custom placement of X number of 'rezzer prims' - chosen by user (up to 12) can be rezzed in custom mode - the user will put them in the formation they want and this custom pattern can be saved with a name in the script also for future use).
- select 1 male or 2 males (we will use male and female "rezzer prims" inside the control rezzer prim to make it easy)
- save custom position (with name)

7. Double POD (v2 version)
Selection on 
Will rez 2 "formations".

#### Script function
- Auto detect the Male horse (and rez it in "S" - Stud position (if more than one - will just use first stud dropped in)
- Auto detect mare with most fervour to place in "primary" position near stud.
- 

#### Menu driven commands
- start/stop/reset (Scripts)
- creator only debug option
- choose formation
     - choose 1 or 2 "pods" (2 pods has 2 males) 
- custom formation
     - choose number of horses (up to 12)
     - choose number of males (1 or 2)
     - choose "Base formation" - ie choose one of the predefined formations to start the custom rez from
     - place rezzer prims (within 20m ? any constraints on distance?)
     - save as (name)
- 'just rez' mode (line with settings)
     - rez horses in a line
     - select number: "rez 1", "rez X" (user input), "rez all"
     - select distance apart (0.5m -> 5m in 0.5m intervals)
- 

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
- related to organiser project.
