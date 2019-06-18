function init()
  self.id = effect.sourceEntity()
  self.maxDuration = config.getParameter("maxDuration", 30)
end


function update(dt)
  local duration = effect.duration()
  if duration > self.maxDuration then
    effect.modifyDuration(self.maxDuration - duration)
    duration = self.maxDuration
  end
  mcontroller.controlModifiers({
    speedModifier = 1 + 0.01 * duration
  })
  status.setPersistentEffects("ivrpgpoptoppower", {
    { stat = "powerMultiplier", baseMultiplier = 1 + 0.033 * duration}
  })
end

function reset()
  status.clearPersistentEffects("ivrpgpoptoppower")
end

function uninit()
  reset()
end