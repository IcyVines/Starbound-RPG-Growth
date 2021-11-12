require "/scripts/keybinds.lua"
require "/tech/soldiertech/soldiermarksman/soldiermarksman.lua"

function marksman()
  if self.cooldownTimer == 0 and not status.statPositive("activeMovementAbilities") and mcontroller.groundMovement() then
    self.cooldownTimer = self.cooldown + self.duration
    status.addEphemeralEffect("ivrpgidealshotstatus", self.duration)
    tech.setParentState("Duck")
  elseif self.cooldownTimer > self.cooldown then
    self.cooldownTimer = 2*self.cooldown - self.cooldownTimer
    tech.setParentState()
    status.addEphemeralEffect("ivrpgidealshotcooldown", self.cooldownTimer)
    status.removeEphemeralEffect("ivrpgidealshotstatus")
  end
end

function uninit()
  status.removeEphemeralEffect("ivrpgidealshotstatus")
  status.removeEphemeralEffect("ivrpgidealshotcooldown")
  tech.setParentState()
  tech.setParentDirectives()
end

function update(args)

  updateDamageTaken()

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(0, self.cooldownTimer - args.dt)
    if self.cooldownTimer == 0 then
      self.cooldownActive = false
      self.rechargeEffectTimer = self.rechargeEffectTime
      tech.setParentDirectives(self.rechargeDirectives)
      animator.playSound("recharge")
    elseif self.cooldownTimer <= self.cooldown and not self.cooldownActive then
      self.cooldownActive = true
      tech.setParentState()
      status.addEphemeralEffect("ivrpgidealshotcooldown", self.cooldownTimer)
    end
  end

  if self.rechargeEffectTimer > 0 then
    self.rechargeEffectTimer = math.max(0, self.rechargeEffectTimer - args.dt)
    if self.rechargeEffectTimer == 0 then
      tech.setParentDirectives()
    end
  end

end

function expire()
  status.removeEphemeralEffect("ivrpgidealshotstatus")
  animator.playSound("break")
  self.cooldownTimer = self.cooldown
  tech.setParentState()
  status.addEphemeralEffect("ivrpgidealshotcooldown", self.cooldownTimer)
end

function updateDamageTaken()
  local notifications = nil
  notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate or 3)
  if notifications and self.cooldownTimer > self.cooldown then
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 then
        expire()
      end
    end
  end
end