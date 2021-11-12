require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.id = effect.sourceEntity()
  animator.setParticleEmitterOffsetRegion("rageEmbers", mcontroller.boundBox())
  animator.setParticleEmitterOffsetRegion("unrageEmbers", mcontroller.boundBox())
end


function update(dt)
  self.nearbyAggressive = 0
  local targetIds = enemyQuery(mcontroller.position(), 15, {}, self.id)
  self.nearbyAggressive = #targetIds / 2
  status.setPersistentEffects("battlemagebattletendency", {
    {stat = "powerMultiplier", baseMultiplier = math.min(0.5 + self.nearbyAggressive, 3)}
  })

  animator.setParticleEmitterActive("rageEmbers", self.nearbyAggressive > 0)
  animator.setParticleEmitterActive("unrageEmbers", self.nearbyAggressive == 0)

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 1 or world.entityCurrency(self.id, "classtype") ~= 3 then
    effect.expire()
  end

end

function uninit()
  status.clearPersistentEffects("battlemagebattletendency")
end
