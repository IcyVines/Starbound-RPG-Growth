require "/scripts/keybinds.lua"
require "/tech/ivrpgopenrpgui.lua"

function init()
  ivrpg_ttShortcut.initialize()
  self.jumpsLeft = config.getParameter("multiJumpCount")
  self.origJumpsLeft = self.jumpsLeft
  self.cost = config.getParameter("cost")
  self.downPressed = false
  self.jumped = false
  self.lastYVelocity = 0
  self.lastYPosition = 0
  --timer variables
  self.liquidTimer = 0
  self.slamCooldownTimer = 0
  self.rechargeEffectTimer = 0
  self.slamCooldown = config.getParameter("cooldown")
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=4cedffFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)
  --end timer variables
  refreshJumps()

  Bind.create({jumping = true, onGround = false, liquidPercentage = 0}, doMultiJump)
  Bind.create({g = true, onGround = false, liquidPercentage = 0}, doSlam)
end

function update(args)
  
  self.peakPerformance = status.statPositive("ivrpgucpeakperformance")

  if self.slamCooldownTimer > 0 then
    self.slamCooldownTimer = math.max(0, self.slamCooldownTimer - args.dt)
    if self.slamCooldownTimer == 0 then
      self.rechargeEffectTimer = self.rechargeEffectTime
      tech.setParentDirectives(self.rechargeDirectives)
      animator.playSound("recharge")
    end
  end

  if self.rechargeEffectTimer > 0 then
    self.rechargeEffectTimer = math.max(0, self.rechargeEffectTimer - args.dt)
    if self.rechargeEffectTimer == 0 then
      tech.setParentDirectives()
    end
  end

  self.liquidMovement = mcontroller.liquidMovement()

  if mcontroller.falling() then
    if self.downPressed and not self.liquidMovement then
      mcontroller.setYVelocity(-100)
    end
    self.lastYVelocity = mcontroller.yVelocity()
  end

  if (mcontroller.onGround() or self.liquidMovement) and self.downPressed then
    self.slamCooldownTimer = self.slamCooldown
    self.downPressed = false
    status.clearPersistentEffects("movementAbility")
    self.lastYPosition = self.lastYPosition - mcontroller.yPosition()
    if not self.liquidMovement then
      spawnExplosions(mcontroller.xPosition(), mcontroller.yPosition())
    else
      mcontroller.setYVelocity(0)
    end
  end

  if (mcontroller.groundMovement() and mcontroller.onGround()) or self.liquidMovement then
    if not self.liquidMovement then
      status.removeEphemeralEffect("nofalldamageks")
    else
      self.liquidTimer = self.liquidTimer + args.dt
      if self.liquidTimer > 0.2 then
        self.liquidTimer = 0
        status.removeEphemeralEffect("nofalldamageks")
      end
    end
    refreshJumps()
  end

end

function uninit()
  status.clearPersistentEffects("movementAbility")
  status.removeEphemeralEffect("nofalldamageks")
end

function spawnExplosions(x, y)
    self.strength = status.statusProperty("ivrpgstrength", 0)
    local damageFallOff = 1
    local bonusKnockback = 0
    if self.peakPerformance then
      damageFallOff = 0.8
      bonusKnockback = 40
    end
    local visualConfig = {power = math.min(200*damageFallOff, (self.lastYPosition^2*self.strength/50+1)*damageFallOff), timeToLive = .4, speed = 6.66, knockback = 10 + bonusKnockback, physics = "default"}
    animator.playSound("slamSound")
    world.spawnProjectile("armornova", {x + 2, y - 2}, entity.id(), {0, 0}, false, visualConfig)
    world.spawnProjectile("armornova", {x - 2, y - 2}, entity.id(), {0, 0}, false, visualConfig)
    world.spawnProjectile("armornova", {x, y - 2.5}, entity.id(), {0, 0}, false, visualConfig)
end

function doSlam()
  --set flashjump player changes
  if not self.downPressed and self.slamCooldownTimer == 0 and not status.statPositive("activeMovementAbilities") and status.overConsumeResource("energy", self.cost) then
    self.downPressed = true
    self.lastYPosition = mcontroller.yPosition()
    status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
    status.addEphemeralEffect("nofalldamageks", math.huge)
    mcontroller.controlJump(true)
    mcontroller.setYVelocity(-100)
    mcontroller.setXVelocity(0)
    animator.burstParticleEmitter("downParticles")
    animator.playSound("multiJumpSound")
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
  if status.statPositive("ivrpgucpeakperformance") then
    self.jumpsLeft = self.origJumpsLeft + 1
  else
    self.jumpsLeft = self.origJumpsLeft
  end
end
