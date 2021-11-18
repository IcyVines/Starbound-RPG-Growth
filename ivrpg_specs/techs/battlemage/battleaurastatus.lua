require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.effect = config.getParameter("effect", "none")
  _,self.damageGivenUpdate = status.inflictedDamageSince()
  self.timer = 0
  self.protectionStack = 0
  local bounds = mcontroller.boundBox()
  animator.setParticleEmitterOffsetRegion("power", bounds)
  animator.setParticleEmitterOffsetRegion("armor", bounds)
  animator.setParticleEmitterOffsetRegion("speed", world.isMonster(entity.id()) and bounds or {bounds[1], bounds[2] + 0.2, bounds[3], bounds[2] + 0.3})

  if self.effect ~= "none" then
    animator.setParticleEmitterActive(self.effect, true)
  end

  effect.addStatModifierGroup({
    { stat = "powerMultiplier", effectiveMultiplier = self.effect == "power" and 1.15 or (self.effect == "speed" and 0.75 or 1) },
    { stat = "maxHealth", effectiveMultiplier = self.effect == "armor" and 1.15 or (self.effect == "power" and 0.75 or 1) }
  })

  --[[
    Blood Aura: 115% Power Multplier but 75% Max Health. Health Regen.
    Iron Aura: 115% Max Health but 75% Speed and Jump Height. Armor Stacking.
    Ionic Aura: 115% Speed and Jump Height but 75% Power Multiplier. Energy Regen.
  ]]
end


function update(dt)
  if self.effect == "speed" then
    animator.setParticleEmitterActive("speed", mcontroller.onGround() and mcontroller.running())
    mcontroller.controlModifiers({
      speedModifier = 1.15,
      airJumpModifier = 1.15
    })
  elseif self.effect == "armor" then
    mcontroller.controlModifiers({
      speedModifier = 0.75,
      airJumpModifier = 0.75
    })
  end

  updateDamageGiven()

  status.setPersistentEffects("ivrpgbattleauraprotection", {
    { stat = "protection", amount = 2 * self.protectionStack }
  })

  if self.protectionStack > 0 then
    if self.timer == 0 then
      self.timer = 1
      self.protectionStack = math.max(0, self.protectionStack - 1)
    else
      self.timer = math.max(0, self.timer - dt)
    end
  end
end

function updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if self.effect ~= "none" and notifications then
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 then
        --notification.damageDealt
        if self.effect == "armor" then
          self.protectionStack = math.min(self.protectionStack + 1, 15)
          self.timer = 1
        else
          status.modifyResource(self.effect == "power" and "health" or "energy", notification.healthLost / 10)
        end
      end
    end
  end
end

function uninit()
  status.clearPersistentEffects("ivrpgbattleauraprotection")
end