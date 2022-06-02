I'm writing this to myself in an attempt to explain how the various methods pass slot objects to each other. It might be helpful to anyone trying to read my code too.

Each single slot object can contain the following properties:

* `slotName` is the name of the slot. This can be any vanilla ND item slot name except `bomb` or `hud`, *or* it can be `holster`.
* `index` is the index of a given item within the slot. Like most things in Lua, it's 1-indexed.
* `contents` is the actual item of the slot.
* `remove` means that a slot should only be emptied and its item not replaced (even if the replacement chance is 100%).
* For a holster slot, `holster` represents the actual holster that gives the "slot".

Additionally, `getAllowedSlots` has *two* return values - empty slots and full slots.