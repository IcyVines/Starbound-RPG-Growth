require "/scripts/keybinds.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.active = false
  _,self.damageGivenUpdate = status.inflictedDamageSince()
  self.id = entity.id()
  Bind.create("g", toggle)
end

function toggle()
  if not self.active and not status.resourceLocked("energy") then
    self.active = true
    animator.playSound("activate")
    status.addEphemeralEffect("ivrpgquasarcamouflage", math.huge)
  elseif self.active then
    animator.playSound("deactivate")
    reset()
    weaken()
  end
end

function weaken()
  status.setPersistentEffects("ivrpgquasarweaken", {
    {stat = "energyRegenPercentageRate", effectiveMultiplier = 0.5}
  })
end

function reset()
  self.active = false
  status.removeEphemeralEffect("ivrpgquasarcamouflage")
  status.clearPersistentEffects("ivrpgquasarweaken")
end

function uninit()
  reset()
end

function update(args)
  if not status.uniqueStatusEffectActive("ivrpgquasarcamouflage") then
    self.active = false
  end

  updateDamageGiven()

  if status.resource("energy") == status.resourceMax("energy") then
    status.clearPersistentEffects("ivrpgquasarweaken")
  end
end

function updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 and self.active then
        burst(notification.targetEntityId)
      end
    end
  end
end

function burst(entity)
  if not world.entityExists(entity) then return end
  local energy = status.resource("energy")
  status.overConsumeResource("energy", energy + 1)
  world.spawnProjectile("ivrpgquasarcollapse", world.entityPosition(entity), self.id, {0,0}, false, {power = energy, powerMultiplier = status.stat("powerMultiplier")})
  reset()
end

