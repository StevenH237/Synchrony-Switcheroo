local Settings        = require "necro.config.Settings"
local SettingsStorage = require "necro.config.SettingsStorage"

local SwEnum = require "Switcheroo.Enum"

local NixLib = require "NixLib.NixLib"

local function getSetting(name)
  return SettingsStorage.get("mod.Switcheroo." .. name, Settings.Layer.REMOTE_PENDING)
end

local function setSetting(name, value)
  SettingsStorage.set("mod.Switcheroo." .. name, value, Settings.Layer.REMOTE_PENDING)
end

local function clearSettings(prefix, settings)
  for i, v in ipairs(settings) do
    SettingsStorage.set("mod.Switcheroo." .. prefix .. v, nil, Settings.Layer.REMOTE_PENDING)
  end
end

local module = {}

function module.ImportV1Settings()
  -- Import "chance" group first
  local chanceEmpty = getSetting("chance.empty") or 1
  local chanceFilled = getSetting("chance.filled") or 1
  local chanceNew = getSetting("chance.new") or 1
  local chanceMin = getSetting("chance.minimum") or 0
  local chanceMax = getSetting("chance.maximum") or -1

  if chanceMax == -1 then chanceMax = 20 end
  if chanceMin > chanceMax then chanceMin, chanceMax = chanceMax, chanceMin end

  local simpleChance = false

  -- Can we represent this with simple settings?
  if (chanceEmpty == 0 or chanceFilled == 0 or chanceEmpty == chanceFilled)
      and chanceNew == 1 and chanceMin == 0
      and (chanceMax == -1 or chanceMax >= 20) then
    clearSettings("replacement.advanced", { "", "EmptyChance", "EmptyMinSlots", "FullMinSlots", "FullReplaceChance", "FullSelectChance", "MinSlots", "FullMaxSlots" })

    if chanceEmpty == 0 then
      setSetting("replacement.simpleMode", SwEnum.EXISTING)
      setSetting("replacement.simpleChance", chanceFilled)
    elseif chanceFilled == 0 then
      setSetting("replacement.simpleMode", SwEnum.EMPTY)
      setSetting("replacement.simpleChance", chanceEmpty)
    else
      setSetting("replacement.simpleMode", nil)
      setSetting("replacement.simpleChance", chanceEmpty)
    end
  else
    clearSettings("replacement.", { "simpleMode", "simpleChance", "advancedEmptyMinSlots", "advancedFullMinSlots" })

    setSetting("replacement.advanced", true)
    -- Because of changes to how empty slot filling works, the multiplication here mimics the old behavior.
    setSetting("replacement.advancedEmptyChance", chanceEmpty * chanceNew)
    setSetting("replacement.advancedFullSelectChance", chanceFilled)
    setSetting("replacement.advancedFullReplaceChance", chanceNew)
    setSetting("replacement.advancedMinSlots", math.min(chanceMin, 20))
    setSetting("replacement.advancedMaxSlots", math.min(chanceMax, 20))
  end

  -- Import "charms" group next
  -- We'll set "other.advanced" false before anything that would set it true
  setSetting("other.advanced", nil)

  local charmsMax = getSetting("charms.max")
  local charmsAdd = getSetting("charms.new")

  if charmsMax or charmsAdd then
    setSetting("other.advanced", true)
    setSetting("other.charms.maxTotal", charmsMax)
    setSetting("other.charms.maxAdd", charmsAdd)
  end

  -- Import "components" group next
  -- First, clear the existing (new version) no-give stuff
  clearSettings("dontGive.", { "advanced", "bannedItems", "components", "goldItems", "items", "magicFood" })
  setSetting("dontGive.damageUps", false)
  setSetting("dontGive.magicFood", false)
  setSetting("dontGive.moveAmplifiers", false)

  -- Then, import items not given.
  local itemsNoGive = NixLib.splitToList(getSetting("components.giveItem") or "")
  local itemsNotGiven = {}

  for i, v in itemsNoGive do
    setSetting("dontGive.advanced", true)
    itemsNotGiven[#itemsNotGiven + 1] = v
  end

  setSetting("dontGive.items", itemsNotGiven)

  -- Then, import components not given.
  local componentsNoGive = NixLib.splitToList(getSetting("components.giveComponent") or "itemIncomingDamageIncrease itemBanInnateSpell")
  local componentsNotGiven = {}

  for i, v in componentsNoGive do
    if v == "Switcheroo_noGive"
        -- haha, think you're clever? :P
        -- we'll just ignore that one
        or v == "itemBanInnateSpell" then
      -- This is ignored because of legacy defaults
    elseif v == "itemIncomingDamageIncrease" or v == "itemIncomingDamageMultiplier" then
      setSetting("dontGive.damageUps", nil)
    elseif v == "itemBanPoverty" then
      setSetting("dontGive.goldItems", true)
    elseif v == "itemMoveAmplifier" then
      setSetting("dontGive.moveAmplifiers", nil)
    elseif v == "itemLimitTileVisionRadius" then
      setSetting("dontGive.visionReducers", true)
    else
      componentsNotGiven[#componentsNotGiven + 1] = v
    end
  end

  if #componentsNotGiven >= 1 then
    setSetting("dontGive.advanced", true)
    setSetting("dontGive.components", componentsNotGiven)
  end

  -- Now, clear the existing (new version) no-take stuff
  clearSettings("dontTake.", { "advanced", "componentsUnlessGiven", "components", "itemsUnlessGiven", "items", "locked" })
  setSetting("dontTake.crownOfGreed", SwEnum.DontTake.TAKE)
  setSetting("dontTake.luckyCharm", SwEnum.DontTake.TAKE)
  setSetting("dontTake.potion", SwEnum.DontTake.TAKE)
  setSetting("dontTake.ringOfWonder", SwEnum.DontTake.TAKE)

  -- Then, import items not taken.
  local itemsNoTake = NixLib.splitToList(getSetting("components.takeItem") or "MiscPotion CharmLuck RingWonder HeadCrownOfGreed")
  local itemsNotTaken = {}

  for i, v in itemsNoTake do
    if v == "HeadCrownOfGreed" then
      setSetting("dontTake.crownOfGreed", SwEnum.DontTake.DONT_TAKE)
    elseif v == "CharmLuck" then
      setSetting("dontTake.luckyCharm", SwEnum.DontTake.DONT_TAKE)
    elseif v == "MiscPotion" then
      setSetting("dontTake.potion", SwEnum.DontTake.DONT_TAKE)
    elseif v == "RingWonder" then
      setSetting("dontTake.ringOfWonder", SwEnum.DontTake.DONT_TAKE)
    else
      itemsNotTaken[#itemsNotTaken + 1] = v
    end
  end

  if #itemsNotTaken >= 1 then
    setSetting("dontTake.advanced", true)
    setSetting("dontTake.items", itemsNotTaken)
  end

  -- And lastly import components not taken.
  local componentsNoTake = NixLib.splitToList(getSetting("components.takeComponent") or "itemBanInnateSpell")
  local componentsNotTaken = {}

  for i, v in componentsNoTake do
    if v == "itemBanInnateSpell" then
      -- Do nothing because of legacy defaults.
    else
      componentsNotTaken[#componentsNotTaken + 1] = v
    end
  end

  if #componentsNotTaken >= 1 then
    setSetting("dontTake.advanced", true)
    setSetting("dontTake.components", componentsNotTaken)
  end

  -- One more thing that had its own node before for some reason?
  if getSetting("deadly") then
    setSetting("dontGive.deadlyItems", true)
  end

  -- Now we need to import the floors settings.
  local floorMask = 0
  for d = 1, 5 do
    for l = 1, 4 do
      local exp = d * 4 + l
      local val = 2 ^ exp
      if getSetting("floors.l" .. d .. l) ~= false then
        floorMask = floorMask + val
      end
    end
  end
end

return module
