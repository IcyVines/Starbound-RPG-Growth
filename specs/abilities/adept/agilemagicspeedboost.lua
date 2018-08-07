require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", true)
end


function update(dt)
  mcontroller.controlModifiers({
    speedModifier = 1.2
  })
end

function uninit()

end
