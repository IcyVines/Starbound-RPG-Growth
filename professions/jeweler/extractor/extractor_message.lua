require "/scripts/util.lua"

function init()
  self.slotTypes = {"main", "left", "right"}
  self.widgetToSlot = {itemSlot2 = "main", itemSlot3 = "left", itemSlot4 = "right"}
end

function uninit()
  player.giveItem(widget.itemSlotItem("itemSlot1"))
end

function leftClick(widgetName)
  local new = player.swapSlotItem()
  local previous = widget.itemSlotItem(widgetName)
  if widgetName == "itemSlot1" and (not previous or not new) then
    --previous = setWeaponACI(previous)
    player.setSwapSlotItem(previous)
    widget.setItemSlotItem(widgetName, new)
    clearJewelrySlots(new)
    insertJewelrySlots(new)
  elseif widgetName ~= "itemSlot1" and not new then
    player.setSwapSlotItem(previous)
    widget.setItemSlotItem(widgetName, nil)
    removeJewelryFromArmor(widgetName)
  end
end

function rightClick(widgetName)
  local previous = widget.itemSlotItem(widgetName)
  if previous then
    player.giveItem(previous)
    widget.setItemSlotItem(widgetName, nil)
    if widgetName ~= "itemSlot1" then
      removeJewelryFromArmor(widgetName)
    else
      clearJewelrySlots()
    end
  end
end

function clearJewelrySlots(giveItems)
  for i=2,4 do
    if giveItems then player.giveItem(widget.itemSlotItem("itemSlot" .. tostring(i))) end
    widget.setItemSlotItem("itemSlot" .. tostring(i), nil)
  end
end

-- {"main":{"itemStats":{},"itemName":"ivrpgferoziumwatch"}}
function insertJewelrySlots(armor)
  if not armor then return end
  local jewelry = isValidArmor(armor)
  if jewelry then
    if jewelry.main then widget.setItemSlotItem("itemSlot2", jewelry.main.itemName) end
    if jewelry.left then widget.setItemSlotItem("itemSlot3", jewelry.left.itemName) end
    if jewelry.right then widget.setItemSlotItem("itemSlot4", jewelry.right.itemName) end
  end
end

function isValidArmor(armor)
  return armor and armor.parameters and armor.parameters.currentAugment and armor.parameters.currentAugment.rpg_jewelry
end

function containerPutItem(item, slot)
  if not item then return end
  widget.setItemSlotItem("itemSlot" .. tostring(slot), item)
end

function removeJewelryFromArmor(widgetName)
  if not widgetName then return end
  local slotType = self.widgetToSlot[widgetName]
  local armor = widget.itemSlotItem("itemSlot1")
  if not armor or not armor.parameters or not armor.parameters.currentAugment or not armor.parameters.currentAugment.rpg_jewelry then return end
  local effects = armor.parameters.currentAugment.effects
  local index = 1
  local itemStats = false

  --sb.logInfo(sb.printJson(armor))

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

  widget.setItemSlotItem("itemSlot1", armor)
end