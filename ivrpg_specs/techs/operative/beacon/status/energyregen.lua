function init()
  animator.setParticleEmitterOffsetRegion("energy", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("energy", config.getParameter("emissionRate", 5))
  animator.setParticleEmitterActive("energy", true)

  effect.addStatModifierGroup({
    {stat = "ivrpgoperativebeacon", amount = 1}
  })
end

function update(dt)
	if status.isResource("energy") then
		status.modifyResource("energy", dt * config.getParameter("energyRegen"))
	end
end

function uninit()

end
