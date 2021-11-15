function init()
  if status.isResource("stunned") then
    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  end
  self.zTimer = 0

  effect.setParentDirectives("fade=FFFFFF=0.25?border=1;ffffc933;ffff6933")
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  effect.addStatModifierGroup({{stat = "ivrpg_extraBleedChance", amount = 0.25}})
end

function update(dt)
  if self.zTimer <= 0 then
    animator.burstParticleEmitter("statustext")
    self.zTimer = 0.5
  end
  self.zTimer = self.zTimer - dt

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

  if status.resource("health") == 0 then
    uninit()
  end
end

function uninit()
   effect.setParentDirectives()
   status.setResource("stunned", 0)
end
