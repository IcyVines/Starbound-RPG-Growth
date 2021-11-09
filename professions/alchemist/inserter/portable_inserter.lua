require "/scripts/util.lua"

-- Written with help from Alberto-Rota's Weapon Assembly Station and Mighty Annihilator's Augment Extractor

function init()
  self.potions = root.assetJson("/professions/alchemist/potionList.config")
end

function uninit()
  for i=1,4 do
    player.giveItem(widget.itemSlotItem("itemSlot" .. tostring(i)))
  end
end

function leftClick(widgetName)
  -- Check swap item
  local new = player.swapSlotItem()
  local previous = widget.itemSlotItem(widgetName)
  if widgetName == "itemSlot1" and ((new and new.name and new.name == "ivrpgwalchemicpistol") or not new) and (not previous or not new) then
    previous = setWeaponACI(previous)
    player.setSwapSlotItem(previous)
    widget.setItemSlotItem(widgetName, new)
    clearPotionSlots(new)
    insertPotionSlots(new)
  elseif widgetName ~= "itemSlot1" and ((new and new.name and self.potions[new.name]) or not new) then
    -- Add Potions
    local oldCount = 0
    if new then
      new.count = math.max(new.count - 1, 0)
      player.setSwapSlotItem(new)
      new.count = 1
      player.giveItem(previous)
    else
      player.setSwapSlotItem(previous)
    end
    widget.setItemSlotItem(widgetName, new)
  end
end

function rightClick(widgetName)
  local previous = widget.itemSlotItem(widgetName)
  if previous then
    player.giveItem(previous)
    widget.setItemSlotItem(widgetName, nil)
  end
end

function clearPotionSlots(giveItems)
  for i=2,4 do
    if giveItems then player.giveItem(widget.itemSlotItem("itemSlot" .. tostring(i))) end
    widget.setItemSlotItem("itemSlot" .. tostring(i), nil)
  end
end

function insertPotionSlots(item)
  if not item then return end
  if item and item.parameters and item.parameters.rpg_ACI then
    local ACIs = item.parameters.rpg_ACI
    for i=2,4 do
      if ACIs["itemSlot" .. tostring(i)] then containerPutItem(ACIs["itemSlot" .. tostring(i)], i) end
    end
  end
end

function containerPutItem(item, slot)
  if not item then return end
  widget.setItemSlotItem("itemSlot" .. tostring(slot), item)
end

function setWeaponACI(weapon)
  if not weapon then return end
  local params = weapon.parameters or {}
  params.rpg_ACI = {}
  for i=2,4 do
    local slot = "itemSlot" .. tostring(i)
    params.rpg_ACI[slot] = widget.itemSlotItem(slot) or nil
  end
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