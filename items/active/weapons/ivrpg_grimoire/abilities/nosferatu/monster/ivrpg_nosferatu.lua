function init()
  if status.isResource("stunned") then
    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  end
  effect.setParentDirectives("?fade=666666=0.5")

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
      facingSuppressed = true
  })
  --mcontroller.setXVelocity(0)
  mcontroller.controlParameters({
      gravityEnabled = true,
      collisionEnabled = true
    })
  --mcontroller.controlCrouch()
  if status.isResource("stunned") then
    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  end

  local healthGain = dt / 100 * status.resourceMax("health")
  status.modifyResourcePercentage("health", -dt / 100 * 5)
  world.sendEntityMessage(effect.sourceEntity(), "modifyResource", "health", healthGain)

  if status.resource("health") == 0 then
    uninit()
  end
end

function uninit()
   effect.setParentDirectives()
   status.setResource("stunned", 0)
end
