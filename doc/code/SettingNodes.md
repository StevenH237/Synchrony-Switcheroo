* `allowedFloors`: bitflag (flag `SwEnum.AllowedFloors`, default `SwEnum.FloorPresets.ALL_FLOORS`)
* `dontGive`: group
  * `dontGive.advanced`: bool (default `false`)
  * `dontGive.bannedItems`: bool (default `true`)
  * `dontGive.components`: list.component (default `{}`)
  * `dontGive.damageUps`: bool (default `true`)
  * `dontGive.deadlyItems`: bool (default `true`)
  * `dontGive.goldItems`: bool (default `false`)
  * `dontGive.hideAdvanced`: action
  * `dontGive.hideAdvancedLabel`: label
  * `dontGive.items`: list.entity (default `{}`)
  * `dontGive.magicFood`: bool (default `true`)
  * `dontGive.moveAmplifiers`: bool (default `true`)
  * `dontGive.showAdvanced`: action
  * `dontGive.visionReducers`: bool (default `false`)
* `dontTake`: group
  * `dontTake.advanced`: bool (default `false`)
  * `dontTake.alwaysLabel`: label
  * `dontTake.componentsUnlessGiven`: list.component (default `{}`)
  * `dontTake.components`: list.component (default `{}`)
  * `dontTake.crownOfGreed`: enum (`SwEnum.DontTake`, default `.TAKE_IF_GIVEN`)
  * `dontTake.hideAdvanced`: action
  * `dontTake.hideAdvancedLabel`: label
  * `dontTake.items`: list.entity (default `{}`)
  * `dontTake.itemsUnlessGiven`: list.entity (default `{}`)
  * `dontTake.locked`: enum (`SwEnum.DontTake`, default `.DONT_TAKE`)
  * `dontTake.luckyCharm`: enum (`SwEnum.DontTake`, default `.TAKE_IF_GIVEN`)
  * `dontTake.potion`: enum (`SwEnum.DontTake`, default `.TAKE_IF_GIVEN`)
  * `dontTake.ringOfWonder`: enum (`SwEnum.DontTake`, default `.TAKE_IF_GIVEN`)
  * `dontTake.showAdvanced`: action
  * `dontTake.unlessGivenLabel`: label
* `guarantees`: bool (default `true`)
* `other`: group
  * `other.advanced`: bool (default `false`)
  * `other.charms`: group
    * `other.charms.maxAdd`: number (`0-*`, default `1`)
    * `other.charms.maxTotal`: number (`0-*`, default `5`)
  * `other.generator`: enum (`SwEnum.Generators`, default `.CONJURER`)
  * `other.hideAdvanced`: action
  * `other.hideAdvancedLabel`: label
  * `other.slots`: group
    * `other.slots.allowed`: bitflag (flag `SwEnum.SlotsBitmask`, default `SwEnum.SlotPresets.ALL_SLOTS`)
    * `other.slots.capacity`: number (`0-*`, default `3`)
    * `other.slots.oneTime`: bitflag (flag `SwEnum.SlotsBitmask`, default `SwEnum.SlotPresets.NO_SLOTS`)
    * `other.slots.reduce`: boolean (default `true`)
    * `other.slots.unlocked`: bitflag (flag `SwEnum.SlotsBitmask`, default `SwEnum.SlotPresets.NO_SLOTS`)
* `replacement`: group
  * `replacement.advanced`: bool (default `false`)
  * `replacement.advancedEmptyChance`: percent (default `1`)
  * `replacement.advancedEmptyMinSlots`: number (`0-?`, default `0`)
  * `replacement.advancedFullMinSlots`: number (`0-?`, default `0`)
  * `replacement.advancedFullReplaceChance`: percent (default `1`)
  * `replacement.advancedFullSelectChance`: percent (default `1`)
  * `replacement.advancedMaxSlots`: number (`?-*`, default `20`)
  * `replacement.advancedMinSlots`: number (`0-?`, default `20`)
  * `replacement.hideAdvanced`: action
  * `replacement.showAdvanced`: action
  * `replacement.simpleChance`: percent (default `100%`)
  * `replacement.simpleMode`: enum (`SwEnum.ReplaceMode`, default `.EVERYTHING`)
* `sellItems`: percent (`0-2`, default `0`)
* `version`: number (internal use only)