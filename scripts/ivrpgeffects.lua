local fuoldInit = init
local fuoldUpdate = update
local fuoldUninit = uninit

function init()
  fuoldInit()
  self.lastYPosition = 0
  self.lastYVelocity = 0
  self.fallDistance = 0
  --script.setUpdateDelta(10)
  local bounds = mcontroller.boundBox() --Mcontroller for movement
end

function update(dt)
  fuoldUpdate(dt)
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
  status.addEphemeralEffect("ivrpgstatboosts", math.huge)
end

function addXP(amount)
  sb.logInfo(amount)
end