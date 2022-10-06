Components available in Switcheroo:

# `Swticheroo_itemPoolSwitcheroo`
A custom item pool.

# `Switcheroo_noGive`
Items with this component are not given by the randomizer.

There are no fields or constants on this component.

It is not hardcoded to any entities. However, it is automatically assigned to or removed from items during an entity schema regeneration, depending on player-selected settings. The mod's default settings assign it to:

* Any entity with the `itemIncomingDamageMultiplier` component.
* Any entity with the `itemIncomingDamageIncrease` component.
* Any entity with the `itemMoveAmplifier` component.
* Any entity with the `consumableHeal` component where `overheal = true`.

# `Switcheroo_noGiveIfBroke`
Items with this component are not given by the randomizer, iff the player has no gold.

It is not hardcoded to any entities. However, it is automatically assigned to or removed from items during an entity schema regeneration, depending on player-selected settings. The mod's default settings assign it to:

* Any entity with the `itemBanPoverty` component.
* Any entity with the `itemBanKillPoverty` component.
* The entities `RingGold` and `RingGoldUncertain`.

# `Switcheroo_noTake`
Items with this component are not taken by the randomizer.

This component contains the following fields:

* `unlessGiven`: constant boolean, default `false`. If it's `true`, items with this component can be taken by the randomizer iff they were given by it.
* `wasGiven`: boolean, default `false`. If it's `true`, the item was given by the randomizer mod, and (if `unlessGiven` is true) can be taken too.

This component isn't hardcoded to any entities. However, it is automatically assigned to or removed from items during an entity schema regeneration, depending on player-selected settings. The mod's default settings assign it to:

* The `HeadCrownGreed` entity: `{ unlessGiven = true }`
* The `CharmLuck` entity: `{ unlessGiven = true }`
* The `Potion` entity: `{ unlessGiven = true }`
* The `RingWonder` entity: `{ unlessGiven = true }`

# `Switcheroo_randomizer`
This component links a player to their Switcheroo randomizer, to keep items more or less consistent between seeds and runs.

This component contains the following field:

* `entity`: entityID, default `nil`.

This component is, by default, given to all `playableCharacter` entities.