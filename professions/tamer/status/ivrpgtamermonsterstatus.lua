function init()
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", config.getParameter("particles", true))
  script.setUpdateDelta(5)
end

function update(dt)
  local duration = effect.duration() or 2
  local multiplier = duration <= 2 and 1.2 or duration - 0.8
  status.setPersistentEffects("ivrpgtamerstatus", {
    {stat = "powerMultiplier", effectiveMultiplier = multiplier},
    {stat = "protection", amount = 20*multiplier}
  })
  mcontroller.controlModifiers({
    speedModifier = multiplier
  })
end

function uninit()
  status.clearPersistentEffects("ivrpgtamerstatus")
end
