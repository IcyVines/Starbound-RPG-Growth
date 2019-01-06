require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.regenTimer = 0
  self.regenTime = config.getParameter("regenTime", 5)
  self.movementParams = mcontroller.baseParameters()
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 4 or world.entityCurrency(self.id, "classtype") ~= 1 then
    effect.expire()
  end
end

function reset()
  animator.setParticleEmitterActive("embers", false)
  status.setPrimaryDirectives()
end

function uninit()
  reset()
end
