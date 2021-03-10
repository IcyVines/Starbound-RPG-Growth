function init()
  --Power
  self.damageModifier = config.getParameter("powerModifier")
  self.damageBonusId = effect.addStatModifierGroup({})
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  self.active = false
  self.damageGivenUpdate = 5
  self.damageUpdate = 5
  self.perfectTimer = 0
  self.id = entity.id()

  self.rpg_levelRequirements = root.assetJson("/ivrpgLevelRequirements.config")
  self.rpg_specUnlockXp = self.rpg_levelRequirements.specialization ^ 2 * 100
end


function update(dt)
  self.energy = status.resource("energy")
  self.maxEnergy = status.stat("maxEnergy")
  if self.energy == self.maxEnergy and not self.active then
    effect.setStatModifierGroup(self.damageBonusId, {
      {stat = "powerMultiplier", effectiveMultiplier = self.damageModifier}
    })
    animator.setParticleEmitterActive("embers", true)
    self.active = true
  elseif self.energy < self.maxEnergy*3/4 and self.active then
    effect.setStatModifierGroup(self.damageBonusId, {})
    animator.setParticleEmitterActive("embers", false)
    self.active = false
  end

  checkPerfectShield(dt)
  updateDamageGiven(dt)

  if not status.statPositive("ivrpgclassability") then
    effect.setParentDirectives("border=1;d8a23c20;d8a23c00")
  else
    effect.setParentDirectives()
  end

  if world.entityCurrency(effect.sourceEntity(), "classtype") ~= 4 then
    effect.expire()
  end
end

function updateDamageGiven(dt)
  if type(status.statusProperty("ivrpgsutitan", 0)) == "boolean" and status.statusProperty("ivrpgsutitan") then return end
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if self.perfectTimer > 0 and notifications then
    for _,notification in ipairs(notifications) do
      --Titan
      if (world.entityCurrency(self.id, "experienceorb") >= self.rpg_specUnlockXp or status.statPositive("ivrpgmasteryunlocked")) and (string.find(notification.damageSourceKind, "bullet") or string.find(notification.damageSourceKind, "shotgun")) then
        if notification.healthLost > 0 and world.entityHealth(notification.targetEntityId) then
          local add = notification.damageDealt
          if notification.healthLost >= world.entityHealth(notification.targetEntityId)[1] then
            add = add * 3
          end
          status.setStatusProperty("ivrpgsutitan", status.statusProperty("ivrpgsutitan", 0) + math.floor(add*100 + 0.5)/100)
        end
      end
    end
  end
end

function checkPerfectShield(dt)
  local notifications = nil
  notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      --Titan
      if notification.hitType == "ShieldHit" then
        if status.resourcePositive("perfectBlock") then
          self.perfectTimer = 3
        end
      end
      --Dragoon
      if notification.damageSourceKind and notification.damageSourceKind == "falling" and type(status.statusProperty("ivrpgsudragoon", 0)) == "number" and (world.entityCurrency(self.id, "experienceorb") >= self.rpg_specUnlockXp or status.statPositive("ivrpgmasteryunlocked")) and not status.statPositive("admin") then
        status.setStatusProperty("ivrpgsudragoon", status.statusProperty("ivrpgsudragoon", 0) + (notification.healthLost/2 or 0))
      end
    end
  end

  if self.perfectTimer > 0 then
    self.perfectTimer = math.max(self.perfectTimer - dt, 0)
  end

end

function uninit()

end
