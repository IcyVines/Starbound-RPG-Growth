function init()
  animator.setParticleEmitterOffsetRegion("feathers", mcontroller.boundBox())
  animator.setParticleEmitterActive("feathers", true)
  self.fallDamageMultiplier = config.getParameter("fallDamageMultiplier", 0)
  self.gravityMultiplier = config.getParameter("gravityMultiplier", 1)
  self.movementParams = mcontroller.baseParameters()
  effect.addStatModifierGroup({{stat = "fallDamageMultiplier", effectiveMultiplier = self.fallDamageMultiplier}})
end

function update(dt)
  local oldGravityMultiplier = self.movementParams.gravityMultiplier or 1
  local newGravityMultiplier = self.gravityMultiplier * oldGravityMultiplier
  mcontroller.controlParameters({
  	gravityMultiplier = newGravityMultiplier
  })
end