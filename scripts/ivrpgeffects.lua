local ivrpgoldInit = init
local ivrpgoldUpdate = update

function init()
  ivrpgoldInit()
end

function update(dt)
  ivrpgoldUpdate(dt)

  --Deprecated, was used with the Remove Tech for safe mod uninstall
  if status.statPositive("ivrpgremove") then
  	status.removeEphemeralEffect("ivrpgstatboosts")
  	status.clearPersistentEffects("ivrpgstatboosts")
    status.clearPersistentEffects("ivrpgclassboosts")
    status.removeEphemeralEffect("explorerglow")
    status.removeEphemeralEffect("knightblock")
    status.removeEphemeralEffect("ninjacrit")
    status.removeEphemeralEffect("wizardaffinity")
    status.removeEphemeralEffect("roguepoison")
    status.removeEphemeralEffect("soldierdiscipline")
  	script.setUpdateDelta(0)
  	return
  end

  status.addEphemeralEffect("ivrpganimation", math.huge)
  status.addEphemeralEffect("ivrpgstatboosts", math.huge)
end