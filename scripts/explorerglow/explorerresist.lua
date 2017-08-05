function init()
  animator.setParticleEmitterOffsetRegion("sparkles", mcontroller.boundBox())
  animator.setParticleEmitterActive("sparkles", config.getParameter("particles", true))
  self.statID = effect.addStatModifierGroup({{stat = "physicalResistance", amount = .1}})
end

function update(dt)
  
end

function uninit()
  
end
