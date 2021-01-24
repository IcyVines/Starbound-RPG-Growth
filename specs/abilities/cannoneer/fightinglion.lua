require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.powerTimer = 0
  self.powerTime = config.getParameter("powerTime", 5)
  self.power = config.getParameter("power", 1.0)
  self.energy = config.getParameter("energy", 0.1)
  self.damageGivenUpdate = 5
  self.correctWeapons = false
  self.movementParams = mcontroller.baseParameters()
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)

  checkWeaponCombo()
  updateDamageGiven()
  
  if self.powerTimer > 0 then
    status.setPersistentEffects("ivrpgfightinglion", {
      { stat = "powerMultiplier", baseMultiplier = self.power}
    })
    status.modifyResourcePercentage("energy", dt*self.energy)
    self.powerTimer = math.max(self.powerTimer-dt, 0)
    animator.setParticleEmitterActive("embers", true)
  else
    status.clearPersistentEffects("ivrpgfightinglion")
    animator.setParticleEmitterActive("embers", false)
  end

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 1 or world.entityCurrency(self.id, "classtype") ~= 5 then
    effect.expire()
  end
end

function reset()
  animator.setParticleEmitterActive("embers", false)
  status.clearPersistentEffects("ivrpgfightinglion")
  status.setPrimaryDirectives()
end

function uninit()
  reset()
end

function checkWeaponCombo()
  self.heldItem = world.entityHandItem(self.id, "primary")
  self.heldItem2 = world.entityHandItem(self.id, "alt")
  if self.heldItem and self.heldItem2 and ((root.itemHasTag(self.heldItem, "shortsword") and root.itemHasTag(self.heldItem2, "grenadelauncher")) or (root.itemHasTag(self.heldItem2, "shortsword") and root.itemHasTag(self.heldItem, "grenadelauncher"))) then
    self.correctWeapons = true
  else
    self.powerTimer = 0
    self.correctWeapons = false
  end
end

function updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      local id = notification.targetEntityId
      local entityHealth = world.entityHealth(id)
      if notification.healthLost > 0 and string.find(notification.damageSourceKind, "shortsword") then
        if self.correctWeapons then self.powerTimer = 2 end
      end
      --Explosions
      if entityHealth and notification.damageDealt > notification.healthLost and notification.healthLost > 0 then
        if self.powerTimer > 0 then
          world.spawnProjectile("poisonplasmaexplosion", world.entityPosition(notification.targetEntityId), self.id, {0,0}, false, {power = entityHealth[2]*0.125*status.stat("powerMultiplier")})
        end
      end
    end
  end
end