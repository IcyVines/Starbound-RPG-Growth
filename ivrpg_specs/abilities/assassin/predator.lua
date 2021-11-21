require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.id = effect.sourceEntity()
  _,self.damageUpdate = status.damageTakenSince()
  self.uninvisTime = 10
  self.uninvisTimer = 0
  self.entityDamaged = nil

  message.setHandler("ivrpgPredator", function(_, _, damage, position, facingDirection, entityId)
    if self.uninvisTimer == 0 and damage > 0 then
      self.uninvisTimer = self.uninvisTime
      self.entityDamaged = entityId
    end
  end)
end


function update(dt)

  updateDamageTaken()

  if self.uninvisTimer == 0 then
    status.setPersistentEffects("ivrpg_predator", {
      {stat = "ivrpgstealth", amount = 1},
      {stat = "invulnerable", amount = 1}
    })
    effect.setParentDirectives("?multiply=555555BB")
  else
    if self.entityDamaged and not world.entityExists(self.entityDamaged) then
      self.entityDamaged = nil
      self.uninvisTimer = 0
    end
    status.clearPersistentEffects("ivrpg_predator")
    effect.setParentDirectives()
  end

  self.uninvisTimer = math.max(self.uninvisTimer - dt, 0)

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 1 or world.entityCurrency(self.id, "classtype") ~= 3 then
    effect.expire()
  end

end

function updateDamageTaken()
  local notifications = nil
  notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 then
        self.uninvisTimer = self.uninvisTime
      end
    end
  end
end

function uninit()
  status.clearPersistentEffects("ivrpg_predator")
  effect.setParentDirectives()
end
