require "/scripts/util.lua"

function craftingRecipe(items)
  if #items ~= 5 then return end

  local params = config.getParameter("craftParameters", {})
  local elements = params.elements
  local required = params.requiredCount
  local barLevels = params.barLevels
  local modifiers = params.modifiers
  local electrum = params.electrum
  local crafting = params.crafting

  for i,item in pairs(items) do
    if not item or item.count < required[i] then
      return
    end
  end

  if items[1].name ~= "ivrpgelectrumbar" or (not barLevels[items[2].name]) or (not elements[items[3].name]) or (not modifiers[items[4].name]) then
    return
  end
  
  local weapon = items[5]
  local recipeType = "upgrade"
  if not weapon or not root.itemHasTag(weapon.name, "weapon") then
    if not crafting[weapon.name] then return end
    recipeType = "craft"
  end

  if items[4].count < modifiers[items[4].name].count then return end
  if recipeType == "craft" and items[1].count < 4 then return end


  local newLevel = barLevels[items[2].name]
  local input = copy(items)
  local newWeapon = copy(weapon)

  if recipeType == "upgrade" then
    local itemConfig = root.itemConfig(weapon)
    local highestLevel = weapon.parameters.level or (itemConfig and itemConfig.config and itemConfig.config.level) or 11
    local oldElement = "physical"
    if highestLevel > newLevel then return end
    newWeapon.parameters.level = newLevel
    if elements[items[3].name] ~= "physical" then
      oldElement = newWeapon.parameters.elementalType
      newWeapon.parameters.elementalType = elements[items[3].name]
    end
    if modifiers[items[4].name].stat ~= "none" then
      local params = modifiers[items[4].name]
      local stat = params.stat
      if not stat or newWeapon.parameters["ivrpgsmith" .. stat] then return end
      local num = (itemConfig and itemConfig.config and itemConfig.config.primaryAbility and itemConfig.config.primaryAbility[stat]) or (weapon.parameters.primaryAbility and weapon.parameters.primaryAbility[stat])
      if not num then return end
      if not newWeapon.parameters.primaryAbility then newWeapon.parameters.primaryAbility = {} end
      newWeapon.parameters.primaryAbility[stat] = num * params.mod
      newWeapon.parameters["ivrpgsmith" .. stat] = true
    end
    if highestLevel == newLevel and (oldElement and oldElement == elements[items[3].name]) and items[4].name == "coalore" then return end
    input[1].count = 2
    input[2].count = 5
    input[3].count = 1
    input[4].count = modifiers[items[4].name].count
  else
    newWeapon = {}
    newWeapon.name = crafting[weapon.name][tostring(weapon.count)]
    if not newWeapon.name then return end
    newWeapon.parameters = {}
    newWeapon.config = {}
    newWeapon.config.level = newLevel
    newWeapon.parameters.level = newLevel
    newWeapon.config.elementalType = elements[items[3].name]
    newWeapon.parameters.elementalType = elements[items[3].name]
    if items[4].name ~= "coalore" then return end
    input[1].count = 4
    input[2].count = 5
    input[3].count = 1
    input[4].count = 3
    input[5].count = weapon.count
  end
  --newWeapon.parameters.level = (newWeapon.parameters.level or itemConfig.config.level) + 1
  --animator.setAnimationState("healState", "on")
  return {
    input = input,
    output = newWeapon,
    duration = 1.0
  }
end

function update(dt)
  local active = false
  targetIds = world.playerQuery(entity.position(), 10)
  if targetIds then
    for _,id in ipairs(targetIds) do
      if world.entityCurrency(id, "proftype") == config.getParameter("proftype", 10) then
        active = true
      end
    end
  end

  object.setInteractive(active)

  local powerOn = false

  for _,item in pairs(world.containerItems(entity.id())) do
    if item.parameters and item.parameters.podUuid then
      powerOn = true
      break
    end
  end

  if powerOn then
    --animator.setAnimationState("powerState", "on")
  else
    --animator.setAnimationState("powerState", "off")
  end
end
