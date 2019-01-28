function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterActive("healing", config.getParameter("particles", true))

  script.setUpdateDelta(5)
  animator.playSound("heal")

  self.healingRate = 1.0 / config.getParameter("healTime", 60)
  self.bonusEffects = config.getParameter("bonusEffects", false)
  if self.bonusEffects then
    effect.addStatModifierGroup(self.bonusEffects)
  end
end

function update(dt)
  status.modifyResourcePercentage("health", self.healingRate * dt)
end

function uninit()
  
end
