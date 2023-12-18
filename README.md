# Obiter Dicta

This creates a Limbus Company REPL Mode.
 
## Installation

1. Download Julia. (This is not compatable with the LTS version, please use the current stable release.)
2. In Julia, enter `]add https://github.com/SyxP/ObiterDicta.jl` (or `]add https://limbus.wiki`)
3. To run, in Julia mode (you should see `julia>`, if not press Backspace), enter `using ObiterDicta`. 
4. You can now freely access the `Limbus Query>` mode via `)`. Use `help` to see the list of commands and 
for each command `_command_ help` would access the command specific help.
5. In the future, when updates have been made, you can use `]up` to update the package directly. 

## Uninstalling

1. In Julia, enter `]rm ObiterDicta`
2. If you wish to also remove all the data bundle files, `]gc`. Note that upon uninstalling,
doing other processes in Julia may delete the data bundle files! If you wish to keep them,
do back them up.

## Other Sources

Chinese translations are from https://github.com/LocalizeLimbusCompany/LocalizeLimbusCompany

Russian translations are from https://github.com/Crescent-Corporation/LimbusCompanyBusRUS

## Features

### General

1. EXP Tables (100%)
2. Buffs / Status Effects (100%)
3. Skills (100%)
4. Identities (100%)
5. E.G.O (100%)
6. Passives (100%)
7. Enemy Information (0%)
8. Uptie/Threadspin Comparator (0%)
9. Clash Calculator (40%)
10. Damage Calculator (0%)

### Story Data 

1. Main Story Text (0%)
2. Main Story - Drop Rates (0%)
3. Main Story - Enemies (0%)
4. Main Story - Dungeons (0%)
5. Main Story - E.G.O Gifts (100%)
6. Main Story - Choice Events (0%)

### Specific Game Modes

1. Mirror Dungeon - E.G.O Gifts (100%)
2. Mirror Dungeon - Choice Events (0%)
3. Mirror Dungeon - List of Fights (0%)
4. Mirror Dungeon - Drop Rates (0%)
5. Luxcavation - Enemies (0%)
6. Refraction Railway 1 - Enemies (0%)
7. Refraction Railway 2 - Enemies (0%)
8. Refraction Railway 2 - Buffs (0%)

For Mirror Dungeon, as the content may be revamp in the near future, may require specific backups to ensure the data is not lost.
1. Mirror Dungeon 1 and 2 - List of Fights (0%)
2. Mirror Dungeon 2 - Starlight Buffs (20%)
3. Mirror Dungeon 3 - Fusion Mechanics (0%)
4. Mirror Dungeon 3 - Fusion Calculator (0%)
5. Mirror Dungeon 3 - Starlight Buffs (0%)

### Miscellaneous Story

1. Dante's Notes (0%)
2. Abnormality Observation Levels (0%)
3. Identity Uptie Stories (0%)

### Miscellaneous Utility

1. Item IDs (0%)
2. Battle Pass Information (0%)
3. Voice Lines - Announcer (0%)
4. Voice Lines - Identity (100%)
5. Choice Event Identity Check Text (0%)
6. Profile Card Information (100%)
7. Automatic Updating of Bundles (100%)

### Known Bugs/Specific Requested Features

1. Let Damage Type be localized
2. Fix printing of id-voice with non-English language.

### Immediate Upcoming Plans

1. Choice Events printing
2. Enemy printing