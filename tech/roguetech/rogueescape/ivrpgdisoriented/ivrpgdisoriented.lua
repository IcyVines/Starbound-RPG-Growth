function init()
  effect.addStatModifierGroup({
    {stat = "powerMultiplier", baseMultiplier = 0.75}
  })
  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.5}
  })
  activateVisualEffects()
  effect.setParentDirectives("fade=FFFFFF=0.25?border=1;999999;595959")
end

function update(dt)
  mcontroller.controlModifiers({
    groundMovementModifier = 0.25,
    speedModifier = 0.25,
    airJumpModifier = 0.25
  })
end

function activateVisualEffects()
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end


function uninit()
  
end
