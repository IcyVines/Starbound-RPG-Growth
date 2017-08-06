function init()
  self.multiJumpCount = config.getParameter("multiJumpCount")
  self.multiJumpModifier = config.getParameter("multiJumpModifier")
  self.cost = config.getParameter("cost")

  refreshJumps()
end

function update(args)
  local jumpActivated = args.moves["jump"] and not self.lastJump
  self.lastJump = args.moves["jump"]

  updateJumpModifier()

  if jumpActivated and canMultiJump() then
    if status.overConsumeResource("energy", self.cost) then
      doMultiJump()
    end
  else
    if mcontroller.groundMovement() or mcontroller.liquidMovement() or status.resource("energy") < 1 then
      status.removeEphemeralEffect("camouflage25")
      status.removeEphemeralEffect("invulnerable")
      status.removeEphemeralEffect("nofalldamage")
      refreshJumps()
    end
  end
end

-- after the original ground jump has finished, start applying the new jump modifier
function updateJumpModifier()
  if self.multiJumpModifier then
    if not self.applyJumpModifier
        and not mcontroller.jumping()
        and not mcontroller.groundMovement() then

      self.applyJumpModifier = true
    end

    if self.applyJumpModifier then mcontroller.controlModifiers({airJumpModifier = self.multiJumpModifier}) end
  end
end

function canMultiJump()
  return self.multiJumps > 0
      and not mcontroller.jumping()
      and not mcontroller.canJump()
      and not mcontroller.liquidMovement()
      and not status.statPositive("activeMovementAbilities")
      and math.abs(world.gravity(mcontroller.position())) > 0
end

function doMultiJump()
  --set flashjump player changes

  status.addEphemeralEffect("camouflage25", 20)
  status.addEphemeralEffect("invulnerable", 20)
  status.addEphemeralEffect("nofalldamage", 20)

  mcontroller.controlJump(true)
  mcontroller.setYVelocity(math.max(0, mcontroller.yVelocity()))
  self.facing = mcontroller.facingDirection()
  --self.facing = tech.aimPosition()[1]-mcontroller.position()[1]
  if self.facing < 0 then
    mcontroller.setXVelocity(-50 + math.min(0, mcontroller.xVelocity()))
    animator.burstParticleEmitter("jumpParticles")
  else
    mcontroller.setXVelocity(50 + math.max(0, mcontroller.xVelocity()))
    animator.burstParticleEmitter("jumpParticles")
  end
  self.multiJumps = self.multiJumps - 1
  animator.playSound("multiJumpSound")
end

function refreshJumps()
  self.multiJumps = self.multiJumpCount
  self.applyJumpModifier = false
end
