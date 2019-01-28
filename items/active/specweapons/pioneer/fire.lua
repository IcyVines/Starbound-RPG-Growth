require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/interp.lua"
require "/scripts/ivrpgutil.lua"

-- Base gun fire ability
GunFire = WeaponAbility:new()

function GunFire:init()
  self.weapon:setStance(self.stances.idle)
  self.movementParams = mcontroller.baseParameters()
  self.shieldPoly = config.getParameter("shieldPoly", {})
  self.cooldownTimer = self.fireTime
  self.inLiquid = false
  self.liquidTimer = 0
  self.active = false
  self.weapon.shieldId = false
  self.knockbackDamageSource = {
    poly = self.shieldPoly,
    damage = 0,
    damageType = "Knockback",
    sourceEntity = activeItem.ownerEntityId(),
    team = activeItem.ownerTeam(),
    knockback = 20,
    rayCheck = true,
    damageRepeatTimeout = 0.25
  }

  animator.setSoundVolume("liquid", 0.6, 0)
  animator.setSoundVolume("fire", 0.8, 0)

  self.damageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.hitType == "ShieldHit" then
        if status.resourcePositive("perfectBlock") then
          animator.playSound("block")
        elseif status.resourcePositive("shieldStamina") then
          animator.playSound("block")
        end
        return
      end
    end
  end)

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end

end

function GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.dt = dt

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  self.liquidTimer = math.max(0, self.liquidTimer - self.dt)

  if self.active then
    self.damageListener:update()
    if not status.resourcePositive("shieldStamina") then
      reset()
      self.active = false
      self.cooldownTimer = self.fireTime
    end
    self:bubbleEffects(shiftHeld)
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy") 
    and not self.active then

    if status.overConsumeResource("energy", self:energyPerShot()) then
      reset()
      self.active = false
      self:setState(self.fire)
    end
  end

  status.setPersistentEffects("ivrpgwnautilus", {
    {stat = "fireResistance", amount = 0.60},
    {stat = "powerMultiplier", effectiveMultiplier = 1.2},
  })

  if (not self.active) and self.weapon.shieldId then
    popBubble()
  end

  incorrectWeapon()
end

function GunFire:fire()
  self.weapon:setStance(self.stances.fire)

  animator.playSound("fire")

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration, function()
      status.overConsumeResource("energy", self.dt*self:energyPerShot())
    end)
  end

  self:setState(self.shield)
end

function GunFire:shield()
  status.modifyResourcePercentage("shieldStamina", 1)
  status.setPersistentEffects(activeItem.hand().."Shield", {
    {stat = "shieldHealth", amount = status.stat("maxHealth")},
    { stat = "fireStatusImmunity", amount = 1 },
    { stat = "poisonStatusImmunity", amount = 1 },
    { stat = "electricStatusImmunity", amount = 1 },
    { stat = "iceStatusImmunity", amount = 1 },
    { stat = "breathProtection", amount = 1 },
    { stat = "biomecoldImmunity", amount = 1 },
    { stat = "ffextremecoldImmunity", amount = 1 },
    { stat = "biomeradiationImmunity", amount = 1 },
    { stat = "ffextremeradiationImmunity", amount = 1 },
    { stat = "biomeheatImmunity", amount = 1 },
    { stat = "ffextremeheatImmunity", amount = 1 },
    { stat = "lavaImmunity", amount = 1 },
    { stat = "protoImmunity", amount = 1 },
    { stat = "fallDamageMultiplier", effectiveMultiplier = 0 }
  })
  activeItem.setShieldPolys({self.shieldPoly})
  activeItem.setDamageSources({ self.knockbackDamageSource })
  self.active = true
  self.weapon.shieldId = world.spawnProjectile("ivrpgnautilusbubble", mcontroller.position(), activeItem.ownerEntityId(), {0,0}, true, {timeToLive = math.huge})
  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function GunFire:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  local progress = 0
  util.wait(self.stances.cooldown.duration, function()
    local from = self.stances.cooldown.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.weaponRotation, self.stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.armRotation, self.stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.cooldown.duration))
  end)
end

function GunFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function GunFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function GunFire:energyPerShot()
  return self.energyUsage * (self.energyUsageMultiplier or 1.0)
end

function GunFire:uninit()

end

function GunFire:bubbleEffects(sink)
  local oldGravityMultiplier = self.movementParams.gravityMultiplier or 1
  local newGravityMultiplier = 0.25 * oldGravityMultiplier
  local buoyancy = sink and -10 or 1
  if mcontroller.jumping() and mcontroller.liquidMovement() then buoyancy = 10 end
  mcontroller.controlModifiers({
    airJumpModifier = 1.1,
    liquidMovementModifier = 10
  })
  mcontroller.controlParameters({
    gravityMultiplier = newGravityMultiplier,
    bounceFactor = 0.8,
    liquidFriction = 10,
    liquidBuoyancy = buoyancy,
    liquidForce = 1000
  })
  if mcontroller.liquidMovement() and not self.inLiquid then
    self.inLiquid = true
    if self.liquidTimer == 0 then
      animator.playSound("liquid")
      self.liquidTimer = 1
    end
  elseif not mcontroller.liquidMovement() then
    self.inLiquid = false
  end
end

function popBubble()
  if self.weapon.shieldId then
    world.callScriptedEntity(self.weapon.shieldId, "die")
    self.weapon.shieldId = false
    animator.playSound("break")
  end
end

function reset()
  popBubble()
  activeItem.setShieldPolys({})
  activeItem.setDamageSources({})
  status.clearPersistentEffects(activeItem.hand().."Shield")
end

function uninit()
  incorrectWeapon(true)
  reset()
  status.clearPersistentEffects("ivrpgwnautilus")
  self.weapon:uninit()
end
