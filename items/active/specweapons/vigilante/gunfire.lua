require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/ivrpgutil.lua"

-- Base gun fire ability
GunFire = WeaponAbility:new()

function GunFire:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
  self.hand = activeItem.hand()
  self.hand = self.hand == "primary" and "alt" or "primary"
  self.id = activeItem.ownerEntityId()
  self.name = item.name()
  self.energyUsage2 = config.getParameter("primaryAbility.energyUsage2", self.energyUsage)
  self.reload = config.getParameter("primaryAbility.reloadSound", "")
  
  self.heldItem = world.entityHandItem(self.id, self.hand)
  self.marie = self.heldItem and self.heldItem == "ivrpgwmarie"
  self.anne = self.heldItem and self.heldItem == "ivrpgwanne"

  if self.marie then
    self.maxShots = config.getParameter("primaryAbility.shotsLeft", 6) + 2
  else
    self.maxShots = config.getParameter("primaryAbility.shotsLeft", 6)
  end
  self.shotsLeft = self.maxShots
end

function GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end

  if self.marie then
    self.maxShots = config.getParameter("primaryAbility.shotsLeft", 6) + 2
  else
    self.maxShots = config.getParameter("primaryAbility.shotsLeft", 6)
  end

  if self.name == "ivrpgwanne" and status.resource("energy") == status.resourceMax("energy") and (not status.resourceLocked("energy")) then
    if self.shotsLeft < self.maxShots then
      animator.playSound("reload")
      self.weapon:setStance(self.stances.fire)
      if self.stances.fire.duration then
        util.wait(self.stances.fire.duration)
      end
      self.cooldownTimer = self.fireTime
      self:setState(self.cooldown)
    end
    self.shotsLeft = self.maxShots
  end

  self.heldItem = world.entityHandItem(self.id, self.hand)
  self.marie = self.heldItem and self.heldItem == "ivrpgwmarie"
  self.anne = self.heldItem and self.heldItem == "ivrpgwanne"

  if self.anne and self.name == "ivrpgwmarie" then
    status.setPersistentEffects("vigilantedualpistols", {
      {stat = "physicalResistance", amount = 0.2},
      {stat = "grit", amount = 0.2}
    })
  elseif self.name == "ivrpgwmarie" then
    status.setPersistentEffects("vigilantedualpistols", {})
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then

    if self.fireType == "anne" and self:canAnneFire() then
      self:setState(self.auto)
    elseif self.fireType == "marie" and (not status.resourceLocked("energy")) and status.overConsumeResource("energy", self:energyPerShot()) then
      self:setState(self.auto)
    end
  end

  incorrectWeapon()
end

function GunFire:canAnneFire()
  if self.shotsLeft > 0 then
    self.shotsLeft = self.shotsLeft - 1
    return status.resourceLocked("energy") or status.overConsumeResource("energy", self:energyPercentPerShot())
  else
    return false
  end
end

function GunFire:auto()
  self.weapon:setStance(self.stances.fire)

  self:fireProjectile()
  self:muzzleFlash()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

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
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.speed = util.randomInRange(params.speed)

  if not projectileType then
    projectileType = self.projectileType
  end
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  local projectileId = 0
  for i = 1, (projectileCount or self.projectileCount) do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end
    if self.name == "ivrpgwanne" then
      if self.marie then
        params.statusEffects = {{effect = "burning", duration = 3}} 
      end
    end
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

function GunFire:energyPercentPerShot()
  return 1 / (self.shotsLeft + 1) * status.resource("energy")
end

function GunFire:damagePerShot()
  return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
end

function GunFire:uninit()
  status.clearPersistentEffects("vigilantedualpistols")
  incorrectWeapon(true)
end

function Weapon:updateAim()
  self.gunScale = config.getParameter("gunScale", {0.8,0.8})
  for _,group in pairs(self.transformationGroups) do
    animator.resetTransformationGroup(group.name)
    animator.translateTransformationGroup(group.name, group.offset)
    animator.rotateTransformationGroup(group.name, group.rotation, group.rotationCenter)
    animator.translateTransformationGroup(group.name, self.weaponOffset)
    animator.rotateTransformationGroup(group.name, self.relativeWeaponRotation, self.relativeWeaponRotationCenter)
    animator.scaleTransformationGroup(group.name, self.gunScale)
  end

  local aimAngle, aimDirection = activeItem.aimAngleAndDirection(self.aimOffset, activeItem.ownerAimPosition())


  if self.stance.allowRotate then
    self.aimAngle = aimAngle
  elseif self.stance.aimAngle then
    self.aimAngle = self.stance.aimAngle
  end
  activeItem.setArmAngle(self.aimAngle + self.relativeArmRotation)

  local isPrimary = activeItem.hand() == "primary"
  if isPrimary then
    -- primary hand weapons should set their aim direction whenever they can be flipped,
    -- unless paired with an alt hand that CAN'T flip, in which case they should use that
    -- weapon's aim direction
    if self.stance.allowFlip then
      if activeItem.callOtherHandScript("dwDisallowFlip") then
        local altAimDirection = activeItem.callOtherHandScript("dwAimDirection")
        if altAimDirection then
          self.aimDirection = altAimDirection
        end
      else
        self.aimDirection = aimDirection
      end
    end
  elseif self.stance.allowFlip then
    -- alt hand weapons should be slaved to the primary whenever they can be flipped
    local primaryAimDirection = activeItem.callOtherHandScript("dwAimDirection")
    if primaryAimDirection then
      self.aimDirection = primaryAimDirection
    else
      self.aimDirection = aimDirection
    end
  end

  activeItem.setFacingDirection(self.aimDirection)

  activeItem.setFrontArmFrame(self.stance.frontArmFrame)
  activeItem.setBackArmFrame(self.stance.backArmFrame)
end