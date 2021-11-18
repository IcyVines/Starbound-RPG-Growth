require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  _,self.damageUpdate = status.damageTakenSince()
  _,self.damageGivenUpdate = status.inflictedDamageSince()
  self.timer = 0
  self.healTime = config.getParameter("healTime", 5)
  self.healPercent = config.getParameter("healPercent", 0.1)
  self.damagedBy = {}
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
end


function update(dt)

  updateDamageTaken()
  updateDamageGiven()

  if self.timer > 0 then
    self.timer = math.max(0, self.timer - dt)
    animator.setParticleEmitterActive("healing", true)
    status.modifyResourcePercentage("health", dt * self.healPercent / self.healTime)
    status.modifyResourcePercentage("energy", dt * self.healPercent / self.healTime)
    if self.timer == 0 then
      animator.setParticleEmitterActive("healing", false)
    end
  end

  for id,_ in pairs(self.damagedBy) do
    if not world.entityExists(id) then
      self.damagedBy[id] = nil
    end
  end

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 6 or not (world.entityCurrency(self.id, "classtype") == 1 or world.entityCurrency(self.id, "classtype") == 6) then
    effect.expire()
  end
end

function reset()
  status.setPrimaryDirectives()
end

function uninit()
  animator.setParticleEmitterActive("healing", false)
  status.clearPersistentEffects("ivrpginquisition")
  reset()
end

function updateDamageTaken()
  local notifications = nil
  notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 then
        self.damagedBy[notification.sourceEntityId] = true
      end
    end
  end
end

function updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.damageDealt > notification.healthLost and notification.healthLost > 0 and not self.damagedBy[notification.targetEntityId] then
        if world.isNpc(notification.targetEntityId) or world.isMonster(notification.targetEntityId) then
          self.damagedBy[notification.targetEntityId] = nil
          self.timer = self.healTime
        end
      end
    end
  end
end