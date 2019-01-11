require "/scripts/keybinds.lua"
require "/scripts/vec2.lua"

function init()
  self.energyCost = config.getParameter("energyCost")
  self.dashSpeedModifier = config.getParameter("dashSpeedModifier")
  self.stopAfterDash = config.getParameter("stopAfterDash")
  self.cooldownTime = config.getParameter("cooldownTime")
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=b79d5bFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)
  self.damageUpdate = 5
  self.cooldownTimer = 0
  self.rechargeEffectTimer = 0
  self.timer = 0
  self.endTimer = 0
  self.dashTimer = 0
  self.travelPoint = nil
  self.damageGivenUpdate = 5
  self.id = entity.id()
  Bind.create("g", rush)
end

function rush()
  if self.timer == 0 and self.dashTimer == 0 and self.cooldownTimer == 0 then
    self.travelPoint = tech.aimPosition()
    local targetIds = world.entityQuery(self.travelPoint, 3, {
      withoutEntityId = self.id,
      includedTypes = {"creature"}
    })
    for i,id in ipairs(targetIds) do
      if world.entityCanDamage(self.id, id) and (not world.pointCollision(world.entityPosition(id), {"block"})) and status.overConsumeResource("energy", self.energyCost) then
        animator.playSound("activate")
        self.timer = 1
        self.targetId = id
      end
    end
  end
end

function updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.damageSourceKind == "rushelectricplasma" then
        if notification.healthLost > 0 and (world.entityHealth(notification.targetEntityId) and notification.healthLost >= world.entityHealth(notification.targetEntityId)[1]) then
          status.modifyResourcePercentage("energy", 0.2)
          status.setResourceLocked("energy", false)
        end
      end
    end
  end
end

function setTravelBuffs(velocity)
  mcontroller.controlModifiers({
    jumpingSuppressed = true,
    movementSuppressed = true
  })
  status.setResourcePercentage("energyRegenBlock", 1.0)
  mcontroller.controlParameters({collisionEnabled = false})
  status.setPersistentEffects("ivrpgrush", {
    {stat = "invulnerable", amount = 1},
    {stat = "activeMovementAbilities", amount = 1}
  })
  mcontroller.setVelocity(velocity)
  tech.setToolUsageSuppressed(true)
  tech.setParentState("Fly")
end

function update(args)
  updateDamageGiven()

  if self.timer > 0 then
    setTravelBuffs({0,0})
    tech.setParentDirectives(string.format("?multiply=BE9632%02X", math.floor(self.timer*200 + 55)))
    self.timer = math.max(self.timer - args.dt, 0)
    if self.timer == 0 then
      startDash()
    end
  end

  if self.dashTimer > 0 then
    setTravelBuffs(vec2.mul(self.direction, -self.dashSpeedModifier))
    animator.setFlipped(mcontroller.facingDirection() == -1)
    self.dashTimer = math.max(0, self.dashTimer - args.dt)
    if self.dashTimer == 0 then
      endDash()
    end
  end

  if self.endTimer > 0 then
    setTravelBuffs({0,0})
    self.endTimer = math.max(0, self.endTimer - args.dt)
    if self.endTimer == 0 then
      reset(true)
    end
  end

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(self.cooldownTimer - args.dt, 0)
    if self.cooldownTimer == 0 then
      tech.setParentDirectives(self.rechargeDirectives)
      animator.playSound("recharge")
      self.rechargeEffectTimer = self.rechargeEffectTime
    end
  end

  if self.rechargeEffectTimer > 0 then
    self.rechargeEffectTimer = math.max(self.rechargeEffectTimer - args.dt, 0)
    if self.rechargeEffectTimer == 0 then
      tech.setParentDirectives()
    end
  end

end

function startDash()
  local position = world.entityPosition(self.targetId)
  if position and not world.pointCollision(position, {"block"}) then
    self.travelPoint = position
  end
  self.direction = world.distance(mcontroller.position(), self.travelPoint)
  self.dashTimer = vec2.mag(self.direction) / self.dashSpeedModifier
  self.direction = vec2.norm(self.direction)
  animator.setAnimationState("dashing", "on")
  animator.setParticleEmitterActive("dashParticles", true)
end

function endDash()
  mcontroller.setVelocity({0, 0})
  self.cooldownTimer = self.cooldownTime
  self.endTimer = 0.2
  spawnExplosion()
  reset(false)
end

function spawnExplosion()
  agility = status.statusProperty("ivrpgagility", 0) / 2
  dexterity = status.statusProperty("ivrpgdexterity", 0) / 2
  world.spawnProjectile("ivrpgrushexplosionconfig", mcontroller.position(), self.id, {0,0}, true, {power = 25 + dexterity + agility})
end

function reset(clearPersistentEffect)
  if clearPersistentEffect then
    status.clearPersistentEffects("ivrpgrush")
  end
  animator.setAnimationState("dashing", "off")
  animator.setParticleEmitterActive("dashParticles", false)
  tech.setParentDirectives()
  tech.setParentState()
  tech.setToolUsageSuppressed(false)
end

function uninit()
  reset(true)
end