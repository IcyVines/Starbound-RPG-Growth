require "/scripts/augments/item.lua"

function apply(input)
  local augmentConfig = config.getParameter("augment")
  local output = Item.new(input)
  local baseLeveledStatEffects = root.assetJson("/professions/jeweler/jewelry/baseLeveledStatusEffects.config")
  if augmentConfig then
    if output:instanceValue("category", "") == augmentConfig.type then
      local currentAugment = output:instanceValue("currentAugment")
      local slotType = config.getParameter("slotType", "main")
      local jewelry = {}
      if currentAugment then
        jewelry = currentAugment.rpg_jewelry
        if not jewelry then
          -- Current Augment is real Augment
          jewelry = {}
          currentAugment = slotType == "main" and augmentConfig or {}
        elseif (slotType == "alt" and jewelry.right) or jewelry[slotType] then
          -- Current Augment is Jewelry, but has no space
          return nil
        else
          -- Jewelry exists on item.
          currentAugment = slotType == "main" and augmentConfig or currentAugment
          currentAugment.rpg_jewelry = jewelry
        end
      else
        -- Current Augment does not exist
        currentAugment = slotType == "main" and augmentConfig or {}
      end

      output:setInstanceValue("tooltipKind", "ivrpgarmoraugment")

      local tooltipFields = output:instanceValue("tooltipFields", {})
      if slotType == "alt" then
        slotType = jewelry["left"] and "right" or "left"
        if slotType == "left" then
          tooltipFields.collarNameLabel = augmentConfig.displayName
          tooltipFields.collarIconImage = augmentConfig.displayIcon
        else
          tooltipFields.reelNameLabel = augmentConfig.displayName
          tooltipFields.reelIconImage = augmentConfig.displayIcon
        end

        if not jewelry["main"] then
          currentAugment.displayName = "-"
          currentAugment.displayIcon = "/professions/jeweler/jewelry/unknown.png"
        end
      end
      output:setInstanceValue("tooltipFields", tooltipFields)

      jewelry[slotType] = {
        itemName = config.getParameter("itemName", ""),
        itemStats = config.getParameter("jewelStats", {})
      }
      -- Apply new bonus to armor
      local armorStatusEffects = output:instanceValue("leveledStatusEffects", false)
      if not armorStatusEffects then
        armorStatusEffects = baseLeveledStatusEffects
      end
      local itemStats = jewelry[slotType].itemStats
      for _,v in pairs(armorStatusEffects) do
        if itemStats[v.stat] then
          if v.amount then v.amount = v.amount + itemStats[v.stat] end
          if v.baseMultiplier then v.baseMultiplier = v.baseMultiplier + itemStats[v.stat] end
        end
      end
      output:setInstanceValue("leveledStatusEffects", armorStatusEffects)
      augmentConfig = currentAugment
      augmentConfig.rpg_jewelry = jewelry
      output:setInstanceValue("currentAugment", augmentConfig)
      return output:descriptor(), 1
    end
  end
end