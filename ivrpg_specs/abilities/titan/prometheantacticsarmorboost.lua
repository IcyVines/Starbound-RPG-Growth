require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.armor = config.getParameter("armor", 5)
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", true)
  effect.addStatModifierGroup({
    {stat = "protection", amount = self.armor}
  })
end


function update(dt)
end

function uninit()
  animator.setParticleEmitterActive("embers", false)
end
