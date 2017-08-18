require "/scripts/keybinds.lua"

function init()
  self.cooldownTimer = 0
  self.rechargeEffectTimer = 0

  self.cooldown = config.getParameter("cooldown")
  self.duration = config.getParameter("duration")

  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=A85A16FF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)

  Bind.create("g", marksman)
end

function marksman()
  if self.cooldownTimer == 0 and not status.statPositive("activeMovementAbilities") then
    self.cooldownTimer = self.cooldown + self.duration
    status.addEphemeralEffect("soldierfocus", self.duration)
  elseif self.cooldownTimer > self.cooldown then
    self.cooldownTimer = 2*self.cooldown - self.cooldownTimer
    status.removeEphemeralEffect("soldierfocus")
  end
end

function uninit()
  status.removeEphemeralEffect("soldierfocus")
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

end