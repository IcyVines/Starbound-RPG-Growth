require "/scripts/ivrpgutil.lua"
require "/scripts/ivrpgactivestealthintercept.lua"

local origInit = init
local origUpdate = update
local origUninit = uninit

function init()
  origInit()
  script.setUpdateDelta(14)
  performStealthFunctionOverrides()
  self.removed = true
  self.xp = player.currency("experienceorb")
  self.money = player.currency("money")
  self.moneyDifferential = 0
  checkMaxXP()
  self.xpScalingTimer = 0
  self.xpScaling = status.statusProperty("ivrpgintelligence", 0)
  self.rpgPlayerID = entity.id()
  self.class = player.currency("classtype")
  self.spec = player.currency("spectype")
  self.specList = root.assetJson("/specList.config")
  self.loreList = root.assetJson("/loreList.config")
  self.professionTimer = 0
  self.specsAvailable = {}
  self.damageUpdate = 5
  updateSpecsAvailable()
  
  -- Treasure Test
  --[[local testTreasure = root.assetJson("/scripts/testTreasure.config")
  sb.logInfo(sb.printJson(testTreasure))
  ]]

  local data = root.assetJson("/ivrpgversion.config")
  local oldVersion = status.statusProperty("ivrpgversion", "0")
  if oldVersion ~= data.version then
    status.setStatusProperty("ivrpgversion", data.version)
    if data.giveScrolls then
      player.giveItem("ivrpgscrollresetclass")
      player.giveItem("ivrpgscrollresetaffinity")
    end
    removeTechs()
  end

  if not status.statusProperty("ivrpgskillpoints") then
    status.setStatusProperty("ivrpgskillpoints", math.min(math.floor(math.sqrt(self.xp/100)), 50))
  end
  
  sb.logInfo("Chaika's RPG Growth: Version %s", data.version)
  self.upgradeData = root.assetJson("/ivrpgUpMonDic.config")

  message.setHandler("addXP", function(_, _, amount)
    addXP(amount)
  end)

  message.setHandler("setXPScaling", function(_, _, intelligence)
    if intelligence > self.xpScaling then
      self.xpScalingTimer = 8
      self.xpScaling = intelligence
    end
  end)

  message.setHandler("hasStat", function(_, _, name)
    return status.statPositive(name)
  end)

  message.setHandler("feedbackLoop", function(_, _)
  	if status.statPositive("ivrpgucfeedbackloop") then status.addEphemeralEffect("rage", 2) end
  end)

  message.setHandler("killedEnemy", function(_, _, enemyType, enemyLevel, position, facing, statusEffects, damageDealtForKill, damageKind)
  	killedEnemy(enemyType, enemyLevel, position, facing, statusEffects, damageDealtForKill, damageKind)
  end)

  message.setHandler("modifyResource", function(_, _, type, amount)
  	status.modifyResource(type, amount)
  end)

  message.setHandler("modifyResourcePercentage", function(_, _, type, amount)
    status.modifyResourcePercentage(type, amount)
  end)

  message.setHandler("addEphemeralEffect", function(_, _, name, duration, sourceId)
    status.addEphemeralEffect(name, duration, sourceId)
  end)

  message.setHandler("removeEphemeralEffect", function(_, _, name)
    status.removeEphemeralEffect(name)
  end)

  message.setHandler("sendRadioMessage", function(_, _, text)
    sendRadioMessage(text)
  end)

end

function update(dt)
  origUpdate(dt)

  self.players = world.playerQuery(entity.position(), 60, {withoutEntityId = self.rpgPlayerID}) or {}

  updateXPScalingShare()
  updateXPPulse(dt)
  updateMoneyDifferential()
  updateRallyMode()
  updateLore()

  --admin
  if player.isAdmin() then
    status.setPersistentEffects("ivrpgadmin", {{stat = "admin", amount = 1}})
  else
    status.clearPersistentEffects("ivrpgadmin")
  end

  status.clearPersistentEffects("ivrpgchallenge1progress")
  status.clearPersistentEffects("ivrpgchallenge3progress")
  status.clearPersistentEffects("ivrpgchallenge2progress")

  if self.class ~= player.currency("classtype") then
    if player.currency("spectype") > 0 then
      rescrollSpecialization(self.class, player.currency("spectype"))
    end
    self.class = player.currency("classtype")
    updateSpecsAvailable()
  end

  if self.spec ~= player.currency("spectype") then
    self.spec = player.currency("spectype")
  end

  updateProfessionEffects(dt)
  updateSpecializationEffects(dt)
  updateSkillEffects(dt)

  updateUpgrades()
  updateSpecs(dt)
  unlockSpecs()

  if self.xpScalingTimer > 0 then
    self.xpScalingTimer = math.max(self.xpScalingTimer - dt, 0)
  else
    self.xpScaling = status.statusProperty("ivrpgintelligence", 0)
  end
end

function updateLore()
  local unlocked = false
  local unlockedSpecs = {}
  local unlocks = status.statusProperty("ivrpgloreunlocks", {})
  for _,lore in ipairs(self.loreList) do
    if type(lore) == "table" then
      for _,spec in ipairs(lore) do
        if not unlocks[spec] and status.statusProperty("ivrpgsu" .. spec, false) == true then
          unlocks[spec] = true
          sendRadioMessage("Lore Unlocked: Specialization - " .. lore:gsub("^%l",string.upper))
        end
      end
    elseif not unlocks[lore] then
      unlocks[lore] = true
      unlocked = true
    end
  end
  status.setStatusProperty("ivrpgloreunlocks", unlocks)
  if unlocked then
    sendRadioMessage("Lore Unlocked")
  end
end

function updateSpecializationEffects(dt)
   -- Pioneer Effect
  if status.statPositive("ivrpgterranova") then
    local teleportMarked = false
    local worldId = player.worldId()
    local count = 1
    local coords = {
      location = {},
    }

    local teleportBookmarks = player.teleportBookmarks()
    for _,bookmark in ipairs(teleportBookmarks) do
      if worldId == bookmark.target[1] then
        teleportMarked = true
      end
    end

    if player.worldId():sub(1, 14) == "CelestialWorld" then
      for c in worldId:gmatch(":([^:]*)") do
        if count == 4 then
          coords.planet = tonumber(c)
          break
        end
        (coords.location)[count] = tonumber(c)
        count = count + 1
      end
      --for k,v in pairs(coords.location) do sb.logInfo(v) end
      if player.worldHasOrbitBookmark(coords) or teleportMarked then
        status.setStatusProperty("ivrpgterranova", "Bookmarked")
      else
        status.setStatusProperty("ivrpgterranova", "Not Bookmarked")
      end
    else
      status.setStatusProperty("ivrpgterranova", "Not Celestial")
    end
  end
  -- End Pioneer Effect
end

function updateProfessionEffects(dt)
  local proftype = player.currency("proftype")
  self.professionTimer = math.max(self.professionTimer - dt, 0)
  local element = smithDamageTaken()
  if not status.statusProperty("ivrpgprofessionpassive", false) then return end
  if proftype == 1 then
    if status.resource("health") / status.stat("maxHealth") < 0.25 and not hasEphemeralStats(status.activeUniqueStatusEffectSummary(), {"bandageheal","salveheal","nanowrapheal","medkitheal"}) then
      local healthItems = { {item = "nanowrap", duration = 1}, {item = "bandage", duration = 1},  {item = "medkit", duration = 10}, {item = "salve", duration = 10}}
      for _,v in ipairs(healthItems) do
        if self.professionTimer == 0 and player.hasItem(v.item) then
          player.consumeItem({v.item, 1})
          status.addEphemeralEffect(v.item .. "heal", v.duration, self.rpgPlayerID)
          status.setStatusProperty("ivrpgprofessionpassiveactivation", true)
          self.professionTimer = v.duration
        end
      end
    end
  elseif proftype == 2 then
    local foodItems = {
      {item = "ivrpgmeatcrunch", statusName = "armor"},
      {item = "ivrpgtripletreat", statusName = "damage"},
      {item = "ivrpgveggiemix", statusName = "health"},
      {item = "rawpoultry", statusName = ""},
      {item = "alienmeat", statusName = ""},
      {item = "rawfish", statusName = ""}
    }
    local item = false
    for _,v in ipairs(foodItems) do
      if player.hasItem(v.item) and not hasEphemeralStat(status.activeUniqueStatusEffectSummary(), "ivrpgtamerstatuscooldown") then
        item = v
        break
      end
    end
    local targetIds = item and world.monsterQuery(entity.position(), 20)
    if targetIds then
      for _,id in ipairs(targetIds) do
        if world.entityDamageTeam(id).type == "friendly" then
          local health = world.entityHealth(id)
          if health and health[1]/health[2] < 0.5 then
            player.consumeItem({item.item, 1})
            status.addEphemeralEffect("ivrpgtamerstatuscooldown", 30)
            world.sendEntityMessage(id, "applyStatusEffect", "ivrpgtamermonsterregen" .. item.statusName, 15, self.rpgPlayerID)
            break
          end
        end
      end
    end
  elseif proftype == 3 then
    if self.moneyDifferential > 3 and status.overConsumeResource("energy", self.moneyDifferential / 2) then
      player.giveItem({"experienceorb", math.floor(self.moneyDifferential / 4)})
      player.consumeCurrency("money", math.floor(self.moneyDifferential / 2))
    end
  elseif proftype == 7 then
    if status.resource("energy") / status.stat("maxEnergy") < 0.25 and not hasEphemeralStat(status.activeUniqueStatusEffectSummary(), "ivrpgengineerstatuscooldown") then
      local energyItems = {{item = "smallbattery", kind = "modifyResource", amount = 20}, {item = "battery", kind = "modifyResource", amount = 60}, {item = "ivrpgspowercell", kind = "modifyResourcePercentage", amount = 0.5}}
      for _,v in ipairs(energyItems) do
        if player.hasItem(v.item) then
          player.consumeItem({v.item, 1})
          status[v.kind]("energy", v.amount)
          status.addEphemeralEffect("ivrpgengineerstatuscooldown")
        end
      end
    end
  elseif proftype == 10 then
    if element then
      local time = getEphemeralDuration(status.activeUniqueStatusEffectSummary(), "ivrpgsmithstatusresistance")
      if status.overConsumeResource("energy", 45 - math.min(45*time, 45)) then
        status.setStatusProperty("ivrpgsmithstatuselement", element)
        status.addEphemeralEffect("ivrpgsmithstatusresistance", 15, self.rpgPlayerID)
      end
    end
  end
end

function updateSkillEffects()
  local activeSkills = status.statusProperty("ivrpgskills", {})
  if self.class > 0 and self.spec > 0 then
    local gender = self.specList[self.class][self.spec].gender
    if gender and gender ~= player.gender() and not (activeSkills.skillbodytrueunderstanding and activeSkills.skillmindtrueunderstanding and activeSkills.skillsoultrueunderstanding) then
      rescrollSpecialization(self.class, self.spec)
    end
  end
end

function smithDamageTaken(dt)
  local notifications = nil
  notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  if not status.statusProperty("ivrpgprofessionpassive", false) then return false end
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.damageSourceKind then
        local elements = {"fire", "electric", "ice", "poison", "holy", "demonic", "nova", "cosmic", "shadow", "radioactive"}
        for _,element in ipairs(elements) do
          if string.find(notification.damageSourceKind, element) then
            return element
          end
        end
      end
    end
  end
  return false
end

function updateSpecsAvailable()
  if self.class > 0 then
    self.specsAvailable = self.specList[self.class]
  else
    self.specsAvailable = {}
  end
end

function uninit()
  updateRallyMode(true)
  origUninit()
  status.removeEphemeralEffect("ivrpgstatboosts")
  status.removeEphemeralEffect("ivrpganimation")
  status.clearPersistentEffects("ivrpgclassboosts")
  status.clearPersistentEffects("ivrpgstatboosts")
  status.clearPersistentEffects("ivrpgaffinityeffects")
  status.removeEphemeralEffect("explorerglow")
  status.removeEphemeralEffect("knightblock")
  status.removeEphemeralEffect("ninjacrit")
  status.removeEphemeralEffect("wizardaffinity")
  status.removeEphemeralEffect("roguepoison")
  status.removeEphemeralEffect("soldierdiscipline")
end

function removeTechs()
    --These Techs are deprecated, so should be removed!
    player.makeTechUnavailable("roguecloudjump")
    player.makeTechUnavailable("roguetoxiccapsule")
    player.makeTechUnavailable("roguepoisondash")
    player.makeTechUnavailable("soldiermissilestrike")
    player.makeTechUnavailable("explorerdrill")
end

function updateXPPulse()    
  if self.xp then
    local new = player.currency("experienceorb") - self.xp
    if new > 0 then
      local multiplier = self.xpScaling * 0.005
      if multiplier > 0 then player.giveItem({"experienceorb", new * multiplier}) end
      new = new * (1 + multiplier)
      for _,id in ipairs(self.players) do
        world.sendEntityMessage(id, "addXP", new)
      end
    end
  end
  self.xp = player.currency("experienceorb")
  checkMaxXP()
end

function checkMaxXP()
  if (self.xp or 0) > 500000 then
    player.consumeCurrency("experienceorb", self.xp - 500000)
  end
  self.xp = player.currency("experienceorb")
end

function updateXPScalingShare()
  for _,id in ipairs(self.players) do
    world.sendEntityMessage(id, "setXPScaling", status.statusProperty("ivrpgintelligence", 0))
  end
end

function updateMoneyDifferential()
  local money = player.currency("money")
  self.moneyDifferential = 0
  if money ~= self.money then
    self.moneyDifferential = math.max(money - self.money, 0)
    self.money = money
  end
end

function updateRallyMode(uninit)
  local rallyActive = status.statusProperty("ivrpgrallymode", false)
  world.setProperty("ivrpgRallyMode[" .. self.rpgPlayerID .. "]", rallyActive and math.floor(math.sqrt(self.xp/100)) or 0)
end

function addXP(new)
  player.giveItem({"experienceorb", new})
  self.xp = player.currency("experienceorb")
  checkMaxXP()
end

function updateUpgrades()

end

function updateSpecs(dt)
  if player.currency("experienceorb") < 122500 and not status.statPositive("ivrpgmasteryunlocked") then
    return
  end

  -- Pioneer
  if self.class == 6 and type(status.statusProperty("ivrpgsupioneer", 0)) == "number" then
    local worldId = player.worldId()
    if worldId:sub(1, 14) == "CelestialWorld" then
      local visitedPlanets = status.statusProperty("ivrpgsupioneerplanets", {})
      if not visitedPlanets[worldId] then
        visitedPlanets[worldId] = 0
        status.setStatusProperty("ivrpgsupioneerplanets", visitedPlanets)
      else
        if type(visitedPlanets[worldId]) == "number" then
          local time = visitedPlanets[worldId] + dt
          if time > 180 then
            visitedPlanets[worldId] = true
            status.setStatusProperty("ivrpgsupioneer", status.statusProperty("ivrpgsupioneer", 0) + 1)
          else
            visitedPlanets[worldId] = time
          end
          status.setStatusProperty("ivrpgsupioneerplanets", visitedPlanets)
        end
      end
    end
  end
  -- End Pioneer

  -- Captain
  if self.class == 6 and type(status.statusProperty("ivrpgsucaptain", 0)) == "number" then
    if player.worldId() ~= player.ownShipWorldId() then return end
    local crewIds = world.npcQuery(world.entityPosition(self.rpgPlayerID), 60)
    local crewSize = 0
    if crewIds then
      for _,id in ipairs(crewIds) do
        if string.find(world.entityTypeName(id), "crewmember") then
          crewSize = crewSize + 1
        end
      end
    end
    status.setStatusProperty("ivrpgsucaptain", crewSize)
  end
  -- End Captain

end

function unlockSpecs()

  if player.currency("experienceorb") < 122500 and not status.statPositive("ivrpgmasteryunlocked") then
    return
  end

  for _,spec in ipairs(self.specsAvailable) do
    local unlockStatus = status.statusProperty(spec.unlockStatus)
    if spec.unlockNumber and type(unlockStatus) == "number" and unlockStatus >= spec.unlockNumber then
      sendRadioMessage(spec.title .. " Unlocked!")
      status.setStatusProperty(spec.unlockStatus, true)
    end
  end

end

function killedEnemy(enemyType, level, position, facing, statusEffects, damage, damageType)
  addToChallengeCount(level)
  dyingEffects(position, statusEffects)
  killingEffects(level, position, statusEffects, damageType, enemyType)
  dropUpgradeChips(level, position, enemyType)
  specChecks(enemyType, level, position, facing, statusEffects, damage, damageType)
end

function specChecks(enemyType, level, position, facing, statusEffects, damage, damageType)
  if player.currency("experienceorb") < 122500 and not status.statPositive("ivrpgmasteryunlocked") then
    return
  end

  for _,spec in ipairs(self.specsAvailable) do
    if status.statusProperty(spec.unlockStatus) ~= true then
      local unlockBehavior = spec.unlockBehavior
      if unlockBehavior then
        local damageTypes = unlockBehavior.damageTypes
        local damageTypeBonus = unlockBehavior.damageTypeBonus
        local enemyTypes = unlockBehavior.enemyTypes
        local requiredPosition = unlockBehavior.requiredPosition
        local requiredCurrency = unlockBehavior.requiredCurrency
        local ignore = false
        local trueIgnore = false
        local healthBonus = 1
        local damageBonus = 1
        
        if damageTypes then
          ignore = true
          for _,dType in ipairs(damageTypes) do
            if string.find(damageType, dType) then
              ignore = false
              break
            end
          end
          if ignore then trueIgnore = true end
        end

        if damageTypeBonus then
          for dType,bonusMultiplier in pairs(damageTypeBonus) do
            if string.find(damageType, dType) then
              damageBonus = bonusMultiplier
              break
            end
          end
        end

        if requiredPosition then
          ignore = true
          if requiredPosition.type == "<" and world.magnitude(position, world.entityPosition(self.rpgPlayerID)) < requiredPosition.magnitude then
            ignore = false
          elseif requiredPosition.type == ">" and world.magnitude(position, world.entityPosition(self.rpgPlayerID)) > requiredPosition.magnitude then
            ignore = false
          elseif requiredPosition.type == "behind" and facing * world.distance(world.entityPosition(self.rpgPlayerID), position)[1] < 0 then
            ignore = false
          end
          if ignore then trueIgnore = true end
        end

        if requiredCurrency then
          for currency,amount in pairs(requiredCurrency) do
            if player.currency(currency) < amount then
              ignore = true
              break
            end
            ignore = false
          end
          if ignore then trueIgnore = true end
        end

        if unlockBehavior.healthUnder then
          ignore = true
          if status.resource("health") / status.stat("maxHealth") < unlockBehavior.healthUnder then
            healthBonus = (status.resource("health") / status.stat("maxHealth") + 0.7)^-5
            ignore = false
          end
          if ignore then trueIgnore = true end
        end

        if unlockBehavior.weaponTypes then
          ignore = not checkWeaponCombo(unlockBehavior.weaponTypes[1], unlockBehavior.weaponTypes[2])
          if ignore then trueIgnore = true end
        end

        if enemyTypes and not trueIgnore then
          for _,v in ipairs(enemyTypes) do
            if string.find(enemyType, v.type) then
              status.setStatusProperty(spec.unlockStatus, status.statusProperty(spec.unlockStatus, 0) + healthBonus * damageBonus * (v.modifier and level * v.modifier or (v.amount or level)))
              break
            end
          end
        end

      end
    end
  end

end

function checkWeaponCombo(tag1, tag2)
  self.heldItem = world.entityHandItem(self.rpgPlayerID, "primary")
  self.heldItem2 = world.entityHandItem(self.rpgPlayerID, "alt")
  if self.heldItem and self.heldItem2 and ((root.itemHasTag(self.heldItem, tag1) and root.itemHasTag(self.heldItem2, tag2)) or (root.itemHasTag(self.heldItem, tag2) and root.itemHasTag(self.heldItem2, tag1))) then
    return true
  else
    return false
  end
end

function dropUpgradeChips(level, position, name)
  local monsterData = self.upgradeData.monsters[name]
  if monsterData then
    shuffle(monsterData)
    local item = monsterData[1]
    local itemData = self.upgradeData.items[item]
    if itemData then
      level = level * itemData
    end
    if level >= math.random(1,1000) then
      world.spawnItem(item, position)
    end
  end
end

function addToChallengeCount(level)
  local challenge1 = status.stat("ivrpgchallenge1")
  local challenge2 = status.stat("ivrpgchallenge2")
  local challenge3 = status.stat("ivrpgchallenge3")

	if challenge1 == 1 and level >= 4 then
    status.setStatusProperty("ivrpgchallenge1progress", status.statusProperty("ivrpgchallenge1progress", 0) + 1)
	elseif challenge1 == 2 and level >= 5 then
		status.setStatusProperty("ivrpgchallenge1progress", status.statusProperty("ivrpgchallenge1progress", 0) + 1)
	end

	if challenge2 == 1 and level >= 6 then
		status.setStatusProperty("ivrpgchallenge2progress", status.statusProperty("ivrpgchallenge2progress", 0) + 1)
	end

	if challenge3 == 1 and level >= 7 then
		status.setStatusProperty("ivrpgchallenge3progress", status.statusProperty("ivrpgchallenge3progress", 0) + 1)
	end
end

function dyingEffects(position, statusEffects)
  if status.statPositive("ivrpgucbloom") then
    if hasEphemeralStat(statusEffects, "ivrpgsear") or hasEphemeralStat(statusEffects, "burning") or hasEphemeralStat(statusEffects, "melting") then
    	world.spawnProjectile(
        	"fireplasmaexplosionstatus",
        	position,
        	self.rpgPlayerID,
        	{0,0},
        	false,
        	{timeToLive = 0.25, power = status.stat("powerMultiplier")*50}
      )
    end
  end
end

function killingEffects(level, position, statusEffects, damageType, name)

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