require "/scripts/keybinds.lua"
require "/tech/ivrpgopenrpgui.lua"

function init()
  ivrpg_ttShortcut.initialize()
  self.multiJumpCount = config.getParameter("multiJumpCount")
  self.cost = config.getParameter("cost")
  self.maxSpeed = 25
  refreshJumps()
  Bind.create({jumping = true, onGround = false, liquidPercentage = 0}, doMultiJump)
end

function update(args)

 self.lrInput = nil
  if args.moves["left"] and not args.moves["right"] then
    self.lrInput = "left"
  elseif args.moves["right"] and not args.moves["left"] then
    self.lrInput = "right"
  end
  if mcontroller.groundMovement() or mcontroller.liquidMovement() then
    status.removeEphemeralEffect("ivrpgjumpcamouflage")
    status.removeEphemeralEffect("nofalldamage")
    refreshJumps()
  elseif status.resource("energy") < 1 or status.statPositive("activeMovementAbilities") then
    status.removeEphemeralEffect("ivrpgjumpcamouflage")
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

function doMultiJump(args)
  --set flashjump player changes
  if canMultiJump() then
    if status.overConsumeResource("energy", self.cost) then
      status.addEphemeralEffect("ivrpgjumpcamouflage", .25)
      status.addEphemeralEffect("nofalldamage", math.huge)

      mcontroller.controlJump(true)
      mcontroller.setYVelocity(math.max(0, mcontroller.yVelocity()))
      self.facing = mcontroller.facingDirection()
      --self.facing = tech.aimPosition()[1]-mcontroller.position()[1]
    
      if self.lrInput == "left" then
        mcontroller.setXVelocity(-self.maxSpeed + math.min(0, mcontroller.xVelocity()))
        animator.burstParticleEmitter("jumpLeftParticles")
      elseif self.lrInput == "right" then
        mcontroller.setXVelocity(self.maxSpeed + math.max(0, mcontroller.xVelocity()))
        animator.burstParticleEmitter("jumpRightParticles")
      elseif self.facing < 0 then
        mcontroller.setXVelocity(-self.maxSpeed + math.min(0, mcontroller.xVelocity()))
        animator.burstParticleEmitter("jumpLeftParticles")
      else
        mcontroller.setXVelocity(self.maxSpeed + math.max(0, mcontroller.xVelocity()))
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
