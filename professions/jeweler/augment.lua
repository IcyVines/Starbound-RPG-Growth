require "/scripts/augments/item.lua"
require "/scripts/util.lua"

function apply(input)
  local augmentConfig = config.getParameter("augment")
  local output = Item.new(input)
  local baseLeveledStatEffects = root.assetJson("/professions/jeweler/jewelry/baseLeveledStatusEffects.config")
  local jewelryDictionary = root.assetJson("/professions/jeweler/jewelry/ivrpgJewelryDictionary.config")
  local prefix = "/professions/jeweler/jewelry/"
  local suffix = config.getParameter("inventoryIcon")
  if augmentConfig then
    local category = output:instanceValue("category", "")
    if jewelryDictionary[category] and contains(jewelryDictionary[category], config.getParameter("itemName", "ivrpgjewelryplaceholder")) then
    --if category == augmentConfig.type then
      local currentAugment = output:instanceValue("currentAugment")
      local slotType = config.getParameter("slotType", "main")
      local jewelry = {}
      if currentAugment then
        jewelry = currentAugment.rpg_jewelry
        if not jewelry then
          -- Current Augment is real Augment
          jewelry = {}
          currentAugment = {}--slotType == "main" and augmentConfig or {}
        elseif jewelry[slotType] or (slotType == "alt" and jewelry["left"] and jewelry["right"]) then
          -- Current Augment is Jewelry, but has no space
          return nil
        else
          -- Jewelry exists on item.
        end
      else
        -- Current Augment does not exist
        currentAugment = {}--slotType == "main" and augmentConfig or {}
      end
      -- currentAugment = augmentConfig = {New Jewelry Config}
      output:setInstanceValue("tooltipKind", "ivrpgarmoraugment")

      prefix = prefix .. (augmentConfig.name and (augmentConfig.name .. "/") or "")
      local tooltipFields = output:instanceValue("tooltipFields", {})
      if slotType == "alt" then
        slotType = jewelry["left"] and "right" or "left"
        if slotType == "left" then
          tooltipFields.collarNameLabel = augmentConfig.displayName
          tooltipFields.collarIconImage = prefix .. suffix
        else
          tooltipFields.reelNameLabel = augmentConfig.displayName
          tooltipFields.reelIconImage = prefix .. suffix
        end

        if not jewelry["main"] then
          currentAugment.displayName = "-"
          currentAugment.displayIcon = "/professions/jeweler/jewelry/unknown.png"
        end
      elseif slotType == "main" then
        currentAugment.displayName = augmentConfig.displayName
        currentAugment.displayIcon = prefix .. suffix
      end
      output:setInstanceValue("tooltipFields", tooltipFields)
      -- currentAugment = augmentConfig = {New Jewelry Config}
      jewelry[slotType] = {
        itemName = config.getParameter("itemName", ""),
        itemStats = config.getParameter("jewelStats", {})
      }

      local newEffects = augmentConfig.effects
      local oldEffects = currentAugment.effects
      local effectConfig = newAugmentEffects(slotType, newEffects, oldEffects, jewelry)
      currentAugment.effects = effectConfig
      -- Apply new bonus to armor
      --local armorStatusEffects = output:instanceValue("leveledStatusEffects", baseLeveledStatusEffects)
      --output:setInstanceValue("leveledStatusEffects", armorStatusEffects)
      augmentConfig = currentAugment
      augmentConfig.rpg_jewelry = jewelry
      output:setInstanceValue("currentAugment", augmentConfig)
      return output:descriptor(), 1
    end
  end
end

function newAugmentEffects(slotType, new, old, jewelry)
  new = new[1] or {stat = "ivrpgjewelryplaceholder", amount = 0}
  old = old or {}
  transfer = {}
  if slotType == "right" then
    transfer = copy(old)
    table.insert(transfer, {stat = config.getParameter("itemName", "ivrpgjewelryplaceholder"), amount = 1})
    table.insert(transfer, new)
  elseif slotType == "left" then
    if jewelry.main then
      for i=1,2 do
        table.insert(transfer, old[i])
      end
    end
    table.insert(transfer, {stat = config.getParameter("itemName", "ivrpgjewelryplaceholder"), amount = 1})
    table.insert(transfer, new)
    if jewelry.right then
      for i=#old-1,#old do
        table.insert(transfer, old[i])
      end
    end
  elseif slotType == "main" then
    table.insert(transfer, {stat = config.getParameter("itemName", "ivrpgjewelryplaceholder"), amount = 1})
    table.insert(transfer, new)
    for _,v in ipairs(old) do
      table.insert(transfer, v)
    end
  end
  return transfer
end