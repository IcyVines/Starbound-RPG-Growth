require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.modifiers = config.getParameter("modifiers", {})
  self.movementParams = mcontroller.baseParameters()
  animator.setParticleEmitterOffsetRegion("embersB", mcontroller.boundBox())
  animator.setParticleEmitterOffsetRegion("embersNB", mcontroller.boundBox())
  effect.addStatModifierGroup({
    {stat = "ivrpgterranova", amount = 1}
  })
end


function update(dt)
  
  if status.statusProperty("ivrpgterranova", "Not Celestial") == "Bookmarked" then
    status.setPersistentEffects("ivrpgterranova", {
      {stat = "powerMultiplier", baseMultiplier = self.modifiers.power},
      {stat = "maxEnergy", baseMultiplier = self.modifiers.energy}
    })
    animator.setParticleEmitterActive("embersB", true)
  elseif status.statusProperty("ivrpgterranova", "Not Celestial") == "Not Bookmarked" then
    status.setPersistentEffects("ivrpgterranova", {
      {stat = "physicalResistance", amount = self.modifiers.resistance},
      {stat = "fireResistance", amount = self.modifiers.resistance},
      {stat = "poisonResistance", amount = self.modifiers.resistance},
      {stat = "iceResistance", amount = self.modifiers.resistance},
      {stat = "electricResistance", amount = self.modifiers.resistance},
      {stat = "novaResistance", amount = self.modifiers.resistance},
      {stat = "demonicResistance", amount = self.modifiers.resistance},
      {stat = "holyResistance", amount = self.modifiers.resistance},
      {stat = "shadowResistance", amount = self.modifiers.resistance},
      {stat = "radioactiveResistance", amount = self.modifiers.resistance},
      {stat = "cosmicResistance", amount = self.modifiers.resistance}
    })
    mcontroller.controlModifiers({
      speedModifier = self.modifiers.speed
    })
    animator.setParticleEmitterActive("embersNB", true)
  elseif status.statusProperty("ivrpgterranova", "Not Celestial") == "Not Celestial" then
    reset()
  end

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 1 or world.entityCurrency(self.id, "classtype") ~= 6 then
    effect.expire()
  end
end

function reset()
  animator.setParticleEmitterActive("embersB", false)
  animator.setParticleEmitterActive("embersNB", false)
  status.clearPersistentEffects("ivrpgterranova")
end

function uninit()
  reset()
end
