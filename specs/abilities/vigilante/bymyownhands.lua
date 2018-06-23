require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.damageUpdate = 5
  self.timer = 0
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)
  self.nearbyAggressiveNpcs = 0
  local npcIds = world.npcQuery(mcontroller.position(), 15)
  for _,id in ipairs(npcIds) do
    if world.entityAggressive(id) then
      self.nearbyAggressiveNpcs = self.nearbyAggressiveNpcs + 0.25
    end
  end

  status.setPersistentEffects("vigilantebymyownhands", {
    {stat = "powerMultiplier", baseMultiplier = math.min(1 + self.nearbyAggressiveNpcs, 2.5)}
  })
  mcontroller.controlModifiers({
    speedModifier = math.min(1 + self.nearbyAggressiveNpcs, 2.5)
  })

  if self.nearbyAggressiveNpcs > 1 then
    animator.setParticleEmitterActive("embers", true)
  else
    animator.setParticleEmitterActive("embers", false)
  end

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 3 or world.entityCurrency(self.id, "classtype") ~= 4 then
    effect.expire()
  end

end

function uninit()
  status.clearPersistentEffects("vigilantebymyownhands")
end
