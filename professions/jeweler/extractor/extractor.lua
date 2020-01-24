require "/scripts/util.lua"

function init()
  storage.item = storage.item or false
  if storage.inventory == nil then storage.inventory = {} end
  if storage.lastInventory == nil then storage.lastInventory = {} end
  storage.slotTypes = {"main", "left", "right"}
end

function die()

end

function main()

end


function containerCallback(args)
  local slots = {}
  for i = 0, 3 do
    storage.lastInventory[ i + 1 ] = storage.inventory[ i + 1 ]
    if inventorySlotChanged(i) then
      table.insert(slots, i)
    end
  end

  containerSlotsChanged(slots)
end

function containerSlotsChanged(slots)
  if slots[1] == 0 then
    if world.containerItemAt(entity.id(), 0) and not storage.lastInventory[1] then
      world.spawnItem(containerTakeItem(1), entity.position())
      world.spawnItem(containerTakeItem(2), entity.position())
      world.spawnItem(containerTakeItem(3), entity.position())
    end
    containerTakeItem(1)
    containerTakeItem(2)
    containerTakeItem(3)
  end
  if slots[1] == 1 or slots[1] == 2 or slots[1] == 3 then
    if not storage.lastInventory[slots[1] + 1] then
      world.spawnItem(containerTakeItem(0), entity.position())
      for i=1,3 do
        if slots[1] ~= i then
          containerTakeItem(i)
        end
      end
    end
    removeJewelryFromArmor(slots[1])
  end


  local jewelry = breakIntoJewelry()
  if jewelry then
    containerPutItem(jewelry.main and {name = jewelry.main.itemName, count = 1, parameters = {}}, 1)
    containerPutItem(jewelry.left and {name = jewelry.left.itemName, count = 1, parameters = {}}, 2)
    containerPutItem(jewelry.right and {name = jewelry.right.itemName, count = 1, parameters = {}}, 3)
    return
  end

end

function breakIntoJewelry()
  local inputArmor = world.containerItemAt(entity.id(), 0)
  local jewelry = isValidArmor(inputArmor)
  if jewelry then
    if world.containerItemAt(entity.id(), 1) == nil and world.containerItemAt(entity.id(), 2) == nil and world.containerItemAt(entity.id(), 3) == nil then
      return jewelry
    end
  end
end

function isValidArmor(armor)
  return armor and armor.parameters and armor.parameters.currentAugment and armor.parameters.currentAugment.rpg_jewelry
end

function inventorySlotChanged(slot)
  if not compare(storage.inventory[slot + 1], world.containerItemAt(entity.id(), slot)) then
    storage.inventory[slot+1] = world.containerItemAt(entity.id(), slot)
    return true
  end
  return false
end

function containerTakeItem(slot)
  storage.inventory[slot+1] = nil
  return world.containerTakeAt(entity.id(), slot)
end

function containerPutItem(item, slot)
  if not item then return end
  world.containerPutItemsAt(entity.id(), item, slot)
  storage.inventory[slot+1] = world.containerItemAt(entity.id(), slot)
end

function compare(t1,t2)
  if t1 == t2 then return true end
  if type(t1) ~= type(t2) then return false end
  if type(t1) ~= "table" then return false end
  for k,v in pairs(t1) do
    if not compare(v, t2[k]) then return false end
  end
  for k,v in pairs(t2) do
    if not compare(v, t1[k]) then return false end
  end
  return true
end

function removeJewelryFromArmor(slot)
  if not slot then return end
  slotType = storage.slotTypes[slot]
  armor = storage.inventory[1]
  if not armor or not armor.parameters or not armor.parameters.currentAugment or not armor.parameters.currentAugment.rpg_jewelry then return end

  local effects = armor.parameters.currentAugment.effects
  local index = 1
  local itemStats = false
  if slotType == "main" and armor.parameters.currentAugment.rpg_jewelry.main then
    itemStats = armor.parameters.currentAugment.rpg_jewelry.main.itemStats
    jremove(armor.parameters.currentAugment.rpg_jewelry, "main")
    armor.parameters.currentAugment.displayName = "-"
    armor.parameters.currentAugment.displayIcon = "/professions/jeweler/jewelry/unknown.png"
    armor.parameters.currentAugment.name = "ivrpgnone"
    armor.parameters.currentAugment.type = ""
    table.remove(effects, index + 1)
    table.remove(effects, index)
  elseif slotType == "left" and armor.parameters.currentAugment.rpg_jewelry.left then
    armor.parameters.tooltipFields.collarIconImage = "/professions/jeweler/jewelry/unknown.png"
    armor.parameters.tooltipFields.collarNameLabel = "-"
    itemStats = armor.parameters.currentAugment.rpg_jewelry.left.itemStats
    jremove(armor.parameters.currentAugment.rpg_jewelry,"left")
    if #effects > 2 and armor.parameters.currentAugment.rpg_jewelry.main then
      index = 3
    end
    table.remove(effects, index + 1)
    table.remove(effects, index)
  elseif slotType == "right" and armor.parameters.currentAugment.rpg_jewelry.right then
    armor.parameters.tooltipFields.reelIconImage = "/professions/jeweler/jewelry/unknown.png"
    armor.parameters.tooltipFields.reelNameLabel = "-"
    itemStats = armor.parameters.currentAugment.rpg_jewelry.right.itemStats
    jremove(armor.parameters.currentAugment.rpg_jewelry,"right")
    if #effects > 2 then
      if armor.parameters.currentAugment.rpg_jewelry.main then
        index = index + 2
      end
      if armor.parameters.currentAugment.rpg_jewelry.left then
        index = index + 2
      end
    end
    table.remove(effects, index + 1)
    table.remove(effects, index)
  else
    return
  end

  --[[
  if itemStats then
    local armorStatusEffects = armor.parameters.leveledStatusEffects
    if armorStatusEffects then
      for _,v in pairs(armorStatusEffects) do
        if itemStats[v.stat] then
          if v.amount then v.amount = v.amount - itemStats[v.stat] end
          if v.baseMultiplier then v.baseMultiplier = v.baseMultiplier - itemStats[v.stat] end
        end
      end
    end
  end
  ]]
  containerTakeItem(0)
  containerPutItem(armor, 0)
end


--[[ Deprecated Function
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
]]