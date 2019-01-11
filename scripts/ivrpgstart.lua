require "/scripts/ivrpgutil.lua"
local origInit = init
local origUpdate = update
local origUninit = uninit

function init()
  origInit()
  script.setUpdateDelta(14)
  self.removed = true
  self.xp = player.currency("experienceorb")
  checkMaxXP()
  self.xpScalingTimer = 0
  self.xpScaling = status.statusProperty("ivrpgintelligence", 0)
  self.id = entity.id()
  self.class = player.currency("classtype")
  self.spec = player.currency("spectype")
  self.specList = root.assetJson("/specList.config")
  self.specsAvailable = {}
  updateSpecsAvailable()
  
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
  
  sb.logInfo("Chaika's RPG Growth: Version %s", data.version)
  self.upgradeData = root.assetJson("/ivrpgUpMonDic.config")

  message.setHandler("addXP", function(_, _, amount)
    addXP(amount)
  end)

  message.setHandler("setXPScaling", function(_, _, intelligence)
    if intelligence > self.xpScaling then
      self.xpScalingTimer = 0.3
      self.xpScaling = intelligence
      sb.logInfo("In setXPScaling, self.xpScaling = " .. self.xpScaling)
    end
  end)

  message.setHandler("hasStat", function(_, _, name)
    return status.statPositive(name)
  end)

  message.setHandler("feedbackLoop", function(_, _)
  	if status.statPositive("ivrpgucfeedbackloop") then status.addEphemeralEffect("rage", 2) end
  end)

  message.setHandler("killedEnemy", function(_, _, enemyType, enemyLevel, position, statusEffects, damageDealtForKill, damageKind)
  	killedEnemy(enemyType, enemyLevel, position, statusEffects, damageDealtForKill, damageKind)
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

  message.setHandler("sendRadioMessage", function(_, _, text)
    sendRadioMessage(text)
  end)

end

function update(dt)
  origUpdate(dt)

  if self.xpScalingTimer > 0 then
    self.xpScalingTimer = math.max(self.xpScalingTimer - dt, 0)
  else
    self.xpScaling = status.statusProperty("ivrpgintelligence", 0)
  end

  updateXPScalingShare()
  updateXPPulse(dt)
  updateRallyMode()

  --admin
  if player.isAdmin() then
    if not status.statPositive("admin") then status.addPersistentEffect("ivrpgadmin", {stat = "admin", amount = 1}) end
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

  -- Pioneer Effect
  if status.statPositive("ivrpgterranova") then
    local worldId = player.worldId()
    local count = 1
    local coords = {
      location = {},
    }
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
      if player.worldHasOrbitBookmark(coords) then
        status.setStatusProperty("ivrpgterranova", "Bookmarked")
      else
        status.setStatusProperty("ivrpgterranova", "Not Bookmarked")
      end
    else
      status.setStatusProperty("ivrpgterranova", "Not Celestial")
    end
    -- End Pioneer Effect

    --[[for _,v in ipairs(player.orbitBookmarks()) do
      for k,val in pairs(v) do
        --sb.logInfo(k)
        for x,y in pairs(val) do
          if type(y) == "table" then
            for r,o in pairs(y) do
              if type(o) == "table" then
                for f,g in pairs(o) do
                  sb.logInfo(x .. " " .. r .. " " .. f .. " " .. g)
                end
              else
                sb.logInfo(x .. " " .. r .. " " .. o)
              end
            end
          else
            sb.logInfo(x .. " " .. y)
          end
        end
      end
    end]]
  end

  updateUpgrades()
  updateSpecs()
  unlockSpecs()

end

function updateSpecsAvailable()
  if self.class > 0 then
    self.specsAvailable = self.specList[self.class]
  else
    self.specsAvailable = {}
  end
end

function uninit()
  origUninit()
  status.removeEphemeralEffect("ivrpgstatboosts")
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
    sb.logInfo("updateXPPulse - self.xp = " .. self.xp)
    local new = player.currency("experienceorb") - self.xp
    sb.logInfo("updateXPPulse - new = " .. new)
    if new > 0 then
      local multiplier = self.xpScaling * 0.005
      sb.logInfo("In updateXPPulse, multiplier = " .. multiplier)
      if multiplier > 0 then player.giveItem({"experienceorb", new * multiplier}) end
      new = new * (1 + multiplier)
      local players = world.playerQuery(entity.position(), 60, {
        withoutEntityId = self.id
      })
      for _,id in ipairs(players) do
        sb.logInfo("In updateXPPulse, shareId = " .. id)
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
  local players = world.playerQuery(entity.position(), 60, {
    withoutEntityId = self.id
  })
  for _,id in ipairs(players) do
    world.sendEntityMessage(id, "setXPScaling", status.statusProperty("ivrpgintelligence", 0))
  end
end

function updateRallyMode()
  if status.statusProperty("ivrpgrallymode", false) then
    local targetIds = world.entityQuery(entity.position(), 80, {
      withoutEntityId = self.id,
      includedTypes = {"creature"}
    })
    for _,id in ipairs(targetIds) do
      if world.entityAggressive(id) then
        world.sendEntityMessage(id, "ivrpgRally", math.floor(math.sqrt(self.xp/100)), self.id)
      end
    end
  end
end

function addXP(new)
  player.giveItem({"experienceorb", new})
  self.xp = player.currency("experienceorb")
  checkMaxXP()
end

function updateUpgrades()

end

function updateSpecs()
  if player.currency("experienceorb") < 122500 and not status.statPositive("ivrpgmasteryunlocked") then
    return
  end
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

function sendRadioMessage(text)
  player.radioMessage({
    messageId = "specUnlocks",
    unique = false,
    senderName = "SAIL",
    text = text
  })
end

function killedEnemy(enemyType, level, position, statusEffects, damage, damageType)
  addToChallengeCount(level)
  dyingEffects(position, statusEffects)
  killingEffects(level, position, statusEffects, damageType, enemyType)
  dropUpgradeChips(level, position, enemyType)
  specChecks(enemyType, level, position, statusEffects, damage, damageType)
end

function specChecks(enemyType, level, position, statusEffects, damage, damageType)
  if player.currency("experienceorb") < 122500 and not status.statPositive("ivrpgmasteryunlocked") then
    return
  end

  for _,spec in ipairs(self.specsAvailable) do
    if status.statusProperty(spec.unlockStatus) ~= true then
      local unlockBehavior = spec.unlockBehavior
      if unlockBehavior then
        local damageTypes = unlockBehavior.damageTypes
        local enemyTypes = unlockBehavior.enemyTypes
        local requiredPosition = unlockBehavior.requiredPosition
        local requiredCurrency = unlockBehavior.requiredCurrency
        local ignore = false
        local trueIgnore = false
        local healthBonus = 1
        
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

        if requiredPosition then
          ignore = true
          if requiredPosition.type == "<" and world.magnitude(position, world.entityPosition(self.id)) < requiredPosition.magnitude then
            ignore = false
          elseif requiredPosition.type == ">" and world.magnitude(position, world.entityPosition(self.id)) > requiredPosition.magnitude then
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

        if enemyTypes and not trueIgnore then
          for _,v in ipairs(enemyTypes) do
            if string.find(enemyType, v.type) then
              status.setStatusProperty(spec.unlockStatus, status.statusProperty(spec.unlockStatus, 0) + healthBonus * (v.modifier and level * v.modifier or (v.amount or level)))
              break
            end
          end
        end

      end
    end
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
        	self.id,
        	{0,0},
        	false,
        	{timeToLive = 0.25, power = status.stat("powerMultiplier")*50}
      )
    end
  end
end

function killingEffects(level, position, statusEffects, damageType, name)
	if status.statPositive("ivrpgucvampirescaress") and damageType == "bloodaether" then
		status.addEphemeralEffect("rage", 2, self.id)
		status.addEphemeralEffect("regeneration4", 2, self.id)
	end
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