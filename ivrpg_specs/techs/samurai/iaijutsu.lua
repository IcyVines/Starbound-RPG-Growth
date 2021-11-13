require "/scripts/keybinds.lua"
require "/tech/doubletap.lua"
require "/scripts/vec2.lua"

function init()
  self.id = entity.id()
  self.timer = 0
  self.lastPosition = mcontroller.position()

  self.dashControlForce = config.getParameter("dashControlForce")
  self.dashSpeedModifier = config.getParameter("dashSpeedModifier")
  self.groundOnly = config.getParameter("groundOnly")
  self.stopAfterDash = config.getParameter("stopAfterDash")
  self.dashDirection = nil

  self.trailProjectiles = {}

  animator.setParticleEmitterOffsetRegion("swordCharge", mcontroller.boundBox())

  self.doubleTap = DoubleTap:new({"left", "right"}, config.getParameter("maximumDoubleTapTime"), function(dashKey)
      local direction = dashKey == "left" and -1 or 1
      if not self.dashDirection
          and groundValid()
          and mcontroller.facingDirection() == direction
          and not mcontroller.crouching()
          and not dashBlocked()
          and not status.resourceLocked("energy")
          and not status.statPositive("activeMovementAbilities") then

        startDash(direction)
      end
    end)
end

function uninit()
  status.clearPersistentEffects("movementAbility")
  status.clearPersistentEffects("ivrpgiaijutsu")
  tech.setToolUsageSuppressed(false)
  tech.setParentDirectives()
end

function update(args)
  
  self.doubleTap:update(args.dt, args.moves)

  if self.dashDirection and self.timer > 0 then

    mcontroller.controlModifiers({jumpingSuppressed = true})
    self.timer = self.timer - args.dt
    mcontroller.setVelocity({self.dashDirection * self.dashSpeedModifier, -200})
    mcontroller.controlMove(self.dashDirection)
    table.insert(self.trailProjectiles,
      world.spawnProjectile("ivrpgiaijutsutrailexplosion", mcontroller.position(), self.id, {0,0}, false,
        {timeToLive = self.timer, powerMultiplier = 1 + status.statusProperty("ivrpgdexterity", 0) / 25, power = self.energyUsage}
      )
    )
    --animator.setParticleEmitterActive("trail", true)

  end

  if self.dashDirection and ((self.timer <= 0) or math.abs(world.distance(self.lastPosition, mcontroller.position())[1]) == 0) then
    endDash(self.dashDirection)
  end

  self.lastPosition = mcontroller.position()

end

function groundValid()
  return mcontroller.groundMovement() or not self.groundOnly
end

function dashBlocked()
  return mcontroller.velocity()[1] == 0
end

function startDash(direction)
  self.dashDirection = direction
  self.timer = 0.2
  self.energyUsage = status.resource("energy")
  status.overConsumeResource("energy", status.resourceMax("energy"))
  self.projectile = world.spawnProjectile("ivrpgsamuraitrail", mcontroller.position(), self.id, mcontroller.velocity(), true, {speed = 0, powerMultiplier = 1 + status.statusProperty("ivrpgdexterity", 0) / 25, power = self.energyUsage})
  --world.spawnProjectile("ivrpgiaijutsuslash", mcontroller.position(), self.id, {direction,0}, true, {speed = 0, powerMultiplier = 1 + status.statusProperty("ivrpgdexterity", 0) / 25, power = self.energyUsage})
  status.setPersistentEffects("movementAbility", {
    {stat = "activeMovementAbilities", amount = 1},
    {stat = "grit", amount = 1},
    {stat = "invulnerable", amount = 1}
  })
  --status.addEphemeralEffect("crusaderbashattack", math.huge)
  tech.setToolUsageSuppressed(true)
  animator.setParticleEmitterActive("swordCharge", true)
  --animator.playSound(self.weapon.elementalType.."TrailDashCharge")
  animator.playSound("unsheathe")

  animator.setFlipped(self.dashDirection == -1)
end

function endDash(direction)
  status.clearPersistentEffects("movementAbility")
  --status.removeEphemeralEffect("crusaderbashattack")
  tech.setToolUsageSuppressed(false)
  animator.setParticleEmitterActive("swordCharge", false)
  animator.setParticleEmitterActive("trail", false)
  animator.playSound("trailDashFire")
  world.spawnProjectile("ivrpgiaijutsuslash", vec2.add(mcontroller.position(), {direction * 2, 0}), self.id, {direction,0}, false, {speed = 0, powerMultiplier = 1 + status.statusProperty("ivrpgdexterity", 0) / 25, power = self.energyUsage})

  if self.projectile then world.callScriptedEntity(self.projectile, "die") end
  self.timer = 0

  if self.stopAfterDash then
    mcontroller.setVelocity({0,0})
  end

  for _,projectile in ipairs(self.trailProjectiles) do
    world.callScriptedEntity(projectile, "die")
  end

  self.trailProjectiles = {}

  self.dashDirection = nil
end