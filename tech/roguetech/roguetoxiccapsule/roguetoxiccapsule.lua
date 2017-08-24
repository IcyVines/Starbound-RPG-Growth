require "/scripts/vec2.lua"
require "/scripts/keybinds.lua"

function init()
  self.durationBonus = 0
  self.duration = config.getParameter("duration")
  self.cooldown = config.getParameter("cooldown")
  self.cost = config.getParameter("cost")
  self.cooldownTimer = 0
  self.active = false
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=00FF3FFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)
  self.rechargeEffectTimer = 0

  Bind.create("f", toxicCapsule)
end

function toxicCapsule()
  if self.active then
    self.active = false
    status.removeEphemeralEffect("roguecapsule")
    spawnPoison(self.cooldown + self.duration - self.cooldownTimer)
    status.addEphemeralEffect("roguetoxiccapsulecooldown", self.cooldownTimer)
  else
    if self.cooldownTimer <= 0 and status.overConsumeResource("energy", self.cost) then
      self.active = true
      status.addEphemeralEffect("roguecapsule", self.duration)
      self.cooldownTimer = self.cooldown + self.duration
    end
  end
end

function update(args)
  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(0, self.cooldownTimer - args.dt)
    if self.cooldownTimer <= self.cooldown and self.active then
      self.active = false
      status.removeEphemeralEffect("roguecapsule")
      status.addEphemeralEffect("roguetoxiccapsulecooldown", self.cooldownTimer)
    end
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
end

function spawnPoison(timeMult)
  self.power = status.stat("powerMultiplier")
  self.damageConfig = {
    power = self.power*(1.4^timeMult),
    speed = 4
  }
  world.spawnProjectile("poisontrail", {mcontroller.xPosition(), mcontroller.yPosition()}, entity.id(), {1,0}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", {mcontroller.xPosition(), mcontroller.yPosition()}, entity.id(), {0.87,-0.5}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", {mcontroller.xPosition(), mcontroller.yPosition()}, entity.id(), {0.5,-0.87}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", {mcontroller.xPosition(), mcontroller.yPosition()}, entity.id(), {0,-1}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", {mcontroller.xPosition(), mcontroller.yPosition()}, entity.id(), {-0.5,-0.87}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", {mcontroller.xPosition(), mcontroller.yPosition()}, entity.id(), {-0.87,-0.5}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", {mcontroller.xPosition(), mcontroller.yPosition()}, entity.id(), {-1,0}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", {mcontroller.xPosition(), mcontroller.yPosition()}, entity.id(), {-0.87,0.5}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", {mcontroller.xPosition(), mcontroller.yPosition()}, entity.id(), {-0.5,0.87}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", {mcontroller.xPosition(), mcontroller.yPosition()}, entity.id(), {0,1}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", {mcontroller.xPosition(), mcontroller.yPosition()}, entity.id(), {0.5,0.87}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", {mcontroller.xPosition(), mcontroller.yPosition()}, entity.id(), {0.87,0.5}, false, self.damageConfig)
end

function uninit()
  status.removeEphemeralEffect("roguecapsule")
  status.removeEphemeralEffect("roguetoxiccapsulecooldown")
end