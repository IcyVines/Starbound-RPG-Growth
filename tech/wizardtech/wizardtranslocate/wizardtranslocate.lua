require "/scripts/ivrpgutil.lua"
require "/scripts/keybinds.lua"
require "/tech/ivrpgopenrpgui.lua"

function init()
  ivrpg_ttShortcut.initialize()
  self.dashCooldownTimer = 0
  self.rechargeEffectTimer = 0

  self.cost = config.getParameter("cost")
  self.dashMaxDistance = config.getParameter("dashDistance")
  self.dashCooldown = config.getParameter("dashCooldown")
  --sb.logInfo("ConfigCooldown: " .. tostring(self.dashCooldown))
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=B880FCFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)

  Bind.create("g", translocate)
end

function translocate()
  --sb.logInfo("Cooldown: " .. tostring(self.dashCooldownTimer))
  local isNotMissionWorld = ((world.terrestrial() or world.type() == "outpost" or world.type() == "scienceoutpost") and world.dayLength() ~= 100000) or (status.statPositive("admin") or status.statPositive("ivrpgucfourthwall"))
  -- local notThroughWalls = not world.lineTileCollision(tech.aimPosition(), mcontroller.position())
  local notThroughWalls = ivrpgHasPath(mcontroller, tech.aimPosition())
  if self.dashCooldownTimer == 0 and not status.statPositive("activeMovementAbilities") and (isNotMissionWorld or notThroughWalls) and status.overConsumeResource("energy", 1) then
    local agility = status.statusProperty("ivrpgagility", 0)
    local distance = world.magnitude(tech.aimPosition(), mcontroller.position())
    local costPercent = math.min(-(1.06^(distance*2-agility)+20.0)/100.0, -0.05)
    status.modifyResourcePercentage("energy", costPercent)
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
    status.setResourcePercentage("energyRegenBlock", 1.0)
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
