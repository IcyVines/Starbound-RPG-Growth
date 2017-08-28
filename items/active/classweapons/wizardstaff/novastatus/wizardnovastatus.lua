function init()
  effect.addStatModifierGroup({
    {stat = "iceResistance", amount = -.50},
    {stat = "fireResistance", amount = -.50},
    {stat = "electricResistance", amount = -.50},
  })
  activateVisualEffects()
  effect.setParentDirectives("fade=77005F=0.25")
end

function update(dt)
end

function activateVisualEffects()
  animator.setParticleEmitterOffsetRegion("bloodparticles", mcontroller.boundBox())
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
  animator.burstParticleEmitter("smoke")
end


function uninit()

end
