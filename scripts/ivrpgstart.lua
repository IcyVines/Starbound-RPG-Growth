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

end

function update(args)
  origUpdate(args)

  if status.statPositive("ivrpgmultiplayerxp") then
    if self.removed then
      player.giveItem({ "experienceorb", status.stat("ivrpgmultiplayerxp")})
      self.removed = false
    end
  elseif not self.removed then
    self.removed = true
  end

  --admin
  if player.isAdmin() then
    if not status.statPositive("admin") then status.addPersistentEffect("ivrpgadmin", {stat = "admin", amount = 1}) end
  else
    status.clearPersistentEffects("ivrpgadmin")
  end


end

function removeTechs()
    --These Techs are deprecated, so should be removed!
    player.makeTechUnavailable("roguecloudjump")
    player.makeTechUnavailable("roguetoxiccapsule")
    player.makeTechUnavailable("roguepoisondash")
    player.makeTechUnavailable("soldiermissilestrike")
    player.makeTechUnavailable("explorerdrill")
end