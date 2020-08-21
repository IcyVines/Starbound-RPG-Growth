require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/util.lua"
require "/scripts/keybinds.lua"
require "/tech/ivrpgopenrpgui.lua"

function init()
  ivrpg_ttShortcut.initialize()
  self.jumpsLeft = config.getParameter("multiJumpCount")
  self.rechargeEffectTimer = 0
  self.dashTimer = 0
  self.dashCooldownTimer = 0

  self.dashControlForce = config.getParameter("dashControlForce")
  self.dashSpeed = config.getParameter("dashSpeed")
  self.dashDuration = config.getParameter("dashDuration")
  self.dashCooldown = config.getParameter("dashCooldown")

  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=FF991AFF=0.25")
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
  tech.setParentState()
end

function update(args)

  local jumpActivated = args.moves["jump"] and not self.lastJump
  self.lastJump = args.moves["jump"]
  self.shiftHeld = not args.moves["run"]
  self.dt = args.dt
  self.float = args.moves["up"]

  --Find Directional Input
  self.hDirection = 0
  self.vDirection = 0
  local lrInput
  if args.moves["left"] and not args.moves["right"] then
    self.hDirection = -1
    lrInput = "left"
  elseif args.moves["right"] and not args.moves["left"] then
    self.hDirection = 1
    lrInput = "right"
  end
  if args.moves["up"] and not args.moves["down"] then
    self.vDirection = 1
  elseif args.moves["down"] and not args.moves["up"] then
    self.vDirection = -1
  end

  if self.dashTimer > 0 then
    if self.vDirectionLocked == 0 or self.hDirectionLocked == 0 then
      mcontroller.setVelocity({self.dashSpeed * self.hDirectionLocked, self.dashSpeed * self.vDirectionLocked})
    else
      mcontroller.setVelocity({self.dashSpeed/1.41 * self.hDirectionLocked, self.dashSpeed/1.41 * self.vDirectionLocked})
    end
    mcontroller.controlMove(self.hDirectionLocked, true)
    mcontroller.controlModifiers({
      jumpingSuppressed = true,
      gravityEnabled = false
    })
    animator.setFlipped(mcontroller.facingDirection() == -1)
    self.dashTimer = math.max(0, self.dashTimer - args.dt)
    if self.dashTimer <= 0 or mcontroller.groundMovement() or mcontroller.liquidMovement() then
      endDash()
    end
  end

  if self.float and canFloat() then
    mcontroller.setXVelocity(util.clamp(mcontroller.xVelocity(), self.hDirection == 1 and 0 or -10, self.hDirection == -1 and 0 or 10))
    mcontroller.controlApproachYVelocity(0, self.dashControlForce / 2)
    tech.setParentState("Fly")
  else
    tech.setParentState()
  end

  if mcontroller.groundMovement() or mcontroller.liquidMovement() then
    refreshJumps()
    --status.removeEphemeralEffect("nofalldamage")
  end

end

function doMultiJump()
  if not canMultiJump() then
    return
  end
  --mcontroller.controlJump(true)
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

function canFloat()
  return not mcontroller.jumping()
      and not mcontroller.canJump()
      and not mcontroller.liquidMovement()
      and not status.statPositive("activeMovementAbilities")
      and status.overConsumeResource("energy", self.dt * 10)
end

function refreshJumps()
  self.jumpsLeft = config.getParameter("multiJumpCount")
end

function startDash()
  self.vDirectionLocked = (not self.shiftHeld and self.vDirection == 0) and 1 or self.vDirection
  self.hDirectionLocked = self.hDirection
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
  animator.setAnimationState("dashing", "off")
  animator.setParticleEmitterActive("dashParticles", false)
end

function spawnSmoke()
  world.spawnProjectile("ivrpgdazinggas", {mcontroller.xPosition()+1, mcontroller.yPosition()+1}, entity.id(), {0,0}, false, {})
  world.spawnProjectile("ivrpgdazinggas", {mcontroller.xPosition()-1, mcontroller.yPosition()+1}, entity.id(), {0,0}, false, {})
  world.spawnProjectile("ivrpgdazinggas", {mcontroller.xPosition()+1, mcontroller.yPosition()-1}, entity.id(), {0,0}, false, {})
  world.spawnProjectile("ivrpgdazinggas", {mcontroller.xPosition()-1, mcontroller.yPosition()-1}, entity.id(), {0,0}, false, {})
end