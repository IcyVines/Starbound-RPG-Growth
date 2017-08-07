require "/scripts/keybinds.lua"

function init()
  self.jumpsLeft = config.getParameter("multiJumpCount")
  self.cost = config.getParameter("cost")
  self.downPressed = false
  self.jumped = false
  self.lastYVelocity = 0
  self.lastYPosition = 0
  refreshJumps()

  Bind.create({jumping = true, onGround = false, liquidPercentage = 0}, doMultiJump)
  Bind.create({down = true, onGround = false, liquidPercentage = 0}, doSlam)
end

function update(args)

  self.liquidMovement = mcontroller.liquidMovement()

  if mcontroller.falling() then
    if self.downPressed and not self.liquidMovement then
      mcontroller.setYVelocity(-100)
    end
    self.lastYVelocity = mcontroller.yVelocity()
  end

  if (mcontroller.onGround() or self.liquidMovement) and self.downPressed then
    self.downPressed = false
    --sb.logInfo("Last Y"..tostring(self.lastYVelocity))
    status.clearPersistentEffects("movementAbility")
    self.lastYPosition = self.lastYPosition - mcontroller.yPosition()
    if not self.liquidMovement then
      spawnExplosions(mcontroller.xPosition(), mcontroller.yPosition())
    end
  end

  if (mcontroller.groundMovement() and mcontroller.onGround()) or self.liquidMovement then
    status.removeEphemeralEffect("nofalldamageks")
    refreshJumps()
  end

end

function spawnExplosions(x, y)
    sb.logInfo("yVelocity: " .. self.lastYVelocity .. ", yPosition: " .. self.lastYPosition)
    self.strength = world.entityCurrency(entity.id(), "strengthpoint")
    local visualConfig = {power = math.min(math.floor(self.lastYPosition^(self.strength^.25)/50)+1,150), timeToLive = .3, speed = 0.5, physics = "default"}
    world.spawnProjectile("armornova", {x + 2, y - 2}, entity.id(), {0, 0}, false, visualConfig)
    world.spawnProjectile("armornova", {x - 2, y - 2}, entity.id(), {0, 0}, false, visualConfig)
    world.spawnProjectile("armornova", {x, y - 2.5}, entity.id(), {0, 0}, false, visualConfig)
end

function doSlam()
  --set flashjump player changes
  if not self.downPressed and not status.statPositive("activeMovementAbilities") and status.overConsumeResource("energy", self.cost) then
    self.downPressed = true
    self.lastYPosition = mcontroller.yPosition()
    status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
    status.addEphemeralEffect("nofalldamageks", math.huge)
    mcontroller.controlJump(true)
    mcontroller.setYVelocity(-100)
    mcontroller.setXVelocity(0)
    animator.burstParticleEmitter("downParticles")
  end
end

function doMultiJump()
  if not canMultiJump() then
    return
  end
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
