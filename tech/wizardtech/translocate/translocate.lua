function init()
  self.dashCooldownTimer = 0
  self.rechargeEffectTimer = 0

  self.dashMaxDistance = config.getParameter("dashDistance")
  self.dashCooldown = config.getParameter("dashCooldown")
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=CCCCFFFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)

  Bind.create("f", translocate)

end

function translocate()
  if self.dashCooldownTimer == 0 then
    local projectileId = world.spawnProjectile(
        "translocatordisc",
        tech.aimPosition(),
        entity.id(),
        {0,0},
        false,
        {}
      )
    if projectileId then
      storage.projectileId = projectileId
      world.callScriptedEntity(projectileId, "setOwnerId", activeItem.ownerEntityId())
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
