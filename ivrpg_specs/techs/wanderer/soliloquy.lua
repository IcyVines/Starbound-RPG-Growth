require "/scripts/keybinds.lua"

function init()
  self.active = status.statusProperty("ivrpgsoliloquy", false)
  _,self.damageUpdate = status.damageTakenSince()
  _,self.damageGivenUpdate = status.inflictedDamageSince()
  Bind.create("f", toggle)
end

function toggle()
  if not self.active then
    self.active = 0
    status.setStatusProperty("ivrpgsoliloquy", 0)
    animator.playSound("activate")
  end
end

function uninit()
  tech.setParentDirectives()
  status.removeEphemeralEffect("ivrpgsoliloquystatus")
  status.clearPersistentEffects("ivrpgsoliloquy")
end

function update(args)
  
  updateDamageGiven()
  updateDamageTaken()

  if self.active then
    status.addEphemeralEffect("ivrpgsoliloquystatus", 10)
    status.setPersistentEffects("ivrpgsoliloquy", {
      {stat = "powerMultiplier", amount = self.active * 0.1},
      {stat = "ivrpgBleedChance", amount = self.active * 0.01},
      {stat = "physicalResistance", amount = -0.05 * self.active},
      {stat = "iceResistance", amount = -0.05 * self.active},
      {stat = "electricResistance", amount = -0.05 * self.active},
      {stat = "fireResistance", amount = -0.05 * self.active},
      {stat = "poisonResistance", amount = -0.05 * self.active},
      {stat = "shadowResistance", amount = -0.05 * self.active},
      {stat = "radioactiveResistance", amount = -0.05 * self.active},
      {stat = "demonicResistance", amount = -0.05 * self.active},
      {stat = "holyResistance", amount = -0.05 * self.active},
      {stat = "novaResistance", amount = -0.05 * self.active},
      {stat = "cosmicResistance", amount = -0.05 * self.active}
    })
  else
    status.clearPersistentEffects("ivrpgsoliloquy")
    status.removeEphemeralEffect("ivrpgsoliloquystatus")
  end

end

function updateDamageTaken()
  local notifications = nil
  notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 then
        if self.active then
          animator.playSound("deactivate")
          self.active = false
          status.setStatusProperty("ivrpgsoliloquy", false)
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
      if notification.damageDealt > notification.healthLost and notification.healthLost > 0 then
        if self.active then
          self.active = self.active + 1
          status.setStatusProperty("ivrpgsoliloquy", self.active)
        end
      end
    end
  end
end