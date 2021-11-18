require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  _,self.damageUpdate = status.damageTakenSince()
  self.resistanceTimer = 0
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)
  self.notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  if self.notifications then
    for _,notification in pairs(self.notifications) do
      if notification.hitType == "ShieldHit" then
        if status.resourcePositive("perfectBlock") then
          status.modifyResource("shieldStamina", 0.1)
          animator.setParticleEmitterActive("embers", true)
          self.resistanceTimer = 5
        end
      end
    end
  end

  if self.resistanceTimer > 0 then
    status.setPersistentEffects("ivrpgperfectbarrer", {
      {stat = "physicalResistance", amount = 0.2},
      {stat = "poisonResistance", amount = 0.2},
      {stat = "shadowResistance", amount = 0.2},
      {stat = "demonicResistance", amount = 0.2},
    })
    animator.setParticleEmitterActive("embers", true)
    self.resistanceTimer = math.max(self.resistanceTimer - dt, 0)
    if self.resistanceTimer == 0 then
      status.clearPersistentEffects("ivrpgperfectbarrer")
      animator.setParticleEmitterActive("embers", false)
    end
  end

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 1 or world.entityCurrency(self.id, "classtype") ~= 1 then
    effect.expire()
  end

end

function uninit()
  status.clearPersistentEffects("ivrpgperfectbarrer")
end
