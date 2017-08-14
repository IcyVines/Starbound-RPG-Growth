require "/scripts/keybinds.lua"

function init()
  self.cooldownTimer = 0
  self.rechargeEffectTimer = 0

  self.foodGain = config.getParameter("foodGain")
  self.cooldown = config.getParameter("cooldown")

  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=B7862CFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)

  Bind.create("Up", eat)
  Bind.create("Down", test)
end

function eat()
  if self.cooldownTimer == 0 and not status.statPositive("activeMovementAbilities") then
      self.cooldownTimer = self.cooldown
      status.addEphemeralEffect("soldiermre", self.cooldown)
      animator.playSound("eat")
      status.modifyResourcePercentage("food", self.foodGain/100)
  end
end

function test()
  status.modifyResourcePercentage("food", -2*self.foodGain/100)
end

function uninit()
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
