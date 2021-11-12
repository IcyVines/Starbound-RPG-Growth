function init()
  self.id = effect.sourceEntity()
  self.maxDuration = config.getParameter("maxDuration", 30)
  self.highestDuration = 0
end


function update(dt)
  local duration = effect.duration()
  self.highestDuration = math.min(duration > self.highestDuration and duration or self.highestDuration, 30)
  if duration > self.maxDuration then
    effect.modifyDuration(self.maxDuration - duration)
    duration = self.maxDuration
  end
  mcontroller.controlModifiers({
    speedModifier = 1.2 + 0.01 * self.highestDuration
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