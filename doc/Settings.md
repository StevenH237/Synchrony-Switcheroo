Switcheroo has many customizations available via Custom Rules. Those settings are as follows:

# Slot chances
This controls chances of slots having their items changed. Note that the spell section always counts as having two separate slots. As for charms, check the [charms settings](#charms-settings) to see how those slots are calculated.

* **Empty slot pick chance**: This is the chance that each empty slot that exists gets picked.
* **Filled slot pick chance**: This is the chance that each filled slot that exists gets picked.
* **Slot fill chance**: This is the chance that an item attempts to generate for each selected slot. If a slot is selected and then this roll fails, the slot is left without an item (except for shovel or weapon, in which case the basic shovel or dagger will be used).
* **Minimum slots**: This is the lowest number of slots that can be picked. 0% pick chances override this, but if at least this many are eligible, this many will be picked regardless of percentage chances.
* **Maximum slots**: This is the highest number of slots that can be picked.

# Allowed slots
This controls which specific slots can be selected to have their items changed. Note that cursed slots can't be selected, regardless of the values of these settings.

* **Set all...**: Selecting an option from this sub-menu sets all the options on this page to the selected value.
* **(slot)**:
  * **No**: This slot cannot be modified by Switcheroo.
  * **Yes**: This slot can be modified by Switcheroo, but item bans are respected.
  * **Unlocked**: This slot can be modified by Switcheroo, ignoring item bans.

# Charms settings
Charms are tricky! Technically you have infinite slots here, but we don't want to just fill it completely, do we? These settings limit how fast and how much those slots can fill up.

* **Max new charms**: How many new charms can the player get per floor?
* **Max charms from new**: How many total charms can the player get through new charms from the mod?

Note that these settings don't delete charms if you have more than the "max charms from new" value. More specifically, the number of charms slots you have is treated as the median of:

* The number of charms you have
* The number of charms you have, plus the "max new charms" value
* The "max charms from new" value

# Allowed floors
This page lets you control which floors the mod may activate on. Yes or no influences that particular floor. The available presets are as follows:

* **Every floor**: Every floor is set to "on".
* **Every odd floor**: Every -1, -3, and 5-5 are set to "on"; the rest to "off".
* **Every even floor**: Every -2 and -4 are set to "on"; the rest to "off".
* **First and boss floors**: Every -1, -4, and 5-5 are set to "on"; the rest to "off".
* **First floor of zone**: Every -1 is set to "on"; the rest to "off".
* **Boss floor of zone**: Every -4 and 5-5 is set to "on"; the rest to "off".
* **At start of run**: 1-1 is set to "on"; the rest to "off".

# Other settings
These settings are just on the first page of settings.

* **Generator type**: This selects the algorithm which is used to select items for random builds.
* **Sell items**: Items that are removed from the player are sold for this percent of the Pawnbroker price.
* **Guaranteed transmutations**: Items that have a fixed transmute result are guaranteed to be transmuted according to that result, *if* they are replaced and not deleted. For vanilla items, this affects only the Ring of Becoming turning into a Ring of Wonder.
* **Ignore non-pool items**: Items that are not in random pools cannot be removed or replaced by the mod if this setting is on.
* **Forbid instakill items**: Items that cause the player to die in a single hit cannot be given by the mod if this setting is on.