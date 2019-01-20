require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/ivrpgutil.lua"

-- Base gun fire ability
GunFire = WeaponAbility:new()

function GunFire:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime
  self.powerCharge = 0

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
  self.hand = activeItem.hand()
  self.id = activeItem.ownerEntityId()
  self.name = item.name()
  self.grenadesActive = false
  self.minimumTriggerTimer = 0
  self.minimumTriggerTime = config.getParameter("primaryAbility.minimumTriggerTime", 0)
  self.projectiles = config.getParameter("primaryAbility.projectiles", {})

  storage.fireTimer = storage.fireTimer or 0
  self.recoilTimer = 0

  storage.activeProjectiles = storage.activeProjectiles or {}
  self:updateCursor()
end

function GunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  self.recoilTimer = math.max(self.recoilTimer - dt, 0)
  self.minimumTriggerTimer = math.max(0, self.minimumTriggerTimer - dt)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and #storage.activeProjectiles == 0
    and self.cooldownTimer == 0
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
    if (not status.resourceLocked("energy")) and status.overConsumeResource("energy", self:energyPerShot()) then
      self:setState(self.fire)
    end
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot) and #storage.activeProjectiles > 0 and self.minimumTriggerTimer == 0 then
    self.powerCharge = math.min(self.powerCharge + dt*5/8, 5)
  end

  activeItem.setRecoil(self.recoilTimer > 0)

  self:updateProjectiles()
  self:updateCursor()
  self:powerUpProjectiles()

  if self.fireMode ~= (self.activatingFireMode or self.abilitySlot) and #storage.activeProjectiles > 0 and self.minimumTriggerTimer == 0 then
    self:triggerProjectiles()
  end

  incorrectWeapon()
end


function GunFire:fire()
  self.weapon:setStance(self.stances.fire)

  self:fireProjectile()
  --self:muzzleFlash()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.minimumTriggerTimer = self.minimumTriggerTime

  --self:setState(self.cooldown)
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

  self.powerCharge = 0
  self.cooldownTimer = 0.5
end

function GunFire:powerUpProjectiles()
  for i, projectile in ipairs(storage.activeProjectiles) do
    if world.entityExists(projectile) then
      world.callScriptedEntity(projectile, "powerUp", self.powerCharge, activeItem.ownerPowerMultiplier())
    end
  end 
end

function GunFire:updateProjectiles()
  local newProjectiles = {}
  local count = #storage.activeProjectiles
  for i, projectile in ipairs(storage.activeProjectiles) do
    if world.entityExists(projectile) then
      newProjectiles[#newProjectiles + 1] = projectile
    end
  end
  storage.activeProjectiles = newProjectiles
  if count > 0 and #storage.activeProjectiles == 0 then
    self:setState(self.cooldown)
  end
end

function GunFire:triggerProjectiles()
  if #storage.activeProjectiles > 0 then
    animator.playSound("trigger")
  end
  for i, projectile in ipairs(storage.activeProjectiles) do
    world.callScriptedEntity(projectile, "trigger")
  end
  self:setState(self.cooldown)
end

function GunFire:updateCursor()
  if #storage.activeProjectiles > 0 then
    activeItem.setCursor("/cursors/chargeready.cursor")
  else
    activeItem.setCursor("/cursors/reticle0.cursor")
  end
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

  shuffle(self.projectiles)
  local projectileId = 0
  for i = 1, (projectileCount or self.projectileCount) do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end
    local inacChange = 0
    if math.abs(i-3) == 2 then
      inacChange = i - 3
      params.speed = 40
    elseif math.abs(i-3) == 1 then
      params.speed = 40 + (i-3)*5
    else
      params.speed = 40
    end

    local projectileId = world.spawnProjectile(
        self.projectiles[i],
        firePosition or self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVectorChange(inaccuracy or self.inaccuracy, inacChange*0.1),
        false,
        params
      )
    if projectileId then
      storage.activeProjectiles[#storage.activeProjectiles + 1] = projectileId
    end
  end
  animator.burstParticleEmitter("fireParticles")
  animator.playSound("fire")
  self.recoilTimer = config.getParameter("recoilTime", 0.15)
end

function GunFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function GunFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function GunFire:aimVectorChange(inaccuracy, rotation)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0) + rotation)
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function GunFire:energyPerShot()
  return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function GunFire:damagePerShot()
  return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1)) / self.projectileCount
end

function GunFire:uninit()
  for i, projectile in ipairs(storage.activeProjectiles) do
    world.callScriptedEntity(projectile, "setTarget", nil)
  end
end

function uninit()
  incorrectWeapon(true)
  self.weapon:uninit()
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