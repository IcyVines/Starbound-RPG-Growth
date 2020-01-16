require "/scripts/util.lua"

function init()
  storage.item = storage.item or false
end

function craftingRecipe(items)
  if #items ~= 1 then return end
  local item = items[1]
  --sb.logInfo(sb.printJson(items,1))
  
  if not item then return end
  
  if not item.parameters or not item.parameters.currentAugment then
    return
  elseif item.parameters.currentAugment and item.parameters.currentAugment.rpg_jewelry then

    storage.item = copy(item)
    
    --storage.item.parameters.tooltipKind = "armor"

    local output = {}
    local itemStats = false
    if item.parameters.currentAugment.rpg_jewelry.right then
      output = {
        name = item.parameters.currentAugment.rpg_jewelry.right.itemName,
        count = 1,
        parameters = {}
      }
      storage.item.parameters.tooltipFields.reelIconImage = "/professions/jeweler/jewelry/unknown.png"
      storage.item.parameters.tooltipFields.reelNameLabel = "-"
      itemStats = storage.item.parameters.currentAugment.rpg_jewelry.right.itemStats
      jremove(storage.item.parameters.currentAugment.rpg_jewelry,"right")
    elseif item.parameters.currentAugment.rpg_jewelry.left then
      output = {
        name = item.parameters.currentAugment.rpg_jewelry.left.itemName,
        count = 1,
        parameters = {}
      }
      storage.item.parameters.tooltipFields.collarIconImage = "/professions/jeweler/jewelry/unknown.png"
      storage.item.parameters.tooltipFields.collarNameLabel = "-"
      itemStats = storage.item.parameters.currentAugment.rpg_jewelry.left.itemStats
      jremove(storage.item.parameters.currentAugment.rpg_jewelry,"left")
    elseif item.parameters.currentAugment.rpg_jewelry.main then
      output = {
        name = item.parameters.currentAugment.rpg_jewelry.main.itemName,
        count = 1,
        parameters = {}
      }
      itemStats = storage.item.parameters.currentAugment.rpg_jewelry.main.itemStats
      jremove(storage.item.parameters.currentAugment, "rpg_jewelry")
      storage.item.parameters.currentAugment.displayName = "-"
      storage.item.parameters.currentAugment.effects = {{stat = "ivrpgjewelry", amount = 0}}
      storage.item.parameters.currentAugment.displayIcon = "/professions/jeweler/jewelry/unknown.png"
      storage.item.parameters.currentAugment.name = "ivrpgnone"
      storage.item.parameters.currentAugment.type = ""
    end

    if itemStats then
      local armorStatusEffects = storage.item.parameters.leveledStatusEffects
      if armorStatusEffects then
        for _,v in pairs(armorStatusEffects) do
          if itemStats[v.stat] then
            if v.amount then v.amount = v.amount - itemStats[v.stat] end
            if v.baseMultiplier then v.baseMultiplier = v.baseMultiplier - itemStats[v.stat] end
          end
        end
      end
    end

    if not output then return end
    
    --animator.setAnimationState("healState","on")
    
    return {
      input = items,
      output = output,
      duration = 1.0
    }
    
  else
    return
  end  
end

--[[
  local jewelryStatusEffects = {}
  for _,v in pairs(jewelry) do
    if v.itemStats then
      for stat,amount in pairs(v.itemStats) do
        jewelryStatusEffects[stat] = (jewelryStatusEffects[stat] or 0) + amount
      end
    end
  end

  if armorStatusEffects then
    for _,v in pairs(armorStatusEffects) do
      if jewelryStatusEffects[v.stat] then

      end
    end
  else
    armorStatusEffects = baseLeveledStatusEffects
  end
]]

function removeLeveledStats()

end

function update(dt)
  local powerOn = false
  local inventory = world.containerItems(entity.id())
  
  
  for _,item in pairs(inventory) do
    if item.parameters.currentAugment then
      powerOn = true
      break
    end
  end
  
  if storage.item and not inventory[1] and inventory[2] then
    world.containerAddItems(entity.id(),storage.item)
    --sb.logInfo(sb.printJson(storage.item,1))
    storage.item = false
  end

  if powerOn then
    --animator.setAnimationState("powerState", "on")
  else
    --animator.setAnimationState("powerState", "off")
  end
end
