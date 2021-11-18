require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.id = effect.sourceEntity()
  _,self.damageGivenUpdate = status.inflictedDamageSince()
  self.killTime = 5
  self.killTimer = 0
  self.killTimeMax = 30
  animator.setParticleEmitterOffsetRegion("rageEmbers", mcontroller.boundBox())
end


function update(dt)

  updateDamageGiven()

  status.setPersistentEffects("ivrpg_berserkersrage", {
    {stat = "powerMultiplier", baseMultiplier = math.min(1 + self.killTimer / 15, 3)},
    {stat = "physicalResistance", amount = math.min(self.killTimer / 100, 0.5)},
    {stat = "maxEnergy", effectiveMultiplier = math.max(1 - (self.killTimer / 60), 0.5)}
  })

  animator.setParticleEmitterActive("rageEmbers", self.killTimer > 0)
  animator.setParticleEmitterEmissionRate("rageEmbers", self.killTimer)
  self.killTimer = math.max(self.killTimer - dt, 0)

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 7 or not (world.entityCurrency(self.id, "classtype") == 1 or world.entityCurrency(self.id, "classtype") == 5) then
    effect.expire()
  end

end

function uninit()
  status.clearPersistentEffects("ivrpg_berserkersrage")
end


function updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.damageDealt > notification.healthLost and notification.healthLost > 0 then
        self.killTimer = math.min((self.killTimer + self.killTime), self.killTimeMax)
      end
    end
  end
end