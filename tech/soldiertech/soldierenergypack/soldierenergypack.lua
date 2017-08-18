require "/scripts/keybinds.lua"

function init()
  self.jumpsLeft = config.getParameter("multiJumpCount")
  self.cooldownTimer = 0
  self.rechargeEffectTimer = 0

  self.cooldown = config.getParameter("cooldown")
  self.duration = config.getParameter("duration")

  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=21A81AFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)

  refreshJumps()
  Bind.create("Up", energize)
  Bind.create({jumping = true, onGround = false, liquidPercentage = 0}, doMultiJump)

end

function energize()
  if self.cooldownTimer == 0 and not status.statPositive("activeMovementAbilities") then
    self.cooldownTimer = self.cooldown + self.duration
    status.addEphemeralEffect("jumpboost", self.duration)
    animator.playSound("energize")
    status.modifyResourcePercentage("energy", 1)
  elseif self.cooldownTimer > self.cooldown then
    self.cooldownTimer = self.cooldown
    status.removeEphemeralEffect("jumpboost")
  end
end

function uninit()
  status.removeEphemeralEffect("jumpboost")
  tech.setParentDirectives()
end

function update(args)

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(0, self.cooldownTimer - args.dt)
    if self.cooldownTimer == 0 then
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

  if mcontroller.groundMovement() or mcontroller.liquidMovement() then
    refreshJumps()
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
  self.jumpsLeft = config.getParameter("multiJumpCount")
end