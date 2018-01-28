local origInit = init
local origUpdate = update

function init()
  origInit()
  script.setUpdateDelta(9)
  self.removed = true
  self.xp = player.currency("experienceorb")
  self.id = entity.id()
  
  local data = root.assetJson("/ivrpgversion.config")
  if status.statusProperty("ivrpgversion", "0") ~= data.version then
    status.setStatusProperty("ivrpgversion", data.version)
    removeTechs()
  end
  
  sb.logInfo("Chaika's RPG Growth: Version %s", data.version)

  message.setHandler("addXP", function(_, _, amount)
    addXP(amount)
  end)

  message.setHandler("hasStat", function(_, _, name)
  	sb.logInfo(name)
  	if status.statPositive(name) then sb.logInfo("True") end
    return status.statPositive(name)
  end)

  message.setHandler("feedbackLoop", function(_, _)
  	if status.statPositive("ivrpgucfeedbackloop") then status.addEphemeralEffect("rage", 2) end
  end)

  message.setHandler("killedMonster", function(_, _, level, position, statusEffects)
  	killedMonster(level, position, statusEffects)
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

  updateUpgrades()

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

function killedMonster(level, position, statusEffects)
  addToChallengeCount(level)
  dyingEffects(position, statusEffects)
end

function addToChallengeCount(level)
  local challenge1 = status.stat("ivrpgchallenge1")
  local challenge2 = status.stat("ivrpgchallenge2")
  local challenge3 = status.stat("ivrpgchallenge3")

	if challenge1 == 1 and level >= 4 then
		status.addPersistentEffect("ivrpgchallenge1progress", {stat = "ivrpgchallenge1progress", amount = 1})
	elseif challenge1 == 2 and level >= 5 then
		status.addPersistentEffect("ivrpgchallenge1progress", {stat = "ivrpgchallenge1progress", amount = 1})
	end

	if challenge2 == 1 and level >= 6 then
		status.addPersistentEffect("ivrpgchallenge2progress", {stat = "ivrpgchallenge2progress", amount = 1})
	end

	if challenge3 == 1 and level >= 7 then
		status.addPersistentEffect("ivrpgchallenge3progress", {stat = "ivrpgchallenge3progress", amount = 1})
	end
end

function dyingEffects(position, statusEffects)
  if status.statPositive("ivrpgucbloom") then
    if hasEphemeralStat(statusEffects, "ivrpgsear") or hasEphemeralStat(statusEffects, "burning") then
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