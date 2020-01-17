require "/scripts/ivrpgactivestealthintercept.lua"

function operate(operator, x, y)
  stringToOperation = {
    ['+'] = function (x, y) return x + y end,
    ['-'] = function (x, y) return x - y end,
    ['*'] = function (x, y) return x * y end,
    ['/'] = function (x, y) return x / y end,
    ['<'] = function (x, y) return x < y end,
    ['>'] = function (x, y) return x > y end,
    ['<='] = function (x, y) return x <= y end,
    ['>='] = function (x, y) return x >= y end,
    ['=='] = function (x, y) return x == y end,
    ['~='] = function (x, y) return x ~= y end
  }
  return stringToOperation[operator](x,y)
end

function joinMaps(table1, table2)
  if not table1 then
    if not table2 then return nil
    else return table2 end
  else
    if not table2 then return table1
    else
      for k,v in pairs(table2) do
        table1[k] = v
      end
      return table1
    end
  end
end

function getArrayFromType(t, atype)
  local returnT = {}
  for k,v in ipairs(t) do
    if v.type == atype then
      for x,y in ipairs(v.apply) do
         table.insert(returnT, y)
      end
    end
  end
  return returnT
end

function getDictionaryFromType(t, atype)
  local returnT = nil
  for k,v in ipairs(t) do
    if v.type == atype then
      if not returnT then returnT = {} end
      for x,y in pairs(v.apply) do
         returnT[x] = y
      end
    end
  end
  return returnT
end

function hasElement(map, element)
  for _,v in ipairs(map) do
    if v == element then
      return true
    end
  end
  return false
end

function getEphemeralDuration(statusEffects, stat)
  for _,array in ipairs(statusEffects) do
    if array[1] == stat then
      return array[2]
    end
  end
  return 0
end

function hasEphemeralStat(statusEffects, stat)
  ephStats = util.map(statusEffects,
    function (elem)
      return elem[1]
    end)
  for _,v in pairs(ephStats) do
    if v == stat then return true end
  end
  return false
end

function hasEphemeralStats(statusEffects, stats)
  ephStats = util.map(statusEffects,
    function (elem)
      return elem[1]
    end)
  for _,v in pairs(ephStats) do
    for _,s in ipairs(stats) do
      if v == s then return true end
    end
  end
  return false
end

function isInLiquid()
  local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
  local mouthful = world.liquidAt(mouthposition)
  return (world.liquidAt(mouthPosition)) and
    ((mcontroller.liquidId()== 1) or 
    (mcontroller.liquidId()== 5) or 
    (mcontroller.liquidId()== 6) or 
    (mcontroller.liquidId()== 12) or 
    (mcontroller.liquidId()== 43) or 
    (mcontroller.liquidId()== 55) or 
    (mcontroller.liquidId()== 58) or
    (mcontroller.liquidId()== 60) or 
    (mcontroller.liquidId()== 69))
end

function incorrectWeapon(isUninit)

  stringTag = "ivrpgincorrectweapon" .. activeItem.hand()
  otherStringTag = "ivrpgincorrectweapon" .. (activeItem.hand() == "alt" and "primary" or "alt")

  if isUninit or not status.statPositive("ivrpghardcore") then
    status.clearPersistentEffects(stringTag)
    return
  end

  local id = activeItem.ownerEntityId()
  local class = config.getParameter("classreq")
  local spec = config.getParameter("specreq")

  if spec and spec ~= world.entityCurrency(id, "spectype") then
    if (#status.getPersistentEffects(otherStringTag) == 0) then
      status.setPersistentEffects(stringTag, {
        {stat = "powerMultiplier", effectiveMultiplier = 0.25}
      })
    end
    return
  elseif class and ((type(class) == "table" and not hasElement(class, world.entityCurrency(id, "classtype"))) or (type(class) == "number" and class ~= world.entityCurrency(id, "classtype"))) then
    if (#status.getPersistentEffects(otherStringTag) == 0) then
      status.setPersistentEffects(stringTag, {
        {stat = "powerMultiplier", effectiveMultiplier = 0.25}
      })
    end
  else
    status.clearPersistentEffects(stringTag)
  end
end

function rescrollSpecialization(class, spec)
  specList = root.assetJson("/ivrpgSpecList.config")
  local specInfo = nil
  if class == 0 or spec == 0 then
    return
  else
    specInfo = root.assetJson("/specs/" .. specList[class][spec].name .. ".config")
  end
  player.makeTechUnavailable(specInfo.tech.name)
  player.consumeCurrency("spectype", spec)
end

function friendlyQuery(a1, a2, a3, a4, ignoresStealth)
  performStealthFunctionOverrides()
  ignoresStealth = ignoresStealth == nil and true or ignoresStealth
  local targetIds = world.entityQuery(a1, a2, a3, ignoresStealth)
  local newTargets = {}
  for _,id in ipairs(targetIds) do
    if world.entityDamageTeam(id).type == "friendly" or (world.entityDamageTeam(id).type == "pvp" and not world.entityCanDamage(a4, id)) then
      table.insert(newTargets, id)
    end
  end
  return newTargets
end

function enemyQuery(a1, a2, a3, a4, ignoresStealth)
  performStealthFunctionOverrides()
  ignoresStealth = ignoresStealth == nil and true or ignoresStealth
  local targetIds = world.entityQuery(a1, a2, a3, ignoresStealth)
  local newTargets = {}
  for _,id in ipairs(targetIds) do
    if world.entityDamageTeam(id).type == "enemy" or (world.entityDamageTeam(id).type == "pvp" and world.entityCanDamage(a4, id)) then
      table.insert(newTargets, id)
    end
  end
  return newTargets
end

function ivrpgBuildItemConfigHelper(id, hand)
  local heldItem = nil
  local itemConfig = nil
  if not hand then
    itemConfig = root.itemConfig(id)
  else
    heldItem = world.entityHandItem(id, hand)
    itemConfig = heldItem and root.itemConfig(heldItem)
  end
  return itemConfig
end

function ivrpgBuildItemConfig(id, hand)
  local pStatus, pMessage = pcall(ivrpgBuildItemConfigHelper, id, hand)
  if not pStatus then sb.logInfo(pMessage or "There was an error attempting to generate an item config") end
  return pMessage
end

-- Only for scripts with access to Player
function sendRadioMessage(text)
  player.radioMessage({
    messageId = "specUnlocks",
    unique = false,
    senderName = "SAIL",
    text = text
  })
end

function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

function hashLength(map)
  if type(map) ~= "table" then return false end
  local count = 0
  for k,v in pairs(map) do
    count = count + 1
  end
  return count
end