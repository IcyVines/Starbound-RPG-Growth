require "/scripts/keybinds.lua"
require "/scripts/vec2.lua"

function init()
  self.cost = config.getParameter("cost", 30)
  self.cooldownTime = config.getParameter("cooldown", 1)
  self.cannonballSpeed = config.getParameter("cannonballSpeed", 50)
  self.power = config.getParameter("power", 20)

  self.hDirection = 0
  self.cooldownTimer = self.cooldownTime
  self.rechargeTimer = 0
  self.vDirection = 0
  self.shift = false
  animator.setSoundVolume("fire", 0.5)

  Bind.create("f", launch)
end

function launch()
  if self.cooldownTimer ~= 0 or status.statPositive("activeMovementAbilities") or not status.overConsumeResource("energy", 40) then return end
  getShootingDirection()
  if self.hDirection == 0 and self.vDirection == 0 then self.hDirection = mcontroller.facingDirection() end
  animator.playSound("fire")
  animator.burstParticleEmitter("fireParticles")
  local power = self.power + status.statusProperty("ivrpgdexterity")
  world.spawnProjectile("ivrpg_mitsunosnuke", mcontroller.position(), entity.id(), self.aimDirection or {self.hDirection, self.vDirection*2}, false, {power = power, speed = self.cannonballSpeed})
  self.cooldownTimer = self.cooldownTime
  --mcontroller.setYVelocity(0)
  --mcontroller.controlApproachVelocity(vec2.mul(self.aimDirection or {self.hDirection, self.vDirection*2}, -self.dashSpeed), self.controlForce * 1.2)
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

end

function getShootingDirection()
  self.aimDirection = world.distance(tech.aimPosition(), mcontroller.position())
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
end
