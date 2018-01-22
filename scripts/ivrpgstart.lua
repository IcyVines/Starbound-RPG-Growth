local origInit = init
local origUpdate = update

function init()
  origInit()
  script.setUpdateDelta(9)
  self.removed = true
  self.xp = player.currency("experienceorb")
  
  local data = root.assetJson("/ivrpgversion.config")
  if status.statusProperty("ivrpgversion", "0") ~= data.version then
    status.setStatusProperty("ivrpgversion", data.version)
    removeTechs()
  end
  
  sb.logInfo("Chaika's RPG Growth: Version %s", data.version)

  message.setHandler("addXP", function(_, _, amount)
    addXP(amount)
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