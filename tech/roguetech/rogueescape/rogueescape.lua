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

  self.vDirectionLocked = 0
  self.hDirectionLocked = 0

  refreshJumps()
  Bind.create({jumping = true, onGround = false, liquidPercentage = 0}, doMultiJump)

end

function uninit()
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
    self.agility = world.entityCurrency(entity.id(), "agilitypoint")
    if self.vDirectionLocked == 0 or self.hDirectionLocked == 0 then
      mcontroller.controlApproachVelocity({self.dashSpeed * self.hDirectionLocked * (1+self.agility/100), self.dashSpeed * self.vDirectionLocked * (1+self.agility/100)}, self.dashControlForce)
    else
      mcontroller.controlApproachVelocity({self.dashSpeed/1.41 * self.hDirectionLocked * (1+self.agility/100), self.dashSpeed/1.41 * self.vDirectionLocked * (1+self.agility/100)}, self.dashControlForce)
    end
    mcontroller.controlMove(self.hDirectionLocked, true)
    mcontroller.controlModifiers({jumpingSuppressed = true})
    animator.setFlipped(mcontroller.facingDirection() == -1)
    self.dashTimer = math.max(0, self.dashTimer - args.dt)
    if self.dashTimer == 0 or mcontroller.groundMovement() or mcontroller.liquidMovement() then
      endDash()
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
  startDash()
  --animator.burstParticleEmitter("jumpParticles")
  self.jumpsLeft = self.jumpsLeft - 1
  --animator.playSound("multiJumpSound")
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
  self.vDirectionLocked = self.vDirection
  self.hDirectionLocked = (self.vDirectionLocked == 0 and self.hDirection == 0) and mcontroller.facingDirection()*-1 or self.hDirection
  self.dashTimer = self.dashDuration
  status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  mcontroller.setVelocity({0, 0})
  animator.playSound("startDash")
  animator.setAnimationState("dashing", "on")
  animator.setParticleEmitterActive("dashParticles", true)
  spawnSmoke()
end

function endDash()
  status.clearPersistentEffects("movementAbility")
  local movementParams = mcontroller.baseParameters()
  local currentVelocity = mcontroller.velocity()
  --mcontroller.setVelocity({0, 0})
  animator.setAnimationState("dashing", "off")
  animator.setParticleEmitterActive("dashParticles", false)
end

function spawnSmoke()
  world.spawnProjectile("roguedisorientingsmoke", {mcontroller.xPosition()+1, mcontroller.yPosition()+1}, entity.id(), {0,0}, false, {})
  world.spawnProjectile("roguedisorientingsmoke", {mcontroller.xPosition()-1, mcontroller.yPosition()+1}, entity.id(), {0,0}, false, {})
  world.spawnProjectile("roguedisorientingsmoke", {mcontroller.xPosition()+1, mcontroller.yPosition()-1}, entity.id(), {0,0}, false, {})
  world.spawnProjectile("roguedisorientingsmoke", {mcontroller.xPosition()-1, mcontroller.yPosition()-1}, entity.id(), {0,0}, false, {})
end