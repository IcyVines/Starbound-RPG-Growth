require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  animator.setParticleEmitterOffsetRegion("upEmbers", mcontroller.boundBox())
  animator.setParticleEmitterOffsetRegion("downEmbers", mcontroller.boundBox())
end


function update(dt)
  self.nearAggressiveEntities = 0.5
  local targetIds = world.entityQuery(mcontroller.position(), 10)
  for _,id in ipairs(targetIds) do
    if world.entityAggressive(id) or (world.entityDamageTeam(id).type == "pvp" and world.canDamage(self.id, id)) then
      self.nearAggressiveEntities = 1.5
      break
    end
  end

  status.setPersistentEffects("ivrpginthefray", {
    {stat = "maxEnergy", effectiveMultiplier = self.nearAggressiveEntities * 0.8},
    {stat = "physicalResistance", amount = (self.nearAggressiveEntities - 0.5) / 4},
    {stat = "powerMultiplier", baseMultiplier = (self.nearAggressiveEntities + 0.5) / 2}
  })
  mcontroller.controlModifiers({
    speedModifier = (self.nearAggressiveEntities / 5) + 0.9
  })

  if self.nearAggressiveEntities == 1.5 then
    animator.setParticleEmitterActive("upEmbers", true)
    animator.setParticleEmitterActive("downEmbers", false)
  else
    animator.setParticleEmitterActive("upEmbers", false)
    animator.setParticleEmitterActive("downEmbers", true)
  end

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 4 or (world.entityCurrency(self.id, "classtype") ~= 4 and world.entityCurrency(self.id, "classtype") ~= 6) then
    effect.expire()
  end

end

function uninit()
  status.clearPersistentEffects("ivrpginthefray")
end
