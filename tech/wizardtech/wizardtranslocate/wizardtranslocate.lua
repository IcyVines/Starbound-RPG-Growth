require "/scripts/keybinds.lua"

function init()
  self.dashCooldownTimer = 0
  self.rechargeEffectTimer = 0

  self.cost = config.getParameter("cost")
  self.dashMaxDistance = config.getParameter("dashDistance")
  self.dashCooldown = config.getParameter("dashCooldown")
  sb.logInfo("ConfigCooldown: " .. tostring(self.dashCooldown))
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=B880FCFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)

  Bind.create("g", translocate)
end

function translocate()
  --sb.logInfo("Cooldown: " .. tostring(self.dashCooldownTimer))
  if self.dashCooldownTimer == 0 and not status.statPositive("activeMovementAbilities") and status.overConsumeResource("energy", self.cost) then
    local projectileId = world.spawnProjectile(
        "invtransdisc",
        tech.aimPosition(),
        entity.id(),
        {0,0},
        false
      )
    --sb.logInfo("projectile created: " .. tostring(projectileId)) 
    if projectileId then
      world.callScriptedEntity(projectileId, "setOwnerId", entity.id())
      status.setStatusProperty("translocatorDiscId", projectileId)
      status.addEphemeralEffect("translocate")
      self.dashCooldownTimer = self.dashCooldown
    end
  end
end

function uninit()
  tech.setParentDirectives()
end

function update(args)
  if self.dashCooldownTimer > 0 then
    self.dashCooldownTimer = math.max(0, self.dashCooldownTimer - args.dt)
    if self.dashCooldownTimer == 0 then
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
