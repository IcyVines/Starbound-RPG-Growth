require "/scripts/keybinds.lua"

function init()
  self.cooldownTimer = 0
  self.rechargeEffectTimer = 0

  self.grenadeCount = config.getParameter("grenades")
  self.cooldown = config.getParameter("cooldown")
  self.cost = config.getParameter("cost")
  self.damage = config.getParameter("damage")

  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=A82B1AFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)

  Bind.create("f", strike)
  --Bind.create("Down", test)
end

function strike()
  if self.cooldownTimer == 0 and not status.statPositive("activeMovementAbilities") and not world.pointTileCollision(tech.aimPosition()) and status.overConsumeResource("energy", self.cost) then
      self.cooldownTimer = self.cooldown
      status.addEphemeralEffect("soldiermissilestrikecooldown", self.cooldownTimer)
      spawnMissile()
  end
end

function spawnMissile()
  animator.playSound("spawn")
  self.cursor = tech.aimPosition()
  self.damageConfig = {
    power = self.damage
  }
  world.spawnProjectile("soldiermissile", self.cursor, entity.id(), {0, -1}, false, self.damageConfig)
end

function uninit()
  tech.setParentDirectives()
  status.removeEphemeralEffect("soldiermissilestrikecooldown")
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
