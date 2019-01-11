require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.damageUpdate = 5
  self.damageGivenUpdate = 5
  self.speedTimer = 0
  self.powerTimer = 0
  self.speedDrop = 1
  self.powerUp = 0
  self.speedTime = config.getParameter("speedTime")
  self.powerTime = config.getParameter("powerTime")
  self.powerTimeMax = self.powerTime * 2
  animator.setParticleEmitterOffsetRegion("speedEmbers", mcontroller.boundBox())
  animator.setParticleEmitterOffsetRegion("powerEmbers", mcontroller.boundBox())
end


function update(dt)

  updateDamageTaken()
  updateDamageGiven()

  if self.speedTimer > 0 then
    self.speedTimer = math.max(0, self.speedTimer - dt)
    animator.setParticleEmitterActive("speedEmbers", true)
    animator.setParticleEmitterEmissionRate("speedEmbers", 1 / self.speedDrop * 20)
    mcontroller.controlModifiers({
      speedModifier = self.speedDrop
    })
    if self.speedTimer == 0 then
      animator.setParticleEmitterActive("speedEmbers", false)
      self.speedDrop = 1
    end
  end

  if self.powerTimer > 0 then
    self.powerTimer = math.max(0, self.powerTimer - dt)
    animator.setParticleEmitterActive("powerEmbers", true)
    animator.setParticleEmitterEmissionRate("powerEmbers", self.powerUp * self.powerTimer / 5 * 20)
    status.setPersistentEffects("ivrpgpurity", {
      {stat = "powerMultiplier", baseMultiplier = 1 + math.min((self.powerUp * self.powerTimer / 5), 1)},
      {stat = "protection", amount = math.min((self.powerUp * 10 * self.powerTimer), 25)}
    })
    if self.powerTimer == 0 then
      animator.setParticleEmitterActive("powerEmbers", false)
      self.powerUp = 0
    end
  end

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 5 or not (world.entityCurrency(self.id, "classtype") == 1 or world.entityCurrency(self.id, "classtype") == 2) then
    effect.expire()
  end
end

function reset()
  status.setPrimaryDirectives()
end

function uninit()
  animator.setParticleEmitterActive("speedEmbers", false)
  animator.setParticleEmitterActive("powerEmbers", false)
  status.clearPersistentEffects("ivrpgpurity")
  reset()
end

function updateDamageTaken()
  local notifications = nil
  notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 then
        if notification.damageSourceKind == "slash" or notification.damageSourceKind == "lash" then
          self.speedTimer = self.speedTime
          self.speedDrop = math.max(self.speedDrop - 0.05, 0.6)
        end
      end
    end
  end
end

function updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if world.entityHealth(notification.targetEntityId) and notification.healthLost >= world.entityHealth(notification.targetEntityId)[1] then
        self.powerTimer = math.min((self.powerTimer + self.powerTime), self.powerTimeMax)
        self.powerUp = math.min(self.powerUp + 0.1, 2)
      elseif notification.healthLost > 0 and self.powerTimer > 0 then
        world.sendEntityMessage(notification.targetEntityId, "addEphemeralEffect", "ivrpgjudgement", 2, self.id)
      end
    end
  end
end