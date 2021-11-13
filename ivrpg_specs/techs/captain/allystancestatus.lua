require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.effect = config.getParameter("effect", "none")
  local bounds = mcontroller.boundBox()
  animator.setParticleEmitterOffsetRegion("power", bounds)
  animator.setParticleEmitterOffsetRegion("armor", bounds)
  animator.setParticleEmitterOffsetRegion("speed", world.isMonster(entity.id()) and bounds or {bounds[1], bounds[2] + 0.2, bounds[3], bounds[2] + 0.3})

  if self.effect ~= "none" then
    animator.setParticleEmitterActive(self.effect, true)
  end

  effect.addStatModifierGroup({
    { stat = "powerMultiplier", effectiveMultiplier = self.effect == "power" and 1.25 or (self.effect == "speed" and 0.75 or 1) },
    { stat = "protection", amount = self.effect == "armor" and 15 or (self.effect == "power" and -15 or 0) }
  })

  --[[
    Power Stance: 125% Power Multplier but -15 Armor.
    Armor Stance: +15 Armor but 75% Speed and Jump Height.
    Speed Stance: 125% Speed and Jump Height but 75% Power Multiplier
  ]]
end


function update(dt)
  if self.effect == "speed" then
    animator.setParticleEmitterActive("speed", mcontroller.onGround() and mcontroller.running())
    mcontroller.controlModifiers({
      speedModifier = 1.25,
      airJumpModifier = 1.25
    })
  elseif self.effect == "armor" then
    mcontroller.controlModifiers({
      speedModifier = 0.75,
      airJumpModifier = 0.75
    })
  end
end


function uninit()
end