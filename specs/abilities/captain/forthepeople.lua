require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.power = config.getParameter("power", 1.25)
  self.armor = config.getParameter("armor", 15)
  animator.setParticleEmitterOffsetRegion("posEmbers", mcontroller.boundBox())
  animator.setParticleEmitterActive("posEmbers", true)
  effect.addStatModifierGroup({
    { stat = "powerMultiplier", effectiveMultiplier = self.power },
    { stat = "protection", amount = self.armor }
  })
end


function update(dt)
  
end

function reset()
  animator.setParticleEmitterActive("posEmbers", false)
  status.setPrimaryDirectives()
end

function uninit()
  reset()
end