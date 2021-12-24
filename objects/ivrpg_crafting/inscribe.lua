require "/scripts/util.lua"

-- Written with help from Alberto-Rota's Weapon Assembly Station and Mighty Annihilator's Augment Extractor

function init()
  self.abilities = root.assetJson("/objects/ivrpg_crafting/abilityList.config")
  self.elementConversion = root.assetJson("/objects/ivrpg_crafting/elementList.config")
  self.abilityElements = root.assetJson("/objects/ivrpg_crafting/abilityElements.config")
  self.oreLevels = root.assetJson("/objects/ivrpg_crafting/oreLevels.config")
end

function uninit()
  if self.ogWeapon then
    player.giveItem(self.ogWeapon)
    for i=4,6 do
      if widget.itemSlotItem("itemSlot" .. tostring(i)) then
        player.giveItem(widget.itemSlotItem("itemSlot" .. tostring(i)))
      end
    end
  else
    for i=2,6 do
      if widget.itemSlotItem("itemSlot" .. tostring(i)) then
        player.giveItem(widget.itemSlotItem("itemSlot" .. tostring(i)))
      end
    end
  end
  --[[if weapon then
    weapon = updateWeaponTooltips(weapon)
    player.giveItem(weapon)
    clearSlots()
  end]]
end

function leftClick(widgetName)
  -- Check swap item
  local new = player.swapSlotItem()
  local previous = widget.itemSlotItem(widgetName)
  if widgetName == "itemSlot1" and ((new and new.name and (new.name == "ivrpg_commongrimoire" or new.name == "ivrpg_uncommongrimoire" or new.name == "ivrpg_raregrimoire")) or not new) and (not previous or not new) then
    previous = updateWeaponTooltips(previous)
    player.setSwapSlotItem(previous)
    widget.setItemSlotItem(widgetName, new)
    clearSlots(new)
    insertSlots(new)
    self.ogWeapon = new
  elseif (widgetName == "itemSlot2" or widgetName == "itemSlot3") and ((new and new.name and new.name == "ivrpg_grimoirepage") or not new) then
    -- Add Pages
    swapItems(widgetName, new, previous, 1)
    self.ogWeapon = nil
  elseif widgetName == "itemSlot4" and ((new and new.name and self.oreLevels[new.name] and new.count and new.count >= 5) or not new) then
    -- Add Element
    swapItems(widgetName, new, previous, 5)
  elseif (widgetName == "itemSlot5" or widgetName == "itemSlot6") and ((new and new.name and self.elementConversion[new.name]) or not new) then
    -- Add Element
    swapItems(widgetName, new, previous, 1)
  end
  updateWeaponTooltips(widget.itemSlotItem("itemSlot1"))
end

function rightClick(widgetName)
  local previous = widget.itemSlotItem(widgetName)
  if previous then
    if widgetName == "itemSlot1" then
      previous = updateWeaponTooltips(previous)
      clearSlots()
    end
    player.giveItem(previous)
    widget.setItemSlotItem(widgetName, nil)
  end
  updateWeaponTooltips(widget.itemSlotItem("itemSlot1"))
end

function swapItems(widgetName, new, previous, count)
  local oldCount = 0
  if new then
    new.count = math.max(new.count - count, 0)
    player.setSwapSlotItem(new)
    new.count = count
    player.giveItem(previous)
  else
    player.setSwapSlotItem(previous)
  end
  widget.setItemSlotItem(widgetName, new)
end

function clearSlots(giveItems)
  for i=2,6 do
    if giveItems or (not self.removeElement1 and i == 5) or (not self.removeElement2 and i == 6) then
      player.giveItem(widget.itemSlotItem("itemSlot" .. tostring(i)))
    end
    widget.setItemSlotItem("itemSlot" .. tostring(i), nil)
  end
end

function insertSlots(item)
  if not item then return end
  if item and item.parameters then
    local params = item.parameters
    containerPutItem({name = "ivrpg_grimoirepage", count = 1, parameters = {
      abilityType = params.primaryAbilityType,
      shortdescription = self.abilities[params.primaryAbilityType] or "Something went horribly wrong.",
      description = "A level " .. tostring(params.level or 1.0) .. ", " .. params.elementalType .. " Grimoire page.",
      level = params.level or 1.0,
      elementalType = params.elementalType or "earth",
      slotType = "primary"
    }}, 2)
    containerPutItem({name = "ivrpg_grimoirepage", count = 1, parameters = {
      abilityType = params.altAbilityType,
      shortdescription = self.abilities[params.altAbilityType] or "Something went horribly wrong.",
      description = "A level " .. tostring(params.level or 1.0) .. ", " .. params.altElementalType .. " Grimoire page.",
      level = params.level or 1.0,
      elementalType = params.altElementalType or "earth",
      slotType = "alt"
    }}, 3)
  end
end

function updateWeaponTooltips(weapon)
  -- If a Grimoire Page is missing, book cannot be shown!
  for i=2,3 do
    if not widget.itemSlotItem("itemSlot" .. tostring(i)) then
      widget.setItemSlotItem("itemSlot1", nil)
      return
    end
  end

  -- Otherwise, check for appropriate materials!
  local primaryPage = widget.itemSlotItem("itemSlot2")
  local altPage = widget.itemSlotItem("itemSlot3")
  local levelSlot = widget.itemSlotItem("itemSlot4")
  local primaryElement = widget.itemSlotItem("itemSlot5")
  local altElement = widget.itemSlotItem("itemSlot6")
  -- If pages don't match their slot, return
  if primaryPage.parameters.slotType ~= "primary" or altPage.parameters.slotType ~= "alt" then
    widget.setItemSlotItem("itemSlot1", nil)
    return
  end

  -- Average the level between both pages
  local level = (primaryPage.parameters.level + altPage.parameters.level) / 2
  if levelSlot and levelSlot.name and self.oreLevels[levelSlot.name] then
    level = self.oreLevels[levelSlot.name] or level
  end

  weapon = weapon or {count = 1}
  weapon.name = "ivrpg_" .. (level < 3 and "common" or (level < 5 and "uncommon" or "rare")) .. "grimoire"
  if not weapon.parameters then weapon.parameters = {} end
  if not weapon.parameters.tooltipFields then weapon.parameters.tooltipFields = {} end

  weapon.parameters.level = level
  weapon.parameters.primaryAbilityType = primaryPage.parameters.abilityType
  weapon.parameters.altAbilityType = altPage.parameters.abilityType

  -- Ensure that the Element Material can be slotted for that ability type, and set whether or not that material should be cleared upon extracting the Grimoire.
  local check1 = self.abilityElements[weapon.parameters.primaryAbilityType]
  local check2 = self.abilityElements[weapon.parameters.altAbilityType]
  local elementType1 = primaryElement and self.elementConversion[primaryElement.name]
  local elementType2 = altElement and self.elementConversion[altElement.name]
  self.removeElement1 = elementType1 and (not check1 or check1[elementType1]) 
  self.removeElement2 = elementType2 and (not check2 or check2[elementType2])
  weapon.parameters.elementalType = self.removeElement1 and elementType1 or primaryPage.parameters.elementalType
  weapon.parameters.altElementalType = self.removeElement2 and elementType2 or altPage.parameters.elementalType

  widget.setItemSlotItem("itemSlot1", weapon)
  return weapon
end

function containerPutItem(item, slot)
  if not item then return end
  widget.setItemSlotItem("itemSlot" .. tostring(slot), item)
end

function setWeaponParameters(weapon)
  if not weapon then return end
  local params = weapon.parameters or {}
  params.primaryAbilityType = widget.itemSlotItem("itemSlot2").parameters.abilityType
  params.altAbilityType = widget.itemSlotItem("itemSlot3").parameters.abilityType
  -- set elements based on item table
  --params.elementalType = widget.itemSlotItem("itemSlot5").parameters.abilityType
  --params.altElementalType = widget.itemSlotItem("itemSlot6").parameters.abilityType
  -- set level based on item table
  --params.level = [widget.itemSlotItem("itemSlot4")]
  weapon.parameters = params
  return weapon
end

-- Old
function containerConsumeItem(slot, amount)
  storage.inventory[slot+1] = nil
  return world.containerConsumeAt(entity.id(), slot, amount)
end

function containerTakeItem(slot)
  storage.inventory[slot+1] = nil
  return world.containerTakeAt(entity.id(), slot)
end