require "/scripts/keybinds.lua"

function init()
  self.cost = config.getParameter("cost")
  self.dashMaxDistance = config.getParameter("dashDistance")
  self.dashCooldown = config.getParameter("dashCooldown")
  self.healthDamageCooldownTime = config.getParameter("healthDamageCooldownTime")
  self.teleportTime = config.getParameter("teleportTime")
  self.pauseTime = config.getParameter("pauseTime")
  self.teleportsBeforeDamage = config.getParameter("teleportsBeforeDamage")
  self.healthDamageFactor = config.getParameter("healthDamageFactor")
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=961e46FF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)

  self.timer = 0
  self.pauseTimer = 0
  self.cooldownTimer = 0
  self.rechargeEffectTimer = 0
  self.healthDamageTimer = 0
  self.teleportCount = 0

  self.hDirection = 0
  self.vDirection = 0
  self.shift = false
  
  Bind.create("jumping", prepareFlashStep)
end

function prepareFlashStep()
  if self.cooldownTimer ~= 0 or (self.hDirection == 0 and self.vDirection == 0) or status.resourceLocked("energy") or status.statPositive("activeMovementAbilities") or self.shift then return end
  local currentPosition = mcontroller.position()
  self.teleportTarget = currentPosition
  local diagonal = math.abs(self.hDirection*self.vDirection) * math.sqrt(2)
  local agility = status.statusProperty("ivrpgagility", 1)
  diagonal = diagonal == 0 and 1 or diagonal
  self.teleportTarget[1] = currentPosition[1] + (self.hDirection * (self.dashMaxDistance + agility / 10) / diagonal)
  self.teleportTarget[2] = currentPosition[2] + (self.vDirection * (self.dashMaxDistance + agility / 10) / diagonal)
  local intelligence = status.statusProperty("ivrpgintelligence", 1)
  local cost = self.cost - math.min(intelligence / 5, 15)
  local healthCost = (self.teleportCount > self.teleportsBeforeDamage and not status.statPositive("admin")) and (self.healthDamageFactor ^ (self.teleportCount - self.teleportsBeforeDamage)) or 0
  if status.consumeResource("health", healthCost) and status.overConsumeResource("energy", cost) then
    flashStep()
  end
end

function flashStep()
  animator.setAnimationState("blink", "blinkout")
  tech.setParentDirectives("?multiply=ffffff00")
  animator.playSound("activate")
  self.timer = self.teleportTime
  self.cooldownTimer = self.teleportTime + self.dashCooldown
  if self.healthDamageTimer > 0 then
    self.teleportCount = self.teleportCount + 1
  end
  self.healthDamageTimer = self.healthDamageCooldownTime
end

function teleport()
  mcontroller.setPosition(self.teleportTarget)
  tech.setParentDirectives("")
  animator.burstParticleEmitter("translocate")
  animator.setAnimationState("blink", "blinkin")
  self.pauseTimer = self.pauseTime
end

function uninit()
  tech.setParentDirectives()
end

function update(args)
  -- Find Directional Input
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
  self.shift = not args.moves["run"]

  mcontroller.controlModifiers({jumpingSuppressed = not self.shift})

  if self.pauseTimer > 0 then
    self.pauseTimer = math.max(self.pauseTimer - args.dt, 0)
    mcontroller.setVelocity({0,0})
  end

  if self.timer > 0 then
    self.timer = math.max(self.timer - args.dt, 0)
    mcontroller.setVelocity({0,0})
    if self.timer == 0 then
      teleport()
    end
  end

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(self.cooldownTimer - args.dt, 0)
    status.setResourcePercentage("energyRegenBlock", 1.0)
  end

  if self.healthDamageTimer > 0 then
    self.healthDamageTimer = math.max(self.healthDamageTimer - args.dt, 0)
    if self.healthDamageTimer == 0 then
      self.teleportCount = 0
      tech.setParentDirectives(self.rechargeDirectives)
      animator.playSound("recharge")
      self.rechargeEffectTimer = self.rechargeEffectTime
    end
  end

  if self.rechargeEffectTimer > 0 then
    self.rechargeEffectTimer = math.max(self.rechargeEffectTimer - args.dt, 0)
    if self.rechargeEffectTimer == 0 then
      tech.setParentDirectives()
    end
  end

end
