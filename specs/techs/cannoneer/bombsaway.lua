require "/scripts/keybinds.lua"
require "/scripts/vec2.lua"

function init()
  self.cost = config.getParameter("cost", 30)
  self.dashSpeed = config.getParameter("dashSpeed", 100)
  self.controlForce = config.getParameter("controlForce", 1000)
  self.cooldownTime = config.getParameter("cooldown", 1)
  self.aerialCooldownTime = config.getParameter("aerialCooldown", 1)
  self.cannonballSpeed = config.getParameter("cannonballSpeed", 50)
  self.power = config.getParameter("power", 20)
  self.multijumps = config.getParameter("multijumps", 2)
  self.wasGrounded = false
  self.aerial = false
  self.jumpsLeft = self.multijumps

  self.hDirection = 0
  self.cooldownTimer = self.cooldownTime
  self.aerialCooldownTimer = self.aerialCooldownTime
  self.rechargeTimer = 0
  self.vDirection = 0
  self.shift = false
end

function launch()
  getShootingDirection()
  if self.aerial then self.aerialCooldownTimer = self.aerialCooldownTime else self.cooldownTimer = self.cooldownTime end
  if self.hDirection == 0 and self.vDirection == 0 then self.hDirection = mcontroller.facingDirection() end
  animator.playSound("fire")
  animator.burstParticleEmitter("fireParticles")
  local power = self.power + status.statusProperty("ivrpgdexterity")
  world.spawnProjectile("ivrpgcannonball", mcontroller.position(), entity.id(), self.aimDirection or {self.hDirection, self.vDirection*2}, false, {power = power, speed = self.cannonballSpeed})
  mcontroller.setYVelocity(0)
  mcontroller.controlApproachVelocity(vec2.mul(self.aimDirection or {self.hDirection, self.vDirection*2}, -self.dashSpeed), self.controlForce * 1.2)
end

function reset()
  tech.setParentDirectives()
end

function uninit()
  reset()
end

function update(args)
  -- Find Directional Input
  directionalInput(args)

  if ((self.shift and self.cooldownTimer == 0 and not self.aerial) or (self.aerial and self.jumpsLeft > 0 and self.aerialCooldownTimer == 0)) and self.jumping and (not status.statPositive("activeMovementAbilities")) and status.overConsumeResource("energy", self.aerial and 10 or 40) then
    launch()
  else
    reset()
  end

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(0, self.cooldownTimer - args.dt)
    if self.cooldownTimer ==  0 then
      self.rechargeTimer = 0.1
      animator.playSound("recharge")
    end
  end

  if self.rechargeTimer > 0 then
    self.rechargeTimer = math.max(0, self.rechargeTimer - args.dt)
    tech.setParentDirectives("?fade=32ffb4=0.15")
    if self.rechargeTimer == 0 then
      tech.setParentDirectives()
    end
  end

  self.aerialCooldownTimer = math.max(0, self.aerialCooldownTimer - args.dt)
  if not self.aerial then self.jumpsLeft = self.multijumps end

  mcontroller.controlModifiers({jumpingSuppressed = self.shift})
end

function getShootingDirection()
  if self.aerial then
    self.vDirection = -1
    self.hDirection = -1 * self.hDirection
    self.aimDirection = false
    self.jumpsLeft = self.jumpsLeft - 1
  end

  if self.shift then
    self.aimDirection = world.distance(tech.aimPosition(), mcontroller.position())
  else
    self.aimDirection = false
  end
end

function directionalInput(args)
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
  if args.moves["run"] then self.shift = false else self.shift = true end
  if args.moves["jump"] and not self.lastJump then self.jumping = true else self.jumping = false end
  self.lastJump = args.moves["jump"]

  if mcontroller.onGround() then self.wasGrounded = true end
  self.aerial = not (mcontroller.onGround() or mcontroller.liquidMovement())
  if self.aerial and self.wasGrounded then
    self.wasGrounded = false
    self.aerialCooldownTimer = 0.2
  end
end
