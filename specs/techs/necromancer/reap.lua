require "/scripts/keybinds.lua"

function init()
  self.healthCost = config.getParameter("healthCost", 5)
  self.cooldown = config.getParameter("cooldown", 5)
  self.cooldownTimer = 0
  self.rechargeTimer = 0
  self.mobCharge = 0
  self.damageGivenUpdate = 5
  self.id = entity.id()
  Bind.create("f", reap)

  message.setHandler("enemyReaped", function(_, _)
    self.mobCharge = self.mobCharge + 1
  end)

end

function uninit()
  tech.setParentDirectives()
end

function reap()
  if self.cooldownTimer == 0 and (not status.statPositive("activeMovementAbilities")) and self.shiftHeld and self.mobCharge > 0 then
    self.cooldownTimer = self.cooldown
    animator.playSound("reap")
    world.spawnMonster("bonepteropod", mcontroller.position(), {
      damageTeamType = "friendly",
      level = self.mobCharge + 1
    })
    self.mobCharge = 0
    return
  end

  if self.cooldownTimer == 0 and (not status.statPositive("activeMovementAbilities")) and status.consumeResource("health", self.healthCost) then
    self.cooldownTimer = self.cooldown
    animator.playSound("reap")
    local intelligence = world.entityCurrency(self.id, "intelligencepoint")
    local damageConfig = {
      power = intelligence^0.75 + 9
    }
    world.spawnProjectile("ivrpgreapexplosion", {mcontroller.xPosition(), mcontroller.yPosition() - 0.25}, self.id, nil, true, damageConfig)
  end
end

function update(args)
  self.shiftHeld = not args.moves["run"]

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(self.cooldownTimer - args.dt, 0)
    if self.cooldownTimer == 0 then
      animator.playSound("recharge")
      self.rechargeTimer = 0.1
      tech.setParentDirectives("?fade=000000=0.25")
    end
  end

  if self.rechargeTimer > 0 then
    self.rechargeTimer = math.max(self.rechargeTimer - args.dt, 0)
    if self.rechargeTimer == 0 then
      tech.setParentDirectives()
    end
  end
end