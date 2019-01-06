function init()
  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.5}
  })
  activateVisualEffects()
  animator.setParticleEmitterOffsetRegion("smoke", mcontroller.boundBox())
  animator.setParticleEmitterOffsetRegion("smoke", {0,1,0,0})
  animator.setParticleEmitterActive("smoke", true)
end

function update(dt)
  mcontroller.controlModifiers({
    groundMovementModifier = 0.25,
    speedModifier = 0.25,
    airJumpModifier = 0.25
  })
  mcontroller.controlParameters({
    airSpeed = 1,
    walkSpeed = 2,
    runSpeed = 4
  })
end

function activateVisualEffects()
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end


function uninit()
  animator.setParticleEmitterActive("embers", false)
end
