function init()
  self.sourceId = effect.sourceEntity()
  self.id = entity.id()
  self.cooldown = config.getParameter("cooldown", false)

  if not self.cooldown then
    animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
    animator.setParticleEmitterActive("healing", true)
  end

  if self.id ~= self.sourceId then
    world.sendEntityMessage(self.sourceId, "addEphemeralEffect", "ivrpgeinherjar", 5, self.sourceId)
    effect.addStatModifierGroup({
      { stat = "powerMultiplier", baseMultiplier = 2.5 },
      { stat = "protection", amount = 1000 },
      { stat = "physicalResistance", amount = 3 },
      { stat = "poisonResistance", amount = 3 },
      { stat = "fireResistance", amount = 3 },
      { stat = "electricResistance", amount = 3 },
      { stat = "iceResistance", amount = 3 },
      { stat = "shadowResistance", amount = 3 },
      { stat = "holyResistance", amount = 3 },
      { stat = "demonicResistance", amount = 3 },
      { stat = "novaResistance", amount = 3 },
      { stat = "cosmicResistance", amount = 3 },
      { stat = "radioactiveResistance", amount = 3 },
      { stat = "fireStatusImmunity", amount = 1 },
      { stat = "poisonStatusImmunity", amount = 1 },
      { stat = "electricStatusImmunity", amount = 1 },
      { stat = "iceStatusImmunity", amount = 1 },
      { stat = "breathProtection", amount = 1 },
      { stat = "biomecoldImmunity", amount = 1 },
      { stat = "ffextremecoldImmunity", amount = 1 },
      { stat = "biomeradiationImmunity", amount = 1 },
      { stat = "ffextremeradiationImmunity", amount = 1 },
      { stat = "biomeheatImmunity", amount = 1 },
      { stat = "ffextremeheatImmunity", amount = 1 },
      { stat = "lavaImmunity", amount = 1 },
      { stat = "protoImmunity", amount = 1 }
    })
  elseif self.cooldown then
    status.setStatusProperty("ivrpgeinherjarcooldown", true)
  else
    status.modifyResourcePercentage("health", -0.2)
  end
end

function update(dt)
  if self.id == self.sourceId and not self.cooldown then
    status.setResourcePercentage("energyRegenBlock", 1.0)
    status.setResource("energy", 0)
  end
end

function uninit()
  effect.setParentDirectives()
  if self.id ~= self.sourceId then
    world.sendEntityMessage(self.sourceId, "removeEphemeralEffect", "ivrpgeinherjar")
  elseif self.cooldown then
    status.setStatusProperty("ivrpgeinherjarcooldown", false)
  else
    status.addEphemeralEffect("ivrpgeinherjarcooldown", 30, self.sourceId)
  end
end