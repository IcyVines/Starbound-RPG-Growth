require "/scripts/ivrpgutil.lua"
local origInit = init
local origUpdate = update
local origUninit = uninit

function init()
  origInit()
  script.setUpdateDelta(14)
  self.removed = true
  self.xp = player.currency("experienceorb")
  self.id = entity.id()
  self.class = player.currency("classtype")
  self.spec = player.currency("spectype")
  self.specList = root.assetJson("/specList.config")
  
  local data = root.assetJson("/ivrpgversion.config")
  local oldVersion = status.statusProperty("ivrpgversion", "0")
  if oldVersion ~= data.version then
    status.setStatusProperty("ivrpgversion", data.version)
    if oldVersion ~= "1.4e" then
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

function update(args)
  origUpdate(args)

  updateXPPulse()

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
  end

  updateUpgrades()
  updateSpecs()
  unlockSpecs()

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
    local new = player.currency("experienceorb") - self.xp
    if new > 0 then
      local players = world.playerQuery(entity.position(), 60, {
        withoutEntityId = entity.id()
      })
      for k,id in pairs(players) do
        world.sendEntityMessage(id, "addXP", new)
      end
    end
  end
  self.xp = player.currency("experienceorb")
end

function addXP(new)
  player.giveItem({"experienceorb", new})
  self.xp = player.currency("experienceorb")
end

function updateUpgrades()

end

function updateSpecs()
  if player.currency("experienceorb") < 122500 and not status.statPositive("ivrpgmasteryunlocked") then
    return
  end
end

function unlockSpecs()
  if type(status.statusProperty("ivrpgsucrusader")) == "number" and status.statusProperty("ivrpgsucrusader") >= 1000 then
    sendRadioMessage("Crusader Unlocked!")
    status.setStatusProperty("ivrpgsucrusader", true)
  end

  if type(status.statusProperty("ivrpgsunecromancer")) == "number" and status.statusProperty("ivrpgsunecromancer") >= 1000 then
    sendRadioMessage("Necromancer Unlocked!")
    status.setStatusProperty("ivrpgsunecromancer", true)
  end

  if type(status.statusProperty("ivrpgsuvanguard")) == "number" and status.statusProperty("ivrpgsuvanguard") >= 500 then
    sendRadioMessage("Vanguard Unlocked!")
    status.setStatusProperty("ivrpgsuvanguard", true)
  end

  if type(status.statusProperty("ivrpgsuwraith")) == "number" and status.statusProperty("ivrpgsuwraith") >= 1000 then
    sendRadioMessage("Wraith Unlocked!")
    status.setStatusProperty("ivrpgsuwraith", true)
  end

  if type(status.statusProperty("ivrpgsuvigilante")) == "number" and status.statusProperty("ivrpgsuvigilante") >= 100 then
    sendRadioMessage("Vigilante Unlocked!")
    status.setStatusProperty("ivrpgsuvigilante", true)
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
  -- Crusader
  if status.statusProperty("ivrpgsucrusader") ~= true and (self.class == 1 or self.class == 2) and string.find(damageType, "broadsword") then
    if enemyType == "cultist" or enemyType == "templeguard" or enemyType == "tombguard" then
      status.setStatusProperty("ivrpgsucrusader", status.statusProperty("ivrpgsucrusader", 0) + 4 * level)
    elseif string.find(enemyType, "tentacle") then
      status.setStatusProperty("ivrpgsucrusader", status.statusProperty("ivrpgsucrusader", 0) + level)
    else
      status.setStatusProperty("ivrpgsucrusader", status.statusProperty("ivrpgsucrusader", 0) + level / 4)
    end
  end

  -- Necromancer
  if status.statusProperty("ivrpgsunecromancer") ~= true and self.class == 2 then
    if status.resource("health") / status.stat("maxHealth") < 0.2 then
      status.setStatusProperty("ivrpgsunecromancer", status.statusProperty("ivrpgsunecromancer", 0) + level)
    end
  end

  -- Vanguard
  if status.statusProperty("ivrpgsuvanguard") ~= true and (self.class == 4 or self.class == 6) then
    if string.find(damageType, "bullet") or string.find(damageType, "shotgun") then
      if world.magnitude(position, world.entityPosition(self.id)) < 5 then
        status.setStatusProperty("ivrpgsuvanguard", status.statusProperty("ivrpgsuvanguard", 0) + level)
      end
    end
  end

  --Wraith
  if status.statusProperty("ivrpgsuwraith") ~= true and (self.class == 2 or self.class == 5) then
    if player.currency("intelligencepoint") > 40 then
      if hasElement({"skimbus", "spookit", "gosmet", "wisper", "squeem"}, enemyType) then
        status.setStatusProperty("ivrpgsuwraith", status.statusProperty("ivrpgsuwraith", 0) + level)
      elseif string.find(enemyType, "tentacleghost") then
        status.setStatusProperty("ivrpgsuwraith", status.statusProperty("ivrpgsuwraith", 0) + 1)
      elseif string.find(enemyType, "erchiusghost") then
        status.setStatusProperty("ivrpgsuwraith", status.statusProperty("ivrpgsuwraith", 0) + 10)
      end
    end
  end

  --Paladin
  --Completed in Knight Ability Lua

  --Vigilante
  if status.statusProperty("ivrpgsuvigilante") ~= true and self.class == 4 then
    if string.find(damageType, "bullet") or string.find(damageType, "shotgun") then
      if string.find(enemyType, "bandit") or string.find(enemyType, "outlaw") then
        status.setStatusProperty("ivrpgsuvigilante", status.statusProperty("ivrpgsuvigilante", 0) + level)
      end
    end
  end

  --Adept
  --Completed in Ninja Ability Lua


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

  -- Vigilante
  if self.spec == 3 and self.class == 4 then
    if string.find(name, "bandit") or string.find(name, "outlaw") then
      local allyIds = world.entityQuery(world.entityPosition(self.id), 8, {includedTypes = {"creature"}})
      for _,id in ipairs(allyIds) do
        if world.entityDamageTeam(id).type == "friendly" then
          world.sendEntityMessage(id, "modifyResourcePercentage", "energy", 0.1)
        end
      end
    end
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