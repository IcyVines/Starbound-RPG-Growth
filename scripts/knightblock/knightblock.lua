function init()
  --Power
  self.powerModifier = config.getParameter("powerModifier", 0)
  self.damageUpdate = 5
  self.timer = 0
  self.damageBonusId = effect.addStatModifierGroup({})
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)

  self.notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  if self.notifications then
    for _,notification in pairs(self.notifications) do
      if notification.hitType == "ShieldHit" then
        if status.resourcePositive("perfectBlock") then
          self.timer = 5
          effect.setStatModifierGroup(self.damageBonusId, {{stat = "powerMultiplier", baseMultiplier = self.powerModifier}})
          animator.setParticleEmitterActive("embers", true)
        end
      end
    end
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
