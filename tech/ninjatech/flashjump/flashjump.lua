require "/scripts/keybinds.lua"

function init()
  self.multiJumpCount = config.getParameter("multiJumpCount")
  self.cost = config.getParameter("cost")
  refreshJumps()
  Bind.create({jumping = true, onGround = false, liquidPercentage = 0}, doMultiJump)
end

function update(args)
  if mcontroller.groundMovement() or mcontroller.liquidMovement() then
    status.removeEphemeralEffect("camouflage25")
    status.removeEphemeralEffect("invulnerable")
    status.removeEphemeralEffect("nofalldamage")
    refreshJumps()
  elseif status.resource("energy") < 1 or status.statPositive("activeMovementAbilities") then
    status.removeEphemeralEffect("camouflage25")
    status.removeEphemeralEffect("invulnerable")
    status.removeEphemeralEffect("nofalldamage")
  end
end

function canMultiJump()
  return self.multiJumpCount > 0
      and not mcontroller.jumping()
      and not mcontroller.canJump()
      and not mcontroller.liquidMovement()
      and not status.statPositive("activeMovementAbilities")
      and math.abs(world.gravity(mcontroller.position())) > 0
end

function doMultiJump()
  --set flashjump player changes
  if canMultiJump() then
    if status.overConsumeResource("energy", self.cost) then
      status.addEphemeralEffect("camouflage25", .25)
      status.addEphemeralEffect("invulnerable", .25)
      status.addEphemeralEffect("nofalldamage", math.huge)

      mcontroller.controlJump(true)
      mcontroller.setYVelocity(math.max(0, mcontroller.yVelocity()))
      self.facing = mcontroller.facingDirection()
      --self.facing = tech.aimPosition()[1]-mcontroller.position()[1]
      if self.facing < 0 then
        mcontroller.setXVelocity(-50 + math.min(0, mcontroller.xVelocity()))
        animator.burstParticleEmitter("jumpLeftParticles")
      else
        mcontroller.setXVelocity(50 + math.max(0, mcontroller.xVelocity()))
        animator.burstParticleEmitter("jumpRightParticles")
      end
      self.multiJumpCount = self.multiJumpCount - 1
      animator.playSound("multiJumpSound")
    end
  end
end

function refreshJumps()
  self.multiJumpCount = config.getParameter("multiJumpCount")
  self.applyJumpModifier = false
end
