function init()
  object.setInteractive(true)
end

function onInteraction(args)
  world.sendEntityMessage(args.sourceId,"ivrpgExtractRemoval", entity.id(), "/professions/alchemist/inserter/portable.config")
end

--[[

function uninit(dt)
  for i=1,4 do
    player.giveItem(widget.itemSlotItem("itemSlot" .. tostring(i)))
  end
end

function leftClick(widgetName)

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
  -- Main slot changed
  if slots[1] == 0 then
    -- Weapon slot has weapon, last inventory is null
    if world.containerItemAt(entity.id(), 0) and not storage.lastInventory[1] then
      local contained = {containerTakeItem(1), containerTakeItem(2), containerTakeItem(3)}
      for i=1,3 do
        if contained[i] then world.spawnItem(contained[i], entity.position()) end
      end
    else
      local oldInv = {first = storage.inventory[2], second = storage.inventory[3], third = storage.inventory[4]}
      local oldInvIndex = {first = 1, second = 2, third = 3}
      for key,item in pairs(oldInv) do
        if item and item.name and self.potions[item.name] then
          containerConsumeItem(oldInvIndex[key], 1)
        end
      end
    end

    if storage.inventory[1] then
      local ACIs = breakIntoACI()
      if ACIs then
        if ACIs.first then containerPutItem({name = ACIs.first, count =1, parameters = {}}, 1) end
        if ACIs.second then containerPutItem({name = ACIs.second, count =1, parameters = {}}, 2) end
        if ACIs.third then containerPutItem({name = ACIs.third, count =1, parameters = {}}, 3) end
        return
      end
    end
  end

  -- Secondary slots changed
  if slots[1] == 1 or slots[1] == 2 or slots[1] == 3 then
    if not storage.lastInventory[slots[1] + 1] then
      for i=1,3 do
        if slots[1] ~= i then
          --containerTakeItem(i)
        end
      end
    else
      removeACIFromWeapon(slots[1])
    end
    addACIToWeapon(slots[1])
  end

end

function breakIntoACI()
  local input = world.containerItemAt(entity.id(), 0)
  local ACI = isValidWeapon(input)
  if ACI then
    if world.containerItemAt(entity.id(), 1) == nil and world.containerItemAt(entity.id(), 2) == nil and world.containerItemAt(entity.id(), 3) == nil then
      return ACI
    end
  end
end

function addACIToWeapon(slot)
  if not slot then return end
  slotType = storage.slotTypes[slot]
  local input = world.containerItemAt(entity.id(), slot)
  local ACI = isValidACI(input)
  weapon = storage.inventory[1]
  if not weapon or not weapon.name then return end
  if weapon.name ~= "ivrpgwalchemicpistol" then return end
  if ACI then
    local rpg_ACI = weapon.parameters and weapon.parameters.rpg_ACI or {}
    weapon.parameters.rpg_ACI = rpg_ACI
    weapon.parameters.rpg_ACI[slotType] = ACI
  else
    return
  end
  containerTakeItem(0)
  containerPutItem(weapon, 0)
end

function isValidWeapon(weapon)
  return weapon and weapon.parameters and weapon.parameters.rpg_ACI
end

function isValidACI(ACI)
  if ACI and ACI.name and self.potions[ACI.name] then
    --local name = string.gsub(ACI.name, "ivrpg_alchemicpotion_", "")
    return ACI.name
  else
    return nil
  end
end

function inventorySlotChanged(slot)
  if not compare(storage.inventory[slot + 1], world.containerItemAt(entity.id(), slot)) then
    storage.inventory[slot+1] = world.containerItemAt(entity.id(), slot)
    return true
  end
  return false
end

function containerConsumeItem(slot, amount)
  storage.inventory[slot+1] = nil
  return world.containerConsumeAt(entity.id(), slot, amount)
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

function removeACIFromWeapon(slot)
  if not slot then return end
  slotType = storage.slotTypes[slot]
  weapon = storage.inventory[1]
  if not weapon or not weapon.parameters or not weapon.parameters.rpg_ACI then return end
  if slotType == "first" and weapon.parameters.rpg_ACI.first then
    jremove(weapon.parameters.rpg_ACI, "first")
  elseif slotType == "second" and weapon.parameters.rpg_ACI.second then
    jremove(weapon.parameters.rpg_ACI, "second")
  elseif slotType == "third" and weapon.parameters.rpg_ACI.third then
    jremove(weapon.parameters.rpg_ACI, "third")
  else
    return
  end

  containerTakeItem(0)
  containerPutItem(weapon, 0)
end

]]