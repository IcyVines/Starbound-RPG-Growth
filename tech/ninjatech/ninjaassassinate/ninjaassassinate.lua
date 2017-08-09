require "/scripts/keybinds.lua"

function init()
  self.dashCooldownTimer = 0
  self.rechargeEffectTimer = 0

  self.cost = config.getParameter("cost")
  self.dashMaxDistance = config.getParameter("dashDistance")
  self.dashCooldown = config.getParameter("dashCooldown")

  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=7C1616FF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)

  self.vanishTimer = 0
  self.vanishTime = config.getParameter("vanishTime", 3)
  self.vanished = false

  Bind.create("Up", assassinate)
end

function assassinate()
  --sb.logInfo("Cooldown: " .. tostring(self.dashCooldownTimer))
  if self.dashCooldownTimer == 0 and not status.statPositive("activeMovementAbilities") and status.overConsumeResource("energy", self.cost) then
    --sb.logInfo("projectile created: " .. tostring(projectileId))
      self.vanishTimer = self.vanishTime
      self.vanished = true
      status.addEphemeralEffect("invisible", math.huge)
      status.setPersistentEffects("ninjaassassinate", {
        {stat = "invulnerable", amount = 1},
        {stat = "activeMovementAbilities", amount = 1}
      })
  end
end

function uninit()
  tech.setParentDirectives()
end

function update(args)

  --status.clearPersistentEffects("ninjaassassinate")

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

  if self.vanished then
    if self.vanishTimer > 0 then
      self.vanishTimer = math.max(0, self.vanishTimer - args.dt)
      mcontroller.setVelocity({0,0})
      mcontroller.controlModifiers({
        speedModifier = 0,
        airJumpModifier = 0
      })
    else
      mcontroller.setVelocity({0,0})
      mcontroller.controlModifiers({
        speedModifier = 0,
        airJumpModifier = 0
      })
      local projectileId = world.spawnProjectile(
        "invtransdisc",
        tech.aimPosition(),
        entity.id(),
        {0,0},
        false
      )
      if projectileId then
        world.callScriptedEntity(projectileId, "setOwnerId", entity.id())
        status.setStatusProperty("translocatorDiscId", projectileId)
        status.addEphemeralEffect("ninjatranslocate")
      end
      self.vanished = false
      status.clearPersistentEffects("ninjaassassinate")
      status.removeEphemeralEffect("invisible")
      self.dashCooldownTimer = self.dashCooldown
    end
  end

end
