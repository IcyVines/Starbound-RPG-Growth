function init()
  animator.setParticleEmitterOffsetRegion("energy", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("energy", config.getParameter("emissionRate", 5))
  animator.setParticleEmitterActive("energy", true)
  self.energyRegen = config.getParameter("energyRegen", 0.2)
  --[[effect.addStatModifierGroup({
      {stat = "energyRegenPercentageRate", amount = 0},
      {stat = "energyRegenBlockTime", effectiveMultiplier = 0}
   })]]
end

function update(dt)
	if status.isResource("energy") then
		status.modifyResourcePercentage("energy", self.energyRegen * dt)
	end
end

function uninit()

end
