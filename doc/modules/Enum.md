`local SwEnum = require "Switcheroo.Enum"`

Note: All names given are in English, but they are localizable.

# `AllowedFloors`: enum (bitmask)
| Key                  |      Value | Name                         | Description                                                                          |
| :------------------- | ---------: | :--------------------------- | :----------------------------------------------------------------------------------- |
| `DEPTH_1_LEVEL_1`    |        0x1 | Depth 1-1                    | This setting always means the first floor of a dungeon, even in custom dungeons.     |
| `DEPTH_1_LEVEL_2`    |        0x2 | Depth 1-2                    |                                                                                      |
| `DEPTH_1_LEVEL_3`    |        0x4 | Depth 1-3                    |                                                                                      |
| `DEPTH_1_LEVEL_4`    |        0x8 | Depth 1-4                    |                                                                                      |
| `DEPTH_2_LEVEL_1`    |       0x10 | Depth 2-1                    |                                                                                      |
| `DEPTH_2_LEVEL_2`    |       0x20 | Depth 2-2                    |                                                                                      |
| `DEPTH_2_LEVEL_3`    |       0x40 | Depth 2-3                    |                                                                                      |
| `DEPTH_2_LEVEL_4`    |       0x80 | Depth 2-4                    |                                                                                      |
| `DEPTH_3_LEVEL_1`    |      0x100 | Depth 3-1                    |                                                                                      |
| `DEPTH_3_LEVEL_2`    |      0x200 | Depth 3-2                    |                                                                                      |
| `DEPTH_3_LEVEL_3`    |      0x400 | Depth 3-3                    |                                                                                      |
| `DEPTH_3_LEVEL_4`    |      0x800 | Depth 3-4                    |                                                                                      |
| `DEPTH_4_LEVEL_1`    |     0x1000 | Depth 4-1                    |                                                                                      |
| `DEPTH_4_LEVEL_2`    |     0x2000 | Depth 4-2                    |                                                                                      |
| `DEPTH_4_LEVEL_3`    |     0x4000 | Depth 4-3                    |                                                                                      |
| `DEPTH_4_LEVEL_4`    |     0x8000 | Depth 4-4                    |                                                                                      |
| `DEPTH_5_LEVEL_1`    |    0x10000 | Depth 5-1                    |                                                                                      |
| `DEPTH_5_LEVEL_2`    |    0x20000 | Depth 5-2                    |                                                                                      |
| `DEPTH_5_LEVEL_3`    |    0x40000 | Depth 5-3                    |                                                                                      |
| `DEPTH_5_LEVEL_4`    |    0x80000 | Depth 5-4                    |                                                                                      |
| `EXTRA_BOSS`         |  0x1000000 | Extra story boss             | For Cadence, Necrodancer. For Nocturna, The Conductor.                               |
| `RAW_FLOOR_NUMBERS`  |  0x2000000 | Raw floor numbers above      | Treat the first 20 bits as raw floor numbers 1-20 instead of specific floors/depths. |
| `TRAINING_FLOORS`    |  0x4000000 | Training floors              | Should the mod activate on training floors?                                          |
| `EXTRA_BOSS_FLOORS`  | 0x10000000 | Add extra/custom boss floors | In a custom dungeon or custom zone, should the mod activate on boss floors?          |
| `EXTRA_POST_BOSSES`  | 0x20000000 | Add extra post-boss floors   | In a custom dungeon or custom zone, should the mod activate after boss floors?       |
| `EXTRA_OTHER_FLOORS` | 0x40000000 | Add other extra floors       | In a custom dungeon or custom zone, should the mod activate on other floors?         |

# `CharmsAlgorithm`: enum (sequence)
Note: There used to be more entries here but they got removed. The enum still exists for future compatibility.

| Key       | Value | Name   | Description                                  |
| :-------- | ----: | :----- | :------------------------------------------- |
| `ADD_ONE` |     1 | Simple | Each floor, add one new charm up to a limit. |

# `DontGiveGold`: enum (sequence)
| Key           | Value | Name        | Description                                                                |
| :------------ | ----: | :---------- | :------------------------------------------------------------------------- |
| `DONT_BAN`    |     0 | Don't ban   | The item can be given by the mod (is not banned).                          |
| `BAN`         |     1 | Ban         | The item cannot be given by the mod (is banned).                           |
| `DYNAMIC_BAN` |     2 | Dynamic ban | The item can be given by the mod iff the player has no gold (dynamic ban). |

# `DontTake`: enum (sequence)
| Key             | Value | Name                 | Description                                                   |
| :-------------- | ----: | :------------------- | :------------------------------------------------------------ |
| `TAKE`          |     0 | Take item            | The item can be taken by the mod under any circumstance.      |
| `TAKE_IF_GIVEN` |     1 | Take if given by mod | The item can be taken by the mod iff it was given by the mod. |
| `DONT_TAKE`     |     2 | Don't take item      | The item cannot be taken by the mod under any circumstance.   |

# `FloorPresets`: enum (sequence)
| Key             |      Value | Name               | Description                                                                                        |
| :-------------- | ---------: | :----------------- | :------------------------------------------------------------------------------------------------- |
| `ALL_FLOORS`    | 0x750FFFFF | All floors         | Activate on all floors.                                                                            |
| `FIRST_OF_ZONE` | 0x24011111 | First of each zone | The first floor of each zone, or 1F and the floor immediately following a boss in custom dungeons. |
| `START_OF_RUN`  | 0x04000001 | Start of run only  | Only the first floor of a run (1-1 in all zones, 1F in custom dungeons). Also training floors.     |
| `POST_BOSSES`   | 0x20011110 | After every boss   | The floor immediately following each boss. Excludes 1F and training floors.                        |

# `ReplaceMode`: enum (sequence)
| Key          | Value | Name                   | Description                                                 |
| :----------- | ----: | :--------------------- | :---------------------------------------------------------- |
| `EMPTY`      |     2 | Fill empty slots       | The mod will activate only to fill empty slots.             |
| `EVERYTHING` |     3 | Fill and replace       | The mod will activate to fill empty and replace full slots. |
| `EXISTING`   |     1 | Replace existing items | The mod will activate only to replace full slots.           |

# `Slots`: enum (sequence) / `SlotsBitmask`: enum (bitmask)
| Key       | Value (sequence) | Value (bitmask) | Name             | Note                                                    |
| :-------- | ---------------: | --------------: | :--------------- | :------------------------------------------------------ |
| `ACTION`  |                1 |             0x1 | Item             |                                                         |
| `SHOVEL`  |                2 |             0x2 | Shovel           |                                                         |
| `WEAPON`  |                3 |             0x4 | Weapon           |                                                         |
| `BODY`    |                4 |             0x8 | Body             |                                                         |
| `HEAD`    |                5 |            0x10 | Head             |                                                         |
| `FEET`    |                6 |            0x20 | Feet             |                                                         |
| `TORCH`   |                7 |            0x40 | Torch            |                                                         |
| `RING`    |                8 |            0x80 | Ring             |                                                         |
| `MISC`    |                9 |           0x100 | Charms           |                                                         |
| `SPELL`   |               10 |           0x200 | Spells           |                                                         |
| `HOLSTER` |               11 |           0x400 | Holstered weapon |                                                         |
| `SHIELD`  |               12 |           0x800 | Shield           | This is only available if the Synchrony DLC is enabled. |

# `SlotPresets`: enum (sequence)
| Key                      | Value | Name                                | Description                                     | Note                                                    |
| :----------------------- | ----: | :---------------------------------- | :---------------------------------------------- | :------------------------------------------------------ |
| `ALL_SLOTS`              | 0xFFF | All slots                           | Every slot.                                     |                                                         |
| `ALL_BUT_WEAPON`         | 0xBFB | All slots except weapons            | Excludes weapon and holstered weapon.           |                                                         |
| `ALL_BUT_HOLSTER`        | 0xBFF | All slots except holster            | Excludes holstered weapon, but includes weapon. |                                                         |
| `NO_SLOTS`               | 0x000 | No slots                            | No slots.                                       |                                                         |
| `ALL_BUT_SHIELD`         | 0x7FF | All slots except shield             | Excludes shield slot.                           | This is only available if the Synchrony DLC is enabled. |
| `ALL_BUT_WEAPON_SHIELD`  | 0x3FB | All slots except shield and weapons | Excludes weapon, holster, and shield.           | This is only available if the Synchrony DLC is enabled. |
| `ALL_BUT_HOLSTER_SHIELD` | 0x3FF | All slots except shield and holster | Excludes holstered weapon and shield.           | This is only available if the Synchrony DLC is enabled. |
