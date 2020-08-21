function init()
  if status.isResource("stunned") then
    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  end
  effect.setParentDirectives("fade=FFFFFF=0.25?border=1;98e81933;68a30933")

  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.0,
      speedModifier = 0.0,
      airJumpModifier = 0.0,
      movementSuppressed = true,
      facingSuppressed = true,
      jumpingSuppressed = true
  })

  mcontroller.controlParameters({
    collisionEnabled = true
  })

  if status.isResource("stunned") then
    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  end

  if status.resource("health") == 0 then
    uninit()
  end
end

function uninit()
   effect.setParentDirectives()
   status.setResource("stunned", 0)
end
