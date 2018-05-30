require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.damageUpdate = 5
  self.timer = 0
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)
  self.notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  if self.notifications then
    for _,notification in pairs(self.notifications) do
      if notification.hitType == "ShieldHit" then
        if status.resourcePositive("perfectBlock") then
          status.modifyResource("shieldStamina", 0.05)
          animator.setParticleEmitterActive("embers", true)
          self.timer = 0.5
        end
      end
    end
  end

  if self.timer > 0 then
    self.timer = math.max(self.timer - dt, 0)
    if self.timer == 0 then
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

end
