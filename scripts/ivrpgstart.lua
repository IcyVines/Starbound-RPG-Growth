local origInit = init

function init()
  origInit()
  
  local data = root.assetJson("/ivrpgversion.config")
  if status.statusProperty("ivrpgversion", "0") ~= data.version then
    status.setStatusProperty("ivrpgversion", data.version)
    removeTechs()
  end

  if not player.hasQuest("oneforall") or player.hasCompletedQuest("oneforall") then
    player.startQuest("oneforall")
  end
  
  sb.logInfo("Chaika's RPG Growth: Version %s", data.version)
end

function removeTechs()
    --These Techs are deprecated, so should be removed!
    player.makeTechUnavailable("roguecloudjump")
    player.makeTechUnavailable("roguetoxiccapsule")
    player.makeTechUnavailable("roguepoisondash")
    player.makeTechUnavailable("soldierenergypack")
    player.makeTechUnavailable("explorerdrill")
end