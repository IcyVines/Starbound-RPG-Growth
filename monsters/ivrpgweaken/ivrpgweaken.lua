function init()
  effect.addStatModifierGroup({
    {stat = "protection", amount = -20}
  })
  activateVisualEffects()
  effect.setParentDirectives("fade=770000=0.25")
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
