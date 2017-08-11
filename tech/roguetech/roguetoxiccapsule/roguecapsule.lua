function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  effect.addStatModifierGroup({
    {stat = "poisonStatusImmunity", amount = 1},
    {stat = "physicalResistance", amount = .33}
  })
  effect.setParentDirectives("border=2;00822020;00421000")
end


function update(dt)
  status.modifyResourcePercentage("health", -1/55 * dt)
end

function uninit()

end
