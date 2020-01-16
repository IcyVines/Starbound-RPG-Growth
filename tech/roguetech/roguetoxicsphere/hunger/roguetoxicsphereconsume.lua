function init()
  self.energyGain = config.getParameter("energyGain")
  self.healthGain = config.getParameter("healthGain")
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterOffsetRegion("energy", mcontroller.boundBox())
end

function update(dt)
  self.healthFull = (status.resourceMax("health") == status.resource("health"))
  self.energyFull = (status.resourceMax("energy") == status.resource("energy"))

  if not self.healthFull then
    animator.setParticleEmitterActive("healing", true)
    status.modifyResourcePercentage("health", self.healthGain/100 * dt)
  else
    animator.setParticleEmitterActive("healing", false)
  end

  if not self.energyFull then
    animator.setParticleEmitterActive("energy", true)
    status.setResourceLocked("energy", false)
    status.modifyResourcePercentage("energy", self.energyGain/100 * dt)
  else
    animator.setParticleEmitterActive("energy", false)
  end
end

function uninit()

end
