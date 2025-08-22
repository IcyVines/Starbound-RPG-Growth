require "/scripts/keybinds.lua"
require "/tech/ivrpgopenrpgui.lua"

function init()
  ivrpg_ttShortcut.initialize()
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

  Bind.create("g", assassinate)
end

function assassinate()
  if self.dashCooldownTimer == 0 and not status.statPositive("activeMovementAbilities") and status.resource("energy") > 0 then--status.overConsumeResource("energy", self.cost) then
 	self.vanishTimer = self.vanishTime
    self.vanished = true
    status.addEphemeralEffect("invisible", math.huge)
    tech.setToolUsageSuppressed(true)
    status.setPersistentEffects("ninjaassassinate", {
        {stat = "invulnerable", amount = 1},
        {stat = "lavaImmunity", amount = 1},
        {stat = "poisonStatusImmunity", amount = 1},
        {stat = "tarImmunity", amount = 1},
        {stat = "waterImmunity", amount = 1},
        {stat = "activeMovementAbilities", amount = 1}
      })
	local projectileId = world.spawnProjectile(
		"ninjasmoke",
		{mcontroller.xPosition(), mcontroller.yPosition()-2},
        entity.id(),
        {0,0},
        false
     )
  end
end

function uninit()
  tech.setParentDirectives()
  status.clearPersistentEffects("ninjaassassinate")
  status.removeEphemeralEffect("invisible")
  status.removeEphemeralEffect("ninjaassassinatecooldown")
  tech.setToolUsageSuppressed(false)
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
      tech.setToolUsageSuppressed(false)
      status.clearPersistentEffects("ninjaassassinate")
      status.removeEphemeralEffect("invisible")
      self.dashCooldownTimer = self.dashCooldown
      status.addEphemeralEffect("ninjaassassinatecooldown", self.dashCooldownTimer)
    end
  end

end
