require "/scripts/vec2.lua"
require "/scripts/keybinds.lua"

function init()
  self.durationBonus = 0
  self.duration = config.getParameter("duration")
  self.cooldown = config.getParameter("cooldown")
  self.cost = config.getParameter("cost")
  self.cooldownTimer = 0
  self.active = false
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=80FC9FFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)
  self.rechargeEffectTimer = 0

  Bind.create("f", magicShield)
end

function magicShield()
  if self.active then
    self.active = false
    status.removeEphemeralEffect("wizardshield")
    if self.cooldownTimer > self.cooldown then
      self.cooldownTimer = 2*self.cooldown - self.cooldownTimer
    end
  else
    if self.cooldownTimer <= 0 and status.overConsumeResource("energy", self.cost) then
      self.active = true
      status.addEphemeralEffect("wizardshield", self.duration)
      self.cooldownTimer = self.cooldown + self.duration
    end
  end
end

function update(args)
  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(0, self.cooldownTimer - args.dt)
    if self.cooldownTimer <= self.cooldown then
      self.active = false
      status.removeEphemeralEffect("wizardshield")
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

function uninit()
  status.removeEphemeralEffect("wizardshield")
end