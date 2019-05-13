require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.power = config.getParameter("power", 1.25)
  self.resistance = config.getParameter("resistance", 0.25)
  self.energy = config.getParameter("energy", 0.1)
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", true)
  animator.setParticleEmitterOffsetRegion("energy", mcontroller.boundBox())
  animator.setParticleEmitterActive("energy", true)
  effect.addStatModifierGroup({
    { stat = "powerMultiplier", effectiveMultiplier = self.power },
    { stat = "physicalResistance", amount = self.resistance },
    { stat = "fireResistance", amount = self.resistance },
    { stat = "iceResistance", amount = self.resistance },
    { stat = "electricResistance", amount = self.resistance },
    { stat = "poisonResistance", amount = self.resistance },
    { stat = "novaResistance", amount = self.resistance },
    { stat = "demonicResistance", amount = self.resistance },
    { stat = "holyResistance", amount = self.resistance },
    { stat = "cosmicResistance", amount = self.resistance },
    { stat = "shadowResistance", amount = self.resistance },
    { stat = "radioactiveResistance", amount = self.resistance }
  })
end


function update(dt)
  if status.isResource("energy") then
    status.modifyResourcePercentage("energy", self.energy * dt)
  end
end

function uninit()
end