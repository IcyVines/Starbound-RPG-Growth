require "/scripts/keybinds.lua"

function init()
  self.jumpsLeft = config.getParameter("multiJumpCount")
  self.rechargeEffectTimer = 0
  self.dashTimer = 0
  self.dashCooldownTimer = 0

  self.dashControlForce = config.getParameter("dashControlForce")
  self.dashSpeed = config.getParameter("dashSpeed")
  self.dashDuration = config.getParameter("dashDuration")
  self.dashCooldown = config.getParameter("dashCooldown")

  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=21A81AFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)

  refreshJumps()
  --Bind.create("Up", energize)
  Bind.create({jumping = true, onGround = false, liquidPercentage = 0}, doMultiJump)

  status.setPersistentEffects("energizefalldamagereduction", {
    {stat = "fallDamageMultiplier", amount = -0.1}
  })

end

--[[
function energize()
  if self.cooldownTimer == 0 and not status.statPositive("activeMovementAbilities") then
    self.cooldownTimer = self.cooldown + self.duration
    status.addEphemeralEffect("jumpboost", self.duration)
    animator.playSound("energize")
    status.modifyResourcePercentage("energy", 1)
  elseif self.cooldownTimer > self.cooldown then
    self.cooldownTimer = self.cooldown
    status.addEphemeralEffect("soldierenergypackcooldown", self.cooldownTimer)
    status.removeEphemeralEffect("jumpboost")
  end
end
--]]

function uninit()
  --status.removeEphemeralEffect("jumpboost")
  --status.removeEphemeralEffect("soldierenergypackcooldown")
  status.clearPersistentEffects("energizefalldamagereduction")
  status.clearPersistentEffects("movementAbility")
  animator.setAnimationState("dashing", "off")
  animator.setParticleEmitterActive("dashParticles", false)
  tech.setParentDirectives()
end

function update(args)

  --Find Directional Input
  self.hDirection = 0
  self.vDirection = 0
  if args.moves["left"] and not args.moves["right"] then
    self.hDirection = -1
  elseif args.moves["right"] and not args.moves["left"] then
    self.hDirection = 1
  end
  if args.moves["up"] and not args.moves["down"] then
    self.vDirection = 1
  elseif args.moves["down"] and not args.moves["up"] then
    self.vDirection = -1
  end

  if self.dashTimer > 0 then
    mcontroller.controlApproachVelocity({self.dashSpeed * self.hDirection, self.dashSpeed * self.vDirection}, self.dashControlForce)
    mcontroller.controlMove(self.hDirection, true)
    mcontroller.controlModifiers({jumpingSuppressed = true})
    animator.setFlipped(mcontroller.facingDirection() == -1)
    self.dashTimer = math.max(0, self.dashTimer - args.dt)
    if self.dashTimer == 0 or mcontroller.groundMovement() or mcontroller.liquidMovement() then
      endDash()
    end
  end

  --[[if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(0, self.cooldownTimer - args.dt)
    if self.cooldownTimer == 0 then
      self.cooldownActive = false
      self.rechargeEffectTimer = self.rechargeEffectTime
      tech.setParentDirectives(self.rechargeDirectives)
      animator.playSound("recharge")
    elseif self.cooldownTimer <= self.cooldown and not self.cooldownActive then
      self.cooldownActive = true
      status.addEphemeralEffect("soldierenergypackcooldown", self.cooldownTimer)
    end
  end

  if self.rechargeEffectTimer > 0 then
    self.rechargeEffectTimer = math.max(0, self.rechargeEffectTimer - args.dt)
    if self.rechargeEffectTimer == 0 then
      tech.setParentDirectives()
    end
  end--]]

  if mcontroller.groundMovement() or mcontroller.liquidMovement() then
    refreshJumps()
  end

end

function doMultiJump()
  if not canMultiJump() then
    return
  end
  mcontroller.controlJump(true)
  startDash()
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

function startDash()
  self.dashTimer = self.dashDuration
  status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  mcontroller.setVelocity({0, 0})
  animator.playSound("startDash")
  animator.setAnimationState("dashing", "on")
  animator.setParticleEmitterActive("dashParticles", true)
end

function endDash()
  status.clearPersistentEffects("movementAbility")
  local movementParams = mcontroller.baseParameters()
  local currentVelocity = mcontroller.velocity()
  mcontroller.setVelocity({0, 0})
  animator.setAnimationState("dashing", "off")
  animator.setParticleEmitterActive("dashParticles", false)
end