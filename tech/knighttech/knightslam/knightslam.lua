require "/scripts/keybinds.lua"

function init()
  self.jumpsLeft = config.getParameter("multiJumpCount")
  self.cost = config.getParameter("cost")
  self.downPressed = false
  self.jumped = false
  self.lastYVelocity = 0
  refreshJumps()

  Bind.create({jumping = true, onGround = false, liquidPercentage = 0}, doMultiJump)
  Bind.create({down = true, onGround = false, liquidPercentage = 0}, doSlam)
end

function update(args)

  if mcontroller.falling() then
    self.lastYVelocity = mcontroller.yVelocity()
  end

  if mcontroller.onGround() and self.downPressed and not self.jumped then
    self.downPressed = false
    --sb.logInfo("Last Y"..tostring(self.lastYVelocity))
    status.removeEphemeralEffect("nofalldamage")
    local damageConfig = {
      power = math.abs(self.lastYVelocity)*2,
      speed = 0,
      physics = "default"
    }
    world.spawnProjectile("armorthornburst", mcontroller.position(), entity.id(), {0, 0}, true, damageConfig)
  end

  if mcontroller.groundMovement() or mcontroller.liquidMovement() then
      refreshJumps()
  end

end

function doSlam()
  --set flashjump player changes
  self.downPressed = true
  status.addEphemeralEffect("nofalldamage", math.huge)
  mcontroller.controlJump(true)
  mcontroller.setYVelocity(math.min(-1, mcontroller.yVelocity())*20)
  animator.burstParticleEmitter("jumpParticles")
end

function doMultiJump()
  if not canMultiJump() then
    return
  end
  self.downPressed = false
  self.jumped = true
  mcontroller.controlJump(true)
  mcontroller.setYVelocity(math.max(0, mcontroller.yVelocity()))
  animator.burstParticleEmitter("jumpParticles")
  self.jumpsLeft = self.jumpsLeft - 1
  animator.playSound("multiJumpSound")
end

function canMultiJump()
  return self.jumpsLeft > 0
      and not mcontroller.jumping()
      and not mcontroller.canJump()
      and not mcontroller.liquidMovement()
      and not status.statPositive("activeMovementAbilities")
      and math.abs(world.gravity(mcontroller.position())) > 0
end

function refreshJumps()
  self.jumped = false
  self.jumpsLeft = config.getParameter("multiJumpCount")
end
