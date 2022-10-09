return {
  Bans = {
    Giving = {
      Allow = L("Allow item", "bans.giving.allow"),
      DontAllow = L("Don't allow item", "bans.giving.dontAllow"),
      DynamicGold = L("Allow while holding gold", "bans.giving.dynamicGold")
    },
    Taking = {
      DontTake = L("Don't take item", "bans.taking.dontTake"),
      Take = L("Take item", "bans.taking.take"),
      TakeIfGiven = L("Take if given by mod", "bans.taking.ifGiven")
    }
  },
  CharmsAlgorithms = {
    -- This only has one For Now, but a second is already in the works
    Simple = L("Simple", "charmsAlgorithms.simple")
  },
  Floors = {
    DepthLevel = function(...) return L.formatKey("Depth %d-%d", "floors.depth", ...) end,
    ExtraBossFloors = L("Add extra/custom boss floors", "floors.extraBoss"),
    ExtraOtherFloors = L("Add other extra floors", "floors.extraOther"),
    ExtraPostBosses = L("Add extra post-boss floors", "floors.extraPostBosses"),
    ExtraStoryBoss = L("Extra story boss", "floors.extraStoryBoss"),
    RawFloorNumbers = L("Raw floor numbers above", "floors.rawNumbers"),
    TrainingFloors = L("Training floors", "floors.trainingFloors"),
  },
  FloorPresets = {
    AllFloors = L("All floors", "floorPresets.allFloors"),
    FirstOfZone = L("First of each zone", "floorPresets.firstOfZone"),
    PostBosses = L("After every boss", "floorPresets.postBosses"),
    StartOfRun = L("Start of run only", "floorPresets.startOfRun")
  },
  Formats = {
    ItemPoolAdvanced = function(...) return L.formatKey("%s (%s)", "formats.itemPoolAdvanced", ...) end,
    NoLimit = L("(No limit)", "formats.noLimit"),
    Sell = {
      No = L("No", "formats.sell.no"),
      Yes = function(...) return L.formatKey("%d%% of purchase price", "formats.sell.yes", ...) end
    }
  },
  Func = {
    NounCase = function(slot)
      if L("lower", "grammar.nounCase") == "upper" then
        return slot
      else
        return slot:lower()
      end
    end
  },
  ItemPools = {
    itemPoolChest = L("Chest", "itemPools.itemPoolChest"),
    itemPoolRedChest = L("Red boss chest", "itemPools.itemPoolRedChest"),
    itemPoolPurpleChest = L("Purple boss chest", "itemPools.itemPoolPurpleChest"),
    itemPoolBlackChest = L("Black boss chest", "itemPools.itemPoolBlackChest"),
    itemPoolLockedChest = L("Locked chest", "itemPools.itemPoolLockedChest"),
    itemPoolShop = L("Shop", "itemPools.itemPoolShop"),
    itemPoolLockedShop = L("Locked shop", "itemPools.itemPoolLockedShop"),
    itemPoolUrn = L("Urn", "itemPools.itemPoolUrn"),
    itemPoolSecret = L("Conjurer", "itemPools.itemPoolSecret"),
    itemPoolFood = L("Food", "itemPools.itemPoolFood"),
    itemPoolHearts = L("Hearts", "itemPools.itemPoolHearts"),
    itemPoolCrate = L("Crate", "itemPools.itemPoolCrate"),
    itemPoolWar = L("Shrine of War", "itemPools.itemPoolWar"),
    itemPoolUncertainty = L("Shrine of Uncertainty", "itemPools.itemPoolUncertainty"),
    itemPoolEnchant = L("Enchant weapon scroll", "itemPools.itemPoolEnchant"),
    itemPoolNeed = L("Need scroll", "itemPools.itemPoolNeed"),
    Switcheroo_itemPoolSwitcheroo = L("Switcheroo default", "itemPools.Switcheroo_itemPoolSwitcheroo")
  },
  ReplaceMode = {
    Empty = L("Fill empty slots", "replaceMode.empty"),
    Everything = L("Fill and replace", "replaceMode.everything"),
    Existing = L("Replace existing items", "replaceMode.existing")
  },
  Settings = {
    DefaultItemDesc = function(...) return L.formatKey("Default item for %s slot", "settings.defaultItemDesc", ...) end,
  },
  Slots = {
    Names = {
      -- If we can find a way to get existing translation keys
      -- Use those instead of this table
      Action = L("Item", "slots.names.action"), -- render.inventoryHUDSlots.item
      Body = L("Body", "slots.names.body"), -- render.inventoryHUDSlots.body
      Feet = L("Feet", "slots.names.feet"), -- render.inventoryHUDSlots.feet
      Head = L("Head", "slots.names.head"), -- render.inventoryHUDSlots.head
      Holster = L("Holster", "slots.names.holster"), -- component.itemHolster.slotLabel
      Misc = L("Charms", "slots.names.misc"), -- no pre-existing key
      Ring = L("Ring", "slots.names.ring"), -- render.inventoryHUDSlots.ring
      Shield = L("Shield", "slots.names.shield"), -- mod.Sync.slotShield.shield
      Shovel = L("Shovel", "slots.names.shovel"), -- render.inventoryHUDSlots.shovel
      Spell = L("Spell", "slots.names.spell"), -- render.inventoryHUDSlots.spell
      Torch = L("Torch", "slots.names.torch"), -- render.inventoryHUDSlots.torch
      Weapon = L("Attack", "slots.names.weapon") -- render.inventoryHUDSlots.attack
    },
    Presets = {
      AllButHolster = L("All slots except holster", "slots.presets.allButHolster"),
      AllButHolsterShield = L("All slots except shield and holster", "slots.presets.allButHolsterShield"),
      AllButShield = L("All slots except shield", "slots.presets.allButShield"),
      AllButWeapon = L("All slots except weapons", "slots.presets.allButWeapon"),
      AllButWeaponShield = L("All slots except shield and weapons", "slots.presets.allButWeaponShield"),
      AllSlots = L("All slots", "slots.presets.all"),
      NoSlots = L("No slots", "slots.presets.none")
    }
  }
}
