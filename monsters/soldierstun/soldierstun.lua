function init()
  effect.setParentDirectives("fade=FFFFFF=0.25?border=1;e89819;a36809")
  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.3}
  })
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.0,
      speedModifier = 0.0,
      airJumpModifier = 0.0
    })
  
end

function uninit()
end
