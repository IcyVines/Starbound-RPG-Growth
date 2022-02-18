require "/scripts/ivrpgutil.lua"
require "/scripts/ivrpgactivestealthintercept.lua"

local origInit = init
local origUpdate = update
local origUninit = uninit

function init()
  origInit()
  performStealthFunctionOverrides()
  self.rpg_xp = player.currency("experienceorb")
  self.rpg_level = math.floor(math.sqrt(self.rpg_xp/100))
  self.rpg_money = player.currency("money")
  self.rpg_moneyDifferential = 0
  checkMaxXP()
  self.rpg_xpScalingTimer = 0
  self.rpg_xpScaling = status.statusProperty("ivrpgintelligence", 0)
  self.rpg_playerId = entity.id()
  self.rpg_class = player.currency("classtype")
  self.rpg_spec = player.currency("spectype")
  self.rpg_specList = root.assetJson("/ivrpgSpecList.config")
  self.rpg_loreList = root.assetJson("/ivrpgLoreList.config")
  self.rpg_monsterLoreList = root.assetJson("/ivrpgMonsterLoreUnlocks.config")
  self.rpg_levelRequirements = root.assetJson("/ivrpgLevelRequirements.config")
  self.rpg_professionTimer = 0
  self.rpg_specsAvailable = {}
  self.rpg_damageUpdate = 5

  self.rpg_specUnlockXp = self.rpg_levelRequirements.specialization ^ 2 * 100

  updateSpecsAvailable()

  local data = root.assetJson("/ivrpgVersion.config")
  local oldVersion = status.statusProperty("ivrpgversion", "0")
  if oldVersion ~= data.version then
    status.setStatusProperty("ivrpgversion", data.version)
    if data.giveScrolls then
      player.giveItem("ivrpgscrollresetclass")
      player.giveItem("ivrpgscrollresetaffinity")
    end
    removeTechs()
    --Lines for one update only
  end

  if not status.statusProperty("ivrpgskillpoints") then
    status.setStatusProperty("ivrpgskillpoints", math.min(math.floor(math.sqrt(self.rpg_xp/100)), 50))
  end
  
  sb.logInfo("Chaika's RPG Growth: Version %s", data.version)
  self.rpg_upgradeData = root.assetJson("/ivrpgUpMonDic.config")

  message.setHandler("addXP", function(_, _, amount)
    addXP(amount)
  end)

  message.setHandler("setXPScaling", function(_, _, intelligence)
    if intelligence > self.rpg_xpScaling then
      self.rpg_xpScalingTimer = 8
      self.rpg_xpScaling = intelligence
    end
  end)

  message.setHandler("hasStat", function(_, _, name)
    return status.statPositive(name)
  end)

  message.setHandler("feedbackLoop", function(_, _)
    if status.statPositive("ivrpgucfeedbackloop") then status.addEphemeralEffect("rage", 2) end
  end)

  message.setHandler("killedEnemy", function(_, _, enemyType, enemyLevel, position, facing, statusEffects, damageDealtForKill, damageKind, bledToDeath)
    killedEnemy(enemyType, enemyLevel, position, facing, statusEffects, damageDealtForKill, damageKind, bledToDeath)
    world.sendEntityMessage(self.rpg_playerId, "killedEnemyDarkTemplar", enemyLevel, damageKind, bledToDeath)
    world.sendEntityMessage(self.rpg_playerId, "killedEnemyDeadshot", enemyLevel, damageKind, bledToDeath)
  end)

  message.setHandler("damageDealt", function(_, _, damage, damageKind, bleedKind, damageNotRegistered)
  	world.sendEntityMessage(self.rpg_playerId, "damageDealtDarkTemplar", damage, damageKind, bleedKind)
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

  message.setHandler("interact", function(_, _, scriptType, script, sourceId)
    player.interact(scriptType, script, sourceId)
  end)

  message.setHandler("giveItem", function(_, _, item, amount)
    player.giveItem({item, amount})
  end)

  message.setHandler("challengeStatusProperty", function(_, _, statusProperty, challengeNumber, bossNumber)
    if status.stat(challengeNumber) == bossNumber then
      status.setStatusProperty(statusProperty, status.statusProperty(statusProperty, 0) + 1)
    end
  end)

  message.setHandler("giveBlueprint", function(_, _, blueprint)
    if type(blueprint) == "string" then
    	player.giveBlueprint(blueprint)
    elseif type(blueprint) == "table" then
    	for _,bp in ipairs(blueprint) do
    		player.giveBlueprint(bp)
    	end
    end
  end)

  message.setHandler("applySelfDamageRequest", function(_, _, damageType, damageSourceKind, damage, sourceId)
    status.applySelfDamageRequest({
      damageType = damageType,
      damageSourceKind = damageSourceKind,
      damage = math.floor(damage),
      sourceEntityId = sourceId
    })
  end)

  message.setHandler("ivrpgExtractRemoval", function(_ ,_ , id, configSrc)
    local configSrc = root.assetJson(configSrc)
    player.interact("ScriptPane", configSrc, id)
  end)

end

function update(dt)
  origUpdate(dt)

  self.rpg_players = world.playerQuery(entity.position(), 60, {withoutEntityId = self.rpg_playerId}) or {}

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

  if self.rpg_class ~= player.currency("classtype") then
    if player.currency("spectype") > 0 then
      rescrollSpecialization(self.rpg_class, player.currency("spectype"))
    end
    self.rpg_class = player.currency("classtype")
    updateSpecsAvailable()
  end

  if self.rpg_spec ~= player.currency("spectype") then
    self.rpg_spec = player.currency("spectype")
  end

  updateProfessionEffects(dt)

  local rpg_pStatus, rpg_pMessage = pcall(updateSpecializationEffects, dt)
  if not rpg_pStatus then sb.logInfo(rpg_pMessage or "RPG Growth: There was an error attempting to generate certain specialization effects!") end
  
  updateSkillEffects(dt)

  updateUpgrades()
  updateSpecs(dt)
  unlockSpecs()

  if self.rpg_xpScalingTimer > 0 then
    self.rpg_xpScalingTimer = math.max(self.rpg_xpScalingTimer - dt, 0)
  else
    self.rpg_xpScaling = status.statusProperty("ivrpgintelligence", 0)
  end

  local newLevel = math.min(math.floor(math.sqrt(self.rpg_xp/100)), 50)
  if inMech() and self.rpg_level < newLevel then
    status.setStatusProperty("ivrpgskillpoints", status.statusProperty("ivrpgskillpoints", 0) + (newLevel - self.rpg_level))
    localAnimator.playAudio("/sfx/cinematics/mission_unlock_event.ogg")
  end
  self.rpg_level = newLevel

  -- Alchemist
  toxicity = status.statusProperty("ivrpg_alchemic_toxicity", 0)
  if not status.statPositive("ivrpg_alchemy_active") then
    status.setStatusProperty("ivrpg_alchemic_toxicity", math.max(toxicity - dt * (toxicity + 20) / 20, 0))
  end

  if toxicity >= 30 then
    status.setPersistentEffects("ivrpg_alchemic_toxicity", {
      {stat = "maxEnergy", effectiveMultiplier = 30 / toxicity},
      {stat = "powerMultiplier", effectiveMultiplier = 30 / toxicity},
    })
  else
    status.clearPersistentEffects("ivrpg_alchemic_toxicity")
  end

end

function updateLore()
  local unlocked = false
  local unlockedSpecs = {}
  local unlocks = status.statusProperty("ivrpgloreunlocks", {})
  for _,lore in ipairs(self.rpg_loreList) do
    if type(lore) == "table" then
      for _,spec in ipairs(lore) do
        if not unlocks[spec] and status.statusProperty("ivrpgsu" .. spec, false) == true then
          unlocks[spec] = true
          if spec == "darktemplar" then spec = "Dark Templar" elseif spec == "battlemage" then spec = "Battle Mage" end
          sendRadioMessage("Lore Unlocked: Specialization - " .. spec:gsub("^%l",string.upper))
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

  -- Pilot Effect
  if status.statPositive("ivrpg_homeawayfromhome") then
    if string.find(player.worldId(), "ClientShipWorld") then
      status.modifyResourcePercentage("food", 0.01 * dt)
      status.modifyResourcePercentage("health", 0.01 * dt)
    end
  end
  -- End Pilot Effect
end

function updateProfessionEffects(dt)
  local proftype = player.currency("proftype")
  self.rpg_professionTimer = math.max(self.rpg_professionTimer - dt, 0)
  local element = smithDamageTaken()
  local pPassive = status.statusProperty("ivrpgprofessionpassive", false)
  self.rpg_jewelerExperience = (proftype == 9) and pPassive
  if not pPassive then return end
  if proftype == 1 then
    if status.resource("health") / status.stat("maxHealth") < 0.25 and not hasEphemeralStats(status.activeUniqueStatusEffectSummary(), {"bandageheal","salveheal","nanowrapheal","medkitheal"}) then
      local healthItems = {
      	{item = "nanowrap", duration = 1},
      	{item = "bandage", duration = 1}, 
      	{item = "medkit", duration = 10},
      	{item = "salve", duration = 10}
      }
      for _,v in ipairs(healthItems) do
        if self.rpg_professionTimer == 0 and player.hasItem(v.item) then
          player.consumeItem({v.item, 1})
          status.addEphemeralEffect(v.item .. "heal", v.duration, self.rpg_playerId)
          status.setStatusProperty("ivrpgprofessionpassiveactivation", true)
          self.rpg_professionTimer = v.duration
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
    local petIds = item and status.statusProperty("ivrpg-pets", {})
    if petIds then
      for id,v in pairs(petIds) do
        local health = false
        local maxHealth = false
        if v.status then
          health = v.status.resources and v.status.resources.health
          maxHealth = v.status.resourceMax and v.status.resourceMax.health
        end
        if health and maxHealth and health/maxHealth < 0.5 then
          player.consumeItem({item.item, 1})
          status.addEphemeralEffect("ivrpgtamerstatuscooldown", 30)
          world.sendEntityMessage(id, "applyStatusEffect", "ivrpgtamermonsterregen" .. item.statusName, 15, self.rpg_playerId)
          break
        end
      end
    end
  elseif proftype == 3 then
    if self.rpg_moneyDifferential > 3 and status.overConsumeResource("energy", self.rpg_moneyDifferential / 2) then
      player.giveItem({"experienceorb", math.floor(self.rpg_moneyDifferential / 4)})
      player.consumeCurrency("money", math.floor(self.rpg_moneyDifferential / 2))
    end
  elseif proftype == 7 then
    if status.resource("energy") / status.stat("maxEnergy") < 0.25 and not hasEphemeralStat(status.activeUniqueStatusEffectSummary(), "ivrpgengineerstatuscooldown") then
      local energyItems = {
      	{item = "smallbattery", kind = "modifyResource", amount = 20},
      	{item = "battery", kind = "modifyResource", amount = 60},
      	{item = "ivrpgspowercell", kind = "modifyResourcePercentage", amount = 0.5}
      }
      for _,v in ipairs(energyItems) do
        if player.hasItem(v.item) then
          player.consumeItem({v.item, 1})
          status[v.kind]("energy", v.amount)
          status.addEphemeralEffect("ivrpgengineerstatuscooldown")
        end
      end
    end
  elseif proftype == 8 then
    local blockPos = {entity.position()[1], entity.position()[2] - 3}
    local block = world.material(blockPos, "foreground")
    local mod = world.mod(blockPos, "foreground")
    if block == "dirt" then
      if mod ~= "tilled" then status.overConsumeResource("energy", 10) end
      world.placeMod(blockPos, "foreground", "tilled")
    end
  elseif proftype == 10 then
    if element then
      local time = getEphemeralDuration(status.activeUniqueStatusEffectSummary(), "ivrpgsmithstatusresistance")
      if status.overConsumeResource("energy", 45 - math.min(45*time, 45)) then
        status.setStatusProperty("ivrpgsmithstatuselement", element)
        status.addEphemeralEffect("ivrpgsmithstatusresistance", 15, self.rpg_playerId)
      end
    end
  end
end

function updateSkillEffects()
  local activeSkills = status.statusProperty("ivrpgskills", {})
  if self.rpg_class > 0 and self.rpg_spec > 0 then
    local gender = self.rpg_specList[self.rpg_class][self.rpg_spec].gender
    if gender and gender ~= player.gender() and not (activeSkills.skillbodytrueunderstanding and activeSkills.skillmindtrueunderstanding and activeSkills.skillsoultrueunderstanding) then
      rescrollSpecialization(self.rpg_class, self.rpg_spec)
    end
  end
end

function smithDamageTaken(dt)
  local notifications = nil
  notifications, self.rpg_damageUpdate = status.damageTakenSince(self.rpg_damageUpdate)
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

function calculateJewelerConversion(experience)
  if not self.rpg_jewelerExperience then return 0 end
  experience = math.floor(experience)
  if experience < 4 then return 0 end

  local food = status.resource("food")
  local maxConversion = math.max(food - 20, 0)
  local minRemoval = math.min(maxConversion, experience / 4)
  if status.consumeResource("food", minRemoval) then
    player.giveItem({"money", math.floor(minRemoval)})
    return math.floor(minRemoval * 2)
  end
end

function updateSpecsAvailable()
  if self.rpg_class > 0 then
    self.rpg_specsAvailable = self.rpg_specList[self.rpg_class]
  else
    self.rpg_specsAvailable = {}
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
  status.clearPersistentEffects("ivrpgelementalovercharge")
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
  if self.rpg_xp then
    local new = player.currency("experienceorb") - self.rpg_xp
    if new > 0 then
      local multiplier = self.rpg_xpScaling * 0.005
      if multiplier > 0 then
        local removeXP = calculateJewelerConversion(new * multiplier)
        player.giveItem({"experienceorb", new * multiplier - removeXP})
      end
      new = new * (1 + multiplier)
      for _,id in ipairs(self.rpg_players) do
        world.sendEntityMessage(id, "addXP", new)
      end
    end
  end
  self.rpg_xp = player.currency("experienceorb")
  checkMaxXP()
end

function checkMaxXP()
  if (self.rpg_xp or 0) > 500000 then
    player.consumeCurrency("experienceorb", self.rpg_xp - 500000)
  end
  self.rpg_xp = player.currency("experienceorb")
end

function updateXPScalingShare()
  for _,id in ipairs(self.rpg_players) do
    world.sendEntityMessage(id, "setXPScaling", status.statusProperty("ivrpgintelligence", 0))
  end
end

function updateMoneyDifferential()
  local money = player.currency("money")
  self.rpg_moneyDifferential = 0
  if money ~= self.rpg_money then
    self.rpg_moneyDifferential = math.max(money - self.rpg_money, 0)
    self.rpg_money = money
  end
end

function updateRallyMode(uninit)
  local rallyActive = status.statusProperty("ivrpgrallymode", false)
  world.setProperty("ivrpgRallyMode[" .. self.rpg_playerId .. "]", rallyActive and math.floor(math.sqrt(self.rpg_xp/100)) or 0)
end

function addXP(new)
  player.giveItem({"experienceorb", new})
  self.rpg_xp = player.currency("experienceorb")
  checkMaxXP()
end

function updateUpgrades()

end

function updateSpecs(dt)
  if player.currency("experienceorb") < self.rpg_specUnlockXp and not status.statPositive("ivrpgmasteryunlocked") then
    return
  end

  -- Pioneer, Scout
  if self.rpg_class == 6 then
    local scoutLocked = type(status.statusProperty("ivrpgsuscout", 0)) == "number"
    local pioneerLocked = type(status.statusProperty("ivrpgsupioneer", 0)) == "number"
    local pilotLocked = type(status.statusProperty("ivrpgsupilot", 0)) == "number"

    if pilotLocked and inMech() then
      status.setStatusProperty("ivrpgsupilot", status.statusProperty("ivrpgsupilot", 0) + dt)
    end

    if scoutLocked or pioneerLocked then
      local worldId = player.worldId()
      if worldId:sub(1, 14) == "CelestialWorld" then
        local visitedPlanets = status.statusProperty("ivrpgsupioneerplanets", {})
        -- Pioneer
        if not visitedPlanets[worldId] then
          visitedPlanets[worldId] = 0
          status.setStatusProperty("ivrpgsupioneerplanets", visitedPlanets)
          -- Scout
          if scoutLocked then
            local count = 0
            for k,v in pairs(visitedPlanets) do
              count = count + 1
            end
            status.setStatusProperty("ivrpgsuscout", count)
          end
        elseif pioneerLocked then
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
  end
  -- End Pioneer, Scout

  -- Captain
  if self.rpg_class == 6 and type(status.statusProperty("ivrpgsucaptain", 0)) == "number" then
    local crew = status.statusProperty("ivrpg-crew", {})
    if hashLength(crew) > 0 then
      status.setStatusProperty("ivrpgsucaptain", hashLength(crew))
    end
  end
  -- End Captain

  -- Thief
  if self.rpg_moneyDifferential and self.rpg_moneyDifferential > 0 and (self.rpg_class == 3 or self.rpg_class == 5) and type(status.statusProperty("ivrpgsuthief", 0)) == "number" then
    status.setStatusProperty("ivrpgsuthief", status.statusProperty("ivrpgsuthief", 0) + self.rpg_moneyDifferential)
  end
  -- End Thief

end

function unlockSpecs()

  if player.currency("experienceorb") < self.rpg_specUnlockXp and not status.statPositive("ivrpgmasteryunlocked") then
    return
  end

  for _,spec in ipairs(self.rpg_specsAvailable) do
    local unlockStatus = status.statusProperty(spec.unlockStatus)
    if spec.unlockNumber and type(unlockStatus) == "number" and unlockStatus >= spec.unlockNumber then
      sendRadioMessage(spec.title .. " Unlocked!")
      status.setStatusProperty(spec.unlockStatus, true)
    end
  end

end

function killedEnemy(enemyType, level, position, facing, statusEffects, damage, damageType, bledToDeath)
  addToChallengeCount(level)
  dyingEffects(position, statusEffects)
  killingEffects(level, position, statusEffects, damageType, enemyType, bledToDeath)
  dropUpgradeChips(level, position, enemyType)
  specChecks(enemyType, level, position, facing, statusEffects, damage, damageType, bledToDeath)
  unlockMonsterLore(enemyType)
end

function unlockMonsterLore(enemyType)
  local unlocks = status.statusProperty("ivrpgloreunlocks", {})
  local unlock = self.rpg_monsterLoreList[enemyType]
  if unlock then
    local enemyTypeCondensed = enemyType:gsub("ivrpg_","",1)
    if unlocks[enemyTypeCondensed] then return end
    unlocks[enemyTypeCondensed] = true
    sendRadioMessage("Lore Unlocked: Mechanics - Enemies - " .. unlock)
    status.setStatusProperty("ivrpgloreunlocks", unlocks)
  end
end

function specChecks(enemyType, level, position, facing, statusEffects, damage, damageType, bledToDeath)
  if player.currency("experienceorb") < self.rpg_specUnlockXp and not status.statPositive("ivrpgmasteryunlocked") then
    return
  end

  for _,spec in ipairs(self.rpg_specsAvailable) do
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
        local positionBonus = 1
        local bleedBonus = bledToDeath and unlockBehavior.bleedBonus or 1
        
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
          if requiredPosition.type == "behind" then
            if facing * world.distance(world.entityPosition(self.rpg_playerId), position)[1] < 0 then
              ignore = false
              if requiredPosition.optional then positionBonus = 2 end
            end
          elseif operate(requiredPosition.type, world.magnitude(position, world.entityPosition(self.rpg_playerId)),  requiredPosition.magnitude) then
            ignore = false
            if requiredPosition.optional then positionBonus = 2 end
          end
          if ignore and not requiredPosition.optional then trueIgnore = true end
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

        local fullBonus = healthBonus * damageBonus * positionBonus * bleedBonus

        if enemyTypes and not trueIgnore then
          for _,v in ipairs(enemyTypes) do
            if string.find(enemyType, v.type) then
              status.setStatusProperty(spec.unlockStatus, status.statusProperty(spec.unlockStatus, 0) + fullBonus * (v.modifier and level * v.modifier or (v.amount or level)))
              break
            end
          end
        elseif (not enemyTypes) and not trueIgnore then
          status.setStatusProperty(spec.unlockStatus, status.statusProperty(spec.unlockStatus, 0) + fullBonus * level)
        end

      end
    end
  end

end

function checkWeaponCombo(tag1, tag2)
  self.rpg_heldItem = world.entityHandItem(self.rpg_playerId, "primary")
  self.rpg_heldItem2 = world.entityHandItem(self.rpg_playerId, "alt")
  if tag1 == tag2 then
    if (self.rpg_heldItem and root.itemHasTag(self.rpg_heldItem, tag1)) or (self.rpg_heldItem2 and root.itemHasTag(self.rpg_heldItem2, tag2)) then
      return true
    else
      return false
    end
  end
  
  if self.rpg_heldItem and self.rpg_heldItem2 and ((root.itemHasTag(self.rpg_heldItem, tag1) and root.itemHasTag(self.rpg_heldItem2, tag2)) or (root.itemHasTag(self.rpg_heldItem, tag2) and root.itemHasTag(self.rpg_heldItem2, tag1))) then
    return true
  else
    return false
  end
end

function dropUpgradeChips(level, position, name)
  local monsterData = self.rpg_upgradeData.monsters[name]
  if monsterData then
    shuffle(monsterData)
    local item = monsterData[1]
    local itemData = self.rpg_upgradeData.items[item]
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
          self.rpg_playerId,
          {0,0},
          false,
          {timeToLive = 0.25, power = status.stat("powerMultiplier")*50}
      )
    end
  end
end

function killingEffects(level, position, statusEffects, damageType, name, bleedKind)

end