function init()
  --Power
  self.powerModifier = config.getParameter("powerModifier", 0)
  self.damageUpdate = 5
  self.timer = 0
  self.beganFall = false
  self.position = false
  self.damageBonusId = effect.addStatModifierGroup({})
  self.id = effect.sourceEntity()
  self.distanceFallen = 0
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)

  if mcontroller.falling() and not self.beganFall then
    self.beganFall = true
    self.position = mcontroller.position()
  end

  self.notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  if self.notifications then
    for _,notification in pairs(self.notifications) do
      --Paladin
      if notification.hitType == "ShieldHit" then
        if status.resourcePositive("perfectBlock") then
          local uniqueId = world.entityUniqueId(notification.sourceEntityId)
          if uniqueId and (uniqueId == "tentacleleft" or uniqueId == "tentacleright") and world.entityCurrency(self.id, "experienceorb") >= 122500 and not status.statusProperty("ivrpgsupaladin") then
            world.sendEntityMessage(self.id, "sendRadioMessage", "Paladin Unlocked!")
            status.setStatusProperty("ivrpgsupaladin", true)
          end
          self.timer = 5
          effect.setStatModifierGroup(self.damageBonusId, {{stat = "powerMultiplier", baseMultiplier = self.powerModifier}})
          animator.setParticleEmitterActive("embers", true)
        end
      end
      --Dragoon / Valkyrie
      if notification.damageSourceKind and notification.damageSourceKind == "falling" then
        -- Dragoon
        if type(status.statusProperty("ivrpgsudragoon", 0)) == "number" and world.entityCurrency(self.id, "experienceorb") >= 122500 and not status.statPositive("admin") then
          status.setStatusProperty("ivrpgsudragoon", status.statusProperty("ivrpgsudragoon", 0) + (notification.healthLost/2 or 0))
        end
        -- Valkyrie
        if type(status.statusProperty("ivrpgsuvalkyrie", 0)) == "number" and (notification.healthLost or 0) > 0 and status.resource("health") > 0 and self.position and world.entityCurrency(self.id, "experienceorb") >= 122500 and not status.statPositive("admin") then
          local distance = self.position and world.distance(self.position, mcontroller.position())[2] or 0
          if distance > 250 then
            self.position = false
            self.beganFall = false
            status.setStatusProperty("ivrpgsuvalkyrie", 500)
          end
        end
      end
    end
  end

  if self.position and not mcontroller.falling() then
    self.position = false
    self.beganFall = false
  end

  if self.timer > 0 then
    self.timer = math.max(0, self.timer - dt)
    if self.timer == 0 then
      effect.setStatModifierGroup(self.damageBonusId, {})
      animator.setParticleEmitterActive("embers", false)
    end
  end

  if not status.statPositive("ivrpgclassability") then
  	effect.setParentDirectives("border=1;51b1ba20;51b1ba00")
  else
  	effect.setParentDirectives()
  end

  if world.entityCurrency(effect.sourceEntity(), "classtype") ~= 1 then
      effect.expire()
  end
end

function uninit()

end
