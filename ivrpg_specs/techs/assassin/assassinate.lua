require "/scripts/keybinds.lua"
require "/scripts/vec2.lua"
require "/tech/ivrpgopenrpgui.lua"
require "/tech/ninjatech/ninjaassassinate/ninjaassassinate.lua"

oldInit = init

function init()
  oldInit()
  message.setHandler("ivrpg_assassinateFailed", function(_, _)
    status.modifyResourcePercentage("energy", -1)
  end)
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

  if self.vanished then
    mcontroller.setVelocity({0,0})
    mcontroller.controlParameters({
      gravityEnabled = false
    })
    mcontroller.controlModifiers({
      speedModifier = 0,
      airJumpModifier = 0
    })
    if self.vanishTimer > 0 then
      self.vanishTimer = math.max(0, self.vanishTimer - args.dt)
      status.setResourcePercentage("energyRegenBlock", 1.0)
    else
      local distance = world.distance(tech.aimPosition(), mcontroller.position())
      distance = vec2.mag(distance) <= 10 and distance or vec2.mul(vec2.norm(distance), 10)
      local projectileId = world.spawnProjectile(
        "invtransdisc",
        vec2.add(mcontroller.position(), distance or {0,0}),
        entity.id(),
        {0,0},
        false
      )
      if projectileId then
        world.callScriptedEntity(projectileId, "setOwnerId", entity.id())
        status.setStatusProperty("translocatorDiscId", projectileId)
        status.addEphemeralEffect("ivrpg_assassinateteleport")
      end
      self.vanished = false
      tech.setToolUsageSuppressed(false)
      status.clearPersistentEffects("ninjaassassinate")
      status.removeEphemeralEffect("invisible")
      self.dashCooldownTimer = self.dashCooldown
      status.addEphemeralEffect("ivrpg_assassinatecooldown", self.dashCooldownTimer)
    end
  end

end

function uninit()
  tech.setParentDirectives()
  status.clearPersistentEffects("ninjaassassinate")
  status.removeEphemeralEffect("invisible")
  status.removeEphemeralEffect("ivrpg_assassinatecooldown")
  tech.setToolUsageSuppressed(false)
end