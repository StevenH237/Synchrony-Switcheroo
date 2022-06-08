Settings formerly available in Switcheroo (all prefixed with `mod.Switcheroo.`):

* `chance`: group
  * `chance.empty`: percent (default `1`)
  * `chance.filled`: percent (default `1`)
  * `chance.maximum`: number (`-1-10000`, default `-1`)
  * `chance.minimum`: number (`0-10000`, default `0`)
  * `chance.new`: percent (default `1`)
* `charms`: group
  * `charms.max`: number (`-1-100`, default `5`)
  * `charms.new`: number (`0-100`, default `1`)
* `components`: group
  * `components.check`: string (default empty)
  * `components.checkexecute`: action
  * `components.giveComponent`: string (default `"itemIncomingDamageIncrease itemBanInnateSpell"`)
  * `components.giveItem`: string (default empty)
  * `components.takeComponent`: string (default `"itemBanInnateSpell"`)
  * `components.takeItem`: string (default `"MiscPotion CharmLuck RingWonder HeadCrownOfGreed"`)
* `deadly`: bool (default `false`)
* `floors`: group
  * `floors.l11`: bool (default `true`)
  * `floors.l12`: bool (default `true`)
  * `floors.l13`: bool (default `true`)
  * `floors.l14`: bool (default `true`)
  * `floors.l21`: bool (default `true`)
  * `floors.l22`: bool (default `true`)
  * `floors.l23`: bool (default `true`)
  * `floors.l24`: bool (default `true`)
  * `floors.l31`: bool (default `true`)
  * `floors.l32`: bool (default `true`)
  * `floors.l33`: bool (default `true`)
  * `floors.l34`: bool (default `true`)
  * `floors.l41`: bool (default `true`)
  * `floors.l42`: bool (default `true`)
  * `floors.l43`: bool (default `true`)
  * `floors.l44`: bool (default `true`)
  * `floors.l51`: bool (default `true`)
  * `floors.l52`: bool (default `true`)
  * `floors.l53`: bool (default `true`)
  * `floors.l54`: bool (default `true`)
  * `floors.l55`: bool (default `true`)
  * `floors.preset`: group
    * `floors.preset.bossofzone`: action
    * `floors.preset.every`: action
    * `floors.preset.everyeven`: action
    * `floors.preset.everyodd`: action
    * `floors.preset.firstandboss`: action
    * `floors.preset.firstfloor`: action
    * `floors.preset.firstofzone`: action
* `guarantees`: bool (default `true`)
* `sell`: percent (`0-2`, default `0`)
* `slots`: group
  * `slots.action`: enum (`enumSlotType`, default `.YES`)
  * `slots.all`: group
    * `slots.all.no`: action
    * `slots.all.once`: action
    * `slots.all.unlock_no`: action
    * `slots.all.unlock_yes`: action
    * `slots.all.unlock`: action
    * `slots.all.yes`: action
  * `slots.body`: enum (`enumSlotType`, default `.YES`)
  * `slots.feet`: enum (`enumSlotType`, default `.YES`)
  * `slots.head`: enum (`enumSlotType`, default `.YES`)
  * `slots.misc`: enum (`enumSlotType`, default `.YES`)
  * `slots.ring`: enum (`enumSlotType`, default `.YES`)
  * `slots.shovel`: enum (`enumSlotType`, default `.YES`)
  * `slots.spell`: enum (`enumSlotType`, default `.YES`)
  * `slots.torch`: enum (`enumSlotType`, default `.YES`)
  * `slots.weapon`: enum (`enumSlotType`, default `.YES`)
* `type`: enum (`enumGenType`, default `.CONJURER`)