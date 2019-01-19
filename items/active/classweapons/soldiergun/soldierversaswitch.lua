require "/scripts/util.lua"
require "/scripts/interp.lua"

-- Base gun fire ability
GunFire = WeaponAbility:new()

function GunFire:init()
  self.weapon:setStance(self.stances.idle)
  self.name = item.name()
  self.cooldownTimer = self.fireTime
  self.chargeTime = config.getParameter("chargeTime", 1)
  self.chargeTimer = 0
  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  self.triggerHappy = status.statPositive("ivrpguctriggerhappy") and self.name == "soldierversagun3"
  self.hardLight = status.statPositive("ivrpguchardlight") and self.name == "soldierversagun3"

  if self.triggerHappy then
    self.chargeTime = 1
  else
    self.chargeTime = 1.5
  end

  if self.hardLight then
    self.projectileType = "versabullethl"
  else
    self.projectileType = "versabullet"
  end

  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and not world.lineTileCollision(mcontroller.position(), self:firePosition())
    and not (self.triggerHappy and self.chargeTimer == self.chargeTime) then
    if self.chargeTimer < self.chargeTime then
      if self.chargeTimer == 0 then
        animator.playSound("charge")
      end
      status.overConsumeResource("energy", self:energyPerShot()*self.dt*(self.triggerHappy and 4/3 or 1))
      self.chargeTimer = math.min(self.chargeTime, self.chargeTimer + self.dt)
      if self.chargeTimer == self.chargeTime then
        animator.playSound("charged")
        animator.stopAllSounds("charge")
      end
    else
      status.setResourcePercentage("energyRegenBlock", 1.0)
    end
  else
    if self.chargeTimer > 0 then
      animator.stopAllSounds("charge")
      status.overConsumeResource("energy", self:energyPerShot() * (1.5 - self.chargeTimer))
      self:setState(self.auto)
    end
    self.chargeTimer = 0
  end
end

function isNearHand()
  return (activeItem.hand() == "primary") == (aimDirection < 0)
end

function GunFire:auto()

  if self.triggerHappy then
    self.chargeTimer = self.chargeTimer*4/3
  end

  self.baseInaccuracy = self.inaccuracy
  self.inaccuracy = self.inaccuracy * (1.5 - self.chargeTimer)
  self.extraPower = (1 + (self.chargeTimer*2/3)^3)

  self.weapon:setStance(self.stances.fire)

  self:fireProjectile()
  self:muzzleFlash()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.inaccuracy = self.baseInaccuracy
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

function GunFire:muzzleFlash()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("muzzleFlash")
  animator.playSound("fire")

  animator.setLightActive("muzzleFlash", true)
end

function GunFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = self:damagePerShot()
  params.powerMultiplier = activeItem.ownerPowerMultiplier()*self.extraPower
  params.speed = util.randomInRange(params.speed)

  if not projectileType then
    projectileType = self.projectileType
  end
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  local projectileId = 0
  for i = 1, (projectileCount or self.projectileCount) do
    projectileId = world.spawnProjectile(
        projectileType,
        firePosition or self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(inaccuracy or self.inaccuracy),
        false,
        params
      )
  end
  return projectileId
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
  return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function GunFire:damagePerShot()
  return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
end

function GunFire:uninit()

end
