require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)
  self.nearbyAggressiveNpcs = 0
  self.nearbyAllies = 0
  local entityIds = world.entityQuery(mcontroller.position(), 15, {withoutEntityId = self.id}, true)
  for _,id in ipairs(entityIds) do
    if world.entityDamageTeam(id).type == "friendly" or (world.entityDamageTeam(id).type == "pvp" and not world.entityCanDamage(a4, id)) then
      self.nearbyAllies = 1
    elseif world.entityDamageTeam(id).type == "enemy" and world.isNpc(id) and world.entityAggressive(id) then
      self.nearbyAggressiveNpcs = 1
    elseif world.entityDamageTeam(id).type == "pvp" and world.entityCanDamage(a4, id) then
      self.nearbyAggressiveNpcs = 1
    end
  end

  status.setPersistentEffects("wandererthestranger", {
    {stat = "powerMultiplier", amount = 2 + self.nearbyAggressiveNpcs - self.nearbyAllies},
    {stat = "physicalResistance", amount = 0.2 - (self.nearbyAllies / 5)},
    {stat = "iceResistance", amount = 0.2 - (self.nearbyAllies / 5)},
    {stat = "electricResistance", amount = 0.2 - (self.nearbyAllies / 5)},
    {stat = "fireResistance", amount = 0.2 - (self.nearbyAllies / 5)},
    {stat = "poisonResistance", amount = 0.2 - (self.nearbyAllies / 5)},
    {stat = "shadowResistance", amount = 0.2 - (self.nearbyAllies / 5)},
    {stat = "radioactiveResistance", amount = 0.2 - (self.nearbyAllies / 5)},
    {stat = "demonicResistance", amount = 0.2 - (self.nearbyAllies / 5)},
    {stat = "holyResistance", amount = 0.2 - (self.nearbyAllies / 5)},
    {stat = "novaResistance", amount = 0.2 - (self.nearbyAllies / 5)},
    {stat = "cosmicResistance", amount = 0.2 - (self.nearbyAllies / 5)}
  })

  if self.nearbyAggressiveNpcs >= 1 then
    animator.setParticleEmitterActive("embers", true)
  else
    animator.setParticleEmitterActive("embers", false)
  end

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 7 or (world.entityCurrency(self.id, "classtype") ~= 3 and world.entityCurrency(self.id, "classtype") ~= 6) then
    effect.expire()
  end

end

function uninit()
  status.clearPersistentEffects("wandererthestranger")
end
