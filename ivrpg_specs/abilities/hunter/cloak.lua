require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.cloakTimer = 0
  self.crouchTimer = 0
  _,self.damageGivenUpdate = status.inflictedDamageSince()
  self.energy = status.resource("energy")
  self.cloakTime = config.getParameter("cloakTime", 5)
  self.crouchTime = config.getParameter("crouchTime", 2)
  self.bleedTime = config.getParameter("bleedTime", 0.5)
  self.bleedChance = config.getParameter("bleedChance", 0.33)
  self.bleedTimer = 0
end


function update(dt)

  updateDamageGiven()

  if mcontroller.crouching() and self.cloakTimer == 0 then
    self.crouchTimer = self.crouchTimer + dt
    if self.crouchTimer >= self.crouchTime then
      self.cloakTimer = self.cloakTime
      self.crouchTimer = 0
      animator.playSound("cloak")
      status.addEphemeralEffect("ivrpgcamouflagehunter", 5)
    end
  else
    self.crouchTimer = 0
  end

  if self.cloakTimer > 0 then
    if status.resource("energy") < self.energy then
      bleedChance()
    end
    self.cloakTimer = math.max(self.cloakTimer - dt, 0)
  end

  if self.bleedTimer == 0 then
    status.clearPersistentEffects("ivrpgcloak")
  end

  self.bleedTimer = math.max(self.bleedTimer - dt, 0)
  self.energy = status.resource("energy")

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 4 or world.entityCurrency(self.id, "classtype") ~= 5 then
    effect.expire()
  end
end

function updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.damageDealt > 0 and self.cloakTimer > 0 then
        bleedChance()
      end
    end
  end
end

function bleedChance()
  status.removeEphemeralEffect("ivrpgcamouflagehunter")
  self.bleedTimer = self.bleedTime
  status.addPersistentEffects("ivrpgcloak", {{stat = "ivrpgBleedChance", amount = self.bleedChance}})
  self.cloakTimer = 0
end

function reset()
  status.setPrimaryDirectives()
  status.clearPersistentEffects("ivrpgcloak")
end

function uninit()
  reset()
end
